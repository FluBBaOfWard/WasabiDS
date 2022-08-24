#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 gRomSize;
extern u32 maxRomSize;
extern u8 gConfig;
extern u8 gMachine;
extern u8 gMachineSet;
extern u8 gSOC;
extern u8 gLang;
extern u8 gPaletteBank;
extern u8 gGameID;
extern int sramSize;

extern u8 svRAM[0x2000];
extern u8 svVRAM[0x2000];
extern u8 svSRAM[0x2000];
extern u8 biosSpace[0x1000];
extern u8 biosSpaceColor[0x2000];
extern u8 *romSpacePtr;
extern void *g_BIOSBASE_BNW;
extern void *g_BIOSBASE_COLOR;

void machineInit(void);
void loadCart(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
