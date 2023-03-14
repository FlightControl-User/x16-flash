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
.file [name="FLASH-CX16.prg", type="prg", segments="Program"]
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
  .const RED = 2
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
// void snputc(__zp($e3) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $e3
    // [9] snputc::c#0 = stackidx(char,snputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
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
    // [15] phi snputc::c#2 = 0 [phi:snputc::@1->snputc::@2#0] -- vbuz1=vbuc1 
    lda #0
    sta.z c
    // [14] phi from snputc::@1 to snputc::@3 [phi:snputc::@1->snputc::@3]
    // snputc::@3
    // [15] phi from snputc::@3 to snputc::@2 [phi:snputc::@3->snputc::@2]
    // [15] phi snputc::c#2 = snputc::c#0 [phi:snputc::@3->snputc::@2#0] -- register_copy 
    // snputc::@2
  __b2:
    // *(__snprintf_buffer++) = c
    // [16] *__snprintf_buffer = snputc::c#2 -- _deref_pbum1=vbuz2 
    // Append char
    lda.z c
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
    .label __4 = $d0
    .label __5 = $79
    .label __6 = $d0
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [511] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [516] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
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
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwuz2 
    lda.z __4+1
    sta.z __5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio+$d) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // cbm_k_plot_get()
    // [32] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [33] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [34] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbum1=_byte0_vwuz2 
    lda.z __6
    sta __7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+$e) = conio_x16_init::$7 -- _deref_pbuc1=vbum1 
    sta __conio+$e
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#1 = *((char *)&__conio+$d) -- vbuz1=_deref_pbuc1 
    lda __conio+$d
    sta.z gotoxy.x
    // [38] gotoxy::y#1 = *((char *)&__conio+$e) -- vbuz1=_deref_pbuc1 
    lda __conio+$e
    sta.z gotoxy.y
    // [39] call gotoxy
    // [529] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    __7: .byte 0
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__zp($56) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label __1 = $37
    .label __2 = $7f
    .label __3 = $a9
    .label c = $56
    // [43] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
    // if(c=='\n')
    // [44] if(cputc::c#0==' 'pm) goto cputc::@1 -- vbuz1_eq_vbuc1_then_la1 
  .encoding "petscii_mixed"
    lda #'\n'
    cmp.z c
    beq __b1
    // cputc::@2
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [45] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [46] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z __1
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [47] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [48] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z __2
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [49] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [50] cputc::$3 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [51] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [52] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuz1 
    lda.z c
    sta VERA_DATA0
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
    .const bank_set_bram1_bank = 1
    .const bank_set_bram2_bank = 1
    .const bank_set_bram3_bank = 1
    .const bank_set_bram4_bank = 1
    .label __20 = $77
    .label __22 = $77
    .label __38 = $ee
    .label __56 = $2b
    .label __64 = $78
    .label __98 = $b9
    .label __137 = $63
    .label __161 = $bd
    .label __162 = $26
    .label __163 = $76
    .label rom_chip = $fb
    .label flash_rom_address = $f6
    .label flash_chip = $fa
    .label flash_rom_address_boundary = $50
    .label size = $c1
    .label flash_bytes_1 = $f0
    .label flash_rom_address1 = $da
    .label equal_bytes = $61
    .label flash_rom_address_sector = $d4
    .label read_ram_address = $cb
    .label x_sector = $e1
    .label read_ram_bank = $c0
    .label y_sector = $e2
    .label equal_bytes1 = $61
    .label read_ram_address_sector = $c5
    .label flash_rom_address_boundary1 = $c7
    .label retries = $be
    .label flash_errors = $b0
    .label read_ram_address1 = $b6
    .label flash_rom_address2 = $b2
    .label x1 = $b1
    .label flash_errors_sector = $cd
    .label x_sector1 = $d3
    .label read_ram_bank_sector = $bf
    .label y_sector1 = $d2
    .label v = $df
    .label w = $f4
    .label pattern = $ea
    .label pattern1 = $3c
    .label flash_rom_address_boundary_2 = $f0
    .label __179 = $ee
    .label __180 = $ee
    .label __183 = $78
    .label __185 = $2b
    .label __186 = $2b
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@55
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
    // [75] phi from main::@55 to main::@64 [phi:main::@55->main::@64]
    // main::@64
    // textcolor(WHITE)
    // [76] call textcolor
    // [511] phi from main::@64 to textcolor [phi:main::@64->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@64->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [77] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
    // bgcolor(BLUE)
    // [78] call bgcolor
    // [516] phi from main::@65 to bgcolor [phi:main::@65->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:main::@65->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [79] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // scroll(0)
    // [80] call scroll
    jsr scroll
    // [81] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // clrscr()
    // [82] call clrscr
    jsr clrscr
    // [83] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // frame_draw()
    // [84] call frame_draw
    // [577] phi from main::@68 to frame_draw [phi:main::@68->frame_draw]
    jsr frame_draw
    // [85] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // gotoxy(2, 1)
    // [86] call gotoxy
    // [529] phi from main::@69 to gotoxy [phi:main::@69->gotoxy]
    // [529] phi gotoxy::y#24 = 1 [phi:main::@69->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = 2 [phi:main::@69->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [87] phi from main::@69 to main::@70 [phi:main::@69->main::@70]
    // main::@70
    // printf("commander x16 rom flash utility")
    // [88] call printf_str
    // [757] phi from main::@70 to printf_str [phi:main::@70->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:main::@70->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s [phi:main::@70->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [89] phi from main::@70 to main::@71 [phi:main::@70->main::@71]
    // main::@71
    // print_chips()
    // [90] call print_chips
    // [766] phi from main::@71 to print_chips [phi:main::@71->print_chips]
    jsr print_chips
    // [91] phi from main::@71 to main::@1 [phi:main::@71->main::@1]
    // [91] phi main::rom_chip#10 = 0 [phi:main::@71->main::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // [91] phi main::flash_rom_address#10 = 0 [phi:main::@71->main::@1#1] -- vduz1=vduc1 
    sta.z flash_rom_address
    sta.z flash_rom_address+1
    lda #<0>>$10
    sta.z flash_rom_address+2
    lda #>0>>$10
    sta.z flash_rom_address+3
    // main::@1
  __b1:
    // for (unsigned long flash_rom_address = 0; flash_rom_address < 8 * 0x80000; flash_rom_address += 0x80000)
    // [92] if(main::flash_rom_address#10<8*$80000) goto main::@2 -- vduz1_lt_vduc1_then_la1 
    lda.z flash_rom_address+3
    cmp #>8*$80000>>$10
    bcs !__b2+
    jmp __b2
  !__b2:
    bne !+
    lda.z flash_rom_address+2
    cmp #<8*$80000>>$10
    bcs !__b2+
    jmp __b2
  !__b2:
    bne !+
    lda.z flash_rom_address+1
    cmp #>8*$80000
    bcs !__b2+
    jmp __b2
  !__b2:
    bne !+
    lda.z flash_rom_address
    cmp #<8*$80000
    bcs !__b2+
    jmp __b2
  !__b2:
  !:
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [94] phi from main::CLI1 to main::@56 [phi:main::CLI1->main::@56]
    // main::@56
    // sprintf(buffer, "press a key to start flashing.")
    // [95] call snprintf_init
    jsr snprintf_init
    // [96] phi from main::@56 to main::@77 [phi:main::@56->main::@77]
    // main::@77
    // sprintf(buffer, "press a key to start flashing.")
    // [97] call printf_str
    // [757] phi from main::@77 to printf_str [phi:main::@77->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@77->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s1 [phi:main::@77->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@78
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
    // [801] phi from main::@78 to print_text [phi:main::@78->print_text]
    jsr print_text
    // [102] phi from main::@78 to main::@79 [phi:main::@78->main::@79]
    // main::@79
    // wait_key()
    // [103] call wait_key
    // [808] phi from main::@79 to wait_key [phi:main::@79->wait_key]
    jsr wait_key
    // [104] phi from main::@79 to main::@11 [phi:main::@79->main::@11]
    // [104] phi main::flash_chip#10 = 7 [phi:main::@79->main::@11#0] -- vbuz1=vbuc1 
    lda #7
    sta.z flash_chip
    // main::@11
  __b11:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [105] if(main::flash_chip#10!=$ff) goto main::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #$ff
    cmp.z flash_chip
    beq !__b12+
    jmp __b12
  !__b12:
    // [106] phi from main::@11 to main::@13 [phi:main::@11->main::@13]
    // main::@13
    // bank_set_brom(0)
    // [107] call bank_set_brom
    // [818] phi from main::@13 to bank_set_brom [phi:main::@13->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 0 [phi:main::@13->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #0
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [108] phi from main::@13 to main::@92 [phi:main::@13->main::@92]
    // main::@92
    // textcolor(WHITE)
    // [109] call textcolor
    // [511] phi from main::@92 to textcolor [phi:main::@92->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@92->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [110] phi from main::@92 to main::@50 [phi:main::@92->main::@50]
    // [110] phi main::w#10 = $80 [phi:main::@92->main::@50#0] -- vwsz1=vwsc1 
    lda #<$80
    sta.z w
    lda #>$80
    sta.z w+1
    // main::@50
  __b50:
    // for (int w = 128; w >= 0; w--)
    // [111] if(main::w#10>=0) goto main::@52 -- vwsz1_ge_0_then_la1 
    lda.z w+1
    bpl __b6
    // [112] phi from main::@50 to main::@51 [phi:main::@50->main::@51]
    // main::@51
    // system_reset()
    // [113] call system_reset
    // [821] phi from main::@51 to system_reset [phi:main::@51->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [114] return 
    rts
    // [115] phi from main::@50 to main::@52 [phi:main::@50->main::@52]
  __b6:
    // [115] phi main::v#2 = 0 [phi:main::@50->main::@52#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z v
    sta.z v+1
    // main::@52
  __b52:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [116] if(main::v#2<$100*$80) goto main::@53 -- vwuz1_lt_vwuc1_then_la1 
    lda.z v+1
    cmp #>$100*$80
    bcc __b53
    bne !+
    lda.z v
    cmp #<$100*$80
    bcc __b53
  !:
    // [117] phi from main::@52 to main::@54 [phi:main::@52->main::@54]
    // main::@54
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [118] call snprintf_init
    jsr snprintf_init
    // [119] phi from main::@54 to main::@175 [phi:main::@54->main::@175]
    // main::@175
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [120] call printf_str
    // [757] phi from main::@175 to printf_str [phi:main::@175->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@175->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s22 [phi:main::@175->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@176
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [121] printf_sint::value#1 = main::w#10 -- vwsz1=vwsz2 
    lda.z w
    sta.z printf_sint.value
    lda.z w+1
    sta.z printf_sint.value+1
    // [122] call printf_sint
    jsr printf_sint
    // [123] phi from main::@176 to main::@177 [phi:main::@176->main::@177]
    // main::@177
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [124] call printf_str
    // [757] phi from main::@177 to printf_str [phi:main::@177->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@177->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s23 [phi:main::@177->printf_str#1] -- pbuz1=pbuc1 
    lda #<s23
    sta.z printf_str.s
    lda #>s23
    sta.z printf_str.s+1
    jsr printf_str
    // main::@178
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [125] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [126] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [128] call print_text
    // [801] phi from main::@178 to print_text [phi:main::@178->print_text]
    jsr print_text
    // main::@179
    // for (int w = 128; w >= 0; w--)
    // [129] main::w#1 = -- main::w#10 -- vwsz1=_dec_vwsz1 
    lda.z w
    bne !+
    dec.z w+1
  !:
    dec.z w
    // [110] phi from main::@179 to main::@50 [phi:main::@179->main::@50]
    // [110] phi main::w#10 = main::w#1 [phi:main::@179->main::@50#0] -- register_copy 
    jmp __b50
    // main::@53
  __b53:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [130] main::v#1 = ++ main::v#2 -- vwuz1=_inc_vwuz1 
    inc.z v
    bne !+
    inc.z v+1
  !:
    // [115] phi from main::@53 to main::@52 [phi:main::@53->main::@52]
    // [115] phi main::v#2 = main::v#1 [phi:main::@53->main::@52#0] -- register_copy 
    jmp __b52
    // main::@12
  __b12:
    // if (rom_device_ids[flash_chip] != UNKNOWN)
    // [131] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@14 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b14+
    jmp __b14
  !__b14:
    // [132] phi from main::@12 to main::@48 [phi:main::@12->main::@48]
    // main::@48
    // gotoxy(0, 2)
    // [133] call gotoxy
    // [529] phi from main::@48 to gotoxy [phi:main::@48->gotoxy]
    // [529] phi gotoxy::y#24 = 2 [phi:main::@48->gotoxy#0] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = 0 [phi:main::@48->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [134] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [135] phi from main::bank_set_bram1 to main::@57 [phi:main::bank_set_bram1->main::@57]
    // main::@57
    // bank_set_brom(4)
    // [136] call bank_set_brom
    // [818] phi from main::@57 to bank_set_brom [phi:main::@57->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 4 [phi:main::@57->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@93
    // if (flash_chip == 0)
    // [137] if(main::flash_chip#10==0) goto main::@15 -- vbuz1_eq_0_then_la1 
    lda.z flash_chip
    bne !__b15+
    jmp __b15
  !__b15:
    // [138] phi from main::@93 to main::@49 [phi:main::@93->main::@49]
    // main::@49
    // sprintf(file, "rom%u.bin", flash_chip)
    // [139] call snprintf_init
    jsr snprintf_init
    // [140] phi from main::@49 to main::@96 [phi:main::@49->main::@96]
    // main::@96
    // sprintf(file, "rom%u.bin", flash_chip)
    // [141] call printf_str
    // [757] phi from main::@96 to printf_str [phi:main::@96->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@96->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s3 [phi:main::@96->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@97
    // sprintf(file, "rom%u.bin", flash_chip)
    // [142] printf_uchar::uvalue#4 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [143] call printf_uchar
    // [837] phi from main::@97 to printf_uchar [phi:main::@97->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@97->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@97->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &snputc [phi:main::@97->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@97->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#4 [phi:main::@97->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [144] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // sprintf(file, "rom%u.bin", flash_chip)
    // [145] call printf_str
    // [757] phi from main::@98 to printf_str [phi:main::@98->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@98->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s4 [phi:main::@98->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@99
    // sprintf(file, "rom%u.bin", flash_chip)
    // [146] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [147] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // main::@16
  __b16:
    // unsigned char flash_rom_bank = flash_chip * 32
    // [149] main::flash_rom_bank#0 = main::flash_chip#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z flash_chip
    asl
    asl
    asl
    asl
    asl
    sta flash_rom_bank
    // FILE *fp = fopen(1, 8, 2, file)
    // [150] call fopen
    // Read the file content.
    jsr fopen
    // [151] fopen::return#4 = fopen::return#1
    // main::@100
    // [152] main::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [153] if((struct $1 *)0!=main::fp#0) goto main::@17 -- pssc1_neq_pssm1_then_la1 
    cmp #>0
    beq !__b17+
    jmp __b17
  !__b17:
    lda fp
    cmp #<0
    beq !__b17+
    jmp __b17
  !__b17:
    // [154] phi from main::@100 to main::@46 [phi:main::@100->main::@46]
    // main::@46
    // textcolor(WHITE)
    // [155] call textcolor
    // [511] phi from main::@46 to textcolor [phi:main::@46->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@46->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [156] phi from main::@46 to main::@114 [phi:main::@46->main::@114]
    // main::@114
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [157] call snprintf_init
    jsr snprintf_init
    // [158] phi from main::@114 to main::@115 [phi:main::@114->main::@115]
    // main::@115
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [159] call printf_str
    // [757] phi from main::@115 to printf_str [phi:main::@115->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@115->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s7 [phi:main::@115->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@116
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [160] printf_uchar::uvalue#6 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [161] call printf_uchar
    // [837] phi from main::@116 to printf_uchar [phi:main::@116->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@116->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@116->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &snputc [phi:main::@116->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@116->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#6 [phi:main::@116->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [162] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [163] call printf_str
    // [757] phi from main::@117 to printf_str [phi:main::@117->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@117->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s8 [phi:main::@117->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@118
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [164] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [165] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [167] call print_text
    // [801] phi from main::@118 to print_text [phi:main::@118->print_text]
    jsr print_text
    // main::@119
    // flash_chip * 10
    // [168] main::$185 = main::flash_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z flash_chip
    asl
    asl
    sta.z __185
    // [169] main::$186 = main::$185 + main::flash_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z __186
    clc
    adc.z flash_chip
    sta.z __186
    // [170] main::$56 = main::$186 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __56
    // gotoxy(2 + flash_chip * 10, 58)
    // [171] gotoxy::x#18 = 2 + main::$56 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __56
    sta.z gotoxy.x
    // [172] call gotoxy
    // [529] phi from main::@119 to gotoxy [phi:main::@119->gotoxy]
    // [529] phi gotoxy::y#24 = $3a [phi:main::@119->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = gotoxy::x#18 [phi:main::@119->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [173] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // printf("no file")
    // [174] call printf_str
    // [757] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s9 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@121
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [175] print_chip_led::r#6 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [176] call print_chip_led
    // [885] phi from main::@121 to print_chip_led [phi:main::@121->print_chip_led]
    // [885] phi print_chip_led::tc#10 = DARK_GREY [phi:main::@121->print_chip_led#0] -- vbuz1=vbuc1 
    lda #DARK_GREY
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#6 [phi:main::@121->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@18
  __b18:
    // if (flash_chip != 0)
    // [177] if(main::flash_chip#10==0) goto main::@14 -- vbuz1_eq_0_then_la1 
    lda.z flash_chip
    beq __b14
    // [178] phi from main::@18 to main::@47 [phi:main::@18->main::@47]
    // main::@47
    // bank_set_brom(4)
    // [179] call bank_set_brom
    // [818] phi from main::@47 to bank_set_brom [phi:main::@47->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 4 [phi:main::@47->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // [181] phi from main::CLI3 to main::@63 [phi:main::CLI3->main::@63]
    // main::@63
    // wait_key()
    // [182] call wait_key
    // [808] phi from main::@63 to wait_key [phi:main::@63->wait_key]
    jsr wait_key
    // main::SEI4
    // asm
    // asm { sei  }
    sei
    // main::@14
  __b14:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [184] main::flash_chip#1 = -- main::flash_chip#10 -- vbuz1=_dec_vbuz1 
    dec.z flash_chip
    // [104] phi from main::@14 to main::@11 [phi:main::@14->main::@11]
    // [104] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@14->main::@11#0] -- register_copy 
    jmp __b11
    // main::@17
  __b17:
    // table_chip_clear(flash_chip * 32)
    // [185] table_chip_clear::rom_bank#1 = main::flash_chip#10 << 5 -- vbuz1=vbuz2_rol_5 
    lda.z flash_chip
    asl
    asl
    asl
    asl
    asl
    sta.z table_chip_clear.rom_bank
    // [186] call table_chip_clear
    // [905] phi from main::@17 to table_chip_clear [phi:main::@17->table_chip_clear]
    jsr table_chip_clear
    // [187] phi from main::@17 to main::@101 [phi:main::@17->main::@101]
    // main::@101
    // textcolor(WHITE)
    // [188] call textcolor
    // [511] phi from main::@101 to textcolor [phi:main::@101->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@101->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@102
    // flash_chip * 10
    // [189] main::$164 = main::flash_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z flash_chip
    asl
    asl
    sta __164
    // [190] main::$183 = main::$164 + main::flash_chip#10 -- vbuz1=vbum2_plus_vbuz3 
    clc
    adc.z flash_chip
    sta.z __183
    // [191] main::$64 = main::$183 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __64
    // gotoxy(2 + flash_chip * 10, 58)
    // [192] gotoxy::x#17 = 2 + main::$64 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __64
    sta.z gotoxy.x
    // [193] call gotoxy
    // [529] phi from main::@102 to gotoxy [phi:main::@102->gotoxy]
    // [529] phi gotoxy::y#24 = $3a [phi:main::@102->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = gotoxy::x#17 [phi:main::@102->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [194] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // printf("%s", file)
    // [195] call printf_string
    // [930] phi from main::@103 to printf_string [phi:main::@103->printf_string]
    // [930] phi printf_string::str#10 = main::buffer [phi:main::@103->printf_string#0] -- pbuz1=pbuc1 
    lda #<buffer
    sta.z printf_string.str
    lda #>buffer
    sta.z printf_string.str+1
    // [930] phi printf_string::format_justify_left#10 = 0 [phi:main::@103->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [930] phi printf_string::format_min_length#7 = 0 [phi:main::@103->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@104
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [196] print_chip_led::r#5 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [197] call print_chip_led
    // [885] phi from main::@104 to print_chip_led [phi:main::@104->print_chip_led]
    // [885] phi print_chip_led::tc#10 = CYAN [phi:main::@104->print_chip_led#0] -- vbuz1=vbuc1 
    lda #CYAN
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#5 [phi:main::@104->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [198] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [199] call snprintf_init
    jsr snprintf_init
    // [200] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [201] call printf_str
    // [757] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s5 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [202] printf_uchar::uvalue#5 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [203] call printf_uchar
    // [837] phi from main::@107 to printf_uchar [phi:main::@107->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@107->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@107->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &snputc [phi:main::@107->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@107->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#5 [phi:main::@107->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [204] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [205] call printf_str
    // [757] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s6 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [206] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [207] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [209] call print_text
    // [801] phi from main::@109 to print_text [phi:main::@109->print_text]
    jsr print_text
    // main::@110
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [210] rom_address::rom_bank#2 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [211] call rom_address
    // [952] phi from main::@110 to rom_address [phi:main::@110->rom_address]
    // [952] phi rom_address::rom_bank#5 = rom_address::rom_bank#2 [phi:main::@110->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [212] rom_address::return#10 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_2
    lda.z rom_address.return+1
    sta.z rom_address.return_2+1
    lda.z rom_address.return+2
    sta.z rom_address.return_2+2
    lda.z rom_address.return+3
    sta.z rom_address.return_2+3
    // main::@111
    // [213] main::flash_rom_address_boundary#0 = rom_address::return#10
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, size)
    // [214] flash_read::fp#0 = main::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z flash_read.fp
    lda fp+1
    sta.z flash_read.fp+1
    // [215] flash_read::rom_bank_start#1 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z flash_read.rom_bank_start
    // [216] call flash_read
    // [956] phi from main::@111 to flash_read [phi:main::@111->flash_read]
    // [956] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@111->flash_read#0] -- register_copy 
    // [956] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@111->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [956] phi flash_read::read_size#4 = $4000 [phi:main::@111->flash_read#2] -- vduz1=vduc1 
    lda #<$4000
    sta.z flash_read.read_size
    lda #>$4000
    sta.z flash_read.read_size+1
    lda #<$4000>>$10
    sta.z flash_read.read_size+2
    lda #>$4000>>$10
    sta.z flash_read.read_size+3
    // [956] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@111->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, size)
    // [217] flash_read::return#3 = flash_read::return#2
    // main::@112
    // [218] main::flash_bytes#0 = flash_read::return#3 -- vdum1=vduz2 
    lda.z flash_read.return
    sta flash_bytes
    lda.z flash_read.return+1
    sta flash_bytes+1
    lda.z flash_read.return+2
    sta flash_bytes+2
    lda.z flash_read.return+3
    sta flash_bytes+3
    // rom_size(1)
    // [219] call rom_size
    // [988] phi from main::@112 to rom_size [phi:main::@112->rom_size]
    jsr rom_size
    // main::@113
    // if (flash_bytes != rom_size(1))
    // [220] if(main::flash_bytes#0==rom_size::return#0) goto main::@19 -- vdum1_eq_vduc1_then_la1 
    lda flash_bytes+3
    cmp #>rom_size.return>>$10
    bne !+
    lda flash_bytes+2
    cmp #<rom_size.return>>$10
    bne !+
    lda flash_bytes+1
    cmp #>rom_size.return
    bne !+
    lda flash_bytes
    cmp #<rom_size.return
    beq __b19
  !:
    rts
    // main::@19
  __b19:
    // flash_rom_address_boundary += flash_bytes
    // [221] main::flash_rom_address_boundary#1 = main::flash_rom_address_boundary#0 + main::flash_bytes#0 -- vdum1=vduz2_plus_vdum1 
    clc
    lda flash_rom_address_boundary_1
    adc.z flash_rom_address_boundary
    sta flash_rom_address_boundary_1
    lda flash_rom_address_boundary_1+1
    adc.z flash_rom_address_boundary+1
    sta flash_rom_address_boundary_1+1
    lda flash_rom_address_boundary_1+2
    adc.z flash_rom_address_boundary+2
    sta flash_rom_address_boundary_1+2
    lda flash_rom_address_boundary_1+3
    adc.z flash_rom_address_boundary+3
    sta flash_rom_address_boundary_1+3
    // main::bank_set_bram2
    // BRAM = bank
    // [222] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@58
    // size = rom_sizes[flash_chip]
    // [223] main::size#1 = main::rom_sizes[main::$164] -- vduz1=pduc1_derefidx_vbum2 
    // read from bank 1 in bram.
    ldy __164
    lda rom_sizes,y
    sta.z size
    lda rom_sizes+1,y
    sta.z size+1
    lda rom_sizes+2,y
    sta.z size+2
    lda rom_sizes+3,y
    sta.z size+3
    // size -= 0x4000
    // [224] main::size#2 = main::size#1 - $4000 -- vduz1=vduz1_minus_vduc1 
    lda.z size
    sec
    sbc #<$4000
    sta.z size
    lda.z size+1
    sbc #>$4000
    sta.z size+1
    lda.z size+2
    sbc #<$4000>>$10
    sta.z size+2
    lda.z size+3
    sbc #>$4000>>$10
    sta.z size+3
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [225] flash_read::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbuz1=vbum2_plus_1 
    lda flash_rom_bank
    inc
    sta.z flash_read.rom_bank_start
    // [226] flash_read::fp#1 = main::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z flash_read.fp
    lda fp+1
    sta.z flash_read.fp+1
    // [227] flash_read::read_size#1 = main::size#2
    // [228] call flash_read
    // [956] phi from main::@58 to flash_read [phi:main::@58->flash_read]
    // [956] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@58->flash_read#0] -- register_copy 
    // [956] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@58->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [956] phi flash_read::read_size#4 = flash_read::read_size#1 [phi:main::@58->flash_read#2] -- register_copy 
    // [956] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@58->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [229] flash_read::return#4 = flash_read::return#2
    // main::@122
    // flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [230] main::flash_bytes#1 = flash_read::return#4 -- vduz1=vduz2 
    lda.z flash_read.return
    sta.z flash_bytes_1
    lda.z flash_read.return+1
    sta.z flash_bytes_1+1
    lda.z flash_read.return+2
    sta.z flash_bytes_1+2
    lda.z flash_read.return+3
    sta.z flash_bytes_1+3
    // flash_rom_address_boundary += flash_bytes
    // [231] main::flash_rom_address_boundary#11 = main::flash_rom_address_boundary#1 + main::flash_bytes#1 -- vduz1=vdum2_plus_vduz1 
    clc
    lda.z flash_rom_address_boundary_2
    adc flash_rom_address_boundary_1
    sta.z flash_rom_address_boundary_2
    lda.z flash_rom_address_boundary_2+1
    adc flash_rom_address_boundary_1+1
    sta.z flash_rom_address_boundary_2+1
    lda.z flash_rom_address_boundary_2+2
    adc flash_rom_address_boundary_1+2
    sta.z flash_rom_address_boundary_2+2
    lda.z flash_rom_address_boundary_2+3
    adc flash_rom_address_boundary_1+3
    sta.z flash_rom_address_boundary_2+3
    // fclose(fp)
    // [232] fclose::fp#0 = main::fp#0
    // [233] call fclose
    jsr fclose
    // main::bank_set_bram3
    // BRAM = bank
    // [234] BRAM = main::bank_set_bram3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram3_bank
    sta.z BRAM
    // [235] phi from main::bank_set_bram3 to main::@59 [phi:main::bank_set_bram3->main::@59]
    // main::@59
    // bank_set_brom(4)
    // [236] call bank_set_brom
    // [818] phi from main::@59 to bank_set_brom [phi:main::@59->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 4 [phi:main::@59->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [237] phi from main::@59 to main::@123 [phi:main::@59->main::@123]
    // main::@123
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [238] call snprintf_init
    jsr snprintf_init
    // [239] phi from main::@123 to main::@124 [phi:main::@123->main::@124]
    // main::@124
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [240] call printf_str
    // [757] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s10 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@125
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [241] printf_uchar::uvalue#7 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [242] call printf_uchar
    // [837] phi from main::@125 to printf_uchar [phi:main::@125->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@125->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@125->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &snputc [phi:main::@125->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@125->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#7 [phi:main::@125->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [243] phi from main::@125 to main::@126 [phi:main::@125->main::@126]
    // main::@126
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [244] call printf_str
    // [757] phi from main::@126 to printf_str [phi:main::@126->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@126->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s11 [phi:main::@126->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@127
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [245] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [246] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [248] call print_text
    // [801] phi from main::@127 to print_text [phi:main::@127->print_text]
    jsr print_text
    // main::@128
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [249] rom_address::rom_bank#3 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [250] call rom_address
    // [952] phi from main::@128 to rom_address [phi:main::@128->rom_address]
    // [952] phi rom_address::rom_bank#5 = rom_address::rom_bank#3 [phi:main::@128->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [251] rom_address::return#11 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_3
    lda.z rom_address.return+1
    sta.z rom_address.return_3+1
    lda.z rom_address.return+2
    sta.z rom_address.return_3+2
    lda.z rom_address.return+3
    sta.z rom_address.return_3+3
    // main::@129
    // [252] main::flash_rom_address1#0 = rom_address::return#11
    // gotoxy(x, y)
    // [253] call gotoxy
    // [529] phi from main::@129 to gotoxy [phi:main::@129->gotoxy]
    // [529] phi gotoxy::y#24 = 4 [phi:main::@129->gotoxy#0] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = $e [phi:main::@129->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [255] phi from main::SEI2 to main::@20 [phi:main::SEI2->main::@20]
    // [255] phi main::y_sector#10 = 4 [phi:main::SEI2->main::@20#0] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector
    // [255] phi main::x_sector#10 = $e [phi:main::SEI2->main::@20#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [255] phi main::read_ram_address#10 = (char *) 16384 [phi:main::SEI2->main::@20#2] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address
    lda #>$4000
    sta.z read_ram_address+1
    // [255] phi main::read_ram_bank#13 = 0 [phi:main::SEI2->main::@20#3] -- vbuz1=vbuc1 
    lda #0
    sta.z read_ram_bank
    // [255] phi main::flash_rom_address1#13 = main::flash_rom_address1#0 [phi:main::SEI2->main::@20#4] -- register_copy 
    // [255] phi from main::@26 to main::@20 [phi:main::@26->main::@20]
    // [255] phi main::y_sector#10 = main::y_sector#10 [phi:main::@26->main::@20#0] -- register_copy 
    // [255] phi main::x_sector#10 = main::x_sector#1 [phi:main::@26->main::@20#1] -- register_copy 
    // [255] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@26->main::@20#2] -- register_copy 
    // [255] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@26->main::@20#3] -- register_copy 
    // [255] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@26->main::@20#4] -- register_copy 
    // main::@20
  __b20:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [256] if(main::flash_rom_address1#13<main::flash_rom_address_boundary#11) goto main::@21 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address1+3
    cmp.z flash_rom_address_boundary_2+3
    bcs !__b21+
    jmp __b21
  !__b21:
    bne !+
    lda.z flash_rom_address1+2
    cmp.z flash_rom_address_boundary_2+2
    bcs !__b21+
    jmp __b21
  !__b21:
    bne !+
    lda.z flash_rom_address1+1
    cmp.z flash_rom_address_boundary_2+1
    bcs !__b21+
    jmp __b21
  !__b21:
    bne !+
    lda.z flash_rom_address1
    cmp.z flash_rom_address_boundary_2
    bcs !__b21+
    jmp __b21
  !__b21:
  !:
    // [257] phi from main::@20 to main::@22 [phi:main::@20->main::@22]
    // main::@22
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [258] call snprintf_init
    jsr snprintf_init
    // [259] phi from main::@22 to main::@131 [phi:main::@22->main::@131]
    // main::@131
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [260] call printf_str
    // [757] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s12 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@132
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [261] printf_uchar::uvalue#8 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [262] call printf_uchar
    // [837] phi from main::@132 to printf_uchar [phi:main::@132->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@132->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@132->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &snputc [phi:main::@132->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@132->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#8 [phi:main::@132->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [263] phi from main::@132 to main::@133 [phi:main::@132->main::@133]
    // main::@133
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [264] call printf_str
    // [757] phi from main::@133 to printf_str [phi:main::@133->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@133->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s13 [phi:main::@133->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@134
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [265] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [266] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [268] call print_text
    // [801] phi from main::@134 to print_text [phi:main::@134->print_text]
    jsr print_text
    // [269] phi from main::@134 to main::@135 [phi:main::@134->main::@135]
    // main::@135
    // bank_set_brom(4)
    // [270] call bank_set_brom
    // [818] phi from main::@135 to bank_set_brom [phi:main::@135->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 4 [phi:main::@135->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [272] phi from main::CLI2 to main::@60 [phi:main::CLI2->main::@60]
    // main::@60
    // wait_key()
    // [273] call wait_key
    // [808] phi from main::@60 to wait_key [phi:main::@60->wait_key]
    jsr wait_key
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::@61
    // rom_address(flash_rom_bank)
    // [275] rom_address::rom_bank#4 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [276] call rom_address
    // [952] phi from main::@61 to rom_address [phi:main::@61->rom_address]
    // [952] phi rom_address::rom_bank#5 = rom_address::rom_bank#4 [phi:main::@61->rom_address#0] -- register_copy 
    jsr rom_address
    // rom_address(flash_rom_bank)
    // [277] rom_address::return#12 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_4
    lda.z rom_address.return+1
    sta.z rom_address.return_4+1
    lda.z rom_address.return+2
    sta.z rom_address.return_4+2
    lda.z rom_address.return+3
    sta.z rom_address.return_4+3
    // main::@136
    // flash_rom_address_sector = rom_address(flash_rom_bank)
    // [278] main::flash_rom_address_sector#1 = rom_address::return#12
    // textcolor(WHITE)
    // [279] call textcolor
    // [511] phi from main::@136 to textcolor [phi:main::@136->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@136->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@137
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [280] print_chip_led::r#7 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [281] call print_chip_led
    // [885] phi from main::@137 to print_chip_led [phi:main::@137->print_chip_led]
    // [885] phi print_chip_led::tc#10 = PURPLE [phi:main::@137->print_chip_led#0] -- vbuz1=vbuc1 
    lda #PURPLE
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#7 [phi:main::@137->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [282] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [283] call snprintf_init
    jsr snprintf_init
    // [284] phi from main::@138 to main::@139 [phi:main::@138->main::@139]
    // main::@139
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [285] call printf_str
    // [757] phi from main::@139 to printf_str [phi:main::@139->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@139->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s14 [phi:main::@139->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@140
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [286] printf_uchar::uvalue#9 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [287] call printf_uchar
    // [837] phi from main::@140 to printf_uchar [phi:main::@140->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@140->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@140->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &snputc [phi:main::@140->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@140->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#9 [phi:main::@140->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [288] phi from main::@140 to main::@141 [phi:main::@140->main::@141]
    // main::@141
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [289] call printf_str
    // [757] phi from main::@141 to printf_str [phi:main::@141->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@141->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s15 [phi:main::@141->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@142
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [290] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [291] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [293] call print_text
    // [801] phi from main::@142 to print_text [phi:main::@142->print_text]
    jsr print_text
    // [294] phi from main::@142 to main::@29 [phi:main::@142->main::@29]
    // [294] phi main::flash_errors_sector#10 = 0 [phi:main::@142->main::@29#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [294] phi main::y_sector1#13 = 4 [phi:main::@142->main::@29#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector1
    // [294] phi main::x_sector1#10 = $e [phi:main::@142->main::@29#2] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector1
    // [294] phi main::read_ram_address_sector#10 = (char *) 16384 [phi:main::@142->main::@29#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address_sector
    lda #>$4000
    sta.z read_ram_address_sector+1
    // [294] phi main::read_ram_bank_sector#13 = 0 [phi:main::@142->main::@29#4] -- vbuz1=vbuc1 
    lda #0
    sta.z read_ram_bank_sector
    // [294] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#1 [phi:main::@142->main::@29#5] -- register_copy 
    // [294] phi from main::@40 to main::@29 [phi:main::@40->main::@29]
    // [294] phi main::flash_errors_sector#10 = main::flash_errors_sector#19 [phi:main::@40->main::@29#0] -- register_copy 
    // [294] phi main::y_sector1#13 = main::y_sector1#13 [phi:main::@40->main::@29#1] -- register_copy 
    // [294] phi main::x_sector1#10 = main::x_sector1#1 [phi:main::@40->main::@29#2] -- register_copy 
    // [294] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@40->main::@29#3] -- register_copy 
    // [294] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@40->main::@29#4] -- register_copy 
    // [294] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@40->main::@29#5] -- register_copy 
    // main::@29
  __b29:
    // while (flash_rom_address_sector < flash_rom_address_boundary)
    // [295] if(main::flash_rom_address_sector#11<main::flash_rom_address_boundary#11) goto main::@30 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address_sector+3
    cmp.z flash_rom_address_boundary_2+3
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda.z flash_rom_address_sector+2
    cmp.z flash_rom_address_boundary_2+2
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda.z flash_rom_address_sector+1
    cmp.z flash_rom_address_boundary_2+1
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda.z flash_rom_address_sector
    cmp.z flash_rom_address_boundary_2
    bcs !__b30+
    jmp __b30
  !__b30:
  !:
    // main::bank_set_bram4
    // BRAM = bank
    // [296] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // [297] phi from main::bank_set_bram4 to main::@62 [phi:main::bank_set_bram4->main::@62]
    // main::@62
    // bank_set_brom(4)
    // [298] call bank_set_brom
    // [818] phi from main::@62 to bank_set_brom [phi:main::@62->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 4 [phi:main::@62->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@148
    // if (!flash_errors_sector)
    // [299] if(0==main::flash_errors_sector#10) goto main::@45 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    bne !__b45+
    jmp __b45
  !__b45:
    // [300] phi from main::@148 to main::@44 [phi:main::@148->main::@44]
    // main::@44
    // textcolor(RED)
    // [301] call textcolor
    // [511] phi from main::@44 to textcolor [phi:main::@44->textcolor]
    // [511] phi textcolor::color#24 = RED [phi:main::@44->textcolor#0] -- vbuz1=vbuc1 
    lda #RED
    sta.z textcolor.color
    jsr textcolor
    // [302] phi from main::@44 to main::@167 [phi:main::@44->main::@167]
    // main::@167
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [303] call snprintf_init
    jsr snprintf_init
    // [304] phi from main::@167 to main::@168 [phi:main::@167->main::@168]
    // main::@168
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [305] call printf_str
    // [757] phi from main::@168 to printf_str [phi:main::@168->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@168->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s17 [phi:main::@168->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@169
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [306] printf_uchar::uvalue#11 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [307] call printf_uchar
    // [837] phi from main::@169 to printf_uchar [phi:main::@169->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@169->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@169->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &snputc [phi:main::@169->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@169->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#11 [phi:main::@169->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [308] phi from main::@169 to main::@170 [phi:main::@169->main::@170]
    // main::@170
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [309] call printf_str
    // [757] phi from main::@170 to printf_str [phi:main::@170->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@170->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s20 [phi:main::@170->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@171
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [310] printf_uint::uvalue#2 = main::flash_errors_sector#10 -- vwuz1=vwuz2 
    lda.z flash_errors_sector
    sta.z printf_uint.uvalue
    lda.z flash_errors_sector+1
    sta.z printf_uint.uvalue+1
    // [311] call printf_uint
    // [1001] phi from main::@171 to printf_uint [phi:main::@171->printf_uint]
    // [1001] phi printf_uint::format_min_length#3 = 0 [phi:main::@171->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_min_length
    // [1001] phi printf_uint::putc#3 = &snputc [phi:main::@171->printf_uint#1] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1001] phi printf_uint::format_radix#3 = DECIMAL [phi:main::@171->printf_uint#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1001] phi printf_uint::uvalue#3 = printf_uint::uvalue#2 [phi:main::@171->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [312] phi from main::@171 to main::@172 [phi:main::@171->main::@172]
    // main::@172
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [313] call printf_str
    // [757] phi from main::@172 to printf_str [phi:main::@172->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@172->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s21 [phi:main::@172->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@173
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [314] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [315] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [317] call print_text
    // [801] phi from main::@173 to print_text [phi:main::@173->print_text]
    jsr print_text
    // main::@174
    // print_chip_led(flash_chip, RED, BLUE)
    // [318] print_chip_led::r#9 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [319] call print_chip_led
    // [885] phi from main::@174 to print_chip_led [phi:main::@174->print_chip_led]
    // [885] phi print_chip_led::tc#10 = RED [phi:main::@174->print_chip_led#0] -- vbuz1=vbuc1 
    lda #RED
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#9 [phi:main::@174->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp __b18
    // [320] phi from main::@148 to main::@45 [phi:main::@148->main::@45]
    // main::@45
  __b45:
    // textcolor(GREEN)
    // [321] call textcolor
    // [511] phi from main::@45 to textcolor [phi:main::@45->textcolor]
    // [511] phi textcolor::color#24 = GREEN [phi:main::@45->textcolor#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z textcolor.color
    jsr textcolor
    // [322] phi from main::@45 to main::@161 [phi:main::@45->main::@161]
    // main::@161
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [323] call snprintf_init
    jsr snprintf_init
    // [324] phi from main::@161 to main::@162 [phi:main::@161->main::@162]
    // main::@162
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [325] call printf_str
    // [757] phi from main::@162 to printf_str [phi:main::@162->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@162->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s17 [phi:main::@162->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@163
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [326] printf_uchar::uvalue#10 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [327] call printf_uchar
    // [837] phi from main::@163 to printf_uchar [phi:main::@163->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@163->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@163->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &snputc [phi:main::@163->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@163->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#10 [phi:main::@163->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [328] phi from main::@163 to main::@164 [phi:main::@163->main::@164]
    // main::@164
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [329] call printf_str
    // [757] phi from main::@164 to printf_str [phi:main::@164->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@164->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s18 [phi:main::@164->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@165
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [330] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [331] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [333] call print_text
    // [801] phi from main::@165 to print_text [phi:main::@165->print_text]
    jsr print_text
    // main::@166
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [334] print_chip_led::r#8 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [335] call print_chip_led
    // [885] phi from main::@166 to print_chip_led [phi:main::@166->print_chip_led]
    // [885] phi print_chip_led::tc#10 = GREEN [phi:main::@166->print_chip_led#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#8 [phi:main::@166->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp __b18
    // main::@30
  __b30:
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [336] flash_verify::bank_ram#1 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_verify.bank_ram
    // [337] flash_verify::ptr_ram#2 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address_sector+1
    sta.z flash_verify.ptr_ram+1
    // [338] flash_verify::verify_rom_address#1 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address_sector+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address_sector+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address_sector+3
    sta.z flash_verify.verify_rom_address+3
    // [339] call flash_verify
  // rom_sector_erase(flash_rom_address_sector);
    // [1011] phi from main::@30 to flash_verify [phi:main::@30->flash_verify]
    // [1011] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#2 [phi:main::@30->flash_verify#0] -- register_copy 
    // [1011] phi flash_verify::verify_rom_size#11 = $1000 [phi:main::@30->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z flash_verify.verify_rom_size
    lda #>$1000
    sta.z flash_verify.verify_rom_size+1
    // [1011] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#1 [phi:main::@30->flash_verify#2] -- register_copy 
    // [1011] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#1 [phi:main::@30->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [340] flash_verify::return#3 = flash_verify::correct_bytes#2
    // main::@147
    // [341] main::equal_bytes1#0 = flash_verify::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [342] if(main::equal_bytes1#0!=$1000) goto main::@32 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes1+1
    cmp #>$1000
    beq !__b8+
    jmp __b8
  !__b8:
    lda.z equal_bytes1
    cmp #<$1000
    beq !__b8+
    jmp __b8
  !__b8:
    // [343] phi from main::@147 to main::@41 [phi:main::@147->main::@41]
    // main::@41
    // textcolor(WHITE)
    // [344] call textcolor
    // [511] phi from main::@41 to textcolor [phi:main::@41->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@41->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@149
    // gotoxy(x_sector, y_sector)
    // [345] gotoxy::x#21 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z gotoxy.x
    // [346] gotoxy::y#21 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [347] call gotoxy
    // [529] phi from main::@149 to gotoxy [phi:main::@149->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#21 [phi:main::@149->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = gotoxy::x#21 [phi:main::@149->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [348] phi from main::@149 to main::@150 [phi:main::@149->main::@150]
    // main::@150
    // printf("%s", pattern)
    // [349] call printf_string
    // [930] phi from main::@150 to printf_string [phi:main::@150->printf_string]
    // [930] phi printf_string::str#10 = main::pattern1#1 [phi:main::@150->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern1_1
    sta.z printf_string.str
    lda #>pattern1_1
    sta.z printf_string.str+1
    // [930] phi printf_string::format_justify_left#10 = 0 [phi:main::@150->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [930] phi printf_string::format_min_length#7 = 0 [phi:main::@150->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [350] phi from main::@150 main::@38 to main::@31 [phi:main::@150/main::@38->main::@31]
    // [350] phi main::flash_errors_sector#19 = main::flash_errors_sector#10 [phi:main::@150/main::@38->main::@31#0] -- register_copy 
    // main::@31
  __b31:
    // read_ram_address_sector += ROM_SECTOR
    // [351] main::read_ram_address_sector#2 = main::read_ram_address_sector#10 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address_sector
    clc
    adc #<$1000
    sta.z read_ram_address_sector
    lda.z read_ram_address_sector+1
    adc #>$1000
    sta.z read_ram_address_sector+1
    // flash_rom_address_sector += ROM_SECTOR
    // [352] main::flash_rom_address_sector#10 = main::flash_rom_address_sector#11 + $1000 -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z flash_rom_address_sector
    adc #<$1000
    sta.z flash_rom_address_sector
    lda.z flash_rom_address_sector+1
    adc #>$1000
    sta.z flash_rom_address_sector+1
    lda.z flash_rom_address_sector+2
    adc #0
    sta.z flash_rom_address_sector+2
    lda.z flash_rom_address_sector+3
    adc #0
    sta.z flash_rom_address_sector+3
    // if (read_ram_address_sector == 0x8000)
    // [353] if(main::read_ram_address_sector#2!=$8000) goto main::@182 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$8000
    bne __b39
    lda.z read_ram_address_sector
    cmp #<$8000
    bne __b39
    // [355] phi from main::@31 to main::@39 [phi:main::@31->main::@39]
    // [355] phi main::read_ram_bank_sector#6 = 1 [phi:main::@31->main::@39#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank_sector
    // [355] phi main::read_ram_address_sector#8 = (char *) 40960 [phi:main::@31->main::@39#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [354] phi from main::@31 to main::@182 [phi:main::@31->main::@182]
    // main::@182
    // [355] phi from main::@182 to main::@39 [phi:main::@182->main::@39]
    // [355] phi main::read_ram_bank_sector#6 = main::read_ram_bank_sector#13 [phi:main::@182->main::@39#0] -- register_copy 
    // [355] phi main::read_ram_address_sector#8 = main::read_ram_address_sector#2 [phi:main::@182->main::@39#1] -- register_copy 
    // main::@39
  __b39:
    // if (read_ram_address_sector == 0xC000)
    // [356] if(main::read_ram_address_sector#8!=$c000) goto main::@40 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$c000
    bne __b40
    lda.z read_ram_address_sector
    cmp #<$c000
    bne __b40
    // main::@42
    // read_ram_bank_sector++;
    // [357] main::read_ram_bank_sector#3 = ++ main::read_ram_bank_sector#6 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank_sector
    // [358] phi from main::@42 to main::@40 [phi:main::@42->main::@40]
    // [358] phi main::read_ram_address_sector#14 = (char *) 40960 [phi:main::@42->main::@40#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [358] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#3 [phi:main::@42->main::@40#1] -- register_copy 
    // [358] phi from main::@39 to main::@40 [phi:main::@39->main::@40]
    // [358] phi main::read_ram_address_sector#14 = main::read_ram_address_sector#8 [phi:main::@39->main::@40#0] -- register_copy 
    // [358] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#6 [phi:main::@39->main::@40#1] -- register_copy 
    // main::@40
  __b40:
    // x_sector += 16
    // [359] main::x_sector1#1 = main::x_sector1#10 + $10 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$10
    clc
    adc.z x_sector1
    sta.z x_sector1
    // flash_rom_address_sector % 0x4000
    // [360] main::$137 = main::flash_rom_address_sector#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address_sector
    and #<$4000-1
    sta.z __137
    lda.z flash_rom_address_sector+1
    and #>$4000-1
    sta.z __137+1
    lda.z flash_rom_address_sector+2
    and #<$4000-1>>$10
    sta.z __137+2
    lda.z flash_rom_address_sector+3
    and #>$4000-1>>$10
    sta.z __137+3
    // if (!(flash_rom_address_sector % 0x4000))
    // [361] if(0!=main::$137) goto main::@29 -- 0_neq_vduz1_then_la1 
    lda.z __137
    ora.z __137+1
    ora.z __137+2
    ora.z __137+3
    beq !__b29+
    jmp __b29
  !__b29:
    // main::@43
    // y_sector++;
    // [362] main::y_sector1#1 = ++ main::y_sector1#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector1
    // [294] phi from main::@43 to main::@29 [phi:main::@43->main::@29]
    // [294] phi main::flash_errors_sector#10 = main::flash_errors_sector#19 [phi:main::@43->main::@29#0] -- register_copy 
    // [294] phi main::y_sector1#13 = main::y_sector1#1 [phi:main::@43->main::@29#1] -- register_copy 
    // [294] phi main::x_sector1#10 = $e [phi:main::@43->main::@29#2] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector1
    // [294] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@43->main::@29#3] -- register_copy 
    // [294] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@43->main::@29#4] -- register_copy 
    // [294] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@43->main::@29#5] -- register_copy 
    jmp __b29
    // [363] phi from main::@147 to main::@32 [phi:main::@147->main::@32]
  __b8:
    // [363] phi main::flash_errors#10 = 0 [phi:main::@147->main::@32#0] -- vbuz1=vbuc1 
    lda #0
    sta.z flash_errors
    // [363] phi main::retries#10 = 0 [phi:main::@147->main::@32#1] -- vbuz1=vbuc1 
    sta.z retries
    // [363] phi from main::@180 to main::@32 [phi:main::@180->main::@32]
    // [363] phi main::flash_errors#10 = main::flash_errors#11 [phi:main::@180->main::@32#0] -- register_copy 
    // [363] phi main::retries#10 = main::retries#1 [phi:main::@180->main::@32#1] -- register_copy 
    // main::@32
  __b32:
    // rom_sector_erase(flash_rom_address_sector)
    // [364] rom_sector_erase::address#0 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z rom_sector_erase.address
    lda.z flash_rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda.z flash_rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda.z flash_rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [365] call rom_sector_erase
    // [1038] phi from main::@32 to rom_sector_erase [phi:main::@32->rom_sector_erase]
    jsr rom_sector_erase
    // main::@151
    // unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR
    // [366] main::flash_rom_address_boundary1#0 = main::flash_rom_address_sector#11 + $1000 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z flash_rom_address_sector
    adc #<$1000
    sta.z flash_rom_address_boundary1
    lda.z flash_rom_address_sector+1
    adc #>$1000
    sta.z flash_rom_address_boundary1+1
    lda.z flash_rom_address_sector+2
    adc #0
    sta.z flash_rom_address_boundary1+2
    lda.z flash_rom_address_sector+3
    adc #0
    sta.z flash_rom_address_boundary1+3
    // gotoxy(x, y)
    // [367] gotoxy::x#22 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z gotoxy.x
    // [368] gotoxy::y#22 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [369] call gotoxy
    // [529] phi from main::@151 to gotoxy [phi:main::@151->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#22 [phi:main::@151->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = gotoxy::x#22 [phi:main::@151->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [370] phi from main::@151 to main::@152 [phi:main::@151->main::@152]
    // main::@152
    // printf("................")
    // [371] call printf_str
    // [757] phi from main::@152 to printf_str [phi:main::@152->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:main::@152->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s16 [phi:main::@152->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@153
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [372] print_address::bram_bank#1 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z print_address.bram_bank
    // [373] print_address::bram_ptr#1 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z print_address.bram_ptr
    lda.z read_ram_address_sector+1
    sta.z print_address.bram_ptr+1
    // [374] print_address::brom_address#1 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z print_address.brom_address
    lda.z flash_rom_address_sector+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address_sector+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address_sector+3
    sta.z print_address.brom_address+3
    // [375] call print_address
    // [1050] phi from main::@153 to print_address [phi:main::@153->print_address]
    // [1050] phi print_address::bram_ptr#10 = print_address::bram_ptr#1 [phi:main::@153->print_address#0] -- register_copy 
    // [1050] phi print_address::bram_bank#10 = print_address::bram_bank#1 [phi:main::@153->print_address#1] -- register_copy 
    // [1050] phi print_address::brom_address#10 = print_address::brom_address#1 [phi:main::@153->print_address#2] -- register_copy 
    jsr print_address
    // main::@154
    // [376] main::flash_rom_address2#16 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_rom_address2
    lda.z flash_rom_address_sector+1
    sta.z flash_rom_address2+1
    lda.z flash_rom_address_sector+2
    sta.z flash_rom_address2+2
    lda.z flash_rom_address_sector+3
    sta.z flash_rom_address2+3
    // [377] main::read_ram_address1#16 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z read_ram_address1
    lda.z read_ram_address_sector+1
    sta.z read_ram_address1+1
    // [378] main::x1#16 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z x1
    // [379] phi from main::@154 main::@160 to main::@33 [phi:main::@154/main::@160->main::@33]
    // [379] phi main::x1#10 = main::x1#16 [phi:main::@154/main::@160->main::@33#0] -- register_copy 
    // [379] phi main::flash_errors#11 = main::flash_errors#10 [phi:main::@154/main::@160->main::@33#1] -- register_copy 
    // [379] phi main::read_ram_address1#10 = main::read_ram_address1#16 [phi:main::@154/main::@160->main::@33#2] -- register_copy 
    // [379] phi main::flash_rom_address2#11 = main::flash_rom_address2#16 [phi:main::@154/main::@160->main::@33#3] -- register_copy 
    // main::@33
  __b33:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [380] if(main::flash_rom_address2#11<main::flash_rom_address_boundary1#0) goto main::@34 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address2+3
    cmp.z flash_rom_address_boundary1+3
    bcc __b34
    bne !+
    lda.z flash_rom_address2+2
    cmp.z flash_rom_address_boundary1+2
    bcc __b34
    bne !+
    lda.z flash_rom_address2+1
    cmp.z flash_rom_address_boundary1+1
    bcc __b34
    bne !+
    lda.z flash_rom_address2
    cmp.z flash_rom_address_boundary1
    bcc __b34
  !:
    // main::@35
    // retries++;
    // [381] main::retries#1 = ++ main::retries#10 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors && retries <= 3)
    // [382] if(0==main::flash_errors#11) goto main::@38 -- 0_eq_vbuz1_then_la1 
    lda.z flash_errors
    beq __b38
    // main::@180
    // [383] if(main::retries#1<3+1) goto main::@32 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b32+
    jmp __b32
  !__b32:
    // main::@38
  __b38:
    // flash_errors_sector += flash_errors
    // [384] main::flash_errors_sector#1 = main::flash_errors_sector#10 + main::flash_errors#11 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z flash_errors
    clc
    adc.z flash_errors_sector
    sta.z flash_errors_sector
    bcc !+
    inc.z flash_errors_sector+1
  !:
    jmp __b31
    // main::@34
  __b34:
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [385] print_address::bram_bank#2 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z print_address.bram_bank
    // [386] print_address::bram_ptr#2 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z print_address.bram_ptr
    lda.z read_ram_address1+1
    sta.z print_address.bram_ptr+1
    // [387] print_address::brom_address#2 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z print_address.brom_address
    lda.z flash_rom_address2+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address2+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address2+3
    sta.z print_address.brom_address+3
    // [388] call print_address
    // [1050] phi from main::@34 to print_address [phi:main::@34->print_address]
    // [1050] phi print_address::bram_ptr#10 = print_address::bram_ptr#2 [phi:main::@34->print_address#0] -- register_copy 
    // [1050] phi print_address::bram_bank#10 = print_address::bram_bank#2 [phi:main::@34->print_address#1] -- register_copy 
    // [1050] phi print_address::brom_address#10 = print_address::brom_address#2 [phi:main::@34->print_address#2] -- register_copy 
    jsr print_address
    // main::@155
    // unsigned long written_bytes = flash_write(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address)
    // [389] flash_write::flash_ram_bank#0 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_write.flash_ram_bank
    // [390] flash_write::flash_ram_address#1 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_write.flash_ram_address
    lda.z read_ram_address1+1
    sta.z flash_write.flash_ram_address+1
    // [391] flash_write::flash_rom_address#1 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z flash_write.flash_rom_address
    lda.z flash_rom_address2+1
    sta.z flash_write.flash_rom_address+1
    lda.z flash_rom_address2+2
    sta.z flash_write.flash_rom_address+2
    lda.z flash_rom_address2+3
    sta.z flash_write.flash_rom_address+3
    // [392] call flash_write
    jsr flash_write
    // main::@156
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [393] flash_verify::bank_ram#2 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_verify.bank_ram
    // [394] flash_verify::ptr_ram#3 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address1+1
    sta.z flash_verify.ptr_ram+1
    // [395] flash_verify::verify_rom_address#2 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address2+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address2+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address2+3
    sta.z flash_verify.verify_rom_address+3
    // [396] call flash_verify
    // [1011] phi from main::@156 to flash_verify [phi:main::@156->flash_verify]
    // [1011] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#3 [phi:main::@156->flash_verify#0] -- register_copy 
    // [1011] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@156->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    // [1011] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#2 [phi:main::@156->flash_verify#2] -- register_copy 
    // [1011] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#2 [phi:main::@156->flash_verify#3] -- register_copy 
    jsr flash_verify
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [397] flash_verify::return#4 = flash_verify::correct_bytes#2
    // main::@157
    // equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [398] main::equal_bytes1#1 = flash_verify::return#4
    // if (equal_bytes != 0x0100)
    // [399] if(main::equal_bytes1#1!=$100) goto main::@36 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes1+1
    cmp #>$100
    bne __b36
    lda.z equal_bytes1
    cmp #<$100
    bne __b36
    // [401] phi from main::@157 to main::@37 [phi:main::@157->main::@37]
    // [401] phi main::flash_errors#12 = main::flash_errors#11 [phi:main::@157->main::@37#0] -- register_copy 
    // [401] phi main::pattern1#5 = main::pattern1#3 [phi:main::@157->main::@37#1] -- pbuz1=pbuc1 
    lda #<pattern1_3
    sta.z pattern1
    lda #>pattern1_3
    sta.z pattern1+1
    jmp __b37
    // main::@36
  __b36:
    // flash_errors++;
    // [400] main::flash_errors#1 = ++ main::flash_errors#11 -- vbuz1=_inc_vbuz1 
    inc.z flash_errors
    // [401] phi from main::@36 to main::@37 [phi:main::@36->main::@37]
    // [401] phi main::flash_errors#12 = main::flash_errors#1 [phi:main::@36->main::@37#0] -- register_copy 
    // [401] phi main::pattern1#5 = main::pattern1#2 [phi:main::@36->main::@37#1] -- pbuz1=pbuc1 
    lda #<pattern1_2
    sta.z pattern1
    lda #>pattern1_2
    sta.z pattern1+1
    // main::@37
  __b37:
    // read_ram_address += 0x0100
    // [402] main::read_ram_address1#1 = main::read_ram_address1#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address1
    clc
    adc #<$100
    sta.z read_ram_address1
    lda.z read_ram_address1+1
    adc #>$100
    sta.z read_ram_address1+1
    // flash_rom_address += 0x0100
    // [403] main::flash_rom_address2#1 = main::flash_rom_address2#11 + $100 -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z flash_rom_address2
    adc #<$100
    sta.z flash_rom_address2
    lda.z flash_rom_address2+1
    adc #>$100
    sta.z flash_rom_address2+1
    lda.z flash_rom_address2+2
    adc #0
    sta.z flash_rom_address2+2
    lda.z flash_rom_address2+3
    adc #0
    sta.z flash_rom_address2+3
    // textcolor(WHITE)
    // [404] call textcolor
    // [511] phi from main::@37 to textcolor [phi:main::@37->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@37->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@158
    // gotoxy(x, y)
    // [405] gotoxy::x#23 = main::x1#10 -- vbuz1=vbuz2 
    lda.z x1
    sta.z gotoxy.x
    // [406] gotoxy::y#23 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [407] call gotoxy
    // [529] phi from main::@158 to gotoxy [phi:main::@158->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#23 [phi:main::@158->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = gotoxy::x#23 [phi:main::@158->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@159
    // printf("%s", pattern)
    // [408] printf_string::str#6 = main::pattern1#5
    // [409] call printf_string
    // [930] phi from main::@159 to printf_string [phi:main::@159->printf_string]
    // [930] phi printf_string::str#10 = printf_string::str#6 [phi:main::@159->printf_string#0] -- register_copy 
    // [930] phi printf_string::format_justify_left#10 = 0 [phi:main::@159->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [930] phi printf_string::format_min_length#7 = 0 [phi:main::@159->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@160
    // x++;
    // [410] main::x1#1 = ++ main::x1#10 -- vbuz1=_inc_vbuz1 
    inc.z x1
    jmp __b33
    // main::@21
  __b21:
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [411] flash_verify::bank_ram#0 = main::read_ram_bank#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank
    sta.z flash_verify.bank_ram
    // [412] flash_verify::ptr_ram#1 = main::read_ram_address#10 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address+1
    sta.z flash_verify.ptr_ram+1
    // [413] flash_verify::verify_rom_address#0 = main::flash_rom_address1#13 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address1+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address1+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address1+3
    sta.z flash_verify.verify_rom_address+3
    // [414] call flash_verify
    // [1011] phi from main::@21 to flash_verify [phi:main::@21->flash_verify]
    // [1011] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#1 [phi:main::@21->flash_verify#0] -- register_copy 
    // [1011] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@21->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    // [1011] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#0 [phi:main::@21->flash_verify#2] -- register_copy 
    // [1011] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#0 [phi:main::@21->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [415] flash_verify::return#2 = flash_verify::correct_bytes#2
    // main::@130
    // [416] main::equal_bytes#0 = flash_verify::return#2
    // if (equal_bytes != 0x0100)
    // [417] if(main::equal_bytes#0!=$100) goto main::@23 -- vwuz1_neq_vwuc1_then_la1 
    // unsigned long equal_bytes = 0x100;
    lda.z equal_bytes+1
    cmp #>$100
    bne __b23
    lda.z equal_bytes
    cmp #<$100
    bne __b23
    // [419] phi from main::@130 to main::@24 [phi:main::@130->main::@24]
    // [419] phi main::pattern#3 = main::pattern#2 [phi:main::@130->main::@24#0] -- pbuz1=pbuc1 
    lda #<pattern_2
    sta.z pattern
    lda #>pattern_2
    sta.z pattern+1
    jmp __b24
    // [418] phi from main::@130 to main::@23 [phi:main::@130->main::@23]
    // main::@23
  __b23:
    // [419] phi from main::@23 to main::@24 [phi:main::@23->main::@24]
    // [419] phi main::pattern#3 = main::pattern#1 [phi:main::@23->main::@24#0] -- pbuz1=pbuc1 
    lda #<pattern_1
    sta.z pattern
    lda #>pattern_1
    sta.z pattern+1
    // main::@24
  __b24:
    // read_ram_address += 0x0100
    // [420] main::read_ram_address#1 = main::read_ram_address#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address
    clc
    adc #<$100
    sta.z read_ram_address
    lda.z read_ram_address+1
    adc #>$100
    sta.z read_ram_address+1
    // flash_rom_address += 0x0100
    // [421] main::flash_rom_address1#1 = main::flash_rom_address1#13 + $100 -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z flash_rom_address1
    adc #<$100
    sta.z flash_rom_address1
    lda.z flash_rom_address1+1
    adc #>$100
    sta.z flash_rom_address1+1
    lda.z flash_rom_address1+2
    adc #0
    sta.z flash_rom_address1+2
    lda.z flash_rom_address1+3
    adc #0
    sta.z flash_rom_address1+3
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [422] print_address::bram_bank#0 = main::read_ram_bank#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank
    sta.z print_address.bram_bank
    // [423] print_address::bram_ptr#0 = main::read_ram_address#1 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z print_address.bram_ptr
    lda.z read_ram_address+1
    sta.z print_address.bram_ptr+1
    // [424] print_address::brom_address#0 = main::flash_rom_address1#1 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z print_address.brom_address
    lda.z flash_rom_address1+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address1+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address1+3
    sta.z print_address.brom_address+3
    // [425] call print_address
    // [1050] phi from main::@24 to print_address [phi:main::@24->print_address]
    // [1050] phi print_address::bram_ptr#10 = print_address::bram_ptr#0 [phi:main::@24->print_address#0] -- register_copy 
    // [1050] phi print_address::bram_bank#10 = print_address::bram_bank#0 [phi:main::@24->print_address#1] -- register_copy 
    // [1050] phi print_address::brom_address#10 = print_address::brom_address#0 [phi:main::@24->print_address#2] -- register_copy 
    jsr print_address
    // [426] phi from main::@24 to main::@143 [phi:main::@24->main::@143]
    // main::@143
    // textcolor(WHITE)
    // [427] call textcolor
    // [511] phi from main::@143 to textcolor [phi:main::@143->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@143->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@144
    // gotoxy(x_sector, y_sector)
    // [428] gotoxy::x#20 = main::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z gotoxy.x
    // [429] gotoxy::y#20 = main::y_sector#10 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z gotoxy.y
    // [430] call gotoxy
    // [529] phi from main::@144 to gotoxy [phi:main::@144->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#20 [phi:main::@144->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = gotoxy::x#20 [phi:main::@144->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@145
    // printf("%s", pattern)
    // [431] printf_string::str#4 = main::pattern#3 -- pbuz1=pbuz2 
    lda.z pattern
    sta.z printf_string.str
    lda.z pattern+1
    sta.z printf_string.str+1
    // [432] call printf_string
    // [930] phi from main::@145 to printf_string [phi:main::@145->printf_string]
    // [930] phi printf_string::str#10 = printf_string::str#4 [phi:main::@145->printf_string#0] -- register_copy 
    // [930] phi printf_string::format_justify_left#10 = 0 [phi:main::@145->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [930] phi printf_string::format_min_length#7 = 0 [phi:main::@145->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@146
    // x_sector++;
    // [433] main::x_sector#1 = ++ main::x_sector#10 -- vbuz1=_inc_vbuz1 
    inc.z x_sector
    // if (read_ram_address == 0x8000)
    // [434] if(main::read_ram_address#1!=$8000) goto main::@181 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$8000
    bne __b25
    lda.z read_ram_address
    cmp #<$8000
    bne __b25
    // [436] phi from main::@146 to main::@25 [phi:main::@146->main::@25]
    // [436] phi main::read_ram_bank#5 = 1 [phi:main::@146->main::@25#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank
    // [436] phi main::read_ram_address#7 = (char *) 40960 [phi:main::@146->main::@25#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [435] phi from main::@146 to main::@181 [phi:main::@146->main::@181]
    // main::@181
    // [436] phi from main::@181 to main::@25 [phi:main::@181->main::@25]
    // [436] phi main::read_ram_bank#5 = main::read_ram_bank#13 [phi:main::@181->main::@25#0] -- register_copy 
    // [436] phi main::read_ram_address#7 = main::read_ram_address#1 [phi:main::@181->main::@25#1] -- register_copy 
    // main::@25
  __b25:
    // if (read_ram_address == 0xC000)
    // [437] if(main::read_ram_address#7!=$c000) goto main::@26 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$c000
    bne __b26
    lda.z read_ram_address
    cmp #<$c000
    bne __b26
    // main::@27
    // read_ram_bank++;
    // [438] main::read_ram_bank#2 = ++ main::read_ram_bank#5 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank
    // [439] phi from main::@27 to main::@26 [phi:main::@27->main::@26]
    // [439] phi main::read_ram_address#12 = (char *) 40960 [phi:main::@27->main::@26#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [439] phi main::read_ram_bank#10 = main::read_ram_bank#2 [phi:main::@27->main::@26#1] -- register_copy 
    // [439] phi from main::@25 to main::@26 [phi:main::@25->main::@26]
    // [439] phi main::read_ram_address#12 = main::read_ram_address#7 [phi:main::@25->main::@26#0] -- register_copy 
    // [439] phi main::read_ram_bank#10 = main::read_ram_bank#5 [phi:main::@25->main::@26#1] -- register_copy 
    // main::@26
  __b26:
    // flash_rom_address % 0x4000
    // [440] main::$98 = main::flash_rom_address1#1 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address1
    and #<$4000-1
    sta.z __98
    lda.z flash_rom_address1+1
    and #>$4000-1
    sta.z __98+1
    lda.z flash_rom_address1+2
    and #<$4000-1>>$10
    sta.z __98+2
    lda.z flash_rom_address1+3
    and #>$4000-1>>$10
    sta.z __98+3
    // if (!(flash_rom_address % 0x4000))
    // [441] if(0!=main::$98) goto main::@20 -- 0_neq_vduz1_then_la1 
    lda.z __98
    ora.z __98+1
    ora.z __98+2
    ora.z __98+3
    beq !__b20+
    jmp __b20
  !__b20:
    // main::@28
    // y_sector++;
    // [442] main::y_sector#1 = ++ main::y_sector#10 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [255] phi from main::@28 to main::@20 [phi:main::@28->main::@20]
    // [255] phi main::y_sector#10 = main::y_sector#1 [phi:main::@28->main::@20#0] -- register_copy 
    // [255] phi main::x_sector#10 = $e [phi:main::@28->main::@20#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [255] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@28->main::@20#2] -- register_copy 
    // [255] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@28->main::@20#3] -- register_copy 
    // [255] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@28->main::@20#4] -- register_copy 
    jmp __b20
    // [443] phi from main::@93 to main::@15 [phi:main::@93->main::@15]
    // main::@15
  __b15:
    // sprintf(file, "rom.bin", flash_chip)
    // [444] call snprintf_init
    jsr snprintf_init
    // [445] phi from main::@15 to main::@94 [phi:main::@15->main::@94]
    // main::@94
    // sprintf(file, "rom.bin", flash_chip)
    // [446] call printf_str
    // [757] phi from main::@94 to printf_str [phi:main::@94->printf_str]
    // [757] phi printf_str::putc#33 = &snputc [phi:main::@94->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = main::s2 [phi:main::@94->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@95
    // sprintf(file, "rom.bin", flash_chip)
    // [447] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [448] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b16
    // main::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [450] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [451] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0x90)
    // [452] rom_unlock::address#3 = main::flash_rom_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z flash_rom_address
    adc #<$5555
    sta.z rom_unlock.address
    lda.z flash_rom_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda.z flash_rom_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda.z flash_rom_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [453] call rom_unlock
    // [1096] phi from main::@2 to rom_unlock [phi:main::@2->rom_unlock]
    // [1096] phi rom_unlock::unlock_code#5 = $90 [phi:main::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1096] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:main::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // main::@72
    // rom_read_byte(flash_rom_address)
    // [454] rom_read_byte::address#0 = main::flash_rom_address#10 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_read_byte.address
    lda.z flash_rom_address+1
    sta.z rom_read_byte.address+1
    lda.z flash_rom_address+2
    sta.z rom_read_byte.address+2
    lda.z flash_rom_address+3
    sta.z rom_read_byte.address+3
    // [455] call rom_read_byte
    // [1106] phi from main::@72 to rom_read_byte [phi:main::@72->rom_read_byte]
    // [1106] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:main::@72->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(flash_rom_address)
    // [456] rom_read_byte::return#2 = rom_read_byte::return#0
    // main::@73
    // [457] main::$20 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(flash_rom_address)
    // [458] main::rom_manufacturer_ids[main::rom_chip#10] = main::$20 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z __20
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(flash_rom_address + 1)
    // [459] rom_read_byte::address#1 = main::flash_rom_address#10 + 1 -- vduz1=vduz2_plus_1 
    lda.z flash_rom_address
    clc
    adc #1
    sta.z rom_read_byte.address
    lda.z flash_rom_address+1
    adc #0
    sta.z rom_read_byte.address+1
    lda.z flash_rom_address+2
    adc #0
    sta.z rom_read_byte.address+2
    lda.z flash_rom_address+3
    adc #0
    sta.z rom_read_byte.address+3
    // [460] call rom_read_byte
    // [1106] phi from main::@73 to rom_read_byte [phi:main::@73->rom_read_byte]
    // [1106] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:main::@73->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(flash_rom_address + 1)
    // [461] rom_read_byte::return#3 = rom_read_byte::return#0
    // main::@74
    // [462] main::$22 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(flash_rom_address + 1)
    // [463] main::rom_device_ids[main::rom_chip#10] = main::$22 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z __22
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0xF0)
    // [464] rom_unlock::address#4 = main::flash_rom_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z flash_rom_address
    adc #<$5555
    sta.z rom_unlock.address
    lda.z flash_rom_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda.z flash_rom_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda.z flash_rom_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [465] call rom_unlock
    // [1096] phi from main::@74 to rom_unlock [phi:main::@74->rom_unlock]
    // [1096] phi rom_unlock::unlock_code#5 = $f0 [phi:main::@74->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1096] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:main::@74->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // [466] phi from main::@74 to main::@75 [phi:main::@74->main::@75]
    // main::@75
    // bank_set_brom(4)
    // [467] call bank_set_brom
  // Ensure the ROM is set to BASIC.
    // [818] phi from main::@75 to bank_set_brom [phi:main::@75->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 4 [phi:main::@75->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@76
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_KB(rom_chip, "128");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [468] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@3 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip
    lda rom_device_ids,y
    cmp #$b5
    bne !__b3+
    jmp __b3
  !__b3:
    // main::@9
    // case SST39SF020A:
    //             rom_device = "f020a";
    //             print_chip_KB(rom_chip, "256");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             rom_sizes[rom_chip] = 256 * 1024;
    //             break;
    // [469] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@4 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b6
    bne !__b4+
    jmp __b4
  !__b4:
    // main::@10
    // case SST39SF040:
    //             rom_device = "f040";
    //             print_chip_KB(rom_chip, "512");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             rom_sizes[rom_chip] = 512 * 1024;
    //             break;
    // [470] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@5 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b5+
    jmp __b5
  !__b5:
    // main::@6
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [471] print_chip_led::r#4 = main::rom_chip#10 -- vbuz1=vbuz2 
    tya
    sta.z print_chip_led.r
    // [472] call print_chip_led
    // [885] phi from main::@6 to print_chip_led [phi:main::@6->print_chip_led]
    // [885] phi print_chip_led::tc#10 = BLACK [phi:main::@6->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#4 [phi:main::@6->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@86
    // rom_device_ids[rom_chip] = UNKNOWN
    // [473] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // [474] phi from main::@86 to main::@7 [phi:main::@86->main::@7]
    // [474] phi main::rom_device#5 = main::rom_device#13 [phi:main::@86->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_4
    sta rom_device
    lda #>rom_device_4
    sta rom_device+1
    // main::@7
  __b7:
    // textcolor(WHITE)
    // [475] call textcolor
    // [511] phi from main::@7 to textcolor [phi:main::@7->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:main::@7->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@87
    // rom_chip * 10
    // [476] main::$179 = main::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z __179
    // [477] main::$180 = main::$179 + main::rom_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z __180
    clc
    adc.z rom_chip
    sta.z __180
    // [478] main::$38 = main::$180 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __38
    // gotoxy(2 + rom_chip * 10, 56)
    // [479] gotoxy::x#14 = 2 + main::$38 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __38
    sta.z gotoxy.x
    // [480] call gotoxy
    // [529] phi from main::@87 to gotoxy [phi:main::@87->gotoxy]
    // [529] phi gotoxy::y#24 = $38 [phi:main::@87->gotoxy#0] -- vbuz1=vbuc1 
    lda #$38
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = gotoxy::x#14 [phi:main::@87->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@88
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [481] printf_uchar::uvalue#3 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip
    lda rom_manufacturer_ids,y
    sta.z printf_uchar.uvalue
    // [482] call printf_uchar
    // [837] phi from main::@88 to printf_uchar [phi:main::@88->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@88->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 0 [phi:main::@88->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &cputc [phi:main::@88->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = HEXADECIMAL [phi:main::@88->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#3 [phi:main::@88->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // main::@89
    // gotoxy(2 + rom_chip * 10, 57)
    // [483] gotoxy::x#15 = 2 + main::$38 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __38
    sta.z gotoxy.x
    // [484] call gotoxy
    // [529] phi from main::@89 to gotoxy [phi:main::@89->gotoxy]
    // [529] phi gotoxy::y#24 = $39 [phi:main::@89->gotoxy#0] -- vbuz1=vbuc1 
    lda #$39
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = gotoxy::x#15 [phi:main::@89->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@90
    // printf("%s", rom_device)
    // [485] printf_string::str#2 = main::rom_device#5 -- pbuz1=pbum2 
    lda rom_device
    sta.z printf_string.str
    lda rom_device+1
    sta.z printf_string.str+1
    // [486] call printf_string
    // [930] phi from main::@90 to printf_string [phi:main::@90->printf_string]
    // [930] phi printf_string::str#10 = printf_string::str#2 [phi:main::@90->printf_string#0] -- register_copy 
    // [930] phi printf_string::format_justify_left#10 = 0 [phi:main::@90->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [930] phi printf_string::format_min_length#7 = 0 [phi:main::@90->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@91
    // rom_chip++;
    // [487] main::rom_chip#1 = ++ main::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // main::@8
    // flash_rom_address += 0x80000
    // [488] main::flash_rom_address#1 = main::flash_rom_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
    clc
    lda.z flash_rom_address
    adc #<$80000
    sta.z flash_rom_address
    lda.z flash_rom_address+1
    adc #>$80000
    sta.z flash_rom_address+1
    lda.z flash_rom_address+2
    adc #<$80000>>$10
    sta.z flash_rom_address+2
    lda.z flash_rom_address+3
    adc #>$80000>>$10
    sta.z flash_rom_address+3
    // [91] phi from main::@8 to main::@1 [phi:main::@8->main::@1]
    // [91] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@8->main::@1#0] -- register_copy 
    // [91] phi main::flash_rom_address#10 = main::flash_rom_address#1 [phi:main::@8->main::@1#1] -- register_copy 
    jmp __b1
    // main::@5
  __b5:
    // print_chip_KB(rom_chip, "512")
    // [489] print_chip_KB::rom_chip#2 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_KB.rom_chip
    // [490] call print_chip_KB
    // [1119] phi from main::@5 to print_chip_KB [phi:main::@5->print_chip_KB]
    // [1119] phi print_chip_KB::kb#3 = main::kb2 [phi:main::@5->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb2
    sta.z print_chip_KB.kb
    lda #>kb2
    sta.z print_chip_KB.kb+1
    // [1119] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#2 [phi:main::@5->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@84
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [491] print_chip_led::r#3 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_led.r
    // [492] call print_chip_led
    // [885] phi from main::@84 to print_chip_led [phi:main::@84->print_chip_led]
    // [885] phi print_chip_led::tc#10 = WHITE [phi:main::@84->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#3 [phi:main::@84->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@85
    // rom_sizes[rom_chip] = 512 * 1024
    // [493] main::$163 = main::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z __163
    // [494] main::rom_sizes[main::$163] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$200*$400
    sta rom_sizes,y
    lda #>$200*$400
    sta rom_sizes+1,y
    lda #<$200*$400>>$10
    sta rom_sizes+2,y
    lda #>$200*$400>>$10
    sta rom_sizes+3,y
    // [474] phi from main::@85 to main::@7 [phi:main::@85->main::@7]
    // [474] phi main::rom_device#5 = main::rom_device#12 [phi:main::@85->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_3
    sta rom_device
    lda #>rom_device_3
    sta rom_device+1
    jmp __b7
    // main::@4
  __b4:
    // print_chip_KB(rom_chip, "256")
    // [495] print_chip_KB::rom_chip#1 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_KB.rom_chip
    // [496] call print_chip_KB
    // [1119] phi from main::@4 to print_chip_KB [phi:main::@4->print_chip_KB]
    // [1119] phi print_chip_KB::kb#3 = main::kb1 [phi:main::@4->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb1
    sta.z print_chip_KB.kb
    lda #>kb1
    sta.z print_chip_KB.kb+1
    // [1119] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#1 [phi:main::@4->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@82
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [497] print_chip_led::r#2 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_led.r
    // [498] call print_chip_led
    // [885] phi from main::@82 to print_chip_led [phi:main::@82->print_chip_led]
    // [885] phi print_chip_led::tc#10 = WHITE [phi:main::@82->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#2 [phi:main::@82->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@83
    // rom_sizes[rom_chip] = 256 * 1024
    // [499] main::$162 = main::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z __162
    // [500] main::rom_sizes[main::$162] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$100*$400
    sta rom_sizes,y
    lda #>$100*$400
    sta rom_sizes+1,y
    lda #<$100*$400>>$10
    sta rom_sizes+2,y
    lda #>$100*$400>>$10
    sta rom_sizes+3,y
    // [474] phi from main::@83 to main::@7 [phi:main::@83->main::@7]
    // [474] phi main::rom_device#5 = main::rom_device#11 [phi:main::@83->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_2
    sta rom_device
    lda #>rom_device_2
    sta rom_device+1
    jmp __b7
    // main::@3
  __b3:
    // print_chip_KB(rom_chip, "128")
    // [501] print_chip_KB::rom_chip#0 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_KB.rom_chip
    // [502] call print_chip_KB
    // [1119] phi from main::@3 to print_chip_KB [phi:main::@3->print_chip_KB]
    // [1119] phi print_chip_KB::kb#3 = main::kb [phi:main::@3->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb
    sta.z print_chip_KB.kb
    lda #>kb
    sta.z print_chip_KB.kb+1
    // [1119] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#0 [phi:main::@3->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@80
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [503] print_chip_led::r#1 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_led.r
    // [504] call print_chip_led
    // [885] phi from main::@80 to print_chip_led [phi:main::@80->print_chip_led]
    // [885] phi print_chip_led::tc#10 = WHITE [phi:main::@80->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#1 [phi:main::@80->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@81
    // rom_sizes[rom_chip] = 128 * 1024
    // [505] main::$161 = main::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z __161
    // [506] main::rom_sizes[main::$161] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$80*$400
    sta rom_sizes,y
    lda #>$80*$400
    sta rom_sizes+1,y
    lda #<$80*$400>>$10
    sta rom_sizes+2,y
    lda #>$80*$400>>$10
    sta rom_sizes+3,y
    // [474] phi from main::@81 to main::@7 [phi:main::@81->main::@7]
    // [474] phi main::rom_device#5 = main::rom_device#1 [phi:main::@81->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_1
    sta rom_device
    lda #>rom_device_1
    sta rom_device+1
    jmp __b7
  .segment Data
    buffer: .text ""
    .byte 0
    .fill $9f, 0
    rom_device_ids: .byte 0
    .fill 7, 0
    rom_manufacturer_ids: .byte 0
    .fill 7, 0
    rom_sizes: .dword 0
    .fill 4*7, 0
    s: .text "commander x16 rom flash utility"
    .byte 0
    s1: .text "press a key to start flashing."
    .byte 0
    kb: .text "128"
    .byte 0
    kb1: .text "256"
    .byte 0
    kb2: .text "512"
    .byte 0
    s2: .text "rom.bin"
    .byte 0
    s3: .text "rom"
    .byte 0
    s4: .text ".bin"
    .byte 0
    s5: .text "reading file for rom"
    .byte 0
    s6: .text " in ram ..."
    .byte 0
    s7: .text "there is no file on the sdcard to flash rom"
    .byte 0
    s8: .text ". press a key ..."
    .byte 0
    s9: .text "no file"
    .byte 0
    s10: .text "verifying rom"
    .byte 0
    s11: .text " with file ... (.) same, (*) different."
    .byte 0
    s12: .text "verified rom"
    .byte 0
    s13: .text " ... (.) same, (*) different. press a key to flash ..."
    .byte 0
    s14: .text "flashing rom"
    .byte 0
    s15: .text " from ram ... (-) unchanged, (+) flashed, (!) error."
    .byte 0
    s16: .text "................"
    .byte 0
    s17: .text "the flashing of rom"
    .byte 0
    s18: .text " went perfectly ok. press a key ..."
    .byte 0
    s20: .text " went wrong, "
    .byte 0
    s21: .text " errors. press a key ..."
    .byte 0
    s22: .text "resetting commander x16 ("
    .byte 0
    s23: .text ")"
    .byte 0
    rom_device_1: .text "f010a"
    .byte 0
    rom_device_2: .text "f020a"
    .byte 0
    rom_device_3: .text "f040"
    .byte 0
    rom_device_4: .text "----"
    .byte 0
    pattern_1: .text "*"
    .byte 0
    pattern_2: .text "."
    .byte 0
    pattern1_1: .text "----------------"
    .byte 0
    pattern1_2: .text "!"
    .byte 0
    pattern1_3: .text "+"
    .byte 0
    __164: .byte 0
    flash_rom_bank: .byte 0
    fp: .word 0
    flash_bytes: .dword 0
    .label flash_rom_address_boundary_1 = flash_bytes
    rom_device: .word 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [507] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [508] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [509] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [510] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($79) char color)
textcolor: {
    .label __0 = $7a
    .label __1 = $79
    .label color = $79
    // __conio.color & 0xF0
    // [512] textcolor::$0 = *((char *)&__conio+$b) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$b
    sta.z __0
    // __conio.color & 0xF0 | color
    // [513] textcolor::$1 = textcolor::$0 | textcolor::color#24 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z __1
    ora.z __0
    sta.z __1
    // __conio.color = __conio.color & 0xF0 | color
    // [514] *((char *)&__conio+$b) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$b
    // textcolor::@return
    // }
    // [515] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($79) char color)
bgcolor: {
    .label __0 = $b8
    .label __1 = $79
    .label __2 = $b8
    .label color = $79
    // __conio.color & 0x0F
    // [517] bgcolor::$0 = *((char *)&__conio+$b) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$b
    sta.z __0
    // color << 4
    // [518] bgcolor::$1 = bgcolor::color#11 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z __1
    asl
    asl
    asl
    asl
    sta.z __1
    // __conio.color & 0x0F | color << 4
    // [519] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z __2
    ora.z __1
    sta.z __2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [520] *((char *)&__conio+$b) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$b
    // bgcolor::@return
    // }
    // [521] return 
    rts
}
  // cursor
// If onoff is 1, a cursor is displayed when waiting for keyboard input.
// If onoff is 0, the cursor is hidden when waiting for keyboard input.
// The function returns the old cursor setting.
// char cursor(char onoff)
cursor: {
    .const onoff = 0
    // __conio.cursor = onoff
    // [522] *((char *)&__conio+$a) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$a
    // cursor::@return
    // }
    // [523] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $d0
    // __mem unsigned char x
    // [524] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [525] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [527] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [528] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($70) char x, __zp($72) char y)
gotoxy: {
    .label __2 = $70
    .label __3 = $70
    .label __6 = $6d
    .label __7 = $6d
    .label __8 = $75
    .label __9 = $73
    .label __10 = $72
    .label x = $70
    .label y = $72
    .label __14 = $6d
    // (x>=__conio.width)?__conio.width:x
    // [530] if(gotoxy::x#24>=*((char *)&__conio+4)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+4
    bcs __b1
    // [532] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [532] phi gotoxy::$3 = gotoxy::x#24 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [531] gotoxy::$2 = *((char *)&__conio+4) -- vbuz1=_deref_pbuc1 
    lda __conio+4
    sta.z __2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [533] *((char *)&__conio+$d) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z __3
    sta __conio+$d
    // (y>=__conio.height)?__conio.height:y
    // [534] if(gotoxy::y#24>=*((char *)&__conio+5)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+5
    bcs __b3
    // gotoxy::@4
    // [535] gotoxy::$14 = gotoxy::y#24 -- vbuz1=vbuz2 
    sta.z __14
    // [536] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [536] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [537] *((char *)&__conio+$e) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z __7
    sta __conio+$e
    // __conio.cursor_x << 1
    // [538] gotoxy::$8 = *((char *)&__conio+$d) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$d
    asl
    sta.z __8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [539] gotoxy::$10 = gotoxy::y#24 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __10
    // [540] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z __10
    clc
    adc __conio+$15,y
    sta.z __9
    lda __conio+$15+1,y
    adc #0
    sta.z __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [541] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z __9
    sta __conio+$13
    lda.z __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [542] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [543] gotoxy::$6 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z __6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label __2 = $7b
    // __conio.cursor_x = 0
    // [544] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y++;
    // [545] *((char *)&__conio+$e) = ++ *((char *)&__conio+$e) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$e
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [546] cputln::$2 = *((char *)&__conio+$e) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    sta.z __2
    // [547] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [548] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [549] return 
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
    // [551] return 
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
    // [552] ((char *)&__conio+$f)[*((char *)&__conio)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio
    sta __conio+$f,y
    // scroll::@return
    // }
    // [553] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label __0 = $2e
    .label __1 = $68
    .label __2 = $af
    .label line_text = $42
    .label l = $4f
    .label ch = $42
    .label c = $57
    // unsigned int line_text = __conio.mapbase_offset
    // [554] clrscr::line_text#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z line_text
    lda __conio+1+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [555] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [556] clrscr::$0 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [557] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [558] clrscr::l#0 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z l
    // [559] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [559] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [559] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [560] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z __1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [561] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [562] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z __2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [563] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [564] clrscr::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [565] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [565] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [566] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [567] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [568] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [569] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [570] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+8
    sta.z line_text
    lda.z line_text+1
    adc __conio+8+1
    sta.z line_text+1
    // l--;
    // [571] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [572] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [573] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y = 0
    // [574] *((char *)&__conio+$e) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+$e
    // __conio.offset = __conio.mapbase_offset
    // [575] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+1) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+1
    sta __conio+$13
    lda __conio+1+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [576] return 
    rts
}
  // frame_draw
frame_draw: {
    .label x = $4f
    .label x1 = $57
    .label y = $34
    .label x2 = $2b
    .label y_1 = $78
    .label x3 = $77
    .label y_2 = $46
    .label x4 = $2a
    .label y_3 = $39
    .label x5 = $33
    // textcolor(WHITE)
    // [578] call textcolor
    // [511] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [579] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [580] call bgcolor
    // [516] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [581] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [582] call clrscr
    jsr clrscr
    // [583] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [583] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [584] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [585] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [586] call cputcxy
    // [1179] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [1179] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbuz1=vbuc1 
    sta.z cputcxy.x
    jsr cputcxy
    // [587] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [588] call cputcxy
    // [1179] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [1179] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [589] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [590] call cputcxy
    // [1179] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbuz1=vbuc1 
    lda #1
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // [591] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [592] call cputcxy
    // [1179] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbuz1=vbuc1 
    lda #1
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [593] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [593] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [594] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [595] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [596] call cputcxy
    // [1179] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [1179] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // [597] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [598] call cputcxy
    // [1179] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [1179] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [599] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [600] call cputcxy
    // [1179] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [1179] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // [601] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [601] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbuz1=vbuc1 
    lda #3
    sta.z y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [602] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [603] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [603] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [604] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [605] cputcxy::y#13 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [606] call cputcxy
    // [1179] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [1179] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [607] cputcxy::y#14 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [608] call cputcxy
    // [1179] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [1179] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [609] cputcxy::y#15 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [610] call cputcxy
    // [1179] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [1179] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [611] frame_draw::y#5 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [612] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [612] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [613] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [614] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [614] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [615] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [616] cputcxy::y#19 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [617] call cputcxy
    // [1179] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [1179] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [618] cputcxy::y#20 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [619] call cputcxy
    // [1179] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [1179] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [620] cputcxy::y#21 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [621] call cputcxy
    // [1179] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [1179] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [622] cputcxy::y#22 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [623] call cputcxy
    // [1179] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [1179] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [624] cputcxy::y#23 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [625] call cputcxy
    // [1179] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [1179] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [626] cputcxy::y#24 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [627] call cputcxy
    // [1179] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [1179] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [628] cputcxy::y#25 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [629] call cputcxy
    // [1179] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [1179] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [630] cputcxy::y#26 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [631] call cputcxy
    // [1179] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [1179] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [632] cputcxy::y#27 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [633] call cputcxy
    // [1179] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [1179] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [634] cputcxy::y#28 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [635] call cputcxy
    // [1179] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [1179] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [636] frame_draw::y#7 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz2 
    lda.z y_1
    inc
    sta.z y_2
    // [637] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [637] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [638] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [639] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [639] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [640] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [641] cputcxy::y#39 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [642] call cputcxy
    // [1179] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [1179] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [643] cputcxy::y#40 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [644] call cputcxy
    // [1179] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [1179] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [645] cputcxy::y#41 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [646] call cputcxy
    // [1179] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [1179] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [647] cputcxy::y#42 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [648] call cputcxy
    // [1179] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [1179] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [649] cputcxy::y#43 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [650] call cputcxy
    // [1179] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [1179] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [651] cputcxy::y#44 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [652] call cputcxy
    // [1179] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [1179] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [653] cputcxy::y#45 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [654] call cputcxy
    // [1179] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [1179] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [655] cputcxy::y#46 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [656] call cputcxy
    // [1179] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [1179] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [657] cputcxy::y#47 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [658] call cputcxy
    // [1179] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [1179] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [659] frame_draw::y#9 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz2 
    lda.z y_2
    inc
    sta.z y_3
    // [660] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [660] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [661] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [662] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [662] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [663] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x5
    cmp #$4f
    bcs !__b25+
    jmp __b25
  !__b25:
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [664] cputcxy::y#58 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [665] call cputcxy
    // [1179] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [1179] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [666] cputcxy::y#59 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [667] call cputcxy
    // [1179] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [1179] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [668] cputcxy::y#60 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [669] call cputcxy
    // [1179] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [1179] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [670] cputcxy::y#61 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [671] call cputcxy
    // [1179] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [1179] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [672] cputcxy::y#62 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [673] call cputcxy
    // [1179] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [1179] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [674] cputcxy::y#63 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [675] call cputcxy
    // [1179] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [1179] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [676] cputcxy::y#64 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [677] call cputcxy
    // [1179] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [1179] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [678] cputcxy::y#65 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [679] call cputcxy
    // [1179] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [1179] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [680] cputcxy::y#66 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [681] call cputcxy
    // [1179] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [1179] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [682] cputcxy::y#67 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [683] call cputcxy
    // [1179] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [1179] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@return
    // }
    // [684] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [685] cputcxy::x#57 = frame_draw::x5#2 -- vbuz1=vbuz2 
    lda.z x5
    sta.z cputcxy.x
    // [686] cputcxy::y#57 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [687] call cputcxy
    // [1179] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [1179] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [688] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbuz1=_inc_vbuz1 
    inc.z x5
    // [662] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [662] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [689] cputcxy::y#48 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [690] call cputcxy
    // [1179] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [691] cputcxy::y#49 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [692] call cputcxy
    // [1179] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [693] cputcxy::y#50 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [694] call cputcxy
    // [1179] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [695] cputcxy::y#51 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [696] call cputcxy
    // [1179] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [697] cputcxy::y#52 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [698] call cputcxy
    // [1179] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [699] cputcxy::y#53 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [700] call cputcxy
    // [1179] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [701] cputcxy::y#54 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [702] call cputcxy
    // [1179] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [703] cputcxy::y#55 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [704] call cputcxy
    // [1179] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [705] cputcxy::y#56 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [706] call cputcxy
    // [1179] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [707] frame_draw::y#10 = ++ frame_draw::y#106 -- vbuz1=_inc_vbuz1 
    inc.z y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [708] cputcxy::x#38 = frame_draw::x4#2 -- vbuz1=vbuz2 
    lda.z x4
    sta.z cputcxy.x
    // [709] cputcxy::y#38 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [710] call cputcxy
    // [1179] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [1179] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [711] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbuz1=_inc_vbuz1 
    inc.z x4
    // [639] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [639] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [712] cputcxy::y#29 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [713] call cputcxy
    // [1179] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [714] cputcxy::y#30 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [715] call cputcxy
    // [1179] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [716] cputcxy::y#31 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [717] call cputcxy
    // [1179] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [718] cputcxy::y#32 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [719] call cputcxy
    // [1179] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [720] cputcxy::y#33 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [721] call cputcxy
    // [1179] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [722] cputcxy::y#34 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [723] call cputcxy
    // [1179] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [724] cputcxy::y#35 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [725] call cputcxy
    // [1179] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [726] cputcxy::y#36 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [727] call cputcxy
    // [1179] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [728] cputcxy::y#37 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [729] call cputcxy
    // [1179] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [730] frame_draw::y#8 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz1 
    inc.z y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [731] cputcxy::x#18 = frame_draw::x3#2 -- vbuz1=vbuz2 
    lda.z x3
    sta.z cputcxy.x
    // [732] cputcxy::y#18 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [733] call cputcxy
    // [1179] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [1179] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [734] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbuz1=_inc_vbuz1 
    inc.z x3
    // [614] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [614] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [735] cputcxy::y#16 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [736] call cputcxy
    // [1179] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [737] cputcxy::y#17 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [738] call cputcxy
    // [1179] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [739] frame_draw::y#6 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [740] cputcxy::x#12 = frame_draw::x2#2 -- vbuz1=vbuz2 
    lda.z x2
    sta.z cputcxy.x
    // [741] cputcxy::y#12 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [742] call cputcxy
    // [1179] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [1179] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [743] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbuz1=_inc_vbuz1 
    inc.z x2
    // [603] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [603] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [744] cputcxy::y#9 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [745] call cputcxy
    // [1179] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [746] cputcxy::y#10 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [747] call cputcxy
    // [1179] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [748] cputcxy::y#11 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [749] call cputcxy
    // [1179] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [1179] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [1179] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [750] frame_draw::y#4 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [601] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [601] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [751] cputcxy::x#5 = frame_draw::x1#2 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [752] call cputcxy
    // [1179] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [1179] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [753] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbuz1=_inc_vbuz1 
    inc.z x1
    // [593] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [593] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [754] cputcxy::x#0 = frame_draw::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [755] call cputcxy
    // [1179] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [1179] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1179] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1179] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [756] frame_draw::x#1 = ++ frame_draw::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [583] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [583] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
    jmp __b1
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($42) void (*putc)(char), __zp($3c) const char *s)
printf_str: {
    .label c = $2e
    .label s = $3c
    .label putc = $42
    // [758] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [758] phi printf_str::s#32 = printf_str::s#33 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [759] printf_str::c#1 = *printf_str::s#32 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [760] printf_str::s#0 = ++ printf_str::s#32 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [761] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [762] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [763] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [764] callexecute *printf_str::putc#33  -- call__deref_pprz1 
    jsr icall12
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall12:
    jmp (putc)
}
  // print_chips
print_chips: {
    .label __4 = $68
    .label r = $76
    .label __33 = $68
    .label __34 = $68
    // [767] phi from print_chips to print_chips::@1 [phi:print_chips->print_chips::@1]
    // [767] phi print_chips::r#10 = 0 [phi:print_chips->print_chips::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // print_chips::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [768] if(print_chips::r#10<8) goto print_chips::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // print_chips::@return
    // }
    // [769] return 
    rts
    // print_chips::@2
  __b2:
    // r * 10
    // [770] print_chips::$33 = print_chips::r#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z r
    asl
    asl
    sta.z __33
    // [771] print_chips::$34 = print_chips::$33 + print_chips::r#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z __34
    clc
    adc.z r
    sta.z __34
    // [772] print_chips::$4 = print_chips::$34 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __4
    // print_chip_line(3 + r * 10, 45, ' ')
    // [773] print_chip_line::x#0 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [774] call print_chip_line
    // [1187] phi from print_chips::@2 to print_chip_line [phi:print_chips::@2->print_chip_line]
    // [1187] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@2->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1187] phi print_chip_line::y#12 = $2d [phi:print_chips::@2->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2d
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#0 [phi:print_chips::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@3
    // print_chip_line(3 + r * 10, 46, 'r')
    // [775] print_chip_line::x#1 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [776] call print_chip_line
    // [1187] phi from print_chips::@3 to print_chip_line [phi:print_chips::@3->print_chip_line]
    // [1187] phi print_chip_line::c#12 = 'r'pm [phi:print_chips::@3->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'r'
    sta.z print_chip_line.c
    // [1187] phi print_chip_line::y#12 = $2e [phi:print_chips::@3->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2e
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#1 [phi:print_chips::@3->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@4
    // print_chip_line(3 + r * 10, 47, 'o')
    // [777] print_chip_line::x#2 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [778] call print_chip_line
    // [1187] phi from print_chips::@4 to print_chip_line [phi:print_chips::@4->print_chip_line]
    // [1187] phi print_chip_line::c#12 = 'o'pm [phi:print_chips::@4->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'o'
    sta.z print_chip_line.c
    // [1187] phi print_chip_line::y#12 = $2f [phi:print_chips::@4->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2f
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#2 [phi:print_chips::@4->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@5
    // print_chip_line(3 + r * 10, 48, 'm')
    // [779] print_chip_line::x#3 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [780] call print_chip_line
    // [1187] phi from print_chips::@5 to print_chip_line [phi:print_chips::@5->print_chip_line]
    // [1187] phi print_chip_line::c#12 = 'm'pm [phi:print_chips::@5->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'m'
    sta.z print_chip_line.c
    // [1187] phi print_chip_line::y#12 = $30 [phi:print_chips::@5->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$30
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#3 [phi:print_chips::@5->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@6
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [781] print_chip_line::x#4 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [782] print_chip_line::c#4 = '0'pm + print_chips::r#10 -- vbuz1=vbuc1_plus_vbuz2 
    lda #'0'
    clc
    adc.z r
    sta.z print_chip_line.c
    // [783] call print_chip_line
    // [1187] phi from print_chips::@6 to print_chip_line [phi:print_chips::@6->print_chip_line]
    // [1187] phi print_chip_line::c#12 = print_chip_line::c#4 [phi:print_chips::@6->print_chip_line#0] -- register_copy 
    // [1187] phi print_chip_line::y#12 = $31 [phi:print_chips::@6->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#4 [phi:print_chips::@6->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@7
    // print_chip_line(3 + r * 10, 50, ' ')
    // [784] print_chip_line::x#5 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [785] call print_chip_line
    // [1187] phi from print_chips::@7 to print_chip_line [phi:print_chips::@7->print_chip_line]
    // [1187] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@7->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1187] phi print_chip_line::y#12 = $32 [phi:print_chips::@7->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$32
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#5 [phi:print_chips::@7->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@8
    // print_chip_line(3 + r * 10, 51, ' ')
    // [786] print_chip_line::x#6 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [787] call print_chip_line
    // [1187] phi from print_chips::@8 to print_chip_line [phi:print_chips::@8->print_chip_line]
    // [1187] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@8->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1187] phi print_chip_line::y#12 = $33 [phi:print_chips::@8->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$33
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#6 [phi:print_chips::@8->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@9
    // print_chip_line(3 + r * 10, 52, ' ')
    // [788] print_chip_line::x#7 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [789] call print_chip_line
    // [1187] phi from print_chips::@9 to print_chip_line [phi:print_chips::@9->print_chip_line]
    // [1187] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@9->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1187] phi print_chip_line::y#12 = $34 [phi:print_chips::@9->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$34
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#7 [phi:print_chips::@9->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@10
    // print_chip_line(3 + r * 10, 53, ' ')
    // [790] print_chip_line::x#8 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [791] call print_chip_line
    // [1187] phi from print_chips::@10 to print_chip_line [phi:print_chips::@10->print_chip_line]
    // [1187] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@10->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1187] phi print_chip_line::y#12 = $35 [phi:print_chips::@10->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$35
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#8 [phi:print_chips::@10->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@11
    // print_chip_end(3 + r * 10, 54)
    // [792] print_chip_end::x#0 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z print_chip_end.x
    sta.z print_chip_end.x
    // [793] call print_chip_end
    jsr print_chip_end
    // print_chips::@12
    // print_chip_led(r, BLACK, BLUE)
    // [794] print_chip_led::r#0 = print_chips::r#10 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_chip_led.r
    // [795] call print_chip_led
    // [885] phi from print_chips::@12 to print_chip_led [phi:print_chips::@12->print_chip_led]
    // [885] phi print_chip_led::tc#10 = BLACK [phi:print_chips::@12->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [885] phi print_chip_led::r#10 = print_chip_led::r#0 [phi:print_chips::@12->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // print_chips::@13
    // for (unsigned char r = 0; r < 8; r++)
    // [796] print_chips::r#1 = ++ print_chips::r#10 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [767] phi from print_chips::@13 to print_chips::@1 [phi:print_chips::@13->print_chips::@1]
    // [767] phi print_chips::r#10 = print_chips::r#1 [phi:print_chips::@13->print_chips::@1#0] -- register_copy 
    jmp __b1
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [797] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [798] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [799] __snprintf_buffer = main::buffer -- pbum1=pbuc1 
    lda #<main.buffer
    sta __snprintf_buffer
    lda #>main.buffer
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [800] return 
    rts
}
  // print_text
// void print_text(char *text)
print_text: {
    // textcolor(WHITE)
    // [802] call textcolor
    // [511] phi from print_text to textcolor [phi:print_text->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:print_text->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [803] phi from print_text to print_text::@1 [phi:print_text->print_text::@1]
    // print_text::@1
    // gotoxy(2, 39)
    // [804] call gotoxy
    // [529] phi from print_text::@1 to gotoxy [phi:print_text::@1->gotoxy]
    // [529] phi gotoxy::y#24 = $27 [phi:print_text::@1->gotoxy#0] -- vbuz1=vbuc1 
    lda #$27
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = 2 [phi:print_text::@1->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [805] phi from print_text::@1 to print_text::@2 [phi:print_text::@1->print_text::@2]
    // print_text::@2
    // printf("%-76s", text)
    // [806] call printf_string
    // [930] phi from print_text::@2 to printf_string [phi:print_text::@2->printf_string]
    // [930] phi printf_string::str#10 = main::buffer [phi:print_text::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z printf_string.str
    lda #>main.buffer
    sta.z printf_string.str+1
    // [930] phi printf_string::format_justify_left#10 = 1 [phi:print_text::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [930] phi printf_string::format_min_length#7 = $4c [phi:print_text::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #$4c
    sta.z printf_string.format_min_length
    jsr printf_string
    // print_text::@return
    // }
    // [807] return 
    rts
}
  // wait_key
// Some addressing constants.
// The different device IDs that can be returned from the manufacturer ID read sequence.
// To print the graphics on the vera.
wait_key: {
    .const bank_set_bram1_bank = 0
    .label return = $af
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [809] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [810] phi from wait_key::bank_set_bram1 to wait_key::@2 [phi:wait_key::bank_set_bram1->wait_key::@2]
    // wait_key::@2
    // bank_set_brom(4)
    // [811] call bank_set_brom
    // [818] phi from wait_key::@2 to bank_set_brom [phi:wait_key::@2->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 4 [phi:wait_key::@2->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [812] phi from wait_key::@2 wait_key::@3 to wait_key::@1 [phi:wait_key::@2/wait_key::@3->wait_key::@1]
    // wait_key::@1
  __b1:
    // getin()
    // [813] call getin
    jsr getin
    // [814] getin::return#2 = getin::return#1
    // wait_key::@3
    // [815] wait_key::return#0 = getin::return#2
    // while (!(ch = getin()))
    // [816] if(0==wait_key::return#0) goto wait_key::@1 -- 0_eq_vbuz1_then_la1 
    lda.z return
    beq __b1
    // wait_key::@return
    // }
    // [817] return 
    rts
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
// void bank_set_brom(__zp($34) char bank)
bank_set_brom: {
    .label bank = $34
    // BROM = bank
    // [819] BROM = bank_set_brom::bank#12 -- vbuz1=vbuz2 
    lda.z bank
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [820] return 
    rts
}
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [822] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [823] phi from system_reset::bank_set_bram1 to system_reset::@1 [phi:system_reset::bank_set_bram1->system_reset::@1]
    // system_reset::@1
    // bank_set_brom(0)
    // [824] call bank_set_brom
    // [818] phi from system_reset::@1 to bank_set_brom [phi:system_reset::@1->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = 0 [phi:system_reset::@1->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #0
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [826] return 
}
  // printf_sint
// Print a signed integer using a specific format
// void printf_sint(void (*putc)(char), __zp($27) int value, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_sint: {
    .const format_min_length = 0
    .const format_justify_left = 0
    .const format_zero_padding = 0
    .const format_upper_case = 0
    .label putc = snputc
    .label value = $27
    // printf_buffer.sign = 0
    // [827] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // if(value<0)
    // [828] if(printf_sint::value#1<0) goto printf_sint::@1 -- vwsz1_lt_0_then_la1 
    lda.z value+1
    bmi __b1
    // [831] phi from printf_sint printf_sint::@1 to printf_sint::@2 [phi:printf_sint/printf_sint::@1->printf_sint::@2]
    // [831] phi printf_sint::value#4 = printf_sint::value#1 [phi:printf_sint/printf_sint::@1->printf_sint::@2#0] -- register_copy 
    jmp __b2
    // printf_sint::@1
  __b1:
    // value = -value
    // [829] printf_sint::value#0 = - printf_sint::value#1 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z value
    sta.z value
    lda #0
    sbc.z value+1
    sta.z value+1
    // printf_buffer.sign = '-'
    // [830] *((char *)&printf_buffer) = '-'pm -- _deref_pbuc1=vbuc2 
    lda #'-'
    sta printf_buffer
    // printf_sint::@2
  __b2:
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [832] utoa::value#1 = (unsigned int)printf_sint::value#4
    // [833] call utoa
    // [1250] phi from printf_sint::@2 to utoa [phi:printf_sint::@2->utoa]
    // [1250] phi utoa::value#10 = utoa::value#1 [phi:printf_sint::@2->utoa#0] -- register_copy 
    // [1250] phi utoa::radix#2 = DECIMAL [phi:printf_sint::@2->utoa#1] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z utoa.radix
    jsr utoa
    // printf_sint::@3
    // printf_number_buffer(putc, printf_buffer, format)
    // [834] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [835] call printf_number_buffer
  // Print using format
    // [1281] phi from printf_sint::@3 to printf_number_buffer [phi:printf_sint::@3->printf_number_buffer]
    // [1281] phi printf_number_buffer::format_upper_case#10 = printf_sint::format_upper_case#0 [phi:printf_sint::@3->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #format_upper_case
    sta.z printf_number_buffer.format_upper_case
    // [1281] phi printf_number_buffer::putc#10 = printf_sint::putc#0 [phi:printf_sint::@3->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [1281] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_sint::@3->printf_number_buffer#2] -- register_copy 
    // [1281] phi printf_number_buffer::format_zero_padding#10 = printf_sint::format_zero_padding#0 [phi:printf_sint::@3->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #format_zero_padding
    sta.z printf_number_buffer.format_zero_padding
    // [1281] phi printf_number_buffer::format_justify_left#10 = printf_sint::format_justify_left#0 [phi:printf_sint::@3->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #format_justify_left
    sta.z printf_number_buffer.format_justify_left
    // [1281] phi printf_number_buffer::format_min_length#4 = printf_sint::format_min_length#0 [phi:printf_sint::@3->printf_number_buffer#5] -- vbuz1=vbuc1 
    lda #format_min_length
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_sint::@return
    // }
    // [836] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($61) void (*putc)(char), __zp($26) char uvalue, __zp($78) char format_min_length, char format_justify_left, char format_sign_always, __zp($77) char format_zero_padding, char format_upper_case, __zp($2b) char format_radix)
printf_uchar: {
    .label uvalue = $26
    .label format_radix = $2b
    .label putc = $61
    .label format_min_length = $78
    .label format_zero_padding = $77
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [838] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [839] uctoa::value#1 = printf_uchar::uvalue#12
    // [840] uctoa::radix#0 = printf_uchar::format_radix#12
    // [841] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [842] printf_number_buffer::putc#3 = printf_uchar::putc#12
    // [843] printf_number_buffer::buffer_sign#3 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [844] printf_number_buffer::format_min_length#3 = printf_uchar::format_min_length#12
    // [845] printf_number_buffer::format_zero_padding#3 = printf_uchar::format_zero_padding#12
    // [846] call printf_number_buffer
  // Print using format
    // [1281] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1281] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1281] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#3 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1281] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#3 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1281] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#3 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [1281] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [1281] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#3 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [847] return 
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
// __zp($42) struct $1 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label __4 = $47
    .label __7 = $68
    .label __11 = $5c
    .label fp = $42
    .label return = $42
    .label __32 = $5c
    .label __33 = $5c
    // FILE *fp = &__files[__filecount]
    // [848] fopen::$32 = __filecount << 2 -- vbuz1=vbum2_rol_2 
    lda __filecount
    asl
    asl
    sta.z __32
    // [849] fopen::$33 = fopen::$32 + __filecount -- vbuz1=vbuz1_plus_vbum2 
    lda __filecount
    clc
    adc.z __33
    sta.z __33
    // [850] fopen::$11 = fopen::$33 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z __11
    asl
    asl
    sta.z __11
    // [851] fopen::fp#0 = __files + fopen::$11 -- pssz1=pssc1_plus_vbuz2 
    clc
    adc #<__files
    sta.z fp
    lda #>__files
    adc #0
    sta.z fp+1
    // fp->status = 0
    // [852] ((char *)fopen::fp#0)[$13] = 0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #0
    ldy #$13
    sta (fp),y
    // fp->channel = channel
    // [853] ((char *)fopen::fp#0)[$10] = fopen::channel#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #channel
    ldy #$10
    sta (fp),y
    // fp->device = device
    // [854] ((char *)fopen::fp#0)[$11] = fopen::device#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #device
    ldy #$11
    sta (fp),y
    // fp->secondary = secondary
    // [855] ((char *)fopen::fp#0)[$12] = fopen::secondary#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #secondary
    ldy #$12
    sta (fp),y
    // strncpy(fp->filename, filename, 16)
    // [856] strncpy::dst#1 = (char *)fopen::fp#0 -- pbuz1=pbuz2 
    lda.z fp
    sta.z strncpy.dst
    lda.z fp+1
    sta.z strncpy.dst+1
    // [857] call strncpy
    // [1350] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@5
    // cbm_k_setnam(filename)
    // [858] cbm_k_setnam::filename = main::buffer -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z cbm_k_setnam.filename
    lda #>main.buffer
    sta.z cbm_k_setnam.filename+1
    // [859] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@6
    // cbm_k_setlfs(channel, device, secondary)
    // [860] cbm_k_setlfs::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_setlfs.channel
    // [861] cbm_k_setlfs::device = fopen::device#0 -- vbuz1=vbuc1 
    lda #device
    sta.z cbm_k_setlfs.device
    // [862] cbm_k_setlfs::command = fopen::secondary#0 -- vbuz1=vbuc1 
    lda #secondary
    sta.z cbm_k_setlfs.command
    // [863] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [864] phi from fopen::@6 to fopen::@7 [phi:fopen::@6->fopen::@7]
    // fopen::@7
    // cbm_k_open()
    // [865] call cbm_k_open
    jsr cbm_k_open
    // [866] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@8
    // [867] fopen::$4 = cbm_k_open::return#2
    // fp->status = cbm_k_open()
    // [868] ((char *)fopen::fp#0)[$13] = fopen::$4 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __4
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [869] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // fopen::@3
    // cbm_k_close(channel)
    // [870] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [871] call cbm_k_close
    jsr cbm_k_close
    // [872] phi from fopen::@3 fopen::@4 to fopen::@return [phi:fopen::@3/fopen::@4->fopen::@return]
  __b3:
    // [872] phi fopen::return#1 = 0 [phi:fopen::@3/fopen::@4->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [873] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [874] cbm_k_chkin::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_chkin.channel
    // [875] call cbm_k_chkin
    jsr cbm_k_chkin
    // [876] phi from fopen::@1 to fopen::@9 [phi:fopen::@1->fopen::@9]
    // fopen::@9
    // cbm_k_readst()
    // [877] call cbm_k_readst
    jsr cbm_k_readst
    // [878] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@10
    // [879] fopen::$7 = cbm_k_readst::return#2
    // fp->status = cbm_k_readst()
    // [880] ((char *)fopen::fp#0)[$13] = fopen::$7 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __7
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [881] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@2 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b2
    // fopen::@4
    // cbm_k_close(channel)
    // [882] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [883] call cbm_k_close
    jsr cbm_k_close
    jmp __b3
    // fopen::@2
  __b2:
    // __filecount++;
    // [884] __filecount = ++ __filecount -- vbum1=_inc_vbum1 
    inc __filecount
    // [872] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [872] phi fopen::return#1 = fopen::fp#0 [phi:fopen::@2->fopen::@return#0] -- register_copy 
    rts
}
  // print_chip_led
// void print_chip_led(__zp($46) char r, __zp($29) char tc, char bc)
print_chip_led: {
    .label __0 = $46
    .label r = $46
    .label tc = $29
    .label __8 = $5c
    .label __9 = $46
    // r * 10
    // [886] print_chip_led::$8 = print_chip_led::r#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z r
    asl
    asl
    sta.z __8
    // [887] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#10 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z __9
    clc
    adc.z __8
    sta.z __9
    // [888] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __0
    // gotoxy(4 + r * 10, 43)
    // [889] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbuz1=vbuc1_plus_vbuz2 
    lda #4
    clc
    adc.z __0
    sta.z gotoxy.x
    // [890] call gotoxy
    // [529] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [529] phi gotoxy::y#24 = $2b [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #$2b
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [891] textcolor::color#8 = print_chip_led::tc#10 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [892] call textcolor
    // [511] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [511] phi textcolor::color#24 = textcolor::color#8 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [893] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [894] call bgcolor
    // [516] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [895] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [896] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [898] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [899] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [901] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [902] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [904] return 
    rts
}
  // table_chip_clear
// void table_chip_clear(__zp($af) char rom_bank)
table_chip_clear: {
    .label flash_rom_address = $ab
    .label rom_bank = $af
    .label y = $bd
    // textcolor(WHITE)
    // [906] call textcolor
    // [511] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:table_chip_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [907] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [908] call bgcolor
    // [516] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [909] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [909] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [909] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [910] if(table_chip_clear::y#10<$24) goto table_chip_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$24
    bcc __b2
    // table_chip_clear::@return
    // }
    // [911] return 
    rts
    // table_chip_clear::@2
  __b2:
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [912] rom_address::rom_bank#1 = table_chip_clear::rom_bank#11 -- vbuz1=vbuz2 
    lda.z rom_bank
    sta.z rom_address.rom_bank
    // [913] call rom_address
    // [952] phi from table_chip_clear::@2 to rom_address [phi:table_chip_clear::@2->rom_address]
    // [952] phi rom_address::rom_bank#5 = rom_address::rom_bank#1 [phi:table_chip_clear::@2->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [914] rom_address::return#3 = rom_address::return#0
    // table_chip_clear::@4
    // [915] table_chip_clear::flash_rom_address#0 = rom_address::return#3
    // gotoxy(2, y)
    // [916] gotoxy::y#9 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [917] call gotoxy
    // [529] phi from table_chip_clear::@4 to gotoxy [phi:table_chip_clear::@4->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#9 [phi:table_chip_clear::@4->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = 2 [phi:table_chip_clear::@4->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // table_chip_clear::@5
    // printf("%02x", rom_bank)
    // [918] printf_uchar::uvalue#2 = table_chip_clear::rom_bank#11 -- vbuz1=vbuz2 
    lda.z rom_bank
    sta.z printf_uchar.uvalue
    // [919] call printf_uchar
    // [837] phi from table_chip_clear::@5 to printf_uchar [phi:table_chip_clear::@5->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 1 [phi:table_chip_clear::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 2 [phi:table_chip_clear::@5->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &cputc [phi:table_chip_clear::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = HEXADECIMAL [phi:table_chip_clear::@5->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#2 [phi:table_chip_clear::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@6
    // gotoxy(5, y)
    // [920] gotoxy::y#10 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [921] call gotoxy
    // [529] phi from table_chip_clear::@6 to gotoxy [phi:table_chip_clear::@6->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#10 [phi:table_chip_clear::@6->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = 5 [phi:table_chip_clear::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #5
    sta.z gotoxy.x
    jsr gotoxy
    // table_chip_clear::@7
    // printf("%06x", flash_rom_address)
    // [922] printf_ulong::uvalue#1 = table_chip_clear::flash_rom_address#0 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z printf_ulong.uvalue
    lda.z flash_rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z flash_rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z flash_rom_address+3
    sta.z printf_ulong.uvalue+3
    // [923] call printf_ulong
    // [1388] phi from table_chip_clear::@7 to printf_ulong [phi:table_chip_clear::@7->printf_ulong]
    // [1388] phi printf_ulong::format_zero_padding#2 = 1 [phi:table_chip_clear::@7->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1388] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:table_chip_clear::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // table_chip_clear::@8
    // gotoxy(14, y)
    // [924] gotoxy::y#11 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [925] call gotoxy
    // [529] phi from table_chip_clear::@8 to gotoxy [phi:table_chip_clear::@8->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#11 [phi:table_chip_clear::@8->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = $e [phi:table_chip_clear::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // [926] phi from table_chip_clear::@8 to table_chip_clear::@9 [phi:table_chip_clear::@8->table_chip_clear::@9]
    // table_chip_clear::@9
    // printf("%64s", " ")
    // [927] call printf_string
    // [930] phi from table_chip_clear::@9 to printf_string [phi:table_chip_clear::@9->printf_string]
    // [930] phi printf_string::str#10 = table_chip_clear::str [phi:table_chip_clear::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [930] phi printf_string::format_justify_left#10 = 0 [phi:table_chip_clear::@9->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [930] phi printf_string::format_min_length#7 = $40 [phi:table_chip_clear::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #$40
    sta.z printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@10
    // rom_bank++;
    // [928] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [929] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [909] phi from table_chip_clear::@10 to table_chip_clear::@1 [phi:table_chip_clear::@10->table_chip_clear::@1]
    // [909] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@10->table_chip_clear::@1#0] -- register_copy 
    // [909] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@10->table_chip_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    str: .text " "
    .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($3c) char *str, __zp($2a) char format_min_length, __zp($39) char format_justify_left)
printf_string: {
    .label __9 = $35
    .label len = $47
    .label padding = $2a
    .label str = $3c
    .label format_min_length = $2a
    .label format_justify_left = $39
    // if(format.min_length)
    // [931] if(0==printf_string::format_min_length#7) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [932] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [933] call strlen
    // [1396] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1396] phi strlen::str#6 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [934] strlen::return#4 = strlen::len#2
    // printf_string::@6
    // [935] printf_string::$9 = strlen::return#4
    // signed char len = (signed char)strlen(str)
    // [936] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z __9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [937] printf_string::padding#1 = (signed char)printf_string::format_min_length#7 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [938] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [940] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [940] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [939] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [940] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [940] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [941] if(0!=printf_string::format_justify_left#10) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [942] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [943] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [944] call printf_padding
    // [1402] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1402] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1402] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [945] printf_str::s#2 = printf_string::str#10
    // [946] call printf_str
    // [757] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [947] if(0==printf_string::format_justify_left#10) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [948] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [949] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [950] call printf_padding
    // [1402] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1402] phi printf_padding::putc#7 = &cputc [phi:printf_string::@5->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1402] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [951] return 
    rts
}
  // rom_address
/**
 * @brief Calculates the 22 bit ROM address from the 8 bit ROM bank.
 * The ROM bank number is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM address.
 * @return unsigned long The 22 bit ROM address.
 */
/* inline */
// __zp($d4) unsigned long rom_address(__zp($33) char rom_bank)
rom_address: {
    .label __1 = $ab
    .label return = $ab
    .label rom_bank = $33
    .label return_1 = $63
    .label return_2 = $50
    .label return_3 = $da
    .label return_4 = $d4
    // ((unsigned long)(rom_bank)) << 14
    // [953] rom_address::$1 = (unsigned long)rom_address::rom_bank#5 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z __1
    lda #0
    sta.z __1+1
    sta.z __1+2
    sta.z __1+3
    // [954] rom_address::return#0 = rom_address::$1 << $e -- vduz1=vduz1_rol_vbuc1 
    ldx #$e
    cpx #0
    beq !e+
  !:
    asl.z return
    rol.z return+1
    rol.z return+2
    rol.z return+3
    dex
    bne !-
  !e:
    // rom_address::@return
    // }
    // [955] return 
    rts
}
  // flash_read
// __zp($5d) unsigned long flash_read(__zp($61) struct $1 *fp, __zp($3e) char *flash_ram_address, __zp($48) char rom_bank_start, __zp($c1) unsigned long read_size)
flash_read: {
    .label __3 = $ab
    .label __6 = $68
    .label __12 = $69
    .label flash_rom_address = $63
    .label read_bytes = $2c
    .label rom_bank_start = $48
    .label return = $5d
    .label flash_ram_address = $3e
    .label flash_bytes = $5d
    .label fp = $61
    .label read_size = $c1
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [957] rom_address::rom_bank#0 = flash_read::rom_bank_start#11 -- vbuz1=vbuz2 
    lda.z rom_bank_start
    sta.z rom_address.rom_bank
    // [958] call rom_address
    // [952] phi from flash_read to rom_address [phi:flash_read->rom_address]
    // [952] phi rom_address::rom_bank#5 = rom_address::rom_bank#0 [phi:flash_read->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [959] rom_address::return#2 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_1
    lda.z rom_address.return+1
    sta.z rom_address.return_1+1
    lda.z rom_address.return+2
    sta.z rom_address.return_1+2
    lda.z rom_address.return+3
    sta.z rom_address.return_1+3
    // flash_read::@9
    // [960] flash_read::flash_rom_address#0 = rom_address::return#2
    // textcolor(WHITE)
    // [961] call textcolor
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [511] phi from flash_read::@9 to textcolor [phi:flash_read::@9->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:flash_read::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [962] phi from flash_read::@9 to flash_read::@1 [phi:flash_read::@9->flash_read::@1]
    // [962] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@9->flash_read::@1#0] -- register_copy 
    // [962] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@9->flash_read::@1#1] -- register_copy 
    // [962] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#0 [phi:flash_read::@9->flash_read::@1#2] -- register_copy 
    // [962] phi flash_read::return#2 = 0 [phi:flash_read::@9->flash_read::@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // [962] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [962] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [962] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [962] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [962] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < read_size)
    // [963] if(flash_read::return#2<flash_read::read_size#4) goto flash_read::@2 -- vduz1_lt_vduz2_then_la1 
    lda.z return+3
    cmp.z read_size+3
    bcc __b2
    bne !+
    lda.z return+2
    cmp.z read_size+2
    bcc __b2
    bne !+
    lda.z return+1
    cmp.z read_size+1
    bcc __b2
    bne !+
    lda.z return
    cmp.z read_size
    bcc __b2
  !:
    // flash_read::@return
    // }
    // [964] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [965] flash_read::$3 = flash_read::flash_rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address
    and #<$4000-1
    sta.z __3
    lda.z flash_rom_address+1
    and #>$4000-1
    sta.z __3+1
    lda.z flash_rom_address+2
    and #<$4000-1>>$10
    sta.z __3+2
    lda.z flash_rom_address+3
    and #>$4000-1>>$10
    sta.z __3+3
    // if (!(flash_rom_address % 0x04000))
    // [966] if(0!=flash_read::$3) goto flash_read::@3 -- 0_neq_vduz1_then_la1 
    lda.z __3
    ora.z __3+1
    ora.z __3+2
    ora.z __3+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [967] flash_read::$6 = flash_read::rom_bank_start#4 & $20-1 -- vbuz1=vbuz2_band_vbuc1 
    lda #$20-1
    and.z rom_bank_start
    sta.z __6
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [968] gotoxy::y#8 = 4 + flash_read::$6 -- vbuz1=vbuc1_plus_vbuz2 
    lda #4
    clc
    adc.z __6
    sta.z gotoxy.y
    // [969] call gotoxy
    // [529] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#8 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = $e [phi:flash_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // flash_read::@11
    // rom_bank_start++;
    // [970] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank_start
    // [971] phi from flash_read::@11 flash_read::@2 to flash_read::@3 [phi:flash_read::@11/flash_read::@2->flash_read::@3]
    // [971] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@11/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [972] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [973] fgets::fp#0 = flash_read::fp#10 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [974] call fgets
    jsr fgets
    // [975] fgets::return#5 = fgets::return#1
    // flash_read::@10
    // [976] flash_read::read_bytes#0 = fgets::return#5
    // if (!read_bytes)
    // [977] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwuz1_then_la1 
    lda.z read_bytes
    ora.z read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [978] flash_read::$12 = flash_read::flash_rom_address#10 & $100-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address
    and #<$100-1
    sta.z __12
    lda.z flash_rom_address+1
    and #>$100-1
    sta.z __12+1
    lda.z flash_rom_address+2
    and #<$100-1>>$10
    sta.z __12+2
    lda.z flash_rom_address+3
    and #>$100-1>>$10
    sta.z __12+3
    // if (!(flash_rom_address % 0x100))
    // [979] if(0!=flash_read::$12) goto flash_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z __12
    ora.z __12+1
    ora.z __12+2
    ora.z __12+3
    bne __b5
    // flash_read::@7
    // cputc('.')
    // [980] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    // cputc(0xE0);
    lda #'.'
    pha
    // [981] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [983] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [984] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [985] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [986] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // [987] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z flash_ram_address
    sec
    sbc #<$2000
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    sbc #>$2000
    sta.z flash_ram_address+1
    jmp __b1
}
  // rom_size
/**
 * @brief Calculates the 22 bit ROM size from the 8 bit ROM banks.
 * The ROM size is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM banks.
 * @return unsigned long The resulting 22 bit ROM address.
 */
// unsigned long rom_size(char rom_banks)
rom_size: {
    .const rom_banks = 1
    .label return = rom_banks<<$e
    // rom_size::@return
    // }
    // [989] return 
    rts
}
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
    .label __0 = $4f
    .label st = $7e
    // cbm_k_close(fp->channel)
    // [990] cbm_k_close::channel = ((char *)fclose::fp#0)[$10] -- vbuz1=pbum2_derefidx_vbuc1 
    ldy #$10
    lda fp
    sta.z $fe
    lda fp+1
    sta.z $ff
    lda ($fe),y
    sta.z cbm_k_close.channel
    // [991] call cbm_k_close
    jsr cbm_k_close
    // [992] cbm_k_close::return#4 = cbm_k_close::return#1
    // fclose::@2
    // [993] fclose::$0 = cbm_k_close::return#4
    // fp->status = cbm_k_close(fp->channel)
    // [994] ((char *)fclose::fp#0)[$13] = fclose::$0 -- pbum1_derefidx_vbuc1=vbuz2 
    lda.z __0
    ldy fp
    sty.z $fe
    ldy fp+1
    sty.z $ff
    ldy #$13
    sta ($fe),y
    // char st = fp->status
    // [995] fclose::st#0 = ((char *)fclose::fp#0)[$13] -- vbuz1=pbum2_derefidx_vbuc1 
    lda fp
    sta.z $fe
    lda fp+1
    sta.z $ff
    lda ($fe),y
    sta.z st
    // if(st)
    // [996] if(0==fclose::st#0) goto fclose::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // fclose::@return
    // }
    // [997] return 
    rts
    // [998] phi from fclose::@2 to fclose::@1 [phi:fclose::@2->fclose::@1]
    // fclose::@1
  __b1:
    // cbm_k_clrchn()
    // [999] call cbm_k_clrchn
    jsr cbm_k_clrchn
    // fclose::@3
    // __filecount--;
    // [1000] __filecount = -- __filecount -- vbum1=_dec_vbum1 
    dec __filecount
    rts
  .segment Data
    .label fp = main.fp
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($61) void (*putc)(char), __zp($27) unsigned int uvalue, __zp($78) char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, __zp($76) char format_radix)
printf_uint: {
    .label uvalue = $27
    .label format_radix = $76
    .label putc = $61
    .label format_min_length = $78
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1002] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1003] utoa::value#2 = printf_uint::uvalue#3
    // [1004] utoa::radix#1 = printf_uint::format_radix#3
    // [1005] call utoa
  // Format number into buffer
    // [1250] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    // [1250] phi utoa::value#10 = utoa::value#2 [phi:printf_uint::@1->utoa#0] -- register_copy 
    // [1250] phi utoa::radix#2 = utoa::radix#1 [phi:printf_uint::@1->utoa#1] -- register_copy 
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1006] printf_number_buffer::putc#2 = printf_uint::putc#3
    // [1007] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1008] printf_number_buffer::format_min_length#2 = printf_uint::format_min_length#3
    // [1009] call printf_number_buffer
  // Print using format
    // [1281] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1281] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1281] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1281] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1281] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_zero_padding
    // [1281] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [1281] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#2 [phi:printf_uint::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1010] return 
    rts
}
  // flash_verify
// __zp($61) unsigned int flash_verify(__zp($26) char bank_ram, __zp($44) char *ptr_ram, __zp($5d) unsigned long verify_rom_address, __zp($27) unsigned int verify_rom_size)
flash_verify: {
    .label __5 = $33
    .label rom_bank1___0 = $4f
    .label rom_bank1___1 = $7e
    .label rom_bank1___2 = $7c
    .label rom_ptr1___0 = $3e
    .label rom_ptr1___2 = $3e
    .label bank_set_bram1_bank = $26
    .label rom_bank1_bank_unshifted = $7c
    .label rom_bank1_return = $34
    .label rom_ptr1_return = $3e
    .label ptr_rom = $3e
    .label ptr_ram = $44
    .label verified_bytes = $42
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label correct_bytes = $61
    .label bank_ram = $26
    .label verify_rom_address = $5d
    .label return = $61
    .label verify_rom_size = $27
    // flash_verify::bank_set_bram1
    // BRAM = bank
    // [1012] BRAM = flash_verify::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // flash_verify::rom_bank1
    // BYTE2(address)
    // [1013] flash_verify::rom_bank1_$0 = byte2  flash_verify::verify_rom_address#3 -- vbuz1=_byte2_vduz2 
    lda.z verify_rom_address+2
    sta.z rom_bank1___0
    // BYTE1(address)
    // [1014] flash_verify::rom_bank1_$1 = byte1  flash_verify::verify_rom_address#3 -- vbuz1=_byte1_vduz2 
    lda.z verify_rom_address+1
    sta.z rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1015] flash_verify::rom_bank1_$2 = flash_verify::rom_bank1_$0 w= flash_verify::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1___0
    sta.z rom_bank1___2+1
    lda.z rom_bank1___1
    sta.z rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1016] flash_verify::rom_bank1_bank_unshifted#0 = flash_verify::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1017] flash_verify::rom_bank1_return#0 = byte1  flash_verify::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // flash_verify::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1018] flash_verify::rom_ptr1_$2 = (unsigned int)flash_verify::verify_rom_address#3 -- vwuz1=_word_vduz2 
    lda.z verify_rom_address
    sta.z rom_ptr1___2
    lda.z verify_rom_address+1
    sta.z rom_ptr1___2+1
    // [1019] flash_verify::rom_ptr1_$0 = flash_verify::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1___0
    and #<$3fff
    sta.z rom_ptr1___0
    lda.z rom_ptr1___0+1
    and #>$3fff
    sta.z rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1020] flash_verify::rom_ptr1_return#0 = flash_verify::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // flash_verify::@5
    // bank_set_brom(bank_rom)
    // [1021] bank_set_brom::bank#4 = flash_verify::rom_bank1_return#0
    // [1022] call bank_set_brom
    // [818] phi from flash_verify::@5 to bank_set_brom [phi:flash_verify::@5->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = bank_set_brom::bank#4 [phi:flash_verify::@5->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // flash_verify::@6
    // [1023] flash_verify::ptr_rom#9 = (char *)flash_verify::rom_ptr1_return#0
    // [1024] phi from flash_verify::@6 to flash_verify::@1 [phi:flash_verify::@6->flash_verify::@1]
    // [1024] phi flash_verify::correct_bytes#2 = 0 [phi:flash_verify::@6->flash_verify::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z correct_bytes
    sta.z correct_bytes+1
    // [1024] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#10 [phi:flash_verify::@6->flash_verify::@1#1] -- register_copy 
    // [1024] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#9 [phi:flash_verify::@6->flash_verify::@1#2] -- register_copy 
    // [1024] phi flash_verify::verified_bytes#2 = 0 [phi:flash_verify::@6->flash_verify::@1#3] -- vwuz1=vwuc1 
    sta.z verified_bytes
    sta.z verified_bytes+1
    // flash_verify::@1
  __b1:
    // while (verified_bytes < verify_rom_size)
    // [1025] if(flash_verify::verified_bytes#2<flash_verify::verify_rom_size#11) goto flash_verify::@2 -- vwuz1_lt_vwuz2_then_la1 
    lda.z verified_bytes+1
    cmp.z verify_rom_size+1
    bcc __b2
    bne !+
    lda.z verified_bytes
    cmp.z verify_rom_size
    bcc __b2
  !:
    // flash_verify::@return
    // }
    // [1026] return 
    rts
    // flash_verify::@2
  __b2:
    // rom_byte_verify(ptr_rom, *ptr_ram)
    // [1027] rom_byte_verify::ptr_rom#0 = flash_verify::ptr_rom#2
    // [1028] rom_byte_verify::value#0 = *flash_verify::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_verify.value
    // [1029] call rom_byte_verify
    jsr rom_byte_verify
    // [1030] rom_byte_verify::return#2 = rom_byte_verify::return#0
    // flash_verify::@7
    // [1031] flash_verify::$5 = rom_byte_verify::return#2
    // if (rom_byte_verify(ptr_rom, *ptr_ram))
    // [1032] if(0==flash_verify::$5) goto flash_verify::@3 -- 0_eq_vbuz1_then_la1 
    lda.z __5
    beq __b3
    // flash_verify::@4
    // correct_bytes++;
    // [1033] flash_verify::correct_bytes#1 = ++ flash_verify::correct_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z correct_bytes
    bne !+
    inc.z correct_bytes+1
  !:
    // [1034] phi from flash_verify::@4 flash_verify::@7 to flash_verify::@3 [phi:flash_verify::@4/flash_verify::@7->flash_verify::@3]
    // [1034] phi flash_verify::correct_bytes#6 = flash_verify::correct_bytes#1 [phi:flash_verify::@4/flash_verify::@7->flash_verify::@3#0] -- register_copy 
    // flash_verify::@3
  __b3:
    // ptr_rom++;
    // [1035] flash_verify::ptr_rom#1 = ++ flash_verify::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [1036] flash_verify::ptr_ram#0 = ++ flash_verify::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // verified_bytes++;
    // [1037] flash_verify::verified_bytes#1 = ++ flash_verify::verified_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z verified_bytes
    bne !+
    inc.z verified_bytes+1
  !:
    // [1024] phi from flash_verify::@3 to flash_verify::@1 [phi:flash_verify::@3->flash_verify::@1]
    // [1024] phi flash_verify::correct_bytes#2 = flash_verify::correct_bytes#6 [phi:flash_verify::@3->flash_verify::@1#0] -- register_copy 
    // [1024] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#0 [phi:flash_verify::@3->flash_verify::@1#1] -- register_copy 
    // [1024] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#1 [phi:flash_verify::@3->flash_verify::@1#2] -- register_copy 
    // [1024] phi flash_verify::verified_bytes#2 = flash_verify::verified_bytes#1 [phi:flash_verify::@3->flash_verify::@1#3] -- register_copy 
    jmp __b1
}
  // rom_sector_erase
