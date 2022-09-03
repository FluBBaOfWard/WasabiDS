#include <nds.h>
#include <fat.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/dir.h>

#include "FileHandling.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Shared/Unzip/unzipnds.h"
#include "Shared/AsmExtra.h"
#include "Main.h"
#include "Gui.h"
#include "Cart.h"
#include "cpu.h"
#include "Gfx.h"
#include "io.h"
#include "Memory.h"
#include "Supervision.h"

static const char *const folderName = "nitroswan";
static const char *const settingName = "settings.cfg";

ConfigData cfg;

//---------------------------------------------------------------------------------
int initSettings() {
	cfg.gammaValue = 0;
	cfg.emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM;
	cfg.sleepTime = 60*60*5;
	cfg.controller = 0;					// Don't swap A/B
	cfg.language = (PersonalData->language == 0) ? 0 : 1;
	int col = 0;
	switch (PersonalData->theme & 0xF) {
		case 1:
		case 4:
			col = 4;	// Brown
			break;
		case 2:
		case 3:
		case 15:
			col = 2;	// Red
			break;
		case 6:
		case 7:
		case 8:
			col = 0;	// Green
			break;
		case 10:
		case 11:
		case 12:
			col = 3;	// Blue
			break;
		default:
			break;
	}
	col = 0;
	cfg.palette = col;
	gPaletteBank = col;

	return 0;
}

bool updateSettingsFromSV() {
	int val = 0;
	bool changed = false;

	if (cfg.language != val) {
		cfg.language = val;
		gLang = val;
		changed = true;
	}
	settingsChanged |= changed;

	return changed;
}

