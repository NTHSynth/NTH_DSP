		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

; =================================
;
; External Labels
;
; =================================

	EXTERN	process_tempo_knob
	EXTERN	process_steps_knob
	EXTERN	update_sequencer_from_grain
	EXTERN	read_pot
	EXTERN	read_from_data_eeprom
	EXTERN	write_to_data_eeprom
	EXTERN	read_buttons_refresh_leds
	EXTERN	channel_select_mode
	EXTERN	special_blink_leds

; ==================================================================
; ==================================================================
;
; NTH Initialization
;
; ==================================================================
; ==================================================================

init_code		code
	GLOBAL	nth_init
nth_init

; =================================
;
; PIC Initialization
;
; =================================

; Configure Timer 0 and PORTB pull-ups
		banksel	OPTION_REG
		movlw	B'00000001'
		movwf	OPTION_REG
		banksel	WPUB
		movlw	B'11110000'
		movwf	WPUB
; Configure the ADC
		banksel	ADCON1
		movlw	B'01100000'
		movwf	ADCON1
; Init output ports
		clrf	BSR
		movlw	B'11111111'
		movwf	PORTA
		movlw	B'11111111'
		movwf	PORTB
		movlw	B'11000000'
		movwf	PORTC
		movwf	GHOST_C
		movlw	B'00000000'
		movwf	PORTD
		movlw	B'00000000'
		movwf	PORTE
		banksel	ANSELA
		movlw	B'00101111'
		movwf	ANSELA
		movlw	B'00000111'
		movwf	ANSELB
		clrf	ANSELD
		movlw	B'00000111'
		movwf	ANSELE
; Configure the internal clock
		banksel	OSCCON
		movlw	B'11110000'
		movwf	OSCCON
; Configure port A tri-states.
		banksel	TRISA
		movlw	B'01101111'
		movwf	TRISA
; Configure port B tri-states.
		movlw	B'11110111'
		movwf	TRISB
; Configure port C tri-states.
		movlw	B'00000000'
		movwf	TRISC
; Configure port D tri-states.
		movlw	B'00000000'
		movwf	TRISD
; Configure port E tri-states.
		movlw	B'11111111'
		movwf	TRISE

; =================================
;
; Variable Initialization
;
; =================================

		clrf	BSR

		movlw	D'3'
		movwf	COUNTER_24PPQ
		clrf	TX_BYTES_LEFT

		movlw	0x7F
		movwf	TX_NOTE_ON_NUM
		movwf	TX_NOTE_OFF_NUM
		movwf	TX_NOTE_ON_VEL

		movlw	0x08
		movwf	AMP_LEVEL

; STATE_FLAGS
; default state: gate on, external control off.
;		movlw	B'10000000'
; default state: gate off, external control off.
		movlw	B'00000000'
		movwf	STATE_FLAGS
