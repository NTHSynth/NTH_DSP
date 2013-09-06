		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

; =================================
;
; External Labels
;
; =================================

	EXTERN	fetch_note_velocity


sequencer_utils		code

; ==================================================================
;
;
;
; ==================================================================
	GLOBAL	update_oscillator_pitch
update_oscillator_pitch
; update oscillator frequencies
; grab the pitch offset
		movfw	PITCH_ENV
		addwf	PITCH_ENV,w
		addwf	PITCH_ENV,w
		addwf	PITCH_ENV,w
		addwf	PITCH_ENV,w
		addwf	PITCH_ENV,w
		addwf	PITCH_ENV,w
		addwf	PITCH_ENV,w
		addwf	STEP_EIGHTH,w
		movwf	FSR0L
		movlw	0x9A
		movwf	FSR0H
; if using slider note generation,
; grab the slider position for current step
; otherwise use MIDI note
		btfsc	STATE_FLAGS,1
		goto	insert_midi_note
get_slider_note
		movfw	STEP
		sublw	POT_STATE_7
		movwf	FSR1L
		clrf	FSR1H
		lsrf	INDF1,w
		goto	sum_note_stuff
insert_midi_note
		movlw	ACTIVE_MIDI_NOTE
		movwf	FSR1L
		clrf	FSR1H
		movfw	INDF1
sum_note_stuff
; sum the slider position, offset,
;    and 12 (breathing room for pitch envelopes)
		addwf	INDF0,w
		addlw	0x0C
		movwf	TEMP
;		movfw	TEMP
		addwf	TEMP,w
		movwf	FSR0L
		movlw	0x98
		movwf	FSR0H
		moviw	INDF0++
		movwf	OSCA_FREQ_H
		moviw	INDF0--
		movwf	OSCA_FREQ_L
; osc B pitch, detuned
		movfw	DETUNE
		addwf	DETUNE,w
		addwf	FSR0L,f
		moviw	INDF0++
		movwf	OSCB_FREQ_H
		movfw	INDF0
		movwf	OSCB_FREQ_L

		return

; ==================================================================
;
;
;
; ==================================================================
	GLOBAL	update_oscillator_gate
update_oscillator_gate
; update the gate bit
; midi controller mode (no synthesis?)
		btfsc	SPECIAL_MODE_FLAGS,3
		return
; midi note control?
		btfsc	STATE_FLAGS,1
		goto	midi_note_gate
; midi sync control?
		btfsc	STATE_FLAGS,0
		goto	midi_sync_gate
slider_gate
; use active step & slider button to determine gate.
		movfw	STEP_BIT
		andwf	STEP_FLAGS,w
		btfsc	STATUS,Z
		goto	clear_gate
set_gate
		bsf	STATE_FLAGS,7
		goto	midi_note_tx_gate_on
clear_gate
		bcf	STATE_FLAGS,7
		goto	midi_note_tx_gate_off

midi_sync_gate
; if external sync is active but stopped, gate is off
; otherwise, use slider gate
		btfsc	STATE_FLAGS_2,0
		goto	slider_gate
		bcf	STATE_FLAGS,7
		goto	midi_note_tx_gate_off
midi_note_gate
		btfsc	STATE_FLAGS_2,1
		goto	set_gate
		goto	clear_gate
		goto	midi_note_tx_gate_off

midi_note_tx_gate_on
; using external note gate?  don't send notes.
		btfsc	STATE_FLAGS,1
		return
; disable interrupts
		bcf	INTCON,GIE
; generate MIDI note
; MIDI note is "NTH note" + 5
		movlw	0x05
		addwf	TEMP,f
;		movlw	0x07
;		subwf	TEMP,f
; pending midi?  skip
		btfsc	STATE_FLAGS_2,2
		goto	poll_enable_interrupts
		btfsc	STATE_FLAGS_2,3
		goto	poll_enable_interrupts
		btfsc	STATE_FLAGS_3,2
		goto	poll_enable_interrupts
; calculate the current note velocity
		movfw	AMP_LEVEL
		call	fetch_note_velocity
		movwf	TEMP2

; If MIDI TX gate is off, send note-on.
		btfsc	STATE_FLAGS_3,0
		goto	midi_note_tx_gate_on_change

		movfw	TEMP
		movwf	TX_NOTE_ON_NUM
		movfw	TEMP2
		movwf	TX_NOTE_ON_VEL
		movlw	0x03
		movwf	TX_BYTES_LEFT
		bsf	STATE_FLAGS_2,3
		goto	poll_enable_tx

midi_note_tx_gate_on_change
; If MIDI TX gate is on and note number has changed, send note-off
		movfw	TEMP
		subwf	TX_NOTE_ON_NUM,w
		bnz	midi_note_tx_gate_on_note_off
; If MIDI TX gate is on and amplitude has changed, send note-off
		movfw	TEMP2
		subwf	TX_NOTE_ON_VEL,w
		bz	poll_enable_interrupts

midi_note_tx_gate_on_note_off
		movfw	TX_NOTE_ON_NUM
		movwf	TX_NOTE_OFF_NUM
		movlw	0x03
		movwf	TX_BYTES_LEFT
		bsf	STATE_FLAGS_2,2
		goto	poll_enable_tx

midi_note_tx_gate_off
; using external note gate?  don't send notes.
		btfsc	STATE_FLAGS,1
		return
; disable interrupts
		bcf	INTCON,GIE
; If MIDI TX gate is on and no notes pending, send note-off
		btfss	STATE_FLAGS_3,0
		goto	poll_enable_interrupts
		btfsc	STATE_FLAGS_2,2
		goto	poll_enable_interrupts
		btfsc	STATE_FLAGS_2,3
		goto	poll_enable_interrupts
		btfsc	STATE_FLAGS_3,2
		goto	poll_enable_interrupts

		movfw	TX_NOTE_ON_NUM
		movwf	TX_NOTE_OFF_NUM
		movlw	0x03
		movwf	TX_BYTES_LEFT
		bsf	STATE_FLAGS_2,2

poll_enable_tx
		banksel	PIE1
		bsf	PIE1,TXIE
		clrf	BSR
poll_enable_interrupts
		bsf	INTCON,GIE

		return

		end