/**
 * @brief Erases a 1KB sector of the ROM using the 22 bit address.
 * This is required before any new bytes can be flashed into the ROM.
 * Erasing a sector of the ROM requires an erase sector sequence to be initiated, which has the following steps:
 *
 *   1. Write byte $AA into ROM address $005555.
 *   2. Write byte $55 into ROM address $002AAA.
 *   3. Write byte $80 into ROM address $005555.
 *   4. Write byte $AA into ROM address $005555.
 *   5. Write byte $55 into ROM address $002AAA.
 *
 * Once this write sequence is finished, the ROM sector is erased by writing byte $30 into the 22 bit ROM sector address.
 * Then it waits until the chip has correctly flashed the ROM erasure.
 *
 * Note that a ROM sector is 1KB (not 4KB), so the most 7 significant bits (18-12) are used.
 * The remainder 12 low bits are ignored.
 *
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *                                   | 2 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      SECTOR          0x37F000     | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      IGNORED         0x000FFF     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 * @param address The 22 bit ROM address.
 */
/* inline */
// void rom_sector_erase(__zp($b9) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1___0 = $35
    .label rom_ptr1___2 = $35
    .label rom_ptr1_return = $35
    .label rom_chip_address = $5d
    .label address = $b9
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1039] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1___2
    lda.z address+1
    sta.z rom_ptr1___2+1
    // [1040] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1___0
    and #<$3fff
    sta.z rom_ptr1___0
    lda.z rom_ptr1___0+1
    and #>$3fff
    sta.z rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1041] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [1042] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
    lda.z address
    and #<$380000
    sta.z rom_chip_address
    lda.z address+1
    and #>$380000
    sta.z rom_chip_address+1
    lda.z address+2
    and #<$380000>>$10
    sta.z rom_chip_address+2
    lda.z address+3
    and #>$380000>>$10
    sta.z rom_chip_address+3
    // rom_unlock(rom_chip_address + 0x05555, 0x80)
    // [1043] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z rom_unlock.address
    adc #<$5555
    sta.z rom_unlock.address
    lda.z rom_unlock.address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda.z rom_unlock.address+2
    adc #0
    sta.z rom_unlock.address+2
    lda.z rom_unlock.address+3
    adc #0
    sta.z rom_unlock.address+3
    // [1044] call rom_unlock
    // [1096] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1096] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1096] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [1045] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [1046] call rom_unlock
    // [1096] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1096] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1096] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [1047] rom_wait::ptr_rom#1 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [1048] call rom_wait
    // [1457] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [1457] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [1049] return 
    rts
}
  // print_address
