		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

; =================================
;
; External Labels
;
; =================================

	EXTERN	test_delay

user_io		code

; ****************************
;
; read_buttons_refresh_leds
;
; simultaneously refresh LEDs and read buttons
;
; each call refreshes 4 LEDs and reads from 4 switches
;
; automatically cycles to next switch/LED group on each call:
; requires 3 calls to refresh all 12 LEDs / read all 12 buttons
; 
; ****************************
	GLOBAL	read_buttons_refresh_leds
read_buttons_refresh_leds
; check which of 3 select phases we are in.
; if previous select pulse was on select 2, send a pulse on select 0
		btfsc	PORTB,3
		goto	send_select_pulse_1_or_2

send_select_pulse_0
; deactivate previous select pulse
		movlw	B'11111111'
		movwf	PORTB
; set LED data for this select
		movfw	GHOST_C
		andlw	B'11110000'
		iorwf	LED_STATES_0,w
		movwf	GHOST_C
		movwf	PORTC
; activate this select pulse
		movlw	B'01111111'	
		movwf	PORTA
; skip read on 7 of 8 select pulses to debounce
		movlw	B'00000111'
		andwf	POLL_COUNT,w
		btfss	STATUS,Z
		return
; wait for the switch data to set up (fast instruction clock!)
		nop
		nop
; read the switch data
		swapf	PORTB,w
		movwf	TEMP
		comf	TEMP,w
		andlw	B'00001111'
; store the new switch data
		movwf	BUTTON_STATES_0
		return

send_select_pulse_1_or_2
; if previous select pulse was on Select 0, send select pulse on Select 1
		btfsc	PORTA,7
		goto	send_select_pulse_2
send_select_pulse_1
; deactivate previous select pulse
		movlw	B'11111111'	
		movwf	PORTA
;		bsf		PORTA,7
; set LED data for this select
		movfw	GHOST_C
		andlw	B'11110000'
		iorwf	LED_STATES_1,w
		movwf	GHOST_C
		movwf	PORTC
; activate this select pulse
		movlw	B'11101111'	
		movwf	PORTA
; skip read on 7 of 8 polls to debounce switches
		movlw	B'00000111'
		andwf	POLL_COUNT,w
		btfss	STATUS,Z
		return
; wait for the switch data to set up (fast instruction clock!)
		nop
		nop
; read the switch data
		swapf	PORTB,w
		movwf	TEMP
		comf	TEMP,w
		andlw	B'00001111'
; store the new switch data
		movwf	BUTTON_STATES_1
		return

send_select_pulse_2
; deactivate previous select pulse
		movlw	B'11111111'	
		movwf	PORTA
; set LED data for this select
		movfw	GHOST_C
		andlw	B'11110000'
		iorwf	LED_STATES_2,w
		movwf	GHOST_C
		movwf	PORTC
; activate this select pulse
		movlw	B'11110111'	
		movwf	PORTB
; skip read on 7 of 8 polls to debounce switches.
		movlw	B'00000111'
		andwf	POLL_COUNT,w
		btfss	STATUS,Z
		return
; store the old switch states.
; These two instructions allow the switch data to set up.
		nop
		nop
; read the switch data
		swapf	PORTB,w
		movwf	TEMP
		comf	TEMP,w
		andlw	B'00001111'
; store the new switch data
		movwf	BUTTON_STATES_2
		return

; ****************************
;
; Use mod buttons to update mod LED states and flag bits for
; mod functions.
;
; New mod selections also result in a CC refresh.
;
; ****************************
	GLOBAL	update_mod_flags_from_buttons
update_mod_flags_from_buttons
; store old value
		movfw	FUNCTION_FLAGS
		movwf	TEMP2
; process button activity
		movfw	BUTTON_STATES_2
		xorwf	BUTTON_PREV_2,w
; w now contains change flags
		andwf	BUTTON_STATES_2,w
; w now contains new button presses--quit if none occurred.
		movwf	TEMP
		bz	update_mod_flags_store_previous
