		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

isr_code		code	0x04
isr
		clrf	BSR

		btfsc	PIR1,TMR2IF
		goto	handle_timer_2

		btfsc	PIR1,RCIF
		goto	handle_rx

		btfsc	INTCON,TMR0IF
		goto	handle_timer_0

		btfsc	PIR1,TXIF
		goto	handle_tx

		retfie

handle_timer_2
		bcf		PIR1,TMR2IF

; check gate
		btfss	STATE_FLAGS,7
		goto	ht2_zero_sample

ht2_update_osca
; advance OSCA counter based on current frequency
		movfw	OSCA_FREQ_L
		addwf	OSCA_COUNTER_L,f
		movfw	OSCA_FREQ_H
		addwfc	OSCA_COUNTER_H,f

; carry flag means it's time to update sample
; otherwise, skip and update OSCB
		bnc		ht2_update_oscb

ht2_advance_phase_a
		btfsc	SPECIAL_MODE_FLAGS,4
		goto	ht2_advance_phase_a_noise
ht2_advance_phase_a_normal
; advance phase.  (phase has 8 steps)
		incf	OSCA_PHASE,f
		movlw	B'00000111'
		andwf	OSCA_PHASE,f

		movlw	ACTIVE_WAVEFORM
		addwf	OSCA_PHASE,w
		movwf	FSR0L
		clrf	FSR0H
		movfw	INDF0
		movwf	OSCA_CURRENT_SAMPLE
		goto	ht2_update_oscb

ht2_advance_phase_a_noise
; prng.  thanks to joescat.com
		banksel	NOISE_PRNG_V0
		rrf	NOISE_PRNG_V0,w
		xorwf	NOISE_PRNG_V1,w
		movwf	NOISE_PRNG_TEMP
		swapf	NOISE_PRNG_TEMP,f
		rlf	NOISE_PRNG_V0,f
		xorwf	NOISE_PRNG_V0,f
		xorwf	NOISE_PRNG_TEMP,f
		rlf	NOISE_PRNG_TEMP,w
		rlf	NOISE_PRNG_V1,f
		rlf	NOISE_PRNG_V0,f
		movfw	NOISE_PRNG_V0
		clrf	BSR
		movwf	OSCA_CURRENT_SAMPLE

ht2_update_oscb
; advance OSCB counter based on current frequency
		movfw	OSCB_FREQ_L
		addwf	OSCB_COUNTER_L,f
		movfw	OSCB_FREQ_H
		addwfc	OSCB_COUNTER_H,f
; carry flag means it's time to update sample
; otherwise, skip and update OSCB
		bnc		ht2_sum_a_b

ht2_advance_phase_b
; advance phase.  (phase has 8 steps)
		incf	OSCB_PHASE,f
		movlw	B'00000111'
		andwf	OSCB_PHASE,f

		movlw	ACTIVE_WAVEFORM
		addwf	OSCB_PHASE,w
		movwf	FSR0L
		clrf	FSR0H
		movfw	INDF0
		movwf	OSCB_CURRENT_SAMPLE

ht2_sum_a_b
		movfw	OSCA_CURRENT_SAMPLE
		movwf	TEMP_ISR
		movfw	DETUNE
		bz		ht2_amp_envelope
		movfw	OSCA_CURRENT_SAMPLE
		addwf	OSCB_CURRENT_SAMPLE,w
		movwf	TEMP_ISR
		rrf		TEMP_ISR,f

ht2_amp_envelope
; Amplitude value of 0?  Don't update the DAC.
		movfw	AMP_LEVEL
		bz	ht2_zero_sample
; Amplitude value 8?  No shifting required.
		sublw	0x08
		bz	ht2_write_sample
		movwf	TEMP_ISR2
ht2_amp_shift
		lsrf	TEMP_ISR,f
		decfsz	TEMP_ISR2,f
		goto	ht2_amp_shift

ht2_write_sample
		movfw	TEMP_ISR
		movwf	DACA_CURRENT_SAMPLE
		movwf	PORTD
; DAC A
		bcf	GHOST_C,5
; write
		bcf	GHOST_C,4
		movfw	GHOST_C
		movwf	PORTC
		bsf	GHOST_C,4
		movfw	GHOST_C
		movwf	PORTC

		retfie

