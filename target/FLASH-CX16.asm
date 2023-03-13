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
  .label __snprintf_buffer = $e4
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
    // [16] *__snprintf_buffer = snputc::c#2 -- _deref_pbuz1=vbuxx 
    // Append char
    txa
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
    .label __4 = $bb
    .label __6 = $bb
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [514] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [519] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuxx=vbuc1 
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
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuaa=_byte1_vwuz1 
    lda.z __4+1
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
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuaa=_byte0_vwuz1 
    lda.z __6
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+$e) = conio_x16_init::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+$e
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#1 = *((char *)&__conio+$d) -- vbuxx=_deref_pbuc1 
    ldx __conio+$d
    // [38] gotoxy::y#1 = *((char *)&__conio+$e) -- vbuyy=_deref_pbuc1 
    tay
    // [39] call gotoxy
    // [532] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .const bank_set_bram1_bank = 1
    .const bank_set_bram2_bank = 1
    .const bank_set_bram3_bank = 1
    .const bank_set_bram4_bank = 1
    .label __20 = $4a
    .label __66 = $e3
    .label __101 = $59
    .label __127 = $ab
    .label __167 = $4b
    .label r = $da
    .label rom_chip = $e2
    .label flash_rom_address = $dd
    .label flash_chip = $e1
    .label flash_rom_bank = $ed
    .label fp = $e6
    .label flash_rom_address_boundary = $60
    .label flash_bytes = $74
    .label flash_rom_address_boundary_1 = $34
    .label flash_bytes_1 = $d6
    .label flash_rom_address1 = $7a
    .label equal_bytes = $5d
    .label flash_rom_address_sector = $bf
    .label read_ram_address = $b9
    .label x_sector = $c6
    .label read_ram_bank = $b6
    .label y_sector = $c7
    .label equal_bytes1 = $5d
    .label read_ram_address_sector = $b7
    .label flash_rom_address_boundary1 = $ca
    .label read_ram_address1 = $b3
    .label flash_rom_address2 = $af
    .label x1 = $7f
    .label x_sector1 = $be
    .label read_ram_bank_sector = $b5
    .label y_sector1 = $c3
    .label v = $c4
    .label w = $db
    .label rom_device = $ea
    .label flash_rom_address_boundary_2 = $d6
    .label pattern = $d3
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@54
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
    // [75] phi from main::@54 to main::@63 [phi:main::@54->main::@63]
    // main::@63
    // textcolor(WHITE)
    // [76] call textcolor
    // [514] phi from main::@63 to textcolor [phi:main::@63->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@63->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [77] phi from main::@63 to main::@64 [phi:main::@63->main::@64]
    // main::@64
    // bgcolor(BLUE)
    // [78] call bgcolor
    // [519] phi from main::@64 to bgcolor [phi:main::@64->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:main::@64->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [79] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
    // scroll(0)
    // [80] call scroll
    jsr scroll
    // [81] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // clrscr()
    // [82] call clrscr
    jsr clrscr
    // [83] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // frame_draw()
    // [84] call frame_draw
    // [580] phi from main::@67 to frame_draw [phi:main::@67->frame_draw]
    jsr frame_draw
    // [85] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // gotoxy(2, 1)
    // [86] call gotoxy
    // [532] phi from main::@68 to gotoxy [phi:main::@68->gotoxy]
    // [532] phi gotoxy::y#26 = 1 [phi:main::@68->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [532] phi gotoxy::x#26 = 2 [phi:main::@68->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // [87] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // printf("commander x16 rom flash utility")
    // [88] call printf_str
    // [760] phi from main::@69 to printf_str [phi:main::@69->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@69->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s [phi:main::@69->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [89] phi from main::@69 to main::@1 [phi:main::@69->main::@1]
    // [89] phi main::r#10 = 0 [phi:main::@69->main::@1#0] -- vbuz1=vbuc1 
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
    // [94] phi from main::CLI1 to main::@55 [phi:main::CLI1->main::@55]
    // main::@55
    // sprintf(buffer, "press a key to start flashing.")
    // [95] call snprintf_init
    jsr snprintf_init
    // [96] phi from main::@55 to main::@81 [phi:main::@55->main::@81]
    // main::@81
    // sprintf(buffer, "press a key to start flashing.")
    // [97] call printf_str
    // [760] phi from main::@81 to printf_str [phi:main::@81->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@81->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s1 [phi:main::@81->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@82
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
    // [773] phi from main::@82 to print_text [phi:main::@82->print_text]
    jsr print_text
    // [102] phi from main::@82 to main::@83 [phi:main::@82->main::@83]
    // main::@83
    // wait_key()
    // [103] call wait_key
    // [780] phi from main::@83 to wait_key [phi:main::@83->wait_key]
    jsr wait_key
    // [104] phi from main::@83 to main::@15 [phi:main::@83->main::@15]
    // [104] phi main::flash_chip#10 = 7 [phi:main::@83->main::@15#0] -- vbuz1=vbuc1 
    lda #7
    sta.z flash_chip
    // main::@15
  __b15:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [105] if(main::flash_chip#10!=$ff) goto main::@16 -- vbuz1_neq_vbuc1_then_la1 
    lda #$ff
    cmp.z flash_chip
    beq !__b16+
    jmp __b16
  !__b16:
    // [106] phi from main::@15 to main::@17 [phi:main::@15->main::@17]
    // main::@17
    // bank_set_brom(0)
    // [107] call bank_set_brom
    // [790] phi from main::@17 to bank_set_brom [phi:main::@17->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 0 [phi:main::@17->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #0
    jsr bank_set_brom
    // [108] phi from main::@17 to main::@92 [phi:main::@17->main::@92]
    // main::@92
    // textcolor(WHITE)
    // [109] call textcolor
    // [514] phi from main::@92 to textcolor [phi:main::@92->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@92->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [110] phi from main::@92 to main::@49 [phi:main::@92->main::@49]
    // [110] phi main::w#10 = $80 [phi:main::@92->main::@49#0] -- vwsz1=vwsc1 
    lda #<$80
    sta.z w
    lda #>$80
    sta.z w+1
    // main::@49
  __b49:
    // for (int w = 128; w >= 0; w--)
    // [111] if(main::w#10>=0) goto main::@51 -- vwsz1_ge_0_then_la1 
    lda.z w+1
    bpl __b9
    // [112] phi from main::@49 to main::@50 [phi:main::@49->main::@50]
    // main::@50
    // system_reset()
    // [113] call system_reset
    // [793] phi from main::@50 to system_reset [phi:main::@50->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [114] return 
    rts
    // [115] phi from main::@49 to main::@51 [phi:main::@49->main::@51]
  __b9:
    // [115] phi main::v#2 = 0 [phi:main::@49->main::@51#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z v
    sta.z v+1
    // main::@51
  __b51:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [116] if(main::v#2<$100*$80) goto main::@52 -- vwuz1_lt_vwuc1_then_la1 
    lda.z v+1
    cmp #>$100*$80
    bcc __b52
    bne !+
    lda.z v
    cmp #<$100*$80
    bcc __b52
  !:
    // [117] phi from main::@51 to main::@53 [phi:main::@51->main::@53]
    // main::@53
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [118] call snprintf_init
    jsr snprintf_init
    // [119] phi from main::@53 to main::@184 [phi:main::@53->main::@184]
    // main::@184
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [120] call printf_str
    // [760] phi from main::@184 to printf_str [phi:main::@184->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@184->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s31 [phi:main::@184->printf_str#1] -- pbuz1=pbuc1 
    lda #<s31
    sta.z printf_str.s
    lda #>s31
    sta.z printf_str.s+1
    jsr printf_str
    // main::@185
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [121] printf_sint::value#1 = main::w#10 -- vwsz1=vwsz2 
    lda.z w
    sta.z printf_sint.value
    lda.z w+1
    sta.z printf_sint.value+1
    // [122] call printf_sint
    jsr printf_sint
    // [123] phi from main::@185 to main::@186 [phi:main::@185->main::@186]
    // main::@186
    // sprintf(buffer, "resetting commander x16 (%i)", w)
    // [124] call printf_str
    // [760] phi from main::@186 to printf_str [phi:main::@186->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@186->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s32 [phi:main::@186->printf_str#1] -- pbuz1=pbuc1 
    lda #<s32
    sta.z printf_str.s
    lda #>s32
    sta.z printf_str.s+1
    jsr printf_str
    // main::@187
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
    // [773] phi from main::@187 to print_text [phi:main::@187->print_text]
    jsr print_text
    // main::@188
    // for (int w = 128; w >= 0; w--)
    // [129] main::w#1 = -- main::w#10 -- vwsz1=_dec_vwsz1 
    lda.z w
    bne !+
    dec.z w+1
  !:
    dec.z w
    // [110] phi from main::@188 to main::@49 [phi:main::@188->main::@49]
    // [110] phi main::w#10 = main::w#1 [phi:main::@188->main::@49#0] -- register_copy 
    jmp __b49
    // main::@52
  __b52:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [130] main::v#1 = ++ main::v#2 -- vwuz1=_inc_vwuz1 
    inc.z v
    bne !+
    inc.z v+1
  !:
    // [115] phi from main::@52 to main::@51 [phi:main::@52->main::@51]
    // [115] phi main::v#2 = main::v#1 [phi:main::@52->main::@51#0] -- register_copy 
    jmp __b51
    // main::@16
  __b16:
    // if (rom_device_ids[flash_chip] != UNKNOWN)
    // [131] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@18 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b18+
    jmp __b18
  !__b18:
    // [132] phi from main::@16 to main::@47 [phi:main::@16->main::@47]
    // main::@47
    // gotoxy(0, 2)
    // [133] call gotoxy
    // [532] phi from main::@47 to gotoxy [phi:main::@47->gotoxy]
    // [532] phi gotoxy::y#26 = 2 [phi:main::@47->gotoxy#0] -- vbuyy=vbuc1 
    ldy #2
    // [532] phi gotoxy::x#26 = 0 [phi:main::@47->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [134] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [135] phi from main::bank_set_bram1 to main::@56 [phi:main::bank_set_bram1->main::@56]
    // main::@56
    // bank_set_brom(4)
    // [136] call bank_set_brom
    // [790] phi from main::@56 to bank_set_brom [phi:main::@56->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 4 [phi:main::@56->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::@93
    // if (flash_chip == 0)
    // [137] if(main::flash_chip#10==0) goto main::@19 -- vbuz1_eq_0_then_la1 
    lda.z flash_chip
    bne !__b19+
    jmp __b19
  !__b19:
    // [138] phi from main::@93 to main::@48 [phi:main::@93->main::@48]
    // main::@48
    // sprintf(file, "rom%u.bin", flash_chip)
    // [139] call snprintf_init
    jsr snprintf_init
    // [140] phi from main::@48 to main::@96 [phi:main::@48->main::@96]
    // main::@96
    // sprintf(file, "rom%u.bin", flash_chip)
    // [141] call printf_str
    // [760] phi from main::@96 to printf_str [phi:main::@96->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@96->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s3 [phi:main::@96->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@97
    // sprintf(file, "rom%u.bin", flash_chip)
    // [142] printf_uchar::uvalue#2 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [143] call printf_uchar
    // [809] phi from main::@97 to printf_uchar [phi:main::@97->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@97->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 0 [phi:main::@97->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &snputc [phi:main::@97->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = DECIMAL [phi:main::@97->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#2 [phi:main::@97->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [144] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // sprintf(file, "rom%u.bin", flash_chip)
    // [145] call printf_str
    // [760] phi from main::@98 to printf_str [phi:main::@98->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@98->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s4 [phi:main::@98->printf_str#1] -- pbuz1=pbuc1 
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
    // main::@20
  __b20:
    // unsigned char flash_rom_bank = flash_chip * 32
    // [149] main::flash_rom_bank#0 = main::flash_chip#10 << 5 -- vbuz1=vbuz2_rol_5 
    lda.z flash_chip
    asl
    asl
    asl
    asl
    asl
    sta.z flash_rom_bank
    // FILE *fp = fopen(1, 8, 2, file)
    // [150] call fopen
    // Read the file content.
    jsr fopen
    // [151] fopen::return#4 = fopen::return#1
    // main::@100
    // [152] main::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [153] if((struct $1 *)0!=main::fp#0) goto main::@21 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    beq !__b21+
    jmp __b21
  !__b21:
    lda.z fp
    cmp #<0
    beq !__b21+
    jmp __b21
  !__b21:
    // [154] phi from main::@100 to main::@45 [phi:main::@100->main::@45]
    // main::@45
    // textcolor(WHITE)
    // [155] call textcolor
    // [514] phi from main::@45 to textcolor [phi:main::@45->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@45->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [156] phi from main::@45 to main::@114 [phi:main::@45->main::@114]
    // main::@114
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [157] call snprintf_init
    jsr snprintf_init
    // [158] phi from main::@114 to main::@115 [phi:main::@114->main::@115]
    // main::@115
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [159] call printf_str
    // [760] phi from main::@115 to printf_str [phi:main::@115->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@115->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s7 [phi:main::@115->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@116
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [160] printf_uchar::uvalue#4 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [161] call printf_uchar
    // [809] phi from main::@116 to printf_uchar [phi:main::@116->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@116->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 0 [phi:main::@116->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &snputc [phi:main::@116->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = DECIMAL [phi:main::@116->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#4 [phi:main::@116->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [162] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // sprintf(buffer, "there is no file on the sdcard to flash rom%u. press a key ...", flash_chip)
    // [163] call printf_str
    // [760] phi from main::@117 to printf_str [phi:main::@117->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@117->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s8 [phi:main::@117->printf_str#1] -- pbuz1=pbuc1 
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
    // [773] phi from main::@118 to print_text [phi:main::@118->print_text]
    jsr print_text
    // main::@119
    // flash_chip * 10
    // [168] main::$214 = main::flash_chip#10 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z flash_chip
    asl
    asl
    // [169] main::$215 = main::$214 + main::flash_chip#10 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z flash_chip
    // [170] main::$84 = main::$215 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(2 + flash_chip * 10, 58)
    // [171] gotoxy::x#17 = 2 + main::$84 -- vbuxx=vbuc1_plus_vbuaa 
    clc
    adc #2
    tax
    // [172] call gotoxy
    // [532] phi from main::@119 to gotoxy [phi:main::@119->gotoxy]
    // [532] phi gotoxy::y#26 = $3a [phi:main::@119->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$3a
    // [532] phi gotoxy::x#26 = gotoxy::x#17 [phi:main::@119->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [173] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // printf("no file")
    // [174] call printf_str
    // [760] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s9 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@121
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [175] print_chip_led::r#6 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [176] call print_chip_led
    // [857] phi from main::@121 to print_chip_led [phi:main::@121->print_chip_led]
    // [857] phi print_chip_led::tc#10 = DARK_GREY [phi:main::@121->print_chip_led#0] -- vbuz1=vbuc1 
    lda #DARK_GREY
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#6 [phi:main::@121->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::CLI2
  CLI2:
    // asm
    // asm { cli  }
    cli
    // main::@57
    // if (flash_chip != 0)
    // [178] if(main::flash_chip#10==0) goto main::@18 -- vbuz1_eq_0_then_la1 
    lda.z flash_chip
    beq __b18
    // [179] phi from main::@57 to main::@46 [phi:main::@57->main::@46]
    // main::@46
    // bank_set_brom(4)
    // [180] call bank_set_brom
    // [790] phi from main::@46 to bank_set_brom [phi:main::@46->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 4 [phi:main::@46->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // [181] phi from main::@46 to main::@183 [phi:main::@46->main::@183]
    // main::@183
    // wait_key()
    // [182] call wait_key
    // [780] phi from main::@183 to wait_key [phi:main::@183->wait_key]
    jsr wait_key
    // main::@18
  __b18:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [183] main::flash_chip#1 = -- main::flash_chip#10 -- vbuz1=_dec_vbuz1 
    dec.z flash_chip
    // [104] phi from main::@18 to main::@15 [phi:main::@18->main::@15]
    // [104] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@18->main::@15#0] -- register_copy 
    jmp __b15
    // main::@21
  __b21:
    // table_chip_clear(flash_chip * 32)
    // [184] table_chip_clear::rom_bank#1 = main::flash_chip#10 << 5 -- vbuz1=vbuz2_rol_5 
    lda.z flash_chip
    asl
    asl
    asl
    asl
    asl
    sta.z table_chip_clear.rom_bank
    // [185] call table_chip_clear
    // [877] phi from main::@21 to table_chip_clear [phi:main::@21->table_chip_clear]
    jsr table_chip_clear
    // [186] phi from main::@21 to main::@101 [phi:main::@21->main::@101]
    // main::@101
    // textcolor(WHITE)
    // [187] call textcolor
    // [514] phi from main::@101 to textcolor [phi:main::@101->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@101->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@102
    // flash_chip * 10
    // [188] main::$211 = main::flash_chip#10 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z flash_chip
    asl
    asl
    // [189] main::$212 = main::$211 + main::flash_chip#10 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z flash_chip
    // [190] main::$92 = main::$212 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(2 + flash_chip * 10, 58)
    // [191] gotoxy::x#16 = 2 + main::$92 -- vbuxx=vbuc1_plus_vbuaa 
    clc
    adc #2
    tax
    // [192] call gotoxy
    // [532] phi from main::@102 to gotoxy [phi:main::@102->gotoxy]
    // [532] phi gotoxy::y#26 = $3a [phi:main::@102->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$3a
    // [532] phi gotoxy::x#26 = gotoxy::x#16 [phi:main::@102->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [193] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // printf("%s", file)
    // [194] call printf_string
    // [902] phi from main::@103 to printf_string [phi:main::@103->printf_string]
    // [902] phi printf_string::str#10 = main::buffer [phi:main::@103->printf_string#0] -- pbuz1=pbuc1 
    lda #<buffer
    sta.z printf_string.str
    lda #>buffer
    sta.z printf_string.str+1
    // [902] phi printf_string::format_justify_left#10 = 0 [phi:main::@103->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [902] phi printf_string::format_min_length#7 = 0 [phi:main::@103->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@104
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [195] print_chip_led::r#5 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [196] call print_chip_led
    // [857] phi from main::@104 to print_chip_led [phi:main::@104->print_chip_led]
    // [857] phi print_chip_led::tc#10 = CYAN [phi:main::@104->print_chip_led#0] -- vbuz1=vbuc1 
    lda #CYAN
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#5 [phi:main::@104->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [197] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [198] call snprintf_init
    jsr snprintf_init
    // [199] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [200] call printf_str
    // [760] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s5 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [201] printf_uchar::uvalue#3 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [202] call printf_uchar
    // [809] phi from main::@107 to printf_uchar [phi:main::@107->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@107->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 0 [phi:main::@107->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &snputc [phi:main::@107->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = DECIMAL [phi:main::@107->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#3 [phi:main::@107->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [203] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [204] call printf_str
    // [760] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s6 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // sprintf(buffer, "reading file for rom%u in ram ...", flash_chip)
    // [205] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [206] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [208] call print_text
    // [773] phi from main::@109 to print_text [phi:main::@109->print_text]
    jsr print_text
    // main::@110
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [209] rom_address::rom_bank#2 = main::flash_rom_bank#0 -- vbuaa=vbuz1 
    lda.z flash_rom_bank
    // [210] call rom_address
    // [924] phi from main::@110 to rom_address [phi:main::@110->rom_address]
    // [924] phi rom_address::rom_bank#5 = rom_address::rom_bank#2 [phi:main::@110->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [211] rom_address::return#10 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_2
    lda.z rom_address.return+1
    sta.z rom_address.return_2+1
    lda.z rom_address.return+2
    sta.z rom_address.return_2+2
    lda.z rom_address.return+3
    sta.z rom_address.return_2+3
    // main::@111
    // [212] main::flash_rom_address_boundary#0 = rom_address::return#10
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [213] flash_read::fp#0 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [214] flash_read::rom_bank_start#1 = main::flash_rom_bank#0 -- vbuz1=vbuz2 
    lda.z flash_rom_bank
    sta.z flash_read.rom_bank_start
    // [215] call flash_read
    // [928] phi from main::@111 to flash_read [phi:main::@111->flash_read]
    // [928] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@111->flash_read#0] -- register_copy 
    // [928] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@111->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [928] phi flash_read::rom_bank_size#2 = 1 [phi:main::@111->flash_read#2] -- vbuxx=vbuc1 
    ldx #1
    // [928] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@111->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [216] flash_read::return#3 = flash_read::return#2
    // main::@112
    // [217] main::flash_bytes#0 = flash_read::return#3
    // rom_size(1)
    // [218] call rom_size
    // [964] phi from main::@112 to rom_size [phi:main::@112->rom_size]
    // [964] phi rom_size::rom_banks#2 = 1 [phi:main::@112->rom_size#0] -- vbuaa=vbuc1 
    lda #1
    jsr rom_size
    // rom_size(1)
    // [219] rom_size::return#3 = rom_size::return#0
    // main::@113
    // [220] main::$101 = rom_size::return#3
    // if (flash_bytes != rom_size(1))
    // [221] if(main::flash_bytes#0==main::$101) goto main::@22 -- vduz1_eq_vduz2_then_la1 
    lda.z flash_bytes
    cmp.z __101
    bne !+
    lda.z flash_bytes+1
    cmp.z __101+1
    bne !+
    lda.z flash_bytes+2
    cmp.z __101+2
    bne !+
    lda.z flash_bytes+3
    cmp.z __101+3
    beq __b22
  !:
    rts
    // main::@22
  __b22:
    // flash_rom_address_boundary += flash_bytes
    // [222] main::flash_rom_address_boundary#1 = main::flash_rom_address_boundary#0 + main::flash_bytes#0 -- vduz1=vduz2_plus_vduz3 
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
    // [223] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@58
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [224] flash_read::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z flash_rom_bank
    inc
    sta.z flash_read.rom_bank_start
    // [225] flash_read::fp#1 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [226] call flash_read
    // [928] phi from main::@58 to flash_read [phi:main::@58->flash_read]
    // [928] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@58->flash_read#0] -- register_copy 
    // [928] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@58->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [928] phi flash_read::rom_bank_size#2 = $1f [phi:main::@58->flash_read#2] -- vbuxx=vbuc1 
    ldx #$1f
    // [928] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@58->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [227] flash_read::return#4 = flash_read::return#2
    // main::@122
    // flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [228] main::flash_bytes#1 = flash_read::return#4 -- vduz1=vduz2 
    lda.z flash_read.return
    sta.z flash_bytes_1
    lda.z flash_read.return+1
    sta.z flash_bytes_1+1
    lda.z flash_read.return+2
    sta.z flash_bytes_1+2
    lda.z flash_read.return+3
    sta.z flash_bytes_1+3
    // flash_rom_address_boundary += flash_bytes
    // [229] main::flash_rom_address_boundary#11 = main::flash_rom_address_boundary#1 + main::flash_bytes#1 -- vduz1=vduz2_plus_vduz1 
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
    // [230] fclose::fp#0 = main::fp#0
    // [231] call fclose
    jsr fclose
    // main::bank_set_bram3
    // BRAM = bank
    // [232] BRAM = main::bank_set_bram3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram3_bank
    sta.z BRAM
    // [233] phi from main::bank_set_bram3 to main::@59 [phi:main::bank_set_bram3->main::@59]
    // main::@59
    // bank_set_brom(4)
    // [234] call bank_set_brom
    // [790] phi from main::@59 to bank_set_brom [phi:main::@59->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 4 [phi:main::@59->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // [235] phi from main::@59 to main::@123 [phi:main::@59->main::@123]
    // main::@123
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [236] call snprintf_init
    jsr snprintf_init
    // [237] phi from main::@123 to main::@124 [phi:main::@123->main::@124]
    // main::@124
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [238] call printf_str
    // [760] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s10 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@125
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [239] printf_uchar::uvalue#5 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [240] call printf_uchar
    // [809] phi from main::@125 to printf_uchar [phi:main::@125->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@125->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 0 [phi:main::@125->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &snputc [phi:main::@125->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = DECIMAL [phi:main::@125->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#5 [phi:main::@125->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [241] phi from main::@125 to main::@126 [phi:main::@125->main::@126]
    // main::@126
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [242] call printf_str
    // [760] phi from main::@126 to printf_str [phi:main::@126->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@126->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s11 [phi:main::@126->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@127
    // sprintf(buffer, "verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [243] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [244] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [246] call print_text
    // [773] phi from main::@127 to print_text [phi:main::@127->print_text]
    jsr print_text
    // main::@128
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [247] rom_address::rom_bank#3 = main::flash_rom_bank#0 -- vbuaa=vbuz1 
    lda.z flash_rom_bank
    // [248] call rom_address
    // [924] phi from main::@128 to rom_address [phi:main::@128->rom_address]
    // [924] phi rom_address::rom_bank#5 = rom_address::rom_bank#3 [phi:main::@128->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [249] rom_address::return#11 = rom_address::return#0
    // main::@129
    // [250] main::flash_rom_address1#0 = rom_address::return#11
    // gotoxy(x, y)
    // [251] call gotoxy
    // [532] phi from main::@129 to gotoxy [phi:main::@129->gotoxy]
    // [532] phi gotoxy::y#26 = 4 [phi:main::@129->gotoxy#0] -- vbuyy=vbuc1 
    ldy #4
    // [532] phi gotoxy::x#26 = $e [phi:main::@129->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$e
    jsr gotoxy
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [253] phi from main::SEI2 to main::@23 [phi:main::SEI2->main::@23]
    // [253] phi main::y_sector#10 = 4 [phi:main::SEI2->main::@23#0] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector
    // [253] phi main::x_sector#10 = $e [phi:main::SEI2->main::@23#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [253] phi main::read_ram_address#10 = (char *) 16384 [phi:main::SEI2->main::@23#2] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address
    lda #>$4000
    sta.z read_ram_address+1
    // [253] phi main::read_ram_bank#12 = 1 [phi:main::SEI2->main::@23#3] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank
    // [253] phi main::flash_rom_address1#10 = main::flash_rom_address1#0 [phi:main::SEI2->main::@23#4] -- register_copy 
    // [253] phi from main::@29 to main::@23 [phi:main::@29->main::@23]
    // [253] phi main::y_sector#10 = main::y_sector#10 [phi:main::@29->main::@23#0] -- register_copy 
    // [253] phi main::x_sector#10 = main::x_sector#1 [phi:main::@29->main::@23#1] -- register_copy 
    // [253] phi main::read_ram_address#10 = main::read_ram_address#14 [phi:main::@29->main::@23#2] -- register_copy 
    // [253] phi main::read_ram_bank#12 = main::read_ram_bank#10 [phi:main::@29->main::@23#3] -- register_copy 
    // [253] phi main::flash_rom_address1#10 = main::flash_rom_address1#1 [phi:main::@29->main::@23#4] -- register_copy 
    // main::@23
  __b23:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [254] if(main::flash_rom_address1#10<main::flash_rom_address_boundary#11) goto main::@24 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address1+3
    cmp.z flash_rom_address_boundary_2+3
    bcs !__b24+
    jmp __b24
  !__b24:
    bne !+
    lda.z flash_rom_address1+2
    cmp.z flash_rom_address_boundary_2+2
    bcs !__b24+
    jmp __b24
  !__b24:
    bne !+
    lda.z flash_rom_address1+1
    cmp.z flash_rom_address_boundary_2+1
    bcs !__b24+
    jmp __b24
  !__b24:
    bne !+
    lda.z flash_rom_address1
    cmp.z flash_rom_address_boundary_2
    bcs !__b24+
    jmp __b24
  !__b24:
  !:
    // [255] phi from main::@23 to main::@25 [phi:main::@23->main::@25]
    // main::@25
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [256] call snprintf_init
    jsr snprintf_init
    // [257] phi from main::@25 to main::@131 [phi:main::@25->main::@131]
    // main::@131
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [258] call printf_str
    // [760] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s12 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@132
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [259] printf_uchar::uvalue#6 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [260] call printf_uchar
    // [809] phi from main::@132 to printf_uchar [phi:main::@132->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@132->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 0 [phi:main::@132->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &snputc [phi:main::@132->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = DECIMAL [phi:main::@132->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#6 [phi:main::@132->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [261] phi from main::@132 to main::@133 [phi:main::@132->main::@133]
    // main::@133
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [262] call printf_str
    // [760] phi from main::@133 to printf_str [phi:main::@133->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@133->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s13 [phi:main::@133->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@134
    // sprintf(buffer, "verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [263] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [264] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [266] call print_text
    // [773] phi from main::@134 to print_text [phi:main::@134->print_text]
    jsr print_text
    // [267] phi from main::@134 to main::@135 [phi:main::@134->main::@135]
    // main::@135
    // bank_set_brom(4)
    // [268] call bank_set_brom
    // [790] phi from main::@135 to bank_set_brom [phi:main::@135->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 4 [phi:main::@135->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // [270] phi from main::CLI3 to main::@60 [phi:main::CLI3->main::@60]
    // main::@60
    // wait_key()
    // [271] call wait_key
    // [780] phi from main::@60 to wait_key [phi:main::@60->wait_key]
    jsr wait_key
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::@61
    // rom_address(flash_rom_bank)
    // [273] rom_address::rom_bank#4 = main::flash_rom_bank#0 -- vbuaa=vbuz1 
    lda.z flash_rom_bank
    // [274] call rom_address
    // [924] phi from main::@61 to rom_address [phi:main::@61->rom_address]
    // [924] phi rom_address::rom_bank#5 = rom_address::rom_bank#4 [phi:main::@61->rom_address#0] -- register_copy 
    jsr rom_address
    // rom_address(flash_rom_bank)
    // [275] rom_address::return#12 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_3
    lda.z rom_address.return+1
    sta.z rom_address.return_3+1
    lda.z rom_address.return+2
    sta.z rom_address.return_3+2
    lda.z rom_address.return+3
    sta.z rom_address.return_3+3
    // main::@136
    // flash_rom_address_sector = rom_address(flash_rom_bank)
    // [276] main::flash_rom_address_sector#1 = rom_address::return#12
    // textcolor(WHITE)
    // [277] call textcolor
    // [514] phi from main::@136 to textcolor [phi:main::@136->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@136->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@137
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [278] print_chip_led::r#7 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [279] call print_chip_led
    // [857] phi from main::@137 to print_chip_led [phi:main::@137->print_chip_led]
    // [857] phi print_chip_led::tc#10 = PURPLE [phi:main::@137->print_chip_led#0] -- vbuz1=vbuc1 
    lda #PURPLE
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#7 [phi:main::@137->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [280] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [281] call snprintf_init
    jsr snprintf_init
    // [282] phi from main::@138 to main::@139 [phi:main::@138->main::@139]
    // main::@139
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [283] call printf_str
    // [760] phi from main::@139 to printf_str [phi:main::@139->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@139->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s14 [phi:main::@139->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@140
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [284] printf_uchar::uvalue#7 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [285] call printf_uchar
    // [809] phi from main::@140 to printf_uchar [phi:main::@140->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@140->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 0 [phi:main::@140->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &snputc [phi:main::@140->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = DECIMAL [phi:main::@140->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#7 [phi:main::@140->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [286] phi from main::@140 to main::@141 [phi:main::@140->main::@141]
    // main::@141
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [287] call printf_str
    // [760] phi from main::@141 to printf_str [phi:main::@141->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@141->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s15 [phi:main::@141->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@142
    // sprintf(buffer, "flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [288] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [289] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [291] call print_text
    // [773] phi from main::@142 to print_text [phi:main::@142->print_text]
    jsr print_text
    // [292] phi from main::@142 to main::@32 [phi:main::@142->main::@32]
    // [292] phi main::y_sector1#13 = 4 [phi:main::@142->main::@32#0] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector1
    // [292] phi main::x_sector1#10 = $e [phi:main::@142->main::@32#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector1
    // [292] phi main::read_ram_address_sector#10 = (char *) 16384 [phi:main::@142->main::@32#2] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address_sector
    lda #>$4000
    sta.z read_ram_address_sector+1
    // [292] phi main::read_ram_bank_sector#10 = 1 [phi:main::@142->main::@32#3] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank_sector
    // [292] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#1 [phi:main::@142->main::@32#4] -- register_copy 
    // [292] phi from main::@40 to main::@32 [phi:main::@40->main::@32]
    // [292] phi main::y_sector1#13 = main::y_sector1#13 [phi:main::@40->main::@32#0] -- register_copy 
    // [292] phi main::x_sector1#10 = main::x_sector1#1 [phi:main::@40->main::@32#1] -- register_copy 
    // [292] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@40->main::@32#2] -- register_copy 
    // [292] phi main::read_ram_bank_sector#10 = main::read_ram_bank_sector#16 [phi:main::@40->main::@32#3] -- register_copy 
    // [292] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@40->main::@32#4] -- register_copy 
    // main::@32
  __b32:
    // while (flash_rom_address_sector < flash_rom_address_boundary)
    // [293] if(main::flash_rom_address_sector#11<main::flash_rom_address_boundary#11) goto main::@33 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address_sector+3
    cmp.z flash_rom_address_boundary_2+3
    bcc __b33
    bne !+
    lda.z flash_rom_address_sector+2
    cmp.z flash_rom_address_boundary_2+2
    bcc __b33
    bne !+
    lda.z flash_rom_address_sector+1
    cmp.z flash_rom_address_boundary_2+1
    bcc __b33
    bne !+
    lda.z flash_rom_address_sector
    cmp.z flash_rom_address_boundary_2
    bcc __b33
  !:
    // main::bank_set_bram4
    // BRAM = bank
    // [294] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // [295] phi from main::bank_set_bram4 to main::@62 [phi:main::bank_set_bram4->main::@62]
    // main::@62
    // bank_set_brom(4)
    // [296] call bank_set_brom
    // [790] phi from main::@62 to bank_set_brom [phi:main::@62->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 4 [phi:main::@62->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // [297] phi from main::@62 to main::@44 [phi:main::@62->main::@44]
    // main::@44
    // textcolor(GREEN)
    // [298] call textcolor
    // [514] phi from main::@44 to textcolor [phi:main::@44->textcolor]
    // [514] phi textcolor::color#23 = GREEN [phi:main::@44->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREEN
    jsr textcolor
    // [299] phi from main::@44 to main::@177 [phi:main::@44->main::@177]
    // main::@177
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [300] call snprintf_init
    jsr snprintf_init
    // [301] phi from main::@177 to main::@178 [phi:main::@177->main::@178]
    // main::@178
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [302] call printf_str
    // [760] phi from main::@178 to printf_str [phi:main::@178->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@178->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s26 [phi:main::@178->printf_str#1] -- pbuz1=pbuc1 
    lda #<s26
    sta.z printf_str.s
    lda #>s26
    sta.z printf_str.s+1
    jsr printf_str
    // main::@179
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [303] printf_uchar::uvalue#11 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [304] call printf_uchar
    // [809] phi from main::@179 to printf_uchar [phi:main::@179->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@179->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 0 [phi:main::@179->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &snputc [phi:main::@179->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = DECIMAL [phi:main::@179->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#11 [phi:main::@179->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [305] phi from main::@179 to main::@180 [phi:main::@179->main::@180]
    // main::@180
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [306] call printf_str
    // [760] phi from main::@180 to printf_str [phi:main::@180->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@180->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s27 [phi:main::@180->printf_str#1] -- pbuz1=pbuc1 
    lda #<s27
    sta.z printf_str.s
    lda #>s27
    sta.z printf_str.s+1
    jsr printf_str
    // main::@181
    // sprintf(buffer, "the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [307] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [308] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_text(buffer)
    // [310] call print_text
    // [773] phi from main::@181 to print_text [phi:main::@181->print_text]
    jsr print_text
    // main::@182
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [311] print_chip_led::r#8 = main::flash_chip#10 -- vbuxx=vbuz1 
    ldx.z flash_chip
    // [312] call print_chip_led
    // [857] phi from main::@182 to print_chip_led [phi:main::@182->print_chip_led]
    // [857] phi print_chip_led::tc#10 = GREEN [phi:main::@182->print_chip_led#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#8 [phi:main::@182->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp CLI2
    // main::@33
  __b33:
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [313] flash_verify::bank_ram#1 = main::read_ram_bank_sector#10 -- vbuxx=vbuz1 
    ldx.z read_ram_bank_sector
    // [314] flash_verify::ptr_ram#2 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address_sector+1
    sta.z flash_verify.ptr_ram+1
    // [315] flash_verify::verify_rom_address#1 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address_sector+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address_sector+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address_sector+3
    sta.z flash_verify.verify_rom_address+3
    // [316] call flash_verify
    // [979] phi from main::@33 to flash_verify [phi:main::@33->flash_verify]
    // [979] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#2 [phi:main::@33->flash_verify#0] -- register_copy 
    // [979] phi flash_verify::verify_rom_size#11 = $1000 [phi:main::@33->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z flash_verify.verify_rom_size
    lda #>$1000
    sta.z flash_verify.verify_rom_size+1
    // [979] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#1 [phi:main::@33->flash_verify#2] -- register_copy 
    // [979] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#1 [phi:main::@33->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [317] flash_verify::return#3 = flash_verify::correct_bytes#2
    // main::@153
    // [318] main::equal_bytes1#0 = flash_verify::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [319] if(main::equal_bytes1#0!=$1000) goto main::@35 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes1+1
    cmp #>$1000
    beq !__b35+
    jmp __b35
  !__b35:
    lda.z equal_bytes1
    cmp #<$1000
    beq !__b35+
    jmp __b35
  !__b35:
    // [320] phi from main::@153 to main::@41 [phi:main::@153->main::@41]
    // main::@41
    // textcolor(WHITE)
    // [321] call textcolor
    // [514] phi from main::@41 to textcolor [phi:main::@41->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@41->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@154
    // gotoxy(x_sector, y_sector)
    // [322] gotoxy::x#21 = main::x_sector1#10 -- vbuxx=vbuz1 
    ldx.z x_sector1
    // [323] gotoxy::y#21 = main::y_sector1#13 -- vbuyy=vbuz1 
    ldy.z y_sector1
    // [324] call gotoxy
    // [532] phi from main::@154 to gotoxy [phi:main::@154->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#21 [phi:main::@154->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = gotoxy::x#21 [phi:main::@154->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [325] phi from main::@154 to main::@155 [phi:main::@154->main::@155]
    // main::@155
    // printf("%s", pattern)
    // [326] call printf_string
    // [902] phi from main::@155 to printf_string [phi:main::@155->printf_string]
    // [902] phi printf_string::str#10 = main::pattern1#1 [phi:main::@155->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern1
    sta.z printf_string.str
    lda #>pattern1
    sta.z printf_string.str+1
    // [902] phi printf_string::format_justify_left#10 = 0 [phi:main::@155->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [902] phi printf_string::format_min_length#7 = 0 [phi:main::@155->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@34
  __b34:
    // read_ram_address_sector += ROM_SECTOR
    // [327] main::read_ram_address_sector#2 = main::read_ram_address_sector#10 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address_sector
    clc
    adc #<$1000
    sta.z read_ram_address_sector
    lda.z read_ram_address_sector+1
    adc #>$1000
    sta.z read_ram_address_sector+1
    // flash_rom_address_sector += ROM_SECTOR
    // [328] main::flash_rom_address_sector#10 = main::flash_rom_address_sector#11 + $1000 -- vduz1=vduz1_plus_vwuc1 
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
    // [329] if(main::read_ram_address_sector#2!=$8000) goto main::@190 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$8000
    bne __b39
    lda.z read_ram_address_sector
    cmp #<$8000
    bne __b39
    // [331] phi from main::@34 to main::@39 [phi:main::@34->main::@39]
    // [331] phi main::read_ram_bank_sector#14 = 1 [phi:main::@34->main::@39#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank_sector
    // [331] phi main::read_ram_address_sector#8 = (char *) 40960 [phi:main::@34->main::@39#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [330] phi from main::@34 to main::@190 [phi:main::@34->main::@190]
    // main::@190
    // [331] phi from main::@190 to main::@39 [phi:main::@190->main::@39]
    // [331] phi main::read_ram_bank_sector#14 = main::read_ram_bank_sector#10 [phi:main::@190->main::@39#0] -- register_copy 
    // [331] phi main::read_ram_address_sector#8 = main::read_ram_address_sector#2 [phi:main::@190->main::@39#1] -- register_copy 
    // main::@39
  __b39:
    // if (read_ram_address_sector == 0xC000)
    // [332] if(main::read_ram_address_sector#8!=$c000) goto main::@40 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$c000
    bne __b40
    lda.z read_ram_address_sector
    cmp #<$c000
    bne __b40
    // main::@42
    // read_ram_bank_sector++;
    // [333] main::read_ram_bank_sector#3 = ++ main::read_ram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank_sector
    // [334] phi from main::@42 to main::@40 [phi:main::@42->main::@40]
    // [334] phi main::read_ram_address_sector#14 = (char *) 40960 [phi:main::@42->main::@40#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [334] phi main::read_ram_bank_sector#16 = main::read_ram_bank_sector#3 [phi:main::@42->main::@40#1] -- register_copy 
    // [334] phi from main::@39 to main::@40 [phi:main::@39->main::@40]
    // [334] phi main::read_ram_address_sector#14 = main::read_ram_address_sector#8 [phi:main::@39->main::@40#0] -- register_copy 
    // [334] phi main::read_ram_bank_sector#16 = main::read_ram_bank_sector#14 [phi:main::@39->main::@40#1] -- register_copy 
    // main::@40
  __b40:
    // x_sector += 16
    // [335] main::x_sector1#1 = main::x_sector1#10 + $10 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$10
    clc
    adc.z x_sector1
    sta.z x_sector1
    // flash_rom_address_sector % 0x4000
    // [336] main::$167 = main::flash_rom_address_sector#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address_sector
    and #<$4000-1
    sta.z __167
    lda.z flash_rom_address_sector+1
    and #>$4000-1
    sta.z __167+1
    lda.z flash_rom_address_sector+2
    and #<$4000-1>>$10
    sta.z __167+2
    lda.z flash_rom_address_sector+3
    and #>$4000-1>>$10
    sta.z __167+3
    // if (!(flash_rom_address_sector % 0x4000))
    // [337] if(0!=main::$167) goto main::@32 -- 0_neq_vduz1_then_la1 
    lda.z __167
    ora.z __167+1
    ora.z __167+2
    ora.z __167+3
    beq !__b32+
    jmp __b32
  !__b32:
    // main::@43
    // y_sector++;
    // [338] main::y_sector1#1 = ++ main::y_sector1#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector1
    // [292] phi from main::@43 to main::@32 [phi:main::@43->main::@32]
    // [292] phi main::y_sector1#13 = main::y_sector1#1 [phi:main::@43->main::@32#0] -- register_copy 
    // [292] phi main::x_sector1#10 = $e [phi:main::@43->main::@32#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector1
    // [292] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@43->main::@32#2] -- register_copy 
    // [292] phi main::read_ram_bank_sector#10 = main::read_ram_bank_sector#16 [phi:main::@43->main::@32#3] -- register_copy 
    // [292] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@43->main::@32#4] -- register_copy 
    jmp __b32
    // main::@35
  __b35:
    // rom_sector_erase(flash_rom_address_sector)
    // [339] rom_sector_erase::address#0 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z rom_sector_erase.address
    lda.z flash_rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda.z flash_rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda.z flash_rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [340] call rom_sector_erase
    jsr rom_sector_erase
    // main::@156
    // unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR
    // [341] main::flash_rom_address_boundary1#0 = main::flash_rom_address_sector#11 + $1000 -- vduz1=vduz2_plus_vwuc1 
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
    // [342] gotoxy::x#22 = main::x_sector1#10 -- vbuxx=vbuz1 
    ldx.z x_sector1
    // [343] gotoxy::y#22 = main::y_sector1#13 -- vbuyy=vbuz1 
    ldy.z y_sector1
    // [344] call gotoxy
    // [532] phi from main::@156 to gotoxy [phi:main::@156->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#22 [phi:main::@156->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = gotoxy::x#22 [phi:main::@156->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [345] phi from main::@156 to main::@157 [phi:main::@156->main::@157]
    // main::@157
    // printf("................")
    // [346] call printf_str
    // [760] phi from main::@157 to printf_str [phi:main::@157->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@157->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s19 [phi:main::@157->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // [347] phi from main::@157 to main::@158 [phi:main::@157->main::@158]
    // main::@158
    // gotoxy(50, 1)
    // [348] call gotoxy
    // [532] phi from main::@158 to gotoxy [phi:main::@158->gotoxy]
    // [532] phi gotoxy::y#26 = 1 [phi:main::@158->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [532] phi gotoxy::x#26 = $32 [phi:main::@158->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$32
    jsr gotoxy
    // [349] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [350] call printf_str
    // [760] phi from main::@159 to printf_str [phi:main::@159->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@159->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s16 [phi:main::@159->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@160
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [351] printf_uchar::uvalue#9 = main::read_ram_bank_sector#10 -- vbuxx=vbuz1 
    ldx.z read_ram_bank_sector
    // [352] call printf_uchar
    // [809] phi from main::@160 to printf_uchar [phi:main::@160->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@160->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 2 [phi:main::@160->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &cputc [phi:main::@160->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = HEXADECIMAL [phi:main::@160->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#9 [phi:main::@160->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [353] phi from main::@160 to main::@161 [phi:main::@160->main::@161]
    // main::@161
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [354] call printf_str
    // [760] phi from main::@161 to printf_str [phi:main::@161->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@161->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s17 [phi:main::@161->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@162
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [355] printf_uint::uvalue#1 = (unsigned int)main::read_ram_address_sector#10 -- vwuz1=vwuz2 
    lda.z read_ram_address_sector
    sta.z printf_uint.uvalue
    lda.z read_ram_address_sector+1
    sta.z printf_uint.uvalue+1
    // [356] call printf_uint
    // [1018] phi from main::@162 to printf_uint [phi:main::@162->printf_uint]
    // [1018] phi printf_uint::uvalue#4 = printf_uint::uvalue#1 [phi:main::@162->printf_uint#0] -- register_copy 
    jsr printf_uint
    // [357] phi from main::@162 to main::@163 [phi:main::@162->main::@163]
    // main::@163
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [358] call printf_str
    // [760] phi from main::@163 to printf_str [phi:main::@163->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@163->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s18 [phi:main::@163->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@164
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [359] printf_ulong::uvalue#2 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z printf_ulong.uvalue
    lda.z flash_rom_address_sector+1
    sta.z printf_ulong.uvalue+1
    lda.z flash_rom_address_sector+2
    sta.z printf_ulong.uvalue+2
    lda.z flash_rom_address_sector+3
    sta.z printf_ulong.uvalue+3
    // [360] call printf_ulong
    // [1025] phi from main::@164 to printf_ulong [phi:main::@164->printf_ulong]
    // [1025] phi printf_ulong::format_zero_padding#4 = 0 [phi:main::@164->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1025] phi printf_ulong::uvalue#4 = printf_ulong::uvalue#2 [phi:main::@164->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // main::@165
    // [361] main::flash_rom_address2#28 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_rom_address2
    lda.z flash_rom_address_sector+1
    sta.z flash_rom_address2+1
    lda.z flash_rom_address_sector+2
    sta.z flash_rom_address2+2
    lda.z flash_rom_address_sector+3
    sta.z flash_rom_address2+3
    // [362] main::read_ram_address1#28 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z read_ram_address1
    lda.z read_ram_address_sector+1
    sta.z read_ram_address1+1
    // [363] main::x1#28 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z x1
    // [364] phi from main::@165 main::@176 to main::@36 [phi:main::@165/main::@176->main::@36]
    // [364] phi main::x1#10 = main::x1#28 [phi:main::@165/main::@176->main::@36#0] -- register_copy 
    // [364] phi main::read_ram_address1#10 = main::read_ram_address1#28 [phi:main::@165/main::@176->main::@36#1] -- register_copy 
    // [364] phi main::flash_rom_address2#11 = main::flash_rom_address2#28 [phi:main::@165/main::@176->main::@36#2] -- register_copy 
    // main::@36
  __b36:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [365] if(main::flash_rom_address2#11<main::flash_rom_address_boundary1#0) goto main::@37 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address2+3
    cmp.z flash_rom_address_boundary1+3
    bcc __b37
    bne !+
    lda.z flash_rom_address2+2
    cmp.z flash_rom_address_boundary1+2
    bcc __b37
    bne !+
    lda.z flash_rom_address2+1
    cmp.z flash_rom_address_boundary1+1
    bcc __b37
    bne !+
    lda.z flash_rom_address2
    cmp.z flash_rom_address_boundary1
    bcc __b37
  !:
    jmp __b34
    // [366] phi from main::@36 to main::@37 [phi:main::@36->main::@37]
    // main::@37
  __b37:
    // gotoxy(50, 1)
    // [367] call gotoxy
    // [532] phi from main::@37 to gotoxy [phi:main::@37->gotoxy]
    // [532] phi gotoxy::y#26 = 1 [phi:main::@37->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [532] phi gotoxy::x#26 = $32 [phi:main::@37->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$32
    jsr gotoxy
    // [368] phi from main::@37 to main::@166 [phi:main::@37->main::@166]
    // main::@166
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [369] call printf_str
    // [760] phi from main::@166 to printf_str [phi:main::@166->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@166->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s16 [phi:main::@166->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@167
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [370] printf_uchar::uvalue#10 = main::read_ram_bank_sector#10 -- vbuxx=vbuz1 
    ldx.z read_ram_bank_sector
    // [371] call printf_uchar
    // [809] phi from main::@167 to printf_uchar [phi:main::@167->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@167->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 2 [phi:main::@167->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &cputc [phi:main::@167->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = HEXADECIMAL [phi:main::@167->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#10 [phi:main::@167->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [372] phi from main::@167 to main::@168 [phi:main::@167->main::@168]
    // main::@168
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [373] call printf_str
    // [760] phi from main::@168 to printf_str [phi:main::@168->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@168->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s17 [phi:main::@168->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@169
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [374] printf_uint::uvalue#2 = (unsigned int)main::read_ram_address1#10 -- vwuz1=vwuz2 
    lda.z read_ram_address1
    sta.z printf_uint.uvalue
    lda.z read_ram_address1+1
    sta.z printf_uint.uvalue+1
    // [375] call printf_uint
    // [1018] phi from main::@169 to printf_uint [phi:main::@169->printf_uint]
    // [1018] phi printf_uint::uvalue#4 = printf_uint::uvalue#2 [phi:main::@169->printf_uint#0] -- register_copy 
    jsr printf_uint
    // [376] phi from main::@169 to main::@170 [phi:main::@169->main::@170]
    // main::@170
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [377] call printf_str
    // [760] phi from main::@170 to printf_str [phi:main::@170->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@170->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s18 [phi:main::@170->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@171
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank_sector, read_ram_address, flash_rom_address)
    // [378] printf_ulong::uvalue#3 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z printf_ulong.uvalue
    lda.z flash_rom_address2+1
    sta.z printf_ulong.uvalue+1
    lda.z flash_rom_address2+2
    sta.z printf_ulong.uvalue+2
    lda.z flash_rom_address2+3
    sta.z printf_ulong.uvalue+3
    // [379] call printf_ulong
    // [1025] phi from main::@171 to printf_ulong [phi:main::@171->printf_ulong]
    // [1025] phi printf_ulong::format_zero_padding#4 = 0 [phi:main::@171->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1025] phi printf_ulong::uvalue#4 = printf_ulong::uvalue#3 [phi:main::@171->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // main::@172
    // unsigned long written_bytes = flash_write(read_ram_bank_sector, (ram_ptr_t)read_ram_address, flash_rom_address)
    // [380] flash_write::flash_ram_bank#0 = main::read_ram_bank_sector#10 -- vbuxx=vbuz1 
    ldx.z read_ram_bank_sector
    // [381] flash_write::flash_ram_address#1 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_write.flash_ram_address
    lda.z read_ram_address1+1
    sta.z flash_write.flash_ram_address+1
    // [382] flash_write::flash_rom_address#1 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z flash_write.flash_rom_address
    lda.z flash_rom_address2+1
    sta.z flash_write.flash_rom_address+1
    lda.z flash_rom_address2+2
    sta.z flash_write.flash_rom_address+2
    lda.z flash_rom_address2+3
    sta.z flash_write.flash_rom_address+3
    // [383] call flash_write
    jsr flash_write
    // main::@173
    // flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [384] flash_verify::bank_ram#2 = main::read_ram_bank_sector#10 -- vbuxx=vbuz1 
    ldx.z read_ram_bank_sector
    // [385] flash_verify::ptr_ram#3 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address1+1
    sta.z flash_verify.ptr_ram+1
    // [386] flash_verify::verify_rom_address#2 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address2+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address2+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address2+3
    sta.z flash_verify.verify_rom_address+3
    // [387] call flash_verify
    // [979] phi from main::@173 to flash_verify [phi:main::@173->flash_verify]
    // [979] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#3 [phi:main::@173->flash_verify#0] -- register_copy 
    // [979] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@173->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    // [979] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#2 [phi:main::@173->flash_verify#2] -- register_copy 
    // [979] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#2 [phi:main::@173->flash_verify#3] -- register_copy 
    jsr flash_verify
    // main::@38
    // read_ram_address += 0x0100
    // [388] main::read_ram_address1#1 = main::read_ram_address1#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address1
    clc
    adc #<$100
    sta.z read_ram_address1
    lda.z read_ram_address1+1
    adc #>$100
    sta.z read_ram_address1+1
    // flash_rom_address += 0x0100
    // [389] main::flash_rom_address2#1 = main::flash_rom_address2#11 + $100 -- vduz1=vduz1_plus_vwuc1 
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
    // [390] call textcolor
    // [514] phi from main::@38 to textcolor [phi:main::@38->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@38->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@174
    // gotoxy(x, y)
    // [391] gotoxy::x#25 = main::x1#10 -- vbuxx=vbuz1 
    ldx.z x1
    // [392] gotoxy::y#25 = main::y_sector1#13 -- vbuyy=vbuz1 
    ldy.z y_sector1
    // [393] call gotoxy
    // [532] phi from main::@174 to gotoxy [phi:main::@174->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#25 [phi:main::@174->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = gotoxy::x#25 [phi:main::@174->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [394] phi from main::@174 to main::@175 [phi:main::@174->main::@175]
    // main::@175
    // printf("%s", pattern)
    // [395] call printf_string
    // [902] phi from main::@175 to printf_string [phi:main::@175->printf_string]
    // [902] phi printf_string::str#10 = main::pattern1#3 [phi:main::@175->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern1_1
    sta.z printf_string.str
    lda #>pattern1_1
    sta.z printf_string.str+1
    // [902] phi printf_string::format_justify_left#10 = 0 [phi:main::@175->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [902] phi printf_string::format_min_length#7 = 0 [phi:main::@175->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@176
    // x++;
    // [396] main::x1#1 = ++ main::x1#10 -- vbuz1=_inc_vbuz1 
    inc.z x1
    jmp __b36
    // main::@24
  __b24:
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [397] flash_verify::bank_ram#0 = main::read_ram_bank#12 -- vbuxx=vbuz1 
    ldx.z read_ram_bank
    // [398] flash_verify::ptr_ram#1 = main::read_ram_address#10 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address+1
    sta.z flash_verify.ptr_ram+1
    // [399] flash_verify::verify_rom_address#0 = main::flash_rom_address1#10 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address1+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address1+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address1+3
    sta.z flash_verify.verify_rom_address+3
    // [400] call flash_verify
    // [979] phi from main::@24 to flash_verify [phi:main::@24->flash_verify]
    // [979] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#1 [phi:main::@24->flash_verify#0] -- register_copy 
    // [979] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@24->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    // [979] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#0 [phi:main::@24->flash_verify#2] -- register_copy 
    // [979] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#0 [phi:main::@24->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [401] flash_verify::return#2 = flash_verify::correct_bytes#2
    // main::@130
    // [402] main::equal_bytes#0 = flash_verify::return#2
    // if (equal_bytes != 0x0100)
    // [403] if(main::equal_bytes#0!=$100) goto main::@26 -- vwuz1_neq_vwuc1_then_la1 
    // unsigned long equal_bytes = 0x100;
    lda.z equal_bytes+1
    cmp #>$100
    bne __b26
    lda.z equal_bytes
    cmp #<$100
    bne __b26
    // [405] phi from main::@130 to main::@27 [phi:main::@130->main::@27]
    // [405] phi main::pattern#10 = main::pattern#2 [phi:main::@130->main::@27#0] -- pbuz1=pbuc1 
    lda #<pattern_2
    sta.z pattern
    lda #>pattern_2
    sta.z pattern+1
    jmp __b27
    // [404] phi from main::@130 to main::@26 [phi:main::@130->main::@26]
    // main::@26
  __b26:
    // [405] phi from main::@26 to main::@27 [phi:main::@26->main::@27]
    // [405] phi main::pattern#10 = main::pattern#1 [phi:main::@26->main::@27#0] -- pbuz1=pbuc1 
    lda #<pattern_1
    sta.z pattern
    lda #>pattern_1
    sta.z pattern+1
    // main::@27
  __b27:
    // read_ram_address += 0x0100
    // [406] main::read_ram_address#1 = main::read_ram_address#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address
    clc
    adc #<$100
    sta.z read_ram_address
    lda.z read_ram_address+1
    adc #>$100
    sta.z read_ram_address+1
    // flash_rom_address += 0x0100
    // [407] main::flash_rom_address1#1 = main::flash_rom_address1#10 + $100 -- vduz1=vduz1_plus_vwuc1 
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
    // [408] call textcolor
    // [514] phi from main::@27 to textcolor [phi:main::@27->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@27->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [409] phi from main::@27 to main::@143 [phi:main::@27->main::@143]
    // main::@143
    // gotoxy(50, 1)
    // [410] call gotoxy
    // [532] phi from main::@143 to gotoxy [phi:main::@143->gotoxy]
    // [532] phi gotoxy::y#26 = 1 [phi:main::@143->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [532] phi gotoxy::x#26 = $32 [phi:main::@143->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$32
    jsr gotoxy
    // [411] phi from main::@143 to main::@144 [phi:main::@143->main::@144]
    // main::@144
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank, read_ram_address, flash_rom_address)
    // [412] call printf_str
    // [760] phi from main::@144 to printf_str [phi:main::@144->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@144->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s16 [phi:main::@144->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@145
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank, read_ram_address, flash_rom_address)
    // [413] printf_uchar::uvalue#8 = main::read_ram_bank#12 -- vbuxx=vbuz1 
    ldx.z read_ram_bank
    // [414] call printf_uchar
    // [809] phi from main::@145 to printf_uchar [phi:main::@145->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@145->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 2 [phi:main::@145->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &cputc [phi:main::@145->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = HEXADECIMAL [phi:main::@145->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#8 [phi:main::@145->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [415] phi from main::@145 to main::@146 [phi:main::@145->main::@146]
    // main::@146
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank, read_ram_address, flash_rom_address)
    // [416] call printf_str
    // [760] phi from main::@146 to printf_str [phi:main::@146->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@146->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s17 [phi:main::@146->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@147
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank, read_ram_address, flash_rom_address)
    // [417] printf_uint::uvalue#0 = (unsigned int)main::read_ram_address#1 -- vwuz1=vwuz2 
    lda.z read_ram_address
    sta.z printf_uint.uvalue
    lda.z read_ram_address+1
    sta.z printf_uint.uvalue+1
    // [418] call printf_uint
    // [1018] phi from main::@147 to printf_uint [phi:main::@147->printf_uint]
    // [1018] phi printf_uint::uvalue#4 = printf_uint::uvalue#0 [phi:main::@147->printf_uint#0] -- register_copy 
    jsr printf_uint
    // [419] phi from main::@147 to main::@148 [phi:main::@147->main::@148]
    // main::@148
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank, read_ram_address, flash_rom_address)
    // [420] call printf_str
    // [760] phi from main::@148 to printf_str [phi:main::@148->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:main::@148->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s18 [phi:main::@148->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@149
    // printf("ram = %2x, %4p, rom = %6x", read_ram_bank, read_ram_address, flash_rom_address)
    // [421] printf_ulong::uvalue#1 = main::flash_rom_address1#1 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z printf_ulong.uvalue
    lda.z flash_rom_address1+1
    sta.z printf_ulong.uvalue+1
    lda.z flash_rom_address1+2
    sta.z printf_ulong.uvalue+2
    lda.z flash_rom_address1+3
    sta.z printf_ulong.uvalue+3
    // [422] call printf_ulong
    // [1025] phi from main::@149 to printf_ulong [phi:main::@149->printf_ulong]
    // [1025] phi printf_ulong::format_zero_padding#4 = 0 [phi:main::@149->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1025] phi printf_ulong::uvalue#4 = printf_ulong::uvalue#1 [phi:main::@149->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // main::@150
    // gotoxy(x_sector, y_sector)
    // [423] gotoxy::x#20 = main::x_sector#10 -- vbuxx=vbuz1 
    ldx.z x_sector
    // [424] gotoxy::y#20 = main::y_sector#10 -- vbuyy=vbuz1 
    ldy.z y_sector
    // [425] call gotoxy
    // [532] phi from main::@150 to gotoxy [phi:main::@150->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#20 [phi:main::@150->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = gotoxy::x#20 [phi:main::@150->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@151
    // printf("%s", pattern)
    // [426] printf_string::str#4 = main::pattern#10 -- pbuz1=pbuz2 
    lda.z pattern
    sta.z printf_string.str
    lda.z pattern+1
    sta.z printf_string.str+1
    // [427] call printf_string
    // [902] phi from main::@151 to printf_string [phi:main::@151->printf_string]
    // [902] phi printf_string::str#10 = printf_string::str#4 [phi:main::@151->printf_string#0] -- register_copy 
    // [902] phi printf_string::format_justify_left#10 = 0 [phi:main::@151->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [902] phi printf_string::format_min_length#7 = 0 [phi:main::@151->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@152
    // x_sector++;
    // [428] main::x_sector#1 = ++ main::x_sector#10 -- vbuz1=_inc_vbuz1 
    inc.z x_sector
    // if (read_ram_address == 0x8000)
    // [429] if(main::read_ram_address#1!=$8000) goto main::@189 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$8000
    bne __b28
    lda.z read_ram_address
    cmp #<$8000
    bne __b28
    // [431] phi from main::@152 to main::@28 [phi:main::@152->main::@28]
    // [431] phi main::read_ram_bank#5 = 1 [phi:main::@152->main::@28#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank
    // [431] phi main::read_ram_address#8 = (char *) 40960 [phi:main::@152->main::@28#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [430] phi from main::@152 to main::@189 [phi:main::@152->main::@189]
    // main::@189
    // [431] phi from main::@189 to main::@28 [phi:main::@189->main::@28]
    // [431] phi main::read_ram_bank#5 = main::read_ram_bank#12 [phi:main::@189->main::@28#0] -- register_copy 
    // [431] phi main::read_ram_address#8 = main::read_ram_address#1 [phi:main::@189->main::@28#1] -- register_copy 
    // main::@28
  __b28:
    // if (read_ram_address == 0xC000)
    // [432] if(main::read_ram_address#8!=$c000) goto main::@29 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$c000
    bne __b29
    lda.z read_ram_address
    cmp #<$c000
    bne __b29
    // main::@30
    // read_ram_bank++;
    // [433] main::read_ram_bank#2 = ++ main::read_ram_bank#5 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank
    // [434] phi from main::@30 to main::@29 [phi:main::@30->main::@29]
    // [434] phi main::read_ram_address#14 = (char *) 40960 [phi:main::@30->main::@29#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [434] phi main::read_ram_bank#10 = main::read_ram_bank#2 [phi:main::@30->main::@29#1] -- register_copy 
    // [434] phi from main::@28 to main::@29 [phi:main::@28->main::@29]
    // [434] phi main::read_ram_address#14 = main::read_ram_address#8 [phi:main::@28->main::@29#0] -- register_copy 
    // [434] phi main::read_ram_bank#10 = main::read_ram_bank#5 [phi:main::@28->main::@29#1] -- register_copy 
    // main::@29
  __b29:
    // flash_rom_address % 0x4000
    // [435] main::$127 = main::flash_rom_address1#1 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address1
    and #<$4000-1
    sta.z __127
    lda.z flash_rom_address1+1
    and #>$4000-1
    sta.z __127+1
    lda.z flash_rom_address1+2
    and #<$4000-1>>$10
    sta.z __127+2
    lda.z flash_rom_address1+3
    and #>$4000-1>>$10
    sta.z __127+3
    // if (!(flash_rom_address % 0x4000))
    // [436] if(0!=main::$127) goto main::@23 -- 0_neq_vduz1_then_la1 
    lda.z __127
    ora.z __127+1
    ora.z __127+2
    ora.z __127+3
    beq !__b23+
    jmp __b23
  !__b23:
    // main::@31
    // y_sector++;
    // [437] main::y_sector#1 = ++ main::y_sector#10 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [253] phi from main::@31 to main::@23 [phi:main::@31->main::@23]
    // [253] phi main::y_sector#10 = main::y_sector#1 [phi:main::@31->main::@23#0] -- register_copy 
    // [253] phi main::x_sector#10 = $e [phi:main::@31->main::@23#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [253] phi main::read_ram_address#10 = main::read_ram_address#14 [phi:main::@31->main::@23#2] -- register_copy 
    // [253] phi main::read_ram_bank#12 = main::read_ram_bank#10 [phi:main::@31->main::@23#3] -- register_copy 
    // [253] phi main::flash_rom_address1#10 = main::flash_rom_address1#1 [phi:main::@31->main::@23#4] -- register_copy 
    jmp __b23
    // [438] phi from main::@93 to main::@19 [phi:main::@93->main::@19]
    // main::@19
  __b19:
    // sprintf(file, "rom.bin", flash_chip)
    // [439] call snprintf_init
    jsr snprintf_init
    // [440] phi from main::@19 to main::@94 [phi:main::@19->main::@94]
    // main::@94
    // sprintf(file, "rom.bin", flash_chip)
    // [441] call printf_str
    // [760] phi from main::@94 to printf_str [phi:main::@94->printf_str]
    // [760] phi printf_str::putc#37 = &snputc [phi:main::@94->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = main::s2 [phi:main::@94->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@95
    // sprintf(file, "rom.bin", flash_chip)
    // [442] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [443] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b20
    // main::@4
  __b4:
    // rom_manufacturer_ids[rom_chip] = 0
    // [445] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [446] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // if (flash_rom_address <= 0x100000)
    // [447] if(main::flash_rom_address#10>$100000) goto main::@5 -- vduz1_gt_vduc1_then_la1 
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
    // main::@12
    // rom_unlock(flash_rom_address + 0x05555, 0x90)
    // [448] rom_unlock::address#3 = main::flash_rom_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [449] call rom_unlock
    // [1046] phi from main::@12 to rom_unlock [phi:main::@12->rom_unlock]
    // [1046] phi rom_unlock::unlock_code#5 = $90 [phi:main::@12->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1046] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:main::@12->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // main::@85
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [450] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [451] main::rom_device_ids[main::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0xF0)
    // [452] rom_unlock::address#4 = main::flash_rom_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1046] phi from main::@85 to rom_unlock [phi:main::@85->rom_unlock]
    // [1046] phi rom_unlock::unlock_code#5 = $f0 [phi:main::@85->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1046] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:main::@85->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // [454] phi from main::@4 main::@85 to main::@5 [phi:main::@4/main::@85->main::@5]
    // main::@5
  __b5:
    // bank_set_brom(4)
    // [455] call bank_set_brom
  // Ensure the ROM is set to BASIC.
    // [790] phi from main::@5 to bank_set_brom [phi:main::@5->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 4 [phi:main::@5->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::@84
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             break;
    // [456] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@6 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [457] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@7 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [458] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@8 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b8+
    jmp __b8
  !__b8:
    // main::@9
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [459] print_chip_led::r#4 = main::rom_chip#10 -- vbuxx=vbuz1 
    ldx.z rom_chip
    // [460] call print_chip_led
    // [857] phi from main::@9 to print_chip_led [phi:main::@9->print_chip_led]
    // [857] phi print_chip_led::tc#10 = BLACK [phi:main::@9->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#4 [phi:main::@9->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@86
    // rom_device_ids[rom_chip] = UNKNOWN
    // [461] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // [462] phi from main::@86 to main::@10 [phi:main::@86->main::@10]
    // [462] phi main::rom_device#5 = main::rom_device#13 [phi:main::@86->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_4
    sta.z rom_device
    lda #>rom_device_4
    sta.z rom_device+1
    // main::@10
  __b10:
    // textcolor(WHITE)
    // [463] call textcolor
    // [514] phi from main::@10 to textcolor [phi:main::@10->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:main::@10->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@87
    // rom_chip * 10
    // [464] main::$208 = main::rom_chip#10 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z rom_chip
    asl
    asl
    // [465] main::$209 = main::$208 + main::rom_chip#10 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip
    // [466] main::$66 = main::$209 << 1 -- vbuz1=vbuaa_rol_1 
    asl
    sta.z __66
    // gotoxy(2 + rom_chip * 10, 56)
    // [467] gotoxy::x#13 = 2 + main::$66 -- vbuxx=vbuc1_plus_vbuz1 
    lda #2
    clc
    adc.z __66
    tax
    // [468] call gotoxy
    // [532] phi from main::@87 to gotoxy [phi:main::@87->gotoxy]
    // [532] phi gotoxy::y#26 = $38 [phi:main::@87->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$38
    // [532] phi gotoxy::x#26 = gotoxy::x#13 [phi:main::@87->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@88
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [469] printf_uchar::uvalue#1 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbuxx=pbuc1_derefidx_vbuz1 
    ldy.z rom_chip
    ldx rom_manufacturer_ids,y
    // [470] call printf_uchar
    // [809] phi from main::@88 to printf_uchar [phi:main::@88->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 0 [phi:main::@88->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 0 [phi:main::@88->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &cputc [phi:main::@88->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = HEXADECIMAL [phi:main::@88->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#1 [phi:main::@88->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // main::@89
    // gotoxy(2 + rom_chip * 10, 57)
    // [471] gotoxy::x#14 = 2 + main::$66 -- vbuxx=vbuc1_plus_vbuz1 
    lda #2
    clc
    adc.z __66
    tax
    // [472] call gotoxy
    // [532] phi from main::@89 to gotoxy [phi:main::@89->gotoxy]
    // [532] phi gotoxy::y#26 = $39 [phi:main::@89->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$39
    // [532] phi gotoxy::x#26 = gotoxy::x#14 [phi:main::@89->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@90
    // printf("%s", rom_device)
    // [473] printf_string::str#2 = main::rom_device#5 -- pbuz1=pbuz2 
    lda.z rom_device
    sta.z printf_string.str
    lda.z rom_device+1
    sta.z printf_string.str+1
    // [474] call printf_string
    // [902] phi from main::@90 to printf_string [phi:main::@90->printf_string]
    // [902] phi printf_string::str#10 = printf_string::str#2 [phi:main::@90->printf_string#0] -- register_copy 
    // [902] phi printf_string::format_justify_left#10 = 0 [phi:main::@90->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [902] phi printf_string::format_min_length#7 = 0 [phi:main::@90->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@91
    // rom_chip++;
    // [475] main::rom_chip#1 = ++ main::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // main::@11
    // flash_rom_address += 0x80000
    // [476] main::flash_rom_address#1 = main::flash_rom_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [477] print_chip_led::r#3 = main::rom_chip#10 -- vbuxx=vbuz1 
    ldx.z rom_chip
    // [478] call print_chip_led
    // [857] phi from main::@8 to print_chip_led [phi:main::@8->print_chip_led]
    // [857] phi print_chip_led::tc#10 = WHITE [phi:main::@8->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#3 [phi:main::@8->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [462] phi from main::@8 to main::@10 [phi:main::@8->main::@10]
    // [462] phi main::rom_device#5 = main::rom_device#12 [phi:main::@8->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_3
    sta.z rom_device
    lda #>rom_device_3
    sta.z rom_device+1
    jmp __b10
    // main::@7
  __b7:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [479] print_chip_led::r#2 = main::rom_chip#10 -- vbuxx=vbuz1 
    ldx.z rom_chip
    // [480] call print_chip_led
    // [857] phi from main::@7 to print_chip_led [phi:main::@7->print_chip_led]
    // [857] phi print_chip_led::tc#10 = WHITE [phi:main::@7->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#2 [phi:main::@7->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [462] phi from main::@7 to main::@10 [phi:main::@7->main::@10]
    // [462] phi main::rom_device#5 = main::rom_device#11 [phi:main::@7->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_2
    sta.z rom_device
    lda #>rom_device_2
    sta.z rom_device+1
    jmp __b10
    // main::@6
  __b6:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [481] print_chip_led::r#1 = main::rom_chip#10 -- vbuxx=vbuz1 
    ldx.z rom_chip
    // [482] call print_chip_led
    // [857] phi from main::@6 to print_chip_led [phi:main::@6->print_chip_led]
    // [857] phi print_chip_led::tc#10 = WHITE [phi:main::@6->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#1 [phi:main::@6->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [462] phi from main::@6 to main::@10 [phi:main::@6->main::@10]
    // [462] phi main::rom_device#5 = main::rom_device#1 [phi:main::@6->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_1
    sta.z rom_device
    lda #>rom_device_1
    sta.z rom_device+1
    jmp __b10
    // main::@2
  __b2:
    // r * 10
    // [483] main::$205 = main::r#10 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z r
    asl
    asl
    // [484] main::$206 = main::$205 + main::r#10 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z r
    // [485] main::$20 = main::$206 << 1 -- vbuz1=vbuaa_rol_1 
    asl
    sta.z __20
    // print_chip_line(3 + r * 10, 45, ' ')
    // [486] print_chip_line::x#0 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [487] call print_chip_line
    // [1056] phi from main::@2 to print_chip_line [phi:main::@2->print_chip_line]
    // [1056] phi print_chip_line::c#10 = ' 'pm [phi:main::@2->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1056] phi print_chip_line::y#9 = $2d [phi:main::@2->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$2d
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#0 [phi:main::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@70
    // print_chip_line(3 + r * 10, 46, 'r')
    // [488] print_chip_line::x#1 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [489] call print_chip_line
    // [1056] phi from main::@70 to print_chip_line [phi:main::@70->print_chip_line]
    // [1056] phi print_chip_line::c#10 = 'r'pm [phi:main::@70->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'r'
    sta.z print_chip_line.c
    // [1056] phi print_chip_line::y#9 = $2e [phi:main::@70->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$2e
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#1 [phi:main::@70->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@71
    // print_chip_line(3 + r * 10, 47, 'o')
    // [490] print_chip_line::x#2 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [491] call print_chip_line
    // [1056] phi from main::@71 to print_chip_line [phi:main::@71->print_chip_line]
    // [1056] phi print_chip_line::c#10 = 'o'pm [phi:main::@71->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'o'
    sta.z print_chip_line.c
    // [1056] phi print_chip_line::y#9 = $2f [phi:main::@71->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$2f
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#2 [phi:main::@71->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@72
    // print_chip_line(3 + r * 10, 48, 'm')
    // [492] print_chip_line::x#3 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [493] call print_chip_line
    // [1056] phi from main::@72 to print_chip_line [phi:main::@72->print_chip_line]
    // [1056] phi print_chip_line::c#10 = 'm'pm [phi:main::@72->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'m'
    sta.z print_chip_line.c
    // [1056] phi print_chip_line::y#9 = $30 [phi:main::@72->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$30
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#3 [phi:main::@72->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@73
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [494] print_chip_line::x#4 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [495] print_chip_line::c#4 = '0'pm + main::r#10 -- vbuz1=vbuc1_plus_vbuz2 
    lda #'0'
    clc
    adc.z r
    sta.z print_chip_line.c
    // [496] call print_chip_line
    // [1056] phi from main::@73 to print_chip_line [phi:main::@73->print_chip_line]
    // [1056] phi print_chip_line::c#10 = print_chip_line::c#4 [phi:main::@73->print_chip_line#0] -- register_copy 
    // [1056] phi print_chip_line::y#9 = $31 [phi:main::@73->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$31
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#4 [phi:main::@73->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@74
    // print_chip_line(3 + r * 10, 50, ' ')
    // [497] print_chip_line::x#5 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [498] call print_chip_line
    // [1056] phi from main::@74 to print_chip_line [phi:main::@74->print_chip_line]
    // [1056] phi print_chip_line::c#10 = ' 'pm [phi:main::@74->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1056] phi print_chip_line::y#9 = $32 [phi:main::@74->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$32
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#5 [phi:main::@74->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@75
    // print_chip_line(3 + r * 10, 51, '5')
    // [499] print_chip_line::x#6 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [500] call print_chip_line
    // [1056] phi from main::@75 to print_chip_line [phi:main::@75->print_chip_line]
    // [1056] phi print_chip_line::c#10 = '5'pm [phi:main::@75->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'5'
    sta.z print_chip_line.c
    // [1056] phi print_chip_line::y#9 = $33 [phi:main::@75->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$33
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#6 [phi:main::@75->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@76
    // print_chip_line(3 + r * 10, 52, '1')
    // [501] print_chip_line::x#7 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [502] call print_chip_line
    // [1056] phi from main::@76 to print_chip_line [phi:main::@76->print_chip_line]
    // [1056] phi print_chip_line::c#10 = '1'pm [phi:main::@76->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'1'
    sta.z print_chip_line.c
    // [1056] phi print_chip_line::y#9 = $34 [phi:main::@76->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$34
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#7 [phi:main::@76->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@77
    // print_chip_line(3 + r * 10, 53, '2')
    // [503] print_chip_line::x#8 = 3 + main::$20 -- vbuxx=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    tax
    // [504] call print_chip_line
    // [1056] phi from main::@77 to print_chip_line [phi:main::@77->print_chip_line]
    // [1056] phi print_chip_line::c#10 = '2'pm [phi:main::@77->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'2'
    sta.z print_chip_line.c
    // [1056] phi print_chip_line::y#9 = $35 [phi:main::@77->print_chip_line#1] -- vbuyy=vbuc1 
    ldy #$35
    // [1056] phi print_chip_line::x#9 = print_chip_line::x#8 [phi:main::@77->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@78
    // print_chip_end(3 + r * 10, 54)
    // [505] print_chip_end::x#0 = 3 + main::$20 -- vbuaa=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z __20
    // [506] call print_chip_end
    jsr print_chip_end
    // main::@79
    // print_chip_led(r, BLACK, BLUE)
    // [507] print_chip_led::r#0 = main::r#10 -- vbuxx=vbuz1 
    ldx.z r
    // [508] call print_chip_led
    // [857] phi from main::@79 to print_chip_led [phi:main::@79->print_chip_led]
    // [857] phi print_chip_led::tc#10 = BLACK [phi:main::@79->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [857] phi print_chip_led::r#10 = print_chip_led::r#0 [phi:main::@79->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@80
    // for (unsigned char r = 0; r < 8; r++)
    // [509] main::r#1 = ++ main::r#10 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [89] phi from main::@80 to main::@1 [phi:main::@80->main::@1]
    // [89] phi main::r#10 = main::r#1 [phi:main::@80->main::@1#0] -- register_copy 
    jmp __b1
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
    s16: .text "ram = "
    .byte 0
    s17: .text ", "
    .byte 0
    s18: .text ", rom = "
    .byte 0
    s19: .text "................"
    .byte 0
    s26: .text "the flashing of rom"
    .byte 0
    s27: .text " went perfectly ok. press a key ..."
    .byte 0
    s31: .text "resetting commander x16 ("
    .byte 0
    s32: .text ")"
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
    pattern1: .text "----------------"
    .byte 0
    pattern1_1: .text "+"
    .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [510] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuxx=_deref_pbuc1 
    ldx VERA_L1_MAPBASE
    // [511] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [512] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [513] return 
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
    // [515] textcolor::$0 = *((char *)&__conio+$b) & $f0 -- vbuaa=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$b
    // __conio.color & 0xF0 | color
    // [516] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbuaa=vbuaa_bor_vbuxx 
    stx.z $ff
    ora.z $ff
    // __conio.color = __conio.color & 0xF0 | color
    // [517] *((char *)&__conio+$b) = textcolor::$1 -- _deref_pbuc1=vbuaa 
    sta __conio+$b
    // textcolor::@return
    // }
    // [518] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__register(X) char color)
