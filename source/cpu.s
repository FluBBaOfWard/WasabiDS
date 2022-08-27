#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARM6502/M6502mac.h"
#include "KS5360/SVVideo.i"

#define CYCLE_PSL (240)

	.global run
	.global cpuInit
	.global cpuReset
	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
run:		;@ Return after X frame(s)
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
//	ldr v30ptr,=V30OpTable
//	bl V30SetNMIPin

	bl refreshEMUjoypads
skipInput:
	ldr m6502optbl,=m6502OpTable
	add r1,m6502optbl,#m6502Regs
	ldmia r1,{m6502nz-m6502pc,m6502zpage}	;@ Restore M6502 state
;@----------------------------------------------------------------------------
svFrameLoop:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	b m6502RunXCycles
svM6502End:
	ldr svvptr,=ks5360_0
	bl svDoScanline
	cmp r0,#0
	bne svFrameLoop

;@----------------------------------------------------------------------------
	add r0,m6502optbl,#m6502Regs
	stmia r0,{m6502nz-m6502pc,m6502zpage}	;@ Save M6502 state
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
frameTotal:			.long 0		;@ Let ui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
cpuInit:					;@ Called by machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{m6502optbl,lr}
	ldr m6502optbl,=m6502OpTable

	mov r0,#CYCLE_PSL
	str r0,m6502CyclesPerScanline
//	mov r0,m6502optbl
//	bl V30Init

	ldmfd sp!,{m6502optbl,lr}
	bx lr
;@----------------------------------------------------------------------------
cpuReset:					;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{m6502optbl,lr}
	ldr m6502optbl,=m6502OpTable

	adr r0,svM6502End
	str r0,[m6502optbl,#m6502NextTimeout]
	str r0,[m6502optbl,#m6502NextTimeout_]

	mov r0,m6502optbl
	mov r0,#0
	bl m6502Reset

	ldmfd sp!,{m6502optbl,lr}
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
