  // File Comments
/**
 * @mainpage cx16-rom-flash.c
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @brief COMMANDER X16 ROM FLASH UTILITY
 *
 * Please find below some technical details how this flash ROM utility works, for those who are interested.
 *
 * This flash utility can be used to flash a new ROM.BIN into ROM banks of the COMMANDER X16.
 * ROM upgrades for the CX16 will come as ROM.BIN files, and will probably be downloadable from a dedicated location.
 * Because the ROM.BIN files are significantly large binaries, ROM flashing will only be possible from the SD card.
 * Therefore, this utility follows a simple and lean upload and flashing design, keeping it as simple as possible.
 * The utility program is to be placed onto a folder on the SD card, together with the ROM.BIN file.
 * The user can then simply load the program and run it from the SD card folder to flash the ROM.
 *
 *
 * The main principles of ROM flashing is to **unlock the ROM** for flashing following pre-defined read/write sequences
 * defined by the manufacturer of the chip. Once these sequences have been correctly initiated, a byte can be written
 * at a specified ROM address. And this is where it got tricky and interesting concerning the COMMANDER X16
 * address bus and architecture, to develop a COMMANDER X16 program that allows the flashing onto the hardware itself.
 *
 *
 * # ROM Adressing
 *
 * The addressing of the ROM chips follow 22 bit wide addressing mode, and is implemented on the CX16 in a special way.
 * The CX16 has 32 banks ROM of 16KB each, so it implements a banking solution to address the 22 bit wide ROM address,
 * where the most significant 8 bits of the 22 bit wide ROM address are configured through zero page $01,
 * configuring one of the 32 ROM banks,
 * while the CX16 main address bus is used to addresses the remaining 14 bits of the 22 bit ROM address.
 *
 * This results in the following architecture, where this flashing program uses a combination of setting the ROM bank
 * and using the main address bus to select the 22 bit wide ROM addresses.
 *
 *
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *                                   | 2 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *                                   | BANK (ZP $01)     | MAIN ADDRESS BUS (+ $C000)                                        |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      ROM_BANK_MASK  0x3FC000      | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      ROM_PTR_MASK   0x003FFF      | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 * Designing this program, there was also one important caveat to keep in mind ... What does the 6502 CPU see?
 * The CPU uses zero page $01 to set the ROM banks, but the lower 14 bits of the 22 bit wide ROM address is visible for the CPU
 * starting at address $C000 and ending at $FFFF (16KB), as the CPU uses a 16 bit address bus!
 * So the lower 14 bits of the ROM address requires the addition of $C000 to reach the correct memory in the ROM by the CPU!
 *
 * # Flashing the ROM
 *
 * ROM flashing is done by executing specific write sequences at specific addresses into the ROM, with specific bytes.
 * Depending on the write sequence, a specific ROM flashing functions are selected.
 *
 * This utility uses the following ROM flashing sequences (there are more available):
 *
 *   - Reading the ROM manufacturer and device ID information.
 *   - Clearing a ROM sector (filling with FF). Each ROM sector is 1KB wide.
 *   - Flashing the cleared ROM sector with new ROM bytes.
 *
 * That's it, simple and easy, but there is more to it than this ...
 *
 * # ROM flashing approach
 *
 * The ROM flashing requires a specific approach, as you need to keep in mind that while flashing ROM, there is **no ROM available**!
 * This utility flashes the ROM in four steps:
 *
 *   1. Read the complete ROM.BIN file from the SD card into (banked) RAM.
 *   2. Flash the ROM from (banked) RAM.
 *   3. Verify that the ROM has been correctly flashed (still TODO).
 *   4. Reset and reboot the COMMANDER X16 using the new ROM state.
 *
 * During and after ROM flash (from step 2), there cannot be any user interaction anymore and all interrupts must be disabled!
 * The screen writing that you see during flashing is executed directly from the program into the VERA, as no ROM screen IO functions can be used anymore.
 *
 *
 * @version 1.1
 * @date 2023-02-27
 *
 * @copyright Copyright (c) 2023
 *
 */
  // Upstart
.cpu _65c02
  // Commander X16 PRG executable file
.file [name="cx16-rom-flash-v2.prg", type="prg", segments="Program"]
.segmentdef Program [segments="Basic, Code, Data"]
.segmentdef Basic [start=$0801]
.segmentdef Code [start=$80d]
.segmentdef Data [startAfter="Code"]
.segment Basic
:BasicUpstart(__start)
  // Global Constants & labels
  /// The colors of the C64
  .const BLACK = 0
  .const WHITE = 1
  .const CYAN = 3
  .const PURPLE = 4
  .const GREEN = 5
  .const BLUE = 6
  .const DARK_GREY = $b
  .const GREY = $c
  // Common CBM Kernal Routines
  .const CBM_SETNAM = $ffbd
  ///< Set the name of a file.
  .const CBM_SETLFS = $ffba
  ///< Set the logical file.
  .const CBM_OPEN = $ffc0
  ///< Open the file for the current logical file.
  .const CBM_CHKIN = $ffc6
  ///< Set the logical channel for input.
  .const CBM_READST = $ffb7
  ///< Read a character from the current channel for input.
  .const CBM_CLOSE = $ffc3
  ///< Close a logical file.
  .const CBM_CLRCHN = $ffcc
  ///< Load a logical file.
  .const CBM_PLOT = $fff0
  ///< Output a character.
  .const CBM_MACPTR = $ff44
  /**
 * @file cx16-kernal.h
 * Specific kernal routines for the commander x16.
 * @author Sven Van de Velde (sven.van.de.velde@telenet.be)
 * @brief CX16 Kernal Wrapper
 * @version 0.1
 * @date 2023-02-19
 * 
 * @copyright Copyright (c) 2023
 * 
 */
  .const CX16_CHRSET = $ff62
  .const BINARY = 2
  .const OCTAL = 8
  .const DECIMAL = $a
  .const HEXADECIMAL = $10
  .const VERA_INC_1 = $10
  .const VERA_ADDRSEL = 1
  .const VERA_LAYER_WIDTH_MASK = $30
  .const VERA_LAYER_HEIGHT_MASK = $c0
  .const OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS = 1
  .const STACK_BASE = $103
  .const isr_vsync = $314
  .const SIZEOF_STRUCT___0 = $8d
  .const SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER = $c
  /// $9F20 VRAM Address (7:0)
  .label VERA_ADDRX_L = $9f20
  /// $9F21 VRAM Address (15:8)
  .label VERA_ADDRX_M = $9f21
  /// $9F22 VRAM Address (7:0)
  /// Bit 4-7: Address Increment  The following is the amount incremented per value value:increment
  ///                             0:0, 1:1, 2:2, 3:4, 4:8, 5:16, 6:32, 7:64, 8:128, 9:256, 10:512, 11:40, 12:80, 13:160, 14:320, 15:640
  /// Bit 3: DECR Setting the DECR bit, will decrement instead of increment by the value set by the 'Address Increment' field.
  /// Bit 0: VRAM Address (16)
  .label VERA_ADDRX_H = $9f22
  /// $9F23	DATA0	VRAM Data port 0
  .label VERA_DATA0 = $9f23
  /// $9F24	DATA1	VRAM Data port 1
  .label VERA_DATA1 = $9f24
  /// $9F25	CTRL Control
  /// Bit 7: Reset
  /// Bit 1: DCSEL
  /// Bit 2: ADDRSEL
  .label VERA_CTRL = $9f25
  /// $9F2A	DC_HSCALE (DCSEL=0)	Active Display H-Scale
  .label VERA_DC_HSCALE = $9f2a
  /// $9F2B	DC_VSCALE (DCSEL=0)	Active Display V-Scale
  .label VERA_DC_VSCALE = $9f2b
  /// $9F34	L1_CONFIG   Layer 1 Configuration
  .label VERA_L1_CONFIG = $9f34
  /// $9F35	L1_MAPBASE	    Layer 1 Map Base Address (16:9)
  .label VERA_L1_MAPBASE = $9f35
  .label BRAM = 0
  .label BROM = 1
.segment Code
  // __start
__start: {
    // __start::__init1
    // __export volatile __address(0x00) unsigned char BRAM = 0
    // [1] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // __export volatile __address(0x01) unsigned char BROM = 4
    // [2] BROM = 4 -- vbuz1=vbuc1 
    lda #4
    sta.z BROM
    // char * __snprintf_buffer
    // [3] __snprintf_buffer = (char *) 0 -- pbum1=pbuc1 
    lda #<0
    sta __snprintf_buffer
    sta __snprintf_buffer+1
    // [4] phi from __start::__init1 to __start::@2 [phi:__start::__init1->__start::@2]
    // __start::@2
    // #pragma constructor_for(conio_x16_init, cputc, clrscr, cscroll)
    // [5] call conio_x16_init
    // [18] phi from __start::@2 to conio_x16_init [phi:__start::@2->conio_x16_init]
    jsr conio_x16_init
    // [6] phi from __start::@2 to __start::@1 [phi:__start::@2->__start::@1]
    // __start::@1
    // [7] call main
    // [70] phi from __start::@1 to main [phi:__start::@1->main]
    jsr main
    // __start::@return
    // [8] return 
    rts
}
  // snputc
/// Print a character into snprintf buffer
/// Used by snprintf()
/// @param c The character to print
// void snputc(__register(X) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    // [9] snputc::c#0 = stackidx(char,snputc::OFFSET_STACK_C) -- vbuxx=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    tax
    // ++__snprintf_size;
    // [10] __snprintf_size = ++ __snprintf_size -- vwum1=_inc_vwum1 
    inc __snprintf_size
    bne !+
    inc __snprintf_size+1
  !:
    // if(__snprintf_size > __snprintf_capacity)
    // [11] if(__snprintf_size<=__snprintf_capacity) goto snputc::@1 -- vwum1_le_vwum2_then_la1 
    lda __snprintf_size+1
    cmp __snprintf_capacity+1
    bne !+
    lda __snprintf_size
    cmp __snprintf_capacity
    beq __b1
  !:
    bcc __b1
    // snputc::@return
    // }
    // [12] return 
    rts
    // snputc::@1
  __b1:
    // if(__snprintf_size==__snprintf_capacity)
    // [13] if(__snprintf_size!=__snprintf_capacity) goto snputc::@3 -- vwum1_neq_vwum2_then_la1 
    lda __snprintf_size+1
    cmp __snprintf_capacity+1
    bne __b2
    lda __snprintf_size
    cmp __snprintf_capacity
    bne __b2
    // [15] phi from snputc::@1 to snputc::@2 [phi:snputc::@1->snputc::@2]
    // [15] phi snputc::c#2 = 0 [phi:snputc::@1->snputc::@2#0] -- vbuxx=vbuc1 
    ldx #0
    // [14] phi from snputc::@1 to snputc::@3 [phi:snputc::@1->snputc::@3]
    // snputc::@3
    // [15] phi from snputc::@3 to snputc::@2 [phi:snputc::@3->snputc::@2]
    // [15] phi snputc::c#2 = snputc::c#0 [phi:snputc::@3->snputc::@2#0] -- register_copy 
    // snputc::@2
  __b2:
    // *(__snprintf_buffer++) = c
    // [16] *__snprintf_buffer = snputc::c#2 -- _deref_pbum1=vbuxx 
    // Append char
    txa
    ldy __snprintf_buffer
    sty.z $fe
    ldy __snprintf_buffer+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // *(__snprintf_buffer++) = c;
    // [17] __snprintf_buffer = ++ __snprintf_buffer -- pbum1=_inc_pbum1 
    inc __snprintf_buffer
    bne !+
    inc __snprintf_buffer+1
  !:
    rts
}
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [609] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [614] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [24] phi from conio_x16_init::@2 to conio_x16_init::@3 [phi:conio_x16_init::@2->conio_x16_init::@3]
    // conio_x16_init::@3
    // cursor(0)
    // [25] call cursor
    jsr cursor
    // [26] phi from conio_x16_init::@3 to conio_x16_init::@4 [phi:conio_x16_init::@3->conio_x16_init::@4]
    // conio_x16_init::@4
    // cbm_k_plot_get()
    // [27] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [28] cbm_k_plot_get::return#2 = cbm_k_plot_get::return#0
    // conio_x16_init::@5
    // [29] conio_x16_init::$4 = cbm_k_plot_get::return#2
    // BYTE1(cbm_k_plot_get())
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuaa=_byte1_vwum1 
    lda __4+1
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio+$d) = conio_x16_init::$5 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // cbm_k_plot_get()
    // [32] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [33] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [34] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuaa=_byte0_vwum1 
    lda __6
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+$e) = conio_x16_init::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+$e
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#1 = *((char *)&__conio+$d) -- vbuxx=_deref_pbuc1 
    ldx __conio+$d
    // [38] gotoxy::y#1 = *((char *)&__conio+$e) -- vbuyy=_deref_pbuc1 
    tay
    // [39] call gotoxy
    // [627] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
    jsr gotoxy
    // conio_x16_init::@7
    // __conio.scroll[0] = 1
    // [40] *((char *)&__conio+$f) = 1 -- _deref_pbuc1=vbuc2 
    lda #1
    sta __conio+$f
    // __conio.scroll[1] = 1
    // [41] *((char *)&__conio+$f+1) = 1 -- _deref_pbuc1=vbuc2 
    sta __conio+$f+1
    // conio_x16_init::@return
    // }
    // [42] return 
    rts
  .segment Data
    .label __4 = cbm_k_plot_get.return
    .label __6 = cbm_k_plot_get.return
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__register(X) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    // [43] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuxx=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    tax
    // if(c=='\n')
    // [44] if(cputc::c#0==' 'pm) goto cputc::@1 -- vbuxx_eq_vbuc1_then_la1 
  .encoding "petscii_mixed"
    cpx #'\n'
    beq __b1
    // cputc::@2
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [45] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [46] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbuaa=_byte0__deref_pwuc1 
    lda __conio+$13
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [47] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [48] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuaa=_byte1__deref_pwuc1 
    lda __conio+$13+1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [49] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [50] cputc::$3 = *((char *)&__conio+3) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [51] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [52] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuxx 
    stx VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [53] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // if(!__conio.hscroll[__conio.layer])
    // [54] if(0==((char *)&__conio+$11)[*((char *)&__conio)]) goto cputc::@5 -- 0_eq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$11,y
    cmp #0
    beq __b5
    // cputc::@3
    // if(__conio.cursor_x >= __conio.mapwidth)
    // [55] if(*((char *)&__conio+$d)>=*((char *)&__conio+6)) goto cputc::@6 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio+$d
    cmp __conio+6
    bcs __b6
    // cputc::@4
    // __conio.cursor_x++;
    // [56] *((char *)&__conio+$d) = ++ *((char *)&__conio+$d) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$d
    // cputc::@7
  __b7:
    // __conio.offset++;
    // [57] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // [58] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // cputc::@return
    // }
    // [59] return 
    rts
    // [60] phi from cputc::@3 to cputc::@6 [phi:cputc::@3->cputc::@6]
    // cputc::@6
  __b6:
    // cputln()
    // [61] call cputln
    jsr cputln
    jmp __b7
    // cputc::@5
  __b5:
    // if(__conio.cursor_x >= __conio.width)
    // [62] if(*((char *)&__conio+$d)>=*((char *)&__conio+4)) goto cputc::@8 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio+$d
    cmp __conio+4
    bcs __b8
    // cputc::@9
    // __conio.cursor_x++;
    // [63] *((char *)&__conio+$d) = ++ *((char *)&__conio+$d) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$d
    // __conio.offset++;
    // [64] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // [65] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    rts
    // [66] phi from cputc::@5 to cputc::@8 [phi:cputc::@5->cputc::@8]
    // cputc::@8
  __b8:
    // cputln()
    // [67] call cputln
    jsr cputln
    rts
    // [68] phi from cputc to cputc::@1 [phi:cputc->cputc::@1]
    // cputc::@1
  __b1:
    // cputln()
    // [69] call cputln
    jsr cputln
    rts
}
  // main
