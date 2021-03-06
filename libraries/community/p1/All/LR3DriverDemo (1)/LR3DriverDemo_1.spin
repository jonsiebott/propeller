     
{{
**************************************************************************************************************
**************************************************************************************************************
                             LR3DriverDemo (1).spin                              
                        Copyright(C)2011 Thomas J. McLean                         
                        See End of File for Terms of Use.        
**************************************************************************************************************
**************************************************************************************************************

   This is a Parallax Propeller combined driver/demo for the LR3 Laser RangeFinder.  
The LR3($149 at porcupineelectronics.com)is an interface board that,with a 
microcontroller such as the Propeller,operates the Fluke 411D compact handheld laser
rangefinder($104 at Amazon.com).The LR3,when installed into the Fluke 411D,uses a red laser
to measure distances in millimeters up to 30 meters(98.5 feet)with a +/-3 millimeter accuracy.
The LR3/Fluke 411D unit can be used with autonomous robots.This unit can,for example,be
affixed to a standard servo by attaching a servo horn to the removable battery door on the
bottom of the Fluke and used for distance measurements,object avoidance,target acquisition or
P.I.D. tracking,in fixed or scanning mode,with continuous measurement readings.This program
has two demos for using the laser in fixed and scanning modes with the laser attached to a servo. 
   For more information on the LR3,including a data sheet and a video showing how to install
the LR3 into the Fluke,visit porcupineelectronics.com.Questions about the LR3 can be
directed to richard@porcupineelectronics.com.See Note below.   

Last Revised 06/10/11
                                                                
}}

CON

   _clkmode = xtal1 + pll16x    '80MHz     
   _xinfreq = 5_000_000    
                       
   'pins
   LaserServo = 6   '(4.7KΩ)(+5v)Parallax servo
   txpin      = 10  'pin connected to LR3 RX PIN(blue wire)
   rxpin      = 12  '(1KΩ)pin connected to LR3 TX PIN(white wire)
   LedR       = 16  'red status led 
   LedG       = 17  'green status led
   LedY       = 18  'yellow status led                       
                    'LR3 runs on +3.3v w/LR3 gnd connected to Propeller gnd.
                    'See Note below.
   'other                   
   baud = 9600  'max LR3 baudrate     
   scp  = 1500  'servo center position
   end  = "\"   'end character
                   
VAR

  long Astack[20]       
  byte Acog
  long Bstack[40]       
  byte Bcog
  long DST
  long delay          
  byte MyStr[8]
  byte data[8]    
   
OBJ

  SERVO : "Servo32v7"                 'download this object and Servo32_Ramp_v2 object from the OBEX
  FDS   : "FullDuplexSerial"            
  PST   : "Parallax Serial Terminal"  'set PST to 115200 baud                
  
PUB Init
   
  dira[LedR..LedY]~~ 
  delay := clkfreq/1000  
  SERVO.Start                   'start servo   
  Pause_m(20)          
  SERVO.Set(LaserServo,scp)     'center servo
  Pause_m(20)  
  PST.Start(115200)             'start PST 
  PST.Clear   
  Pause_m(5000)    
  FDS.start(rxpin,txpin,0,baud) 'start serial              
  Pause_m(100)            
  A_Start                       'start laser                    
  Pause_m(7000)                 'laser warm-up   
  B_Start                       'get laser measurements 
  Fixed_Demo                    'try this demo,then try next demo    
  'Scan_Demo                     'scan demo
  
'-----------------------------------------------------------------------------------------------------------
'                              A_Start in Separate Cog
'-----------------------------------------------------------------------------------------------------------
                            
PUB A_Start : success      

  A_Stop    
  success := (Acog := cognew(Go_A,@Astack) + 1)   
  
PUB A_Stop               

  if Acog
    cogstop(Acog~ -1)

PUB Go_A   'start laser 
  
  FDS.str(string("g")) 

'-------------------------------------------------------------------------------------------
'                              B_Start in Separate Cog
'-------------------------------------------------------------------------------------------                            
                            