bgcolor: {
    .label __0 = $bd
    // __conio.color & 0x0F
    // [520] bgcolor::$0 = *((char *)&__conio+$b) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$b
    sta.z __0
    // color << 4
    // [521] bgcolor::$1 = bgcolor::color#11 << 4 -- vbuaa=vbuxx_rol_4 
    txa
    asl
    asl
    asl
    asl
    // __conio.color & 0x0F | color << 4
    // [522] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuaa=vbuz1_bor_vbuaa 
    ora.z __0
    // __conio.color = __conio.color & 0x0F | color << 4
    // [523] *((char *)&__conio+$b) = bgcolor::$2 -- _deref_pbuc1=vbuaa 
    sta __conio+$b
    // bgcolor::@return
    // }
    // [524] return 
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
    // [525] *((char *)&__conio+$a) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$a
    // cursor::@return
    // }
    // [526] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $bb
    // __mem unsigned char x
    // [527] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [528] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [530] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [531] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__register(X) char x, __register(Y) char y)
gotoxy: {
    .label __9 = $68
    // (x>=__conio.width)?__conio.width:x
    // [533] if(gotoxy::x#26>=*((char *)&__conio+4)) goto gotoxy::@1 -- vbuxx_ge__deref_pbuc1_then_la1 
    cpx __conio+4
    bcs __b1
    // [535] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [535] phi gotoxy::$3 = gotoxy::x#26 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [534] gotoxy::$2 = *((char *)&__conio+4) -- vbuxx=_deref_pbuc1 
    ldx __conio+4
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [536] *((char *)&__conio+$d) = gotoxy::$3 -- _deref_pbuc1=vbuxx 
    stx __conio+$d
    // (y>=__conio.height)?__conio.height:y
    // [537] if(gotoxy::y#26>=*((char *)&__conio+5)) goto gotoxy::@3 -- vbuyy_ge__deref_pbuc1_then_la1 
    cpy __conio+5
    bcs __b3
    // gotoxy::@4
    // [538] gotoxy::$14 = gotoxy::y#26 -- vbuaa=vbuyy 
    tya
    // [539] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [539] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [540] *((char *)&__conio+$e) = gotoxy::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+$e
    // __conio.cursor_x << 1
    // [541] gotoxy::$8 = *((char *)&__conio+$d) << 1 -- vbuxx=_deref_pbuc1_rol_1 
    lda __conio+$d
    asl
    tax
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [542] gotoxy::$10 = gotoxy::y#26 << 1 -- vbuaa=vbuyy_rol_1 
    tya
    asl
    // [543] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuaa_plus_vbuxx 
    tay
    txa
    clc
    adc __conio+$15,y
    sta.z __9
    lda __conio+$15+1,y
    adc #0
    sta.z __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [544] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z __9
    sta __conio+$13
    lda.z __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [545] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [546] gotoxy::$6 = *((char *)&__conio+5) -- vbuaa=_deref_pbuc1 
    lda __conio+5
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    // __conio.cursor_x = 0
    // [547] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y++;
    // [548] *((char *)&__conio+$e) = ++ *((char *)&__conio+$e) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$e
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [549] cputln::$2 = *((char *)&__conio+$e) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    // [550] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [551] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [552] return 
    rts
}
  // cbm_x_charset
/**
 * @brief Sets the [character set](https://github.com/commanderx16/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-screen_set_charset).
 * 
 * @param charset The code of the charset to copy.
 * @param offset The offset of the character set in ram.
 */
// void cbm_x_charset(__zp($ec) volatile char charset, __zp($e8) char * volatile offset)
cbm_x_charset: {
    .label charset = $ec
    .label offset = $e8
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_CHRSET  }
    lda charset
    ldx.z <offset
    ldy.z >offset
    jsr CX16_CHRSET
    // cbm_x_charset::@return
    // }
    // [554] return 
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
    // [555] ((char *)&__conio+$f)[*((char *)&__conio)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio
    sta __conio+$f,y
    // scroll::@return
    // }
    // [556] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label line_text = $6e
    .label ch = $6e
    // unsigned int line_text = __conio.mapbase_offset
    // [557] clrscr::line_text#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z line_text
    lda __conio+1+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [558] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [559] clrscr::$0 = *((char *)&__conio+3) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [560] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [561] clrscr::l#0 = *((char *)&__conio+7) -- vbuyy=_deref_pbuc1 
    ldy __conio+7
    // [562] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [562] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [562] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [563] clrscr::$1 = byte0  clrscr::ch#0 -- vbuaa=_byte0_vwuz1 
    lda.z ch
    // *VERA_ADDRX_L = BYTE0(ch)
    // [564] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuaa 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [565] clrscr::$2 = byte1  clrscr::ch#0 -- vbuaa=_byte1_vwuz1 
    lda.z ch+1
    // *VERA_ADDRX_M = BYTE1(ch)
    // [566] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [567] clrscr::c#0 = *((char *)&__conio+6) -- vbuxx=_deref_pbuc1 
    ldx __conio+6
    // [568] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [568] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [569] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [570] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [571] clrscr::c#1 = -- clrscr::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [572] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [573] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+8
    sta.z line_text
    lda.z line_text+1
    adc __conio+8+1
    sta.z line_text+1
    // l--;
    // [574] clrscr::l#1 = -- clrscr::l#4 -- vbuyy=_dec_vbuyy 
    dey
    // while(l)
    // [575] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [576] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y = 0
    // [577] *((char *)&__conio+$e) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+$e
    // __conio.offset = __conio.mapbase_offset
    // [578] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+1) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+1
    sta __conio+$13
    lda __conio+1+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [579] return 
    rts
}
  // frame_draw