// void print_address(__zp($26) char bram_bank, __zp($27) char *bram_ptr, __zp($22) unsigned long brom_address)
print_address: {
    .label rom_bank1___0 = $57
    .label rom_bank1___1 = $4f
    .label rom_bank1___2 = $44
    .label rom_ptr1___0 = $7c
    .label rom_ptr1___2 = $7c
    .label rom_bank1_bank_unshifted = $44
    .label brom_bank = $7e
    .label brom_ptr = $7c
    .label bram_bank = $26
    .label bram_ptr = $27
    .label brom_address = $22
    // textcolor(WHITE)
    // [1051] call textcolor
    // [511] phi from print_address to textcolor [phi:print_address->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:print_address->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // print_address::rom_bank1
    // BYTE2(address)
    // [1052] print_address::rom_bank1_$0 = byte2  print_address::brom_address#10 -- vbuz1=_byte2_vduz2 
    lda.z brom_address+2
    sta.z rom_bank1___0
    // BYTE1(address)
    // [1053] print_address::rom_bank1_$1 = byte1  print_address::brom_address#10 -- vbuz1=_byte1_vduz2 
    lda.z brom_address+1
    sta.z rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1054] print_address::rom_bank1_$2 = print_address::rom_bank1_$0 w= print_address::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1___0
    sta.z rom_bank1___2+1
    lda.z rom_bank1___1
    sta.z rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1055] print_address::rom_bank1_bank_unshifted#0 = print_address::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1056] print_address::brom_bank#0 = byte1  print_address::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z brom_bank
    // print_address::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1057] print_address::rom_ptr1_$2 = (unsigned int)print_address::brom_address#10 -- vwuz1=_word_vduz2 
    lda.z brom_address
    sta.z rom_ptr1___2
    lda.z brom_address+1
    sta.z rom_ptr1___2+1
    // [1058] print_address::rom_ptr1_$0 = print_address::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1___0
    and #<$3fff
    sta.z rom_ptr1___0
    lda.z rom_ptr1___0+1
    and #>$3fff
    sta.z rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1059] print_address::brom_ptr#0 = print_address::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z brom_ptr
    clc
    adc #<$c000
    sta.z brom_ptr
    lda.z brom_ptr+1
    adc #>$c000
    sta.z brom_ptr+1
    // [1060] phi from print_address::rom_ptr1 to print_address::@1 [phi:print_address::rom_ptr1->print_address::@1]
    // print_address::@1
    // gotoxy(43, 1)
    // [1061] call gotoxy
    // [529] phi from print_address::@1 to gotoxy [phi:print_address::@1->gotoxy]
    // [529] phi gotoxy::y#24 = 1 [phi:print_address::@1->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = $2b [phi:print_address::@1->gotoxy#1] -- vbuz1=vbuc1 
    lda #$2b
    sta.z gotoxy.x
    jsr gotoxy
    // [1062] phi from print_address::@1 to print_address::@2 [phi:print_address::@1->print_address::@2]
    // print_address::@2
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1063] call printf_str
    // [757] phi from print_address::@2 to printf_str [phi:print_address::@2->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:print_address::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = print_address::s [phi:print_address::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@3
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1064] printf_uchar::uvalue#0 = print_address::bram_bank#10
    // [1065] call printf_uchar
    // [837] phi from print_address::@3 to printf_uchar [phi:print_address::@3->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:print_address::@3->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 2 [phi:print_address::@3->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &cputc [phi:print_address::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = HEXADECIMAL [phi:print_address::@3->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#0 [phi:print_address::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1066] phi from print_address::@3 to print_address::@4 [phi:print_address::@3->print_address::@4]
    // print_address::@4
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1067] call printf_str
    // [757] phi from print_address::@4 to printf_str [phi:print_address::@4->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:print_address::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = print_address::s1 [phi:print_address::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@5
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1068] printf_uint::uvalue#0 = (unsigned int)print_address::bram_ptr#10
    // [1069] call printf_uint
    // [1001] phi from print_address::@5 to printf_uint [phi:print_address::@5->printf_uint]
    // [1001] phi printf_uint::format_min_length#3 = 4 [phi:print_address::@5->printf_uint#0] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1001] phi printf_uint::putc#3 = &cputc [phi:print_address::@5->printf_uint#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1001] phi printf_uint::format_radix#3 = HEXADECIMAL [phi:print_address::@5->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1001] phi printf_uint::uvalue#3 = printf_uint::uvalue#0 [phi:print_address::@5->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1070] phi from print_address::@5 to print_address::@6 [phi:print_address::@5->print_address::@6]
    // print_address::@6
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1071] call printf_str
    // [757] phi from print_address::@6 to printf_str [phi:print_address::@6->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:print_address::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = print_address::s2 [phi:print_address::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@7
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1072] printf_ulong::uvalue#0 = print_address::brom_address#10
    // [1073] call printf_ulong
    // [1388] phi from print_address::@7 to printf_ulong [phi:print_address::@7->printf_ulong]
    // [1388] phi printf_ulong::format_zero_padding#2 = 0 [phi:print_address::@7->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1388] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:print_address::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1074] phi from print_address::@7 to print_address::@8 [phi:print_address::@7->print_address::@8]
    // print_address::@8
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1075] call printf_str
    // [757] phi from print_address::@8 to printf_str [phi:print_address::@8->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:print_address::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = print_address::s3 [phi:print_address::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@9
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1076] printf_uchar::uvalue#1 = print_address::brom_bank#0 -- vbuz1=vbuz2 
    lda.z brom_bank
    sta.z printf_uchar.uvalue
    // [1077] call printf_uchar
    // [837] phi from print_address::@9 to printf_uchar [phi:print_address::@9->printf_uchar]
    // [837] phi printf_uchar::format_zero_padding#12 = 0 [phi:print_address::@9->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [837] phi printf_uchar::format_min_length#12 = 2 [phi:print_address::@9->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [837] phi printf_uchar::putc#12 = &cputc [phi:print_address::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [837] phi printf_uchar::format_radix#12 = HEXADECIMAL [phi:print_address::@9->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [837] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#1 [phi:print_address::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1078] phi from print_address::@9 to print_address::@10 [phi:print_address::@9->print_address::@10]
    // print_address::@10
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1079] call printf_str
    // [757] phi from print_address::@10 to printf_str [phi:print_address::@10->printf_str]
    // [757] phi printf_str::putc#33 = &cputc [phi:print_address::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [757] phi printf_str::s#33 = print_address::s1 [phi:print_address::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@11
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1080] printf_uint::uvalue#1 = (unsigned int)(char *)print_address::brom_ptr#0 -- vwuz1=vwuz2 
    lda.z brom_ptr
    sta.z printf_uint.uvalue
    lda.z brom_ptr+1
    sta.z printf_uint.uvalue+1
    // [1081] call printf_uint
    // [1001] phi from print_address::@11 to printf_uint [phi:print_address::@11->printf_uint]
    // [1001] phi printf_uint::format_min_length#3 = 4 [phi:print_address::@11->printf_uint#0] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1001] phi printf_uint::putc#3 = &cputc [phi:print_address::@11->printf_uint#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1001] phi printf_uint::format_radix#3 = HEXADECIMAL [phi:print_address::@11->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1001] phi printf_uint::uvalue#3 = printf_uint::uvalue#1 [phi:print_address::@11->printf_uint#3] -- register_copy 
    jsr printf_uint
    // print_address::@return
    // }
    // [1082] return 
    rts
  .segment Data
    s: .text "ram = "
    .byte 0
    s1: .text "/"
    .byte 0
    s2: .text ", rom = "
    .byte 0
    s3: .text ","
    .byte 0
}
.segment Code
  // flash_write