main: {
    .const rom_unlock1_unlock_code = $90
    .const rom_unlock1_rom_write_byte1_value = $aa
    .const rom_unlock1_rom_write_byte2_value = $55
    .const rom_unlock2_unlock_code = $f0
    .const rom_unlock2_rom_write_byte1_value = $aa
    .const rom_unlock2_rom_write_byte2_value = $55
    .const bank_set_bram1_bank = 1
    .const bank_set_bram2_bank = 1
    .const bank_set_bram3_bank = 1
    .const flash_verify1_verify_rom_size = $1000
    .const bank_set_bram4_bank = 1
    .const rom_sector_erase1_rom_unlock1_unlock_code = $80
    .const rom_sector_erase1_rom_unlock1_rom_write_byte1_value = $aa
    .const rom_sector_erase1_rom_unlock1_rom_write_byte2_value = $55
    .const rom_sector_erase1_rom_unlock2_unlock_code = $30
    .const rom_sector_erase1_rom_unlock2_rom_write_byte1_value = $aa
    .const rom_sector_erase1_rom_unlock2_rom_write_byte2_value = $55
    .const flash_write1_rom_unlock1_unlock_code = $a0
    .const flash_write1_rom_unlock1_rom_write_byte1_value = $aa
    .const flash_write1_rom_unlock1_rom_write_byte2_value = $55
    .const flash_verify2_verify_rom_size = $100
    .label __139 = $da
    .label flash_verify1_rom_byte_verify1_rom_bank1___1 = $e0
    .label flash_verify1_rom_byte_verify1_rom_bank1___2 = $e0
    .label flash_verify1_rom_byte_verify1_rom_ptr1___0 = $f6
    .label flash_verify1_rom_byte_verify1_rom_ptr1___2 = $e8
    .label rom_sector_erase1_rom_ptr1___2 = $36
    .label rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___2 = $64
    .label rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___2 = $3e
    .label rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1___2 = $4a
    .label rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___2 = $3b
    .label rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___2 = $38
    .label rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0 = $25
    .label rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___2 = $23
    .label rom_sector_erase1_rom_wait1___0 = $eb
    .label flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___1 = $54
    .label flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___2 = $54
    .label flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0 = $b9
    .label flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___2 = $6c
    .label flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___1 = $58
    .label flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___2 = $58
    .label flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0 = $b5
    .label flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___2 = $6e
    .label flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___1 = $5c
    .label flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___2 = $5c
    .label flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0 = $c2
    .label flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___2 = $70
    .label flash_write1_rom_byte_program1_rom_ptr1___2 = $78
    .label flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___1 = $60
    .label flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___2 = $60
    .label flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0 = $f0
    .label flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___2 = $72
    .label flash_write1_rom_byte_program1_rom_wait1___0 = $50
    .label flash_verify2_rom_byte_verify1_rom_bank1___1 = $c6
    .label flash_verify2_rom_byte_verify1_rom_bank1___2 = $a9
    .label flash_verify2_rom_byte_verify1_rom_ptr1___0 = $ca
    .label flash_verify2_rom_byte_verify1_rom_ptr1___2 = $6a
    .label flash_bytes = $d6
    .label flash_verify1_rom_byte_verify1_value = $bd
    .label flash_verify1_rom_byte_verify1_rom_ptr1_return = $e8
    .label flash_verify1_verify_ram_address = $f4
    .label flash_verify1_verified_bytes = $ec
    .label flash_verify1_correct_bytes = $e4
    .label rom_sector_erase1_ptr_rom = $36
    .label rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_return = $64
    .label rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_return = $3e
    .label rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_return = $4a
    .label rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_return = $3b
    .label rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_return = $38
    .label rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_return = $23
    .label flash_write1_rom_unlock1_address = $c2
    .label flash_write1_rom_unlock1_chip_address = $b5
    .label flash_write1_rom_unlock1_rom_write_byte1_address = $b9
    .label flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_return = $6c
    .label flash_write1_rom_unlock1_rom_write_byte2_address = $b5
    .label flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_return = $6e
    .label flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_return = $70
    .label flash_write1_rom_byte_program1_ptr_rom = $78
    .label flash_write1_rom_byte_program1_rom_write_byte1_value = $42
    .label flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_return = $72
    .label flash_write1_flash_rom_address = $d2
    .label flash_write1_flash_ram_address = $c0
    .label flash_write1_flashed_bytes = $7a
    .label flash_verify2_rom_byte_verify1_rom_ptr1_return = $6a
    .label flash_verify2_verify_rom_address = $ce
    .label flash_verify2_verify_ram_address = $be
    .label flash_verify2_verified_bytes = $74
    .label flash_verify2_correct_bytes = $66
    .label x = $ea
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@42
    // cbm_x_charset(3, (char *)0)
    // [72] cbm_x_charset::charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cbm_x_charset.charset
    // [73] cbm_x_charset::offset = (char *) 0 -- pbum1=pbuc1 
    lda #<0
    sta cbm_x_charset.offset
    sta cbm_x_charset.offset+1
    // [74] call cbm_x_charset
    // Set the charset to lower case.
    jsr cbm_x_charset
    // [75] phi from main::@42 to main::@53 [phi:main::@42->main::@53]
    // main::@53
    // textcolor(WHITE)
    // [76] call textcolor
    // [609] phi from main::@53 to textcolor [phi:main::@53->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:main::@53->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [77] phi from main::@53 to main::@54 [phi:main::@53->main::@54]
    // main::@54
    // bgcolor(BLUE)
    // [78] call bgcolor
    // [614] phi from main::@54 to bgcolor [phi:main::@54->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:main::@54->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [79] phi from main::@54 to main::@55 [phi:main::@54->main::@55]
    // main::@55
    // scroll(0)
    // [80] call scroll
    jsr scroll
    // [81] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
    // clrscr()
    // [82] call clrscr
    jsr clrscr
    // [83] phi from main::@56 to main::@57 [phi:main::@56->main::@57]
    // main::@57
    // frame_draw()
    // [84] call frame_draw
    // [675] phi from main::@57 to frame_draw [phi:main::@57->frame_draw]
    jsr frame_draw
    // [85] phi from main::@57 to main::@58 [phi:main::@57->main::@58]
    // main::@58
    // gotoxy(20, 1)
    // [86] call gotoxy
    // [627] phi from main::@58 to gotoxy [phi:main::@58->gotoxy]
    // [627] phi gotoxy::y#22 = 1 [phi:main::@58->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [627] phi gotoxy::x#22 = $14 [phi:main::@58->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$14
    jsr gotoxy
    // [87] phi from main::@58 to main::@59 [phi:main::@58->main::@59]
    // main::@59
    // printf("rom flash utility")
    // [88] call printf_str
    // [855] phi from main::@59 to printf_str [phi:main::@59->printf_str]
    // [855] phi printf_str::putc#20 = &cputc [phi:main::@59->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s [phi:main::@59->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [89] phi from main::@59 to main::@1 [phi:main::@59->main::@1]
    // [89] phi main::r#10 = 0 [phi:main::@59->main::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // main::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [90] if(main::r#10<8) goto main::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcs !__b2+
    jmp __b2
  !__b2:
    // [91] phi from main::@1 to main::@3 [phi:main::@1->main::@3]
    // [91] phi main::rom_chip#10 = 0 [phi:main::@1->main::@3#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [91] phi main::flash_rom_address#10 = 0 [phi:main::@1->main::@3#1] -- vdum1=vduc1 
    sta flash_rom_address
    sta flash_rom_address+1
    lda #<0>>$10
    sta flash_rom_address+2
    lda #>0>>$10
    sta flash_rom_address+3
    // main::@3
  __b3:
    // for (unsigned long flash_rom_address = 0; flash_rom_address < 8 * 0x80000; flash_rom_address += 0x80000)
    // [92] if(main::flash_rom_address#10<8*$80000) goto main::@4 -- vdum1_lt_vduc1_then_la1 
    lda flash_rom_address+3
    cmp #>8*$80000>>$10
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda flash_rom_address+2
    cmp #<8*$80000>>$10
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda flash_rom_address+1
    cmp #>8*$80000
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda flash_rom_address
    cmp #<8*$80000
    bcs !__b4+
    jmp __b4
  !__b4:
  !:
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [94] phi from main::CLI1 to main::@43 [phi:main::CLI1->main::@43]
    // main::@43
    // sprintf(buffer, "press a key to start flashing.")
    // [95] call snprintf_init
    jsr snprintf_init
    // [96] phi from main::@43 to main::@71 [phi:main::@43->main::@71]
    // main::@71
    // sprintf(buffer, "press a key to start flashing.")
    // [97] call printf_str
    // [855] phi from main::@71 to printf_str [phi:main::@71->printf_str]
    // [855] phi printf_str::putc#20 = &snputc [phi:main::@71->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s1 [phi:main::@71->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@72
    // sprintf(buffer, "press a key to start flashing.")
    // [98] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [99] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [101] call print_text
    // [868] phi from main::@72 to print_text [phi:main::@72->print_text]
    jsr print_text
    // [102] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // wait_key()
    // [103] call wait_key
    // [875] phi from main::@73 to wait_key [phi:main::@73->wait_key]
    jsr wait_key
    // [104] phi from main::@73 to main::@15 [phi:main::@73->main::@15]
    // [104] phi main::flash_chip#10 = 7 [phi:main::@73->main::@15#0] -- vbum1=vbuc1 
    lda #7
    sta flash_chip
    // main::@15
  __b15:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [105] if(main::flash_chip#10!=$ff) goto main::@16 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp flash_chip
    bne __b16
    // [106] phi from main::@15 to main::@17 [phi:main::@15->main::@17]
    // main::@17
    // textcolor(WHITE)
    // [107] call textcolor
    // [609] phi from main::@17 to textcolor [phi:main::@17->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:main::@17->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [108] phi from main::@17 to main::@87 [phi:main::@17->main::@87]
    // main::@87
    // sprintf(buffer, "resetting commander x16" )
    // [109] call snprintf_init
    jsr snprintf_init
    // [110] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // sprintf(buffer, "resetting commander x16" )
    // [111] call printf_str
    // [855] phi from main::@88 to printf_str [phi:main::@88->printf_str]
    // [855] phi printf_str::putc#20 = &snputc [phi:main::@88->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s2 [phi:main::@88->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@89
    // sprintf(buffer, "resetting commander x16" )
    // [112] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [113] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [115] call print_text
    // [868] phi from main::@89 to print_text [phi:main::@89->print_text]
    jsr print_text
    // [116] phi from main::@89 to main::@37 [phi:main::@89->main::@37]
    // [116] phi main::w#2 = 0 [phi:main::@89->main::@37#0] -- vwum1=vwuc1 
    lda #<0
    sta w
    sta w+1
    // main::@37
  __b37:
    // for (unsigned int w = 0; w < 32; w++)
    // [117] if(main::w#2<$20) goto main::@39 -- vwum1_lt_vbuc1_then_la1 
    lda w+1
    bne !+
    lda w
    cmp #$20
    bcc __b9
  !:
    // [118] phi from main::@37 to main::@38 [phi:main::@37->main::@38]
    // main::@38
    // system_reset()
    // [119] call system_reset
    // [885] phi from main::@38 to system_reset [phi:main::@38->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [120] return 
    rts
    // [121] phi from main::@37 to main::@39 [phi:main::@37->main::@39]
  __b9:
    // [121] phi main::v#2 = 0 [phi:main::@37->main::@39#0] -- vwum1=vwuc1 
    lda #<0
    sta v
    sta v+1
    // main::@39
  __b39:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [122] if(main::v#2<$100*$80) goto main::@40 -- vwum1_lt_vwuc1_then_la1 
    lda v+1
    cmp #>$100*$80
    bcc __b40
    bne !+
    lda v
    cmp #<$100*$80
    bcc __b40
  !:
    // main::@41
    // cputc('.')
    // [123] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [124] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for (unsigned int w = 0; w < 32; w++)
    // [126] main::w#1 = ++ main::w#2 -- vwum1=_inc_vwum1 
    inc w
    bne !+
    inc w+1
  !:
    // [116] phi from main::@41 to main::@37 [phi:main::@41->main::@37]
    // [116] phi main::w#2 = main::w#1 [phi:main::@41->main::@37#0] -- register_copy 
    jmp __b37
    // main::@40
  __b40:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [127] main::v#1 = ++ main::v#2 -- vwum1=_inc_vwum1 
    inc v
    bne !+
    inc v+1
  !:
    // [121] phi from main::@40 to main::@39 [phi:main::@40->main::@39]
    // [121] phi main::v#2 = main::v#1 [phi:main::@40->main::@39#0] -- register_copy 
    jmp __b39
    // main::@16
  __b16:
    // if (rom_device_ids[flash_chip] != UNKNOWN)
    // [128] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@18 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b18+
    jmp __b18
  !__b18:
    // [129] phi from main::@16 to main::@35 [phi:main::@16->main::@35]
    // main::@35
    // gotoxy(0, 2)
    // [130] call gotoxy
    // [627] phi from main::@35 to gotoxy [phi:main::@35->gotoxy]
    // [627] phi gotoxy::y#22 = 2 [phi:main::@35->gotoxy#0] -- vbuyy=vbuc1 
    ldy #2
    // [627] phi gotoxy::x#22 = 0 [phi:main::@35->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [131] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [132] phi from main::bank_set_bram1 to main::@45 [phi:main::bank_set_bram1->main::@45]
    // main::@45
    // bank_set_brom(4)
    // [133] call bank_set_brom
    // [891] phi from main::@45 to bank_set_brom [phi:main::@45->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = 4 [phi:main::@45->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::@90
    // if (flash_chip == 0)
    // [134] if(main::flash_chip#10==0) goto main::@19 -- vbum1_eq_0_then_la1 
    lda flash_chip
    bne !__b19+
    jmp __b19
  !__b19:
    // [135] phi from main::@90 to main::@36 [phi:main::@90->main::@36]
    // main::@36
    // sprintf(file, "rom%u.bin", flash_chip)
    // [136] call snprintf_init
    jsr snprintf_init
    // [137] phi from main::@36 to main::@93 [phi:main::@36->main::@93]
    // main::@93
    // sprintf(file, "rom%u.bin", flash_chip)
    // [138] call printf_str
    // [855] phi from main::@93 to printf_str [phi:main::@93->printf_str]
    // [855] phi printf_str::putc#20 = &snputc [phi:main::@93->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s4 [phi:main::@93->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@94
    // sprintf(file, "rom%u.bin", flash_chip)
    // [139] printf_uchar::uvalue#2 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [140] call printf_uchar
    // [894] phi from main::@94 to printf_uchar [phi:main::@94->printf_uchar]
    // [894] phi printf_uchar::format_zero_padding#4 = 0 [phi:main::@94->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [894] phi printf_uchar::format_min_length#4 = 0 [phi:main::@94->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [894] phi printf_uchar::putc#4 = &snputc [phi:main::@94->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [894] phi printf_uchar::format_radix#4 = DECIMAL [phi:main::@94->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [894] phi printf_uchar::uvalue#4 = printf_uchar::uvalue#2 [phi:main::@94->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [141] phi from main::@94 to main::@95 [phi:main::@94->main::@95]
    // main::@95
    // sprintf(file, "rom%u.bin", flash_chip)
    // [142] call printf_str
    // [855] phi from main::@95 to printf_str [phi:main::@95->printf_str]
    // [855] phi printf_str::putc#20 = &snputc [phi:main::@95->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s5 [phi:main::@95->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@96
    // sprintf(file, "rom%u.bin", flash_chip)
    // [143] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [144] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // main::@20
  __b20:
    // unsigned char flash_rom_bank = flash_chip * 32
    // [146] main::flash_rom_bank#0 = main::flash_chip#10 << 5 -- vbum1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta flash_rom_bank
    // FILE *fp = fopen(1, 8, 2, file)
    // [147] call fopen
    // Read the file content.
    jsr fopen
    // [148] fopen::return#4 = fopen::return#1
    // main::@97
    // [149] main::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [150] if((struct $1 *)0!=main::fp#0) goto main::@21 -- pssc1_neq_pssm1_then_la1 
    cmp #>0
    bne __b21
    lda fp
    cmp #<0
    bne __b21
    // [151] phi from main::@97 to main::@34 [phi:main::@97->main::@34]
    // main::@34
    // textcolor(WHITE)
    // [152] call textcolor
    // [609] phi from main::@34 to textcolor [phi:main::@34->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:main::@34->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@107
    // flash_chip * 10
    // [153] main::$178 = main::flash_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda flash_chip
    asl
    asl
    // [154] main::$179 = main::$178 + main::flash_chip#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc flash_chip
    // [155] main::$83 = main::$179 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(2 + flash_chip * 10, 58)
    // [156] gotoxy::x#17 = 2 + main::$83 -- vbuxx=vbuc1_plus_vbuaa 
    clc
    adc #2
    tax
    // [157] call gotoxy
    // [627] phi from main::@107 to gotoxy [phi:main::@107->gotoxy]
    // [627] phi gotoxy::y#22 = $3a [phi:main::@107->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$3a
    // [627] phi gotoxy::x#22 = gotoxy::x#17 [phi:main::@107->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [158] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // printf("no file")
    // [159] call printf_str
    // [855] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [855] phi printf_str::putc#20 = &cputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s7 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [160] print_chip_led::r#6 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [161] call print_chip_led
    // [942] phi from main::@109 to print_chip_led [phi:main::@109->print_chip_led]
    // [942] phi print_chip_led::tc#10 = DARK_GREY [phi:main::@109->print_chip_led#0] -- vbuz1=vbuc1 
    lda #DARK_GREY
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#6 [phi:main::@109->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@18
  __b18:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [162] main::flash_chip#1 = -- main::flash_chip#10 -- vbum1=_dec_vbum1 
    dec flash_chip
    // [104] phi from main::@18 to main::@15 [phi:main::@18->main::@15]
    // [104] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@18->main::@15#0] -- register_copy 
    jmp __b15
    // main::@21
  __b21:
    // table_chip_clear(flash_chip * 32)
    // [163] table_chip_clear::rom_bank#1 = main::flash_chip#10 << 5 -- vbuz1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta.z table_chip_clear.rom_bank
    // [164] call table_chip_clear
    // [962] phi from main::@21 to table_chip_clear [phi:main::@21->table_chip_clear]
    jsr table_chip_clear
    // [165] phi from main::@21 to main::@98 [phi:main::@21->main::@98]
    // main::@98
    // textcolor(WHITE)
    // [166] call textcolor
    // [609] phi from main::@98 to textcolor [phi:main::@98->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:main::@98->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@99
    // flash_chip * 10
    // [167] main::$175 = main::flash_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda flash_chip
    asl
    asl
    // [168] main::$176 = main::$175 + main::flash_chip#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc flash_chip
    // [169] main::$91 = main::$176 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(2 + flash_chip * 10, 58)
    // [170] gotoxy::x#16 = 2 + main::$91 -- vbuxx=vbuc1_plus_vbuaa 
    clc
    adc #2
    tax
    // [171] call gotoxy
    // [627] phi from main::@99 to gotoxy [phi:main::@99->gotoxy]
    // [627] phi gotoxy::y#22 = $3a [phi:main::@99->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$3a
    // [627] phi gotoxy::x#22 = gotoxy::x#16 [phi:main::@99->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [172] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // printf("%s", file)
    // [173] call printf_string
    // [985] phi from main::@100 to printf_string [phi:main::@100->printf_string]
    // [985] phi printf_string::str#10 = main::buffer [phi:main::@100->printf_string#0] -- pbuz1=pbuc1 
    lda #<buffer
    sta.z printf_string.str
    lda #>buffer
    sta.z printf_string.str+1
    // [985] phi printf_string::format_justify_left#10 = 0 [phi:main::@100->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [985] phi printf_string::format_min_length#6 = 0 [phi:main::@100->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@101
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [174] print_chip_led::r#5 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [175] call print_chip_led
    // [942] phi from main::@101 to print_chip_led [phi:main::@101->print_chip_led]
    // [942] phi print_chip_led::tc#10 = CYAN [phi:main::@101->print_chip_led#0] -- vbuz1=vbuc1 
    lda #CYAN
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#5 [phi:main::@101->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [176] phi from main::@101 to main::@102 [phi:main::@101->main::@102]
    // main::@102
    // sprintf(buffer, "reading in ram ...")
    // [177] call snprintf_init
    jsr snprintf_init
    // [178] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // sprintf(buffer, "reading in ram ...")
    // [179] call printf_str
    // [855] phi from main::@103 to printf_str [phi:main::@103->printf_str]
    // [855] phi printf_str::putc#20 = &snputc [phi:main::@103->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s6 [phi:main::@103->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@104
    // sprintf(buffer, "reading in ram ...")
    // [180] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [181] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [183] call print_text
    // [868] phi from main::@104 to print_text [phi:main::@104->print_text]
    jsr print_text
    // main::rom_address1
    // ((unsigned long)(rom_bank)) << 14
    // [184] main::rom_address1_$1 = (unsigned long)main::flash_rom_bank#0 -- vdum1=_dword_vbum2 
    lda flash_rom_bank
    sta rom_address1___1
    lda #0
    sta rom_address1___1+1
    sta rom_address1___1+2
    sta rom_address1___1+3
    // [185] main::rom_address1_return#0 = main::rom_address1_$1 << $e -- vdum1=vdum1_rol_vbuc1 
    ldx #$e
    cpx #0
    beq !e+
  !:
    asl rom_address1_return
    rol rom_address1_return+1
    rol rom_address1_return+2
    rol rom_address1_return+3
    dex
    bne !-
  !e:
    // main::@46
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [186] flash_read::fp#0 = main::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z flash_read.fp
    lda fp+1
    sta.z flash_read.fp+1
    // [187] flash_read::rom_bank_start#1 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z flash_read.rom_bank_start
    // [188] call flash_read
    // [1007] phi from main::@46 to flash_read [phi:main::@46->flash_read]
    // [1007] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@46->flash_read#0] -- register_copy 
    // [1007] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@46->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [1007] phi flash_read::rom_bank_size#2 = 1 [phi:main::@46->flash_read#2] -- vbuxx=vbuc1 
    ldx #1
    // [1007] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@46->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [189] flash_read::return#3 = flash_read::return#2
    // main::@105
    // [190] main::flash_bytes#0 = flash_read::return#3
    // rom_size(1)
    // [191] call rom_size
    // [1041] phi from main::@105 to rom_size [phi:main::@105->rom_size]
    // [1041] phi rom_size::rom_banks#2 = 1 [phi:main::@105->rom_size#0] -- vbuaa=vbuc1 
    lda #1
    jsr rom_size
    // rom_size(1)
    // [192] rom_size::return#3 = rom_size::return#0
    // main::@106
    // [193] main::$100 = rom_size::return#3
    // if (flash_bytes != rom_size(1))
    // [194] if(main::flash_bytes#0==main::$100) goto main::@22 -- vduz1_eq_vdum2_then_la1 
    lda __100
    cmp.z flash_bytes
    bne !+
    lda __100+1
    cmp.z flash_bytes+1
    bne !+
    lda __100+2
    cmp.z flash_bytes+2
    bne !+
    lda __100+3
    cmp.z flash_bytes+3
    beq __b22
  !:
    rts
    // main::@22
  __b22:
    // flash_rom_address_boundary += flash_bytes
    // [195] main::flash_rom_address_boundary#1 = main::rom_address1_return#0 + main::flash_bytes#0 -- vdum1=vdum2_plus_vduz3 
    lda rom_address1_return
    clc
    adc.z flash_bytes
    sta flash_rom_address_boundary
    lda rom_address1_return+1
    adc.z flash_bytes+1
    sta flash_rom_address_boundary+1
    lda rom_address1_return+2
    adc.z flash_bytes+2
    sta flash_rom_address_boundary+2
    lda rom_address1_return+3
    adc.z flash_bytes+3
    sta flash_rom_address_boundary+3
    // main::bank_set_bram2
    // BRAM = bank
    // [196] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@47
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [197] flash_read::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbuz1=vbum2_plus_1 
    lda flash_rom_bank
    inc
    sta.z flash_read.rom_bank_start
    // [198] flash_read::fp#1 = main::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z flash_read.fp
    lda fp+1
    sta.z flash_read.fp+1
    // [199] call flash_read
    // [1007] phi from main::@47 to flash_read [phi:main::@47->flash_read]
    // [1007] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@47->flash_read#0] -- register_copy 
    // [1007] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@47->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [1007] phi flash_read::rom_bank_size#2 = $1f [phi:main::@47->flash_read#2] -- vbuxx=vbuc1 
    ldx #$1f
    // [1007] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@47->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [200] flash_read::return#4 = flash_read::return#2
    // main::@110
    // flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [201] main::flash_bytes#1 = flash_read::return#4 -- vdum1=vduz2 
    lda.z flash_read.return
    sta flash_bytes_1
    lda.z flash_read.return+1
    sta flash_bytes_1+1
    lda.z flash_read.return+2
    sta flash_bytes_1+2
    lda.z flash_read.return+3
    sta flash_bytes_1+3
    // flash_rom_address_boundary += flash_bytes
    // [202] main::flash_rom_address_boundary#13 = main::flash_rom_address_boundary#1 + main::flash_bytes#1 -- vdum1=vdum2_plus_vdum1 
    clc
    lda flash_rom_address_boundary_1
    adc flash_rom_address_boundary
    sta flash_rom_address_boundary_1
    lda flash_rom_address_boundary_1+1
    adc flash_rom_address_boundary+1
    sta flash_rom_address_boundary_1+1
    lda flash_rom_address_boundary_1+2
    adc flash_rom_address_boundary+2
    sta flash_rom_address_boundary_1+2
    lda flash_rom_address_boundary_1+3
    adc flash_rom_address_boundary+3
    sta flash_rom_address_boundary_1+3
    // fclose(fp)
    // [203] fclose::fp#0 = main::fp#0
    // [204] call fclose
    jsr fclose
    // main::bank_set_bram3
    // BRAM = bank
    // [205] BRAM = main::bank_set_bram3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram3_bank
    sta.z BRAM
    // [206] phi from main::bank_set_bram3 to main::@48 [phi:main::bank_set_bram3->main::@48]
    // main::@48
    // bank_set_brom(4)
    // [207] call bank_set_brom
    // [891] phi from main::@48 to bank_set_brom [phi:main::@48->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = 4 [phi:main::@48->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::rom_address2
    // ((unsigned long)(rom_bank)) << 14
    // [209] main::rom_address2_$1 = (unsigned long)main::flash_rom_bank#0 -- vdum1=_dword_vbum2 
    lda flash_rom_bank
    sta rom_address2___1
    lda #0
    sta rom_address2___1+1
    sta rom_address2___1+2
    sta rom_address2___1+3
    // [210] main::flash_rom_address_sector#0 = main::rom_address2_$1 << $e -- vdum1=vdum1_rol_vbuc1 
    ldx #$e
    cpx #0
    beq !e+
  !:
    asl flash_rom_address_sector
    rol flash_rom_address_sector+1
    rol flash_rom_address_sector+2
    rol flash_rom_address_sector+3
    dex
    bne !-
  !e:
    // [211] phi from main::rom_address2 to main::@49 [phi:main::rom_address2->main::@49]
    // main::@49
    // textcolor(WHITE)
    // [212] call textcolor
    // [609] phi from main::@49 to textcolor [phi:main::@49->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:main::@49->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@111
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [213] print_chip_led::r#7 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [214] call print_chip_led
    // [942] phi from main::@111 to print_chip_led [phi:main::@111->print_chip_led]
    // [942] phi print_chip_led::tc#10 = PURPLE [phi:main::@111->print_chip_led#0] -- vbuz1=vbuc1 
    lda #PURPLE
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#7 [phi:main::@111->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [215] phi from main::@111 to main::@112 [phi:main::@111->main::@112]
    // main::@112
    // sprintf(buffer, "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error.")
    // [216] call snprintf_init
    jsr snprintf_init
    // [217] phi from main::@112 to main::@113 [phi:main::@112->main::@113]
    // main::@113
    // sprintf(buffer, "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error.")
    // [218] call printf_str
    // [855] phi from main::@113 to printf_str [phi:main::@113->printf_str]
    // [855] phi printf_str::putc#20 = &snputc [phi:main::@113->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s8 [phi:main::@113->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@114
    // sprintf(buffer, "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error.")
    // [219] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [220] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [222] call print_text
    // [868] phi from main::@114 to print_text [phi:main::@114->print_text]
    jsr print_text
    // [223] phi from main::@114 to main::@23 [phi:main::@114->main::@23]
    // [223] phi main::y_sector#25 = 4 [phi:main::@114->main::@23#0] -- vbum1=vbuc1 
    lda #4
    sta y_sector
    // [223] phi main::x_sector#26 = $e [phi:main::@114->main::@23#1] -- vbum1=vbuc1 
    lda #$e
    sta x_sector
    // [223] phi main::read_ram_address_sector#4 = (char *) 16384 [phi:main::@114->main::@23#2] -- pbum1=pbuc1 
    lda #<$4000
    sta read_ram_address_sector
    lda #>$4000
    sta read_ram_address_sector+1
    // [223] phi main::read_ram_bank_sector#3 = 1 [phi:main::@114->main::@23#3] -- vbum1=vbuc1 
    lda #1
    sta read_ram_bank_sector
    // [223] phi main::flash_rom_address_sector#2 = main::flash_rom_address_sector#0 [phi:main::@114->main::@23#4] -- register_copy 
    // [223] phi from main::@29 to main::@23 [phi:main::@29->main::@23]
    // [223] phi main::y_sector#25 = main::y_sector#25 [phi:main::@29->main::@23#0] -- register_copy 
    // [223] phi main::x_sector#26 = main::x_sector#1 [phi:main::@29->main::@23#1] -- register_copy 
    // [223] phi main::read_ram_address_sector#4 = main::read_ram_address_sector#13 [phi:main::@29->main::@23#2] -- register_copy 
    // [223] phi main::read_ram_bank_sector#3 = main::read_ram_bank_sector#14 [phi:main::@29->main::@23#3] -- register_copy 
    // [223] phi main::flash_rom_address_sector#2 = main::flash_rom_address_sector#1 [phi:main::@29->main::@23#4] -- register_copy 
    // main::@23
  __b23:
    // while (flash_rom_address_sector < flash_rom_address_boundary)
    // [224] if(main::flash_rom_address_sector#2<main::flash_rom_address_boundary#13) goto main::flash_verify1 -- vdum1_lt_vdum2_then_la1 
    lda flash_rom_address_sector+3
    cmp flash_rom_address_boundary_1+3
    bcc flash_verify1
    bne !+
    lda flash_rom_address_sector+2
    cmp flash_rom_address_boundary_1+2
    bcc flash_verify1
    bne !+
    lda flash_rom_address_sector+1
    cmp flash_rom_address_boundary_1+1
    bcc flash_verify1
    bne !+
    lda flash_rom_address_sector
    cmp flash_rom_address_boundary_1
    bcc flash_verify1
  !:
    // main::bank_set_bram4
    // BRAM = bank
    // [225] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // [226] phi from main::bank_set_bram4 to main::@51 [phi:main::bank_set_bram4->main::@51]
    // main::@51
    // bank_set_brom(4)
    // [227] call bank_set_brom
    // [891] phi from main::@51 to bank_set_brom [phi:main::@51->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = 4 [phi:main::@51->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [229] phi from main::CLI2 to main::@33 [phi:main::CLI2->main::@33]
    // main::@33
    // textcolor(GREEN)
    // [230] call textcolor
    // [609] phi from main::@33 to textcolor [phi:main::@33->textcolor]
    // [609] phi textcolor::color#22 = GREEN [phi:main::@33->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREEN
    jsr textcolor
    // [231] phi from main::@33 to main::@140 [phi:main::@33->main::@140]
    // main::@140
    // sprintf(buffer, "the flashing went perfectly ok. press a key to flash the next chip ...", file)
    // [232] call snprintf_init
    jsr snprintf_init
    // [233] phi from main::@140 to main::@141 [phi:main::@140->main::@141]
    // main::@141
    // sprintf(buffer, "the flashing went perfectly ok. press a key to flash the next chip ...", file)
    // [234] call printf_str
    // [855] phi from main::@141 to printf_str [phi:main::@141->printf_str]
    // [855] phi printf_str::putc#20 = &snputc [phi:main::@141->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s13 [phi:main::@141->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@142
    // sprintf(buffer, "the flashing went perfectly ok. press a key to flash the next chip ...", file)
    // [235] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [236] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [238] call print_text
    // [868] phi from main::@142 to print_text [phi:main::@142->print_text]
    jsr print_text
    // main::@143
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [239] print_chip_led::r#8 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [240] call print_chip_led
    // [942] phi from main::@143 to print_chip_led [phi:main::@143->print_chip_led]
    // [942] phi print_chip_led::tc#10 = GREEN [phi:main::@143->print_chip_led#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#8 [phi:main::@143->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp __b18
    // [241] phi from main::@23 to main::flash_verify1 [phi:main::@23->main::flash_verify1]
    // main::flash_verify1
  flash_verify1:
    // main::flash_verify1_bank_set_bram1
    // BRAM = bank
    // [242] BRAM = main::read_ram_bank_sector#3 -- vbuz1=vbum2 
    lda read_ram_bank_sector
    sta.z BRAM
    // [243] main::flash_verify1_verify_rom_address#21 = main::flash_rom_address_sector#2 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta flash_verify1_verify_rom_address
    lda flash_rom_address_sector+1
    sta flash_verify1_verify_rom_address+1
    lda flash_rom_address_sector+2
    sta flash_verify1_verify_rom_address+2
    lda flash_rom_address_sector+3
    sta flash_verify1_verify_rom_address+3
    // [244] main::flash_verify1_verify_ram_address#21 = main::read_ram_address_sector#4 -- pbuz1=pbum2 
    lda read_ram_address_sector
    sta.z flash_verify1_verify_ram_address
    lda read_ram_address_sector+1
    sta.z flash_verify1_verify_ram_address+1
    // [245] phi from main::flash_verify1_bank_set_bram1 to main::flash_verify1_@1 [phi:main::flash_verify1_bank_set_bram1->main::flash_verify1_@1]
    // [245] phi main::flash_verify1_correct_bytes#10 = 0 [phi:main::flash_verify1_bank_set_bram1->main::flash_verify1_@1#0] -- vduz1=vduc1 
    lda #<0
    sta.z flash_verify1_correct_bytes
    sta.z flash_verify1_correct_bytes+1
    lda #<0>>$10
    sta.z flash_verify1_correct_bytes+2
    lda #>0>>$10
    sta.z flash_verify1_correct_bytes+3
    // [245] phi main::flash_verify1_verify_ram_address#10 = main::flash_verify1_verify_ram_address#21 [phi:main::flash_verify1_bank_set_bram1->main::flash_verify1_@1#1] -- register_copy 
    // [245] phi main::flash_verify1_verify_rom_address#10 = main::flash_verify1_verify_rom_address#21 [phi:main::flash_verify1_bank_set_bram1->main::flash_verify1_@1#2] -- register_copy 
    // [245] phi main::flash_verify1_verified_bytes#10 = 0 [phi:main::flash_verify1_bank_set_bram1->main::flash_verify1_@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z flash_verify1_verified_bytes
    sta.z flash_verify1_verified_bytes+1
    lda #<0>>$10
    sta.z flash_verify1_verified_bytes+2
    lda #>0>>$10
    sta.z flash_verify1_verified_bytes+3
    // main::flash_verify1_@1
  flash_verify1___b1:
    // while (verified_bytes < verify_rom_size)
    // [246] if(main::flash_verify1_verified_bytes#10<main::flash_verify1_verify_rom_size#0) goto main::flash_verify1_@2 -- vduz1_lt_vduc1_then_la1 
    lda.z flash_verify1_verified_bytes+3
    cmp #>flash_verify1_verify_rom_size>>$10
    bcs !flash_verify1___b2+
    jmp flash_verify1___b2
  !flash_verify1___b2:
    bne !+
    lda.z flash_verify1_verified_bytes+2
    cmp #<flash_verify1_verify_rom_size>>$10
    bcs !flash_verify1___b2+
    jmp flash_verify1___b2
  !flash_verify1___b2:
    bne !+
    lda.z flash_verify1_verified_bytes+1
    cmp #>flash_verify1_verify_rom_size
    bcs !flash_verify1___b2+
    jmp flash_verify1___b2
  !flash_verify1___b2:
    bne !+
    lda.z flash_verify1_verified_bytes
    cmp #<flash_verify1_verify_rom_size
    bcs !flash_verify1___b2+
    jmp flash_verify1___b2
  !flash_verify1___b2:
  !:
    // main::@50
    // if (equal_bytes != ROM_SECTOR)
    // [247] if(main::flash_verify1_correct_bytes#10!=$1000) goto main::rom_sector_erase1 -- vduz1_neq_vduc1_then_la1 
    lda.z flash_verify1_correct_bytes+3
    cmp #>$1000>>$10
    beq !rom_sector_erase1+
    jmp rom_sector_erase1
  !rom_sector_erase1:
    lda.z flash_verify1_correct_bytes+2
    cmp #<$1000>>$10
    beq !rom_sector_erase1+
    jmp rom_sector_erase1
  !rom_sector_erase1:
    lda.z flash_verify1_correct_bytes+1
    cmp #>$1000
    beq !rom_sector_erase1+
    jmp rom_sector_erase1
  !rom_sector_erase1:
    lda.z flash_verify1_correct_bytes
    cmp #<$1000
    beq !rom_sector_erase1+
    jmp rom_sector_erase1
  !rom_sector_erase1:
    // [248] phi from main::@50 to main::@30 [phi:main::@50->main::@30]
    // main::@30
    // textcolor(WHITE)
    // [249] call textcolor
    // [609] phi from main::@30 to textcolor [phi:main::@30->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:main::@30->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@116
    // gotoxy(x_sector, y_sector)
    // [250] gotoxy::x#18 = main::x_sector#26 -- vbuxx=vbum1 
    ldx x_sector
    // [251] gotoxy::y#18 = main::y_sector#25 -- vbuyy=vbum1 
    ldy y_sector
    // [252] call gotoxy
    // [627] phi from main::@116 to gotoxy [phi:main::@116->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#18 [phi:main::@116->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = gotoxy::x#18 [phi:main::@116->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [253] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // printf("%s", pattern)
    // [254] call printf_string
    // [985] phi from main::@117 to printf_string [phi:main::@117->printf_string]
    // [985] phi printf_string::str#10 = main::pattern#1 [phi:main::@117->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern
    sta.z printf_string.str
    lda #>pattern
    sta.z printf_string.str+1
    // [985] phi printf_string::format_justify_left#10 = 0 [phi:main::@117->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [985] phi printf_string::format_min_length#6 = 0 [phi:main::@117->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@24
  __b24:
    // read_ram_address_sector += ROM_SECTOR
    // [255] main::read_ram_address_sector#1 = main::read_ram_address_sector#4 + $1000 -- pbum1=pbum1_plus_vwuc1 
    lda read_ram_address_sector
    clc
    adc #<$1000
    sta read_ram_address_sector
    lda read_ram_address_sector+1
    adc #>$1000
    sta read_ram_address_sector+1
    // flash_rom_address_sector += ROM_SECTOR
    // [256] main::flash_rom_address_sector#1 = main::flash_rom_address_sector#2 + $1000 -- vdum1=vdum1_plus_vwuc1 
    clc
    lda flash_rom_address_sector
    adc #<$1000
    sta flash_rom_address_sector
    lda flash_rom_address_sector+1
    adc #>$1000
    sta flash_rom_address_sector+1
    lda flash_rom_address_sector+2
    adc #0
    sta flash_rom_address_sector+2
    lda flash_rom_address_sector+3
    adc #0
    sta flash_rom_address_sector+3
    // if (read_ram_address_sector == 0x8000)
    // [257] if(main::read_ram_address_sector#1!=$8000) goto main::@144 -- pbum1_neq_vwuc1_then_la1 
    lda read_ram_address_sector+1
    cmp #>$8000
    bne __b28
    lda read_ram_address_sector
    cmp #<$8000
    bne __b28
    // [259] phi from main::@24 to main::@28 [phi:main::@24->main::@28]
    // [259] phi main::read_ram_bank_sector#12 = 1 [phi:main::@24->main::@28#0] -- vbum1=vbuc1 
    lda #1
    sta read_ram_bank_sector
    // [259] phi main::read_ram_address_sector#7 = (char *) 40960 [phi:main::@24->main::@28#1] -- pbum1=pbuc1 
    lda #<$a000
    sta read_ram_address_sector
    lda #>$a000
    sta read_ram_address_sector+1
    // [258] phi from main::@24 to main::@144 [phi:main::@24->main::@144]
    // main::@144
    // [259] phi from main::@144 to main::@28 [phi:main::@144->main::@28]
    // [259] phi main::read_ram_bank_sector#12 = main::read_ram_bank_sector#3 [phi:main::@144->main::@28#0] -- register_copy 
    // [259] phi main::read_ram_address_sector#7 = main::read_ram_address_sector#1 [phi:main::@144->main::@28#1] -- register_copy 
    // main::@28
  __b28:
    // if (read_ram_address_sector == 0xC000)
    // [260] if(main::read_ram_address_sector#7!=$c000) goto main::@29 -- pbum1_neq_vwuc1_then_la1 
    lda read_ram_address_sector+1
    cmp #>$c000
    bne __b29
    lda read_ram_address_sector
    cmp #<$c000
    bne __b29
    // main::@31
    // read_ram_bank_sector++;
    // [261] main::read_ram_bank_sector#2 = ++ main::read_ram_bank_sector#12 -- vbum1=_inc_vbum1 
    inc read_ram_bank_sector
    // [262] phi from main::@31 to main::@29 [phi:main::@31->main::@29]
    // [262] phi main::read_ram_address_sector#13 = (char *) 40960 [phi:main::@31->main::@29#0] -- pbum1=pbuc1 
    lda #<$a000
    sta read_ram_address_sector
    lda #>$a000
    sta read_ram_address_sector+1
    // [262] phi main::read_ram_bank_sector#14 = main::read_ram_bank_sector#2 [phi:main::@31->main::@29#1] -- register_copy 
    // [262] phi from main::@28 to main::@29 [phi:main::@28->main::@29]
    // [262] phi main::read_ram_address_sector#13 = main::read_ram_address_sector#7 [phi:main::@28->main::@29#0] -- register_copy 
    // [262] phi main::read_ram_bank_sector#14 = main::read_ram_bank_sector#12 [phi:main::@28->main::@29#1] -- register_copy 
    // main::@29
  __b29:
    // x_sector += 16
    // [263] main::x_sector#1 = main::x_sector#26 + $10 -- vbum1=vbum1_plus_vbuc1 
    lda #$10
    clc
    adc x_sector
    sta x_sector
    // flash_rom_address_sector % 0x4000
    // [264] main::$139 = main::flash_rom_address_sector#1 & $4000-1 -- vduz1=vdum2_band_vduc1 
    lda flash_rom_address_sector
    and #<$4000-1
    sta.z __139
    lda flash_rom_address_sector+1
    and #>$4000-1
    sta.z __139+1
    lda flash_rom_address_sector+2
    and #<$4000-1>>$10
    sta.z __139+2
    lda flash_rom_address_sector+3
    and #>$4000-1>>$10
    sta.z __139+3
    // if (!(flash_rom_address_sector % 0x4000))
    // [265] if(0!=main::$139) goto main::@23 -- 0_neq_vduz1_then_la1 
    lda.z __139
    ora.z __139+1
    ora.z __139+2
    ora.z __139+3
    beq !__b23+
    jmp __b23
  !__b23:
    // main::@32
    // y_sector++;
    // [266] main::y_sector#1 = ++ main::y_sector#25 -- vbum1=_inc_vbum1 
    inc y_sector
    // [223] phi from main::@32 to main::@23 [phi:main::@32->main::@23]
    // [223] phi main::y_sector#25 = main::y_sector#1 [phi:main::@32->main::@23#0] -- register_copy 
    // [223] phi main::x_sector#26 = $e [phi:main::@32->main::@23#1] -- vbum1=vbuc1 
    lda #$e
    sta x_sector
    // [223] phi main::read_ram_address_sector#4 = main::read_ram_address_sector#13 [phi:main::@32->main::@23#2] -- register_copy 
    // [223] phi main::read_ram_bank_sector#3 = main::read_ram_bank_sector#14 [phi:main::@32->main::@23#3] -- register_copy 
    // [223] phi main::flash_rom_address_sector#2 = main::flash_rom_address_sector#1 [phi:main::@32->main::@23#4] -- register_copy 
    jmp __b23
    // [267] phi from main::@50 to main::rom_sector_erase1 [phi:main::@50->main::rom_sector_erase1]
    // main::rom_sector_erase1
  rom_sector_erase1:
    // main::rom_sector_erase1_rom_ptr1
    // address & ROM_PTR_MASK
    // [268] main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_$0 = main::flash_rom_address_sector#2 & $3fff -- vduz1=vdum2_band_vduc1 
    lda flash_rom_address_sector
    and #<$3fff
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0
    lda flash_rom_address_sector+1
    and #>$3fff
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0+1
    lda flash_rom_address_sector+2
    and #<$3fff>>$10
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0+2
    lda flash_rom_address_sector+3
    and #>$3fff>>$10
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [269] main::rom_sector_erase1_rom_ptr1_$2 = (unsigned int)main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0
    sta.z rom_sector_erase1_rom_ptr1___2
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0+1
    sta.z rom_sector_erase1_rom_ptr1___2+1
    // [270] main::rom_sector_erase1_ptr_rom#0 = main::rom_sector_erase1_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_sector_erase1_ptr_rom
    clc
    adc #<$c000
    sta.z rom_sector_erase1_ptr_rom
    lda.z rom_sector_erase1_ptr_rom+1
    adc #>$c000
    sta.z rom_sector_erase1_ptr_rom+1
    // main::rom_sector_erase1_@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [271] main::rom_sector_erase1_rom_unlock2_chip_address#0 = main::flash_rom_address_sector#2 & $380000 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address_sector
    and #<$380000
    sta rom_sector_erase1_rom_unlock2_chip_address
    lda flash_rom_address_sector+1
    and #>$380000
    sta rom_sector_erase1_rom_unlock2_chip_address+1
    lda flash_rom_address_sector+2
    and #<$380000>>$10
    sta rom_sector_erase1_rom_unlock2_chip_address+2
    lda flash_rom_address_sector+3
    and #>$380000>>$10
    sta rom_sector_erase1_rom_unlock2_chip_address+3
    // rom_chip_address + 0x05555
    // [272] main::rom_sector_erase1_rom_unlock2_rom_write_byte1_address#0 = main::rom_sector_erase1_rom_unlock2_chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda rom_sector_erase1_rom_unlock2_chip_address
    adc #<$5555
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_address
    lda rom_sector_erase1_rom_unlock2_chip_address+1
    adc #>$5555
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_address+1
    lda rom_sector_erase1_rom_unlock2_chip_address+2
    adc #0
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_address+2
    lda rom_sector_erase1_rom_unlock2_chip_address+3
    adc #0
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_address+3
    // main::rom_sector_erase1_rom_unlock1
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [273] main::rom_sector_erase1_rom_unlock1_chip_address#0 = main::rom_sector_erase1_rom_unlock2_rom_write_byte1_address#0 & $380000 -- vdum1=vdum2_band_vduc1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address
    and #<$380000
    sta rom_sector_erase1_rom_unlock1_chip_address
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+1
    and #>$380000
    sta rom_sector_erase1_rom_unlock1_chip_address+1
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+2
    and #<$380000>>$10
    sta rom_sector_erase1_rom_unlock1_chip_address+2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+3
    and #>$380000>>$10
    sta rom_sector_erase1_rom_unlock1_chip_address+3
    // chip_address + 0x05555
    // [274] main::rom_sector_erase1_rom_unlock1_rom_write_byte1_address#0 = main::rom_sector_erase1_rom_unlock1_chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda rom_sector_erase1_rom_unlock1_chip_address
    adc #<$5555
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_address
    lda rom_sector_erase1_rom_unlock1_chip_address+1
    adc #>$5555
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_address+1
    lda rom_sector_erase1_rom_unlock1_chip_address+2
    adc #0
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_address+2
    lda rom_sector_erase1_rom_unlock1_chip_address+3
    adc #0
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_address+3
    // [275] phi from main::rom_sector_erase1_rom_unlock1 to main::rom_sector_erase1_rom_unlock1_rom_write_byte1 [phi:main::rom_sector_erase1_rom_unlock1->main::rom_sector_erase1_rom_unlock1_rom_write_byte1]
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte1
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [276] main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1_$2 = main::rom_sector_erase1_rom_unlock1_rom_write_byte1_address#0 & $3fc000 -- vdum1=vdum2_band_vduc1 
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_address
    and #<$3fc000
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_address+1
    and #>$3fc000
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___2+1
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_address+2
    and #<$3fc000>>$10
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___2+2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_address+3
    and #>$3fc000>>$10
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___2+3
    // [277] main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1_$1 = main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1_$2 >> $e -- vdum1=vdum1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___1+3
    ror rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___1+2
    ror rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___1+1
    ror rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [278] main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1_return#0 = (char)main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___1
    tax
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1
    // address & ROM_PTR_MASK
    // [279] main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_$0 = main::rom_sector_erase1_rom_unlock1_rom_write_byte1_address#0 & $3fff -- vdum1=vdum1_band_vduc1 
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0
    and #<$3fff
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0+1
    and #>$3fff
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0+1
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0+2
    and #<$3fff>>$10
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0+2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0+3
    and #>$3fff>>$10
    sta rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [280] main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_$2 = (unsigned int)main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_$0 -- vwuz1=_word_vdum2 
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0+1
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___2+1
    // [281] main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_return#0 = main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_return
    lda.z rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_return+1
    adc #>$c000
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_return+1
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte1_@2
    // bank_set_brom(bank_rom)
    // [282] bank_set_brom::bank#13 = main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [283] call bank_set_brom
    // [891] phi from main::rom_sector_erase1_rom_unlock1_rom_write_byte1_@2 to bank_set_brom [phi:main::rom_sector_erase1_rom_unlock1_rom_write_byte1_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#13 [phi:main::rom_sector_erase1_rom_unlock1_rom_write_byte1_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@118
    // *ptr_rom = value
    // [284] *((char *)main::rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_return#0) = main::rom_sector_erase1_rom_unlock1_rom_write_byte1_value#0 -- _deref_pbuz1=vbuc1 
    lda #rom_sector_erase1_rom_unlock1_rom_write_byte1_value
    ldy #0
    sta (rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1_return),y
    // main::rom_sector_erase1_rom_unlock1_@1
    // chip_address + 0x02AAA
    // [285] main::rom_sector_erase1_rom_unlock1_rom_write_byte2_address#0 = main::rom_sector_erase1_rom_unlock1_chip_address#0 + $2aaa -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_address
    adc #<$2aaa
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_address
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_address+1
    adc #>$2aaa
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_address+1
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_address+2
    adc #0
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_address+2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_address+3
    adc #0
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_address+3
    // [286] phi from main::rom_sector_erase1_rom_unlock1_@1 to main::rom_sector_erase1_rom_unlock1_rom_write_byte2 [phi:main::rom_sector_erase1_rom_unlock1_@1->main::rom_sector_erase1_rom_unlock1_rom_write_byte2]
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte2
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [287] main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1_$2 = main::rom_sector_erase1_rom_unlock1_rom_write_byte2_address#0 & $3fc000 -- vdum1=vdum2_band_vduc1 
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_address
    and #<$3fc000
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_address+1
    and #>$3fc000
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___2+1
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_address+2
    and #<$3fc000>>$10
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___2+2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_address+3
    and #>$3fc000>>$10
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___2+3
    // [288] main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1_$1 = main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1_$2 >> $e -- vdum1=vdum1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___1+3
    ror rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___1+2
    ror rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___1+1
    ror rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [289] main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1_return#0 = (char)main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___1
    tax
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1
    // address & ROM_PTR_MASK
    // [290] main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_$0 = main::rom_sector_erase1_rom_unlock1_rom_write_byte2_address#0 & $3fff -- vdum1=vdum1_band_vduc1 
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0
    and #<$3fff
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0+1
    and #>$3fff
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0+1
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0+2
    and #<$3fff>>$10
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0+2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0+3
    and #>$3fff>>$10
    sta rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [291] main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_$2 = (unsigned int)main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_$0 -- vwuz1=_word_vdum2 
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___2
    lda rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0+1
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___2+1
    // [292] main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_return#0 = main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_return
    lda.z rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_return+1
    adc #>$c000
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_return+1
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte2_@2
    // bank_set_brom(bank_rom)
    // [293] bank_set_brom::bank#14 = main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [294] call bank_set_brom
    // [891] phi from main::rom_sector_erase1_rom_unlock1_rom_write_byte2_@2 to bank_set_brom [phi:main::rom_sector_erase1_rom_unlock1_rom_write_byte2_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#14 [phi:main::rom_sector_erase1_rom_unlock1_rom_write_byte2_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@119
    // *ptr_rom = value
    // [295] *((char *)main::rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_return#0) = main::rom_sector_erase1_rom_unlock1_rom_write_byte2_value#0 -- _deref_pbuz1=vbuc1 
    lda #rom_sector_erase1_rom_unlock1_rom_write_byte2_value
    ldy #0
    sta (rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1_return),y
    // [296] phi from main::@119 to main::rom_sector_erase1_rom_unlock1_rom_write_byte3 [phi:main::@119->main::rom_sector_erase1_rom_unlock1_rom_write_byte3]
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte3
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [297] main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1_$2 = main::rom_sector_erase1_rom_unlock2_rom_write_byte1_address#0 & $3fc000 -- vdum1=vdum2_band_vduc1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address
    and #<$3fc000
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+1
    and #>$3fc000
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___2+1
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+2
    and #<$3fc000>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___2+2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+3
    and #>$3fc000>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___2+3
    // [298] main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1_$1 = main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1_$2 >> $e -- vdum1=vdum1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___1+3
    ror rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___1+2
    ror rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___1+1
    ror rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [299] main::rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_bank1_return#0 = (char)main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___1
    tax
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1
    // address & ROM_PTR_MASK
    // [300] main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_$0 = main::rom_sector_erase1_rom_unlock2_rom_write_byte1_address#0 & $3fff -- vdum1=vdum2_band_vduc1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address
    and #<$3fff
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+1
    and #>$3fff
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0+1
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+2
    and #<$3fff>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0+2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_address+3
    and #>$3fff>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [301] main::rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_$2 = (unsigned int)main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_$0 -- vwuz1=_word_vdum2 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1___2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0+1
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1___2+1
    // [302] main::rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_return#0 = main::rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_return
    lda.z rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_return+1
    adc #>$c000
    sta.z rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_return+1
    // main::rom_sector_erase1_rom_unlock1_rom_write_byte3_@2
    // bank_set_brom(bank_rom)
    // [303] bank_set_brom::bank#15 = main::rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [304] call bank_set_brom
    // [891] phi from main::rom_sector_erase1_rom_unlock1_rom_write_byte3_@2 to bank_set_brom [phi:main::rom_sector_erase1_rom_unlock1_rom_write_byte3_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#15 [phi:main::rom_sector_erase1_rom_unlock1_rom_write_byte3_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@120
    // *ptr_rom = value
    // [305] *((char *)main::rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_return#0) = main::rom_sector_erase1_rom_unlock1_unlock_code#0 -- _deref_pbuz1=vbuc1 
    lda #rom_sector_erase1_rom_unlock1_unlock_code
    ldy #0
    sta (rom_sector_erase1_rom_unlock1_rom_write_byte3_rom_ptr1_return),y
    // [306] phi from main::@120 to main::rom_sector_erase1_rom_unlock2 [phi:main::@120->main::rom_sector_erase1_rom_unlock2]
    // main::rom_sector_erase1_rom_unlock2
    // [307] phi from main::rom_sector_erase1_rom_unlock2 to main::rom_sector_erase1_rom_unlock2_rom_write_byte1 [phi:main::rom_sector_erase1_rom_unlock2->main::rom_sector_erase1_rom_unlock2_rom_write_byte1]
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte1
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [308] main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1_return#0 = (char)main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___1
    tax
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [309] main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_$2 = (unsigned int)main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_$0 -- vwuz1=_word_vdum2 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0+1
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___2+1
    // [310] main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_return#0 = main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_return
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_return+1
    adc #>$c000
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_return+1
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte1_@2
    // bank_set_brom(bank_rom)
    // [311] bank_set_brom::bank#16 = main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [312] call bank_set_brom
    // [891] phi from main::rom_sector_erase1_rom_unlock2_rom_write_byte1_@2 to bank_set_brom [phi:main::rom_sector_erase1_rom_unlock2_rom_write_byte1_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#16 [phi:main::rom_sector_erase1_rom_unlock2_rom_write_byte1_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@121
    // *ptr_rom = value
    // [313] *((char *)main::rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_return#0) = main::rom_sector_erase1_rom_unlock2_rom_write_byte1_value#0 -- _deref_pbuz1=vbuc1 
    lda #rom_sector_erase1_rom_unlock2_rom_write_byte1_value
    ldy #0
    sta (rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1_return),y
    // main::rom_sector_erase1_rom_unlock2_@1
    // chip_address + 0x02AAA
    // [314] main::rom_sector_erase1_rom_unlock2_rom_write_byte2_address#0 = main::rom_sector_erase1_rom_unlock2_chip_address#0 + $2aaa -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_address
    adc #<$2aaa
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_address
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_address+1
    adc #>$2aaa
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_address+1
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_address+2
    adc #0
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_address+2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_address+3
    adc #0
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_address+3
    // [315] phi from main::rom_sector_erase1_rom_unlock2_@1 to main::rom_sector_erase1_rom_unlock2_rom_write_byte2 [phi:main::rom_sector_erase1_rom_unlock2_@1->main::rom_sector_erase1_rom_unlock2_rom_write_byte2]
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte2
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [316] main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1_$2 = main::rom_sector_erase1_rom_unlock2_rom_write_byte2_address#0 & $3fc000 -- vdum1=vdum2_band_vduc1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_address
    and #<$3fc000
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_address+1
    and #>$3fc000
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___2+1
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_address+2
    and #<$3fc000>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___2+2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_address+3
    and #>$3fc000>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___2+3
    // [317] main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1_$1 = main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1_$2 >> $e -- vdum1=vdum1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___1+3
    ror rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___1+2
    ror rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___1+1
    ror rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [318] main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1_return#0 = (char)main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___1
    tax
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1
    // address & ROM_PTR_MASK
    // [319] main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_$0 = main::rom_sector_erase1_rom_unlock2_rom_write_byte2_address#0 & $3fff -- vdum1=vdum1_band_vduc1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0
    and #<$3fff
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0+1
    and #>$3fff
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0+1
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0+2
    and #<$3fff>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0+2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0+3
    and #>$3fff>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [320] main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_$2 = (unsigned int)main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_$0 -- vwuz1=_word_vdum2 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___2
    lda rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0+1
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___2+1
    // [321] main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_return#0 = main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_return
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_return+1
    adc #>$c000
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_return+1
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte2_@2
    // bank_set_brom(bank_rom)
    // [322] bank_set_brom::bank#17 = main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [323] call bank_set_brom
    // [891] phi from main::rom_sector_erase1_rom_unlock2_rom_write_byte2_@2 to bank_set_brom [phi:main::rom_sector_erase1_rom_unlock2_rom_write_byte2_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#17 [phi:main::rom_sector_erase1_rom_unlock2_rom_write_byte2_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@122
    // *ptr_rom = value
    // [324] *((char *)main::rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_return#0) = main::rom_sector_erase1_rom_unlock2_rom_write_byte2_value#0 -- _deref_pbuz1=vbuc1 
    lda #rom_sector_erase1_rom_unlock2_rom_write_byte2_value
    ldy #0
    sta (rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1_return),y
    // [325] phi from main::@122 to main::rom_sector_erase1_rom_unlock2_rom_write_byte3 [phi:main::@122->main::rom_sector_erase1_rom_unlock2_rom_write_byte3]
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte3
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [326] main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1_$2 = main::flash_rom_address_sector#2 & $3fc000 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address_sector
    and #<$3fc000
    sta rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___2
    lda flash_rom_address_sector+1
    and #>$3fc000
    sta rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___2+1
    lda flash_rom_address_sector+2
    and #<$3fc000>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___2+2
    lda flash_rom_address_sector+3
    and #>$3fc000>>$10
    sta rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___2+3
    // [327] main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1_$1 = main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1_$2 >> $e -- vdum1=vdum1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___1+3
    ror rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___1+2
    ror rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___1+1
    ror rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [328] main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1_return#0 = (char)main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___1
    tax
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [329] main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_$2 = (unsigned int)main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___2
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___0+1
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1___2+1
    // [330] main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_return#0 = main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_return
    lda.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_return+1
    adc #>$c000
    sta.z rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_return+1
    // main::rom_sector_erase1_rom_unlock2_rom_write_byte3_@2
    // bank_set_brom(bank_rom)
    // [331] bank_set_brom::bank#18 = main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [332] call bank_set_brom
    // [891] phi from main::rom_sector_erase1_rom_unlock2_rom_write_byte3_@2 to bank_set_brom [phi:main::rom_sector_erase1_rom_unlock2_rom_write_byte3_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#18 [phi:main::rom_sector_erase1_rom_unlock2_rom_write_byte3_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@123
    // *ptr_rom = value
    // [333] *((char *)main::rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_return#0) = main::rom_sector_erase1_rom_unlock2_unlock_code#0 -- _deref_pbuz1=vbuc1 
    lda #rom_sector_erase1_rom_unlock2_unlock_code
    ldy #0
    sta (rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_ptr1_return),y
    // [334] phi from main::@123 to main::rom_sector_erase1_rom_wait1 [phi:main::@123->main::rom_sector_erase1_rom_wait1]
    // main::rom_sector_erase1_rom_wait1
  rom_sector_erase1_rom_wait1:
    // main::rom_sector_erase1_rom_wait1_@1
    // test1 = *((brom_ptr_t)ptr_rom)
    // [335] main::rom_sector_erase1_rom_wait1_test1#1 = *((char *)main::rom_sector_erase1_ptr_rom#0) -- vbuxx=_deref_pbuz1 
    ldy #0
    lda (rom_sector_erase1_ptr_rom),y
    tax
    // test2 = *((brom_ptr_t)ptr_rom)
    // [336] main::rom_sector_erase1_rom_wait1_test2#1 = *((char *)main::rom_sector_erase1_ptr_rom#0) -- vbuyy=_deref_pbuz1 
    lda (rom_sector_erase1_ptr_rom),y
    tay
    // test1 & 0x40
    // [337] main::rom_sector_erase1_rom_wait1_$0 = main::rom_sector_erase1_rom_wait1_test1#1 & $40 -- vbuz1=vbuxx_band_vbuc1 
    txa
    and #$40
    sta.z rom_sector_erase1_rom_wait1___0
    // test2 & 0x40
    // [338] main::rom_sector_erase1_rom_wait1_$1 = main::rom_sector_erase1_rom_wait1_test2#1 & $40 -- vbuaa=vbuyy_band_vbuc1 
    tya
    and #$40
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [339] if(main::rom_sector_erase1_rom_wait1_$0!=main::rom_sector_erase1_rom_wait1_$1) goto main::rom_sector_erase1_rom_wait1_@1 -- vbuz1_neq_vbuaa_then_la1 
    cmp.z rom_sector_erase1_rom_wait1___0
    bne rom_sector_erase1_rom_wait1
    // main::@52
    // unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR
    // [340] main::flash_rom_address_boundary1#0 = main::flash_rom_address_sector#2 + $1000 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda flash_rom_address_sector
    adc #<$1000
    sta flash_rom_address_boundary1
    lda flash_rom_address_sector+1
    adc #>$1000
    sta flash_rom_address_boundary1+1
    lda flash_rom_address_sector+2
    adc #0
    sta flash_rom_address_boundary1+2
    lda flash_rom_address_sector+3
    adc #0
    sta flash_rom_address_boundary1+3
    // gotoxy(x, y)
    // [341] gotoxy::x#19 = main::x_sector#26 -- vbuxx=vbum1 
    ldx x_sector
    // [342] gotoxy::y#19 = main::y_sector#25 -- vbuyy=vbum1 
    ldy y_sector
    // [343] call gotoxy
    // [627] phi from main::@52 to gotoxy [phi:main::@52->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#19 [phi:main::@52->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = gotoxy::x#19 [phi:main::@52->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [344] phi from main::@52 to main::@124 [phi:main::@52->main::@124]
    // main::@124
    // printf("................")
    // [345] call printf_str
    // [855] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [855] phi printf_str::putc#20 = &cputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s9 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@125
    // [346] main::flash_rom_address1#89 = main::flash_rom_address_sector#2 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta flash_rom_address1
    lda flash_rom_address_sector+1
    sta flash_rom_address1+1
    lda flash_rom_address_sector+2
    sta flash_rom_address1+2
    lda flash_rom_address_sector+3
    sta flash_rom_address1+3
    // [347] main::read_ram_address#89 = main::read_ram_address_sector#4 -- pbum1=pbum2 
    lda read_ram_address_sector
    sta read_ram_address
    lda read_ram_address_sector+1
    sta read_ram_address+1
    // [348] main::x#89 = main::x_sector#26 -- vbuz1=vbum2 
    lda x_sector
    sta.z x
    // [349] phi from main::@125 main::@139 to main::@25 [phi:main::@125/main::@139->main::@25]
    // [349] phi main::x#22 = main::x#89 [phi:main::@125/main::@139->main::@25#0] -- register_copy 
    // [349] phi main::read_ram_address#11 = main::read_ram_address#89 [phi:main::@125/main::@139->main::@25#1] -- register_copy 
    // [349] phi main::flash_rom_address1#14 = main::flash_rom_address1#89 [phi:main::@125/main::@139->main::@25#2] -- register_copy 
    // main::@25
  __b25:
    // while(flash_rom_address < flash_rom_address_boundary)
    // [350] if(main::flash_rom_address1#14<main::flash_rom_address_boundary1#0) goto main::@26 -- vdum1_lt_vdum2_then_la1 
    lda flash_rom_address1+3
    cmp flash_rom_address_boundary1+3
    bcc __b26
    bne !+
    lda flash_rom_address1+2
    cmp flash_rom_address_boundary1+2
    bcc __b26
    bne !+
    lda flash_rom_address1+1
    cmp flash_rom_address_boundary1+1
    bcc __b26
    bne !+
    lda flash_rom_address1
    cmp flash_rom_address_boundary1
    bcc __b26
  !:
    jmp __b24
    // [351] phi from main::@25 to main::@26 [phi:main::@25->main::@26]
    // main::@26
  __b26:
    // gotoxy(50,1)
    // [352] call gotoxy
    // [627] phi from main::@26 to gotoxy [phi:main::@26->gotoxy]
    // [627] phi gotoxy::y#22 = 1 [phi:main::@26->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [627] phi gotoxy::x#22 = $32 [phi:main::@26->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$32
    jsr gotoxy
    // [353] phi from main::@26 to main::@126 [phi:main::@26->main::@126]
    // main::@126
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [354] call printf_str
    // [855] phi from main::@126 to printf_str [phi:main::@126->printf_str]
    // [855] phi printf_str::putc#20 = &cputc [phi:main::@126->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s10 [phi:main::@126->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@127
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [355] printf_uchar::uvalue#3 = main::read_ram_bank_sector#3 -- vbuxx=vbum1 
    ldx read_ram_bank_sector
    // [356] call printf_uchar
    // [894] phi from main::@127 to printf_uchar [phi:main::@127->printf_uchar]
    // [894] phi printf_uchar::format_zero_padding#4 = 0 [phi:main::@127->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [894] phi printf_uchar::format_min_length#4 = 2 [phi:main::@127->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [894] phi printf_uchar::putc#4 = &cputc [phi:main::@127->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [894] phi printf_uchar::format_radix#4 = HEXADECIMAL [phi:main::@127->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [894] phi printf_uchar::uvalue#4 = printf_uchar::uvalue#3 [phi:main::@127->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [357] phi from main::@127 to main::@128 [phi:main::@127->main::@128]
    // main::@128
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [358] call printf_str
    // [855] phi from main::@128 to printf_str [phi:main::@128->printf_str]
    // [855] phi printf_str::putc#20 = &cputc [phi:main::@128->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s11 [phi:main::@128->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@129
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [359] printf_uint::uvalue#0 = (unsigned int)main::read_ram_address#11 -- vwuz1=vwum2 
    lda read_ram_address
    sta.z printf_uint.uvalue
    lda read_ram_address+1
    sta.z printf_uint.uvalue+1
    // [360] call printf_uint
    // [1056] phi from main::@129 to printf_uint [phi:main::@129->printf_uint]
    jsr printf_uint
    // [361] phi from main::@129 to main::@130 [phi:main::@129->main::@130]
    // main::@130
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [362] call printf_str
    // [855] phi from main::@130 to printf_str [phi:main::@130->printf_str]
    // [855] phi printf_str::putc#20 = &cputc [phi:main::@130->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s12 [phi:main::@130->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@131
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [363] printf_ulong::uvalue#1 = main::flash_rom_address1#14 -- vduz1=vdum2 
    lda flash_rom_address1
    sta.z printf_ulong.uvalue
    lda flash_rom_address1+1
    sta.z printf_ulong.uvalue+1
    lda flash_rom_address1+2
    sta.z printf_ulong.uvalue+2
    lda flash_rom_address1+3
    sta.z printf_ulong.uvalue+3
    // [364] call printf_ulong
    // [1063] phi from main::@131 to printf_ulong [phi:main::@131->printf_ulong]
    // [1063] phi printf_ulong::format_zero_padding#2 = 0 [phi:main::@131->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1063] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:main::@131->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // main::flash_write1
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [365] main::flash_write1_rom_chip_address#0 = main::flash_rom_address1#14 & $380000 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address1
    and #<$380000
    sta flash_write1_rom_chip_address
    lda flash_rom_address1+1
    and #>$380000
    sta flash_write1_rom_chip_address+1
    lda flash_rom_address1+2
    and #<$380000>>$10
    sta flash_write1_rom_chip_address+2
    lda flash_rom_address1+3
    and #>$380000>>$10
    sta flash_write1_rom_chip_address+3
    // main::flash_write1_bank_set_bram1
    // BRAM = bank
    // [366] BRAM = main::read_ram_bank_sector#3 -- vbuz1=vbum2 
    lda read_ram_bank_sector
    sta.z BRAM
    // [367] main::flash_write1_flash_rom_address#51 = main::flash_rom_address1#14 -- vduz1=vdum2 
    lda flash_rom_address1
    sta.z flash_write1_flash_rom_address
    lda flash_rom_address1+1
    sta.z flash_write1_flash_rom_address+1
    lda flash_rom_address1+2
    sta.z flash_write1_flash_rom_address+2
    lda flash_rom_address1+3
    sta.z flash_write1_flash_rom_address+3
    // [368] main::flash_write1_flash_ram_address#51 = main::read_ram_address#11 -- pbuz1=pbum2 
    lda read_ram_address
    sta.z flash_write1_flash_ram_address
    lda read_ram_address+1
    sta.z flash_write1_flash_ram_address+1
    // [369] phi from main::flash_write1_bank_set_bram1 to main::flash_write1_@1 [phi:main::flash_write1_bank_set_bram1->main::flash_write1_@1]
    // [369] phi main::flash_write1_flash_ram_address#10 = main::flash_write1_flash_ram_address#51 [phi:main::flash_write1_bank_set_bram1->main::flash_write1_@1#0] -- register_copy 
    // [369] phi main::flash_write1_flash_rom_address#10 = main::flash_write1_flash_rom_address#51 [phi:main::flash_write1_bank_set_bram1->main::flash_write1_@1#1] -- register_copy 
    // [369] phi main::flash_write1_flashed_bytes#10 = 0 [phi:main::flash_write1_bank_set_bram1->main::flash_write1_@1#2] -- vduz1=vduc1 
    lda #<0
    sta.z flash_write1_flashed_bytes
    sta.z flash_write1_flashed_bytes+1
    lda #<0>>$10
    sta.z flash_write1_flashed_bytes+2
    lda #>0>>$10
    sta.z flash_write1_flashed_bytes+3
    // main::flash_write1_@1
  flash_write1___b1:
    // while (flashed_bytes < 0x0100)
    // [370] if(main::flash_write1_flashed_bytes#10<$100) goto main::flash_write1_@2 -- vduz1_lt_vduc1_then_la1 
    lda.z flash_write1_flashed_bytes+3
    cmp #>$100>>$10
    bcs !flash_write1___b2+
    jmp flash_write1___b2
  !flash_write1___b2:
    bne !+
    lda.z flash_write1_flashed_bytes+2
    cmp #<$100>>$10
    bcs !flash_write1___b2+
    jmp flash_write1___b2
  !flash_write1___b2:
    bne !+
    lda.z flash_write1_flashed_bytes+1
    cmp #>$100
    bcs !flash_write1___b2+
    jmp flash_write1___b2
  !flash_write1___b2:
    bne !+
    lda.z flash_write1_flashed_bytes
    cmp #<$100
    bcs !flash_write1___b2+
    jmp flash_write1___b2
  !flash_write1___b2:
  !:
    // [371] phi from main::flash_write1_@1 to main::flash_verify2 [phi:main::flash_write1_@1->main::flash_verify2]
    // main::flash_verify2
    // main::flash_verify2_bank_set_bram1
    // BRAM = bank
    // [372] BRAM = main::read_ram_bank_sector#3 -- vbuz1=vbum2 
    lda read_ram_bank_sector
    sta.z BRAM
    // [373] main::flash_verify2_verify_rom_address#21 = main::flash_rom_address1#14 -- vduz1=vdum2 
    lda flash_rom_address1
    sta.z flash_verify2_verify_rom_address
    lda flash_rom_address1+1
    sta.z flash_verify2_verify_rom_address+1
    lda flash_rom_address1+2
    sta.z flash_verify2_verify_rom_address+2
    lda flash_rom_address1+3
    sta.z flash_verify2_verify_rom_address+3
    // [374] main::flash_verify2_verify_ram_address#21 = main::read_ram_address#11 -- pbuz1=pbum2 
    lda read_ram_address
    sta.z flash_verify2_verify_ram_address
    lda read_ram_address+1
    sta.z flash_verify2_verify_ram_address+1
    // [375] phi from main::flash_verify2_bank_set_bram1 to main::flash_verify2_@1 [phi:main::flash_verify2_bank_set_bram1->main::flash_verify2_@1]
    // [375] phi main::flash_verify2_correct_bytes#10 = 0 [phi:main::flash_verify2_bank_set_bram1->main::flash_verify2_@1#0] -- vduz1=vduc1 
    lda #<0
    sta.z flash_verify2_correct_bytes
    sta.z flash_verify2_correct_bytes+1
    lda #<0>>$10
    sta.z flash_verify2_correct_bytes+2
    lda #>0>>$10
    sta.z flash_verify2_correct_bytes+3
    // [375] phi main::flash_verify2_verify_ram_address#10 = main::flash_verify2_verify_ram_address#21 [phi:main::flash_verify2_bank_set_bram1->main::flash_verify2_@1#1] -- register_copy 
    // [375] phi main::flash_verify2_verify_rom_address#10 = main::flash_verify2_verify_rom_address#21 [phi:main::flash_verify2_bank_set_bram1->main::flash_verify2_@1#2] -- register_copy 
    // [375] phi main::flash_verify2_verified_bytes#10 = 0 [phi:main::flash_verify2_bank_set_bram1->main::flash_verify2_@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z flash_verify2_verified_bytes
    sta.z flash_verify2_verified_bytes+1
    lda #<0>>$10
    sta.z flash_verify2_verified_bytes+2
    lda #>0>>$10
    sta.z flash_verify2_verified_bytes+3
    // main::flash_verify2_@1
  flash_verify2___b1:
    // while (verified_bytes < verify_rom_size)
    // [376] if(main::flash_verify2_verified_bytes#10<main::flash_verify2_verify_rom_size#0) goto main::flash_verify2_@2 -- vduz1_lt_vduc1_then_la1 
    lda.z flash_verify2_verified_bytes+3
    cmp #>flash_verify2_verify_rom_size>>$10
    bcc flash_verify2___b2
    bne !+
    lda.z flash_verify2_verified_bytes+2
    cmp #<flash_verify2_verify_rom_size>>$10
    bcc flash_verify2___b2
    bne !+
    lda.z flash_verify2_verified_bytes+1
    cmp #>flash_verify2_verify_rom_size
    bcc flash_verify2___b2
    bne !+
    lda.z flash_verify2_verified_bytes
    cmp #<flash_verify2_verify_rom_size
    bcc flash_verify2___b2
  !:
    // main::@27
    // read_ram_address += 0x0100
    // [377] main::read_ram_address#1 = main::read_ram_address#11 + $100 -- pbum1=pbum1_plus_vwuc1 
    lda read_ram_address
    clc
    adc #<$100
    sta read_ram_address
    lda read_ram_address+1
    adc #>$100
    sta read_ram_address+1
    // flash_rom_address += 0x0100
    // [378] main::flash_rom_address1#1 = main::flash_rom_address1#14 + $100 -- vdum1=vdum1_plus_vwuc1 
    clc
    lda flash_rom_address1
    adc #<$100
    sta flash_rom_address1
    lda flash_rom_address1+1
    adc #>$100
    sta flash_rom_address1+1
    lda flash_rom_address1+2
    adc #0
    sta flash_rom_address1+2
    lda flash_rom_address1+3
    adc #0
    sta flash_rom_address1+3
    // textcolor(WHITE)
    // [379] call textcolor
    // [609] phi from main::@27 to textcolor [phi:main::@27->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:main::@27->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@137
    // gotoxy(x, y)
    // [380] gotoxy::x#21 = main::x#22 -- vbuxx=vbuz1 
    ldx.z x
    // [381] gotoxy::y#21 = main::y_sector#25 -- vbuyy=vbum1 
    ldy y_sector
    // [382] call gotoxy
    // [627] phi from main::@137 to gotoxy [phi:main::@137->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#21 [phi:main::@137->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = gotoxy::x#21 [phi:main::@137->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [383] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // printf("%s", pattern)
    // [384] call printf_string
    // [985] phi from main::@138 to printf_string [phi:main::@138->printf_string]
    // [985] phi printf_string::str#10 = main::pattern#3 [phi:main::@138->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern_1
    sta.z printf_string.str
    lda #>pattern_1
    sta.z printf_string.str+1
    // [985] phi printf_string::format_justify_left#10 = 0 [phi:main::@138->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [985] phi printf_string::format_min_length#6 = 0 [phi:main::@138->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@139
    // x++;
    // [385] main::x#1 = ++ main::x#22 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b25
    // main::flash_verify2_@2
  flash_verify2___b2:
    // rom_byte_verify(verify_rom_address, *verify_ram_address)
    // [386] main::flash_verify2_rom_byte_verify1_value#0 = *main::flash_verify2_verify_ram_address#10 -- vbuyy=_deref_pbuz1 
    ldy #0
    lda (flash_verify2_verify_ram_address),y
    tay
    // [387] phi from main::flash_verify2_@2 to main::flash_verify2_rom_byte_verify1 [phi:main::flash_verify2_@2->main::flash_verify2_rom_byte_verify1]
    // main::flash_verify2_rom_byte_verify1
    // main::flash_verify2_rom_byte_verify1_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [388] main::flash_verify2_rom_byte_verify1_rom_bank1_$2 = main::flash_verify2_verify_rom_address#10 & $3fc000 -- vduz1=vduz2_band_vduc1 
    lda.z flash_verify2_verify_rom_address
    and #<$3fc000
    sta.z flash_verify2_rom_byte_verify1_rom_bank1___2
    lda.z flash_verify2_verify_rom_address+1
    and #>$3fc000
    sta.z flash_verify2_rom_byte_verify1_rom_bank1___2+1
    lda.z flash_verify2_verify_rom_address+2
    and #<$3fc000>>$10
    sta.z flash_verify2_rom_byte_verify1_rom_bank1___2+2
    lda.z flash_verify2_verify_rom_address+3
    and #>$3fc000>>$10
    sta.z flash_verify2_rom_byte_verify1_rom_bank1___2+3
    // [389] main::flash_verify2_rom_byte_verify1_rom_bank1_$1 = main::flash_verify2_rom_byte_verify1_rom_bank1_$2 >> $e -- vduz1=vduz2_ror_vbuc1 
    ldx #$e
    lda.z flash_verify2_rom_byte_verify1_rom_bank1___2
    sta.z flash_verify2_rom_byte_verify1_rom_bank1___1
    lda.z flash_verify2_rom_byte_verify1_rom_bank1___2+1
    sta.z flash_verify2_rom_byte_verify1_rom_bank1___1+1
    lda.z flash_verify2_rom_byte_verify1_rom_bank1___2+2
    sta.z flash_verify2_rom_byte_verify1_rom_bank1___1+2
    lda.z flash_verify2_rom_byte_verify1_rom_bank1___2+3
    sta.z flash_verify2_rom_byte_verify1_rom_bank1___1+3
    cpx #0
    beq !e+
  !:
    lsr.z flash_verify2_rom_byte_verify1_rom_bank1___1+3
    ror.z flash_verify2_rom_byte_verify1_rom_bank1___1+2
    ror.z flash_verify2_rom_byte_verify1_rom_bank1___1+1
    ror.z flash_verify2_rom_byte_verify1_rom_bank1___1
    dex
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [390] main::flash_verify2_rom_byte_verify1_rom_bank1_return#0 = (char)main::flash_verify2_rom_byte_verify1_rom_bank1_$1 -- vbuxx=_byte_vduz1 
    lda.z flash_verify2_rom_byte_verify1_rom_bank1___1
    tax
    // main::flash_verify2_rom_byte_verify1_rom_ptr1
    // address & ROM_PTR_MASK
    // [391] main::flash_verify2_rom_byte_verify1_rom_ptr1_$0 = main::flash_verify2_verify_rom_address#10 & $3fff -- vduz1=vduz2_band_vduc1 
    lda.z flash_verify2_verify_rom_address
    and #<$3fff
    sta.z flash_verify2_rom_byte_verify1_rom_ptr1___0
    lda.z flash_verify2_verify_rom_address+1
    and #>$3fff
    sta.z flash_verify2_rom_byte_verify1_rom_ptr1___0+1
    lda.z flash_verify2_verify_rom_address+2
    and #<$3fff>>$10
    sta.z flash_verify2_rom_byte_verify1_rom_ptr1___0+2
    lda.z flash_verify2_verify_rom_address+3
    and #>$3fff>>$10
    sta.z flash_verify2_rom_byte_verify1_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [392] main::flash_verify2_rom_byte_verify1_rom_ptr1_$2 = (unsigned int)main::flash_verify2_rom_byte_verify1_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z flash_verify2_rom_byte_verify1_rom_ptr1___0
    sta.z flash_verify2_rom_byte_verify1_rom_ptr1___2
    lda.z flash_verify2_rom_byte_verify1_rom_ptr1___0+1
    sta.z flash_verify2_rom_byte_verify1_rom_ptr1___2+1
    // [393] main::flash_verify2_rom_byte_verify1_rom_ptr1_return#0 = main::flash_verify2_rom_byte_verify1_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z flash_verify2_rom_byte_verify1_rom_ptr1_return
    clc
    adc #<$c000
    sta.z flash_verify2_rom_byte_verify1_rom_ptr1_return
    lda.z flash_verify2_rom_byte_verify1_rom_ptr1_return+1
    adc #>$c000
    sta.z flash_verify2_rom_byte_verify1_rom_ptr1_return+1
    // main::flash_verify2_rom_byte_verify1_@5
    // bank_set_brom(bank_rom)
    // [394] bank_set_brom::bank#23 = main::flash_verify2_rom_byte_verify1_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [395] call bank_set_brom
    // [891] phi from main::flash_verify2_rom_byte_verify1_@5 to bank_set_brom [phi:main::flash_verify2_rom_byte_verify1_@5->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#23 [phi:main::flash_verify2_rom_byte_verify1_@5->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@136
    // if (*ptr_rom != value)
    // [396] if(*((char *)main::flash_verify2_rom_byte_verify1_rom_ptr1_return#0)==main::flash_verify2_rom_byte_verify1_value#0) goto main::flash_verify2_rom_byte_verify1_@1 -- _deref_pbuz1_eq_vbuyy_then_la1 
    tya
    ldy #0
    cmp (flash_verify2_rom_byte_verify1_rom_ptr1_return),y
    beq __b11
    // [397] phi from main::@136 to main::flash_verify2_rom_byte_verify1_@2 [phi:main::@136->main::flash_verify2_rom_byte_verify1_@2]
    // main::flash_verify2_rom_byte_verify1_@2
    // [398] phi from main::flash_verify2_rom_byte_verify1_@2 to main::flash_verify2_rom_byte_verify1_@1 [phi:main::flash_verify2_rom_byte_verify1_@2->main::flash_verify2_rom_byte_verify1_@1]
    // [398] phi main::flash_verify2_rom_byte_verify1_return#0 = 0 [phi:main::flash_verify2_rom_byte_verify1_@2->main::flash_verify2_rom_byte_verify1_@1#0] -- vbuaa=vbuc1 
    tya
    jmp flash_verify2___b11
    // [398] phi from main::@136 to main::flash_verify2_rom_byte_verify1_@1 [phi:main::@136->main::flash_verify2_rom_byte_verify1_@1]
  __b11:
    // [398] phi main::flash_verify2_rom_byte_verify1_return#0 = 1 [phi:main::@136->main::flash_verify2_rom_byte_verify1_@1#0] -- vbuaa=vbuc1 
    lda #1
    // main::flash_verify2_rom_byte_verify1_@1
    // main::flash_verify2_@11
  flash_verify2___b11:
    // if (rom_byte_verify(verify_rom_address, *verify_ram_address))
    // [399] if(0==main::flash_verify2_rom_byte_verify1_return#0) goto main::flash_verify2_@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq flash_verify2___b4
    // main::flash_verify2_@7
    // correct_bytes++;
    // [400] main::flash_verify2_correct_bytes#1 = ++ main::flash_verify2_correct_bytes#10 -- vduz1=_inc_vduz1 
    inc.z flash_verify2_correct_bytes
    bne !+
    inc.z flash_verify2_correct_bytes+1
    bne !+
    inc.z flash_verify2_correct_bytes+2
    bne !+
    inc.z flash_verify2_correct_bytes+3
  !:
    // [401] phi from main::flash_verify2_@11 main::flash_verify2_@7 to main::flash_verify2_@4 [phi:main::flash_verify2_@11/main::flash_verify2_@7->main::flash_verify2_@4]
    // [401] phi main::flash_verify2_correct_bytes#6 = main::flash_verify2_correct_bytes#10 [phi:main::flash_verify2_@11/main::flash_verify2_@7->main::flash_verify2_@4#0] -- register_copy 
    // main::flash_verify2_@4
  flash_verify2___b4:
    // verify_rom_address++;
    // [402] main::flash_verify2_verify_rom_address#1 = ++ main::flash_verify2_verify_rom_address#10 -- vduz1=_inc_vduz1 
    inc.z flash_verify2_verify_rom_address
    bne !+
    inc.z flash_verify2_verify_rom_address+1
    bne !+
    inc.z flash_verify2_verify_rom_address+2
    bne !+
    inc.z flash_verify2_verify_rom_address+3
  !:
    // verify_ram_address++;
    // [403] main::flash_verify2_verify_ram_address#1 = ++ main::flash_verify2_verify_ram_address#10 -- pbuz1=_inc_pbuz1 
    inc.z flash_verify2_verify_ram_address
    bne !+
    inc.z flash_verify2_verify_ram_address+1
  !:
    // verified_bytes++;
    // [404] main::flash_verify2_verified_bytes#1 = ++ main::flash_verify2_verified_bytes#10 -- vduz1=_inc_vduz1 
    inc.z flash_verify2_verified_bytes
    bne !+
    inc.z flash_verify2_verified_bytes+1
    bne !+
    inc.z flash_verify2_verified_bytes+2
    bne !+
    inc.z flash_verify2_verified_bytes+3
  !:
    // [375] phi from main::flash_verify2_@4 to main::flash_verify2_@1 [phi:main::flash_verify2_@4->main::flash_verify2_@1]
    // [375] phi main::flash_verify2_correct_bytes#10 = main::flash_verify2_correct_bytes#6 [phi:main::flash_verify2_@4->main::flash_verify2_@1#0] -- register_copy 
    // [375] phi main::flash_verify2_verify_ram_address#10 = main::flash_verify2_verify_ram_address#1 [phi:main::flash_verify2_@4->main::flash_verify2_@1#1] -- register_copy 
    // [375] phi main::flash_verify2_verify_rom_address#10 = main::flash_verify2_verify_rom_address#1 [phi:main::flash_verify2_@4->main::flash_verify2_@1#2] -- register_copy 
    // [375] phi main::flash_verify2_verified_bytes#10 = main::flash_verify2_verified_bytes#1 [phi:main::flash_verify2_@4->main::flash_verify2_@1#3] -- register_copy 
    jmp flash_verify2___b1
    // main::flash_write1_@2
  flash_write1___b2:
    // rom_chip_address + 0x05555
    // [405] main::flash_write1_rom_unlock1_address#0 = main::flash_write1_rom_chip_address#0 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda flash_write1_rom_chip_address
    adc #<$5555
    sta.z flash_write1_rom_unlock1_address
    lda flash_write1_rom_chip_address+1
    adc #>$5555
    sta.z flash_write1_rom_unlock1_address+1
    lda flash_write1_rom_chip_address+2
    adc #0
    sta.z flash_write1_rom_unlock1_address+2
    lda flash_write1_rom_chip_address+3
    adc #0
    sta.z flash_write1_rom_unlock1_address+3
    // main::flash_write1_rom_unlock1
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [406] main::flash_write1_rom_unlock1_chip_address#0 = main::flash_write1_rom_unlock1_address#0 & $380000 -- vduz1=vduz2_band_vduc1 
    lda.z flash_write1_rom_unlock1_address
    and #<$380000
    sta.z flash_write1_rom_unlock1_chip_address
    lda.z flash_write1_rom_unlock1_address+1
    and #>$380000
    sta.z flash_write1_rom_unlock1_chip_address+1
    lda.z flash_write1_rom_unlock1_address+2
    and #<$380000>>$10
    sta.z flash_write1_rom_unlock1_chip_address+2
    lda.z flash_write1_rom_unlock1_address+3
    and #>$380000>>$10
    sta.z flash_write1_rom_unlock1_chip_address+3
    // chip_address + 0x05555
    // [407] main::flash_write1_rom_unlock1_rom_write_byte1_address#0 = main::flash_write1_rom_unlock1_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z flash_write1_rom_unlock1_chip_address
    adc #<$5555
    sta.z flash_write1_rom_unlock1_rom_write_byte1_address
    lda.z flash_write1_rom_unlock1_chip_address+1
    adc #>$5555
    sta.z flash_write1_rom_unlock1_rom_write_byte1_address+1
    lda.z flash_write1_rom_unlock1_chip_address+2
    adc #0
    sta.z flash_write1_rom_unlock1_rom_write_byte1_address+2
    lda.z flash_write1_rom_unlock1_chip_address+3
    adc #0
    sta.z flash_write1_rom_unlock1_rom_write_byte1_address+3
    // [408] phi from main::flash_write1_rom_unlock1 to main::flash_write1_rom_unlock1_rom_write_byte1 [phi:main::flash_write1_rom_unlock1->main::flash_write1_rom_unlock1_rom_write_byte1]
    // main::flash_write1_rom_unlock1_rom_write_byte1
    // main::flash_write1_rom_unlock1_rom_write_byte1_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [409] main::flash_write1_rom_unlock1_rom_write_byte1_rom_bank1_$2 = main::flash_write1_rom_unlock1_rom_write_byte1_address#0 & $3fc000 -- vduz1=vduz2_band_vduc1 
    lda.z flash_write1_rom_unlock1_rom_write_byte1_address
    and #<$3fc000
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___2
    lda.z flash_write1_rom_unlock1_rom_write_byte1_address+1
    and #>$3fc000
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___2+1
    lda.z flash_write1_rom_unlock1_rom_write_byte1_address+2
    and #<$3fc000>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___2+2
    lda.z flash_write1_rom_unlock1_rom_write_byte1_address+3
    and #>$3fc000>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___2+3
    // [410] main::flash_write1_rom_unlock1_rom_write_byte1_rom_bank1_$1 = main::flash_write1_rom_unlock1_rom_write_byte1_rom_bank1_$2 >> $e -- vduz1=vduz1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___1+3
    ror.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___1+2
    ror.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___1+1
    ror.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [411] main::flash_write1_rom_unlock1_rom_write_byte1_rom_bank1_return#0 = (char)main::flash_write1_rom_unlock1_rom_write_byte1_rom_bank1_$1 -- vbuxx=_byte_vduz1 
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_bank1___1
    tax
    // main::flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1
    // address & ROM_PTR_MASK
    // [412] main::flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_$0 = main::flash_write1_rom_unlock1_rom_write_byte1_address#0 & $3fff -- vduz1=vduz1_band_vduc1 
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0
    and #<$3fff
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0+1
    and #>$3fff
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0+1
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0+2
    and #<$3fff>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0+2
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0+3
    and #>$3fff>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [413] main::flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_$2 = (unsigned int)main::flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___2
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___0+1
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1___2+1
    // [414] main::flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_return#0 = main::flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_return
    clc
    adc #<$c000
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_return
    lda.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_return+1
    adc #>$c000
    sta.z flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_return+1
    // main::flash_write1_rom_unlock1_rom_write_byte1_@2
    // bank_set_brom(bank_rom)
    // [415] bank_set_brom::bank#19 = main::flash_write1_rom_unlock1_rom_write_byte1_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [416] call bank_set_brom
    // [891] phi from main::flash_write1_rom_unlock1_rom_write_byte1_@2 to bank_set_brom [phi:main::flash_write1_rom_unlock1_rom_write_byte1_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#19 [phi:main::flash_write1_rom_unlock1_rom_write_byte1_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@132
    // *ptr_rom = value
    // [417] *((char *)main::flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_return#0) = main::flash_write1_rom_unlock1_rom_write_byte1_value#0 -- _deref_pbuz1=vbuc1 
    lda #flash_write1_rom_unlock1_rom_write_byte1_value
    ldy #0
    sta (flash_write1_rom_unlock1_rom_write_byte1_rom_ptr1_return),y
    // main::flash_write1_rom_unlock1_@1
    // chip_address + 0x02AAA
    // [418] main::flash_write1_rom_unlock1_rom_write_byte2_address#0 = main::flash_write1_rom_unlock1_chip_address#0 + $2aaa -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z flash_write1_rom_unlock1_rom_write_byte2_address
    adc #<$2aaa
    sta.z flash_write1_rom_unlock1_rom_write_byte2_address
    lda.z flash_write1_rom_unlock1_rom_write_byte2_address+1
    adc #>$2aaa
    sta.z flash_write1_rom_unlock1_rom_write_byte2_address+1
    lda.z flash_write1_rom_unlock1_rom_write_byte2_address+2
    adc #0
    sta.z flash_write1_rom_unlock1_rom_write_byte2_address+2
    lda.z flash_write1_rom_unlock1_rom_write_byte2_address+3
    adc #0
    sta.z flash_write1_rom_unlock1_rom_write_byte2_address+3
    // [419] phi from main::flash_write1_rom_unlock1_@1 to main::flash_write1_rom_unlock1_rom_write_byte2 [phi:main::flash_write1_rom_unlock1_@1->main::flash_write1_rom_unlock1_rom_write_byte2]
    // main::flash_write1_rom_unlock1_rom_write_byte2
    // main::flash_write1_rom_unlock1_rom_write_byte2_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [420] main::flash_write1_rom_unlock1_rom_write_byte2_rom_bank1_$2 = main::flash_write1_rom_unlock1_rom_write_byte2_address#0 & $3fc000 -- vduz1=vduz2_band_vduc1 
    lda.z flash_write1_rom_unlock1_rom_write_byte2_address
    and #<$3fc000
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___2
    lda.z flash_write1_rom_unlock1_rom_write_byte2_address+1
    and #>$3fc000
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___2+1
    lda.z flash_write1_rom_unlock1_rom_write_byte2_address+2
    and #<$3fc000>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___2+2
    lda.z flash_write1_rom_unlock1_rom_write_byte2_address+3
    and #>$3fc000>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___2+3
    // [421] main::flash_write1_rom_unlock1_rom_write_byte2_rom_bank1_$1 = main::flash_write1_rom_unlock1_rom_write_byte2_rom_bank1_$2 >> $e -- vduz1=vduz1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___1+3
    ror.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___1+2
    ror.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___1+1
    ror.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [422] main::flash_write1_rom_unlock1_rom_write_byte2_rom_bank1_return#0 = (char)main::flash_write1_rom_unlock1_rom_write_byte2_rom_bank1_$1 -- vbuxx=_byte_vduz1 
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_bank1___1
    tax
    // main::flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1
    // address & ROM_PTR_MASK
    // [423] main::flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_$0 = main::flash_write1_rom_unlock1_rom_write_byte2_address#0 & $3fff -- vduz1=vduz1_band_vduc1 
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0
    and #<$3fff
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0+1
    and #>$3fff
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0+1
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0+2
    and #<$3fff>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0+2
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0+3
    and #>$3fff>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [424] main::flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_$2 = (unsigned int)main::flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___2
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___0+1
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1___2+1
    // [425] main::flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_return#0 = main::flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_return
    clc
    adc #<$c000
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_return
    lda.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_return+1
    adc #>$c000
    sta.z flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_return+1
    // main::flash_write1_rom_unlock1_rom_write_byte2_@2
    // bank_set_brom(bank_rom)
    // [426] bank_set_brom::bank#20 = main::flash_write1_rom_unlock1_rom_write_byte2_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [427] call bank_set_brom
    // [891] phi from main::flash_write1_rom_unlock1_rom_write_byte2_@2 to bank_set_brom [phi:main::flash_write1_rom_unlock1_rom_write_byte2_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#20 [phi:main::flash_write1_rom_unlock1_rom_write_byte2_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@133
    // *ptr_rom = value
    // [428] *((char *)main::flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_return#0) = main::flash_write1_rom_unlock1_rom_write_byte2_value#0 -- _deref_pbuz1=vbuc1 
    lda #flash_write1_rom_unlock1_rom_write_byte2_value
    ldy #0
    sta (flash_write1_rom_unlock1_rom_write_byte2_rom_ptr1_return),y
    // [429] phi from main::@133 to main::flash_write1_rom_unlock1_rom_write_byte3 [phi:main::@133->main::flash_write1_rom_unlock1_rom_write_byte3]
    // main::flash_write1_rom_unlock1_rom_write_byte3
    // main::flash_write1_rom_unlock1_rom_write_byte3_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [430] main::flash_write1_rom_unlock1_rom_write_byte3_rom_bank1_$2 = main::flash_write1_rom_unlock1_address#0 & $3fc000 -- vduz1=vduz2_band_vduc1 
    lda.z flash_write1_rom_unlock1_address
    and #<$3fc000
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___2
    lda.z flash_write1_rom_unlock1_address+1
    and #>$3fc000
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___2+1
    lda.z flash_write1_rom_unlock1_address+2
    and #<$3fc000>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___2+2
    lda.z flash_write1_rom_unlock1_address+3
    and #>$3fc000>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___2+3
    // [431] main::flash_write1_rom_unlock1_rom_write_byte3_rom_bank1_$1 = main::flash_write1_rom_unlock1_rom_write_byte3_rom_bank1_$2 >> $e -- vduz1=vduz1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___1+3
    ror.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___1+2
    ror.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___1+1
    ror.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [432] main::flash_write1_rom_unlock1_rom_write_byte3_rom_bank1_return#0 = (char)main::flash_write1_rom_unlock1_rom_write_byte3_rom_bank1_$1 -- vbuxx=_byte_vduz1 
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_bank1___1
    tax
    // main::flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1
    // address & ROM_PTR_MASK
    // [433] main::flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_$0 = main::flash_write1_rom_unlock1_address#0 & $3fff -- vduz1=vduz1_band_vduc1 
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0
    and #<$3fff
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0+1
    and #>$3fff
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0+1
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0+2
    and #<$3fff>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0+2
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0+3
    and #>$3fff>>$10
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [434] main::flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_$2 = (unsigned int)main::flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___2
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___0+1
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1___2+1
    // [435] main::flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_return#0 = main::flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_return
    clc
    adc #<$c000
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_return
    lda.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_return+1
    adc #>$c000
    sta.z flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_return+1
    // main::flash_write1_rom_unlock1_rom_write_byte3_@2
    // bank_set_brom(bank_rom)
    // [436] bank_set_brom::bank#21 = main::flash_write1_rom_unlock1_rom_write_byte3_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [437] call bank_set_brom
    // [891] phi from main::flash_write1_rom_unlock1_rom_write_byte3_@2 to bank_set_brom [phi:main::flash_write1_rom_unlock1_rom_write_byte3_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#21 [phi:main::flash_write1_rom_unlock1_rom_write_byte3_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@134
    // *ptr_rom = value
    // [438] *((char *)main::flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_return#0) = main::flash_write1_rom_unlock1_unlock_code#0 -- _deref_pbuz1=vbuc1 
    lda #flash_write1_rom_unlock1_unlock_code
    ldy #0
    sta (flash_write1_rom_unlock1_rom_write_byte3_rom_ptr1_return),y
    // main::flash_write1_@9
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [439] main::flash_write1_rom_byte_program1_rom_write_byte1_value#0 = *main::flash_write1_flash_ram_address#10 -- vbuz1=_deref_pbuz2 
    lda (flash_write1_flash_ram_address),y
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_value
    // [440] phi from main::flash_write1_@9 to main::flash_write1_rom_byte_program1 [phi:main::flash_write1_@9->main::flash_write1_rom_byte_program1]
    // main::flash_write1_rom_byte_program1
    // main::flash_write1_rom_byte_program1_rom_ptr1
    // address & ROM_PTR_MASK
    // [441] main::flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_$0 = main::flash_write1_flash_rom_address#10 & $3fff -- vduz1=vduz2_band_vduc1 
    lda.z flash_write1_flash_rom_address
    and #<$3fff
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0
    lda.z flash_write1_flash_rom_address+1
    and #>$3fff
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0+1
    lda.z flash_write1_flash_rom_address+2
    and #<$3fff>>$10
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0+2
    lda.z flash_write1_flash_rom_address+3
    and #>$3fff>>$10
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [442] main::flash_write1_rom_byte_program1_rom_ptr1_$2 = (unsigned int)main::flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0
    sta.z flash_write1_rom_byte_program1_rom_ptr1___2
    lda.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0+1
    sta.z flash_write1_rom_byte_program1_rom_ptr1___2+1
    // [443] main::flash_write1_rom_byte_program1_ptr_rom#0 = main::flash_write1_rom_byte_program1_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z flash_write1_rom_byte_program1_ptr_rom
    clc
    adc #<$c000
    sta.z flash_write1_rom_byte_program1_ptr_rom
    lda.z flash_write1_rom_byte_program1_ptr_rom+1
    adc #>$c000
    sta.z flash_write1_rom_byte_program1_ptr_rom+1
    // [444] phi from main::flash_write1_rom_byte_program1_rom_ptr1 to main::flash_write1_rom_byte_program1_rom_write_byte1 [phi:main::flash_write1_rom_byte_program1_rom_ptr1->main::flash_write1_rom_byte_program1_rom_write_byte1]
    // main::flash_write1_rom_byte_program1_rom_write_byte1
    // main::flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [445] main::flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1_$2 = main::flash_write1_flash_rom_address#10 & $3fc000 -- vduz1=vduz2_band_vduc1 
    lda.z flash_write1_flash_rom_address
    and #<$3fc000
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___2
    lda.z flash_write1_flash_rom_address+1
    and #>$3fc000
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___2+1
    lda.z flash_write1_flash_rom_address+2
    and #<$3fc000>>$10
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___2+2
    lda.z flash_write1_flash_rom_address+3
    and #>$3fc000>>$10
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___2+3
    // [446] main::flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1_$1 = main::flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1_$2 >> $e -- vduz1=vduz1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___1+3
    ror.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___1+2
    ror.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___1+1
    ror.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [447] main::flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1_return#0 = (char)main::flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1_$1 -- vbuxx=_byte_vduz1 
    lda.z flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1___1
    tax
    // main::flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [448] main::flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_$2 = (unsigned int)main::flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___2
    lda.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___0+1
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1___2+1
    // [449] main::flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_return#0 = main::flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_return
    clc
    adc #<$c000
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_return
    lda.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_return+1
    adc #>$c000
    sta.z flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_return+1
    // main::flash_write1_rom_byte_program1_rom_write_byte1_@2
    // bank_set_brom(bank_rom)
    // [450] bank_set_brom::bank#22 = main::flash_write1_rom_byte_program1_rom_write_byte1_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [451] call bank_set_brom
    // [891] phi from main::flash_write1_rom_byte_program1_rom_write_byte1_@2 to bank_set_brom [phi:main::flash_write1_rom_byte_program1_rom_write_byte1_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#22 [phi:main::flash_write1_rom_byte_program1_rom_write_byte1_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@135
    // *ptr_rom = value
    // [452] *((char *)main::flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_return#0) = main::flash_write1_rom_byte_program1_rom_write_byte1_value#0 -- _deref_pbuz1=vbuz2 
    lda.z flash_write1_rom_byte_program1_rom_write_byte1_value
    ldy #0
    sta (flash_write1_rom_byte_program1_rom_write_byte1_rom_ptr1_return),y
    // [453] phi from main::@135 to main::flash_write1_rom_byte_program1_rom_wait1 [phi:main::@135->main::flash_write1_rom_byte_program1_rom_wait1]
    // main::flash_write1_rom_byte_program1_rom_wait1
  flash_write1_rom_byte_program1_rom_wait1:
    // main::flash_write1_rom_byte_program1_rom_wait1_@1
    // test1 = *((brom_ptr_t)ptr_rom)
    // [454] main::flash_write1_rom_byte_program1_rom_wait1_test1#1 = *((char *)main::flash_write1_rom_byte_program1_ptr_rom#0) -- vbuxx=_deref_pbuz1 
    ldy #0
    lda (flash_write1_rom_byte_program1_ptr_rom),y
    tax
    // test2 = *((brom_ptr_t)ptr_rom)
    // [455] main::flash_write1_rom_byte_program1_rom_wait1_test2#1 = *((char *)main::flash_write1_rom_byte_program1_ptr_rom#0) -- vbuyy=_deref_pbuz1 
    lda (flash_write1_rom_byte_program1_ptr_rom),y
    tay
    // test1 & 0x40
    // [456] main::flash_write1_rom_byte_program1_rom_wait1_$0 = main::flash_write1_rom_byte_program1_rom_wait1_test1#1 & $40 -- vbuz1=vbuxx_band_vbuc1 
    txa
    and #$40
    sta.z flash_write1_rom_byte_program1_rom_wait1___0
    // test2 & 0x40
    // [457] main::flash_write1_rom_byte_program1_rom_wait1_$1 = main::flash_write1_rom_byte_program1_rom_wait1_test2#1 & $40 -- vbuaa=vbuyy_band_vbuc1 
    tya
    and #$40
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [458] if(main::flash_write1_rom_byte_program1_rom_wait1_$0!=main::flash_write1_rom_byte_program1_rom_wait1_$1) goto main::flash_write1_rom_byte_program1_rom_wait1_@1 -- vbuz1_neq_vbuaa_then_la1 
    cmp.z flash_write1_rom_byte_program1_rom_wait1___0
    bne flash_write1_rom_byte_program1_rom_wait1
    // main::flash_write1_@10
    // flash_rom_address++;
    // [459] main::flash_write1_flash_rom_address#1 = ++ main::flash_write1_flash_rom_address#10 -- vduz1=_inc_vduz1 
    inc.z flash_write1_flash_rom_address
    bne !+
    inc.z flash_write1_flash_rom_address+1
    bne !+
    inc.z flash_write1_flash_rom_address+2
    bne !+
    inc.z flash_write1_flash_rom_address+3
  !:
    // flash_ram_address++;
    // [460] main::flash_write1_flash_ram_address#1 = ++ main::flash_write1_flash_ram_address#10 -- pbuz1=_inc_pbuz1 
    inc.z flash_write1_flash_ram_address
    bne !+
    inc.z flash_write1_flash_ram_address+1
  !:
    // flashed_bytes++;
    // [461] main::flash_write1_flashed_bytes#1 = ++ main::flash_write1_flashed_bytes#10 -- vduz1=_inc_vduz1 
    inc.z flash_write1_flashed_bytes
    bne !+
    inc.z flash_write1_flashed_bytes+1
    bne !+
    inc.z flash_write1_flashed_bytes+2
    bne !+
    inc.z flash_write1_flashed_bytes+3
  !:
    // [369] phi from main::flash_write1_@10 to main::flash_write1_@1 [phi:main::flash_write1_@10->main::flash_write1_@1]
    // [369] phi main::flash_write1_flash_ram_address#10 = main::flash_write1_flash_ram_address#1 [phi:main::flash_write1_@10->main::flash_write1_@1#0] -- register_copy 
    // [369] phi main::flash_write1_flash_rom_address#10 = main::flash_write1_flash_rom_address#1 [phi:main::flash_write1_@10->main::flash_write1_@1#1] -- register_copy 
    // [369] phi main::flash_write1_flashed_bytes#10 = main::flash_write1_flashed_bytes#1 [phi:main::flash_write1_@10->main::flash_write1_@1#2] -- register_copy 
    jmp flash_write1___b1
    // main::flash_verify1_@2
  flash_verify1___b2:
    // rom_byte_verify(verify_rom_address, *verify_ram_address)
    // [462] main::flash_verify1_rom_byte_verify1_value#0 = *main::flash_verify1_verify_ram_address#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_verify1_verify_ram_address),y
    sta.z flash_verify1_rom_byte_verify1_value
    // [463] phi from main::flash_verify1_@2 to main::flash_verify1_rom_byte_verify1 [phi:main::flash_verify1_@2->main::flash_verify1_rom_byte_verify1]
    // main::flash_verify1_rom_byte_verify1
    // main::flash_verify1_rom_byte_verify1_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [464] main::flash_verify1_rom_byte_verify1_rom_bank1_$2 = main::flash_verify1_verify_rom_address#10 & $3fc000 -- vduz1=vdum2_band_vduc1 
    lda flash_verify1_verify_rom_address
    and #<$3fc000
    sta.z flash_verify1_rom_byte_verify1_rom_bank1___2
    lda flash_verify1_verify_rom_address+1
    and #>$3fc000
    sta.z flash_verify1_rom_byte_verify1_rom_bank1___2+1
    lda flash_verify1_verify_rom_address+2
    and #<$3fc000>>$10
    sta.z flash_verify1_rom_byte_verify1_rom_bank1___2+2
    lda flash_verify1_verify_rom_address+3
    and #>$3fc000>>$10
    sta.z flash_verify1_rom_byte_verify1_rom_bank1___2+3
    // [465] main::flash_verify1_rom_byte_verify1_rom_bank1_$1 = main::flash_verify1_rom_byte_verify1_rom_bank1_$2 >> $e -- vduz1=vduz1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr.z flash_verify1_rom_byte_verify1_rom_bank1___1+3
    ror.z flash_verify1_rom_byte_verify1_rom_bank1___1+2
    ror.z flash_verify1_rom_byte_verify1_rom_bank1___1+1
    ror.z flash_verify1_rom_byte_verify1_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [466] main::flash_verify1_rom_byte_verify1_rom_bank1_return#0 = (char)main::flash_verify1_rom_byte_verify1_rom_bank1_$1 -- vbuxx=_byte_vduz1 
    lda.z flash_verify1_rom_byte_verify1_rom_bank1___1
    tax
    // main::flash_verify1_rom_byte_verify1_rom_ptr1
    // address & ROM_PTR_MASK
    // [467] main::flash_verify1_rom_byte_verify1_rom_ptr1_$0 = main::flash_verify1_verify_rom_address#10 & $3fff -- vduz1=vdum2_band_vduc1 
    lda flash_verify1_verify_rom_address
    and #<$3fff
    sta.z flash_verify1_rom_byte_verify1_rom_ptr1___0
    lda flash_verify1_verify_rom_address+1
    and #>$3fff
    sta.z flash_verify1_rom_byte_verify1_rom_ptr1___0+1
    lda flash_verify1_verify_rom_address+2
    and #<$3fff>>$10
    sta.z flash_verify1_rom_byte_verify1_rom_ptr1___0+2
    lda flash_verify1_verify_rom_address+3
    and #>$3fff>>$10
    sta.z flash_verify1_rom_byte_verify1_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [468] main::flash_verify1_rom_byte_verify1_rom_ptr1_$2 = (unsigned int)main::flash_verify1_rom_byte_verify1_rom_ptr1_$0 -- vwuz1=_word_vduz2 
    lda.z flash_verify1_rom_byte_verify1_rom_ptr1___0
    sta.z flash_verify1_rom_byte_verify1_rom_ptr1___2
    lda.z flash_verify1_rom_byte_verify1_rom_ptr1___0+1
    sta.z flash_verify1_rom_byte_verify1_rom_ptr1___2+1
    // [469] main::flash_verify1_rom_byte_verify1_rom_ptr1_return#0 = main::flash_verify1_rom_byte_verify1_rom_ptr1_$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z flash_verify1_rom_byte_verify1_rom_ptr1_return
    clc
    adc #<$c000
    sta.z flash_verify1_rom_byte_verify1_rom_ptr1_return
    lda.z flash_verify1_rom_byte_verify1_rom_ptr1_return+1
    adc #>$c000
    sta.z flash_verify1_rom_byte_verify1_rom_ptr1_return+1
    // main::flash_verify1_rom_byte_verify1_@5
    // bank_set_brom(bank_rom)
    // [470] bank_set_brom::bank#11 = main::flash_verify1_rom_byte_verify1_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [471] call bank_set_brom
    // [891] phi from main::flash_verify1_rom_byte_verify1_@5 to bank_set_brom [phi:main::flash_verify1_rom_byte_verify1_@5->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#11 [phi:main::flash_verify1_rom_byte_verify1_@5->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@115
    // if (*ptr_rom != value)
    // [472] if(*((char *)main::flash_verify1_rom_byte_verify1_rom_ptr1_return#0)==main::flash_verify1_rom_byte_verify1_value#0) goto main::flash_verify1_rom_byte_verify1_@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z flash_verify1_rom_byte_verify1_value
    ldy #0
    cmp (flash_verify1_rom_byte_verify1_rom_ptr1_return),y
    beq __b12
    // [473] phi from main::@115 to main::flash_verify1_rom_byte_verify1_@2 [phi:main::@115->main::flash_verify1_rom_byte_verify1_@2]
    // main::flash_verify1_rom_byte_verify1_@2
    // [474] phi from main::flash_verify1_rom_byte_verify1_@2 to main::flash_verify1_rom_byte_verify1_@1 [phi:main::flash_verify1_rom_byte_verify1_@2->main::flash_verify1_rom_byte_verify1_@1]
    // [474] phi main::flash_verify1_rom_byte_verify1_return#0 = 0 [phi:main::flash_verify1_rom_byte_verify1_@2->main::flash_verify1_rom_byte_verify1_@1#0] -- vbuaa=vbuc1 
    tya
    jmp flash_verify1___b11
    // [474] phi from main::@115 to main::flash_verify1_rom_byte_verify1_@1 [phi:main::@115->main::flash_verify1_rom_byte_verify1_@1]
  __b12:
    // [474] phi main::flash_verify1_rom_byte_verify1_return#0 = 1 [phi:main::@115->main::flash_verify1_rom_byte_verify1_@1#0] -- vbuaa=vbuc1 
    lda #1
    // main::flash_verify1_rom_byte_verify1_@1
    // main::flash_verify1_@11
  flash_verify1___b11:
    // if (rom_byte_verify(verify_rom_address, *verify_ram_address))
    // [475] if(0==main::flash_verify1_rom_byte_verify1_return#0) goto main::flash_verify1_@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq flash_verify1___b4
    // main::flash_verify1_@7
    // correct_bytes++;
    // [476] main::flash_verify1_correct_bytes#1 = ++ main::flash_verify1_correct_bytes#10 -- vduz1=_inc_vduz1 
    inc.z flash_verify1_correct_bytes
    bne !+
    inc.z flash_verify1_correct_bytes+1
    bne !+
    inc.z flash_verify1_correct_bytes+2
    bne !+
    inc.z flash_verify1_correct_bytes+3
  !:
    // [477] phi from main::flash_verify1_@11 main::flash_verify1_@7 to main::flash_verify1_@4 [phi:main::flash_verify1_@11/main::flash_verify1_@7->main::flash_verify1_@4]
    // [477] phi main::flash_verify1_correct_bytes#6 = main::flash_verify1_correct_bytes#10 [phi:main::flash_verify1_@11/main::flash_verify1_@7->main::flash_verify1_@4#0] -- register_copy 
    // main::flash_verify1_@4
  flash_verify1___b4:
    // verify_rom_address++;
    // [478] main::flash_verify1_verify_rom_address#1 = ++ main::flash_verify1_verify_rom_address#10 -- vdum1=_inc_vdum1 
    inc flash_verify1_verify_rom_address
    bne !+
    inc flash_verify1_verify_rom_address+1
    bne !+
    inc flash_verify1_verify_rom_address+2
    bne !+
    inc flash_verify1_verify_rom_address+3
  !:
    // verify_ram_address++;
    // [479] main::flash_verify1_verify_ram_address#1 = ++ main::flash_verify1_verify_ram_address#10 -- pbuz1=_inc_pbuz1 
    inc.z flash_verify1_verify_ram_address
    bne !+
    inc.z flash_verify1_verify_ram_address+1
  !:
    // verified_bytes++;
    // [480] main::flash_verify1_verified_bytes#1 = ++ main::flash_verify1_verified_bytes#10 -- vduz1=_inc_vduz1 
    inc.z flash_verify1_verified_bytes
    bne !+
    inc.z flash_verify1_verified_bytes+1
    bne !+
    inc.z flash_verify1_verified_bytes+2
    bne !+
    inc.z flash_verify1_verified_bytes+3
  !:
    // [245] phi from main::flash_verify1_@4 to main::flash_verify1_@1 [phi:main::flash_verify1_@4->main::flash_verify1_@1]
    // [245] phi main::flash_verify1_correct_bytes#10 = main::flash_verify1_correct_bytes#6 [phi:main::flash_verify1_@4->main::flash_verify1_@1#0] -- register_copy 
    // [245] phi main::flash_verify1_verify_ram_address#10 = main::flash_verify1_verify_ram_address#1 [phi:main::flash_verify1_@4->main::flash_verify1_@1#1] -- register_copy 
    // [245] phi main::flash_verify1_verify_rom_address#10 = main::flash_verify1_verify_rom_address#1 [phi:main::flash_verify1_@4->main::flash_verify1_@1#2] -- register_copy 
    // [245] phi main::flash_verify1_verified_bytes#10 = main::flash_verify1_verified_bytes#1 [phi:main::flash_verify1_@4->main::flash_verify1_@1#3] -- register_copy 
    jmp flash_verify1___b1
    // [481] phi from main::@90 to main::@19 [phi:main::@90->main::@19]
    // main::@19
  __b19:
    // sprintf(file, "rom.bin", flash_chip)
    // [482] call snprintf_init
    jsr snprintf_init
    // [483] phi from main::@19 to main::@91 [phi:main::@19->main::@91]
    // main::@91
    // sprintf(file, "rom.bin", flash_chip)
    // [484] call printf_str
    // [855] phi from main::@91 to printf_str [phi:main::@91->printf_str]
    // [855] phi printf_str::putc#20 = &snputc [phi:main::@91->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = main::s3 [phi:main::@91->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@92
    // sprintf(file, "rom.bin", flash_chip)
    // [485] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [486] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b20
    // main::@4
  __b4:
    // rom_manufacturer_ids[rom_chip] = 0
    // [488] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [489] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // if (flash_rom_address <= 0x100000)
    // [490] if(main::flash_rom_address#10>$100000) goto main::@5 -- vdum1_gt_vduc1_then_la1 
    lda #>$100000>>$10
    cmp flash_rom_address+3
    bcs !__b5+
    jmp __b5
  !__b5:
    bne !+
    lda #<$100000>>$10
    cmp flash_rom_address+2
    bcs !__b5+
    jmp __b5
  !__b5:
    bne !+
    lda #>$100000
    cmp flash_rom_address+1
    bcs !__b5+
    jmp __b5
  !__b5:
    bne !+
    lda #<$100000
    cmp flash_rom_address
    bcs !__b5+
    jmp __b5
  !__b5:
  !:
    // main::@12
    // flash_rom_address + 0x05555
    // [491] main::rom_unlock2_address#0 = main::flash_rom_address#10 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda flash_rom_address
    adc #<$5555
    sta rom_unlock2_address
    lda flash_rom_address+1
    adc #>$5555
    sta rom_unlock2_address+1
    lda flash_rom_address+2
    adc #0
    sta rom_unlock2_address+2
    lda flash_rom_address+3
    adc #0
    sta rom_unlock2_address+3
    // main::rom_unlock1
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [492] main::rom_unlock2_chip_address#0 = main::rom_unlock2_address#0 & $380000 -- vdum1=vdum2_band_vduc1 
    lda rom_unlock2_address
    and #<$380000
    sta rom_unlock2_chip_address
    lda rom_unlock2_address+1
    and #>$380000
    sta rom_unlock2_chip_address+1
    lda rom_unlock2_address+2
    and #<$380000>>$10
    sta rom_unlock2_chip_address+2
    lda rom_unlock2_address+3
    and #>$380000>>$10
    sta rom_unlock2_chip_address+3
    // chip_address + 0x05555
    // [493] main::rom_unlock2_rom_write_byte1_address#0 = main::rom_unlock2_chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda rom_unlock2_chip_address
    adc #<$5555
    sta rom_unlock2_rom_write_byte1_address
    lda rom_unlock2_chip_address+1
    adc #>$5555
    sta rom_unlock2_rom_write_byte1_address+1
    lda rom_unlock2_chip_address+2
    adc #0
    sta rom_unlock2_rom_write_byte1_address+2
    lda rom_unlock2_chip_address+3
    adc #0
    sta rom_unlock2_rom_write_byte1_address+3
    // [494] phi from main::rom_unlock1 to main::rom_unlock1_rom_write_byte1 [phi:main::rom_unlock1->main::rom_unlock1_rom_write_byte1]
    // main::rom_unlock1_rom_write_byte1
    // main::rom_unlock1_rom_write_byte1_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [495] main::rom_unlock2_rom_write_byte1_rom_bank1_$2 = main::rom_unlock2_rom_write_byte1_address#0 & $3fc000 -- vdum1=vdum2_band_vduc1 
    lda rom_unlock2_rom_write_byte1_address
    and #<$3fc000
    sta rom_unlock2_rom_write_byte1_rom_bank1___2
    lda rom_unlock2_rom_write_byte1_address+1
    and #>$3fc000
    sta rom_unlock2_rom_write_byte1_rom_bank1___2+1
    lda rom_unlock2_rom_write_byte1_address+2
    and #<$3fc000>>$10
    sta rom_unlock2_rom_write_byte1_rom_bank1___2+2
    lda rom_unlock2_rom_write_byte1_address+3
    and #>$3fc000>>$10
    sta rom_unlock2_rom_write_byte1_rom_bank1___2+3
    // [496] main::rom_unlock2_rom_write_byte1_rom_bank1_$1 = main::rom_unlock2_rom_write_byte1_rom_bank1_$2 >> $e -- vdum1=vdum1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr rom_unlock2_rom_write_byte1_rom_bank1___1+3
    ror rom_unlock2_rom_write_byte1_rom_bank1___1+2
    ror rom_unlock2_rom_write_byte1_rom_bank1___1+1
    ror rom_unlock2_rom_write_byte1_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [497] main::rom_unlock1_rom_write_byte1_rom_bank1_return#0 = (char)main::rom_unlock2_rom_write_byte1_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_unlock2_rom_write_byte1_rom_bank1___1
    tax
    // main::rom_unlock1_rom_write_byte1_rom_ptr1
    // address & ROM_PTR_MASK
    // [498] main::rom_unlock2_rom_write_byte1_rom_ptr1_$0 = main::rom_unlock2_rom_write_byte1_address#0 & $3fff -- vdum1=vdum1_band_vduc1 
    lda rom_unlock2_rom_write_byte1_rom_ptr1___0
    and #<$3fff
    sta rom_unlock2_rom_write_byte1_rom_ptr1___0
    lda rom_unlock2_rom_write_byte1_rom_ptr1___0+1
    and #>$3fff
    sta rom_unlock2_rom_write_byte1_rom_ptr1___0+1
    lda rom_unlock2_rom_write_byte1_rom_ptr1___0+2
    and #<$3fff>>$10
    sta rom_unlock2_rom_write_byte1_rom_ptr1___0+2
    lda rom_unlock2_rom_write_byte1_rom_ptr1___0+3
    and #>$3fff>>$10
    sta rom_unlock2_rom_write_byte1_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [499] main::rom_unlock1_rom_write_byte1_rom_ptr1_$2 = (unsigned int)main::rom_unlock2_rom_write_byte1_rom_ptr1_$0 -- vwum1=_word_vdum2 
    lda rom_unlock2_rom_write_byte1_rom_ptr1___0
    sta rom_unlock1_rom_write_byte1_rom_ptr1___2
    lda rom_unlock2_rom_write_byte1_rom_ptr1___0+1
    sta rom_unlock1_rom_write_byte1_rom_ptr1___2+1
    // [500] main::rom_unlock1_rom_write_byte1_rom_ptr1_return#0 = main::rom_unlock1_rom_write_byte1_rom_ptr1_$2 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_unlock1_rom_write_byte1_rom_ptr1_return
    clc
    adc #<$c000
    sta rom_unlock1_rom_write_byte1_rom_ptr1_return
    lda rom_unlock1_rom_write_byte1_rom_ptr1_return+1
    adc #>$c000
    sta rom_unlock1_rom_write_byte1_rom_ptr1_return+1
    // main::rom_unlock1_rom_write_byte1_@2
    // bank_set_brom(bank_rom)
    // [501] bank_set_brom::bank#3 = main::rom_unlock1_rom_write_byte1_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [502] call bank_set_brom
    // [891] phi from main::rom_unlock1_rom_write_byte1_@2 to bank_set_brom [phi:main::rom_unlock1_rom_write_byte1_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#3 [phi:main::rom_unlock1_rom_write_byte1_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@75
    // *ptr_rom = value
    // [503] *((char *)main::rom_unlock1_rom_write_byte1_rom_ptr1_return#0) = main::rom_unlock1_rom_write_byte1_value#0 -- _deref_pbum1=vbuc1 
    lda #rom_unlock1_rom_write_byte1_value
    ldy rom_unlock1_rom_write_byte1_rom_ptr1_return
    sty.z $fe
    ldy rom_unlock1_rom_write_byte1_rom_ptr1_return+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // main::rom_unlock1_@1
    // chip_address + 0x02AAA
    // [504] main::rom_unlock2_rom_write_byte2_address#0 = main::rom_unlock2_chip_address#0 + $2aaa -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_unlock2_rom_write_byte2_address
    adc #<$2aaa
    sta rom_unlock2_rom_write_byte2_address
    lda rom_unlock2_rom_write_byte2_address+1
    adc #>$2aaa
    sta rom_unlock2_rom_write_byte2_address+1
    lda rom_unlock2_rom_write_byte2_address+2
    adc #0
    sta rom_unlock2_rom_write_byte2_address+2
    lda rom_unlock2_rom_write_byte2_address+3
    adc #0
    sta rom_unlock2_rom_write_byte2_address+3
    // [505] phi from main::rom_unlock1_@1 to main::rom_unlock1_rom_write_byte2 [phi:main::rom_unlock1_@1->main::rom_unlock1_rom_write_byte2]
    // main::rom_unlock1_rom_write_byte2
    // main::rom_unlock1_rom_write_byte2_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [506] main::rom_unlock2_rom_write_byte2_rom_bank1_$2 = main::rom_unlock2_rom_write_byte2_address#0 & $3fc000 -- vdum1=vdum2_band_vduc1 
    lda rom_unlock2_rom_write_byte2_address
    and #<$3fc000
    sta rom_unlock2_rom_write_byte2_rom_bank1___2
    lda rom_unlock2_rom_write_byte2_address+1
    and #>$3fc000
    sta rom_unlock2_rom_write_byte2_rom_bank1___2+1
    lda rom_unlock2_rom_write_byte2_address+2
    and #<$3fc000>>$10
    sta rom_unlock2_rom_write_byte2_rom_bank1___2+2
    lda rom_unlock2_rom_write_byte2_address+3
    and #>$3fc000>>$10
    sta rom_unlock2_rom_write_byte2_rom_bank1___2+3
    // [507] main::rom_unlock2_rom_write_byte2_rom_bank1_$1 = main::rom_unlock2_rom_write_byte2_rom_bank1_$2 >> $e -- vdum1=vdum1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr rom_unlock2_rom_write_byte2_rom_bank1___1+3
    ror rom_unlock2_rom_write_byte2_rom_bank1___1+2
    ror rom_unlock2_rom_write_byte2_rom_bank1___1+1
    ror rom_unlock2_rom_write_byte2_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [508] main::rom_unlock1_rom_write_byte2_rom_bank1_return#0 = (char)main::rom_unlock2_rom_write_byte2_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_unlock2_rom_write_byte2_rom_bank1___1
    tax
    // main::rom_unlock1_rom_write_byte2_rom_ptr1
    // address & ROM_PTR_MASK
    // [509] main::rom_unlock2_rom_write_byte2_rom_ptr1_$0 = main::rom_unlock2_rom_write_byte2_address#0 & $3fff -- vdum1=vdum2_band_vduc1 
    lda rom_unlock2_rom_write_byte2_address
    and #<$3fff
    sta rom_unlock2_rom_write_byte2_rom_ptr1___0
    lda rom_unlock2_rom_write_byte2_address+1
    and #>$3fff
    sta rom_unlock2_rom_write_byte2_rom_ptr1___0+1
    lda rom_unlock2_rom_write_byte2_address+2
    and #<$3fff>>$10
    sta rom_unlock2_rom_write_byte2_rom_ptr1___0+2
    lda rom_unlock2_rom_write_byte2_address+3
    and #>$3fff>>$10
    sta rom_unlock2_rom_write_byte2_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [510] main::rom_unlock1_rom_write_byte2_rom_ptr1_$2 = (unsigned int)main::rom_unlock2_rom_write_byte2_rom_ptr1_$0 -- vwum1=_word_vdum2 
    lda rom_unlock2_rom_write_byte2_rom_ptr1___0
    sta rom_unlock1_rom_write_byte2_rom_ptr1___2
    lda rom_unlock2_rom_write_byte2_rom_ptr1___0+1
    sta rom_unlock1_rom_write_byte2_rom_ptr1___2+1
    // [511] main::rom_unlock1_rom_write_byte2_rom_ptr1_return#0 = main::rom_unlock1_rom_write_byte2_rom_ptr1_$2 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_unlock1_rom_write_byte2_rom_ptr1_return
    clc
    adc #<$c000
    sta rom_unlock1_rom_write_byte2_rom_ptr1_return
    lda rom_unlock1_rom_write_byte2_rom_ptr1_return+1
    adc #>$c000
    sta rom_unlock1_rom_write_byte2_rom_ptr1_return+1
    // main::rom_unlock1_rom_write_byte2_@2
    // bank_set_brom(bank_rom)
    // [512] bank_set_brom::bank#4 = main::rom_unlock1_rom_write_byte2_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [513] call bank_set_brom
    // [891] phi from main::rom_unlock1_rom_write_byte2_@2 to bank_set_brom [phi:main::rom_unlock1_rom_write_byte2_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#4 [phi:main::rom_unlock1_rom_write_byte2_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@76
    // *ptr_rom = value
    // [514] *((char *)main::rom_unlock1_rom_write_byte2_rom_ptr1_return#0) = main::rom_unlock1_rom_write_byte2_value#0 -- _deref_pbum1=vbuc1 
    lda #rom_unlock1_rom_write_byte2_value
    ldy rom_unlock1_rom_write_byte2_rom_ptr1_return
    sty.z $fe
    ldy rom_unlock1_rom_write_byte2_rom_ptr1_return+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // [515] phi from main::@76 to main::rom_unlock1_rom_write_byte3 [phi:main::@76->main::rom_unlock1_rom_write_byte3]
    // main::rom_unlock1_rom_write_byte3
    // main::rom_unlock1_rom_write_byte3_rom_bank1
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [516] main::rom_unlock2_rom_write_byte3_rom_bank1_$2 = main::rom_unlock2_address#0 & $3fc000 -- vdum1=vdum2_band_vduc1 
    lda rom_unlock2_address
    and #<$3fc000
    sta rom_unlock2_rom_write_byte3_rom_bank1___2
    lda rom_unlock2_address+1
    and #>$3fc000
    sta rom_unlock2_rom_write_byte3_rom_bank1___2+1
    lda rom_unlock2_address+2
    and #<$3fc000>>$10
    sta rom_unlock2_rom_write_byte3_rom_bank1___2+2
    lda rom_unlock2_address+3
    and #>$3fc000>>$10
    sta rom_unlock2_rom_write_byte3_rom_bank1___2+3
    // [517] main::rom_unlock2_rom_write_byte3_rom_bank1_$1 = main::rom_unlock2_rom_write_byte3_rom_bank1_$2 >> $e -- vdum1=vdum1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr rom_unlock2_rom_write_byte3_rom_bank1___1+3
    ror rom_unlock2_rom_write_byte3_rom_bank1___1+2
    ror rom_unlock2_rom_write_byte3_rom_bank1___1+1
    ror rom_unlock2_rom_write_byte3_rom_bank1___1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [518] main::rom_unlock1_rom_write_byte3_rom_bank1_return#0 = (char)main::rom_unlock2_rom_write_byte3_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_unlock2_rom_write_byte3_rom_bank1___1
    tax
    // main::rom_unlock1_rom_write_byte3_rom_ptr1
    // address & ROM_PTR_MASK
    // [519] main::rom_unlock2_rom_write_byte3_rom_ptr1_$0 = main::rom_unlock2_address#0 & $3fff -- vdum1=vdum2_band_vduc1 
    lda rom_unlock2_address
    and #<$3fff
    sta rom_unlock2_rom_write_byte3_rom_ptr1___0
    lda rom_unlock2_address+1
    and #>$3fff
    sta rom_unlock2_rom_write_byte3_rom_ptr1___0+1
    lda rom_unlock2_address+2
    and #<$3fff>>$10
    sta rom_unlock2_rom_write_byte3_rom_ptr1___0+2
    lda rom_unlock2_address+3
    and #>$3fff>>$10
    sta rom_unlock2_rom_write_byte3_rom_ptr1___0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [520] main::rom_unlock1_rom_write_byte3_rom_ptr1_$2 = (unsigned int)main::rom_unlock2_rom_write_byte3_rom_ptr1_$0 -- vwum1=_word_vdum2 
    lda rom_unlock2_rom_write_byte3_rom_ptr1___0
    sta rom_unlock1_rom_write_byte3_rom_ptr1___2
    lda rom_unlock2_rom_write_byte3_rom_ptr1___0+1
    sta rom_unlock1_rom_write_byte3_rom_ptr1___2+1
    // [521] main::rom_unlock1_rom_write_byte3_rom_ptr1_return#0 = main::rom_unlock1_rom_write_byte3_rom_ptr1_$2 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_unlock1_rom_write_byte3_rom_ptr1_return
    clc
    adc #<$c000
    sta rom_unlock1_rom_write_byte3_rom_ptr1_return
    lda rom_unlock1_rom_write_byte3_rom_ptr1_return+1
    adc #>$c000
    sta rom_unlock1_rom_write_byte3_rom_ptr1_return+1
    // main::rom_unlock1_rom_write_byte3_@2
    // bank_set_brom(bank_rom)
    // [522] bank_set_brom::bank#5 = main::rom_unlock1_rom_write_byte3_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [523] call bank_set_brom
    // [891] phi from main::rom_unlock1_rom_write_byte3_@2 to bank_set_brom [phi:main::rom_unlock1_rom_write_byte3_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#5 [phi:main::rom_unlock1_rom_write_byte3_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@77
    // *ptr_rom = value
    // [524] *((char *)main::rom_unlock1_rom_write_byte3_rom_ptr1_return#0) = main::rom_unlock1_unlock_code#0 -- _deref_pbum1=vbuc1 
    lda #rom_unlock1_unlock_code
    ldy rom_unlock1_rom_write_byte3_rom_ptr1_return
    sty.z $fe
    ldy rom_unlock1_rom_write_byte3_rom_ptr1_return+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // main::@44
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [525] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [526] main::rom_device_ids[main::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // [527] phi from main::@44 to main::rom_unlock2 [phi:main::@44->main::rom_unlock2]
    // main::rom_unlock2
    // [528] phi from main::rom_unlock2 to main::rom_unlock2_rom_write_byte1 [phi:main::rom_unlock2->main::rom_unlock2_rom_write_byte1]
    // main::rom_unlock2_rom_write_byte1
    // main::rom_unlock2_rom_write_byte1_rom_bank1
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [529] main::rom_unlock2_rom_write_byte1_rom_bank1_return#0 = (char)main::rom_unlock2_rom_write_byte1_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_unlock2_rom_write_byte1_rom_bank1___1
    tax
    // main::rom_unlock2_rom_write_byte1_rom_ptr1
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [530] main::rom_unlock2_rom_write_byte1_rom_ptr1_$2 = (unsigned int)main::rom_unlock2_rom_write_byte1_rom_ptr1_$0 -- vwum1=_word_vdum2 
    lda rom_unlock2_rom_write_byte1_rom_ptr1___0
    sta rom_unlock2_rom_write_byte1_rom_ptr1___2
    lda rom_unlock2_rom_write_byte1_rom_ptr1___0+1
    sta rom_unlock2_rom_write_byte1_rom_ptr1___2+1
    // [531] main::rom_unlock2_rom_write_byte1_rom_ptr1_return#0 = main::rom_unlock2_rom_write_byte1_rom_ptr1_$2 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_unlock2_rom_write_byte1_rom_ptr1_return
    clc
    adc #<$c000
    sta rom_unlock2_rom_write_byte1_rom_ptr1_return
    lda rom_unlock2_rom_write_byte1_rom_ptr1_return+1
    adc #>$c000
    sta rom_unlock2_rom_write_byte1_rom_ptr1_return+1
    // main::rom_unlock2_rom_write_byte1_@2
    // bank_set_brom(bank_rom)
    // [532] bank_set_brom::bank#6 = main::rom_unlock2_rom_write_byte1_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [533] call bank_set_brom
    // [891] phi from main::rom_unlock2_rom_write_byte1_@2 to bank_set_brom [phi:main::rom_unlock2_rom_write_byte1_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#6 [phi:main::rom_unlock2_rom_write_byte1_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@78
    // *ptr_rom = value
    // [534] *((char *)main::rom_unlock2_rom_write_byte1_rom_ptr1_return#0) = main::rom_unlock2_rom_write_byte1_value#0 -- _deref_pbum1=vbuc1 
    lda #rom_unlock2_rom_write_byte1_value
    ldy rom_unlock2_rom_write_byte1_rom_ptr1_return
    sty.z $fe
    ldy rom_unlock2_rom_write_byte1_rom_ptr1_return+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // [535] phi from main::@78 to main::rom_unlock2_rom_write_byte2 [phi:main::@78->main::rom_unlock2_rom_write_byte2]
    // main::rom_unlock2_rom_write_byte2
    // main::rom_unlock2_rom_write_byte2_rom_bank1
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [536] main::rom_unlock2_rom_write_byte2_rom_bank1_return#0 = (char)main::rom_unlock2_rom_write_byte2_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_unlock2_rom_write_byte2_rom_bank1___1
    tax
    // main::rom_unlock2_rom_write_byte2_rom_ptr1
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [537] main::rom_unlock2_rom_write_byte2_rom_ptr1_$2 = (unsigned int)main::rom_unlock2_rom_write_byte2_rom_ptr1_$0 -- vwum1=_word_vdum2 
    lda rom_unlock2_rom_write_byte2_rom_ptr1___0
    sta rom_unlock2_rom_write_byte2_rom_ptr1___2
    lda rom_unlock2_rom_write_byte2_rom_ptr1___0+1
    sta rom_unlock2_rom_write_byte2_rom_ptr1___2+1
    // [538] main::rom_unlock2_rom_write_byte2_rom_ptr1_return#0 = main::rom_unlock2_rom_write_byte2_rom_ptr1_$2 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_unlock2_rom_write_byte2_rom_ptr1_return
    clc
    adc #<$c000
    sta rom_unlock2_rom_write_byte2_rom_ptr1_return
    lda rom_unlock2_rom_write_byte2_rom_ptr1_return+1
    adc #>$c000
    sta rom_unlock2_rom_write_byte2_rom_ptr1_return+1
    // main::rom_unlock2_rom_write_byte2_@2
    // bank_set_brom(bank_rom)
    // [539] bank_set_brom::bank#7 = main::rom_unlock2_rom_write_byte2_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [540] call bank_set_brom
    // [891] phi from main::rom_unlock2_rom_write_byte2_@2 to bank_set_brom [phi:main::rom_unlock2_rom_write_byte2_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#7 [phi:main::rom_unlock2_rom_write_byte2_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@79
    // *ptr_rom = value
    // [541] *((char *)main::rom_unlock2_rom_write_byte2_rom_ptr1_return#0) = main::rom_unlock2_rom_write_byte2_value#0 -- _deref_pbum1=vbuc1 
    lda #rom_unlock2_rom_write_byte2_value
    ldy rom_unlock2_rom_write_byte2_rom_ptr1_return
    sty.z $fe
    ldy rom_unlock2_rom_write_byte2_rom_ptr1_return+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // [542] phi from main::@79 to main::rom_unlock2_rom_write_byte3 [phi:main::@79->main::rom_unlock2_rom_write_byte3]
    // main::rom_unlock2_rom_write_byte3
    // main::rom_unlock2_rom_write_byte3_rom_bank1
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [543] main::rom_unlock2_rom_write_byte3_rom_bank1_return#0 = (char)main::rom_unlock2_rom_write_byte3_rom_bank1_$1 -- vbuxx=_byte_vdum1 
    lda rom_unlock2_rom_write_byte3_rom_bank1___1
    tax
    // main::rom_unlock2_rom_write_byte3_rom_ptr1
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [544] main::rom_unlock2_rom_write_byte3_rom_ptr1_$2 = (unsigned int)main::rom_unlock2_rom_write_byte3_rom_ptr1_$0 -- vwum1=_word_vdum2 
    lda rom_unlock2_rom_write_byte3_rom_ptr1___0
    sta rom_unlock2_rom_write_byte3_rom_ptr1___2
    lda rom_unlock2_rom_write_byte3_rom_ptr1___0+1
    sta rom_unlock2_rom_write_byte3_rom_ptr1___2+1
    // [545] main::rom_unlock2_rom_write_byte3_rom_ptr1_return#0 = main::rom_unlock2_rom_write_byte3_rom_ptr1_$2 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_unlock2_rom_write_byte3_rom_ptr1_return
    clc
    adc #<$c000
    sta rom_unlock2_rom_write_byte3_rom_ptr1_return
    lda rom_unlock2_rom_write_byte3_rom_ptr1_return+1
    adc #>$c000
    sta rom_unlock2_rom_write_byte3_rom_ptr1_return+1
    // main::rom_unlock2_rom_write_byte3_@2
    // bank_set_brom(bank_rom)
    // [546] bank_set_brom::bank#8 = main::rom_unlock2_rom_write_byte3_rom_bank1_return#0 -- vbuaa=vbuxx 
    txa
    // [547] call bank_set_brom
    // [891] phi from main::rom_unlock2_rom_write_byte3_@2 to bank_set_brom [phi:main::rom_unlock2_rom_write_byte3_@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = bank_set_brom::bank#8 [phi:main::rom_unlock2_rom_write_byte3_@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // main::@80
    // *ptr_rom = value
    // [548] *((char *)main::rom_unlock2_rom_write_byte3_rom_ptr1_return#0) = main::rom_unlock2_unlock_code#0 -- _deref_pbum1=vbuc1 
    lda #rom_unlock2_unlock_code
    ldy rom_unlock2_rom_write_byte3_rom_ptr1_return
    sty.z $fe
    ldy rom_unlock2_rom_write_byte3_rom_ptr1_return+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // [549] phi from main::@4 main::@80 to main::@5 [phi:main::@4/main::@80->main::@5]
    // main::@5
  __b5:
    // bank_set_brom(4)
    // [550] call bank_set_brom
  // Ensure the ROM is set to BASIC.
    // [891] phi from main::@5 to bank_set_brom [phi:main::@5->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = 4 [phi:main::@5->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::@74
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             break;
    // [551] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@6 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip
    lda rom_device_ids,y
    cmp #$b5
    bne !__b6+
    jmp __b6
  !__b6:
    // main::@13
    // case SST39SF020A:
    //             rom_device = "f020a";
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             break;
    // [552] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@7 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b6
    bne !__b7+
    jmp __b7
  !__b7:
    // main::@14
    // case SST39SF040:
    //             rom_device = "f040";
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             break;
    // [553] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@8 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b8+
    jmp __b8
  !__b8:
    // main::@9
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [554] print_chip_led::r#4 = main::rom_chip#10 -- vbuxx=vbum1 
    ldx rom_chip
    // [555] call print_chip_led
    // [942] phi from main::@9 to print_chip_led [phi:main::@9->print_chip_led]
    // [942] phi print_chip_led::tc#10 = BLACK [phi:main::@9->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#4 [phi:main::@9->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@81
    // rom_device_ids[rom_chip] = UNKNOWN
    // [556] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // [557] phi from main::@81 to main::@10 [phi:main::@81->main::@10]
    // [557] phi main::rom_device#5 = main::rom_device#12 [phi:main::@81->main::@10#0] -- pbum1=pbuc1 
    lda #<rom_device_4
    sta rom_device
    lda #>rom_device_4
    sta rom_device+1
    // main::@10
  __b10:
    // textcolor(WHITE)
    // [558] call textcolor
    // [609] phi from main::@10 to textcolor [phi:main::@10->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:main::@10->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@82
    // rom_chip * 10
    // [559] main::$172 = main::rom_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda rom_chip
    asl
    asl
    // [560] main::$173 = main::$172 + main::rom_chip#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip
    // [561] main::$67 = main::$173 << 1 -- vbum1=vbuaa_rol_1 
    asl
    sta __67
    // gotoxy(2 + rom_chip * 10, 56)
    // [562] gotoxy::x#13 = 2 + main::$67 -- vbuxx=vbuc1_plus_vbum1 
    lda #2
    clc
    adc __67
    tax
    // [563] call gotoxy
    // [627] phi from main::@82 to gotoxy [phi:main::@82->gotoxy]
    // [627] phi gotoxy::y#22 = $38 [phi:main::@82->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$38
    // [627] phi gotoxy::x#22 = gotoxy::x#13 [phi:main::@82->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@83
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [564] printf_uchar::uvalue#1 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbuxx=pbuc1_derefidx_vbum1 
    ldy rom_chip
    ldx rom_manufacturer_ids,y
    // [565] call printf_uchar
    // [894] phi from main::@83 to printf_uchar [phi:main::@83->printf_uchar]
    // [894] phi printf_uchar::format_zero_padding#4 = 0 [phi:main::@83->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [894] phi printf_uchar::format_min_length#4 = 0 [phi:main::@83->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [894] phi printf_uchar::putc#4 = &cputc [phi:main::@83->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [894] phi printf_uchar::format_radix#4 = HEXADECIMAL [phi:main::@83->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [894] phi printf_uchar::uvalue#4 = printf_uchar::uvalue#1 [phi:main::@83->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // main::@84
    // gotoxy(2 + rom_chip * 10, 57)
    // [566] gotoxy::x#14 = 2 + main::$67 -- vbuxx=vbuc1_plus_vbum1 
    lda #2
    clc
    adc __67
    tax
    // [567] call gotoxy
    // [627] phi from main::@84 to gotoxy [phi:main::@84->gotoxy]
    // [627] phi gotoxy::y#22 = $39 [phi:main::@84->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$39
    // [627] phi gotoxy::x#22 = gotoxy::x#14 [phi:main::@84->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@85
    // printf("%s", rom_device)
    // [568] printf_string::str#2 = main::rom_device#5 -- pbuz1=pbum2 
    lda rom_device
    sta.z printf_string.str
    lda rom_device+1
    sta.z printf_string.str+1
    // [569] call printf_string
    // [985] phi from main::@85 to printf_string [phi:main::@85->printf_string]
    // [985] phi printf_string::str#10 = printf_string::str#2 [phi:main::@85->printf_string#0] -- register_copy 
    // [985] phi printf_string::format_justify_left#10 = 0 [phi:main::@85->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [985] phi printf_string::format_min_length#6 = 0 [phi:main::@85->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@86
    // rom_chip++;
    // [570] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // main::@11
    // flash_rom_address += 0x80000
    // [571] main::flash_rom_address#1 = main::flash_rom_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
    clc
    lda flash_rom_address
    adc #<$80000
    sta flash_rom_address
    lda flash_rom_address+1
    adc #>$80000
    sta flash_rom_address+1
    lda flash_rom_address+2
    adc #<$80000>>$10
    sta flash_rom_address+2
    lda flash_rom_address+3
    adc #>$80000>>$10
    sta flash_rom_address+3
    // [91] phi from main::@11 to main::@3 [phi:main::@11->main::@3]
    // [91] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@11->main::@3#0] -- register_copy 
    // [91] phi main::flash_rom_address#10 = main::flash_rom_address#1 [phi:main::@11->main::@3#1] -- register_copy 
    jmp __b3
    // main::@8
  __b8:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [572] print_chip_led::r#3 = main::rom_chip#10 -- vbuxx=vbum1 
    ldx rom_chip
    // [573] call print_chip_led
    // [942] phi from main::@8 to print_chip_led [phi:main::@8->print_chip_led]
    // [942] phi print_chip_led::tc#10 = WHITE [phi:main::@8->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#3 [phi:main::@8->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [557] phi from main::@8 to main::@10 [phi:main::@8->main::@10]
    // [557] phi main::rom_device#5 = main::rom_device#11 [phi:main::@8->main::@10#0] -- pbum1=pbuc1 
    lda #<rom_device_3
    sta rom_device
    lda #>rom_device_3
    sta rom_device+1
    jmp __b10
    // main::@7
  __b7:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [574] print_chip_led::r#2 = main::rom_chip#10 -- vbuxx=vbum1 
    ldx rom_chip
    // [575] call print_chip_led
    // [942] phi from main::@7 to print_chip_led [phi:main::@7->print_chip_led]
    // [942] phi print_chip_led::tc#10 = WHITE [phi:main::@7->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#2 [phi:main::@7->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [557] phi from main::@7 to main::@10 [phi:main::@7->main::@10]
    // [557] phi main::rom_device#5 = main::rom_device#10 [phi:main::@7->main::@10#0] -- pbum1=pbuc1 
    lda #<rom_device_2
    sta rom_device
    lda #>rom_device_2
    sta rom_device+1
    jmp __b10
    // main::@6
  __b6:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [576] print_chip_led::r#1 = main::rom_chip#10 -- vbuxx=vbum1 
    ldx rom_chip
    // [577] call print_chip_led
    // [942] phi from main::@6 to print_chip_led [phi:main::@6->print_chip_led]
    // [942] phi print_chip_led::tc#10 = WHITE [phi:main::@6->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#1 [phi:main::@6->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [557] phi from main::@6 to main::@10 [phi:main::@6->main::@10]
    // [557] phi main::rom_device#5 = main::rom_device#1 [phi:main::@6->main::@10#0] -- pbum1=pbuc1 
    lda #<rom_device_1
    sta rom_device
    lda #>rom_device_1
    sta rom_device+1
    jmp __b10
    // main::@2
  __b2:
    // r * 10
    // [578] main::$169 = main::r#10 << 2 -- vbuaa=vbum1_rol_2 
    lda r
    asl
    asl
    // [579] main::$170 = main::$169 + main::r#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc r
    // [580] main::$21 = main::$170 << 1 -- vbum1=vbuaa_rol_1 
    asl
    sta __21
    // print_chip_line(3 + r * 10, 45, ' ')
    // [581] print_chip_line::x#0 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [582] call print_chip_line
    // [1071] phi from main::@2 to print_chip_line [phi:main::@2->print_chip_line]
    // [1071] phi print_chip_line::c#10 = ' 'pm [phi:main::@2->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1071] phi print_chip_line::y#9 = $2d [phi:main::@2->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$2d
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#0 [phi:main::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@60
    // print_chip_line(3 + r * 10, 46, 'r')
    // [583] print_chip_line::x#1 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [584] call print_chip_line
    // [1071] phi from main::@60 to print_chip_line [phi:main::@60->print_chip_line]
    // [1071] phi print_chip_line::c#10 = 'r'pm [phi:main::@60->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'r'
    sta.z print_chip_line.c
    // [1071] phi print_chip_line::y#9 = $2e [phi:main::@60->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$2e
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#1 [phi:main::@60->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@61
    // print_chip_line(3 + r * 10, 47, 'o')
    // [585] print_chip_line::x#2 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [586] call print_chip_line
    // [1071] phi from main::@61 to print_chip_line [phi:main::@61->print_chip_line]
    // [1071] phi print_chip_line::c#10 = 'o'pm [phi:main::@61->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'o'
    sta.z print_chip_line.c
    // [1071] phi print_chip_line::y#9 = $2f [phi:main::@61->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$2f
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#2 [phi:main::@61->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@62
    // print_chip_line(3 + r * 10, 48, 'm')
    // [587] print_chip_line::x#3 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [588] call print_chip_line
    // [1071] phi from main::@62 to print_chip_line [phi:main::@62->print_chip_line]
    // [1071] phi print_chip_line::c#10 = 'm'pm [phi:main::@62->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'m'
    sta.z print_chip_line.c
    // [1071] phi print_chip_line::y#9 = $30 [phi:main::@62->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$30
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#3 [phi:main::@62->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@63
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [589] print_chip_line::x#4 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [590] print_chip_line::c#4 = '0'pm + main::r#10 -- vbuz1=vbuc1_plus_vbum2 
    lda #'0'
    clc
    adc r
    sta.z print_chip_line.c
    // [591] call print_chip_line
    // [1071] phi from main::@63 to print_chip_line [phi:main::@63->print_chip_line]
    // [1071] phi print_chip_line::c#10 = print_chip_line::c#4 [phi:main::@63->print_chip_line#0] -- register_copy 
    // [1071] phi print_chip_line::y#9 = $31 [phi:main::@63->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$31
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#4 [phi:main::@63->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@64
    // print_chip_line(3 + r * 10, 50, ' ')
    // [592] print_chip_line::x#5 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [593] call print_chip_line
    // [1071] phi from main::@64 to print_chip_line [phi:main::@64->print_chip_line]
    // [1071] phi print_chip_line::c#10 = ' 'pm [phi:main::@64->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1071] phi print_chip_line::y#9 = $32 [phi:main::@64->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$32
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#5 [phi:main::@64->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@65
    // print_chip_line(3 + r * 10, 51, '5')
    // [594] print_chip_line::x#6 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [595] call print_chip_line
    // [1071] phi from main::@65 to print_chip_line [phi:main::@65->print_chip_line]
    // [1071] phi print_chip_line::c#10 = '5'pm [phi:main::@65->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'5'
    sta.z print_chip_line.c
    // [1071] phi print_chip_line::y#9 = $33 [phi:main::@65->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$33
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#6 [phi:main::@65->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@66
    // print_chip_line(3 + r * 10, 52, '1')
    // [596] print_chip_line::x#7 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [597] call print_chip_line
    // [1071] phi from main::@66 to print_chip_line [phi:main::@66->print_chip_line]
    // [1071] phi print_chip_line::c#10 = '1'pm [phi:main::@66->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'1'
    sta.z print_chip_line.c
    // [1071] phi print_chip_line::y#9 = $34 [phi:main::@66->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$34
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#7 [phi:main::@66->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@67
    // print_chip_line(3 + r * 10, 53, '2')
    // [598] print_chip_line::x#8 = 3 + main::$21 -- vbuxx=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    tax
    // [599] call print_chip_line
    // [1071] phi from main::@67 to print_chip_line [phi:main::@67->print_chip_line]
    // [1071] phi print_chip_line::c#10 = '2'pm [phi:main::@67->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'2'
    sta.z print_chip_line.c
    // [1071] phi print_chip_line::y#9 = $35 [phi:main::@67->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$35
    // [1071] phi print_chip_line::x#9 = print_chip_line::x#8 [phi:main::@67->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@68
    // print_chip_end(3 + r * 10, 54)
    // [600] print_chip_end::x#0 = 3 + main::$21 -- vbuaa=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __21
    // [601] call print_chip_end
    jsr print_chip_end
    // main::@69
    // print_chip_led(r, BLACK, BLUE)
    // [602] print_chip_led::r#0 = main::r#10 -- vbuxx=vbum1 
    ldx r
    // [603] call print_chip_led
    // [942] phi from main::@69 to print_chip_led [phi:main::@69->print_chip_led]
    // [942] phi print_chip_led::tc#10 = BLACK [phi:main::@69->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [942] phi print_chip_led::r#10 = print_chip_led::r#0 [phi:main::@69->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@70
    // for (unsigned char r = 0; r < 8; r++)
    // [604] main::r#1 = ++ main::r#10 -- vbum1=_inc_vbum1 
    inc r
    // [89] phi from main::@70 to main::@1 [phi:main::@70->main::@1]
    // [89] phi main::r#10 = main::r#1 [phi:main::@70->main::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    buffer: .text ""
    .byte 0
    .fill $9f, 0
    rom_device_ids: .byte 0
    .fill 7, 0
    rom_manufacturer_ids: .byte 0
    .fill 7, 0
    s: .text "rom flash utility"
    .byte 0
    s1: .text "press a key to start flashing."
    .byte 0
    s2: .text "resetting commander x16"
    .byte 0
    s3: .text "rom.bin"
    .byte 0
    s4: .text "rom"
    .byte 0
    s5: .text ".bin"
    .byte 0
    s6: .text "reading in ram ..."
    .byte 0
    s7: .text "no file"
    .byte 0
    s8: .text "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error."
    .byte 0
    s9: .text "................"
    .byte 0
    s10: .text "ram = "
    .byte 0
    s11: .text ", "
    .byte 0
    s12: .text ", rom = "
    .byte 0
    s13: .text "the flashing went perfectly ok. press a key to flash the next chip ..."
    .byte 0
    rom_device_1: .text "f010a"
    .byte 0
    rom_device_2: .text "f020a"
    .byte 0
    rom_device_3: .text "f040"
    .byte 0
    rom_device_4: .text "----"
    .byte 0
    pattern: .text "----------------"
    .byte 0
    pattern_1: .text "+"
    .byte 0
    __21: .byte 0
    __67: .byte 0
    .label __100 = rom_size.return
    rom_unlock1_rom_write_byte1_rom_ptr1___2: .word 0
    rom_unlock1_rom_write_byte2_rom_ptr1___2: .word 0
    rom_unlock1_rom_write_byte3_rom_ptr1___2: .word 0
    .label rom_unlock2_rom_write_byte1_rom_bank1___1 = rom_unlock2_rom_write_byte1_rom_bank1___2
    rom_unlock2_rom_write_byte1_rom_bank1___2: .dword 0
    .label rom_unlock2_rom_write_byte1_rom_ptr1___0 = rom_unlock2_rom_write_byte1_address
    rom_unlock2_rom_write_byte1_rom_ptr1___2: .word 0
    .label rom_unlock2_rom_write_byte2_rom_bank1___1 = rom_unlock2_rom_write_byte2_rom_bank1___2
    rom_unlock2_rom_write_byte2_rom_bank1___2: .dword 0
    rom_unlock2_rom_write_byte2_rom_ptr1___0: .dword 0
    rom_unlock2_rom_write_byte2_rom_ptr1___2: .word 0
    .label rom_unlock2_rom_write_byte3_rom_bank1___1 = rom_unlock2_rom_write_byte3_rom_bank1___2
    rom_unlock2_rom_write_byte3_rom_bank1___2: .dword 0
    rom_unlock2_rom_write_byte3_rom_ptr1___0: .dword 0
    rom_unlock2_rom_write_byte3_rom_ptr1___2: .word 0
    rom_address1___1: .dword 0
    .label rom_address2___1 = flash_rom_address_sector
    .label rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___1 = rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___2
    rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_bank1___2: .dword 0
    .label rom_sector_erase1_rom_unlock1_rom_write_byte1_rom_ptr1___0 = rom_sector_erase1_rom_unlock1_rom_write_byte1_address
    .label rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___1 = rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___2
    rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_bank1___2: .dword 0
    .label rom_sector_erase1_rom_unlock1_rom_write_byte2_rom_ptr1___0 = rom_sector_erase1_rom_unlock1_chip_address
    .label rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___1 = rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___2
    rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_bank1___2: .dword 0
    rom_sector_erase1_rom_unlock2_rom_write_byte1_rom_ptr1___0: .dword 0
    .label rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___1 = rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___2
    rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_bank1___2: .dword 0
    .label rom_sector_erase1_rom_unlock2_rom_write_byte2_rom_ptr1___0 = rom_sector_erase1_rom_unlock2_chip_address
    .label rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___1 = rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___2
    rom_sector_erase1_rom_unlock2_rom_write_byte3_rom_bank1___2: .dword 0
    r: .byte 0
    .label rom_unlock1_rom_write_byte1_rom_ptr1_return = rom_unlock1_rom_write_byte1_rom_ptr1___2
    .label rom_unlock1_rom_write_byte2_rom_ptr1_return = rom_unlock1_rom_write_byte2_rom_ptr1___2
    .label rom_unlock1_rom_write_byte3_rom_ptr1_return = rom_unlock1_rom_write_byte3_rom_ptr1___2
    rom_unlock2_address: .dword 0
    rom_unlock2_chip_address: .dword 0
    rom_unlock2_rom_write_byte1_address: .dword 0
    .label rom_unlock2_rom_write_byte1_rom_ptr1_return = rom_unlock2_rom_write_byte1_rom_ptr1___2
    .label rom_unlock2_rom_write_byte2_address = rom_unlock2_chip_address
    .label rom_unlock2_rom_write_byte2_rom_ptr1_return = rom_unlock2_rom_write_byte2_rom_ptr1___2
    .label rom_unlock2_rom_write_byte3_rom_ptr1_return = rom_unlock2_rom_write_byte3_rom_ptr1___2
    rom_chip: .byte 0
    flash_rom_address: .dword 0
    flash_chip: .byte 0
    flash_rom_bank: .byte 0
    fp: .word 0
    .label rom_address1_return = rom_address1___1
    flash_rom_address_boundary: .dword 0
    flash_bytes_1: .dword 0
    flash_rom_address_sector: .dword 0
    flash_verify1_verify_rom_address: .dword 0
    read_ram_address_sector: .word 0
    rom_sector_erase1_rom_unlock1_chip_address: .dword 0
    rom_sector_erase1_rom_unlock1_rom_write_byte1_address: .dword 0
    .label rom_sector_erase1_rom_unlock1_rom_write_byte2_address = rom_sector_erase1_rom_unlock1_chip_address
    rom_sector_erase1_rom_unlock2_chip_address: .dword 0
    rom_sector_erase1_rom_unlock2_rom_write_byte1_address: .dword 0
    .label rom_sector_erase1_rom_unlock2_rom_write_byte2_address = rom_sector_erase1_rom_unlock2_chip_address
    flash_rom_address_boundary1: .dword 0
    flash_write1_rom_chip_address: .dword 0
    read_ram_address: .word 0
    flash_rom_address1: .dword 0
    x_sector: .byte 0
    read_ram_bank_sector: .byte 0
    y_sector: .byte 0
    v: .word 0
    w: .word 0
    rom_device: .word 0
    .label flash_rom_address_boundary_1 = flash_bytes_1
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [605] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuxx=_deref_pbuc1 
    ldx VERA_L1_MAPBASE
    // [606] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [607] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [608] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__register(X) char color)
textcolor: {
    // __conio.color & 0xF0
    // [610] textcolor::$0 = *((char *)&__conio+$b) & $f0 -- vbuaa=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$b
    // __conio.color & 0xF0 | color
    // [611] textcolor::$1 = textcolor::$0 | textcolor::color#22 -- vbuaa=vbuaa_bor_vbuxx 
    stx.z $ff
    ora.z $ff
    // __conio.color = __conio.color & 0xF0 | color
    // [612] *((char *)&__conio+$b) = textcolor::$1 -- _deref_pbuc1=vbuaa 
    sta __conio+$b
    // textcolor::@return
    // }
    // [613] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__register(X) char color)
bgcolor: {
    // __conio.color & 0x0F
    // [615] bgcolor::$0 = *((char *)&__conio+$b) & $f -- vbum1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$b
    sta __0
    // color << 4
    // [616] bgcolor::$1 = bgcolor::color#11 << 4 -- vbuaa=vbuxx_rol_4 
    txa
    asl
    asl
    asl
    asl
    // __conio.color & 0x0F | color << 4
    // [617] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuaa=vbum1_bor_vbuaa 
    ora __0
    // __conio.color = __conio.color & 0x0F | color << 4
    // [618] *((char *)&__conio+$b) = bgcolor::$2 -- _deref_pbuc1=vbuaa 
    sta __conio+$b
    // bgcolor::@return
    // }
    // [619] return 
    rts
  .segment Data
    __0: .byte 0
}
.segment Code
  // cursor
// If onoff is 1, a cursor is displayed when waiting for keyboard input.
// If onoff is 0, the cursor is hidden when waiting for keyboard input.
// The function returns the old cursor setting.
// char cursor(char onoff)
cursor: {
    .const onoff = 0
    // __conio.cursor = onoff
    // [620] *((char *)&__conio+$a) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$a
    // cursor::@return
    // }
    // [621] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [622] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [623] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [625] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [626] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    return: .word 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__register(X) char x, __register(Y) char y)
gotoxy: {
    .label __9 = $4e
    // (x>=__conio.width)?__conio.width:x
    // [628] if(gotoxy::x#22>=*((char *)&__conio+4)) goto gotoxy::@1 -- vbuxx_ge__deref_pbuc1_then_la1 
    cpx __conio+4
    bcs __b1
    // [630] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [630] phi gotoxy::$3 = gotoxy::x#22 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [629] gotoxy::$2 = *((char *)&__conio+4) -- vbuxx=_deref_pbuc1 
    ldx __conio+4
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [631] *((char *)&__conio+$d) = gotoxy::$3 -- _deref_pbuc1=vbuxx 
    stx __conio+$d
    // (y>=__conio.height)?__conio.height:y
    // [632] if(gotoxy::y#22>=*((char *)&__conio+5)) goto gotoxy::@3 -- vbuyy_ge__deref_pbuc1_then_la1 
    cpy __conio+5
    bcs __b3
    // gotoxy::@4
    // [633] gotoxy::$14 = gotoxy::y#22 -- vbuaa=vbuyy 
    tya
    // [634] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [634] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [635] *((char *)&__conio+$e) = gotoxy::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+$e
    // __conio.cursor_x << 1
    // [636] gotoxy::$8 = *((char *)&__conio+$d) << 1 -- vbuxx=_deref_pbuc1_rol_1 
    lda __conio+$d
    asl
    tax
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [637] gotoxy::$10 = gotoxy::y#22 << 1 -- vbuaa=vbuyy_rol_1 
    tya
    asl
    // [638] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuaa_plus_vbuxx 
    tay
    txa
    clc
    adc __conio+$15,y
    sta.z __9
    lda __conio+$15+1,y
    adc #0
    sta.z __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [639] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z __9
    sta __conio+$13
    lda.z __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [640] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [641] gotoxy::$6 = *((char *)&__conio+5) -- vbuaa=_deref_pbuc1 
    lda __conio+5
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    // __conio.cursor_x = 0
    // [642] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y++;
    // [643] *((char *)&__conio+$e) = ++ *((char *)&__conio+$e) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$e
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [644] cputln::$2 = *((char *)&__conio+$e) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    // [645] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [646] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [647] return 
    rts
}
  // cbm_x_charset
/**
 * @brief Sets the [character set](https://github.com/commanderx16/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-screen_set_charset).
 * 
 * @param charset The code of the charset to copy.
 * @param offset The offset of the character set in ram.
 */
// void cbm_x_charset(__mem() volatile char charset, __mem() char * volatile offset)
cbm_x_charset: {
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_CHRSET  }
    lda charset
    ldx.z <offset
    ldy.z >offset
    jsr CX16_CHRSET
    // cbm_x_charset::@return
    // }
    // [649] return 
    rts
  .segment Data
    charset: .byte 0
    offset: .word 0
}
.segment Code
  // scroll
// If onoff is 1, scrolling is enabled when outputting past the end of the screen
// If onoff is 0, scrolling is disabled and the cursor instead moves to (0,0)
// The function returns the old scroll setting.
// char scroll(char onoff)
scroll: {
    .const onoff = 0
    // __conio.scroll[__conio.layer] = onoff
    // [650] ((char *)&__conio+$f)[*((char *)&__conio)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio
    sta __conio+$f,y
    // scroll::@return
    // }
    // [651] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label line_text = $4a
    .label ch = $4a
    // unsigned int line_text = __conio.mapbase_offset
    // [652] clrscr::line_text#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z line_text
    lda __conio+1+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [653] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [654] clrscr::$0 = *((char *)&__conio+3) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [655] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [656] clrscr::l#0 = *((char *)&__conio+7) -- vbuyy=_deref_pbuc1 
    ldy __conio+7
    // [657] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [657] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [657] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [658] clrscr::$1 = byte0  clrscr::ch#0 -- vbuaa=_byte0_vwuz1 
    lda.z ch
    // *VERA_ADDRX_L = BYTE0(ch)
    // [659] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuaa 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [660] clrscr::$2 = byte1  clrscr::ch#0 -- vbuaa=_byte1_vwuz1 
    lda.z ch+1
    // *VERA_ADDRX_M = BYTE1(ch)
    // [661] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [662] clrscr::c#0 = *((char *)&__conio+6) -- vbuxx=_deref_pbuc1 
    ldx __conio+6
    // [663] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [663] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [664] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [665] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [666] clrscr::c#1 = -- clrscr::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [667] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [668] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+8
    sta.z line_text
    lda.z line_text+1
    adc __conio+8+1
    sta.z line_text+1
    // l--;
    // [669] clrscr::l#1 = -- clrscr::l#4 -- vbuyy=_dec_vbuyy 
    dey
    // while(l)
    // [670] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [671] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y = 0
    // [672] *((char *)&__conio+$e) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+$e
    // __conio.offset = __conio.mapbase_offset
    // [673] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+1) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+1
    sta __conio+$13
    lda __conio+1+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [674] return 
    rts
}
  // frame_draw
frame_draw: {
    .label x = $42
    .label x1 = $50
    .label y = $bd
    .label x2 = $2f
    .label y_1 = $4c
    .label x3 = $44
    .label y_2 = $47
    .label x4 = $de
    .label y_3 = $52
    .label x5 = $df
    // textcolor(WHITE)
    // [676] call textcolor
    // [609] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:frame_draw->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [677] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [678] call bgcolor
    // [614] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [679] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [680] call clrscr
    jsr clrscr
    // [681] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [681] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [682] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [683] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [684] call cputcxy
    // [1175] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [1175] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbuyy=vbuc1 
    ldy #0
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // [685] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [686] call cputcxy
    // [1175] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [1175] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbuyy=vbuc1 
    ldy #0
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // [687] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [688] call cputcxy
    // [1175] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbuyy=vbuc1 
    ldy #1
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // [689] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [690] call cputcxy
    // [1175] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbuyy=vbuc1 
    ldy #1
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // [691] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [691] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [692] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [693] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [694] call cputcxy
    // [1175] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [1175] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbuyy=vbuc1 
    ldy #2
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // [695] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [696] call cputcxy
    // [1175] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [1175] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbuyy=vbuc1 
    ldy #2
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // [697] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [698] call cputcxy
    // [1175] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [1175] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbuyy=vbuc1 
    ldy #2
    // [1175] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$c
    jsr cputcxy
    // [699] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [699] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbuz1=vbuc1 
    lda #3
    sta.z y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [700] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [701] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [701] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [702] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [703] cputcxy::y#13 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [704] call cputcxy
    // [1175] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [1175] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [705] cputcxy::y#14 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [706] call cputcxy
    // [1175] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [1175] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [707] cputcxy::y#15 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [708] call cputcxy
    // [1175] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [1175] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$c
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [709] frame_draw::y#5 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [710] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [710] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [711] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [712] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [712] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [713] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [714] cputcxy::y#19 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [715] call cputcxy
    // [1175] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [1175] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [716] cputcxy::y#20 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [717] call cputcxy
    // [1175] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [1175] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [718] cputcxy::y#21 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [719] call cputcxy
    // [1175] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [1175] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [720] cputcxy::y#22 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [721] call cputcxy
    // [1175] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [1175] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [722] cputcxy::y#23 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [723] call cputcxy
    // [1175] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [1175] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [724] cputcxy::y#24 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [725] call cputcxy
    // [1175] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [1175] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [726] cputcxy::y#25 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [727] call cputcxy
    // [1175] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [1175] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [728] cputcxy::y#26 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [729] call cputcxy
    // [1175] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [1175] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [730] cputcxy::y#27 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [731] call cputcxy
    // [1175] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [1175] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [732] cputcxy::y#28 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [733] call cputcxy
    // [1175] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [1175] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [734] frame_draw::y#7 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz2 
    lda.z y_1
    inc
    sta.z y_2
    // [735] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [735] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [736] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [737] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [737] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [738] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [739] cputcxy::y#39 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [740] call cputcxy
    // [1175] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [1175] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [741] cputcxy::y#40 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [742] call cputcxy
    // [1175] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [1175] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [743] cputcxy::y#41 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [744] call cputcxy
    // [1175] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [1175] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [745] cputcxy::y#42 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [746] call cputcxy
    // [1175] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [1175] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [747] cputcxy::y#43 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [748] call cputcxy
    // [1175] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [1175] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [749] cputcxy::y#44 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [750] call cputcxy
    // [1175] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [1175] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [751] cputcxy::y#45 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [752] call cputcxy
    // [1175] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [1175] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [753] cputcxy::y#46 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [754] call cputcxy
    // [1175] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [1175] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [755] cputcxy::y#47 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [756] call cputcxy
    // [1175] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [1175] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [757] frame_draw::y#9 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz2 
    lda.z y_2
    inc
    sta.z y_3
    // [758] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [758] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [759] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [760] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [760] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [761] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x5
    cmp #$4f
    bcc __b25
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [762] cputcxy::y#58 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [763] call cputcxy
    // [1175] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [1175] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [764] cputcxy::y#59 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [765] call cputcxy
    // [1175] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [1175] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [766] cputcxy::y#60 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [767] call cputcxy
    // [1175] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [1175] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [768] cputcxy::y#61 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [769] call cputcxy
    // [1175] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [1175] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [770] cputcxy::y#62 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [771] call cputcxy
    // [1175] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [1175] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [772] cputcxy::y#63 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [773] call cputcxy
    // [1175] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [1175] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [774] cputcxy::y#64 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [775] call cputcxy
    // [1175] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [1175] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [776] cputcxy::y#65 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [777] call cputcxy
    // [1175] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [1175] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [778] cputcxy::y#66 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [779] call cputcxy
    // [1175] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [1175] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [780] cputcxy::y#67 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [781] call cputcxy
    // [1175] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [1175] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@return
    // }
    // [782] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [783] cputcxy::x#57 = frame_draw::x5#2 -- vbuxx=vbuz1 
    ldx.z x5
    // [784] cputcxy::y#57 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [785] call cputcxy
    // [1175] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [1175] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [786] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbuz1=_inc_vbuz1 
    inc.z x5
    // [760] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [760] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [787] cputcxy::y#48 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [788] call cputcxy
    // [1175] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [789] cputcxy::y#49 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [790] call cputcxy
    // [1175] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [791] cputcxy::y#50 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [792] call cputcxy
    // [1175] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [793] cputcxy::y#51 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [794] call cputcxy
    // [1175] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [795] cputcxy::y#52 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [796] call cputcxy
    // [1175] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [797] cputcxy::y#53 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [798] call cputcxy
    // [1175] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [799] cputcxy::y#54 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [800] call cputcxy
    // [1175] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [801] cputcxy::y#55 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [802] call cputcxy
    // [1175] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [803] cputcxy::y#56 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [804] call cputcxy
    // [1175] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [805] frame_draw::y#10 = ++ frame_draw::y#106 -- vbuz1=_inc_vbuz1 
    inc.z y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [806] cputcxy::x#38 = frame_draw::x4#2 -- vbuxx=vbuz1 
    ldx.z x4
    // [807] cputcxy::y#38 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [808] call cputcxy
    // [1175] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [1175] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [809] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbuz1=_inc_vbuz1 
    inc.z x4
    // [737] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [737] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [810] cputcxy::y#29 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [811] call cputcxy
    // [1175] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [812] cputcxy::y#30 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [813] call cputcxy
    // [1175] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [814] cputcxy::y#31 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [815] call cputcxy
    // [1175] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [816] cputcxy::y#32 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [817] call cputcxy
    // [1175] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [818] cputcxy::y#33 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [819] call cputcxy
    // [1175] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [820] cputcxy::y#34 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [821] call cputcxy
    // [1175] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [822] cputcxy::y#35 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [823] call cputcxy
    // [1175] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [824] cputcxy::y#36 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [825] call cputcxy
    // [1175] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [826] cputcxy::y#37 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [827] call cputcxy
    // [1175] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [828] frame_draw::y#8 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz1 
    inc.z y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [829] cputcxy::x#18 = frame_draw::x3#2 -- vbuxx=vbuz1 
    ldx.z x3
    // [830] cputcxy::y#18 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [831] call cputcxy
    // [1175] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [1175] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [832] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbuz1=_inc_vbuz1 
    inc.z x3
    // [712] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [712] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [833] cputcxy::y#16 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [834] call cputcxy
    // [1175] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [835] cputcxy::y#17 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [836] call cputcxy
    // [1175] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [837] frame_draw::y#6 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [838] cputcxy::x#12 = frame_draw::x2#2 -- vbuxx=vbuz1 
    ldx.z x2
    // [839] cputcxy::y#12 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [840] call cputcxy
    // [1175] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [1175] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [841] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbuz1=_inc_vbuz1 
    inc.z x2
    // [701] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [701] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [842] cputcxy::y#9 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [843] call cputcxy
    // [1175] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [844] cputcxy::y#10 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [845] call cputcxy
    // [1175] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$c
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [846] cputcxy::y#11 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [847] call cputcxy
    // [1175] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [1175] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [1175] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [848] frame_draw::y#4 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [699] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [699] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [849] cputcxy::x#5 = frame_draw::x1#2 -- vbuxx=vbuz1 
    ldx.z x1
    // [850] call cputcxy
    // [1175] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [1175] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbuyy=vbuc1 
    ldy #2
    // [1175] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [851] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbuz1=_inc_vbuz1 
    inc.z x1
    // [691] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [691] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [852] cputcxy::x#0 = frame_draw::x#2 -- vbuxx=vbuz1 
    ldx.z x
    // [853] call cputcxy
    // [1175] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [1175] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1175] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbuyy=vbuc1 
    ldy #0
    // [1175] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [854] frame_draw::x#1 = ++ frame_draw::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [681] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [681] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
    jmp __b1
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($4a) void (*putc)(char), __zp($3b) const char *s)
printf_str: {
    .label s = $3b
    .label putc = $4a
    // [856] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [856] phi printf_str::s#19 = printf_str::s#20 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [857] printf_str::c#1 = *printf_str::s#19 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [858] printf_str::s#0 = ++ printf_str::s#19 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [859] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // printf_str::@return
    // }
    // [860] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [861] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [862] callexecute *printf_str::putc#20  -- call__deref_pprz1 
    jsr icall9
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall9:
    jmp (putc)
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [864] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [865] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [866] __snprintf_buffer = main::buffer -- pbum1=pbuc1 
    lda #<main.buffer
    sta __snprintf_buffer
    lda #>main.buffer
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [867] return 
    rts
}
  // print_text
// void print_text(char *text)
print_text: {
    // textcolor(WHITE)
    // [869] call textcolor
    // [609] phi from print_text to textcolor [phi:print_text->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:print_text->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [870] phi from print_text to print_text::@1 [phi:print_text->print_text::@1]
    // print_text::@1
    // gotoxy(2, 39)
    // [871] call gotoxy
    // [627] phi from print_text::@1 to gotoxy [phi:print_text::@1->gotoxy]
    // [627] phi gotoxy::y#22 = $27 [phi:print_text::@1->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$27
    // [627] phi gotoxy::x#22 = 2 [phi:print_text::@1->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // [872] phi from print_text::@1 to print_text::@2 [phi:print_text::@1->print_text::@2]
    // print_text::@2
    // printf("%-76s", text)
    // [873] call printf_string
    // [985] phi from print_text::@2 to printf_string [phi:print_text::@2->printf_string]
    // [985] phi printf_string::str#10 = main::buffer [phi:print_text::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z printf_string.str
    lda #>main.buffer
    sta.z printf_string.str+1
    // [985] phi printf_string::format_justify_left#10 = 1 [phi:print_text::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [985] phi printf_string::format_min_length#6 = $4c [phi:print_text::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #$4c
    sta.z printf_string.format_min_length
    jsr printf_string
    // print_text::@return
    // }
    // [874] return 
    rts
}
  // wait_key
// Some addressing constants.
// The different device IDs that can be returned from the manufacturer ID read sequence.
// To print the graphics on the vera.
wait_key: {
    .const bank_set_bram1_bank = 0
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [876] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [877] phi from wait_key::bank_set_bram1 to wait_key::@2 [phi:wait_key::bank_set_bram1->wait_key::@2]
    // wait_key::@2
    // bank_set_brom(4)
    // [878] call bank_set_brom
    // [891] phi from wait_key::@2 to bank_set_brom [phi:wait_key::@2->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = 4 [phi:wait_key::@2->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // [879] phi from wait_key::@2 wait_key::@3 to wait_key::@1 [phi:wait_key::@2/wait_key::@3->wait_key::@1]
    // wait_key::@1
  __b1:
    // getin()
    // [880] call getin
    jsr getin
    // [881] getin::return#2 = getin::return#1
    // wait_key::@3
    // [882] wait_key::return#0 = getin::return#2
    // while (!(ch = getin()))
    // [883] if(0==wait_key::return#0) goto wait_key::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // wait_key::@return
    // }
    // [884] return 
    rts
}
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [886] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [887] phi from system_reset::bank_set_bram1 to system_reset::@1 [phi:system_reset::bank_set_bram1->system_reset::@1]
    // system_reset::@1
    // bank_set_brom(0)
    // [888] call bank_set_brom
    // [891] phi from system_reset::@1 to bank_set_brom [phi:system_reset::@1->bank_set_brom]
    // [891] phi bank_set_brom::bank#24 = 0 [phi:system_reset::@1->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #0
    jsr bank_set_brom
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [890] return 
}
  // bank_set_brom
/**
 * @brief Set the active banked rom on the X16.
 *
 * There are several banked roms available between 0xC000 and 0xFFFF.
 *
 * Bank	Name	Description
 * 0	KERNAL	character sets (uploaded into VRAM), MONITOR, KERNAL
 * 1	KEYBD	Keyboard layout tables
 * 2	CBDOS	The computer-based CBM-DOS for FAT32 SD cards
 * 3	GEOS	GEOS KERNAL
 * 4	BASIC	BASIC interpreter
 * 5	MONITOR	Machine Language Monitor
 *
 * Detailed documentation in the CX16 programmers reference:
 * https://github.com/commanderx16/x16-docs/blob/master/Commander%20X16%20Programmer's%20Reference%20Guide.md
 *
 * Note: This method will change when R39 is released,
 * as the bank is modified using zero page 0x01, instead of the VIA.
 *
 * @param bank Switch to this bank.
 */
// void bank_set_brom(__register(A) char bank)
bank_set_brom: {
    // BROM = bank
    // [892] BROM = bank_set_brom::bank#24 -- vbuz1=vbuaa 
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [893] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($64) void (*putc)(char), __register(X) char uvalue, __zp($42) char format_min_length, char format_justify_left, char format_sign_always, __zp($50) char format_zero_padding, char format_upper_case, __register(Y) char format_radix)
printf_uchar: {
    .label putc = $64
    .label format_min_length = $42
    .label format_zero_padding = $50
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [895] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [896] uctoa::value#1 = printf_uchar::uvalue#4
    // [897] uctoa::radix#0 = printf_uchar::format_radix#4
    // [898] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [899] printf_number_buffer::putc#2 = printf_uchar::putc#4
    // [900] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [901] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#4 -- vbuxx=vbuz1 
    ldx.z format_min_length
    // [902] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#4
    // [903] call printf_number_buffer
  // Print using format
    // [1216] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1216] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1216] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1216] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1216] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [1216] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [1216] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [904] return 
    rts
}
  // fopen
/**
 * @brief Load a file to banked ram located between address 0xA000 and 0xBFFF incrementing the banks.
 *
 * @param channel Input channel.
 * @param device Input device.
 * @param secondary Secondary channel.
 * @param filename Name of the file to be loaded.
 * @return 
 *  - 0x0000: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - other: OK! The last pointer between 0xA000 and 0xBFFF is returned. Note that the last pointer is indicating the first free byte.
 */
// __zp($4a) struct $1 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label fp = $4a
    .label return = $4a
    // FILE *fp = &__files[__filecount]
    // [905] fopen::$32 = __filecount << 2 -- vbuaa=vbum1_rol_2 
    lda __filecount
    asl
    asl
    // [906] fopen::$33 = fopen::$32 + __filecount -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc __filecount
    // [907] fopen::$11 = fopen::$33 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [908] fopen::fp#0 = __files + fopen::$11 -- pssz1=pssc1_plus_vbuaa 
    clc
    adc #<__files
    sta.z fp
    lda #>__files
    adc #0
    sta.z fp+1
    // fp->status = 0
    // [909] ((char *)fopen::fp#0)[$13] = 0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #0
    ldy #$13
    sta (fp),y
    // fp->channel = channel
    // [910] ((char *)fopen::fp#0)[$10] = fopen::channel#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #channel
    ldy #$10
    sta (fp),y
    // fp->device = device
    // [911] ((char *)fopen::fp#0)[$11] = fopen::device#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #device
    ldy #$11
    sta (fp),y
    // fp->secondary = secondary
    // [912] ((char *)fopen::fp#0)[$12] = fopen::secondary#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #secondary
    ldy #$12
    sta (fp),y
    // strncpy(fp->filename, filename, 16)
    // [913] strncpy::dst#1 = (char *)fopen::fp#0 -- pbuz1=pbuz2 
    lda.z fp
    sta.z strncpy.dst
    lda.z fp+1
    sta.z strncpy.dst+1
    // [914] call strncpy
    // [1257] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@5
    // cbm_k_setnam(filename)
    // [915] cbm_k_setnam::filename = main::buffer -- pbum1=pbuc1 
    lda #<main.buffer
    sta cbm_k_setnam.filename
    lda #>main.buffer
    sta cbm_k_setnam.filename+1
    // [916] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@6
    // cbm_k_setlfs(channel, device, secondary)
    // [917] cbm_k_setlfs::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_setlfs.channel
    // [918] cbm_k_setlfs::device = fopen::device#0 -- vbum1=vbuc1 
    lda #device
    sta cbm_k_setlfs.device
    // [919] cbm_k_setlfs::command = fopen::secondary#0 -- vbum1=vbuc1 
    lda #secondary
    sta cbm_k_setlfs.command
    // [920] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [921] phi from fopen::@6 to fopen::@7 [phi:fopen::@6->fopen::@7]
    // fopen::@7
    // cbm_k_open()
    // [922] call cbm_k_open
    jsr cbm_k_open
    // [923] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@8
    // [924] fopen::$4 = cbm_k_open::return#2
    // fp->status = cbm_k_open()
    // [925] ((char *)fopen::fp#0)[$13] = fopen::$4 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [926] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // fopen::@3
    // cbm_k_close(channel)
    // [927] cbm_k_close::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_close.channel
    // [928] call cbm_k_close
    jsr cbm_k_close
    // [929] phi from fopen::@3 fopen::@4 to fopen::@return [phi:fopen::@3/fopen::@4->fopen::@return]
  __b3:
    // [929] phi fopen::return#1 = 0 [phi:fopen::@3/fopen::@4->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [930] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [931] cbm_k_chkin::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_chkin.channel
    // [932] call cbm_k_chkin
    jsr cbm_k_chkin
    // [933] phi from fopen::@1 to fopen::@9 [phi:fopen::@1->fopen::@9]
    // fopen::@9
    // cbm_k_readst()
    // [934] call cbm_k_readst
    jsr cbm_k_readst
    // [935] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@10
    // [936] fopen::$7 = cbm_k_readst::return#2
    // fp->status = cbm_k_readst()
    // [937] ((char *)fopen::fp#0)[$13] = fopen::$7 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [938] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@2 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b2
    // fopen::@4
    // cbm_k_close(channel)
    // [939] cbm_k_close::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_close.channel
    // [940] call cbm_k_close
    jsr cbm_k_close
    jmp __b3
    // fopen::@2
  __b2:
    // __filecount++;
    // [941] __filecount = ++ __filecount -- vbum1=_inc_vbum1 
    inc __filecount
    // [929] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [929] phi fopen::return#1 = fopen::fp#0 [phi:fopen::@2->fopen::@return#0] -- register_copy 
    rts
}
  // print_chip_led
// void print_chip_led(__register(X) char r, __zp($51) char tc, char bc)
print_chip_led: {
    .label tc = $51
    // r * 10
    // [943] print_chip_led::$8 = print_chip_led::r#10 << 2 -- vbuaa=vbuxx_rol_2 
    txa
    asl
    asl
    // [944] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#10 -- vbuaa=vbuaa_plus_vbuxx 
    stx.z $ff
    clc
    adc.z $ff
    // [945] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(4 + r * 10, 43)
    // [946] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbuxx=vbuc1_plus_vbuaa 
    clc
    adc #4
    tax
    // [947] call gotoxy
    // [627] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [627] phi gotoxy::y#22 = $2b [phi:print_chip_led->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$2b
    // [627] phi gotoxy::x#22 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [948] textcolor::color#7 = print_chip_led::tc#10 -- vbuxx=vbuz1 
    ldx.z tc
    // [949] call textcolor
    // [609] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [609] phi textcolor::color#22 = textcolor::color#7 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [950] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [951] call bgcolor
    // [614] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [952] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [953] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [955] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [956] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [958] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [959] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [961] return 
    rts
}
  // table_chip_clear
// void table_chip_clear(__zp($eb) char rom_bank)
table_chip_clear: {
    .label rom_address1___1 = $25
    .label rom_address1_return = $25
    .label rom_bank = $eb
    .label y = $43
    // textcolor(WHITE)
    // [963] call textcolor
    // [609] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:table_chip_clear->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [964] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [965] call bgcolor
    // [614] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [966] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [966] phi table_chip_clear::rom_bank#10 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [966] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [967] if(table_chip_clear::y#10<$24) goto table_chip_clear::rom_address1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$24
    bcc rom_address1
    // table_chip_clear::@return
    // }
    // [968] return 
    rts
    // table_chip_clear::rom_address1
  rom_address1:
    // ((unsigned long)(rom_bank)) << 14
    // [969] table_chip_clear::rom_address1_$1 = (unsigned long)table_chip_clear::rom_bank#10 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address1___1
    lda #0
    sta.z rom_address1___1+1
    sta.z rom_address1___1+2
    sta.z rom_address1___1+3
    // [970] table_chip_clear::rom_address1_return#0 = table_chip_clear::rom_address1_$1 << $e -- vduz1=vduz1_rol_vbuc1 
    ldx #$e
    cpx #0
    beq !e+
  !:
    asl.z rom_address1_return
    rol.z rom_address1_return+1
    rol.z rom_address1_return+2
    rol.z rom_address1_return+3
    dex
    bne !-
  !e:
    // table_chip_clear::@2
    // gotoxy(2, y)
    // [971] gotoxy::y#8 = table_chip_clear::y#10 -- vbuyy=vbuz1 
    ldy.z y
    // [972] call gotoxy
    // [627] phi from table_chip_clear::@2 to gotoxy [phi:table_chip_clear::@2->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#8 [phi:table_chip_clear::@2->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = 2 [phi:table_chip_clear::@2->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // table_chip_clear::@4
    // printf("%02x", rom_bank)
    // [973] printf_uchar::uvalue#0 = table_chip_clear::rom_bank#10 -- vbuxx=vbuz1 
    ldx.z rom_bank
    // [974] call printf_uchar
    // [894] phi from table_chip_clear::@4 to printf_uchar [phi:table_chip_clear::@4->printf_uchar]
    // [894] phi printf_uchar::format_zero_padding#4 = 1 [phi:table_chip_clear::@4->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [894] phi printf_uchar::format_min_length#4 = 2 [phi:table_chip_clear::@4->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [894] phi printf_uchar::putc#4 = &cputc [phi:table_chip_clear::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [894] phi printf_uchar::format_radix#4 = HEXADECIMAL [phi:table_chip_clear::@4->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [894] phi printf_uchar::uvalue#4 = printf_uchar::uvalue#0 [phi:table_chip_clear::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@5
    // gotoxy(5, y)
    // [975] gotoxy::y#9 = table_chip_clear::y#10 -- vbuyy=vbuz1 
    ldy.z y
    // [976] call gotoxy
    // [627] phi from table_chip_clear::@5 to gotoxy [phi:table_chip_clear::@5->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#9 [phi:table_chip_clear::@5->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = 5 [phi:table_chip_clear::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #5
    jsr gotoxy
    // table_chip_clear::@6
    // printf("%06x", flash_rom_address)
    // [977] printf_ulong::uvalue#0 = table_chip_clear::rom_address1_return#0
    // [978] call printf_ulong
    // [1063] phi from table_chip_clear::@6 to printf_ulong [phi:table_chip_clear::@6->printf_ulong]
    // [1063] phi printf_ulong::format_zero_padding#2 = 1 [phi:table_chip_clear::@6->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1063] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:table_chip_clear::@6->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // table_chip_clear::@7
    // gotoxy(14, y)
    // [979] gotoxy::y#10 = table_chip_clear::y#10 -- vbuyy=vbuz1 
    ldy.z y
    // [980] call gotoxy
    // [627] phi from table_chip_clear::@7 to gotoxy [phi:table_chip_clear::@7->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#10 [phi:table_chip_clear::@7->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = $e [phi:table_chip_clear::@7->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$e
    jsr gotoxy
    // [981] phi from table_chip_clear::@7 to table_chip_clear::@8 [phi:table_chip_clear::@7->table_chip_clear::@8]
    // table_chip_clear::@8
    // printf("%64s", " ")
    // [982] call printf_string
    // [985] phi from table_chip_clear::@8 to printf_string [phi:table_chip_clear::@8->printf_string]
    // [985] phi printf_string::str#10 = table_chip_clear::str [phi:table_chip_clear::@8->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [985] phi printf_string::format_justify_left#10 = 0 [phi:table_chip_clear::@8->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [985] phi printf_string::format_min_length#6 = $40 [phi:table_chip_clear::@8->printf_string#2] -- vbuz1=vbuc1 
    lda #$40
    sta.z printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@9
    // rom_bank++;
    // [983] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [984] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [966] phi from table_chip_clear::@9 to table_chip_clear::@1 [phi:table_chip_clear::@9->table_chip_clear::@1]
    // [966] phi table_chip_clear::rom_bank#10 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@9->table_chip_clear::@1#0] -- register_copy 
    // [966] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@9->table_chip_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    str: .text " "
    .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($3b) char *str, __zp($bd) char format_min_length, __zp($2f) char format_justify_left)
printf_string: {
    .label __9 = $23
    .label padding = $bd
    .label str = $3b
    .label format_min_length = $bd
    .label format_justify_left = $2f
    // if(format.min_length)
    // [986] if(0==printf_string::format_min_length#6) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [987] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [988] call strlen
    // [1295] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1295] phi strlen::str#6 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [989] strlen::return#4 = strlen::len#2
    // printf_string::@6
    // [990] printf_string::$9 = strlen::return#4
    // signed char len = (signed char)strlen(str)
    // [991] printf_string::len#0 = (signed char)printf_string::$9 -- vbsaa=_sbyte_vwuz1 
    lda.z __9
    // padding = (signed char)format.min_length  - len
    // [992] printf_string::padding#1 = (signed char)printf_string::format_min_length#6 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsaa 
    eor #$ff
    sec
    adc.z padding
    sta.z padding
    // if(padding<0)
    // [993] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [995] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [995] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [994] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [995] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [995] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [996] if(0!=printf_string::format_justify_left#10) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [997] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [998] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [999] call printf_padding
    // [1301] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1301] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1301] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1301] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1000] printf_str::s#2 = printf_string::str#10
    // [1001] call printf_str
    // [855] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [855] phi printf_str::putc#20 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [855] phi printf_str::s#20 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1002] if(0==printf_string::format_justify_left#10) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [1003] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1004] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1005] call printf_padding
    // [1301] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1301] phi printf_padding::putc#7 = &cputc [phi:printf_string::@5->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1301] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1301] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1006] return 
    rts
}
  // flash_read
// __zp($d6) unsigned long flash_read(__zp($3b) struct $1 *fp, __zp($64) char *flash_ram_address, __zp($45) char rom_bank_start, __register(X) char rom_bank_size)
flash_read: {
    .label __4 = $ad
    .label __13 = $b1
    .label rom_address1___1 = $2b
    .label rom_address1_return = $da
    .label read_bytes = $36
    .label rom_bank_start = $45
    .label return = $d6
    .label flash_ram_address = $64
    .label flash_rom_address = $da
    .label flash_bytes = $d6
    .label fp = $3b
    // flash_read::rom_address1
    // ((unsigned long)(rom_bank)) << 14
    // [1008] flash_read::rom_address1_$1 = (unsigned long)flash_read::rom_bank_start#11 -- vduz1=_dword_vbuz2 
    lda.z rom_bank_start
    sta.z rom_address1___1
    lda #0
    sta.z rom_address1___1+1
    sta.z rom_address1___1+2
    sta.z rom_address1___1+3
    // [1009] flash_read::rom_address1_return#0 = flash_read::rom_address1_$1 << $e -- vduz1=vduz2_rol_vbuc1 
    ldy #$e
    lda.z rom_address1___1
    sta.z rom_address1_return
    lda.z rom_address1___1+1
    sta.z rom_address1_return+1
    lda.z rom_address1___1+2
    sta.z rom_address1_return+2
    lda.z rom_address1___1+3
    sta.z rom_address1_return+3
    cpy #0
    beq !e+
  !:
    asl.z rom_address1_return
    rol.z rom_address1_return+1
    rol.z rom_address1_return+2
    rol.z rom_address1_return+3
    dey
    bne !-
  !e:
    // flash_read::@9
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [1010] rom_size::rom_banks#0 = flash_read::rom_bank_size#2 -- vbuaa=vbuxx 
    txa
    // [1011] call rom_size
    // [1041] phi from flash_read::@9 to rom_size [phi:flash_read::@9->rom_size]
    // [1041] phi rom_size::rom_banks#2 = rom_size::rom_banks#0 [phi:flash_read::@9->rom_size#0] -- register_copy 
    jsr rom_size
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [1012] rom_size::return#2 = rom_size::return#0
    // flash_read::@10
    // [1013] flash_read::flash_size#0 = rom_size::return#2
    // textcolor(WHITE)
    // [1014] call textcolor
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [609] phi from flash_read::@10 to textcolor [phi:flash_read::@10->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:flash_read::@10->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1015] phi from flash_read::@10 to flash_read::@1 [phi:flash_read::@10->flash_read::@1]
    // [1015] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@10->flash_read::@1#0] -- register_copy 
    // [1015] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@10->flash_read::@1#1] -- register_copy 
    // [1015] phi flash_read::flash_rom_address#10 = flash_read::rom_address1_return#0 [phi:flash_read::@10->flash_read::@1#2] -- register_copy 
    // [1015] phi flash_read::return#2 = 0 [phi:flash_read::@10->flash_read::@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // [1015] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [1015] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [1015] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [1015] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [1015] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < flash_size)
    // [1016] if(flash_read::return#2<flash_read::flash_size#0) goto flash_read::@2 -- vduz1_lt_vdum2_then_la1 
    lda.z return+3
    cmp flash_size+3
    bcc __b2
    bne !+
    lda.z return+2
    cmp flash_size+2
    bcc __b2
    bne !+
    lda.z return+1
    cmp flash_size+1
    bcc __b2
    bne !+
    lda.z return
    cmp flash_size
    bcc __b2
  !:
    // flash_read::@return
    // }
    // [1017] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [1018] flash_read::$4 = flash_read::flash_rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address
    and #<$4000-1
    sta.z __4
    lda.z flash_rom_address+1
    and #>$4000-1
    sta.z __4+1
    lda.z flash_rom_address+2
    and #<$4000-1>>$10
    sta.z __4+2
    lda.z flash_rom_address+3
    and #>$4000-1>>$10
    sta.z __4+3
    // if (!(flash_rom_address % 0x04000))
    // [1019] if(0!=flash_read::$4) goto flash_read::@3 -- 0_neq_vduz1_then_la1 
    lda.z __4
    ora.z __4+1
    ora.z __4+2
    ora.z __4+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [1020] flash_read::$7 = flash_read::rom_bank_start#4 & $20-1 -- vbuaa=vbuz1_band_vbuc1 
    lda #$20-1
    and.z rom_bank_start
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [1021] gotoxy::y#7 = 4 + flash_read::$7 -- vbuyy=vbuc1_plus_vbuaa 
    clc
    adc #4
    tay
    // [1022] call gotoxy
    // [627] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#7 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = $e [phi:flash_read::@6->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$e
    jsr gotoxy
    // flash_read::@12
    // rom_bank_start++;
    // [1023] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank_start
    // [1024] phi from flash_read::@12 flash_read::@2 to flash_read::@3 [phi:flash_read::@12/flash_read::@2->flash_read::@3]
    // [1024] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@12/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [1025] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [1026] fgets::fp#0 = flash_read::fp#10 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [1027] call fgets
    jsr fgets
    // [1028] fgets::return#5 = fgets::return#1
    // flash_read::@11
    // [1029] flash_read::read_bytes#0 = fgets::return#5
    // if (!read_bytes)
    // [1030] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwuz1_then_la1 
    lda.z read_bytes
    ora.z read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [1031] flash_read::$13 = flash_read::flash_rom_address#10 & $100-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address
    and #<$100-1
    sta.z __13
    lda.z flash_rom_address+1
    and #>$100-1
    sta.z __13+1
    lda.z flash_rom_address+2
    and #<$100-1>>$10
    sta.z __13+2
    lda.z flash_rom_address+3
    and #>$100-1>>$10
    sta.z __13+3
    // if (!(flash_rom_address % 0x100))
    // [1032] if(0!=flash_read::$13) goto flash_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z __13
    ora.z __13+1
    ora.z __13+2
    ora.z __13+3
    bne __b5
    // flash_read::@7
    // cputc('.')
    // [1033] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    // cputc(0xE0);
    lda #'.'
    pha
    // [1034] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [1036] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [1037] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
    lda.z flash_rom_address
    clc
    adc.z read_bytes
    sta.z flash_rom_address
    lda.z flash_rom_address+1
    adc.z read_bytes+1
    sta.z flash_rom_address+1
    lda.z flash_rom_address+2
    adc #0
    sta.z flash_rom_address+2
    lda.z flash_rom_address+3
    adc #0
    sta.z flash_rom_address+3
    // flash_bytes += read_bytes
    // [1038] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
    lda.z flash_bytes
    clc
    adc.z read_bytes
    sta.z flash_bytes
    lda.z flash_bytes+1
    adc.z read_bytes+1
    sta.z flash_bytes+1
    lda.z flash_bytes+2
    adc #0
    sta.z flash_bytes+2
    lda.z flash_bytes+3
    adc #0
    sta.z flash_bytes+3
    // if (flash_ram_address >= 0xC000)
    // [1039] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
    lda.z flash_ram_address+1
    cmp #>$c000
    bcs !__b1+
    jmp __b1
  !__b1:
    bne !+
    lda.z flash_ram_address
    cmp #<$c000
    bcs !__b1+
    jmp __b1
  !__b1:
  !:
    // flash_read::@8
    // flash_ram_address = flash_ram_address - 0x2000
    // [1040] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z flash_ram_address
    sec
    sbc #<$2000
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    sbc #>$2000
    sta.z flash_ram_address+1
    jmp __b1
  .segment Data
    .label flash_size = rom_size.return
}
.segment Code
  // rom_size
/**
 * @brief Calculates the 22 bit ROM size from the 8 bit ROM banks.
 * The ROM size is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM banks.
 * @return unsigned long The resulting 22 bit ROM address.
 */
// __mem() unsigned long rom_size(__register(A) char rom_banks)
rom_size: {
    // ((unsigned long)(rom_banks)) << 14
    // [1042] rom_size::$1 = (unsigned long)rom_size::rom_banks#2 -- vdum1=_dword_vbuaa 
    sta __1
    lda #0
    sta __1+1
    sta __1+2
    sta __1+3
    // [1043] rom_size::return#0 = rom_size::$1 << $e -- vdum1=vdum1_rol_vbuc1 
    ldx #$e
    cpx #0
    beq !e+
  !:
    asl return
    rol return+1
    rol return+2
    rol return+3
    dex
    bne !-
  !e:
    // rom_size::@return
    // }
    // [1044] return 
    rts
  .segment Data
    .label __1 = return
    return: .dword 0
}
.segment Code
  // fclose
/**
 * @brief Close a file.
 *
 * @param fp The FILE pointer.
 * @return 
 *  - 0x0000: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - other: OK! The last pointer between 0xA000 and 0xBFFF is returned. Note that the last pointer is indicating the first free byte.
 */
// int fclose(__mem() struct $1 *fp)
fclose: {
    // cbm_k_close(fp->channel)
    // [1045] cbm_k_close::channel = ((char *)fclose::fp#0)[$10] -- vbum1=pbum2_derefidx_vbuc1 
    ldy #$10
    lda fp
    sta.z $fe
    lda fp+1
    sta.z $ff
    lda ($fe),y
    sta cbm_k_close.channel
    // [1046] call cbm_k_close
    jsr cbm_k_close
    // [1047] cbm_k_close::return#4 = cbm_k_close::return#1
    // fclose::@2
    // [1048] fclose::$0 = cbm_k_close::return#4
    // fp->status = cbm_k_close(fp->channel)
    // [1049] ((char *)fclose::fp#0)[$13] = fclose::$0 -- pbum1_derefidx_vbuc1=vbuaa 
    ldy fp
    sty.z $fe
    ldy fp+1
    sty.z $ff
    ldy #$13
    sta ($fe),y
    // char st = fp->status
    // [1050] fclose::st#0 = ((char *)fclose::fp#0)[$13] -- vbuaa=pbum1_derefidx_vbuc1 
    lda fp
    sta.z $fe
    lda fp+1
    sta.z $ff
    lda ($fe),y
    // if(st)
    // [1051] if(0==fclose::st#0) goto fclose::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [1052] return 
    rts
    // [1053] phi from fclose::@2 to fclose::@1 [phi:fclose::@2->fclose::@1]
    // fclose::@1
  __b1:
    // cbm_k_clrchn()
    // [1054] call cbm_k_clrchn
    jsr cbm_k_clrchn
    // fclose::@3
    // __filecount--;
    // [1055] __filecount = -- __filecount -- vbum1=_dec_vbum1 
    dec __filecount
    rts
  .segment Data
    .label fp = main.fp
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __zp($23) unsigned int uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uint: {
    .const format_min_length = 4
    .const format_justify_left = 0
    .const format_zero_padding = 0
    .const format_upper_case = 0
    .label putc = cputc
    .label uvalue = $23
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1057] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1058] utoa::value#1 = printf_uint::uvalue#0
    // [1059] call utoa
  // Format number into buffer
    // [1352] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1060] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1061] call printf_number_buffer
  // Print using format
    // [1216] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1216] phi printf_number_buffer::format_upper_case#10 = printf_uint::format_upper_case#0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #format_upper_case
    sta.z printf_number_buffer.format_upper_case
    // [1216] phi printf_number_buffer::putc#10 = printf_uint::putc#0 [phi:printf_uint::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [1216] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1216] phi printf_number_buffer::format_zero_padding#10 = printf_uint::format_zero_padding#0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #format_zero_padding
    sta.z printf_number_buffer.format_zero_padding
    // [1216] phi printf_number_buffer::format_justify_left#10 = printf_uint::format_justify_left#0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #format_justify_left
    sta.z printf_number_buffer.format_justify_left
    // [1216] phi printf_number_buffer::format_min_length#3 = printf_uint::format_min_length#0 [phi:printf_uint::@2->printf_number_buffer#5] -- vbuxx=vbuc1 
    ldx #format_min_length
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1062] return 
    rts
}
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($25) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, __zp($50) char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $25
    .label format_zero_padding = $50
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1064] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1065] ultoa::value#1 = printf_ulong::uvalue#2
    // [1066] call ultoa
  // Format number into buffer
    // [1373] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1067] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1068] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#2
    // [1069] call printf_number_buffer
  // Print using format
    // [1216] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1216] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1216] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1216] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1216] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    // [1216] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_justify_left
    // [1216] phi printf_number_buffer::format_min_length#3 = 6 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbuxx=vbuc1 
    ldx #6
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1070] return 
    rts
}
  // print_chip_line
