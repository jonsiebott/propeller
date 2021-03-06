{{
                  *************************************************
                  *           PLX-DAQ Object Library              *
                  *                Version 1.0.0                  *
                  *             Released: 2/8/2007                *
                  *         Primary Author: Martin Hebel          *
                  *       Electronic Systems Technologies         *
                  *   Southern Illinois University Carbondale     *
                  *            www.siu.edu/~isat/est              *
                  *                    and                        *
                  *              www.selmaware.com                *
                  *                                               *
                  * Questions? Please post on the Propeller forum *
                  *       http://forums.parallax.com/forums/      *
                  *************************************************
                  *     --- Distribute Freely Unmodified ---      *
                  *************************************************

This object provides means for interfacing to PLX-DAQ
The PLX-DAQ Object Library must be created and started.
Uses Extended_FDSerial available from the Propeller Object Exchange
and FullDuplexSerial installed with the Propeller tool.
                   
CON
    _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000

OBJ                                           
    PDAQ : "PLX-DAQ"                   

Pub Start
    PDAQ.start(31,30,0,9600) ' Rx,Tx, Mode, Baud 
  
}}
Var
  Long  CR_Flag

OBJ
     Serial  : "Extended_FDSerial"   

Pub Start (RXpin, TXpin, Mode, Baud)
{{
   Start serial driver - starts a cog
   returns false if no cog available
  
   mode bit 0 = invert rx
   mode bit 1 = invert tx
   mode bit 2 = open-drain/source tx
   mode bit 3 = ignore tx echo on rx

   Serial.Start(31,30,0, 9600)
}}
    Serial.Start(RXPin, TXPin, Mode, Baud)
    Pause(500)
    CR

Pub Label (stringptr)
{{
  Places headings on the columns for rows A-J using up to
  26 comma-separated labels.
  PLX-DAQ String: LABEL,label1,label2,...label10
  ┌────────────────────────────────────────┐ 
  │ PDAQ.Label(string("label1,label2,etc"))│
  └────────────────────────────────────────┘
}}
   Serial.str(string("LABEL,"))
   Serial.str(stringptr)
   CR   

Pub Data(Value)
{{
  Sends an integer decimal value
  The Object library allows sending data as values or as text.                      
  A complete data set must end with a .CR call.                                                                  
 ┌────────────────────────────────────────────────┐                                 
 │ PDAQ.Data(value1)           ' Value            │                                 
 │ PDAQ.DataDiv(Value2,1000)   ' Value/1000       │                                 
 │ PDAQ.DataText(string("On"))                    │                                 
 │ PDAQ.CR                                        │                                 
 └────────────────────────────────────────────────┘                                 
}}
    If CR_Flag == true
       Serial.str(string("DATA"))
       CR_Flag := False
    Serial.tx(",")
    Serial.Dec(Value)

Pub DataDiv(Value,div)
{{
  Sends an integer decimal value divided by a divisor for a decimal point
  1234,100 will send 12.23
  
  The Object library allows sending data as values or as text.                      
  A complete data set must end with a .CR call.                                                                  
 ┌────────────────────────────────────────────────┐                                 
 │ PDAQ.Data(value1)           ' Value            │                                 
 │ PDAQ.DataDiv(Value2,1000)   ' Value/1000       │                                 
 │ PDAQ.DataText(string("On"))                    │                                 
 │ PDAQ.CR                                        │                                 
 └────────────────────────────────────────────────┘                                 
}}
    If CR_Flag == true
       Serial.str(string("DATA"))
       CR_Flag := False
    Serial.tx(",")
    Serial.DecPt(Value,div)

Pub DataText(stringptr)
{{
  Sends a text string
  
  The Object library allows sending data as values or as text.                      
  A complete data set must end with a .CR call.                                                                  
 ┌────────────────────────────────────────────────┐                                 
 │ PDAQ.Data(value1)           ' Value            │                                 
 │ PDAQ.DataDiv(Value2,1000)   ' Value/1000       │                                 
 │ PDAQ.DataText(string("On"))                    │                                 
 │ PDAQ.CR                                        │                                 
 └────────────────────────────────────────────────┘                                 
}}
    If CR_Flag == true
       Serial.str(string("DATA"))
       CR_Flag := false
    Serial.tx(",")
    Serial.str(stringptr)

Pub ClearData
{{
 Clears columns A-J, rows 2 and on. (labels remain). 
 PLX-DAQ String: CLEARDATA                          
┌────────────────────────────────────────┐           
│ PDAQ.ClearData                         │           
└────────────────────────────────────────┘           
}}
  Serial.str(string("CLEARDATA",13))      'Clear all data columns (A-J) in Excel   

Pub ResetTimer
{{
 Resets the timer to 0.                        
 PLX-DAQ String: CLEARDATA                    
┌────────────────────────────────────────┐     
│ PDAQ.ResetTimer                        │     
└────────────────────────────────────────┘     
}}
   Serial.str(string("RESETTIMER",13))     'Reset Timer to 0 

