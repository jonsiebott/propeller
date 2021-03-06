{{
 PS2Controller 
 by Chris Cantrell
 Version 1.0 3/24/2011
 Copyright (c) 2011 Chris Cantrell
 See end of file for terms of use.
}}

{{  
  ##### HARDWARE CONNECTION #####

  Looking into controller's plug (the pins are visible).
  The curved edge is at the bottom. Pins are numbered
  left to right as shown here:
      
  ┌─────────────┐
  │ 123 456 789 │
   \___________/

    
            3.3V
           
            10K  1K
  1 DAT  ──┻───────── PN
  2 CMD  ──────────── PN+1
  3 VIB    1K
  4 Ground
  5 3.3V   1K
  6 SEL  ──────────── PN+2
  7 CLK  ──────────── PN+3
  8 ---    1K
  9 ACK

  The controller is connected to the propeller port pins in order as shown above.
  The driver assumes the signals are connected to consecutive pins in order.
  Each pin uses a 1K in series, and the DAT line is pulled up to 3.3V through
  a 10K resistor.

  You can connect the VIB pin to a 9V source (down to 4V even). The vibration motors
  draw a lot of current.

  Lynxmotion sells a $5 breakout cable for the PS2 controller:
  http://www.lynxmotion.com/p-73-ps2-controller-cable.aspx
  
  If this deep link has changed start at the lynxmotion top page and search in cables.

  ##### SOFTWARE DRIVER #####

  Most of the time you will want to run the driver in "polling" mode where it will automatically
  read the controller values and write them to shared memory. But at startup you might want
  to configure the controller (for instance, turn on analog mode) with a sequence of commands.

  The driver allows you to write arbitrary multi-byte commands to the controller. Once configured
  you can setup the polling command and have the driver continually send it. You may stop/start
  polling mode as needed.

  To setup a command you write the bytes of the command to the "outBuf". You also write the number
  of bytes to "length". Then write the value 2 to the control parameter. The driver will handle
  the write/read and set the control value to 0. You may then read the response bytes from "inBuf".

  To start the polling you write the command bytes for the polling command to the "outBuf" along
  with the "length". Then write the value 3 to the control parameter. The driver will continually
  refresh the "inBuf" with the values from the controller.

  To stop polling write the value 1 to the control parameter. When the driver has halted it will
  change the control value to 0.
  
  Driver parameters:
    long control        Controls the driver's actions
    long length         Number of bytes to read/write                                       
    byte inBuf[32]      Buffer to store incoming bytes   
    byte outBuf[32]     Buffer containing command bytes

  Control/status values:
    0: Halted
    1: Halt. Goes to 0 when halted.
    2: Read/Write bytes. Goes to 0 when done.
    3: Read/Write bytes in a loop. Remains 3

  ##### FREQUENCIES AND COMMANDS #####

  The official playstation 2 controllers can be clocked at 500KHz. The guitar-hero controller
  will requires a much slower clock. 250KHz works fine.

  There are lots of hobbyist pages on the web discussing the PS2 controller protocol. Most of
  the information in this driver comes from:

  http://store.curiousinventor.com/guides/ps2/

  The above link also explains how to control the vibration motors in the Dual Shock controller.

  ##### INPUT MAPPINGS #####

  The 4th and 5th bytes returned by the $42 command contain the digital button bits, one per button.
  The 6th and 7th bytes are the right stick horizontal and vertical analog values respectively.
  The 8th and 9th bytes are the left stick horizontal and vertical analog values respectively.

  On the GuitarHero controller the 9th byte is the whammy-bar analog value.

  Some controllers can return pressure values (how hard the button is pressed) for the digital
  inputs. See the web link above for details.

  The digital inputs return 0 when pressed and 1 when NOT pressed.

  In this table bit 0 is the least-significant and bit 7 is the most-significant.
  The table shows the digital bit mappings for bytes 4 and 5 of the $42 response data.
  The GuitarHero mappings are show in upper-case.
  
    4.0 Select    SELECT
    4.1 L3
    4.2 R3
    4.3 Start     START
    4.4 Up        STRUM_UP
    4.5 Right
    4.6 Down      STRUM_DOWN
    4.7 Left      *ALWAYS PRESSED*
    5.0 L2        STAR_POWER
    5.1 R2        GREEN
    5.2 L1
    5.3 R1
    5.4 Triangle  YELLOW
    5.5 Circle    RED
    5.6 X         BLUE
    5.7 Square    ORANGE 
  
}}