frame_draw: {
    .label x = $a9
    .label x1 = $71
    .label y = $29
    .label x2 = $aa
    .label y_1 = $53
    .label x3 = $52
    .label y_2 = $57
    .label x4 = $58
    .label y_3 = $79
    .label x5 = $72
    // textcolor(WHITE)
    // [581] call textcolor
    // [514] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:frame_draw->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [582] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [583] call bgcolor
    // [519] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [584] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [585] call clrscr
    jsr clrscr
    // [586] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [586] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [587] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [588] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [589] call cputcxy
    // [1160] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [1160] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbuyy=vbuc1 
    ldy #0
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // [590] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [591] call cputcxy
    // [1160] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [1160] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbuyy=vbuc1 
    ldy #0
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // [592] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [593] call cputcxy
    // [1160] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbuyy=vbuc1 
    ldy #1
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // [594] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [595] call cputcxy
    // [1160] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbuyy=vbuc1 
    ldy #1
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // [596] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [596] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [597] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [598] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [599] call cputcxy
    // [1160] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [1160] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbuyy=vbuc1 
    ldy #2
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // [600] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [601] call cputcxy
    // [1160] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [1160] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbuyy=vbuc1 
    ldy #2
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // [602] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [603] call cputcxy
    // [1160] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [1160] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbuyy=vbuc1 
    ldy #2
    // [1160] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$c
    jsr cputcxy
    // [604] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [604] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbuz1=vbuc1 
    lda #3
    sta.z y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [605] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [606] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [606] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [607] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [608] cputcxy::y#13 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [609] call cputcxy
    // [1160] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [1160] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [610] cputcxy::y#14 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [611] call cputcxy
    // [1160] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [1160] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [612] cputcxy::y#15 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [613] call cputcxy
    // [1160] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [1160] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$c
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [614] frame_draw::y#5 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [615] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [615] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [616] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [617] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [617] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [618] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [619] cputcxy::y#19 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [620] call cputcxy
    // [1160] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [1160] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [621] cputcxy::y#20 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [622] call cputcxy
    // [1160] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [1160] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [623] cputcxy::y#21 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [624] call cputcxy
    // [1160] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [1160] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [625] cputcxy::y#22 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [626] call cputcxy
    // [1160] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [1160] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [627] cputcxy::y#23 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [628] call cputcxy
    // [1160] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [1160] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [629] cputcxy::y#24 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [630] call cputcxy
    // [1160] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [1160] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [631] cputcxy::y#25 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [632] call cputcxy
    // [1160] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [1160] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [633] cputcxy::y#26 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [634] call cputcxy
    // [1160] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [1160] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [635] cputcxy::y#27 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [636] call cputcxy
    // [1160] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [1160] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [637] cputcxy::y#28 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [638] call cputcxy
    // [1160] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [1160] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [639] frame_draw::y#7 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz2 
    lda.z y_1
    inc
    sta.z y_2
    // [640] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [640] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [641] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [642] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [642] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [643] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [644] cputcxy::y#39 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [645] call cputcxy
    // [1160] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [1160] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [646] cputcxy::y#40 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [647] call cputcxy
    // [1160] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [1160] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [648] cputcxy::y#41 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [649] call cputcxy
    // [1160] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [1160] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [650] cputcxy::y#42 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [651] call cputcxy
    // [1160] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [1160] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [652] cputcxy::y#43 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [653] call cputcxy
    // [1160] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [1160] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [654] cputcxy::y#44 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [655] call cputcxy
    // [1160] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [1160] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [656] cputcxy::y#45 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [657] call cputcxy
    // [1160] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [1160] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [658] cputcxy::y#46 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [659] call cputcxy
    // [1160] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [1160] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [660] cputcxy::y#47 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [661] call cputcxy
    // [1160] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [1160] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [662] frame_draw::y#9 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz2 
    lda.z y_2
    inc
    sta.z y_3
    // [663] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [663] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [664] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [665] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [665] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [666] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x5
    cmp #$4f
    bcc __b25
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [667] cputcxy::y#58 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [668] call cputcxy
    // [1160] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [1160] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [669] cputcxy::y#59 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [670] call cputcxy
    // [1160] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [1160] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [671] cputcxy::y#60 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [672] call cputcxy
    // [1160] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [1160] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [673] cputcxy::y#61 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [674] call cputcxy
    // [1160] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [1160] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [675] cputcxy::y#62 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [676] call cputcxy
    // [1160] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [1160] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [677] cputcxy::y#63 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [678] call cputcxy
    // [1160] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [1160] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [679] cputcxy::y#64 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [680] call cputcxy
    // [1160] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [1160] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [681] cputcxy::y#65 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [682] call cputcxy
    // [1160] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [1160] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [683] cputcxy::y#66 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [684] call cputcxy
    // [1160] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [1160] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [685] cputcxy::y#67 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [686] call cputcxy
    // [1160] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [1160] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@return
    // }
    // [687] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [688] cputcxy::x#57 = frame_draw::x5#2 -- vbuxx=vbuz1 
    ldx.z x5
    // [689] cputcxy::y#57 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [690] call cputcxy
    // [1160] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [1160] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [691] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbuz1=_inc_vbuz1 
    inc.z x5
    // [665] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [665] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [692] cputcxy::y#48 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [693] call cputcxy
    // [1160] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [694] cputcxy::y#49 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [695] call cputcxy
    // [1160] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [696] cputcxy::y#50 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [697] call cputcxy
    // [1160] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [698] cputcxy::y#51 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [699] call cputcxy
    // [1160] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [700] cputcxy::y#52 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [701] call cputcxy
    // [1160] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [702] cputcxy::y#53 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [703] call cputcxy
    // [1160] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [704] cputcxy::y#54 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [705] call cputcxy
    // [1160] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [706] cputcxy::y#55 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [707] call cputcxy
    // [1160] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [708] cputcxy::y#56 = frame_draw::y#106 -- vbuyy=vbuz1 
    ldy.z y_3
    // [709] call cputcxy
    // [1160] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [710] frame_draw::y#10 = ++ frame_draw::y#106 -- vbuz1=_inc_vbuz1 
    inc.z y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [711] cputcxy::x#38 = frame_draw::x4#2 -- vbuxx=vbuz1 
    ldx.z x4
    // [712] cputcxy::y#38 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [713] call cputcxy
    // [1160] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [1160] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [714] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbuz1=_inc_vbuz1 
    inc.z x4
    // [642] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [642] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [715] cputcxy::y#29 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [716] call cputcxy
    // [1160] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [717] cputcxy::y#30 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [718] call cputcxy
    // [1160] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [719] cputcxy::y#31 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [720] call cputcxy
    // [1160] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$a
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [721] cputcxy::y#32 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [722] call cputcxy
    // [1160] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$14
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [723] cputcxy::y#33 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [724] call cputcxy
    // [1160] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$1e
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [725] cputcxy::y#34 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [726] call cputcxy
    // [1160] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$28
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [727] cputcxy::y#35 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [728] call cputcxy
    // [1160] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$32
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [729] cputcxy::y#36 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [730] call cputcxy
    // [1160] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$3c
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [731] cputcxy::y#37 = frame_draw::y#104 -- vbuyy=vbuz1 
    ldy.z y_2
    // [732] call cputcxy
    // [1160] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$46
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [733] frame_draw::y#8 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz1 
    inc.z y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [734] cputcxy::x#18 = frame_draw::x3#2 -- vbuxx=vbuz1 
    ldx.z x3
    // [735] cputcxy::y#18 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [736] call cputcxy
    // [1160] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [1160] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [737] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbuz1=_inc_vbuz1 
    inc.z x3
    // [617] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [617] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [738] cputcxy::y#16 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [739] call cputcxy
    // [1160] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [740] cputcxy::y#17 = frame_draw::y#102 -- vbuyy=vbuz1 
    ldy.z y_1
    // [741] call cputcxy
    // [1160] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [742] frame_draw::y#6 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [743] cputcxy::x#12 = frame_draw::x2#2 -- vbuxx=vbuz1 
    ldx.z x2
    // [744] cputcxy::y#12 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [745] call cputcxy
    // [1160] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [1160] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [746] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbuz1=_inc_vbuz1 
    inc.z x2
    // [606] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [606] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [747] cputcxy::y#9 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [748] call cputcxy
    // [1160] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbuxx=vbuc1 
    ldx #0
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [749] cputcxy::y#10 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [750] call cputcxy
    // [1160] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$c
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [751] cputcxy::y#11 = frame_draw::y#101 -- vbuyy=vbuz1 
    ldy.z y
    // [752] call cputcxy
    // [1160] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [1160] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [1160] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbuxx=vbuc1 
    ldx #$4f
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [753] frame_draw::y#4 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [604] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [604] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [754] cputcxy::x#5 = frame_draw::x1#2 -- vbuxx=vbuz1 
    ldx.z x1
    // [755] call cputcxy
    // [1160] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [1160] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbuyy=vbuc1 
    ldy #2
    // [1160] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [756] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbuz1=_inc_vbuz1 
    inc.z x1
    // [596] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [596] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [757] cputcxy::x#0 = frame_draw::x#2 -- vbuxx=vbuz1 
    ldx.z x
    // [758] call cputcxy
    // [1160] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [1160] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1160] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbuyy=vbuc1 
    ldy #0
    // [1160] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [759] frame_draw::x#1 = ++ frame_draw::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [586] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [586] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
    jmp __b1
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($6e) void (*putc)(char), __zp($23) const char *s)
printf_str: {
    .label s = $23
    .label putc = $6e
    // [761] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [761] phi printf_str::s#36 = printf_str::s#37 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [762] printf_str::c#1 = *printf_str::s#36 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [763] printf_str::s#0 = ++ printf_str::s#36 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [764] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // printf_str::@return
    // }
    // [765] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [766] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [767] callexecute *printf_str::putc#37  -- call__deref_pprz1 
    jsr icall11
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall11:
    jmp (putc)
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [769] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [770] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [771] __snprintf_buffer = main::buffer -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z __snprintf_buffer
    lda #>main.buffer
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [772] return 
    rts
}
  // print_text
