#ifndef GUI_HEADER
#define GUI_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u8 gGammaValue;
extern u8 gContrastValue;

void setupGUI(void);
void enterGUI(void);
void exitGUI(void);
void quickSelectGame(void);
void nullUINormal(int key);
void nullUIDebug(int key);
void ejectGame(void);
void resetGame(void);

void uiNullNormal(void);
void uiFile(void);
void uiSettings(void);
void uiAbout(void);
void uiOptions(void);
void uiController(void);
void uiDisplay(void);

void debugIOUnmappedR(u8 port);
void debugIOUnmappedW(u8 port, u8 val);
void debugIOUnimplR(u8 port);
void debugIOUnimplW(u8 port, u8 val);
void debugUndefinedInstruction(void);
void debugCrashInstruction(void);

void swapABSet(void);

void gammaSet(void);
void contrastSet(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GUI_HEADER
