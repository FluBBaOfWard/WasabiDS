//
//  SVVideo.s
//  Watara Supervision video emulation for GBA/NDS.
//
//  Created by Fredrik Ahlström on 2004-11-30.
//  Copyright © 2004-2022 Fredrik Ahlström. All rights reserved.
//

#ifdef __arm__

#ifdef GBA
	#include "../Shared/gba_asm.h"
#elif NDS
	#include "../Shared/nds_asm.h"
#endif
#include "SVVideo.i"
#include "../ARM6502/M6502.i"

	.global svVideoInit
	.global svVideoReset
	.global svVideoSaveState
	.global svVideoLoadState
	.global svVideoGetStateSize
	.global svDoScanline
	.global copyScrollValues
	.global svConvertScreen
	.global svBufferWindows
	.global svRead
	.global svWrite
	.global svRefW
	.global svGetInterruptVector

	.syntax unified
	.arm

#if GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
svVideoInit:				;@ Only need to be called once
;@----------------------------------------------------------------------------
	mov r1,#0xffffff00			;@ Build chr decode tbl
	ldr r2,=CHR_DECODE			;@ 0x200
chrLutLoop:
	and r0,r1,#0x01
	tst r1,#0x02
	orrne r0,r0,#0x0002
	tst r1,#0x04
	orrne r0,r0,#0x0010
	tst r1,#0x08
	orrne r0,r0,#0x0020
	tst r1,#0x10
	orrne r0,r0,#0x0100
	tst r1,#0x20
	orrne r0,r0,#0x0200
	tst r1,#0x40
	orrne r0,r0,#0x1000
	tst r1,#0x80
	orrne r0,r0,#0x2000
	strh r0,[r2],#2
	adds r1,r1,#1
	bne chrLutLoop

;@----------------------------------------------------------------------------
makeTileBgr:
;@----------------------------------------------------------------------------
	mov r1,#BG_GFX
//	add r1,r1,#5*2
	mov r0,#0
	mov r2,#20
oLoop:
	mov r3,#24
bgrLoop:
	strh r0,[r1],#2
	add r0,r0,#1
	subs r3,r3,#1
	bne bgrLoop
	add r0,r0,#8
	add r1,r1,#8*2
	subs r2,r2,#1
	bne oLoop

	bx lr