// void print_text(char *text)
print_text: {
    // textcolor(WHITE)
    // [774] call textcolor
    // [514] phi from print_text to textcolor [phi:print_text->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:print_text->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [775] phi from print_text to print_text::@1 [phi:print_text->print_text::@1]
    // print_text::@1
    // gotoxy(2, 39)
    // [776] call gotoxy
    // [532] phi from print_text::@1 to gotoxy [phi:print_text::@1->gotoxy]
    // [532] phi gotoxy::y#26 = $27 [phi:print_text::@1->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$27
    // [532] phi gotoxy::x#26 = 2 [phi:print_text::@1->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // [777] phi from print_text::@1 to print_text::@2 [phi:print_text::@1->print_text::@2]
    // print_text::@2
    // printf("%-76s", text)
    // [778] call printf_string
    // [902] phi from print_text::@2 to printf_string [phi:print_text::@2->printf_string]
    // [902] phi printf_string::str#10 = main::buffer [phi:print_text::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z printf_string.str
    lda #>main.buffer
    sta.z printf_string.str+1
    // [902] phi printf_string::format_justify_left#10 = 1 [phi:print_text::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [902] phi printf_string::format_min_length#7 = $4c [phi:print_text::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #$4c
    sta.z printf_string.format_min_length
    jsr printf_string
    // print_text::@return
    // }
    // [779] return 
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
    // [781] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [782] phi from wait_key::bank_set_bram1 to wait_key::@2 [phi:wait_key::bank_set_bram1->wait_key::@2]
    // wait_key::@2
    // bank_set_brom(4)
    // [783] call bank_set_brom
    // [790] phi from wait_key::@2 to bank_set_brom [phi:wait_key::@2->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 4 [phi:wait_key::@2->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // [784] phi from wait_key::@2 wait_key::@3 to wait_key::@1 [phi:wait_key::@2/wait_key::@3->wait_key::@1]
    // wait_key::@1
  __b1:
    // getin()
    // [785] call getin
    jsr getin
    // [786] getin::return#2 = getin::return#1
    // wait_key::@3
    // [787] wait_key::return#0 = getin::return#2
    // while (!(ch = getin()))
    // [788] if(0==wait_key::return#0) goto wait_key::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // wait_key::@return
    // }
    // [789] return 
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
// void bank_set_brom(__register(A) char bank)
bank_set_brom: {
    // BROM = bank
    // [791] BROM = bank_set_brom::bank#12 -- vbuz1=vbuaa 
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [792] return 
    rts
}
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [794] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [795] phi from system_reset::bank_set_bram1 to system_reset::@1 [phi:system_reset::bank_set_bram1->system_reset::@1]
    // system_reset::@1
    // bank_set_brom(0)
    // [796] call bank_set_brom
    // [790] phi from system_reset::@1 to bank_set_brom [phi:system_reset::@1->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = 0 [phi:system_reset::@1->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #0
    jsr bank_set_brom
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [798] return 
}
  // printf_sint