// void print_chip_line(__register(X) char x, __register(Y) char y, __zp($46) char c)
print_chip_line: {
    .label c = $46
    // gotoxy(x, y)
    // [1072] gotoxy::x#4 = print_chip_line::x#9
    // [1073] gotoxy::y#4 = print_chip_line::y#9
    // [1074] call gotoxy
    // [627] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1075] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [1076] call textcolor
    // [609] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [609] phi textcolor::color#22 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1077] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [1078] call bgcolor
    // [614] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [1079] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1080] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1082] call textcolor
    // [609] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [609] phi textcolor::color#22 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1083] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [1084] call bgcolor
    // [614] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [614] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [1085] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1086] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [1088] stackpush(char) = print_chip_line::c#10 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1089] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [1091] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1092] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1094] call textcolor
    // [609] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [609] phi textcolor::color#22 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1095] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [1096] call bgcolor
    // [614] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [1097] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1098] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [1100] return 
    rts
}
  // print_chip_end
// void print_chip_end(__register(A) char x, char y)
print_chip_end: {
    .const y = $36
    // gotoxy(x, y)
    // [1101] gotoxy::x#5 = print_chip_end::x#0 -- vbuxx=vbuaa 
    tax
    // [1102] call gotoxy
    // [627] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [627] phi gotoxy::y#22 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbuyy=vbuc1 
    ldy #y
    // [627] phi gotoxy::x#22 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1103] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [1104] call textcolor
    // [609] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [609] phi textcolor::color#22 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1105] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [1106] call bgcolor
    // [614] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [1107] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1108] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1110] call textcolor
    // [609] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [609] phi textcolor::color#22 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr textcolor
    // [1111] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [1112] call bgcolor
    // [614] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [614] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [1113] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1114] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1116] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1117] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1119] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1120] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1122] call textcolor
    // [609] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [609] phi textcolor::color#22 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1123] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [1124] call bgcolor
    // [614] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [614] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [1125] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1126] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1128] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __register(X) char mapbase, __mem() char config)
screenlayer: {
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1129] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1130] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1131] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // mapbase >> 7
    // [1132] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuaa=vbuxx_ror_7 
    txa
    rol
    rol
    and #1
    // __conio.mapbase_bank = mapbase >> 7
    // [1133] *((char *)&__conio+3) = screenlayer::$0 -- _deref_pbuc1=vbuaa 
    sta __conio+3
    // (mapbase)<<1
    // [1134] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // MAKEWORD((mapbase)<<1,0)
    // [1135] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuaa_word_vbuc1 
    ldy #0
    sta __2+1
    sty __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1136] *((unsigned int *)&__conio+1) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    tya
    sta __conio+1
    lda __2+1
    sta __conio+1+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1137] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuaa=vbum1_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1138] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuxx=vbuaa_ror_4 
    lsr
    lsr
    lsr
    lsr
    tax
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1139] *((char *)&__conio+6) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuxx 
    lda VERA_LAYER_DIM,x
    sta __conio+6
    // config & VERA_LAYER_HEIGHT_MASK
    // [1140] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuaa=vbum1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1141] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuaa=vbuaa_ror_6 
    rol
    rol
    rol
    and #3
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1142] *((char *)&__conio+7) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuaa 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+7
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1143] screenlayer::$16 = screenlayer::$8 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [1144] *((unsigned int *)&__conio+8) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    tay
    lda VERA_LAYER_SKIP,y
    sta __conio+8
    lda VERA_LAYER_SKIP+1,y
    sta __conio+8+1
    // vera_dc_hscale_temp == 0x80
    // [1145] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1146] screenlayer::$18 = (char)screenlayer::$9 -- vbuxx=vbuaa 
    tax
    // [1147] screenlayer::$10 = $28 << screenlayer::$18 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$28
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1148] screenlayer::$11 = screenlayer::$10 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1149] *((char *)&__conio+4) = screenlayer::$11 -- _deref_pbuc1=vbuaa 
    sta __conio+4
    // vera_dc_vscale_temp == 0x80
    // [1150] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1151] screenlayer::$19 = (char)screenlayer::$12 -- vbuxx=vbuaa 
    tax
    // [1152] screenlayer::$13 = $1e << screenlayer::$19 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$1e
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1153] screenlayer::$14 = screenlayer::$13 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1154] *((char *)&__conio+5) = screenlayer::$14 -- _deref_pbuc1=vbuaa 
    sta __conio+5
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1155] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+1) -- vwum1=_deref_pwuc1 
    lda __conio+1
    sta mapbase_offset
    lda __conio+1+1
    sta mapbase_offset+1
    // [1156] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1156] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1156] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1157] if(screenlayer::y#2<=*((char *)&__conio+5)) goto screenlayer::@2 -- vbuxx_le__deref_pbuc1_then_la1 
    lda __conio+5
    stx.z $ff
    cmp.z $ff
    bcs __b2
    // screenlayer::@return
    // }
    // [1158] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1159] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [1160] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuaa=vwum1 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1161] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+8) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+8
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+8+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1162] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuxx=_inc_vbuxx 
    inx
    // [1156] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1156] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1156] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    __2: .word 0
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
    .label mapbase_offset = cbm_k_plot_get.return
    .label config = bgcolor.__0
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [1163] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1164] if(0!=((char *)&__conio+$f)[*((char *)&__conio)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1165] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // [1166] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1167] call gotoxy
    // [627] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [627] phi gotoxy::y#22 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuyy=vbuc1 
    ldy #0
    // [627] phi gotoxy::x#22 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1168] return 
    rts
    // [1169] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1170] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1171] gotoxy::y#2 = *((char *)&__conio+5) -- vbuyy=_deref_pbuc1 
    ldy __conio+5
    // [1172] call gotoxy
    // [627] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // [1173] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1174] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__register(X) char x, __register(Y) char y, __zp($3a) char c)
cputcxy: {
    .label c = $3a
    // gotoxy(x, y)
    // [1176] gotoxy::x#0 = cputcxy::x#68
    // [1177] gotoxy::y#0 = cputcxy::y#68
    // [1178] call gotoxy
    // [627] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [627] phi gotoxy::y#22 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [627] phi gotoxy::x#22 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1179] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1180] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1182] return 
    rts
}
  // getin
/**
 * @brief Get a character from keyboard.
 * 
 * @return char The character read.
 */
getin: {
    // __mem unsigned char ch
    // [1183] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [1185] getin::return#0 = getin::ch -- vbuaa=vbum1 
    // getin::@return
    // }
    // [1186] getin::return#1 = getin::return#0
    // [1187] return 
    rts
  .segment Data
    ch: .byte 0
}
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__register(X) char value, __zp($3b) char *buffer, __register(Y) char radix)
uctoa: {
    .label buffer = $3b
    .label digit = $44
    .label started = $47
    .label max_digits = $4c
    .label digit_values = $4a
    // if(radix==DECIMAL)
    // [1188] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #DECIMAL
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1189] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #HEXADECIMAL
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1190] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #OCTAL
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1191] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #BINARY
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1192] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1193] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1194] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1195] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1196] return 
    rts
    // [1197] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1197] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1197] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1197] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1197] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1197] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1197] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1197] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1197] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1197] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1197] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1197] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1198] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1198] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1198] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1198] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1198] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1199] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuaa=vbuz1_minus_1 
    lda.z max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1200] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuaa_then_la1 
    cmp.z digit
    beq !+
    bcs __b7
  !:
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1201] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1202] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1203] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1204] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuyy=pbuz1_derefidx_vbuz2 
    ldy.z digit
    lda (digit_values),y
    tay
    // if (started || value >= digit_value)
    // [1205] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1206] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuxx_ge_vbuyy_then_la1 
    sty.z $ff
    cpx.z $ff
    bcs __b10
    // [1207] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1207] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1207] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1207] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1208] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1198] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1198] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1198] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1198] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1198] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1209] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1210] uctoa_append::value#0 = uctoa::value#2
    // [1211] uctoa_append::sub#0 = uctoa::digit_value#0 -- vbuz1=vbuyy 
    sty.z uctoa_append.sub
    // [1212] call uctoa_append
    // [1427] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1213] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1214] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1215] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1207] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1207] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1207] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1207] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($64) void (*putc)(char), __zp($52) char buffer_sign, char *buffer_digits, __register(X) char format_min_length, __zp($de) char format_justify_left, char format_sign_always, __zp($50) char format_zero_padding, __zp($df) char format_upper_case, char format_radix)