VAR

  long control        ' The control byte for the driver loop
  long length         ' Number of bytes to send/receive
  byte inBuffer[32]   ' Incoming response bytes
  byte outBuffer[32]  ' Outgoing command bytes


PUB start(firstPin, clockFreq, pollFreq)
'' Start the driver cog.
'' @param firstPin the DAT pin (followed in order by CMD, SEL, and CLK pins)
'' @param clockFreq the data clock frequence to use

  ' Make the pin masks
  dat_pin := 1 << firstPin
  cmd_pin := 1 << (firstPin+1)
  sel_pin := 1 << (firstPin+2)
  clk_pin := 1 << (firstPin+3)

  ' Setup the paramter pointers
  cmd_ptr := @control
  len_ptr := @length
  in_ptr  := @inBuffer
  out_ptr := @outBuffer

  ' Setup the delay counts
  halfCycleTime := (clkfreq / clockFreq) / 2

  ' On the scope the delay between bytes is roughly the
  ' time it takes to send 4 bits
  timeBetweenBytes := halfCycleTime * 2 * 4

  timeBetweenLoops := clkfreq / pollFreq ' Delay between reads when polling  

  'Examples:           250KHz    500KHz 
  'halfCycleTime    :=    160        80
  'timeBetweenBytes :=  1_280       640
  'timeBetweenLoops := 80_000    80_000

  control := 0 ' Start with the driver idle

  ' Start the driver
  return cognew(@entry, 0)

PUB setControl(controlVal)
'' Set the driver loop control value.
'' @param controlVal

  control := controlVal

PUB getControl
'' Get the driver loop control value.
'' @return the control value
  return control

PUB setLength(lengthVal)
'' Set the send/receive byte length.
'' @param lengthVal
  length := lengthVal

PUB getLength
'' Get the send/receive byte length.
'' @return the length
  return length

PUB setCommandBytes(ptr) | i
'' Set the command bytes (outgoing) from a given buffer.
'' The first byte of the buffer is the length of the data
'' @param ptr pointer to the data buffer to copy
  length := byte[ptr++]
  repeat i from 0 to (length-1)
    outBuffer[i] := byte[ptr++]

PUB setCommandByte(value,index)
'' Set a byte in the command (outgoing) buffer.
'' @param value
'' @param index
  outBuffer[index] := value

PUB getResponseByte(index)
'' Get a byte from the response (incoming) buffer.
'' @param index
'' @return the value from the buffer
  return inBuffer[index]

PUB getParamPointer
'' Get a pointer to the parameter block for full control.
'' @return pointer to the parameters
  return @control

PUB executeAndWait
'' Send the command buffer to the controller and wait for the driver to finish the I/O.
  control := 2
  repeat while control<>0

PUB startPolling
'' Start the driver's polling loop.
  control := 3

PUB stopPolling
'' Stop the driver's polling loop and wait for it to go idle.
  control := 1
  repeat while control<>0
  
DAT
         org     0
entry   
         or        outa,clk_pin        ' De-assert the CLK (active low)
         or        outa,sel_pin        ' De-assert the SEL (active low)
         
         mov       dira,cmd_pin        ' CMD is an output (DAT is input)        
         or        dira,sel_pin        ' SEL is an output
         or        dira,clk_pin        ' CLK is an output

main
         rdlong    t1,cmd_ptr wz       ' Get the control value
  if_z   jmp       #main               ' 0: Idle ... keep waiting
         cmp       t1,#2 wz            ' 2: ReadWrite ...
  if_z   jmp       #doReadWrite        ' ... go read/write a sinlge command
         cmp       t1,#3 wz            ' 3: ReadWrite loop ...
  if_z   jmp       #doLoop             ' ... go read/write a command in a loop
  
         ' 1 and everything else is a HALT
doHalt
         mov       t1,#0               ' Set the control byte ...
         wrlong    t1,cmd_ptr          ' ... to 0 (idle)
         jmp       #main               ' Wait for next control 

doReadWrite
         call      #readWriteBytes     ' Read/write the command/data                  
         jmp       #doHalt             ' Go to idle state
         
doLoop   
         call      #readWriteBytes     ' Read/write the command/data

         ' Delay between polls (not worried about sync-wait drifts)
         mov       t1,timeBetweenLoops ' Delay between loops
         add       t1,cnt              ' Add it to existing count
         waitcnt   t1,#0               ' Wait for the delay

         jmp       #main               ' Continue processing