// Print a signed integer using a specific format
// void printf_sint(void (*putc)(char), __zp($23) int value, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_sint: {
    .const format_min_length = 0
    .const format_justify_left = 0
    .const format_zero_padding = 0
    .const format_upper_case = 0
    .label putc = snputc
    .label value = $23
    // printf_buffer.sign = 0
    // [799] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // if(value<0)
    // [800] if(printf_sint::value#1<0) goto printf_sint::@1 -- vwsz1_lt_0_then_la1 
    lda.z value+1
    bmi __b1
    // [803] phi from printf_sint printf_sint::@1 to printf_sint::@2 [phi:printf_sint/printf_sint::@1->printf_sint::@2]
    // [803] phi printf_sint::value#4 = printf_sint::value#1 [phi:printf_sint/printf_sint::@1->printf_sint::@2#0] -- register_copy 
    jmp __b2
    // printf_sint::@1
  __b1:
    // value = -value
    // [801] printf_sint::value#0 = - printf_sint::value#1 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z value
    sta.z value
    lda #0
    sbc.z value+1
    sta.z value+1
    // printf_buffer.sign = '-'
    // [802] *((char *)&printf_buffer) = '-'pm -- _deref_pbuc1=vbuc2 
    lda #'-'
    sta printf_buffer
    // printf_sint::@2
  __b2:
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [804] utoa::value#1 = (unsigned int)printf_sint::value#4
    // [805] call utoa
    // [1173] phi from printf_sint::@2 to utoa [phi:printf_sint::@2->utoa]
    // [1173] phi utoa::value#10 = utoa::value#1 [phi:printf_sint::@2->utoa#0] -- register_copy 
    // [1173] phi utoa::radix#2 = DECIMAL [phi:printf_sint::@2->utoa#1] -- vbuaa=vbuc1 
    lda #DECIMAL
    jsr utoa
    // printf_sint::@3
    // printf_number_buffer(putc, printf_buffer, format)
    // [806] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [807] call printf_number_buffer
  // Print using format
    // [1204] phi from printf_sint::@3 to printf_number_buffer [phi:printf_sint::@3->printf_number_buffer]
    // [1204] phi printf_number_buffer::format_upper_case#10 = printf_sint::format_upper_case#0 [phi:printf_sint::@3->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #format_upper_case
    sta.z printf_number_buffer.format_upper_case
    // [1204] phi printf_number_buffer::putc#10 = printf_sint::putc#0 [phi:printf_sint::@3->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [1204] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_sint::@3->printf_number_buffer#2] -- register_copy 
    // [1204] phi printf_number_buffer::format_zero_padding#10 = printf_sint::format_zero_padding#0 [phi:printf_sint::@3->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #format_zero_padding
    sta.z printf_number_buffer.format_zero_padding
    // [1204] phi printf_number_buffer::format_justify_left#10 = printf_sint::format_justify_left#0 [phi:printf_sint::@3->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #format_justify_left
    sta.z printf_number_buffer.format_justify_left
    // [1204] phi printf_number_buffer::format_min_length#4 = printf_sint::format_min_length#0 [phi:printf_sint::@3->printf_number_buffer#5] -- vbuxx=vbuc1 
    ldx #format_min_length
    jsr printf_number_buffer
    // printf_sint::@return
    // }
    // [808] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($5d) void (*putc)(char), __register(X) char uvalue, __zp($a9) char format_min_length, char format_justify_left, char format_sign_always, __zp($71) char format_zero_padding, char format_upper_case, __register(Y) char format_radix)
printf_uchar: {
    .label putc = $5d
    .label format_min_length = $a9
    .label format_zero_padding = $71
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [810] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [811] uctoa::value#1 = printf_uchar::uvalue#13
    // [812] uctoa::radix#0 = printf_uchar::format_radix#13
    // [813] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [814] printf_number_buffer::putc#3 = printf_uchar::putc#13
    // [815] printf_number_buffer::buffer_sign#3 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [816] printf_number_buffer::format_min_length#3 = printf_uchar::format_min_length#13 -- vbuxx=vbuz1 
    ldx.z format_min_length
    // [817] printf_number_buffer::format_zero_padding#3 = printf_uchar::format_zero_padding#13
    // [818] call printf_number_buffer
  // Print using format
    // [1204] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1204] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1204] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#3 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1204] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#3 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1204] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#3 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [1204] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [1204] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#3 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [819] return 
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
// __zp($6e) struct $1 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label fp = $6e
    .label return = $6e
    // FILE *fp = &__files[__filecount]
    // [820] fopen::$32 = __filecount << 2 -- vbuaa=vbum1_rol_2 
    lda __filecount
    asl
    asl
    // [821] fopen::$33 = fopen::$32 + __filecount -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc __filecount
    // [822] fopen::$11 = fopen::$33 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [823] fopen::fp#0 = __files + fopen::$11 -- pssz1=pssc1_plus_vbuaa 
    clc
    adc #<__files
    sta.z fp
    lda #>__files
    adc #0
    sta.z fp+1
    // fp->status = 0
    // [824] ((char *)fopen::fp#0)[$13] = 0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #0
    ldy #$13
    sta (fp),y
    // fp->channel = channel
    // [825] ((char *)fopen::fp#0)[$10] = fopen::channel#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #channel
    ldy #$10
    sta (fp),y
    // fp->device = device
    // [826] ((char *)fopen::fp#0)[$11] = fopen::device#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #device
    ldy #$11
    sta (fp),y
    // fp->secondary = secondary
    // [827] ((char *)fopen::fp#0)[$12] = fopen::secondary#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #secondary
    ldy #$12
    sta (fp),y
    // strncpy(fp->filename, filename, 16)
    // [828] strncpy::dst#1 = (char *)fopen::fp#0 -- pbuz1=pbuz2 
    lda.z fp
    sta.z strncpy.dst
    lda.z fp+1
    sta.z strncpy.dst+1
    // [829] call strncpy
    // [1273] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@5
    // cbm_k_setnam(filename)
    // [830] cbm_k_setnam::filename = main::buffer -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z cbm_k_setnam.filename
    lda #>main.buffer
    sta.z cbm_k_setnam.filename+1
    // [831] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@6
    // cbm_k_setlfs(channel, device, secondary)
    // [832] cbm_k_setlfs::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_setlfs.channel
    // [833] cbm_k_setlfs::device = fopen::device#0 -- vbuz1=vbuc1 
    lda #device
    sta.z cbm_k_setlfs.device
    // [834] cbm_k_setlfs::command = fopen::secondary#0 -- vbuz1=vbuc1 
    lda #secondary
    sta.z cbm_k_setlfs.command
    // [835] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [836] phi from fopen::@6 to fopen::@7 [phi:fopen::@6->fopen::@7]
    // fopen::@7
    // cbm_k_open()
    // [837] call cbm_k_open
    jsr cbm_k_open
    // [838] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@8
    // [839] fopen::$4 = cbm_k_open::return#2
    // fp->status = cbm_k_open()
    // [840] ((char *)fopen::fp#0)[$13] = fopen::$4 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [841] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // fopen::@3
    // cbm_k_close(channel)
    // [842] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [843] call cbm_k_close
    jsr cbm_k_close
    // [844] phi from fopen::@3 fopen::@4 to fopen::@return [phi:fopen::@3/fopen::@4->fopen::@return]
  __b3:
    // [844] phi fopen::return#1 = 0 [phi:fopen::@3/fopen::@4->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [845] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [846] cbm_k_chkin::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_chkin.channel
    // [847] call cbm_k_chkin
    jsr cbm_k_chkin
    // [848] phi from fopen::@1 to fopen::@9 [phi:fopen::@1->fopen::@9]
    // fopen::@9
    // cbm_k_readst()
    // [849] call cbm_k_readst
    jsr cbm_k_readst
    // [850] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@10
    // [851] fopen::$7 = cbm_k_readst::return#2
    // fp->status = cbm_k_readst()
    // [852] ((char *)fopen::fp#0)[$13] = fopen::$7 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [853] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@2 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b2
    // fopen::@4
    // cbm_k_close(channel)
    // [854] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [855] call cbm_k_close
    jsr cbm_k_close
    jmp __b3
    // fopen::@2
  __b2:
    // __filecount++;
    // [856] __filecount = ++ __filecount -- vbum1=_inc_vbum1 
    inc __filecount
    // [844] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [844] phi fopen::return#1 = fopen::fp#0 [phi:fopen::@2->fopen::@return#0] -- register_copy 
    rts
}
  // print_chip_led
