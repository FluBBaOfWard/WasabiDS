#ifdef __arm__

#include "ARM6502/M6502.i"
#include "KS5360/SVVideo.i"

	.global ioReset
	.global refreshEMUjoypads
	.global ioSaveState
	.global ioLoadState
	.global ioGetStateSize

	.global joy0_R

	.global joyCfg
	.global EMUinput

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
ioReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

//	bl intEepromReset

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
ioSaveState:			;@ In r0=destination. Out r0=size.
	.type   ioSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

//	ldr r1,=rtcRegs
//	mov r2,#0x100
//	bl memcpy

	ldmfd sp!,{lr}
	mov r0,#0x100
	bx lr
;@----------------------------------------------------------------------------
ioLoadState:			;@ In r0=source. Out r0=size.
	.type   ioLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

//	bl initSysMem

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
ioGetStateSize:		;@ Out r0=state size.
	.type   ioGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#0x100
	bx lr

;@----------------------------------------------------------------------------
refreshEMUjoypads:			;@ Call every frame
;@----------------------------------------------------------------------------

		ldr r0,=frameTotal
		ldr r0,[r0]
		movs r0,r0,lsr#2		;@ C=frame&2 (autofire alternates every other frame)
	ldr r4,EMUinput
	mov r3,r4
	and r0,r4,#0xf0
		ldr r2,joyCfg
		andcs r3,r3,r2
		tstcs r3,r3,lsr#10		;@ NDS L?
		andcs r3,r3,r2,lsr#16
	adr r1,dulr2udlr
	ldrb r0,[r1,r0,lsr#4]

	and r1,r4,#0x0C				;@ NDS Select/Start
	orr r0,r0,r1,lsl#4			;@ SV Select/Start

	ands r1,r3,#3				;@ A/B buttons
	cmpne r1,#3
	eorne r1,r1,#3
	tst r2,#0x400				;@ Swap A/B?
	andeq r1,r3,#3
	orr r0,r0,r1,lsl#4

	strb r0,joy0State
	bx lr
;@----------------------------------------------------------------------------
joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
playerCount:.long 0			;@ Number of players in multilink.
joy0State:	.long 0
stslba2stslab:	.byte 0x00,0x02,0x01,0x03, 0x04,0x06,0x05,0x07, 0x08,0x0A,0x09,0x0B, 0x0C,0x0E,0x0D,0x0F
dulr2udlr:		.byte 0x00,0x01,0x02,0x03, 0x08,0x09,0x0A,0x0B, 0x04,0x05,0x06,0x07, 0x0C,0x0D,0x0E,0x0F

EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

;@----------------------------------------------------------------------------
joy0_R:			;@ 0x2000
;@----------------------------------------------------------------------------
	ldrb r0,joy0State
	eor r0,r0,#0xFF

	bx lr

;@----------------------------------------------------------------------------

	.end
#endif // #ifdef __arm__
