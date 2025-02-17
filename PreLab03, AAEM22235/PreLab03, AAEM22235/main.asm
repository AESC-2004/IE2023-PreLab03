;
; PreLab03, AAEM22235.asm
;
; Created: 17/02/2025 11:36:42 a. m.
; Author : ang50
;


.include "M328PDEF.inc"
.cseg

;Guardamos un salto a la sub-rutina "PIN_CHANGE" en el vector de interrupción necesario
.org PCINT1 ;Pin Change Interrupt 1 (PORTC)
	JMP	PIN_CHANGE

;Registros importantes
.def	COUNT			= R20
;.def	COUNTtemp		= R21
.def	PBUP_LASTVALUE	= R22
.def	PBDWN_LASTVALUE	= R23



SETUP:
	;Deshabilitar interrupciones globales en el SETUP
	CLI

	;Configurar STACK
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

	;Configurar I/O PORTS (DDRx, PORTx)
	;PORTB: BIN Out (PB0,1,2,3)								|	PORTB: 0000XXXX
	LDI		R16, 0x0F
	OUT		DDRB, R16
	LDI		R16, 0x00
	OUT		PORTB, R16
	;PORTC: BIN In (PC0,1)									|	PORTC: 00000011
	LDI		R16, 0
	OUT		DDRC, R16
	LDI		R16, 0b00000011
	OUT		PORTC, R16

	;Valores iniciales
	LDI		COUNT, 0x00

	;Rehabilitamos interrupciones globales
	SEI



;Loop infinito sin acción alguna, pues las interrupciones evitan POLLING
MAIN_LOOP:
	JMP MAIN_LOOP



;********Sub-rutinas de interrupción******** 
;(Será utilizada la instrucción SEI para habilitar interrupciones anidadas)

PIN_CHANGE:
	SEI		; Habilitamos interrupciones anidadas
	;Primero revisamos si el cambio fue en COUNTUP_BUTTON
	;Si el botón se encuentra presionado, nos vamos a revisar su estado anterior para verificar
	;si es correcto incrementar el valor de COUNT
	;Si el botón NO se encuentra presionado, establecemos su último estado como NO presionado,
	;y revisamos COUNTDWN_BUTTON
	SBIS	PINC, 1
	JMP		COUNTUP_SEG
	LDI		PBUP_LASTVALUE, 0b00000001

	;Si el estado anterior de COUNTUP_BUTTON era el mismo que el último guardado, o bien, si el
	; botón NO se encontraba presionado, no ejecutamos un incremento y revisamos COUNTDWN_BUTTON
	;Si countDWN_BUTTON se encuentra presionado, nos vamos a revisar su estado anterior para verificar
	;si es correcto decrementar el valor de COUNT
	;Si el botón NO se encuentra presionado, establecemos su último estado como NO presionado,
	;y regresamos a MAIN saliéndonos de la rutina de interrupción
	RETURN_UP:
		SBIS	PINC, 0
		JMP		COUNTDWN_SEG
		LDI		PBDWN_LASTVALUE, 0b00000001

	RETURN_DWN:
		RETI


;********Sub-rutinas de la sub-rutina de interrupción******** 
COUNTUP_SEG:
	BST		PBUP_LASTVALUE, 0
	BRTC	RETURN_UP
	CALL	COUNTUP
	LDI		PBUP_LASTVALUE,	0b00000000
	;No es necesario un loop de seguridad dado el uso de interrupciones
	JMP		RETURN_UP
COUNTUP:
	INC		COUNT
	SBRS	COUNT, 4
	CLR		COUNT
	OUT		PORTB, COUNT
	RET	

COUNTDWN_SEG:
	BST		PBDWN_LASTVALUE, 0
	BRTC	RETURN_DWN
	CALL	COUNTDWN
	LDI		PBDWN_LASTVALUE,	0b00000000
	;No es necesario un loop de seguridad dado el uso de interrupciones
	JMP		RETURN_DWN
COUNTDWN:
	DEC		COUNT
	SBRS	COUNT, 7
	LDI		COUNT, 0x0F
	OUT		PORTB, COUNT
	RET