// void print_chip_led(__register(X) char r, __zp($7e) char tc, char bc)
print_chip_led: {
    .label tc = $7e
    // r * 10
    // [858] print_chip_led::$8 = print_chip_led::r#10 << 2 -- vbuaa=vbuxx_rol_2 
    txa
    asl
    asl
    // [859] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#10 -- vbuaa=vbuaa_plus_vbuxx 
    stx.z $ff
    clc
    adc.z $ff
    // [860] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(4 + r * 10, 43)
    // [861] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbuxx=vbuc1_plus_vbuaa 
    clc
    adc #4
    tax
    // [862] call gotoxy
    // [532] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [532] phi gotoxy::y#26 = $2b [phi:print_chip_led->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$2b
    // [532] phi gotoxy::x#26 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [863] textcolor::color#7 = print_chip_led::tc#10 -- vbuxx=vbuz1 
    ldx.z tc
    // [864] call textcolor
    // [514] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [514] phi textcolor::color#23 = textcolor::color#7 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [865] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [866] call bgcolor
    // [519] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [867] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [868] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [870] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [871] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [873] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [874] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [876] return 
    rts
}
  // table_chip_clear
// void table_chip_clear(__zp($5f) char rom_bank)
table_chip_clear: {
    .label flash_rom_address = $25
    .label rom_bank = $5f
    .label y = $78
    // textcolor(WHITE)
    // [878] call textcolor
    // [514] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:table_chip_clear->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [879] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [880] call bgcolor
    // [519] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [881] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [881] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [881] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [882] if(table_chip_clear::y#10<$24) goto table_chip_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$24
    bcc __b2
    // table_chip_clear::@return
    // }
    // [883] return 
    rts
    // table_chip_clear::@2
  __b2:
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [884] rom_address::rom_bank#1 = table_chip_clear::rom_bank#11 -- vbuaa=vbuz1 
    lda.z rom_bank
    // [885] call rom_address
    // [924] phi from table_chip_clear::@2 to rom_address [phi:table_chip_clear::@2->rom_address]
    // [924] phi rom_address::rom_bank#5 = rom_address::rom_bank#1 [phi:table_chip_clear::@2->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [886] rom_address::return#3 = rom_address::return#0
    // table_chip_clear::@4
    // [887] table_chip_clear::flash_rom_address#0 = rom_address::return#3 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z flash_rom_address
    lda.z rom_address.return+1
    sta.z flash_rom_address+1
    lda.z rom_address.return+2
    sta.z flash_rom_address+2
    lda.z rom_address.return+3
    sta.z flash_rom_address+3
    // gotoxy(2, y)
    // [888] gotoxy::y#8 = table_chip_clear::y#10 -- vbuyy=vbuz1 
    ldy.z y
    // [889] call gotoxy
    // [532] phi from table_chip_clear::@4 to gotoxy [phi:table_chip_clear::@4->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#8 [phi:table_chip_clear::@4->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = 2 [phi:table_chip_clear::@4->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // table_chip_clear::@5
    // printf("%02x", rom_bank)
    // [890] printf_uchar::uvalue#0 = table_chip_clear::rom_bank#11 -- vbuxx=vbuz1 
    ldx.z rom_bank
    // [891] call printf_uchar
    // [809] phi from table_chip_clear::@5 to printf_uchar [phi:table_chip_clear::@5->printf_uchar]
    // [809] phi printf_uchar::format_zero_padding#13 = 1 [phi:table_chip_clear::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [809] phi printf_uchar::format_min_length#13 = 2 [phi:table_chip_clear::@5->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [809] phi printf_uchar::putc#13 = &cputc [phi:table_chip_clear::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [809] phi printf_uchar::format_radix#13 = HEXADECIMAL [phi:table_chip_clear::@5->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [809] phi printf_uchar::uvalue#13 = printf_uchar::uvalue#0 [phi:table_chip_clear::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@6
    // gotoxy(5, y)
    // [892] gotoxy::y#9 = table_chip_clear::y#10 -- vbuyy=vbuz1 
    ldy.z y
    // [893] call gotoxy
    // [532] phi from table_chip_clear::@6 to gotoxy [phi:table_chip_clear::@6->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#9 [phi:table_chip_clear::@6->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = 5 [phi:table_chip_clear::@6->gotoxy#1] -- vbuxx=vbuc1 
    ldx #5
    jsr gotoxy
    // table_chip_clear::@7
    // printf("%06x", flash_rom_address)
    // [894] printf_ulong::uvalue#0 = table_chip_clear::flash_rom_address#0
    // [895] call printf_ulong
    // [1025] phi from table_chip_clear::@7 to printf_ulong [phi:table_chip_clear::@7->printf_ulong]
    // [1025] phi printf_ulong::format_zero_padding#4 = 1 [phi:table_chip_clear::@7->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1025] phi printf_ulong::uvalue#4 = printf_ulong::uvalue#0 [phi:table_chip_clear::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // table_chip_clear::@8
    // gotoxy(14, y)
    // [896] gotoxy::y#10 = table_chip_clear::y#10 -- vbuyy=vbuz1 
    ldy.z y
    // [897] call gotoxy
    // [532] phi from table_chip_clear::@8 to gotoxy [phi:table_chip_clear::@8->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#10 [phi:table_chip_clear::@8->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = $e [phi:table_chip_clear::@8->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$e
    jsr gotoxy
    // [898] phi from table_chip_clear::@8 to table_chip_clear::@9 [phi:table_chip_clear::@8->table_chip_clear::@9]
    // table_chip_clear::@9
    // printf("%64s", " ")
    // [899] call printf_string
    // [902] phi from table_chip_clear::@9 to printf_string [phi:table_chip_clear::@9->printf_string]
    // [902] phi printf_string::str#10 = table_chip_clear::str [phi:table_chip_clear::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [902] phi printf_string::format_justify_left#10 = 0 [phi:table_chip_clear::@9->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [902] phi printf_string::format_min_length#7 = $40 [phi:table_chip_clear::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #$40
    sta.z printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@10
    // rom_bank++;
    // [900] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [901] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [881] phi from table_chip_clear::@10 to table_chip_clear::@1 [phi:table_chip_clear::@10->table_chip_clear::@1]
    // [881] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@10->table_chip_clear::@1#0] -- register_copy 
    // [881] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@10->table_chip_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    str: .text " "
    .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($23) char *str, __zp($29) char format_min_length, __zp($aa) char format_justify_left)
printf_string: {
    .label __9 = $2a
    .label padding = $29
    .label str = $23
    .label format_min_length = $29
    .label format_justify_left = $aa
    // if(format.min_length)
    // [903] if(0==printf_string::format_min_length#7) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [904] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [905] call strlen
    // [1311] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1311] phi strlen::str#6 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [906] strlen::return#4 = strlen::len#2
    // printf_string::@6
    // [907] printf_string::$9 = strlen::return#4
    // signed char len = (signed char)strlen(str)
    // [908] printf_string::len#0 = (signed char)printf_string::$9 -- vbsaa=_sbyte_vwuz1 
    lda.z __9
    // padding = (signed char)format.min_length  - len
    // [909] printf_string::padding#1 = (signed char)printf_string::format_min_length#7 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsaa 
    eor #$ff
    sec
    adc.z padding
    sta.z padding
    // if(padding<0)
    // [910] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [912] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [912] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [911] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [912] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [912] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [913] if(0!=printf_string::format_justify_left#10) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [914] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [915] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [916] call printf_padding
    // [1317] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1317] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1317] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1317] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [917] printf_str::s#2 = printf_string::str#10
    // [918] call printf_str
    // [760] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [760] phi printf_str::putc#37 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [760] phi printf_str::s#37 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [919] if(0==printf_string::format_justify_left#10) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [920] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [921] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [922] call printf_padding
    // [1317] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1317] phi printf_padding::putc#7 = &cputc [phi:printf_string::@5->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1317] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1317] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [923] return 
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
// __zp($bf) unsigned long rom_address(__register(A) char rom_bank)
rom_address: {
    .label __1 = $41
    .label return = $7a
    .label return_1 = $39
    .label return_2 = $60
    .label return_3 = $bf
    // ((unsigned long)(rom_bank)) << 14
    // [925] rom_address::$1 = (unsigned long)rom_address::rom_bank#5 -- vduz1=_dword_vbuaa 
    sta.z __1
    lda #0
    sta.z __1+1
    sta.z __1+2
    sta.z __1+3
    // [926] rom_address::return#0 = rom_address::$1 << $e -- vduz1=vduz2_rol_vbuc1 
    ldy #$e
    lda.z __1
    sta.z return
    lda.z __1+1
    sta.z return+1
    lda.z __1+2
    sta.z return+2
    lda.z __1+3
    sta.z return+3
    cpy #0
    beq !e+
  !:
    asl.z return
    rol.z return+1
    rol.z return+2
    rol.z return+3
    dey
    bne !-
  !e:
    // rom_address::@return
    // }
    // [927] return 
    rts
}
  // flash_read
// __zp($74) unsigned long flash_read(__zp($5d) struct $1 *fp, __zp($23) char *flash_ram_address, __zp($70) char rom_bank_start, __register(X) char rom_bank_size)
flash_read: {
    .label __4 = $41
    .label __13 = $6a
    .label flash_rom_address = $39
    .label flash_size = $59
    .label read_bytes = $4f
    .label rom_bank_start = $70
    .label return = $74
    .label flash_ram_address = $23
    .label flash_bytes = $74
    .label fp = $5d
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [929] rom_address::rom_bank#0 = flash_read::rom_bank_start#11 -- vbuaa=vbuz1 
    lda.z rom_bank_start
    // [930] call rom_address
    // [924] phi from flash_read to rom_address [phi:flash_read->rom_address]
    // [924] phi rom_address::rom_bank#5 = rom_address::rom_bank#0 [phi:flash_read->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [931] rom_address::return#2 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_1
    lda.z rom_address.return+1
    sta.z rom_address.return_1+1
    lda.z rom_address.return+2
    sta.z rom_address.return_1+2
    lda.z rom_address.return+3
    sta.z rom_address.return_1+3
    // flash_read::@9
    // [932] flash_read::flash_rom_address#0 = rom_address::return#2
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [933] rom_size::rom_banks#0 = flash_read::rom_bank_size#2 -- vbuaa=vbuxx 
    txa
    // [934] call rom_size
    // [964] phi from flash_read::@9 to rom_size [phi:flash_read::@9->rom_size]
    // [964] phi rom_size::rom_banks#2 = rom_size::rom_banks#0 [phi:flash_read::@9->rom_size#0] -- register_copy 
    jsr rom_size
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [935] rom_size::return#2 = rom_size::return#0
    // flash_read::@10
    // [936] flash_read::flash_size#0 = rom_size::return#2
    // textcolor(WHITE)
    // [937] call textcolor
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [514] phi from flash_read::@10 to textcolor [phi:flash_read::@10->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:flash_read::@10->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [938] phi from flash_read::@10 to flash_read::@1 [phi:flash_read::@10->flash_read::@1]
    // [938] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@10->flash_read::@1#0] -- register_copy 
    // [938] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@10->flash_read::@1#1] -- register_copy 
    // [938] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#0 [phi:flash_read::@10->flash_read::@1#2] -- register_copy 
    // [938] phi flash_read::return#2 = 0 [phi:flash_read::@10->flash_read::@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // [938] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [938] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [938] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [938] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [938] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < flash_size)
    // [939] if(flash_read::return#2<flash_read::flash_size#0) goto flash_read::@2 -- vduz1_lt_vduz2_then_la1 
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
    // [940] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [941] flash_read::$4 = flash_read::flash_rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [942] if(0!=flash_read::$4) goto flash_read::@3 -- 0_neq_vduz1_then_la1 
    lda.z __4
    ora.z __4+1
    ora.z __4+2
    ora.z __4+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [943] flash_read::$7 = flash_read::rom_bank_start#4 & $20-1 -- vbuaa=vbuz1_band_vbuc1 
    lda #$20-1
    and.z rom_bank_start
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [944] gotoxy::y#7 = 4 + flash_read::$7 -- vbuyy=vbuc1_plus_vbuaa 
    clc
    adc #4
    tay
    // [945] call gotoxy
    // [532] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#7 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = $e [phi:flash_read::@6->gotoxy#1] -- vbuxx=vbuc1 
    ldx #$e
    jsr gotoxy
    // flash_read::@12
    // rom_bank_start++;
    // [946] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank_start
    // [947] phi from flash_read::@12 flash_read::@2 to flash_read::@3 [phi:flash_read::@12/flash_read::@2->flash_read::@3]
    // [947] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@12/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [948] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [949] fgets::fp#0 = flash_read::fp#10 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [950] call fgets
    jsr fgets
    // [951] fgets::return#5 = fgets::return#1
    // flash_read::@11
    // [952] flash_read::read_bytes#0 = fgets::return#5
    // if (!read_bytes)
    // [953] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwuz1_then_la1 
    lda.z read_bytes
    ora.z read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [954] flash_read::$13 = flash_read::flash_rom_address#10 & $100-1 -- vduz1=vduz2_band_vduc1 
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
    // [955] if(0!=flash_read::$13) goto flash_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z __13
    ora.z __13+1
    ora.z __13+2
    ora.z __13+3
    bne __b5
    // flash_read::@7
    // cputc('.')
    // [956] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    // cputc(0xE0);
    lda #'.'
    pha
    // [957] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [959] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [960] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [961] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [962] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // [963] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
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
// __zp($59) unsigned long rom_size(__register(A) char rom_banks)
rom_size: {
    .label __1 = $59
    .label return = $59
    // ((unsigned long)(rom_banks)) << 14
    // [965] rom_size::$1 = (unsigned long)rom_size::rom_banks#2 -- vduz1=_dword_vbuaa 
    sta.z __1
    lda #0
    sta.z __1+1
    sta.z __1+2
    sta.z __1+3
    // [966] rom_size::return#0 = rom_size::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [967] return 
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
// int fclose(__zp($e6) struct $1 *fp)
fclose: {
    .label fp = $e6
    // cbm_k_close(fp->channel)
    // [968] cbm_k_close::channel = ((char *)fclose::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_close.channel
    // [969] call cbm_k_close
    jsr cbm_k_close
    // [970] cbm_k_close::return#4 = cbm_k_close::return#1
    // fclose::@2
    // [971] fclose::$0 = cbm_k_close::return#4
    // fp->status = cbm_k_close(fp->channel)
    // [972] ((char *)fclose::fp#0)[$13] = fclose::$0 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // char st = fp->status
    // [973] fclose::st#0 = ((char *)fclose::fp#0)[$13] -- vbuaa=pbuz1_derefidx_vbuc1 
    lda (fp),y
    // if(st)
    // [974] if(0==fclose::st#0) goto fclose::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [975] return 
    rts
    // [976] phi from fclose::@2 to fclose::@1 [phi:fclose::@2->fclose::@1]
    // fclose::@1
  __b1:
    // cbm_k_clrchn()
    // [977] call cbm_k_clrchn
    jsr cbm_k_clrchn
    // fclose::@3
    // __filecount--;
    // [978] __filecount = -- __filecount -- vbum1=_dec_vbum1 
    dec __filecount
    rts
}
  // flash_verify
// __zp($5d) unsigned int flash_verify(__register(X) char bank_ram, __zp($46) char *ptr_ram, __zp($39) unsigned long verify_rom_address, __zp($6e) unsigned int verify_rom_size)
flash_verify: {
    .label bank_rom = $78
    .label ptr_rom = $3d
    .label ptr_ram = $46
    .label verified_bytes = $23
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label correct_bytes = $5d
    .label verify_rom_address = $39
    .label return = $5d
    .label verify_rom_size = $6e
    // flash_verify::bank_set_bram1
    // BRAM = bank
    // [980] BRAM = flash_verify::bank_set_bram1_bank#0 -- vbuz1=vbuxx 
    stx.z BRAM
    // flash_verify::@6
    // brom_bank_t bank_rom = rom_bank((unsigned long)verify_rom_address)
    // [981] rom_bank::address#1 = flash_verify::verify_rom_address#3 -- vduz1=vduz2 
    lda.z verify_rom_address
    sta.z rom_bank.address
    lda.z verify_rom_address+1
    sta.z rom_bank.address+1
    lda.z verify_rom_address+2
    sta.z rom_bank.address+2
    lda.z verify_rom_address+3
    sta.z rom_bank.address+3
    // [982] call rom_bank
    // [1368] phi from flash_verify::@6 to rom_bank [phi:flash_verify::@6->rom_bank]
    // [1368] phi rom_bank::address#2 = rom_bank::address#1 [phi:flash_verify::@6->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)verify_rom_address)
    // [983] rom_bank::return#3 = rom_bank::return#0
    // flash_verify::@8
    // [984] flash_verify::bank_rom#0 = rom_bank::return#3 -- vbuz1=vbuaa 
    sta.z bank_rom
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)verify_rom_address)
    // [985] rom_ptr::address#3 = flash_verify::verify_rom_address#3
    // [986] call rom_ptr
    // [1373] phi from flash_verify::@8 to rom_ptr [phi:flash_verify::@8->rom_ptr]
    // [1373] phi rom_ptr::address#4 = rom_ptr::address#3 [phi:flash_verify::@8->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // flash_verify::@9
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)verify_rom_address)
    // [987] flash_verify::ptr_rom#0 = (char *)rom_ptr::return#0
    // flash_verify::bank_get_brom1
    // return BROM;
    // [988] flash_verify::bank_get_brom1_return#0 = BROM -- vbuxx=vbuz1 
    ldx.z BROM
    // flash_verify::@7
    // bank_set_brom(bank_rom)
    // [989] bank_set_brom::bank#3 = flash_verify::bank_rom#0 -- vbuaa=vbuz1 
    lda.z bank_rom
    // [990] call bank_set_brom
    // [790] phi from flash_verify::@7 to bank_set_brom [phi:flash_verify::@7->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = bank_set_brom::bank#3 [phi:flash_verify::@7->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // [991] phi from flash_verify::@7 to flash_verify::@1 [phi:flash_verify::@7->flash_verify::@1]
    // [991] phi flash_verify::correct_bytes#2 = 0 [phi:flash_verify::@7->flash_verify::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z correct_bytes
    sta.z correct_bytes+1
    // [991] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#10 [phi:flash_verify::@7->flash_verify::@1#1] -- register_copy 
    // [991] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#0 [phi:flash_verify::@7->flash_verify::@1#2] -- register_copy 
    // [991] phi flash_verify::verified_bytes#2 = 0 [phi:flash_verify::@7->flash_verify::@1#3] -- vwuz1=vwuc1 
    sta.z verified_bytes
    sta.z verified_bytes+1
    // flash_verify::@1
  __b1:
    // while (verified_bytes < verify_rom_size)
    // [992] if(flash_verify::verified_bytes#2<flash_verify::verify_rom_size#11) goto flash_verify::@2 -- vwuz1_lt_vwuz2_then_la1 
    lda.z verified_bytes+1
    cmp.z verify_rom_size+1
    bcc __b2
    bne !+
    lda.z verified_bytes
    cmp.z verify_rom_size
    bcc __b2
  !:
    // flash_verify::@3
    // bank_set_brom(bank_rom_old)
    // [993] bank_set_brom::bank#4 = flash_verify::bank_get_brom1_return#0 -- vbuaa=vbuxx 
    txa
    // [994] call bank_set_brom
    // [790] phi from flash_verify::@3 to bank_set_brom [phi:flash_verify::@3->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = bank_set_brom::bank#4 [phi:flash_verify::@3->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // flash_verify::@return
    // }
    // [995] return 
    rts
    // flash_verify::@2
  __b2:
    // rom_byte_verify(ptr_rom, *ptr_ram)
    // [996] rom_byte_verify::ptr_rom#0 = flash_verify::ptr_rom#2
    // [997] rom_byte_verify::value#0 = *flash_verify::ptr_ram#4 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (ptr_ram),y
    // [998] call rom_byte_verify
    jsr rom_byte_verify
    // [999] rom_byte_verify::return#2 = rom_byte_verify::return#0
    // flash_verify::@10
    // [1000] flash_verify::$7 = rom_byte_verify::return#2
    // if (rom_byte_verify(ptr_rom, *ptr_ram))
    // [1001] if(0==flash_verify::$7) goto flash_verify::@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b4
    // flash_verify::@5
    // correct_bytes++;
    // [1002] flash_verify::correct_bytes#1 = ++ flash_verify::correct_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z correct_bytes
    bne !+
    inc.z correct_bytes+1
  !:
    // [1003] phi from flash_verify::@10 flash_verify::@5 to flash_verify::@4 [phi:flash_verify::@10/flash_verify::@5->flash_verify::@4]
    // [1003] phi flash_verify::correct_bytes#9 = flash_verify::correct_bytes#2 [phi:flash_verify::@10/flash_verify::@5->flash_verify::@4#0] -- register_copy 
    // flash_verify::@4
  __b4:
    // ptr_rom++;
    // [1004] flash_verify::ptr_rom#1 = ++ flash_verify::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [1005] flash_verify::ptr_ram#0 = ++ flash_verify::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // verified_bytes++;
    // [1006] flash_verify::verified_bytes#1 = ++ flash_verify::verified_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z verified_bytes
    bne !+
    inc.z verified_bytes+1
  !:
    // [991] phi from flash_verify::@4 to flash_verify::@1 [phi:flash_verify::@4->flash_verify::@1]
    // [991] phi flash_verify::correct_bytes#2 = flash_verify::correct_bytes#9 [phi:flash_verify::@4->flash_verify::@1#0] -- register_copy 
    // [991] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#0 [phi:flash_verify::@4->flash_verify::@1#1] -- register_copy 
    // [991] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#1 [phi:flash_verify::@4->flash_verify::@1#2] -- register_copy 
    // [991] phi flash_verify::verified_bytes#2 = flash_verify::verified_bytes#1 [phi:flash_verify::@4->flash_verify::@1#3] -- register_copy 
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
// void rom_sector_erase(__zp($ab) unsigned long address)
rom_sector_erase: {
    .label ptr_rom = $2c
    .label rom_chip_address = $59
    .label address = $ab
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1007] rom_ptr::address#2 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [1008] call rom_ptr
    // [1373] phi from rom_sector_erase to rom_ptr [phi:rom_sector_erase->rom_ptr]
    // [1373] phi rom_ptr::address#4 = rom_ptr::address#2 [phi:rom_sector_erase->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_sector_erase::@1
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1009] rom_sector_erase::ptr_rom#0 = (char *)rom_ptr::return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [1010] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1011] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [1012] call rom_unlock
    // [1046] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1046] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1046] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [1013] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [1014] call rom_unlock
    // [1046] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1046] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1046] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [1015] rom_wait::ptr_rom#1 = rom_sector_erase::ptr_rom#0
    // [1016] call rom_wait
    // [1382] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [1382] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [1017] return 
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __zp($23) unsigned int uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uint: {
    .label uvalue = $23
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1019] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1020] utoa::value#2 = printf_uint::uvalue#4
    // [1021] call utoa
  // Format number into buffer
    // [1173] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    // [1173] phi utoa::value#10 = utoa::value#2 [phi:printf_uint::@1->utoa#0] -- register_copy 
    // [1173] phi utoa::radix#2 = HEXADECIMAL [phi:printf_uint::@1->utoa#1] -- vbuaa=vbuc1 
    lda #HEXADECIMAL
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1022] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1023] call printf_number_buffer
  // Print using format
    // [1204] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1204] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1204] phi printf_number_buffer::putc#10 = &cputc [phi:printf_uint::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1204] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1204] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_zero_padding
    // [1204] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [1204] phi printf_number_buffer::format_min_length#4 = 4 [phi:printf_uint::@2->printf_number_buffer#5] -- vbuxx=vbuc1 
    ldx #4
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1024] return 
    rts
}
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($25) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, __zp($71) char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $25
    .label format_zero_padding = $71
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1026] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1027] ultoa::value#1 = printf_ulong::uvalue#4
    // [1028] call ultoa
  // Format number into buffer
    // [1389] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1029] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1030] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#4
    // [1031] call printf_number_buffer
  // Print using format
    // [1204] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1204] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1204] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1204] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1204] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    // [1204] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_justify_left
    // [1204] phi printf_number_buffer::format_min_length#4 = 6 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbuxx=vbuc1 
    ldx #6
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1032] return 
    rts
}
  // flash_write
