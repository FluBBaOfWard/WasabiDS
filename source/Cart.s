#ifdef __arm__

#include "KS5360/KS5360.i"
#include "ARM6502/M6502.i"

	.global machineInit
	.global loadCart
	.global romNum
	.global cartFlags
	.global romStart
	.global bankSwitchCart
	.global reBankSwitchCart
	.global BankSwitch89AB_W
	.global clearDirtyTiles

	.global romSpacePtr
	.global MEMMAPTBL_

	.global biosBase
	.global biosSpace
	.global biosSpaceColor
	.global g_BIOSBASE_BNW
	.global g_BIOSBASE_COLOR
	.global svRAM
	.global svVRAM
	.global DIRTYTILES
	.global svSRAM
	.global sramSize
	.global gRomSize
	.global maxRomSize
	.global romMask
	.global gGameID
	.global gConfig
	.global gMachine
	.global gMachineSet
	.global gSOC
	.global gLang
	.global gPaletteBank

	.syntax unified
	.arm

	.section .rodata
	.align 2

ROM_Space:
//	.incbin "roms/Alien.sv"
//	.incbin "roms/Bubble World (1992) (Bon Treasure).sv"
//	.incbin "roms/Cave Wonder (1992) (Bon Treasure).sv"
//	.incbin "roms/Climber (1992) (Bon Treasure).sv"
//	.incbin "roms/Happy Pairs (1992) (Sachen).sv"
//	.incbin "roms/Jaguar Bomber (1992) (Bon Treasure).sv"
//	.incbin "roms/Journey to the West (US).sv"
//	.incbin "roms/Juggler (1992) (Bon Treasure).sv"
//	.incbin "roms/Kitchen War (1992) (Bon Treasure).sv"
//	.incbin "roms/WaTest.sv"
ROM_SpaceEnd:
WS_BIOS_INTERNAL:
//	.incbin "wsroms/boot.rom"
WSC_BIOS_INTERNAL:
//	.incbin "wsroms/boot1.rom"

	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

//	ldr r0,=romSize
//	mov r1,#ROM_SpaceEnd-ROM_Space
//	str r1,[r0]
//	ldr r0,=romSpacePtr
//	ldr r7,=ROM_Space
//	str r7,[r0]

	bl memoryMapInit
	bl gfxInit
//	bl ioInit
	bl soundInit
	bl cpuInit

	ldmfd sp!,{r4-r11,lr}
	bx lr

	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr m6502optbl,=m6502OpTable

	ldr r0,romSize
	movs r1,r0,lsr#14		;@ 16kB blocks.
	subne r1,r1,#1
	str r1,romMask			;@ romMask=romBlocks-1

	bl resetCartridgeBanks

	ldrb r5,gMachine
	cmp r5,#HW_SUPERVISION
	moveq r0,#1				;@ Set boot rom overlay (size small)
	ldreq r1,g_BIOSBASE_BNW
	ldreq r2,=WS_BIOS_INTERNAL
	moveq r4,#SOC_ASWAN
	movne r0,#2				;@ Set boot rom overlay (size big)
	ldrne r1,g_BIOSBASE_COLOR
	ldrne r2,=WSC_BIOS_INTERNAL
	movne r4,#SOC_KS5360
	strb r4,gSOC
	cmp r1,#0
	moveq r1,r2				;@ Use internal bios
	str r1,biosBase


	ldr r0,=svRAM			;@ Clear RAM
	mov r1,#0x4000/4
	bl memclr_
	bl clearDirtyTiles

//	bl hacksInit
	bl gfxReset
	bl resetCartridgeBanks
	bl ioReset
	bl soundReset
	bl cpuReset
	ldmfd sp!,{r4-r11,lr}
	bx lr


;@----------------------------------------------------------------------------
clearDirtyTiles:
;@----------------------------------------------------------------------------
	ldr r0,=DIRTYTILES			;@ Clear RAM
	mov r1,#0x200/4
	b memclr_

