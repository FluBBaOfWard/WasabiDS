#include <nds.h>

#include "Supervision.h"
#include "SVBorder.h"
#include "TVLink.h"
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

void setupSVBackground() {
	vramSetBankF(VRAM_F_LCD);
	decompress(SVBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(SVBorderMap, BG_MAP_RAM(2), LZ77Vram);
	memcpy(VRAM_F, SVBorderPal, SVBorderPalLen);
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupTVBackground() {
	vramSetBankF(VRAM_F_LCD);
	decompress(TVLinkTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(TVLinkMap, BG_MAP_RAM(2), LZ77Vram);
	memcpy(VRAM_F, TVLinkPal, TVLinkPalLen);
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupEmuBackground() {
//	if (gMachine == HW_SUPERVISION) {
		setupSVBackground();
//		setupTVBackground();
//	}
}