/* inline */
// unsigned long flash_write(__register(X) char flash_ram_bank, __zp($2a) char *flash_ram_address, __zp($60) unsigned long flash_rom_address)
flash_write: {
    .label rom_chip_address = $6a
    .label flash_rom_address = $60
    .label flash_ram_address = $2a
    .label flashed_bytes = $25
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [1033] flash_write::rom_chip_address#0 = flash_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1034] BRAM = flash_write::flash_ram_bank#0 -- vbuz1=vbuxx 
    stx.z BRAM
    // [1035] phi from flash_write::bank_set_bram1 to flash_write::@1 [phi:flash_write::bank_set_bram1->flash_write::@1]
    // [1035] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#0] -- register_copy 
    // [1035] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#1] -- register_copy 
    // [1035] phi flash_write::flashed_bytes#2 = 0 [phi:flash_write::bank_set_bram1->flash_write::@1#2] -- vduz1=vduc1 
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
    // [1036] if(flash_write::flashed_bytes#2<$100) goto flash_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [1037] return 
    rts
    // flash_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [1038] rom_unlock::address#2 = flash_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1039] call rom_unlock
    // [1046] phi from flash_write::@2 to rom_unlock [phi:flash_write::@2->rom_unlock]
    // [1046] phi rom_unlock::unlock_code#5 = $a0 [phi:flash_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1046] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:flash_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // flash_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [1040] rom_byte_program::address#0 = flash_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [1041] rom_byte_program::value#0 = *flash_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [1042] call rom_byte_program
    jsr rom_byte_program
    // flash_write::@4
    // flash_rom_address++;
    // [1043] flash_write::flash_rom_address#0 = ++ flash_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [1044] flash_write::flash_ram_address#0 = ++ flash_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [1045] flash_write::flashed_bytes#1 = ++ flash_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [1035] phi from flash_write::@4 to flash_write::@1 [phi:flash_write::@4->flash_write::@1]
    // [1035] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#0 [phi:flash_write::@4->flash_write::@1#0] -- register_copy 
    // [1035] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#0 [phi:flash_write::@4->flash_write::@1#1] -- register_copy 
    // [1035] phi flash_write::flashed_bytes#2 = flash_write::flashed_bytes#1 [phi:flash_write::@4->flash_write::@1#2] -- register_copy 
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
// void rom_unlock(__zp($59) unsigned long address, __zp($53) char unlock_code)
rom_unlock: {
    .label chip_address = $2e
    .label address = $59
    .label unlock_code = $53
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1047] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1048] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1049] call rom_write_byte
    // [1419] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1419] phi rom_write_byte::value#4 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuyy=vbuc1 
    ldy #$aa
    // [1419] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1050] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [1051] call rom_write_byte
    // [1419] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1419] phi rom_write_byte::value#4 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuyy=vbuc1 
    ldy #$55
    // [1419] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1052] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1053] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuyy=vbuz1 
    ldy.z unlock_code
    // [1054] call rom_write_byte
    // [1419] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1419] phi rom_write_byte::value#4 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1419] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1055] return 
    rts
}
  // print_chip_line
// void print_chip_line(__register(X) char x, __register(Y) char y, __zp($66) char c)
print_chip_line: {
    .label c = $66
    // gotoxy(x, y)
    // [1057] gotoxy::x#4 = print_chip_line::x#9
    // [1058] gotoxy::y#4 = print_chip_line::y#9
    // [1059] call gotoxy
    // [532] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1060] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [1061] call textcolor
    // [514] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [514] phi textcolor::color#23 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1062] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [1063] call bgcolor
    // [519] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [1064] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1065] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1067] call textcolor
    // [514] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [514] phi textcolor::color#23 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1068] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [1069] call bgcolor
    // [519] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [519] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [1070] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1071] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [1073] stackpush(char) = print_chip_line::c#10 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1074] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [1076] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1077] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1079] call textcolor
    // [514] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [514] phi textcolor::color#23 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1080] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [1081] call bgcolor
    // [519] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [1082] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1083] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [1085] return 
    rts
}
  // print_chip_end
// void print_chip_end(__register(A) char x, char y)
print_chip_end: {
    .const y = $36
    // gotoxy(x, y)
    // [1086] gotoxy::x#5 = print_chip_end::x#0 -- vbuxx=vbuaa 
    tax
    // [1087] call gotoxy
    // [532] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [532] phi gotoxy::y#26 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbuyy=vbuc1 
    ldy #y
    // [532] phi gotoxy::x#26 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1088] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [1089] call textcolor
    // [514] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [514] phi textcolor::color#23 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1090] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [1091] call bgcolor
    // [519] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [1092] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1093] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1095] call textcolor
    // [514] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [514] phi textcolor::color#23 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr textcolor
    // [1096] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [1097] call bgcolor
    // [519] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [519] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [1098] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1099] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1101] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1102] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1104] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1105] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1107] call textcolor
    // [514] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [514] phi textcolor::color#23 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1108] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [1109] call bgcolor
    // [519] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [519] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [1110] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1111] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1113] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __register(X) char mapbase, __zp($bd) char config)
screenlayer: {
    .label __2 = $c8
    .label mapbase_offset = $bb
    .label config = $bd
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1114] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1115] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1116] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // mapbase >> 7
    // [1117] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuaa=vbuxx_ror_7 
    txa
    rol
    rol
    and #1
    // __conio.mapbase_bank = mapbase >> 7
    // [1118] *((char *)&__conio+3) = screenlayer::$0 -- _deref_pbuc1=vbuaa 
    sta __conio+3
    // (mapbase)<<1
    // [1119] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // MAKEWORD((mapbase)<<1,0)
    // [1120] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuaa_word_vbuc1 
    ldy #0
    sta.z __2+1
    sty.z __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1121] *((unsigned int *)&__conio+1) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    tya
    sta __conio+1
    lda.z __2+1
    sta __conio+1+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1122] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuaa=vbuz1_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1123] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuxx=vbuaa_ror_4 
    lsr
    lsr
    lsr
    lsr
    tax
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1124] *((char *)&__conio+6) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuxx 
    lda VERA_LAYER_DIM,x
    sta __conio+6
    // config & VERA_LAYER_HEIGHT_MASK
    // [1125] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuaa=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z config
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1126] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuaa=vbuaa_ror_6 
    rol
    rol
    rol
    and #3
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1127] *((char *)&__conio+7) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuaa 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+7
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1128] screenlayer::$16 = screenlayer::$8 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [1129] *((unsigned int *)&__conio+8) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    tay
    lda VERA_LAYER_SKIP,y
    sta __conio+8
    lda VERA_LAYER_SKIP+1,y
    sta __conio+8+1
    // vera_dc_hscale_temp == 0x80
    // [1130] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1131] screenlayer::$18 = (char)screenlayer::$9 -- vbuxx=vbuaa 
    tax
    // [1132] screenlayer::$10 = $28 << screenlayer::$18 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$28
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1133] screenlayer::$11 = screenlayer::$10 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1134] *((char *)&__conio+4) = screenlayer::$11 -- _deref_pbuc1=vbuaa 
    sta __conio+4
    // vera_dc_vscale_temp == 0x80
    // [1135] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1136] screenlayer::$19 = (char)screenlayer::$12 -- vbuxx=vbuaa 
    tax
    // [1137] screenlayer::$13 = $1e << screenlayer::$19 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$1e
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1138] screenlayer::$14 = screenlayer::$13 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1139] *((char *)&__conio+5) = screenlayer::$14 -- _deref_pbuc1=vbuaa 
    sta __conio+5
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1140] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z mapbase_offset
    lda __conio+1+1
    sta.z mapbase_offset+1
    // [1141] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1141] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1141] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1142] if(screenlayer::y#2<=*((char *)&__conio+5)) goto screenlayer::@2 -- vbuxx_le__deref_pbuc1_then_la1 
    lda __conio+5
    stx.z $ff
    cmp.z $ff
    bcs __b2
    // screenlayer::@return
    // }
    // [1143] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1144] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [1145] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuaa=vwuz1 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1146] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+8
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+8+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1147] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuxx=_inc_vbuxx 
    inx
    // [1141] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1141] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1141] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1148] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1149] if(0!=((char *)&__conio+$f)[*((char *)&__conio)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1150] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // [1151] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1152] call gotoxy
    // [532] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [532] phi gotoxy::y#26 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuyy=vbuc1 
    ldy #0
    // [532] phi gotoxy::x#26 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1153] return 
    rts
    // [1154] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1155] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1156] gotoxy::y#2 = *((char *)&__conio+5) -- vbuyy=_deref_pbuc1 
    ldy __conio+5
    // [1157] call gotoxy
    // [532] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // [1158] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1159] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__register(X) char x, __register(Y) char y, __zp($56) char c)
cputcxy: {
    .label c = $56
    // gotoxy(x, y)
    // [1161] gotoxy::x#0 = cputcxy::x#68
    // [1162] gotoxy::y#0 = cputcxy::y#68
    // [1163] call gotoxy
    // [532] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [532] phi gotoxy::y#26 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [532] phi gotoxy::x#26 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1164] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1165] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1167] return 
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
    // [1168] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [1170] getin::return#0 = getin::ch -- vbuaa=vbum1 
    // getin::@return
    // }
    // [1171] getin::return#1 = getin::return#0
    // [1172] return 
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
// void utoa(__zp($23) unsigned int value, __zp($46) char *buffer, __register(A) char radix)
utoa: {
    .label digit_value = $2a
    .label buffer = $46
    .label digit = $57
    .label value = $23
    .label started = $58
    .label max_digits = $52
    .label digit_values = $3d
    // if(radix==DECIMAL)
    // [1174] if(utoa::radix#2==DECIMAL) goto utoa::@1 -- vbuaa_eq_vbuc1_then_la1 
    cmp #DECIMAL
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1175] if(utoa::radix#2==HEXADECIMAL) goto utoa::@1 -- vbuaa_eq_vbuc1_then_la1 
    cmp #HEXADECIMAL
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1176] if(utoa::radix#2==OCTAL) goto utoa::@1 -- vbuaa_eq_vbuc1_then_la1 
    cmp #OCTAL
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1177] if(utoa::radix#2==BINARY) goto utoa::@1 -- vbuaa_eq_vbuc1_then_la1 
    cmp #BINARY
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1178] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1179] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1180] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1181] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1182] return 
    rts
    // [1183] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1183] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1183] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1183] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1183] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1183] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1183] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1183] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1183] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1183] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1183] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1183] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1184] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1184] phi utoa::buffer#10 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1184] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1184] phi utoa::value#3 = utoa::value#10 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1184] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1185] utoa::$4 = utoa::max_digits#7 - 1 -- vbuxx=vbuz1_minus_1 
    ldx.z max_digits
    dex
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1186] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuxx_then_la1 
    cpx.z digit
    beq !+
    bcs __b7
  !:
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1187] utoa::$11 = (char)utoa::value#3 -- vbuxx=_byte_vwuz1 
    ldx.z value
    // [1188] *utoa::buffer#10 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1189] utoa::buffer#3 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1190] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1191] utoa::$10 = utoa::digit#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z digit
    asl
    // [1192] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuaa 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1193] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1194] if(utoa::value#3>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1195] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1195] phi utoa::buffer#15 = utoa::buffer#10 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1195] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1195] phi utoa::value#7 = utoa::value#3 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1196] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1184] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1184] phi utoa::buffer#10 = utoa::buffer#15 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1184] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1184] phi utoa::value#3 = utoa::value#7 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1184] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1197] utoa_append::buffer#0 = utoa::buffer#10 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1198] utoa_append::value#0 = utoa::value#3
    // [1199] utoa_append::sub#0 = utoa::digit_value#0
    // [1200] call utoa_append
    // [1464] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1201] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1202] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1203] utoa::buffer#4 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1195] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1195] phi utoa::buffer#15 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1195] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1195] phi utoa::value#7 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($5d) void (*putc)(char), __zp($72) char buffer_sign, char *buffer_digits, __register(X) char format_min_length, __zp($79) char format_justify_left, char format_sign_always, __zp($71) char format_zero_padding, __zp($7e) char format_upper_case, char format_radix)
printf_number_buffer: {
    .label __19 = $2a
    .label buffer_sign = $72
    .label format_zero_padding = $71
    .label putc = $5d
    .label padding = $70
    .label format_justify_left = $79
    .label format_upper_case = $7e
    // if(format.min_length)
    // [1205] if(0==printf_number_buffer::format_min_length#4) goto printf_number_buffer::@1 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq __b6
    // [1206] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [1207] call strlen
    // [1311] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [1311] phi strlen::str#6 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1208] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@14
    // [1209] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1210] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsyy=_sbyte_vwuz1 
    // There is a minimum length - work out the padding
    ldy.z __19
    // if(buffer.sign)
    // [1211] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [1212] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsyy=_inc_vbsyy 
    iny
    // [1213] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [1213] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [1214] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#4 - printf_number_buffer::len#2 -- vbsz1=vbsxx_minus_vbsyy 
    txa
    sty.z $ff
    sec
    sbc.z $ff
    sta.z padding
    // if(padding<0)
    // [1215] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1217] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [1217] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1216] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [1217] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [1217] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1218] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [1219] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [1220] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [1221] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1222] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1223] call printf_padding
    // [1317] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1317] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1317] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@8->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1317] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1224] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [1225] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1226] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall27
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1228] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [1229] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1230] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1231] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1232] call printf_padding
    // [1317] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1317] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1317] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@10->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1317] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1233] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbuz1_then_la1 
    lda.z format_upper_case
    beq __b5
    // [1234] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1235] call strupr
    // [1471] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1236] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1237] call printf_str
    // [760] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [760] phi printf_str::putc#37 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [760] phi printf_str::s#37 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1238] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1239] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1240] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1241] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1242] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1243] call printf_padding
    // [1317] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1317] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1317] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@12->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1317] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1244] return 
    rts
    // Outside Flow
  icall27:
    jmp (putc)
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__register(X) char value, __zp($3d) char *buffer, __register(Y) char radix)
uctoa: {
    .label buffer = $3d
    .label digit = $56
    .label started = $53
    .label max_digits = $66
    .label digit_values = $2a
    // if(radix==DECIMAL)
    // [1245] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #DECIMAL
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1246] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #HEXADECIMAL
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1247] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #OCTAL
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1248] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #BINARY
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1249] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1250] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1251] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1252] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1253] return 
    rts
    // [1254] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1254] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1254] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1254] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1254] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1254] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1254] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1254] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1254] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1254] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1254] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1254] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1255] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1255] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1255] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1255] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1255] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1256] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuaa=vbuz1_minus_1 
    lda.z max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1257] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuaa_then_la1 
    cmp.z digit
    beq !+
    bcs __b7
  !:
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1258] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1259] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1260] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1261] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuyy=pbuz1_derefidx_vbuz2 
    ldy.z digit
    lda (digit_values),y
    tay
    // if (started || value >= digit_value)
    // [1262] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1263] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuxx_ge_vbuyy_then_la1 
    sty.z $ff
    cpx.z $ff
    bcs __b10
    // [1264] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1264] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1264] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1264] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1265] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1255] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1255] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1255] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1255] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1255] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1266] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1267] uctoa_append::value#0 = uctoa::value#2
    // [1268] uctoa_append::sub#0 = uctoa::digit_value#0 -- vbuz1=vbuyy 
    sty.z uctoa_append.sub
    // [1269] call uctoa_append
    // [1481] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1270] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1271] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1272] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1264] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1264] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1264] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1264] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($2a) char *dst, __zp($46) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label dst = $2a
    .label i = $3d
    .label src = $46
    // [1274] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1274] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1274] phi strncpy::src#2 = main::buffer [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.buffer
    sta.z src
    lda #>main.buffer
    sta.z src+1
    // [1274] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1275] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuc1_then_la1 
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
    // [1276] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1277] strncpy::c#0 = *strncpy::src#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // if(c)
    // [1278] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // strncpy::@4
    // src++;
    // [1279] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1280] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1280] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1281] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1282] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1283] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1274] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1274] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1274] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1274] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_setnam