;@----------------------------------------------------------------------------
memoryMapInit:
;@----------------------------------------------------------------------------
	ldr r0,=m6502OpTable

	ldr r1,=svRAM
	str r1,[r0,#m6502MemTbl+0*4]		;@ 0 RAM
	ldr r1,=svVRAM
	str r1,[r0,#m6502MemTbl+2*4]		;@ 0 VRAM

	ldr r1,=ram6502R
	str r1,[r0,#m6502ReadTbl+0*4]
	ldr r1,=wsvReadIO
	str r1,[r0,#m6502ReadTbl+1*4]
	ldr r1,=vram6502R
	str r1,[r0,#m6502ReadTbl+2*4]
	ldr r1,=empty_R
	str r1,[r0,#m6502ReadTbl+3*4]
	ldr r1,=mem6502R4
	str r1,[r0,#m6502ReadTbl+4*4]
	ldr r1,=mem6502R5
	str r1,[r0,#m6502ReadTbl+5*4]
	ldr r1,=mem6502R6
	str r1,[r0,#m6502ReadTbl+6*4]
	ldr r1,=mem6502R7
	str r1,[r0,#m6502ReadTbl+7*4]

	ldr r1,=ram6502W
	str r1,[r0,#m6502WriteTbl+0*4]
	ldr r1,=wsvWriteIO
	str r1,[r0,#m6502WriteTbl+1*4]
	ldr r1,=vram6502W
	str r1,[r0,#m6502WriteTbl+2*4]
	ldr r1,=empty_W
	str r1,[r0,#m6502WriteTbl+3*4]
	ldr r1,=rom_W
	str r1,[r0,#m6502WriteTbl+4*4]
	str r1,[r0,#m6502WriteTbl+5*4]
	str r1,[r0,#m6502WriteTbl+6*4]
	str r1,[r0,#m6502WriteTbl+7*4]

	bx lr
;@----------------------------------------------------------------------------
resetCartridgeBanks:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r1,#0
	bl BankSwitch89AB_W
	mov r1,#-1
	bl BankSwitchCDEF_W
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
reBankSwitchCart:				;@ r0 = LinkPort val, r1 = BankChip val
;@----------------------------------------------------------------------------
	ldr m6502optbl,=m6502OpTable
;@----------------------------------------------------------------------------
bankSwitchCart:					;@ r0 = LinkPort val, r1 = BankChip val
;@----------------------------------------------------------------------------
	mov r1,r1,lsr#5
	ldrb r2,romMask
	cmp r2,#8
	bmi BankSwitch89AB_W
	tst r1,#4
	orrne r0,r0,#0xF
	and r1,r1,#1
	orr r1,r1,r0,lsl#1
;@----------------------------------------------------------------------------
BankSwitch89AB_W:				;@ 0x8000-0xBFFF
;@----------------------------------------------------------------------------
	ldr r0,romMask
	ldr r2,romSpacePtr
	and r0,r0,r1
	sub r2,r2,#0x8000

	add r0,r2,r0,lsl#14		;@ 16kB blocks.
	str r0,[m6502optbl,#m6502MemTbl+4*4]
	str r0,[m6502optbl,#m6502MemTbl+5*4]
	bx lr
;@----------------------------------------------------------------------------
BankSwitchCDEF_W:				;@ 0xC000-0xFFFF
;@----------------------------------------------------------------------------
	ldr r0,romMask
	ldr r2,romSpacePtr
	and r0,r0,r1
	sub r2,r2,#0xC000

	add r0,r2,r0,lsl#14		;@ 16kB blocks.
	str r0,[m6502optbl,#m6502MemTbl+6*4]
	str r0,[m6502optbl,#m6502MemTbl+7*4]

	bx lr

;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ romnumber
romInfo:						;@
emuFlags:
	.byte 0						;@ emuflags      (label this so GUI.c can take a peek) see EmuSettings.h for bitfields
//scaling:
	.byte 0						;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ cartflags
gConfig:
	.byte 0						;@ Config, bit 7=BIOS on/off
gMachineSet:
	.byte HW_AUTO
gMachine:
	.byte HW_SUPERVISION
gSOC:
	.byte SOC_KS5360
gLang:
	.byte 1						;@ language
gPaletteBank:
	.byte 0						;@ palettebank
gGameID:
	.byte 0						;@ Game ID
	.byte 0
	.byte 0
	.space 2					;@ alignment.

romSpacePtr:
	.long 0
g_BIOSBASE_BNW:
	.long 0
g_BIOSBASE_COLOR:
	.long 0
gRomSize:
romSize:
	.long 0
maxRomSize:
	.long 0
romMask:
	.long 0
biosBase:
	.long 0
sramSize:
	.long 0

#ifdef GBA
	.section .sbss				;@ For the GBA
#else
	.section .bss
#endif
	.align 2
svRAM:
	.space 0x2000
svVRAM:
	.space 0x2000
DIRTYTILES:
	.space 0x200
svSRAM:
	.space 0x2000
biosSpace:
	.space 0x1000
biosSpaceColor:
	.space 0x2000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
