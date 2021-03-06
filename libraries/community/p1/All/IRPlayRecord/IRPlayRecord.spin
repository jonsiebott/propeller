{{
*****************************************
* 38KHz PWM IR Remote record/playback   *
* Author: Christopher Cantrell          *               
* See end of file for terms of use.     *               
*****************************************
}}
                
'' For the GP1UX311QS IR sensor. See:
'' http://www.ladyada.net/learn/sensors/ir.html

'' For the TV-B-Gone circuit and design see:
'' http://www.ladyada.net/make/tvbgone/design.html

'' For this project I built the TV-B-Gone and then pulled the micro controller
'' from its socket. I connected pin 5 of the micro's socket to IO port 7 of the
'' propeller demo board. I connected pin 4 of the micro's socket to the demo
'' board's ground (common ground). Thus I used the existing transistors and
'' 3V batteries of the TV-B-Gone project.

'' In this configuration, a 1 (high) on the output pin turns the LEDs *OFF* while
'' a 0 (low) on the output pin turns the LEDs *ON*. I burned out a set of LEDs
'' in development. Be careful.

'' I hooked the IR sensor's output to IO port 0 of the demo board. I hooked the
'' sensor's power and ground to the demo board.



'' This driver runs in a COG and watches a command block for command requests.
''   command  - non-zero command value. Returns to zero when the command is done
''   param    - additional parameters needed by some commands. Returns non-zero error status.
''   bufPtr   - pointer to buffer used by command

'' At startup the "param" must contain the I/O pin configuration: OUT<<8 | IN.
''   For example, my project has pin 0 connected to the sensor and pin 7 connected to the LED outputs.
''   I initialized the driver with "7<<8 | 0".

'' Command "1" : Record IR sequence
''   This command fills a buffer (pointed to by bufPtr) with pulse transition timing values.
''   Before the command starts the first word of the buffer must contain the max number of
''   words allowed to be written. When the command is complete the first word of the buffer
''   contains the actual number of words written.

'' Command "2" : Play IR sequence
''   This command plays out a buffer (pointed to by bufPtr) of previously recorded IR samples.
''   The first word of this buffer contains the number of samples to play.


'' This driver can also maintain a database of named-sequences. IR recordings are given names
'' and stored in a table and can be played back by name.

'' If you use these functions then you must set the "bufPtr" to point to the large database memory
'' before starting the driver. In this project I used an 8K database buffer. The first word of this
'' memory is the total size of the database.

'' Command "50" : Initialize the sequence database
''   This command sets the first word to "0002" thus initializing an empty table

'' Command "10" : Record a new named sequence.
''   The "bufPtr" points to a null terminated string to name the sequence.
''   The "param" contains the max number of samples to record.
''   This command records the IR sequences as in command "1" but appends the data to the table.

'' Command "20" : Plays a previously recorded named sequence.
''    The "bufPtr" points to a null terminated string -- the name of the sequence
''    This command finds a previously recorded sequence and plays it as in command "2".
''    The "param" is set to "1" on return if the sequence was not found

'' The sequence buffer database is organized as follows:

''   BM BL                 Current size of the buffer (1st byte MSB)
''   
''   NA NB NC ... NN 00    String bytes (null terminated)
''   SM SL                 Number of samples
''   SA SB ... SN          Samples
''   
''   NA NB NC ... NN 00    String bytes (null terminated)
''   SM SL                 Number of samples
''   SA SB ... SN          Samples
''   
''   NA NB NC ... NN 00    String bytes (null terminated)
''   SM SL                 Number of samples
''   SA SB ... SN          Samples
''   ...                             
                          
CON


'' For clock config of "xtal1 + pll16x" and a 5_000_000 crystal:
'' Clock runs at 80_000_000Hz.
'' 80_000_000 * 0.000_010 = 800 clocks
'' Thus a wait count of +800 is 10usecs
'' The written sample values are numbers of 10usec intervals
  resolution = 800

'' 65 ms is 65/.01 = 6500 10-usec-intervals
  maxPulse = 6500             


VAR

  long  cog          

PUB start(data) : okay

'' Start IRSensor driver - starts a cog
'' returns false if no cog available      ''

  stop
  okay := cog := cognew(@entry, data) + 1


PUB stop

'' Stop IR Sensor - frees a cog

  if cog
    cogstop(cog~ - 1)

DAT

