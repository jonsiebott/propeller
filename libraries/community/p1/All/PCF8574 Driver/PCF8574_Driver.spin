''PCF8574_Driver.spin, v1.0, Craig Weber

''┌──────────────────────────────────────────┐
''│ Copyright (c) 2008 Craig Weber           │               
''│     See end of file for terms of use.    │               
''└──────────────────────────────────────────┘

''PCF8574 I2C 8-Bit I/O Expansion Driver

''This is a modified version of Raymond Allen's PCF8574 I2C Driver code, which is a
''stripped down version of Michael Green's "Basic_i2c_driver" found on "Object Exchange"

''It only reads and writes bytes
''This is all in SPIN, so it doesn't use up a cog.

''WARNING:  You should set all pins to HIGH (i.e., call OUT(%11111111)) before using pins as inputs.
''          Otherwise, an input signal to a pin may be connected to ground and fry the chip!
''          (but, note that all pins HIGH is the power-on state)

''NOTE:     OUT(%11111111) is automatically called before every read

''REMEMBER: Call Set_Pins(SCL, SDA) before calling anything else.  This can be called multiple times to change the I2C bus.

VAR
   byte SCL                  'I2C clock pin#
   byte SDA                  'I2C data pin# 

CON
   ACK      = 0              ' I2C Acknowledge
   NAK      = 1              ' I2C No Acknowledge
   Xmit     = 0              ' I2C Direction Transmit
   Recv     = 1              ' I2C Direction Receive

PUB Set_Pins(CLK, DATA)  ''Set SDA & SCL Pins
SCL := CLK
SDA := DATA

PUB Initialize                          ''Reinitialize I2C Device
   outa[SCL] := 1                       'Drive SCL high.
   dira[SCL] := 1
   dira[SDA] := 0                       'Set SDA as input
   repeat 9
      outa[SCL] := 0                    'Put out up to 9 clock pulses
      outa[SCL] := 1
      if ina[SDA]                       'Repeat if SDA not driven high
         quit                           'by the I2C Device
            
PUB IN(address):data | ackbit  ''Read PCF8574 Inputs. Automatically sets all pins to HIGH.
''Remember to Reset Outputs after calling

    OUT(address, %11111111)
    START
    ackbit:=Write((address<<1)+1)
    if (ackbit==ACK)
      data:=Read(ACK)
    else
      data:=-1   'return negative to indicate read failure
    STOP
    return data
    

PUB OUT(address,data):ackbit ''Write PCF8574 Outputs.
   START
   ackbit:=Write(address<<1)
   ackbit := (ackbit << 1) | Write(data)
   STOP
   return (ackbit==ACK)
            

PRI Start'(SCL) | SDA                   ' SDA goes HIGH to LOW with SCL HIGH
   outa[SCL]~~                         ' Initially drive SCL HIGH
   dira[SCL]~~
   outa[SDA]~~                         ' Initially drive SDA HIGH
   dira[SDA]~~
   outa[SDA]~                          ' Now drive SDA LOW
   outa[SCL]~                          ' Leave SCL LOW
  
PRI Stop'(SCL) | SDA                    ' SDA goes LOW to HIGH with SCL High
   outa[SCL]~~                         ' Drive SCL HIGH
   outa[SDA]~~                         '  then SDA HIGH
   dira[SCL]~                          ' Now let them float
   dira[SDA]~                          ' If pullups present, they'll stay HIGH

PRI Write(data) : ackbit '(SCL, data) : ackbit | SDA
'' Write i2c data.  Data byte is output MSB first, SDA data line is valid
'' only while the SCL line is HIGH.  Data is always 8 bits (+ ACK/NAK).
'' SDA is assumed LOW and SCL and SDA are both left in the LOW state.
   ackbit := 0 
   data <<= 24
   repeat 8                            ' Output data to SDA
      outa[SDA] := (data <-= 1) & 1
      outa[SCL]~~                      ' Toggle SCL from LOW to HIGH to LOW
      outa[SCL]~
   dira[SDA]~                          ' Set SDA to input for ACK/NAK
   outa[SCL]~~
   ackbit := ina[SDA]                  ' Sample SDA when SCL is HIGH
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW
   dira[SDA]~~

PRI Read(ackbit):data'(SCL, ackbit): data | SDA
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.
   data := 0
   dira[SDA]~                          ' Make SDA an input
   repeat 8                            ' Receive data from SDA
      outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
   outa[SDA] := ackbit                 ' Output ACK/NAK to SDA
   dira[SDA]~~
   outa[SCL]~~                         ' Toggle SCL from LOW to HIGH to LOW
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW


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
   