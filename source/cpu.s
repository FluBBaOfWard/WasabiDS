#ifdef __arm__

#include "ARM6502/M6502.i"
#include "KS5360/KS5360.i"

#define CYCLE_PSL (246*2)

	.global run
	.global stepFrame
	.global cpuInit
	.global cpuReset

	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global m6502_0

	.syntax unified
	.arm

#if GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
run:						;@ Return after X frame(s)
	.type run STT_FUNC
;@----------------------------------------------------------------------------
	ldrh r0,waitCountIn
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountIn
	bxne lr
	stmfd sp!,{r4-r11,lr}

;@----------------------------------------------------------------------------
runStart:
;@----------------------------------------------------------------------------
	ldr r0,=EMUinput
	ldr r0,[r0]
	ldr r3,joyClick
	eor r3,r3,r0
	and r3,r3,r0
	str r0,joyClick

//	tst r3,#0x04				;@ NDS Select?
//	tsteq r3,#0x800				;@ NDS Y?
//	ldrne r2,=systemMemory+0xB3
//	ldrbne r2,[r2]
//	tstne r2,#4					;@ Power button NMI enabled?
//	and r0,r3,#0x04				;@ NDS Select?

	bl refreshEMUjoypads

	ldr m6502ptr,=m6502_0
	add r1,m6502ptr,#m6502Regs
	ldmia r1,{m6502nz-m6502pc,m6502zpage}	;@ Restore M6502 state
;@----------------------------------------------------------------------------
svFrameLoop:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	bl m6502RunXCycles
	ldr svvptr,=ks5360_0
	bl svDoScanline
	cmp r0,#0
	bne svFrameLoop

;@----------------------------------------------------------------------------
	add r0,m6502ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}	;@ Save M6502 state
	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldrh r0,waitCountOut
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountOut
	ldmfdeq sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

;@----------------------------------------------------------------------------
m6502CyclesPerScanline:	.long 0
joyClick:			.long 0
frameTotal:			.long 0		;@ Let Gui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
stepFrame:					;@ Return after 1 frame
	.type stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr m6502ptr,=m6502_0
	add r1,m6502ptr,#m6502Regs
	ldmia r1,{m6502nz-m6502pc,m6502zpage}	;@ Restore M6502 state
;@----------------------------------------------------------------------------
svStepLoop:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	bl m6502RunXCycles
	ldr svvptr,=ks5360_0
	bl svDoScanline
	cmp r0,#0
	bne svStepLoop
;@----------------------------------------------------------------------------
	add r0,m6502ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}	;@ Save M6502 state

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
cpuInit:					;@ Called by machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r0,#CYCLE_PSL
	str r0,m6502CyclesPerScanline
	ldr r0,=m6502_0
	bl m6502Init

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
cpuReset:					;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=m6502_0
	bl m6502Reset

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
#ifdef NDS
	.section .dtcm, "ax", %progbits			;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits		;@ For the GBA
#else
	.section .text
#endif
	.align 2
;@----------------------------------------------------------------------------
m6502_0:
	.space m6502Size
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
