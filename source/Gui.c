#include <nds.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Main.h"
#include "SVController.h"
#include "FileHandling.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "ARM6502/Version.h"
#include "KS5360/Version.h"

#define EMUVERSION "V0.2.4 2024-09-11"

#define ALLOW_SPEED_HACKS	(1<<17)
#define ENABLE_HEADPHONES	(1<<18)
#define ALLOW_REFRESH_CHG	(1<<19)

static void paletteChange(void);
static void machineSet(void);
static void refreshChgSet(void);

static void setupWSVBackground(void);

static void uiMachine(void);
static void uiDebug(void);

const MItem fnList0[] = {{"",uiDummy}};
const MItem fnList1[] = {
	{"Load Game",selectGame},
	{"Load State",loadState},
	{"Save State",saveState},
	{"Save Settings",saveSettings},
	{"Eject Game",ejectGame},
	{"Reset Console",resetGame},
	{"Quit Emulator",ui9}};
const MItem fnList2[] = {
	{"Controller",ui4},
	{"Display",ui5},
	{"Machine",ui6},
	{"Settings",ui7},
	{"Debug",ui8}};
const MItem fnList4[] = {{"",autoBSet}, {"",autoASet}, {"",swapABSet}};
const MItem fnList5[] = {{"",gammaSet}, {"",contrastSet}, {"",paletteChange}};
const MItem fnList6[] = {{"",machineSet}};
const MItem fnList7[] = {{"",speedSet}, {"",refreshChgSet}, {"",autoStateSet}, {"",autoSettingsSet}, {"",autoPauseGameSet}, {"",powerSaveSet}, {"",screenSwapSet}, {"",sleepSet}};
const MItem fnList8[] = {{"",debugTextSet}, {"",stepFrame}};
const MItem fnList9[] = {{"Yes ",exitEmulator}, {"No ",backOutOfMenu}};

const Menu menu0 = MENU_M("", uiNullNormal, fnList0);
Menu menu1 = MENU_M("", uiAuto, fnList1);
const Menu menu2 = MENU_M("", uiAuto, fnList2);
const Menu menu3 = MENU_M("", uiAbout, fnList0);
const Menu menu4 = MENU_M("Controller Settings", uiController, fnList4);
const Menu menu5 = MENU_M("Display Settings", uiDisplay, fnList5);
const Menu menu6 = MENU_M("Machine Settings", uiMachine, fnList6);
const Menu menu7 = MENU_M("Settings", uiSettings, fnList7);
const Menu menu8 = MENU_M("Debug", uiDebug, fnList8);
const Menu menu9 = MENU_M("Quit Emulator?", uiAuto, fnList9);
const Menu menu10 = MENU_M("", uiDummy, fnList0);

const Menu *const menus[] = {&menu0, &menu1, &menu2, &menu3, &menu4, &menu5, &menu6, &menu7, &menu8, &menu9, &menu10 };

u8 gGammaValue = 0;
u8 gContrastValue = 1;

const char *const autoTxt[]  = {"Off", "On", "With R"};
const char *const speedTxt[] = {"Normal", "200%", "Max", "50%"};
const char *const sleepTxt[] = {"5min", "10min", "30min", "Off"};
const char *const brighTxt[] = {"I", "II", "III", "IIII", "IIIII"};
const char *const ctrlTxt[]  = {"1P", "2P"};
const char *const dispTxt[]  = {"Unscaled", "Scaled"};
const char *const flickTxt[] = {"No Flicker", "Flicker"};

const char *const machTxt[]  = {"Auto", "Supervision", "Supervision TV-Link"};
const char *const bordTxt[]  = {"Black", "Border Color", "None"};
const char *const palTxt[]   = {"Green", "Black & White", "Red", "Blue", "Classic"};
const char *const langTxt[]  = {"Japanese", "English"};

/// This is called at the start of the emulator
void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION | AUTOSLEEP_OFF;
	keysSetRepeat(25, 4);	// delay, repeat.
	menu1.itemCount = ARRSIZE(fnList1) - (enableExit?0:1);
	openMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
}

void quickSelectGame(void) {
	openMenu();
	selectGame();
	closeMenu();
}

void uiNullNormal() {
//	uiNullDefault();
	setupWSVBackground();
	drawItem("Menu",27,1,0);
}

