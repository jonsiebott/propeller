{{
*****************************************
* Single Pin Sigma Delta Driver      v1 *
* Author: Beau Schwabe                  *
* Copyright (c) 2013 Parallax           *
* See end of file for terms of use.     *
*****************************************


 History:
                            Version 1 - 07-16-2013      initial release


Schematic:                            

                                          Vdd
                                           
              2.2k                         │      Note: Potentiometers are ideal for this type of ADC
          ┌─────────── Analog Input ── 10k
          │   1k                           │
IO Pin ──┻───────┐                      
                   0.047uF             Vss
                    
                   Vss

              
Theory of Operation:
 
A key feature with this sigma-delta ADC is that the drive pin is only an output for a brief amount of time, while the
remainder of the time it is an input and used as the feedback pin.  A Typical Sigma Delta configuration will have the
Drive pin always set as an output and driven either HIGH or LOW while another pin is always an input and used as
Feedback.  This technique combines the two methods so that only one pin is necessary.
                            

}}

PUB Stop

PUB Start(PinLocation,Samples,SampleAddress)
    _ADC :=  |<PinLocation
    _Samples := Samples
    cognew(@PASM,SampleAddress)

DAT
              org
PASM          andn      dira,    _ADC           'Set ADC pin to an input
ADC_Start     mov       ADC_accumulator,#0      'Clear ADC_Sample
              mov       Counter,_Samples        'Set number of itterations
ADC_loop      test      _ADC,   ina wz          'Read ADC pin ; set Z flag
              muxz      outa,   _ADC            'Preset ADC pin to opposite state of ADC pin reading
              or        dira,   _ADC            'Set ADC pin to an output
              nop                               'small delay for charging/discharging
              andn      dira,   _ADC            'Set ADC pin to an input
       if_nz  add       ADC_accumulator, #1     'Increment ADC_accumulator only if cap needed charging
              djnz      Counter, #ADC_loop      'next itteration
              wrlong    ADC_accumulator,par     'write ADC_accumulator back to Spin variable "sample"
              jmp       #ADC_Start              'read next ADC sample

ADC_accumulator         long      0             'Holds ADC value
Counter                 long      0             'Temporary varible to hold _Samples             
_ADC                    long      0             'ADC Pin Mask
_Samples                long      0             'Resolution of the ADC ; number of samples
              

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