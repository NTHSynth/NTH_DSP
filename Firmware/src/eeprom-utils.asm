		list p=16F1937
		#include	<p16f1937.inc>
		#include	"nth.inc"

eeprom_utils	code

; ****************************
;
; read a byte from data EEPROM at address in TEMP
; leave result in W
; 
; ****************************
	GLOBAL	read_from_data_eeprom
read_from_data_eeprom
	banksel	EEADRL
	movfw	TEMP
	movwf	EEADRL
	bcf	EECON1,EEPGD
	bsf	EECON1,RD
	movfw	EEDATL
	clrf	BSR
	return

; ****************************
;
; write byte in TEMP2 to data EEPROM at address TEMP
; global interrupts are assumed to be off.
; 
; ****************************
	GLOBAL	write_to_data_eeprom
write_to_data_eeprom
	banksel	EECON1
; make sure EEPROM is ready for write
	btfsc	EECON1,WR
	goto	$-1

	movfw	TEMP
	movwf	EEADRL
	movfw	TEMP2
	movwf	EEDATL
	bcf	EECON1,EEPGD
	bsf	EECON1,WREN
	movlw	0x55
	movwf	EECON2
	movlw	0xAA
	movwf	EECON2
	bsf	EECON1,WR
	bcf	EECON1,WREN
; make sure write is complete
	btfsc	EECON1,WR
	goto	$-1

	clrf	BSR

	end
