\ 2016-04-18  FDA  changed for ProSnap ProMini rev. 13
\ copyright 2016 by Franklin Amador
\ hw layout
\ arduino | atmega328p                | ProtoSnap ProMini with future NovaREM parts
\      D0 |        PD0   rx	      	  |   Tx-0    (FTDI)
\      D1 |        PD1   tx	      	  |   Rx-I    (FTDI)
\      D2 |        PD2   int0	      |   bz      (buzzer)
\      D3 |        PD3   int1  oc2b   |   rredled
\      D4 |        PD4   t0	      	  |   sw2	  (future)
\      D5 |        PD5   t1    oc0b   |   rgrnled
\      D6 |        PD6         oc0a   |   rbluled
\      D7 |        PD7		          |   sw1     (switch)
\ 		  |
\      D8 |        PB0    icp	      |   rIRled	  (future)
\      D9 |        PB1         oc1a   |	  lredled (future)
\     D10 |        PB2    ss   oc1b   |   lgrnled (future)
\     D11 |        PB3    mosi oc2a   |   lredled (future)
\     D12 |        PB4    miso	      |   lIRled    (future)
\     D13 |        PB5    sck	      |	  Led0	  (default)
\ 		  |
\      A0 |        PC0    adc0	      |   rlight   (photo cell w rled)
\      A1 |        PC1    adc1	      |   llight   (Future IR Photo Cell w lled)
\      A2 |        PC2    adc2	      |   
\      A3 |        PC3    adc3	      |   
\      A4 |        PC4    adc4  sda   |   
\      A5 |        PC5    adc5  scl   |
\
\ Note: "$" to indicate hexadecimal, "%" for binary and "&" for decimal numbers FORTH 2012
\

decimal
\ --- Variables -----------------------------------------------
variable 1delay 0 1delay !
variable mode 0 mode !
variable submode 0 submode !
variable submax_mode 0 submax_mode !
variable sensitivity 0 sensitivity !
variable scalardelay 0 scalardelay !
10 constant max_mode

\  --- Structure ------------------------------------------------
begin-structure set
	field: set.cuetype
	field: set.rate
	field: set.number
	field: set.intensity
end-structure

set buffer: unit

begin-structure user
	field: user.cuetype
	field: user.rate
	field: user.number
	field: user.intensity
end-structure

user buffer: custom
\ --- Port Assignments -----------------------------------------------
PORTB 0 portpin: rIRled
PORTB 1 portpin: lredled
PORTB 2 portpin: lgrnled
PORTB 3 portpin: lbluled
PORTB 4 portpin: lIRled
PORTB 5 portpin: Led0

PORTC 0 portpin: rlight
PORTC 1 portpin: llight

PORTD 2 portpin: bz
PORTD 3 portpin: rbluled
PORTD 4 portpin: sw2
PORTD 5 portpin: rgrnled
PORTD 6 portpin: rredled
PORTD 7 portpin: sw1

\ --- Port Configurations: Initiliaze
: init
  20 1delay !
  10 unit set.rate !
  10 unit set.number ! 
   1 unit set.cuetype !
   1 scalardelay !
   1 sensitivity !
  rIRled high rIRled pin_output
  lredled high lredled pin_output
  lgrnled high lgrnled pin_output
  lbluled high lbluled pin_output
  lIRled high lIRled pin_output
  Led0 low Led0 pin_output
  
  adc.init
  rlight adc.init.pin
  llight adc.init.pin
  
  bz low bz pin_output
  rbluled high rbluled pin_output
  sw2 high sw2 pin_input
  rgrnled high rgrnled pin_output
  rredled high rredled pin_output
  sw1 high sw1 pin_input
;
\ --- Messages -------------------------------------------------
: msg_quit
  ." press switch 1 (Button) to quit" cr 
;
: unit.delay ( -- )
	unit set.rate @ scalardelay @ * ms ;
;
\ --- Debounce sw1 ----------6----------------------------------
: sw1? ( -- true|false )
  sw1 pin_low? if       \ if switch1 pressed
    &20 ms              \ { wait a little
    sw1 pin_low? if     \   if switch1 still pressed
      -1                \   { "true" on stack
    else                \   }else
      0                 \   { "false on stack
    then                \   }
  else                  \ }else
    0                   \ { "false" on stack
  then                  \ }
;
\ --- Debounce sw2 (future) --------------------------------------
: sw2? ( -- true|false )
  sw2 pin_low? if       \ if switch1 pressed
    &20 ms              \ { wait a little
    sw2 pin_low? if     \   if switch1 still pressed
      -1                \   { "true" on stack
    else                \   }else
      0                 \   { "false on stack
    then                \   }
  else                  \ }else
    0                   \ { "false" on stack
  then                  \ }
;
\ --- buzzer ------------------------------------------------
\ 2 ms T_period =^= 500 Hz
: buzz ( cycles -- )
  0 ?do bz low 1ms bz high 1ms loop
;

: buzzer ( rate -- )
  100 * dup dup  buzz 2 / ms buzz
;

\ --- light sensor ------------------------------------------
: .rlight.
	rlight analog_read 4 u.r
;
: .llight
	llight analog_read 4 u.r
