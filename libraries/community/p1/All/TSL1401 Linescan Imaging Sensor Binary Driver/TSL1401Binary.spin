{{ Binary driver for TSL1401 Linescan Imaging Sensor Daughterboard
   Version - 1.0                Initial release
   Version - 1.1                Fixed error in reading last pixel.
                                Added ability to turn an LED connected to the mezzanine connector on  and off. 
   Author - John Abshier (jabshier on Parallax forum)
   Development setup - TSL1401 plugged into SIP adapter and SIP adapter plugged into Propeller Development Board
}}   
   
CON
'' Constants
  CNT_MIN     = 400        '' CNT_MIN Minimum waitcnt value to prevent lock-up
  DRK = 0                  '' DRK dark pixels
  BRT = 1                  '' BRT bright pixels
  FWD = 0                  '' FWD forward direction, left to right
  BKWD = 1                 '' BKWD backward direction, right to left
  LTOD = 0                 '' LTOD light to dark edge
  DTOL = 1                 '' DTOL dark to light edge
  ERROR = -1               '' ERROR error return value
  
VAR
  long ao, si, clk, led         ' camera analog output, si, clock and LED control pins
  long ms                       ' clock cycles for 1 ms
  long expTimeCorr              ' expTime correction for Spin timing overhead

{{ Common parameters
        imageAddr address of array of 128 bytes for image
        expTime - exposre time in milliSeconds
        lprt - left limit for operation
        rptr - right limit for operation
        type - bright or dark
        dir - direct ot search
}}

PUB GetImage(imageAddr, expTime)  | i  
'' One shot binaryimage acquire
'' Expects to be passed an address of array of 128 bytes and a long with expTime in milli seconds
'' Returns ERROR or adjusted expTime and image in passed array  
  expTime -= expTimeCorr                    ' Reduce for program overhead
  if expTime =< 0                           ' Don't know what max should be           
    return ERROR  
  longfill(imageAddr,0,32)                  ' zero image array
  outa[si]~~                                ' start exposure interval
  outa[clk]~~
  outa[si]~
  outa[clk]~
  repeat 256                                ' clock out pixels for one shot
    !outa[clk]
  outa[clk]~
  Pause_mS(expTime)                         ' wait exposure time
  outa[si]~~                                ' end exposure
  outa[clk]~~
  outa[si]~
  outa[clk]~
  byte[imageAddr][0] := ina[ao]
  repeat i from 1 to 127
    outa[clk]~~                                                ' high
    byte[imageAddr][i] := ina[ao]
    outa[clk]~                                                 ' low
  return expTime

PUB CountPixels(lptr, rptr, type, imageAddr) : count | i
'' Counts number of pixels of type between left and right limits, inclusive
'' Returns -1 on error
  count := 0
  if lptr => 0 and lptr =< rptr and rptr =< 127
    repeat i from lptr to rptr
      if byte[imageAddr][i] == type
        count++       
  else
    count := ERROR
    
PUB FindPixel(lptr, rptr, type, dir, imageAddr) : pixel
'' Finds pixel of type between limits, inclusive, in direction dir
'' Returns -1 on error
  if lptr => 0 and lptr =< rptr and rptr =< 127
    if dir == FWD
      repeat pixel from lptr to rptr
        if byte[imageAddr][pixel]  == type
          return
    else
      repeat pixel from rptr to lptr
        if byte[imageAddr][pixel] == type
          return
  return ERROR

PUB FindEdge(lptr, rptr, type, dir, imageAddr) : pixel 
'' Finds edge of type between limits, inclusive, in direction dir
'' returns pixel location or -1 for failure/error
  pixel := FindPixel(lptr, rptr, 1-type, dir, imageAddr)         ' Find pixel of 1st color
  if pixel == -1
    return                                                       ' return with ERROR
  if dir == FWD                                                  ' find pixel of 2d color
    pixel := FindPixel(pixel, rptr, type, dir, imageAddr)
  else
    pixel := FindPixel(lptr, pixel, type, dir, imageAddr)               '  

PUB FindLine(lptr, rptr, type, dir, imageAddr) : line | lEdge, rEdge
'' Finds a line of type between limits, inclusive, in direction dir
'' Returns a packed long:  xxxxxxxlllllllrrrrrrrrmmmmmmmm where
''  xxxxxxxx - unused byte llllllll - left edge of line
''  rrrrrrrr - right edge of line  mmmmmmm - middle of line
  if dir == FWD
    lEdge := FindEdge(lptr, rptr, type, dir, imageAddr)
    rEdge := FindEdge(lEdge, rptr, 1-type, dir, imageAddr) - 1
  else
    rEdge := FindEdge(lptr, rptr, type, dir, imageAddr)
    lEdge := FindEdge(lptr, rEdge, 1-type, dir, imageAddr) + 1
  if rEdge == -1 or lEdge == -1
    line := ERROR
  else
    line := lEdge << 16 + rEdge << 8 + (lEdge + rEdge)/ 2            ' bombs if lEdge=rEdge=0 is this possible?

PUB Denoise(imageAddr) | temp, i
{{ Removes 1 pixel noise.  Moves a window 3 pixels wide over data.  If center pixel is different
   from the two ends, it is set equal to the ends.    }}
   
  temp := long[imageAddr][0] << 2 + long[imageAddr][1] << 1 + long[imageAddr][2] 'left most pixel denoise
  if temp == $03
    long[imageAddr][0] := BRT
  if temp == $04
    long[imageAddr][0] := DRK
  temp := long[imageAddr][125] << 2 + long[imageAddr][126] << 1 + long[imageAddr][127] 'right most pixel denoise
  if temp == $06
    long[imageAddr][0] := BRT
  if temp == $01
    long[imageAddr][0] := DRK
  temp := long[imageAddr][0] << 1 + long[imageAddr][1]
  repeat i from 2 to 127
    temp := temp <<  1 + long[imageAddr][i]
    if temp & $07 == 5
      long[imageAddr][i-1] := BRT
    if temp & $07 == 2
      long[imageAddr][i-1] := DRK
  
Pub LedOn
{{ Turns LED connected to mezzanine connector on.  As you look at the camera use the bottom center and
   right sockets }} 
  outa[led]~

Pub LedOff
{{ Turns LED connected to mezzanine connector off }} 
  outa[led]~~
  

PUB Init(_ao, _si, _clk, _led)
{{ Initialize the pins direction and state. Must be called once. }}
  ao := _ao
  si := _si
  clk := _clk
  led := _led
  dira[ao]~                 ' set DO pin as input (is default at start, present for clarity)
  dira[si]~~
  dira[clk]~~
  dira[led]~~
  outa[si]~
  outa[clk]~
  outa[led]~~                               ' Led off
  ms:= clkfreq / 1_000                      ' Clock cycles for 1 us 
  expTimeCorr := 240_000_000 / clkfreq      ' adjust expTimeCorr for different clock frequencies

PRI PAUSE_mS(Duration) | clkCycles
''   Causes a pause for the duration in mS
   clkCycles := Duration * mS #> CNT_MIN                   ' duration * clk cycles for ms                                                          
   waitcnt(clkcycles + cnt)                                ' wait until clk gets there

{{
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}                          