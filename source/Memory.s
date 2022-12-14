#ifdef __arm__

#include "ARM6502/M6502mac.h"

	.global empty_R
	.global empty_W
	.global empty_IO_R
	.global empty_IO_W
	.global rom_W
	.global ram6502W
	.global ram6502R
	.global vram6502R
	.global vram6502W
	.global mem6502R4
	.global mem6502R5
	.global mem6502R6
	.global mem6502R7


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
empty_R:					;@ Read bad address (error)
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
empty_IO_R:					;@ Read bad IO address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0x10
	bx lr
;@----------------------------------------------------------------------------
empty_W:					;@ Write bad address (error)
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
empty_IO_W:					;@ Write bad IO address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0x18
	bx lr
;@----------------------------------------------------------------------------
rom_W:						;@ Write ROM address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0xB0
	bx lr
;@----------------------------------------------------------------------------

#ifdef NDS
	.section .itcm						;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#endif
	.align 2

;@----------------------------------------------------------------------------
ram6502W:					;@ Ram write ($0000-$1FFF)
;@----------------------------------------------------------------------------
	strb r0,[m6502zpage,addy]
	bx lr
;@----------------------------------------------------------------------------
vram6502W:					;@ VRam write ($4000-$5FFF)
;@----------------------------------------------------------------------------
	add r1,m6502zpage,#0x2000-0x4000
	strb r0,[r1,addy]
//	add r1,m6502zpage,#0x4000
//	strb m6502a,[r1,addy,lsr#11]
	bx lr
;@----------------------------------------------------------------------------
ram6502R:					;@ Ram read ($0000-$1FFF)
;@----------------------------------------------------------------------------
	ldrb r0,[m6502zpage,addy]
	bx lr
;@----------------------------------------------------------------------------
vram6502R:					;@ VRam read ($4000-$5FFF)
;@----------------------------------------------------------------------------
	add r1,m6502zpage,#0x2000-0x4000
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R4:					;@ Mem read ($8000-$9FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+16]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R5:					;@ Mem read ($A000-$BFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+20]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R6:					;@ Mem read ($C000-$DFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+24]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R7:					;@ Mem read ($E000-$FFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+28]
	ldrb r0,[r1,addy]
	bx lr

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