printf_number_buffer: {
    .label __19 = $23
    .label buffer_sign = $52
    .label format_zero_padding = $50
    .label putc = $64
    .label padding = $51
    .label format_justify_left = $de
    .label format_upper_case = $df
    // if(format.min_length)
    // [1217] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq __b6
    // [1218] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [1219] call strlen
    // [1295] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [1295] phi strlen::str#6 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1220] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@14
    // [1221] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1222] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsyy=_sbyte_vwuz1 
    // There is a minimum length - work out the padding
    ldy.z __19
    // if(buffer.sign)
    // [1223] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [1224] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsyy=_inc_vbsyy 
    iny
    // [1225] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [1225] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [1226] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsxx_minus_vbsyy 
    txa
    sty.z $ff
    sec
    sbc.z $ff
    sta.z padding
    // if(padding<0)
    // [1227] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1229] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [1229] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1228] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [1229] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [1229] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1230] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [1231] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [1232] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [1233] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1234] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1235] call printf_padding
    // [1301] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1301] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1301] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@8->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1301] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1236] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [1237] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1238] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall25
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1240] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [1241] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1242] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1243] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1244] call printf_padding
    // [1301] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1301] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1301] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@10->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1301] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1245] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbuz1_then_la1 
    lda.z format_upper_case
    beq __b5
    // [1246] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1247] call strupr
    // [1434] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1248] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1249] call printf_str
    // [855] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [855] phi printf_str::putc#20 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [855] phi printf_str::s#20 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1250] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1251] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1252] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1253] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1254] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1255] call printf_padding
    // [1301] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1301] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1301] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@12->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1301] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1256] return 
    rts
    // Outside Flow
  icall25:
    jmp (putc)
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($23) char *dst, __zp($38) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label dst = $23
    .label i = $3b
    .label src = $38
    // [1258] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1258] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1258] phi strncpy::src#2 = main::buffer [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z src
    lda #>main.buffer
    sta.z src+1
    // [1258] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1259] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuc1_then_la1 
    lda.z i+1
    cmp #>n
    bcc __b2
    bne !+
    lda.z i
    cmp #<n
    bcc __b2
  !:
    // strncpy::@return
    // }
    // [1260] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1261] strncpy::c#0 = *strncpy::src#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // if(c)
    // [1262] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // strncpy::@4
    // src++;
    // [1263] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1264] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1264] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1265] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1266] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1267] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1258] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1258] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1258] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1258] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_setnam