entry
         mov       command,par             ' Could use "par" but easier to read code
         mov       paramError,command      ' Point to ...
         add       paramError,#4           ' ... param/error pointer
         mov       bufPtr,paramError       ' Point to ...
         add       bufPtr,#4               ' ... buffer pointer

         ' If using the sequence table functions
         rdlong    seqTable,bufPtr         ' Pointer to the sequence table buffer
         '
                  
         rdlong    tmp,paramError          ' Get the I/O pins
         mov       curSize,tmp             ' Use bottom byte ...
         and       curSize,#255            ' ... to pick ...
         shl       inputMask,curSize       ' ... input pin mask    
         shr       tmp,#8                  ' Use top byte ...
         shl       outputMask,tmp          ' ... to pick output pin mask
         add       CTR_VAL,tmp             ' Add pin number to the counter control value         

         mov       outa,outputMask         ' Make sure LED is off (a one)
         mov       dira,outputMask         ' Output pin as output ... all others input

         mov       ctra,CTR_VAL            ' Set output pinto ...
         mov       frqa,FRQ_VAL            ' ... 38KHz clock

         mov       tmp,#0                  ' Ready for ...
         wrlong    tmp,command             ' ... command requests

main     rdlong    tmp,command wz          ' Wait for a ...
   if_z  jmp       #main                   ' ... command


    ' If using the sequence table functions        
         cmp       tmp,#$10 wz
   if_z  jmp       #doSeqRec
         cmp       tmp,#$20 wz
   if_z  jmp       #doSeqPlay
         cmp       tmp,#$30 wz
   if_z  jmp       #doSeqFind
         cmp       tmp,#$40 wz
   if_z  jmp       #doSeqDel
         cmp       tmp,#$50 wz
   if_z  jmp       #doSeqInit
         '

         cmp       tmp,#2 wz               ' Is this a playback?
   if_z  jmp       #doPlayback             ' Yes ... do it
         cmp       tmp,#1 wz               ' Is this a record?         
  if_nz  mov       tmp,#99                 ' Error code "Invalid command"
  if_nz  jmp       #clearAndDone           ' No ... ignore this command

doRecord
         call      #serv_record            ' Call the record service
         mov       tmp,#0                  ' No error
         
clearAndDone
         wrlong    tmp,paramError          ' Write the return code
         mov       tmp,#0                  ' Signal the ...
         wrlong    tmp,command             ' ... end of processing                              
         jmp       #main                   ' Wait for next decode request

doPlayback
         call      #serv_play              ' Call the play routine
         mov       tmp,#0                  ' No error
         jmp       #clearAndDone           ' Tell user we are done


' Recording service:
'
' [bufPtr] contains the pointer to the buffer to fill. The first word of the buffer
' is the max number of samples (samples are words). After recording the first word
' contains the number of samples written to the buffer.                
'
serv_record                           
         rdlong    bufSize,bufPtr          ' This is the buffer to fill (size is 1st word)
         mov       dataPtr,bufSize         ' Next word starts the ...
         add       dataPtr,#2              ' ... buffer to fill

         rdbyte    maxSize,bufSize         ' Read ...
         add       bufSize,#1              ' ... two-byte ...
         shl       maxSize,#8              ' ... max buffer size. ...
         rdbyte    tmp,bufSize             ' ... This might not ...
         sub       bufSize,#1              ' ... be word ...
         add       maxSize,tmp             ' ... aligned (no rdword)

         mov       curSize,#0              ' Current number of words stored 
        
waitFirst        
         and       inputMask,ina wz,nr     ' Wait for the first low value ...             
  if_nz  jmp       #waitFirst              ' ... at start of transmission                  

         mov       tmp,cnt                 ' Calculate the first ...
         add       tmp,resol               ' ... resoultion interval
         
         mov       pulseCnt,#1             ' Init pulse count (we always wait 1)
         mov       curpul,leadpul          ' The leader-pulse can be very long
         
goHigh   waitcnt   tmp,resol               ' Wait until the next resolution interval
         and       inputMask,ina wz, nr    ' Wait for the input pin ...
  if_nz  jmp       #wentHigh               ' ... to go high 
         add       pulseCnt,#1             ' Still low ... count this interval
         cmp       pulseCnt,curpul wz,wc   ' Max pulse width reached (this would be an error)?
  if_ae  jmp       #done                   ' Yes ... done        
         jmp       #goHigh                 ' Keep waiting for a high

wentHigh mov       tmp2,pulseCnt           ' Write ...
         shr       tmp2,#8                 ' ... two-byte ...
         wrbyte    tmp2,dataPtr            ' ... sample ...
         add       dataPtr,#1              ' ... that might not be
         wrbyte    pulseCnt,dataPtr        ' ... word aligned ...
         add       dataPtr,#1              ' ... (no wrword)
         
         add       curSize,#1              ' Count the number of entries
         cmp       curSize,maxSize wz,wc   ' Reached the given end
  if_ae  jmp       #done                   ' Yes ... that's all we can do
         mov       pulseCnt,#1             ' Next pulse count

         mov       curpul,maxpul           ' From now on we timeout on a smaller pulse