; STATE_FLAGS_2 & 3: MIDI stuff.
		clrf	STATE_FLAGS_2
		clrf	STATE_FLAGS_3
		clrf	SPECIAL_MODE_FLAGS
		clrf	POLL_COUNT

		clrf	ANALOG_POLL

		clrf	LED_STATES_0
		clrf	LED_STATES_1
		clrf	LED_STATES_2

		movlw	B'00000001'
		movwf	FUNCTION_FLAGS

		clrf	BUTTON_STATES_0
		clrf	BUTTON_STATES_1
		clrf	BUTTON_STATES_2
		clrf	BUTTON_PREV_0
		clrf	BUTTON_PREV_1
		clrf	BUTTON_PREV_2

		clrf	POT_STATE_8_PREV
		movlw	0xff
		clrf	POT_STATE_A_PREV
		clrf 	POT_STATE_A

		movlw	0x20
		movwf	POT_STATE_0
		movwf	POT_STATE_1
		movwf	POT_STATE_2
		movwf	POT_STATE_3
		movwf	POT_STATE_4
		movwf	POT_STATE_5
		movwf	POT_STATE_6
		movwf	POT_STATE_7

		movlw	D'0'
		movwf	STEP
		movwf	STEP_EIGHTH
		movlw	D'8'
		movwf	NUM_GRAINS
		movlw	B'00000001'
		movwf	STEP_BIT
		movlw	B'11111111'
		movwf	STEP_FLAGS

		movlw	0x30
		movwf	PARTY_PRNG_V0
		movwf	NOISE_PRNG_V0
		movlw	0x45
		movwf	PARTY_PRNG_V1
		movwf	NOISE_PRNG_V1
		clrf	PARTY_GRAIN_COUNT


		movlw	0xFF
		movwf	ACTIVE_WAVEFORM+0
		movwf	ACTIVE_WAVEFORM+1
		movwf	ACTIVE_WAVEFORM+2
		movwf	ACTIVE_WAVEFORM+3
		clrf	ACTIVE_WAVEFORM+4
		clrf	ACTIVE_WAVEFORM+5
		clrf	ACTIVE_WAVEFORM+6
		clrf	ACTIVE_WAVEFORM+7

		clrf	PITCH_ENV
		clrf	PITCH_ENV_POT
		clrf	AMP_ENV
		clrf	AMP_ENV_POT
		clrf	DETUNE_POT
		clrf	DETUNE
		clrf	WAVEFORM_POT
		clrf	WAVEFORM

		clrf	OSCA_PHASE
		clrf	OSCB_PHASE

		clrf	MIDI_CLOCK_COUNT
		clrf	GRAIN_COUNT
		movlw	D'128'
		movwf	POT_STATE_C
		movwf	POT_STATE_C_PREV
		movlw	D'1'
		movwf	GRAIN_INCREMENT

; clear "ignore previous value" flags.
		movlw	0x01
		movwf	FSR0H
		movlw	CC_SEND_FLAGS
		movwf	FSR0L
		movlw	D'48'
		movwf	TEMP
		movlw	0x01
init_cc_sent_flags_loop
		movwi	INDF0++
		decfsz	TEMP,f
		goto	init_cc_sent_flags_loop

; set "virtual pot" raw values to 0
		movlw	0x01
		movwf	FSR0H
		movlw	VIRTUAL_ADC_VALUE_0
		movwf	FSR0L
		movlw	0x08
		movwf	TEMP
		movlw	0x00
init_virtual_pots_loop
		movwi	INDF0++
		decfsz	TEMP,f
		goto	init_virtual_pots_loop

; send CC from button states if in midi controller mode.
		movlw	0xFF
		movwf	CC_BUTTON_TOGGLES
		movwf	CC_LED_INIT_FLAGS

; =================================
;
; Configure Timer 2
;
; =================================

		banksel	T2CON
		movlw	B'00000100'
		movwf	T2CON
		movlw	D'255'
		movwf	PR2
		banksel	PIE1
		bsf		PIE1,TMR2IE
		clrf	BSR

; =================================
;
; Check if the user is holding down a button at start-up.
;
; =================================

; read all 12 buttons
		call	read_buttons_refresh_leds
		call	read_buttons_refresh_leds
		call	read_buttons_refresh_leds
channel_select_check
; is the user pressing the Gliss button?  Enter channel select mode.
		btfsc	BUTTON_STATES_2,3
		call	channel_select_mode
; read the MIDI channel setting from EEPROM
		clrf	TEMP
		call	read_from_data_eeprom
		movwf	MIDI_CHANNEL
; did the user select a special mode?
special_mode_check
; special modes 8 not implemented.
		movlw	B'00000111'
		andwf	BUTTON_STATES_1,f
; move button states to LED states
		movfw	BUTTON_STATES_0
		movwf	LED_STATES_0
		movfw	BUTTON_STATES_1
		movwf	LED_STATES_1
; combine button states into special mode flags
		swapf	BUTTON_STATES_1,w
		iorwf	BUTTON_STATES_0,w
		movwf	SPECIAL_MODE_FLAGS
; if no special mode selected, skip to normal operation.
		movfw	SPECIAL_MODE_FLAGS
		bz	re_init_buttons
; if special modes selected, confirm them with some blinking
		call	special_blink_leds
		call	special_blink_leds
		call	special_blink_leds
		call	special_blink_leds
		call	special_blink_leds
; special mode 7 is just one-shot mode
		btfsc	SPECIAL_MODE_FLAGS,6
		bsf	STATE_FLAGS,2