/* inline */
// unsigned long flash_write(__zp($77) char flash_ram_bank, __zp($3a) char *flash_ram_address, __zp($22) unsigned long flash_rom_address)
flash_write: {
    .label rom_chip_address = $69
    .label flash_rom_address = $22
    .label flash_ram_address = $3a
    .label flashed_bytes = $63
    .label flash_ram_bank = $77
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [1083] flash_write::rom_chip_address#0 = flash_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
    /// Holds the amount of bytes actually flashed in the ROM.
    lda.z flash_rom_address
    and #<$380000
    sta.z rom_chip_address
    lda.z flash_rom_address+1
    and #>$380000
    sta.z rom_chip_address+1
    lda.z flash_rom_address+2
    and #<$380000>>$10
    sta.z rom_chip_address+2
    lda.z flash_rom_address+3
    and #>$380000>>$10
    sta.z rom_chip_address+3
    // flash_write::bank_set_bram1
    // BRAM = bank
    // [1084] BRAM = flash_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [1085] phi from flash_write::bank_set_bram1 to flash_write::@1 [phi:flash_write::bank_set_bram1->flash_write::@1]
    // [1085] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#0] -- register_copy 
    // [1085] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#1] -- register_copy 
    // [1085] phi flash_write::flashed_bytes#2 = 0 [phi:flash_write::bank_set_bram1->flash_write::@1#2] -- vduz1=vduc1 
    lda #<0
    sta.z flashed_bytes
    sta.z flashed_bytes+1
    lda #<0>>$10
    sta.z flashed_bytes+2
    lda #>0>>$10
    sta.z flashed_bytes+3
    // flash_write::@1
  __b1:
    // while (flashed_bytes < 0x0100)
    // [1086] if(flash_write::flashed_bytes#2<$100) goto flash_write::@2 -- vduz1_lt_vduc1_then_la1 
    lda.z flashed_bytes+3
    cmp #>$100>>$10
    bcc __b2
    bne !+
    lda.z flashed_bytes+2
    cmp #<$100>>$10
    bcc __b2
    bne !+
    lda.z flashed_bytes+1
    cmp #>$100
    bcc __b2
    bne !+
    lda.z flashed_bytes
    cmp #<$100
    bcc __b2
  !:
    // flash_write::@return
    // }
    // [1087] return 
    rts
    // flash_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [1088] rom_unlock::address#2 = flash_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z rom_chip_address
    adc #<$5555
    sta.z rom_unlock.address
    lda.z rom_chip_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda.z rom_chip_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda.z rom_chip_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [1089] call rom_unlock
    // [1096] phi from flash_write::@2 to rom_unlock [phi:flash_write::@2->rom_unlock]
    // [1096] phi rom_unlock::unlock_code#5 = $a0 [phi:flash_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1096] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:flash_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // flash_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [1090] rom_byte_program::address#0 = flash_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [1091] rom_byte_program::value#0 = *flash_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [1092] call rom_byte_program
    // [1464] phi from flash_write::@3 to rom_byte_program [phi:flash_write::@3->rom_byte_program]
    jsr rom_byte_program
    // flash_write::@4
    // flash_rom_address++;
    // [1093] flash_write::flash_rom_address#0 = ++ flash_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [1094] flash_write::flash_ram_address#0 = ++ flash_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [1095] flash_write::flashed_bytes#1 = ++ flash_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [1085] phi from flash_write::@4 to flash_write::@1 [phi:flash_write::@4->flash_write::@1]
    // [1085] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#0 [phi:flash_write::@4->flash_write::@1#0] -- register_copy 
    // [1085] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#0 [phi:flash_write::@4->flash_write::@1#1] -- register_copy 
    // [1085] phi flash_write::flashed_bytes#2 = flash_write::flashed_bytes#1 [phi:flash_write::@4->flash_write::@1#2] -- register_copy 
    jmp __b1
}
  // rom_unlock
