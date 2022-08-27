//
//  SVVideo.i
//  Watara Supervision video emulation for GBA/NDS.
//
//  Created by Fredrik Ahlström on 2004-11-30.
//  Copyright © 2004-2022 Fredrik Ahlström. All rights reserved.
//
;@ ASM header for the Watara Supervision video emulator

#define HW_AUTO              (0)
#define HW_SUPERVISION       (1)
#define HW_SUPERVISIONCOLOR  (2)
#define HW_SELECT_END        (3)

#define SOC_ASWAN		(0)
#define SOC_KS5360		(1)

/** Game screen width in pixels */
#define GAME_WIDTH  (160)
/** Game screen height in pixels */
#define GAME_HEIGHT (160)

	svvptr		.req r12
						;@ WSVideo.s
	.struct 0
scanline:			.long 0		;@ These 3 must be first in state.
nextLineChange:		.long 0
lineState:			.long 0

windowData:			.long 0
ks5360State:					;@
wsvRegs:
wsvLCDXSize:		.byte 0		;@ 0x00 LCD X Size
wsvLCDYSize:		.byte 0		;@ 0x01 LCD Y Size
wsvXScroll:			.byte 0		;@ 0x02 X Scroll
wsvYScroll:			.byte 0		;@ 0x03 Y Scroll
wsvMirr00:			.byte 0		;@ 0x04 Mirror of reg 0x00
wsvMirr01:			.byte 0		;@ 0x05 Mirror of reg 0x01
wsvMirr02:			.byte 0		;@ 0x06 Mirror of reg 0x02
wsvMirr03:			.byte 0		;@ 0x07 Mirror of reg 0x03

wsvDMASrcLow:		.byte 0		;@ 0x08 DMA Source Low
wsvDMASrcHigh:		.byte 0		;@ 0x09 DMA Source High
wsvDMADstLow:		.byte 0		;@ 0x0A DMA Destination Low
wsvDMADstHigh:		.byte 0		;@ 0x0B DMA Destination High
wsvDMALen:			.byte 0		;@ 0x0C DMA Length
wsvDMACtrl:			.byte 0		;@ 0x0D DMA Control

wsvPadding0:		.space 2	;@ 0x0E-0x0F ??

wsvCh1FreqLow:		.byte 0		;@ 0x10 Channel 1 Frequency Low (Right only)
wsvCh1FreqHigh:		.byte 0		;@ 0x11 Channel 1 Frequency High
wsvCh1Duty:			.byte 0		;@ 0x12 Channel 1 Duty cycle
wsvCh1Len:			.byte 0		;@ 0x13 Channel 1 Length
wsvCh2FreqLow:		.byte 0		;@ 0x14 Channel 2 Frequency Low (Left only)
wsvCh2FreqHigh:		.byte 0		;@ 0x15 Channel 2 Frequency High
wsvCh2Duty:			.byte 0		;@ 0x16 Channel 2 Duty cycle
wsvCh2Len:			.byte 0		;@ 0x17 Channel 2 Length

wsvCh3AdrLow:		.byte 0		;@ 0x18 Channel 3 Address Low
wsvCh3AdrHigh:		.byte 0		;@ 0x19 Channel 3 Address High
wsvCh3Len:			.byte 0		;@ 0x1A Channel 3 Length
wsvCh3Ctrl:			.byte 0		;@ 0x1B Channel 3 Control
wsvCh3Trigg:		.byte 0		;@ 0x1C Channel 3 Trigger
wsvPadding1:		.space 3	;@ 0x1D - 0x1F ???

wsvController:		.byte 0		;@ 0x20 Controller
wsvLinkPortDDR:		.byte 0		;@ 0x21 Link Port DDR
wsvLinkPortData:	.byte 0		;@ 0x22 Link Port Data
wsvIRQTimer:		.byte 0		;@ 0x23 IRQ Timer
wsvTimerIRQReset:	.byte 0		;@ 0x24 Timer IRQ Reset
wsvSndDMAIRQReset:	.byte 0		;@ 0x25 Sound DMA IRQ Reset
wsvSystemControl:	.byte 0		;@ 0x26 System Control
wsvIRQStatus:		.byte 0		;@ 0x27 IRQ Status
wsvCh4FreqVol:		.byte 0		;@ 0x28 Channel 4 Frquency and volume
wsvCh4Len:			.byte 0		;@ 0x29 Channel 4 Length
wsvCh4Ctrl:			.byte 0		;@ 0x2A Channel 4 Control
wsvPadding2:		.byte 0		;@ 0x2B ???
wsvMirr028:			.byte 0		;@ 0x2C Mirror of Reg 0x28
wsvMirr029:			.byte 0		;@ 0x2D Mirror of Reg 0x29
wsvMirr02A:			.byte 0		;@ 0x2E Mirror of Reg 0x2A
wsvPadding3:		.byte 0		;@ 0x2F ???


;@----------------------------------------------------------------------------
wsvTimerLatch:		.long 0
wsvTimerValue:		.long 0
sndDmaSource:		.long 0		;@ Original Sound DMA source address
sndDmaLength:		.long 0		;@ Original Sound DMA length

wsvSOC:				.byte 0		;@ ASWAN or KS5360
wsvLatchedSprCnt:	.byte 0		;@ Latched Sprite count
wsvLatchedDispCtrl:	.byte 0		;@ Latched Display Control
wsvOrientation:		.byte 0
wsvLowBattery:		.byte 0
wsvSleepMode__:		.byte 0
wsvPadding13:		.space 2

scrollLine: 		.long 0		;@ Last line scroll was updated.
ledCounter:			.long 0
ks5360StateEnd:

nmiFunction:		.long 0		;@ NMI function
irqFunction:		.long 0		;@ IRQ function

dirtyTiles:			.space 4
gfxRAM:				.long 0		;@ 0x2000
paletteRAM:			.long 0		;@ 0x0200
scrollBuff:			.long 0

ks5360Size:

;@----------------------------------------------------------------------------