/**
 * @brief Sets the name of the file before opening.
 * 
 * @param filename The name of the file.
 */
// void cbm_k_setnam(__mem() char * volatile filename)
cbm_k_setnam: {
    .label __0 = $23
    // strlen(filename)
    // [1268] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbum2 
    lda filename
    sta.z strlen.str
    lda filename+1
    sta.z strlen.str+1
    // [1269] call strlen
    // [1295] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [1295] phi strlen::str#6 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1270] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [1271] cbm_k_setnam::$0 = strlen::return#0
    // __mem char filename_len = (char)strlen(filename)
    // [1272] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwuz2 
    lda.z __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [1274] return 
    rts
  .segment Data
    filename: .word 0
    filename_len: .byte 0
}
.segment Code
  // cbm_k_setlfs
/**
 * @brief Sets the logical file channel.
 * 
 * @param channel the logical file number.
 * @param device the device number.
 * @param command the command.
 */
// void cbm_k_setlfs(__mem() volatile char channel, __mem() volatile char device, __mem() volatile char command)
cbm_k_setlfs: {
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1276] return 
    rts
  .segment Data
    channel: .byte 0
    device: .byte 0
    command: .byte 0
}
.segment Code
  // cbm_k_open
/**
 * @brief Open a logical file.
 * 
 * @return char The status.
 */
