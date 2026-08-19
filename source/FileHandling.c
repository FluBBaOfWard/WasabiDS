#include <nds.h>
#include <stdio.h>
#include <string.h>

#include "FileHandling.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Shared/AsmExtra.h"
#include "Main.h"
#include "Gui.h"
#include "Cart.h"
#include "cpu.h"
#include "Gfx.h"
#include "io.h"
#include "Memory.h"

static const char *const folderName = "wasabi";
static const char *const settingName = "settings.cfg";

ConfigData cfg;

//---------------------------------------------------------------------------------
void applyConfigData(void) {
	emuSettings    = cfg.emuSettings & ~EMUSPEED_MASK; // Clear speed setting.
	gPaletteBank   = cfg.palette;
	gGammaValue    = cfg.gammaValue;
	gContrastValue = cfg.contrastValue;
	joyCfg         = (joyCfg & ~0x400) | ((cfg.controller & 1) << 10);
	strlcpy(currentDir, cfg.currentPath, sizeof(currentDir));
	pauseEmulation = emuSettings & AUTOPAUSE_EMULATION;
}

void updateConfigData(void) {
	strcpy(cfg.magic, "cfg");
	cfg.emuSettings   = emuSettings & ~EMUSPEED_MASK; // Clear speed setting.
	cfg.palette       = gPaletteBank;
	cfg.gammaValue    = gGammaValue;
	cfg.contrastValue = gContrastValue;
	cfg.controller    = (joyCfg >> 10) & 1;
	strlcpy(cfg.currentPath, currentDir, sizeof(cfg.currentPath));
}

void initSettings() {
	memset(&cfg, 0, sizeof(cfg));
	cfg.emuSettings   = AUTOPAUSE_EMULATION | AUTOSLEEP_OFF;
	cfg.contrastValue = 1;

	applyConfigData();
}

int loadSettings() {
	FILE *file;
	if (!findFolder(folderName)
		&& (file = fopen(settingName, "r"))) {
		int len = fread(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		if (strstr(cfg.magic, "cfg") && len == sizeof(ConfigData)) {
			applyConfigData();
			infoOutput("Settings loaded.");
			return 0;
		}
		updateConfigData();
		infoOutput("Error in settings file.");
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
	}
	return 1;
}

int saveSettings() {
	updateConfigData();

	FILE *file;
	if (!findFolder(folderName)
		&& (file = fopen(settingName, "w"))) {
		int len = fwrite(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		if (len == sizeof(ConfigData)) {
			infoOutput("Settings saved.");
			return 0;
		}
		infoOutput("Couldn't save settings.");
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
	}
	return 1;
}

void loadNVRAM() {
	FILE *svsFile;
	char nvramName[FILENAME_MAX_LENGTH];
	int saveSize = 0;
	void *nvMem = NULL;

	if (0 > 0) {
		nvMem = svRAM;
		setFileExtension(nvramName, currentFilename, ".ram", sizeof(nvramName));
	}
	else {
		return;
	}
	if (findFolder(folderName)) {
		return;
	}
	if ( (svsFile = fopen(nvramName, "r")) ) {
		if (fread(nvMem, 1, saveSize, svsFile) != saveSize) {
			infoOutput("Bad NVRAM file:");
			infoOutput(nvramName);
		}
		fclose(svsFile);
		infoOutput("Loaded NVRAM.");
	}
	else {
		infoOutput("Couldn't open NVRAM file:");
		infoOutput(nvramName);
	}
}

void saveNVRAM() {
	FILE *svsFile;
	char nvramName[FILENAME_MAX_LENGTH];
	int saveSize = 0;
	void *nvMem = NULL;

	if (0 > 0) {
		nvMem = svRAM;
		setFileExtension(nvramName, currentFilename, ".ram", sizeof(nvramName));
	}
	else {
		return;
	}
	if (findFolder(folderName)) {
		return;
	}
	if ( (svsFile = fopen(nvramName, "w")) ) {
		if (fwrite(nvMem, 1, saveSize, svsFile) != saveSize) {
			infoOutput("Couldn't write correct number of bytes.");
		}
		fclose(svsFile);
		infoOutput("Saved NVRAM.");
	}
	else {
		infoOutput("Couldn't open NVRAM file:");
		infoOutput(nvramName);
	}
}

void loadState() {
	loadDeviceState(folderName);
}

void saveState() {
	saveDeviceState(folderName);
}

//---------------------------------------------------------------------------------
bool loadGame(const char *gameName) {
	if (gameName) {
		cls(0);
		drawText("     Please wait, loading.", 11, 0);
		gRomSize = loadROM(romSpacePtr, gameName, maxRomSize);
		if (gRomSize) {
			checkMachine();
			setEmuSpeed(0);
			loadCart();
			gameInserted = true;
			if (emuSettings & AUTOLOAD_NVRAM) {
				loadNVRAM();
			}
			if (emuSettings & AUTOLOAD_STATE) {
				loadState();
			}
			powerIsOn = true;
			closeMenu();
			return false;
		}
	}
	return true;
}

void selectGame() {
	pauseEmulation = true;
	ui10();
	const char *gameName = browseForFileType(FILEEXTENSIONS".zip");
	if (loadGame(gameName)) {
		backOutOfMenu();
	}
}

void checkMachine() {
	char fileExt[8];
	if (gMachineSet == HW_AUTO) {
		getFileExtension(fileExt, currentFilename);
		gMachine = HW_SUPERVISION;
	}
	else {
		gMachine = gMachineSet;
	}
	setupEmuBackground();
}

//---------------------------------------------------------------------------------
void ejectCart() {
	gRomSize = 0x80000;
	memset(romSpacePtr, -1, gRomSize);
	gameInserted = false;
}

//---------------------------------------------------------------------------------
static int loadBIOS(void *dest, const char *fPath, const int maxSize) {
	char tempString[FILEPATH_MAX_LENGTH];
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
	if (loadBIOS(NULL, cfg.monoBiosPath, 0)) {
		return 1;
	}
	return 0;
}

static bool selectBios(char *dest, const char *fileTypes) {
	const char *biosName = browseForFileType(fileTypes);

	if (biosName) {
		strlcpy(dest, currentDir, FILEPATH_MAX_LENGTH);
		strlcat(dest, "/", FILEPATH_MAX_LENGTH);
		strlcat(dest, biosName, FILEPATH_MAX_LENGTH);
		return true;
	}
	return false;
}

void selectBnWBios() {
	if (selectBios(cfg.monoBiosPath, ".sv.bin.zip")) {
		loadBnWBIOS();
	}
	cls(0);
}