re_init_buttons
; reset the button states to prepare for normal operation.
		clrf	BUTTON_STATES_0
		clrf	BUTTON_STATES_1
		clrf	BUTTON_STATES_2
		clrf	BUTTON_PREV_0
		clrf	BUTTON_PREV_1
		clrf	BUTTON_PREV_2

; =================================
;
; Sweep the LEDs.  Looks pretty and serves as a LED test.
; At the same time, intilize the ADC value for each pot.
;
; =================================

		call	led_test_and_init_analog_input_data


; =================================
;
; Serial Port (MIDI) Setup
;
; =================================

; Set up the baud rate generator
; 32 MHz / 31.25 kHz / 16 - 1 = 63
; 32 MHz / [16 (63 + 1)] = 31250
		banksel	SPBRGL
		movlw	D'63'
		movwf	SPBRGL
; Set the transmit control bits
		movlw	B'00100110'
		movwf	TXSTA
; Set the receive control bits
		movlw	B'10010000'
		movwf	RCSTA
; Enable Rx interrupts
		banksel	PIE1
		bsf	PIE1,RCIE
; Flush the FIFO
		banksel	RCREG
		movfw	RCREG
		movfw	RCREG
; Flush out any bytes & errors sitting around
		banksel	RCSTA
		bcf	RCSTA,4
		bsf	RCSTA,4
		clrf	BSR

; =================================
;
; Final init before normal operation begins.
;
; =================================

; clear select lines
		movlw	B'11111111'
		movwf	PORTA
		movwf	PORTB

; midi controller mode?  skip the sequencer setup
		btfsc	SPECIAL_MODE_FLAGS,3
		goto	init_midi_controller_mode

; set up MIDI sync
		bsf	STATE_FLAGS,3
		bsf	STATE_FLAGS,6
		clrf	TMR0

; set up sequencer starting position
		call	process_tempo_knob
		call	process_steps_knob
; assume reverse tempo
		decf	NUM_GRAINS,w
		movwf	GRAIN_COUNT
; check for forward tempo
		btfsc	TEMPO,7
		clrf	GRAIN_COUNT

		call	update_sequencer_from_grain

init_enable_interrupts
; Enable Interrupts
		movlw	B'11100000'
		movwf	INTCON

		return

init_midi_controller_mode
; clear LED0-7
		clrf	LED_STATES_0
		clrf	LED_STATES_1
; clear the step toggles
		clrf	STEP_FLAGS
; Disable RX interrupts
		banksel	PIE1
		bcf	PIE1,RCIE
		clrf	BSR

; Enable interrupts without Timer 0
		movlw	B'11000000'
		movwf	INTCON

		return

; =================================
;
; Make a pretty LED sweep as an LED self-test.
; Meanwhile, record initial values for the pot inputs.
;
; =================================

led_test_and_init_analog_input_data
		movlw	B'00001000'
		movwf	LED_STATES_1
		call	test_delay_and_read_pots
		movlw	B'00001100'
		movwf	LED_STATES_1
		call	test_delay_and_read_pots
		movlw	B'00001110'
		movwf	LED_STATES_1
		call	test_delay_and_read_pots
		movlw	B'00001111'
		movwf	LED_STATES_1
		call	test_delay_and_read_pots
		movlw	B'00001000'
		movwf	LED_STATES_0
		call	test_delay_and_read_pots
		movlw	B'00001100'
		movwf	LED_STATES_0
		call	test_delay_and_read_pots
		movlw	B'00001110'
		movwf	LED_STATES_0
		call	test_delay_and_read_pots
		movlw	B'00001111'
		movwf	LED_STATES_0
		call	test_delay_and_read_pots
		movlw	B'00001000'
		movwf	LED_STATES_2
		call	test_delay_and_read_pots
		movlw	B'00001100'
		movwf	LED_STATES_2
		call	test_delay_and_read_pots
		movlw	B'00001110'
		movwf	LED_STATES_2
		call	test_delay_and_read_pots
		movlw	B'00001111'
		movwf	LED_STATES_2
		call	test_delay_and_read_pots