PUB B_Start : success      

  B_Stop    
  success := (Bcog := cognew(Read_Measures,@Bstack) + 1) 
  
PUB B_Stop               

  if Bcog
    cogstop(Bcog~ -1)

PUB Read_Measures   'get laser measurements
 
  repeat
    repeat until MyStr[0] <> -1              
      RxStr(@MyStr)               
    DST := Get_Distance    
    
PUB Get_Distance    'get measurement string 
  
  RxStrTime(@MyStr,20)    
  return Convert_String(@MyStr,strsize(@MyStr))   

PUB Convert_String(ptr,indx) | dec, h    'convert measurement string to usable number  

  dec := 0 
  repeat indx
    h := byte[ptr++]           
    if (h < "0") or (h > "9")   
      quit
    else
      dec *= 10                
      dec += (h - "0")
  return dec
    
'----------------------------------------------------------------------------------------
'                                   FIXED DEMO
'----------------------------------------------------------------------------------------  

PUB Fixed_Demo   
{{
This works with fixed targets.It also works with a target moving directly away from or
towards the laser,or a target moving across the laser's field of view,if the target width,
range,speed,shape and composition are such that the laser can get readings on the target. 
}}                         
     
  repeat                                            
    PST.dec(DST)       
    PST.newline                             'change values for different ranges  
    if (DST => 220) and (DST =< 10000)      '220mm to 10 meters,red          
      Signal(LedR,20)
    elseif (DST > 10000) and (DST =< 20000) '10 meters to 20 meters,green        
      Signal(LedG,20)
    elseif (DST > 2000) and (DST =< 30000)  '20 meters to 30 meters,yellow          
      Signal(LedY,20)     

'----------------------------------------------------------------------------------------
'                                  SCAN DEMO
'----------------------------------------------------------------------------------------

PUB Scan_Demo | a, b, c, i 
{{
This works with fixed targets depending on target width,range,shape and composition.    
}}
  
  '20° scan(can vary)            
  a := scp - 100
  b := scp + 100              
  c := a + b                                  
  repeat                                      
    repeat i from a to b step 2               'coordinate no step or any step value w/stabilization pause 
      Servo.Set(LaserServo,i)      
      Pause_m(200)                            'stabilization pause(can adjust value)
      PST.dec(DST)                          
      PST.newline                             'change values for different ranges
      if (DST => 220) and (DST =< 15000)      '220mm to 15 meters,red         
        Signal(LedR,20)
      elseif (DST > 15000) and (DST =< 25000) '15 meters to 25 meters,green        
        Signal(LedG,20)                
      elseif (DST > 25000) and (DST =< 30000) '25 meters to 30 meters,yellow                                     
        Signal(LedY,20)                                       
    a := c - a                                'reverse direction    
    b := c - b  
    
'----------------------------------------------------------------------------------------
'                                    OTHER
'----------------------------------------------------------------------------------------

PUB Pause_m(msec) | q    

  q := cnt
  waitcnt(q+=(delay*msec)) 

PUB Signal(led,time)

  outa[led]~~
  Pause_m(time)
  outa[led]~ 

PUB RxStr(strptr)| ptr    'adapted from Extended Full Duplex Serial(OBEX)

   ptr := 0
   bytefill(@data,0,8)
   bytefill(strptr,0,8)                               
   data[ptr] := FDS.rx        
   ptr++                                                  
   repeat while (data[ptr-1] <> end) and (ptr < 8)       
     data[ptr] := FDS.rx    
     ptr++
   data[ptr-1] := 0                                         
   byteMove(strptr,@data,8)  

PUB RxStrTime(strptr,ms)| ptr, clc    'adapted from Extended Full Duplex Serial(OBEX)     

   ptr := 0     
   bytefill(@data,0,8)          
   bytefill(strptr,0,8)    
   clc := FDS.rxtime(ms)        
   if clc <> -1
     data[ptr] := clc
     ptr++       
     repeat while (data[ptr-1] <> end) and (ptr < 8)       
       clc := FDS.rxtime(ms)     
       if clc == -1
         ptr++
         quit    
       data[ptr] := clc
       ptr++
     data[ptr-1] := 0                                        
     byteMove(strptr,@data,8) 
       
