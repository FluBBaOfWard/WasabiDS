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
#define SOC_SPHINX		(1)
#define SOC_SPHINX2		(2)

/** Game screen width in pixels */
#define GAME_WIDTH  (160)
/** Game screen height in pixels */
#define GAME_HEIGHT (160)

	spxptr		.req r12
	svvptr		.req r12
						;@ WSVideo.s
	.struct 0
scanline:			.long 0		;@ These 3 must be first in state.
nextLineChange:		.long 0
lineState:			.long 0

windowData:			.long 0
sphinxState:					;@
wsvRegs:
wsvDispCtrl:		.byte 0		;@ 0x00 Display control
wsvBGColor:			.byte 0		;@ 0x01 Background color
wsvCurrentLine:		.byte 0		;@ 0x02 Current scan line
wsvLineCompare:		.byte 0		;@ 0x03 Scan line compare for IRQ
wsvSprTblAdr:		.byte 0		;@ 0x04 Sprite table address
wsvSpriteFirst:		.byte 0		;@ 0x05 Sprite to start with
wsvSpriteCount:		.byte 0		;@ 0x06 Sprite count
wsvMapTblAdr:		.byte 0		;@ 0x07 Map table address

wsvFgWinXPos:		.byte 0		;@ 0x08 Foreground window X-Position
wsvFgWinYPos:		.byte 0		;@ 0x09 Foreground window Y-Position
wsvFgWinXSize:		.byte 0		;@ 0x0A Foreground window X-Size
wsvFgWinYSize:		.byte 0		;@ 0x0B Foreground window Y-Size

wsvSprWinXPos:		.byte 0		;@ 0x0C Sprite window X-Position
wsvSprWinYPos:		.byte 0		;@ 0x0D Sprite window Y-Position
wsvSprWinXSize:		.byte 0		;@ 0x0E Sprite window X-Size
wsvSprWinYSize:		.byte 0		;@ 0x0F Sprite window Y-Size

wsvBgXScroll:		.byte 0		;@ 0x10 Background X-Scroll
wsvBgYScroll:		.byte 0		;@ 0x11 Background Y-Scroll
wsvFgXScroll:		.byte 0		;@ 0x12 Foreground X-Scroll
wsvFgYScroll:		.byte 0		;@ 0x13 Foreground Y-Scroll

wsvLCDControl:		.byte 0		;@ 0x14 LCD control (on/off?)
wsvLCDIcons:		.byte 0		;@ 0x15 LCD icons
wsvTotalLines:		.byte 0		;@ 0x16 Total scan lines
wsvPadding0:		.space 5	;@ 0x17 - 0x1B ???

wsvColor01:			.byte 0		;@ 0x1C Color 0 & 1
wsvColor23:			.byte 0		;@ 0x1D Color 2 & 3
wsvColor45:			.byte 0		;@ 0x1E Color 4 & 5
wsvColor67:			.byte 0		;@ 0x1F Color 6 & 7

wsvPalette0:		.short 0	;@ 0x20/0x21 Palette 0
wsvPalette1:		.short 0	;@ 0x22/0x23 Palette 1
wsvPalette2:		.short 0	;@ 0x24/0x25 Palette 2
wsvPalette3:		.short 0	;@ 0x26/0x27 Palette 3
wsvPalette4:		.short 0	;@ 0x28/0x29 Palette 4
wsvPalette5:		.short 0	;@ 0x2A/0x2B Palette 5
wsvPalette6:		.short 0	;@ 0x2C/0x2D Palette 6
wsvPalette7:		.short 0	;@ 0x2E/0x2F Palette 7
wsvPalette8:		.short 0	;@ 0x30/0x31 Palette 8
wsvPalette9:		.short 0	;@ 0x32/0x33 Palette 9
wsvPaletteA:		.short 0	;@ 0x34/0x35 Palette A
wsvPaletteB:		.short 0	;@ 0x36/0x37 Palette B
wsvPaletteC:		.short 0	;@ 0x38/0x39 Palette C
wsvPaletteD:		.short 0	;@ 0x3A/0x3B Palette D
wsvPaletteE:		.short 0	;@ 0x3C/0x3D Palette E
wsvPaletteF:		.short 0	;@ 0x3E/0x3F Palette F

