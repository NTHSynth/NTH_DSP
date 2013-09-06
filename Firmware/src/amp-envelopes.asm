		list p=16F1937
		#include	<p16f1937.inc>

; =================================
;
; Data in Program EEPROM
;
; =================================

amp_env_data	code	0x1B00

; Amplitude Envelopes
; A "slider step" for the NTH is divided into 8 slices.
; Each slice has an amplitude defined by the number of bits
;    from the waveform sample that are right-justified and sent to the DAC.
; So:
;    an 8 is the full sample.
;    a 7 is the sample divided by two
;    a 6 is the sample divided by four
;    ...etc
; In other words:
;    if the current waveform sample is 0xFF (B'11111111')
;    and the amplitude being applied is 0x05
;    then the sample sent to the DAC is 0x1F (B'00011111')
; Note that dividing the sample by two doesn't result in
;    halved perceived loudness
; Envelope 0 is the full counter-clockwise knob position.
; Like for waveforms, we could have a larger number of envelopes.
; They could be ordered on the knob algorithmically.

; Env 0
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
; Env 1
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0007
		data	0x0006
; 2
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0006
		data	0x0004
		data	0x0002
		data	0x0000
; 3
		data	0x0008
		data	0x0008
		data	0x0008
		data	0x0007
		data	0x0006
		data	0x0005
		data	0x0004
		data	0x0003
; 4
		data	0x0008
		data	0x0007
		data	0x0006
		data	0x0005
		data	0x0005
		data	0x0005
		data	0x0005
		data	0x0005
; 5
		data	0x0008
		data	0x0007
		data	0x0006
		data	0x0005
		data	0x0004
		data	0x0003
		data	0x0002
		data	0x0001
; 6
		data	0x0008
		data	0x0007
		data	0x0006
		data	0x0005
		data	0x0007
		data	0x0006
		data	0x0005
		data	0x0004
; 7
		data	0x0008
		data	0x0006
		data	0x0004
		data	0x0002
		data	0x0005
		data	0x0003
		data	0x0002
		data	0x0001
; 8
		data	0x0008
		data	0x0005
		data	0x0002
		data	0x0006
		data	0x0005
		data	0x0004
		data	0x0003
		data	0x0002
; 9
		data	0x0008
		data	0x0005
		data	0x0002
		data	0x0006
		data	0x0003
		data	0x0001
		data	0x0004
		data	0x0001
; 10
		data	0x0008
		data	0x0003
		data	0x0006
		data	0x0002
		data	0x0004
		data	0x0001
		data	0x0002
		data	0x0000
; 11
		data	0x0008
		data	0x0006
		data	0x0004
		data	0x0002
		data	0x0000
		data	0x0002
		data	0x0004
		data	0x0006
; 12
		data	0x0008
		data	0x0007
		data	0x0006
		data	0x0005
		data	0x0005
		data	0x0006
		data	0x0007
		data	0x0008
; 13
		data	0x0004
		data	0x0005
		data	0x0006
		data	0x0007
		data	0x0008
		data	0x0007
		data	0x0006
		data	0x0005
; 14
		data	0x0005
		data	0x0006
		data	0x0007
		data	0x0008
		data	0x0003
		data	0x0004
		data	0x0005
		data	0x0006
; 15
		data	0x0003
		data	0x0004
		data	0x0005
		data	0x0006
		data	0x0007
		data	0x0008
		data	0x0008
		data	0x0008


		end

