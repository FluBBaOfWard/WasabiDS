#include <nds.h>

#include "Supervision.h"
#include "SVBorder.h"
#include "TVLink.h"
#include "Gui.h"
#include "Cart.h"
#include "Gfx.h"
#include "cpu.h"


int packState(void *statePtr) {
	int size = 0;
	memcpy(statePtr+size, svRAM, sizeof(svRAM));
	size += sizeof(svRAM);
	size += svVideoSaveState(statePtr+size, &ks5360_0);
	size += m6502SaveState(statePtr+size, &m6502_0);
	memcpy(statePtr+size, svVRAM, sizeof(svVRAM));
	size += sizeof(svVRAM);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(svRAM, statePtr+size, sizeof(svRAM));
	size += sizeof(svRAM);
	size += svVideoLoadState(&ks5360_0, statePtr+size);
	size += m6502LoadState(&m6502_0, statePtr+size);
	memcpy(svVRAM, statePtr+size, sizeof(svVRAM));
	size += sizeof(svVRAM);
}

int getStateSize() {
	int size = 0;
	size += sizeof(svRAM);
	size += svVideoGetStateSize();
	size += m6502GetStateSize();
	size += sizeof(svVRAM);
	return size;
}

static void setupBorderPalette(const unsigned short *palette, int len) {
	vramSetBankF(VRAM_F_LCD);
	if (gBorderEnable == 0) {
		memset(VRAM_F, 0, len);
	}
	else {
		memcpy(VRAM_F, palette, len);
	}
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupSVBackground() {
	decompress(SVBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(SVBorderMap, BG_MAP_RAM(2), LZ77Vram);
}

void setupSVBorderPalette() {
	setupBorderPalette(SVBorderPal, SVBorderPalLen);
}

void setupTVBackground() {
	decompress(TVLinkTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(TVLinkMap, BG_MAP_RAM(2), LZ77Vram);
}

void setupTVBorderPalette() {
	setupBorderPalette(TVLinkPal, TVLinkPalLen);
}

void setupEmuBackground() {
	if (gMachine == HW_SUPERVISION) {
		setupSVBackground();
		setupSVBorderPalette();
	}
	else {
		setupTVBackground();
		setupTVBorderPalette();
	}
}

void setupEmuBorderPalette() {
	if (gMachine == HW_SUPERVISION) {
		setupSVBorderPalette();
	}
	else {
		setupTVBorderPalette();
	}
}