goLow    waitcnt   tmp,resol               ' Wait until the next resolution interval    
         and       inputMask,ina wz, nr    ' Wait for the input pin ...
  if_z   jmp       #wentLow                ' ... to go low
         add       pulseCnt,#1             ' Still high ... count this interval
         cmp       pulseCnt,curpul wz,wc   ' Max pulse width reached (end of transmission)?
  if_ae  jmp       #done                   ' Yes ... done                                        
         jmp       #goLow                  ' Keep waiting for low
         
wentLow  mov       tmp2,pulseCnt           ' Write ...
         shr       tmp2,#8                 ' ... two-byte ...
         wrbyte    tmp2,dataPtr            ' ... sample ...
         add       dataPtr,#1              ' ... that might not be
         wrbyte    pulseCnt,dataPtr        ' ... word aligned ...
         add       dataPtr,#1              ' ... (no wrword)
         
         add       curSize,#1              ' Count the number of entries
         cmp       curSize,maxSize wz,wc   ' Reached the given end
  if_ae  jmp       #done                   ' Yes ... that's all we can do
         mov       pulseCnt,#1             ' Next pulse count            
         
         jmp       #goHigh                 ' Wait for the next high transition   

done     mov       tmp,curSize             ' Store number ...
         shr       tmp,#8                  ' ... of samples ...
         wrbyte    tmp,bufSize             ' ... might not ...
         add       bufSize,#1              ' ... be word aligned ...
         wrbyte    curSize,bufSize         ' ... (no wrword)

serv_record_ret
         ret 
                                                                  


' [bufPtr] contains the pointer to the buffer to play out. The first word of the buffer
' is the number of samples (samples are words) in the buffer.
'
serv_play

         ' We assume the IR-LED is wired so that a 1 turns it OFF and
         ' a 0 turns it ON.
         
         ' Setting output to 0 allows the clock to control (38KHz)
         ' Setting output to 1 forces the output to always 1 (LED off)

         rdlong    bufSize,bufPtr          ' This is the buffer to play (size is 1st word)
         mov       dataPtr,bufSize         ' Next word starts the ...
         add       dataPtr,#2              ' ... buffer to play

         rdbyte    maxSize,bufSize         ' Read ...
         add       bufSize,#1              ' ... two-byte ...
         shl       maxSize,#8              ' ... buffer size. ...
         rdbyte    tmp,bufSize             ' ... This might not ...
         sub       bufSize,#1              ' ... be word ...
         add       maxSize,tmp             ' ... aligned (no rdword)
                
         mov       curSize,#0              ' Current number of words played out                                                                                

         mov       tmp,cnt                 ' Calculate the first ...
         add       tmp,resol               ' ... resoultion interval
         
         mov       tmp2,outputMask         ' Start the pulses with an ON (0)

playLoop  
         xor       tmp2,outputMask         ' Change pulse polarity
         mov       outa,tmp2               ' Start the next pulse (38KHz:0 or off:1)  

         cmp       curSize,maxSize wz      ' Start of interval. Have we done them all?
  if_z   jmp       #doPlaybackDone         ' Yes ... out


         rdbyte    pulseCnt,dataPtr        ' Read ...
         add       dataPtr,#1              ' ... two-byte ...
         shl       pulseCnt,#8             ' ... sample. ...
         rdbyte    tmp3,dataPtr            ' ... This might not ...
         add       dataPtr,#1              ' ... be word ...
         add       pulseCnt,tmp3           ' ... aligned (no rdword)
                
         add       curSize,#1                         

pulseLoop                         
         waitcnt   tmp,resol               ' Wait the timing interval
         sub       pulseCnt,#1 wz,wc       ' All done?
  if_nz  jmp       #pulseLoop              ' No ... keep counting

         jmp       #playLoop               ' Next pulse    
 
doPlaybackDone
         
         mov       outa,outputMask         ' Set output to 1 (LED off)

serv_play_ret
         ret                      

command    long   0              ' Pointer to command
paramError long   0              ' Pointer to command/error
bufPtr     long   0              ' Pointer to buffer pointer

bufSize    long   0              ' Pointer to sample buffer size
dataPtr    long   0              ' Current sample data cursor
maxSize    long   0              ' Max size of sample input buffer
curSize    long   0              ' Current size of sample input buffer

inputMask  long   1              ' Pin number (shifted at start)
outputMask long   1              ' Pin number (shifted at start)

tmp        long   0              ' Misc use
tmp2       long   0              ' Misc use
tmp3       long   0              ' Misc use

pulseCnt   long   0              ' Current pulse count            

curpul     long   0              ' Current max-pulse wait time 
leadpul    long   $F0000000      ' Max pulse count for lead in (can be long)             
maxpul     long   maxPulse       ' Max pulse count ... considered timeout

resol      long   resolution     ' Offset for WAITCNT in the pulse counting

CTR_VAL    long  %00100_000 << 23 + 1 << 9 +  0 ' Change 0 to the pin number 
FRQ_VAL    long  $1f_2000


