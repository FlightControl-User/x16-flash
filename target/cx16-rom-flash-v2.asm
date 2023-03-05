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
  /// Current position in the buffer being filled ( initially *s passed to snprintf()
  /// Used to hold state while printing
  .label __snprintf_buffer = $ea
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
    // [3] __snprintf_buffer = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z __snprintf_buffer
    sta.z __snprintf_buffer+1
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
// void snputc(__zp($d2) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $d2
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
    // [16] *__snprintf_buffer = snputc::c#2 -- _deref_pbuz1=vbuz2 
    // Append char
    lda.z c
    ldy #0
    sta (__snprintf_buffer),y
    // *(__snprintf_buffer++) = c;
    // [17] __snprintf_buffer = ++ __snprintf_buffer -- pbuz1=_inc_pbuz1 
    inc.z __snprintf_buffer
    bne !+
    inc.z __snprintf_buffer+1
  !:
    rts
}
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    .label __4 = $c9
    .label __5 = $7c
    .label __6 = $c9
    .label __7 = $ee
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [413] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [418] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuz1=_byte0_vwuz2 
    lda.z __6
    sta.z __7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+$e) = conio_x16_init::$7 -- _deref_pbuc1=vbuz1 
    sta __conio+$e
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#1 = *((char *)&__conio+$d) -- vbuz1=_deref_pbuc1 
    lda __conio+$d
    sta.z gotoxy.x
    // [38] gotoxy::y#1 = *((char *)&__conio+$e) -- vbuz1=_deref_pbuc1 
    lda __conio+$e
    sta.z gotoxy.y
    // [39] call gotoxy
    // [431] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
}
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__zp($52) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label __1 = $32
    .label __2 = $7e
    .label __3 = $7f
    .label c = $52
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
    .label __19 = $d8
    .label __63 = $af
    .label __79 = $2a
    .label __87 = $7b
    .label __96 = $5b
    .label __136 = $6c
    .label r = $e3
    .label rom_chip = $e9
    .label flash_rom_address = $e4
    .label flash_chip = $e8
    .label flash_rom_bank = $f1
    .label fp = $ec
    .label flash_rom_address_boundary = $34
    .label flash_bytes = $b3
    .label flash_rom_address_boundary_1 = $3f
    .label flash_bytes_1 = $dd
    .label flash_rom_address_sector = $ab
    .label equal_bytes = $63
    .label read_ram_address_sector = $c0
    .label flash_rom_address_boundary1 = $c4
    .label retries = $bd
    .label flash_errors = $b0
    .label read_ram_address = $bb
    .label flash_rom_address1 = $b7
    .label x = $b1
    .label flash_errors_sector = $c2
    .label x_sector = $cc
    .label read_ram_bank_sector = $be
    .label y_sector = $cb
    .label v = $d0
    .label w = $e1
    .label rom_device = $f2
    .label pattern = $3b
    .label flash_rom_address_boundary_2 = $dd
    .label __166 = $d8
    .label __167 = $d8
    .label __169 = $af
    .label __170 = $af
    .label __172 = $7b
    .label __173 = $7b
    .label __175 = $2a
    .label __176 = $2a
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@49
    // cbm_x_charset(3, (char *)0)
    // [72] cbm_x_charset::charset = 3 -- vbuz1=vbuc1 
    lda #3
    sta.z cbm_x_charset.charset
    // [73] cbm_x_charset::offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cbm_x_charset.offset
    sta.z cbm_x_charset.offset+1
    // [74] call cbm_x_charset
    // Set the charset to lower case.
    jsr cbm_x_charset
    // [75] phi from main::@49 to main::@57 [phi:main::@49->main::@57]
    // main::@57
    // textcolor(WHITE)
    // [76] call textcolor
    // [413] phi from main::@57 to textcolor [phi:main::@57->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:main::@57->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [77] phi from main::@57 to main::@58 [phi:main::@57->main::@58]
    // main::@58
    // bgcolor(BLUE)
    // [78] call bgcolor
    // [418] phi from main::@58 to bgcolor [phi:main::@58->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:main::@58->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [79] phi from main::@58 to main::@59 [phi:main::@58->main::@59]
    // main::@59
    // scroll(0)
    // [80] call scroll
    jsr scroll
    // [81] phi from main::@59 to main::@60 [phi:main::@59->main::@60]
    // main::@60
    // clrscr()
    // [82] call clrscr
    jsr clrscr
    // [83] phi from main::@60 to main::@61 [phi:main::@60->main::@61]
    // main::@61
    // frame_draw()
    // [84] call frame_draw
    // [479] phi from main::@61 to frame_draw [phi:main::@61->frame_draw]
    jsr frame_draw
    // [85] phi from main::@61 to main::@62 [phi:main::@61->main::@62]
    // main::@62
    // gotoxy(33, 1)
    // [86] call gotoxy
    // [431] phi from main::@62 to gotoxy [phi:main::@62->gotoxy]
    // [431] phi gotoxy::y#22 = 1 [phi:main::@62->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = $21 [phi:main::@62->gotoxy#1] -- vbuz1=vbuc1 
    lda #$21
    sta.z gotoxy.x
    jsr gotoxy
    // [87] phi from main::@62 to main::@63 [phi:main::@62->main::@63]
    // main::@63
    // printf("rom flash utility")
    // [88] call printf_str
    // [659] phi from main::@63 to printf_str [phi:main::@63->printf_str]
    // [659] phi printf_str::putc#20 = &cputc [phi:main::@63->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s [phi:main::@63->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [89] phi from main::@63 to main::@1 [phi:main::@63->main::@1]
    // [89] phi main::r#10 = 0 [phi:main::@63->main::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // main::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [90] if(main::r#10<8) goto main::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcs !__b2+
    jmp __b2
  !__b2:
    // [91] phi from main::@1 to main::@3 [phi:main::@1->main::@3]
    // [91] phi main::rom_chip#10 = 0 [phi:main::@1->main::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // [91] phi main::flash_rom_address#10 = 0 [phi:main::@1->main::@3#1] -- vduz1=vduc1 
    sta.z flash_rom_address
    sta.z flash_rom_address+1
    lda #<0>>$10
    sta.z flash_rom_address+2
    lda #>0>>$10
    sta.z flash_rom_address+3
    // main::@3
  __b3:
    // for (unsigned long flash_rom_address = 0; flash_rom_address < 8 * 0x80000; flash_rom_address += 0x80000)
    // [92] if(main::flash_rom_address#10<8*$80000) goto main::@4 -- vduz1_lt_vduc1_then_la1 
    lda.z flash_rom_address+3
    cmp #>8*$80000>>$10
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda.z flash_rom_address+2
    cmp #<8*$80000>>$10
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda.z flash_rom_address+1
    cmp #>8*$80000
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda.z flash_rom_address
    cmp #<8*$80000
    bcs !__b4+
    jmp __b4
  !__b4:
  !:
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [94] phi from main::CLI1 to main::@50 [phi:main::CLI1->main::@50]
    // main::@50
    // wait_key()
    // [95] call wait_key
  // printf("press any key to start flashing ...\n");
    // [668] phi from main::@50 to wait_key [phi:main::@50->wait_key]
    jsr wait_key
    // [96] phi from main::@50 to main::@15 [phi:main::@50->main::@15]
    // [96] phi main::flash_chip#10 = 7 [phi:main::@50->main::@15#0] -- vbuz1=vbuc1 
    lda #7
    sta.z flash_chip
    // main::@15
  __b15:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [97] if(main::flash_chip#10!=$ff) goto main::@16 -- vbuz1_neq_vbuc1_then_la1 
    lda #$ff
    cmp.z flash_chip
    bne __b16
    // [98] phi from main::@15 to main::@17 [phi:main::@15->main::@17]
    // main::@17
    // textcolor(WHITE)
    // [99] call textcolor
    // [413] phi from main::@17 to textcolor [phi:main::@17->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:main::@17->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [100] phi from main::@17 to main::@83 [phi:main::@17->main::@83]
    // main::@83
    // sprintf(buffer, "resetting commander x16" )
    // [101] call snprintf_init
    jsr snprintf_init
    // [102] phi from main::@83 to main::@84 [phi:main::@83->main::@84]
    // main::@84
    // sprintf(buffer, "resetting commander x16" )
    // [103] call printf_str
    // [659] phi from main::@84 to printf_str [phi:main::@84->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@84->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s1 [phi:main::@84->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@85
    // sprintf(buffer, "resetting commander x16" )
    // [104] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [105] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [107] call print_text
    // [682] phi from main::@85 to print_text [phi:main::@85->print_text]
    jsr print_text
    // [108] phi from main::@85 to main::@44 [phi:main::@85->main::@44]
    // [108] phi main::w#2 = 0 [phi:main::@85->main::@44#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z w
    sta.z w+1
    // main::@44
  __b44:
    // for (unsigned int w = 0; w < 32; w++)
    // [109] if(main::w#2<$20) goto main::@46 -- vwuz1_lt_vbuc1_then_la1 
    lda.z w+1
    bne !+
    lda.z w
    cmp #$20
    bcc __b9
  !:
    // [110] phi from main::@44 to main::@45 [phi:main::@44->main::@45]
    // main::@45
    // system_reset()
    // [111] call system_reset
    // [689] phi from main::@45 to system_reset [phi:main::@45->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [112] return 
    rts
    // [113] phi from main::@44 to main::@46 [phi:main::@44->main::@46]
  __b9:
    // [113] phi main::v#2 = 0 [phi:main::@44->main::@46#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z v
    sta.z v+1
    // main::@46
  __b46:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [114] if(main::v#2<$100*$80) goto main::@47 -- vwuz1_lt_vwuc1_then_la1 
    lda.z v+1
    cmp #>$100*$80
    bcc __b47
    bne !+
    lda.z v
    cmp #<$100*$80
    bcc __b47
  !:
    // main::@48
    // cputc('.')
    // [115] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [116] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for (unsigned int w = 0; w < 32; w++)
    // [118] main::w#1 = ++ main::w#2 -- vwuz1=_inc_vwuz1 
    inc.z w
    bne !+
    inc.z w+1
  !:
    // [108] phi from main::@48 to main::@44 [phi:main::@48->main::@44]
    // [108] phi main::w#2 = main::w#1 [phi:main::@48->main::@44#0] -- register_copy 
    jmp __b44
    // main::@47
  __b47:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [119] main::v#1 = ++ main::v#2 -- vwuz1=_inc_vwuz1 
    inc.z v
    bne !+
    inc.z v+1
  !:
    // [113] phi from main::@47 to main::@46 [phi:main::@47->main::@46]
    // [113] phi main::v#2 = main::v#1 [phi:main::@47->main::@46#0] -- register_copy 
    jmp __b46
    // main::@16
  __b16:
    // if (rom_device_ids[flash_chip] != UNKNOWN)
    // [120] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@18 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b18+
    jmp __b18
  !__b18:
    // [121] phi from main::@16 to main::@42 [phi:main::@16->main::@42]
    // main::@42
    // gotoxy(0, 2)
    // [122] call gotoxy
    // [431] phi from main::@42 to gotoxy [phi:main::@42->gotoxy]
    // [431] phi gotoxy::y#22 = 2 [phi:main::@42->gotoxy#0] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = 0 [phi:main::@42->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [123] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [124] phi from main::bank_set_bram1 to main::@51 [phi:main::bank_set_bram1->main::@51]
    // main::@51
    // bank_set_brom(4)
    // [125] call bank_set_brom
    // [695] phi from main::@51 to bank_set_brom [phi:main::@51->bank_set_brom]
    // [695] phi bank_set_brom::bank#8 = 4 [phi:main::@51->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@86
    // if (flash_chip == 0)
    // [126] if(main::flash_chip#10==0) goto main::@19 -- vbuz1_eq_0_then_la1 
    lda.z flash_chip
    bne !__b19+
    jmp __b19
  !__b19:
    // [127] phi from main::@86 to main::@43 [phi:main::@86->main::@43]
    // main::@43
    // sprintf(file, "rom%u.bin", flash_chip)
    // [128] call snprintf_init
    jsr snprintf_init
    // [129] phi from main::@43 to main::@89 [phi:main::@43->main::@89]
    // main::@89
    // sprintf(file, "rom%u.bin", flash_chip)
    // [130] call printf_str
    // [659] phi from main::@89 to printf_str [phi:main::@89->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@89->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s3 [phi:main::@89->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@90
    // sprintf(file, "rom%u.bin", flash_chip)
    // [131] printf_uchar::uvalue#2 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z printf_uchar.uvalue
    // [132] call printf_uchar
    // [698] phi from main::@90 to printf_uchar [phi:main::@90->printf_uchar]
    // [698] phi printf_uchar::format_zero_padding#4 = 0 [phi:main::@90->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [698] phi printf_uchar::format_min_length#4 = 0 [phi:main::@90->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [698] phi printf_uchar::putc#4 = &snputc [phi:main::@90->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [698] phi printf_uchar::format_radix#4 = DECIMAL [phi:main::@90->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [698] phi printf_uchar::uvalue#4 = printf_uchar::uvalue#2 [phi:main::@90->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [133] phi from main::@90 to main::@91 [phi:main::@90->main::@91]
    // main::@91
    // sprintf(file, "rom%u.bin", flash_chip)
    // [134] call printf_str
    // [659] phi from main::@91 to printf_str [phi:main::@91->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@91->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s4 [phi:main::@91->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@92
    // sprintf(file, "rom%u.bin", flash_chip)
    // [135] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [136] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // main::@20
  __b20:
    // unsigned char flash_rom_bank = flash_chip * 32
    // [138] main::flash_rom_bank#0 = main::flash_chip#10 << 5 -- vbuz1=vbuz2_rol_5 
    lda.z flash_chip
    asl
    asl
    asl
    asl
    asl
    sta.z flash_rom_bank
    // FILE *fp = fopen(1, 8, 2, file)
    // [139] call fopen
    // Read the file content.
    jsr fopen
    // [140] fopen::return#4 = fopen::return#1
    // main::@93
    // [141] main::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [142] if((struct $1 *)0!=main::fp#0) goto main::@21 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    bne __b21
    lda.z fp
    cmp #<0
    bne __b21
    // [143] phi from main::@93 to main::@41 [phi:main::@93->main::@41]
    // main::@41
    // textcolor(WHITE)
    // [144] call textcolor
    // [413] phi from main::@41 to textcolor [phi:main::@41->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:main::@41->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@105
    // flash_chip * 10
    // [145] main::$175 = main::flash_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z flash_chip
    asl
    asl
    sta.z __175
    // [146] main::$176 = main::$175 + main::flash_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z __176
    clc
    adc.z flash_chip
    sta.z __176
    // [147] main::$79 = main::$176 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __79
    // gotoxy(2 + flash_chip * 10, 58)
    // [148] gotoxy::x#17 = 2 + main::$79 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __79
    sta.z gotoxy.x
    // [149] call gotoxy
    // [431] phi from main::@105 to gotoxy [phi:main::@105->gotoxy]
    // [431] phi gotoxy::y#22 = $3a [phi:main::@105->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = gotoxy::x#17 [phi:main::@105->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [150] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // printf("no file")
    // [151] call printf_str
    // [659] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [659] phi printf_str::putc#20 = &cputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s6 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [152] print_chip_led::r#6 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [153] call print_chip_led
    // [746] phi from main::@107 to print_chip_led [phi:main::@107->print_chip_led]
    // [746] phi print_chip_led::tc#10 = DARK_GREY [phi:main::@107->print_chip_led#0] -- vbuz1=vbuc1 
    lda #DARK_GREY
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#6 [phi:main::@107->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [154] phi from main::@107 main::@136 main::@142 to main::@22 [phi:main::@107/main::@136/main::@142->main::@22]
    // main::@22
  __b22:
    // wait_key()
    // [155] call wait_key
    // [668] phi from main::@22 to wait_key [phi:main::@22->wait_key]
    jsr wait_key
    // main::@18
  __b18:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [156] main::flash_chip#1 = -- main::flash_chip#10 -- vbuz1=_dec_vbuz1 
    dec.z flash_chip
    // [96] phi from main::@18 to main::@15 [phi:main::@18->main::@15]
    // [96] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@18->main::@15#0] -- register_copy 
    jmp __b15
    // main::@21
  __b21:
    // table_chip_clear(flash_chip * 32)
    // [157] table_chip_clear::rom_bank#1 = main::flash_chip#10 << 5 -- vbuz1=vbuz2_rol_5 
    lda.z flash_chip
    asl
    asl
    asl
    asl
    asl
    sta.z table_chip_clear.rom_bank
    // [158] call table_chip_clear
    // [766] phi from main::@21 to table_chip_clear [phi:main::@21->table_chip_clear]
    jsr table_chip_clear
    // [159] phi from main::@21 to main::@94 [phi:main::@21->main::@94]
    // main::@94
    // textcolor(WHITE)
    // [160] call textcolor
    // [413] phi from main::@94 to textcolor [phi:main::@94->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:main::@94->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@95
    // flash_chip * 10
    // [161] main::$172 = main::flash_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z flash_chip
    asl
    asl
    sta.z __172
    // [162] main::$173 = main::$172 + main::flash_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z __173
    clc
    adc.z flash_chip
    sta.z __173
    // [163] main::$87 = main::$173 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __87
    // gotoxy(2 + flash_chip * 10, 58)
    // [164] gotoxy::x#16 = 2 + main::$87 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __87
    sta.z gotoxy.x
    // [165] call gotoxy
    // [431] phi from main::@95 to gotoxy [phi:main::@95->gotoxy]
    // [431] phi gotoxy::y#22 = $3a [phi:main::@95->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = gotoxy::x#16 [phi:main::@95->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [166] phi from main::@95 to main::@96 [phi:main::@95->main::@96]
    // main::@96
    // printf("%s", file)
    // [167] call printf_string
    // [791] phi from main::@96 to printf_string [phi:main::@96->printf_string]
    // [791] phi printf_string::str#10 = main::buffer [phi:main::@96->printf_string#0] -- pbuz1=pbuc1 
    lda #<buffer
    sta.z printf_string.str
    lda #>buffer
    sta.z printf_string.str+1
    // [791] phi printf_string::format_justify_left#10 = 0 [phi:main::@96->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [791] phi printf_string::format_min_length#6 = 0 [phi:main::@96->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@97
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [168] print_chip_led::r#5 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [169] call print_chip_led
    // [746] phi from main::@97 to print_chip_led [phi:main::@97->print_chip_led]
    // [746] phi print_chip_led::tc#10 = CYAN [phi:main::@97->print_chip_led#0] -- vbuz1=vbuc1 
    lda #CYAN
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#5 [phi:main::@97->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [170] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // sprintf(buffer, "reading in ram ...")
    // [171] call snprintf_init
    jsr snprintf_init
    // [172] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // sprintf(buffer, "reading in ram ...")
    // [173] call printf_str
    // [659] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s5 [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@100
    // sprintf(buffer, "reading in ram ...")
    // [174] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [175] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [177] call print_text
    // [682] phi from main::@100 to print_text [phi:main::@100->print_text]
    jsr print_text
    // main::@101
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [178] rom_address::rom_bank#2 = main::flash_rom_bank#0 -- vbuz1=vbuz2 
    lda.z flash_rom_bank
    sta.z rom_address.rom_bank
    // [179] call rom_address
    // [813] phi from main::@101 to rom_address [phi:main::@101->rom_address]
    // [813] phi rom_address::rom_bank#4 = rom_address::rom_bank#2 [phi:main::@101->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [180] rom_address::return#4 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_2
    lda.z rom_address.return+1
    sta.z rom_address.return_2+1
    lda.z rom_address.return+2
    sta.z rom_address.return_2+2
    lda.z rom_address.return+3
    sta.z rom_address.return_2+3
    // main::@102
    // [181] main::flash_rom_address_boundary#0 = rom_address::return#4
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [182] flash_read::fp#0 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [183] flash_read::rom_bank_start#1 = main::flash_rom_bank#0 -- vbuz1=vbuz2 
    lda.z flash_rom_bank
    sta.z flash_read.rom_bank_start
    // [184] call flash_read
    // [817] phi from main::@102 to flash_read [phi:main::@102->flash_read]
    // [817] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@102->flash_read#0] -- register_copy 
    // [817] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@102->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [817] phi flash_read::rom_bank_size#2 = 1 [phi:main::@102->flash_read#2] -- vbuz1=vbuc1 
    lda #1
    sta.z flash_read.rom_bank_size
    // [817] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@102->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [185] flash_read::return#3 = flash_read::return#2
    // main::@103
    // [186] main::flash_bytes#0 = flash_read::return#3
    // rom_size(1)
    // [187] call rom_size
    // [853] phi from main::@103 to rom_size [phi:main::@103->rom_size]
    // [853] phi rom_size::rom_banks#2 = 1 [phi:main::@103->rom_size#0] -- vbuz1=vbuc1 
    lda #1
    sta.z rom_size.rom_banks
    jsr rom_size
    // rom_size(1)
    // [188] rom_size::return#3 = rom_size::return#0
    // main::@104
    // [189] main::$96 = rom_size::return#3
    // if (flash_bytes != rom_size(1))
    // [190] if(main::flash_bytes#0==main::$96) goto main::@23 -- vduz1_eq_vduz2_then_la1 
    lda.z flash_bytes
    cmp.z __96
    bne !+
    lda.z flash_bytes+1
    cmp.z __96+1
    bne !+
    lda.z flash_bytes+2
    cmp.z __96+2
    bne !+
    lda.z flash_bytes+3
    cmp.z __96+3
    beq __b23
  !:
    rts
    // main::@23
  __b23:
    // flash_rom_address_boundary += flash_bytes
    // [191] main::flash_rom_address_boundary#1 = main::flash_rom_address_boundary#0 + main::flash_bytes#0 -- vduz1=vduz2_plus_vduz3 
    lda.z flash_rom_address_boundary
    clc
    adc.z flash_bytes
    sta.z flash_rom_address_boundary_1
    lda.z flash_rom_address_boundary+1
    adc.z flash_bytes+1
    sta.z flash_rom_address_boundary_1+1
    lda.z flash_rom_address_boundary+2
    adc.z flash_bytes+2
    sta.z flash_rom_address_boundary_1+2
    lda.z flash_rom_address_boundary+3
    adc.z flash_bytes+3
    sta.z flash_rom_address_boundary_1+3
    // main::bank_set_bram2
    // BRAM = bank
    // [192] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@52
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [193] flash_read::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z flash_rom_bank
    inc
    sta.z flash_read.rom_bank_start
    // [194] flash_read::fp#1 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [195] call flash_read
    // [817] phi from main::@52 to flash_read [phi:main::@52->flash_read]
    // [817] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@52->flash_read#0] -- register_copy 
    // [817] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@52->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [817] phi flash_read::rom_bank_size#2 = $1f [phi:main::@52->flash_read#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z flash_read.rom_bank_size
    // [817] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@52->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [196] flash_read::return#4 = flash_read::return#2
    // main::@108
    // flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [197] main::flash_bytes#1 = flash_read::return#4 -- vduz1=vduz2 
    lda.z flash_read.return
    sta.z flash_bytes_1
    lda.z flash_read.return+1
    sta.z flash_bytes_1+1
    lda.z flash_read.return+2
    sta.z flash_bytes_1+2
    lda.z flash_read.return+3
    sta.z flash_bytes_1+3
    // flash_rom_address_boundary += flash_bytes
    // [198] main::flash_rom_address_boundary#13 = main::flash_rom_address_boundary#1 + main::flash_bytes#1 -- vduz1=vduz2_plus_vduz1 
    clc
    lda.z flash_rom_address_boundary_2
    adc.z flash_rom_address_boundary_1
    sta.z flash_rom_address_boundary_2
    lda.z flash_rom_address_boundary_2+1
    adc.z flash_rom_address_boundary_1+1
    sta.z flash_rom_address_boundary_2+1
    lda.z flash_rom_address_boundary_2+2
    adc.z flash_rom_address_boundary_1+2
    sta.z flash_rom_address_boundary_2+2
    lda.z flash_rom_address_boundary_2+3
    adc.z flash_rom_address_boundary_1+3
    sta.z flash_rom_address_boundary_2+3
    // fclose(fp)
    // [199] fclose::fp#0 = main::fp#0
    // [200] call fclose
    jsr fclose
    // main::bank_set_bram3
    // BRAM = bank
    // [201] BRAM = main::bank_set_bram3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram3_bank
    sta.z BRAM
    // [202] phi from main::bank_set_bram3 to main::@53 [phi:main::bank_set_bram3->main::@53]
    // main::@53
    // bank_set_brom(4)
    // [203] call bank_set_brom
    // [695] phi from main::@53 to bank_set_brom [phi:main::@53->bank_set_brom]
    // [695] phi bank_set_brom::bank#8 = 4 [phi:main::@53->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::@54
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [205] rom_address::rom_bank#3 = main::flash_rom_bank#0 -- vbuz1=vbuz2 
    lda.z flash_rom_bank
    sta.z rom_address.rom_bank
    // [206] call rom_address
    // [813] phi from main::@54 to rom_address [phi:main::@54->rom_address]
    // [813] phi rom_address::rom_bank#4 = rom_address::rom_bank#3 [phi:main::@54->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [207] rom_address::return#10 = rom_address::return#0
    // main::@109
    // [208] main::flash_rom_address_sector#0 = rom_address::return#10
    // textcolor(WHITE)
    // [209] call textcolor
    // [413] phi from main::@109 to textcolor [phi:main::@109->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:main::@109->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@110
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [210] print_chip_led::r#7 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [211] call print_chip_led
    // [746] phi from main::@110 to print_chip_led [phi:main::@110->print_chip_led]
    // [746] phi print_chip_led::tc#10 = PURPLE [phi:main::@110->print_chip_led#0] -- vbuz1=vbuc1 
    lda #PURPLE
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#7 [phi:main::@110->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [212] phi from main::@110 to main::@111 [phi:main::@110->main::@111]
    // main::@111
    // sprintf(buffer, "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error.")
    // [213] call snprintf_init
    jsr snprintf_init
    // [214] phi from main::@111 to main::@112 [phi:main::@111->main::@112]
    // main::@112
    // sprintf(buffer, "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error.")
    // [215] call printf_str
    // [659] phi from main::@112 to printf_str [phi:main::@112->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@112->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s7 [phi:main::@112->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@113
    // sprintf(buffer, "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error.")
    // [216] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [217] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [219] call print_text
    // [682] phi from main::@113 to print_text [phi:main::@113->print_text]
    jsr print_text
    // [220] phi from main::@113 to main::@24 [phi:main::@113->main::@24]
    // [220] phi main::flash_errors_sector#10 = 0 [phi:main::@113->main::@24#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [220] phi main::y_sector#13 = 4 [phi:main::@113->main::@24#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector
    // [220] phi main::x_sector#10 = $e [phi:main::@113->main::@24#2] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [220] phi main::read_ram_address_sector#15 = (char *) 16384 [phi:main::@113->main::@24#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address_sector
    lda #>$4000
    sta.z read_ram_address_sector+1
    // [220] phi main::read_ram_bank_sector#19 = 1 [phi:main::@113->main::@24#4] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank_sector
    // [220] phi main::flash_rom_address_sector#10 = main::flash_rom_address_sector#0 [phi:main::@113->main::@24#5] -- register_copy 
    // [220] phi from main::@35 to main::@24 [phi:main::@35->main::@24]
    // [220] phi main::flash_errors_sector#10 = main::flash_errors_sector#24 [phi:main::@35->main::@24#0] -- register_copy 
    // [220] phi main::y_sector#13 = main::y_sector#13 [phi:main::@35->main::@24#1] -- register_copy 
    // [220] phi main::x_sector#10 = main::x_sector#1 [phi:main::@35->main::@24#2] -- register_copy 
    // [220] phi main::read_ram_address_sector#15 = main::read_ram_address_sector#13 [phi:main::@35->main::@24#3] -- register_copy 
    // [220] phi main::read_ram_bank_sector#19 = main::read_ram_bank_sector#13 [phi:main::@35->main::@24#4] -- register_copy 
    // [220] phi main::flash_rom_address_sector#10 = main::flash_rom_address_sector#1 [phi:main::@35->main::@24#5] -- register_copy 
    // main::@24
  __b24:
    // while (flash_rom_address_sector < flash_rom_address_boundary)
    // [221] if(main::flash_rom_address_sector#10<main::flash_rom_address_boundary#13) goto main::@25 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address_sector+3
    cmp.z flash_rom_address_boundary_2+3
    bcs !__b25+
    jmp __b25
  !__b25:
    bne !+
    lda.z flash_rom_address_sector+2
    cmp.z flash_rom_address_boundary_2+2
    bcs !__b25+
    jmp __b25
  !__b25:
    bne !+
    lda.z flash_rom_address_sector+1
    cmp.z flash_rom_address_boundary_2+1
    bcs !__b25+
    jmp __b25
  !__b25:
    bne !+
    lda.z flash_rom_address_sector
    cmp.z flash_rom_address_boundary_2
    bcs !__b25+
    jmp __b25
  !__b25:
  !:
    // main::bank_set_bram4
    // BRAM = bank
    // [222] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // [223] phi from main::bank_set_bram4 to main::@55 [phi:main::bank_set_bram4->main::@55]
    // main::@55
    // bank_set_brom(4)
    // [224] call bank_set_brom
    // [695] phi from main::@55 to bank_set_brom [phi:main::@55->bank_set_brom]
    // [695] phi bank_set_brom::bank#8 = 4 [phi:main::@55->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::@56
    // if (!flash_errors_sector)
    // [226] if(0==main::flash_errors_sector#10) goto main::@40 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b40
    // [227] phi from main::@56 to main::@39 [phi:main::@56->main::@39]
    // main::@39
    // textcolor(RED)
    // [228] call textcolor
    // [413] phi from main::@39 to textcolor [phi:main::@39->textcolor]
    // [413] phi textcolor::color#22 = RED [phi:main::@39->textcolor#0] -- vbuz1=vbuc1 
    lda #RED
    sta.z textcolor.color
    jsr textcolor
    // [229] phi from main::@39 to main::@137 [phi:main::@39->main::@137]
    // main::@137
    // sprintf(buffer, "the flashing went wrong, %u errors. press a key to flash the next chip ...", flash_errors_sector)
    // [230] call snprintf_init
    jsr snprintf_init
    // [231] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(buffer, "the flashing went wrong, %u errors. press a key to flash the next chip ...", flash_errors_sector)
    // [232] call printf_str
    // [659] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s14 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(buffer, "the flashing went wrong, %u errors. press a key to flash the next chip ...", flash_errors_sector)
    // [233] printf_uint::uvalue#1 = main::flash_errors_sector#10 -- vwuz1=vwuz2 
    lda.z flash_errors_sector
    sta.z printf_uint.uvalue
    lda.z flash_errors_sector+1
    sta.z printf_uint.uvalue+1
    // [234] call printf_uint
    // [867] phi from main::@139 to printf_uint [phi:main::@139->printf_uint]
    // [867] phi printf_uint::format_min_length#2 = 0 [phi:main::@139->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_min_length
    // [867] phi printf_uint::putc#2 = &snputc [phi:main::@139->printf_uint#1] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [867] phi printf_uint::format_radix#2 = DECIMAL [phi:main::@139->printf_uint#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [867] phi printf_uint::uvalue#2 = printf_uint::uvalue#1 [phi:main::@139->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [235] phi from main::@139 to main::@140 [phi:main::@139->main::@140]
    // main::@140
    // sprintf(buffer, "the flashing went wrong, %u errors. press a key to flash the next chip ...", flash_errors_sector)
    // [236] call printf_str
    // [659] phi from main::@140 to printf_str [phi:main::@140->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@140->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s15 [phi:main::@140->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@141
    // sprintf(buffer, "the flashing went wrong, %u errors. press a key to flash the next chip ...", flash_errors_sector)
    // [237] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [238] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [240] call print_text
    // [682] phi from main::@141 to print_text [phi:main::@141->print_text]
    jsr print_text
    // main::@142
    // print_chip_led(flash_chip, RED, BLUE)
    // [241] print_chip_led::r#9 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [242] call print_chip_led
    // [746] phi from main::@142 to print_chip_led [phi:main::@142->print_chip_led]
    // [746] phi print_chip_led::tc#10 = RED [phi:main::@142->print_chip_led#0] -- vbuz1=vbuc1 
    lda #RED
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#9 [phi:main::@142->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp __b22
    // [243] phi from main::@56 to main::@40 [phi:main::@56->main::@40]
    // main::@40
  __b40:
    // textcolor(GREEN)
    // [244] call textcolor
    // [413] phi from main::@40 to textcolor [phi:main::@40->textcolor]
    // [413] phi textcolor::color#22 = GREEN [phi:main::@40->textcolor#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z textcolor.color
    jsr textcolor
    // [245] phi from main::@40 to main::@133 [phi:main::@40->main::@133]
    // main::@133
    // sprintf(buffer, "the flashing went perfectly ok. press a key to flash the next chip ...", file)
    // [246] call snprintf_init
    jsr snprintf_init
    // [247] phi from main::@133 to main::@134 [phi:main::@133->main::@134]
    // main::@134
    // sprintf(buffer, "the flashing went perfectly ok. press a key to flash the next chip ...", file)
    // [248] call printf_str
    // [659] phi from main::@134 to printf_str [phi:main::@134->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@134->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s13 [phi:main::@134->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@135
    // sprintf(buffer, "the flashing went perfectly ok. press a key to flash the next chip ...", file)
    // [249] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [250] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [252] call print_text
    // [682] phi from main::@135 to print_text [phi:main::@135->print_text]
    jsr print_text
    // main::@136
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [253] print_chip_led::r#8 = main::flash_chip#10 -- vbuz1=vbuz2 
    lda.z flash_chip
    sta.z print_chip_led.r
    // [254] call print_chip_led
    // [746] phi from main::@136 to print_chip_led [phi:main::@136->print_chip_led]
    // [746] phi print_chip_led::tc#10 = GREEN [phi:main::@136->print_chip_led#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#8 [phi:main::@136->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp __b22
    // main::@25
  __b25:
    // unsigned long equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [255] flash_verify::verify_ram_bank#0 = main::read_ram_bank_sector#19 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_verify.verify_ram_bank
    // [256] flash_verify::verify_ram_address#1 = main::read_ram_address_sector#15 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z flash_verify.verify_ram_address
    lda.z read_ram_address_sector+1
    sta.z flash_verify.verify_ram_address+1
    // [257] flash_verify::verify_rom_address#1 = main::flash_rom_address_sector#10 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address_sector+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address_sector+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address_sector+3
    sta.z flash_verify.verify_rom_address+3
    // [258] call flash_verify
    // [877] phi from main::@25 to flash_verify [phi:main::@25->flash_verify]
    // [877] phi flash_verify::verify_ram_address#8 = flash_verify::verify_ram_address#1 [phi:main::@25->flash_verify#0] -- register_copy 
    // [877] phi flash_verify::verify_rom_address#8 = flash_verify::verify_rom_address#1 [phi:main::@25->flash_verify#1] -- register_copy 
    // [877] phi flash_verify::verify_rom_size#4 = $1000 [phi:main::@25->flash_verify#2] -- vduz1=vduc1 
    lda #<$1000
    sta.z flash_verify.verify_rom_size
    lda #>$1000
    sta.z flash_verify.verify_rom_size+1
    lda #<$1000>>$10
    sta.z flash_verify.verify_rom_size+2
    lda #>$1000>>$10
    sta.z flash_verify.verify_rom_size+3
    // [877] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::verify_ram_bank#0 [phi:main::@25->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned long equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [259] flash_verify::return#2 = flash_verify::correct_bytes#2
    // main::@114
    // [260] main::equal_bytes#0 = flash_verify::return#2
    // if (equal_bytes != ROM_SECTOR)
    // [261] if(main::equal_bytes#0!=$1000) goto main::@27 -- vduz1_neq_vduc1_then_la1 
    lda.z equal_bytes+3
    cmp #>$1000>>$10
    beq !__b11+
    jmp __b11
  !__b11:
    lda.z equal_bytes+2
    cmp #<$1000>>$10
    beq !__b11+
    jmp __b11
  !__b11:
    lda.z equal_bytes+1
    cmp #>$1000
    beq !__b11+
    jmp __b11
  !__b11:
    lda.z equal_bytes
    cmp #<$1000
    beq !__b11+
    jmp __b11
  !__b11:
    // [262] phi from main::@114 to main::@36 [phi:main::@114->main::@36]
    // main::@36
    // textcolor(WHITE)
    // [263] call textcolor
    // [413] phi from main::@36 to textcolor [phi:main::@36->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:main::@36->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@115
    // gotoxy(x_sector, y_sector)
    // [264] gotoxy::x#18 = main::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z gotoxy.x
    // [265] gotoxy::y#18 = main::y_sector#13 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z gotoxy.y
    // [266] call gotoxy
    // [431] phi from main::@115 to gotoxy [phi:main::@115->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#18 [phi:main::@115->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = gotoxy::x#18 [phi:main::@115->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [267] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // printf("%s", pattern)
    // [268] call printf_string
    // [791] phi from main::@116 to printf_string [phi:main::@116->printf_string]
    // [791] phi printf_string::str#10 = main::pattern#1 [phi:main::@116->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern_1
    sta.z printf_string.str
    lda #>pattern_1
    sta.z printf_string.str+1
    // [791] phi printf_string::format_justify_left#10 = 0 [phi:main::@116->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [791] phi printf_string::format_min_length#6 = 0 [phi:main::@116->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [269] phi from main::@116 main::@33 to main::@26 [phi:main::@116/main::@33->main::@26]
    // [269] phi main::flash_errors_sector#24 = main::flash_errors_sector#10 [phi:main::@116/main::@33->main::@26#0] -- register_copy 
    // main::@26
  __b26:
    // read_ram_address_sector += ROM_SECTOR
    // [270] main::read_ram_address_sector#1 = main::read_ram_address_sector#15 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address_sector
    clc
    adc #<$1000
    sta.z read_ram_address_sector
    lda.z read_ram_address_sector+1
    adc #>$1000
    sta.z read_ram_address_sector+1
    // flash_rom_address_sector += ROM_SECTOR
    // [271] main::flash_rom_address_sector#1 = main::flash_rom_address_sector#10 + $1000 -- vduz1=vduz1_plus_vwuc1 
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
    // [272] if(main::read_ram_address_sector#1!=$8000) goto main::@144 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$8000
    bne __b34
    lda.z read_ram_address_sector
    cmp #<$8000
    bne __b34
    // [274] phi from main::@26 to main::@34 [phi:main::@26->main::@34]
    // [274] phi main::read_ram_bank_sector#11 = 1 [phi:main::@26->main::@34#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank_sector
    // [274] phi main::read_ram_address_sector#7 = (char *) 40960 [phi:main::@26->main::@34#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [273] phi from main::@26 to main::@144 [phi:main::@26->main::@144]
    // main::@144
    // [274] phi from main::@144 to main::@34 [phi:main::@144->main::@34]
    // [274] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#19 [phi:main::@144->main::@34#0] -- register_copy 
    // [274] phi main::read_ram_address_sector#7 = main::read_ram_address_sector#1 [phi:main::@144->main::@34#1] -- register_copy 
    // main::@34
  __b34:
    // if (read_ram_address_sector == 0xC000)
    // [275] if(main::read_ram_address_sector#7!=$c000) goto main::@35 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$c000
    bne __b35
    lda.z read_ram_address_sector
    cmp #<$c000
    bne __b35
    // main::@37
    // read_ram_bank_sector++;
    // [276] main::read_ram_bank_sector#2 = ++ main::read_ram_bank_sector#11 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank_sector
    // [277] phi from main::@37 to main::@35 [phi:main::@37->main::@35]
    // [277] phi main::read_ram_address_sector#13 = (char *) 40960 [phi:main::@37->main::@35#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [277] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#2 [phi:main::@37->main::@35#1] -- register_copy 
    // [277] phi from main::@34 to main::@35 [phi:main::@34->main::@35]
    // [277] phi main::read_ram_address_sector#13 = main::read_ram_address_sector#7 [phi:main::@34->main::@35#0] -- register_copy 
    // [277] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@34->main::@35#1] -- register_copy 
    // main::@35
  __b35:
    // x_sector += 16
    // [278] main::x_sector#1 = main::x_sector#10 + $10 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$10
    clc
    adc.z x_sector
    sta.z x_sector
    // flash_rom_address_sector % 0x4000
    // [279] main::$136 = main::flash_rom_address_sector#1 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address_sector
    and #<$4000-1
    sta.z __136
    lda.z flash_rom_address_sector+1
    and #>$4000-1
    sta.z __136+1
    lda.z flash_rom_address_sector+2
    and #<$4000-1>>$10
    sta.z __136+2
    lda.z flash_rom_address_sector+3
    and #>$4000-1>>$10
    sta.z __136+3
    // if (!(flash_rom_address_sector % 0x4000))
    // [280] if(0!=main::$136) goto main::@24 -- 0_neq_vduz1_then_la1 
    lda.z __136
    ora.z __136+1
    ora.z __136+2
    ora.z __136+3
    beq !__b24+
    jmp __b24
  !__b24:
    // main::@38
    // y_sector++;
    // [281] main::y_sector#1 = ++ main::y_sector#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [220] phi from main::@38 to main::@24 [phi:main::@38->main::@24]
    // [220] phi main::flash_errors_sector#10 = main::flash_errors_sector#24 [phi:main::@38->main::@24#0] -- register_copy 
    // [220] phi main::y_sector#13 = main::y_sector#1 [phi:main::@38->main::@24#1] -- register_copy 
    // [220] phi main::x_sector#10 = $e [phi:main::@38->main::@24#2] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [220] phi main::read_ram_address_sector#15 = main::read_ram_address_sector#13 [phi:main::@38->main::@24#3] -- register_copy 
    // [220] phi main::read_ram_bank_sector#19 = main::read_ram_bank_sector#13 [phi:main::@38->main::@24#4] -- register_copy 
    // [220] phi main::flash_rom_address_sector#10 = main::flash_rom_address_sector#1 [phi:main::@38->main::@24#5] -- register_copy 
    jmp __b24
    // [282] phi from main::@114 to main::@27 [phi:main::@114->main::@27]
  __b11:
    // [282] phi main::flash_errors#10 = 0 [phi:main::@114->main::@27#0] -- vbuz1=vbuc1 
    lda #0
    sta.z flash_errors
    // [282] phi main::retries#10 = 0 [phi:main::@114->main::@27#1] -- vbuz1=vbuc1 
    sta.z retries
    // [282] phi from main::@143 to main::@27 [phi:main::@143->main::@27]
    // [282] phi main::flash_errors#10 = main::flash_errors#11 [phi:main::@143->main::@27#0] -- register_copy 
    // [282] phi main::retries#10 = main::retries#1 [phi:main::@143->main::@27#1] -- register_copy 
    // main::@27
  __b27:
    // rom_sector_erase(flash_rom_address_sector)
    // [283] rom_sector_erase::address#0 = main::flash_rom_address_sector#10
    // [284] call rom_sector_erase
    jsr rom_sector_erase
    // main::@117
    // unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR
    // [285] main::flash_rom_address_boundary1#0 = main::flash_rom_address_sector#10 + $1000 -- vduz1=vduz2_plus_vwuc1 
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
    // [286] gotoxy::x#19 = main::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z gotoxy.x
    // [287] gotoxy::y#19 = main::y_sector#13 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z gotoxy.y
    // [288] call gotoxy
    // [431] phi from main::@117 to gotoxy [phi:main::@117->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#19 [phi:main::@117->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = gotoxy::x#19 [phi:main::@117->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [289] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // printf("................")
    // [290] call printf_str
    // [659] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [659] phi printf_str::putc#20 = &cputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s8 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // [291] main::flash_rom_address1#22 = main::flash_rom_address_sector#10 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_rom_address1
    lda.z flash_rom_address_sector+1
    sta.z flash_rom_address1+1
    lda.z flash_rom_address_sector+2
    sta.z flash_rom_address1+2
    lda.z flash_rom_address_sector+3
    sta.z flash_rom_address1+3
    // [292] main::read_ram_address#22 = main::read_ram_address_sector#15 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z read_ram_address
    lda.z read_ram_address_sector+1
    sta.z read_ram_address+1
    // [293] main::x#22 = main::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z x
    // [294] phi from main::@119 main::@132 to main::@28 [phi:main::@119/main::@132->main::@28]
    // [294] phi main::x#10 = main::x#22 [phi:main::@119/main::@132->main::@28#0] -- register_copy 
    // [294] phi main::read_ram_address#10 = main::read_ram_address#22 [phi:main::@119/main::@132->main::@28#1] -- register_copy 
    // [294] phi main::flash_errors#11 = main::flash_errors#10 [phi:main::@119/main::@132->main::@28#2] -- register_copy 
    // [294] phi main::flash_rom_address1#10 = main::flash_rom_address1#22 [phi:main::@119/main::@132->main::@28#3] -- register_copy 
    // main::@28
  __b28:
    // while(flash_rom_address < flash_rom_address_boundary)
    // [295] if(main::flash_rom_address1#10<main::flash_rom_address_boundary1#0) goto main::@29 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address1+3
    cmp.z flash_rom_address_boundary1+3
    bcc __b29
    bne !+
    lda.z flash_rom_address1+2
    cmp.z flash_rom_address_boundary1+2
    bcc __b29
    bne !+
    lda.z flash_rom_address1+1
    cmp.z flash_rom_address_boundary1+1
    bcc __b29
    bne !+
    lda.z flash_rom_address1
    cmp.z flash_rom_address_boundary1
    bcc __b29
  !:
    // main::@30
    // retries++;
    // [296] main::retries#1 = ++ main::retries#10 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while(flash_errors && retries <= 3)
    // [297] if(0==main::flash_errors#11) goto main::@33 -- 0_eq_vbuz1_then_la1 
    lda.z flash_errors
    beq __b33
    // main::@143
    // [298] if(main::retries#1<3+1) goto main::@27 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcc __b27
    // main::@33
  __b33:
    // flash_errors_sector += flash_errors
    // [299] main::flash_errors_sector#1 = main::flash_errors_sector#10 + main::flash_errors#11 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z flash_errors
    clc
    adc.z flash_errors_sector
    sta.z flash_errors_sector
    bcc !+
    inc.z flash_errors_sector+1
  !:
    jmp __b26
    // [300] phi from main::@28 to main::@29 [phi:main::@28->main::@29]
    // main::@29
  __b29:
    // gotoxy(0,0)
    // [301] call gotoxy
    // [431] phi from main::@29 to gotoxy [phi:main::@29->gotoxy]
    // [431] phi gotoxy::y#22 = 0 [phi:main::@29->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = 0 [phi:main::@29->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // [302] phi from main::@29 to main::@120 [phi:main::@29->main::@120]
    // main::@120
    // printf("ram = %2x, %4p, rom = %6x ", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [303] call printf_str
    // [659] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [659] phi printf_str::putc#20 = &cputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s9 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@121
    // printf("ram = %2x, %4p, rom = %6x ", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [304] printf_uchar::uvalue#3 = main::read_ram_bank_sector#19 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z printf_uchar.uvalue
    // [305] call printf_uchar
    // [698] phi from main::@121 to printf_uchar [phi:main::@121->printf_uchar]
    // [698] phi printf_uchar::format_zero_padding#4 = 0 [phi:main::@121->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [698] phi printf_uchar::format_min_length#4 = 2 [phi:main::@121->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [698] phi printf_uchar::putc#4 = &cputc [phi:main::@121->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [698] phi printf_uchar::format_radix#4 = HEXADECIMAL [phi:main::@121->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [698] phi printf_uchar::uvalue#4 = printf_uchar::uvalue#3 [phi:main::@121->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [306] phi from main::@121 to main::@122 [phi:main::@121->main::@122]
    // main::@122
    // printf("ram = %2x, %4p, rom = %6x ", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [307] call printf_str
    // [659] phi from main::@122 to printf_str [phi:main::@122->printf_str]
    // [659] phi printf_str::putc#20 = &cputc [phi:main::@122->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s10 [phi:main::@122->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@123
    // printf("ram = %2x, %4p, rom = %6x ", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [308] printf_uint::uvalue#0 = (unsigned int)main::read_ram_address#10 -- vwuz1=vwuz2 
    lda.z read_ram_address
    sta.z printf_uint.uvalue
    lda.z read_ram_address+1
    sta.z printf_uint.uvalue+1
    // [309] call printf_uint
    // [867] phi from main::@123 to printf_uint [phi:main::@123->printf_uint]
    // [867] phi printf_uint::format_min_length#2 = 4 [phi:main::@123->printf_uint#0] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [867] phi printf_uint::putc#2 = &cputc [phi:main::@123->printf_uint#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [867] phi printf_uint::format_radix#2 = HEXADECIMAL [phi:main::@123->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [867] phi printf_uint::uvalue#2 = printf_uint::uvalue#0 [phi:main::@123->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [310] phi from main::@123 to main::@124 [phi:main::@123->main::@124]
    // main::@124
    // printf("ram = %2x, %4p, rom = %6x ", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [311] call printf_str
    // [659] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [659] phi printf_str::putc#20 = &cputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s11 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@125
    // printf("ram = %2x, %4p, rom = %6x ", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [312] printf_ulong::uvalue#1 = main::flash_rom_address1#10 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z printf_ulong.uvalue
    lda.z flash_rom_address1+1
    sta.z printf_ulong.uvalue+1
    lda.z flash_rom_address1+2
    sta.z printf_ulong.uvalue+2
    lda.z flash_rom_address1+3
    sta.z printf_ulong.uvalue+3
    // [313] call printf_ulong
    // [896] phi from main::@125 to printf_ulong [phi:main::@125->printf_ulong]
    // [896] phi printf_ulong::format_zero_padding#2 = 0 [phi:main::@125->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [896] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:main::@125->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [314] phi from main::@125 to main::@126 [phi:main::@125->main::@126]
    // main::@126
    // printf("ram = %2x, %4p, rom = %6x ", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [315] call printf_str
    // [659] phi from main::@126 to printf_str [phi:main::@126->printf_str]
    // [659] phi printf_str::putc#20 = &cputc [phi:main::@126->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = str [phi:main::@126->printf_str#1] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_str.s
    lda #>str
    sta.z printf_str.s+1
    jsr printf_str
    // main::@127
    // unsigned long written_bytes = flash_write(read_ram_bank_sector, (ram_ptr_t)read_ram_address, flash_rom_address)
    // [316] flash_write::flash_ram_bank#0 = main::read_ram_bank_sector#19 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_write.flash_ram_bank
    // [317] flash_write::flash_ram_address#1 = main::read_ram_address#10 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z flash_write.flash_ram_address
    lda.z read_ram_address+1
    sta.z flash_write.flash_ram_address+1
    // [318] flash_write::flash_rom_address#1 = main::flash_rom_address1#10 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z flash_write.flash_rom_address
    lda.z flash_rom_address1+1
    sta.z flash_write.flash_rom_address+1
    lda.z flash_rom_address1+2
    sta.z flash_write.flash_rom_address+2
    lda.z flash_rom_address1+3
    sta.z flash_write.flash_rom_address+3
    // [319] call flash_write
    // [904] phi from main::@127 to flash_write [phi:main::@127->flash_write]
    jsr flash_write
    // main::@128
    // flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [320] flash_verify::verify_ram_bank#1 = main::read_ram_bank_sector#19 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_verify.verify_ram_bank
    // [321] flash_verify::verify_ram_address#2 = main::read_ram_address#10 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z flash_verify.verify_ram_address
    lda.z read_ram_address+1
    sta.z flash_verify.verify_ram_address+1
    // [322] flash_verify::verify_rom_address#2 = main::flash_rom_address1#10 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address1+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address1+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address1+3
    sta.z flash_verify.verify_rom_address+3
    // [323] call flash_verify
    // [877] phi from main::@128 to flash_verify [phi:main::@128->flash_verify]
    // [877] phi flash_verify::verify_ram_address#8 = flash_verify::verify_ram_address#2 [phi:main::@128->flash_verify#0] -- register_copy 
    // [877] phi flash_verify::verify_rom_address#8 = flash_verify::verify_rom_address#2 [phi:main::@128->flash_verify#1] -- register_copy 
    // [877] phi flash_verify::verify_rom_size#4 = $100 [phi:main::@128->flash_verify#2] -- vduz1=vduc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    lda #<$100>>$10
    sta.z flash_verify.verify_rom_size+2
    lda #>$100>>$10
    sta.z flash_verify.verify_rom_size+3
    // [877] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::verify_ram_bank#1 [phi:main::@128->flash_verify#3] -- register_copy 
    jsr flash_verify
    // flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [324] flash_verify::return#3 = flash_verify::correct_bytes#2
    // main::@129
    // equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [325] main::equal_bytes#1 = flash_verify::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [326] if(main::equal_bytes#1!=$1000) goto main::@31 -- vduz1_neq_vduc1_then_la1 
    lda.z equal_bytes+3
    cmp #>$1000>>$10
    bne __b31
    lda.z equal_bytes+2
    cmp #<$1000>>$10
    bne __b31
    lda.z equal_bytes+1
    cmp #>$1000
    bne __b31
    lda.z equal_bytes
    cmp #<$1000
    bne __b31
    // [328] phi from main::@129 to main::@32 [phi:main::@129->main::@32]
    // [328] phi main::flash_errors#12 = main::flash_errors#11 [phi:main::@129->main::@32#0] -- register_copy 
    // [328] phi main::pattern#5 = main::pattern#3 [phi:main::@129->main::@32#1] -- pbuz1=pbuc1 
    lda #<pattern_3
    sta.z pattern
    lda #>pattern_3
    sta.z pattern+1
    jmp __b32
    // main::@31
  __b31:
    // flash_errors++;
    // [327] main::flash_errors#1 = ++ main::flash_errors#11 -- vbuz1=_inc_vbuz1 
    inc.z flash_errors
    // [328] phi from main::@31 to main::@32 [phi:main::@31->main::@32]
    // [328] phi main::flash_errors#12 = main::flash_errors#1 [phi:main::@31->main::@32#0] -- register_copy 
    // [328] phi main::pattern#5 = main::pattern#2 [phi:main::@31->main::@32#1] -- pbuz1=pbuc1 
    lda #<pattern_2
    sta.z pattern
    lda #>pattern_2
    sta.z pattern+1
    // main::@32
  __b32:
    // read_ram_address += 0x0100
    // [329] main::read_ram_address#1 = main::read_ram_address#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address
    clc
    adc #<$100
    sta.z read_ram_address
    lda.z read_ram_address+1
    adc #>$100
    sta.z read_ram_address+1
    // flash_rom_address += 0x0100
    // [330] main::flash_rom_address1#1 = main::flash_rom_address1#10 + $100 -- vduz1=vduz1_plus_vwuc1 
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
    // textcolor(WHITE)
    // [331] call textcolor
    // [413] phi from main::@32 to textcolor [phi:main::@32->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:main::@32->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@130
    // gotoxy(x, y)
    // [332] gotoxy::x#21 = main::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [333] gotoxy::y#21 = main::y_sector#13 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z gotoxy.y
    // [334] call gotoxy
    // [431] phi from main::@130 to gotoxy [phi:main::@130->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#21 [phi:main::@130->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = gotoxy::x#21 [phi:main::@130->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@131
    // printf("%s", pattern)
    // [335] printf_string::str#5 = main::pattern#5
    // [336] call printf_string
    // [791] phi from main::@131 to printf_string [phi:main::@131->printf_string]
    // [791] phi printf_string::str#10 = printf_string::str#5 [phi:main::@131->printf_string#0] -- register_copy 
    // [791] phi printf_string::format_justify_left#10 = 0 [phi:main::@131->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [791] phi printf_string::format_min_length#6 = 0 [phi:main::@131->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@132
    // x++;
    // [337] main::x#1 = ++ main::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b28
    // [338] phi from main::@86 to main::@19 [phi:main::@86->main::@19]
    // main::@19
  __b19:
    // sprintf(file, "rom.bin", flash_chip)
    // [339] call snprintf_init
    jsr snprintf_init
    // [340] phi from main::@19 to main::@87 [phi:main::@19->main::@87]
    // main::@87
    // sprintf(file, "rom.bin", flash_chip)
    // [341] call printf_str
    // [659] phi from main::@87 to printf_str [phi:main::@87->printf_str]
    // [659] phi printf_str::putc#20 = &snputc [phi:main::@87->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = main::s2 [phi:main::@87->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@88
    // sprintf(file, "rom.bin", flash_chip)
    // [342] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [343] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b20
    // main::@4
  __b4:
    // rom_manufacturer_ids[rom_chip] = 0
    // [345] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [346] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // if (flash_rom_address <= 0x100000)
    // [347] if(main::flash_rom_address#10>$100000) goto main::@5 -- vduz1_gt_vduc1_then_la1 
    lda #>$100000>>$10
    cmp.z flash_rom_address+3
    bcc __b5
    bne !+
    lda #<$100000>>$10
    cmp.z flash_rom_address+2
    bcc __b5
    bne !+
    lda #>$100000
    cmp.z flash_rom_address+1
    bcc __b5
    bne !+
    lda #<$100000
    cmp.z flash_rom_address
    bcc __b5
  !:
    // [348] phi from main::@4 to main::@12 [phi:main::@4->main::@12]
    // main::@12
    // rom_unlock(0x05555, 0x90)
    // [349] call rom_unlock
    // [912] phi from main::@12 to rom_unlock [phi:main::@12->rom_unlock]
    // [912] phi rom_unlock::unlock_code#2 = $90 [phi:main::@12->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    jsr rom_unlock
    // main::@76
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [350] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [351] main::rom_device_ids[main::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_unlock(0x05555, 0xF0)
    // [352] call rom_unlock
    // [912] phi from main::@76 to rom_unlock [phi:main::@76->rom_unlock]
    // [912] phi rom_unlock::unlock_code#2 = $f0 [phi:main::@76->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    jsr rom_unlock
    // [353] phi from main::@4 main::@76 to main::@5 [phi:main::@4/main::@76->main::@5]
    // main::@5
  __b5:
    // bank_set_brom(4)
    // [354] call bank_set_brom
  // Ensure the ROM is set to BASIC.
    // [695] phi from main::@5 to bank_set_brom [phi:main::@5->bank_set_brom]
    // [695] phi bank_set_brom::bank#8 = 4 [phi:main::@5->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@75
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             break;
    // [355] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@6 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip
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
    // [356] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@7 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [357] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@8 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b8+
    jmp __b8
  !__b8:
    // main::@9
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [358] print_chip_led::r#4 = main::rom_chip#10 -- vbuz1=vbuz2 
    tya
    sta.z print_chip_led.r
    // [359] call print_chip_led
    // [746] phi from main::@9 to print_chip_led [phi:main::@9->print_chip_led]
    // [746] phi print_chip_led::tc#10 = BLACK [phi:main::@9->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#4 [phi:main::@9->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@77
    // rom_device_ids[rom_chip] = UNKNOWN
    // [360] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // [361] phi from main::@77 to main::@10 [phi:main::@77->main::@10]
    // [361] phi main::rom_device#5 = main::rom_device#13 [phi:main::@77->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_4
    sta.z rom_device
    lda #>rom_device_4
    sta.z rom_device+1
    // main::@10
  __b10:
    // textcolor(WHITE)
    // [362] call textcolor
    // [413] phi from main::@10 to textcolor [phi:main::@10->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:main::@10->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@78
    // rom_chip * 10
    // [363] main::$169 = main::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z __169
    // [364] main::$170 = main::$169 + main::rom_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z __170
    clc
    adc.z rom_chip
    sta.z __170
    // [365] main::$63 = main::$170 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __63
    // gotoxy(2 + rom_chip * 10, 56)
    // [366] gotoxy::x#13 = 2 + main::$63 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __63
    sta.z gotoxy.x
    // [367] call gotoxy
    // [431] phi from main::@78 to gotoxy [phi:main::@78->gotoxy]
    // [431] phi gotoxy::y#22 = $38 [phi:main::@78->gotoxy#0] -- vbuz1=vbuc1 
    lda #$38
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = gotoxy::x#13 [phi:main::@78->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@79
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [368] printf_uchar::uvalue#1 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip
    lda rom_manufacturer_ids,y
    sta.z printf_uchar.uvalue
    // [369] call printf_uchar
    // [698] phi from main::@79 to printf_uchar [phi:main::@79->printf_uchar]
    // [698] phi printf_uchar::format_zero_padding#4 = 0 [phi:main::@79->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [698] phi printf_uchar::format_min_length#4 = 0 [phi:main::@79->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [698] phi printf_uchar::putc#4 = &cputc [phi:main::@79->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [698] phi printf_uchar::format_radix#4 = HEXADECIMAL [phi:main::@79->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [698] phi printf_uchar::uvalue#4 = printf_uchar::uvalue#1 [phi:main::@79->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // main::@80
    // gotoxy(2 + rom_chip * 10, 57)
    // [370] gotoxy::x#14 = 2 + main::$63 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __63
    sta.z gotoxy.x
    // [371] call gotoxy
    // [431] phi from main::@80 to gotoxy [phi:main::@80->gotoxy]
    // [431] phi gotoxy::y#22 = $39 [phi:main::@80->gotoxy#0] -- vbuz1=vbuc1 
    lda #$39
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = gotoxy::x#14 [phi:main::@80->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@81
    // printf("%s", rom_device)
    // [372] printf_string::str#2 = main::rom_device#5 -- pbuz1=pbuz2 
    lda.z rom_device
    sta.z printf_string.str
    lda.z rom_device+1
    sta.z printf_string.str+1
    // [373] call printf_string
    // [791] phi from main::@81 to printf_string [phi:main::@81->printf_string]
    // [791] phi printf_string::str#10 = printf_string::str#2 [phi:main::@81->printf_string#0] -- register_copy 
    // [791] phi printf_string::format_justify_left#10 = 0 [phi:main::@81->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [791] phi printf_string::format_min_length#6 = 0 [phi:main::@81->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@82
    // rom_chip++;
    // [374] main::rom_chip#1 = ++ main::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // main::@11
    // flash_rom_address += 0x80000
    // [375] main::flash_rom_address#1 = main::flash_rom_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [91] phi from main::@11 to main::@3 [phi:main::@11->main::@3]
    // [91] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@11->main::@3#0] -- register_copy 
    // [91] phi main::flash_rom_address#10 = main::flash_rom_address#1 [phi:main::@11->main::@3#1] -- register_copy 
    jmp __b3
    // main::@8
  __b8:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [376] print_chip_led::r#3 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_led.r
    // [377] call print_chip_led
    // [746] phi from main::@8 to print_chip_led [phi:main::@8->print_chip_led]
    // [746] phi print_chip_led::tc#10 = WHITE [phi:main::@8->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#3 [phi:main::@8->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [361] phi from main::@8 to main::@10 [phi:main::@8->main::@10]
    // [361] phi main::rom_device#5 = main::rom_device#12 [phi:main::@8->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_3
    sta.z rom_device
    lda #>rom_device_3
    sta.z rom_device+1
    jmp __b10
    // main::@7
  __b7:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [378] print_chip_led::r#2 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_led.r
    // [379] call print_chip_led
    // [746] phi from main::@7 to print_chip_led [phi:main::@7->print_chip_led]
    // [746] phi print_chip_led::tc#10 = WHITE [phi:main::@7->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#2 [phi:main::@7->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [361] phi from main::@7 to main::@10 [phi:main::@7->main::@10]
    // [361] phi main::rom_device#5 = main::rom_device#11 [phi:main::@7->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_2
    sta.z rom_device
    lda #>rom_device_2
    sta.z rom_device+1
    jmp __b10
    // main::@6
  __b6:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [380] print_chip_led::r#1 = main::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_chip_led.r
    // [381] call print_chip_led
    // [746] phi from main::@6 to print_chip_led [phi:main::@6->print_chip_led]
    // [746] phi print_chip_led::tc#10 = WHITE [phi:main::@6->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#1 [phi:main::@6->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [361] phi from main::@6 to main::@10 [phi:main::@6->main::@10]
    // [361] phi main::rom_device#5 = main::rom_device#1 [phi:main::@6->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_1
    sta.z rom_device
    lda #>rom_device_1
    sta.z rom_device+1
    jmp __b10
    // main::@2
  __b2:
    // r * 10
    // [382] main::$166 = main::r#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z r
    asl
    asl
    sta.z __166
    // [383] main::$167 = main::$166 + main::r#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z __167
    clc
    adc.z r
    sta.z __167
    // [384] main::$19 = main::$167 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __19
    // print_chip_line(3 + r * 10, 45, ' ')
    // [385] print_chip_line::x#0 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [386] call print_chip_line
    // [919] phi from main::@2 to print_chip_line [phi:main::@2->print_chip_line]
    // [919] phi print_chip_line::c#10 = ' 'pm [phi:main::@2->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [919] phi print_chip_line::y#9 = $2d [phi:main::@2->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2d
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#0 [phi:main::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@64
    // print_chip_line(3 + r * 10, 46, 'r')
    // [387] print_chip_line::x#1 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [388] call print_chip_line
    // [919] phi from main::@64 to print_chip_line [phi:main::@64->print_chip_line]
    // [919] phi print_chip_line::c#10 = 'r'pm [phi:main::@64->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'r'
    sta.z print_chip_line.c
    // [919] phi print_chip_line::y#9 = $2e [phi:main::@64->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2e
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#1 [phi:main::@64->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@65
    // print_chip_line(3 + r * 10, 47, 'o')
    // [389] print_chip_line::x#2 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [390] call print_chip_line
    // [919] phi from main::@65 to print_chip_line [phi:main::@65->print_chip_line]
    // [919] phi print_chip_line::c#10 = 'o'pm [phi:main::@65->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'o'
    sta.z print_chip_line.c
    // [919] phi print_chip_line::y#9 = $2f [phi:main::@65->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2f
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#2 [phi:main::@65->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@66
    // print_chip_line(3 + r * 10, 48, 'm')
    // [391] print_chip_line::x#3 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [392] call print_chip_line
    // [919] phi from main::@66 to print_chip_line [phi:main::@66->print_chip_line]
    // [919] phi print_chip_line::c#10 = 'm'pm [phi:main::@66->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'m'
    sta.z print_chip_line.c
    // [919] phi print_chip_line::y#9 = $30 [phi:main::@66->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$30
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#3 [phi:main::@66->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@67
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [393] print_chip_line::x#4 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [394] print_chip_line::c#4 = '0'pm + main::r#10 -- vbuz1=vbuc1_plus_vbuz2 
    lda #'0'
    clc
    adc.z r
    sta.z print_chip_line.c
    // [395] call print_chip_line
    // [919] phi from main::@67 to print_chip_line [phi:main::@67->print_chip_line]
    // [919] phi print_chip_line::c#10 = print_chip_line::c#4 [phi:main::@67->print_chip_line#0] -- register_copy 
    // [919] phi print_chip_line::y#9 = $31 [phi:main::@67->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#4 [phi:main::@67->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@68
    // print_chip_line(3 + r * 10, 50, ' ')
    // [396] print_chip_line::x#5 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [397] call print_chip_line
    // [919] phi from main::@68 to print_chip_line [phi:main::@68->print_chip_line]
    // [919] phi print_chip_line::c#10 = ' 'pm [phi:main::@68->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [919] phi print_chip_line::y#9 = $32 [phi:main::@68->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$32
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#5 [phi:main::@68->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@69
    // print_chip_line(3 + r * 10, 51, '5')
    // [398] print_chip_line::x#6 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [399] call print_chip_line
    // [919] phi from main::@69 to print_chip_line [phi:main::@69->print_chip_line]
    // [919] phi print_chip_line::c#10 = '5'pm [phi:main::@69->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'5'
    sta.z print_chip_line.c
    // [919] phi print_chip_line::y#9 = $33 [phi:main::@69->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$33
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#6 [phi:main::@69->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@70
    // print_chip_line(3 + r * 10, 52, '1')
    // [400] print_chip_line::x#7 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [401] call print_chip_line
    // [919] phi from main::@70 to print_chip_line [phi:main::@70->print_chip_line]
    // [919] phi print_chip_line::c#10 = '1'pm [phi:main::@70->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'1'
    sta.z print_chip_line.c
    // [919] phi print_chip_line::y#9 = $34 [phi:main::@70->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$34
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#7 [phi:main::@70->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@71
    // print_chip_line(3 + r * 10, 53, '2')
    // [402] print_chip_line::x#8 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __19
    sta.z print_chip_line.x
    // [403] call print_chip_line
    // [919] phi from main::@71 to print_chip_line [phi:main::@71->print_chip_line]
    // [919] phi print_chip_line::c#10 = '2'pm [phi:main::@71->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'2'
    sta.z print_chip_line.c
    // [919] phi print_chip_line::y#9 = $35 [phi:main::@71->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$35
    sta.z print_chip_line.y
    // [919] phi print_chip_line::x#9 = print_chip_line::x#8 [phi:main::@71->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@72
    // print_chip_end(3 + r * 10, 54)
    // [404] print_chip_end::x#0 = 3 + main::$19 -- vbuz1=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z print_chip_end.x
    sta.z print_chip_end.x
    // [405] call print_chip_end
    jsr print_chip_end
    // main::@73
    // print_chip_led(r, BLACK, BLUE)
    // [406] print_chip_led::r#0 = main::r#10 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_chip_led.r
    // [407] call print_chip_led
    // [746] phi from main::@73 to print_chip_led [phi:main::@73->print_chip_led]
    // [746] phi print_chip_led::tc#10 = BLACK [phi:main::@73->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [746] phi print_chip_led::r#10 = print_chip_led::r#0 [phi:main::@73->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@74
    // for (unsigned char r = 0; r < 8; r++)
    // [408] main::r#1 = ++ main::r#10 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [89] phi from main::@74 to main::@1 [phi:main::@74->main::@1]
    // [89] phi main::r#10 = main::r#1 [phi:main::@74->main::@1#0] -- register_copy 
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
    s1: .text "resetting commander x16"
    .byte 0
    s2: .text "rom.bin"
    .byte 0
    s3: .text "rom"
    .byte 0
    s4: .text ".bin"
    .byte 0
    s5: .text "reading in ram ..."
    .byte 0
    s6: .text "no file"
    .byte 0
    s7: .text "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error."
    .byte 0
    s8: .text "................"
    .byte 0
    s9: .text "ram = "
    .byte 0
    s10: .text ", "
    .byte 0
    s11: .text ", rom = "
    .byte 0
    s13: .text "the flashing went perfectly ok. press a key to flash the next chip ..."
    .byte 0
    s14: .text "the flashing went wrong, "
    .byte 0
    s15: .text " errors. press a key to flash the next chip ..."
    .byte 0
    rom_device_1: .text "f010a"
    .byte 0
    rom_device_2: .text "f020a"
    .byte 0
    rom_device_3: .text "f040"
    .byte 0
    rom_device_4: .text "----"
    .byte 0
    pattern_1: .text "----------------"
    .byte 0
    pattern_2: .text "!"
    .byte 0
    pattern_3: .text "+"
    .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [409] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [410] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [411] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [412] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($7c) char color)
textcolor: {
    .label __0 = $7d
    .label __1 = $7c
    .label color = $7c
    // __conio.color & 0xF0
    // [414] textcolor::$0 = *((char *)&__conio+$b) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$b
    sta.z __0
    // __conio.color & 0xF0 | color
    // [415] textcolor::$1 = textcolor::$0 | textcolor::color#22 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z __1
    ora.z __0
    sta.z __1
    // __conio.color = __conio.color & 0xF0 | color
    // [416] *((char *)&__conio+$b) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$b
    // textcolor::@return
    // }
    // [417] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($7c) char color)
bgcolor: {
    .label __0 = $bf
    .label __1 = $7c
    .label __2 = $bf
    .label color = $7c
    // __conio.color & 0x0F
    // [419] bgcolor::$0 = *((char *)&__conio+$b) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$b
    sta.z __0
    // color << 4
    // [420] bgcolor::$1 = bgcolor::color#11 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z __1
    asl
    asl
    asl
    asl
    sta.z __1
    // __conio.color & 0x0F | color << 4
    // [421] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z __2
    ora.z __1
    sta.z __2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [422] *((char *)&__conio+$b) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$b
    // bgcolor::@return
    // }
    // [423] return 
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
    // [424] *((char *)&__conio+$a) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$a
    // cursor::@return
    // }
    // [425] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $c9
    // __mem unsigned char x
    // [426] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [427] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [429] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [430] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($73) char x, __zp($75) char y)
gotoxy: {
    .label __2 = $73
    .label __3 = $73
    .label __6 = $70
    .label __7 = $70
    .label __8 = $78
    .label __9 = $76
    .label __10 = $75
    .label x = $73
    .label y = $75
    .label __14 = $70
    // (x>=__conio.width)?__conio.width:x
    // [432] if(gotoxy::x#22>=*((char *)&__conio+4)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+4
    bcs __b1
    // [434] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [434] phi gotoxy::$3 = gotoxy::x#22 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [433] gotoxy::$2 = *((char *)&__conio+4) -- vbuz1=_deref_pbuc1 
    lda __conio+4
    sta.z __2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [435] *((char *)&__conio+$d) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z __3
    sta __conio+$d
    // (y>=__conio.height)?__conio.height:y
    // [436] if(gotoxy::y#22>=*((char *)&__conio+5)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+5
    bcs __b3
    // gotoxy::@4
    // [437] gotoxy::$14 = gotoxy::y#22 -- vbuz1=vbuz2 
    sta.z __14
    // [438] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [438] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [439] *((char *)&__conio+$e) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z __7
    sta __conio+$e
    // __conio.cursor_x << 1
    // [440] gotoxy::$8 = *((char *)&__conio+$d) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$d
    asl
    sta.z __8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [441] gotoxy::$10 = gotoxy::y#22 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __10
    // [442] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z __10
    clc
    adc __conio+$15,y
    sta.z __9
    lda __conio+$15+1,y
    adc #0
    sta.z __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [443] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z __9
    sta __conio+$13
    lda.z __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [444] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [445] gotoxy::$6 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z __6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label __2 = $79
    // __conio.cursor_x = 0
    // [446] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y++;
    // [447] *((char *)&__conio+$e) = ++ *((char *)&__conio+$e) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$e
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [448] cputln::$2 = *((char *)&__conio+$e) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    sta.z __2
    // [449] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [450] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [451] return 
    rts
}
  // cbm_x_charset
/**
 * @brief Sets the [character set](https://github.com/commanderx16/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-screen_set_charset).
 * 
 * @param charset The code of the charset to copy.
 * @param offset The offset of the character set in ram.
 */
// void cbm_x_charset(__zp($f4) volatile char charset, __zp($ef) char * volatile offset)
cbm_x_charset: {
    .label charset = $f4
    .label offset = $ef
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_CHRSET  }
    lda charset
    ldx.z <offset
    ldy.z >offset
    jsr CX16_CHRSET
    // cbm_x_charset::@return
    // }
    // [453] return 
    rts
}
  // scroll
// If onoff is 1, scrolling is enabled when outputting past the end of the screen
// If onoff is 0, scrolling is disabled and the cursor instead moves to (0,0)
// The function returns the old scroll setting.
// char scroll(char onoff)
scroll: {
    .const onoff = 0
    // __conio.scroll[__conio.layer] = onoff
    // [454] ((char *)&__conio+$f)[*((char *)&__conio)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio
    sta __conio+$f,y
    // scroll::@return
    // }
    // [455] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label __0 = $4c
    .label __1 = $7a
    .label __2 = $a9
    .label line_text = $67
    .label l = $55
    .label ch = $67
    .label c = $53
    // unsigned int line_text = __conio.mapbase_offset
    // [456] clrscr::line_text#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z line_text
    lda __conio+1+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [457] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [458] clrscr::$0 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [459] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [460] clrscr::l#0 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z l
    // [461] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [461] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [461] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [462] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z __1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [463] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [464] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z __2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [465] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [466] clrscr::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [467] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [467] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [468] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [469] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [470] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [471] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [472] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+8
    sta.z line_text
    lda.z line_text+1
    adc __conio+8+1
    sta.z line_text+1
    // l--;
    // [473] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [474] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [475] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y = 0
    // [476] *((char *)&__conio+$e) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+$e
    // __conio.offset = __conio.mapbase_offset
    // [477] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+1) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+1
    sta __conio+$13
    lda __conio+1+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [478] return 
    rts
}
  // frame_draw
frame_draw: {
    .label x = $55
    .label x1 = $53
    .label y = $49
    .label x2 = $23
    .label y_1 = $58
    .label x3 = $2a
    .label y_2 = $7b
    .label x4 = $2d
    .label y_3 = $22
    .label x5 = $b2
    // textcolor(WHITE)
    // [480] call textcolor
    // [413] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [481] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [482] call bgcolor
    // [418] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [483] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [484] call clrscr
    jsr clrscr
    // [485] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [485] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [486] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [487] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [488] call cputcxy
    // [1023] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [1023] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbuz1=vbuc1 
    sta.z cputcxy.x
    jsr cputcxy
    // [489] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [490] call cputcxy
    // [1023] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [1023] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [491] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [492] call cputcxy
    // [1023] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbuz1=vbuc1 
    lda #1
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // [493] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [494] call cputcxy
    // [1023] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbuz1=vbuc1 
    lda #1
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [495] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [495] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [496] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [497] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [498] call cputcxy
    // [1023] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [1023] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // [499] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [500] call cputcxy
    // [1023] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [1023] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [501] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [502] call cputcxy
    // [1023] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [1023] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // [503] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [503] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbuz1=vbuc1 
    lda #3
    sta.z y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [504] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [505] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [505] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [506] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [507] cputcxy::y#13 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [508] call cputcxy
    // [1023] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [1023] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [509] cputcxy::y#14 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [510] call cputcxy
    // [1023] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [1023] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [511] cputcxy::y#15 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [512] call cputcxy
    // [1023] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [1023] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [513] frame_draw::y#5 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [514] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [514] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [515] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [516] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [516] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [517] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [518] cputcxy::y#19 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [519] call cputcxy
    // [1023] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [1023] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [520] cputcxy::y#20 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [521] call cputcxy
    // [1023] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [1023] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [522] cputcxy::y#21 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [523] call cputcxy
    // [1023] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [1023] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [524] cputcxy::y#22 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [525] call cputcxy
    // [1023] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [1023] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [526] cputcxy::y#23 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [527] call cputcxy
    // [1023] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [1023] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [528] cputcxy::y#24 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [529] call cputcxy
    // [1023] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [1023] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [530] cputcxy::y#25 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [531] call cputcxy
    // [1023] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [1023] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [532] cputcxy::y#26 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [533] call cputcxy
    // [1023] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [1023] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [534] cputcxy::y#27 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [535] call cputcxy
    // [1023] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [1023] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [536] cputcxy::y#28 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [537] call cputcxy
    // [1023] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [1023] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [538] frame_draw::y#7 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz2 
    lda.z y_1
    inc
    sta.z y_2
    // [539] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [539] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [540] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [541] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [541] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [542] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [543] cputcxy::y#39 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [544] call cputcxy
    // [1023] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [1023] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [545] cputcxy::y#40 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [546] call cputcxy
    // [1023] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [1023] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [547] cputcxy::y#41 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [548] call cputcxy
    // [1023] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [1023] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [549] cputcxy::y#42 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [550] call cputcxy
    // [1023] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [1023] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [551] cputcxy::y#43 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [552] call cputcxy
    // [1023] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [1023] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [553] cputcxy::y#44 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [554] call cputcxy
    // [1023] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [1023] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [555] cputcxy::y#45 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [556] call cputcxy
    // [1023] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [1023] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [557] cputcxy::y#46 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [558] call cputcxy
    // [1023] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [1023] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [559] cputcxy::y#47 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [560] call cputcxy
    // [1023] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [1023] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [561] frame_draw::y#9 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz2 
    lda.z y_2
    inc
    sta.z y_3
    // [562] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [562] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [563] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [564] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [564] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [565] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x5
    cmp #$4f
    bcs !__b25+
    jmp __b25
  !__b25:
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [566] cputcxy::y#58 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [567] call cputcxy
    // [1023] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [1023] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [568] cputcxy::y#59 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [569] call cputcxy
    // [1023] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [1023] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [570] cputcxy::y#60 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [571] call cputcxy
    // [1023] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [1023] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [572] cputcxy::y#61 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [573] call cputcxy
    // [1023] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [1023] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [574] cputcxy::y#62 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [575] call cputcxy
    // [1023] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [1023] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [576] cputcxy::y#63 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [577] call cputcxy
    // [1023] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [1023] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [578] cputcxy::y#64 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [579] call cputcxy
    // [1023] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [1023] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [580] cputcxy::y#65 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [581] call cputcxy
    // [1023] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [1023] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [582] cputcxy::y#66 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [583] call cputcxy
    // [1023] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [1023] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [584] cputcxy::y#67 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [585] call cputcxy
    // [1023] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [1023] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@return
    // }
    // [586] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [587] cputcxy::x#57 = frame_draw::x5#2 -- vbuz1=vbuz2 
    lda.z x5
    sta.z cputcxy.x
    // [588] cputcxy::y#57 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [589] call cputcxy
    // [1023] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [1023] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [590] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbuz1=_inc_vbuz1 
    inc.z x5
    // [564] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [564] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [591] cputcxy::y#48 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [592] call cputcxy
    // [1023] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [593] cputcxy::y#49 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [594] call cputcxy
    // [1023] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [595] cputcxy::y#50 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [596] call cputcxy
    // [1023] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [597] cputcxy::y#51 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [598] call cputcxy
    // [1023] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [599] cputcxy::y#52 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [600] call cputcxy
    // [1023] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [601] cputcxy::y#53 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [602] call cputcxy
    // [1023] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [603] cputcxy::y#54 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [604] call cputcxy
    // [1023] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [605] cputcxy::y#55 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [606] call cputcxy
    // [1023] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [607] cputcxy::y#56 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [608] call cputcxy
    // [1023] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [609] frame_draw::y#10 = ++ frame_draw::y#106 -- vbuz1=_inc_vbuz1 
    inc.z y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [610] cputcxy::x#38 = frame_draw::x4#2 -- vbuz1=vbuz2 
    lda.z x4
    sta.z cputcxy.x
    // [611] cputcxy::y#38 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [612] call cputcxy
    // [1023] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [1023] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [613] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbuz1=_inc_vbuz1 
    inc.z x4
    // [541] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [541] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [614] cputcxy::y#29 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [615] call cputcxy
    // [1023] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [616] cputcxy::y#30 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [617] call cputcxy
    // [1023] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [618] cputcxy::y#31 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [619] call cputcxy
    // [1023] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [620] cputcxy::y#32 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [621] call cputcxy
    // [1023] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [622] cputcxy::y#33 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [623] call cputcxy
    // [1023] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [624] cputcxy::y#34 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [625] call cputcxy
    // [1023] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [626] cputcxy::y#35 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [627] call cputcxy
    // [1023] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [628] cputcxy::y#36 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [629] call cputcxy
    // [1023] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [630] cputcxy::y#37 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [631] call cputcxy
    // [1023] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [632] frame_draw::y#8 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz1 
    inc.z y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [633] cputcxy::x#18 = frame_draw::x3#2 -- vbuz1=vbuz2 
    lda.z x3
    sta.z cputcxy.x
    // [634] cputcxy::y#18 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [635] call cputcxy
    // [1023] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [1023] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [636] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbuz1=_inc_vbuz1 
    inc.z x3
    // [516] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [516] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [637] cputcxy::y#16 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [638] call cputcxy
    // [1023] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [639] cputcxy::y#17 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [640] call cputcxy
    // [1023] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [641] frame_draw::y#6 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [642] cputcxy::x#12 = frame_draw::x2#2 -- vbuz1=vbuz2 
    lda.z x2
    sta.z cputcxy.x
    // [643] cputcxy::y#12 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [644] call cputcxy
    // [1023] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [1023] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [645] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbuz1=_inc_vbuz1 
    inc.z x2
    // [505] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [505] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [646] cputcxy::y#9 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [647] call cputcxy
    // [1023] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [648] cputcxy::y#10 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [649] call cputcxy
    // [1023] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [650] cputcxy::y#11 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [651] call cputcxy
    // [1023] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [1023] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [1023] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [652] frame_draw::y#4 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [503] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [503] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [653] cputcxy::x#5 = frame_draw::x1#2 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [654] call cputcxy
    // [1023] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [1023] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [655] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbuz1=_inc_vbuz1 
    inc.z x1
    // [495] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [495] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [656] cputcxy::x#0 = frame_draw::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [657] call cputcxy
    // [1023] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [1023] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1023] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1023] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [658] frame_draw::x#1 = ++ frame_draw::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [485] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [485] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
    jmp __b1
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($67) void (*putc)(char), __zp($3b) const char *s)
printf_str: {
    .label c = $4c
    .label s = $3b
    .label putc = $67
    // [660] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [660] phi printf_str::s#19 = printf_str::s#20 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [661] printf_str::c#1 = *printf_str::s#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [662] printf_str::s#0 = ++ printf_str::s#19 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [663] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [664] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [665] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [666] callexecute *printf_str::putc#20  -- call__deref_pprz1 
    jsr icall9
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall9:
    jmp (putc)
}
  // wait_key
// Some addressing constants.
// The different device IDs that can be returned from the manufacturer ID read sequence.
// To print the graphics on the vera.
wait_key: {
    .const bank_set_bram1_bank = 0
    .label return = $7a
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [669] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [670] phi from wait_key::bank_set_bram1 to wait_key::@2 [phi:wait_key::bank_set_bram1->wait_key::@2]
    // wait_key::@2
    // bank_set_brom(4)
    // [671] call bank_set_brom
    // [695] phi from wait_key::@2 to bank_set_brom [phi:wait_key::@2->bank_set_brom]
    // [695] phi bank_set_brom::bank#8 = 4 [phi:wait_key::@2->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [672] phi from wait_key::@2 wait_key::@3 to wait_key::@1 [phi:wait_key::@2/wait_key::@3->wait_key::@1]
    // wait_key::@1
  __b1:
    // getin()
    // [673] call getin
    jsr getin
    // [674] getin::return#2 = getin::return#1
    // wait_key::@3
    // [675] wait_key::return#0 = getin::return#2
    // while (!(ch = getin()))
    // [676] if(0==wait_key::return#0) goto wait_key::@1 -- 0_eq_vbuz1_then_la1 
    lda.z return
    beq __b1
    // wait_key::@return
    // }
    // [677] return 
    rts
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [678] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [679] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [680] __snprintf_buffer = main::buffer -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z __snprintf_buffer
    lda #>main.buffer
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [681] return 
    rts
}
  // print_text
// void print_text(char *text)
print_text: {
    // textcolor(WHITE)
    // [683] call textcolor
    // [413] phi from print_text to textcolor [phi:print_text->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:print_text->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [684] phi from print_text to print_text::@1 [phi:print_text->print_text::@1]
    // print_text::@1
    // gotoxy(2, 39)
    // [685] call gotoxy
    // [431] phi from print_text::@1 to gotoxy [phi:print_text::@1->gotoxy]
    // [431] phi gotoxy::y#22 = $27 [phi:print_text::@1->gotoxy#0] -- vbuz1=vbuc1 
    lda #$27
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = 2 [phi:print_text::@1->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [686] phi from print_text::@1 to print_text::@2 [phi:print_text::@1->print_text::@2]
    // print_text::@2
    // printf("%-76s", text)
    // [687] call printf_string
    // [791] phi from print_text::@2 to printf_string [phi:print_text::@2->printf_string]
    // [791] phi printf_string::str#10 = main::buffer [phi:print_text::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z printf_string.str
    lda #>main.buffer
    sta.z printf_string.str+1
    // [791] phi printf_string::format_justify_left#10 = 1 [phi:print_text::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [791] phi printf_string::format_min_length#6 = $4c [phi:print_text::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #$4c
    sta.z printf_string.format_min_length
    jsr printf_string
    // print_text::@return
    // }
    // [688] return 
    rts
}
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [690] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [691] phi from system_reset::bank_set_bram1 to system_reset::@1 [phi:system_reset::bank_set_bram1->system_reset::@1]
    // system_reset::@1
    // bank_set_brom(0)
    // [692] call bank_set_brom
    // [695] phi from system_reset::@1 to bank_set_brom [phi:system_reset::@1->bank_set_brom]
    // [695] phi bank_set_brom::bank#8 = 0 [phi:system_reset::@1->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #0
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [694] return 
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
// void bank_set_brom(__zp($49) char bank)
bank_set_brom: {
    .label bank = $49
    // BROM = bank
    // [696] BROM = bank_set_brom::bank#8 -- vbuz1=vbuz2 
    lda.z bank
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [697] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($67) void (*putc)(char), __zp($23) char uvalue, __zp($2a) char format_min_length, char format_justify_left, char format_sign_always, __zp($7b) char format_zero_padding, char format_upper_case, __zp($58) char format_radix)
printf_uchar: {
    .label uvalue = $23
    .label format_radix = $58
    .label putc = $67
    .label format_min_length = $2a
    .label format_zero_padding = $7b
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [699] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [700] uctoa::value#1 = printf_uchar::uvalue#4
    // [701] uctoa::radix#0 = printf_uchar::format_radix#4
    // [702] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [703] printf_number_buffer::putc#2 = printf_uchar::putc#4
    // [704] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [705] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#4
    // [706] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#4
    // [707] call printf_number_buffer
  // Print using format
    // [1064] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1064] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1064] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1064] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1064] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [708] return 
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
// __zp($24) struct $1 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label __4 = $b2
    .label __7 = $54
    .label __11 = $a9
    .label fp = $24
    .label return = $24
    .label __32 = $a9
    .label __33 = $a9
    // FILE *fp = &__files[__filecount]
    // [709] fopen::$32 = __filecount << 2 -- vbuz1=vbum2_rol_2 
    lda __filecount
    asl
    asl
    sta.z __32
    // [710] fopen::$33 = fopen::$32 + __filecount -- vbuz1=vbuz1_plus_vbum2 
    lda __filecount
    clc
    adc.z __33
    sta.z __33
    // [711] fopen::$11 = fopen::$33 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z __11
    asl
    asl
    sta.z __11
    // [712] fopen::fp#0 = __files + fopen::$11 -- pssz1=pssc1_plus_vbuz2 
    clc
    adc #<__files
    sta.z fp
    lda #>__files
    adc #0
    sta.z fp+1
    // fp->status = 0
    // [713] ((char *)fopen::fp#0)[$13] = 0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #0
    ldy #$13
    sta (fp),y
    // fp->channel = channel
    // [714] ((char *)fopen::fp#0)[$10] = fopen::channel#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #channel
    ldy #$10
    sta (fp),y
    // fp->device = device
    // [715] ((char *)fopen::fp#0)[$11] = fopen::device#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #device
    ldy #$11
    sta (fp),y
    // fp->secondary = secondary
    // [716] ((char *)fopen::fp#0)[$12] = fopen::secondary#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #secondary
    ldy #$12
    sta (fp),y
    // strncpy(fp->filename, filename, 16)
    // [717] strncpy::dst#1 = (char *)fopen::fp#0 -- pbuz1=pbuz2 
    lda.z fp
    sta.z strncpy.dst
    lda.z fp+1
    sta.z strncpy.dst+1
    // [718] call strncpy
    // [1095] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@5
    // cbm_k_setnam(filename)
    // [719] cbm_k_setnam::filename = main::buffer -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z cbm_k_setnam.filename
    lda #>main.buffer
    sta.z cbm_k_setnam.filename+1
    // [720] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@6
    // cbm_k_setlfs(channel, device, secondary)
    // [721] cbm_k_setlfs::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_setlfs.channel
    // [722] cbm_k_setlfs::device = fopen::device#0 -- vbuz1=vbuc1 
    lda #device
    sta.z cbm_k_setlfs.device
    // [723] cbm_k_setlfs::command = fopen::secondary#0 -- vbuz1=vbuc1 
    lda #secondary
    sta.z cbm_k_setlfs.command
    // [724] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [725] phi from fopen::@6 to fopen::@7 [phi:fopen::@6->fopen::@7]
    // fopen::@7
    // cbm_k_open()
    // [726] call cbm_k_open
    jsr cbm_k_open
    // [727] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@8
    // [728] fopen::$4 = cbm_k_open::return#2
    // fp->status = cbm_k_open()
    // [729] ((char *)fopen::fp#0)[$13] = fopen::$4 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __4
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [730] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // fopen::@3
    // cbm_k_close(channel)
    // [731] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [732] call cbm_k_close
    jsr cbm_k_close
    // [733] phi from fopen::@3 fopen::@4 to fopen::@return [phi:fopen::@3/fopen::@4->fopen::@return]
  __b3:
    // [733] phi fopen::return#1 = 0 [phi:fopen::@3/fopen::@4->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [734] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [735] cbm_k_chkin::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_chkin.channel
    // [736] call cbm_k_chkin
    jsr cbm_k_chkin
    // [737] phi from fopen::@1 to fopen::@9 [phi:fopen::@1->fopen::@9]
    // fopen::@9
    // cbm_k_readst()
    // [738] call cbm_k_readst
    jsr cbm_k_readst
    // [739] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@10
    // [740] fopen::$7 = cbm_k_readst::return#2
    // fp->status = cbm_k_readst()
    // [741] ((char *)fopen::fp#0)[$13] = fopen::$7 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __7
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [742] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@2 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b2
    // fopen::@4
    // cbm_k_close(channel)
    // [743] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [744] call cbm_k_close
    jsr cbm_k_close
    jmp __b3
    // fopen::@2
  __b2:
    // __filecount++;
    // [745] __filecount = ++ __filecount -- vbum1=_inc_vbum1 
    inc __filecount
    // [733] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [733] phi fopen::return#1 = fopen::fp#0 [phi:fopen::@2->fopen::@return#0] -- register_copy 
    rts
}
  // print_chip_led
// void print_chip_led(__zp($2d) char r, __zp($54) char tc, char bc)
print_chip_led: {
    .label __0 = $2d
    .label r = $2d
    .label tc = $54
    .label __8 = $b2
    .label __9 = $2d
    // r * 10
    // [747] print_chip_led::$8 = print_chip_led::r#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z r
    asl
    asl
    sta.z __8
    // [748] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#10 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z __9
    clc
    adc.z __8
    sta.z __9
    // [749] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __0
    // gotoxy(4 + r * 10, 43)
    // [750] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbuz1=vbuc1_plus_vbuz2 
    lda #4
    clc
    adc.z __0
    sta.z gotoxy.x
    // [751] call gotoxy
    // [431] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [431] phi gotoxy::y#22 = $2b [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #$2b
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [752] textcolor::color#7 = print_chip_led::tc#10 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [753] call textcolor
    // [413] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [413] phi textcolor::color#22 = textcolor::color#7 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [754] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [755] call bgcolor
    // [418] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [756] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [757] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [759] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [760] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [762] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [763] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [765] return 
    rts
}
  // table_chip_clear
// void table_chip_clear(__zp($a9) char rom_bank)
table_chip_clear: {
    .label flash_rom_address = $26
    .label rom_bank = $a9
    .label y = $7a
    // textcolor(WHITE)
    // [767] call textcolor
    // [413] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:table_chip_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [768] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [769] call bgcolor
    // [418] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [770] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [770] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [770] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [771] if(table_chip_clear::y#10<$24) goto table_chip_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$24
    bcc __b2
    // table_chip_clear::@return
    // }
    // [772] return 
    rts
    // table_chip_clear::@2
  __b2:
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [773] rom_address::rom_bank#1 = table_chip_clear::rom_bank#11 -- vbuz1=vbuz2 
    lda.z rom_bank
    sta.z rom_address.rom_bank
    // [774] call rom_address
    // [813] phi from table_chip_clear::@2 to rom_address [phi:table_chip_clear::@2->rom_address]
    // [813] phi rom_address::rom_bank#4 = rom_address::rom_bank#1 [phi:table_chip_clear::@2->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [775] rom_address::return#3 = rom_address::return#0
    // table_chip_clear::@4
    // [776] table_chip_clear::flash_rom_address#0 = rom_address::return#3 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z flash_rom_address
    lda.z rom_address.return+1
    sta.z flash_rom_address+1
    lda.z rom_address.return+2
    sta.z flash_rom_address+2
    lda.z rom_address.return+3
    sta.z flash_rom_address+3
    // gotoxy(2, y)
    // [777] gotoxy::y#8 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [778] call gotoxy
    // [431] phi from table_chip_clear::@4 to gotoxy [phi:table_chip_clear::@4->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#8 [phi:table_chip_clear::@4->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = 2 [phi:table_chip_clear::@4->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // table_chip_clear::@5
    // printf("%02x", rom_bank)
    // [779] printf_uchar::uvalue#0 = table_chip_clear::rom_bank#11 -- vbuz1=vbuz2 
    lda.z rom_bank
    sta.z printf_uchar.uvalue
    // [780] call printf_uchar
    // [698] phi from table_chip_clear::@5 to printf_uchar [phi:table_chip_clear::@5->printf_uchar]
    // [698] phi printf_uchar::format_zero_padding#4 = 1 [phi:table_chip_clear::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [698] phi printf_uchar::format_min_length#4 = 2 [phi:table_chip_clear::@5->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [698] phi printf_uchar::putc#4 = &cputc [phi:table_chip_clear::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [698] phi printf_uchar::format_radix#4 = HEXADECIMAL [phi:table_chip_clear::@5->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [698] phi printf_uchar::uvalue#4 = printf_uchar::uvalue#0 [phi:table_chip_clear::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@6
    // gotoxy(5, y)
    // [781] gotoxy::y#9 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [782] call gotoxy
    // [431] phi from table_chip_clear::@6 to gotoxy [phi:table_chip_clear::@6->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#9 [phi:table_chip_clear::@6->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = 5 [phi:table_chip_clear::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #5
    sta.z gotoxy.x
    jsr gotoxy
    // table_chip_clear::@7
    // printf("%06x", flash_rom_address)
    // [783] printf_ulong::uvalue#0 = table_chip_clear::flash_rom_address#0
    // [784] call printf_ulong
    // [896] phi from table_chip_clear::@7 to printf_ulong [phi:table_chip_clear::@7->printf_ulong]
    // [896] phi printf_ulong::format_zero_padding#2 = 1 [phi:table_chip_clear::@7->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [896] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:table_chip_clear::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // table_chip_clear::@8
    // gotoxy(14, y)
    // [785] gotoxy::y#10 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [786] call gotoxy
    // [431] phi from table_chip_clear::@8 to gotoxy [phi:table_chip_clear::@8->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#10 [phi:table_chip_clear::@8->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = $e [phi:table_chip_clear::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // [787] phi from table_chip_clear::@8 to table_chip_clear::@9 [phi:table_chip_clear::@8->table_chip_clear::@9]
    // table_chip_clear::@9
    // printf("%64s", " ")
    // [788] call printf_string
    // [791] phi from table_chip_clear::@9 to printf_string [phi:table_chip_clear::@9->printf_string]
    // [791] phi printf_string::str#10 = str [phi:table_chip_clear::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [791] phi printf_string::format_justify_left#10 = 0 [phi:table_chip_clear::@9->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [791] phi printf_string::format_min_length#6 = $40 [phi:table_chip_clear::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #$40
    sta.z printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@10
    // rom_bank++;
    // [789] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [790] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [770] phi from table_chip_clear::@10 to table_chip_clear::@1 [phi:table_chip_clear::@10->table_chip_clear::@1]
    // [770] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@10->table_chip_clear::@1#0] -- register_copy 
    // [770] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@10->table_chip_clear::@1#1] -- register_copy 
    jmp __b1
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($3b) char *str, __zp($22) char format_min_length, __zp($b2) char format_justify_left)
printf_string: {
    .label __9 = $4a
    .label len = $54
    .label padding = $22
    .label str = $3b
    .label format_min_length = $22
    .label format_justify_left = $b2
    // if(format.min_length)
    // [792] if(0==printf_string::format_min_length#6) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [793] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [794] call strlen
    // [1133] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1133] phi strlen::str#6 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [795] strlen::return#4 = strlen::len#2
    // printf_string::@6
    // [796] printf_string::$9 = strlen::return#4
    // signed char len = (signed char)strlen(str)
    // [797] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z __9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [798] printf_string::padding#1 = (signed char)printf_string::format_min_length#6 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [799] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [801] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [801] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [800] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [801] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [801] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [802] if(0!=printf_string::format_justify_left#10) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [803] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [804] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [805] call printf_padding
    // [1139] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1139] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1139] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1139] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [806] printf_str::s#2 = printf_string::str#10
    // [807] call printf_str
    // [659] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [659] phi printf_str::putc#20 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [659] phi printf_str::s#20 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [808] if(0==printf_string::format_justify_left#10) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [809] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [810] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [811] call printf_padding
    // [1139] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1139] phi printf_padding::putc#7 = &cputc [phi:printf_string::@5->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1139] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1139] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [812] return 
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
// __zp($ab) unsigned long rom_address(__zp($54) char rom_bank)
rom_address: {
    .label __1 = $ab
    .label return = $ab
    .label rom_bank = $54
    .label return_1 = $6c
    .label return_2 = $34
    // ((unsigned long)(rom_bank)) << 14
    // [814] rom_address::$1 = (unsigned long)rom_address::rom_bank#4 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z __1
    lda #0
    sta.z __1+1
    sta.z __1+2
    sta.z __1+3
    // [815] rom_address::return#0 = rom_address::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [816] return 
    rts
}
  // flash_read
// __zp($b3) unsigned long flash_read(__zp($67) struct $1 *fp, __zp($3d) char *flash_ram_address, __zp($4f) char rom_bank_start, __zp($55) char rom_bank_size)
flash_read: {
    .label __4 = $5f
    .label __7 = $2d
    .label __13 = $2e
    .label flash_rom_address = $6c
    .label flash_size = $5b
    .label read_bytes = $6a
    .label rom_bank_start = $4f
    .label return = $b3
    .label flash_ram_address = $3d
    .label flash_bytes = $b3
    .label fp = $67
    .label rom_bank_size = $55
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [818] rom_address::rom_bank#0 = flash_read::rom_bank_start#11 -- vbuz1=vbuz2 
    lda.z rom_bank_start
    sta.z rom_address.rom_bank
    // [819] call rom_address
    // [813] phi from flash_read to rom_address [phi:flash_read->rom_address]
    // [813] phi rom_address::rom_bank#4 = rom_address::rom_bank#0 [phi:flash_read->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [820] rom_address::return#2 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_1
    lda.z rom_address.return+1
    sta.z rom_address.return_1+1
    lda.z rom_address.return+2
    sta.z rom_address.return_1+2
    lda.z rom_address.return+3
    sta.z rom_address.return_1+3
    // flash_read::@9
    // [821] flash_read::flash_rom_address#0 = rom_address::return#2
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [822] rom_size::rom_banks#0 = flash_read::rom_bank_size#2
    // [823] call rom_size
    // [853] phi from flash_read::@9 to rom_size [phi:flash_read::@9->rom_size]
    // [853] phi rom_size::rom_banks#2 = rom_size::rom_banks#0 [phi:flash_read::@9->rom_size#0] -- register_copy 
    jsr rom_size
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [824] rom_size::return#2 = rom_size::return#0
    // flash_read::@10
    // [825] flash_read::flash_size#0 = rom_size::return#2
    // textcolor(WHITE)
    // [826] call textcolor
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [413] phi from flash_read::@10 to textcolor [phi:flash_read::@10->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:flash_read::@10->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [827] phi from flash_read::@10 to flash_read::@1 [phi:flash_read::@10->flash_read::@1]
    // [827] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@10->flash_read::@1#0] -- register_copy 
    // [827] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@10->flash_read::@1#1] -- register_copy 
    // [827] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#0 [phi:flash_read::@10->flash_read::@1#2] -- register_copy 
    // [827] phi flash_read::return#2 = 0 [phi:flash_read::@10->flash_read::@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // [827] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [827] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [827] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [827] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [827] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < flash_size)
    // [828] if(flash_read::return#2<flash_read::flash_size#0) goto flash_read::@2 -- vduz1_lt_vduz2_then_la1 
    lda.z return+3
    cmp.z flash_size+3
    bcc __b2
    bne !+
    lda.z return+2
    cmp.z flash_size+2
    bcc __b2
    bne !+
    lda.z return+1
    cmp.z flash_size+1
    bcc __b2
    bne !+
    lda.z return
    cmp.z flash_size
    bcc __b2
  !:
    // flash_read::@return
    // }
    // [829] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [830] flash_read::$4 = flash_read::flash_rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [831] if(0!=flash_read::$4) goto flash_read::@3 -- 0_neq_vduz1_then_la1 
    lda.z __4
    ora.z __4+1
    ora.z __4+2
    ora.z __4+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [832] flash_read::$7 = flash_read::rom_bank_start#4 & $20-1 -- vbuz1=vbuz2_band_vbuc1 
    lda #$20-1
    and.z rom_bank_start
    sta.z __7
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [833] gotoxy::y#7 = 4 + flash_read::$7 -- vbuz1=vbuc1_plus_vbuz2 
    lda #4
    clc
    adc.z __7
    sta.z gotoxy.y
    // [834] call gotoxy
    // [431] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#7 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = $e [phi:flash_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // flash_read::@12
    // rom_bank_start++;
    // [835] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank_start
    // [836] phi from flash_read::@12 flash_read::@2 to flash_read::@3 [phi:flash_read::@12/flash_read::@2->flash_read::@3]
    // [836] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@12/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [837] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [838] fgets::fp#0 = flash_read::fp#10 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [839] call fgets
    jsr fgets
    // [840] fgets::return#5 = fgets::return#1
    // flash_read::@11
    // [841] flash_read::read_bytes#0 = fgets::return#5
    // if (!read_bytes)
    // [842] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwuz1_then_la1 
    lda.z read_bytes
    ora.z read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [843] flash_read::$13 = flash_read::flash_rom_address#10 & $100-1 -- vduz1=vduz2_band_vduc1 
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
    // [844] if(0!=flash_read::$13) goto flash_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z __13
    ora.z __13+1
    ora.z __13+2
    ora.z __13+3
    bne __b5
    // flash_read::@7
    // cputc('.')
    // [845] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    // cputc(0xE0);
    lda #'.'
    pha
    // [846] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [848] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [849] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [850] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [851] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // [852] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
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
// __zp($5b) unsigned long rom_size(__zp($55) char rom_banks)
rom_size: {
    .label __1 = $5b
    .label return = $5b
    .label rom_banks = $55
    // ((unsigned long)(rom_banks)) << 14
    // [854] rom_size::$1 = (unsigned long)rom_size::rom_banks#2 -- vduz1=_dword_vbuz2 
    lda.z rom_banks
    sta.z __1
    lda #0
    sta.z __1+1
    sta.z __1+2
    sta.z __1+3
    // [855] rom_size::return#0 = rom_size::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // rom_size::@return
    // }
    // [856] return 
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
// int fclose(__zp($ec) struct $1 *fp)
fclose: {
    .label __0 = $2d
    .label fp = $ec
    // cbm_k_close(fp->channel)
    // [857] cbm_k_close::channel = ((char *)fclose::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_close.channel
    // [858] call cbm_k_close
    jsr cbm_k_close
    // [859] cbm_k_close::return#4 = cbm_k_close::return#1
    // fclose::@2
    // [860] fclose::$0 = cbm_k_close::return#4
    // fp->status = cbm_k_close(fp->channel)
    // [861] ((char *)fclose::fp#0)[$13] = fclose::$0 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __0
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [862] if(0==((char *)fclose::fp#0)[$13]) goto fclose::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [863] return 
    rts
    // [864] phi from fclose::@2 to fclose::@1 [phi:fclose::@2->fclose::@1]
    // fclose::@1
  __b1:
    // cbm_k_clrchn()
    // [865] call cbm_k_clrchn
    jsr cbm_k_clrchn
    // fclose::@3
    // __filecount--;
    // [866] __filecount = -- __filecount -- vbum1=_dec_vbum1 
    dec __filecount
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($67) void (*putc)(char), __zp($24) unsigned int uvalue, __zp($2a) char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, __zp($7a) char format_radix)
printf_uint: {
    .label uvalue = $24
    .label format_radix = $7a
    .label putc = $67
    .label format_min_length = $2a
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [868] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [869] utoa::value#1 = printf_uint::uvalue#2
    // [870] utoa::radix#0 = printf_uint::format_radix#2
    // [871] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [872] printf_number_buffer::putc#1 = printf_uint::putc#2
    // [873] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [874] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#2
    // [875] call printf_number_buffer
  // Print using format
    // [1064] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1064] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1064] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1064] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uint::@2->printf_number_buffer#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_zero_padding
    // [1064] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [876] return 
    rts
}
  // flash_verify
// __zp($63) unsigned long flash_verify(__zp($a9) char verify_ram_bank, __zp($67) char *verify_ram_address, __zp($5b) unsigned long verify_rom_address, __zp($6c) unsigned long verify_rom_size)
flash_verify: {
    .label __2 = $23
    .label bank_set_bram1_bank = $a9
    .label verify_rom_address = $5b
    .label verify_ram_address = $67
    .label verified_bytes = $26
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label correct_bytes = $63
    .label verify_ram_bank = $a9
    .label return = $63
    .label verify_rom_size = $6c
    // flash_verify::bank_set_bram1
    // BRAM = bank
    // [878] BRAM = flash_verify::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // [879] phi from flash_verify::bank_set_bram1 to flash_verify::@1 [phi:flash_verify::bank_set_bram1->flash_verify::@1]
    // [879] phi flash_verify::correct_bytes#2 = 0 [phi:flash_verify::bank_set_bram1->flash_verify::@1#0] -- vduz1=vduc1 
    lda #<0
    sta.z correct_bytes
    sta.z correct_bytes+1
    lda #<0>>$10
    sta.z correct_bytes+2
    lda #>0>>$10
    sta.z correct_bytes+3
    // [879] phi flash_verify::verify_ram_address#3 = flash_verify::verify_ram_address#8 [phi:flash_verify::bank_set_bram1->flash_verify::@1#1] -- register_copy 
    // [879] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#8 [phi:flash_verify::bank_set_bram1->flash_verify::@1#2] -- register_copy 
    // [879] phi flash_verify::verified_bytes#2 = 0 [phi:flash_verify::bank_set_bram1->flash_verify::@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z verified_bytes
    sta.z verified_bytes+1
    lda #<0>>$10
    sta.z verified_bytes+2
    lda #>0>>$10
    sta.z verified_bytes+3
    // flash_verify::@1
  __b1:
    // while (verified_bytes < verify_rom_size)
    // [880] if(flash_verify::verified_bytes#2<flash_verify::verify_rom_size#4) goto flash_verify::@2 -- vduz1_lt_vduz2_then_la1 
    lda.z verified_bytes+3
    cmp.z verify_rom_size+3
    bcc __b2
    bne !+
    lda.z verified_bytes+2
    cmp.z verify_rom_size+2
    bcc __b2
    bne !+
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
    // [881] return 
    rts
    // flash_verify::@2
  __b2:
    // rom_byte_verify(verify_rom_address, *verify_ram_address)
    // [882] rom_byte_verify::address#0 = flash_verify::verify_rom_address#3 -- vduz1=vduz2 
    lda.z verify_rom_address
    sta.z rom_byte_verify.address
    lda.z verify_rom_address+1
    sta.z rom_byte_verify.address+1
    lda.z verify_rom_address+2
    sta.z rom_byte_verify.address+2
    lda.z verify_rom_address+3
    sta.z rom_byte_verify.address+3
    // [883] rom_byte_verify::value#0 = *flash_verify::verify_ram_address#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (verify_ram_address),y
    sta.z rom_byte_verify.value
    // [884] call rom_byte_verify
    jsr rom_byte_verify
    // [885] rom_byte_verify::return#2 = rom_byte_verify::return#0
    // flash_verify::@5
    // [886] flash_verify::$2 = rom_byte_verify::return#2
    // if (rom_byte_verify(verify_rom_address, *verify_ram_address))
    // [887] if(0==flash_verify::$2) goto flash_verify::@3 -- 0_eq_vbuz1_then_la1 
    lda.z __2
    beq __b3
    // flash_verify::@4
    // correct_bytes++;
    // [888] flash_verify::correct_bytes#1 = ++ flash_verify::correct_bytes#2 -- vduz1=_inc_vduz1 
    inc.z correct_bytes
    bne !+
    inc.z correct_bytes+1
    bne !+
    inc.z correct_bytes+2
    bne !+
    inc.z correct_bytes+3
  !:
    // [889] phi from flash_verify::@4 flash_verify::@5 to flash_verify::@3 [phi:flash_verify::@4/flash_verify::@5->flash_verify::@3]
    // [889] phi flash_verify::correct_bytes#6 = flash_verify::correct_bytes#1 [phi:flash_verify::@4/flash_verify::@5->flash_verify::@3#0] -- register_copy 
    // flash_verify::@3
  __b3:
    // verify_rom_address++;
    // [890] flash_verify::verify_rom_address#0 = ++ flash_verify::verify_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z verify_rom_address
    bne !+
    inc.z verify_rom_address+1
    bne !+
    inc.z verify_rom_address+2
    bne !+
    inc.z verify_rom_address+3
  !:
    // verify_ram_address++;
    // [891] flash_verify::verify_ram_address#0 = ++ flash_verify::verify_ram_address#3 -- pbuz1=_inc_pbuz1 
    inc.z verify_ram_address
    bne !+
    inc.z verify_ram_address+1
  !:
    // verified_bytes++;
    // [892] flash_verify::verified_bytes#1 = ++ flash_verify::verified_bytes#2 -- vduz1=_inc_vduz1 
    inc.z verified_bytes
    bne !+
    inc.z verified_bytes+1
    bne !+
    inc.z verified_bytes+2
    bne !+
    inc.z verified_bytes+3
  !:
    // [879] phi from flash_verify::@3 to flash_verify::@1 [phi:flash_verify::@3->flash_verify::@1]
    // [879] phi flash_verify::correct_bytes#2 = flash_verify::correct_bytes#6 [phi:flash_verify::@3->flash_verify::@1#0] -- register_copy 
    // [879] phi flash_verify::verify_ram_address#3 = flash_verify::verify_ram_address#0 [phi:flash_verify::@3->flash_verify::@1#1] -- register_copy 
    // [879] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#0 [phi:flash_verify::@3->flash_verify::@1#2] -- register_copy 
    // [879] phi flash_verify::verified_bytes#2 = flash_verify::verified_bytes#1 [phi:flash_verify::@3->flash_verify::@1#3] -- register_copy 
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
// void rom_sector_erase(__zp($ab) unsigned long address)
rom_sector_erase: {
    .label address = $ab
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [893] rom_ptr::address#2 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [894] call rom_ptr
    // [1233] phi from rom_sector_erase to rom_ptr [phi:rom_sector_erase->rom_ptr]
    // [1233] phi rom_ptr::address#3 = rom_ptr::address#2 [phi:rom_sector_erase->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_sector_erase::@return
    // }
    // [895] return 
    rts
}
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($26) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, __zp($7b) char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $26
    .label format_zero_padding = $7b
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [897] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [898] ultoa::value#1 = printf_ulong::uvalue#2
    // [899] call ultoa
  // Format number into buffer
    // [1238] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [900] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [901] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#2
    // [902] call printf_number_buffer
  // Print using format
    // [1064] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1064] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1064] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1064] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1064] phi printf_number_buffer::format_min_length#3 = 6 [phi:printf_ulong::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [903] return 
    rts
}
  // flash_write
// unsigned long flash_write(__zp($af) char flash_ram_bank, __zp($3d) char *flash_ram_address, __zp($3f) unsigned long flash_rom_address)
flash_write: {
    .label flash_rom_address = $3f
    .label flash_ram_address = $3d
    .label flashed_bytes = $5b
    .label flash_ram_bank = $af
    // flash_write::bank_set_bram1
    // BRAM = bank
    // [905] BRAM = flash_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [906] phi from flash_write::bank_set_bram1 to flash_write::@1 [phi:flash_write::bank_set_bram1->flash_write::@1]
    // [906] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#0] -- register_copy 
    // [906] phi flash_write::flash_rom_address#2 = flash_write::flash_rom_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#1] -- register_copy 
    // [906] phi flash_write::flashed_bytes#2 = 0 [phi:flash_write::bank_set_bram1->flash_write::@1#2] -- vduz1=vduc1 
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
    // [907] if(flash_write::flashed_bytes#2<$100) goto flash_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [908] return 
    rts
    // flash_write::@2
  __b2:
    // flash_rom_address++;
    // [909] flash_write::flash_rom_address#0 = ++ flash_write::flash_rom_address#2 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [910] flash_write::flash_ram_address#0 = ++ flash_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [911] flash_write::flashed_bytes#1 = ++ flash_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [906] phi from flash_write::@2 to flash_write::@1 [phi:flash_write::@2->flash_write::@1]
    // [906] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#0 [phi:flash_write::@2->flash_write::@1#0] -- register_copy 
    // [906] phi flash_write::flash_rom_address#2 = flash_write::flash_rom_address#0 [phi:flash_write::@2->flash_write::@1#1] -- register_copy 
    // [906] phi flash_write::flashed_bytes#2 = flash_write::flashed_bytes#1 [phi:flash_write::@2->flash_write::@1#2] -- register_copy 
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
// void rom_unlock(unsigned long address, __zp($55) char unlock_code)
rom_unlock: {
    .label unlock_code = $55
    // rom_write_byte(0x05555, 0xAA)
    // [913] call rom_write_byte
    // [1259] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1259] phi rom_write_byte::value#3 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [1259] phi rom_write_byte::address#3 = $5555 [phi:rom_unlock->rom_write_byte#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_write_byte.address
    lda #>$5555
    sta.z rom_write_byte.address+1
    lda #<$5555>>$10
    sta.z rom_write_byte.address+2
    lda #>$5555>>$10
    sta.z rom_write_byte.address+3
    jsr rom_write_byte
    // [914] phi from rom_unlock to rom_unlock::@1 [phi:rom_unlock->rom_unlock::@1]
    // rom_unlock::@1
    // rom_write_byte(0x02AAA, 0x55)
    // [915] call rom_write_byte
    // [1259] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1259] phi rom_write_byte::value#3 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [1259] phi rom_write_byte::address#3 = $2aaa [phi:rom_unlock::@1->rom_write_byte#1] -- vduz1=vduc1 
    lda #<$2aaa
    sta.z rom_write_byte.address
    lda #>$2aaa
    sta.z rom_write_byte.address+1
    lda #<$2aaa>>$10
    sta.z rom_write_byte.address+2
    lda #>$2aaa>>$10
    sta.z rom_write_byte.address+3
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [916] rom_write_byte::value#2 = rom_unlock::unlock_code#2 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [917] call rom_write_byte
    // [1259] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1259] phi rom_write_byte::value#3 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1259] phi rom_write_byte::address#3 = $5555 [phi:rom_unlock::@2->rom_write_byte#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_write_byte.address
    lda #>$5555
    sta.z rom_write_byte.address+1
    lda #<$5555>>$10
    sta.z rom_write_byte.address+2
    lda #>$5555>>$10
    sta.z rom_write_byte.address+3
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [918] return 
    rts
}
  // print_chip_line
// void print_chip_line(__zp($4f) char x, __zp($54) char y, __zp($38) char c)
print_chip_line: {
    .label x = $4f
    .label c = $38
    .label y = $54
    // gotoxy(x, y)
    // [920] gotoxy::x#4 = print_chip_line::x#9 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [921] gotoxy::y#4 = print_chip_line::y#9 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [922] call gotoxy
    // [431] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [923] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [924] call textcolor
    // [413] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [413] phi textcolor::color#22 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [925] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [926] call bgcolor
    // [418] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [927] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [928] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [930] call textcolor
    // [413] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [413] phi textcolor::color#22 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [931] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [932] call bgcolor
    // [418] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [418] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [933] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [934] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [936] stackpush(char) = print_chip_line::c#10 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [937] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [939] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [940] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [942] call textcolor
    // [413] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [413] phi textcolor::color#22 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [943] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [944] call bgcolor
    // [418] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [945] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [946] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [948] return 
    rts
}
  // print_chip_end
// void print_chip_end(__zp($d8) char x, char y)
print_chip_end: {
    .const y = $36
    .label x = $d8
    // gotoxy(x, y)
    // [949] gotoxy::x#5 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [950] call gotoxy
    // [431] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [431] phi gotoxy::y#22 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #y
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [951] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [952] call textcolor
    // [413] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [413] phi textcolor::color#22 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [953] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [954] call bgcolor
    // [418] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [955] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [956] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [958] call textcolor
    // [413] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [413] phi textcolor::color#22 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [959] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [960] call bgcolor
    // [418] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [418] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [961] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [962] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [964] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [965] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [967] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [968] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [970] call textcolor
    // [413] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [413] phi textcolor::color#22 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [971] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [972] call bgcolor
    // [418] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [418] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [973] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [974] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [976] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($7d) char mapbase, __zp($bf) char config)
screenlayer: {
    .label __0 = $d3
    .label __1 = $7d
    .label __2 = $d4
    .label __5 = $bf
    .label __6 = $bf
    .label __7 = $cf
    .label __8 = $cf
    .label __9 = $cd
    .label __10 = $cd
    .label __11 = $cd
    .label __12 = $ce
    .label __13 = $ce
    .label __14 = $ce
    .label __16 = $cf
    .label __17 = $c8
    .label __18 = $cd
    .label __19 = $ce
    .label mapbase_offset = $c9
    .label y = $7c
    .label mapbase = $7d
    .label config = $bf
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [977] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [978] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [979] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // mapbase >> 7
    // [980] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z __0
    // __conio.mapbase_bank = mapbase >> 7
    // [981] *((char *)&__conio+3) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+3
    // (mapbase)<<1
    // [982] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __1
    // MAKEWORD((mapbase)<<1,0)
    // [983] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z __1
    sty.z __2+1
    sta.z __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [984] *((unsigned int *)&__conio+1) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+1
    tya
    sta __conio+1+1
    // config & VERA_LAYER_WIDTH_MASK
    // [985] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z __7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [986] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z __8
    lsr
    lsr
    lsr
    lsr
    sta.z __8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [987] *((char *)&__conio+6) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+6
    // config & VERA_LAYER_HEIGHT_MASK
    // [988] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z __5
    sta.z __5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [989] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z __6
    rol
    rol
    rol
    and #3
    sta.z __6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [990] *((char *)&__conio+7) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+7
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [991] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __16
    // [992] *((unsigned int *)&__conio+8) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z __16
    lda VERA_LAYER_SKIP,y
    sta __conio+8
    lda VERA_LAYER_SKIP+1,y
    sta __conio+8+1
    // vera_dc_hscale_temp == 0x80
    // [993] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z __9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [994] screenlayer::$18 = (char)screenlayer::$9
    // [995] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [996] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z __11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [997] *((char *)&__conio+4) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z __11
    sta __conio+4
    // vera_dc_vscale_temp == 0x80
    // [998] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z __12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [999] screenlayer::$19 = (char)screenlayer::$12
    // [1000] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1001] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z __14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1002] *((char *)&__conio+5) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z __14
    sta __conio+5
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1003] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z mapbase_offset
    lda __conio+1+1
    sta.z mapbase_offset+1
    // [1004] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1004] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1004] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1005] if(screenlayer::y#2<=*((char *)&__conio+5)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+5
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1006] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1007] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z __17
    // [1008] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1009] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+8
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+8+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1010] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1004] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1004] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1004] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1011] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1012] if(0!=((char *)&__conio+$f)[*((char *)&__conio)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1013] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // [1014] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1015] call gotoxy
    // [431] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [431] phi gotoxy::y#22 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [431] phi gotoxy::x#22 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1016] return 
    rts
    // [1017] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1018] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1019] gotoxy::y#2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z gotoxy.y
    // [1020] call gotoxy
    // [431] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1021] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1022] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($54) char x, __zp($38) char y, __zp($4c) char c)
cputcxy: {
    .label x = $54
    .label y = $38
    .label c = $4c
    // gotoxy(x, y)
    // [1024] gotoxy::x#0 = cputcxy::x#68 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1025] gotoxy::y#0 = cputcxy::y#68 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1026] call gotoxy
    // [431] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [431] phi gotoxy::y#22 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [431] phi gotoxy::x#22 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1027] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1028] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1030] return 
    rts
}
  // getin
/**
 * @brief Get a character from keyboard.
 * 
 * @return char The character read.
 */
getin: {
    .label return = $7a
    // __mem unsigned char ch
    // [1031] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [1033] getin::return#0 = getin::ch -- vbuz1=vbum2 
    sta.z return
    // getin::@return
    // }
    // [1034] getin::return#1 = getin::return#0
    // [1035] return 
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
// void uctoa(__zp($23) char value, __zp($4a) char *buffer, __zp($58) char radix)
uctoa: {
    .label __4 = $54
    .label digit_value = $2d
    .label buffer = $4a
    .label digit = $53
    .label value = $23
    .label radix = $58
    .label started = $49
    .label max_digits = $4c
    .label digit_values = $3d
    // if(radix==DECIMAL)
    // [1036] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1037] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1038] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1039] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1040] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1041] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1042] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1043] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1044] return 
    rts
    // [1045] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1045] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1045] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1045] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1045] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1045] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1045] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1045] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1045] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1045] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1045] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1045] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1046] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1046] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1046] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1046] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1046] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1047] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1048] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z __4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1049] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1050] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1051] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1052] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1053] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1054] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1055] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1055] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1055] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1055] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1056] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1046] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1046] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1046] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1046] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1046] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1057] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1058] uctoa_append::value#0 = uctoa::value#2
    // [1059] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1060] call uctoa_append
    // [1304] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1061] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1062] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1063] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1055] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1055] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1055] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1055] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($67) void (*putc)(char), __zp($53) char buffer_sign, char *buffer_digits, __zp($2a) char format_min_length, char format_justify_left, char format_sign_always, __zp($7b) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label __19 = $4a
    .label buffer_sign = $53
    .label format_zero_padding = $7b
    .label putc = $67
    .label format_min_length = $2a
    .label len = $49
    .label padding = $49
    // if(format.min_length)
    // [1065] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [1066] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1067] call strlen
    // [1133] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1133] phi strlen::str#6 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1068] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1069] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1070] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z __19
    sta.z len
    // if(buffer.sign)
    // [1071] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1072] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1073] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1073] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1074] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1075] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1077] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1077] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1076] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1077] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1077] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1078] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1079] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1080] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1081] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1082] call printf_padding
    // [1139] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1139] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1139] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1139] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1083] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1084] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1085] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall25
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1087] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1088] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1089] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1090] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1091] call printf_padding
    // [1139] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1139] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1139] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1139] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1092] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1093] call printf_str
    // [659] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [659] phi printf_str::putc#20 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [659] phi printf_str::s#20 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1094] return 
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
// char * strncpy(__zp($39) char *dst, __zp($4a) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label c = $2d
    .label dst = $39
    .label i = $3d
    .label src = $4a
    // [1096] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1096] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1096] phi strncpy::src#2 = main::buffer [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z src
    lda #>main.buffer
    sta.z src+1
    // [1096] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1097] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuc1_then_la1 
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
    // [1098] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1099] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1100] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1101] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1102] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1102] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1103] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1104] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1105] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1096] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1096] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1096] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1096] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_setnam
/**
 * @brief Sets the name of the file before opening.
 * 
 * @param filename The name of the file.
 */
// void cbm_k_setnam(__zp($d6) char * volatile filename)
cbm_k_setnam: {
    .label filename = $d6
    .label __0 = $4a
    // strlen(filename)
    // [1106] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbuz2 
    lda.z filename
    sta.z strlen.str
    lda.z filename+1
    sta.z strlen.str+1
    // [1107] call strlen
    // [1133] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [1133] phi strlen::str#6 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1108] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [1109] cbm_k_setnam::$0 = strlen::return#0
    // __mem char filename_len = (char)strlen(filename)
    // [1110] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwuz2 
    lda.z __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [1112] return 
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
// void cbm_k_setlfs(__zp($dc) volatile char channel, __zp($db) volatile char device, __zp($d9) volatile char command)
cbm_k_setlfs: {
    .label channel = $dc
    .label device = $db
    .label command = $d9
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1114] return 
    rts
}
  // cbm_k_open
/**
 * @brief Open a logical file.
 * 
 * @return char The status.
 */
cbm_k_open: {
    .label return = $b2
    // __mem unsigned char status
    // [1115] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [1117] cbm_k_open::return#0 = cbm_k_open::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_open::@return
    // }
    // [1118] cbm_k_open::return#1 = cbm_k_open::return#0
    // [1119] return 
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
// __zp($2d) char cbm_k_close(__zp($da) volatile char channel)
cbm_k_close: {
    .label channel = $da
    .label return = $2d
    // __mem unsigned char status
    // [1120] cbm_k_close::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldachannel jsrCBM_CLOSE stastatus  }
    lda channel
    jsr CBM_CLOSE
    sta status
    // return status;
    // [1122] cbm_k_close::return#0 = cbm_k_close::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_close::@return
    // }
    // [1123] cbm_k_close::return#1 = cbm_k_close::return#0
    // [1124] return 
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
    // [1125] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [1127] return 
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
    .label return = $54
    // __mem unsigned char status
    // [1128] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [1130] cbm_k_readst::return#0 = cbm_k_readst::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_readst::@return
    // }
    // [1131] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [1132] return 
    rts
  .segment Data
    status: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($4a) unsigned int strlen(__zp($39) char *str)
strlen: {
    .label str = $39
    .label return = $4a
    .label len = $4a
    // [1134] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1134] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1134] phi strlen::str#4 = strlen::str#6 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1135] if(0!=*strlen::str#4) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1136] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1137] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1138] strlen::str#1 = ++ strlen::str#4 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1134] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1134] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1134] phi strlen::str#4 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($39) void (*putc)(char), __zp($4f) char pad, __zp($2d) char length)
printf_padding: {
    .label i = $38
    .label putc = $39
    .label length = $2d
    .label pad = $4f
    // [1140] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1140] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1141] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1142] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1143] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1144] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall26
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1146] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1140] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1140] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
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
// __zp($6a) unsigned int fgets(__zp($4a) char *ptr, unsigned int size, __zp($2b) struct $1 *fp)
fgets: {
    .const size = $80
    .label __1 = $54
    .label __9 = $54
    .label __10 = $22
    .label __14 = $53
    .label return = $6a
    .label bytes = $50
    .label read = $6a
    .label ptr = $4a
    .label remaining = $39
    .label fp = $2b
    // cbm_k_chkin(fp->channel)
    // [1147] cbm_k_chkin::channel = ((char *)fgets::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_chkin.channel
    // [1148] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1149] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [1150] call cbm_k_readst
    jsr cbm_k_readst
    // [1151] cbm_k_readst::return#3 = cbm_k_readst::return#1
    // fgets::@12
    // [1152] fgets::$1 = cbm_k_readst::return#3
    // fp->status = cbm_k_readst()
    // [1153] ((char *)fgets::fp#0)[$13] = fgets::$1 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __1
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [1154] if(0==((char *)fgets::fp#0)[$13]) goto fgets::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b8
    // [1155] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [1155] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1156] return 
    rts
    // [1157] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [1157] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1157] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@12->fgets::@1#1] -- vwuz1=vwuc1 
    lda #<size
    sta.z remaining
    lda #>size
    sta.z remaining+1
    // [1157] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [1157] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [1157] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [1157] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [1157] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [1158] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwuz1_ge_vbuc1_then_la1 
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
    // [1159] cbm_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cbm_k_macptr.bytes
    // [1160] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1161] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1162] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [1163] fgets::bytes#3 = cbm_k_macptr::return#4
    // [1164] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [1164] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [1165] call cbm_k_readst
    jsr cbm_k_readst
    // [1166] cbm_k_readst::return#4 = cbm_k_readst::return#1
    // fgets::@15
    // [1167] fgets::$9 = cbm_k_readst::return#4
    // fp->status = cbm_k_readst()
    // [1168] ((char *)fgets::fp#0)[$13] = fgets::$9 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __9
    ldy #$13
    sta (fp),y
    // fp->status & 0xBF
    // [1169] fgets::$10 = ((char *)fgets::fp#0)[$13] & $bf -- vbuz1=pbuz2_derefidx_vbuc1_band_vbuc2 
    lda #$bf
    and (fp),y
    sta.z __10
    // if(fp->status & 0xBF)
    // [1170] if(0==fgets::$10) goto fgets::@4 -- 0_eq_vbuz1_then_la1 
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [1171] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1172] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1173] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1174] fgets::$14 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z __14
    // if(BYTE1(ptr) == 0xC0)
    // [1175] if(fgets::$14!=$c0) goto fgets::@6 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z __14
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [1176] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1177] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [1177] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [1178] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((fp->status == 0) && ((size && remaining) || !size))
    // [1179] if(((char *)fgets::fp#0)[$13]==0) goto fgets::@16 -- pbuz1_derefidx_vbuc1_eq_0_then_la1 
    ldy #$13
    lda (fp),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [1180] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [1181] cbm_k_chkin::channel = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin.channel
    // [1182] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1155] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [1155] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [1183] cbm_k_macptr::bytes = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cbm_k_macptr.bytes
    // [1184] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1185] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1186] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [1187] fgets::bytes#2 = cbm_k_macptr::return#3
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
    // [1189] return 
    rts
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($24) unsigned int value, __zp($50) char *buffer, __zp($7a) char radix)
utoa: {
    .label __4 = $22
    .label __10 = $55
    .label __11 = $53
    .label digit_value = $2b
    .label buffer = $50
    .label digit = $4f
    .label value = $24
    .label radix = $7a
    .label started = $38
    .label max_digits = $2d
    .label digit_values = $6a
    // if(radix==DECIMAL)
    // [1190] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1191] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1192] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1193] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1194] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1195] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1196] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1197] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1198] return 
    rts
    // [1199] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1199] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1199] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1199] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1199] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1199] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1199] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1199] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1199] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1199] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1199] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1199] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1200] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1200] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1200] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1200] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1200] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1201] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1202] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z __4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1203] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z __11
    // [1204] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1205] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1206] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1207] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z __10
    // [1208] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1209] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1210] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1211] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1211] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1211] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1211] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1212] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1200] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1200] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1200] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1200] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1200] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1213] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1214] utoa_append::value#0 = utoa::value#2
    // [1215] utoa_append::sub#0 = utoa::digit_value#0
    // [1216] call utoa_append
    // [1316] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1217] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1218] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1219] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1211] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1211] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1211] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1211] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
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
// __zp($23) char rom_byte_verify(__zp($5f) unsigned long address, __zp($54) char value)
rom_byte_verify: {
    .label bank_rom = $49
    .label ptr_rom = $3d
    .label return = $23
    .label address = $5f
    .label value = $54
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1220] rom_bank::address#1 = rom_byte_verify::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_bank.address
    lda.z address+1
    sta.z rom_bank.address+1
    lda.z address+2
    sta.z rom_bank.address+2
    lda.z address+3
    sta.z rom_bank.address+3
    // [1221] call rom_bank
    // [1323] phi from rom_byte_verify to rom_bank [phi:rom_byte_verify->rom_bank]
    // [1323] phi rom_bank::address#2 = rom_bank::address#1 [phi:rom_byte_verify->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1222] rom_bank::return#3 = rom_bank::return#0
    // rom_byte_verify::@3
    // [1223] rom_byte_verify::bank_rom#0 = rom_bank::return#3
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1224] rom_ptr::address#1 = rom_byte_verify::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [1225] call rom_ptr
    // [1233] phi from rom_byte_verify::@3 to rom_ptr [phi:rom_byte_verify::@3->rom_ptr]
    // [1233] phi rom_ptr::address#3 = rom_ptr::address#1 [phi:rom_byte_verify::@3->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_byte_verify::@4
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1226] rom_byte_verify::ptr_rom#0 = (char *)rom_ptr::return#0
    // bank_set_brom(bank_rom)
    // [1227] bank_set_brom::bank#3 = rom_byte_verify::bank_rom#0
    // [1228] call bank_set_brom
    // [695] phi from rom_byte_verify::@4 to bank_set_brom [phi:rom_byte_verify::@4->bank_set_brom]
    // [695] phi bank_set_brom::bank#8 = bank_set_brom::bank#3 [phi:rom_byte_verify::@4->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_byte_verify::@5
    // if (*ptr_rom != value)
    // [1229] if(*rom_byte_verify::ptr_rom#0==rom_byte_verify::value#0) goto rom_byte_verify::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1230] phi from rom_byte_verify::@5 to rom_byte_verify::@2 [phi:rom_byte_verify::@5->rom_byte_verify::@2]
    // rom_byte_verify::@2
    // [1231] phi from rom_byte_verify::@2 to rom_byte_verify::@1 [phi:rom_byte_verify::@2->rom_byte_verify::@1]
    // [1231] phi rom_byte_verify::return#0 = 0 [phi:rom_byte_verify::@2->rom_byte_verify::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [1231] phi from rom_byte_verify::@5 to rom_byte_verify::@1 [phi:rom_byte_verify::@5->rom_byte_verify::@1]
  __b2:
    // [1231] phi rom_byte_verify::return#0 = 1 [phi:rom_byte_verify::@5->rom_byte_verify::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_verify::@1
    // rom_byte_verify::@return
    // }
    // [1232] return 
    rts
}
  // rom_ptr