/**
 * @brief Unlock a byte location for flashing using the 22 bit address.
 * This is a various purpose routine to unlock the ROM for flashing a byte.
 * The 3rd byte can be variable, depending on the write sequence used, so this byte is a parameter into the routine.
 *
 * @param address The 3rd write to model the specific unlock sequence.
 * @param unlock_code The 3rd write to model the specific unlock sequence.
 */
/* inline */
// void rom_unlock(__zp($5d) unsigned long address, __zp($29) char unlock_code)
rom_unlock: {
    .label chip_address = $2f
    .label address = $5d
    .label unlock_code = $29
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1097] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
    lda.z address
    and #<$380000
    sta.z chip_address
    lda.z address+1
    and #>$380000
    sta.z chip_address+1
    lda.z address+2
    and #<$380000>>$10
    sta.z chip_address+2
    lda.z address+3
    and #>$380000>>$10
    sta.z chip_address+3
    // rom_write_byte(chip_address + 0x05555, 0xAA)
    // [1098] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z chip_address
    adc #<$5555
    sta.z rom_write_byte.address
    lda.z chip_address+1
    adc #>$5555
    sta.z rom_write_byte.address+1
    lda.z chip_address+2
    adc #0
    sta.z rom_write_byte.address+2
    lda.z chip_address+3
    adc #0
    sta.z rom_write_byte.address+3
    // [1099] call rom_write_byte
    // [1474] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1474] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [1474] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1100] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z chip_address
    adc #<$2aaa
    sta.z rom_write_byte.address
    lda.z chip_address+1
    adc #>$2aaa
    sta.z rom_write_byte.address+1
    lda.z chip_address+2
    adc #0
    sta.z rom_write_byte.address+2
    lda.z chip_address+3
    adc #0
    sta.z rom_write_byte.address+3
    // [1101] call rom_write_byte
    // [1474] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1474] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [1474] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1102] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1103] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1104] call rom_write_byte
    // [1474] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1474] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1474] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1105] return 
    rts
}
  // rom_read_byte