wsvDMASource:		.long 0		;@ 0x40-0x43 DMA source adr bits 19-0
wsvDMADest:			.short 0	;@ 0x44/0x45 DMA destination adr bits 15-0
wsvDMALength:		.short 0	;@ 0x46/0x47 DMA length bits 15-0
wsvDMACtrl:			.byte 0		;@ 0x48 DMA control, bit 7 start
wsvPadding1:		.space 1	;@ 0x49 ???

wsvSndDMASrc:		.long 0		;@ 0x4A-0x4D Sound DMA source adr bits 19-0
wsvSndDMALen:		.long 0		;@ 0x4E-0x51 Sound DMA length bits 19-0
wsvSndDMACtrl:		.byte 0		;@ 0x52 Sound DMA control, bit 7 start
wsvPadding2:		.space 1	;@ 0x53 ???

wsvPadding3:		.space 12	;@ 0x54 - 0x5F ???

wsvVideoMode:		.byte 0		;@ 0x60 Video rendering mode

wsvPadding4:		.space 1	;@ 0x61 ???
wsvSystemCtrl3:		.byte 0		;@ 0x62 WSC / SC, Power off
wsvPadding5:		.space 1	;@ 0x63 ???
wsvHyperVLL:		.byte 0		;@ 0x64 HyperVoice Left channel (lower byte)
wsvHyperVLH:		.byte 0		;@ 0x65 HyperVoice Left channel (upper byte)
wsvHyperVRL:		.byte 0		;@ 0x66 HyperVoice Right channel (lower byte)
wsvHyperVRH:		.byte 0		;@ 0x67 HyperVoice Right channel (upper byte)
wsvHyperVSL:		.byte 0		;@ 0x68 HyperVoice Shadow (lower byte)
wsvHyperVSH:		.byte 0		;@ 0x69 HyperVoice Shadow (upper byte)
wsvHyperVCtrl:		.byte 0		;@ 0x6A HyperVoice control
wsvHyperVChnCtrl:	.byte 0		;@ 0x6B HyperVoice channel control
wsvPadding5_1:		.space 20	;@ 0x6C - 0x7F ???

wsvSound1Freq:		.short 0	;@ 0x80/0x81 Sound ch 1 pitch bits 10-0
wsvSound2Freq:		.short 0	;@ 0x82/0x83 Sound ch 2 pitch bits 10-0
wsvSound3Freq:		.short 0	;@ 0x84/0x85 Sound ch 3 pitch bits 10-0
wsvSound4Freq:		.short 0	;@ 0x86/0x87 Sound ch 4 pitch bits 10-0

wsvSound1Vol:		.byte 0		;@ 0x88 Sound ch 1 volume
wsvSound2Vol:		.byte 0		;@ 0x89 Sound ch 2 volume
wsvSound3Vol:		.byte 0		;@ 0x8A Sound ch 3 volume
wsvSound4Vol:		.byte 0		;@ 0x8B Sound ch 4 volume
wsvSweepValue:		.byte 0		;@ 0x8C Sweep value
wsvSweepTime:		.byte 0		;@ 0x8D Sweep time
wsvNoiseCtrl:		.byte 0		;@ 0x8E Noise control
wsvSampleBase:		.byte 0		;@ 0x8F Sound wave base

wsvSoundCtrl:		.byte 0		;@ 0x90 Sound control
wsvSoundOutput:		.byte 0		;@ 0x91 Sound output
wsvNoiseCntr:		.short 0	;@ 0x92/0x93 Noise Counter Shift Register (15 bits)
wsvVolume:			.byte 0		;@ 0x94 Volume (4 bit)

wsvPadding6:		.space 9	;@ 0x95 - 0x9D ???
wsvHWVolume:		.byte 0		;@ 0x9E HW Volume (2 bit)
wsvPadding7:		.space 1	;@ 0x9F ???

wsvSystemCtrl1:		.byte 0		;@ 0xA0 Hardware type, boot rom lock.

wsvPadding8:		.space 1	;@ 0xA1 ???

wsvTimerControl:	.byte 0		;@ 0xA2 Timer control
wsvPadding9:		.space 1	;@ 0xA3 ???
wsvHBlTimerFreq:	.short 0	;@ 0xA4/0xA5 HBlank Timer 'frequency'
wsvVBlTimerFreq:	.short 0	;@ 0xA6/0xA7 VBlank Timer 'frequency'
wsvHBlCounter:		.short 0	;@ 0xA8/0xA9 HBlank Counter - 1/12000s
wsvVBlCounter:		.short 0	;@ 0xAA/0xAB VBlank Counter - 1/75s

wsvPadding10:		.space 4	;@ 0xAC - 0xAF ???

