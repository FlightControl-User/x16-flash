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
// void snputc(__zp($ed) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $ed
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
    .label __4 = $da
    .label __5 = $b0
    .label __6 = $da
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [504] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [509] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [522] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
// void cputc(__zp($5d) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label __1 = $35
    .label __2 = $b3
    .label __3 = $b4
    .label c = $5d
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
    .label __20 = $af
    .label __22 = $af
    .label __38 = $f8
    .label __56 = $54
    .label __64 = $2b
    .label __73 = $74
    .label __98 = $d5
    .label __137 = $23
    .label flash_rom_address_boundary = $6f
    .label flash_bytes = $bd
    .label flash_rom_address_boundary_1 = $69
    .label flash_rom_address1 = $e4
    .label equal_bytes = $6d
    .label flash_rom_address_sector = $de
    .label read_ram_address = $d1
    .label x_sector = $eb
    .label read_ram_bank = $ca
    .label y_sector = $ec
    .label equal_bytes1 = $6d
    .label read_ram_address_sector = $cb
    .label flash_rom_address_boundary1 = $cd
    .label retries = $c8
    .label flash_errors = $b6
    .label read_ram_address1 = $c5
    .label flash_rom_address2 = $c1
    .label x1 = $bb
    .label flash_errors_sector = $d3
    .label x_sector1 = $dd
    .label read_ram_bank_sector = $c9
    .label y_sector1 = $dc
    .label v = $e9
    .label pattern = $f4
    .label pattern1 = $3e
    .label __175 = $f8
    .label __176 = $f8
    .label __178 = $2b
    .label __179 = $2b
    .label __181 = $54
    .label __182 = $54
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
    // [504] phi from main::@64 to textcolor [phi:main::@64->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@64->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [77] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
    // bgcolor(BLUE)
    // [78] call bgcolor
    // [509] phi from main::@65 to bgcolor [phi:main::@65->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:main::@65->bgcolor#0] -- vbuz1=vbuc1 
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
    // [570] phi from main::@68 to frame_draw [phi:main::@68->frame_draw]
    jsr frame_draw
    // [85] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // gotoxy(2, 1)
    // [86] call gotoxy
    // [522] phi from main::@69 to gotoxy [phi:main::@69->gotoxy]
    // [522] phi gotoxy::y#24 = 1 [phi:main::@69->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = 2 [phi:main::@69->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [87] phi from main::@69 to main::@70 [phi:main::@69->main::@70]
    // main::@70
    // printf("commander x16 rom flash utility")
    // [88] call printf_str
    // [750] phi from main::@70 to printf_str [phi:main::@70->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:main::@70->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s [phi:main::@70->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [89] phi from main::@70 to main::@71 [phi:main::@70->main::@71]
    // main::@71
    // print_chips()
    // [90] call print_chips
    // [759] phi from main::@71 to print_chips [phi:main::@71->print_chips]
    jsr print_chips
    // [91] phi from main::@71 to main::@1 [phi:main::@71->main::@1]
    // [91] phi main::rom_chip#10 = 0 [phi:main::@71->main::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [91] phi main::flash_rom_address#10 = 0 [phi:main::@71->main::@1#1] -- vdum1=vduc1 
    sta flash_rom_address
    sta flash_rom_address+1
    lda #<0>>$10
    sta flash_rom_address+2
    lda #>0>>$10
    sta flash_rom_address+3
    // main::@1
  __b1:
    // for (unsigned long flash_rom_address = 0; flash_rom_address < 8 * 0x80000; flash_rom_address += 0x80000)
    // [92] if(main::flash_rom_address#10<8*$80000) goto main::@2 -- vdum1_lt_vduc1_then_la1 
    lda flash_rom_address+3
    cmp #>8*$80000>>$10
    bcs !__b2+
    jmp __b2
  !__b2:
    bne !+
    lda flash_rom_address+2
    cmp #<8*$80000>>$10
    bcs !__b2+
    jmp __b2
  !__b2:
    bne !+
    lda flash_rom_address+1
    cmp #>8*$80000
    bcs !__b2+
    jmp __b2
  !__b2:
    bne !+
    lda flash_rom_address
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
    // [750] phi from main::@77 to printf_str [phi:main::@77->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@77->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s1 [phi:main::@77->printf_str#1] -- pbuz1=pbuc1 
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
    // [794] phi from main::@78 to print_text [phi:main::@78->print_text]
    jsr print_text
    // [102] phi from main::@78 to main::@79 [phi:main::@78->main::@79]
    // main::@79
    // wait_key()
    // [103] call wait_key
    // [801] phi from main::@79 to wait_key [phi:main::@79->wait_key]
    jsr wait_key
    // [104] phi from main::@79 to main::@11 [phi:main::@79->main::@11]
    // [104] phi main::flash_chip#10 = 7 [phi:main::@79->main::@11#0] -- vbum1=vbuc1 
    lda #7
    sta flash_chip
    // main::@11
  __b11:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [105] if(main::flash_chip#10!=$ff) goto main::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp flash_chip
    beq !__b12+
    jmp __b12
  !__b12:
    // [106] phi from main::@11 to main::@13 [phi:main::@11->main::@13]
    // main::@13
    // bank_set_brom(0)
    // [107] call bank_set_brom
    // [811] phi from main::@13 to bank_set_brom [phi:main::@13->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 0 [phi:main::@13->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #0
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [108] phi from main::@13 to main::@89 [phi:main::@13->main::@89]
    // main::@89
    // textcolor(WHITE)
    // [109] call textcolor
    // [504] phi from main::@89 to textcolor [phi:main::@89->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@89->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [110] phi from main::@89 to main::@50 [phi:main::@89->main::@50]
    // [110] phi main::w#10 = $80 [phi:main::@89->main::@50#0] -- vwsm1=vwsc1 
    lda #<$80
    sta w
    lda #>$80
    sta w+1
    // main::@50
  __b50:
    // for (int w = 128; w >= 0; w--)
    // [111] if(main::w#10>=0) goto main::@52 -- vwsm1_ge_0_then_la1 
    lda w+1
    bpl __b6
    // [112] phi from main::@50 to main::@51 [phi:main::@50->main::@51]
    // main::@51
    // system_reset()
    // [113] call system_reset
    // [814] phi from main::@51 to system_reset [phi:main::@51->system_reset]
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
    // [119] phi from main::@54 to main::@172 [phi:main::@54->main::@172]
    // main::@172
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [120] call printf_str
    // [750] phi from main::@172 to printf_str [phi:main::@172->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@172->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s22 [phi:main::@172->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@173
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [121] printf_sint::value#1 = main::w#10 -- vwsz1=vwsm2 
    lda w
    sta.z printf_sint.value
    lda w+1
    sta.z printf_sint.value+1
    // [122] call printf_sint
    jsr printf_sint
    // [123] phi from main::@173 to main::@174 [phi:main::@173->main::@174]
    // main::@174
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [124] call printf_str
    // [750] phi from main::@174 to printf_str [phi:main::@174->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@174->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s23 [phi:main::@174->printf_str#1] -- pbuz1=pbuc1 
    lda #<s23
    sta.z printf_str.s
    lda #>s23
    sta.z printf_str.s+1
    jsr printf_str
    // main::@175
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
    // [794] phi from main::@175 to print_text [phi:main::@175->print_text]
    jsr print_text
    // main::@176
    // for (int w = 128; w >= 0; w--)
    // [129] main::w#1 = -- main::w#10 -- vwsm1=_dec_vwsm1 
    lda w
    bne !+
    dec w+1
  !:
    dec w
    // [110] phi from main::@176 to main::@50 [phi:main::@176->main::@50]
    // [110] phi main::w#10 = main::w#1 [phi:main::@176->main::@50#0] -- register_copy 
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
    // [131] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@14 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b14+
    jmp __b14
  !__b14:
    // [132] phi from main::@12 to main::@48 [phi:main::@12->main::@48]
    // main::@48
    // gotoxy(0, 2)
    // [133] call gotoxy
    // [522] phi from main::@48 to gotoxy [phi:main::@48->gotoxy]
    // [522] phi gotoxy::y#24 = 2 [phi:main::@48->gotoxy#0] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = 0 [phi:main::@48->gotoxy#1] -- vbuz1=vbuc1 
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
    // [811] phi from main::@57 to bank_set_brom [phi:main::@57->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 4 [phi:main::@57->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@90
    // if (flash_chip == 0)
    // [137] if(main::flash_chip#10==0) goto main::@15 -- vbum1_eq_0_then_la1 
    lda flash_chip
    bne !__b15+
    jmp __b15
  !__b15:
    // [138] phi from main::@90 to main::@49 [phi:main::@90->main::@49]
    // main::@49
    // sprintf(file, "rom%u.bin", flash_chip)
    // [139] call snprintf_init
    jsr snprintf_init
    // [140] phi from main::@49 to main::@93 [phi:main::@49->main::@93]
    // main::@93
    // sprintf(file, "rom%u.bin", flash_chip)
    // [141] call printf_str
    // [750] phi from main::@93 to printf_str [phi:main::@93->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@93->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s3 [phi:main::@93->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@94
    // sprintf(file, "rom%u.bin", flash_chip)
    // [142] printf_uchar::uvalue#4 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [143] call printf_uchar
    // [830] phi from main::@94 to printf_uchar [phi:main::@94->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@94->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@94->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &snputc [phi:main::@94->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@94->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#4 [phi:main::@94->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [144] phi from main::@94 to main::@95 [phi:main::@94->main::@95]
    // main::@95
    // sprintf(file, "rom%u.bin", flash_chip)
    // [145] call printf_str
    // [750] phi from main::@95 to printf_str [phi:main::@95->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@95->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s4 [phi:main::@95->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@96
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
    // [149] main::flash_rom_bank#0 = main::flash_chip#10 << 5 -- vbum1=vbum2_rol_5 
    lda flash_chip
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
    // main::@97
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
    // [154] phi from main::@97 to main::@46 [phi:main::@97->main::@46]
    // main::@46
    // textcolor(WHITE)
    // [155] call textcolor
    // [504] phi from main::@46 to textcolor [phi:main::@46->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@46->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [156] phi from main::@46 to main::@111 [phi:main::@46->main::@111]
    // main::@111
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [157] call snprintf_init
    jsr snprintf_init
    // [158] phi from main::@111 to main::@112 [phi:main::@111->main::@112]
    // main::@112
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [159] call printf_str
    // [750] phi from main::@112 to printf_str [phi:main::@112->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@112->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s7 [phi:main::@112->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@113
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [160] printf_uchar::uvalue#6 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [161] call printf_uchar
    // [830] phi from main::@113 to printf_uchar [phi:main::@113->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@113->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@113->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &snputc [phi:main::@113->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@113->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#6 [phi:main::@113->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [162] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [163] call printf_str
    // [750] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s8 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
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
    // [794] phi from main::@115 to print_text [phi:main::@115->print_text]
    jsr print_text
    // main::@116
    // flash_chip * 10
    // [168] main::$181 = main::flash_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda flash_chip
    asl
    asl
    sta.z __181
    // [169] main::$182 = main::$181 + main::flash_chip#10 -- vbuz1=vbuz1_plus_vbum2 
    lda flash_chip
    clc
    adc.z __182
    sta.z __182
    // [170] main::$56 = main::$182 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __56
    // gotoxy(2 + flash_chip * 10, 58)
    // [171] gotoxy::x#18 = 2 + main::$56 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __56
    sta.z gotoxy.x
    // [172] call gotoxy
    // [522] phi from main::@116 to gotoxy [phi:main::@116->gotoxy]
    // [522] phi gotoxy::y#24 = $3a [phi:main::@116->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = gotoxy::x#18 [phi:main::@116->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [173] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // printf("no file")
    // [174] call printf_str
    // [750] phi from main::@117 to printf_str [phi:main::@117->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:main::@117->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s9 [phi:main::@117->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@118
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [175] print_chip_led::r#6 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [176] call print_chip_led
    // [878] phi from main::@118 to print_chip_led [phi:main::@118->print_chip_led]
    // [878] phi print_chip_led::tc#10 = DARK_GREY [phi:main::@118->print_chip_led#0] -- vbuz1=vbuc1 
    lda #DARK_GREY
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#6 [phi:main::@118->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@18
  __b18:
    // if (flash_chip != 0)
    // [177] if(main::flash_chip#10==0) goto main::@14 -- vbum1_eq_0_then_la1 
    lda flash_chip
    beq __b14
    // [178] phi from main::@18 to main::@47 [phi:main::@18->main::@47]
    // main::@47
    // bank_set_brom(4)
    // [179] call bank_set_brom
    // [811] phi from main::@47 to bank_set_brom [phi:main::@47->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 4 [phi:main::@47->bank_set_brom#0] -- vbuz1=vbuc1 
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
    // [801] phi from main::@63 to wait_key [phi:main::@63->wait_key]
    jsr wait_key
    // main::SEI4
    // asm
    // asm { sei  }
    sei
    // main::@14
  __b14:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [184] main::flash_chip#1 = -- main::flash_chip#10 -- vbum1=_dec_vbum1 
    dec flash_chip
    // [104] phi from main::@14 to main::@11 [phi:main::@14->main::@11]
    // [104] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@14->main::@11#0] -- register_copy 
    jmp __b11
    // main::@17
  __b17:
    // table_chip_clear(flash_chip * 32)
    // [185] table_chip_clear::rom_bank#1 = main::flash_chip#10 << 5 -- vbuz1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta.z table_chip_clear.rom_bank
    // [186] call table_chip_clear
    // [898] phi from main::@17 to table_chip_clear [phi:main::@17->table_chip_clear]
    jsr table_chip_clear
    // [187] phi from main::@17 to main::@98 [phi:main::@17->main::@98]
    // main::@98
    // textcolor(WHITE)
    // [188] call textcolor
    // [504] phi from main::@98 to textcolor [phi:main::@98->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@98->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@99
    // flash_chip * 10
    // [189] main::$178 = main::flash_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda flash_chip
    asl
    asl
    sta.z __178
    // [190] main::$179 = main::$178 + main::flash_chip#10 -- vbuz1=vbuz1_plus_vbum2 
    lda flash_chip
    clc
    adc.z __179
    sta.z __179
    // [191] main::$64 = main::$179 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __64
    // gotoxy(2 + flash_chip * 10, 58)
    // [192] gotoxy::x#17 = 2 + main::$64 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __64
    sta.z gotoxy.x
    // [193] call gotoxy
    // [522] phi from main::@99 to gotoxy [phi:main::@99->gotoxy]
    // [522] phi gotoxy::y#24 = $3a [phi:main::@99->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = gotoxy::x#17 [phi:main::@99->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [194] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // printf("%s", file)
    // [195] call printf_string
    // [923] phi from main::@100 to printf_string [phi:main::@100->printf_string]
    // [923] phi printf_string::str#10 = main::buffer [phi:main::@100->printf_string#0] -- pbuz1=pbuc1 
    lda #<buffer
    sta.z printf_string.str
    lda #>buffer
    sta.z printf_string.str+1
    // [923] phi printf_string::format_justify_left#10 = 0 [phi:main::@100->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [923] phi printf_string::format_min_length#7 = 0 [phi:main::@100->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@101
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [196] print_chip_led::r#5 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [197] call print_chip_led
    // [878] phi from main::@101 to print_chip_led [phi:main::@101->print_chip_led]
    // [878] phi print_chip_led::tc#10 = CYAN [phi:main::@101->print_chip_led#0] -- vbuz1=vbuc1 
    lda #CYAN
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#5 [phi:main::@101->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [198] phi from main::@101 to main::@102 [phi:main::@101->main::@102]
    // main::@102
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [199] call snprintf_init
    jsr snprintf_init
    // [200] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [201] call printf_str
    // [750] phi from main::@103 to printf_str [phi:main::@103->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@103->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s5 [phi:main::@103->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@104
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [202] printf_uchar::uvalue#5 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [203] call printf_uchar
    // [830] phi from main::@104 to printf_uchar [phi:main::@104->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@104->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@104->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &snputc [phi:main::@104->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@104->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#5 [phi:main::@104->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [204] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [205] call printf_str
    // [750] phi from main::@105 to printf_str [phi:main::@105->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@105->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s6 [phi:main::@105->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@106
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
    // [794] phi from main::@106 to print_text [phi:main::@106->print_text]
    jsr print_text
    // main::@107
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [210] rom_address::rom_bank#2 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [211] call rom_address
    // [945] phi from main::@107 to rom_address [phi:main::@107->rom_address]
    // [945] phi rom_address::rom_bank#5 = rom_address::rom_bank#2 [phi:main::@107->rom_address#0] -- register_copy 
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
    // main::@108
    // [213] main::flash_rom_address_boundary#0 = rom_address::return#10
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [214] flash_read::fp#0 = main::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z flash_read.fp
    lda fp+1
    sta.z flash_read.fp+1
    // [215] flash_read::rom_bank_start#1 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z flash_read.rom_bank_start
    // [216] call flash_read
    // [949] phi from main::@108 to flash_read [phi:main::@108->flash_read]
    // [949] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@108->flash_read#0] -- register_copy 
    // [949] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@108->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [949] phi flash_read::rom_bank_size#2 = 1 [phi:main::@108->flash_read#2] -- vbuz1=vbuc1 
    lda #1
    sta.z flash_read.rom_bank_size
    // [949] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@108->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [217] flash_read::return#3 = flash_read::return#2
    // main::@109
    // [218] main::flash_bytes#0 = flash_read::return#3
    // rom_size(1)
    // [219] call rom_size
    // [985] phi from main::@109 to rom_size [phi:main::@109->rom_size]
    // [985] phi rom_size::rom_banks#2 = 1 [phi:main::@109->rom_size#0] -- vbuz1=vbuc1 
    lda #1
    sta.z rom_size.rom_banks
    jsr rom_size
    // rom_size(1)
    // [220] rom_size::return#3 = rom_size::return#0
    // main::@110
    // [221] main::$73 = rom_size::return#3
    // if (flash_bytes != rom_size(1))
    // [222] if(main::flash_bytes#0==main::$73) goto main::@19 -- vduz1_eq_vduz2_then_la1 
    lda.z flash_bytes
    cmp.z __73
    bne !+
    lda.z flash_bytes+1
    cmp.z __73+1
    bne !+
    lda.z flash_bytes+2
    cmp.z __73+2
    bne !+
    lda.z flash_bytes+3
    cmp.z __73+3
    beq __b19
  !:
    rts
    // main::@19
  __b19:
    // flash_rom_address_boundary += flash_bytes
    // [223] main::flash_rom_address_boundary#1 = main::flash_rom_address_boundary#0 + main::flash_bytes#0 -- vduz1=vduz2_plus_vduz3 
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
    // [224] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@58
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [225] flash_read::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbuz1=vbum2_plus_1 
    lda flash_rom_bank
    inc
    sta.z flash_read.rom_bank_start
    // [226] flash_read::fp#1 = main::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z flash_read.fp
    lda fp+1
    sta.z flash_read.fp+1
    // [227] call flash_read
    // [949] phi from main::@58 to flash_read [phi:main::@58->flash_read]
    // [949] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@58->flash_read#0] -- register_copy 
    // [949] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@58->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [949] phi flash_read::rom_bank_size#2 = $1f [phi:main::@58->flash_read#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z flash_read.rom_bank_size
    // [949] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@58->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [228] flash_read::return#4 = flash_read::return#2
    // main::@119
    // flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [229] main::flash_bytes#1 = flash_read::return#4 -- vdum1=vduz2 
    lda.z flash_read.return
    sta flash_bytes_1
    lda.z flash_read.return+1
    sta flash_bytes_1+1
    lda.z flash_read.return+2
    sta flash_bytes_1+2
    lda.z flash_read.return+3
    sta flash_bytes_1+3
    // flash_rom_address_boundary += flash_bytes
    // [230] main::flash_rom_address_boundary#11 = main::flash_rom_address_boundary#1 + main::flash_bytes#1 -- vdum1=vduz2_plus_vdum1 
    clc
    lda flash_rom_address_boundary_2
    adc.z flash_rom_address_boundary_1
    sta flash_rom_address_boundary_2
    lda flash_rom_address_boundary_2+1
    adc.z flash_rom_address_boundary_1+1
    sta flash_rom_address_boundary_2+1
    lda flash_rom_address_boundary_2+2
    adc.z flash_rom_address_boundary_1+2
    sta flash_rom_address_boundary_2+2
    lda flash_rom_address_boundary_2+3
    adc.z flash_rom_address_boundary_1+3
    sta flash_rom_address_boundary_2+3
    // fclose(fp)
    // [231] fclose::fp#0 = main::fp#0
    // [232] call fclose
    jsr fclose
    // main::bank_set_bram3
    // BRAM = bank
    // [233] BRAM = main::bank_set_bram3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram3_bank
    sta.z BRAM
    // [234] phi from main::bank_set_bram3 to main::@59 [phi:main::bank_set_bram3->main::@59]
    // main::@59
    // bank_set_brom(4)
    // [235] call bank_set_brom
    // [811] phi from main::@59 to bank_set_brom [phi:main::@59->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 4 [phi:main::@59->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [236] phi from main::@59 to main::@120 [phi:main::@59->main::@120]
    // main::@120
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [237] call snprintf_init
    jsr snprintf_init
    // [238] phi from main::@120 to main::@121 [phi:main::@120->main::@121]
    // main::@121
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [239] call printf_str
    // [750] phi from main::@121 to printf_str [phi:main::@121->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@121->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s10 [phi:main::@121->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@122
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [240] printf_uchar::uvalue#7 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [241] call printf_uchar
    // [830] phi from main::@122 to printf_uchar [phi:main::@122->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@122->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@122->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &snputc [phi:main::@122->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@122->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#7 [phi:main::@122->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [242] phi from main::@122 to main::@123 [phi:main::@122->main::@123]
    // main::@123
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [243] call printf_str
    // [750] phi from main::@123 to printf_str [phi:main::@123->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@123->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s11 [phi:main::@123->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@124
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [244] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [245] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [247] call print_text
    // [794] phi from main::@124 to print_text [phi:main::@124->print_text]
    jsr print_text
    // main::@125
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [248] rom_address::rom_bank#3 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [249] call rom_address
    // [945] phi from main::@125 to rom_address [phi:main::@125->rom_address]
    // [945] phi rom_address::rom_bank#5 = rom_address::rom_bank#3 [phi:main::@125->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [250] rom_address::return#11 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_3
    lda.z rom_address.return+1
    sta.z rom_address.return_3+1
    lda.z rom_address.return+2
    sta.z rom_address.return_3+2
    lda.z rom_address.return+3
    sta.z rom_address.return_3+3
    // main::@126
    // [251] main::flash_rom_address1#0 = rom_address::return#11
    // gotoxy(x, y)
    // [252] call gotoxy
    // [522] phi from main::@126 to gotoxy [phi:main::@126->gotoxy]
    // [522] phi gotoxy::y#24 = 4 [phi:main::@126->gotoxy#0] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = $e [phi:main::@126->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [254] phi from main::SEI2 to main::@20 [phi:main::SEI2->main::@20]
    // [254] phi main::y_sector#10 = 4 [phi:main::SEI2->main::@20#0] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector
    // [254] phi main::x_sector#10 = $e [phi:main::SEI2->main::@20#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [254] phi main::read_ram_address#10 = (char *) 16384 [phi:main::SEI2->main::@20#2] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address
    lda #>$4000
    sta.z read_ram_address+1
    // [254] phi main::read_ram_bank#13 = 0 [phi:main::SEI2->main::@20#3] -- vbuz1=vbuc1 
    lda #0
    sta.z read_ram_bank
    // [254] phi main::flash_rom_address1#13 = main::flash_rom_address1#0 [phi:main::SEI2->main::@20#4] -- register_copy 
    // [254] phi from main::@26 to main::@20 [phi:main::@26->main::@20]
    // [254] phi main::y_sector#10 = main::y_sector#10 [phi:main::@26->main::@20#0] -- register_copy 
    // [254] phi main::x_sector#10 = main::x_sector#1 [phi:main::@26->main::@20#1] -- register_copy 
    // [254] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@26->main::@20#2] -- register_copy 
    // [254] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@26->main::@20#3] -- register_copy 
    // [254] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@26->main::@20#4] -- register_copy 
    // main::@20
  __b20:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [255] if(main::flash_rom_address1#13<main::flash_rom_address_boundary#11) goto main::@21 -- vduz1_lt_vdum2_then_la1 
    lda.z flash_rom_address1+3
    cmp flash_rom_address_boundary_2+3
    bcs !__b21+
    jmp __b21
  !__b21:
    bne !+
    lda.z flash_rom_address1+2
    cmp flash_rom_address_boundary_2+2
    bcs !__b21+
    jmp __b21
  !__b21:
    bne !+
    lda.z flash_rom_address1+1
    cmp flash_rom_address_boundary_2+1
    bcs !__b21+
    jmp __b21
  !__b21:
    bne !+
    lda.z flash_rom_address1
    cmp flash_rom_address_boundary_2
    bcs !__b21+
    jmp __b21
  !__b21:
  !:
    // [256] phi from main::@20 to main::@22 [phi:main::@20->main::@22]
    // main::@22
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [257] call snprintf_init
    jsr snprintf_init
    // [258] phi from main::@22 to main::@128 [phi:main::@22->main::@128]
    // main::@128
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [259] call printf_str
    // [750] phi from main::@128 to printf_str [phi:main::@128->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@128->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s12 [phi:main::@128->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@129
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [260] printf_uchar::uvalue#8 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [261] call printf_uchar
    // [830] phi from main::@129 to printf_uchar [phi:main::@129->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@129->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@129->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &snputc [phi:main::@129->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@129->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#8 [phi:main::@129->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [262] phi from main::@129 to main::@130 [phi:main::@129->main::@130]
    // main::@130
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [263] call printf_str
    // [750] phi from main::@130 to printf_str [phi:main::@130->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@130->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s13 [phi:main::@130->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@131
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [264] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [265] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [267] call print_text
    // [794] phi from main::@131 to print_text [phi:main::@131->print_text]
    jsr print_text
    // [268] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // bank_set_brom(4)
    // [269] call bank_set_brom
    // [811] phi from main::@132 to bank_set_brom [phi:main::@132->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 4 [phi:main::@132->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [271] phi from main::CLI2 to main::@60 [phi:main::CLI2->main::@60]
    // main::@60
    // wait_key()
    // [272] call wait_key
    // [801] phi from main::@60 to wait_key [phi:main::@60->wait_key]
    jsr wait_key
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::@61
    // rom_address(flash_rom_bank)
    // [274] rom_address::rom_bank#4 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [275] call rom_address
    // [945] phi from main::@61 to rom_address [phi:main::@61->rom_address]
    // [945] phi rom_address::rom_bank#5 = rom_address::rom_bank#4 [phi:main::@61->rom_address#0] -- register_copy 
    jsr rom_address
    // rom_address(flash_rom_bank)
    // [276] rom_address::return#12 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_4
    lda.z rom_address.return+1
    sta.z rom_address.return_4+1
    lda.z rom_address.return+2
    sta.z rom_address.return_4+2
    lda.z rom_address.return+3
    sta.z rom_address.return_4+3
    // main::@133
    // flash_rom_address_sector = rom_address(flash_rom_bank)
    // [277] main::flash_rom_address_sector#1 = rom_address::return#12
    // textcolor(WHITE)
    // [278] call textcolor
    // [504] phi from main::@133 to textcolor [phi:main::@133->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@133->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@134
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [279] print_chip_led::r#7 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [280] call print_chip_led
    // [878] phi from main::@134 to print_chip_led [phi:main::@134->print_chip_led]
    // [878] phi print_chip_led::tc#10 = PURPLE [phi:main::@134->print_chip_led#0] -- vbuz1=vbuc1 
    lda #PURPLE
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#7 [phi:main::@134->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [281] phi from main::@134 to main::@135 [phi:main::@134->main::@135]
    // main::@135
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [282] call snprintf_init
    jsr snprintf_init
    // [283] phi from main::@135 to main::@136 [phi:main::@135->main::@136]
    // main::@136
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [284] call printf_str
    // [750] phi from main::@136 to printf_str [phi:main::@136->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@136->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s14 [phi:main::@136->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@137
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [285] printf_uchar::uvalue#9 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [286] call printf_uchar
    // [830] phi from main::@137 to printf_uchar [phi:main::@137->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@137->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@137->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &snputc [phi:main::@137->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@137->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#9 [phi:main::@137->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [287] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [288] call printf_str
    // [750] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s15 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [289] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [290] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [292] call print_text
    // [794] phi from main::@139 to print_text [phi:main::@139->print_text]
    jsr print_text
    // [293] phi from main::@139 to main::@29 [phi:main::@139->main::@29]
    // [293] phi main::flash_errors_sector#10 = 0 [phi:main::@139->main::@29#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [293] phi main::y_sector1#13 = 4 [phi:main::@139->main::@29#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector1
    // [293] phi main::x_sector1#10 = $e [phi:main::@139->main::@29#2] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector1
    // [293] phi main::read_ram_address_sector#10 = (char *) 16384 [phi:main::@139->main::@29#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address_sector
    lda #>$4000
    sta.z read_ram_address_sector+1
    // [293] phi main::read_ram_bank_sector#13 = 0 [phi:main::@139->main::@29#4] -- vbuz1=vbuc1 
    lda #0
    sta.z read_ram_bank_sector
    // [293] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#1 [phi:main::@139->main::@29#5] -- register_copy 
    // [293] phi from main::@40 to main::@29 [phi:main::@40->main::@29]
    // [293] phi main::flash_errors_sector#10 = main::flash_errors_sector#19 [phi:main::@40->main::@29#0] -- register_copy 
    // [293] phi main::y_sector1#13 = main::y_sector1#13 [phi:main::@40->main::@29#1] -- register_copy 
    // [293] phi main::x_sector1#10 = main::x_sector1#1 [phi:main::@40->main::@29#2] -- register_copy 
    // [293] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@40->main::@29#3] -- register_copy 
    // [293] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@40->main::@29#4] -- register_copy 
    // [293] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@40->main::@29#5] -- register_copy 
    // main::@29
  __b29:
    // while (flash_rom_address_sector < flash_rom_address_boundary)
    // [294] if(main::flash_rom_address_sector#11<main::flash_rom_address_boundary#11) goto main::@30 -- vduz1_lt_vdum2_then_la1 
    lda.z flash_rom_address_sector+3
    cmp flash_rom_address_boundary_2+3
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda.z flash_rom_address_sector+2
    cmp flash_rom_address_boundary_2+2
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda.z flash_rom_address_sector+1
    cmp flash_rom_address_boundary_2+1
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda.z flash_rom_address_sector
    cmp flash_rom_address_boundary_2
    bcs !__b30+
    jmp __b30
  !__b30:
  !:
    // main::bank_set_bram4
    // BRAM = bank
    // [295] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // [296] phi from main::bank_set_bram4 to main::@62 [phi:main::bank_set_bram4->main::@62]
    // main::@62
    // bank_set_brom(4)
    // [297] call bank_set_brom
    // [811] phi from main::@62 to bank_set_brom [phi:main::@62->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 4 [phi:main::@62->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@145
    // if (!flash_errors_sector)
    // [298] if(0==main::flash_errors_sector#10) goto main::@45 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    bne !__b45+
    jmp __b45
  !__b45:
    // [299] phi from main::@145 to main::@44 [phi:main::@145->main::@44]
    // main::@44
    // textcolor(RED)
    // [300] call textcolor
    // [504] phi from main::@44 to textcolor [phi:main::@44->textcolor]
    // [504] phi textcolor::color#24 = RED [phi:main::@44->textcolor#0] -- vbuz1=vbuc1 
    lda #RED
    sta.z textcolor.color
    jsr textcolor
    // [301] phi from main::@44 to main::@164 [phi:main::@44->main::@164]
    // main::@164
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [302] call snprintf_init
    jsr snprintf_init
    // [303] phi from main::@164 to main::@165 [phi:main::@164->main::@165]
    // main::@165
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [304] call printf_str
    // [750] phi from main::@165 to printf_str [phi:main::@165->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@165->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s17 [phi:main::@165->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@166
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [305] printf_uchar::uvalue#11 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [306] call printf_uchar
    // [830] phi from main::@166 to printf_uchar [phi:main::@166->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@166->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@166->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &snputc [phi:main::@166->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@166->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#11 [phi:main::@166->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [307] phi from main::@166 to main::@167 [phi:main::@166->main::@167]
    // main::@167
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [308] call printf_str
    // [750] phi from main::@167 to printf_str [phi:main::@167->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@167->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s20 [phi:main::@167->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@168
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [309] printf_uint::uvalue#2 = main::flash_errors_sector#10 -- vwuz1=vwuz2 
    lda.z flash_errors_sector
    sta.z printf_uint.uvalue
    lda.z flash_errors_sector+1
    sta.z printf_uint.uvalue+1
    // [310] call printf_uint
    // [1000] phi from main::@168 to printf_uint [phi:main::@168->printf_uint]
    // [1000] phi printf_uint::format_min_length#3 = 0 [phi:main::@168->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_min_length
    // [1000] phi printf_uint::putc#3 = &snputc [phi:main::@168->printf_uint#1] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1000] phi printf_uint::format_radix#3 = DECIMAL [phi:main::@168->printf_uint#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1000] phi printf_uint::uvalue#3 = printf_uint::uvalue#2 [phi:main::@168->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [311] phi from main::@168 to main::@169 [phi:main::@168->main::@169]
    // main::@169
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [312] call printf_str
    // [750] phi from main::@169 to printf_str [phi:main::@169->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@169->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s21 [phi:main::@169->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@170
    // sprintf(buffer, "the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [313] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [314] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [316] call print_text
    // [794] phi from main::@170 to print_text [phi:main::@170->print_text]
    jsr print_text
    // main::@171
    // print_chip_led(flash_chip, RED, BLUE)
    // [317] print_chip_led::r#9 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [318] call print_chip_led
    // [878] phi from main::@171 to print_chip_led [phi:main::@171->print_chip_led]
    // [878] phi print_chip_led::tc#10 = RED [phi:main::@171->print_chip_led#0] -- vbuz1=vbuc1 
    lda #RED
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#9 [phi:main::@171->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp __b18
    // [319] phi from main::@145 to main::@45 [phi:main::@145->main::@45]
    // main::@45
  __b45:
    // textcolor(GREEN)
    // [320] call textcolor
    // [504] phi from main::@45 to textcolor [phi:main::@45->textcolor]
    // [504] phi textcolor::color#24 = GREEN [phi:main::@45->textcolor#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z textcolor.color
    jsr textcolor
    // [321] phi from main::@45 to main::@158 [phi:main::@45->main::@158]
    // main::@158
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [322] call snprintf_init
    jsr snprintf_init
    // [323] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [324] call printf_str
    // [750] phi from main::@159 to printf_str [phi:main::@159->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@159->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s17 [phi:main::@159->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@160
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [325] printf_uchar::uvalue#10 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [326] call printf_uchar
    // [830] phi from main::@160 to printf_uchar [phi:main::@160->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@160->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@160->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &snputc [phi:main::@160->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = DECIMAL [phi:main::@160->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#10 [phi:main::@160->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [327] phi from main::@160 to main::@161 [phi:main::@160->main::@161]
    // main::@161
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [328] call printf_str
    // [750] phi from main::@161 to printf_str [phi:main::@161->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@161->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s18 [phi:main::@161->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@162
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [329] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [330] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [332] call print_text
    // [794] phi from main::@162 to print_text [phi:main::@162->print_text]
    jsr print_text
    // main::@163
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [333] print_chip_led::r#8 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [334] call print_chip_led
    // [878] phi from main::@163 to print_chip_led [phi:main::@163->print_chip_led]
    // [878] phi print_chip_led::tc#10 = GREEN [phi:main::@163->print_chip_led#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#8 [phi:main::@163->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp __b18
    // main::@30
  __b30:
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [335] flash_verify::bank_ram#1 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_verify.bank_ram
    // [336] flash_verify::ptr_ram#2 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address_sector+1
    sta.z flash_verify.ptr_ram+1
    // [337] flash_verify::verify_rom_address#1 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address_sector+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address_sector+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address_sector+3
    sta.z flash_verify.verify_rom_address+3
    // [338] call flash_verify
  // rom_sector_erase(flash_rom_address_sector);
    // [1010] phi from main::@30 to flash_verify [phi:main::@30->flash_verify]
    // [1010] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#2 [phi:main::@30->flash_verify#0] -- register_copy 
    // [1010] phi flash_verify::verify_rom_size#11 = $1000 [phi:main::@30->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z flash_verify.verify_rom_size
    lda #>$1000
    sta.z flash_verify.verify_rom_size+1
    // [1010] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#1 [phi:main::@30->flash_verify#2] -- register_copy 
    // [1010] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#1 [phi:main::@30->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [339] flash_verify::return#3 = flash_verify::correct_bytes#2
    // main::@144
    // [340] main::equal_bytes1#0 = flash_verify::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [341] if(main::equal_bytes1#0!=$1000) goto main::@32 -- vwuz1_neq_vwuc1_then_la1 
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
    // [342] phi from main::@144 to main::@41 [phi:main::@144->main::@41]
    // main::@41
    // textcolor(WHITE)
    // [343] call textcolor
    // [504] phi from main::@41 to textcolor [phi:main::@41->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@41->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@146
    // gotoxy(x_sector, y_sector)
    // [344] gotoxy::x#21 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z gotoxy.x
    // [345] gotoxy::y#21 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [346] call gotoxy
    // [522] phi from main::@146 to gotoxy [phi:main::@146->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#21 [phi:main::@146->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = gotoxy::x#21 [phi:main::@146->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [347] phi from main::@146 to main::@147 [phi:main::@146->main::@147]
    // main::@147
    // printf("%s", pattern)
    // [348] call printf_string
    // [923] phi from main::@147 to printf_string [phi:main::@147->printf_string]
    // [923] phi printf_string::str#10 = main::pattern1#1 [phi:main::@147->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern1_1
    sta.z printf_string.str
    lda #>pattern1_1
    sta.z printf_string.str+1
    // [923] phi printf_string::format_justify_left#10 = 0 [phi:main::@147->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [923] phi printf_string::format_min_length#7 = 0 [phi:main::@147->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [349] phi from main::@147 main::@38 to main::@31 [phi:main::@147/main::@38->main::@31]
    // [349] phi main::flash_errors_sector#19 = main::flash_errors_sector#10 [phi:main::@147/main::@38->main::@31#0] -- register_copy 
    // main::@31
  __b31:
    // read_ram_address_sector += ROM_SECTOR
    // [350] main::read_ram_address_sector#2 = main::read_ram_address_sector#10 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address_sector
    clc
    adc #<$1000
    sta.z read_ram_address_sector
    lda.z read_ram_address_sector+1
    adc #>$1000
    sta.z read_ram_address_sector+1
    // flash_rom_address_sector += ROM_SECTOR
    // [351] main::flash_rom_address_sector#10 = main::flash_rom_address_sector#11 + $1000 -- vduz1=vduz1_plus_vwuc1 
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
    // [352] if(main::read_ram_address_sector#2!=$8000) goto main::@179 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$8000
    bne __b39
    lda.z read_ram_address_sector
    cmp #<$8000
    bne __b39
    // [354] phi from main::@31 to main::@39 [phi:main::@31->main::@39]
    // [354] phi main::read_ram_bank_sector#6 = 1 [phi:main::@31->main::@39#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank_sector
    // [354] phi main::read_ram_address_sector#8 = (char *) 40960 [phi:main::@31->main::@39#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [353] phi from main::@31 to main::@179 [phi:main::@31->main::@179]
    // main::@179
    // [354] phi from main::@179 to main::@39 [phi:main::@179->main::@39]
    // [354] phi main::read_ram_bank_sector#6 = main::read_ram_bank_sector#13 [phi:main::@179->main::@39#0] -- register_copy 
    // [354] phi main::read_ram_address_sector#8 = main::read_ram_address_sector#2 [phi:main::@179->main::@39#1] -- register_copy 
    // main::@39
  __b39:
    // if (read_ram_address_sector == 0xC000)
    // [355] if(main::read_ram_address_sector#8!=$c000) goto main::@40 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$c000
    bne __b40
    lda.z read_ram_address_sector
    cmp #<$c000
    bne __b40
    // main::@42
    // read_ram_bank_sector++;
    // [356] main::read_ram_bank_sector#3 = ++ main::read_ram_bank_sector#6 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank_sector
    // [357] phi from main::@42 to main::@40 [phi:main::@42->main::@40]
    // [357] phi main::read_ram_address_sector#14 = (char *) 40960 [phi:main::@42->main::@40#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [357] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#3 [phi:main::@42->main::@40#1] -- register_copy 
    // [357] phi from main::@39 to main::@40 [phi:main::@39->main::@40]
    // [357] phi main::read_ram_address_sector#14 = main::read_ram_address_sector#8 [phi:main::@39->main::@40#0] -- register_copy 
    // [357] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#6 [phi:main::@39->main::@40#1] -- register_copy 
    // main::@40
  __b40:
    // x_sector += 16
    // [358] main::x_sector1#1 = main::x_sector1#10 + $10 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$10
    clc
    adc.z x_sector1
    sta.z x_sector1
    // flash_rom_address_sector % 0x4000
    // [359] main::$137 = main::flash_rom_address_sector#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [360] if(0!=main::$137) goto main::@29 -- 0_neq_vduz1_then_la1 
    lda.z __137
    ora.z __137+1
    ora.z __137+2
    ora.z __137+3
    beq !__b29+
    jmp __b29
  !__b29:
    // main::@43
    // y_sector++;
    // [361] main::y_sector1#1 = ++ main::y_sector1#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector1
    // [293] phi from main::@43 to main::@29 [phi:main::@43->main::@29]
    // [293] phi main::flash_errors_sector#10 = main::flash_errors_sector#19 [phi:main::@43->main::@29#0] -- register_copy 
    // [293] phi main::y_sector1#13 = main::y_sector1#1 [phi:main::@43->main::@29#1] -- register_copy 
    // [293] phi main::x_sector1#10 = $e [phi:main::@43->main::@29#2] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector1
    // [293] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@43->main::@29#3] -- register_copy 
    // [293] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@43->main::@29#4] -- register_copy 
    // [293] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@43->main::@29#5] -- register_copy 
    jmp __b29
    // [362] phi from main::@144 to main::@32 [phi:main::@144->main::@32]
  __b8:
    // [362] phi main::flash_errors#10 = 0 [phi:main::@144->main::@32#0] -- vbuz1=vbuc1 
    lda #0
    sta.z flash_errors
    // [362] phi main::retries#10 = 0 [phi:main::@144->main::@32#1] -- vbuz1=vbuc1 
    sta.z retries
    // [362] phi from main::@177 to main::@32 [phi:main::@177->main::@32]
    // [362] phi main::flash_errors#10 = main::flash_errors#11 [phi:main::@177->main::@32#0] -- register_copy 
    // [362] phi main::retries#10 = main::retries#1 [phi:main::@177->main::@32#1] -- register_copy 
    // main::@32
  __b32:
    // rom_sector_erase(flash_rom_address_sector)
    // [363] rom_sector_erase::address#0 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z rom_sector_erase.address
    lda.z flash_rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda.z flash_rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda.z flash_rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [364] call rom_sector_erase
    jsr rom_sector_erase
    // main::@148
    // unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR
    // [365] main::flash_rom_address_boundary1#0 = main::flash_rom_address_sector#11 + $1000 -- vduz1=vduz2_plus_vwuc1 
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
    // [366] gotoxy::x#22 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z gotoxy.x
    // [367] gotoxy::y#22 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [368] call gotoxy
    // [522] phi from main::@148 to gotoxy [phi:main::@148->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#22 [phi:main::@148->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = gotoxy::x#22 [phi:main::@148->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [369] phi from main::@148 to main::@149 [phi:main::@148->main::@149]
    // main::@149
    // printf("................")
    // [370] call printf_str
    // [750] phi from main::@149 to printf_str [phi:main::@149->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:main::@149->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s16 [phi:main::@149->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@150
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [371] print_address::bram_bank#1 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z print_address.bram_bank
    // [372] print_address::bram_ptr#1 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z print_address.bram_ptr
    lda.z read_ram_address_sector+1
    sta.z print_address.bram_ptr+1
    // [373] print_address::brom_address#1 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z print_address.brom_address
    lda.z flash_rom_address_sector+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address_sector+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address_sector+3
    sta.z print_address.brom_address+3
    // [374] call print_address
    // [1046] phi from main::@150 to print_address [phi:main::@150->print_address]
    // [1046] phi print_address::bram_ptr#10 = print_address::bram_ptr#1 [phi:main::@150->print_address#0] -- register_copy 
    // [1046] phi print_address::bram_bank#3 = print_address::bram_bank#1 [phi:main::@150->print_address#1] -- register_copy 
    // [1046] phi print_address::brom_address#10 = print_address::brom_address#1 [phi:main::@150->print_address#2] -- register_copy 
    jsr print_address
    // main::@151
    // [375] main::flash_rom_address2#16 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_rom_address2
    lda.z flash_rom_address_sector+1
    sta.z flash_rom_address2+1
    lda.z flash_rom_address_sector+2
    sta.z flash_rom_address2+2
    lda.z flash_rom_address_sector+3
    sta.z flash_rom_address2+3
    // [376] main::read_ram_address1#16 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z read_ram_address1
    lda.z read_ram_address_sector+1
    sta.z read_ram_address1+1
    // [377] main::x1#16 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z x1
    // [378] phi from main::@151 main::@157 to main::@33 [phi:main::@151/main::@157->main::@33]
    // [378] phi main::x1#10 = main::x1#16 [phi:main::@151/main::@157->main::@33#0] -- register_copy 
    // [378] phi main::flash_errors#11 = main::flash_errors#10 [phi:main::@151/main::@157->main::@33#1] -- register_copy 
    // [378] phi main::read_ram_address1#10 = main::read_ram_address1#16 [phi:main::@151/main::@157->main::@33#2] -- register_copy 
    // [378] phi main::flash_rom_address2#11 = main::flash_rom_address2#16 [phi:main::@151/main::@157->main::@33#3] -- register_copy 
    // main::@33
  __b33:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [379] if(main::flash_rom_address2#11<main::flash_rom_address_boundary1#0) goto main::@34 -- vduz1_lt_vduz2_then_la1 
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
    // [380] main::retries#1 = ++ main::retries#10 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors && retries <= 3)
    // [381] if(0==main::flash_errors#11) goto main::@38 -- 0_eq_vbuz1_then_la1 
    lda.z flash_errors
    beq __b38
    // main::@177
    // [382] if(main::retries#1<3+1) goto main::@32 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b32+
    jmp __b32
  !__b32:
    // main::@38
  __b38:
    // flash_errors_sector += flash_errors
    // [383] main::flash_errors_sector#1 = main::flash_errors_sector#10 + main::flash_errors#11 -- vwuz1=vwuz1_plus_vbuz2 
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
    // [384] print_address::bram_bank#2 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z print_address.bram_bank
    // [385] print_address::bram_ptr#2 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z print_address.bram_ptr
    lda.z read_ram_address1+1
    sta.z print_address.bram_ptr+1
    // [386] print_address::brom_address#2 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z print_address.brom_address
    lda.z flash_rom_address2+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address2+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address2+3
    sta.z print_address.brom_address+3
    // [387] call print_address
    // [1046] phi from main::@34 to print_address [phi:main::@34->print_address]
    // [1046] phi print_address::bram_ptr#10 = print_address::bram_ptr#2 [phi:main::@34->print_address#0] -- register_copy 
    // [1046] phi print_address::bram_bank#3 = print_address::bram_bank#2 [phi:main::@34->print_address#1] -- register_copy 
    // [1046] phi print_address::brom_address#10 = print_address::brom_address#2 [phi:main::@34->print_address#2] -- register_copy 
    jsr print_address
    // main::@152
    // unsigned long written_bytes = flash_write(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address)
    // [388] flash_write::flash_ram_bank#0 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_write.flash_ram_bank
    // [389] flash_write::flash_ram_address#1 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_write.flash_ram_address
    lda.z read_ram_address1+1
    sta.z flash_write.flash_ram_address+1
    // [390] flash_write::flash_rom_address#1 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z flash_write.flash_rom_address
    lda.z flash_rom_address2+1
    sta.z flash_write.flash_rom_address+1
    lda.z flash_rom_address2+2
    sta.z flash_write.flash_rom_address+2
    lda.z flash_rom_address2+3
    sta.z flash_write.flash_rom_address+3
    // [391] call flash_write
    jsr flash_write
    // main::@153
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [392] flash_verify::bank_ram#2 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_verify.bank_ram
    // [393] flash_verify::ptr_ram#3 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address1+1
    sta.z flash_verify.ptr_ram+1
    // [394] flash_verify::verify_rom_address#2 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address2+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address2+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address2+3
    sta.z flash_verify.verify_rom_address+3
    // [395] call flash_verify
    // [1010] phi from main::@153 to flash_verify [phi:main::@153->flash_verify]
    // [1010] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#3 [phi:main::@153->flash_verify#0] -- register_copy 
    // [1010] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@153->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    // [1010] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#2 [phi:main::@153->flash_verify#2] -- register_copy 
    // [1010] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#2 [phi:main::@153->flash_verify#3] -- register_copy 
    jsr flash_verify
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [396] flash_verify::return#4 = flash_verify::correct_bytes#2
    // main::@154
    // equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [397] main::equal_bytes1#1 = flash_verify::return#4
    // if (equal_bytes != 0x0100)
    // [398] if(main::equal_bytes1#1!=$100) goto main::@36 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes1+1
    cmp #>$100
    bne __b36
    lda.z equal_bytes1
    cmp #<$100
    bne __b36
    // [400] phi from main::@154 to main::@37 [phi:main::@154->main::@37]
    // [400] phi main::flash_errors#12 = main::flash_errors#11 [phi:main::@154->main::@37#0] -- register_copy 
    // [400] phi main::pattern1#5 = main::pattern1#3 [phi:main::@154->main::@37#1] -- pbuz1=pbuc1 
    lda #<pattern1_3
    sta.z pattern1
    lda #>pattern1_3
    sta.z pattern1+1
    jmp __b37
    // main::@36
  __b36:
    // flash_errors++;
    // [399] main::flash_errors#1 = ++ main::flash_errors#11 -- vbuz1=_inc_vbuz1 
    inc.z flash_errors
    // [400] phi from main::@36 to main::@37 [phi:main::@36->main::@37]
    // [400] phi main::flash_errors#12 = main::flash_errors#1 [phi:main::@36->main::@37#0] -- register_copy 
    // [400] phi main::pattern1#5 = main::pattern1#2 [phi:main::@36->main::@37#1] -- pbuz1=pbuc1 
    lda #<pattern1_2
    sta.z pattern1
    lda #>pattern1_2
    sta.z pattern1+1
    // main::@37
  __b37:
    // read_ram_address += 0x0100
    // [401] main::read_ram_address1#1 = main::read_ram_address1#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address1
    clc
    adc #<$100
    sta.z read_ram_address1
    lda.z read_ram_address1+1
    adc #>$100
    sta.z read_ram_address1+1
    // flash_rom_address += 0x0100
    // [402] main::flash_rom_address2#1 = main::flash_rom_address2#11 + $100 -- vduz1=vduz1_plus_vwuc1 
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
    // [403] call textcolor
    // [504] phi from main::@37 to textcolor [phi:main::@37->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@37->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@155
    // gotoxy(x, y)
    // [404] gotoxy::x#23 = main::x1#10 -- vbuz1=vbuz2 
    lda.z x1
    sta.z gotoxy.x
    // [405] gotoxy::y#23 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [406] call gotoxy
    // [522] phi from main::@155 to gotoxy [phi:main::@155->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#23 [phi:main::@155->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = gotoxy::x#23 [phi:main::@155->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@156
    // printf("%s", pattern)
    // [407] printf_string::str#6 = main::pattern1#5
    // [408] call printf_string
    // [923] phi from main::@156 to printf_string [phi:main::@156->printf_string]
    // [923] phi printf_string::str#10 = printf_string::str#6 [phi:main::@156->printf_string#0] -- register_copy 
    // [923] phi printf_string::format_justify_left#10 = 0 [phi:main::@156->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [923] phi printf_string::format_min_length#7 = 0 [phi:main::@156->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@157
    // x++;
    // [409] main::x1#1 = ++ main::x1#10 -- vbuz1=_inc_vbuz1 
    inc.z x1
    jmp __b33
    // main::@21
  __b21:
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [410] flash_verify::bank_ram#0 = main::read_ram_bank#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank
    sta.z flash_verify.bank_ram
    // [411] flash_verify::ptr_ram#1 = main::read_ram_address#10 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address+1
    sta.z flash_verify.ptr_ram+1
    // [412] flash_verify::verify_rom_address#0 = main::flash_rom_address1#13 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address1+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address1+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address1+3
    sta.z flash_verify.verify_rom_address+3
    // [413] call flash_verify
    // [1010] phi from main::@21 to flash_verify [phi:main::@21->flash_verify]
    // [1010] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#1 [phi:main::@21->flash_verify#0] -- register_copy 
    // [1010] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@21->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    // [1010] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#0 [phi:main::@21->flash_verify#2] -- register_copy 
    // [1010] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#0 [phi:main::@21->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [414] flash_verify::return#2 = flash_verify::correct_bytes#2
    // main::@127
    // [415] main::equal_bytes#0 = flash_verify::return#2
    // if (equal_bytes != 0x0100)
    // [416] if(main::equal_bytes#0!=$100) goto main::@23 -- vwuz1_neq_vwuc1_then_la1 
    // unsigned long equal_bytes = 0x100;
    lda.z equal_bytes+1
    cmp #>$100
    bne __b23
    lda.z equal_bytes
    cmp #<$100
    bne __b23
    // [418] phi from main::@127 to main::@24 [phi:main::@127->main::@24]
    // [418] phi main::pattern#3 = main::pattern#2 [phi:main::@127->main::@24#0] -- pbuz1=pbuc1 
    lda #<pattern_2
    sta.z pattern
    lda #>pattern_2
    sta.z pattern+1
    jmp __b24
    // [417] phi from main::@127 to main::@23 [phi:main::@127->main::@23]
    // main::@23
  __b23:
    // [418] phi from main::@23 to main::@24 [phi:main::@23->main::@24]
    // [418] phi main::pattern#3 = main::pattern#1 [phi:main::@23->main::@24#0] -- pbuz1=pbuc1 
    lda #<pattern_1
    sta.z pattern
    lda #>pattern_1
    sta.z pattern+1
    // main::@24
  __b24:
    // read_ram_address += 0x0100
    // [419] main::read_ram_address#1 = main::read_ram_address#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address
    clc
    adc #<$100
    sta.z read_ram_address
    lda.z read_ram_address+1
    adc #>$100
    sta.z read_ram_address+1
    // flash_rom_address += 0x0100
    // [420] main::flash_rom_address1#1 = main::flash_rom_address1#13 + $100 -- vduz1=vduz1_plus_vwuc1 
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
    // [421] print_address::bram_bank#0 = main::read_ram_bank#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank
    sta.z print_address.bram_bank
    // [422] print_address::bram_ptr#0 = main::read_ram_address#1 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z print_address.bram_ptr
    lda.z read_ram_address+1
    sta.z print_address.bram_ptr+1
    // [423] print_address::brom_address#0 = main::flash_rom_address1#1 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z print_address.brom_address
    lda.z flash_rom_address1+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address1+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address1+3
    sta.z print_address.brom_address+3
    // [424] call print_address
    // [1046] phi from main::@24 to print_address [phi:main::@24->print_address]
    // [1046] phi print_address::bram_ptr#10 = print_address::bram_ptr#0 [phi:main::@24->print_address#0] -- register_copy 
    // [1046] phi print_address::bram_bank#3 = print_address::bram_bank#0 [phi:main::@24->print_address#1] -- register_copy 
    // [1046] phi print_address::brom_address#10 = print_address::brom_address#0 [phi:main::@24->print_address#2] -- register_copy 
    jsr print_address
    // [425] phi from main::@24 to main::@140 [phi:main::@24->main::@140]
    // main::@140
    // textcolor(WHITE)
    // [426] call textcolor
    // [504] phi from main::@140 to textcolor [phi:main::@140->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@140->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@141
    // gotoxy(x_sector, y_sector)
    // [427] gotoxy::x#20 = main::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z gotoxy.x
    // [428] gotoxy::y#20 = main::y_sector#10 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z gotoxy.y
    // [429] call gotoxy
    // [522] phi from main::@141 to gotoxy [phi:main::@141->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#20 [phi:main::@141->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = gotoxy::x#20 [phi:main::@141->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@142
    // printf("%s", pattern)
    // [430] printf_string::str#4 = main::pattern#3 -- pbuz1=pbuz2 
    lda.z pattern
    sta.z printf_string.str
    lda.z pattern+1
    sta.z printf_string.str+1
    // [431] call printf_string
    // [923] phi from main::@142 to printf_string [phi:main::@142->printf_string]
    // [923] phi printf_string::str#10 = printf_string::str#4 [phi:main::@142->printf_string#0] -- register_copy 
    // [923] phi printf_string::format_justify_left#10 = 0 [phi:main::@142->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [923] phi printf_string::format_min_length#7 = 0 [phi:main::@142->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@143
    // x_sector++;
    // [432] main::x_sector#1 = ++ main::x_sector#10 -- vbuz1=_inc_vbuz1 
    inc.z x_sector
    // if (read_ram_address == 0x8000)
    // [433] if(main::read_ram_address#1!=$8000) goto main::@178 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$8000
    bne __b25
    lda.z read_ram_address
    cmp #<$8000
    bne __b25
    // [435] phi from main::@143 to main::@25 [phi:main::@143->main::@25]
    // [435] phi main::read_ram_bank#5 = 1 [phi:main::@143->main::@25#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank
    // [435] phi main::read_ram_address#7 = (char *) 40960 [phi:main::@143->main::@25#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [434] phi from main::@143 to main::@178 [phi:main::@143->main::@178]
    // main::@178
    // [435] phi from main::@178 to main::@25 [phi:main::@178->main::@25]
    // [435] phi main::read_ram_bank#5 = main::read_ram_bank#13 [phi:main::@178->main::@25#0] -- register_copy 
    // [435] phi main::read_ram_address#7 = main::read_ram_address#1 [phi:main::@178->main::@25#1] -- register_copy 
    // main::@25
  __b25:
    // if (read_ram_address == 0xC000)
    // [436] if(main::read_ram_address#7!=$c000) goto main::@26 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$c000
    bne __b26
    lda.z read_ram_address
    cmp #<$c000
    bne __b26
    // main::@27
    // read_ram_bank++;
    // [437] main::read_ram_bank#2 = ++ main::read_ram_bank#5 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank
    // [438] phi from main::@27 to main::@26 [phi:main::@27->main::@26]
    // [438] phi main::read_ram_address#12 = (char *) 40960 [phi:main::@27->main::@26#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [438] phi main::read_ram_bank#10 = main::read_ram_bank#2 [phi:main::@27->main::@26#1] -- register_copy 
    // [438] phi from main::@25 to main::@26 [phi:main::@25->main::@26]
    // [438] phi main::read_ram_address#12 = main::read_ram_address#7 [phi:main::@25->main::@26#0] -- register_copy 
    // [438] phi main::read_ram_bank#10 = main::read_ram_bank#5 [phi:main::@25->main::@26#1] -- register_copy 
    // main::@26
  __b26:
    // flash_rom_address % 0x4000
    // [439] main::$98 = main::flash_rom_address1#1 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [440] if(0!=main::$98) goto main::@20 -- 0_neq_vduz1_then_la1 
    lda.z __98
    ora.z __98+1
    ora.z __98+2
    ora.z __98+3
    beq !__b20+
    jmp __b20
  !__b20:
    // main::@28
    // y_sector++;
    // [441] main::y_sector#1 = ++ main::y_sector#10 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [254] phi from main::@28 to main::@20 [phi:main::@28->main::@20]
    // [254] phi main::y_sector#10 = main::y_sector#1 [phi:main::@28->main::@20#0] -- register_copy 
    // [254] phi main::x_sector#10 = $e [phi:main::@28->main::@20#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [254] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@28->main::@20#2] -- register_copy 
    // [254] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@28->main::@20#3] -- register_copy 
    // [254] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@28->main::@20#4] -- register_copy 
    jmp __b20
    // [442] phi from main::@90 to main::@15 [phi:main::@90->main::@15]
    // main::@15
  __b15:
    // sprintf(file, "rom.bin", flash_chip)
    // [443] call snprintf_init
    jsr snprintf_init
    // [444] phi from main::@15 to main::@91 [phi:main::@15->main::@91]
    // main::@91
    // sprintf(file, "rom.bin", flash_chip)
    // [445] call printf_str
    // [750] phi from main::@91 to printf_str [phi:main::@91->printf_str]
    // [750] phi printf_str::putc#33 = &snputc [phi:main::@91->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = main::s2 [phi:main::@91->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@92
    // sprintf(file, "rom.bin", flash_chip)
    // [446] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [447] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b16
    // main::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [449] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [450] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0x90)
    // [451] rom_unlock::address#3 = main::flash_rom_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda flash_rom_address
    adc #<$5555
    sta.z rom_unlock.address
    lda flash_rom_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda flash_rom_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda flash_rom_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [452] call rom_unlock
    // [1090] phi from main::@2 to rom_unlock [phi:main::@2->rom_unlock]
    // [1090] phi rom_unlock::unlock_code#5 = $90 [phi:main::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1090] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:main::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // main::@72
    // rom_read_byte(flash_rom_address)
    // [453] rom_read_byte::address#0 = main::flash_rom_address#10 -- vduz1=vdum2 
    lda flash_rom_address
    sta.z rom_read_byte.address
    lda flash_rom_address+1
    sta.z rom_read_byte.address+1
    lda flash_rom_address+2
    sta.z rom_read_byte.address+2
    lda flash_rom_address+3
    sta.z rom_read_byte.address+3
    // [454] call rom_read_byte
    // [1100] phi from main::@72 to rom_read_byte [phi:main::@72->rom_read_byte]
    // [1100] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:main::@72->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(flash_rom_address)
    // [455] rom_read_byte::return#2 = rom_read_byte::return#0
    // main::@73
    // [456] main::$20 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(flash_rom_address)
    // [457] main::rom_manufacturer_ids[main::rom_chip#10] = main::$20 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z __20
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(flash_rom_address + 1)
    // [458] rom_read_byte::address#1 = main::flash_rom_address#10 + 1 -- vduz1=vdum2_plus_1 
    lda flash_rom_address
    clc
    adc #1
    sta.z rom_read_byte.address
    lda flash_rom_address+1
    adc #0
    sta.z rom_read_byte.address+1
    lda flash_rom_address+2
    adc #0
    sta.z rom_read_byte.address+2
    lda flash_rom_address+3
    adc #0
    sta.z rom_read_byte.address+3
    // [459] call rom_read_byte
    // [1100] phi from main::@73 to rom_read_byte [phi:main::@73->rom_read_byte]
    // [1100] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:main::@73->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(flash_rom_address + 1)
    // [460] rom_read_byte::return#3 = rom_read_byte::return#0
    // main::@74
    // [461] main::$22 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(flash_rom_address + 1)
    // [462] main::rom_device_ids[main::rom_chip#10] = main::$22 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z __22
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0xF0)
    // [463] rom_unlock::address#4 = main::flash_rom_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda flash_rom_address
    adc #<$5555
    sta.z rom_unlock.address
    lda flash_rom_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda flash_rom_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda flash_rom_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [464] call rom_unlock
    // [1090] phi from main::@74 to rom_unlock [phi:main::@74->rom_unlock]
    // [1090] phi rom_unlock::unlock_code#5 = $f0 [phi:main::@74->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1090] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:main::@74->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // [465] phi from main::@74 to main::@75 [phi:main::@74->main::@75]
    // main::@75
    // bank_set_brom(4)
    // [466] call bank_set_brom
  // Ensure the ROM is set to BASIC.
    // [811] phi from main::@75 to bank_set_brom [phi:main::@75->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 4 [phi:main::@75->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@76
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_KB(rom_chip, "128");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             break;
    // [467] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip
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
    //             break;
    // [468] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    //             break;
    // [469] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b5+
    jmp __b5
  !__b5:
    // main::@6
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [470] print_chip_led::r#4 = main::rom_chip#10 -- vbuz1=vbum2 
    tya
    sta.z print_chip_led.r
    // [471] call print_chip_led
    // [878] phi from main::@6 to print_chip_led [phi:main::@6->print_chip_led]
    // [878] phi print_chip_led::tc#10 = BLACK [phi:main::@6->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#4 [phi:main::@6->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@83
    // rom_device_ids[rom_chip] = UNKNOWN
    // [472] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // [473] phi from main::@83 to main::@7 [phi:main::@83->main::@7]
    // [473] phi main::rom_device#5 = main::rom_device#13 [phi:main::@83->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_4
    sta rom_device
    lda #>rom_device_4
    sta rom_device+1
    // main::@7
  __b7:
    // textcolor(WHITE)
    // [474] call textcolor
    // [504] phi from main::@7 to textcolor [phi:main::@7->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:main::@7->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@84
    // rom_chip * 10
    // [475] main::$175 = main::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z __175
    // [476] main::$176 = main::$175 + main::rom_chip#10 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z __176
    sta.z __176
    // [477] main::$38 = main::$176 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __38
    // gotoxy(2 + rom_chip * 10, 56)
    // [478] gotoxy::x#14 = 2 + main::$38 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __38
    sta.z gotoxy.x
    // [479] call gotoxy
    // [522] phi from main::@84 to gotoxy [phi:main::@84->gotoxy]
    // [522] phi gotoxy::y#24 = $38 [phi:main::@84->gotoxy#0] -- vbuz1=vbuc1 
    lda #$38
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = gotoxy::x#14 [phi:main::@84->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@85
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [480] printf_uchar::uvalue#3 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_manufacturer_ids,y
    sta.z printf_uchar.uvalue
    // [481] call printf_uchar
    // [830] phi from main::@85 to printf_uchar [phi:main::@85->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:main::@85->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 0 [phi:main::@85->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &cputc [phi:main::@85->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = HEXADECIMAL [phi:main::@85->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#3 [phi:main::@85->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // main::@86
    // gotoxy(2 + rom_chip * 10, 57)
    // [482] gotoxy::x#15 = 2 + main::$38 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z __38
    sta.z gotoxy.x
    // [483] call gotoxy
    // [522] phi from main::@86 to gotoxy [phi:main::@86->gotoxy]
    // [522] phi gotoxy::y#24 = $39 [phi:main::@86->gotoxy#0] -- vbuz1=vbuc1 
    lda #$39
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = gotoxy::x#15 [phi:main::@86->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@87
    // printf("%s", rom_device)
    // [484] printf_string::str#2 = main::rom_device#5 -- pbuz1=pbum2 
    lda rom_device
    sta.z printf_string.str
    lda rom_device+1
    sta.z printf_string.str+1
    // [485] call printf_string
    // [923] phi from main::@87 to printf_string [phi:main::@87->printf_string]
    // [923] phi printf_string::str#10 = printf_string::str#2 [phi:main::@87->printf_string#0] -- register_copy 
    // [923] phi printf_string::format_justify_left#10 = 0 [phi:main::@87->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [923] phi printf_string::format_min_length#7 = 0 [phi:main::@87->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@88
    // rom_chip++;
    // [486] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // main::@8
    // flash_rom_address += 0x80000
    // [487] main::flash_rom_address#1 = main::flash_rom_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [91] phi from main::@8 to main::@1 [phi:main::@8->main::@1]
    // [91] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@8->main::@1#0] -- register_copy 
    // [91] phi main::flash_rom_address#10 = main::flash_rom_address#1 [phi:main::@8->main::@1#1] -- register_copy 
    jmp __b1
    // main::@5
  __b5:
    // print_chip_KB(rom_chip, "512")
    // [488] print_chip_KB::rom_chip#2 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_KB.rom_chip
    // [489] call print_chip_KB
    // [1112] phi from main::@5 to print_chip_KB [phi:main::@5->print_chip_KB]
    // [1112] phi print_chip_KB::kb#3 = main::kb2 [phi:main::@5->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb2
    sta.z print_chip_KB.kb
    lda #>kb2
    sta.z print_chip_KB.kb+1
    // [1112] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#2 [phi:main::@5->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@82
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [490] print_chip_led::r#3 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_led.r
    // [491] call print_chip_led
    // [878] phi from main::@82 to print_chip_led [phi:main::@82->print_chip_led]
    // [878] phi print_chip_led::tc#10 = WHITE [phi:main::@82->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#3 [phi:main::@82->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [473] phi from main::@82 to main::@7 [phi:main::@82->main::@7]
    // [473] phi main::rom_device#5 = main::rom_device#12 [phi:main::@82->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_3
    sta rom_device
    lda #>rom_device_3
    sta rom_device+1
    jmp __b7
    // main::@4
  __b4:
    // print_chip_KB(rom_chip, "256")
    // [492] print_chip_KB::rom_chip#1 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_KB.rom_chip
    // [493] call print_chip_KB
    // [1112] phi from main::@4 to print_chip_KB [phi:main::@4->print_chip_KB]
    // [1112] phi print_chip_KB::kb#3 = main::kb1 [phi:main::@4->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb1
    sta.z print_chip_KB.kb
    lda #>kb1
    sta.z print_chip_KB.kb+1
    // [1112] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#1 [phi:main::@4->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@81
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [494] print_chip_led::r#2 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_led.r
    // [495] call print_chip_led
    // [878] phi from main::@81 to print_chip_led [phi:main::@81->print_chip_led]
    // [878] phi print_chip_led::tc#10 = WHITE [phi:main::@81->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#2 [phi:main::@81->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [473] phi from main::@81 to main::@7 [phi:main::@81->main::@7]
    // [473] phi main::rom_device#5 = main::rom_device#11 [phi:main::@81->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_2
    sta rom_device
    lda #>rom_device_2
    sta rom_device+1
    jmp __b7
    // main::@3
  __b3:
    // print_chip_KB(rom_chip, "128")
    // [496] print_chip_KB::rom_chip#0 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_KB.rom_chip
    // [497] call print_chip_KB
    // [1112] phi from main::@3 to print_chip_KB [phi:main::@3->print_chip_KB]
    // [1112] phi print_chip_KB::kb#3 = main::kb [phi:main::@3->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb
    sta.z print_chip_KB.kb
    lda #>kb
    sta.z print_chip_KB.kb+1
    // [1112] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#0 [phi:main::@3->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@80
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [498] print_chip_led::r#1 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_led.r
    // [499] call print_chip_led
    // [878] phi from main::@80 to print_chip_led [phi:main::@80->print_chip_led]
    // [878] phi print_chip_led::tc#10 = WHITE [phi:main::@80->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#1 [phi:main::@80->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [473] phi from main::@80 to main::@7 [phi:main::@80->main::@7]
    // [473] phi main::rom_device#5 = main::rom_device#1 [phi:main::@80->main::@7#0] -- pbum1=pbuc1 
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
    rom_chip: .byte 0
    flash_rom_address: .dword 0
    flash_chip: .byte 0
    flash_rom_bank: .byte 0
    fp: .word 0
    flash_bytes_1: .dword 0
    w: .word 0
    rom_device: .word 0
    .label flash_rom_address_boundary_2 = flash_bytes_1
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [500] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [501] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [502] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [503] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($b0) char color)
textcolor: {
    .label __0 = $b1
    .label __1 = $b0
    .label color = $b0
    // __conio.color & 0xF0
    // [505] textcolor::$0 = *((char *)&__conio+$b) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$b
    sta.z __0
    // __conio.color & 0xF0 | color
    // [506] textcolor::$1 = textcolor::$0 | textcolor::color#24 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z __1
    ora.z __0
    sta.z __1
    // __conio.color = __conio.color & 0xF0 | color
    // [507] *((char *)&__conio+$b) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$b
    // textcolor::@return
    // }
    // [508] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($b0) char color)
bgcolor: {
    .label __0 = $c7
    .label __1 = $b0
    .label __2 = $c7
    .label color = $b0
    // __conio.color & 0x0F
    // [510] bgcolor::$0 = *((char *)&__conio+$b) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$b
    sta.z __0
    // color << 4
    // [511] bgcolor::$1 = bgcolor::color#11 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z __1
    asl
    asl
    asl
    asl
    sta.z __1
    // __conio.color & 0x0F | color << 4
    // [512] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z __2
    ora.z __1
    sta.z __2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [513] *((char *)&__conio+$b) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$b
    // bgcolor::@return
    // }
    // [514] return 
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
    // [515] *((char *)&__conio+$a) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$a
    // cursor::@return
    // }
    // [516] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $da
    // __mem unsigned char x
    // [517] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [518] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [520] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [521] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($7f) char x, __zp($aa) char y)
gotoxy: {
    .label __2 = $7f
    .label __3 = $7f
    .label __6 = $7c
    .label __7 = $7c
    .label __8 = $ad
    .label __9 = $ab
    .label __10 = $aa
    .label x = $7f
    .label y = $aa
    .label __14 = $7c
    // (x>=__conio.width)?__conio.width:x
    // [523] if(gotoxy::x#24>=*((char *)&__conio+4)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+4
    bcs __b1
    // [525] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [525] phi gotoxy::$3 = gotoxy::x#24 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [524] gotoxy::$2 = *((char *)&__conio+4) -- vbuz1=_deref_pbuc1 
    lda __conio+4
    sta.z __2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [526] *((char *)&__conio+$d) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z __3
    sta __conio+$d
    // (y>=__conio.height)?__conio.height:y
    // [527] if(gotoxy::y#24>=*((char *)&__conio+5)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+5
    bcs __b3
    // gotoxy::@4
    // [528] gotoxy::$14 = gotoxy::y#24 -- vbuz1=vbuz2 
    sta.z __14
    // [529] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [529] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [530] *((char *)&__conio+$e) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z __7
    sta __conio+$e
    // __conio.cursor_x << 1
    // [531] gotoxy::$8 = *((char *)&__conio+$d) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$d
    asl
    sta.z __8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [532] gotoxy::$10 = gotoxy::y#24 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __10
    // [533] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z __10
    clc
    adc __conio+$15,y
    sta.z __9
    lda __conio+$15+1,y
    adc #0
    sta.z __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [534] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z __9
    sta __conio+$13
    lda.z __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [535] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [536] gotoxy::$6 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z __6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label __2 = $b2
    // __conio.cursor_x = 0
    // [537] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y++;
    // [538] *((char *)&__conio+$e) = ++ *((char *)&__conio+$e) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$e
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [539] cputln::$2 = *((char *)&__conio+$e) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    sta.z __2
    // [540] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [541] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [542] return 
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
    // [544] return 
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
    // [545] ((char *)&__conio+$f)[*((char *)&__conio)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio
    sta __conio+$f,y
    // scroll::@return
    // }
    // [546] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label __0 = $47
    .label __1 = $51
    .label __2 = $ae
    .label line_text = $79
    .label l = $4b
    .label ch = $79
    .label c = $4e
    // unsigned int line_text = __conio.mapbase_offset
    // [547] clrscr::line_text#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z line_text
    lda __conio+1+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [548] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [549] clrscr::$0 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [550] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [551] clrscr::l#0 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z l
    // [552] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [552] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [552] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [553] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z __1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [554] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [555] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z __2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [556] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [557] clrscr::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [558] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [558] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [559] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [560] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [561] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [562] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [563] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+8
    sta.z line_text
    lda.z line_text+1
    adc __conio+8+1
    sta.z line_text+1
    // l--;
    // [564] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [565] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [566] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y = 0
    // [567] *((char *)&__conio+$e) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+$e
    // __conio.offset = __conio.mapbase_offset
    // [568] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+1) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+1
    sta __conio+$13
    lda __conio+1+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [569] return 
    rts
}
  // frame_draw
frame_draw: {
    .label x = $4b
    .label x1 = $4e
    .label y = $46
    .label x2 = $54
    .label y_1 = $2b
    .label x3 = $af
    .label y_2 = $55
    .label x4 = $37
    .label y_3 = $bc
    .label x5 = $32
    // textcolor(WHITE)
    // [571] call textcolor
    // [504] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [572] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [573] call bgcolor
    // [509] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [574] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [575] call clrscr
    jsr clrscr
    // [576] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [576] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [577] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [578] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [579] call cputcxy
    // [1172] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [1172] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbuz1=vbuc1 
    sta.z cputcxy.x
    jsr cputcxy
    // [580] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [581] call cputcxy
    // [1172] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [1172] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [582] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [583] call cputcxy
    // [1172] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbuz1=vbuc1 
    lda #1
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // [584] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [585] call cputcxy
    // [1172] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbuz1=vbuc1 
    lda #1
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [586] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [586] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [587] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [588] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [589] call cputcxy
    // [1172] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [1172] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // [590] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [591] call cputcxy
    // [1172] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [1172] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [592] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [593] call cputcxy
    // [1172] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [1172] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // [594] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [594] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbuz1=vbuc1 
    lda #3
    sta.z y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [595] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [596] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [596] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [597] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [598] cputcxy::y#13 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [599] call cputcxy
    // [1172] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [1172] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [600] cputcxy::y#14 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [601] call cputcxy
    // [1172] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [1172] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [602] cputcxy::y#15 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [603] call cputcxy
    // [1172] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [1172] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [604] frame_draw::y#5 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [605] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [605] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [606] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [607] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [607] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [608] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [609] cputcxy::y#19 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [610] call cputcxy
    // [1172] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [1172] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [611] cputcxy::y#20 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [612] call cputcxy
    // [1172] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [1172] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [613] cputcxy::y#21 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [614] call cputcxy
    // [1172] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [1172] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [615] cputcxy::y#22 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [616] call cputcxy
    // [1172] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [1172] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [617] cputcxy::y#23 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [618] call cputcxy
    // [1172] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [1172] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [619] cputcxy::y#24 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [620] call cputcxy
    // [1172] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [1172] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [621] cputcxy::y#25 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [622] call cputcxy
    // [1172] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [1172] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [623] cputcxy::y#26 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [624] call cputcxy
    // [1172] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [1172] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [625] cputcxy::y#27 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [626] call cputcxy
    // [1172] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [1172] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [627] cputcxy::y#28 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [628] call cputcxy
    // [1172] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [1172] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [629] frame_draw::y#7 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz2 
    lda.z y_1
    inc
    sta.z y_2
    // [630] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [630] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [631] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [632] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [632] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [633] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [634] cputcxy::y#39 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [635] call cputcxy
    // [1172] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [1172] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [636] cputcxy::y#40 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [637] call cputcxy
    // [1172] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [1172] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [638] cputcxy::y#41 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [639] call cputcxy
    // [1172] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [1172] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [640] cputcxy::y#42 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [641] call cputcxy
    // [1172] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [1172] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [642] cputcxy::y#43 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [643] call cputcxy
    // [1172] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [1172] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [644] cputcxy::y#44 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [645] call cputcxy
    // [1172] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [1172] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [646] cputcxy::y#45 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [647] call cputcxy
    // [1172] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [1172] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [648] cputcxy::y#46 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [649] call cputcxy
    // [1172] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [1172] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [650] cputcxy::y#47 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [651] call cputcxy
    // [1172] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [1172] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [652] frame_draw::y#9 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz2 
    lda.z y_2
    inc
    sta.z y_3
    // [653] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [653] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [654] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [655] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [655] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [656] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x5
    cmp #$4f
    bcs !__b25+
    jmp __b25
  !__b25:
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [657] cputcxy::y#58 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [658] call cputcxy
    // [1172] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [1172] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [659] cputcxy::y#59 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [660] call cputcxy
    // [1172] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [1172] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [661] cputcxy::y#60 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [662] call cputcxy
    // [1172] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [1172] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [663] cputcxy::y#61 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [664] call cputcxy
    // [1172] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [1172] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [665] cputcxy::y#62 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [666] call cputcxy
    // [1172] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [1172] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [667] cputcxy::y#63 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [668] call cputcxy
    // [1172] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [1172] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [669] cputcxy::y#64 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [670] call cputcxy
    // [1172] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [1172] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [671] cputcxy::y#65 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [672] call cputcxy
    // [1172] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [1172] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [673] cputcxy::y#66 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [674] call cputcxy
    // [1172] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [1172] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [675] cputcxy::y#67 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [676] call cputcxy
    // [1172] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [1172] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@return
    // }
    // [677] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [678] cputcxy::x#57 = frame_draw::x5#2 -- vbuz1=vbuz2 
    lda.z x5
    sta.z cputcxy.x
    // [679] cputcxy::y#57 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [680] call cputcxy
    // [1172] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [1172] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [681] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbuz1=_inc_vbuz1 
    inc.z x5
    // [655] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [655] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [682] cputcxy::y#48 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [683] call cputcxy
    // [1172] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [684] cputcxy::y#49 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [685] call cputcxy
    // [1172] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [686] cputcxy::y#50 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [687] call cputcxy
    // [1172] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [688] cputcxy::y#51 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [689] call cputcxy
    // [1172] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [690] cputcxy::y#52 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [691] call cputcxy
    // [1172] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [692] cputcxy::y#53 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [693] call cputcxy
    // [1172] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [694] cputcxy::y#54 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [695] call cputcxy
    // [1172] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [696] cputcxy::y#55 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [697] call cputcxy
    // [1172] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [698] cputcxy::y#56 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [699] call cputcxy
    // [1172] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [700] frame_draw::y#10 = ++ frame_draw::y#106 -- vbuz1=_inc_vbuz1 
    inc.z y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [701] cputcxy::x#38 = frame_draw::x4#2 -- vbuz1=vbuz2 
    lda.z x4
    sta.z cputcxy.x
    // [702] cputcxy::y#38 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [703] call cputcxy
    // [1172] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [1172] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [704] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbuz1=_inc_vbuz1 
    inc.z x4
    // [632] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [632] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [705] cputcxy::y#29 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [706] call cputcxy
    // [1172] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [707] cputcxy::y#30 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [708] call cputcxy
    // [1172] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [709] cputcxy::y#31 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [710] call cputcxy
    // [1172] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [711] cputcxy::y#32 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [712] call cputcxy
    // [1172] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [713] cputcxy::y#33 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [714] call cputcxy
    // [1172] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [715] cputcxy::y#34 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [716] call cputcxy
    // [1172] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [717] cputcxy::y#35 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [718] call cputcxy
    // [1172] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [719] cputcxy::y#36 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [720] call cputcxy
    // [1172] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [721] cputcxy::y#37 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [722] call cputcxy
    // [1172] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [723] frame_draw::y#8 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz1 
    inc.z y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [724] cputcxy::x#18 = frame_draw::x3#2 -- vbuz1=vbuz2 
    lda.z x3
    sta.z cputcxy.x
    // [725] cputcxy::y#18 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [726] call cputcxy
    // [1172] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [1172] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [727] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbuz1=_inc_vbuz1 
    inc.z x3
    // [607] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [607] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [728] cputcxy::y#16 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [729] call cputcxy
    // [1172] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [730] cputcxy::y#17 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [731] call cputcxy
    // [1172] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [732] frame_draw::y#6 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [733] cputcxy::x#12 = frame_draw::x2#2 -- vbuz1=vbuz2 
    lda.z x2
    sta.z cputcxy.x
    // [734] cputcxy::y#12 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [735] call cputcxy
    // [1172] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [1172] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [736] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbuz1=_inc_vbuz1 
    inc.z x2
    // [596] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [596] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [737] cputcxy::y#9 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [738] call cputcxy
    // [1172] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [739] cputcxy::y#10 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [740] call cputcxy
    // [1172] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [741] cputcxy::y#11 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [742] call cputcxy
    // [1172] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [1172] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [1172] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [743] frame_draw::y#4 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [594] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [594] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [744] cputcxy::x#5 = frame_draw::x1#2 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [745] call cputcxy
    // [1172] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [1172] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [746] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbuz1=_inc_vbuz1 
    inc.z x1
    // [586] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [586] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [747] cputcxy::x#0 = frame_draw::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [748] call cputcxy
    // [1172] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [1172] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1172] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1172] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [749] frame_draw::x#1 = ++ frame_draw::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [576] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [576] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
    jmp __b1
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($79) void (*putc)(char), __zp($3e) const char *s)
printf_str: {
    .label c = $47
    .label s = $3e
    .label putc = $79
    // [751] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [751] phi printf_str::s#32 = printf_str::s#33 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [752] printf_str::c#1 = *printf_str::s#32 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [753] printf_str::s#0 = ++ printf_str::s#32 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [754] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [755] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [756] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [757] callexecute *printf_str::putc#33  -- call__deref_pprz1 
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
    .label __4 = $51
    .label r = $4a
    .label __33 = $51
    .label __34 = $51
    // [760] phi from print_chips to print_chips::@1 [phi:print_chips->print_chips::@1]
    // [760] phi print_chips::r#10 = 0 [phi:print_chips->print_chips::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // print_chips::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [761] if(print_chips::r#10<8) goto print_chips::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // print_chips::@return
    // }
    // [762] return 
    rts
    // print_chips::@2
  __b2:
    // r * 10
    // [763] print_chips::$33 = print_chips::r#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z r
    asl
    asl
    sta.z __33
    // [764] print_chips::$34 = print_chips::$33 + print_chips::r#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z __34
    clc
    adc.z r
    sta.z __34
    // [765] print_chips::$4 = print_chips::$34 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __4
    // print_chip_line(3 + r * 10, 45, ' ')
    // [766] print_chip_line::x#0 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [767] call print_chip_line
    // [1180] phi from print_chips::@2 to print_chip_line [phi:print_chips::@2->print_chip_line]
    // [1180] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@2->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1180] phi print_chip_line::y#12 = $2d [phi:print_chips::@2->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2d
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#0 [phi:print_chips::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@3
    // print_chip_line(3 + r * 10, 46, 'r')
    // [768] print_chip_line::x#1 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [769] call print_chip_line
    // [1180] phi from print_chips::@3 to print_chip_line [phi:print_chips::@3->print_chip_line]
    // [1180] phi print_chip_line::c#12 = 'r'pm [phi:print_chips::@3->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'r'
    sta.z print_chip_line.c
    // [1180] phi print_chip_line::y#12 = $2e [phi:print_chips::@3->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2e
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#1 [phi:print_chips::@3->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@4
    // print_chip_line(3 + r * 10, 47, 'o')
    // [770] print_chip_line::x#2 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [771] call print_chip_line
    // [1180] phi from print_chips::@4 to print_chip_line [phi:print_chips::@4->print_chip_line]
    // [1180] phi print_chip_line::c#12 = 'o'pm [phi:print_chips::@4->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'o'
    sta.z print_chip_line.c
    // [1180] phi print_chip_line::y#12 = $2f [phi:print_chips::@4->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2f
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#2 [phi:print_chips::@4->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@5
    // print_chip_line(3 + r * 10, 48, 'm')
    // [772] print_chip_line::x#3 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [773] call print_chip_line
    // [1180] phi from print_chips::@5 to print_chip_line [phi:print_chips::@5->print_chip_line]
    // [1180] phi print_chip_line::c#12 = 'm'pm [phi:print_chips::@5->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'m'
    sta.z print_chip_line.c
    // [1180] phi print_chip_line::y#12 = $30 [phi:print_chips::@5->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$30
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#3 [phi:print_chips::@5->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@6
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [774] print_chip_line::x#4 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [775] print_chip_line::c#4 = '0'pm + print_chips::r#10 -- vbuz1=vbuc1_plus_vbuz2 
    lda #'0'
    clc
    adc.z r
    sta.z print_chip_line.c
    // [776] call print_chip_line
    // [1180] phi from print_chips::@6 to print_chip_line [phi:print_chips::@6->print_chip_line]
    // [1180] phi print_chip_line::c#12 = print_chip_line::c#4 [phi:print_chips::@6->print_chip_line#0] -- register_copy 
    // [1180] phi print_chip_line::y#12 = $31 [phi:print_chips::@6->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#4 [phi:print_chips::@6->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@7
    // print_chip_line(3 + r * 10, 50, ' ')
    // [777] print_chip_line::x#5 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [778] call print_chip_line
    // [1180] phi from print_chips::@7 to print_chip_line [phi:print_chips::@7->print_chip_line]
    // [1180] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@7->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1180] phi print_chip_line::y#12 = $32 [phi:print_chips::@7->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$32
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#5 [phi:print_chips::@7->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@8
    // print_chip_line(3 + r * 10, 51, ' ')
    // [779] print_chip_line::x#6 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [780] call print_chip_line
    // [1180] phi from print_chips::@8 to print_chip_line [phi:print_chips::@8->print_chip_line]
    // [1180] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@8->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1180] phi print_chip_line::y#12 = $33 [phi:print_chips::@8->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$33
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#6 [phi:print_chips::@8->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@9
    // print_chip_line(3 + r * 10, 52, ' ')
    // [781] print_chip_line::x#7 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [782] call print_chip_line
    // [1180] phi from print_chips::@9 to print_chip_line [phi:print_chips::@9->print_chip_line]
    // [1180] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@9->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1180] phi print_chip_line::y#12 = $34 [phi:print_chips::@9->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$34
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#7 [phi:print_chips::@9->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@10
    // print_chip_line(3 + r * 10, 53, ' ')
    // [783] print_chip_line::x#8 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __4
    sta.z print_chip_line.x
    // [784] call print_chip_line
    // [1180] phi from print_chips::@10 to print_chip_line [phi:print_chips::@10->print_chip_line]
    // [1180] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@10->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1180] phi print_chip_line::y#12 = $35 [phi:print_chips::@10->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$35
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#8 [phi:print_chips::@10->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@11
    // print_chip_end(3 + r * 10, 54)
    // [785] print_chip_end::x#0 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z print_chip_end.x
    sta.z print_chip_end.x
    // [786] call print_chip_end
    jsr print_chip_end
    // print_chips::@12
    // print_chip_led(r, BLACK, BLUE)
    // [787] print_chip_led::r#0 = print_chips::r#10 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_chip_led.r
    // [788] call print_chip_led
    // [878] phi from print_chips::@12 to print_chip_led [phi:print_chips::@12->print_chip_led]
    // [878] phi print_chip_led::tc#10 = BLACK [phi:print_chips::@12->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [878] phi print_chip_led::r#10 = print_chip_led::r#0 [phi:print_chips::@12->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // print_chips::@13
    // for (unsigned char r = 0; r < 8; r++)
    // [789] print_chips::r#1 = ++ print_chips::r#10 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [760] phi from print_chips::@13 to print_chips::@1 [phi:print_chips::@13->print_chips::@1]
    // [760] phi print_chips::r#10 = print_chips::r#1 [phi:print_chips::@13->print_chips::@1#0] -- register_copy 
    jmp __b1
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [790] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [791] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [792] __snprintf_buffer = main::buffer -- pbum1=pbuc1 
    lda #<main.buffer
    sta __snprintf_buffer
    lda #>main.buffer
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [793] return 
    rts
}
  // print_text
// void print_text(char *text)
print_text: {
    // textcolor(WHITE)
    // [795] call textcolor
    // [504] phi from print_text to textcolor [phi:print_text->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:print_text->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [796] phi from print_text to print_text::@1 [phi:print_text->print_text::@1]
    // print_text::@1
    // gotoxy(2, 39)
    // [797] call gotoxy
    // [522] phi from print_text::@1 to gotoxy [phi:print_text::@1->gotoxy]
    // [522] phi gotoxy::y#24 = $27 [phi:print_text::@1->gotoxy#0] -- vbuz1=vbuc1 
    lda #$27
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = 2 [phi:print_text::@1->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [798] phi from print_text::@1 to print_text::@2 [phi:print_text::@1->print_text::@2]
    // print_text::@2
    // printf("%-76s", text)
    // [799] call printf_string
    // [923] phi from print_text::@2 to printf_string [phi:print_text::@2->printf_string]
    // [923] phi printf_string::str#10 = main::buffer [phi:print_text::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z printf_string.str
    lda #>main.buffer
    sta.z printf_string.str+1
    // [923] phi printf_string::format_justify_left#10 = 1 [phi:print_text::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [923] phi printf_string::format_min_length#7 = $4c [phi:print_text::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #$4c
    sta.z printf_string.format_min_length
    jsr printf_string
    // print_text::@return
    // }
    // [800] return 
    rts
}
  // wait_key
// Some addressing constants.
// The different device IDs that can be returned from the manufacturer ID read sequence.
// To print the graphics on the vera.
wait_key: {
    .const bank_set_bram1_bank = 0
    .label return = $ae
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [802] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [803] phi from wait_key::bank_set_bram1 to wait_key::@2 [phi:wait_key::bank_set_bram1->wait_key::@2]
    // wait_key::@2
    // bank_set_brom(4)
    // [804] call bank_set_brom
    // [811] phi from wait_key::@2 to bank_set_brom [phi:wait_key::@2->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 4 [phi:wait_key::@2->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [805] phi from wait_key::@2 wait_key::@3 to wait_key::@1 [phi:wait_key::@2/wait_key::@3->wait_key::@1]
    // wait_key::@1
  __b1:
    // getin()
    // [806] call getin
    jsr getin
    // [807] getin::return#2 = getin::return#1
    // wait_key::@3
    // [808] wait_key::return#0 = getin::return#2
    // while (!(ch = getin()))
    // [809] if(0==wait_key::return#0) goto wait_key::@1 -- 0_eq_vbuz1_then_la1 
    lda.z return
    beq __b1
    // wait_key::@return
    // }
    // [810] return 
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
// void bank_set_brom(__zp($46) char bank)
bank_set_brom: {
    .label bank = $46
    // BROM = bank
    // [812] BROM = bank_set_brom::bank#12 -- vbuz1=vbuz2 
    lda.z bank
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [813] return 
    rts
}
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [815] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [816] phi from system_reset::bank_set_bram1 to system_reset::@1 [phi:system_reset::bank_set_bram1->system_reset::@1]
    // system_reset::@1
    // bank_set_brom(0)
    // [817] call bank_set_brom
    // [811] phi from system_reset::@1 to bank_set_brom [phi:system_reset::@1->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = 0 [phi:system_reset::@1->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #0
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [819] return 
}
  // printf_sint
// Print a signed integer using a specific format
// void printf_sint(void (*putc)(char), __zp($28) int value, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_sint: {
    .const format_min_length = 0
    .const format_justify_left = 0
    .const format_zero_padding = 0
    .const format_upper_case = 0
    .label putc = snputc
    .label value = $28
    // printf_buffer.sign = 0
    // [820] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // if(value<0)
    // [821] if(printf_sint::value#1<0) goto printf_sint::@1 -- vwsz1_lt_0_then_la1 
    lda.z value+1
    bmi __b1
    // [824] phi from printf_sint printf_sint::@1 to printf_sint::@2 [phi:printf_sint/printf_sint::@1->printf_sint::@2]
    // [824] phi printf_sint::value#4 = printf_sint::value#1 [phi:printf_sint/printf_sint::@1->printf_sint::@2#0] -- register_copy 
    jmp __b2
    // printf_sint::@1
  __b1:
    // value = -value
    // [822] printf_sint::value#0 = - printf_sint::value#1 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z value
    sta.z value
    lda #0
    sbc.z value+1
    sta.z value+1
    // printf_buffer.sign = '-'
    // [823] *((char *)&printf_buffer) = '-'pm -- _deref_pbuc1=vbuc2 
    lda #'-'
    sta printf_buffer
    // printf_sint::@2
  __b2:
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [825] utoa::value#1 = (unsigned int)printf_sint::value#4
    // [826] call utoa
    // [1243] phi from printf_sint::@2 to utoa [phi:printf_sint::@2->utoa]
    // [1243] phi utoa::value#10 = utoa::value#1 [phi:printf_sint::@2->utoa#0] -- register_copy 
    // [1243] phi utoa::radix#2 = DECIMAL [phi:printf_sint::@2->utoa#1] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z utoa.radix
    jsr utoa
    // printf_sint::@3
    // printf_number_buffer(putc, printf_buffer, format)
    // [827] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [828] call printf_number_buffer
  // Print using format
    // [1274] phi from printf_sint::@3 to printf_number_buffer [phi:printf_sint::@3->printf_number_buffer]
    // [1274] phi printf_number_buffer::format_upper_case#10 = printf_sint::format_upper_case#0 [phi:printf_sint::@3->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #format_upper_case
    sta.z printf_number_buffer.format_upper_case
    // [1274] phi printf_number_buffer::putc#10 = printf_sint::putc#0 [phi:printf_sint::@3->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [1274] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_sint::@3->printf_number_buffer#2] -- register_copy 
    // [1274] phi printf_number_buffer::format_zero_padding#10 = printf_sint::format_zero_padding#0 [phi:printf_sint::@3->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #format_zero_padding
    sta.z printf_number_buffer.format_zero_padding
    // [1274] phi printf_number_buffer::format_justify_left#10 = printf_sint::format_justify_left#0 [phi:printf_sint::@3->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #format_justify_left
    sta.z printf_number_buffer.format_justify_left
    // [1274] phi printf_number_buffer::format_min_length#4 = printf_sint::format_min_length#0 [phi:printf_sint::@3->printf_number_buffer#5] -- vbuz1=vbuc1 
    lda #format_min_length
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_sint::@return
    // }
    // [829] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($6d) void (*putc)(char), __zp($27) char uvalue, __zp($2b) char format_min_length, char format_justify_left, char format_sign_always, __zp($af) char format_zero_padding, char format_upper_case, __zp($54) char format_radix)
printf_uchar: {
    .label uvalue = $27
    .label format_radix = $54
    .label putc = $6d
    .label format_min_length = $2b
    .label format_zero_padding = $af
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [831] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [832] uctoa::value#1 = printf_uchar::uvalue#12
    // [833] uctoa::radix#0 = printf_uchar::format_radix#12
    // [834] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [835] printf_number_buffer::putc#3 = printf_uchar::putc#12
    // [836] printf_number_buffer::buffer_sign#3 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [837] printf_number_buffer::format_min_length#3 = printf_uchar::format_min_length#12
    // [838] printf_number_buffer::format_zero_padding#3 = printf_uchar::format_zero_padding#12
    // [839] call printf_number_buffer
  // Print using format
    // [1274] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1274] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1274] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#3 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1274] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#3 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1274] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#3 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [1274] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [1274] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#3 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [840] return 
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
// __zp($79) struct $1 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label __4 = $27
    .label __7 = $73
    .label __11 = $bc
    .label fp = $79
    .label return = $79
    .label __32 = $bc
    .label __33 = $bc
    // FILE *fp = &__files[__filecount]
    // [841] fopen::$32 = __filecount << 2 -- vbuz1=vbum2_rol_2 
    lda __filecount
    asl
    asl
    sta.z __32
    // [842] fopen::$33 = fopen::$32 + __filecount -- vbuz1=vbuz1_plus_vbum2 
    lda __filecount
    clc
    adc.z __33
    sta.z __33
    // [843] fopen::$11 = fopen::$33 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z __11
    asl
    asl
    sta.z __11
    // [844] fopen::fp#0 = __files + fopen::$11 -- pssz1=pssc1_plus_vbuz2 
    clc
    adc #<__files
    sta.z fp
    lda #>__files
    adc #0
    sta.z fp+1
    // fp->status = 0
    // [845] ((char *)fopen::fp#0)[$13] = 0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #0
    ldy #$13
    sta (fp),y
    // fp->channel = channel
    // [846] ((char *)fopen::fp#0)[$10] = fopen::channel#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #channel
    ldy #$10
    sta (fp),y
    // fp->device = device
    // [847] ((char *)fopen::fp#0)[$11] = fopen::device#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #device
    ldy #$11
    sta (fp),y
    // fp->secondary = secondary
    // [848] ((char *)fopen::fp#0)[$12] = fopen::secondary#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #secondary
    ldy #$12
    sta (fp),y
    // strncpy(fp->filename, filename, 16)
    // [849] strncpy::dst#1 = (char *)fopen::fp#0 -- pbuz1=pbuz2 
    lda.z fp
    sta.z strncpy.dst
    lda.z fp+1
    sta.z strncpy.dst+1
    // [850] call strncpy
    // [1343] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@5
    // cbm_k_setnam(filename)
    // [851] cbm_k_setnam::filename = main::buffer -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z cbm_k_setnam.filename
    lda #>main.buffer
    sta.z cbm_k_setnam.filename+1
    // [852] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@6
    // cbm_k_setlfs(channel, device, secondary)
    // [853] cbm_k_setlfs::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_setlfs.channel
    // [854] cbm_k_setlfs::device = fopen::device#0 -- vbuz1=vbuc1 
    lda #device
    sta.z cbm_k_setlfs.device
    // [855] cbm_k_setlfs::command = fopen::secondary#0 -- vbuz1=vbuc1 
    lda #secondary
    sta.z cbm_k_setlfs.command
    // [856] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [857] phi from fopen::@6 to fopen::@7 [phi:fopen::@6->fopen::@7]
    // fopen::@7
    // cbm_k_open()
    // [858] call cbm_k_open
    jsr cbm_k_open
    // [859] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@8
    // [860] fopen::$4 = cbm_k_open::return#2
    // fp->status = cbm_k_open()
    // [861] ((char *)fopen::fp#0)[$13] = fopen::$4 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __4
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [862] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // fopen::@3
    // cbm_k_close(channel)
    // [863] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [864] call cbm_k_close
    jsr cbm_k_close
    // [865] phi from fopen::@3 fopen::@4 to fopen::@return [phi:fopen::@3/fopen::@4->fopen::@return]
  __b3:
    // [865] phi fopen::return#1 = 0 [phi:fopen::@3/fopen::@4->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [866] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [867] cbm_k_chkin::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_chkin.channel
    // [868] call cbm_k_chkin
    jsr cbm_k_chkin
    // [869] phi from fopen::@1 to fopen::@9 [phi:fopen::@1->fopen::@9]
    // fopen::@9
    // cbm_k_readst()
    // [870] call cbm_k_readst
    jsr cbm_k_readst
    // [871] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@10
    // [872] fopen::$7 = cbm_k_readst::return#2
    // fp->status = cbm_k_readst()
    // [873] ((char *)fopen::fp#0)[$13] = fopen::$7 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __7
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [874] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@2 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b2
    // fopen::@4
    // cbm_k_close(channel)
    // [875] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [876] call cbm_k_close
    jsr cbm_k_close
    jmp __b3
    // fopen::@2
  __b2:
    // __filecount++;
    // [877] __filecount = ++ __filecount -- vbum1=_inc_vbum1 
    inc __filecount
    // [865] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [865] phi fopen::return#1 = fopen::fp#0 [phi:fopen::@2->fopen::@return#0] -- register_copy 
    rts
}
  // print_chip_led
// void print_chip_led(__zp($55) char r, __zp($ae) char tc, char bc)
print_chip_led: {
    .label __0 = $55
    .label r = $55
    .label tc = $ae
    .label __8 = $bc
    .label __9 = $55
    // r * 10
    // [879] print_chip_led::$8 = print_chip_led::r#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z r
    asl
    asl
    sta.z __8
    // [880] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#10 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z __9
    clc
    adc.z __8
    sta.z __9
    // [881] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __0
    // gotoxy(4 + r * 10, 43)
    // [882] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbuz1=vbuc1_plus_vbuz2 
    lda #4
    clc
    adc.z __0
    sta.z gotoxy.x
    // [883] call gotoxy
    // [522] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [522] phi gotoxy::y#24 = $2b [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #$2b
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [884] textcolor::color#8 = print_chip_led::tc#10 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [885] call textcolor
    // [504] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [504] phi textcolor::color#24 = textcolor::color#8 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [886] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [887] call bgcolor
    // [509] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [888] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [889] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [891] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [892] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [894] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [895] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [897] return 
    rts
}
  // table_chip_clear
// void table_chip_clear(__zp($63) char rom_bank)
table_chip_clear: {
    .label flash_rom_address = $38
    .label rom_bank = $63
    .label y = $73
    // textcolor(WHITE)
    // [899] call textcolor
    // [504] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:table_chip_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [900] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [901] call bgcolor
    // [509] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [902] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [902] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [902] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [903] if(table_chip_clear::y#10<$24) goto table_chip_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$24
    bcc __b2
    // table_chip_clear::@return
    // }
    // [904] return 
    rts
    // table_chip_clear::@2
  __b2:
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [905] rom_address::rom_bank#1 = table_chip_clear::rom_bank#11 -- vbuz1=vbuz2 
    lda.z rom_bank
    sta.z rom_address.rom_bank
    // [906] call rom_address
    // [945] phi from table_chip_clear::@2 to rom_address [phi:table_chip_clear::@2->rom_address]
    // [945] phi rom_address::rom_bank#5 = rom_address::rom_bank#1 [phi:table_chip_clear::@2->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [907] rom_address::return#3 = rom_address::return#0
    // table_chip_clear::@4
    // [908] table_chip_clear::flash_rom_address#0 = rom_address::return#3
    // gotoxy(2, y)
    // [909] gotoxy::y#9 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [910] call gotoxy
    // [522] phi from table_chip_clear::@4 to gotoxy [phi:table_chip_clear::@4->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#9 [phi:table_chip_clear::@4->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = 2 [phi:table_chip_clear::@4->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // table_chip_clear::@5
    // printf("%02x", rom_bank)
    // [911] printf_uchar::uvalue#2 = table_chip_clear::rom_bank#11 -- vbuz1=vbuz2 
    lda.z rom_bank
    sta.z printf_uchar.uvalue
    // [912] call printf_uchar
    // [830] phi from table_chip_clear::@5 to printf_uchar [phi:table_chip_clear::@5->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 1 [phi:table_chip_clear::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 2 [phi:table_chip_clear::@5->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &cputc [phi:table_chip_clear::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = HEXADECIMAL [phi:table_chip_clear::@5->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#2 [phi:table_chip_clear::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@6
    // gotoxy(5, y)
    // [913] gotoxy::y#10 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [914] call gotoxy
    // [522] phi from table_chip_clear::@6 to gotoxy [phi:table_chip_clear::@6->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#10 [phi:table_chip_clear::@6->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = 5 [phi:table_chip_clear::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #5
    sta.z gotoxy.x
    jsr gotoxy
    // table_chip_clear::@7
    // printf("%06x", flash_rom_address)
    // [915] printf_ulong::uvalue#1 = table_chip_clear::flash_rom_address#0 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z printf_ulong.uvalue
    lda.z flash_rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z flash_rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z flash_rom_address+3
    sta.z printf_ulong.uvalue+3
    // [916] call printf_ulong
    // [1381] phi from table_chip_clear::@7 to printf_ulong [phi:table_chip_clear::@7->printf_ulong]
    // [1381] phi printf_ulong::format_zero_padding#2 = 1 [phi:table_chip_clear::@7->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1381] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:table_chip_clear::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // table_chip_clear::@8
    // gotoxy(14, y)
    // [917] gotoxy::y#11 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [918] call gotoxy
    // [522] phi from table_chip_clear::@8 to gotoxy [phi:table_chip_clear::@8->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#11 [phi:table_chip_clear::@8->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = $e [phi:table_chip_clear::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // [919] phi from table_chip_clear::@8 to table_chip_clear::@9 [phi:table_chip_clear::@8->table_chip_clear::@9]
    // table_chip_clear::@9
    // printf("%64s", " ")
    // [920] call printf_string
    // [923] phi from table_chip_clear::@9 to printf_string [phi:table_chip_clear::@9->printf_string]
    // [923] phi printf_string::str#10 = table_chip_clear::str [phi:table_chip_clear::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [923] phi printf_string::format_justify_left#10 = 0 [phi:table_chip_clear::@9->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [923] phi printf_string::format_min_length#7 = $40 [phi:table_chip_clear::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #$40
    sta.z printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@10
    // rom_bank++;
    // [921] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [922] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [902] phi from table_chip_clear::@10 to table_chip_clear::@1 [phi:table_chip_clear::@10->table_chip_clear::@1]
    // [902] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@10->table_chip_clear::@1#0] -- register_copy 
    // [902] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@10->table_chip_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    str: .text " "
    .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($3e) char *str, __zp($37) char format_min_length, __zp($bc) char format_justify_left)
printf_string: {
    .label __9 = $33
    .label len = $27
    .label padding = $37
    .label str = $3e
    .label format_min_length = $37
    .label format_justify_left = $bc
    // if(format.min_length)
    // [924] if(0==printf_string::format_min_length#7) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [925] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [926] call strlen
    // [1389] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1389] phi strlen::str#6 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [927] strlen::return#4 = strlen::len#2
    // printf_string::@6
    // [928] printf_string::$9 = strlen::return#4
    // signed char len = (signed char)strlen(str)
    // [929] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z __9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [930] printf_string::padding#1 = (signed char)printf_string::format_min_length#7 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [931] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [933] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [933] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [932] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [933] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [933] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [934] if(0!=printf_string::format_justify_left#10) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [935] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [936] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [937] call printf_padding
    // [1395] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1395] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1395] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1395] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [938] printf_str::s#2 = printf_string::str#10
    // [939] call printf_str
    // [750] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [940] if(0==printf_string::format_justify_left#10) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [941] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [942] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [943] call printf_padding
    // [1395] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1395] phi printf_padding::putc#7 = &cputc [phi:printf_string::@5->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1395] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1395] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [944] return 
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
// __zp($de) unsigned long rom_address(__zp($32) char rom_bank)
rom_address: {
    .label __1 = $38
    .label return = $38
    .label rom_bank = $32
    .label return_1 = $40
    .label return_2 = $6f
    .label return_3 = $e4
    .label return_4 = $de
    // ((unsigned long)(rom_bank)) << 14
    // [946] rom_address::$1 = (unsigned long)rom_address::rom_bank#5 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z __1
    lda #0
    sta.z __1+1
    sta.z __1+2
    sta.z __1+3
    // [947] rom_address::return#0 = rom_address::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [948] return 
    rts
}
  // flash_read
// __zp($bd) unsigned long flash_read(__zp($6d) struct $1 *fp, __zp($61) char *flash_ram_address, __zp($22) char rom_bank_start, __zp($4a) char rom_bank_size)
flash_read: {
    .label __4 = $57
    .label __7 = $73
    .label __13 = $b7
    .label flash_rom_address = $40
    .label flash_size = $74
    .label read_bytes = $2c
    .label rom_bank_start = $22
    .label return = $bd
    .label flash_ram_address = $61
    .label flash_bytes = $bd
    .label fp = $6d
    .label rom_bank_size = $4a
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [950] rom_address::rom_bank#0 = flash_read::rom_bank_start#11 -- vbuz1=vbuz2 
    lda.z rom_bank_start
    sta.z rom_address.rom_bank
    // [951] call rom_address
    // [945] phi from flash_read to rom_address [phi:flash_read->rom_address]
    // [945] phi rom_address::rom_bank#5 = rom_address::rom_bank#0 [phi:flash_read->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [952] rom_address::return#2 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_1
    lda.z rom_address.return+1
    sta.z rom_address.return_1+1
    lda.z rom_address.return+2
    sta.z rom_address.return_1+2
    lda.z rom_address.return+3
    sta.z rom_address.return_1+3
    // flash_read::@9
    // [953] flash_read::flash_rom_address#0 = rom_address::return#2
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [954] rom_size::rom_banks#0 = flash_read::rom_bank_size#2
    // [955] call rom_size
    // [985] phi from flash_read::@9 to rom_size [phi:flash_read::@9->rom_size]
    // [985] phi rom_size::rom_banks#2 = rom_size::rom_banks#0 [phi:flash_read::@9->rom_size#0] -- register_copy 
    jsr rom_size
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [956] rom_size::return#2 = rom_size::return#0
    // flash_read::@10
    // [957] flash_read::flash_size#0 = rom_size::return#2
    // textcolor(WHITE)
    // [958] call textcolor
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [504] phi from flash_read::@10 to textcolor [phi:flash_read::@10->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:flash_read::@10->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [959] phi from flash_read::@10 to flash_read::@1 [phi:flash_read::@10->flash_read::@1]
    // [959] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@10->flash_read::@1#0] -- register_copy 
    // [959] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@10->flash_read::@1#1] -- register_copy 
    // [959] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#0 [phi:flash_read::@10->flash_read::@1#2] -- register_copy 
    // [959] phi flash_read::return#2 = 0 [phi:flash_read::@10->flash_read::@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // [959] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [959] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [959] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [959] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [959] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < flash_size)
    // [960] if(flash_read::return#2<flash_read::flash_size#0) goto flash_read::@2 -- vduz1_lt_vduz2_then_la1 
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
    // [961] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [962] flash_read::$4 = flash_read::flash_rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [963] if(0!=flash_read::$4) goto flash_read::@3 -- 0_neq_vduz1_then_la1 
    lda.z __4
    ora.z __4+1
    ora.z __4+2
    ora.z __4+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [964] flash_read::$7 = flash_read::rom_bank_start#4 & $20-1 -- vbuz1=vbuz2_band_vbuc1 
    lda #$20-1
    and.z rom_bank_start
    sta.z __7
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [965] gotoxy::y#8 = 4 + flash_read::$7 -- vbuz1=vbuc1_plus_vbuz2 
    lda #4
    clc
    adc.z __7
    sta.z gotoxy.y
    // [966] call gotoxy
    // [522] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#8 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = $e [phi:flash_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // flash_read::@12
    // rom_bank_start++;
    // [967] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank_start
    // [968] phi from flash_read::@12 flash_read::@2 to flash_read::@3 [phi:flash_read::@12/flash_read::@2->flash_read::@3]
    // [968] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@12/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [969] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [970] fgets::fp#0 = flash_read::fp#10 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [971] call fgets
    jsr fgets
    // [972] fgets::return#5 = fgets::return#1
    // flash_read::@11
    // [973] flash_read::read_bytes#0 = fgets::return#5
    // if (!read_bytes)
    // [974] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwuz1_then_la1 
    lda.z read_bytes
    ora.z read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [975] flash_read::$13 = flash_read::flash_rom_address#10 & $100-1 -- vduz1=vduz2_band_vduc1 
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
    // [976] if(0!=flash_read::$13) goto flash_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z __13
    ora.z __13+1
    ora.z __13+2
    ora.z __13+3
    bne __b5
    // flash_read::@7
    // cputc('.')
    // [977] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    // cputc(0xE0);
    lda #'.'
    pha
    // [978] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [980] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [981] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [982] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [983] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // [984] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
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
// __zp($74) unsigned long rom_size(__zp($4a) char rom_banks)
rom_size: {
    .label __1 = $74
    .label return = $74
    .label rom_banks = $4a
    // ((unsigned long)(rom_banks)) << 14
    // [986] rom_size::$1 = (unsigned long)rom_size::rom_banks#2 -- vduz1=_dword_vbuz2 
    lda.z rom_banks
    sta.z __1
    lda #0
    sta.z __1+1
    sta.z __1+2
    sta.z __1+3
    // [987] rom_size::return#0 = rom_size::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [988] return 
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
    .label __0 = $63
    .label st = $7b
    // cbm_k_close(fp->channel)
    // [989] cbm_k_close::channel = ((char *)fclose::fp#0)[$10] -- vbuz1=pbum2_derefidx_vbuc1 
    ldy #$10
    lda fp
    sta.z $fe
    lda fp+1
    sta.z $ff
    lda ($fe),y
    sta.z cbm_k_close.channel
    // [990] call cbm_k_close
    jsr cbm_k_close
    // [991] cbm_k_close::return#4 = cbm_k_close::return#1
    // fclose::@2
    // [992] fclose::$0 = cbm_k_close::return#4
    // fp->status = cbm_k_close(fp->channel)
    // [993] ((char *)fclose::fp#0)[$13] = fclose::$0 -- pbum1_derefidx_vbuc1=vbuz2 
    lda.z __0
    ldy fp
    sty.z $fe
    ldy fp+1
    sty.z $ff
    ldy #$13
    sta ($fe),y
    // char st = fp->status
    // [994] fclose::st#0 = ((char *)fclose::fp#0)[$13] -- vbuz1=pbum2_derefidx_vbuc1 
    lda fp
    sta.z $fe
    lda fp+1
    sta.z $ff
    lda ($fe),y
    sta.z st
    // if(st)
    // [995] if(0==fclose::st#0) goto fclose::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // fclose::@return
    // }
    // [996] return 
    rts
    // [997] phi from fclose::@2 to fclose::@1 [phi:fclose::@2->fclose::@1]
    // fclose::@1
  __b1:
    // cbm_k_clrchn()
    // [998] call cbm_k_clrchn
    jsr cbm_k_clrchn
    // fclose::@3
    // __filecount--;
    // [999] __filecount = -- __filecount -- vbum1=_dec_vbum1 
    dec __filecount
    rts
  .segment Data
    .label fp = main.fp
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($6d) void (*putc)(char), __zp($28) unsigned int uvalue, __zp($2b) char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, __zp($ae) char format_radix)
printf_uint: {
    .label uvalue = $28
    .label format_radix = $ae
    .label putc = $6d
    .label format_min_length = $2b
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1001] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1002] utoa::value#2 = printf_uint::uvalue#3
    // [1003] utoa::radix#1 = printf_uint::format_radix#3
    // [1004] call utoa
  // Format number into buffer
    // [1243] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    // [1243] phi utoa::value#10 = utoa::value#2 [phi:printf_uint::@1->utoa#0] -- register_copy 
    // [1243] phi utoa::radix#2 = utoa::radix#1 [phi:printf_uint::@1->utoa#1] -- register_copy 
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1005] printf_number_buffer::putc#2 = printf_uint::putc#3
    // [1006] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1007] printf_number_buffer::format_min_length#2 = printf_uint::format_min_length#3
    // [1008] call printf_number_buffer
  // Print using format
    // [1274] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1274] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1274] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1274] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1274] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_zero_padding
    // [1274] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [1274] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#2 [phi:printf_uint::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1009] return 
    rts
}
  // flash_verify
// __zp($6d) unsigned int flash_verify(__zp($27) char bank_ram, __zp($61) char *ptr_ram, __zp($40) unsigned long verify_rom_address, __zp($79) unsigned int verify_rom_size)
flash_verify: {
    .label __5 = $32
    .label bank_set_bram1_bank = $27
    .label bank_rom = $46
    .label ptr_rom = $44
    .label ptr_ram = $61
    .label verified_bytes = $28
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label correct_bytes = $6d
    .label bank_ram = $27
    .label verify_rom_address = $40
    .label return = $6d
    .label verify_rom_size = $79
    // flash_verify::bank_set_bram1
    // BRAM = bank
    // [1011] BRAM = flash_verify::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // flash_verify::@5
    // brom_bank_t bank_rom = rom_bank((unsigned long)verify_rom_address)
    // [1012] rom_bank::address#3 = flash_verify::verify_rom_address#3 -- vduz1=vduz2 
    lda.z verify_rom_address
    sta.z rom_bank.address
    lda.z verify_rom_address+1
    sta.z rom_bank.address+1
    lda.z verify_rom_address+2
    sta.z rom_bank.address+2
    lda.z verify_rom_address+3
    sta.z rom_bank.address+3
    // [1013] call rom_bank
    // [1446] phi from flash_verify::@5 to rom_bank [phi:flash_verify::@5->rom_bank]
    // [1446] phi rom_bank::address#4 = rom_bank::address#3 [phi:flash_verify::@5->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)verify_rom_address)
    // [1014] rom_bank::return#10 = rom_bank::return#1
    // flash_verify::@6
    // [1015] flash_verify::bank_rom#0 = rom_bank::return#10
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)verify_rom_address)
    // [1016] rom_ptr::address#5 = flash_verify::verify_rom_address#3
    // [1017] call rom_ptr
    // [1451] phi from flash_verify::@6 to rom_ptr [phi:flash_verify::@6->rom_ptr]
    // [1451] phi rom_ptr::address#6 = rom_ptr::address#5 [phi:flash_verify::@6->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // flash_verify::@7
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)verify_rom_address)
    // [1018] flash_verify::ptr_rom#0 = (char *)rom_ptr::return#1
    // bank_set_brom(bank_rom)
    // [1019] bank_set_brom::bank#4 = flash_verify::bank_rom#0
    // [1020] call bank_set_brom
    // [811] phi from flash_verify::@7 to bank_set_brom [phi:flash_verify::@7->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = bank_set_brom::bank#4 [phi:flash_verify::@7->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // [1021] phi from flash_verify::@7 to flash_verify::@1 [phi:flash_verify::@7->flash_verify::@1]
    // [1021] phi flash_verify::correct_bytes#2 = 0 [phi:flash_verify::@7->flash_verify::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z correct_bytes
    sta.z correct_bytes+1
    // [1021] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#10 [phi:flash_verify::@7->flash_verify::@1#1] -- register_copy 
    // [1021] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#0 [phi:flash_verify::@7->flash_verify::@1#2] -- register_copy 
    // [1021] phi flash_verify::verified_bytes#2 = 0 [phi:flash_verify::@7->flash_verify::@1#3] -- vwuz1=vwuc1 
    sta.z verified_bytes
    sta.z verified_bytes+1
    // flash_verify::@1
  __b1:
    // while (verified_bytes < verify_rom_size)
    // [1022] if(flash_verify::verified_bytes#2<flash_verify::verify_rom_size#11) goto flash_verify::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1023] return 
    rts
    // flash_verify::@2
  __b2:
    // rom_byte_verify(ptr_rom, *ptr_ram)
    // [1024] rom_byte_verify::ptr_rom#0 = flash_verify::ptr_rom#2
    // [1025] rom_byte_verify::value#0 = *flash_verify::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_verify.value
    // [1026] call rom_byte_verify
    jsr rom_byte_verify
    // [1027] rom_byte_verify::return#2 = rom_byte_verify::return#0
    // flash_verify::@8
    // [1028] flash_verify::$5 = rom_byte_verify::return#2
    // if (rom_byte_verify(ptr_rom, *ptr_ram))
    // [1029] if(0==flash_verify::$5) goto flash_verify::@3 -- 0_eq_vbuz1_then_la1 
    lda.z __5
    beq __b3
    // flash_verify::@4
    // correct_bytes++;
    // [1030] flash_verify::correct_bytes#1 = ++ flash_verify::correct_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z correct_bytes
    bne !+
    inc.z correct_bytes+1
  !:
    // [1031] phi from flash_verify::@4 flash_verify::@8 to flash_verify::@3 [phi:flash_verify::@4/flash_verify::@8->flash_verify::@3]
    // [1031] phi flash_verify::correct_bytes#6 = flash_verify::correct_bytes#1 [phi:flash_verify::@4/flash_verify::@8->flash_verify::@3#0] -- register_copy 
    // flash_verify::@3
  __b3:
    // ptr_rom++;
    // [1032] flash_verify::ptr_rom#1 = ++ flash_verify::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [1033] flash_verify::ptr_ram#0 = ++ flash_verify::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // verified_bytes++;
    // [1034] flash_verify::verified_bytes#1 = ++ flash_verify::verified_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z verified_bytes
    bne !+
    inc.z verified_bytes+1
  !:
    // [1021] phi from flash_verify::@3 to flash_verify::@1 [phi:flash_verify::@3->flash_verify::@1]
    // [1021] phi flash_verify::correct_bytes#2 = flash_verify::correct_bytes#6 [phi:flash_verify::@3->flash_verify::@1#0] -- register_copy 
    // [1021] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#0 [phi:flash_verify::@3->flash_verify::@1#1] -- register_copy 
    // [1021] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#1 [phi:flash_verify::@3->flash_verify::@1#2] -- register_copy 
    // [1021] phi flash_verify::verified_bytes#2 = flash_verify::verified_bytes#1 [phi:flash_verify::@3->flash_verify::@1#3] -- register_copy 
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
// void rom_sector_erase(__zp($b7) unsigned long address)
rom_sector_erase: {
    .label ptr_rom = $33
    .label rom_chip_address = $69
    .label address = $b7
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1035] rom_ptr::address#4 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [1036] call rom_ptr
    // [1451] phi from rom_sector_erase to rom_ptr [phi:rom_sector_erase->rom_ptr]
    // [1451] phi rom_ptr::address#6 = rom_ptr::address#4 [phi:rom_sector_erase->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_sector_erase::@1
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1037] rom_sector_erase::ptr_rom#0 = (char *)rom_ptr::return#1 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [1038] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1039] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [1040] call rom_unlock
    // [1090] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1090] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1090] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [1041] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [1042] call rom_unlock
    // [1090] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1090] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1090] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [1043] rom_wait::ptr_rom#1 = rom_sector_erase::ptr_rom#0
    // [1044] call rom_wait
    // [1460] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [1460] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [1045] return 
    rts
}
  // print_address