; all leds now "on"
		movlw	B'00000111'
		movwf	LED_STATES_1
		call	test_delay_and_read_pots
		movlw	B'00000011'
		movwf	LED_STATES_1
		call	test_delay_and_read_pots
		movlw	B'00000001'
		movwf	LED_STATES_1
		call	test_delay_and_read_pots
		movlw	B'00000000'
		movwf	LED_STATES_1
		call	test_delay_and_read_pots
		movlw	B'00000111'
		movwf	LED_STATES_0
		call	test_delay_and_read_pots
		movlw	B'00000011'
		movwf	LED_STATES_0
		call	test_delay_and_read_pots
		movlw	B'00000001'
		movwf	LED_STATES_0
		call	test_delay_and_read_pots
; duplicate 3 lines for smooth sweep
		movlw	B'00000001'
		movwf	LED_STATES_0
		call	test_delay_and_read_pots

		movlw	B'00000111'
		movwf	LED_STATES_2
		call	test_delay_and_read_pots
		movlw	B'00000011'
		movwf	LED_STATES_2
		call	test_delay_and_read_pots
		movlw	B'00000001'
		movwf	LED_STATES_2
		call	test_delay_and_read_pots
; now led 1 and 9 only are "on"
		call	test_delay_and_read_pots
		call	test_delay_and_read_pots
		call	test_delay_and_read_pots
		call	test_delay_and_read_pots
		call	test_delay_and_read_pots
		call	test_delay_and_read_pots
		call	test_delay_and_read_pots
led_test_complete

; move the current pot values over to the "previous" values
		movlw	0x01
		movwf	FSR0H
		movlw	0x02
		movwf	FSR1H
		movlw	RAW_ADC_VALUE_0
		movwf	FSR0L
		movwf	FSR1L
		movlw	D'16'
		movwf	TEMP
pot_init_loop
		lsrf	INDF0,w
		movwf	INDF1
		movlw	0x02
		addwf	FSR0L,f
		addwf	FSR1L,f
		decfsz	TEMP,f
		goto	pot_init_loop

		bsf	STATE_FLAGS_3,1
		return

; =================================
;
; 
;
; =================================
	GLOBAL	test_delay
test_delay_and_read_pots
		call	read_pot
; increment the pot counter
		incf	ANALOG_POLL,f
		movlw	D'14'
		subwf	ANALOG_POLL,w
		btfsc	STATUS,Z
		clrf	ANALOG_POLL
test_delay
		movlw	0x0B
		movwf	TEMPO_COUNTER_H
		movlw	0xff
		movwf	TEMPO_COUNTER_L
test_delay_loop
		clrf	PORTC
		movlw	B'11111111'
		movwf	PORTA
		movlw	B'11110111'
		movwf	PORTB
		movfw	LED_STATES_2
		movwf	PORTC
		nop
		nop
		nop
		nop
		clrf	PORTC
		movlw	B'11111111'
		movwf	PORTB
		movlw	B'01111111'
		movwf	PORTA
		movfw	LED_STATES_0
		movwf	PORTC
		nop
		nop
		nop
		nop
		clrf	PORTC
		movlw	B'11111111'
		movwf	PORTB
		movlw	B'11101111'
		movwf	PORTA
		movfw	LED_STATES_1
		movwf	PORTC
		nop
		nop
		nop
		nop

		decfsz	TEMPO_COUNTER_L,f
		goto	test_delay_loop
		decfsz	TEMPO_COUNTER_H,f
		goto	test_delay_loop

		return

; =================================
;
;
; =================================

special_mode_setup
		movlw	0x08
		movwf	TEMP2
; flash LED0 to signal user
special_mode_0_loop
;		bsf	LED_STATES_0,0
		movfw	SPECIAL_MODE_FLAGS
		movwf	LED_STATES_0
		movlw	0x08
		movwf	TEMP
		call	test_delay
		decfsz	TEMP,f
		goto	$-2

;		bcf	LED_STATES_0,0
		clrf	LED_STATES_0
		movlw	0x08
		movwf	TEMP
		call	test_delay
		decfsz	TEMP,f
		goto	$-2

		decfsz	TEMP2,f
		goto	special_mode_0_loop

		return

		end
