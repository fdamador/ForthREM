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
\ --- Structure ------------------------------------------------
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

decimal
\ --- Variables -----------------------------------------------
variable 1delay 0 1delay !
variable mode 0 mode !
variable submode 0 submode !
variable submax_mode 0 submax_mode !
variable sensitivity 0 sensitivity !
variable scalardelay 0 scalardelay !

\ --- Dreamer Variables ---------------------------------------
variable sleepdelay 0 sleepdelay !
variable rsensor 0 rsensor !
variable lsensor 0 lsensor !
variable CueCount 0 CueCount !
variable Reset 0 Reset !
variable alarm 0 alarm !

\ --- Constant ------------------------------------------------
  10 constant max_mode
  20 1delay !
  10 unit set.rate !
  10 unit set.number ! 
   1 unit set.cuetype !
   1 scalardelay !
   1 sensitivity !
   
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

\ --- Port Configurations: Initilize ----------------------------------
: init
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
\ --- Timers ---------------------------------------------------
: unit.delay ( -- )
	unit set.rate @ scalardelay @ * ms ;
;
\ --- Debounce sw1 --------------------------------------------
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
: buzz ( cycles -- ) \ 2 ms T_period =^= 500 Hz
  0 ?do bz low 1ms bz high 1ms loop
;
: buzzer ( rate -- ) \ buzzer start
  100 * dup dup  buzz 2 / ms buzz
;
\ --- light sensor ------------------------------------------
: .rlight ( -- analog out ) \ read right sensor
	rlight analog_read 4 u.r
;
: .llight ( -- analog out ) \ read left sensor
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
: TestCues ( -- )
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
: init.dreamer ( -- )
	.rlight rsensor ! .llight lsensor !
	unit.delay 
;
: sensor.scale ( n1 n2 - bool)
	- abs unit set.intensity @ * 100 >
;
: sensor.test ( -- True/False )
	.rlight rsensor sensor.scale
	.llight lsensor sensor.scale
	or
;
: mode.change ( -- true/false)
	mode @ dup 0= swap 4 > and
;
: dreamalarm ( -- )

;
: alarm.clock? ( -- )

;
: Dreamer ( -- )
	0 CueCount !
	1 Reset !
	begin
		init.dreamer
		sw1? if sleepdelay @ 10 + sleepdelay ! then
		1 CueCount +!
		begin
			mode.change if 0 Reset ! then
			icount @ sleepdelay @ > if
				sensor.test if 
					1 CueCount +!
					( record time need CueCount[32] array )
					TestCues
					mode.change sw1? or if 0 Reset ! then
					alarm if dreamalarm	then
				else
					60000 ms
				then
			else
				1 icount +!
				60000 ms
			then
		Reset 0= until
	alarm.clock? Reset or 0= until
;
\ --- Start Dreamer ----------------------------------------
: Start ( -- )
	TestCues
	Dreamer
;
\ --- Modes -------------------------------------------------
: Mode0 ( -- )  \ Off unit in sleep mode

; 
: Mode1 ( -- ) 	\ User Adjustable Sleep Settings
	custom user.cuetype @   unit set.cuetype !
	custom user.rate @      unit set.rate !
	custom user.number @    unit set.number !
	custom user.intensity @ unit set.intensity !
	Start 
; 
: Mode2 ( -- ) 	\ Light Sleep Settings
	6 unit set.cuetype !
	2 unit set.rate !
	2 unit set.number !
	2 unit set.intensity !
	Start 
; 
: Mode3 ( -- )  \ Medium Sleep Settings
	6 unit set.cuetype !
	2 unit set.rate !
	6 unit set.number !
	4 unit set.intensity !
	Start 
; 
: Mode4 ( -- )  \ Deep Sleep Settings
	7  unit set.cuetype !
	2  unit set.rate !
	10 unit set.number !
	5  unit set.intensity !
	Start 
; 
: Mode5 ( -- ) 	\ Set cue numbers (0 to 254)
	custom user.number @ 255 sw2?mode custom user.number !
	TestCues