ht2_zero_sample
; slowly return DACA to zero
		movfw	DACA_CURRENT_SAMPLE
		btfsc	STATUS,Z
		retfie
		decf	DACA_CURRENT_SAMPLE,w
		movwf	TEMP_ISR
		goto	ht2_write_sample

handle_timer_0
; clear the interrupt
		bcf		INTCON,TMR0IF
; if using external sync, exit.
		btfsc		STATE_FLAGS,0
		retfie
; if midi controller mode, exit.
		btfsc		SPECIAL_MODE_FLAGS,3
		retfie

ht0_calc_tempo
; TEMPO is a signed number--get the absolute value.
		comf	TEMPO,w
		btfsc	TEMPO,7
		movfw	TEMPO
		movwf	TEMP_ISR
		bcf	TEMP_ISR,7
; add the absolute value to tempo counter to see if we should do something
		incf	TEMP_ISR,w
		addwf	TEMPO_COUNTER_L,f
		clrw
		addwfc	TEMPO_COUNTER_H,f
		btfss	TEMPO_COUNTER_H,3
		retfie
		clrf	TEMPO_COUNTER_H
ht0_new_24ppq
; send a MIDI clock message.
		bsf	STATE_FLAGS,6
		banksel	PIE1
		bsf	PIE1,TXIE
		clrf	BSR
; advance sequencer "grain" every 3 24ppq pulses.
		decfsz	COUNTER_24PPQ,f
		retfie
		movlw	D'3'
		movwf	COUNTER_24PPQ

		call	advance_sequencer

		retfie

; ****
;
; Process incoming MIDI bytes
;
; ****

handle_rx
; clear the rx interrupt flag
;		bcf	PIR1,RCIF
; grab the received byte
		banksel	RCREG
		movfw	RCREG
; store the byte for study!
		movwf	TEMP_ISR
		clrf	BSR

; status byte?
		btfss	TEMP_ISR,7
		goto	handle_midi_data

; 0xF8 = MIDI Clock
		movlw	0xF8
		subwf	TEMP_ISR,w
		bz	handle_midi_clock
; 0xFA = MIDI Start
		movlw	0xFA
		subwf	TEMP_ISR,w
		bz	handle_midi_start
; 0xFB = MIDI Continue
		movlw	0xFB
		subwf	TEMP_ISR,w
		bz	handle_midi_continue
; 0xFC = MIDI Stop
		movlw	0xFC
		subwf	TEMP_ISR,w
		bz	handle_midi_stop
; 0xB0 = MIDI CC
		movfw	MIDI_CHANNEL
		addlw	0xB0
		subwf	TEMP_ISR,w
		bz	flag_midi_cc
; 0x90 = MIDI Note On
		movfw	MIDI_CHANNEL
		addlw	0x90
		subwf	TEMP_ISR,w
		bz	flag_midi_note_on
; 0x80 = MIDI Note Off
		movfw	MIDI_CHANNEL
		addlw	0x80
		subwf	TEMP_ISR,w
		bz	flag_midi_note_off
; Ignore everything else
		bcf	STATE_FLAGS_2,4
		bcf	STATE_FLAGS_2,5
		bcf	STATE_FLAGS_2,6
		bcf	STATE_FLAGS_2,7
		retfie

flag_midi_cc
		bcf	STATE_FLAGS_2,4
		bsf	STATE_FLAGS_2,5
		btfsc	SPECIAL_MODE_FLAGS,2
		bcf	STATE_FLAGS_2,5
		bcf	STATE_FLAGS_2,6
		bcf	STATE_FLAGS_2,7
		retfie
flag_midi_note_on
		bcf	STATE_FLAGS_2,4
		bcf	STATE_FLAGS_2,5
		bsf	STATE_FLAGS_2,6
		btfsc	SPECIAL_MODE_FLAGS,1
		bcf	STATE_FLAGS_2,6
		bcf	STATE_FLAGS_2,7
		retfie
flag_midi_note_off
		bcf	STATE_FLAGS_2,4
		bcf	STATE_FLAGS_2,5
		bcf	STATE_FLAGS_2,6
		bsf	STATE_FLAGS_2,7
		btfsc	SPECIAL_MODE_FLAGS,1
		bcf	STATE_FLAGS_2,7
		retfie

handle_midi_data
		btfsc	STATE_FLAGS_2,4
		goto	handle_midi_data_d1
handle_midi_data_d0
		movfw	TEMP_ISR
		movwf	MIDI_D0
		bsf	STATE_FLAGS_2,4
		retfie
