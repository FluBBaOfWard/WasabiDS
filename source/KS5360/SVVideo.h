//
//  SVVideo.h
//  Watara Supervision video emulation for GBA/NDS.
//
//  Created by Fredrik Ahlström on 2004-11-30.
//  Copyright © 2004-2022 Fredrik Ahlström. All rights reserved.
//

#ifndef SVVIDEO_HEADER
#define SVVIDEO_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#define HW_AUTO              (0)
#define HW_SUPERVISION       (1)
#define HW_SUPERVISIONCOLOR  (2)
#define HW_SELECT_END        (5)

#define SOC_ASWAN		(0)
#define SOC_SPHINX		(1)

/** Game screen width in pixels */
#define GAME_WIDTH  (160)
/** Game screen height in pixels */
#define GAME_HEIGHT (160)

typedef struct {
	u32 scanline;
	u32 nextLineChange;
	u32 lineState;

	u32 windowData;
//wsvState:
//wsvRegs:					// 0-4
	u8 wsvDispCtrl;
	u8 wsvBGColor;
	u8 wsvCurrentLine;
	u8 wsvLineCompare;

	u8 wsvFgWinXPos;
	u8 wsvFgWinYPos;
	u8 wsvFgWinXSize;
	u8 wsvFgWinYSize;

	u8 wsvSprWinXPos;
	u8 wsvSprWinYPos;
	u8 wsvSprWinXSize;
	u8 wsvSprWinYSize;

	u8 wsvBgXScroll;
	u8 wsvBgYScroll;
	u8 wsvFgXScroll;
	u8 wsvFgYScroll;

	u8 wsvLCDControl;
	u8 wsvLCDIcons;
	u8 wsvTotalLines;
	u8 wsvPadding0[5];

	u8 wsvColor01;
	u8 wsvColor23;
	u8 wsvColor45;
	u8 wsvColor67;

	u16 wsvPalette0;
	u16 wsvPalette1;
	u16 wsvPalette2;
	u16 wsvPalette3;
	u16 wsvPalette4;
	u16 wsvPalette5;
	u16 wsvPalette6;
	u16 wsvPalette7;
	u16 wsvPalette8;
	u16 wsvPalette9;
	u16 wsvPaletteA;
	u16 wsvPaletteB;
	u16 wsvPaletteC;
	u16 wsvPaletteD;
	u16 wsvPaletteE;
	u16 wsvPaletteF;

	u32 wsvDMASource;
	u16 wsvDMADest;
	u16 wsvDMALength;
	u8 wsvDMACtrl;
	u8 wsvPadding1;

	u32 wsvSndDMASrc;
	u32 wsvSndDMALen;
	u8 wsvSndDMACtrl;
	u8 wsvPadding2;

	u8 wsvPadding3[12];

	u8 wsvVideoMode;

	u8 wsvPadding4;
	u8 wsvSystemCtrl3;
	u8 wsvPadding5;
	u8 wsvHyperVLL;			// 0x64 HyperVoice Left channel (lower byte)
	u8 wsvHyperVLH;			// 0x65 HyperVoice Left channel (upper byte)
	u8 wsvHyperVRL;			// 0x66 HyperVoice Right channel (lower byte)
	u8 wsvHyperVRH;			// 0x67 HyperVoice Right channel (upper byte)
	u8 wsvHyperVSL;			// 0x68 HyperVoice Shadow (lower byte)
	u8 wsvHyperVSH;			// 0x69 HyperVoice Shadow (upper byte)
	u8 wsvHyperVCtrl;		// 0x6A HyperVoice control
	u8 wsvHyperVChnCtrl;	// 0x6B HyperVoice channel control
	u8 wsvPadding5_1[20];

	u16 wsvSound1Freq;
	u16 wsvSound2Freq;
	u16 wsvSound3Freq;
	u16 wsvSound4Freq;

	u8 wsvSound1Vol;
	u8 wsvSound2Vol;
	u8 wsvSound3Vol;
	u8 wsvSound4Vol;
	u8 wsvSweepValue;
	u8 wsvSweepTime;
	u8 wsvNoiseCtrl;
	u8 wsvSampleBase;

	u8 wsvSoundCtrl;
	u8 wsvSoundOutput;
	u16 wsvNoiseCntr;
	u8 wsvVolume;

	u8 wsvPadding6[9];
	u8 wsvHWVolume;
	u8 wsvPadding7;

	u8 wsvSystemCtrl1;

	u8 wsvPadding8;

	u8 wsvTimerControl;
	u8 wsvPadding9;
	u16 wsvHBlTimerFreq;
	u16 wsvVBlTimerFreq;
	u16 wsvHBlCounter;
	u16 wsvVBlCounter;

	u8 wsvPadding10[4];

	u8 wsvInterruptBase;
	u8 wsvComByte;
	u8 wsvInterruptEnable;
	u8 wsvSerialStatus;
	u8 wsvInterruptStatus;
	u8 wsvControls;
	u8 wsvInterruptAck;

	u8 wsvPadding11[3];

	u16 wsvIntEEPROMData;
	u16 wsvIntEEPROMAdr;
	u16 wsvIntEEPROMCmd;

//------------------------------
	u8 wsvBnk0Slct_;
	u8 wsvBnk1Slct_;
	u8 wsvBnk2Slct_;
	u8 wsvBnk3Slct_;
	u16 wsvExtEEPROMData;
	u16 wsvExtEEPROMAdr;
	u16 wsvExtEEPROMCmd;

	u8 wsvRTCCommand;
	u8 wsvRTCData;
	u8 wsvGPIOEnable;
	u8 wsvGPIOData;
	u8 wsvWWitch;

	u8 wsvBnk0SlctX;
	u16 wsvBnk1SlctX;
	u16 wsvBnk2SlctX;
	u16 wsvBnk3SlctX;
	u8 wsvPadding12[42];
//------------------------------
	u32 sndDmaSource;			// Original Sound DMA source address
	u32 sndDmaLength;			// Original Sound DMA length

	u32 pcm1CurrentAddr;		// Ch1 Current addr
	u32 pcm2CurrentAddr;		// Ch2 Current addr
	u32 pcm3CurrentAddr;		// Ch3 Current addr
	u32 pcm4CurrentAddr;		// Ch4 Current addr
	u32 noise4CurrentAddr;		// Ch4 noise Current addr
	u32 sweep3CurrentAddr;		// Ch3 sweep Current addr

	u8 wsvSOC;					// ASWAN, SPHINX or SPHINX2
	u8 wsvLatchedSprCnt;		// Latched Sprite count
	u8 wsvLatchedDispCtrl;		// Latched Display Control
	u8 wsvOrientation;
	u8 wsvLowBattery;
	u8 wsvSleepMode__;
	u8 wsvPadding13[2];

	u32 enabledLCDIcons;
	u32 scrollLine;
	u32 ledCounter;

	void *irqFunction;			// IRQ callback

	u8 dirtyTiles[4];
	void *gfxRAM;
	void *paletteRAM;
	u32 *scrollBuff;
	u8 wsvSpriteRAM[0x200];

} Sphinx;

void svVideoReset(void *irqFunction(), void *ram, int soc);

/**
 * Saves the state of the chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The Sphinx chip to save.
 * @return The size of the state.
 */
int svVideoSaveState(void *destination, const Sphinx *chip);

/**
 * Loads the state of the chip from the source.
 * @param  *chip: The Sphinx chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int svVideoLoadState(Sphinx *chip, const void *source);

/**
 * Gets the state size of a Sphinx chip.
 * @return The size of the state.
 */
int svVideoGetStateSize(void);

void svDoScanline(void);
void svConvertTileMaps(void *destination);
void svConvertSprites(void *destination);
void svConvertTiles(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // SVVIDEO_HEADER
