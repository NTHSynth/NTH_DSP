		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

; ****************************
;
; initiate an analog to digial conversion for one ADC channel
; ANALOG_POLL identifies the channel
; store specified-resolution result in POT_STATE_n register
; store 8-bit result in RAW_ADC_n register
;
; ****************************
adc_utils	code
	GLOBAL	read_pot
read_pot
; move the analog input number to TEMP
		movfw	ANALOG_POLL
		movwf	TEMP
; get the resolution need for this ADC channel & store in TEMP2
		call	fetch_resolution
		movwf	TEMP2
; set up the pointer to analog state data
		movlw	POT_STATE_0
		addwf	TEMP,w
		movwf	FSR0L
		clrf	FSR0H
; INDF0 now contains previous polled pot value.
; resolution 0 = skip, return 0.
		movfw	TEMP2
		btfsc	STATUS,Z
		retlw	0x00
;		movwf	TEMP4
; calculate the maximum value based on resolution
;		clrf	TEMP3
;go_adc_calc_max
;		bsf	STATUS,C
;		rlf	TEMP3,f
;		decfsz	TEMP4,f
;		goto	go_adc_calc_max
; TEMP3 now holds max value for pot.
; move the analog input number into ADCON0
		lslf	TEMP,f
		lslf	TEMP,w
		banksel	ADCON0
		movwf	ADCON0
; ADC on
		bsf		ADCON0,ADON
; charge the cap
		call	sample_delay
; wait for result
		bsf		ADCON0,GO_NOT_DONE
		btfsc	ADCON0,GO_NOT_DONE
		goto	$-1
; ADC off
		bcf		ADCON0,ADON
; ADFM=0, so high 8 bits of result are in ADRESH, move to TEMP
; also store in TEMP4 for later storage.
		movfw	ADRESH
		movwf	TEMP
		movwf	TEMP4
		movfw	ADRESL
		movwf	TEMP5
; special case for resolution of 8 bits.  always store value.
		movfw	TEMP2
		sublw	0x08
		bz		go_adc_update
		movwf	TEMP2
go_adc_shift
		lsrf	TEMP,f
		decfsz	TEMP2,f
		goto	go_adc_shift
go_adc_check_value
; update pot value only in certain cases.
go_adc_check_zero
; always update value when ADC is at 10-bit zero.
		movfw	ADRESH
		bnz	go_adc_check_max
		movfw	ADRESL
		bz	go_adc_update
go_adc_check_max
; always update value when ADC is at 10-bit maximum.
		movfw	ADRESH
		sublw	0xff
		bnz	go_adc_average
		movfw	ADRESL
		sublw	B'11000000'
		bz	go_adc_update
go_adc_average
; if this is the first read, don't average.
		btfss	STATE_FLAGS_3,1
		goto	go_adc_check_increment
; average this reading with the previous one.
		movfw	INDF0
		addwf	TEMP,f
		rrf	TEMP,f
go_adc_check_increment
; increment by one?  don't update value.
		incf	INDF0,w
		subwf	TEMP,w
		bz	go_adc_return
go_adc_check_decrement
; decrement by one?  don't update value.
		decf	INDF0,w
		subwf	TEMP,w
		bz	go_adc_return
; all other cases: update value.
go_adc_update
		movfw	TEMP
		movwf	INDF0
go_adc_return
		clrf	BSR
		movlw	RAW_ADC_VALUE_0
		addwf	ANALOG_POLL,w
		addwf	ANALOG_POLL,w
		movwf	FSR1L
		movlw	0x01
		movwf	FSR1H
		movfw	TEMP4
		movwi	INDF1++
		movfw	TEMP5
		movwf	INDF1
; use 3 low bits from adc result to help with PRNG
		rrf	TEMP4,w
		rrf	TEMP5,f
		lsrf	TEMP5,f
		lsrf	TEMP5,f
		lsrf	TEMP5,f
		lsrf	TEMP5,f
		lsrf	TEMP5,f
		banksel	PARTY_PRNG_V0
		movfw	TEMP5
		addwf	PARTY_PRNG_V0,f
		btfsc	STATUS,C
		incf	PARTY_PRNG_V1,f
		movfw	TEMP5
		addwf	NOISE_PRNG_V1,f
		btfsc	STATUS,C
		incf	NOISE_PRNG_V0,f
		clrf	BSR
		return

; ****************************
;
; grab the resolution needed from each ADC channel.
; returns the number of bits in W
;
; ****************************
	GLOBAL	fetch_resolution
fetch_resolution
		brw
; 0-7: sliders
		retlw	0x07
		retlw	0x07
		retlw	0x07
		retlw	0x07
		retlw	0x07
		retlw	0x07
		retlw	0x07
		retlw	0x07
; 8: Multi
		retlw	0x05
; 9: N/A
		retlw	0x00
; 10: Steps
		retlw	0x04
; 11: N/A
		retlw	0x00
; 12: Tempo
		retlw	0x08
; 13: N/A
		retlw	0x00

; ****************************
;
; sample_delay
; allow adc cap to charge
; 
; ****************************

sample_delay
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		return

		end