' -----------------------------------
' Here down only needed for the named-sequence functionality
' -----------------------------------

seqTable   long  0
ptr        long  0
ptr2       long  0

' The entries in the table may not be word-aligned as they contain the
' sequence names. These routines read and write words from the buffer
' without assuming word alignment.
'
readWordPtr
         rdbyte    tmp,ptr
         add       ptr,#1
         shl       tmp,#8
         rdbyte    tmp2,ptr
         add       ptr,#1
         add       tmp,tmp2
readWordPtr_ret
         ret
'
writeWordPtr
         mov       tmp2,tmp
         shr       tmp2,#8
         wrbyte    tmp2,ptr
         add       ptr,#1
         wrbyte    tmp,ptr
         add       ptr,#1
writeWordPtr_ret
         ret


         
' The top word in the table is the total size of the table (including the size)
doSeqInit  
         mov       tmp,#2                  ' Buffer is 2 ...
         mov       ptr,seqTable            ' ... btyes ...
         call      #writeWordPtr           ' ... the total size of the buffer

doSeqFind
doSeqDel
         mov       tmp,#99                 ' Invalid command     
         jmp       #clearAndDone           ' Tell user we are done
         

' bufPtr - name string 
doSeqPlay              
         mov       ptr,seqTable        ' Get the size ...
         call      #readWordPtr        ' ... of the table
         mov       tmp3,seqTable       ' Find the last ...
         add       tmp3,tmp            ' ... address + 1

doSP1    cmp       ptr,tmp3 wz, wc     ' Have we reached the end of the table?
  if_ae  mov       tmp,#1              ' Error status 1 "Not Found"
  if_ae  jmp       #clearAndDone       ' Yes ... ignore request

         rdlong    ptr2,bufPtr         ' Pointer to target string

doSPC    rdbyte    tmp,ptr             ' Get character from table name
         rdbyte    tmp2,ptr2           ' Get character from target name

         cmp       tmp,tmp2 wz         ' Are the characters the same?
   if_z  jmp       #doSPSame           ' Yes ... check for match

         cmp       tmp,#0 wz           ' Are we at the end of the table string?
doSP4
   if_z  jmp       #doSP3              ' Yes ... go skip the samples
         add       ptr,#1              ' Next in name
         rdbyte    tmp,ptr wz          ' Read next byte
         jmp       #doSP4              ' Keep looking for end

doSP3    add       ptr,#1              ' Skip terminator
         call      #readWordPtr        ' Read the sample size
         shl       tmp,#1              ' Count of words ... not bytes
         add       ptr,tmp             ' Skip the data
         jmp       #doSP1              ' Check the next word         

doSPSame cmp       tmp,#0 wz           ' End of both strings
   if_nz add       ptr,#1              ' Advance table-string
   if_nz add       ptr2,#1             ' Advance target-string
   if_nz jmp       #doSPC              ' No ... go try next entry
         
         add       ptr,#1              ' Skip terminator
         wrlong    ptr,bufPtr          ' Sample data
         
         call      #serv_play          ' Play the samples 

         mov       tmp,#0              ' No error
         jmp       #clearAndDone       ' Tell user we are done 
        

' bufPtr - name string
' param  - max size
doSeqRec 
         mov       ptr,seqTable        ' Start of table         
         call      #readWordPtr        ' Get the buffer size
         mov       ptr,seqTable        ' Skip to the end ...  
         add       ptr,tmp             ' ... of the buffer
         
         rdlong    tmp2,bufPtr         ' Pointer to string
doSR1    rdbyte    tmp,tmp2 wz         ' Copy ...
         add       tmp2,#1             ' ... string ...
         wrbyte    tmp,ptr             ' ... to ...
         add       ptr,#1
 if_nz   jmp       #doSR1              ' ... buffer

         wrlong    ptr,bufPtr          ' Set up the sample buffer
         
         rdlong    tmp,paramError      ' Max samples allowed         
         mov       tmp2,tmp            ' Wrte ...
         shr       tmp2,#8             ' ... max ...
         wrbyte    tmp2,ptr            ' ... to ...
         add       ptr,#1              ' ... sample ...
         wrbyte    tmp,ptr             ' ... buffer ...
         sub       ptr,#1              ' ... may not be word aligned

         call      #serv_record        ' Record the samples to the table
                                                                  
         add       ptr,#2              ' The number of the samples
         shl       curSize,#1          ' This is the number of words (double for bytes)
         add       ptr,curSize         ' New end of table
         sub       ptr,seqTable        ' New size
         
         mov       tmp,ptr             ' Write new ...
         mov       ptr,seqTable        ' ... size of ...
         call      #writeWordPtr       ' ... the sequence table

         mov       tmp,#0              ' No error
         jmp       #clearAndDone       ' Tell user we are done

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
                                                                          