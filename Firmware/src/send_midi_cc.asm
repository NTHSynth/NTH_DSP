		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

; =================================
;
; External Labels
;
; =================================

	EXTERN	fetch_note_velocity


send_midi_cc		code

; ==================================================================
;
;
;
; ==================================================================
	GLOBAL	send_cc_from_knobs
send_cc_from_knobs
; check for tempo knob change
		movlw	0x0C
		movwf	TEMP
		movlw	0x06
		movwf	TEMP2
		call	send_cc_from_adc
; check for steps knob change
		movlw	0x0A
		movwf	TEMP
		movlw	0x05
		movwf	TEMP2
		call	send_cc_from_adc
; virtual wave knob
		movlw	0x10
		movwf	TEMP
		movlw	0x01
		movwf	TEMP2
		call	send_cc_from_adc
; virtual env knob
		movlw	0x11
		movwf	TEMP
		movlw	0x02
		movwf	TEMP2
		call	send_cc_from_adc
; virtual detune knob
		movlw	0x12
		movwf	TEMP
		movlw	0x03
		movwf	TEMP2
		call	send_cc_from_adc
; virtual glisss knob
		movlw	0x13
		movwf	TEMP
		movlw	0x04
		movwf	TEMP2
		call	send_cc_from_adc
		return

send_cc_from_adc
; if "send cc" flag is set, use the current adc value and send
		movlw	0x01
		movwf	FSR1H
		movlw	CC_SEND_FLAGS
		addwf	TEMP,w
		addwf	TEMP,w
		movwf	FSR1L
		btfss	INDF1,0
		goto	send_cc_from_adc_check_prev
; get current value
		movlw	RAW_ADC_VALUE_0
		addwf	TEMP,w
		addwf	TEMP,w
		movwf	FSR1L
		lsrf	INDF1,w
		movwf	TEMP4
		goto	send_cc_from_adc_check_pending

send_cc_from_adc_check_prev
; get the previous 7-bit CC value, shift left, store in TEMP3
		movlw	0x02
		movwf	FSR1H
		movlw	RAW_ADC_VALUE_0
		addwf	TEMP,w
		addwf	TEMP,w
		movwf	FSR1L
		movfw	INDF1
		movwf	TEMP3
; shift left, average with current 8-bit value.
; take result, shift right, store in TEMP4
		lslf	TEMP3,w
		movwf	TEMP4
		btfsc	TEMP4,7
		bsf	TEMP4,0
		decf	FSR1H,f
		movfw	INDF1
		addwf	TEMP4,f
		rrf	TEMP4,f
		lsrf	TEMP4,f
; check for change to 7-bit value
		movfw	TEMP4
		subwf	TEMP3,w
		bz	send_cc_from_adc_no_change

send_cc_from_adc_check_pending
; value changed.
; disable_interrupts
		bcf	INTCON,GIE
; pending MIDI? skip
		btfsc	STATE_FLAGS_2,2
		goto	send_cc_enable_interrupts
		btfsc	STATE_FLAGS_2,3
		goto	send_cc_enable_interrupts
		btfsc	STATE_FLAGS_3,2
		goto	send_cc_enable_interrupts
; store new average as "previous" value
		incf	FSR1H,f
		movfw	TEMP4
		movwf	INDF1
; clear the "send cc" flag
		decf	FSR1H,f
		movlw	CC_SEND_FLAGS
		addwf	TEMP,w
		addwf	TEMP,w
		movwf	FSR1L
		clrf	INDF1
; set up CC message
		movfw	TEMP2
		movwf	TX_CC_NUMBER
		movfw	TEMP4
		movwf	TX_CC_VALUE
		movlw	0x03
		movwf	TX_BYTES_LEFT
		bsf	STATE_FLAGS_3,2
		banksel	PIE1
		bsf	PIE1,TXIE	
		clrf	BSR

send_cc_enable_interrupts
		bsf	INTCON,GIE