handle_midi_data_d1
		btfsc	STATE_FLAGS_2,5
		goto	handle_midi_data_cc
		btfsc	STATE_FLAGS_2,6
		goto	handle_midi_data_note_on
		btfsc	STATE_FLAGS_2,7
		goto	handle_midi_data_note_off
		retfie
handle_midi_data_cc
; check for CC 1-7
		bcf	STATE_FLAGS_2,4
		movfw	MIDI_D0
		sublw	0x01
		bz	handle_midi_data_cc1
		movfw	MIDI_D0
		sublw	0x02
		bz	handle_midi_data_cc2
		movfw	MIDI_D0
		sublw	0x03
		bz	handle_midi_data_cc3
		movfw	MIDI_D0
		sublw	0x04
		bz	handle_midi_data_cc4
		movfw	MIDI_D0
		sublw	0x05
		bz	handle_midi_data_cc5
		movfw	MIDI_D0
		sublw	0x06
		bz	handle_midi_data_cc6
		movfw	MIDI_D0
		sublw	0x07
		bz	handle_midi_data_cc7
		movfw	MIDI_D0
		sublw	0x18
		bz	handle_midi_data_cc24
		movfw	MIDI_D0
		sublw	0x19
		bz	handle_midi_data_cc25
; ignore other CC
		retfie
handle_midi_data_cc1
; cc 1 is 5-bit waveform pot
		lsrf	TEMP_ISR,f
		lsrf	TEMP_ISR,w
		movwf	WAVEFORM_POT
		retfie
handle_midi_data_cc2
; cc 2 is 5-bit amp envelope pot
		lsrf	TEMP_ISR,f
		lsrf	TEMP_ISR,w
		movwf	AMP_ENV_POT
		retfie
handle_midi_data_cc3
; cc 3 is 5-bit detune pot
		lsrf	TEMP_ISR,f
		lsrf	TEMP_ISR,w
		movwf	DETUNE_POT
		retfie
handle_midi_data_cc4
; cc 4 is 5-bit pitch env pot
		lsrf	TEMP_ISR,f
		lsrf	TEMP_ISR,w
		movwf	PITCH_ENV_POT
		retfie
handle_midi_data_cc5
; don't adjust num grains if in midi note mode
		btfsc	STATE_FLAGS,1
		retfie
; cc 5 is 6-bit number of grains
; mod 8 and add 8
		lsrf	TEMP_ISR,w
		andlw	B'00111000'
		addlw	0x08
		movwf	NUM_GRAINS
		retfie
handle_midi_data_cc6
		lslf	TEMP_ISR,w
		movwf	TEMPO
		btfsc	TEMPO,7
		bsf	TEMPO,0
		retfie
handle_midi_data_cc7
		bcf	STATE_FLAGS,2
		btfsc	TEMP_ISR,6
		bsf	STATE_FLAGS,2
		retfie
handle_midi_data_cc24
		bcf	SPECIAL_MODE_FLAGS,4
		btfsc	TEMP_ISR,6
		bsf	SPECIAL_MODE_FLAGS,4
		retfie
handle_midi_data_cc25
		bcf	SPECIAL_MODE_FLAGS,5
		btfsc	TEMP_ISR,6
		bsf	SPECIAL_MODE_FLAGS,5
		retfie

handle_midi_data_note_on
		movfw	TEMP_ISR
		bz	handle_midi_data_note_off
		bcf	STATE_FLAGS_2,4
; respond only to notes 17-80
		movlw	D'17'
		subwf	MIDI_D0,f
		btfss	STATUS,C
		retfie
		movlw	D'64'
		subwf	MIDI_D0,w
		btfsc	STATUS,C
		retfie
; store note number & set gate
		movfw	MIDI_D0
		movwf	ACTIVE_MIDI_NOTE
		bsf	STATE_FLAGS_2,1
		bsf	STATE_FLAGS,7
		bsf	STATE_FLAGS,1
; reduce pattern to one step only.
		movlw	0x08
		movwf	NUM_GRAINS
; sync output
		movlw	D'3'
		movwf	COUNTER_24PPQ
		clrf	TEMPO_COUNTER_H
		clrf	TEMPO_COUNTER_L
		clrf	TMR0
		bcf	INTCON,TMR0IF

; set beginning grain count.
; assume reverse: set to last grain in sequence
		decf	NUM_GRAINS,w
		movwf	GRAIN_COUNT