;@----------------------------------------------------------------------------
svVideoReset:		;@ r0=NmiFunc, r1=IrqFunc, r2=ram+LUTs, r3=SOC 0=mono,1=color,2=crystal, r12=svvptr
;@----------------------------------------------------------------------------
	stmfd sp!,{r0-r3,lr}

	mov r0,svvptr
	ldr r1,=ks5360Size/4
	bl memclr_					;@ Clear KS5360 state

	ldr r2,=lineStateTable
	ldr r1,[r2],#4
	mov r0,#-1
	stmia svvptr,{r0-r2}		;@ Reset scanline, nextChange & lineState

	ldmfd sp!,{r0-r3,lr}
	cmp r0,#0
	adreq r0,dummyIrqFunc
	str r0,[svvptr,#nmiFunction]
	cmp r1,#0
	adreq r1,dummyIrqFunc
	str r1,[svvptr,#irqFunction]

	str r2,[svvptr,#gfxRAM]
	add r0,r2,#0x2200
	str r0,[svvptr,#paletteRAM]
	ldr r0,=SCROLL_BUFF
	str r0,[svvptr,#scrollBuff]

	strb r3,[svvptr,#wsvSOC]

	b svRegistersReset

dummyIrqFunc:
	bx lr
;@----------------------------------------------------------------------------
_debugIOUnmappedR:
;@----------------------------------------------------------------------------
	ldr r3,=debugIOUnmappedR
	bx r3
;@----------------------------------------------------------------------------
_debugIOUnimplR:
;@----------------------------------------------------------------------------
	ldr r3,=debugIOUnimplR
	bx r3
;@----------------------------------------------------------------------------
_debugIOUnmappedW:
;@----------------------------------------------------------------------------
	ldr r3,=debugIOUnmappedW
	bx r3
;@----------------------------------------------------------------------------
memCopy:
;@----------------------------------------------------------------------------
	ldr r3,=memcpy
;@----------------------------------------------------------------------------
thumbCallR3:
;@----------------------------------------------------------------------------
	bx r3
;@----------------------------------------------------------------------------
svRegistersReset:				;@ in r3=SOC
;@----------------------------------------------------------------------------
	adr r1,IO_Default
	mov r2,#0x30
	add r0,svvptr,#wsvRegs
	stmfd sp!,{svvptr,lr}
	bl memCopy
	ldmfd sp!,{svvptr,lr}
	ldrb r1,[svvptr,#wsvLCDYSize]
	b svRefW

;@----------------------------------------------------------------------------
IO_Default:
	.byte 0x00, 0xA0, 0x9d, 0xbb, 0x00, 0x00, 0x00, 0x26, 0xfe, 0xde, 0xf9, 0xfb, 0xdb, 0xd7, 0x7f, 0xf5
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0xc6, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x99, 0xfd, 0xb7, 0xdf
	.byte 0x30, 0x57, 0x75, 0x76, 0x15, 0x73, 0x77, 0x77, 0x20, 0x75, 0x50, 0x36, 0x70, 0x67, 0x50, 0x77

;@----------------------------------------------------------------------------
svVideoSaveState:		;@ In r0=destination, r1=svvptr. Out r0=state size.
	.type	svVideoSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r4,r0					;@ Store destination
	mov r5,r1					;@ Store svvptr (r1)

	add r1,r5,#ks5360State
	mov r2,#ks5360StateEnd-ks5360State
	bl memCopy

	ldmfd sp!,{r4,r5,lr}
	mov r0,#ks5360StateEnd-ks5360State
	bx lr
;@----------------------------------------------------------------------------
svVideoLoadState:		;@ In r0=svvptr, r1=source. Out r0=state size.
	.type	svVideoLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r5,r0					;@ Store svvptr (r0)
	mov r4,r1					;@ Store source

	add r0,r5,#ks5360State
	mov r2,#ks5360StateEnd-ks5360State
	bl memCopy

	bl clearDirtyTiles

	bl reBankSwitch89AB
	bl reBankSwitchCDEF

	ldmfd sp!,{r4,r5,lr}
;@----------------------------------------------------------------------------
svVideoGetStateSize:	;@ Out r0=state size.
	.type	svVideoGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#ks5360StateEnd-ks5360State
	bx lr

	.pool
;@----------------------------------------------------------------------------
#ifdef GBA
	.section .ewram,"ax"
#endif
;@----------------------------------------------------------------------------
svBufferWindows:
;@----------------------------------------------------------------------------
//	ldr r0,[svvptr,#wsvFgWinXPos]	;@ Win pos/size
	ldr r0,=0xA0A00000
	and r1,r0,#0x000000FF		;@ H start
	and r2,r0,#0x00FF0000		;@ H end
	cmp r1,#GAME_WIDTH
	movpl r1,#GAME_WIDTH
	add r1,r1,#(SCREEN_WIDTH-GAME_WIDTH)/2
	add r2,r2,#0x10000
	cmp r2,#GAME_WIDTH<<16
	movpl r2,#GAME_WIDTH<<16
	add r2,r2,#((SCREEN_WIDTH-GAME_WIDTH)/2)<<16
	cmp r2,r1,lsl#16
	orr r1,r1,r2,lsl#8
	mov r1,r1,ror#24
	movmi r1,#0
	strh r1,[svvptr,#windowData]

	and r1,r0,#0x0000FF00		;@ V start
	mov r2,r0,lsr#24			;@ V end
	cmp r1,#GAME_HEIGHT<<8
	movpl r1,#GAME_HEIGHT<<8
	add r1,r1,#((SCREEN_HEIGHT-GAME_HEIGHT)/2)<<8
	add r2,r2,#1
	cmp r2,#GAME_HEIGHT
	movpl r2,#GAME_HEIGHT
	add r2,r2,#(SCREEN_HEIGHT-GAME_HEIGHT)/2
	cmp r2,r1,lsr#8
	orr r1,r1,r2
	movmi r1,#0
	strh r1,[svvptr,#windowData+2]

	bx lr

;@----------------------------------------------------------------------------
svRead:		;@ I/O read
;@----------------------------------------------------------------------------
	sub r2,r0,#0x2000
	cmp r2,#0x30
	ldrmi pc,[pc,r2,lsl#2]
	b svUnknownR
io_read_tbl:
	.long svUnknownR	;@ 0x2000
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR	;@ 0x2008
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR	;@ 0x2010
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR	;@ 0x2018
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long joy0_R		;@ 2020: joypad
	.long _2021r		;@ IO port read
	.long _2022r
	.long _2023r		;@ Timer value
	.long _2024r
	.long _2025r
	.long _2026r
	.long _2027r
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR

;@----------------------------------------------------------------------------
svWSUnmappedR:
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	stmfd sp!,{svvptr,lr}
	bl _debugIOUnmappedR
	ldmfd sp!,{svvptr,lr}
	ldrb r0,[svvptr,#wsvSOC]
	cmp r0,#SOC_ASWAN
	moveq r0,#0x90
	movne r0,#0x00
	bx lr
;@----------------------------------------------------------------------------
svUnknownR:
;@----------------------------------------------------------------------------
	ldr r2,=0x826EBAD0
;@----------------------------------------------------------------------------
svImportantR:
	mov r11,r11					;@ No$GBA breakpoint
	stmfd sp!,{r0,svvptr,lr}
	bl _debugIOUnimplR
	ldmfd sp!,{r0,svvptr,lr}
;@----------------------------------------------------------------------------
svRegR:
	add r2,svvptr,#wsvRegs
	ldrb r0,[r2,r0]
	bx lr
	.pool

;@----------------------------------------------------------------------------
_2021r:		;@ IO port read
;@----------------------------------------------------------------------------
	ldrb r0,[svvptr,#wsvLinkPortDDR]
	bx lr
;@----------------------------------------------------------------------------
_2022r:		;@ Link Port Data read
;@----------------------------------------------------------------------------
	ldrb r0,[svvptr,#wsvLinkPortData]
	bx lr
;@----------------------------------------------------------------------------
_2023r:		;@ Timer value
;@----------------------------------------------------------------------------
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
_2024r:		;@ Timer IRQ clear?
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r0,[svvptr,#wsvIRQStatus]
	bic r0,r0,#1
	bl svSetInterruptStatus
	mov r0,#0
	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
_2025r:		;@ DMA IRQ clear?
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r0,[svvptr,#wsvIRQStatus]
	bic r0,r0,#2
	bl svSetInterruptStatus
	mov r0,#0
	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
_2026r:		;@ LCD & IRQs
;@----------------------------------------------------------------------------
	ldrb r0,[svvptr,#wsvSystemControl]
	bx lr
;@----------------------------------------------------------------------------
_2027r:		;@ IRQ bits
;@----------------------------------------------------------------------------
	ldrb r0,[svvptr,#wsvIRQStatus]
	bx lr

;@----------------------------------------------------------------------------
svWrite:	;@ I/O write
;@----------------------------------------------------------------------------
	sub r2,r0,#0x2000
	cmp r2,#0x30
	ldrmi pc,[pc,r2,lsl#2]
	b wsvImportantW
io_write_tbl:
	.long _2000w			;@ Horizontal screen size
	.long _2001w			;@ Vertical screen size
	.long _2002w			;@ Horizontal scroll
	.long _2003w			;@ Vertical scroll
	.long _2000w
	.long _2001w
	.long _2002w
	.long _2003w
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long _200Dw
	.long _200Ew
	.long _200Fw
	.long wsvImportantW		;@ Sound...
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long _2022w		;@ IO port write
	.long _2023w		;@ Timer value
	.long wsvImportantW
	.long wsvImportantW
	.long _2026w		;@ LCD & IRQs
	.long wsvImportantW
	.long wsvImportantW	;@ Sound DMA...
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW
	.long wsvImportantW

;@----------------------------------------------------------------------------
wsvUnknownW:
;@----------------------------------------------------------------------------
wsvImportantW:
;@----------------------------------------------------------------------------
	add r2,svvptr,#wsvRegs
	strb r1,[r2,r0]
	ldr r2,=debugIOUnimplW
	bx r2
;@----------------------------------------------------------------------------
wsvReadOnlyW:
;@----------------------------------------------------------------------------
wsvUnmappedW:
;@----------------------------------------------------------------------------
	b _debugIOUnmappedW
;@----------------------------------------------------------------------------
wsvRegW:
	add r2,svvptr,#wsvRegs
	strb r1,[r2,r0]
	bx lr

;@----------------------------------------------------------------------------
_2000w:
;@----------------------------------------------------------------------------
	strb r1,[svvptr,#wsvLCDXSize]
	bx lr
;@----------------------------------------------------------------------------
_2001w:
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
svRefW:					;@ 0x2001, Last scan line.
;@----------------------------------------------------------------------------
	strb r1,[svvptr,#wsvLCDYSize]
	cmp r1,#0x9E
	movmi r1,#0x9E
	cmp r1,#0xC8
	movpl r1,#0xC8
	add r1,r1,#1
	str r1,lineStateLastLine
	mov r0,r1
	b setScreenRefresh

;@----------------------------------------------------------------------------
_2002w:
;@----------------------------------------------------------------------------
	strb r1,[svvptr,#wsvXScroll]
	bx lr
;@----------------------------------------------------------------------------
_2003w:
;@----------------------------------------------------------------------------
	strb r1,[svvptr,#wsvYScroll]
	bx lr
;@----------------------------------------------------------------------------
_200Dw:		;@ Strange...
_200Ew:		;@ TV link palette?
_200Fw:		;@ TV link something
	bx lr
;@----------------------------------------------------------------------------
_2021w:		;@ IO port write
;@----------------------------------------------------------------------------
	strb r1,[svvptr,#wsvLinkPortDDR]
	bx lr
;@----------------------------------------------------------------------------
_2022w:		;@ Link Port Data write
;@----------------------------------------------------------------------------
	strb r1,[svvptr,#wsvLinkPortData]
	bx lr
;@----------------------------------------------------------------------------
_2023w:		;@ Timer value
;@----------------------------------------------------------------------------
	strb r1,[svvptr,#wsvIRQTimer]
	mov r1,r1,lsl#6
	str r1,[svvptr,#wsvTimerLatch]
	str r1,[svvptr,#wsvTimerValue]
	bx lr
;@----------------------------------------------------------------------------
_2026w:		;@ LCD & IRQs
;@----------------------------------------------------------------------------
	ldrb r0,[svvptr,#wsvSystemControl]
	strb r1,[svvptr,#wsvSystemControl]
	eor r0,r0,r1
	tst r0,#0xE0
	movne r1,r1,lsr#5
	mov addy,lr
	blne BankSwitch89AB_W
	mov lr,addy
	ldrb r0,[svvptr,#wsvSystemControl]

	mov r1,#0x2840		;@ WIN0, BG2 enable. DISPCNTBUFF startvalue. 0x2840
	tst r0,#0x08		;@ lcd en?
	orrne r1,r1,#0x0100

	adr r2,ctrl1Old
	swp r0,r1,[r2]		;@ r0=lastval

	adr r2,ctrl1Line
	ldr addy,[svvptr,#scanline]	;@ addy=scanline
	cmp addy,#159
	movhi addy,#159
	swp r1,addy,[r2]	;@ r1=lastline, lastline=scanline
ctrl1Finish:
//	ldr r2,=DISPCNTBUFF
	add r1,r2,r1,lsl#1
	add r2,r2,addy,lsl#1
ct1:
//	strh r0,[r2],#-2	;@ Fill backwards from scanline to lastline
//	cmp r2,r1
//	bpl ct1

	bx lr

ctrl1Old:	.long 0x2840	;@ Last write
ctrl1Line:	.long 0 		;@ When?


;@----------------------------------------------------------------------------
wsvDMACtrlW:				;@ 0x48, only WSC, word transfer. steals 5+2n cycles.
;@----------------------------------------------------------------------------
	and r1,r1,#0xC0
	strb r1,[svvptr,#wsvDMACtrl]
	tst r1,#0x80				;@ Start?
	bxeq lr

	stmfd sp!,{r4-r8,lr}
	and r8,r1,#0x40				;@ Inc/dec
	rsb r8,r8,#0x20
	mov r7,svvptr
	ldrh r4,[svvptr,#wsvDMASrcLow]

	ldrh r5,[svvptr,#wsvDMADstLow];@ r5=destination
	mov r5,r5,lsl#16

	sub cycles,cycles,#5*CYCLE
	ldrb r6,[svvptr,#wsvDMALen]	;@ r6=length
	mov r6,r6,lsl#7
	sub cycles,cycles,r6,lsl#CYC_SHIFT

dmaLoop:
	mov r0,r4,lsl#12
//	bl readMem20W
	mov r1,r0
	mov r0,r5,lsr#4
//	bl writeMem20W
	add r4,r4,r8,asr#4
	add r5,r5,r8,lsl#12
	subs r6,r6,#2
	bne dmaLoop

	mov svvptr,r7
	strh r4,[svvptr,#wsvDMASrcLow]
	mov r5,r5,lsr#16
	strh r5,[svvptr,#wsvDMADstLow]

	strb r6,[svvptr,#wsvDMALen]
	rsb r8,r8,#0x20
	strb r8,[svvptr,#wsvDMACtrl]
dmaEnd:

	ldmfd sp!,{r4-r8,lr}
	bx lr

;@----------------------------------------------------------------------------
newFrame:					;@ Called before line 0
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
endFrame:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
//	ldr r2,[svvptr,#wsvBgXScroll]
//	bl scrollCnt
	bl endFrameGfx

	ldrb r0,[svvptr,#wsvSystemControl]
	tst r0,#0x1						;@ VBlank timer enabled?
	beq noTimerVBlIrq
	mov lr,pc
	ldr pc,[svvptr,#nmiFunction]
noTimerVBlIrq:

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
frameEndHook:
	stmfd sp!,{lr}
	mov r0,#0
	mov lr,pc
	ldr pc,[svvptr,#nmiFunction]
	ldmfd sp!,{lr}

	mov r0,#0
	str r0,[svvptr,#scrollLine]

	adr r2,lineStateTable
	ldr r1,[r2],#4
	mov r0,#-1
	stmia svvptr,{r0-r2}		;@ Reset scanline, nextChange & lineState
	bx lr

;@----------------------------------------------------------------------------
lineStateTable:
	.long 0, newFrame			;@ zeroLine
	.long 160, endFrame			;@ After last visible scanline
lineStateLastLine:
	.long 164, frameEndHook		;@ totalScanlines
;@----------------------------------------------------------------------------
#ifdef GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
	.align 2
#endif
;@----------------------------------------------------------------------------
redoScanline:
;@----------------------------------------------------------------------------
	ldr r2,[svvptr,#lineState]
	ldmia r2!,{r0,r1}
	stmib svvptr,{r1,r2}		;@ Write nextLineChange & lineState
	stmfd sp!,{lr}
	mov lr,pc
	bx r0
	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
svDoScanline:
;@----------------------------------------------------------------------------
	ldmia svvptr,{r0,r1}		;@ Read scanLine & nextLineChange
	add r0,r0,#1
	cmp r0,r1
	bpl redoScanline
	str r0,[svvptr,#scanline]
;@----------------------------------------------------------------------------
checkScanlineIRQ:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r0,[svvptr,#wsvIRQStatus]

	ldr r1,[svvptr,#wsvTimerValue]
	ldrb r2,[svvptr,#wsvSystemControl]
	tst r2,#0x10
	subseq r1,r1,#64
	subsne r1,r1,#1
	str r1,[svvptr,#wsvTimerValue]
	bpl noHBlIrq
	orr r0,r0,#0x01				;@ #0 = Timer IRQ
noHBlIrq:
	bl svSetInterruptStatus

	ldr r0,[svvptr,#scanline]
	subs r0,r0,#144				;@ Return from emulation loop on this scanline
	movne r0,#1
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
svSetInterruptStatus:		;@ r0 = interrupt status
;@----------------------------------------------------------------------------
	ldrb r2,[svvptr,#wsvIRQStatus]
	cmp r0,r2
	bxeq lr
	strb r0,[svvptr,#wsvIRQStatus]
	ldrb r1,[svvptr,#wsvSystemControl]
svUpdateIrqEnable:
	and r0,r0,r1,lsr#1
	ldr pc,[svvptr,#irqFunction]

;@----------------------------------------------------------------------------
copyScrollValues:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6}
	ldr r1,[svvptr,#scrollBuff]

	mov r2,#(SCREEN_HEIGHT-GAME_HEIGHT)/2
	add r0,r0,r2,lsl#3			;@ 8 bytes per row
	mov r3,#0x100-(SCREEN_WIDTH-GAME_WIDTH)/2
	sub r3,r3,r2,lsl#16
	ldr r4,=0x00FF00FF
	mov r2,#GAME_HEIGHT
setScrlLoop:
	ldr r5,[r1],#4
	mov r6,r5,lsr#16
	mov r5,r5,lsl#16
	orr r6,r6,r6,lsl#8
	orr r5,r5,r5,lsr#8
	and r6,r4,r6
	and r5,r4,r5,lsr#8
	add r6,r6,r3
	add r5,r5,r3
	stmia r0!,{r5,r6}
	subs r2,r2,#1
	bne setScrlLoop

	ldmfd sp!,{r4-r6}
	bx lr

;@----------------------------------------------------------------------------
svConvertScreen:	;@ In r0 = dest
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r7}

	ldr r4,=CHR_DECODE
	ldr r2,[svvptr,#gfxRAM]

	mov r7,#20				;@ 20 tiles high screen
scLoop:
	mov r6,#8				;@ 8 pix high tiles
tiLoop:
	mov r5,#24				;@ 24*8=192 pix
rwLoop:
	ldrb r3,[r2],#1			;@ Read 4 1st pixels
	mov r3,r3,lsl#1
	ldrh r3,[r4,r3]
	ldrb r1,[r2],#1			;@ Read 4 more pixels
	mov r1,r1,lsl#1
	ldrh r1,[r4,r1]
	orr r3,r3,r1,lsl#16
	str r3,[r0],#32
	subs r5,r5,#1
	bne rwLoop

	sub r0,r0,#32*24
	add r0,r0,#4
	subs r6,r6,#1
	bne tiLoop

	add r0,r0,#32*31
	subs r7,r7,#1
	bne scLoop

	ldmfd sp!,{r3-r7}
	bx lr


;@----------------------------------------------------------------------------
#ifdef GBA
	.section .sbss				;@ For the GBA
#else
	.section .bss
#endif
	.align 2
CHR_DECODE:
	.space 0x200
SCROLL_BUFF:
	.space 160*4

#endif // #ifdef __arm__