void uiAbout() {
	cls(1);
	drawTabs();
	drawMenuText("A:        SV A button", 4, 0);
	drawMenuText("B:        SV B button", 5, 0);
	drawMenuText("X/Start:  SV Start button", 6, 0);
	drawMenuText("Y/Select: SV Select button", 7, 0);

	drawMenuText("WasabiDS     " EMUVERSION, 21, 0);
	drawMenuText("KS5360       " KS5360VERSION, 22, 0);
	drawMenuText("ARM6502      " ARM6502VERSION, 23, 0);
}

void uiController() {
	setupSubMenuText();
	drawSubItem("B Autofire:", autoTxt[autoB]);
	drawSubItem("A Autofire:", autoTxt[autoA]);
	drawSubItem("Swap A-B:  ", autoTxt[(joyCfg>>10)&1]);
}

void uiDisplay() {
	setupSubMenuText();
	drawSubItem("Gamma:", brighTxt[gGammaValue]);
	drawSubItem("Contrast:", brighTxt[gContrastValue]);
	drawSubItem("Palette:", palTxt[gPaletteBank]);
}

static void uiMachine() {
	setupSubMenuText();
	drawSubItem("Machine:", machTxt[gMachineSet]);
}

void uiSettings() {
	setupSubMenuText();
	drawSubItem("Speed:", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Allow Refresh Change:", autoTxt[(emuSettings&ALLOW_REFRESH_CHG)>>19]);
	drawSubItem("Autoload State:", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autosave Settings:", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autopause Game:", autoTxt[emuSettings&1]);
	drawSubItem("Powersave 2nd Screen:",autoTxt[(emuSettings>>1)&1]);
	drawSubItem("Emulator on Bottom:", autoTxt[(emuSettings>>8)&1]);
	drawSubItem("Autosleep:", sleepTxt[(emuSettings>>4)&3]);
}

void uiDebug() {
	setupSubMenuText();
	drawSubItem("Debug Output:", autoTxt[gDebugSet&1]);
	drawSubItem("Step Frame", NULL);
}


void nullUINormal(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void nullUIDebug(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void ejectGame() {
	ejectCart();
}

void resetGame() {
	checkMachine();
	loadCart();
}

//---------------------------------------------------------------------------------
void debugIO(u8 port, u8 val, const char *message) {
	char debugString[32];

	debugString[0] = 0;
	strlcat(debugString, message, sizeof(debugString));
	char2HexStr(&debugString[strlen(debugString)], port);
	strlcat(debugString, " val:", sizeof(debugString));
	char2HexStr(&debugString[strlen(debugString)], val);
	debugOutput(debugString);
}
//---------------------------------------------------------------------------------
void debugIOUnimplR(u8 port) {
	debugIO(port, 0, "Unimpl R port:");
}
void debugIOUnimplW(u8 port, u8 val) {
	debugIO(port, val, "Unimpl W port:");
}
void debugIOUnmappedR(u8 port) {
	debugIO(port, 0, "Unmapped R port:");
}
void debugIOUnmappedW(u8 port, u8 val) {
	debugIO(port, val, "Unmapped W port:");
}
void debugUndefinedInstruction() {
	debugOutput("Undefined Instruction.");
}
void debugCrashInstruction() {
	debugOutput("CPU Crash!");
}

//---------------------------------------------------------------------------------
void setupWSVBackground(void) {
	setupCompressedBackground(SVControllerTiles, SVControllerMap, 0);
	memcpy(BG_PALETTE_SUB+0x80, SVControllerPal, SVControllerPalLen);
}

//---------------------------------------------------------------------------------

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}

/// Change gamma (brightness)
void gammaSet() {
	gGammaValue++;
	if (gGammaValue > 4) gGammaValue = 0;
	paletteInit(gGammaValue);
	setupMenuPalette();
	settingsChanged = true;
}

/// Change contrast
void contrastSet() {
	gContrastValue++;
	if (gContrastValue > 4) gContrastValue = 0;
	paletteInit(gGammaValue);
	settingsChanged = true;
}

void paletteChange() {
	gPaletteBank++;
	if (gPaletteBank > 4) {
		gPaletteBank = 0;
	}
	monoPalInit();
	paletteInit(gGammaValue);
	settingsChanged = true;
}

void machineSet() {
	gMachineSet++;
	if (gMachineSet >= HW_SELECT_END) {
		gMachineSet = 0;
	}
}

void refreshChgSet() {
	emuSettings ^= ALLOW_REFRESH_CHG;
	updateLCDRefresh();
}