; if forward, clear grain count (first grain in sequence)
		btfsc	TEMPO,7
		clrf	GRAIN_COUNT
; this is like a one-step sequence.
		call	update_sequencer_from_grain
		retfie

handle_midi_data_note_off
		bcf	STATE_FLAGS_2,4
; respond only to notes 17-80
		movlw	D'17'
		subwf	MIDI_D0,f
		btfss	STATUS,C
		retfie
		movlw	D'64'
		subwf	MIDI_D0,w
		btfsc	STATUS,C
		retfie
; check for note match and clear gate
		movfw	MIDI_D0
		subwf	ACTIVE_MIDI_NOTE,w
		btfss	STATUS,Z
		retfie
		bcf	STATE_FLAGS_2,1
		retfie


handle_midi_clock
; ignore if special mode: ignore sync
		btfsc	SPECIAL_MODE_FLAGS,0
		retfie
; external sync mode
		bsf	STATE_FLAGS,0
; send the midi message thru.
		bsf	STATE_FLAGS,6
		banksel	PIE1
		bsf	PIE1,TXIE
		clrf	BSR
handle_midi_clock_count
; if running, count this clock, otherwise return
		btfss	STATE_FLAGS_2,0
		retfie
; take action every 3 clocks.
		decfsz	MIDI_CLOCK_COUNT,f
		retfie
		movlw	0x03
		movwf	MIDI_CLOCK_COUNT
; advance the sequencer
		call	advance_sequencer
		retfie

advance_sequencer
; add grain increment
		movfw	GRAIN_INCREMENT
		addwf	GRAIN_COUNT,f
; check for overflow
		movfw	NUM_GRAINS
		subwf	GRAIN_COUNT,w
		btfss	STATUS,C
		goto	update_sequencer_from_grain
; overflow.  if using midi gate in one-shot mode, reverse advance.
		comf	STATE_FLAGS,w
		andlw	B'00000110'
		bnz	advance_sequencer_wrap
		movfw	GRAIN_INCREMENT
		subwf	GRAIN_COUNT,f
		return
; if not one-shot mode, wrap
advance_sequencer_wrap
		btfsc	GRAIN_INCREMENT,7
		goto	next_grain_wrap_reverse
next_grain_wrap_forward
;		movfw	NUM_GRAINS
;		subwf	GRAIN_COUNT,f
		movlw	B'00000111'
		andwf	GRAIN_COUNT,f
		goto	update_sequencer_from_grain
next_grain_wrap_reverse
; calculate the step eighth
		movfw	GRAIN_COUNT
		andlw	B'00000111'
		movwf	TEMP_ISR
; calculate the 0 grain for the last step in the sequence.
		movlw	D'8'
		subwf	NUM_GRAINS,w
; then add the step eight back in as an offset.
		addwf	TEMP_ISR,w
		movwf	GRAIN_COUNT

; now, use the grain to calculate the step # and step_eighth
; store the previous step #
	GLOBAL	update_sequencer_from_grain
update_sequencer_from_grain
		movfw	GRAIN_COUNT
		andlw	B'00000111'
		movwf	STEP_EIGHTH
; check for midi note mode
		btfsc	STATE_FLAGS,1
		goto	calculate_step_normal
; check for party mode
		btfsc	SPECIAL_MODE_FLAGS,5
		goto	calculate_step_party
calculate_step_normal
; calculate STEP number for normal sequencer mode
		lsrf	GRAIN_COUNT,w
		movwf	TEMP_ISR
		lsrf	TEMP_ISR,f
		lsrf	TEMP_ISR,w
		movwf	STEP
		goto	calculate_step_bit
calculate_step_party
		movfw	GRAIN_INCREMENT
		banksel	PARTY_PRNG_V0
		addwf	PARTY_GRAIN_COUNT,f
; new step only when appropriate
		btfsc	PARTY_GRAIN_COUNT,3
		goto	calculate_step_party_next
		clrf	BSR
		goto	advance_sequencer_update_gate

calculate_step_party_next
		bcf	PARTY_GRAIN_COUNT,3
