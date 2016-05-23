\ --- analog digital converter -------------------------------
\ --- adc ---
25 constant ADCH
24 constant ADCL

: or!   dup c@ rot or swap c! ;

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
  ADSC_MSK ADCSRA or!
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