/**
 * @brief Read a byte from the ROM using the 22 bit address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to read the byte.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The byte read from the ROM.
 */
// __zp($77) char rom_read_byte(__zp($5d) unsigned long address)
rom_read_byte: {
    .label rom_bank1___0 = $4f
    .label rom_bank1___1 = $7e
    .label rom_bank1___2 = $44
    .label rom_ptr1___0 = $7c
    .label rom_ptr1___2 = $7c
    .label rom_bank1_bank_unshifted = $44
    .label rom_bank1_return = $34
    .label rom_ptr1_return = $7c
    .label return = $77
    .label address = $5d
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1107] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1___0
    // BYTE1(address)
    // [1108] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1109] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1___0
    sta.z rom_bank1___2+1
    lda.z rom_bank1___1
    sta.z rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1110] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1111] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1112] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1___2
    lda.z address+1
    sta.z rom_ptr1___2+1
    // [1113] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1___0
    and #<$3fff
    sta.z rom_ptr1___0
    lda.z rom_ptr1___0+1
    and #>$3fff
    sta.z rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1114] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::@1
    // bank_set_brom(bank_rom)
    // [1115] bank_set_brom::bank#2 = rom_read_byte::rom_bank1_return#0
    // [1116] call bank_set_brom
    // [818] phi from rom_read_byte::@1 to bank_set_brom [phi:rom_read_byte::@1->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = bank_set_brom::bank#2 [phi:rom_read_byte::@1->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_read_byte::@2
    // return *ptr_rom;
    // [1117] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [1118] return 
    rts
}
  // print_chip_KB