; prng.  thanks to joescat.com
		rrf	PARTY_PRNG_V0,w
		xorwf	PARTY_PRNG_V1,w
		movwf	PARTY_PRNG_TEMP
		swapf	PARTY_PRNG_TEMP,f
		rlf	PARTY_PRNG_V0,f
		xorwf	PARTY_PRNG_V0,f
		xorwf	PARTY_PRNG_TEMP,f
		rlf	PARTY_PRNG_TEMP,w
		rlf	PARTY_PRNG_V1,f
		rlf	PARTY_PRNG_V0,f
; use steps knob to determine STEP
		clrf	BSR
		clrf	STEP
		lsrf	POT_STATE_A,w
		movwf	TEMP_ISR2
		clrf	TEMP_ISR
		movfw	TEMP_ISR2
		bz	party_loop_yes
party_loop
		bsf	STATUS,C
		rlf	TEMP_ISR,f
		decfsz	TEMP_ISR2,f
		goto	party_loop

		movfw	TEMP_ISR
		banksel	PARTY_PRNG_V0
		andwf	PARTY_PRNG_V0,w
		clrf	BSR
		movwf	STEP
		andlw	B'11111000'
		bz	party_loop_yes
		clrf	STEP_BIT
		clrf	STEP
		goto	advance_sequencer_update_gate
; mask all but 3 bits
;		movfw	PARTY_PRNG_V0
;		andlw	B'00000111'
;		clrf	BSR
;		movwf	STEP
party_loop_yes
		movfw	STEP
calculate_step_bit
; calculate STEP_BIT from STEP (in W)
		movwf	TEMP_ISR
		incf	TEMP_ISR,f

		clrf	STEP_BIT
		bsf	STATUS,C
next_grain_step_bit_shift
		rlf	STEP_BIT,f
		decfsz	TEMP_ISR,f
		goto	next_grain_step_bit_shift

advance_sequencer_update_gate
		lslf	AMP_ENV,w
		movwf	TEMP_ISR
		lslf	TEMP_ISR,f
		lslf	TEMP_ISR,w
		addwf	STEP_EIGHTH,w
		movwf	FSR0L
		movlw	0x9B
		movwf	FSR0H
		movfw	INDF0
		movwf	AMP_LEVEL
; MIDI note gate?  Ignore.
		btfsc	STATE_FLAGS,1
		return
; set the gate,
		bsf	STATE_FLAGS,7
; ...then check if it should be cleared.
		movfw	STEP_BIT
		andwf	STEP_FLAGS,w
		btfsc	STATUS,Z
		bcf	STATE_FLAGS,7
; advance_sequencer
		return



handle_midi_start
; ignore if special mode: ignore sync
		btfsc	SPECIAL_MODE_FLAGS,0
		retfie
; set state flags
		bsf	STATE_FLAGS,0
		bsf	STATE_FLAGS_2,0
; send the midi message thru
		bsf	STATE_FLAGS,3
		banksel	PIE1
		bsf	PIE1,TXIE
		clrf	BSR
; reset midi clock counter and step state
; first clock is the "zero" clock!  look for 4 not 3
		movlw	0x04
		movwf	MIDI_CLOCK_COUNT
; sync output
		clrf	TEMPO_COUNTER_H
		clrf	TEMPO_COUNTER_L
		clrf	TMR0
		bcf	INTCON,TMR0IF
; set beginning grain count.
; assume reverse: set to last grain in sequence
		decf	NUM_GRAINS,w
		movwf	GRAIN_COUNT
; if forward, clear grain count (first grain in sequence)
		btfsc	TEMPO,7
		clrf	GRAIN_COUNT

		call	update_sequencer_from_grain

		retfie

handle_midi_continue
; ignore if special mode: ignore sync
		btfsc	SPECIAL_MODE_FLAGS,0
		retfie
; set state flags
		bsf	STATE_FLAGS,0
		bsf	STATE_FLAGS_2,0
; send the midi message thru
		bsf	STATE_FLAGS,4
		banksel	PIE1
		bsf	PIE1,TXIE
		retfie

handle_midi_stop
; ignore if special mode: ignore sync
		btfsc	SPECIAL_MODE_FLAGS,0
		retfie
; set state flags
		bsf	STATE_FLAGS,0
		bcf	STATE_FLAGS_2,0
		bcf	STATE_FLAGS,7
; send the midi message thru
		bsf	STATE_FLAGS,5
		banksel	PIE1
		bsf	PIE1,TXIE
		retfie

handle_tx
; check if MIDI start must be sent
		btfsc	STATE_FLAGS,3
		goto	handle_tx_midi_start
