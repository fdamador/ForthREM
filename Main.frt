\ 2016-04-18  EW  changed for ProSnap ProMini rev. 13
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
\     D11 |        PB3    mosi oc2a   |   lbluled (future)
\     D12 |        PB4    miso	      |   lIRled    (future)
\     D13 |        PB5    sck	      |	  Led0	  (default)
\ 		  |
\      A0 |        PC0    adc0	      |   rlight   (photo cell w rled)
\      A1 |        PC1    adc1	      |   llight   (Future IR Photo Cell w lled)
\      A2 |        PC2    adc2	      |   
\      A3 |        PC3    adc3	      |   
\      A4 |        PC4    adc4  sda   |   
\      A5 |        PC5    adc5  scl   |

\ --- Include Libraries -----------------------------------------------
include lib/multitask.frt
include lib/case.frt
include lib/ms.frt
include lib/bitnames.frt

decimal

\ --- Port Assignments -----------------------------------------------
\PORTB 0 portpin: rIRled
\PORTB 1 portpin: lredled
\PORTB 2 portpin: lgrnled
\PORTB 3 portpin: lbluled
\PORTB 4 portpin: lIRled
PORTB 5 portpin: Led0

PORTD 2 portpin: bz
PORTD 3 portpin: rredled
\PORTD 4 portpin: sw2
PORTD 5 portpin: rgrnled
PORTD 6 portpin: rbluled
PORTD 7 portpin: sw1

PORTC 0 portpin: rlight
\PORTC 1 portpin: llight

\ --- Variables -----------------------------------------------
variable sleepsettings 4 cells allot
5 buffer: sleepsettings
variable 1delay 20 1delay !
variable mode 0 mode !
10 constant max_mode

: msg_quit
  ." press switch 1 (D7) to quit" cr
;


\ --- switches -----------------------------------------------
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

\ --- buzzer -------------------------------------------------

\ 2 ms T_period =^= 500 Hz
: buzz ( cycles -- )
  0 ?do bz low 1ms bz high 1ms loop
;

\ --- analog digital converter -------------------------------
\ --- adc ---
\ pin>pos
\     convert bitmask of portpin: back to value (bitposition)
: pin>pos       ( pinmask portaddr -- pos )
  drop          ( -- pinmask )
  log2          ( -- pos_of_most_significant_bit )
;

: adc.init ( -- )
  \ ADMUX
  \ A_ref is NOT connected externally
  \ ==> need to set bit REFS0 in register ADMUX
  [ 1 5 lshift      \ ADLAR
    1 6 lshift or   \ REFS0
  ] literal ADMUX c!
  \ ADCSRA
  [ 1 7 lshift      \ ADEN   ADC enabled
    1 2 lshift or   \ ADPS2  prescaler = 128
    1 1 lshift or   \ ADPS1  .
    1          or   \ ADPS0  .
  ] literal ADCSRA c!
;
: adc.init.pin ( bitmask portaddr -- )
  over over high
  pin_input
;
  
1 6 lshift constant ADSC_MSK \ ADStartConversion bitmask
: adc.start
  \ start conversion
  ADSC_MSK ADCSRA dup c@ rot or swap c! 
;
: adc.wait
  \ wait for completion of conversion
  begin
    ADCSRA c@ ADSC_MSK and 0=
  until
;
: adc.channel! ( channel -- )
  7 and                 \ clip channel to 0..7
  ADMUX c@ 7 invert and \ read ADMUX, clear old channel
  or                    \ add new channel
  ADMUX c!              \ write
;
: adc.get10 ( channel -- a )
  adc.channel! adc.start adc.wait
\ 10 bit
  ADCL c@
  ADCH c@ 8 lshift + 6 rshift
;
: adc.get ( channel -- a )
  adc.channel! adc.start adc.wait
\ 8 bit
  ADCH c@
;

\ --- convert Right Light Sensor reading --------------------------
: .rlight
  rlight pin>pos adc.get10 . cr
;

: Mode0 () sleep ;
: Mode1 () ;
: Mode2 () ;
: Mode3 () ;
: Mode4 () ;
: Mode5 () ;
: Mode6 () ;
: Mode7 () ;
: Mode8 () ;
: Mode9 () ;

: NovaREM ( selector -- )
	init
	0 mode !
	20 1delay !
	
	begin
		
		sw1? if
		  mode @ 1+
		  dup max_mode > if drop 0 then 
		  dup mode !
		  . cr
		then
		
		case
		 0         	 of  ." Mode 0 - Off" 					Mode0 endof
		 1		     of  ." Mode 1 - Adjustable Setting" 	Mode1 endof
		 2           of  ." Mode 2 - Light Sleep" 			Mode2 endof
		 3           of  ." Mode 3 - Medium Sleep" 			Mode3 endof
		 4           of  ." Mode 4 - Deep Sleep" 			Mode4 endof
		 5           of  ." Mode 5 - Cue Flashes" 			Mode5 endof
		 6           of  ." Mode 6 - Intensity" 			Mode6 endof
		 7           of  ." Mode 7 - Rate" 					Mode7 endof
		 8           of  ." Mode 8 - Type" 					Mode8 endof
		 9           of  ." Mode 9 - Adjustable Mode" 		Mode9 endof
		endcase
		
		\wait some
		1delay @ 5 * ms
		key? 
	until
	key drop
 ;
 
 ; Turnkey-app 0 begin NovaREM 1000 ms until :  