send_cc_from_adc_no_change
		return
		
; ==================================================================
;
;
;
; ==================================================================
	GLOBAL	send_cc_from_step_buttons
send_cc_from_step_buttons
; put button states into TEMP
;		swapf	BUTTON_STATES_1,w
;		iorwf	BUTTON_STATES_0,w
;		movwf	TEMP
; put bitmask in TEMP2
		movlw	B'00000001'
		movwf	TEMP2
; put counter in TEMP3
		movlw	0x08
		movwf	TEMP3
; put CC number in TEMP4
		movlw	0x10
		movwf	TEMP4
send_cc_from_buttons_loop
; check if current bit has changed.
		movfw	STEP_FLAGS
		xorwf	CC_BUTTON_TOGGLES,w
		andwf	TEMP2,w
		bz	next_cc_button
; bit changed. check for pending MIDI.
; disable_interrupts
		bcf	INTCON,GIE
; pending MIDI? skip
		btfsc	STATE_FLAGS_2,2
		goto	send_cc_enable_interrupts
		btfsc	STATE_FLAGS_2,3
		goto	send_cc_enable_interrupts
		btfsc	STATE_FLAGS_3,2
		goto	send_cc_enable_interrupts
; record the change.
; don't refresh the LEDs until all 8 CCs have been sent at boot.
		movfw	TEMP2
		xorwf	CC_BUTTON_TOGGLES,f
		comf	TEMP2,w
		andwf	CC_LED_INIT_FLAGS,f
		btfss	STATUS,Z
		goto	send_cc_from_buttons_tx
; write to LEDs
		movfw	CC_BUTTON_TOGGLES
		andlw	0x0F
		movwf	LED_STATES_0
		swapf	CC_BUTTON_TOGGLES,w
		andlw	0x0F
		movwf	LED_STATES_1
send_cc_from_buttons_tx
; set up the cc message.
		movlw	0x7F
		movwf	TX_CC_VALUE
		movfw	STEP_FLAGS
		andwf	TEMP2,w
		btfsc	STATUS,Z
		clrf	TX_CC_VALUE
		movfw	TEMP4
		movwf	TX_CC_NUMBER
		movlw	0x03
		movwf	TX_BYTES_LEFT
		bsf	STATE_FLAGS_3,2
		banksel	PIE1
		bsf	PIE1,TXIE	
		clrf	BSR	

		goto	send_cc_enable_interrupts

next_cc_button
		lslf	TEMP2,f
		incf	TEMP4,f
		decfsz	TEMP3,f
		goto	send_cc_from_buttons_loop

		return



; ==================================================================
;
;
;
; ==================================================================
	GLOBAL	send_cc_from_sliders
send_cc_from_sliders
; slider 0
		movlw	0x07
		movwf	TEMP
		movlw	0x08
		movwf	TEMP2
		call	send_cc_from_adc
; slider 1
		movlw	0x06
		movwf	TEMP
		movlw	0x09
		movwf	TEMP2
		call	send_cc_from_adc
; slider 2
		movlw	0x05
		movwf	TEMP
		movlw	0x0A
		movwf	TEMP2
		call	send_cc_from_adc
; slider 3
		movlw	0x04
		movwf	TEMP
		movlw	0x0B
		movwf	TEMP2
		call	send_cc_from_adc
; slider 4
		movlw	0x03
		movwf	TEMP
		movlw	0x0C
		movwf	TEMP2
		call	send_cc_from_adc
; slider 5
		movlw	0x02
		movwf	TEMP
		movlw	0x0D
		movwf	TEMP2
		call	send_cc_from_adc
; slider 6
		movlw	0x01
		movwf	TEMP
		movlw	0x0E
		movwf	TEMP2
		call	send_cc_from_adc
; slider 7
		movlw	0x00
		movwf	TEMP
		movlw	0x0F
		movwf	TEMP2
		call	send_cc_from_adc

		return


		end
