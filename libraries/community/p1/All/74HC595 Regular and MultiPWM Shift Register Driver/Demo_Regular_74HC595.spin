CON
{{
        Demo for 74HC595 Regular Driver v1.0 April 2009
        See 74HC595_Regular.spin for more info
        
        Copyright Dennis Ferron 
        Contact:  dennis.ferron@gmail.com
        See end of file for terms of use

}}



  _clkmode = xtal1 + pll16x                             ' use crystal x 16
  _xinfreq = 5_000_000                                  ' 5 MHz cyrstal (sys clock = 80 MHz)


  ' Set this to the pins you have connected to the 74HC595's
  SR_CLOCK = 21
  SR_LATCH = 22
  SR_DATA  = 23

  ' <<<<  For demo purposes, connect the shift register's output pins to A0-A7 so the Propeller can check them. >>>>

OBJ
  shift :       "74HC595_Regular"
  text  :       "tv_text"

PUB start | i

  'start term
  text.start(12)

  ' Required:  Initialize the object.  Set 100 chips for testing.
  shift.Start(SR_CLOCK, SR_LATCH, SR_DATA, 100)

  ' Demo: Output continuously changing count
  repeat
    repeat i from $00 to $FF

      ' Output i to chip 0.
      shift.Out(i, 0)

      ' For testing, mess around with "chip" number 99.
      ' (Does not have to have a chip there to save the value.)
      shift.Out(0, 99)          ' Clear chip 99
      shift.High(99*8+0)        ' Set bit 0 of chip 99
      shift.Low(99*8+1)         ' Clear bit 1 of chip 99 
      shift.High(99*8+2)        ' Set bit 2 of chip 99
      text.str(string("What(99), should be 5:  "))
      text.hex(shift.What(99), 2)
      text.out(" ")
      text.bin(shift.What(99), 8)
      text.out(13)

      ' Display what we expect to output to chip 0.
      text.str(string("i = "))
      text.hex(i, 2)
      text.str(string(" What(0) = "))
      text.hex(shift.What(0), 2)
      text.out(" ")
      text.bin(shift.What(0), 8)
      text.out(13)

      ' Input the values output by 74HC595 chip 0.
      ' For this to report a value, connect the QA-QH outputs from
      ' the shift register back to A0-A7 on the Propeller.
      text.str(string("i = "))
      text.hex(i, 2)
      text.str(string(" Input   = "))
      text.hex(ina, 2)
      text.out(" ")
      text.bin(ina, 8)
      text.out(13)
      
      text.out(13)
      waitcnt(clkfreq + cnt)

DAT

{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}