// void print_address(__zp($27) char bram_bank, __zp($28) char *bram_ptr, __zp($23) unsigned long brom_address)
print_address: {
    .label brom_bank = $7b
    .label brom_ptr = $44
    .label bram_bank = $27
    .label bram_ptr = $28
    .label brom_address = $23
    // textcolor(WHITE)
    // [1047] call textcolor
    // [504] phi from print_address to textcolor [phi:print_address->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:print_address->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // print_address::@1
    // brom_bank_t brom_bank = rom_bank(brom_address)
    // [1048] rom_bank::address#0 = print_address::brom_address#10 -- vduz1=vduz2 
    lda.z brom_address
    sta.z rom_bank.address
    lda.z brom_address+1
    sta.z rom_bank.address+1
    lda.z brom_address+2
    sta.z rom_bank.address+2
    lda.z brom_address+3
    sta.z rom_bank.address+3
    // [1049] call rom_bank
    // [1446] phi from print_address::@1 to rom_bank [phi:print_address::@1->rom_bank]
    // [1446] phi rom_bank::address#4 = rom_bank::address#0 [phi:print_address::@1->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t brom_bank = rom_bank(brom_address)
    // [1050] rom_bank::return#0 = rom_bank::return#1 -- vbuz1=vbuz2 
    lda.z rom_bank.return_1
    sta.z rom_bank.return
    // print_address::@2
    // [1051] print_address::brom_bank#0 = rom_bank::return#0
    // brom_ptr_t brom_ptr = rom_ptr(brom_address)
    // [1052] rom_ptr::address#0 = print_address::brom_address#10 -- vduz1=vduz2 
    lda.z brom_address
    sta.z rom_ptr.address
    lda.z brom_address+1
    sta.z rom_ptr.address+1
    lda.z brom_address+2
    sta.z rom_ptr.address+2
    lda.z brom_address+3
    sta.z rom_ptr.address+3
    // [1053] call rom_ptr
    // [1451] phi from print_address::@2 to rom_ptr [phi:print_address::@2->rom_ptr]
    // [1451] phi rom_ptr::address#6 = rom_ptr::address#0 [phi:print_address::@2->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // print_address::@3
    // brom_ptr_t brom_ptr = rom_ptr(brom_address)
    // [1054] print_address::brom_ptr#0 = (char *)rom_ptr::return#1
    // gotoxy(40, 1)
    // [1055] call gotoxy
    // [522] phi from print_address::@3 to gotoxy [phi:print_address::@3->gotoxy]
    // [522] phi gotoxy::y#24 = 1 [phi:print_address::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = $28 [phi:print_address::@3->gotoxy#1] -- vbuz1=vbuc1 
    lda #$28
    sta.z gotoxy.x
    jsr gotoxy
    // [1056] phi from print_address::@3 to print_address::@4 [phi:print_address::@3->print_address::@4]
    // print_address::@4
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1057] call printf_str
    // [750] phi from print_address::@4 to printf_str [phi:print_address::@4->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:print_address::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = print_address::s [phi:print_address::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@5
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1058] printf_uchar::uvalue#0 = print_address::bram_bank#3
    // [1059] call printf_uchar
    // [830] phi from print_address::@5 to printf_uchar [phi:print_address::@5->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:print_address::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 2 [phi:print_address::@5->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &cputc [phi:print_address::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = HEXADECIMAL [phi:print_address::@5->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#0 [phi:print_address::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1060] phi from print_address::@5 to print_address::@6 [phi:print_address::@5->print_address::@6]
    // print_address::@6
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1061] call printf_str
    // [750] phi from print_address::@6 to printf_str [phi:print_address::@6->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:print_address::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = print_address::s1 [phi:print_address::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@7
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1062] printf_uint::uvalue#0 = (unsigned int)print_address::bram_ptr#10
    // [1063] call printf_uint
    // [1000] phi from print_address::@7 to printf_uint [phi:print_address::@7->printf_uint]
    // [1000] phi printf_uint::format_min_length#3 = 4 [phi:print_address::@7->printf_uint#0] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1000] phi printf_uint::putc#3 = &cputc [phi:print_address::@7->printf_uint#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1000] phi printf_uint::format_radix#3 = HEXADECIMAL [phi:print_address::@7->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1000] phi printf_uint::uvalue#3 = printf_uint::uvalue#0 [phi:print_address::@7->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1064] phi from print_address::@7 to print_address::@8 [phi:print_address::@7->print_address::@8]
    // print_address::@8
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1065] call printf_str
    // [750] phi from print_address::@8 to printf_str [phi:print_address::@8->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:print_address::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = print_address::s2 [phi:print_address::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@9
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1066] printf_ulong::uvalue#0 = print_address::brom_address#10
    // [1067] call printf_ulong
    // [1381] phi from print_address::@9 to printf_ulong [phi:print_address::@9->printf_ulong]
    // [1381] phi printf_ulong::format_zero_padding#2 = 0 [phi:print_address::@9->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1381] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:print_address::@9->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1068] phi from print_address::@9 to print_address::@10 [phi:print_address::@9->print_address::@10]
    // print_address::@10
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1069] call printf_str
    // [750] phi from print_address::@10 to printf_str [phi:print_address::@10->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:print_address::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = print_address::s3 [phi:print_address::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@11
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1070] printf_uchar::uvalue#1 = print_address::brom_bank#0 -- vbuz1=vbuz2 
    lda.z brom_bank
    sta.z printf_uchar.uvalue
    // [1071] call printf_uchar
    // [830] phi from print_address::@11 to printf_uchar [phi:print_address::@11->printf_uchar]
    // [830] phi printf_uchar::format_zero_padding#12 = 0 [phi:print_address::@11->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [830] phi printf_uchar::format_min_length#12 = 2 [phi:print_address::@11->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [830] phi printf_uchar::putc#12 = &cputc [phi:print_address::@11->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [830] phi printf_uchar::format_radix#12 = HEXADECIMAL [phi:print_address::@11->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [830] phi printf_uchar::uvalue#12 = printf_uchar::uvalue#1 [phi:print_address::@11->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1072] phi from print_address::@11 to print_address::@12 [phi:print_address::@11->print_address::@12]
    // print_address::@12
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1073] call printf_str
    // [750] phi from print_address::@12 to printf_str [phi:print_address::@12->printf_str]
    // [750] phi printf_str::putc#33 = &cputc [phi:print_address::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [750] phi printf_str::s#33 = print_address::s1 [phi:print_address::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@13
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1074] printf_uint::uvalue#1 = (unsigned int)print_address::brom_ptr#0 -- vwuz1=vwuz2 
    lda.z brom_ptr
    sta.z printf_uint.uvalue
    lda.z brom_ptr+1
    sta.z printf_uint.uvalue+1
    // [1075] call printf_uint
    // [1000] phi from print_address::@13 to printf_uint [phi:print_address::@13->printf_uint]
    // [1000] phi printf_uint::format_min_length#3 = 4 [phi:print_address::@13->printf_uint#0] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1000] phi printf_uint::putc#3 = &cputc [phi:print_address::@13->printf_uint#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1000] phi printf_uint::format_radix#3 = HEXADECIMAL [phi:print_address::@13->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1000] phi printf_uint::uvalue#3 = printf_uint::uvalue#1 [phi:print_address::@13->printf_uint#3] -- register_copy 
    jsr printf_uint
    // print_address::@return
    // }
    // [1076] return 
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
// unsigned long flash_write(__zp($af) char flash_ram_bank, __zp($3c) char *flash_ram_address, __zp($74) unsigned long flash_rom_address)
flash_write: {
    .label rom_chip_address = $2e
    .label flash_rom_address = $74
    .label flash_ram_address = $3c
    .label flashed_bytes = $6f
    .label flash_ram_bank = $af
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [1077] flash_write::rom_chip_address#0 = flash_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1078] BRAM = flash_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [1079] phi from flash_write::bank_set_bram1 to flash_write::@1 [phi:flash_write::bank_set_bram1->flash_write::@1]
    // [1079] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#0] -- register_copy 
    // [1079] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#1] -- register_copy 
    // [1079] phi flash_write::flashed_bytes#2 = 0 [phi:flash_write::bank_set_bram1->flash_write::@1#2] -- vduz1=vduc1 
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
    // [1080] if(flash_write::flashed_bytes#2<$100) goto flash_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [1081] return 
    rts
    // flash_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [1082] rom_unlock::address#2 = flash_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1083] call rom_unlock
    // [1090] phi from flash_write::@2 to rom_unlock [phi:flash_write::@2->rom_unlock]
    // [1090] phi rom_unlock::unlock_code#5 = $a0 [phi:flash_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1090] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:flash_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // flash_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [1084] rom_byte_program::address#0 = flash_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [1085] rom_byte_program::value#0 = *flash_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [1086] call rom_byte_program
    jsr rom_byte_program
    // flash_write::@4
    // flash_rom_address++;
    // [1087] flash_write::flash_rom_address#0 = ++ flash_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [1088] flash_write::flash_ram_address#0 = ++ flash_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [1089] flash_write::flashed_bytes#1 = ++ flash_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [1079] phi from flash_write::@4 to flash_write::@1 [phi:flash_write::@4->flash_write::@1]
    // [1079] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#0 [phi:flash_write::@4->flash_write::@1#0] -- register_copy 
    // [1079] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#0 [phi:flash_write::@4->flash_write::@1#1] -- register_copy 
    // [1079] phi flash_write::flashed_bytes#2 = flash_write::flashed_bytes#1 [phi:flash_write::@4->flash_write::@1#2] -- register_copy 
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
// void rom_unlock(__zp($69) unsigned long address, __zp($73) char unlock_code)
rom_unlock: {
    .label chip_address = $64
    .label address = $69
    .label unlock_code = $73
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1091] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1092] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1093] call rom_write_byte
    // [1476] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1476] phi rom_write_byte::value#4 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [1476] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1094] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [1095] call rom_write_byte
    // [1476] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1476] phi rom_write_byte::value#4 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [1476] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1096] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1097] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1098] call rom_write_byte
    // [1476] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1476] phi rom_write_byte::value#4 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1476] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1099] return 
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
/* inline */
// __zp($af) char rom_read_byte(__zp($d5) unsigned long address)
rom_read_byte: {
    .label bank_rom = $51
    .label ptr_rom = $28
    .label return = $af
    .label address = $d5
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1101] rom_bank::address#1 = rom_read_byte::address#2 -- vduz1=vduz2 
    lda.z address
    sta.z rom_bank.address
    lda.z address+1
    sta.z rom_bank.address+1
    lda.z address+2
    sta.z rom_bank.address+2
    lda.z address+3
    sta.z rom_bank.address+3
    // [1102] call rom_bank
    // [1446] phi from rom_read_byte to rom_bank [phi:rom_read_byte->rom_bank]
    // [1446] phi rom_bank::address#4 = rom_bank::address#1 [phi:rom_read_byte->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1103] rom_bank::return#3 = rom_bank::return#1 -- vbuz1=vbuz2 
    lda.z rom_bank.return_1
    sta.z rom_bank.return_2
    // rom_read_byte::@1
    // [1104] rom_read_byte::bank_rom#0 = rom_bank::return#3
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1105] rom_ptr::address#1 = rom_read_byte::address#2 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [1106] call rom_ptr
    // [1451] phi from rom_read_byte::@1 to rom_ptr [phi:rom_read_byte::@1->rom_ptr]
    // [1451] phi rom_ptr::address#6 = rom_ptr::address#1 [phi:rom_read_byte::@1->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_read_byte::@2
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1107] rom_read_byte::ptr_rom#0 = (char *)rom_ptr::return#1 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // bank_set_brom(bank_rom)
    // [1108] bank_set_brom::bank#2 = rom_read_byte::bank_rom#0 -- vbuz1=vbuz2 
    lda.z bank_rom
    sta.z bank_set_brom.bank
    // [1109] call bank_set_brom
    // [811] phi from rom_read_byte::@2 to bank_set_brom [phi:rom_read_byte::@2->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = bank_set_brom::bank#2 [phi:rom_read_byte::@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_read_byte::@3
    // return *ptr_rom;
    // [1110] rom_read_byte::return#0 = *rom_read_byte::ptr_rom#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [1111] return 
    rts
}
  // print_chip_KB