// void print_chip_KB(__zp($5c) char rom_chip, __zp($44) char *kb)
print_chip_KB: {
    .label __3 = $5c
    .label rom_chip = $5c
    .label kb = $44
    .label __9 = $34
    .label __10 = $5c
    // rom_chip * 10
    // [1120] print_chip_KB::$9 = print_chip_KB::rom_chip#3 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z __9
    // [1121] print_chip_KB::$10 = print_chip_KB::$9 + print_chip_KB::rom_chip#3 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z __10
    clc
    adc.z __9
    sta.z __10
    // [1122] print_chip_KB::$3 = print_chip_KB::$10 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __3
    // print_chip_line(3 + rom_chip * 10, 51, kb[0])
    // [1123] print_chip_line::x#9 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __3
    sta.z print_chip_line.x
    // [1124] print_chip_line::c#9 = *print_chip_KB::kb#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (kb),y
    sta.z print_chip_line.c
    // [1125] call print_chip_line
    // [1187] phi from print_chip_KB to print_chip_line [phi:print_chip_KB->print_chip_line]
    // [1187] phi print_chip_line::c#12 = print_chip_line::c#9 [phi:print_chip_KB->print_chip_line#0] -- register_copy 
    // [1187] phi print_chip_line::y#12 = $33 [phi:print_chip_KB->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$33
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#9 [phi:print_chip_KB->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@1
    // print_chip_line(3 + rom_chip * 10, 52, kb[1])
    // [1126] print_chip_line::x#10 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __3
    sta.z print_chip_line.x
    // [1127] print_chip_line::c#10 = print_chip_KB::kb#3[1] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #1
    lda (kb),y
    sta.z print_chip_line.c
    // [1128] call print_chip_line
    // [1187] phi from print_chip_KB::@1 to print_chip_line [phi:print_chip_KB::@1->print_chip_line]
    // [1187] phi print_chip_line::c#12 = print_chip_line::c#10 [phi:print_chip_KB::@1->print_chip_line#0] -- register_copy 
    // [1187] phi print_chip_line::y#12 = $34 [phi:print_chip_KB::@1->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$34
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#10 [phi:print_chip_KB::@1->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@2
    // print_chip_line(3 + rom_chip * 10, 53, kb[2])
    // [1129] print_chip_line::x#11 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __3
    sta.z print_chip_line.x
    // [1130] print_chip_line::c#11 = print_chip_KB::kb#3[2] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #2
    lda (kb),y
    sta.z print_chip_line.c
    // [1131] call print_chip_line
    // [1187] phi from print_chip_KB::@2 to print_chip_line [phi:print_chip_KB::@2->print_chip_line]
    // [1187] phi print_chip_line::c#12 = print_chip_line::c#11 [phi:print_chip_KB::@2->print_chip_line#0] -- register_copy 
    // [1187] phi print_chip_line::y#12 = $35 [phi:print_chip_KB::@2->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$35
    sta.z print_chip_line.y
    // [1187] phi print_chip_line::x#12 = print_chip_line::x#11 [phi:print_chip_KB::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@return
    // }
    // [1132] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($7a) char mapbase, __zp($b8) char config)
screenlayer: {
    .label __0 = $e4
    .label __1 = $7a
    .label __2 = $e5
    .label __5 = $b8
    .label __6 = $b8
    .label __7 = $de
    .label __8 = $de
    .label __9 = $d8
    .label __10 = $d8
    .label __11 = $d8
    .label __12 = $d9
    .label __13 = $d9
    .label __14 = $d9
    .label __16 = $de
    .label __17 = $cf
    .label __18 = $d8
    .label __19 = $d9
    .label mapbase_offset = $d0
    .label y = $79
    .label mapbase = $7a
    .label config = $b8
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1133] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1134] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1135] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // mapbase >> 7
    // [1136] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z __0
    // __conio.mapbase_bank = mapbase >> 7
    // [1137] *((char *)&__conio+3) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+3
    // (mapbase)<<1
    // [1138] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __1
    // MAKEWORD((mapbase)<<1,0)
    // [1139] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z __1
    sty.z __2+1
    sta.z __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1140] *((unsigned int *)&__conio+1) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+1
    tya
    sta __conio+1+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1141] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z __7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1142] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z __8
    lsr
    lsr
    lsr
    lsr
    sta.z __8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1143] *((char *)&__conio+6) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+6
    // config & VERA_LAYER_HEIGHT_MASK
    // [1144] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z __5
    sta.z __5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1145] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z __6
    rol
    rol
    rol
    and #3
    sta.z __6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1146] *((char *)&__conio+7) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+7
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1147] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __16
    // [1148] *((unsigned int *)&__conio+8) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z __16
    lda VERA_LAYER_SKIP,y
    sta __conio+8
    lda VERA_LAYER_SKIP+1,y
    sta __conio+8+1
    // vera_dc_hscale_temp == 0x80
    // [1149] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z __9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1150] screenlayer::$18 = (char)screenlayer::$9
    // [1151] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
    lda #$28
    ldy.z __10
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta.z __10
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1152] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z __11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1153] *((char *)&__conio+4) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z __11
    sta __conio+4
    // vera_dc_vscale_temp == 0x80
    // [1154] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z __12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1155] screenlayer::$19 = (char)screenlayer::$12
    // [1156] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
    lda #$1e
    ldy.z __13
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta.z __13
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1157] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z __14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1158] *((char *)&__conio+5) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z __14
    sta __conio+5
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1159] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z mapbase_offset
    lda __conio+1+1
    sta.z mapbase_offset+1
    // [1160] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1160] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1160] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1161] if(screenlayer::y#2<=*((char *)&__conio+5)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+5
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1162] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1163] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z __17
    // [1164] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1165] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+8
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+8+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1166] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1160] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1160] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1160] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [1167] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1168] if(0!=((char *)&__conio+$f)[*((char *)&__conio)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1169] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // [1170] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1171] call gotoxy
    // [529] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [529] phi gotoxy::y#24 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1172] return 
    rts
    // [1173] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1174] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1175] gotoxy::y#2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z gotoxy.y
    // [1176] call gotoxy
    // [529] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1177] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1178] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($bd) char x, __zp($af) char y, __zp($2e) char c)
cputcxy: {
    .label x = $bd
    .label y = $af
    .label c = $2e
    // gotoxy(x, y)
    // [1180] gotoxy::x#0 = cputcxy::x#68 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1181] gotoxy::y#0 = cputcxy::y#68 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1182] call gotoxy
    // [529] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1183] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1184] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1186] return 
    rts
}
  // print_chip_line
// void print_chip_line(__zp($48) char x, __zp($2e) char y, __zp($47) char c)
print_chip_line: {
    .label x = $48
    .label c = $47
    .label y = $2e
    // gotoxy(x, y)
    // [1188] gotoxy::x#4 = print_chip_line::x#12 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1189] gotoxy::y#4 = print_chip_line::y#12 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1190] call gotoxy
    // [529] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [529] phi gotoxy::y#24 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [529] phi gotoxy::x#24 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1191] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [1192] call textcolor
    // [511] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [511] phi textcolor::color#24 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1193] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [1194] call bgcolor
    // [516] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [1195] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1196] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1198] call textcolor
    // [511] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [511] phi textcolor::color#24 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1199] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [1200] call bgcolor
    // [516] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [516] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [1201] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1202] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [1204] stackpush(char) = print_chip_line::c#12 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1205] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [1207] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1208] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1210] call textcolor
    // [511] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [511] phi textcolor::color#24 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1211] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [1212] call bgcolor
    // [516] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [1213] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1214] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [1216] return 
    rts
}
  // print_chip_end
// void print_chip_end(__zp($68) char x, char y)
print_chip_end: {
    .const y = $36
    .label x = $68
    // gotoxy(x, y)
    // [1217] gotoxy::x#5 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1218] call gotoxy
    // [529] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [529] phi gotoxy::y#24 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #y
    sta.z gotoxy.y
    // [529] phi gotoxy::x#24 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1219] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [1220] call textcolor
    // [511] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [511] phi textcolor::color#24 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1221] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [1222] call bgcolor
    // [516] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [1223] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1224] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1226] call textcolor
    // [511] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [511] phi textcolor::color#24 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [1227] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [1228] call bgcolor
    // [516] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [516] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [1229] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1230] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1232] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1233] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1235] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1236] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1238] call textcolor
    // [511] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [511] phi textcolor::color#24 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1239] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [1240] call bgcolor
    // [516] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [516] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [1241] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1242] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1244] return 
    rts
}
  // getin
/**
 * @brief Get a character from keyboard.
 * 
 * @return char The character read.
 */
getin: {
    .label return = $af
    // __mem unsigned char ch
    // [1245] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [1247] getin::return#0 = getin::ch -- vbuz1=vbum2 
    sta.z return
    // getin::@return
    // }
    // [1248] getin::return#1 = getin::return#0
    // [1249] return 
    rts
  .segment Data
    ch: .byte 0
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($27) unsigned int value, __zp($3e) char *buffer, __zp($76) char radix)
utoa: {
    .label __4 = $34
    .label __10 = $2e
    .label __11 = $33
    .label digit_value = $2c
    .label buffer = $3e
    .label digit = $47
    .label value = $27
    .label radix = $76
    .label started = $4f
    .label max_digits = $5c
    .label digit_values = $3a
    // if(radix==DECIMAL)
    // [1251] if(utoa::radix#2==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1252] if(utoa::radix#2==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1253] if(utoa::radix#2==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1254] if(utoa::radix#2==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1255] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1256] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1257] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1258] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1259] return 
    rts
    // [1260] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1260] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1260] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1260] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1260] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1260] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1260] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1260] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1260] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1260] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1260] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1260] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1261] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1261] phi utoa::buffer#10 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1261] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1261] phi utoa::value#3 = utoa::value#10 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1261] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1262] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1263] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z __4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1264] utoa::$11 = (char)utoa::value#3 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z __11
    // [1265] *utoa::buffer#10 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1266] utoa::buffer#3 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1267] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1268] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z __10
    // [1269] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1270] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1271] if(utoa::value#3>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1272] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1272] phi utoa::buffer#15 = utoa::buffer#10 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1272] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1272] phi utoa::value#7 = utoa::value#3 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1273] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1261] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1261] phi utoa::buffer#10 = utoa::buffer#15 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1261] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1261] phi utoa::value#3 = utoa::value#7 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1261] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1274] utoa_append::buffer#0 = utoa::buffer#10 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1275] utoa_append::value#0 = utoa::value#3
    // [1276] utoa_append::sub#0 = utoa::digit_value#0
    // [1277] call utoa_append
    // [1520] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1278] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1279] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1280] utoa::buffer#4 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1272] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1272] phi utoa::buffer#15 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1272] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1272] phi utoa::value#7 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($61) void (*putc)(char), __zp($57) char buffer_sign, char *buffer_digits, __zp($78) char format_min_length, __zp($4f) char format_justify_left, char format_sign_always, __zp($77) char format_zero_padding, __zp($34) char format_upper_case, char format_radix)
printf_number_buffer: {
    .label __19 = $35
    .label buffer_sign = $57
    .label format_zero_padding = $77
    .label putc = $61
    .label format_min_length = $78
    .label len = $46
    .label padding = $46
    .label format_justify_left = $4f
    .label format_upper_case = $34
    // if(format.min_length)
    // [1282] if(0==printf_number_buffer::format_min_length#4) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b6
    // [1283] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [1284] call strlen
    // [1396] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [1396] phi strlen::str#6 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1285] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@14
    // [1286] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1287] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z __19
    sta.z len
    // if(buffer.sign)
    // [1288] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [1289] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1290] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [1290] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [1291] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#4 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1292] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1294] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [1294] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1293] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [1294] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [1294] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1295] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [1296] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [1297] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [1298] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1299] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1300] call printf_padding
    // [1402] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1402] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1402] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@8->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1301] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [1302] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1303] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall28
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1305] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [1306] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1307] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1308] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1309] call printf_padding
    // [1402] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1402] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1402] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@10->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1310] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbuz1_then_la1 
    lda.z format_upper_case
    beq __b5
    // [1311] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1312] call strupr
    // [1527] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1313] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1314] call printf_str
    // [757] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [757] phi printf_str::putc#33 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [757] phi printf_str::s#33 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1315] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1316] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1317] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1318] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1319] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1320] call printf_padding
    // [1402] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1402] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1402] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@12->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1321] return 
    rts
    // Outside Flow
  icall28:
    jmp (putc)
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($26) char value, __zp($44) char *buffer, __zp($2b) char radix)
uctoa: {
    .label __4 = $33
    .label digit_value = $2e
    .label buffer = $44
    .label digit = $34
    .label value = $26
    .label radix = $2b
    .label started = $46
    .label max_digits = $57
    .label digit_values = $3e
    // if(radix==DECIMAL)
    // [1322] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1323] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1324] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1325] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1326] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1327] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1328] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1329] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1330] return 
    rts
    // [1331] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1331] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1331] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1331] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1331] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1331] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1331] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1331] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1331] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1331] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1331] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1331] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1332] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1332] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1332] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1332] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1332] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1333] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1334] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z __4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1335] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1336] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1337] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1338] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1339] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1340] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1341] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1341] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1341] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1341] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1342] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1332] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1332] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1332] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1332] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1332] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1343] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1344] uctoa_append::value#0 = uctoa::value#2
    // [1345] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1346] call uctoa_append
    // [1537] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1347] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1348] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1349] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1341] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1341] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1341] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1341] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($35) char *dst, __zp($3a) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label c = $57
    .label dst = $35
    .label i = $44
    .label src = $3a
    // [1351] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1351] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1351] phi strncpy::src#2 = main::buffer [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z src
    lda #>main.buffer
    sta.z src+1
    // [1351] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1352] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuc1_then_la1 
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
    // [1353] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1354] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1355] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1356] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1357] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1357] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1358] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1359] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1360] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1351] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1351] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1351] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1351] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_setnam
/**
 * @brief Sets the name of the file before opening.
 * 
 * @param filename The name of the file.
 */
// void cbm_k_setnam(__zp($e7) char * volatile filename)
cbm_k_setnam: {
    .label filename = $e7
    .label __0 = $35
    // strlen(filename)
    // [1361] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbuz2 
    lda.z filename
    sta.z strlen.str
    lda.z filename+1
    sta.z strlen.str+1
    // [1362] call strlen
    // [1396] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [1396] phi strlen::str#6 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1363] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [1364] cbm_k_setnam::$0 = strlen::return#0
    // __mem char filename_len = (char)strlen(filename)
    // [1365] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwuz2 
    lda.z __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [1367] return 
    rts
  .segment Data
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
// void cbm_k_setlfs(__zp($ef) volatile char channel, __zp($ed) volatile char device, __zp($e9) volatile char command)
cbm_k_setlfs: {
    .label channel = $ef
    .label device = $ed
    .label command = $e9
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1369] return 
    rts
}
  // cbm_k_open
/**
 * @brief Open a logical file.
 * 
 * @return char The status.
 */
cbm_k_open: {
    .label return = $47
    // __mem unsigned char status
    // [1370] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [1372] cbm_k_open::return#0 = cbm_k_open::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_open::@return
    // }
    // [1373] cbm_k_open::return#1 = cbm_k_open::return#0
    // [1374] return 
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
// __zp($4f) char cbm_k_close(__zp($ec) volatile char channel)
cbm_k_close: {
    .label channel = $ec
    .label return = $4f
    // __mem unsigned char status
    // [1375] cbm_k_close::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldachannel jsrCBM_CLOSE stastatus  }
    lda channel
    jsr CBM_CLOSE
    sta status
    // return status;
    // [1377] cbm_k_close::return#0 = cbm_k_close::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_close::@return
    // }
    // [1378] cbm_k_close::return#1 = cbm_k_close::return#0
    // [1379] return 
    rts
  .segment Data
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
// char cbm_k_chkin(__zp($aa) volatile char channel)
cbm_k_chkin: {
    .label channel = $aa
    // __mem unsigned char status
    // [1380] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [1382] return 
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
    .label return = $68
    // __mem unsigned char status
    // [1383] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [1385] cbm_k_readst::return#0 = cbm_k_readst::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_readst::@return
    // }
    // [1386] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [1387] return 
    rts
  .segment Data
    status: .byte 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($22) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, __zp($77) char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $22
    .label format_zero_padding = $77
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1389] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1390] ultoa::value#1 = printf_ulong::uvalue#2
    // [1391] call ultoa
  // Format number into buffer
    // [1544] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1392] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1393] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#2
    // [1394] call printf_number_buffer
  // Print using format
    // [1281] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1281] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1281] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1281] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1281] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    // [1281] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_justify_left
    // [1281] phi printf_number_buffer::format_min_length#4 = 6 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1395] return 
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($35) unsigned int strlen(__zp($3a) char *str)
strlen: {
    .label str = $3a
    .label return = $35
    .label len = $35
    // [1397] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1397] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1397] phi strlen::str#4 = strlen::str#6 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1398] if(0!=*strlen::str#4) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1399] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1400] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1401] strlen::str#1 = ++ strlen::str#4 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1397] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1397] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1397] phi strlen::str#4 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($44) void (*putc)(char), __zp($48) char pad, __zp($33) char length)
printf_padding: {
    .label i = $29
    .label putc = $44
    .label length = $33
    .label pad = $48
    // [1403] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1403] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1404] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1405] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1406] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1407] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall29
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1409] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1403] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1403] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall29:
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
// __zp($2c) unsigned int fgets(__zp($44) char *ptr, unsigned int size, __zp($7c) struct $1 *fp)
fgets: {
    .const size = $80
    .label __1 = $68
    .label __9 = $68
    .label __10 = $57
    .label __14 = $34
    .label return = $2c
    .label bytes = $40
    .label read = $2c
    .label ptr = $44
    .label remaining = $35
    .label fp = $7c
    // cbm_k_chkin(fp->channel)
    // [1410] cbm_k_chkin::channel = ((char *)fgets::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_chkin.channel
    // [1411] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1412] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [1413] call cbm_k_readst
    jsr cbm_k_readst
    // [1414] cbm_k_readst::return#3 = cbm_k_readst::return#1
    // fgets::@12
    // [1415] fgets::$1 = cbm_k_readst::return#3
    // fp->status = cbm_k_readst()
    // [1416] ((char *)fgets::fp#0)[$13] = fgets::$1 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __1
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [1417] if(0==((char *)fgets::fp#0)[$13]) goto fgets::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b8
    // [1418] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [1418] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1419] return 
    rts
    // [1420] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [1420] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1420] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@12->fgets::@1#1] -- vwuz1=vwuc1 
    lda #<size
    sta.z remaining
    lda #>size
    sta.z remaining+1
    // [1420] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [1420] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [1420] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [1420] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [1420] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [1421] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwuz1_ge_vbuc1_then_la1 
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
    // [1422] cbm_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cbm_k_macptr.bytes
    // [1423] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1424] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1425] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [1426] fgets::bytes#3 = cbm_k_macptr::return#4
    // [1427] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [1427] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [1428] call cbm_k_readst
    jsr cbm_k_readst
    // [1429] cbm_k_readst::return#4 = cbm_k_readst::return#1
    // fgets::@15
    // [1430] fgets::$9 = cbm_k_readst::return#4
    // fp->status = cbm_k_readst()
    // [1431] ((char *)fgets::fp#0)[$13] = fgets::$9 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __9
    ldy #$13
    sta (fp),y
    // fp->status & 0xBF
    // [1432] fgets::$10 = ((char *)fgets::fp#0)[$13] & $bf -- vbuz1=pbuz2_derefidx_vbuc1_band_vbuc2 
    lda #$bf
    and (fp),y
    sta.z __10
    // if(fp->status & 0xBF)
    // [1433] if(0==fgets::$10) goto fgets::@4 -- 0_eq_vbuz1_then_la1 
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [1434] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1435] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1436] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1437] fgets::$14 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z __14
    // if(BYTE1(ptr) == 0xC0)
    // [1438] if(fgets::$14!=$c0) goto fgets::@6 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z __14
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [1439] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1440] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [1440] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [1441] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((fp->status == 0) && ((size && remaining) || !size))
    // [1442] if(((char *)fgets::fp#0)[$13]==0) goto fgets::@16 -- pbuz1_derefidx_vbuc1_eq_0_then_la1 
    ldy #$13
    lda (fp),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [1443] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [1444] cbm_k_chkin::channel = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin.channel
    // [1445] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1418] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [1418] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [1446] cbm_k_macptr::bytes = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cbm_k_macptr.bytes
    // [1447] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1448] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1449] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [1450] fgets::bytes#2 = cbm_k_macptr::return#3
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
    // [1452] return 
    rts
}
  // rom_byte_verify