; check if new button presses cancel only function
		xorwf	FUNCTION_FLAGS,w
		bz	zero_functions
; if new button presses, write new function flags
		movfw	BUTTON_STATES_2
		movwf	FUNCTION_FLAGS	
		movwf	LED_STATES_2
		goto	update_mod_flags_store_previous
zero_functions
		clrf	FUNCTION_FLAGS
		clrf	LED_STATES_2
update_mod_flags_store_previous
		movfw	BUTTON_STATES_2
		movwf	BUTTON_PREV_2
; set send CC flags for any newly-selected mod parameters.
		movfw	FUNCTION_FLAGS
		xorwf	TEMP2,w
		andwf	FUNCTION_FLAGS,w
		movwf	TEMP2

		movlw	0x01
		movwf	FSR0H
		movlw	CC_SEND_FLAGS+D'32'
		movwf	FSR0L
		movlw	0x01
		btfsc	TEMP2,0
		movwf	INDF0
		incf	FSR0L,f
		incf	FSR0L,f
		btfsc	TEMP2,1
		movwf	INDF0
		incf	FSR0L,f
		incf	FSR0L,f
		btfsc	TEMP2,2
		movwf	INDF0
		incf	FSR0L,f
		incf	FSR0L,f
		btfsc	TEMP2,3
		movwf	INDF0

		return

; ****************************
;
; Use step buttons to update step flag bits
;
; ****************************
	GLOBAL	update_step_flags_from_buttons
update_step_flags_from_buttons
; update step flags as a result of any button presses 0-3
		movfw	BUTTON_STATES_0
		xorwf	BUTTON_PREV_0,w
; w now contains change flags
		andwf	BUTTON_STATES_0,w
; w now contains new button presses.  toggle those steps.
		xorwf	STEP_FLAGS,f
; update "previous" state so we can detect next change.
		movfw	BUTTON_STATES_0
		movwf	BUTTON_PREV_0
; update step flags as a result of any button presses 4-7
		movfw	BUTTON_STATES_1
		xorwf	BUTTON_PREV_1,w
; w now contains change flags
		andwf	BUTTON_STATES_1,w
; w now contains new button presses.  toggle those steps.
		movwf	TEMP
		swapf	TEMP,w
		xorwf	STEP_FLAGS,f
; update "previous" state so we can detect next change.
		movfw	BUTTON_STATES_1
		movwf	BUTTON_PREV_1

		return

; ****************************
;
; update slider LEDs depending on what step is active and if it is gated
;
; ****************************
	GLOBAL	update_step_leds
update_step_leds
; midi controller mode?  exit.
		btfsc	SPECIAL_MODE_FLAGS,3
		return

update_leds_0
; first 4 step LEDs
		movfw	STEP_BIT
		andwf	STEP_FLAGS,w
		movwf	LED_STATES_0
; clear if under MIDI note control and notes are off.
		btfss	STATE_FLAGS,1
		goto	update_leds_1
		btfss	STATE_FLAGS_2,1
		clrf	LED_STATES_0
update_leds_1
; second 4 step LEDs
		swapf	STEP_BIT,w
		movwf	TEMP
		swapf	STEP_FLAGS,w
		andwf	TEMP,w
		movwf	LED_STATES_1

		return

; ****************************
;
; check for change to pot 8 (mod knob) and apply value to
; the mode "virtual pots"
;
; ****************************
	GLOBAL	process_mod_knob
process_mod_knob
; copy raw ADC result to "virtual" ADC results for active parameters.
		movlw	0x01
		movwf	FSR1H
		movwf	FSR0H
		movlw	RAW_ADC_VALUE_0+0x10
		movwf	FSR1L
update_virtual_mod_pot
		btfss	FUNCTION_FLAGS,0
		goto	update_virtual_env_pot
		movlw	VIRTUAL_ADC_VALUE_0+0x00
		movwf	FSR0L
		moviw	INDF1++
		movwi	INDF0++
		moviw	INDF1--
		movwf	INDF0