cbm_k_open: {
    // __mem unsigned char status
    // [1277] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [1279] cbm_k_open::return#0 = cbm_k_open::status -- vbuaa=vbum1 
    // cbm_k_open::@return
    // }
    // [1280] cbm_k_open::return#1 = cbm_k_open::return#0
    // [1281] return 
    rts
  .segment Data
    status: .byte 0
}
.segment Code
  // cbm_k_close
/**
 * @brief Close a logical file.
 * 
 * @param channel The channel to close.
 * @return char Status.
 */
// __register(A) char cbm_k_close(__mem() volatile char channel)
cbm_k_close: {
    // __mem unsigned char status
    // [1282] cbm_k_close::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldachannel jsrCBM_CLOSE stastatus  }
    lda channel
    jsr CBM_CLOSE
    sta status
    // return status;
    // [1284] cbm_k_close::return#0 = cbm_k_close::status -- vbuaa=vbum1 
    // cbm_k_close::@return
    // }
    // [1285] cbm_k_close::return#1 = cbm_k_close::return#0
    // [1286] return 
    rts
  .segment Data
    channel: .byte 0
    status: .byte 0
}
.segment Code
  // cbm_k_chkin
/**
 * @brief Open a channel for input.
 * 
 * @param channel 
 * @return char 
 */
