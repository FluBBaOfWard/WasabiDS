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
	.global svConvertTileMaps
	.global svConvertSprites
	.global svBufferWindows
	.global svRead
	.global svWrite
	.global svRefW
	.global svGetInterruptVector
	.global svSetInterruptExternal

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
	ldr r2,=CHR_DECODE			;@ 0x400
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

	bx lr
;@----------------------------------------------------------------------------
svVideoReset:		;@ r0=IrqFunc, r1=, r2=ram+LUTs, r3=SOC 0=mono,1=color,2=crystal, r12=spxptr
;@----------------------------------------------------------------------------
	stmfd sp!,{r0-r3,lr}

	mov r0,spxptr
	ldr r1,=sphinxSize/4
	bl memclr_					;@ Clear Sphinx state

	ldr r2,=lineStateTable
	ldr r1,[r2],#4
	mov r0,#-1
	stmia spxptr,{r0-r2}		;@ Reset scanline, nextChange & lineState

	ldmfd sp!,{r0-r3,lr}
	cmp r0,#0
	adreq r0,dummyIrqFunc
	str r0,[spxptr,#irqFunction]

	str r2,[spxptr,#gfxRAM]
	add r0,r2,#0xFE00
	str r0,[spxptr,#paletteRAM]
	ldr r0,=SCROLL_BUFF
	str r0,[spxptr,#scrollBuff]

	strb r3,[spxptr,#wsvSOC]

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
//	cmp r3,#SOC_SPHINX
//	adreq r1,WSC_IO_Default
//	adrhi r1,SC_IO_Default
	mov r2,#0x100
	add r0,spxptr,#wsvRegs
	stmfd sp!,{spxptr,lr}
	bl memCopy
	ldmfd sp!,{spxptr,lr}
	ldrb r1,[spxptr,#wsvSOC]
	cmp r1,#SOC_ASWAN
	mov r0,#0x84
	movne r0,#0x86
	strb r0,[spxptr,#wsvSystemCtrl1]
	ldrb r1,[spxptr,#wsvTotalLines]
	b svRefW

;@----------------------------------------------------------------------------
IO_Default:
	.byte 0x00, 0x00, 0x9d, 0xbb, 0x00, 0x00, 0x00, 0x26, 0xfe, 0xde, 0xf9, 0xfb, 0xdb, 0xd7, 0x7f, 0xf5
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x9e, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x99, 0xfd, 0xb7, 0xdf
	.byte 0x30, 0x57, 0x75, 0x76, 0x15, 0x73, 0x77, 0x77, 0x20, 0x75, 0x50, 0x36, 0x70, 0x67, 0x50, 0x77
	.byte 0x57, 0x54, 0x75, 0x77, 0x75, 0x17, 0x37, 0x73, 0x50, 0x57, 0x60, 0x77, 0x70, 0x77, 0x10, 0x73
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00
	.byte 0x84, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4f, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xdb, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x42, 0x00, 0x83, 0x00
// Cartridge
	.byte 0x2f, 0x3f, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1
	.byte 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1
	.byte 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1
	.byte 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1

;@----------------------------------------------------------------------------
svVideoSaveState:		;@ In r0=destination, r1=spxptr. Out r0=state size.
	.type	svVideoSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r4,r0					;@ Store destination
	mov r5,r1					;@ Store spxptr (r1)

	add r1,r5,#sphinxState
	mov r2,#sphinxStateEnd-sphinxState
	bl memCopy

	ldmfd sp!,{r4,r5,lr}
	mov r0,#sphinxStateEnd-sphinxState
	bx lr
;@----------------------------------------------------------------------------
svVideoLoadState:		;@ In r0=spxptr, r1=source. Out r0=state size.
	.type	svVideoLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r5,r0					;@ Store spxptr (r0)
	mov r4,r1					;@ Store source

	add r0,r5,#sphinxState
	mov r2,#sphinxStateEnd-sphinxState
	bl memCopy

	ldr r0,=DIRTYTILES
	mov r1,#0
	mov r2,#0x800
	bl memset

	mov spxptr,r5
	bl drawFrameGfx

	bl reBankSwitch89AB
	bl reBankSwitchCDEF

	ldmfd sp!,{r4,r5,lr}
;@----------------------------------------------------------------------------
svVideoGetStateSize:	;@ Out r0=state size.
	.type	svVideoGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#sphinxStateEnd-sphinxState
	bx lr

	.pool
;@----------------------------------------------------------------------------
#ifdef GBA
	.section .ewram,"ax"
#endif
;@----------------------------------------------------------------------------
svBufferWindows:
;@----------------------------------------------------------------------------
	ldr r0,[spxptr,#wsvFgWinXPos]	;@ Win pos/size
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
	strh r1,[spxptr,#windowData]

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
	strh r1,[spxptr,#windowData+2]

	bx lr

;@----------------------------------------------------------------------------
IO_R:		;@ I/O read
;@----------------------------------------------------------------------------
	sub r2,addy,#0x2000
	cmp r2,#0x2B
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
	.long svUnknownR
	.long _2023r		;@ Timer value
	.long _2024r
	.long _2025r
	.long _2026r
	.long _2027r
	.long svUnknownR
	.long svUnknownR
	.long svUnknownR

;@----------------------------------------------------------------------------
_2021r:		;@ IO port read
;@----------------------------------------------------------------------------
//	ldrb r0,sv_ioport
	bx lr
;@----------------------------------------------------------------------------
_2023r:		;@ Timer value
;@----------------------------------------------------------------------------
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
_2024r:		;@ Timer IRQ clear?
;@----------------------------------------------------------------------------
//	ldrb r0,irq_r
	bic r0,r0,#1
//	strb r0,irq_r
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
_2025r:		;@ DMA IRQ clear?
;@----------------------------------------------------------------------------
//	ldrb r0,irq_r
	bic r0,r0,#2
//	strb r0,irq_r
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
_2026r:		;@ LCD & IRQs
;@----------------------------------------------------------------------------
//	ldrb r0,lcdctrl
	bx lr
;@----------------------------------------------------------------------------
_2027r:		;@ IRQ bits
;@----------------------------------------------------------------------------
//	ldrb r0,irq_r
	bx lr
;@----------------------------------------------------------------------------
IO_W:		;@ I/O write
;@----------------------------------------------------------------------------
	sub r2,addy,#0x2000
	cmp r2,#0x2B
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


;@----------------------------------------------------------------------------
_2000w:
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
_2001w:
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
_2002w:
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
_2003w:
;@----------------------------------------------------------------------------
	bx lr

;@----------------------------------------------------------------------------
_200Dw:		;@ Strange...
_200Ew:		;@ TV link palette?
_200Fw:		;@ TV link something
	bx lr
;@----------------------------------------------------------------------------
_2022w:		;@ IO port write
;@----------------------------------------------------------------------------
//	strb r0,sv_ioport
	bx lr
;@----------------------------------------------------------------------------
_2023w:		;@ Timer value
;@----------------------------------------------------------------------------
	mov r0,r0,lsl#6
//	str r0,timerlatch
//	str r0,timerval
	bx lr
;@----------------------------------------------------------------------------
_2026w:		;@ LCD & IRQs
;@----------------------------------------------------------------------------
	ldrb r1,[svvptr,#lcdCtrl]
	strb r0,[svvptr,#lcdCtrl]
	eor r1,r0,r1
	tst r1,#0xE0
	movne r0,r0,lsr#5
	movne addy,lr
	blne BankSwitch89AB_W
	movne lr,addy
	ldrb r0,[svvptr,#lcdCtrl]

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
	strh r0,[r2],#-2	;@ Fill backwards from scanline to lastline
	cmp r2,r1
	bpl ct1

	bx lr

ctrl1Old:	.long 0x2840	;@ Last write
ctrl1Line:	.long 0 		;@ When?


;@----------------------------------------------------------------------------
svReadHigh:					;@ I/O read (0x0100-0xFFFF)
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,spxptr,lr}
	bl _debugIOUnmappedR
	ldmfd sp!,{r0,spxptr,lr}
	and r0,r0,#0xFF
;@----------------------------------------------------------------------------
svRead:						;@ I/O read (0x00-0xBF)
;@----------------------------------------------------------------------------
	cmp r0,#0x100
	ldrmi pc,[pc,r0,lsl#2]
	b svReadHigh
IN_Table:
	.long svRegR				;@ 0x00 Display control
	.long svRegR				;@ 0x01 Background color
	.long svVCountR				;@ 0x02 Current scan line
	.long svRegR				;@ 0x03 Scan line compare
	.long svRegR				;@ 0x04 Sprite table address
	.long svRegR				;@ 0x05 Sprite to start with
	.long svRegR				;@ 0x06 Sprite count
	.long svRegR				;@ 0x07 Map table address
	.long svRegR				;@ 0x08 Window X-Position
	.long svRegR				;@ 0x09 Window Y-Position
	.long svRegR				;@ 0x0A Window X-Size
	.long svRegR				;@ 0x0B Window Y-Size
	.long svRegR				;@ 0x0C Sprite window X-Position
	.long svRegR				;@ 0x0D Sprite window Y-Position
	.long svRegR				;@ 0x0E Sprite window X-Size
	.long svRegR				;@ 0x0F Sprite window Y-Size

	.long svRegR				;@ 0x10 Bg scroll X
	.long svRegR				;@ 0x11 Bg scroll Y
	.long svRegR				;@ 0x12 Fg scroll X
	.long svRegR				;@ 0x13 Fg scroll Y
	.long svRegR				;@ 0x14 LCD control (on/off?)
	.long svRegR				;@ 0x15 LCD icons
	.long svRegR				;@ 0x16 Total scan lines
	.long svRegR				;@ 0x17 Vsync line
	.long svWSUnmappedR			;@ 0x18 ---
	.long svWSUnmappedR			;@ 0x19 ---
	.long svUnknownR			;@ 0x1A ???
	.long svWSUnmappedR			;@ 0x1B ---
	.long svRegR				;@ 0x1C Pal mono pool 0
	.long svRegR				;@ 0x1D Pal mono pool 1
	.long svRegR				;@ 0x1E Pal mono pool 2
	.long svRegR				;@ 0x1F Pal mono pool 3

	.long svRegR				;@ 0x20 Pal mono 0 low
	.long svRegR				;@ 0x21 Pal mono 0 high
	.long svRegR				;@ 0x22 Pal mono 1 low
	.long svRegR				;@ 0x23 Pal mono 1 high
	.long svRegR				;@ 0x24 Pal mono 2 low
	.long svRegR				;@ 0x25 Pal mono 2 high
	.long svRegR				;@ 0x26 Pal mono 3 low
	.long svRegR				;@ 0x27 Pal mono 3 high
	.long svRegR				;@ 0x28 Pal mono 4 low
	.long svRegR				;@ 0x29 Pal mono 4 high
	.long svRegR				;@ 0x2A Pal mono 5 low
	.long svRegR				;@ 0x2B Pal mono 5 high
	.long svRegR				;@ 0x2C Pal mono 6 low
	.long svRegR				;@ 0x2D Pal mono 6 high
	.long svRegR				;@ 0x2E Pal mono 7 low
	.long svRegR				;@ 0x2F Pal mono 7 high

	.long svRegR				;@ 0x30 Pal mono 8 low
	.long svRegR				;@ 0x31 Pal mono 8 high
	.long svRegR				;@ 0x32 Pal mono 9 low
	.long svRegR				;@ 0x33 Pal mono 9 high
	.long svRegR				;@ 0x34 Pal mono A low
	.long svRegR				;@ 0x35 Pal mono A high
	.long svRegR				;@ 0x36 Pal mono B low
	.long svRegR				;@ 0x37 Pal mono B high
	.long svRegR				;@ 0x38 Pal mono C low
	.long svRegR				;@ 0x39 Pal mono C high
	.long svRegR				;@ 0x3A Pal mono D low
	.long svRegR				;@ 0x3B Pal mono D high
	.long svRegR				;@ 0x3C Pal mono E low
	.long svRegR				;@ 0x3D Pal mono E high
	.long svRegR				;@ 0x3E Pal mono F low
	.long svRegR				;@ 0x3F Pal mono F high
			;@ DMA registers, only WSC
	.long svRegR				;@ 0x40 DMA source
	.long svRegR				;@ 0x41 DMA source
	.long svRegR				;@ 0x42 DMA source
	.long svWSUnmappedR			;@ 0x43 ---
	.long svRegR				;@ 0x44 DMA destination
	.long svRegR				;@ 0x45 DMA destination
	.long svRegR				;@ 0x46 DMA length
	.long svRegR				;@ 0x47 DMA length
	.long svImportantR			;@ 0x48 DMA control
	.long svWSUnmappedR			;@ 0x49 ---
	.long svRegR				;@ 0x4A Sound DMA source
	.long svRegR				;@ 0x4B Sound DMA source
	.long svRegR				;@ 0x4C Sound DMA source
	.long svWSUnmappedR			;@ 0x4D ---
	.long svRegR				;@ 0x4E Sound DMA length
	.long svRegR				;@ 0x4F Sound DMA length

	.long svRegR				;@ 0x50 Sound DMA length
	.long svWSUnmappedR			;@ 0x51 ---
	.long svRegR				;@ 0x52 Sound DMA control
	.long svWSUnmappedR			;@ 0x53 ---
	.long svWSUnmappedR			;@ 0x54 ---
	.long svWSUnmappedR			;@ 0x55 ---
	.long svWSUnmappedR			;@ 0x56 ---
	.long svWSUnmappedR			;@ 0x57 ---
	.long svWSUnmappedR			;@ 0x58 ---
	.long svWSUnmappedR			;@ 0x59 ---
	.long svWSUnmappedR			;@ 0x5A ---
	.long svWSUnmappedR			;@ 0x5B ---
	.long svWSUnmappedR			;@ 0x5C ---
	.long svWSUnmappedR			;@ 0x5D ---
	.long svWSUnmappedR			;@ 0x5E ---
	.long svWSUnmappedR			;@ 0x5F ---

	.long svRegR				;@ 0x60 Display mode
	.long svWSUnmappedR			;@ 0x61 ---
	.long svImportantR			;@ 0x62 WSC System / Power
	.long svWSUnmappedR			;@ 0x63 ---
	.long svWSUnmappedR			;@ 0x64 ---
	.long svWSUnmappedR			;@ 0x65 ---
	.long svWSUnmappedR			;@ 0x66 ---
	.long svWSUnmappedR			;@ 0x67 ---
	.long svWSUnmappedR			;@ 0x68 ---
	.long svWSUnmappedR			;@ 0x69 ---
	.long svImportantR			;@ 0x6A Hyper control
	.long svImportantR			;@ 0x6B Hyper Chan control
	.long svWSUnmappedR			;@ 0x6C ---
	.long svWSUnmappedR			;@ 0x6D ---
	.long svWSUnmappedR			;@ 0x6E ---
	.long svWSUnmappedR			;@ 0x6F ---

	.long svImportantR			;@ 0x70 Unknown70
	.long svImportantR			;@ 0x71 Unknown71
	.long svImportantR			;@ 0x72 Unknown72
	.long svImportantR			;@ 0x73 Unknown73
	.long svImportantR			;@ 0x74 Unknown74
	.long svImportantR			;@ 0x75 Unknown75
	.long svImportantR			;@ 0x76 Unknown76
	.long svImportantR			;@ 0x77 Unknown77
	.long svWSUnmappedR			;@ 0x78 ---
	.long svWSUnmappedR			;@ 0x79 ---
	.long svWSUnmappedR			;@ 0x7A ---
	.long svWSUnmappedR			;@ 0x7B ---
	.long svWSUnmappedR			;@ 0x7C ---
	.long svWSUnmappedR			;@ 0x7D ---
	.long svWSUnmappedR			;@ 0x7E ---
	.long svWSUnmappedR			;@ 0x7F ---

	.long svRegR				;@ 0x80 Sound Ch1 pitch low
	.long svRegR				;@ 0x81 Sound Ch1 pitch high
	.long svRegR				;@ 0x82 Sound Ch2 pitch low
	.long svRegR				;@ 0x83 Sound Ch2 pitch high
	.long svRegR				;@ 0x84 Sound Ch3 pitch low
	.long svRegR				;@ 0x85 Sound Ch3 pitch high
	.long svRegR				;@ 0x86 Sound Ch4 pitch low
	.long svRegR				;@ 0x87 Sound Ch4 pitch high
	.long svRegR				;@ 0x88 Sound Ch1 volume
	.long svRegR				;@ 0x89 Sound Ch2 volume
	.long svRegR				;@ 0x8A Sound Ch3 volume
	.long svRegR				;@ 0x8B Sound Ch4 volume
	.long svRegR				;@ 0x8C Sweeep value
	.long svRegR				;@ 0x8D Sweep time
	.long svRegR				;@ 0x8E Noise control
	.long svRegR				;@ 0x8F Wave base

	.long svRegR				;@ 0x90 Sound control
	.long svRegR				;@ 0x91 Sound output
	.long svImportantR			;@ 0x92 Noise LFSR value low
	.long svImportantR			;@ 0x93 Noise LFSR value high
	.long svRegR				;@ 0x94 Sound voice control
	.long svRegR				;@ 0x95 Sound Hyper voice
	.long svUnknownR			;@ 0x96 SND9697
	.long svUnknownR			;@ 0x97 SND9697
	.long svUnknownR			;@ 0x98 SND9899
	.long svUnknownR			;@ 0x99 SND9899
	.long svUnknownR			;@ 0x9A SND9A
	.long svUnknownR			;@ 0x9B SND9B
	.long svUnknownR			;@ 0x9C SND9C
	.long svUnknownR			;@ 0x9D SND9D
	.long svImportantR			;@ 0x9E HW Volume
	.long svWSUnmappedR			;@ 0x9F ---

	.long svRegR				;@ 0xA0 Color or mono HW
	.long svWSUnmappedR			;@ 0xA1 ---
	.long svRegR				;@ 0xA2 Timer Control
	.long svUnknownR			;@ 0xA3 ???
	.long svRegR				;@ 0xA4 HBlankTimer low
	.long svRegR				;@ 0xA5 HBlankTimer high
	.long svRegR				;@ 0xA6 VBlankTimer low
	.long svRegR				;@ 0xA7 VBlankTimer high
	.long svRegR				;@ 0xA8 HBlankTimer counter low
	.long svRegR				;@ 0xA9 HBlankTimer counter high
	.long svRegR				;@ 0xAA VBlankTimer counter low
	.long svRegR				;@ 0xAB VBlankTimer counter high
	.long svUnknownR			;@ 0xAC ???
	.long svWSUnmappedR			;@ 0xAD ---
	.long svWSUnmappedR			;@ 0xAE ---
	.long svWSUnmappedR			;@ 0xAF ---

	.long svRegR				;@ 0xB0 Interrupt base
	.long svImportantR			;@ 0xB1 Serial data
	.long svRegR				;@ 0xB2 Interrupt enable
	.long svSerialStatusR		;@ 0xB3 Serial status
	.long svRegR				;@ 0xB4 Interrupt status
	.long joy0_R				;@ 0xB5 keypad
	.long svZeroR				;@ 0xB6 Interrupt acknowledge
	.long svUnknownR			;@ 0xB7 ??? NMI ctrl?
	.long svWSUnmappedR			;@ 0xB8 ---
	.long svWSUnmappedR			;@ 0xB9 ---
	.long svUnknownR			;@ 0xBA
	.long svUnknownR			;@ 0xBB
	.long svUnknownR			;@ 0xBC
	.long svUnknownR			;@ 0xBD
	.long svUnknownR			;@ 0xBE
	.long svUnknownR			;@ 0xBF ???

;@----------------------------------------------------------------------------
;@Cartridge					;@ I/O read cart (0xC0-0xFF)
;@----------------------------------------------------------------------------

	.long BankSwitch4_F_R		;@ 0xC0 Bank ROM 0x40000-0xF0000
	.long BankSwitch1_R			;@ 0xC1 Bank SRAM 0x10000
	.long BankSwitch2_R			;@ 0xC2 Bank ROM 0x20000
	.long BankSwitch3_R			;@ 0xC3 Bank ROM 0x30000
	.long svImportantR			;@ 0xC4 ext-eeprom data low
	.long svImportantR			;@ 0xC5 ext-eeprom data high
	.long svImportantR			;@ 0xC6 ext-eeprom address low
	.long svImportantR			;@ 0xC7 ext-eeprom address high
	.long svImportantR			;@ 0xC8 ext-eeprom status
	.long svUnknownR			;@ 0xC9 ???
	.long svImportantR			;@ 0xCA RTC status
	.long svImportantR			;@ 0xCB RTC data read
	.long svImportantR			;@ 0xCC General purpose input/output enable, bit 3-0.
	.long svImportantR			;@ 0xCD General purpose input/output data, bit 3-0.
	.long svImportantR			;@ 0xCE WonderWitch flash
	.long svRegR				;@ 0xCF Alias to 0xC0

	.long svRegR				;@ 0xD0 Alias to 0xC1
	.long svRegR				;@ 0xD1 2 more bits for 0xC1
	.long svRegR				;@ 0xD2 Alias to 0xC2
	.long svRegR				;@ 0xD3 2 more bits for 0xC2
	.long svRegR				;@ 0xD4 Alias to 0xC3
	.long svRegR				;@ 0xD5 2 more bits for 0xC3
	.long svUnknownR			;@ 0xD6 ???
	.long svUnknownR			;@ 0xD7 ???
	.long svUnknownR			;@ 0xD8 ???
	.long svUnknownR			;@ 0xD9 ???
	.long svUnknownR			;@ 0xDA ???
	.long svUnknownR			;@ 0xDB ???
	.long svUnknownR			;@ 0xDC ???
	.long svUnknownR			;@ 0xDD ???
	.long svUnknownR			;@ 0xDE ???
	.long svUnknownR			;@ 0xDF ???

	.long svUnknownR			;@ 0xE0 ???
	.long svUnknownR			;@ 0xE1 ???
	.long svUnknownR			;@ 0xE2 ???
	.long svUnknownR			;@ 0xE3 ???
	.long svUnknownR			;@ 0xE4 ???
	.long svUnknownR			;@ 0xE5 ???
	.long svUnknownR			;@ 0xE6 ???
	.long svUnknownR			;@ 0xE7 ???
	.long svUnknownR			;@ 0xE8 ???
	.long svUnknownR			;@ 0xE9 ???
	.long svUnknownR			;@ 0xEA ???
	.long svUnknownR			;@ 0xEB ???
	.long svUnknownR			;@ 0xEC ???
	.long svUnknownR			;@ 0xED ???
	.long svUnknownR			;@ 0xEE ???
	.long svUnknownR			;@ 0xEF ???

	.long svUnknownR			;@ 0xF0 ???
	.long svUnknownR			;@ 0xF1 ???
	.long svUnknownR			;@ 0xF2 ???
	.long svUnknownR			;@ 0xF3 ???
	.long svUnknownR			;@ 0xF4 ???
	.long svUnknownR			;@ 0xF5 ???
	.long svUnknownR			;@ 0xF6 ???
	.long svUnknownR			;@ 0xF7 ???
	.long svUnknownR			;@ 0xF8 ???
	.long svUnknownR			;@ 0xF9 ???
	.long svUnknownR			;@ 0xFA ???
	.long svUnknownR			;@ 0xFB ???
	.long svUnknownR			;@ 0xFC ???
	.long svUnknownR			;@ 0xFD ???
	.long svUnknownR			;@ 0xFE ???
	.long svUnknownR			;@ 0xFF ???
;@----------------------------------------------------------------------------
svWSUnmappedR:
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	stmfd sp!,{spxptr,lr}
	bl _debugIOUnmappedR
	ldmfd sp!,{spxptr,lr}
	ldrb r0,[spxptr,#wsvSOC]
	cmp r0,#SOC_ASWAN
	moveq r0,#0x90
	movne r0,#0x00
	bx lr
;@----------------------------------------------------------------------------
svZeroR:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	bl _debugIOUnmappedR
	ldmfd sp!,{lr}
	mov r0,#0x00
	bx lr
;@----------------------------------------------------------------------------
svUnknownR:
;@----------------------------------------------------------------------------
	ldr r2,=0x826EBAD0
;@----------------------------------------------------------------------------
svImportantR:
	mov r11,r11					;@ No$GBA breakpoint
	stmfd sp!,{r0,spxptr,lr}
	bl _debugIOUnimplR
	ldmfd sp!,{r0,spxptr,lr}
;@----------------------------------------------------------------------------
svRegR:
	add r2,spxptr,#wsvRegs
	ldrb r0,[r2,r0]
	bx lr
	.pool
;@----------------------------------------------------------------------------
svVCountR:					;@ 0x03
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,#scanline]
	bx lr
;@----------------------------------------------------------------------------
svSerialStatusR:			;@ 0xB3
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,#wsvSerialStatus]
	and r0,r0,#0xE0				;@ Mask out write bits.
	orr r0,r0,#4				;@ Hack! Send buffer always empty.
	bx lr

;@----------------------------------------------------------------------------
BankSwitch4_F_R:			;@ 0xC0
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk0SlctX]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch1_R:				;@ 0xC1
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk1SlctX]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch2_R:				;@ 0xC2
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk2SlctX]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch3_R:				;@ 0xC3
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk3SlctX]
	bx lr

;@----------------------------------------------------------------------------
svWriteHigh:				;@ I/O write (0x0100-0xFFFF)
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,spxptr,lr}
	bl _debugIOUnmappedW
	ldmfd sp!,{r0,r1,spxptr,lr}
	and r0,r0,#0xFF
;@----------------------------------------------------------------------------
svWrite:					;@ I/O write (0x00-0xBF)
;@----------------------------------------------------------------------------
	cmp r0,#0x100
	ldrmi pc,[pc,r0,lsl#2]
	b svWriteHigh
OUT_Table:
	.long wsvRegW				;@ 0x00 Display control
	.long wsvRegW				;@ 0x01 Background color
	.long wsvReadOnlyW			;@ 0x02 Current scan line
	.long wsvRegW				;@ 0x03 Scan line compare
	.long wsvRegW				;@ 0x04 Sprite table address
	.long wsvSpriteFirstW		;@ 0x05 Sprite to start with
	.long wsvRegW				;@ 0x06 Sprite count
	.long wsvRegW				;@ 0x07 Map table address
	.long wsvRegW				;@ 0x08 Window X-Position
	.long wsvRegW				;@ 0x09 Window Y-Position
	.long wsvRegW				;@ 0x0A Window X-Size
	.long wsvRegW				;@ 0x0B Window Y-Size
	.long wsvRegW				;@ 0x0C Sprite window X-Position
	.long wsvRegW				;@ 0x0D Sprite window Y-Position
	.long wsvRegW				;@ 0x0E Sprite window X-Size
	.long wsvRegW				;@ 0x0F Sprite window Y-Size

	.long wsvBgScrXW			;@ 0x10 Bg scroll X
	.long wsvBgScrYW			;@ 0x11 Bg scroll Y
	.long wsvFgScrXW			;@ 0x12 Fg scroll X
	.long wsvFgScrYW			;@ 0x13 Fg scroll Y
	.long wsvRegW				;@ 0x14 LCD control (on/off?)
	.long wsvLCDIconW			;@ 0x15 LCD icons
	.long svRefW				;@ 0x16 Total scan lines
	.long wsvRegW				;@ 0x17 Vsync line
	.long wsvUnmappedW			;@ 0x18 ---
	.long wsvUnmappedW			;@ 0x19 ---
	.long wsvUnknownW			;@ 0x1A ???
	.long wsvUnmappedW			;@ 0x1B ---
	.long wsvRegW				;@ 0x1C Pal mono pool 0
	.long wsvRegW				;@ 0x1D Pal mono pool 1
	.long wsvRegW				;@ 0x1E Pal mono pool 2
	.long wsvRegW				;@ 0x1F Pal mono pool 3

	.long wsvRegW				;@ 0x20 Pal mono 0 low
	.long wsvRegW				;@ 0x21 Pal mono 0 high
	.long wsvRegW				;@ 0x22 Pal mono 1 low
	.long wsvRegW				;@ 0x23 Pal mono 1 high
	.long wsvRegW				;@ 0x24 Pal mono 2 low
	.long wsvRegW				;@ 0x25 Pal mono 2 high
	.long wsvRegW				;@ 0x26 Pal mono 3 low
	.long wsvRegW				;@ 0x27 Pal mono 3 high
	.long wsvRegW				;@ 0x28 Pal mono 4 low
	.long wsvRegW				;@ 0x29 Pal mono 4 high
	.long wsvRegW				;@ 0x2A Pal mono 5 low
	.long wsvRegW				;@ 0x2B Pal mono 5 high
	.long wsvRegW				;@ 0x2C Pal mono 6 low
	.long wsvRegW				;@ 0x2D Pal mono 6 high
	.long wsvRegW				;@ 0x2E Pal mono 7 low
	.long wsvRegW				;@ 0x2F Pal mono 7 high

	.long wsvRegW				;@ 0x30 Pal mono 8 low
	.long wsvRegW				;@ 0x31 Pal mono 8 high
	.long wsvRegW				;@ 0x32 Pal mono 9 low
	.long wsvRegW				;@ 0x33 Pal mono 9 high
	.long wsvRegW				;@ 0x34 Pal mono A low
	.long wsvRegW				;@ 0x35 Pal mono A high
	.long wsvRegW				;@ 0x36 Pal mono B low
	.long wsvRegW				;@ 0x37 Pal mono B high
	.long wsvRegW				;@ 0x38 Pal mono C low
	.long wsvRegW				;@ 0x39 Pal mono C high
	.long wsvRegW				;@ 0x3A Pal mono D low
	.long wsvRegW				;@ 0x3B Pal mono D high
	.long wsvRegW				;@ 0x3C Pal mono E low
	.long wsvRegW				;@ 0x3D Pal mono E high
	.long wsvRegW				;@ 0x3E Pal mono F low
	.long wsvRegW				;@ 0x3F Pal mono F high
			;@ DMA registers, only WSC
	.long wsvDMASourceW			;@ 0x40	DMA source
	.long wsvRegW				;@ 0x41 DMA src
	.long wsvRegW				;@ 0x42 DMA src
	.long wsvRegW				;@ 0x43 ---
	.long wsvDMADestW			;@ 0x44 DMA destination
	.long wsvRegW				;@ 0x45 DMA dst
	.long wsvDMALengthW			;@ 0x46 DMA length
	.long wsvRegW				;@ 0x47 DMA len
	.long wsvDMACtrlW			;@ 0x48 DMA control
	.long wsvRegW				;@ 0x49 DMA ctrl
	.long wsvRegW				;@ 0x4A	Sound DMA source
	.long wsvRegW				;@ 0x4B Sound DMA src
	.long wsvRegW				;@ 0x4C Sound DMA src
	.long wsvRegW				;@ 0x4D Sound DMA src
	.long wsvRegW				;@ 0x4E Sound DMA length
	.long wsvRegW				;@ 0x4F Sound DMA len

	.long wsvRegW				;@ 0x50 Sound DMA len
	.long wsvRegW				;@ 0x51 Sound DMA len
	.long wsvSndDMACtrlW		;@ 0x52 Sound DMA control
	.long wsvUnmappedW			;@ 0x53 ---
	.long wsvUnmappedW			;@ 0x54 ---
	.long wsvUnmappedW			;@ 0x55 ---
	.long wsvUnmappedW			;@ 0x56 ---
	.long wsvUnmappedW			;@ 0x57 ---
	.long wsvUnmappedW			;@ 0x58 ---
	.long wsvUnmappedW			;@ 0x59 ---
	.long wsvUnmappedW			;@ 0x5A ---
	.long wsvUnmappedW			;@ 0x5B ---
	.long wsvUnmappedW			;@ 0x5C ---
	.long wsvUnmappedW			;@ 0x5D ---
	.long wsvUnmappedW			;@ 0x5E ---
	.long wsvUnmappedW			;@ 0x5F ---

	.long wsvVideoModeW			;@ 0x60 Display mode
	.long wsvUnmappedW			;@ 0x61 ---
	.long wsvImportantW			;@ 0x62 SwanCrystal/Power off
	.long wsvUnmappedW			;@ 0x63 ---
	.long wsvImportantW			;@ 0x64 Left channel Hyper Voice (lower byte)
	.long wsvImportantW			;@ 0x65 Left channel Hyper Voice (upper byte)
	.long wsvImportantW			;@ 0x66 Right channel Hyper Voice (lower byte)
	.long wsvImportantW			;@ 0x67 Right channel Hyper Voice (upper byte)
	.long wsvImportantW			;@ 0x68 Hyper Voice Shadow (lower byte)
	.long wsvImportantW			;@ 0x69 Hyper Voice Shadow (upper byte)
	.long wsvImportantW			;@ 0x6A Hyper control
	.long wsvHyperChanCtrlW		;@ 0x6B Hyper Chan control
	.long wsvUnmappedW			;@ 0x6C ---
	.long wsvUnmappedW			;@ 0x6D ---
	.long wsvUnmappedW			;@ 0x6E ---
	.long wsvUnmappedW			;@ 0x6F ---

	.long wsvReadOnlyW			;@ 0x70 Unknown70
	.long wsvReadOnlyW			;@ 0x71 Unknown71
	.long wsvReadOnlyW			;@ 0x72 Unknown72
	.long wsvReadOnlyW			;@ 0x73 Unknown73
	.long wsvReadOnlyW			;@ 0x74 Unknown74
	.long wsvReadOnlyW			;@ 0x75 Unknown75
	.long wsvReadOnlyW			;@ 0x76 Unknown76
	.long wsvReadOnlyW			;@ 0x77 Unknown77
	.long wsvUnmappedW			;@ 0x78 ---
	.long wsvUnmappedW			;@ 0x79 ---
	.long wsvUnmappedW			;@ 0x7A ---
	.long wsvUnmappedW			;@ 0x7B ---
	.long wsvUnmappedW			;@ 0x7C ---
	.long wsvUnmappedW			;@ 0x7D ---
	.long wsvUnmappedW			;@ 0x7E ---
	.long wsvUnmappedW			;@ 0x7F ---

	.long wsvRegW				;@ 0x80 Sound Ch1 pitch low
	.long wsvFreqW				;@ 0x81 Sound Ch1 pitch high
	.long wsvRegW				;@ 0x82 Sound Ch2 pitch low
	.long wsvFreqW				;@ 0x83 Sound Ch2 pitch high
	.long wsvRegW				;@ 0x84 Sound Ch3 pitch low
	.long wsvFreqW				;@ 0x85 Sound Ch3 pitch high
	.long wsvRegW				;@ 0x86 Sound Ch4 pitch low
	.long wsvFreqW				;@ 0x87 Sound Ch4 pitch high
	.long wsvRegW				;@ 0x88 Sound Ch1 volume
	.long wsvRegW				;@ 0x89 Sound Ch2 volume
	.long wsvRegW				;@ 0x8A Sound Ch3 volume
	.long wsvRegW				;@ 0x8B Sound Ch4 volume
	.long wsvRegW				;@ 0x8C Sweeep value
	.long wsvSweepTimeW			;@ 0x8D Sweep time
	.long wsvRegW				;@ 0x8E Noise control
	.long wsvRegW				;@ 0x8F Wave base

	.long wsvRegW				;@ 0x90 Sound control
	.long wsvSoundOutputW		;@ 0x91 Sound output
	.long wsvReadOnlyW			;@ 0x92 Noise LFSR value low
	.long wsvReadOnlyW			;@ 0x93 Noise LFSR value high
	.long wsvRegW				;@ 0x94 Sound voice control
	.long wsvRegW				;@ 0x95 Sound Hyper voice
	.long wsvImportantW			;@ 0x96 SND9697
	.long wsvImportantW			;@ 0x97 SND9697
	.long wsvImportantW			;@ 0x98 SND9899
	.long wsvImportantW			;@ 0x99 SND9899
	.long wsvReadOnlyW			;@ 0x9A SND9A
	.long wsvReadOnlyW			;@ 0x9B SND9B
	.long wsvReadOnlyW			;@ 0x9C SND9C
	.long wsvReadOnlyW			;@ 0x9D SND9D
	.long wsvHWVolumeW			;@ 0x9E HW Volume
	.long wsvUnmappedW			;@ 0x9F ---

	.long wsvHW					;@ 0xA0 Hardware type, SOC_ASWAN / SOC_SPHINX.
	.long wsvUnmappedW			;@ 0xA1 ---
	.long wsvTimerCtrlW			;@ 0xA2 Timer control
	.long wsvUnknownW			;@ 0xA3 ???
	.long wsvHTimerLowW			;@ 0xA4 HBlank timer low
	.long wsvHTimerHighW		;@ 0xA5 HBlank timer high
	.long wsvVTimerLowW			;@ 0xA6 VBlank timer low
	.long wsvVTimerHighW		;@ 0xA7 VBlank timer high
	.long wsvReadOnlyW			;@ 0xA8 HBlank counter low
	.long wsvReadOnlyW			;@ 0xA9 HBlank counter high
	.long wsvReadOnlyW			;@ 0xAA VBlank counter low
	.long wsvReadOnlyW			;@ 0xAB VBlank counter high
	.long wsvUnknownW			;@ 0xAC ???
	.long wsvUnmappedW			;@ 0xAD ---
	.long wsvUnmappedW			;@ 0xAE ---
	.long wsvUnmappedW			;@ 0xAF ---

	.long wsvRegW				;@ 0xB0 Interrupt base
	.long wsvImportantW			;@ 0xB1 Serial data
	.long wsvIntEnableW			;@ 0xB2 Interrupt enable
	.long wsvSerialStatusW		;@ 0xB3 Serial status
	.long wsvReadOnlyW			;@ 0xB4 Interrupt status
	.long wsvRegW				;@ 0xB5 Input Controls
	.long wsvIntAckW			;@ 0xB6 Interrupt acknowledge
	.long wsvUnknownW			;@ 0xB7 ??? NMI ctrl?
	.long wsvUnmappedW			;@ 0xB8 ---
	.long wsvUnmappedW			;@ 0xB9 ---
	.long wsvUnmappedW			;@ 0xBA ---
	.long wsvUnmappedW			;@ 0xBB ---
	.long wsvUnmappedW			;@ 0xBC ---
	.long wsvUnmappedW			;@ 0xBD ---
	.long wsvUnmappedW			;@ 0xBE ---
	.long wsvUnknownW			;@ 0xBF ???

;@----------------------------------------------------------------------------
;@Cartridge					;@ I/O write cart (0xC0-0xFF)
;@----------------------------------------------------------------------------

	.long wsvImportantW			;@ 0xC0 Bank switch 0x40000-0xF0000
	.long wsvImportantW			;@ 0xC1 Bank switch 0x10000 (SRAM)
	.long wsvImportantW			;@ 0xC2 Bank switch 0x20000
	.long wsvImportantW			;@ 0xC3 Bank switch 0x30000
	.long wsvImportantW			;@ 0xC4 ext-eeprom data low
	.long wsvImportantW			;@ 0xC5 ext-eeprom data high
	.long wsvImportantW			;@ 0xC6 ext-eeprom address low
	.long wsvImportantW			;@ 0xC7 ext-eeprom address high
	.long wsvImportantW			;@ 0xC8 ext-eeprom command
	.long wsvImportantW			;@ 0xC9 ???
	.long wsvImportantW			;@ 0xCA RTC command
	.long wsvImportantW			;@ 0xCB RTC data write
	.long wsvImportantW			;@ 0xCC General purpose input/output enable, bit 3-0.
	.long wsvImportantW			;@ 0xCD General purpose input/output data, bit 3-0.
	.long wsvImportantW			;@ 0xCE WonderWitch flash
	.long wsvUnknownW			;@ 0xCF Alias to 0xC0

	.long wsvUnknownW			;@ 0xD0 Alias to 0xC1
	.long wsvUnknownW			;@ 0xD1 2 more bits for 0xC1
	.long wsvUnknownW			;@ 0xD2 Alias to 0xC2
	.long wsvUnknownW			;@ 0xD3 2 more bits for 0xC2
	.long wsvUnknownW			;@ 0xD4 Alias to 0xC3
	.long wsvUnknownW			;@ 0xD5 2 more bits for 0xC3
	.long wsvUnknownW			;@ 0xD6 ???
	.long wsvUnknownW			;@ 0xD7 ???
	.long wsvUnknownW			;@ 0xD8 ???
	.long wsvUnknownW			;@ 0xD9 ???
	.long wsvUnknownW			;@ 0xDA ???
	.long wsvUnknownW			;@ 0xDB ???
	.long wsvUnknownW			;@ 0xDC ???
	.long wsvUnknownW			;@ 0xDD ???
	.long wsvUnknownW			;@ 0xDE ???
	.long wsvUnknownW			;@ 0xDF ???

	.long wsvUnknownW			;@ 0xE0 ???
	.long wsvUnknownW			;@ 0xE1 ???
	.long wsvUnknownW			;@ 0xE2 ???
	.long wsvUnknownW			;@ 0xE3 ???
	.long wsvUnknownW			;@ 0xE4 ???
	.long wsvUnknownW			;@ 0xE5 ???
	.long wsvUnknownW			;@ 0xE6 ???
	.long wsvUnknownW			;@ 0xE7 ???
	.long wsvUnknownW			;@ 0xE8 ???
	.long wsvUnknownW			;@ 0xE9 ???
	.long wsvUnknownW			;@ 0xEA ???
	.long wsvUnknownW			;@ 0xEB ???
	.long wsvUnknownW			;@ 0xEC ???
	.long wsvUnknownW			;@ 0xED ???
	.long wsvUnknownW			;@ 0xEE ???
	.long wsvUnknownW			;@ 0xEF ???

	.long wsvUnknownW			;@ 0xF0 ???
	.long wsvUnknownW			;@ 0xF1 ???
	.long wsvUnknownW			;@ 0xF2 ???
	.long wsvUnknownW			;@ 0xF3 ???
	.long wsvUnknownW			;@ 0xF4 ???
	.long wsvUnknownW			;@ 0xF5 ???
	.long wsvUnknownW			;@ 0xF6 ???
	.long wsvUnknownW			;@ 0xF7 ???
	.long wsvUnknownW			;@ 0xF8 ???
	.long wsvUnknownW			;@ 0xF9 ???
	.long wsvUnknownW			;@ 0xFA ???
	.long wsvUnknownW			;@ 0xFB ???
	.long wsvUnknownW			;@ 0xFC ???
	.long wsvUnknownW			;@ 0xFD ???
	.long wsvUnknownW			;@ 0xFE ???
	.long wsvUnknownW			;@ 0xFF ???

;@----------------------------------------------------------------------------
wsvUnknownW:
;@----------------------------------------------------------------------------
wsvImportantW:
;@----------------------------------------------------------------------------
	add r2,spxptr,#wsvRegs
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
	add r2,spxptr,#wsvRegs
	strb r1,[r2,r0]
	bx lr

;@----------------------------------------------------------------------------
wsvSpriteTblAdrW:			;@ 0x04, Sprite Table Address
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,#wsvVideoMode]
	tst r0,#0x80				;@ Color mode?
	andne r1,r1,#0x3F
	andeq r1,r1,#0x1F
	strb r1,[spxptr,#wsvSprTblAdr]
	bx lr
;@----------------------------------------------------------------------------
wsvSpriteFirstW:			;@ 0x05, First Sprite
;@----------------------------------------------------------------------------
	and r1,r1,#0x7F
	strb r1,[spxptr,#wsvSpriteFirst]
	bx lr
;@----------------------------------------------------------------------------
wsvBgScrXW:					;@ 0x10, Background Horizontal Scroll register
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
wsvBgScrYW:					;@ 0x11, Background Vertical Scroll register
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
wsvFgScrXW:					;@ 0x12, Foreground Horizontal Scroll register
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
wsvFgScrYW:					;@ 0x13, Foreground Vertical Scroll register
;@----------------------------------------------------------------------------
	ldr r2,[spxptr,#wsvBgXScroll]
	add r0,r0,#wsvRegs
	strb r1,[spxptr,r0]

scrollCnt:
	ldr r1,[spxptr,#scanline]	;@ r1=scanline
	add r1,r1,#1
	cmp r1,#146
	movhi r1,#146
	ldr r0,[spxptr,#scrollLine]
	subs r0,r1,r0
	strhi r1,[spxptr,#scrollLine]

	ldr r3,[spxptr,#scrollBuff]
	add r1,r3,r1,lsl#2
sy2:
	stmdbhi r1!,{r2}			;@ Fill backwards from scanline to lastline
	subs r0,r0,#1
	bhi sy2
	bx lr

;@----------------------------------------------------------------------------
wsvLCDIconW:				;@ 0x15, Enable/disable LCD icons
;@----------------------------------------------------------------------------
	strb r1,[spxptr,#wsvLCDIcons]
	ands r1,r1,#6
	bxeq lr
	cmp r1,#2
	movne r1,#0
	strb r1,[spxptr,#wsvOrientation]
	bx lr
;@----------------------------------------------------------------------------
svRefW:					;@ 0x16, Last scan line.
;@----------------------------------------------------------------------------
	strb r1,[spxptr,#wsvTotalLines]
	cmp r1,#0x9E
	movmi r1,#0x9E
	cmp r1,#0xC8
	movpl r1,#0xC8
	add r1,r1,#1
	str r1,lineStateLastLine
	mov r0,r1
	b setScreenRefresh
;@----------------------------------------------------------------------------
wsvDMASourceW:				;@ 0x40, only WSC.
;@----------------------------------------------------------------------------
	bic r1,r1,#0x01
	strb r1,[spxptr,#wsvDMASource]
	bx lr
;@----------------------------------------------------------------------------
wsvDMADestW:				;@ 0x44, only WSC.
;@----------------------------------------------------------------------------
	bic r1,r1,#0x01
	strb r1,[spxptr,#wsvDMADest]
	bx lr
;@----------------------------------------------------------------------------
wsvDMALengthW:				;@ 0x46, only WSC.
;@----------------------------------------------------------------------------
	bic r1,r1,#0x01
	strb r1,[spxptr,#wsvDMALength]
	bx lr
;@----------------------------------------------------------------------------
wsvDMACtrlW:				;@ 0x48, only WSC, word transfer. steals 5+2n cycles.
;@----------------------------------------------------------------------------
	and r1,r1,#0xC0
	strb r1,[spxptr,#wsvDMACtrl]
	tst r1,#0x80				;@ Start?
	bxeq lr

	stmfd sp!,{r4-r8,lr}
	and r8,r1,#0x40				;@ Inc/dec
	rsb r8,r8,#0x20
	mov r7,spxptr
	ldr r4,[spxptr,#wsvDMASource]

	ldrh r5,[spxptr,#wsvDMADest];@ r5=destination
	mov r5,r5,lsl#16

	sub cycles,cycles,#5*CYCLE
	ldrh r6,[spxptr,#wsvDMALength]	;@ r6=length
	cmp r6,#0
	beq dmaEnd
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

	mov spxptr,r7
	str r4,[spxptr,#wsvDMASource]
	mov r5,r5,lsr#16
	strh r5,[spxptr,#wsvDMADest]

	strh r6,[spxptr,#wsvDMALength]
	rsb r8,r8,#0x20
	strb r8,[spxptr,#wsvDMACtrl]
dmaEnd:

	ldmfd sp!,{r4-r8,lr}
	bx lr
;@----------------------------------------------------------------------------
wsvSndDMACtrlW:				;@ 0x52, only WSC. steals 2n cycles.
;@----------------------------------------------------------------------------
	and r1,r1,#0xDF
	strb r1,[spxptr,#wsvSndDMACtrl]
	tst r1,#0x80
	bxeq lr
	ldr r1,[spxptr,#wsvSndDMASrc]
	str r1,[spxptr,#sndDmaSource]
	ldr r1,[spxptr,#wsvSndDMALen]
	str r1,[spxptr,#sndDmaLength]
	bx lr
;@----------------------------------------------------------------------------
wsvHyperChanCtrlW:			;@ 0x6B, only WSC
;@----------------------------------------------------------------------------
	and r1,r1,#0x6F
	strb r1,[spxptr,#wsvHyperVChnCtrl]
	bx lr
;@----------------------------------------------------------------------------
wsvVideoModeW:				;@ 0x60, Video mode, WSColor
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,#wsvVideoMode]
	strb r1,[spxptr,#wsvVideoMode]
	eor r0,r0,r1
	tst r0,#0x80				;@ Color mode changed?
	bx lr
;@----------------------------------------------------------------------------
wsvFreqW:					;@ 0x81,0x83,0x85,0x87 Sound frequency high
;@----------------------------------------------------------------------------
	and r1,r1,#7				;@ Only low 3 bits
	add r2,spxptr,#wsvRegs
	strb r1,[r2,r0]
	bx lr
;@----------------------------------------------------------------------------
wsvSweepTimeW:				;@ 0x8B Sound sweep time
;@----------------------------------------------------------------------------
	and r1,r1,#0x1F				;@ Only low 5 bits
	strb r1,[spxptr,#wsvSweepTime]
	bx lr
;@----------------------------------------------------------------------------
wsvSoundOutputW:			;@ 0x91 Sound ouput
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,#wsvSoundOutput]
	and r1,r1,#0x0F				;@ Only low 4 bits
	and r0,r0,#0x80				;@ Keep Headphones bit
	orr r1,r1,r0
	strb r1,[spxptr,#wsvSoundOutput]
	bx lr
;@----------------------------------------------------------------------------
wsvHWVolumeW:				;@ 0x9E HW Volume?
;@----------------------------------------------------------------------------
	and r1,r1,#0x03				;@ Only low 2 bits
	strb r1,[spxptr,#wsvHWVolume]
	bx lr
;@----------------------------------------------------------------------------
wsvHW:						;@ 0xA0, Color/Mono, boot rom lock
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,#wsvSystemCtrl1]
	and r0,r0,#0x83				;@ These can't be changed once set.
	and r1,r1,#0x8D				;@ Only these bits can be set.
	orr r1,r1,r0
	strb r1,[spxptr,#wsvSystemCtrl1]
	eor r0,r0,r1
	tst r0,#1					;@ Boot rom locked?
	bx lr

;@----------------------------------------------------------------------------
wsvTimerCtrlW:				;@ 0xA2 Timer control
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
wsvHTimerLowW:				;@ 0xA4 HBlank timer low
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
wsvHTimerHighW:				;@ 0xA5 HBlank timer high
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
wsvVTimerLowW:				;@ 0xA6 VBlank timer low
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
wsvVTimerHighW:				;@ 0xA7 VBlank timer high
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
wsvIntEnableW:				;@ 0xB2
;@----------------------------------------------------------------------------
	strb r1,[spxptr,#wsvInterruptEnable]
	ldrb r0,[spxptr,#wsvInterruptStatus]
	b svUpdateIrqEnable
;@----------------------------------------------------------------------------
wsvSerialStatusW:			;@ 0xB3
;@----------------------------------------------------------------------------
	b wsvImportantW
;@----------------------------------------------------------------------------
wsvIntAckW:					;@ 0xB6
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,#wsvInterruptStatus]
	bic r0,r0,r1
	b svSetInterruptStatus
;@----------------------------------------------------------------------------
svConvertTileMaps:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr r5,=0xFE00FE00
	ldr r6,=0x00010001
	ldrb r7,[spxptr,#wsvMapTblAdr]
	ldr r10,[spxptr,#gfxRAM]

	ldrb r1,[spxptr,#wsvVideoMode]
	tst r1,#0x80				;@ Color Mode / 64kB RAM?
	andeq r7,r7,#0x77
	adr lr,tMapRet
	tst r1,#0x40				;@ 4 bit planes?
	beq bgMono
	b bgColor

tMapRet:
	ldmfd sp!,{r4-r11,pc}

;@----------------------------------------------------------------------------
newFrame:					;@ Called before line 0
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
midFrame:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	bl svBufferWindows
	ldrb r0,[spxptr,#wsvDispCtrl]
	strb r0,[spxptr,#wsvLatchedDispCtrl]

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
endFrame:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r2,[spxptr,#wsvBgXScroll]
	bl scrollCnt
	bl endFrameGfx
	bl wsvDMASprites

	ldrb r0,[spxptr,#wsvInterruptStatus]
	ldrb r2,[spxptr,#wsvTimerControl]
	tst r2,#0x4						;@ VBlank timer enabled?
	beq noTimerVBlIrq
	ldrh r1,[spxptr,#wsvVBlCounter]
	subs r1,r1,#1
	bne noVBlIrq
	orr r0,r0,#0x20					;@ #5 = VBlank timer
	tst r2,#0x8						;@ Repeat?
	biceq r2,r2,#0x4
	strbeq r2,[spxptr,#wsvTimerControl]
	ldrhne r1,[spxptr,#wsvVBlTimerFreq]
noVBlIrq:
	strhpl r1,[spxptr,#wsvVBlCounter]
noTimerVBlIrq:
	orr r0,r0,#0x40					;@ #6 = VBlank
	bl svSetInterruptStatus

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
drawFrameGfx:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldrb r0,[spxptr,#wsvVideoMode]
	adr lr,TransRet
	and r1,r0,#0xC0
	cmp r1,#0xC0
	bne TransferVRAM4Planar
	tst r0,#0x20
	bne TransferVRAM16Packed
	b TransferVRAM16Planar
TransRet:

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
frameEndHook:
	mov r0,#0
	str r0,[spxptr,#scrollLine]

	adr r2,lineStateTable
	ldr r1,[r2],#4
	mov r0,#-1
	stmia spxptr,{r0-r2}		;@ Reset scanline, nextChange & lineState
	bx lr

;@----------------------------------------------------------------------------
lineStateTable:
	.long 0, newFrame			;@ zeroLine
	.long 72, midFrame			;@ Middle of screen
	.long 144, endFrame			;@ After last visible scanline
	.long 145, drawFrameGfx		;@ frameIRQ
lineStateLastLine:
	.long 159, frameEndHook		;@ totalScanlines
;@----------------------------------------------------------------------------
#ifdef GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
	.align 2
#endif
;@----------------------------------------------------------------------------
redoScanline:
;@----------------------------------------------------------------------------
	ldr r2,[spxptr,#lineState]
	ldmia r2!,{r0,r1}
	stmib spxptr,{r1,r2}		;@ Write nextLineChange & lineState
	stmfd sp!,{lr}
	mov lr,pc
	bx r0
	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
svDoScanline:
;@----------------------------------------------------------------------------
	ldmia spxptr,{r0,r1}		;@ Read scanLine & nextLineChange
	add r0,r0,#1
	cmp r0,r1
	bpl redoScanline
	str r0,[spxptr,#scanline]
;@----------------------------------------------------------------------------
checkScanlineIRQ:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb r1,[spxptr,#wsvLineCompare]
	cmp r0,r1
	ldrb r0,[spxptr,#wsvInterruptStatus]
	orreq r0,r0,#0x10			;@ #4 = Line compare

	ldrb r2,[spxptr,#wsvTimerControl]
	tst r2,#0x1					;@ HBlank timer enabled?
	beq noTimerHBlIrq
	ldrh r1,[spxptr,#wsvHBlCounter]
	subs r1,r1,#1
	bne noHBlIrq
	orr r0,r0,#0x80				;@ #7 = HBlank timer
	tst r2,#0x2					;@ Repeat?
	biceq r2,r2,#0x1
	strbeq r2,[spxptr,#wsvTimerControl]
	ldrhne r1,[spxptr,#wsvHBlTimerFreq]
noHBlIrq:
	strhpl r1,[spxptr,#wsvHBlCounter]
noTimerHBlIrq:
	bl svSetInterruptStatus

	ldrb r0,[spxptr,#wsvSndDMACtrl]
	tst r0,#0x80
	blne doSoundDMA

	ldr r0,[spxptr,#scanline]
	subs r0,r0,#144				;@ Return from emulation loop on this scanline
	movne r0,#1
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
svSetInterruptExternal:	;@ r0 = irq state
;@----------------------------------------------------------------------------
	ldrb r1,[spxptr,#wsvInterruptStatus]
	cmp r0,#0
	biceq r0,r1,#4
	orrne r0,r1,#4				;@ External interrupt is bit/number 2.
;@----------------------------------------------------------------------------
svSetInterruptStatus:		;@ r0 = interrupt status
;@----------------------------------------------------------------------------
	ldrb r2,[spxptr,#wsvInterruptStatus]
	cmp r0,r2
	bxeq lr
	strb r0,[spxptr,#wsvInterruptStatus]
	ldrb r1,[spxptr,#wsvInterruptEnable]
svUpdateIrqEnable:
	and r0,r0,r1
	ldr pc,[spxptr,#irqFunction]
;@----------------------------------------------------------------------------
doSoundDMA:					;@ In r0=SndDmaCtrl
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	mov r4,r0
	ldr r1,[spxptr,#wsvSndDMALen]
	ldr r2,[spxptr,#wsvSndDMASrc]
	subs r1,r1,#1
	bpl sndDmaCont
	tst r4,#0x08				;@ Loop?
	biceq r4,r4,#0x80
	strb r4,[spxptr,#wsvSndDMACtrl]
	ldrne r1,[spxptr,#sndDmaLength]
	ldrne r2,[spxptr,#sndDmaSource]
	moveq r1,#0
	streq r1,[spxptr,#wsvSndDMALen]
	ldmfdeq sp!,{r4,pc}
sndDmaCont:
	str r1,[spxptr,#wsvSndDMALen]
	mov r0,r2,lsl#12
	tst r4,#0x40				;@ Increase/decrease
	addeq r2,r2,#1
	subne r2,r2,#1
	str r2,[spxptr,#wsvSndDMASrc]
//	bl cpuReadMem20
	tst r4,#0x10				;@ Ch2Vol/HyperVoice
	strbeq r0,[spxptr,#wsvSound2Vol]
	sub cycles,cycles,#1*CYCLE
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
T_data:
	.long DIRTYTILES+0x200
	.long svVRAM
	.long CHR_DECODE
	.long BG_GFX+0x08000		;@ BGR tiles
	.long SPRITE_GFX			;@ SPR tiles
;@----------------------------------------------------------------------------
TransferVRAM16Packed:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r10,lr}
	adr r0,T_data
	ldmia r0,{r4-r8}
	ldr r6,=0xF0F0F0F0
	mov r9,#-1
	mov r1,#0

tileLoop16_0p:
	ldr r10,[r4,r1,lsr#5]
	str r9,[r4,r1,lsr#5]
	tst r10,#0x000000FF
	addne r1,r1,#0x20
	bleq tileLoop16_1p
	tst r10,#0x0000FF00
	addne r1,r1,#0x20
	bleq tileLoop16_1p
	tst r10,#0x00FF0000
	addne r1,r1,#0x20
	bleq tileLoop16_1p
	tst r10,#0xFF000000
	addne r1,r1,#0x20
	bleq tileLoop16_1p
	cmp r1,#0x8000
	bne tileLoop16_0p

	ldmfd sp!,{r4-r10,pc}

tileLoop16_1p:
	ldr r0,[r5,r1]

	and r3,r6,r0,lsl#4
	and r0,r0,r6
	orr r3,r3,r0,lsr#4

	str r3,[r7,r1]
	str r3,[r8,r1]
	add r1,r1,#4
	tst r1,#0x1C
	bne tileLoop16_1p

	bx lr

;@----------------------------------------------------------------------------
TransferVRAM16Planar:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r10,lr}
	adr r0,T_data
	ldmia r0,{r4-r8}
	mov r9,#-1
	mov r1,#0

tx16ColTileLoop0:
	ldr r10,[r4,r1,lsr#5]
	str r9,[r4,r1,lsr#5]
	tst r10,#0x000000FF
	addne r1,r1,#0x20
	bleq tx16ColTileLoop1
	tst r10,#0x0000FF00
	addne r1,r1,#0x20
	bleq tx16ColTileLoop1
	tst r10,#0x00FF0000
	addne r1,r1,#0x20
	bleq tx16ColTileLoop1
	tst r10,#0xFF000000
	addne r1,r1,#0x20
	bleq tx16ColTileLoop1
	cmp r1,#0x8000
	bne tx16ColTileLoop0

	ldmfd sp!,{r4-r10,pc}

tx16ColTileLoop1:
	ldr r0,[r5,r1]

	ands r3,r0,#0x000000FF
	ldrne r3,[r6,r3,lsl#2]
	ands r2,r0,#0x0000FF00
	ldrne r2,[r6,r2,lsr#6]
	orrne r3,r3,r2,lsl#1
	ands r2,r0,#0x00FF0000
	ldrne r2,[r6,r2,lsr#14]
	orrne r3,r3,r2,lsl#2
	ands r2,r0,#0xFF000000
	ldrne r2,[r6,r2,lsr#22]
	orrne r3,r3,r2,lsl#3

	str r3,[r7,r1]
	str r3,[r8,r1]
	add r1,r1,#4
	tst r1,#0x1C
	bne tx16ColTileLoop1

	bx lr

;@----------------------------------------------------------------------------
T4Data:
	.long DIRTYTILES+0x100
	.long svVRAM
	.long CHR_DECODE
	.long BG_GFX+0x08000		;@ BGR tiles
	.long BG_GFX+0x0C000		;@ BGR tiles 2
	.long SPRITE_GFX			;@ SPR tiles
	.long SPRITE_GFX+0x4000		;@ SPR tiles 2
	.long 0x44444444			;@ Extra bitplane
;@----------------------------------------------------------------------------
TransferVRAM4Planar:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r12,lr}
	adr r0,T4Data
	ldmia r0,{r4-r11}
	mov r1,#0

tx4ColTileLoop0:
	ldr r12,[r4,r1,lsr#5]
	str r11,[r4,r1,lsr#5]
	tst r12,#0x000000FF
	addne r1,r1,#0x20
	bleq tx4ColTileLoop1
	tst r12,#0x0000FF00
	addne r1,r1,#0x20
	bleq tx4ColTileLoop1
	tst r12,#0x00FF0000
	addne r1,r1,#0x20
	bleq tx4ColTileLoop1
	tst r12,#0xFF000000
	addne r1,r1,#0x20
	bleq tx4ColTileLoop1
	cmp r1,#0x2000
	bne tx4ColTileLoop0

	ldmfd sp!,{r4-r12,pc}

tx4ColTileLoop1:
	ldr r0,[r5,r1]

	ands r3,r0,#0x000000FF
	ldrne r3,[r6,r3,lsl#2]
	ands r2,r0,#0x0000FF00
	ldrne r2,[r6,r2,lsr#6]
	orrne r3,r3,r2,lsl#1

	str r3,[r8,r1,lsl#1]
	str r3,[r10,r1,lsl#1]
	orr r3,r3,r11
	str r3,[r7,r1,lsl#1]
	str r3,[r9,r1,lsl#1]
	add r1,r1,#2

	ands r3,r0,#0x00FF0000
	ldrne r3,[r6,r3,lsr#14]
	ands r2,r0,#0xFF000000
	ldrne r2,[r6,r2,lsr#22]
	orrne r3,r3,r2,lsl#1

	str r3,[r8,r1,lsl#1]
	str r3,[r10,r1,lsl#1]
	orr r3,r3,r11
	str r3,[r7,r1,lsl#1]
	str r3,[r9,r1,lsl#1]
	add r1,r1,#2

	tst r1,#0x1C
	bne tx4ColTileLoop1

	bx lr

;@-------------------------------------------------------------------------------
;@ bgChrFinish				;end of frame...
;@-------------------------------------------------------------------------------
;@	ldr r5,=0xFE00FE00
;@ MSB          LSB
;@ hvbppppnnnnnnnnn
bgColor:
	and r1,r7,#0x0f
	add r1,r10,r1,lsl#11
	stmfd sp!,{lr}
	bl bgm16Start
	ldmfd sp!,{lr}

	and r1,r7,#0xf0
	add r1,r10,r1,lsl#7

bgm16Start:
	mov r2,#0x400
bgm16Loop:
	ldr r3,[r1],#4				;@ Read from Supervision Tilemap RAM

	and r4,r5,r3				;@ Mask out palette, flip & bank
	bic r3,r3,r5
	orr r4,r4,r4,lsr#7			;@ Switch palette vs flip + bank
	and r4,r5,r4,lsl#3			;@ Mask again
	orr r3,r3,r4				;@ Add palette, flip + bank.

	str r3,[r0],#4				;@ Write to GBA/NDS Tilemap RAM, background
	subs r2,r2,#2
	bne bgm16Loop

	bx lr

;@-------------------------------------------------------------------------------
;@ bgChrFinish				;end of frame...
;@-------------------------------------------------------------------------------
;@	ldr r5,=0xFE00FE00
;@	ldr r6,=0x00010001
;@ MSB          LSB
;@ hvbppppnnnnnnnnn
bgMono:
	and r1,r7,#0x0f
	add r1,r10,r1,lsl#11
	stmfd sp!,{lr}
	bl bgm4Start
	ldmfd sp!,{lr}

	and r1,r7,#0xf0
	add r1,r10,r1,lsl#7

bgm4Start:
	mov r2,#0x400
bgm4Loop:
	ldr r3,[r1],#4				;@ Read from Supervision Tilemap RAM

	and r4,r5,r3				;@ Mask out palette, flip & bank
	bic r4,r4,r6,lsl#13			;@ Clear out bank bit
	bic r3,r3,r5
	orr r4,r4,r4,lsr#7			;@ Switch palette vs flip + bank
	and r4,r5,r4,lsl#3			;@ Mask again
	orr r3,r3,r4				;@ Add palette, flip + bank.
	and r4,r3,r6,lsl#14			;@ Mask out palette bit 2
	orr r3,r3,r4,lsr#5			;@ Add as bank bit (GBA/NDS)

	str r3,[r0],#4				;@ Write to GBA/NDS Tilemap RAM, background
	subs r2,r2,#2
	bne bgm4Loop

	bx lr

;@----------------------------------------------------------------------------
copyScrollValues:			;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6}
	ldr r1,[spxptr,#scrollBuff]

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
wsvDMASprites:
;@----------------------------------------------------------------------------
	stmfd sp!,{spxptr,lr}

	add r0,spxptr,#wsvSpriteRAM
	ldr r1,[spxptr,#gfxRAM]
	ldrb r2,[spxptr,#wsvSprTblAdr]
	add r1,r1,r2,lsl#9
	ldrb r2,[spxptr,#wsvSpriteFirst]	;@ First sprite
	add r1,r1,r2,lsl#2

	ldrb r3,[spxptr,#wsvSpriteCount]	;@ Sprite count
	add r3,r3,r2
	cmp r3,#128
	movpl r3,#128
	subs r2,r3,r2
	movmi r2,#0
	strb r2,[spxptr,#wsvLatchedSprCnt]
	ldmfdle sp!,{spxptr,pc}
	sub cycles,cycles,r2,lsl#CYC_SHIFT+1
	mov r2,r2,lsl#2

	bl memCopy

	ldmfd sp!,{spxptr,pc}

;@----------------------------------------------------------------------------
	.equ PRIORITY,	0x400		;@ 0x400=AGB OBJ priority 1
;@----------------------------------------------------------------------------
svConvertSprites:			;@ in r0 = destination.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}

	add r1,spxptr,#wsvSpriteRAM
	ldrb r7,[spxptr,#wsvLatchedSprCnt]
	ldrb r2,[spxptr,#wsvVideoMode]
	tst r2,#0x40				;@ 4 bit planes?
	movne r8,#0x0000
	moveq r8,#0x0800			;@ Palette bit 2
	cmp r7,#0
	rsb r6,r7,#128				;@ Max number of sprites minus used.
	beq skipSprites

	mov r2,#(SCREEN_WIDTH-GAME_WIDTH)/2		;@ GBA/NDS X offset
	mov r5,#(SCREEN_HEIGHT-GAME_HEIGHT)/2	;@ GBA/NDS Y offset
	orr r5,r2,r5,lsl#24
dm5:
	ldr r2,[r1],#4				;@ Supervision OBJ, r0=Tile,Attrib,Ypos,Xpos.
	add r3,r5,r2,lsl#8
	mov r3,r3,lsr#24			;@ Ypos
	mov r4,r2,lsr#24			;@ Xpos
	cmp r4,#240
	addpl r4,r4,#0x100
	add r4,r4,r5
	mov r4,r4,lsl#23
	orr r3,r3,r4,lsr#7
	and r4,r2,#0xC000
	orr r3,r3,r4,lsl#14			;@ Flip

	str r3,[r0],#4				;@ Store OBJ Atr 0,1. Xpos, ypos, flip, scale/rot, size, shape.

	mov r3,r2,lsl#23
	mov r3,r3,lsr#23
	and r4,r2,#0x0E00			;@ Palette
	orr r3,r3,r4,lsl#3
	tst r2,#0x2000				;@ Priority
#ifdef NDS
	orreq r3,r3,#PRIORITY		;@ Prio NDS
#elif GBA
	orreq r3,r3,#PRIORITY*2		;@ Prio GBA
#endif
	tst r2,r8					;@ Palette bit 2 for 2bitplane
	orrne r3,r3,#0x200			;@ Opaque tiles

	strh r3,[r0],#4				;@ Store OBJ Atr 2. Pattern, palette.
	subs r7,r7,#1
	bne dm5
skipSprites:
	mov r2,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
skipSprLoop:
	subs r6,r6,#1
	strpl r2,[r0],#8
	bhi skipSprLoop
	ldmfd sp!,{r4-r8,pc}

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