// void print_chip_KB(__zp($47) char rom_chip, __zp($3c) char *kb)
print_chip_KB: {
    .label __3 = $47
    .label rom_chip = $47
    .label kb = $3c
    .label __9 = $56
    .label __10 = $47
    // rom_chip * 10
    // [1113] print_chip_KB::$9 = print_chip_KB::rom_chip#3 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z __9
    // [1114] print_chip_KB::$10 = print_chip_KB::$9 + print_chip_KB::rom_chip#3 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z __10
    clc
    adc.z __9
    sta.z __10
    // [1115] print_chip_KB::$3 = print_chip_KB::$10 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __3
    // print_chip_line(3 + rom_chip * 10, 51, kb[0])
    // [1116] print_chip_line::x#9 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __3
    sta.z print_chip_line.x
    // [1117] print_chip_line::c#9 = *print_chip_KB::kb#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (kb),y
    sta.z print_chip_line.c
    // [1118] call print_chip_line
    // [1180] phi from print_chip_KB to print_chip_line [phi:print_chip_KB->print_chip_line]
    // [1180] phi print_chip_line::c#12 = print_chip_line::c#9 [phi:print_chip_KB->print_chip_line#0] -- register_copy 
    // [1180] phi print_chip_line::y#12 = $33 [phi:print_chip_KB->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$33
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#9 [phi:print_chip_KB->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@1
    // print_chip_line(3 + rom_chip * 10, 52, kb[1])
    // [1119] print_chip_line::x#10 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __3
    sta.z print_chip_line.x
    // [1120] print_chip_line::c#10 = print_chip_KB::kb#3[1] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #1
    lda (kb),y
    sta.z print_chip_line.c
    // [1121] call print_chip_line
    // [1180] phi from print_chip_KB::@1 to print_chip_line [phi:print_chip_KB::@1->print_chip_line]
    // [1180] phi print_chip_line::c#12 = print_chip_line::c#10 [phi:print_chip_KB::@1->print_chip_line#0] -- register_copy 
    // [1180] phi print_chip_line::y#12 = $34 [phi:print_chip_KB::@1->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$34
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#10 [phi:print_chip_KB::@1->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@2
    // print_chip_line(3 + rom_chip * 10, 53, kb[2])
    // [1122] print_chip_line::x#11 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z __3
    sta.z print_chip_line.x
    // [1123] print_chip_line::c#11 = print_chip_KB::kb#3[2] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #2
    lda (kb),y
    sta.z print_chip_line.c
    // [1124] call print_chip_line
    // [1180] phi from print_chip_KB::@2 to print_chip_line [phi:print_chip_KB::@2->print_chip_line]
    // [1180] phi print_chip_line::c#12 = print_chip_line::c#11 [phi:print_chip_KB::@2->print_chip_line#0] -- register_copy 
    // [1180] phi print_chip_line::y#12 = $35 [phi:print_chip_KB::@2->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$35
    sta.z print_chip_line.y
    // [1180] phi print_chip_line::x#12 = print_chip_line::x#11 [phi:print_chip_KB::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@return
    // }
    // [1125] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($b1) char mapbase, __zp($c7) char config)
screenlayer: {
    .label __0 = $ee
    .label __1 = $b1
    .label __2 = $ef
    .label __5 = $c7
    .label __6 = $c7
    .label __7 = $e8
    .label __8 = $e8
    .label __9 = $e2
    .label __10 = $e2
    .label __11 = $e2
    .label __12 = $e3
    .label __13 = $e3
    .label __14 = $e3
    .label __16 = $e8
    .label __17 = $d9
    .label __18 = $e2
    .label __19 = $e3
    .label mapbase_offset = $da
    .label y = $b0
    .label mapbase = $b1
    .label config = $c7
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1126] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1127] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1128] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // mapbase >> 7
    // [1129] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z __0
    // __conio.mapbase_bank = mapbase >> 7
    // [1130] *((char *)&__conio+3) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+3
    // (mapbase)<<1
    // [1131] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __1
    // MAKEWORD((mapbase)<<1,0)
    // [1132] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z __1
    sty.z __2+1
    sta.z __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1133] *((unsigned int *)&__conio+1) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+1
    tya
    sta __conio+1+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1134] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z __7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1135] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z __8
    lsr
    lsr
    lsr
    lsr
    sta.z __8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1136] *((char *)&__conio+6) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+6
    // config & VERA_LAYER_HEIGHT_MASK
    // [1137] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z __5
    sta.z __5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1138] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z __6
    rol
    rol
    rol
    and #3
    sta.z __6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1139] *((char *)&__conio+7) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+7
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1140] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __16
    // [1141] *((unsigned int *)&__conio+8) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z __16
    lda VERA_LAYER_SKIP,y
    sta __conio+8
    lda VERA_LAYER_SKIP+1,y
    sta __conio+8+1
    // vera_dc_hscale_temp == 0x80
    // [1142] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z __9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1143] screenlayer::$18 = (char)screenlayer::$9
    // [1144] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1145] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z __11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1146] *((char *)&__conio+4) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z __11
    sta __conio+4
    // vera_dc_vscale_temp == 0x80
    // [1147] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z __12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1148] screenlayer::$19 = (char)screenlayer::$12
    // [1149] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1150] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z __14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1151] *((char *)&__conio+5) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z __14
    sta __conio+5
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1152] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z mapbase_offset
    lda __conio+1+1
    sta.z mapbase_offset+1
    // [1153] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1153] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1153] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1154] if(screenlayer::y#2<=*((char *)&__conio+5)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+5
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1155] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1156] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z __17
    // [1157] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1158] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+8
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+8+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1159] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1153] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1153] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1153] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1160] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1161] if(0!=((char *)&__conio+$f)[*((char *)&__conio)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1162] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // [1163] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1164] call gotoxy
    // [522] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [522] phi gotoxy::y#24 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1165] return 
    rts
    // [1166] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1167] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1168] gotoxy::y#2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z gotoxy.y
    // [1169] call gotoxy
    // [522] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1170] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1171] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($63) char x, __zp($22) char y, __zp($2a) char c)
cputcxy: {
    .label x = $63
    .label y = $22
    .label c = $2a
    // gotoxy(x, y)
    // [1173] gotoxy::x#0 = cputcxy::x#68 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1174] gotoxy::y#0 = cputcxy::y#68 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1175] call gotoxy
    // [522] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1176] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1177] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1179] return 
    rts
}
  // print_chip_line
// void print_chip_line(__zp($2a) char x, __zp($4b) char y, __zp($56) char c)
print_chip_line: {
    .label x = $2a
    .label c = $56
    .label y = $4b
    // gotoxy(x, y)
    // [1181] gotoxy::x#4 = print_chip_line::x#12 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1182] gotoxy::y#4 = print_chip_line::y#12 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1183] call gotoxy
    // [522] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [522] phi gotoxy::y#24 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [522] phi gotoxy::x#24 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1184] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [1185] call textcolor
    // [504] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [504] phi textcolor::color#24 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1186] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [1187] call bgcolor
    // [509] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [1188] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1189] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1191] call textcolor
    // [504] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [504] phi textcolor::color#24 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1192] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [1193] call bgcolor
    // [509] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [509] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [1194] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1195] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [1197] stackpush(char) = print_chip_line::c#12 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1198] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [1200] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1201] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1203] call textcolor
    // [504] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [504] phi textcolor::color#24 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1204] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [1205] call bgcolor
    // [509] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [1206] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1207] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [1209] return 
    rts
}
  // print_chip_end
// void print_chip_end(__zp($51) char x, char y)
print_chip_end: {
    .const y = $36
    .label x = $51
    // gotoxy(x, y)
    // [1210] gotoxy::x#5 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1211] call gotoxy
    // [522] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [522] phi gotoxy::y#24 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #y
    sta.z gotoxy.y
    // [522] phi gotoxy::x#24 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1212] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [1213] call textcolor
    // [504] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [504] phi textcolor::color#24 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1214] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [1215] call bgcolor
    // [509] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [1216] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1217] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1219] call textcolor
    // [504] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [504] phi textcolor::color#24 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [1220] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [1221] call bgcolor
    // [509] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [509] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [1222] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1223] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1225] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1226] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1228] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1229] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1231] call textcolor
    // [504] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [504] phi textcolor::color#24 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1232] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [1233] call bgcolor
    // [509] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [509] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [1234] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1235] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1237] return 
    rts
}
  // getin
/**
 * @brief Get a character from keyboard.
 * 
 * @return char The character read.
 */
getin: {
    .label return = $ae
    // __mem unsigned char ch
    // [1238] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [1240] getin::return#0 = getin::ch -- vbuz1=vbum2 
    sta.z return
    // getin::@return
    // }
    // [1241] getin::return#1 = getin::return#0
    // [1242] return 
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
// void utoa(__zp($28) unsigned int value, __zp($3c) char *buffer, __zp($ae) char radix)
utoa: {
    .label __4 = $51
    .label __10 = $22
    .label __11 = $32
    .label digit_value = $2c
    .label buffer = $3c
    .label digit = $4b
    .label value = $28
    .label radix = $ae
    .label started = $56
    .label max_digits = $47
    .label digit_values = $61
    // if(radix==DECIMAL)
    // [1244] if(utoa::radix#2==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1245] if(utoa::radix#2==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1246] if(utoa::radix#2==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1247] if(utoa::radix#2==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1248] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1249] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1250] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1251] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1252] return 
    rts
    // [1253] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1253] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1253] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1253] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1253] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1253] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1253] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1253] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1253] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1253] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1253] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1253] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1254] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1254] phi utoa::buffer#10 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1254] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1254] phi utoa::value#3 = utoa::value#10 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1254] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1255] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1256] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z __4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1257] utoa::$11 = (char)utoa::value#3 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z __11
    // [1258] *utoa::buffer#10 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1259] utoa::buffer#3 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1260] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1261] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z __10
    // [1262] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1263] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1264] if(utoa::value#3>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1265] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1265] phi utoa::buffer#15 = utoa::buffer#10 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1265] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1265] phi utoa::value#7 = utoa::value#3 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1266] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1254] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1254] phi utoa::buffer#10 = utoa::buffer#15 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1254] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1254] phi utoa::value#3 = utoa::value#7 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1254] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1267] utoa_append::buffer#0 = utoa::buffer#10 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1268] utoa_append::value#0 = utoa::value#3
    // [1269] utoa_append::sub#0 = utoa::digit_value#0
    // [1270] call utoa_append
    // [1521] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1271] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1272] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1273] utoa::buffer#4 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1265] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1265] phi utoa::buffer#15 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1265] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1265] phi utoa::value#7 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($6d) void (*putc)(char), __zp($46) char buffer_sign, char *buffer_digits, __zp($2b) char format_min_length, __zp($4e) char format_justify_left, char format_sign_always, __zp($af) char format_zero_padding, __zp($55) char format_upper_case, char format_radix)
printf_number_buffer: {
    .label __19 = $33
    .label buffer_sign = $46
    .label format_zero_padding = $af
    .label putc = $6d
    .label format_min_length = $2b
    .label len = $32
    .label padding = $32
    .label format_justify_left = $4e
    .label format_upper_case = $55
    // if(format.min_length)
    // [1275] if(0==printf_number_buffer::format_min_length#4) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b6
    // [1276] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [1277] call strlen
    // [1389] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [1389] phi strlen::str#6 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1278] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@14
    // [1279] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1280] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z __19
    sta.z len
    // if(buffer.sign)
    // [1281] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [1282] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1283] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [1283] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [1284] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#4 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1285] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1287] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [1287] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1286] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [1287] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [1287] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1288] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [1289] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [1290] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [1291] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1292] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1293] call printf_padding
    // [1395] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1395] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1395] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@8->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1395] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1294] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [1295] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1296] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall28
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1298] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [1299] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1300] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1301] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1302] call printf_padding
    // [1395] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1395] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1395] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@10->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1395] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1303] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbuz1_then_la1 
    lda.z format_upper_case
    beq __b5
    // [1304] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1305] call strupr
    // [1528] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1306] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1307] call printf_str
    // [750] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [750] phi printf_str::putc#33 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [750] phi printf_str::s#33 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1308] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1309] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1310] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1311] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1312] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1313] call printf_padding
    // [1395] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1395] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1395] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@12->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1395] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1314] return 
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
// void uctoa(__zp($27) char value, __zp($3c) char *buffer, __zp($54) char radix)
uctoa: {
    .label __4 = $32
    .label digit_value = $22
    .label buffer = $3c
    .label digit = $46
    .label value = $27
    .label radix = $54
    .label started = $55
    .label max_digits = $4e
    .label digit_values = $61
    // if(radix==DECIMAL)
    // [1315] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1316] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1317] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1318] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1319] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1320] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1321] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1322] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1323] return 
    rts
    // [1324] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1324] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1324] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1324] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1324] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1324] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1324] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1324] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1324] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1324] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1324] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1324] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1325] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1325] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1325] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1325] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1325] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1326] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1327] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z __4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1328] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1329] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1330] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1331] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1332] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1333] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1334] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1334] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1334] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1334] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1335] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1325] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1325] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1325] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1325] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1325] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1336] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1337] uctoa_append::value#0 = uctoa::value#2
    // [1338] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1339] call uctoa_append
    // [1538] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1340] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1341] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1342] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1334] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1334] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1334] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1334] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($33) char *dst, __zp($3c) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label c = $7b
    .label dst = $33
    .label i = $44
    .label src = $3c
    // [1344] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1344] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1344] phi strncpy::src#2 = main::buffer [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z src
    lda #>main.buffer
    sta.z src+1
    // [1344] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1345] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuc1_then_la1 
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
    // [1346] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1347] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1348] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1349] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1350] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1350] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1351] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1352] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1353] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1344] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1344] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1344] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1344] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_setnam
/**
 * @brief Sets the name of the file before opening.
 * 
 * @param filename The name of the file.
 */
// void cbm_k_setnam(__zp($f1) char * volatile filename)
cbm_k_setnam: {
    .label filename = $f1
    .label __0 = $33
    // strlen(filename)
    // [1354] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbuz2 
    lda.z filename
    sta.z strlen.str
    lda.z filename+1
    sta.z strlen.str+1
    // [1355] call strlen
    // [1389] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [1389] phi strlen::str#6 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1356] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [1357] cbm_k_setnam::$0 = strlen::return#0
    // __mem char filename_len = (char)strlen(filename)
    // [1358] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwuz2 
    lda.z __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [1360] return 
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
// void cbm_k_setlfs(__zp($f9) volatile char channel, __zp($f7) volatile char device, __zp($f3) volatile char command)
cbm_k_setlfs: {
    .label channel = $f9
    .label device = $f7
    .label command = $f3
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1362] return 
    rts
}
  // cbm_k_open
/**
 * @brief Open a logical file.
 * 
 * @return char The status.
 */
cbm_k_open: {
    .label return = $27
    // __mem unsigned char status
    // [1363] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [1365] cbm_k_open::return#0 = cbm_k_open::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_open::@return
    // }
    // [1366] cbm_k_open::return#1 = cbm_k_open::return#0
    // [1367] return 
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
// __zp($63) char cbm_k_close(__zp($f6) volatile char channel)
cbm_k_close: {
    .label channel = $f6
    .label return = $63
    // __mem unsigned char status
    // [1368] cbm_k_close::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldachannel jsrCBM_CLOSE stastatus  }
    lda channel
    jsr CBM_CLOSE
    sta status
    // return status;
    // [1370] cbm_k_close::return#0 = cbm_k_close::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_close::@return
    // }
    // [1371] cbm_k_close::return#1 = cbm_k_close::return#0
    // [1372] return 
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
// char cbm_k_chkin(__zp($b5) volatile char channel)
cbm_k_chkin: {
    .label channel = $b5
    // __mem unsigned char status
    // [1373] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [1375] return 
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
    .label return = $73
    // __mem unsigned char status
    // [1376] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [1378] cbm_k_readst::return#0 = cbm_k_readst::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_readst::@return
    // }
    // [1379] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [1380] return 
    rts
  .segment Data
    status: .byte 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($23) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, __zp($af) char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $23
    .label format_zero_padding = $af
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1382] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1383] ultoa::value#1 = printf_ulong::uvalue#2
    // [1384] call ultoa
  // Format number into buffer
    // [1545] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1385] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1386] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#2
    // [1387] call printf_number_buffer
  // Print using format
    // [1274] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1274] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1274] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1274] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1274] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    // [1274] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_justify_left
    // [1274] phi printf_number_buffer::format_min_length#4 = 6 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1388] return 
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($33) unsigned int strlen(__zp($3c) char *str)
strlen: {
    .label str = $3c
    .label return = $33
    .label len = $33
    // [1390] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1390] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1390] phi strlen::str#4 = strlen::str#6 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1391] if(0!=*strlen::str#4) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1392] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1393] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1394] strlen::str#1 = ++ strlen::str#4 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1390] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1390] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1390] phi strlen::str#4 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($3c) void (*putc)(char), __zp($22) char pad, __zp($4a) char length)
printf_padding: {
    .label i = $2a
    .label putc = $3c
    .label length = $4a
    .label pad = $22
    // [1396] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1396] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1397] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1398] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1399] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1400] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall29
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1402] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1396] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1396] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
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
// __zp($2c) unsigned int fgets(__zp($3c) char *ptr, unsigned int size, __zp($28) struct $1 *fp)
fgets: {
    .const size = $80
    .label __1 = $73
    .label __9 = $73
    .label __10 = $7b
    .label __14 = $32
    .label return = $2c
    .label bytes = $48
    .label read = $2c
    .label ptr = $3c
    .label remaining = $33
    .label fp = $28
    // cbm_k_chkin(fp->channel)
    // [1403] cbm_k_chkin::channel = ((char *)fgets::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_chkin.channel
    // [1404] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1405] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [1406] call cbm_k_readst
    jsr cbm_k_readst
    // [1407] cbm_k_readst::return#3 = cbm_k_readst::return#1
    // fgets::@12
    // [1408] fgets::$1 = cbm_k_readst::return#3
    // fp->status = cbm_k_readst()
    // [1409] ((char *)fgets::fp#0)[$13] = fgets::$1 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __1
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [1410] if(0==((char *)fgets::fp#0)[$13]) goto fgets::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b8
    // [1411] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [1411] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1412] return 
    rts
    // [1413] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [1413] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1413] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@12->fgets::@1#1] -- vwuz1=vwuc1 
    lda #<size
    sta.z remaining
    lda #>size
    sta.z remaining+1
    // [1413] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [1413] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [1413] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [1413] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [1413] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [1414] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwuz1_ge_vbuc1_then_la1 
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
    // [1415] cbm_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cbm_k_macptr.bytes
    // [1416] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1417] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1418] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [1419] fgets::bytes#3 = cbm_k_macptr::return#4
    // [1420] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [1420] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [1421] call cbm_k_readst
    jsr cbm_k_readst
    // [1422] cbm_k_readst::return#4 = cbm_k_readst::return#1
    // fgets::@15
    // [1423] fgets::$9 = cbm_k_readst::return#4
    // fp->status = cbm_k_readst()
    // [1424] ((char *)fgets::fp#0)[$13] = fgets::$9 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __9
    ldy #$13
    sta (fp),y
    // fp->status & 0xBF
    // [1425] fgets::$10 = ((char *)fgets::fp#0)[$13] & $bf -- vbuz1=pbuz2_derefidx_vbuc1_band_vbuc2 
    lda #$bf
    and (fp),y
    sta.z __10
    // if(fp->status & 0xBF)
    // [1426] if(0==fgets::$10) goto fgets::@4 -- 0_eq_vbuz1_then_la1 
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [1427] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1428] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1429] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1430] fgets::$14 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z __14
    // if(BYTE1(ptr) == 0xC0)
    // [1431] if(fgets::$14!=$c0) goto fgets::@6 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z __14
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [1432] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1433] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [1433] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [1434] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((fp->status == 0) && ((size && remaining) || !size))
    // [1435] if(((char *)fgets::fp#0)[$13]==0) goto fgets::@16 -- pbuz1_derefidx_vbuc1_eq_0_then_la1 
    ldy #$13
    lda (fp),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [1436] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [1437] cbm_k_chkin::channel = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin.channel
    // [1438] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1411] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [1411] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [1439] cbm_k_macptr::bytes = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cbm_k_macptr.bytes
    // [1440] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1441] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1442] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [1443] fgets::bytes#2 = cbm_k_macptr::return#3
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
    // [1445] return 
    rts
}
  // rom_bank