update_virtual_env_pot
		btfss	FUNCTION_FLAGS,1
		goto	update_virtual_detune_pot
		movlw	VIRTUAL_ADC_VALUE_0+0x02
		movwf	FSR0L
		moviw	INDF1++
		movwi	INDF0++
		moviw	INDF1--
		movwf	INDF0
update_virtual_detune_pot
		btfss	FUNCTION_FLAGS,2
		goto	update_virtual_gliss_pot
		movlw	VIRTUAL_ADC_VALUE_0+0x04
		movwf	FSR0L
		moviw	INDF1++
		movwi	INDF0++
		moviw	INDF1--
		movwf	INDF0
update_virtual_gliss_pot
		btfss	FUNCTION_FLAGS,3
		goto	update_virtual_pots_complete
		movlw	VIRTUAL_ADC_VALUE_0+0x06
		movwf	FSR0L
		moviw	INDF1++
		movwi	INDF0++
		moviw	INDF1--
		movwf	INDF0
update_virtual_pots_complete
; check for change to 4-bit value.
		movfw	POT_STATE_8
		subwf	POT_STATE_8_PREV,w
		btfsc	STATUS,Z
		return
; move pot value to W, and update previous value
		movfw	POT_STATE_8
		movwf	POT_STATE_8_PREV
; move to active mod parameters
		btfsc	FUNCTION_FLAGS,0
		movwf	WAVEFORM_POT
		btfsc	FUNCTION_FLAGS,1
		movwf	AMP_ENV_POT
		btfsc	FUNCTION_FLAGS,2
		movwf	DETUNE_POT
		btfsc	FUNCTION_FLAGS,3
		movwf	PITCH_ENV_POT

		return

; ****************************
;
; use the mod virtual pot values to control synth parameters
;
; ****************************
	GLOBAL	apply_mod_values
apply_mod_values
; detune
		call	fetch_detune
		movwf	DETUNE
; pitch envelope
		lsrf	PITCH_ENV_POT,w
		movwf	PITCH_ENV
; amplitude envelope
		lsrf	AMP_ENV_POT,w
		movwf	AMP_ENV
; waveform
		lsrf	WAVEFORM_POT,w
		movwf	WAVEFORM
		addwf	WAVEFORM,w
		addwf	WAVEFORM,w
		addwf	WAVEFORM,w
		addwf	WAVEFORM,w
		addwf	WAVEFORM,w
		addwf	WAVEFORM,w
		addwf	WAVEFORM,w
		movwf	FSR0L
		movlw	0x9C
		movwf	FSR0H
		moviw	INDF0++
		movwf	ACTIVE_WAVEFORM+0
		moviw	INDF0++
		movwf	ACTIVE_WAVEFORM+1
		moviw	INDF0++
		movwf	ACTIVE_WAVEFORM+2
		moviw	INDF0++
		movwf	ACTIVE_WAVEFORM+3
		moviw	INDF0++
		movwf	ACTIVE_WAVEFORM+4
		moviw	INDF0++
		movwf	ACTIVE_WAVEFORM+5
		moviw	INDF0++
		movwf	ACTIVE_WAVEFORM+6
		moviw	INDF0++
		movwf	ACTIVE_WAVEFORM+7

		return

; ****************************
;
; grab the secondary oscillator detune value based on knob position
; as half tones relative to primary oscillator pitch in W
;
; ****************************
	GLOBAL	fetch_detune
fetch_detune
		movfw	DETUNE_POT
		brw
		retlw	D'0'
		retlw	D'1'
		retlw	D'1'
		retlw	D'2'
		retlw	D'2'
		retlw	D'3'
		retlw	D'3'
		retlw	D'4'

		retlw	D'4'
		retlw	D'4'
		retlw	D'5'
		retlw	D'5'
		retlw	D'5'
		retlw	D'6'
		retlw	D'6'
		retlw	D'6'

		retlw	D'7'
		retlw	D'7'
		retlw	D'7'
		retlw	D'8'
		retlw	D'8'
		retlw	D'8'
		retlw	D'9'
		retlw	D'9'

		retlw	D'9'
		retlw	D'10'
		retlw	D'10'
		retlw	D'10'
		retlw	D'11'
		retlw	D'11'
		retlw	D'11'
		retlw	D'12'

