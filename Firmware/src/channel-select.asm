		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

; =================================
;
; External Labels
;
; =================================

	EXTERN	read_pot
	EXTERN	read_buttons_refresh_leds
	EXTERN	special_blink_leds
	EXTERN	write_to_data_eeprom

channel_select	code
; ==================================================================
; ==================================================================
;
; continuosly read the steps knob and disply the MIDI channel
; setting on the LEDS.  When Gliss button release, store channel
; setting and resume operation.
;
; ==================================================================
; ==================================================================
	GLOBAL	channel_select_mode
channel_select_mode
; continuously check buttons and refresh LEDs
	call	read_buttons_refresh_leds
; continuously read Steps pot for channel selection
	movlw	0x08
	movwf	ANALOG_POLL
	call	read_pot
; update the LED states to reflect channel selection
	clrf	LED_STATES_2
	clrf	LED_STATES_1
	movlw	B'00000001'
	movwf	LED_STATES_0
	movwf	TEMP
	lsrf	POT_STATE_8,w
	andlw	B'00000111'
	movwf	TEMP2
	bz	channel_select_skip_shift
channel_select_shift_bits
	lslf	TEMP,f
	decfsz	TEMP2,f
	goto	channel_select_shift_bits
channel_select_skip_shift
	movfw	TEMP
	andlw	B'00001111'
	movwf	LED_STATES_0
	swapf	TEMP,w
	andlw	B'00001111'
	movwf	LED_STATES_1
	btfsc	POT_STATE_8,4
	bsf	LED_STATES_2,3
; check if the user has released the Gliss button
	btfsc	BUTTON_STATES_2,3
	goto	channel_select_mode
; if so, confirm the channel setting with some blinking
	call	special_blink_leds
	call	special_blink_leds
	call	special_blink_leds
	call	special_blink_leds
	call	special_blink_leds
; then write the channel setting to data EEPROM
	lsrf	POT_STATE_8,w
	movwf	TEMP2
	clrf	TEMP
	call	write_to_data_eeprom

	return

	end