{{
------------------------------------------------------------------------------------------
                                 END OF PROGRAM
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
                                    NOTES
------------------------------------------------------------------------------------------
                

                          NOTE FOR LR3 AND FLUKE 411D
                          
                          
       -The LR3 continuously returns ASCII strings at 10/sec in the form of "12345\r\n" where
        "12345" is an example of a 5 digit string in millimeters,and "\r\n" is the LR3 carriage
        return and line feed.There are no extra bytes at the beginning or end of a string.
        See the data sheet at porcupineelectronics.com for more information.
       -The LR3 runs on +3.3v.It can also run on +5v because the LR3 has a voltage regulator but
        there's no need to run it on +5v.
       -The operating temperature of the Fluke should be ~82°F or less.You can monitor the operating
        temperature with a laser thermometer($25 at harborfreight.com).If the operating temperature
        gets too high the laser will stop working properly.In higher ambient temperatures things
        seem to work better with heatsinks on the Prop board's 3.3v and 5v voltage regulators
        (#276-1363 at radioshack.com).
       -The LR3 will not work with the other Fluke rangefinders,416D(60 meters)and 421D(100 meters),
        because they have different LCDs from the Fluke 411D for which the LR3 was designed.  
       -The Fluke can be purchased at places other than Amazon,but Amazon gives free shipping.
       -When you get the Fluke,be sure to try it out several times to make sure it works properly
        because the warranty will void when you take it apart.
       -Review the Fluke instruction manual on the CD that comes with the Fluke. 
       -Be sure to put the Fluke in millimeter mode before you take it apart.
       -You'll need a No.2 Torx screwdriver to take the Fluke apart(Ace Hardware).
       -Measurements are calculated from the rear of the Fluke,not the front.
       -Carefully follow all the instructions in the video at porcupineelectronics.com when
        taking apart the Fluke and installing the LR3.
       -You won't use the Fluke AAA batteries when the LR3 is installed,so you could attach a
        servo horn to the battery door then reinstall the battery door on the completed unit.
        A temporary way to attach the Fluke to a servo is to use a round servo horn with a
        piece of double-stick foam tape.
       -The Fluke will not read measurements if a target is moving too quickly across its field
        of view,or if the Fluke itself is scanning too quickly,or if a target is outside its
        effective range of approximately 220mm to 30000mm.The PST displays zeros for non-measurements.             
       -Try long range experiments in low ambient light so you can see the laser.
       -In addition to the installation instructions in the video,you'll need to do the following:         
        1.You'll need to solder four wires to the four clearly marked solder holes by "J4" on the LR3.
          I used:red for +5v;black for Ground;blue for RX;and white for TX.These wires are attached
          to the Propeller board as noted in the program.I use a 1k resistor on the LR3 TX wire.To
          deal with the wires more easily,especially while scanning,I start with 24" or longer wires,          
          twist them together a bit,then wind them tighty around a pencil for a strain relief wire
          coil.You can then stretch out the coil a bit for more flexibility.          
        2.You'll have to dremel out more of the rear top of the Fluke to allow for the four wires
          you'll attach to come out the rear.The other connector at the rear is for a USB cord
          that comes with the LR3 in case you want to run the LR3 directly to your computer.The
          LR3 website has software you can download for this method of using the laser.
        3.Snip off the two small L-shaped prongs on the underside top of the Fluke that are positioned
          over the middle of the 40 pin ribbon connector that comes with the LR3,in order to better
          re-close the unit.If you're having trouble re-closing the unit,you may have to dremel out
          more of the top rear that's over the USB connector.          
        4.After the unit was reassembled,I ran a strip of black electrical tape around the rear
          of the unit to keep dust out.
          
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