wsvInterruptBase:	.byte 0		;@ 0xB0 Interrupt base
wsvComByte:			.byte 0		;@ 0xB1 Communication byte
wsvInterruptEnable:	.byte 0		;@ 0xB2 Interrupt enable
wsvSerialStatus:	.byte 0		;@ 0xB3 Serial status
wsvInterruptStatus:	.byte 0		;@ 0xB4 Interrupt status
wsvControls:		.byte 0		;@ 0xB5 Input Controls
wsvInterruptAck:	.byte 0		;@ 0xB6 Interrupt acknowledge

wsvPadding11:		.space 3	;@ 0xB7 - 0xB9 ???

wsvIntEEPROMData:	.short 0	;@ 0xBA/0xBB Internal EEPROM data
wsvIntEEPROMAdr:	.short 0	;@ 0xBC/0xBD Internal EEPROM address
wsvIntEEPROMCmd:	.short 0	;@ 0xBE Internal EEPROM command/status

;@----------------------------------------------------------------------------
wsvBnk0Slct_:		.byte 0		;@ 0xC0 ROM Bank Base Selector for segments 4-$F
wsvBnk1Slct_:		.byte 0		;@ 0xC1 SRAM Bank selector
wsvBnk2Slct_:		.byte 0		;@ 0xC2 BNK2SLCT - ROM Bank selector for segment 2
wsvBnk3Slct_:		.byte 0		;@ 0xC3 BNK3SLCT - ROM Bank selector for segment 3
wsvExtEEPROMData:	.short 0	;@ 0xC4/0xC5 External EEPROM data
wsvExtEEPROMAdr:	.short 0	;@ 0xC6/0xC7 External EEPROM address
wsvExtEEPROMCmd:	.short 0	;@ 0xC8/0xC9 External EEPROM command/status

wsvRTCCommand:		.byte 0		;@ 0xCA RTC Command
wsvRTCData:			.byte 0		;@ 0xCB RTC Data
wsvGPIOEnable:		.byte 0		;@ 0xCC GP IO Enable
wsvGPIOData:		.byte 0		;@ 0xCD GP IO Data
wsvWWitch:			.byte 0		;@ 0xCE WonderWitch IO Data

wsvBnk0SlctX:		.byte 0		;@ 0xCF ROM Bank Base Selector for segments 4-$F
wsvBnk1SlctX:		.short 0	;@ 0xD0/0xD1 SRAM Bank selector
wsvBnk2SlctX:		.short 0	;@ 0xD2/0xD3 BNK2SLCT - ROM Bank selector for segment 2
wsvBnk3SlctX:		.short 0	;@ 0xD4/0xD5 BNK3SLCT - ROM Bank selector for segment 3
wsvPadding12:		.space 42	;@ 0xD6 - 0xFF ???

;@----------------------------------------------------------------------------
sndDmaSource:		.long 0		;@ Original Sound DMA source address
sndDmaLength:		.long 0		;@ Original Sound DMA length

pcm1CurrentAddr:	.long 0		;@ Ch1 Current addr
pcm2CurrentAddr:	.long 0		;@ Ch2 Current addr
pcm3CurrentAddr:	.long 0		;@ Ch3 Current addr
pcm4CurrentAddr:	.long 0		;@ Ch4 Current addr
noise4CurrentAddr:	.long 0		;@ Ch4 noise Current addr
sweep3CurrentAddr:	.long 0		;@ Ch3 sweep Current addr

wsvSOC:				.byte 0		;@ ASWAN, SPHINX or SPHINX2
wsvLatchedSprCnt:	.byte 0		;@ Latched Sprite count
wsvLatchedDispCtrl:	.byte 0		;@ Latched Display Control
wsvOrientation:		.byte 0
wsvLowBattery:		.byte 0
wsvSleepMode__:		.byte 0
lcdCtrl:			.byte 0
wsvPadding13:		.space 1

enabledLCDIcons:	.long 0
scrollLine: 		.long 0		;@ Last line scroll was updated.
ledCounter:			.long 0
sphinxStateEnd:

irqFunction:		.long 0		;@ IRQ function

dirtyTiles:			.space 4
gfxRAM:				.long 0		;@ 0x4000/0x10000
paletteRAM:			.long 0		;@ 0x0200
scrollBuff:			.long 0
wsvSpriteRAM:		.space 0x200 ;@ Internal sprite ram

sphinxSize:

;@----------------------------------------------------------------------------