/**
 * @brief Calculates the 8 bit ROM bank from the 22 bit ROM address.
 * The ROM bank number is calcuated by taking the upper 8 bits (bit 18-14) and shifing those 14 bits to the right.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The ROM bank number for usage in ZP $01.
 */
/* inline */
// __zp($46) char rom_bank(__zp($38) unsigned long address)
rom_bank: {
    .label __1 = $38
    .label __2 = $38
    .label address = $38
    .label return = $7b
    .label return_1 = $46
    .label return_2 = $51
    .label return_3 = $22
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [1447] rom_bank::$2 = rom_bank::address#4 & $3fc000 -- vduz1=vduz1_band_vduc1 
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
    // [1448] rom_bank::$1 = rom_bank::$2 >> $e -- vduz1=vduz1_ror_vbuc1 
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
    // [1449] rom_bank::return#1 = (char)rom_bank::$1 -- vbuz1=_byte_vduz2 
    lda.z __1
    sta.z return_1
    // rom_bank::@return
    // }
    // [1450] return 
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
/* inline */
// __zp($44) char * rom_ptr(__zp($40) unsigned long address)
rom_ptr: {
    .label __0 = $40
    .label __2 = $44
    .label address = $40
    .label return = $44
    // address & ROM_PTR_MASK
    // [1452] rom_ptr::$0 = rom_ptr::address#6 & $3fff -- vduz1=vduz1_band_vduc1 
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
    // [1453] rom_ptr::$2 = (unsigned int)rom_ptr::$0 -- vwuz1=_word_vduz2 
    lda.z __0
    sta.z __2
    lda.z __0+1
    sta.z __2+1
    // [1454] rom_ptr::return#1 = rom_ptr::$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z return
    clc
    adc #<$c000
    sta.z return
    lda.z return+1
    adc #>$c000
    sta.z return+1
    // rom_ptr::@return
    // }
    // [1455] return 
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
/* inline */
// __zp($32) char rom_byte_verify(__zp($44) char *ptr_rom, __zp($63) char value)
rom_byte_verify: {
    .label return = $32
    .label ptr_rom = $44
    .label value = $63
    // if (*ptr_rom != value)
    // [1456] if(*rom_byte_verify::ptr_rom#0==rom_byte_verify::value#0) goto rom_byte_verify::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1457] phi from rom_byte_verify to rom_byte_verify::@2 [phi:rom_byte_verify->rom_byte_verify::@2]
    // rom_byte_verify::@2
    // [1458] phi from rom_byte_verify::@2 to rom_byte_verify::@1 [phi:rom_byte_verify::@2->rom_byte_verify::@1]
    // [1458] phi rom_byte_verify::return#0 = 0 [phi:rom_byte_verify::@2->rom_byte_verify::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [1458] phi from rom_byte_verify to rom_byte_verify::@1 [phi:rom_byte_verify->rom_byte_verify::@1]
  __b2:
    // [1458] phi rom_byte_verify::return#0 = 1 [phi:rom_byte_verify->rom_byte_verify::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_verify::@1
    // rom_byte_verify::@return
    // }
    // [1459] return 
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
// void rom_wait(__zp($33) char *ptr_rom)
rom_wait: {
    .label __0 = $32
    .label __1 = $22
    .label test1 = $32
    .label test2 = $22
    .label ptr_rom = $33
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [1461] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [1462] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [1463] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z __0
    sta.z __0
    // test2 & 0x40
    // [1464] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z __1
    sta.z __1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [1465] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z __0
    cmp.z __1
    bne __b1
    // rom_wait::@return
    // }
    // [1466] return 
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
// void rom_byte_program(__zp($57) unsigned long address, __zp($56) char value)
rom_byte_program: {
    .label ptr_rom = $48
    .label address = $57
    .label value = $56
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1467] rom_ptr::address#3 = rom_byte_program::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [1468] call rom_ptr
    // [1451] phi from rom_byte_program to rom_ptr [phi:rom_byte_program->rom_ptr]
    // [1451] phi rom_ptr::address#6 = rom_ptr::address#3 [phi:rom_byte_program->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_byte_program::@1
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1469] rom_byte_program::ptr_rom#0 = (char *)rom_ptr::return#1 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // rom_write_byte(address, value)
    // [1470] rom_write_byte::address#3 = rom_byte_program::address#0
    // [1471] rom_write_byte::value#3 = rom_byte_program::value#0 -- vbuz1=vbuz2 
    lda.z value
    sta.z rom_write_byte.value
    // [1472] call rom_write_byte
    // [1476] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [1476] phi rom_write_byte::value#4 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [1476] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [1473] rom_wait::ptr_rom#0 = rom_byte_program::ptr_rom#0 -- pbuz1=pbuz2 
    lda.z ptr_rom
    sta.z rom_wait.ptr_rom
    lda.z ptr_rom+1
    sta.z rom_wait.ptr_rom+1
    // [1474] call rom_wait
    // [1460] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [1460] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [1475] return 
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
/* inline */
// void rom_write_byte(__zp($57) unsigned long address, __zp($4a) char value)
rom_write_byte: {
    .label bank_rom = $22
    .label ptr_rom = $2c
    .label address = $57
    .label value = $4a
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1477] rom_bank::address#2 = rom_write_byte::address#4 -- vduz1=vduz2 
    lda.z address
    sta.z rom_bank.address
    lda.z address+1
    sta.z rom_bank.address+1
    lda.z address+2
    sta.z rom_bank.address+2
    lda.z address+3
    sta.z rom_bank.address+3
    // [1478] call rom_bank
    // [1446] phi from rom_write_byte to rom_bank [phi:rom_write_byte->rom_bank]
    // [1446] phi rom_bank::address#4 = rom_bank::address#2 [phi:rom_write_byte->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1479] rom_bank::return#4 = rom_bank::return#1 -- vbuz1=vbuz2 
    lda.z rom_bank.return_1
    sta.z rom_bank.return_3
    // rom_write_byte::@1
    // [1480] rom_write_byte::bank_rom#0 = rom_bank::return#4
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1481] rom_ptr::address#2 = rom_write_byte::address#4 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [1482] call rom_ptr
    // [1451] phi from rom_write_byte::@1 to rom_ptr [phi:rom_write_byte::@1->rom_ptr]
    // [1451] phi rom_ptr::address#6 = rom_ptr::address#2 [phi:rom_write_byte::@1->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_write_byte::@2
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1483] rom_write_byte::ptr_rom#0 = (char *)rom_ptr::return#1 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // bank_set_brom(bank_rom)
    // [1484] bank_set_brom::bank#3 = rom_write_byte::bank_rom#0 -- vbuz1=vbuz2 
    lda.z bank_rom
    sta.z bank_set_brom.bank
    // [1485] call bank_set_brom
    // [811] phi from rom_write_byte::@2 to bank_set_brom [phi:rom_write_byte::@2->bank_set_brom]
    // [811] phi bank_set_brom::bank#12 = bank_set_brom::bank#3 [phi:rom_write_byte::@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_write_byte::@3
    // *ptr_rom = value
    // [1486] *rom_write_byte::ptr_rom#0 = rom_write_byte::value#4 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (ptr_rom),y
    // rom_write_byte::@return
    // }
    // [1487] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label __0 = $78
    .label __4 = $60
    .label __6 = $68
    .label __7 = $60
    .label width = $78
    .label y = $5d
    // __conio.width+1
    // [1488] insertup::$0 = *((char *)&__conio+4) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+4
    inc
    sta.z __0
    // unsigned char width = (__conio.width+1) * 2
    // [1489] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z width
    // [1490] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1490] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1491] if(insertup::y#2<=*((char *)&__conio+$e)) goto insertup::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+$e
    cmp.z y
    bcs __b2
    // [1492] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1493] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1494] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1495] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z __4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1496] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z __6
    // [1497] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __7
    // [1498] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.dbank_vram
    // [1499] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1500] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.sbank_vram
    // [1501] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1502] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [1503] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1504] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1490] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1490] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label __0 = $4c
    .label __1 = $4f
    .label __2 = $50
    .label __3 = $4d
    .label addr = $5e
    .label c = $35
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1505] clearline::$3 = *((char *)&__conio+$e) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    sta.z __3
    // [1506] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1507] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1508] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z __0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1509] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1510] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z __1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1511] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1512] clearline::$2 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1513] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1514] clearline::c#0 = *((char *)&__conio+4) -- vbuz1=_deref_pbuc1 
    lda __conio+4
    sta.z c
    // [1515] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1515] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1516] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1517] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [1518] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1519] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1520] return 
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
// __zp($28) unsigned int utoa_append(__zp($48) char *buffer, __zp($28) unsigned int value, __zp($2c) unsigned int sub)
utoa_append: {
    .label buffer = $48
    .label value = $28
    .label sub = $2c
    .label return = $28
    .label digit = $22
    // [1522] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1522] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1522] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1523] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1524] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1525] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1526] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1527] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1522] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1522] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1522] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label __0 = $37
    .label src = $2c
    // [1529] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1529] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1530] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1531] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1532] toupper::ch#0 = *strupr::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z toupper.ch
    // [1533] call toupper
    jsr toupper
    // [1534] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1535] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1536] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbuz2 
    lda.z __0
    ldy #0
    sta (src),y
    // src++;
    // [1537] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1529] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1529] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
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
// __zp($27) char uctoa_append(__zp($2c) char *buffer, __zp($27) char value, __zp($22) char sub)
uctoa_append: {
    .label buffer = $2c
    .label value = $27
    .label sub = $22
    .label return = $27
    .label digit = $2a
    // [1539] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1539] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1539] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1540] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1541] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1542] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1543] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1544] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [1539] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1539] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1539] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($23) unsigned long value, __zp($48) char *buffer, char radix)
ultoa: {
    .label __10 = $4e
    .label __11 = $4b
    .label digit_value = $2e
    .label buffer = $48
    .label digit = $37
    .label value = $23
    .label started = $54
    // [1546] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1546] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1546] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1546] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1546] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1547] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1548] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z __11
    // [1549] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1550] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1551] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1552] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1553] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z __10
    // [1554] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [1555] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [1556] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1557] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1557] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1557] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1557] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1558] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1546] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1546] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1546] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1546] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1546] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1559] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1560] ultoa_append::value#0 = ultoa::value#2
    // [1561] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1562] call ultoa_append
    // [1596] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1563] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1564] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1565] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1557] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1557] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1557] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1557] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
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
// __zp($48) unsigned int cbm_k_macptr(__zp($a9) volatile char bytes, __zp($7d) void * volatile buffer)
cbm_k_macptr: {
    .label bytes = $a9
    .label buffer = $7d
    .label return = $48
    // __mem unsigned int bytes_read
    // [1566] cbm_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [1568] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwuz1=vwum2 
    lda bytes_read
    sta.z return
    lda bytes_read+1
    sta.z return+1
    // cbm_k_macptr::@return
    // }
    // [1569] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [1570] return 
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
// void memcpy8_vram_vram(__zp($4d) char dbank_vram, __zp($5e) unsigned int doffset_vram, __zp($4c) char sbank_vram, __zp($5b) unsigned int soffset_vram, __zp($36) char num8)
memcpy8_vram_vram: {
    .label __0 = $4f
    .label __1 = $50
    .label __2 = $4c
    .label __3 = $52
    .label __4 = $53
    .label __5 = $4d
    .label num8 = $36
    .label dbank_vram = $4d
    .label doffset_vram = $5e
    .label sbank_vram = $4c
    .label soffset_vram = $5b
    .label num8_1 = $35
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1571] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1572] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z __0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1573] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1574] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z __1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1575] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1576] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z __2
    sta.z __2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1577] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1578] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1579] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z __3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1580] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1581] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z __4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1582] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1583] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z __5
    sta.z __5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1584] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1585] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1585] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1586] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [1587] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1588] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1589] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1590] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
    lda.z num8
    sta.z num8_1
    jmp __b1
}
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __zp($37) char toupper(__zp($37) char ch)
toupper: {
    .label return = $37
    .label ch = $37
    // if(ch>='a' && ch<='z')
    // [1591] if(toupper::ch#0<'a'pm) goto toupper::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z ch
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1592] if(toupper::ch#0<='z'pm) goto toupper::@1 -- vbuz1_le_vbuc1_then_la1 
    lda #'z'
    cmp.z ch
    bcs __b1
    // [1594] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1594] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1593] toupper::return#0 = toupper::ch#0 + 'A'pm-'a'pm -- vbuz1=vbuz1_plus_vbuc1 
    lda #'A'-'a'
    clc
    adc.z return
    sta.z return
    // toupper::@return
  __breturn:
    // }
    // [1595] return 
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
// __zp($23) unsigned long ultoa_append(__zp($2c) char *buffer, __zp($23) unsigned long value, __zp($2e) unsigned long sub)
ultoa_append: {
    .label buffer = $2c
    .label value = $23
    .label sub = $2e
    .label return = $23
    .label digit = $2b
    // [1597] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1597] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1597] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1598] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [1599] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1600] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1601] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1602] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [1597] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1597] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1597] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
