		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

; =================================
;
; External Labels
;
; =================================

	EXTERN	apply_mod_values
	EXTERN	process_mod_knob
	EXTERN	process_tempo_knob
	EXTERN	process_steps_knob
	EXTERN	update_sequencer_from_grain
	EXTERN	read_pot
	EXTERN	read_buttons_refresh_leds
	EXTERN	update_step_leds
	EXTERN	fetch_note_velocity
	EXTERN	nth_init
	EXTERN	update_step_flags_from_buttons
	EXTERN	update_mod_flags_from_buttons
	EXTERN	update_oscillator_pitch
	EXTERN	update_oscillator_gate
	EXTERN	send_cc_from_knobs
	EXTERN	send_cc_from_step_buttons
	EXTERN	send_cc_from_sliders

; =================================
;
; Boot Vector
;
; =================================

reset_code		code	0x00
		goto	start

; ==================================================================
; ==================================================================
;
; Main Program
;
; ==================================================================
; ==================================================================

main_code		code
start

; initialize the PIC and variables
		call	nth_init

; this loop repeats forever during normal operation.
main_loop
; read 4 buttons and refresh 4 LEDs
		call	read_buttons_refresh_leds
; count poll cycles for use in button debouncing
		incf	POLL_COUNT,f
; update step flags
		call	update_step_flags_from_buttons
; update step LEDs 0-7
		call	update_step_leds
; update mod flags and LEDs
		call	update_mod_flags_from_buttons
; read one potentiometer
		call	read_pot
; increment the pot counter.  wrap if > 13
		incf	ANALOG_POLL,f
		movlw	D'14'
		subwf	ANALOG_POLL,w
		btfsc	STATUS,Z
		clrf	ANALOG_POLL
; move mod knob state to mod "virtual pots"
		call	process_mod_knob
; move knob states to synth parameters
		call	apply_mod_values
; move knob states to sequencer parameters
		bcf	INTCON,GIE
		call	process_tempo_knob
		bsf	INTCON,GIE

		bcf	INTCON,GIE
		call	process_steps_knob
		bsf	INTCON,GIE
; update oscillator frequencies
		call	update_oscillator_pitch
; update oscillator gate and send MIDI notes
		call	update_oscillator_gate
; send MIDI CC from knob activity
		call	send_cc_from_knobs
; send MIDI CC from sliders and step buttons only in midi controller mode
		btfss	SPECIAL_MODE_FLAGS,3
		goto	main_loop

		call	send_cc_from_sliders
		call	send_cc_from_step_buttons

		goto	main_loop

		end
