# Wasabi V0.2.0

<img align="right" width="220" src="./logo.png" />

This is a Watara/QuickShot Supervision emulator for the Nintendo DS.

## How to use:

1. Create a folder named "wasabi" in either the root of your flash card or in the data folder.
This is where settings and save files end up.
2. Now put game/bios files into a folder where you have (Supervision) roms.
3. Depending on your flashcart you might have to DLDI patch the emulator.

When the emulator starts, you can either press L+R or tap on the screen to open
up the menu.
Now you can use the cross or touchscreen to navigate the menus, A or double tap
to select an option, B or the top of the screen to go back a step.

To select between the tabs use R & L or the touchscreen.

## Menu:

### File:
	Load Game: Select a game to load.
	Load State: Load a previously saved state of the currently running game.
	Save State: Save a state of the currently running game.
	Load NVRAM: Load non volatile ram (EEPROM/SRAM) for the currently running game.
	Save NVRAM: Save non volatile ram (EEPROM/SRAM) for the currently running game.
	Save Settings: Save the current settings (and internal EEPROM).
	Reset Game: Reset the currently running game.

### Options:
	Controller:
		Autofire: Select if you want autofire.
		Controller: 2P start a 2 player game.
		Swap A/B: Swap which NDS button is mapped to which SV button.
	Display:
		Mono Palette: Here you can select the palette for B & W games.
		Gamma: Lets you change the gamma ("brightness").
	Machine Settings:
		Machine: Select the emulated machine.
		Select WS Bios: Load a real WS Bios.
		Cpu speed hacks: Allow speed hacks.
		Change Battery: Change to a new main battery (AA/LR6).
		Language: Select between Japanese and English.
	Settings:
		Speed: Switch between speed modes.
			Normal: Game runs at it's normal speed.
			200%: Game runs at double speed.
			Max: Games can run up to 4 times normal speed (might change).
			50%: Game runs at half speed.
		Allow Refresh Change: Allow the Supervision to change NDS refresh rate.
		Autoload State: Toggle Savestate autoloading.
			Automagically load the savestate associated with the selected game.
		Autoload NVRAM: Toggle EEPROM/SRAM autoloading.
			Automagically load the EEPROM/SRAM associated with the selected game.
		Autosave Settings: This will save settings when
			leaving menu if any changes are made.
		Autopause Game: Toggle if the game should pause when opening the menu.
		Powersave 2nd Screen: If graphics/light should be turned off for the
			GUI screen when menu is not active.
		Emulator on Bottom: Select if top or bottom screen should be used for
			emulator, when menu is active emulator screen is allways on top.
		Autosleep: Doesn't work.
	Debug:
		Debug Output: Show FPS and logged text.
		Disable Foreground: Turn on/off foreground rendering.
		Disable Background: Turn on/off background rendering.
		Disable Sprites: Turn on/off sprite rendering.
		Step Frame: Emulate one frame.

### About:
	Some info about the emulator and game...


## Controls:
	Start is mapped to SV Start.
	Select is mapped to SV Select.
	The d-pad is mapped to SV d-pad.
	 A & B buttons are mapped to SV A & B.

## Games:
	All games should "work".

## Credits:

Huge thanks to Loopy for the incredible PocketNES, without it this emu would
probably never have been made.
Thanks to:
	Peter Trauner & Kevin Horton for docs about the Supervision.
	Osman Celimli for docs & help about the Supervision.


Fredrik Ahlström

Twitter @TheRealFluBBa

http://www.github.com/FluBBaOfWard