/**
 * @brief Verify a byte with the flashed ROM using the 22 bit rom address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
// __zp($33) char rom_byte_verify(__zp($3e) char *ptr_rom, __zp($57) char value)
rom_byte_verify: {
    .label return = $33
    .label ptr_rom = $3e
    .label value = $57
    // if (*ptr_rom != value)
    // [1453] if(*rom_byte_verify::ptr_rom#0==rom_byte_verify::value#0) goto rom_byte_verify::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1454] phi from rom_byte_verify to rom_byte_verify::@2 [phi:rom_byte_verify->rom_byte_verify::@2]
    // rom_byte_verify::@2
    // [1455] phi from rom_byte_verify::@2 to rom_byte_verify::@1 [phi:rom_byte_verify::@2->rom_byte_verify::@1]
    // [1455] phi rom_byte_verify::return#0 = 0 [phi:rom_byte_verify::@2->rom_byte_verify::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [1455] phi from rom_byte_verify to rom_byte_verify::@1 [phi:rom_byte_verify->rom_byte_verify::@1]
  __b2:
    // [1455] phi rom_byte_verify::return#0 = 1 [phi:rom_byte_verify->rom_byte_verify::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_verify::@1
    // rom_byte_verify::@return
    // }
    // [1456] return 
    rts
}
  // rom_wait
/**
 * @brief Wait for the required time to allow the chip to flash the byte into the ROM.
 * This is a core wait routine which is the most important routine in this whole program.
 * Once a byte is flashed into the ROM, it takes time for the chip to actually flash the byte.
 * The chip has implemented a loop mechanism to guarantee correct flashing of the written byte.
 * It does this by requiring the execution of two sequential reads from the previously written ROM address.
 * And loop those sequential reads until bit 6 of the 2 read bytes are equal.
 * Once those two bits are equal, the chip has successfully flashed the byte into the ROM.
 *
 *
 * @param ptr_rom The 16 bit pointer where the byte was written. This pointer is used for the sequence reads to verify bit 6.
 */
/* inline */
// void rom_wait(__zp($35) char *ptr_rom)
rom_wait: {
    .label __0 = $34
    .label __1 = $33
    .label test1 = $34
    .label test2 = $33
    .label ptr_rom = $35
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [1458] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [1459] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [1460] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z __0
    sta.z __0
    // test2 & 0x40
    // [1461] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z __1
    sta.z __1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [1462] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z __0
    cmp.z __1
    bne __b1
    // rom_wait::@return
    // }
    // [1463] return 
    rts
}
  // rom_byte_program
/**
 * @brief Write a byte and wait until the byte has been successfully flashed into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
/* inline */
// void rom_byte_program(__zp($50) unsigned long address, __zp($48) char value)
rom_byte_program: {
    .label rom_ptr1___0 = $40
    .label rom_ptr1___2 = $40
    .label rom_ptr1_return = $40
    .label address = $50
    .label value = $48
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1465] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1___2
    lda.z address+1
    sta.z rom_ptr1___2+1
    // [1466] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1___0
    and #<$3fff
    sta.z rom_ptr1___0
    lda.z rom_ptr1___0+1
    and #>$3fff
    sta.z rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1467] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [1468] rom_write_byte::address#3 = rom_byte_program::address#0
    // [1469] rom_write_byte::value#3 = rom_byte_program::value#0
    // [1470] call rom_write_byte
    // [1474] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [1474] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [1474] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [1471] rom_wait::ptr_rom#0 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [1472] call rom_wait
    // [1457] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [1457] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [1473] return 
    rts
}
  // rom_write_byte
/**
 * @brief Write a byte to the ROM using the 22 bit address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
// void rom_write_byte(__zp($50) unsigned long address, __zp($48) char value)
rom_write_byte: {
    .label rom_bank1___0 = $33
    .label rom_bank1___1 = $2e
    .label rom_bank1___2 = $3e
    .label rom_ptr1___0 = $42
    .label rom_ptr1___2 = $42
    .label rom_bank1_bank_unshifted = $3e
    .label rom_bank1_return = $34
    .label rom_ptr1_return = $42
    .label address = $50
    .label value = $48
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [1475] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1___0
    // BYTE1(address)
    // [1476] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1477] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1___0
    sta.z rom_bank1___2+1
    lda.z rom_bank1___1
    sta.z rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1478] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1479] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1480] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1___2
    lda.z address+1
    sta.z rom_ptr1___2+1
    // [1481] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1___0
    and #<$3fff
    sta.z rom_ptr1___0
    lda.z rom_ptr1___0+1
    and #>$3fff
    sta.z rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1482] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::@1
    // bank_set_brom(bank_rom)
    // [1483] bank_set_brom::bank#3 = rom_write_byte::rom_bank1_return#0
    // [1484] call bank_set_brom
    // [818] phi from rom_write_byte::@1 to bank_set_brom [phi:rom_write_byte::@1->bank_set_brom]
    // [818] phi bank_set_brom::bank#12 = bank_set_brom::bank#3 [phi:rom_write_byte::@1->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_write_byte::@2
    // *ptr_rom = value
    // [1485] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [1486] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label __0 = $67
    .label __4 = $5a
    .label __6 = $5b
    .label __7 = $5a
    .label width = $67
    .label y = $56
    // __conio.width+1
    // [1487] insertup::$0 = *((char *)&__conio+4) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+4
    inc
    sta.z __0
    // unsigned char width = (__conio.width+1) * 2
    // [1488] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z width
    // [1489] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1489] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1490] if(insertup::y#2<=*((char *)&__conio+$e)) goto insertup::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+$e
    cmp.z y
    bcs __b2
    // [1491] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1492] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1493] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1494] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z __4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1495] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z __6
    // [1496] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __7
    // [1497] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.dbank_vram
    // [1498] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1499] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.sbank_vram
    // [1500] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1501] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [1502] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1503] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1489] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1489] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label __0 = $49
    .label __1 = $4b
    .label __2 = $4c
    .label __3 = $4a
    .label addr = $58
    .label c = $37
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1504] clearline::$3 = *((char *)&__conio+$e) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    sta.z __3
    // [1505] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1506] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1507] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z __0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1508] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1509] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z __1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1510] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1511] clearline::$2 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1512] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1513] clearline::c#0 = *((char *)&__conio+4) -- vbuz1=_deref_pbuc1 
    lda __conio+4
    sta.z c
    // [1514] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1514] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1515] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1516] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [1517] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1518] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1519] return 
    rts
}
  // utoa_append
// Used to convert a single digit of an unsigned number value to a string representation
// Counts a single digit up from '0' as long as the value is larger than sub.
// Each time the digit is increased sub is subtracted from value.
// - buffer : pointer to the char that receives the digit
// - value : The value where the digit will be derived from
// - sub : the value of a '1' in the digit. Subtracted continually while the digit is increased.
//        (For decimal the subs used are 10000, 1000, 100, 10, 1)
// returns : the value reduced by sub * digit so that it is less than sub.
// __zp($27) unsigned int utoa_append(__zp($40) char *buffer, __zp($27) unsigned int value, __zp($2c) unsigned int sub)
utoa_append: {
    .label buffer = $40
    .label value = $27
    .label sub = $2c
    .label return = $27
    .label digit = $29
    // [1521] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1521] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1521] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1522] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1523] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1524] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1525] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1526] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1521] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1521] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1521] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label __0 = $39
    .label src = $2c
    // [1528] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1528] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1529] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1530] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1531] toupper::ch#0 = *strupr::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z toupper.ch
    // [1532] call toupper
    jsr toupper
    // [1533] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1534] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1535] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbuz2 
    lda.z __0
    ldy #0
    sta (src),y
    // src++;
    // [1536] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1528] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1528] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
    jmp __b1
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
// __zp($26) char uctoa_append(__zp($2c) char *buffer, __zp($26) char value, __zp($2e) char sub)
uctoa_append: {
    .label buffer = $2c
    .label value = $26
    .label sub = $2e
    .label return = $26
    .label digit = $2a
    // [1538] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1538] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1538] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1539] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1540] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1541] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1542] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1543] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [1538] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1538] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1538] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($22) unsigned long value, __zp($40) char *buffer, char radix)
ultoa: {
    .label __10 = $46
    .label __11 = $2e
    .label digit_value = $2f
    .label buffer = $40
    .label digit = $2a
    .label value = $22
    .label started = $39
    // [1545] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1545] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1545] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1545] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1545] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1546] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1547] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z __11
    // [1548] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1549] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1550] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1551] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1552] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z __10
    // [1553] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [1554] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [1555] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1556] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1556] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1556] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1556] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1557] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1545] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1545] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1545] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1545] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1545] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1558] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1559] ultoa_append::value#0 = ultoa::value#2
    // [1560] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1561] call ultoa_append
    // [1595] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1562] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1563] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1564] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1556] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1556] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1556] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1556] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
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
// __zp($40) unsigned int cbm_k_macptr(__zp($71) volatile char bytes, __zp($6e) void * volatile buffer)
cbm_k_macptr: {
    .label bytes = $71
    .label buffer = $6e
    .label return = $40
    // __mem unsigned int bytes_read
    // [1565] cbm_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [1567] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwuz1=vwum2 
    lda bytes_read
    sta.z return
    lda bytes_read+1
    sta.z return+1
    // cbm_k_macptr::@return
    // }
    // [1568] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [1569] return 
    rts
  .segment Data
    bytes_read: .word 0
}
.segment Code
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
// void memcpy8_vram_vram(__zp($4a) char dbank_vram, __zp($58) unsigned int doffset_vram, __zp($49) char sbank_vram, __zp($54) unsigned int soffset_vram, __zp($38) char num8)
memcpy8_vram_vram: {
    .label __0 = $4b
    .label __1 = $4c
    .label __2 = $49
    .label __3 = $4d
    .label __4 = $4e
    .label __5 = $4a
    .label num8 = $38
    .label dbank_vram = $4a
    .label doffset_vram = $58
    .label sbank_vram = $49
    .label soffset_vram = $54
    .label num8_1 = $37
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1570] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1571] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z __0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1572] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1573] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z __1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1574] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1575] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z __2
    sta.z __2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1576] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1577] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1578] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z __3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1579] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1580] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z __4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1581] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1582] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z __5
    sta.z __5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1583] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1584] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1584] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1585] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [1586] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1587] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1588] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1589] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
    lda.z num8
    sta.z num8_1
    jmp __b1
}
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __zp($39) char toupper(__zp($39) char ch)
toupper: {
    .label return = $39
    .label ch = $39
    // if(ch>='a' && ch<='z')
    // [1590] if(toupper::ch#0<'a'pm) goto toupper::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z ch
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1591] if(toupper::ch#0<='z'pm) goto toupper::@1 -- vbuz1_le_vbuc1_then_la1 
    lda #'z'
    cmp.z ch
    bcs __b1
    // [1593] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1593] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1592] toupper::return#0 = toupper::ch#0 + 'A'pm-'a'pm -- vbuz1=vbuz1_plus_vbuc1 
    lda #'A'-'a'
    clc
    adc.z return
    sta.z return
    // toupper::@return
  __breturn:
    // }
    // [1594] return 
    rts
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
// __zp($22) unsigned long ultoa_append(__zp($3e) char *buffer, __zp($22) unsigned long value, __zp($2f) unsigned long sub)
ultoa_append: {
    .label buffer = $3e
    .label value = $22
    .label sub = $2f
    .label return = $22
    .label digit = $2b
    // [1596] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1596] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1596] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1597] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [1598] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1599] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1600] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1601] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [1596] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1596] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1596] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
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
  // Values of binary digits
  RADIX_BINARY_VALUES: .word $8000, $4000, $2000, $1000, $800, $400, $200, $100, $80, $40, $20, $10, 8, 4, 2
  // Values of octal digits
  RADIX_OCTAL_VALUES: .word $8000, $1000, $200, $40, 8
  // Values of decimal digits
  RADIX_DECIMAL_VALUES: .word $2710, $3e8, $64, $a
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