/**
 * @brief Sets the name of the file before opening.
 * 
 * @param filename The name of the file.
 */
// void cbm_k_setnam(__zp($ce) char * volatile filename)
cbm_k_setnam: {
    .label filename = $ce
    .label __0 = $2a
    // strlen(filename)
    // [1284] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbuz2 
    lda.z filename
    sta.z strlen.str
    lda.z filename+1
    sta.z strlen.str+1
    // [1285] call strlen
    // [1311] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [1311] phi strlen::str#6 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1286] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [1287] cbm_k_setnam::$0 = strlen::return#0
    // __mem char filename_len = (char)strlen(filename)
    // [1288] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwuz2 
    lda.z __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [1290] return 
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
// void cbm_k_setlfs(__zp($d5) volatile char channel, __zp($d2) volatile char device, __zp($d0) volatile char command)
cbm_k_setlfs: {
    .label channel = $d5
    .label device = $d2
    .label command = $d0
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1292] return 
    rts
}
  // cbm_k_open
/**
 * @brief Open a logical file.
 * 
 * @return char The status.
 */
cbm_k_open: {
    // __mem unsigned char status
    // [1293] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [1295] cbm_k_open::return#0 = cbm_k_open::status -- vbuaa=vbum1 
    // cbm_k_open::@return
    // }
    // [1296] cbm_k_open::return#1 = cbm_k_open::return#0
    // [1297] return 
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
// __register(A) char cbm_k_close(__zp($d1) volatile char channel)
cbm_k_close: {
    .label channel = $d1
    // __mem unsigned char status
    // [1298] cbm_k_close::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldachannel jsrCBM_CLOSE stastatus  }
    lda channel
    jsr CBM_CLOSE
    sta status
    // return status;
    // [1300] cbm_k_close::return#0 = cbm_k_close::status -- vbuaa=vbum1 
    // cbm_k_close::@return
    // }
    // [1301] cbm_k_close::return#1 = cbm_k_close::return#0
    // [1302] return 
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
// char cbm_k_chkin(__zp($73) volatile char channel)
cbm_k_chkin: {
    .label channel = $73
    // __mem unsigned char status
    // [1303] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [1305] return 
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
    // [1306] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [1308] cbm_k_readst::return#0 = cbm_k_readst::status -- vbuaa=vbum1 
    // cbm_k_readst::@return
    // }
    // [1309] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [1310] return 
    rts
  .segment Data
    status: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($2a) unsigned int strlen(__zp($46) char *str)
strlen: {
    .label str = $46
    .label return = $2a
    .label len = $2a
    // [1312] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1312] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1312] phi strlen::str#4 = strlen::str#6 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1313] if(0!=*strlen::str#4) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1314] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1315] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1316] strlen::str#1 = ++ strlen::str#4 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1312] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1312] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1312] phi strlen::str#4 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($54) void (*putc)(char), __zp($52) char pad, __zp($53) char length)
printf_padding: {
    .label i = $4a
    .label putc = $54
    .label length = $53
    .label pad = $52
    // [1318] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1318] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1319] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1320] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1321] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1322] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall28
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1324] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1318] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1318] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall28:
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
// __zp($4f) unsigned int fgets(__zp($54) char *ptr, unsigned int size, __zp($2a) struct $1 *fp)
fgets: {
    .const size = $80
    .label return = $4f
    .label bytes = $48
    .label read = $4f
    .label ptr = $54
    .label remaining = $2c
    .label fp = $2a
    // cbm_k_chkin(fp->channel)
    // [1325] cbm_k_chkin::channel = ((char *)fgets::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_chkin.channel
    // [1326] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1327] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [1328] call cbm_k_readst
    jsr cbm_k_readst
    // [1329] cbm_k_readst::return#3 = cbm_k_readst::return#1
    // fgets::@12
    // [1330] fgets::$1 = cbm_k_readst::return#3
    // fp->status = cbm_k_readst()
    // [1331] ((char *)fgets::fp#0)[$13] = fgets::$1 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [1332] if(0==((char *)fgets::fp#0)[$13]) goto fgets::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b8
    // [1333] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [1333] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1334] return 
    rts
    // [1335] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [1335] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1335] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@12->fgets::@1#1] -- vwuz1=vwuc1 
    lda #<size
    sta.z remaining
    lda #>size
    sta.z remaining+1
    // [1335] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [1335] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [1335] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [1335] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [1335] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [1336] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwuz1_ge_vbuc1_then_la1 
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
    // [1337] cbm_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cbm_k_macptr.bytes
    // [1338] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1339] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1340] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [1341] fgets::bytes#3 = cbm_k_macptr::return#4
    // [1342] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [1342] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [1343] call cbm_k_readst
    jsr cbm_k_readst
    // [1344] cbm_k_readst::return#4 = cbm_k_readst::return#1
    // fgets::@15
    // [1345] fgets::$9 = cbm_k_readst::return#4
    // fp->status = cbm_k_readst()
    // [1346] ((char *)fgets::fp#0)[$13] = fgets::$9 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // fp->status & 0xBF
    // [1347] fgets::$10 = ((char *)fgets::fp#0)[$13] & $bf -- vbuaa=pbuz1_derefidx_vbuc1_band_vbuc2 
    lda #$bf
    and (fp),y
    // if(fp->status & 0xBF)
    // [1348] if(0==fgets::$10) goto fgets::@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [1349] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1350] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1351] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1352] fgets::$14 = byte1  fgets::ptr#0 -- vbuaa=_byte1_pbuz1 
    // if(BYTE1(ptr) == 0xC0)
    // [1353] if(fgets::$14!=$c0) goto fgets::@6 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$c0
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [1354] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1355] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [1355] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [1356] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((fp->status == 0) && ((size && remaining) || !size))
    // [1357] if(((char *)fgets::fp#0)[$13]==0) goto fgets::@16 -- pbuz1_derefidx_vbuc1_eq_0_then_la1 
    ldy #$13
    lda (fp),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [1358] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [1359] cbm_k_chkin::channel = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin.channel
    // [1360] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1333] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [1333] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [1361] cbm_k_macptr::bytes = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cbm_k_macptr.bytes
    // [1362] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1363] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1364] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [1365] fgets::bytes#2 = cbm_k_macptr::return#3
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
    // [1367] return 
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
// __register(A) char rom_bank(__zp($34) unsigned long address)
rom_bank: {
    .label __1 = $41
    .label __2 = $34
    .label address = $34
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [1369] rom_bank::$2 = rom_bank::address#2 & $3fc000 -- vduz1=vduz1_band_vduc1 
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
    // [1370] rom_bank::$1 = rom_bank::$2 >> $e -- vduz1=vduz2_ror_vbuc1 
    ldx #$e
    lda.z __2
    sta.z __1
    lda.z __2+1
    sta.z __1+1
    lda.z __2+2
    sta.z __1+2
    lda.z __2+3
    sta.z __1+3
    cpx #0
    beq !e+
  !:
    lsr.z __1+3
    ror.z __1+2
    ror.z __1+1
    ror.z __1
    dex
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [1371] rom_bank::return#0 = (char)rom_bank::$1 -- vbuaa=_byte_vduz1 
    lda.z __1
    // rom_bank::@return
    // }
    // [1372] return 
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
// __zp($3d) char * rom_ptr(__zp($39) unsigned long address)
rom_ptr: {
    .label __0 = $39
    .label __2 = $3d
    .label return = $3d
    .label address = $39
    // address & ROM_PTR_MASK
    // [1374] rom_ptr::$0 = rom_ptr::address#4 & $3fff -- vduz1=vduz1_band_vduc1 
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
    // [1375] rom_ptr::$2 = (unsigned int)rom_ptr::$0 -- vwuz1=_word_vduz2 
    lda.z __0
    sta.z __2
    lda.z __0+1
    sta.z __2+1
    // [1376] rom_ptr::return#0 = rom_ptr::$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z return
    clc
    adc #<$c000
    sta.z return
    lda.z return+1
    adc #>$c000
    sta.z return+1
    // rom_ptr::@return
    // }
    // [1377] return 
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
// __register(A) char rom_byte_verify(__zp($3d) char *ptr_rom, __register(A) char value)
rom_byte_verify: {
    .label ptr_rom = $3d
    // if (*ptr_rom != value)
    // [1378] if(*rom_byte_verify::ptr_rom#0==rom_byte_verify::value#0) goto rom_byte_verify::@1 -- _deref_pbuz1_eq_vbuaa_then_la1 
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1379] phi from rom_byte_verify to rom_byte_verify::@2 [phi:rom_byte_verify->rom_byte_verify::@2]
    // rom_byte_verify::@2
    // [1380] phi from rom_byte_verify::@2 to rom_byte_verify::@1 [phi:rom_byte_verify::@2->rom_byte_verify::@1]
    // [1380] phi rom_byte_verify::return#0 = 0 [phi:rom_byte_verify::@2->rom_byte_verify::@1#0] -- vbuaa=vbuc1 
    tya
    rts
    // [1380] phi from rom_byte_verify to rom_byte_verify::@1 [phi:rom_byte_verify->rom_byte_verify::@1]
  __b2:
    // [1380] phi rom_byte_verify::return#0 = 1 [phi:rom_byte_verify->rom_byte_verify::@1#0] -- vbuaa=vbuc1 
    lda #1
    // rom_byte_verify::@1
    // rom_byte_verify::@return
    // }
    // [1381] return 
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
// void rom_wait(__zp($2c) char *ptr_rom)
rom_wait: {
    .label __0 = $29
    .label ptr_rom = $2c
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [1383] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuxx=_deref_pbuz1 
    ldy #0
    lda (ptr_rom),y
    tax
    // test2 = *((brom_ptr_t)ptr_rom)
    // [1384] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuyy=_deref_pbuz1 
    lda (ptr_rom),y
    tay
    // test1 & 0x40
    // [1385] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuxx_band_vbuc1 
    txa
    and #$40
    sta.z __0
    // test2 & 0x40
    // [1386] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuaa=vbuyy_band_vbuc1 
    tya
    and #$40
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [1387] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuaa_then_la1 
    cmp.z __0
    bne __b1
    // rom_wait::@return
    // }
    // [1388] return 
    rts
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($25) unsigned long value, __zp($4f) char *buffer, char radix)
ultoa: {
    .label digit_value = $2e
    .label buffer = $4f
    .label digit = $52
    .label value = $25
    // [1390] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1390] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1390] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // [1390] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1390] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    txa
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1391] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1392] ultoa::$11 = (char)ultoa::value#2 -- vbuaa=_byte_vduz1 
    lda.z value
    // [1393] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuaa 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1394] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1395] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1396] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1397] ultoa::$10 = ultoa::digit#2 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z digit
    asl
    asl
    // [1398] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuaa 
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
    // [1399] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b5
    // ultoa::@7
    // [1400] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1401] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1401] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1401] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1401] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1402] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1390] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1390] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1390] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1390] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1390] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1403] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1404] ultoa_append::value#0 = ultoa::value#2
    // [1405] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1406] call ultoa_append
    // [1493] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1407] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1408] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1409] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1401] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1401] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1401] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuxx=vbuc1 
    ldx #1
    // [1401] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
}
  // rom_byte_program
/**
 * @brief Write a byte and wait until the byte has been successfully flashed into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
/* inline */
// void rom_byte_program(__zp($4b) unsigned long address, __zp($5f) char value)
rom_byte_program: {
    .label ptr_rom = $48
    .label address = $4b
    .label value = $5f
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1410] rom_ptr::address#1 = rom_byte_program::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [1411] call rom_ptr
    // [1373] phi from rom_byte_program to rom_ptr [phi:rom_byte_program->rom_ptr]
    // [1373] phi rom_ptr::address#4 = rom_ptr::address#1 [phi:rom_byte_program->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_byte_program::@1
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1412] rom_byte_program::ptr_rom#0 = (char *)rom_ptr::return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // rom_write_byte(address, value)
    // [1413] rom_write_byte::address#3 = rom_byte_program::address#0
    // [1414] rom_write_byte::value#3 = rom_byte_program::value#0 -- vbuyy=vbuz1 
    ldy.z value
    // [1415] call rom_write_byte
    // [1419] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [1419] phi rom_write_byte::value#4 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [1419] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [1416] rom_wait::ptr_rom#0 = rom_byte_program::ptr_rom#0 -- pbuz1=pbuz2 
    lda.z ptr_rom
    sta.z rom_wait.ptr_rom
    lda.z ptr_rom+1
    sta.z rom_wait.ptr_rom+1
    // [1417] call rom_wait
    // [1382] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [1382] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [1418] return 
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
// void rom_write_byte(__zp($4b) unsigned long address, __register(Y) char value)
rom_write_byte: {
    .label ptr_rom = $4f
    .label address = $4b
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1420] rom_bank::address#0 = rom_write_byte::address#4 -- vduz1=vduz2 
    lda.z address
    sta.z rom_bank.address
    lda.z address+1
    sta.z rom_bank.address+1
    lda.z address+2
    sta.z rom_bank.address+2
    lda.z address+3
    sta.z rom_bank.address+3
    // [1421] call rom_bank
    // [1368] phi from rom_write_byte to rom_bank [phi:rom_write_byte->rom_bank]
    // [1368] phi rom_bank::address#2 = rom_bank::address#0 [phi:rom_write_byte->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1422] rom_bank::return#2 = rom_bank::return#0
    // rom_write_byte::@1
    // [1423] rom_write_byte::bank_rom#0 = rom_bank::return#2 -- vbuxx=vbuaa 
    tax
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1424] rom_ptr::address#0 = rom_write_byte::address#4 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [1425] call rom_ptr
    // [1373] phi from rom_write_byte::@1 to rom_ptr [phi:rom_write_byte::@1->rom_ptr]
    // [1373] phi rom_ptr::address#4 = rom_ptr::address#0 [phi:rom_write_byte::@1->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_write_byte::@2
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1426] rom_write_byte::ptr_rom#0 = (char *)rom_ptr::return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // bank_set_brom(bank_rom)
    // [1427] bank_set_brom::bank#2 = rom_write_byte::bank_rom#0 -- vbuaa=vbuxx 
    txa
    // [1428] call bank_set_brom
    // [790] phi from rom_write_byte::@2 to bank_set_brom [phi:rom_write_byte::@2->bank_set_brom]
    // [790] phi bank_set_brom::bank#12 = bank_set_brom::bank#2 [phi:rom_write_byte::@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_write_byte::@3
    // *ptr_rom = value
    // [1429] *rom_write_byte::ptr_rom#0 = rom_write_byte::value#4 -- _deref_pbuz1=vbuyy 
    tya
    ldy #0
    sta (ptr_rom),y
    // rom_write_byte::@return
    // }
    // [1430] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label __7 = $22
    .label width = $51
    .label y = $38
    // __conio.width+1
    // [1431] insertup::$0 = *((char *)&__conio+4) + 1 -- vbuaa=_deref_pbuc1_plus_1 
    lda __conio+4
    inc
    // unsigned char width = (__conio.width+1) * 2
    // [1432] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuaa_rol_1 
    asl
    sta.z width
    // [1433] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1433] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1434] if(insertup::y#2<=*((char *)&__conio+$e)) goto insertup::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+$e
    cmp.z y
    bcs __b2
    // [1435] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1436] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1437] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1438] insertup::$4 = insertup::y#2 + 1 -- vbuxx=vbuz1_plus_1 
    ldx.z y
    inx
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1439] insertup::$6 = insertup::y#2 << 1 -- vbuyy=vbuz1_rol_1 
    lda.z y
    asl
    tay
    // [1440] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuxx_rol_1 
    txa
    asl
    sta.z __7
    // [1441] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.dbank_vram
    // [1442] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuyy 
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1443] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+3) -- vbuxx=_deref_pbuc1 
    ldx __conio+3
    // [1444] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1445] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8
    // [1446] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1447] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1433] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1433] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label addr = $3f
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1448] clearline::$3 = *((char *)&__conio+$e) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    // [1449] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1450] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1451] clearline::$0 = byte0  clearline::addr#0 -- vbuaa=_byte0_vwuz1 
    lda.z addr
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1452] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1453] clearline::$1 = byte1  clearline::addr#0 -- vbuaa=_byte1_vwuz1 
    lda.z addr+1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1454] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1455] clearline::$2 = *((char *)&__conio+3) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1456] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1457] clearline::c#0 = *((char *)&__conio+4) -- vbuxx=_deref_pbuc1 
    ldx __conio+4
    // [1458] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1458] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1459] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1460] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [1461] clearline::c#1 = -- clearline::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [1462] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clearline::@return
    // }
    // [1463] return 
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
// __zp($23) unsigned int utoa_append(__zp($54) char *buffer, __zp($23) unsigned int value, __zp($2a) unsigned int sub)
utoa_append: {
    .label buffer = $54
    .label value = $23
    .label sub = $2a
    .label return = $23
    // [1465] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1465] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [1465] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1466] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1467] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1468] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1469] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [1470] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1465] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1465] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1465] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label src = $48
    // [1472] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1472] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1473] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1474] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1475] toupper::ch#0 = *strupr::src#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // [1476] call toupper
    jsr toupper
    // [1477] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1478] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1479] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (src),y
    // src++;
    // [1480] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1472] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1472] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
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
// __register(X) char uctoa_append(__zp($54) char *buffer, __register(X) char value, __zp($29) char sub)
uctoa_append: {
    .label buffer = $54
    .label sub = $29
    // [1482] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1482] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuyy=vbuc1 
    ldy #0
    // [1482] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1483] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuxx_ge_vbuz1_then_la1 
    cpx.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1484] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuyy 
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1485] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1486] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuyy=_inc_vbuyy 
    iny
    // value -= sub
    // [1487] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuxx=vbuxx_minus_vbuz1 
    txa
    sec
    sbc.z sub
    tax
    // [1482] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1482] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1482] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($48) unsigned int cbm_k_macptr(__zp($67) volatile char bytes, __zp($64) void * volatile buffer)
cbm_k_macptr: {
    .label bytes = $67
    .label buffer = $64
    .label return = $48
    // __mem unsigned int bytes_read
    // [1488] cbm_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [1490] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwuz1=vwum2 
    lda bytes_read
    sta.z return
    lda bytes_read+1
    sta.z return+1
    // cbm_k_macptr::@return
    // }
    // [1491] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [1492] return 
    rts
  .segment Data
    bytes_read: .word 0
}
.segment Code
  // ultoa_append
// Used to convert a single digit of an unsigned number value to a string representation
// Counts a single digit up from '0' as long as the value is larger than sub.
// Each time the digit is increased sub is subtracted from value.
// - buffer : pointer to the char that receives the digit
// - value : The value where the digit will be derived from
// - sub : the value of a '1' in the digit. Subtracted continually while the digit is increased.
//        (For decimal the subs used are 10000, 1000, 100, 10, 1)
// returns : the value reduced by sub * digit so that it is less than sub.
// __zp($25) unsigned long ultoa_append(__zp($48) char *buffer, __zp($25) unsigned long value, __zp($2e) unsigned long sub)
ultoa_append: {
    .label buffer = $48
    .label value = $25
    .label sub = $2e
    .label return = $25
    // [1494] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1494] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [1494] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1495] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [1496] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1497] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1498] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [1499] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [1494] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1494] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1494] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
// void memcpy8_vram_vram(__zp($45) char dbank_vram, __zp($3f) unsigned int doffset_vram, __register(X) char sbank_vram, __zp($32) unsigned int soffset_vram, __register(X) char num8)
memcpy8_vram_vram: {
    .label dbank_vram = $45
    .label doffset_vram = $3f
    .label soffset_vram = $32
    .label num8 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1500] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1501] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z soffset_vram
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1502] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1503] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z soffset_vram+1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1504] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1505] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuaa=vbuxx_bor_vbuc1 
    txa
    ora #VERA_INC_1
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1506] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1507] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1508] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z doffset_vram
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1509] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1510] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z doffset_vram+1
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1511] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1512] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuaa=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z dbank_vram
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1513] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // [1514] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1514] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1515] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuxx=_dec_vbuz1 
    ldx.z num8
    dex
    // [1516] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1517] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1518] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1519] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuxx 
    stx.z num8
    jmp __b1
}
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __register(A) char toupper(__register(A) char ch)
toupper: {
    // if(ch>='a' && ch<='z')
    // [1520] if(toupper::ch#0<'a'pm) goto toupper::@return -- vbuaa_lt_vbuc1_then_la1 
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1521] if(toupper::ch#0<='z'pm) goto toupper::@1 -- vbuaa_le_vbuc1_then_la1 
    cmp #'z'
    bcc __b1
    beq __b1
    // [1523] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1523] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1522] toupper::return#0 = toupper::ch#0 + 'A'pm-'a'pm -- vbuaa=vbuaa_plus_vbuc1 
    clc
    adc #'A'-'a'
    // toupper::@return
  __breturn:
    // }
    // [1524] return 
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