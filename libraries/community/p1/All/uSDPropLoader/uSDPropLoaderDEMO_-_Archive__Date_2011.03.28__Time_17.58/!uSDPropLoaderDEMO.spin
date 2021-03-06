{{
=================================================================================================
  File....... uSDPropLoaderDemo
  Purpose.... Load firmware (bin) from uSD & send to another Prop to boot
               
  Author..... MacTuxLin (Kenichi Kato)
               -- see below for terms of use
  E-mail..... MacTuxLin@gmail.com
  Started.... 24 Mar 2011
  Updated....
        24 Mar 2011
                1. Started
        25 Mar 2011
                1. Completed but needed to test in office
        26 Mar 2011
                1. Does not work in DevBoard on BB
                2. Created this DEMO that's meant for driver uSDPropLoader
        28 Mar 2011
                1. Solved the problem that causes Synth.spin not to function properly.

Hardware Setup:

    ┌────────────┐                                      ┌────────────┐
    │            │                                      │            │
    │            │                                      │            │
    │   Master   │                                      │  Sub-Prop  │
    │    Prop    │                                      │            │
    │            │                                      │            │
    │            │                                      │            │
    │        P8  │--------------------------------------│XI          │
    │            │                                      │            │
    │            │                                      │            │
    │            │                                      │            │
    │        P16 │--------┬-----------------------------│P31         │
    │        P17 │--------│--------┬--------------------│P30         │    3v3
    │        P18 │--------│--------│--------┬-----------│Res      BOE│---┘
    │            │        10k     10k      1m        │            │
    │            │       Gnd      Gnd      Gnd          │            │
    │            │                                      │            │
    │            │                                      │            │
    │        P11 │---LED-┐               ┌-LED----│P15         │
    └────────────┘         Gnd             Gnd          └────────────┘                                                                               


For Sub-Prop code, refer to the file p1.spin
============================================
1. Binary file, p1.bin, is basically to blink LED connected on P11.
2. Please ensure when you copy the binary file, it is in 8.3 format. 

=================================================================================================
}}
CON
  '--- --- --- --- --- ---  
  'System - Command
  '--- --- --- --- --- ---  
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001   = _ConClkFreq / 1_000
  _Us_001   = _ConClkFreq / 1_000_000
  

  '--- --- --- --- --- ---
  '--- Inter-Prop Comm
  '--- --- --- --- --- ---
  _freq         = 5_000_000    '5mhz frequency pin output
  _freqPin      = 08  


  '--- --- --- --- --- ---
  '--- Prop Loading to Prop 2
  '--- --- --- --- --- ---
  _p2P30        = 17
  _p2P31        = 16
  _p2Res        = 18
  

  '--- --- --- --- --- ---
  '--- Storage Hardware Setting
  '--- --- --- --- --- ---
  _sd_DO        = 12 
  _sd_CLK       = 13 
  _sd_DI        = 14 
  _sd_CS        = 15 
  _sd_WP        = -1 ' -1 ifnot installed.
  _sd_CD        = -1 ' -1 ifnot installed.
  _statuspin    = 11  ' Status LED pin number.
  '--- --- --- --- --- ---

  '--- --- --- --- --- ---  
  'RTC
  '--- --- --- --- --- ---  
  _rtc_DAT = 29    ' -1 ifnot installed.
  _rtc_CLK = 28    ' -1 ifnot installed.




OBJ
  '--- --- --- --- ---  
  'CPU Loader Section
  '--- --- --- --- ---
  Loader        : "uSDPropLoader_0_1.spin"  

  '--- --- --- --- ---  
  'Inter-CPU Comm Section
  '--- --- --- --- ---  
  ClockGen      : "Synth.spin"      'object that generates the 5mhz clock.
   


PUB Main | tempStr

  ClockGen.Synth("A",_freqPin, _freq)
  waitcnt(cnt + clkfreq/10)


  '--- --- --- --- --- 
  '--- Init uSDPropLoader Drivers 
  '--- --- --- --- ---
  Loader.Start(_sd_DO, _sd_CLK, _sd_DI, _sd_CS, _sd_WP, _sd_CD, _rtc_DAT, _rtc_CLK)

 
  '--- --- --- --- --- 
  '--- Hardware Init 
  '--- --- --- --- --- 
  DIRA[_statuspin]~~
  OUTA[_statuspin]~~
  Pause(500)

  Loader.Connect(_p2Res, _p2P31, _p2P30, 1, Loader#LoadRun, String("p1.bin"))


  Pause(2000)
  Loader.Stop
  
  
  repeat   'Keep the main prop alive



PRI Pause(ms) | t
{{Delay program ms milliseconds}}
  t := cnt - 1088                                               ' sync with system counter
  repeat (ms #> 0)                                              ' delay must be > 0
    waitcnt(t += _MS_001)