// char cbm_k_chkin(__zp($53) volatile char channel)
cbm_k_chkin: {
    .label channel = $53
    // __mem unsigned char status
    // [1287] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [1289] return 
    rts
  .segment Data
    status: .byte 0
}
.segment Code
  // cbm_k_readst
/**
 * @brief Read the status of the I/O.
 * 
 * @return char Status.
 */
cbm_k_readst: {
    // __mem unsigned char status
    // [1290] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [1292] cbm_k_readst::return#0 = cbm_k_readst::status -- vbuaa=vbum1 
    // cbm_k_readst::@return
    // }
    // [1293] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [1294] return 
    rts
  .segment Data
    status: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($23) unsigned int strlen(__zp($38) char *str)
strlen: {
    .label str = $38
    .label return = $23
    .label len = $23
    // [1296] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1296] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1296] phi strlen::str#4 = strlen::str#6 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1297] if(0!=*strlen::str#4) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1298] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1299] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1300] strlen::str#1 = ++ strlen::str#4 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1296] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1296] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1296] phi strlen::str#4 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($38) void (*putc)(char), __zp($46) char pad, __zp($45) char length)
printf_padding: {
    .label i = $3a
    .label putc = $38
    .label length = $45
    .label pad = $46
    // [1302] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1302] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1303] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1304] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1305] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1306] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall26
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1308] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1302] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1302] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall26:
    jmp (putc)
}
  // fgets
