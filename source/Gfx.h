#ifndef GFX_HEADER
#define GFX_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "KS5360/KS5360.h"

extern u8 gFlicker;
extern u8 gTwitch;
extern u8 gGfxMask;

extern KS5360 ks5360_0;
extern u16 EMUPALBUFF[0x200];
extern u32 GFX_DISPCNT;
extern u16 GFX_BG0CNT;
extern u16 GFX_BG1CNT;

void gfxInit(void);
void vblIrqHandler(void);
void monoPalInit(void);
void paletteInit(u8 gammaVal);
void updateLCDRefresh(void);
void gfxRefresh(void);
u8 svReadIO(u16 adr);
void svWriteIO(u16 adr, u8 value);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GFX_HEADER