int loadSettings() {
	FILE *file;

	if (findFolder(folderName)) {
		return 1;
	}
	if ( (file = fopen(settingName, "r")) ) {
		fread(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		if (!strstr(cfg.magic,"cfg")) {
			infoOutput("Error in settings file.");
			return 1;
		}
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
		return 1;
	}

	gGammaValue = cfg.gammaValue;
	gContrastValue = cfg.contrastValue;
	emuSettings  = cfg.emuSettings & ~EMUSPEED_MASK;	// Clear speed setting.
	sleepTime    = cfg.sleepTime;
	joyCfg       = (joyCfg & ~0x400)|((cfg.controller & 1)<<10);
	strlcpy(currentDir, cfg.currentPath, sizeof(currentDir));

	infoOutput("Settings loaded.");
	return 0;
}

void saveSettings() {
	FILE *file;

	strcpy(cfg.magic,"cfg");
	cfg.gammaValue  = gGammaValue;
	cfg.contrastValue  = gContrastValue;
	cfg.emuSettings = emuSettings & ~EMUSPEED_MASK;		// Clear speed setting.
	cfg.sleepTime   = sleepTime;
	cfg.controller  = (joyCfg>>10)&1;
	strlcpy(cfg.currentPath, currentDir, sizeof(cfg.currentPath));

	if (findFolder(folderName)) {
		return;
	}
	if ( (file = fopen(settingName, "w")) ) {
		fwrite(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		infoOutput("Settings saved.");
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
	}
}

//void loadSaveGameFile()
void loadNVRAM() {
	FILE *wssFile;
	char nvramName[FILENAMEMAXLENGTH];
	int saveSize = 0;
	void *nvMem = NULL;

	strlcpy(nvramName, currentFilename, sizeof(nvramName));
	if (sramSize > 0) {
		saveSize = sramSize;
		nvMem = svSRAM;
		setFileExtension(nvramName, ".ram", sizeof(nvramName));
	}
	else {
		return;
	}
	if (findFolder(folderName)) {
		return;
	}
	if ( (wssFile = fopen(nvramName, "r")) ) {
		if (fread(nvMem, 1, saveSize, wssFile) != saveSize) {
			infoOutput("Bad NVRAM file:");
			infoOutput(nvramName);
		}
		fclose(wssFile);
		infoOutput("Loaded NVRAM.");
	}
	else {
//		memset(nvMem, 0, saveSize);
		infoOutput("Couldn't open NVRAM file:");
		infoOutput(nvramName);
	}
}

//void writeSaveGameFile() {
void saveNVRAM() {
	FILE *wssFile;
	char nvramName[FILENAMEMAXLENGTH];
	int saveSize = 0;
	void *nvMem = NULL;

	strlcpy(nvramName, currentFilename, sizeof(nvramName));
	if (sramSize > 0) {
		saveSize = sramSize;
		nvMem = svSRAM;
		setFileExtension(nvramName, ".ram", sizeof(nvramName));
	}
	else {
		return;
	}
	if (findFolder(folderName)) {
		return;
	}
	if ( (wssFile = fopen(nvramName, "w")) ) {
		if (fwrite(nvMem, 1, saveSize, wssFile) != saveSize) {
			infoOutput("Couldn't write correct number of bytes.");
		}
		fclose(wssFile);
		infoOutput("Saved NVRAM.");
	}
	else {
		infoOutput("Couldn't open NVRAM file:");
		infoOutput(nvramName);
	}
}

void loadState() {
	FILE *file;
	u32 *statePtr;
	char stateName[FILENAMEMAXLENGTH];

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(stateName, currentFilename, sizeof(stateName));
	setFileExtension(stateName, ".sta", sizeof(stateName));
	int stateSize = getStateSize();
	if ( (file = fopen(stateName, "r")) ) {
		if ( (statePtr = malloc(stateSize)) ) {
			cls(0);
			drawText("        Loading state...", 11, 0);
			fread(statePtr, 1, stateSize, file);
			unpackState(statePtr);
			free(statePtr);
			infoOutput("Loaded state.");
		} else {
			infoOutput("Couldn't alloc mem for state.");
		}
		fclose(file);
	}
	return;
}

void saveState() {
	FILE *file;
	u32 *statePtr;
	char stateName[FILENAMEMAXLENGTH];

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(stateName, currentFilename, sizeof(stateName));
	setFileExtension(stateName, ".sta", sizeof(stateName));
	int stateSize = getStateSize();
	if ( (file = fopen(stateName, "w")) ) {
		if ( (statePtr = malloc(stateSize)) ) {
			cls(0);
			drawText("        Saving state...", 11, 0);
			packState(statePtr);
			fwrite(statePtr, 1, stateSize, file);
			free(statePtr);
			infoOutput("Saved state.");
		}
		else {
			infoOutput("Couldn't alloc mem for state.");
		}
		fclose(file);
	}
}

//---------------------------------------------------------------------------------
bool loadGame(const char *gameName) {
	if ( gameName ) {
		cls(0);
		drawText("     Please wait, loading.", 11, 0);
		gRomSize = loadROM(romSpacePtr, gameName, maxRomSize);
		if ( gRomSize ) {
			checkMachine();
			setEmuSpeed(0);
			loadCart();
			gameInserted = true;
			if ( emuSettings & AUTOLOAD_NVRAM ) {
				loadNVRAM();
			}
			if ( emuSettings & AUTOLOAD_STATE ) {
				loadState();
			}
			closeMenu();
			return false;
		}
	}
	return true;
}

void selectGame() {
	pauseEmulation = true;
	setSelectedMenu(9);
	const char *gameName = browseForFileType(FILEEXTENSIONS".zip");
	if ( loadGame(gameName) ) {
		backOutOfMenu();
	}
}

void checkMachine() {
	char fileExt[8];
	if ( gMachineSet == HW_AUTO ) {
		getFileExtension(fileExt, currentFilename);
		if ( romSpacePtr[gRomSize - 9] != 0 || strstr(fileExt, ".wsc") ) {
			gMachine = HW_SUPERVISIONCOLOR;
		}
		else {
			gMachine = HW_SUPERVISION;
		}
	}
	else {
		gMachine = gMachineSet;
	}
	setupEmuBackground();
}

//---------------------------------------------------------------------------------
void ejectCart() {
	gRomSize = 0x200000;
	memset(romSpacePtr, -1, gRomSize);
	gameInserted = false;
}

//---------------------------------------------------------------------------------
static int loadBIOS(void *dest, const char *fPath, const int maxSize) {
	char tempString[FILEPATHMAXLENGTH];
	char *sPtr;

	cls(0);
	strlcpy(tempString, fPath, sizeof(tempString));
	if ( (sPtr = strrchr(tempString, '/')) ) {
		sPtr[0] = 0;
		sPtr += 1;
		chdir("/");
		chdir(tempString);
		return loadROM(dest, sPtr, maxSize);
	}
	return 0;
}

int loadBnWBIOS(void) {
	if ( loadBIOS(biosSpace, cfg.monoBiosPath, sizeof(biosSpace)) ) {
		g_BIOSBASE_BNW = biosSpace;
		return 1;
	}
	g_BIOSBASE_BNW = NULL;
	return 0;
}

int loadColorBIOS(void) {
	if ( loadBIOS(biosSpaceColor, cfg.colorBiosPath, sizeof(biosSpaceColor)) ) {
		g_BIOSBASE_COLOR = biosSpaceColor;
		return 1;
	}
	g_BIOSBASE_COLOR = NULL;
	return 0;
}

static bool selectBios(char *dest, const char *fileTypes) {
	const char *biosName = browseForFileType(fileTypes);

	if ( biosName ) {
		strlcpy(dest, currentDir, FILEPATHMAXLENGTH);
		strlcat(dest, "/", FILEPATHMAXLENGTH);
		strlcat(dest, biosName, FILEPATHMAXLENGTH);
		return true;
	}
	return false;
}

void selectBnWBios() {
	if ( selectBios(cfg.monoBiosPath, ".ws.rom.zip") ) {
		loadBnWBIOS();
	}
	cls(0);
}

void selectColorBios() {
	if ( selectBios(cfg.colorBiosPath, ".ws.wsc.rom.zip") ) {
		loadColorBIOS();
	}
	cls(0);
}