/**
 * @brief Load a file to ram or (banked ram located between address 0xA000 and 0xBFFF), incrementing the banks.
 * This function uses the new CX16 macptr kernal API at address $FF44.
 *
 * @param sptr The pointer between 0xA000 and 0xBFFF in banked ram.
 * @param size The amount of bytes to be read.
 * @param filename Name of the file to be loaded.
 * @return ptr the pointer advanced to the point where the stream ends.
 */
// __zp($36) unsigned int fgets(__zp($38) char *ptr, unsigned int size, __zp($40) struct $1 *fp)
fgets: {
    .const size = $80
    .label return = $36
    .label bytes = $3e
    .label read = $36
    .label ptr = $38
    .label remaining = $23
    .label fp = $40
    // cbm_k_chkin(fp->channel)
    // [1309] cbm_k_chkin::channel = ((char *)fgets::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_chkin.channel
    // [1310] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1311] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [1312] call cbm_k_readst
    jsr cbm_k_readst
    // [1313] cbm_k_readst::return#3 = cbm_k_readst::return#1
    // fgets::@12
    // [1314] fgets::$1 = cbm_k_readst::return#3
    // fp->status = cbm_k_readst()
    // [1315] ((char *)fgets::fp#0)[$13] = fgets::$1 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [1316] if(0==((char *)fgets::fp#0)[$13]) goto fgets::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b8
    // [1317] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [1317] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1318] return 
    rts
    // [1319] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [1319] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1319] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@12->fgets::@1#1] -- vwuz1=vwuc1 
    lda #<size
    sta.z remaining
    lda #>size
    sta.z remaining+1
    // [1319] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [1319] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [1319] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [1319] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [1319] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [1320] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwuz1_ge_vbuc1_then_la1 
    lda.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    lda.z remaining
    cmp #$80
    bcc !__b2+
    jmp __b2
  !__b2:
  !:
    // fgets::@8
    // cbm_k_macptr(remaining, ptr)
    // [1321] cbm_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cbm_k_macptr.bytes
    // [1322] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1323] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1324] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [1325] fgets::bytes#3 = cbm_k_macptr::return#4
    // [1326] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [1326] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [1327] call cbm_k_readst
    jsr cbm_k_readst
    // [1328] cbm_k_readst::return#4 = cbm_k_readst::return#1
    // fgets::@15
    // [1329] fgets::$9 = cbm_k_readst::return#4
    // fp->status = cbm_k_readst()
    // [1330] ((char *)fgets::fp#0)[$13] = fgets::$9 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // fp->status & 0xBF
    // [1331] fgets::$10 = ((char *)fgets::fp#0)[$13] & $bf -- vbuaa=pbuz1_derefidx_vbuc1_band_vbuc2 
    lda #$bf
    and (fp),y
    // if(fp->status & 0xBF)
    // [1332] if(0==fgets::$10) goto fgets::@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [1333] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z bytes+1
    cmp #>$ffff
    bne __b5
    lda.z bytes
    cmp #<$ffff
    bne __b5
    jmp __b1
    // fgets::@5
  __b5:
    // read += bytes
    // [1334] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1335] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1336] fgets::$14 = byte1  fgets::ptr#0 -- vbuaa=_byte1_pbuz1 
    // if(BYTE1(ptr) == 0xC0)
    // [1337] if(fgets::$14!=$c0) goto fgets::@6 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$c0
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [1338] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1339] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [1339] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [1340] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((fp->status == 0) && ((size && remaining) || !size))
    // [1341] if(((char *)fgets::fp#0)[$13]==0) goto fgets::@16 -- pbuz1_derefidx_vbuc1_eq_0_then_la1 
    ldy #$13
    lda (fp),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [1342] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [1343] cbm_k_chkin::channel = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin.channel
    // [1344] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1317] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [1317] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [1345] cbm_k_macptr::bytes = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cbm_k_macptr.bytes
    // [1346] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1347] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1348] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [1349] fgets::bytes#2 = cbm_k_macptr::return#3
    jmp __b3
}
  // cbm_k_clrchn
/**
 * @brief Clear all I/O channels.
 * 
 */
cbm_k_clrchn: {
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // cbm_k_clrchn::@return
    // }
    // [1351] return 
    rts
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($23) unsigned int value, __zp($36) char *buffer, char radix)
utoa: {
    .const max_digits = 4
    .label digit_value = $29
    .label buffer = $36
    .label digit = $43
    .label value = $23
    // [1353] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
    // [1353] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa->utoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1353] phi utoa::started#2 = 0 [phi:utoa->utoa::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // [1353] phi utoa::value#2 = utoa::value#1 [phi:utoa->utoa::@1#2] -- register_copy 
    // [1353] phi utoa::digit#2 = 0 [phi:utoa->utoa::@1#3] -- vbuz1=vbuc1 
    txa
    sta.z digit
    // utoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1354] if(utoa::digit#2<utoa::max_digits#2-1) goto utoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #max_digits-1
    bcc __b2
    // utoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1355] utoa::$11 = (char)utoa::value#2 -- vbuxx=_byte_vwuz1 
    ldx.z value
    // [1356] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1357] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1358] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // utoa::@return
    // }
    // [1359] return 
    rts
    // utoa::@2
  __b2:
    // unsigned int digit_value = digit_values[digit]
    // [1360] utoa::$10 = utoa::digit#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z digit
    asl
    // [1361] utoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES[utoa::$10] -- vwuz1=pwuc1_derefidx_vbuaa 
    tay
    lda RADIX_HEXADECIMAL_VALUES,y
    sta.z digit_value
    lda RADIX_HEXADECIMAL_VALUES+1,y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1362] if(0!=utoa::started#2) goto utoa::@5 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b5
    // utoa::@7
    // [1363] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@5 -- vwuz1_ge_vwuz2_then_la1 
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b5
  !:
    bcc __b5
    // [1364] phi from utoa::@7 to utoa::@4 [phi:utoa::@7->utoa::@4]
    // [1364] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@7->utoa::@4#0] -- register_copy 
    // [1364] phi utoa::started#4 = utoa::started#2 [phi:utoa::@7->utoa::@4#1] -- register_copy 
    // [1364] phi utoa::value#6 = utoa::value#2 [phi:utoa::@7->utoa::@4#2] -- register_copy 
    // utoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1365] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1353] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
    // [1353] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@4->utoa::@1#0] -- register_copy 
    // [1353] phi utoa::started#2 = utoa::started#4 [phi:utoa::@4->utoa::@1#1] -- register_copy 
    // [1353] phi utoa::value#2 = utoa::value#6 [phi:utoa::@4->utoa::@1#2] -- register_copy 
    // [1353] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@4->utoa::@1#3] -- register_copy 
    jmp __b1
    // utoa::@5
  __b5:
    // utoa_append(buffer++, value, digit_value)
    // [1366] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1367] utoa_append::value#0 = utoa::value#2
    // [1368] utoa_append::sub#0 = utoa::digit_value#0
    // [1369] call utoa_append
    // [1449] phi from utoa::@5 to utoa_append [phi:utoa::@5->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1370] utoa_append::return#0 = utoa_append::value#2
    // utoa::@6
    // value = utoa_append(buffer++, value, digit_value)
    // [1371] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1372] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1364] phi from utoa::@6 to utoa::@4 [phi:utoa::@6->utoa::@4]
    // [1364] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@6->utoa::@4#0] -- register_copy 
    // [1364] phi utoa::started#4 = 1 [phi:utoa::@6->utoa::@4#1] -- vbuxx=vbuc1 
    ldx #1
    // [1364] phi utoa::value#6 = utoa::value#0 [phi:utoa::@6->utoa::@4#2] -- register_copy 
    jmp __b4
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($25) unsigned long value, __zp($3e) char *buffer, char radix)
ultoa: {
    .label digit_value = $2b
    .label buffer = $3e
    .label digit = $42
    .label value = $25
    // [1374] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1374] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1374] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // [1374] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1374] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    txa
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1375] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1376] ultoa::$11 = (char)ultoa::value#2 -- vbuaa=_byte_vduz1 
    lda.z value
    // [1377] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuaa 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1378] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1379] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1380] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1381] ultoa::$10 = ultoa::digit#2 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z digit
    asl
    asl
    // [1382] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuaa 
    tay
    lda RADIX_HEXADECIMAL_VALUES_LONG,y
    sta.z digit_value
    lda RADIX_HEXADECIMAL_VALUES_LONG+1,y
    sta.z digit_value+1
    lda RADIX_HEXADECIMAL_VALUES_LONG+2,y
    sta.z digit_value+2
    lda RADIX_HEXADECIMAL_VALUES_LONG+3,y
    sta.z digit_value+3
    // if (started || value >= digit_value)
    // [1383] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b5
    // ultoa::@7
    // [1384] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
    lda.z value+3
    cmp.z digit_value+3
    bcc !+
    bne __b5
    lda.z value+2
    cmp.z digit_value+2
    bcc !+
    bne __b5
    lda.z value+1
    cmp.z digit_value+1
    bcc !+
    bne __b5
    lda.z value
    cmp.z digit_value
    bcs __b5
  !:
    // [1385] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1385] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1385] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1385] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1386] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1374] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1374] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1374] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1374] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1374] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1387] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1388] ultoa_append::value#0 = ultoa::value#2
    // [1389] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1390] call ultoa_append
    // [1456] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1391] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1392] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1393] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1385] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1385] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1385] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuxx=vbuc1 
    ldx #1
    // [1385] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label __7 = $22
    .label width = $3d
    .label y = $32
    // __conio.width+1
    // [1394] insertup::$0 = *((char *)&__conio+4) + 1 -- vbuaa=_deref_pbuc1_plus_1 
    lda __conio+4
    inc
    // unsigned char width = (__conio.width+1) * 2
    // [1395] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuaa_rol_1 
    asl
    sta.z width
    // [1396] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1396] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1397] if(insertup::y#2<=*((char *)&__conio+$e)) goto insertup::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+$e
    cmp.z y
    bcs __b2
    // [1398] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1399] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1400] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1401] insertup::$4 = insertup::y#2 + 1 -- vbuxx=vbuz1_plus_1 
    ldx.z y
    inx
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1402] insertup::$6 = insertup::y#2 << 1 -- vbuyy=vbuz1_rol_1 
    lda.z y
    asl
    tay
    // [1403] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuxx_rol_1 
    txa
    asl
    sta.z __7
    // [1404] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.dbank_vram
    // [1405] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuyy 
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1406] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+3) -- vbuxx=_deref_pbuc1 
    ldx __conio+3
    // [1407] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1408] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8
    // [1409] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1410] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1396] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1396] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label addr = $33
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1411] clearline::$3 = *((char *)&__conio+$e) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    // [1412] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1413] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1414] clearline::$0 = byte0  clearline::addr#0 -- vbuaa=_byte0_vwuz1 
    lda.z addr
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1415] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1416] clearline::$1 = byte1  clearline::addr#0 -- vbuaa=_byte1_vwuz1 
    lda.z addr+1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1417] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1418] clearline::$2 = *((char *)&__conio+3) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1419] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1420] clearline::c#0 = *((char *)&__conio+4) -- vbuxx=_deref_pbuc1 
    ldx __conio+4
    // [1421] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1421] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1422] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1423] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [1424] clearline::c#1 = -- clearline::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [1425] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clearline::@return
    // }
    // [1426] return 
    rts
}
  // uctoa_append
// Used to convert a single digit of an unsigned number value to a string representation
// Counts a single digit up from '0' as long as the value is larger than sub.
// Each time the digit is increased sub is subtracted from value.
// - buffer : pointer to the char that receives the digit
// - value : The value where the digit will be derived from
// - sub : the value of a '1' in the digit. Subtracted continually while the digit is increased.
//        (For decimal the subs used are 10000, 1000, 100, 10, 1)
// returns : the value reduced by sub * digit so that it is less than sub.
// __register(X) char uctoa_append(__zp($40) char *buffer, __register(X) char value, __zp($2f) char sub)
uctoa_append: {
    .label buffer = $40
    .label sub = $2f
    // [1428] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1428] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuyy=vbuc1 
    ldy #0
    // [1428] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1429] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuxx_ge_vbuz1_then_la1 
    cpx.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1430] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuyy 
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1431] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1432] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuyy=_inc_vbuyy 
    iny
    // value -= sub
    // [1433] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuxx=vbuxx_minus_vbuz1 
    txa
    sec
    sbc.z sub
    tax
    // [1428] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1428] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1428] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label src = $36
    // [1435] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1435] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1436] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1437] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1438] toupper::ch#0 = *strupr::src#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // [1439] call toupper
    jsr toupper
    // [1440] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1441] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1442] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (src),y
    // src++;
    // [1443] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1435] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1435] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
    jmp __b1
}
  // cbm_k_macptr
/**
 * @brief Read a number of bytes from the sdcard using kernal macptr call.
 * BRAM bank needs to be set properly before the load between adressed A000 and BFFF.
 * 
 * @return x the size of bytes read
 * @return y the size of bytes read
 * @return if carry is set there is an error
 */
// __zp($3e) unsigned int cbm_k_macptr(__zp($4d) volatile char bytes, __zp($48) void * volatile buffer)
cbm_k_macptr: {
    .label bytes = $4d
    .label buffer = $48
    .label return = $3e
    // __mem unsigned int bytes_read
    // [1444] cbm_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
    lda #<0
    sta bytes_read
    sta bytes_read+1
    // asm
    // asm { ldabytes ldxbuffer ldybuffer+1 clc jsrCBM_MACPTR stxbytes_read stybytes_read+1 bcc!+ lda#$FF stabytes_read stabytes_read+1 !:  }
    lda bytes
    ldx buffer
    ldy buffer+1
    clc
    jsr CBM_MACPTR
    stx bytes_read
    sty bytes_read+1
    bcc !+
    lda #$ff
    sta bytes_read
    sta bytes_read+1
  !:
    // return bytes_read;
    // [1446] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwuz1=vwum2 
    lda bytes_read
    sta.z return
    lda bytes_read+1
    sta.z return+1
    // cbm_k_macptr::@return
    // }
    // [1447] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [1448] return 
    rts
  .segment Data
    bytes_read: .word 0
}
.segment Code
  // utoa_append
// Used to convert a single digit of an unsigned number value to a string representation
// Counts a single digit up from '0' as long as the value is larger than sub.
// Each time the digit is increased sub is subtracted from value.
// - buffer : pointer to the char that receives the digit
// - value : The value where the digit will be derived from
// - sub : the value of a '1' in the digit. Subtracted continually while the digit is increased.
//        (For decimal the subs used are 10000, 1000, 100, 10, 1)
// returns : the value reduced by sub * digit so that it is less than sub.
// __zp($23) unsigned int utoa_append(__zp($40) char *buffer, __zp($23) unsigned int value, __zp($29) unsigned int sub)
utoa_append: {
    .label buffer = $40
    .label value = $23
    .label sub = $29
    .label return = $23
    // [1450] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1450] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [1450] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1451] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
    lda.z sub+1
    cmp.z value+1
    bne !+
    lda.z sub
    cmp.z value
    beq __b2
  !:
    bcc __b2
    // utoa_append::@3
    // *buffer = DIGITS[digit]
    // [1452] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1453] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1454] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [1455] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1450] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1450] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1450] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // ultoa_append
// Used to convert a single digit of an unsigned number value to a string representation
// Counts a single digit up from '0' as long as the value is larger than sub.
// Each time the digit is increased sub is subtracted from value.
// - buffer : pointer to the char that receives the digit
// - value : The value where the digit will be derived from
// - sub : the value of a '1' in the digit. Subtracted continually while the digit is increased.
//        (For decimal the subs used are 10000, 1000, 100, 10, 1)
// returns : the value reduced by sub * digit so that it is less than sub.
// __zp($25) unsigned long ultoa_append(__zp($29) char *buffer, __zp($25) unsigned long value, __zp($2b) unsigned long sub)
ultoa_append: {
    .label buffer = $29
    .label value = $25
    .label sub = $2b
    .label return = $25
    // [1457] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1457] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [1457] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1458] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
    lda.z value+3
    cmp.z sub+3
    bcc !+
    bne __b2
    lda.z value+2
    cmp.z sub+2
    bcc !+
    bne __b2
    lda.z value+1
    cmp.z sub+1
    bcc !+
    bne __b2
    lda.z value
    cmp.z sub
    bcs __b2
  !:
    // ultoa_append::@3
    // *buffer = DIGITS[digit]
    // [1459] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1460] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1461] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [1462] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    lda.z value+2
    sbc.z sub+2
    sta.z value+2
    lda.z value+3
    sbc.z sub+3
    sta.z value+3
    // [1457] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1457] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1457] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // memcpy8_vram_vram
/**
 * @brief Copy a block of memory in VRAM from a source to a target destination.
 * This function is designed to copy maximum 255 bytes of memory in one step.
 * If more than 255 bytes need to be copied, use the memcpy_vram_vram function.
 *
 * @see memcpy_vram_vram
 *
 * @param dbank_vram Bank of the destination location in vram.
 * @param doffset_vram Offset of the destination location in vram.
 * @param sbank_vram Bank of the source location in vram.
 * @param soffset_vram Offset of the source location in vram.
 * @param num16 Specified the amount of bytes to be copied.
 */
// void memcpy8_vram_vram(__zp($35) char dbank_vram, __zp($33) unsigned int doffset_vram, __register(X) char sbank_vram, __zp($30) unsigned int soffset_vram, __register(X) char num8)
memcpy8_vram_vram: {
    .label dbank_vram = $35
    .label doffset_vram = $33
    .label soffset_vram = $30
    .label num8 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1463] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1464] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z soffset_vram
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1465] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1466] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z soffset_vram+1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1467] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1468] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuaa=vbuxx_bor_vbuc1 
    txa
    ora #VERA_INC_1
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1469] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1470] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1471] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z doffset_vram
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1472] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1473] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z doffset_vram+1
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1474] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1475] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuaa=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z dbank_vram
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1476] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // [1477] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1477] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1478] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuxx=_dec_vbuz1 
    ldx.z num8
    dex
    // [1479] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1480] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1481] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1482] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuxx 
    stx.z num8
    jmp __b1
}
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __register(A) char toupper(__register(A) char ch)
toupper: {
    // if(ch>='a' && ch<='z')
    // [1483] if(toupper::ch#0<'a'pm) goto toupper::@return -- vbuaa_lt_vbuc1_then_la1 
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1484] if(toupper::ch#0<='z'pm) goto toupper::@1 -- vbuaa_le_vbuc1_then_la1 
    cmp #'z'
    bcc __b1
    beq __b1
    // [1486] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1486] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1485] toupper::return#0 = toupper::ch#0 + 'A'pm-'a'pm -- vbuaa=vbuaa_plus_vbuc1 
    clc
    adc #'A'-'a'
    // toupper::@return
  __breturn:
    // }
    // [1487] return 
    rts
}
  // File Data
.segment Data
  // The digits used for numbers
  DIGITS: .text "0123456789abcdef"
  // Values of binary digits
  RADIX_BINARY_VALUES_CHAR: .byte $80, $40, $20, $10, 8, 4, 2
  // Values of octal digits
  RADIX_OCTAL_VALUES_CHAR: .byte $40, 8
  // Values of decimal digits
  RADIX_DECIMAL_VALUES_CHAR: .byte $64, $a
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_CHAR: .byte $10
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES: .word $1000, $100, $10
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_LONG: .dword $10000000, $1000000, $100000, $10000, $1000, $100, $10
  __files: .fill $14*4, 0
  __conio: .fill SIZEOF_STRUCT___0, 0
  __filecount: .byte 0
  // Buffer used for stringified number being printed
  printf_buffer: .fill SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER, 0
  /// The capacity of the buffer (n passed to snprintf())
  /// Used to hold state while printing
  __snprintf_capacity: .word 0
  // The number of chars that would have been filled when printing without capacity. Grows even after size>capacity.
  /// Used to hold state while printing
  __snprintf_size: .word 0
  /// Current position in the buffer being filled ( initially *s passed to snprintf()
  /// Used to hold state while printing
  __snprintf_buffer: .word 0
