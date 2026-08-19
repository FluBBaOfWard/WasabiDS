#ifndef GUI_HEADER
#define GUI_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u8 gContrastValue;
extern u8 gBorderEnable;

void setupGUI(void);
void enterGUI(void);
void exitGUI(void);
void quickSelectGame(void);
void nullUINormal(int key);
void nullUIDebug(int key);
void ejectGame(void);
void resetGame(void);

void uiNullNormal(void);
void uiAbout(void);

void debugIOUnmappedR(u8 port);
void debugIOUnmappedW(u8 port, u8 val);
void debugIOUnimplR(u8 port);
void debugIOUnimplW(u8 port, u8 val);
void debugUndefinedInstruction(void);
void debugCrashInstruction(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // !GUI_HEADER