Pub RowGet 
{{
  Requests the last row data went into.            
  PLX-DAQ String: ROW,GET                         
 ┌────────────────────────────────────────┐        
 │ Row := PDAQ.RowGet                     │        
 └────────────────────────────────────────┘        
}}                                                   
  Serial.rxflush
  Serial.str(String("ROW,GET",13))
  result := Serial.RxDecTime(500)

Pub RowSet (row)
{{
 Sets the row the next data set will use.  
 PLX-DAQ String: ROW,SET,2                
┌────────────────────────────────────────┐ 
│ PDAQ.RowSet(2)                         │ 
└────────────────────────────────────────┘ 
}}

   Serial.str(String("ROW,SET,"))
   Serial.dec(row)
   CR
   
Pub CellSet(Cell,Value)
{{
 Sets the specified cell in Excel to the whole value.                                                
 PLX-DAQ String: CELL,SET,A2,100                               
 Note that CellSet works only with hex values for columns A to F  
┌────────────────────────────────────────────────┐                
│ PDAQ.CellSet($B3,100)                          │                
│ PDAQ.CellSetText($A4,String("Hello"))          │                
│ PDAQ.CellSetDiv($D4,1234,100)      ' 1234/100  │                   Serial.str(string("CELL,SET,"))
└────────────────────────────────────────────────┘                   Serial.hex(Cell,2)
}}
   Serial.str(string("CELL,SET,"))
   Serial.hex(Cell,2)
   Serial.tx(",")
   Serial.dec(Value)
   CR

Pub CellSetDiv(Cell,Value, div)
{{
 Sets the specified cell in Excel to the decimal point value by defining the divisor.                                                
 PLX-DAQ String: CELL,SET,A2,12.32                               
 Note that CellSet works only with hex values for columns A to F  
┌────────────────────────────────────────────────┐                
│ PDAQ.CellSet($B3,100)                          │                
│ PDAQ.CellSetText($A4,String("Hello"))          │                
│ PDAQ.CellSetDiv($D4,1234,100)      ' 1234/100  │                   Serial.str(string("CELL,SET,"))
└────────────────────────────────────────────────┘                   Serial.hex(Cell,2)
}}


   Serial.str(string("CELL,SET,"))
   Serial.hex(Cell,2)
   Serial.tx(",")
   Serial.decPt(Value, div)
   CR

PUB CellSetText(Cell,stringPtr)
{{
 Sets the specified cell in Excel to the text value.                                                
 PLX-DAQ String: CELL,SET,A2,"Hello"                             
 Note that CellSet works only with hex values for columns A to F  
┌────────────────────────────────────────────────┐                
│ PDAQ.CellSet($B3,100)                          │                
│ PDAQ.CellSetText($A4,String("Hello"))          │                
│ PDAQ.CellSetDiv($D4,1234,100)      ' 1234/100  │                   Serial.str(string("CELL,SET,"))
└────────────────────────────────────────────────┘                   Serial.hex(Cell,2)
}}

   Serial.str(string("CELL,SET,"))
   Serial.hex(Cell,2) 
   Serial.tx(",")
   Serial.str(stringPtr) 
   CR

Pub CellGet(Cell)
{{
  Gets the specified cell's integer value (no text or decimals) in Excel  
  to be accepted by the BASIC Stamp                                       
  PLX-DAQ String: CELLGET,D5                                             
  Note that CellSet works only with hex values for columns A to F         
 ┌────────────────────────────────────────────────┐                       
 │ X := PDAQ.CellGet($A3)                         │                       
 └────────────────────────────────────────────────┘                       
}}
   Serial.rxflush
   Serial.str(string("CELL,GET,"))
   Serial.hex(Cell,2)
   CR
   return Serial.RxDecTime(500)

Pub Msg(stringptr)
{{
  Sets a text message in the PLX-DAQ control          
  PLX-DAQ String: MSG,hello                           
 ┌────────────────────────────────────────────────┐    
 │ PDAQ.Msg(string("Hello"))                      │    
 └────────────────────────────────────────────────┘    
}}
    Serial.str(string("MSG,"))
    Serial.str(stringptr)
    CR

Pub CR
{{
  Sends a carriage return (ASCII 13)
  PDAQ.CR
}}  
   Serial.tx(13)
   CR_Flag := True


Pub DownLoadGet
{{
 Returns the value of the DumpData checkbox back to the BASIC Stamp  
 PLX-DAQ String: DOWNLOAD,GET                                       
 DumpGet returns a True/False condition                          
┌────────────────────────────────────────────────┐                
│ IF PDAQ.DownLoadGet == False                   │                
└────────────────────────────────────────────────┘                
}}
    Serial.rxflush
    Serial.str(string("DOWNLOAD,GET",13))
    if Serial.RxDecTime(500) > 0
      return true
    else
      return false   

