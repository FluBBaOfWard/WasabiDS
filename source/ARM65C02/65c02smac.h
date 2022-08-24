PSR_N EQU 0x80000000	;ARM flags
PSR_Z EQU 0x40000000
PSR_C EQU 0x20000000
PSR_V EQU 0x10000000

C EQU 2_00000001	;6502 flags
Z EQU 2_00000010
I EQU 2_00000100
D EQU 2_00001000
B EQU 2_00010000	;(allways 1 except when IRQ pushes it)
R EQU 2_00100000	;(locked at 1)
V EQU 2_01000000
N EQU 2_10000000


	MACRO		;Change CPU mode from System to FIQ
	modeFIQ
	mrs r0,cpsr
	bic r0,r0,#0x0e
	msr cpsr_cf,r0
	MEND

	MACRO		;Change CPU mode from FIQ to System
	modeSystem
	mrs r0,cpsr
	orr r0,r0,#0x0e
	msr cpsr_cf,r0
	MEND

	MACRO				;translate from 6502 PC to rom offset
	encodePC
	and r1,m6502_pc,#0xE000
	adr r2,memmap_tbl
	ldr r0,[r2,r1,lsr#11]
	str r0,lastbank
	add m6502_pc,m6502_pc,r0
	MEND

	MACRO		;pack 6502 flags into r0
	encodeP $extra
	and r0,cycles,#CYC_V+CYC_D+CYC_I+CYC_C
	tst m6502_nz,#PSR_N
	orrne r0,r0,#N				;N
	tst m6502_nz,#0xff
	orreq r0,r0,#Z				;Z
	orr r0,r0,#$extra			;R(&B)
	MEND

	MACRO		;unpack 6502 flags from r0
	decodeP
	bic cycles,cycles,#CYC_V+CYC_D+CYC_I+CYC_C
	and r1,r0,#V+D+I+C
	orr cycles,cycles,r1		;VDIC
	bic m6502_nz,r0,#0xFD			;r0 is signed
	eor m6502_nz,m6502_nz,#Z
	MEND

	MACRO
	fetch $count
	subs cycles,cycles,#$count*3*CYCLE
	ldrplb r0,[m6502_pc],#1
	ldrpl pc,[m6502_optbl,r0,lsl#2]
	ldr pc,nexttimeout
	MEND

	MACRO
	fetch_c $count				;same as fetch except it adds the Carry (bit 0) also.
	sbcs cycles,cycles,#$count*3*CYCLE
	ldrplb r0,[m6502_pc],#1
	ldrpl pc,[m6502_optbl,r0,lsl#2]
	ldr pc,nexttimeout
	MEND

	MACRO
	clearcycles
	and cycles,cycles,#CYC_MASK		;Save CPU bits
	MEND

	MACRO
	readmemabs
	and r1,addy,#0xE000
	adr lr,%F0
	ldr pc,[m6502_rmem,r1,lsr#11]	;in: addy,r1=addy&0xe000
0				;out: r0=val (bits 8-31=0 (LSR,ROR,INC,DEC,ASL)), addy preserved for RMW instructions
	MEND

	MACRO
	readmemzp
	ldrb r0,[cpu_zpage,addy]
	MEND

	MACRO
	readmemzpi
	ldrb r0,[cpu_zpage,addy,lsr#24]
	MEND

	MACRO
	readmemzps
	ldrsb m6502_nz,[cpu_zpage,addy]
	MEND

	MACRO
	readmemimm
	ldrb r0,[m6502_pc],#1
	MEND

	MACRO
	readmemimms
	ldrsb m6502_nz,[m6502_pc],#1
	MEND

	MACRO
	readmem
	[ _type = _ABS
		readmemabs
	]
	[ _type = _ZP
		readmemzp
	]
	[ _type = _ZPI
		readmemzpi
	]
	[ _type = _IMM
		readmemimm
	]
	MEND

	MACRO
	readmems
	[ _type = _ABS
		readmemabs
		orr m6502_nz,r0,r0,lsl#24
	]
	[ _type = _ZP
		readmemzps
	]
	[ _type = _IMM
		readmemimms
	]
	MEND


	MACRO
	writememabs
	and r1,addy,#0xe000
	adr r2,writemem_tbl
	adr lr,%F0
	ldr pc,[r2,r1,lsr#11]	;in: addy,r0=val(bits 8-31=?),r1=addy&0xe000(for CDRAM_W)
0				;out: r0,r1,r2,addy=?
	MEND

	MACRO
	writememzp
	strb r0,[cpu_zpage,addy]
	MEND

	MACRO
	writememzpi
	strb r0,[cpu_zpage,addy,lsr#24]
	MEND

	MACRO
	writemem
	[ _type = _ABS
		writememabs
	]
	[ _type = _ZP
		writememzp
	]
	[ _type = _ZPI
		writememzpi
	]
	MEND
;----------------------------------------------------------------------------

	MACRO
	push16		;push r0
	mov r1,r0,lsr#8
	ldr r2,m6502_s
	strb r1,[r2],#-1
	orr r2,r2,#0x100
	strb r0,[r2],#-1
	strb r2,m6502_s
	MEND		;r1,r2=?

	MACRO
	push8 $x
	ldr r2,m6502_s
	strb $x,[r2],#-1
	strb r2,m6502_s
	MEND		;r2=?

	MACRO
	pop16		;pop m6502_pc
	ldrb r2,m6502_s
	add r2,r2,#2
	strb r2,m6502_s
	ldr r2,m6502_s
	ldrb r0,[r2],#-1
	orr r2,r2,#0x100
	ldrb m6502_pc,[r2]
	orr m6502_pc,m6502_pc,r0,lsl#8
	MEND		;r0,r1=?

	MACRO
	pop8 $x
	ldrb r2,m6502_s
	add r2,r2,#1
	strb r2,m6502_s
	orr r2,r2,#0x100
	ldrsb $x,[r2,cpu_zpage]		;signed for PLA & PLP
	MEND	;r2=?

;----------------------------------------------------------------------------
;doXXX: load addy, increment m6502_pc

	GBLA _type

_IMM	EQU	1						;immediate
_ZP		EQU	2						;zero page
_ZPI	EQU	3						;zero page indexed
_ABS	EQU	4						;absolute

	MACRO
	doABS                           ;absolute               $nnnn
_type	SETA      _ABS
	ldrb addy,[m6502_pc],#1
	ldrb r0,[m6502_pc],#1
	orr addy,addy,r0,lsl#8
	MEND

	MACRO
	doAIX                           ;absolute indexed X     $nnnn,X
_type	SETA      _ABS
	ldrb addy,[m6502_pc],#1
	ldrb r0,[m6502_pc],#1
	orr addy,addy,r0,lsl#8
	add addy,addy,m6502_x,lsr#24
;	bic addy,addy,#0xff0000
	MEND

	MACRO
	doAIY                           ;absolute indexed Y     $nnnn,Y
_type	SETA      _ABS
	ldrb addy,[m6502_pc],#1
	ldrb r0,[m6502_pc],#1
	orr addy,addy,r0,lsl#8
	add addy,addy,m6502_y,lsr#24
;	bic addy,addy,#0xff0000
	MEND

	MACRO
	doIMM                           ;immediate              #$nn
_type	SETA      _IMM
	MEND

	MACRO
	doIIX                           ;indexed indirect X     ($nn,X)
_type	SETA      _ABS
	ldrb r0,[m6502_pc],#1
	add r0,m6502_x,r0,lsl#24
	ldrb addy,[cpu_zpage,r0,lsr#24]
	add r0,r0,#0x01000000
	ldrb r1,[cpu_zpage,r0,lsr#24]
	orr addy,addy,r1,lsl#8
	MEND

	MACRO
	doIIY                           ;indirect indexed Y     ($nn),Y
_type	SETA      _ABS
	ldrb r0,[m6502_pc],#1
	ldrb addy,[r0,cpu_zpage]!
	ldrb r1,[r0,#1]
	orr addy,addy,r1,lsl#8
	add addy,addy,m6502_y,lsr#24
;	bic addy,addy,#0xff0000
	MEND

	MACRO
	doZPI							;Zeropage indirect     ($nn)
_type	SETA      _ABS
	ldrb r0,[m6502_pc],#1
	ldrb addy,[r0,cpu_zpage]!
	ldrb r1,[r0,#1]
	orr addy,addy,r1,lsl#8
	MEND

	MACRO
	doZ                             ;zero page              $nn
_type	SETA      _ZP
	ldrb addy,[m6502_pc],#1
	MEND

	MACRO
	doZ2							;zero page              $nn
_type	SETA      _ZP
	ldrb addy,[m6502_pc],#2			;ugly thing for bbr/bbs
	MEND

	MACRO
	doZIX							;zero page indexed X    $nn,X
_type	SETA      _ZP
	ldrb addy,[m6502_pc],#1
	add addy,addy,m6502_x,lsr#24
	and addy,addy,#0xff
	MEND

	MACRO
	doZIXf							;zero page indexed X    $nn,X
_type	SETA      _ZPI
	ldrb addy,[m6502_pc],#1
	add addy,m6502_x,addy,lsl#24
	MEND

	MACRO
	doZIY							;zero page indexed Y    $nn,Y
_type	SETA      _ZP
	ldrb addy,[m6502_pc],#1
	add addy,addy,m6502_y,lsr#24
	and addy,addy,#0xff
	MEND

	MACRO
	doZIYf							;zero page indexed Y    $nn,Y
_type	SETA      _ZPI
	ldrb addy,[m6502_pc],#1
	add addy,m6502_y,addy,lsl#24
	MEND

;----------------------------------------------------------------------------

	MACRO
	opADC
	readmem
	tst cycles,#CYC_D
	bne opADC_Dec

	movs r1,cycles,lsr#1			;get C
	subcs r0,r0,#0x00000100
	adcs m6502_a,m6502_a,r0,ror#8
	mov m6502_nz,m6502_a,asr#24		;NZ
	orr cycles,cycles,#CYC_C+CYC_V	;Prepare C & V
	bicvc cycles,cycles,#CYC_V		;V
	MEND

	MACRO
	opADCD
	movs r1,cycles,lsr#1        	;get C
	and r1,r0,#0xF
	subcs r1,r1,#0x10
	mov r1,r1,ror#4
	adcs r1,r1,m6502_a,lsl#4
	cmncc r1,#0x60000000
	addcs r1,r1,#0x60000000

	mov r2,m6502_a,lsr#28
	adc r0,r2,r0,lsr#4
	movs r0,r0,lsl#28				;Set C
	cmncc r0,#0x60000000
	addcs r0,r0,#0x60000000
	orr m6502_a,r0,r1,lsr#4

	mov m6502_nz,m6502_a,asr#24 	;NZ
	orr cycles,cycles,#CYC_C		;Prepare C
	MEND


	MACRO
	opAND
	readmem
	and m6502_a,m6502_a,r0,lsl#24
	mov m6502_nz,m6502_a,asr#24		;NZ
	MEND

	MACRO
	opASL
	readmem
	 add r0,r0,r0
	 orrs m6502_nz,r0,r0,lsl#24		;NZ
	 orr cycles,cycles,#CYC_C		;Prepare C
	writemem
	MEND

	MACRO
	opBBR $x
	doZ2
	readmemzp
	tst r0,#1<<$x
	bne nobbranch
	ldreqsb r0,[m6502_pc,#-1]
	addeq m6502_pc,m6502_pc,r0
	fetch 6
	MEND

	MACRO
	opBBRx $x
	doZ2
	readmemzp
	tst r0,#1<<$x
	bne nobbranch
	ldreqsb r0,[m6502_pc,#-1]
	addeq m6502_pc,m6502_pc,r0
	cmp r0,#-3
	andeq cycles,cycles,#CYC_MASK	;Save CPU bits
	fetch 6
	MEND

	MACRO
	opBBS $x
	doZ2
	readmemzp
	tst r0,#1<<$x
	beq nobbranch
	ldrnesb r0,[m6502_pc,#-1]
	addne m6502_pc,m6502_pc,r0
	fetch 6
	MEND

	MACRO
	opBBSx $x
	doZ2
	readmemzp
	tst r0,#1<<$x
	beq nobbranch
	ldrnesb r0,[m6502_pc,#-1]
	addne m6502_pc,m6502_pc,r0
	cmp r0,#-3
	andeq cycles,cycles,#CYC_MASK	;Save CPU bits
	fetch 6
	MEND

	MACRO
	opBIT
	readmem
	bic cycles,cycles,#CYC_V		;reset V
	tst r0,#V
	orrne cycles,cycles,#CYC_V		;V
	and m6502_nz,r0,m6502_a,lsr#24	;Z
	orr m6502_nz,m6502_nz,r0,lsl#24	;N
	MEND

	MACRO
	opCOMP $x			;A,X & Y
	readmem
	subs m6502_nz,$x,r0,lsl#24
	mov m6502_nz,m6502_nz,asr#24	;NZ
	orr cycles,cycles,#CYC_C		;Prepare C
	MEND

	MACRO
	opDEC
	readmem
	sub r0,r0,#1
	orr m6502_nz,r0,r0,lsl#24		;NZ
	writemem
	MEND

	MACRO
	opEOR
	readmem
	eor m6502_a,m6502_a,r0,lsl#24
	mov m6502_nz,m6502_a,asr#24		;NZ
	MEND

	MACRO
	opINC
	readmem
	add r0,r0,#1
	orr m6502_nz,r0,r0,lsl#24		;NZ
	writemem
	MEND

	MACRO
	opLOAD $x
	readmems
	mov $x,m6502_nz,lsl#24
	MEND

	MACRO
	opLSR
	[ _type = _ABS
		readmemabs
		movs r0,r0,lsr#1
		orr cycles,cycles,#CYC_C	;Prepare C
		mov m6502_nz,r0				;Z, (N=0)
		writememabs
	]
	[ _type = _ZP
		ldrb m6502_nz,[cpu_zpage,addy]
		movs m6502_nz,m6502_nz,lsr#1	;Z, (N=0)
		orr cycles,cycles,#CYC_C	;Prepare C
		strb m6502_nz,[cpu_zpage,addy]
	]
	[ _type = _ZPI
		ldrb m6502_nz,[cpu_zpage,addy,lsr#24]
		movs m6502_nz,m6502_nz,lsr#1	;Z, (N=0)
		orr cycles,cycles,#CYC_C	;Prepare C
		strb m6502_nz,[cpu_zpage,addy,lsr#24]
	]
	MEND

	MACRO
	opORA
	readmem
	orr m6502_a,m6502_a,r0,lsl#24
	mov m6502_nz,m6502_a,asr#24
	MEND

	MACRO
	opRMB $x
	doZ
	readmemzp
	bic r0,r0,#1<<$x
	writememzp
	fetch 5
	MEND

	MACRO
	opROL
	readmem
	 movs cycles,cycles,lsr#1		;get C
	 adc r0,r0,r0
	 orrs m6502_nz,r0,r0,lsl#24		;NZ
	 adc cycles,cycles,cycles		;Set C
	writemem
	MEND

	MACRO
	opROR
	readmem
	 movs cycles,cycles,lsr#1		;get C
	 orrcs r0,r0,#0x100
	 movs r0,r0,lsr#1
	 orr m6502_nz,r0,r0,lsl#24		;NZ
	 adc cycles,cycles,cycles		;Set C
	writemem
	MEND

	MACRO
	opSBC
	readmem
	tst cycles,#CYC_D
	bne opSBC_Dec

	movs r1,cycles,lsr#1			;get C
	sbcs m6502_a,m6502_a,r0,lsl#24
	and m6502_a,m6502_a,#0xff000000
	mov m6502_nz,m6502_a,asr#24 	;NZ
	orr cycles,cycles,#CYC_C+CYC_V	;Prepare C & V
	bicvc cycles,cycles,#CYC_V		;V
	MEND

	MACRO
	opSBCD
	movs r1,cycles,ror#1			;get C
	mov r2,m6502_a,lsl#4
	sbcs r1,r2,r0,lsl#28
	and r1,r1,#0xf0000000
	subcc r1,r1,#0x60000000

	mov r2,m6502_a,lsr#28
	sbcs r0,r2,r0,lsr#4
	mov r0,r0,lsl#28
	subcc r0,r0,#0x60000000
	orr m6502_a,r0,r1,lsr#4

	mov m6502_nz,m6502_a,asr#24 	;NZ
	orr cycles,cycles,#CYC_C		;Prepare C
	MEND

	MACRO
	opSMB $x
	doZ
	readmemzp
	orr r0,r0,#1<<$x
	writememzp
	fetch 5
	MEND

	MACRO
	opSTORE $x
	mov r0,$x,lsr#24
	writemem
	MEND

	MACRO
	opSTZ
	mov r0,#0
	writemem
	MEND

	MACRO
	opTRB
	readmem
	 bic r0,r0,m6502_a,lsr#24		;result
	 bic m6502_nz,m6502_nz,#0xFF
	 orr m6502_nz,m6502_nz,r0		;Z
	writemem
	MEND

	MACRO
	opTSB
	readmem
	 orr r0,r0,m6502_a,lsr#24		;result
	 bic m6502_nz,m6502_nz,#0xFF
	 orr m6502_nz,m6502_nz,r0		;Z
	writemem
	MEND

;----------------------------------------------------
	END