;
: Mode6 ( -- ) 	\ Set cue intensity (0 to 10)
	custom user.intensity @ 11 sw2?mode custom user.intensity !
	TestCues
;
: Mode7 ( -- ) 	\ Set cue numbers (0 to 10)
	custom user.rate @ 11 sw2?mode custom user.rate !
	TestCues
;
: Mode8 ( -- ) 	\ Set cue Type (0 to 8)
	custom user.cuetype @ 11 sw2?mode custom user.cuetype !
	TestCues
;
: Mode9 ( -- ) 	\ Set Adjustment Mode (0 to 10) 
	sensitivity @ 11 sw2?mode sensitivity !
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
		 0	of  ." Mode 0 - Sleep"				Mode0 endof
		 1	of  ." Mode 1 - Adjustable Setting"		Mode1 endof
		 2	of  ." Mode 2 - Light Sleep"			Mode2 endof
		 3	of  ." Mode 3 - Medium Sleep"			Mode3 endof
		 4	of  ." Mode 4 - Deep Sleep"			Mode4 endof
		 5	of  ." Mode 5 - Cue Flashes"			Mode5 endof
		 6	of  ." Mode 6 - Intensity"			Mode6 endof
		 7	of  ." Mode 7 - Rate"				Mode7 endof
		 8	of  ." Mode 8 - Type"				Mode8 endof
		 9	of  ." Mode 9 - Adjustable Mode"		Mode9 endof
		endcase
		
		\ wait some
		1delay @ 5 * ms
		key? 
		
	until
	key drop
 ;
 
\ --------------- Date & Time Task -------------------------------------
\ create task space

$20 $20 0 task: t:date&time   

variable seconds
variable minutes
variable hours
variable day
variable month
variable year

: reset.clock ( -- )
  0 seconds !
  0 minutes !
  0 hours !
  1 days !
  1 month !
  2016 year !
;
: day.month ( -- )
	 1 days ! 1 month +!
;
: check.days ( day -- )
	days @ u< if day.month then
;
: leapyear ( -- )
	year @ 4 mod 0= year @ 100 mod 0= and year @ 400 mod 0= or 
	if
		29 check.days
	else	
		28 check.days
	then
;
\ runs every second
: job-date&time
	begin
		1 seconds +!
		seconds @ 59 > if 0 seconds ! 1 minutes +! then
		minutes @ 59 > if 0 minutes ! 1 hours +! then
		hours @ 24 > if 0 hours ! 1 day +! then
		month @ case
			0 of reset.clock endof
			1 of 31 check.days endof
			2 of leapyear endof
			3 of 31 check.days endof
			4 of 30 check.days endof
			5 of 31 check.days endof
			6 of 30 check.days endof
			7 of 31 check.days endof
			8 of 31 check.days endof
			9 of 30 check.days endof
			10 of 31 check.days endof
			11 of 30 check.days endof
			12 of 31 check.days endof
			13 of 1 month ! 1 year +! endof
		endcase
		1000 ms
	again
;
\ set up the task
: setup-date&time
  t:date&time tcb>tid activate
  \ words after this line are run in new task
  job-date&time
;

\ setup and start the task "date/time"
: datetime-turnkey
  t:date&time task-init			\ create TCB in RAM
  0 seconds !            		\ more code for minutes etc
  131 timer0.ini timer0.start   \ 8 MHz quartz
  \ 6 timer0.init timer0.start  \ 16 MHz quartz
  \ insert task into task list
  setup-date&time
  \ activate tasks job
  onlytask                    
  t:date&time tcb>tid alsotask
  multi                        	\ start multitasking
;
\ ----------- activate multitasking -------------------------------------
 : run-turnkey ( -- )
	\ Task-1: NovaREM
	\ Task-2: DateTime
	applturnkey
	datetime-turnkey
;
 \ ----------- Start on Power up ----------------------------------------
 ' NovaREM is applturnkey
 ' run-turnkey is turnkey
 