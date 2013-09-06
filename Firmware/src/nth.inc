		list p=16F1937
		#include	<p16f1937.inc>

; =================================
;
; Bank 0 Variables
;
; =================================

OSCA_PHASE		equ	0x20
OSCA_FREQ_H		equ	0x21
OSCA_FREQ_L		equ	0x22
OSCA_COUNTER_H		equ	0x23
OSCA_COUNTER_L		equ	0x24
OSCB_PHASE		equ	0x25
OSCB_FREQ_H		equ	0x26
OSCB_FREQ_L		equ	0x27
OSCB_COUNTER_H		equ	0x28
OSCB_COUNTER_L		equ	0x29
OSCA_CURRENT_SAMPLE	equ	0x2a
OSCB_CURRENT_SAMPLE	equ	0x2b
MIDI_CLOCK_COUNT	equ	0x2c
GHOST_C			equ	0x2d
MIDI_D0			equ	0x2e
STEP_FLAGS		equ	0x2f
STEP			equ	0x30
AMP_ENV			equ	0x31
PITCH_ENV		equ	0x32
DETUNE			equ	0x33
WAVEFORM		equ	0x34
TEMPO			equ	0x35
ANALOG_POLL		equ	0x37
STEP_EIGHTH		equ	0x38
ACTIVE_MIDI_NOTE	equ	0x39
MIDI_CHANNEL		equ	0x3A
STEP_BIT		equ	0x3B
TEMPO_COUNTER_H		equ	0x3C
TEMPO_COUNTER_L		equ	0x3D
TX_CC_NUMBER		equ	0x3E
TX_CC_VALUE		equ	0x3F

POT_STATE_0		equ	0x40
POT_STATE_1		equ	0x41
POT_STATE_2		equ	0x42
POT_STATE_3		equ	0x43
POT_STATE_4		equ	0x44
POT_STATE_5		equ	0x45
POT_STATE_6		equ	0x46
POT_STATE_7		equ	0x47
POT_STATE_8		equ	0x48
POT_STATE_9		equ	0x49
POT_STATE_A		equ	0x4a
POT_STATE_B		equ	0x4b
POT_STATE_C		equ	0x4c
POT_STATE_D		equ	0x4d

BUTTON_STATES_0		equ	0x4e
BUTTON_STATES_1		equ	0x4f
BUTTON_STATES_2		equ	0x50
BUTTON_PREV_0		equ	0x51
BUTTON_PREV_1		equ	0x52
BUTTON_PREV_2		equ	0x53
LED_STATES_0		equ	0x54
LED_STATES_1		equ	0x55
LED_STATES_2		equ	0x56
FUNCTION_FLAGS		equ	0x57

ACTIVE_WAVEFORM		equ	0x58
POT_STATE_8_PREV	equ	0x60
DACA_CURRENT_SAMPLE	equ	0x61
DACA_RETURN_COUNTER	equ	0x62
GRAIN_INCREMENT		equ	0x63
GRAIN_COUNT		equ	0x64
POT_STATE_C_PREV	equ	0x65
NUM_GRAINS		equ	0x66
COUNTER_24PPQ		equ	0x67
TX_BYTES_LEFT		equ	0x68
TX_NOTE_OFF_NUM		equ	0x69
TX_NOTE_ON_NUM		equ	0x6A
TX_NOTE_ON_VEL		equ	0x6B
POLL_COUNT		equ	0x6C
AMP_LEVEL		equ	0x6D
SPECIAL_MODE_FLAGS	equ	0x6E
POT_STATE_A_PREV	equ	0x6F

TEMP_ISR		equ	0x70
TEMP_ISR2		equ	0x71
TEMP			equ	0x72
TEMP2			equ	0x73
TEMP3			equ	0x74
TEMP4			equ	0x75
TEMP5			equ	0x76
PITCH_ENV_POT		equ	0x77
AMP_ENV_POT		equ	0x78
DETUNE_POT		equ	0x79
WAVEFORM_POT		equ	0x7A
CC_BUTTON_TOGGLES	equ	0x7B
CC_LED_INIT_FLAGS	equ	0x7C
STATE_FLAGS		equ	0x7D
STATE_FLAGS_2		equ	0x7E
STATE_FLAGS_3		equ	0x7F

; =================================
;
; Bank 1 Variables
;
; =================================

PARTY_PRNG_V0		equ	0xA0
PARTY_PRNG_V1		equ	0xA1
PARTY_PRNG_TEMP		equ	0xA2
PARTY_GRAIN_COUNT	equ	0xA3

NOISE_PRNG_V0		equ	0xA4
NOISE_PRNG_V1		equ	0xA5
NOISE_PRNG_TEMP		equ	0xA6

; =================================
;
; Bank 2 Variables
;
; =================================

; 2 bytes per ADC channel
RAW_ADC_VALUE_0		equ	0x120
; 2 bytes per "virtual" ADC channel (for mod knob)
VIRTUAL_ADC_VALUE_0	equ	0x140

; =================================
;
; Bank 3 Variables
;
; =================================

; used for sending initial CC values.
CC_SEND_FLAGS		equ	0x1A0

; =================================
;
; Bank 4 Variables
;
; =================================

PREV_RAW_ADC_VALUE_0		equ	0x220
PREV_VIRTUAL_ADC_VALUE_0	equ	0x240

; =================================
;
; Constants
;
; =================================