Pub DownLoadSet(value)
{{
 Sets the Dump Data check box to checked (true) or unchecked (false) 
 PLX-DAQ String: DOWNLOAD,SET,0                             
 DownLoad accepts a true/false                            
┌────────────────────────────────────────────────┐        
│ PDAQ.DownLoadSet(True)       'sets state       │        
└────────────────────────────────────────────────┘        
}}
   If Value
     Serial.str(string("DOWNLOAD,SET,1"))
   else
     Serial.str(string("DOWNLOAD,SET,0"))
   CR  

Pub DownloadLabel(stringptr)
{{
 Sets the User1 checkbox in the control to string specified  
 PLX-DAQ String: DOWNLOAD,LABEL,Check me!                      
┌────────────────────────────────────────────────┐           
│ PDAQ.DownloadLabel(String("Check me!"))        │           
└────────────────────────────────────────────────┘           
}}
   Serial.str(string("DOWNLOAD,LABEL,"))
   Serial.str(stringptr)
   CR


Pub StoredSet(value)
{{
 Sets the Dump Data check box to checked (true) or unchecked (false) 
 PLX-DAQ String: STORED,SET,0                             
 Accepts a true/false                            
┌────────────────────────────────────────────────┐        
│ PDAQ.StoredSet(True)     'sets state           │        
└────────────────────────────────────────────────┘        
}}
   If Value
     Serial.str(string("STORED,SET,1"))
   else
     Serial.str(string("STORED,SET,0"))
   CR                           

Pub StoredGet
{{
 Returns the value of the DumpData checkbox back to the BASIC Stamp  
 PLX-DAQ String: STORED,GET                                       
 Returns a True/False condition                          
┌────────────────────────────────────────────────┐                
│ IF PDAQ.StoredGet == False                     │                
└────────────────────────────────────────────────┘                
}}
    Serial.rxflush
    Serial.str(string("STORED,GET",13))
    if Serial.RxDecTime(500) > 0
      return true
    else
      return false 

Pub StoredLabel(stringptr)
{{
 Sets the User1 checkbox in the control to string specified  
 PLX-DAQ String: STORED,LABEL,Check me!                      
┌────────────────────────────────────────────────┐           
│ PDAQ.StoredLabel(String("Check me!"))          │           
└────────────────────────────────────────────────┘           
}}
   Serial.str(string("Stored,LABEL,"))
   Serial.str(stringptr)
   CR
Pub USER1Label(stringptr)
{{
 Sets the User1 checkbox in the control to string specified  
 PLX-DAQ String: USER1,LABEL,Check me!                      
┌────────────────────────────────────────────────┐           
│ PDAQ.User1Label(String("Check me!"))           │           
└────────────────────────────────────────────────┘           
}}
   Serial.str(string("USER1,LABEL,"))
   Serial.str(stringptr)
   CR

Pub USER1Set(value)
{{
 Sets the USER1 check box to checked  
 PLX-DAQ String: USER1,SET,0                             
 User1Set accepts a true/false                            
┌────────────────────────────────────────────────┐        
│ PDAQ.User1Set(True)      'sets state           │        
└────────────────────────────────────────────────┘        
}}
   
   If Value
     Serial.str(string("USER1,SET,1"))
   else
     Serial.str(string("USER1,SET,0"))
   CR  

Pub USER1Get
{{
 Returns the value of the USER1 checkbox back 
 PLX-DAQ String: USER1,GET                                       
 User1Get returns a True/False condition                          
┌────────────────────────────────────────────────┐                
│ IF PDAQ.User1Get == False                      │                
└────────────────────────────────────────────────┘                
}}
    Serial.rxflush
    Serial.str(string("USER1,GET",13))
    if Serial.RxDecTime(500) > 0
      return true
    else
      return false 

Pub USER2Label(stringptr)
{{
 Sets the User2 checkbox in the control to string specified  
 PLX-DAQ String: USER2,LABEL,Check me!                      
┌────────────────────────────────────────────────┐           
│ PDAQ.User2Label(String("Check me!"))           │           
└────────────────────────────────────────────────┘           
}}
   Serial.str(string("USER2,LABEL,"))
   Serial.str(stringptr)
   CR

Pub USER2Set(value)
{{
 Sets the USER2 check box to checked (1) or unchecked (0) 
 PLX-DAQ String: USER2,SET,0                             
 User2Set accepts a true/false                            
┌────────────────────────────────────────────────┐        
│ PDAQ.User2Set(True)      'sets state           │        
└────────────────────────────────────────────────┘        
}}
   If Value
     Serial.str(string("USER2,SET,1"))
   else
     Serial.str(string("USER2,SET,0"))
   CR  

Pub USER2Get
{{
 Returns the value of the USER2 checkbox back 
 PLX-DAQ String: USER2,GET                                       
 User2Get returns a True/False condition                          
┌────────────────────────────────────────────────┐                
│ IF PDAQ.User2Get == False                      │                
└────────────────────────────────────────────────┘                
}}
    Serial.rxflush
    Serial.str(string("USER2,GET",13))
    if Serial.RxDecTime(500) > 0
      return true
    else
      return false 

PUB Pause(mS)
  waitcnt(clkFreq/1000 * ms + cnt)