; ****************************
;
; determines clock division when NTH sequencer is MIDI clock slave
;
; ****************************
fetch_grain_increment
		brw
		retlw	D'248'
		retlw	D'252'
		retlw	D'252'
		retlw	D'254'
		retlw	D'254'
		retlw	D'255'
		retlw	D'255'
		retlw	D'255'

		retlw	D'1'
		retlw	D'1'
		retlw	D'1'
		retlw	D'2'
		retlw	D'2'
		retlw	D'4'
		retlw	D'4'
		retlw	D'8'

; ****************************
;
; amplitude envelopes are represented as midi notes with varying
; velocity values.  These are the velocity values.
;
; ****************************
	GLOBAL	fetch_note_velocity
fetch_note_velocity
		brw
		retlw	0x00
		retlw	0x01
		retlw	0x02
		retlw	0x04
		retlw	0x08
		retlw	0x10
		retlw	0x20
		retlw	0x40
		retlw	0x7F

; ****************************
;
; alter sequencer behavior based on tempo knob input
;
; ****************************
	GLOBAL	process_tempo_knob
process_tempo_knob
; only incorporate knob setting if it has changed from previous poll.
; this prevents interference with a MIDI CC setting.
		movfw	POT_STATE_C
		subwf	POT_STATE_C_PREV,w
		bz	tempo_knob_unchanged
; knob setting changed
		movfw	POT_STATE_C
		movwf	POT_STATE_C_PREV
		movwf	TEMPO
tempo_knob_unchanged
; grain increment is -1 for reverse, +1 for forward.
		movlw	0xFF
		movwf	GRAIN_INCREMENT
		btfss	TEMPO,7
		goto	poll_clock_divider
		movlw	0x01
		movwf	GRAIN_INCREMENT

; update grain increment only if using midi sync
poll_clock_divider
		btfss	STATE_FLAGS,0
		goto	poll_skip_grain_increment

		movfw	TEMPO
		movwf	TEMP
		lsrf	TEMP,f
		lsrf	TEMP,f
		lsrf	TEMP,f
		lsrf	TEMP,w
		call	fetch_grain_increment
		movwf	GRAIN_INCREMENT
poll_skip_grain_increment
		return

; ****************************
;
; alter sequencer behavior based on tempo knob input
;
; ****************************
	GLOBAL	process_steps_knob
process_steps_knob
; midi note control?  skip this
		btfsc	STATE_FLAGS,1
		return
; check for change to knob position
		movfw	POT_STATE_A_PREV
		subwf	POT_STATE_A,w
		btfsc	STATUS,Z
		return
		movfw	POT_STATE_A
		movwf	POT_STATE_A_PREV
; grab 4 bits from pot state, calculate grains in seqeunce (steps x 8)
		lslf	POT_STATE_A,w
		movwf	TEMP
		lslf	TEMP,w
		andlw	B'11111000'
		addlw	D'8'
		movwf	NUM_GRAINS
skip_steps_knob
		return


; ****************************
;
; takes the current LED states and blinks them on and off.
; used to confirm channel selection or special mode selections at boot
; time.
;
; ****************************
	GLOBAL	special_blink_leds
special_blink_leds
		movlw	0x08
		movwf	TEMP4
		call	test_delay
		decfsz	TEMP4,f
		goto	$-2
		movfw	LED_STATES_0
		movwf	TEMP
		movfw	LED_STATES_1
		movwf	TEMP2
		movfw	LED_STATES_2
		movwf	TEMP3
		clrf	LED_STATES_0
		clrf	LED_STATES_1
		clrf	LED_STATES_2
		movlw	0x08
		movwf	TEMP4
		call	test_delay
		decfsz	TEMP4,f
		goto	$-2
		movfw	TEMP
		movwf	LED_STATES_0
		movfw	TEMP2
		movwf	LED_STATES_1
		movfw	TEMP3
		movwf	LED_STATES_2
		return


		end