/**
 * @brief Calcuates the 16 bit ROM pointer from the ROM using the 22 bit address.
 * The 16 bit ROM pointer is calculated by masking the lower 14 bits (bit 13-0), and then adding $C000 to it.
 * The 16 bit ROM pointer is returned as a char* (brom_ptr_t).
 * @param address The 22 bit ROM address.
 * @return brom_ptr_t The 16 bit ROM pointer for the main CPU addressing.
 */
// __zp($3d) char * rom_ptr(__zp($3f) unsigned long address)
rom_ptr: {
    .label __0 = $3f
    .label __2 = $3d
    .label return = $3d
    .label address = $3f
    // address & ROM_PTR_MASK
    // [1234] rom_ptr::$0 = rom_ptr::address#3 & $3fff -- vduz1=vduz1_band_vduc1 
    lda.z __0
    and #<$3fff
    sta.z __0
    lda.z __0+1
    and #>$3fff
    sta.z __0+1
    lda.z __0+2
    and #<$3fff>>$10
    sta.z __0+2
    lda.z __0+3
    and #>$3fff>>$10
    sta.z __0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [1235] rom_ptr::$2 = (unsigned int)rom_ptr::$0 -- vwuz1=_word_vduz2 
    lda.z __0
    sta.z __2
    lda.z __0+1
    sta.z __2+1
    // [1236] rom_ptr::return#0 = rom_ptr::$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z return
    clc
    adc #<$c000
    sta.z return
    lda.z return+1
    adc #>$c000
    sta.z return+1
    // rom_ptr::@return
    // }
    // [1237] return 
    rts
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($26) unsigned long value, __zp($2b) char *buffer, char radix)
ultoa: {
    .label __10 = $22
    .label __11 = $55
    .label digit_value = $2e
    .label buffer = $2b
    .label digit = $23
    .label value = $26
    .label started = $58
    // [1239] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1239] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1239] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1239] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1239] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1240] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1241] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z __11
    // [1242] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1243] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1244] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1245] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1246] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z __10
    // [1247] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [1248] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [1249] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1250] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1250] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1250] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1250] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1251] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1239] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1239] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1239] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1239] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1239] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1252] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1253] ultoa_append::value#0 = ultoa::value#2
    // [1254] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1255] call ultoa_append
    // [1328] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1256] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1257] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1258] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1250] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1250] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1250] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1250] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
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
// void rom_write_byte(__zp($3f) unsigned long address, __zp($58) char value)
rom_write_byte: {
    .label bank_rom = $22
    .label ptr_rom = $24
    .label value = $58
    .label address = $3f
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1260] rom_bank::address#0 = rom_write_byte::address#3 -- vduz1=vduz2 
    lda.z address
    sta.z rom_bank.address
    lda.z address+1
    sta.z rom_bank.address+1
    lda.z address+2
    sta.z rom_bank.address+2
    lda.z address+3
    sta.z rom_bank.address+3
    // [1261] call rom_bank
    // [1323] phi from rom_write_byte to rom_bank [phi:rom_write_byte->rom_bank]
    // [1323] phi rom_bank::address#2 = rom_bank::address#0 [phi:rom_write_byte->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1262] rom_bank::return#2 = rom_bank::return#0 -- vbuz1=vbuz2 
    lda.z rom_bank.return
    sta.z rom_bank.return_1
    // rom_write_byte::@1
    // [1263] rom_write_byte::bank_rom#0 = rom_bank::return#2
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1264] rom_ptr::address#0 = rom_write_byte::address#3
    // [1265] call rom_ptr
    // [1233] phi from rom_write_byte::@1 to rom_ptr [phi:rom_write_byte::@1->rom_ptr]
    // [1233] phi rom_ptr::address#3 = rom_ptr::address#0 [phi:rom_write_byte::@1->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_write_byte::@2
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1266] rom_write_byte::ptr_rom#0 = (char *)rom_ptr::return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // bank_set_brom(bank_rom)
    // [1267] bank_set_brom::bank#2 = rom_write_byte::bank_rom#0 -- vbuz1=vbuz2 
    lda.z bank_rom
    sta.z bank_set_brom.bank
    // [1268] call bank_set_brom
    // [695] phi from rom_write_byte::@2 to bank_set_brom [phi:rom_write_byte::@2->bank_set_brom]
    // [695] phi bank_set_brom::bank#8 = bank_set_brom::bank#2 [phi:rom_write_byte::@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_write_byte::@3
    // *ptr_rom = value
    // [1269] *rom_write_byte::ptr_rom#0 = rom_write_byte::value#3 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (ptr_rom),y
    // rom_write_byte::@return
    // }
    // [1270] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label __0 = $69
    .label __4 = $59
    .label __6 = $5a
    .label __7 = $59
    .label width = $69
    .label y = $52
    // __conio.width+1
    // [1271] insertup::$0 = *((char *)&__conio+4) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+4
    inc
    sta.z __0
    // unsigned char width = (__conio.width+1) * 2
    // [1272] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z width
    // [1273] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1273] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1274] if(insertup::y#2<=*((char *)&__conio+$e)) goto insertup::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+$e
    cmp.z y
    bcs __b2
    // [1275] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1276] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1277] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1278] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z __4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1279] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z __6
    // [1280] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __7
    // [1281] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.dbank_vram
    // [1282] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1283] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.sbank_vram
    // [1284] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1285] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [1286] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1287] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1273] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1273] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label __0 = $43
    .label __1 = $45
    .label __2 = $46
    .label __3 = $44
    .label addr = $56
    .label c = $32
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1288] clearline::$3 = *((char *)&__conio+$e) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    sta.z __3
    // [1289] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1290] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1291] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z __0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1292] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1293] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z __1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1294] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1295] clearline::$2 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1296] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1297] clearline::c#0 = *((char *)&__conio+4) -- vbuz1=_deref_pbuc1 
    lda __conio+4
    sta.z c
    // [1298] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1298] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1299] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1300] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [1301] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1302] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1303] return 
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
// __zp($23) char uctoa_append(__zp($2b) char *buffer, __zp($23) char value, __zp($2d) char sub)
uctoa_append: {
    .label buffer = $2b
    .label value = $23
    .label sub = $2d
    .label return = $23
    .label digit = $22
    // [1305] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1305] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1305] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1306] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1307] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1308] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1309] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1310] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [1305] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1305] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1305] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($50) unsigned int cbm_k_macptr(__zp($74) volatile char bytes, __zp($71) void * volatile buffer)
cbm_k_macptr: {
    .label bytes = $74
    .label buffer = $71
    .label return = $50
    // __mem unsigned int bytes_read
    // [1311] cbm_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [1313] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwuz1=vwum2 
    lda bytes_read
    sta.z return
    lda bytes_read+1
    sta.z return+1
    // cbm_k_macptr::@return
    // }
    // [1314] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [1315] return 
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
// __zp($24) unsigned int utoa_append(__zp($3d) char *buffer, __zp($24) unsigned int value, __zp($2b) unsigned int sub)
utoa_append: {
    .label buffer = $3d
    .label value = $24
    .label sub = $2b
    .label return = $24
    .label digit = $22
    // [1317] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1317] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1317] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1318] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1319] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1320] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1321] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1322] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1317] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1317] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1317] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // rom_bank
/**
 * @brief Calculates the 8 bit ROM bank from the 22 bit ROM address.
 * The ROM bank number is calcuated by taking the upper 8 bits (bit 18-14) and shifing those 14 bits to the right.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The ROM bank number for usage in ZP $01.
 */
// __zp($49) char rom_bank(__zp($34) unsigned long address)
rom_bank: {
    .label __1 = $34
    .label __2 = $34
    .label return = $49
    .label address = $34
    .label return_1 = $22
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [1324] rom_bank::$2 = rom_bank::address#2 & $3fc000 -- vduz1=vduz1_band_vduc1 
    lda.z __2
    and #<$3fc000
    sta.z __2
    lda.z __2+1
    and #>$3fc000
    sta.z __2+1
    lda.z __2+2
    and #<$3fc000>>$10
    sta.z __2+2
    lda.z __2+3
    and #>$3fc000>>$10
    sta.z __2+3
    // [1325] rom_bank::$1 = rom_bank::$2 >> $e -- vduz1=vduz1_ror_vbuc1 
    ldy #$e
    cpy #0
    beq !e+
  !:
    lsr.z __1+3
    ror.z __1+2
    ror.z __1+1
    ror.z __1
    dey
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [1326] rom_bank::return#0 = (char)rom_bank::$1 -- vbuz1=_byte_vduz2 
    lda.z __1
    sta.z return
    // rom_bank::@return
    // }
    // [1327] return 
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
// __zp($26) unsigned long ultoa_append(__zp($24) char *buffer, __zp($26) unsigned long value, __zp($2e) unsigned long sub)
ultoa_append: {
    .label buffer = $24
    .label value = $26
    .label sub = $2e
    .label return = $26
    .label digit = $2a
    // [1329] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1329] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1329] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1330] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [1331] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1332] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1333] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1334] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [1329] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1329] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1329] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
// void memcpy8_vram_vram(__zp($44) char dbank_vram, __zp($56) unsigned int doffset_vram, __zp($43) char sbank_vram, __zp($4d) unsigned int soffset_vram, __zp($33) char num8)
memcpy8_vram_vram: {
    .label __0 = $45
    .label __1 = $46
    .label __2 = $43
    .label __3 = $47
    .label __4 = $48
    .label __5 = $44
    .label num8 = $33
    .label dbank_vram = $44
    .label doffset_vram = $56
    .label sbank_vram = $43
    .label soffset_vram = $4d
    .label num8_1 = $32
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1335] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1336] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z __0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1337] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1338] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z __1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1339] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1340] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z __2
    sta.z __2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1341] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1342] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1343] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z __3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1344] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1345] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z __4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1346] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1347] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z __5
    sta.z __5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1348] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1349] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1349] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1350] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [1351] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1352] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1353] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1354] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
    lda.z num8
    sta.z num8_1
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
  str: .text " "
  .byte 0
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