' Read/write a sequence of bytes.
' @param [len_ptr] number of bytes to move
' @param in_ptr  where to store the incoming bytes
' @param out_ptr where to read the command bytes from         
readWriteBytes
{

    SEL (Attention)  
  ─────────────────  CLK
                                
       D     D     D     D     D     D
       
  The SEL (Attention) line goes from high to low to begin a multi-byte
  transfer. There is a small delay (D) before the first byte and after the
  last. There is a small delay between bytes. The images from the scope
  show these delays are all about the same.
}

         andn       outa,sel_pin       ' Assert the SEL pin to start command

        ' Setup the pointers and count
         rdlong    t3,len_ptr          ' Get the number of bytes to send

         mov       ptrIn,in_ptr        ' Point to start of the incoming buffer
         mov       ptrOut,out_ptr      ' Point to start of the outgoing buffer

         ' Small delay before main loop (not worried about sync-wait drifts)
         mov       t1,timeBetweenBytes ' Delay between bytes
         add       t1,cnt              ' Add it to existing count
         waitcnt   t1,#0               ' Wait for the delay   

:allBytes
         ' Do the I/O
         rdbyte    tx_data,ptrOut      ' Get the next byte to send
         call      #readWriteByte      ' Do the read/write
         wrbyte    rx_data,ptrIn       ' Store the response byte in the buffer

         ' Advance the pointers
         add       ptrOut,#1           ' Bump the pointer 
         add       ptrIn,#1            ' Bump the pointer

         ' Delay after each byte
         mov       t1,timeBetweenBytes ' Delay between bytes
         add       t1,cnt              ' Add it to existing count
         waitcnt   t1,#0               ' Wait for the delay

         ' Do all bytes
         djnz      t3,#:allBytes       ' Do all requested bytes

         or        outa,sel_pin        ' De-assert SEL pin after command

readWriteBytes_ret
         ret
         

' Read a byte and write a byte.
' @param  tx_data the byte to send
' @return rx_data the byte read
readWriteByte
{ 
  The clock starts high and transitions to low and back to high.
  
  The CMD bit is written to the controller before the high-to-low edge.
  The DAT bit is read from the controller just before the next high-to-low edge.  

  Data is transfered LSB first as shown with W(write) and R(read) here:  

    
                                      
      W0  R0 W1 R1 W2 R2 W3 R3 W4 R4 W5 R5 W6 R6 W7 R7
}
           
        mov        t1,#8               ' 8 bits to read/write

:allBits
        ' Output the CMD bit
        test       tx_data,#1 wc       ' Bit-0 of COMMAND to C
        muxc       outa,cmd_pin        ' Write Bit-0 to the CMD pin
        ror        tx_data,#1          ' Prepare for next COMMAND bit

        ' Clock high-to-low
        andn       outa,clk_pin        ' Clock goes from high to low

        ' Wait for half cycle (not worried about synchronized delay)
        mov        t2,cnt              ' Current count ...
        add        t2,halfCycleTime    ' ... plus delay time
        waitcnt    t2,#0               ' Do the wait

        ' Clock low-to-high
        or         outa,clk_pin        ' Clock goes from low to high          

        ' Wait for half cycle (not worried about synchronized delay)
        mov        t2,cnt              ' Current count ...
        add        t2,halfCycleTime    ' ... plus delay time
        waitcnt    t2,#0               ' Do the wait

        ' Read the DAT bit
        test       dat_pin,ina wc      ' Read the data input to C
        rcr        rx_data,#1          ' Shift it into the tally

        djnz       t1,#:allBits        ' Do all 8 bits

        shr        rx_data,#24         ' Shift the long to a byte

readWriteByte_ret
         ret

' Temporaries

t1       long $0
t2       long $0
t3       long $0
tx_data  long $0
rx_data  long $0
ptrIn    long $0
ptrOut   long $0          


' These are filled in before loading the code into the COG

halfCycleTime      long $0-0   ' Cycle count delay for high and low clock holds
timeBetweenBytes   long $0-0   ' Cycle count delay between bytes
timeBetweenLoops   long $0-0   ' In polling, cycle count delay between polls

cmd_ptr            long $0-0   ' Pointer to the control parameter
len_ptr            long $0-0   ' Pointer to the buffer length parameter
in_ptr             long $0-0   ' Pointer to the input buffer (response from controller)
out_ptr            long $0-0   ' Pointer to the output buffer (command to controller)
                     
dat_pin            long $0-0   ' Bit mask for DAT pin
cmd_pin            long $0-0   ' Bit mask for CMD pin
sel_pin            long $0-0   ' Bit mask for SEL pin
clk_pin            long $0-0   ' Bit mask for CLK pin

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