; check if MIDI continue must be sent
		btfsc	STATE_FLAGS,4
		goto	handle_tx_midi_continue
; check if MIDI stop must be sent
		btfsc	STATE_FLAGS,5
		goto	handle_tx_midi_stop
; check if MIDI clock must be sent
		btfsc	STATE_FLAGS,6
		goto	handle_tx_midi_clock
; check if MIDI note off must be sent
		btfsc	STATE_FLAGS_2,2
		goto	handle_tx_midi_note_off
; check if MIDI note on must be sent
		btfsc	STATE_FLAGS_2,3
		goto	handle_tx_midi_note_on
; check if MIDI CC must be sent
		btfsc	STATE_FLAGS_3,2
		goto	handle_tx_midi_cc

; should never execute here.
		retfie

handle_tx_midi_start
		bcf	STATE_FLAGS,3
		movlw	0xFA
		goto	handle_tx_send

handle_tx_midi_continue
		bcf	STATE_FLAGS,4
		movlw	0xFB
		goto	handle_tx_send

handle_tx_midi_stop
		bcf	STATE_FLAGS,5
		movlw	0xFC
		goto	handle_tx_send

handle_tx_midi_clock
		bcf	STATE_FLAGS,6
		movlw	0xF8
		goto	handle_tx_send

handle_tx_midi_note_off
; if bytes left is zero, this is the start of a new message.
		decfsz	TX_BYTES_LEFT,f
		goto	handle_tx_midi_note_off_12
handle_tx_midi_note_off_velocity
; this the last byte, so note off is no longer pending.
; tx gate is also now off.
		bcf	STATE_FLAGS_2,2
		bcf	STATE_FLAGS_3,0
		movlw	0x00
		goto	handle_tx_send
handle_tx_midi_note_off_12
		btfsc	TX_BYTES_LEFT,1
		goto	handle_tx_midi_note_off_status
handle_tx_midi_note_off_number
		movfw	TX_NOTE_OFF_NUM
		goto	handle_tx_send
handle_tx_midi_note_off_status
		movfw	MIDI_CHANNEL
		addlw	0x80
		goto	handle_tx_send


handle_tx_midi_note_on
; if bytes left is zero, this is the start of a new message.
		decfsz	TX_BYTES_LEFT,f
		goto	handle_tx_midi_note_on_12
handle_tx_midi_note_on_velocity
; this the last byte, so note on is no longer pending.
; tx gate is also now on.
		bcf	STATE_FLAGS_2,3
		bsf	STATE_FLAGS_3,0
		movfw	TX_NOTE_ON_VEL
		goto	handle_tx_send
handle_tx_midi_note_on_12
		btfsc	TX_BYTES_LEFT,1
		goto	handle_tx_midi_note_on_status
handle_tx_midi_note_on_number
		movfw	TX_NOTE_ON_NUM
		goto	handle_tx_send
handle_tx_midi_note_on_status
		movfw	MIDI_CHANNEL
		addlw	0x90
		goto	handle_tx_send


handle_tx_midi_cc
; one byte left?  send the cc value
		decfsz	TX_BYTES_LEFT,f
		goto	handle_tx_midi_cc_12
handle_tx_midi_cc_value
; this the last byte, so cc is no longer pending.
; tx gate is also now on.
		bcf	STATE_FLAGS_3,2
		movfw	TX_CC_VALUE
		goto	handle_tx_send
handle_tx_midi_cc_12
		btfsc	TX_BYTES_LEFT,1
		goto	handle_tx_midi_cc_status
handle_tx_midi_cc_number
		movfw	TX_CC_NUMBER
		goto	handle_tx_send
handle_tx_midi_cc_status
		movfw	MIDI_CHANNEL
		addlw	0xB0
		goto	handle_tx_send


handle_tx_send
; write to TX register
		banksel	TXREG
		movwf	TXREG
; if no other messages are pending, shut down the TX
		btfsc	STATE_FLAGS,3
		retfie
		btfsc	STATE_FLAGS,4
		retfie
		btfsc	STATE_FLAGS,5
		retfie
		btfsc	STATE_FLAGS,6
		retfie
		btfsc	STATE_FLAGS_2,2
		retfie
		btfsc	STATE_FLAGS_2,3
		retfie
		btfsc	STATE_FLAGS_3,2
		retfie
; disable the TX interrupt
		banksel	PIE1
		bcf	PIE1,TXIE
		retfie


		end