;
\ --- Test with LED ------------------------------------------
: Test.LED ( cycles -- )
  0 ?do lgrnled low rgrnled low 50 ms lgrnled high rgrnled high 50 ms loop 
;
\ --- sw2 Mode Change ----------------------------------------
: sw2?mode ( current_submode max_mode -- Updated_submode)
	submax_mode !
	submode !
	begin
		sw2? if
			submode @ 1+
			dup submax_mode @ > if drop 0 then 
			drop dup submode !
			. cr
		then
		
		\ wait some
		1delay @ 5 * ms
		key? 
	until
	key drop submode @	
;
\ --- Test Cues ---------------------------------------------
: TestCues 
	unit set.number @ 
	unit set.cuetype @ 
	\ create case for 0 thru 9 for different cue types
	case	\ Off:     left led	right led   buzz    On:	       left led         right led    	buzz
	 0	of  noop endof
	 1	of  0 ?do bz low  unit.delay bz high unit.delay loop endof
	 2	of  0 ?do rgrnled low  unit.delay
				  rgrnled high unit.delay loop endof
	 3	of  0 ?do rgrnled low   bz low  unit.delay
				  rgrnled high 	bz high unit.delay loop endof
	 4	of  0 ?do lgrnled low	unit.delay
				  lgrnled high	unit.delay loop endof
	 5	of  0 ?do lgrnled low  bz low   unit.delay
				  lgrnled high bz high	unit.delay loop endof
	 6	of  0 ?do lgrnled low 	rgrnled low  unit.delay 
	              lgrnled high	rgrnled high unit.delay loop endof
	 7	of  0 ?do lgrnled low 	rgrnled low  bz low  unit.delay 
	              lgrnled high	rgrnled high bz high unit.delay loop endof
	 8	of  0 ?do lgrnled high 	rgrnled low  unit.delay 
	              lgrnled low	rgrnled high unit.delay loop endof
	 9	of  0 ?do lgrnled high	rgrnled low  bz low  unit.delay 
	              lgrnled low	rgrnled high bz high unit.delay loop endof
	endcase
;
\ --- Dreamer ---------------------------------------------
: Dreamer ( -- )
;
\ --- Start Dreamer ----------------------------------------
: Start ( -- )
	TestCues
	Dreamer
;
\ --- Modes -------------------------------------------------
: Mode0 ( -- )   					\ Off unit in sleep mode

; 
: Mode1 ( -- ) 							\ User Adjustable Sleep Settings
	custom user.cuetype @   unit set.cuetype !
	custom user.rate @      unit set.rate !
	custom user.number @    unit set.number !
	custom user.intensity @ unit set.intensity !
	Start 
; 
: Mode2 ( -- ) 							\ Light Sleep Settings
	6 unit set.cuetype !
	2 unit set.rate !
	2 unit set.number !
	2 unit set.intensity !
	Start 
; 
: Mode3 ( -- )  						\ Medium Sleep Settings
	6 unit set.cuetype !
	2 unit set.rate !
	6 unit set.number !
	4 unit set.intensity !
	Start 
; 
: Mode4 ( -- )  						\ Deep Sleep Settings
	7  unit set.cuetype !
	2  unit set.rate !
	10 unit set.number !
	5  unit set.intensity !
	Start 
; 
: Mode5 ( -- ) 							\ Set cue numbers (0 to 254)
	custom user.number @ 	255 sw2?mode custom user.number !
	TestCues
;
: Mode6 ( -- ) 							\ Set cue intensity (0 to 10)
	custom user.intensity @ 11  sw2?mode custom user.intensity !
	TestCues
;
: Mode7 ( -- ) 							\ Set cue numbers (0 to 10)
	custom user.rate @ 	11  sw2?mode custom user.rate !
	TestCues
;
: Mode8 ( -- ) 							\ Set cue Type (0 to 8)
	custom user.cuetype @ 	11   sw2?mode custom user.cuetype !
	TestCues
;
: Mode9 ( -- ) 							\ Set Adjustment Mode (0 to 10) 
	sensitivity @ 		11  sw2?mode sensitivity !
;

\ --- REM Main Routine -------------------------------------------------
: NovaREM ( selector -- )
	Start
	0 mode !
	20 1delay !
	100 Test.LED
	
	begin
		
		sw1? if
		  mode @ 1+
		  dup max_mode > if drop 0 then 
		  dup mode !
		  . cr
		then
		
		case
		 0	of  ." Mode 0 - Sleep" 			Mode0 endof
		 1	of  ." Mode 1 - Adjustable Setting" 	Mode1 endof
		 2	of  ." Mode 2 - Light Sleep" 		Mode2 endof
		 3	of  ." Mode 3 - Medium Sleep" 		Mode3 endof
		 4	of  ." Mode 4 - Deep Sleep" 		Mode4 endof
		 5	of  ." Mode 5 - Cue Flashes" 		Mode5 endof
		 6	of  ." Mode 6 - Intensity" 		Mode6 endof
		 7	of  ." Mode 7 - Rate" 			Mode7 endof
		 8	of  ." Mode 8 - Type" 			Mode8 endof
		 9	of  ." Mode 9 - Adjustable Mode" 	Mode9 endof
		endcase
		
		\ wait some
		1delay @ 5 * ms
		key? 
		
	until
	key drop
 ;

