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
#define SOC_KS5360		(1)

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

//------------------------------
	u32 sndDmaSource;			// Original Sound DMA source address
	u32 sndDmaLength;			// Original Sound DMA length

	u32 pcm1CurrentAddr;		// Ch1 Current addr
	u32 pcm2CurrentAddr;		// Ch2 Current addr
	u32 pcm3CurrentAddr;		// Ch3 Current addr
	u32 pcm4CurrentAddr;		// Ch4 Current addr
	u32 noise4CurrentAddr;		// Ch4 noise Current addr
	u32 sweep3CurrentAddr;		// Ch3 sweep Current addr

	u8 wsvSOC;					// ASWAN or KS5360
	u8 wsvLatchedSprCnt;		// Latched Sprite count
	u8 wsvLatchedDispCtrl;		// Latched Display Control
	u8 wsvOrientation;
	u8 wsvLowBattery;
	u8 wsvSleepMode__;
	u8 wsvPadding13[2];

	u32 enabledLCDIcons;
	u32 scrollLine;
	u32 ledCounter;

	void *nmiFunction;			// NMI callback
	void *irqFunction;			// IRQ callback

	u8 dirtyTiles[4];
	void *gfxRAM;
	void *paletteRAM;
	u32 *scrollBuff;

} KS5360;

void svVideoReset(void *irqFunction(), void *ram, int soc);

/**
 * Saves the state of the chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The KS5360 chip to save.
 * @return The size of the state.
 */
int svVideoSaveState(void *destination, const KS5360 *chip);

/**
 * Loads the state of the chip from the source.
 * @param  *chip: The KS5360 chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int svVideoLoadState(KS5360 *chip, const void *source);

/**
 * Gets the state size of a KS5360 chip.
 * @return The size of the state.
 */
int svVideoGetStateSize(void);

void svDoScanline(void);
void svConvertScreen(void *destination);
void svConvertTiles(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // SVVIDEO_HEADER
