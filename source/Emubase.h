#ifndef EMUBASE
#define EMUBASE

#ifdef __cplusplus
extern "C" {
#endif

#define ALLOW_SPEED_HACKS	(1<<17)
#define ENABLE_HEADPHONES	(1<<18)
#define ALLOW_REFRESH_CHG	(1<<19)

typedef struct {				//(config struct)
	char magic[4];				//="CFG",0
	int emuSettings;
	int unused;					// unused
	u8 gammaValue;				// from gfx.s
	u8 config;					// from cart.s
	u8 controller;				// from io.s
	u8 contrastValue;			// from gfx.s
	u8 language;
	u8 palette;
	u8 padding[2];
	char currentPath[256];
	char monoBiosPath[256];
	char colorBiosPath[256];
} ConfigData;

#ifdef __cplusplus
} // extern "C"
#endif

#endif // !EMUBASE
