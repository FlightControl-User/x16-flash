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
  .label __snprintf_buffer = $58
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
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [305] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [305] phi textcolor::color#16 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [310] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuxx=vbuc1 
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
    // [29] conio_x16_init::$4 = cbm_k_plot_get::return#2 -- vwum1=vwuz2 
    lda.z cbm_k_plot_get.return
    sta __4
    lda.z cbm_k_plot_get.return+1
    sta __4+1
    // BYTE1(cbm_k_plot_get())
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuaa=_byte1_vwum1 
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio+$d) = conio_x16_init::$5 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // cbm_k_plot_get()
    // [32] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [33] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [34] conio_x16_init::$6 = cbm_k_plot_get::return#3 -- vwum1=vwuz2 
    lda.z cbm_k_plot_get.return
    sta __6
    lda.z cbm_k_plot_get.return+1
    sta __6+1
    // BYTE0(cbm_k_plot_get())
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuaa=_byte0_vwum1 
    lda __6
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+$e) = conio_x16_init::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+$e
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#1 = *((char *)&__conio+$d) -- vbuyy=_deref_pbuc1 
    ldy __conio+$d
    // [38] gotoxy::y#1 = *((char *)&__conio+$e) -- vbuz1=_deref_pbuc1 
    sta.z gotoxy.y
    // [39] call gotoxy
    // [323] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    __4: .word 0
    __6: .word 0
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
    .const bank_set_bram1_bank = 1
    .const bank_set_bram2_bank = 1
    .const bank_set_bram3_bank = 1
    .const bank_set_bram4_bank = 1
    .const bank_set_bram5_bank = 1
    .const bank_set_bram6_bank = 1
    .const bank_set_bram7_bank = 1
    .label fp = $5b
    .label rom_device = $5f
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@33
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
    // [75] phi from main::@33 to main::@44 [phi:main::@33->main::@44]
    // main::@44
    // textcolor(WHITE)
    // [76] call textcolor
    // [305] phi from main::@44 to textcolor [phi:main::@44->textcolor]
    // [305] phi textcolor::color#16 = WHITE [phi:main::@44->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [77] phi from main::@44 to main::@45 [phi:main::@44->main::@45]
    // main::@45
    // bgcolor(BLUE)
    // [78] call bgcolor
    // [310] phi from main::@45 to bgcolor [phi:main::@45->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:main::@45->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [79] phi from main::@45 to main::@46 [phi:main::@45->main::@46]
    // main::@46
    // scroll(0)
    // [80] call scroll
    jsr scroll
    // [81] phi from main::@46 to main::@47 [phi:main::@46->main::@47]
    // main::@47
    // clrscr()
    // [82] call clrscr
    jsr clrscr
    // [83] phi from main::@47 to main::@48 [phi:main::@47->main::@48]
    // main::@48
    // frame_draw()
    // [84] call frame_draw
    // [371] phi from main::@48 to frame_draw [phi:main::@48->frame_draw]
    jsr frame_draw
    // [85] phi from main::@48 to main::@49 [phi:main::@48->main::@49]
    // main::@49
    // gotoxy(33, 1)
    // [86] call gotoxy
    // [323] phi from main::@49 to gotoxy [phi:main::@49->gotoxy]
    // [323] phi gotoxy::y#22 = 1 [phi:main::@49->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = $21 [phi:main::@49->gotoxy#1] -- vbuyy=vbuc1 
    ldy #$21
    jsr gotoxy
    // [87] phi from main::@49 to main::@50 [phi:main::@49->main::@50]
    // main::@50
    // printf("rom flash utility")
    // [88] call printf_str
    // [551] phi from main::@50 to printf_str [phi:main::@50->printf_str]
    // [551] phi printf_str::putc#10 = &cputc [phi:main::@50->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [551] phi printf_str::s#10 = main::s [phi:main::@50->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [89] phi from main::@50 to main::@1 [phi:main::@50->main::@1]
    // [89] phi main::r#10 = 0 [phi:main::@50->main::@1#0] -- vbum1=vbuc1 
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
    // [91] phi main::rom_address#10 = 0 [phi:main::@1->main::@3#1] -- vdum1=vduc1 
    sta rom_address
    sta rom_address+1
    lda #<0>>$10
    sta rom_address+2
    lda #>0>>$10
    sta rom_address+3
    // main::@3
  __b3:
    // for (unsigned long rom_address = 0; rom_address < 8 * 0x80000; rom_address += 0x80000)
    // [92] if(main::rom_address#10<8*$80000) goto main::@4 -- vdum1_lt_vduc1_then_la1 
    lda rom_address+3
    cmp #>8*$80000>>$10
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda rom_address+2
    cmp #<8*$80000>>$10
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda rom_address+1
    cmp #>8*$80000
    bcs !__b4+
    jmp __b4
  !__b4:
    bne !+
    lda rom_address
    cmp #<8*$80000
    bcs !__b4+
    jmp __b4
  !__b4:
  !:
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [94] phi from main::CLI1 to main::@34 [phi:main::CLI1->main::@34]
    // main::@34
    // wait_key()
    // [95] call wait_key
  // printf("press any key to start flashing ...\n");
    // [560] phi from main::@34 to wait_key [phi:main::@34->wait_key]
    jsr wait_key
    // [96] phi from main::@34 to main::@15 [phi:main::@34->main::@15]
    // [96] phi main::flash_chip#10 = 7 [phi:main::@34->main::@15#0] -- vbum1=vbuc1 
    lda #7
    sta flash_chip
    // main::@15
  __b15:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [97] if(main::flash_chip#10!=$ff) goto main::@16 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp flash_chip
    bne __b16
    // [98] phi from main::@15 to main::@17 [phi:main::@15->main::@17]
    // main::@17
    // wait_key()
    // [99] call wait_key
    // [560] phi from main::@17 to wait_key [phi:main::@17->wait_key]
    jsr wait_key
    // [100] phi from main::@17 to main::@70 [phi:main::@17->main::@70]
    // main::@70
    // gotoxy(2, 39)
    // [101] call gotoxy
    // [323] phi from main::@70 to gotoxy [phi:main::@70->gotoxy]
    // [323] phi gotoxy::y#22 = $27 [phi:main::@70->gotoxy#0] -- vbuz1=vbuc1 
    lda #$27
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = 2 [phi:main::@70->gotoxy#1] -- vbuyy=vbuc1 
    ldy #2
    jsr gotoxy
    // [102] phi from main::@70 to main::@71 [phi:main::@70->main::@71]
    // main::@71
    // printf("resetting commander x16 ...")
    // [103] call printf_str
    // [551] phi from main::@71 to printf_str [phi:main::@71->printf_str]
    // [551] phi printf_str::putc#10 = &cputc [phi:main::@71->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [551] phi printf_str::s#10 = main::s1 [phi:main::@71->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [104] phi from main::@71 to main::@72 [phi:main::@71->main::@72]
    // main::@72
    // gotoxy(2, 40)
    // [105] call gotoxy
    // [323] phi from main::@72 to gotoxy [phi:main::@72->gotoxy]
    // [323] phi gotoxy::y#22 = $28 [phi:main::@72->gotoxy#0] -- vbuz1=vbuc1 
    lda #$28
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = 2 [phi:main::@72->gotoxy#1] -- vbuyy=vbuc1 
    ldy #2
    jsr gotoxy
    // [106] phi from main::@72 to main::@28 [phi:main::@72->main::@28]
    // [106] phi main::w#2 = 0 [phi:main::@72->main::@28#0] -- vwum1=vwuc1 
    lda #<0
    sta w
    sta w+1
    // main::@28
  __b28:
    // for (unsigned int w = 0; w < 32; w++)
    // [107] if(main::w#2<$20) goto main::@30 -- vwum1_lt_vbuc1_then_la1 
    lda w+1
    bne !+
    lda w
    cmp #$20
    bcc __b9
  !:
    // [108] phi from main::@28 to main::@29 [phi:main::@28->main::@29]
    // main::@29
    // system_reset()
    // [109] call system_reset
    // [570] phi from main::@29 to system_reset [phi:main::@29->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [110] return 
    rts
    // [111] phi from main::@28 to main::@30 [phi:main::@28->main::@30]
  __b9:
    // [111] phi main::v#2 = 0 [phi:main::@28->main::@30#0] -- vwum1=vwuc1 
    lda #<0
    sta v
    sta v+1
    // main::@30
  __b30:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [112] if(main::v#2<$100*$80) goto main::@31 -- vwum1_lt_vwuc1_then_la1 
    lda v+1
    cmp #>$100*$80
    bcc __b31
    bne !+
    lda v
    cmp #<$100*$80
    bcc __b31
  !:
    // main::@32
    // cputc('.')
    // [113] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [114] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for (unsigned int w = 0; w < 32; w++)
    // [116] main::w#1 = ++ main::w#2 -- vwum1=_inc_vwum1 
    inc w
    bne !+
    inc w+1
  !:
    // [106] phi from main::@32 to main::@28 [phi:main::@32->main::@28]
    // [106] phi main::w#2 = main::w#1 [phi:main::@32->main::@28#0] -- register_copy 
    jmp __b28
    // main::@31
  __b31:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [117] main::v#1 = ++ main::v#2 -- vwum1=_inc_vwum1 
    inc v
    bne !+
    inc v+1
  !:
    // [111] phi from main::@31 to main::@30 [phi:main::@31->main::@30]
    // [111] phi main::v#2 = main::v#1 [phi:main::@31->main::@30#0] -- register_copy 
    jmp __b30
    // main::@16
  __b16:
    // if (rom_device_ids[flash_chip] != UNKNOWN)
    // [118] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@18 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b18+
    jmp __b18
  !__b18:
    // [119] phi from main::@16 to main::@26 [phi:main::@16->main::@26]
    // main::@26
    // gotoxy(0, 2)
    // [120] call gotoxy
    // [323] phi from main::@26 to gotoxy [phi:main::@26->gotoxy]
    // [323] phi gotoxy::y#22 = 2 [phi:main::@26->gotoxy#0] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = 0 [phi:main::@26->gotoxy#1] -- vbuyy=vbuc1 
    ldy #0
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [121] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [122] phi from main::bank_set_bram1 to main::@35 [phi:main::bank_set_bram1->main::@35]
    // main::@35
    // bank_set_brom(4)
    // [123] call bank_set_brom
    // [576] phi from main::@35 to bank_set_brom [phi:main::@35->bank_set_brom]
    // [576] phi bank_set_brom::bank#8 = 4 [phi:main::@35->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::@73
    // if (flash_chip == 0)
    // [124] if(main::flash_chip#10==0) goto main::@19 -- vbum1_eq_0_then_la1 
    lda flash_chip
    bne !__b19+
    jmp __b19
  !__b19:
    // [125] phi from main::@73 to main::@27 [phi:main::@73->main::@27]
    // main::@27
    // sprintf(file, "rom%u.bin", flash_chip)
    // [126] call snprintf_init
    jsr snprintf_init
    // [127] phi from main::@27 to main::@76 [phi:main::@27->main::@76]
    // main::@76
    // sprintf(file, "rom%u.bin", flash_chip)
    // [128] call printf_str
    // [551] phi from main::@76 to printf_str [phi:main::@76->printf_str]
    // [551] phi printf_str::putc#10 = &snputc [phi:main::@76->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [551] phi printf_str::s#10 = main::s3 [phi:main::@76->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@77
    // sprintf(file, "rom%u.bin", flash_chip)
    // [129] printf_uchar::uvalue#2 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [130] call printf_uchar
    // [583] phi from main::@77 to printf_uchar [phi:main::@77->printf_uchar]
    // [583] phi printf_uchar::format_zero_padding#3 = 0 [phi:main::@77->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [583] phi printf_uchar::format_min_length#3 = 0 [phi:main::@77->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [583] phi printf_uchar::putc#3 = &snputc [phi:main::@77->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [583] phi printf_uchar::format_radix#3 = DECIMAL [phi:main::@77->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [583] phi printf_uchar::uvalue#3 = printf_uchar::uvalue#2 [phi:main::@77->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [131] phi from main::@77 to main::@78 [phi:main::@77->main::@78]
    // main::@78
    // sprintf(file, "rom%u.bin", flash_chip)
    // [132] call printf_str
    // [551] phi from main::@78 to printf_str [phi:main::@78->printf_str]
    // [551] phi printf_str::putc#10 = &snputc [phi:main::@78->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [551] phi printf_str::s#10 = main::s4 [phi:main::@78->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@79
    // sprintf(file, "rom%u.bin", flash_chip)
    // [133] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [134] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // main::@20
  __b20:
    // unsigned char flash_rom_bank = flash_chip * 32
    // [136] main::flash_rom_bank#0 = main::flash_chip#10 << 5 -- vbum1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta flash_rom_bank
    // FILE *fp = fopen(1, 8, 2, file)
    // [137] call fopen
    // Read the file content.
    jsr fopen
    // [138] fopen::return#4 = fopen::return#1
    // main::@80
    // [139] main::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [140] if((struct $1 *)0!=main::fp#0) goto main::@21 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    bne __b21
    lda.z fp
    cmp #<0
    bne __b21
    // [141] phi from main::@80 to main::@25 [phi:main::@80->main::@25]
    // main::@25
    // textcolor(WHITE)
    // [142] call textcolor
    // [305] phi from main::@25 to textcolor [phi:main::@25->textcolor]
    // [305] phi textcolor::color#16 = WHITE [phi:main::@25->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@88
    // flash_chip * 10
    // [143] main::$145 = main::flash_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda flash_chip
    asl
    asl
    // [144] main::$146 = main::$145 + main::flash_chip#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc flash_chip
    // [145] main::$80 = main::$146 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(2 + flash_chip * 10, 58)
    // [146] gotoxy::x#20 = 2 + main::$80 -- vbuyy=vbuc1_plus_vbuaa 
    clc
    adc #2
    tay
    // [147] call gotoxy
    // [323] phi from main::@88 to gotoxy [phi:main::@88->gotoxy]
    // [323] phi gotoxy::y#22 = $3a [phi:main::@88->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = gotoxy::x#20 [phi:main::@88->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [148] phi from main::@88 to main::@89 [phi:main::@88->main::@89]
    // main::@89
    // printf("no file")
    // [149] call printf_str
    // [551] phi from main::@89 to printf_str [phi:main::@89->printf_str]
    // [551] phi printf_str::putc#10 = &cputc [phi:main::@89->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [551] phi printf_str::s#10 = main::s5 [phi:main::@89->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@90
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [150] print_chip_led::r#6 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [151] call print_chip_led
    // [631] phi from main::@90 to print_chip_led [phi:main::@90->print_chip_led]
    // [631] phi print_chip_led::tc#11 = DARK_GREY [phi:main::@90->print_chip_led#0] -- vbum1=vbuc1 
    lda #DARK_GREY
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#6 [phi:main::@90->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@18
  __b18:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [152] main::flash_chip#1 = -- main::flash_chip#10 -- vbum1=_dec_vbum1 
    dec flash_chip
    // [96] phi from main::@18 to main::@15 [phi:main::@18->main::@15]
    // [96] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@18->main::@15#0] -- register_copy 
    jmp __b15
    // main::@21
  __b21:
    // table_chip_clear(flash_chip * 32)
    // [153] table_chip_clear::rom_bank#1 = main::flash_chip#10 << 5 -- vbum1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta table_chip_clear.rom_bank
    // [154] call table_chip_clear
    // [651] phi from main::@21 to table_chip_clear [phi:main::@21->table_chip_clear]
    jsr table_chip_clear
    // [155] phi from main::@21 to main::@81 [phi:main::@21->main::@81]
    // main::@81
    // textcolor(WHITE)
    // [156] call textcolor
    // [305] phi from main::@81 to textcolor [phi:main::@81->textcolor]
    // [305] phi textcolor::color#16 = WHITE [phi:main::@81->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@82
    // flash_chip * 10
    // [157] main::$142 = main::flash_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda flash_chip
    asl
    asl
    // [158] main::$143 = main::$142 + main::flash_chip#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc flash_chip
    // [159] main::$88 = main::$143 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(2 + flash_chip * 10, 58)
    // [160] gotoxy::x#19 = 2 + main::$88 -- vbuyy=vbuc1_plus_vbuaa 
    clc
    adc #2
    tay
    // [161] call gotoxy
    // [323] phi from main::@82 to gotoxy [phi:main::@82->gotoxy]
    // [323] phi gotoxy::y#22 = $3a [phi:main::@82->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = gotoxy::x#19 [phi:main::@82->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [162] phi from main::@82 to main::@83 [phi:main::@82->main::@83]
    // main::@83
    // printf("%s", file)
    // [163] call printf_string
    // [676] phi from main::@83 to printf_string [phi:main::@83->printf_string]
    // [676] phi printf_string::str#10 = main::file [phi:main::@83->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [676] phi printf_string::format_min_length#3 = 0 [phi:main::@83->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@84
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [164] print_chip_led::r#5 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [165] call print_chip_led
    // [631] phi from main::@84 to print_chip_led [phi:main::@84->print_chip_led]
    // [631] phi print_chip_led::tc#11 = CYAN [phi:main::@84->print_chip_led#0] -- vbum1=vbuc1 
    lda #CYAN
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#5 [phi:main::@84->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@85
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [166] flash_read::fp#0 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [167] flash_read::rom_bank_start#1 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta flash_read.rom_bank_start
    // [168] call flash_read
    // [693] phi from main::@85 to flash_read [phi:main::@85->flash_read]
    // [693] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@85->flash_read#0] -- register_copy 
    // [693] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@85->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [693] phi flash_read::rom_bank_size#2 = 1 [phi:main::@85->flash_read#2] -- vbuxx=vbuc1 
    ldx #1
    // [693] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@85->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1)
    // [169] flash_read::return#3 = flash_read::return#2
    // main::@86
    // [170] main::rom_flash_total#1 = flash_read::return#3 -- vdum1=vdum2 
    lda flash_read.return
    sta rom_flash_total
    lda flash_read.return+1
    sta rom_flash_total+1
    lda flash_read.return+2
    sta rom_flash_total+2
    lda flash_read.return+3
    sta rom_flash_total+3
    // rom_size(1)
    // [171] call rom_size
    // [728] phi from main::@86 to rom_size [phi:main::@86->rom_size]
    // [728] phi rom_size::rom_banks#2 = 1 [phi:main::@86->rom_size#0] -- vbuaa=vbuc1 
    lda #1
    jsr rom_size
    // rom_size(1)
    // [172] rom_size::return#3 = rom_size::return#0
    // main::@87
    // [173] main::$94 = rom_size::return#3
    // if (flash_bytes != rom_size(1))
    // [174] if(main::rom_flash_total#1==main::$94) goto main::bank_set_bram2 -- vdum1_eq_vdum2_then_la1 
    lda rom_flash_total
    cmp __94
    bne !+
    lda rom_flash_total+1
    cmp __94+1
    bne !+
    lda rom_flash_total+2
    cmp __94+2
    bne !+
    lda rom_flash_total+3
    cmp __94+3
    beq bank_set_bram2
  !:
    rts
    // main::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [175] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@36
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [176] flash_read::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbum1=vbum2_plus_1 
    lda flash_rom_bank
    inc
    sta flash_read.rom_bank_start
    // [177] flash_read::fp#1 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [178] call flash_read
    // [693] phi from main::@36 to flash_read [phi:main::@36->flash_read]
    // [693] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@36->flash_read#0] -- register_copy 
    // [693] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@36->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [693] phi flash_read::rom_bank_size#2 = $1f [phi:main::@36->flash_read#2] -- vbuxx=vbuc1 
    ldx #$1f
    // [693] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@36->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [179] flash_read::return#4 = flash_read::return#2
    // main::@91
    // flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31)
    // [180] main::flash_bytes#1 = flash_read::return#4 -- vdum1=vdum2 
    lda flash_read.return
    sta flash_bytes
    lda flash_read.return+1
    sta flash_bytes+1
    lda flash_read.return+2
    sta flash_bytes+2
    lda flash_read.return+3
    sta flash_bytes+3
    // rom_flash_total += flash_bytes
    // [181] main::rom_flash_total#10 = main::rom_flash_total#1 + main::flash_bytes#1 -- vdum1=vdum2_plus_vdum1 
    clc
    lda rom_flash_total_1
    adc rom_flash_total
    sta rom_flash_total_1
    lda rom_flash_total_1+1
    adc rom_flash_total+1
    sta rom_flash_total_1+1
    lda rom_flash_total_1+2
    adc rom_flash_total+2
    sta rom_flash_total_1+2
    lda rom_flash_total_1+3
    adc rom_flash_total+3
    sta rom_flash_total_1+3
    // fclose(fp)
    // [182] fclose::fp#0 = main::fp#0
    // [183] call fclose
    jsr fclose
    // main::bank_set_bram3
    // BRAM = bank
    // [184] BRAM = main::bank_set_bram3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram3_bank
    sta.z BRAM
    // [185] phi from main::bank_set_bram3 to main::@37 [phi:main::bank_set_bram3->main::@37]
    // main::@37
    // bank_set_brom(4)
    // [186] call bank_set_brom
    // [576] phi from main::@37 to bank_set_brom [phi:main::@37->bank_set_brom]
    // [576] phi bank_set_brom::bank#8 = 4 [phi:main::@37->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::@38
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [188] print_chip_led::r#7 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [189] call print_chip_led
    // [631] phi from main::@38 to print_chip_led [phi:main::@38->print_chip_led]
    // [631] phi print_chip_led::tc#11 = PURPLE [phi:main::@38->print_chip_led#0] -- vbum1=vbuc1 
    lda #PURPLE
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#7 [phi:main::@38->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@92
    // unsigned long flashed_bytes = flash_write((ram_ptr_t)0x4000, flash_rom_bank, 0x4000)
    // [190] flash_write::rom_bank_start#1 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta flash_write.rom_bank_start
    // [191] call flash_write
    // [742] phi from main::@92 to flash_write [phi:main::@92->flash_write]
    // [742] phi flash_write::flash_ram_address#24 = (char *) 16384 [phi:main::@92->flash_write#0] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_write.flash_ram_address
    lda #>$4000
    sta.z flash_write.flash_ram_address+1
    // [742] phi flash_write::flash_size#5 = $4000 [phi:main::@92->flash_write#1] -- vdum1=vduc1 
    lda #<$4000
    sta flash_write.flash_size
    lda #>$4000
    sta flash_write.flash_size+1
    lda #<$4000>>$10
    sta flash_write.flash_size+2
    lda #>$4000>>$10
    sta flash_write.flash_size+3
    // [742] phi flash_write::rom_bank_start#10 = flash_write::rom_bank_start#1 [phi:main::@92->flash_write#2] -- register_copy 
    jsr flash_write
    // unsigned long flashed_bytes = flash_write((ram_ptr_t)0x4000, flash_rom_bank, 0x4000)
    // [192] flash_write::return#2 = flash_write::flashed_bytes#11
    // main::@93
    // [193] main::rom_flashed_total#1 = flash_write::return#2 -- vdum1=vdum2 
    lda flash_write.return
    sta rom_flashed_total
    lda flash_write.return+1
    sta rom_flashed_total+1
    lda flash_write.return+2
    sta rom_flashed_total+2
    lda flash_write.return+3
    sta rom_flashed_total+3
    // if (rom_flashed_total >= rom_flash_total)
    // [194] if(main::rom_flashed_total#1<main::rom_flash_total#10) goto main::bank_set_bram4 -- vdum1_lt_vdum2_then_la1 
    cmp rom_flash_total_1+3
    bcc bank_set_bram4
    bne !+
    lda rom_flashed_total+2
    cmp rom_flash_total_1+2
    bcc bank_set_bram4
    bne !+
    lda rom_flashed_total+1
    cmp rom_flash_total_1+1
    bcc bank_set_bram4
    bne !+
    lda rom_flashed_total
    cmp rom_flash_total_1
    bcc bank_set_bram4
  !:
    rts
    // main::bank_set_bram4
  bank_set_bram4:
    // BRAM = bank
    // [195] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // main::@39
    // flash_write((ram_ptr_t)0xA000, flash_rom_bank + 1, rom_flash_total - 0x4000)
    // [196] flash_write::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbum1=vbum2_plus_1 
    lda flash_rom_bank
    inc
    sta flash_write.rom_bank_start
    // [197] flash_write::flash_size#1 = main::rom_flash_total#10 - $4000 -- vdum1=vdum2_minus_vduc1 
    lda rom_flash_total_1
    sec
    sbc #<$4000
    sta flash_write.flash_size
    lda rom_flash_total_1+1
    sbc #>$4000
    sta flash_write.flash_size+1
    lda rom_flash_total_1+2
    sbc #<$4000>>$10
    sta flash_write.flash_size+2
    lda rom_flash_total_1+3
    sbc #>$4000>>$10
    sta flash_write.flash_size+3
    // [198] call flash_write
    // [742] phi from main::@39 to flash_write [phi:main::@39->flash_write]
    // [742] phi flash_write::flash_ram_address#24 = (char *) 40960 [phi:main::@39->flash_write#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_write.flash_ram_address
    lda #>$a000
    sta.z flash_write.flash_ram_address+1
    // [742] phi flash_write::flash_size#5 = flash_write::flash_size#1 [phi:main::@39->flash_write#1] -- register_copy 
    // [742] phi flash_write::rom_bank_start#10 = flash_write::rom_bank_start#2 [phi:main::@39->flash_write#2] -- register_copy 
    jsr flash_write
    // flash_write((ram_ptr_t)0xA000, flash_rom_bank + 1, rom_flash_total - 0x4000)
    // [199] flash_write::return#3 = flash_write::flashed_bytes#11
    // main::@94
    // flashed_bytes = flash_write((ram_ptr_t)0xA000, flash_rom_bank + 1, rom_flash_total - 0x4000)
    // [200] main::flashed_bytes#1 = flash_write::return#3 -- vdum1=vdum2 
    lda flash_write.return
    sta flashed_bytes
    lda flash_write.return+1
    sta flashed_bytes+1
    lda flash_write.return+2
    sta flashed_bytes+2
    lda flash_write.return+3
    sta flashed_bytes+3
    // rom_flashed_total += flashed_bytes
    // [201] main::rom_flashed_total#11 = main::rom_flashed_total#1 + main::flashed_bytes#1 -- vdum1=vdum2_plus_vdum1 
    clc
    lda rom_flashed_total_1
    adc rom_flashed_total
    sta rom_flashed_total_1
    lda rom_flashed_total_1+1
    adc rom_flashed_total+1
    sta rom_flashed_total_1+1
    lda rom_flashed_total_1+2
    adc rom_flashed_total+2
    sta rom_flashed_total_1+2
    lda rom_flashed_total_1+3
    adc rom_flashed_total+3
    sta rom_flashed_total_1+3
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::bank_set_bram5
    // BRAM = bank
    // [203] BRAM = main::bank_set_bram5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram5_bank
    sta.z BRAM
    // main::@40
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [204] print_chip_led::r#8 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [205] call print_chip_led
  // read from bank 1 in bram.
    // [631] phi from main::@40 to print_chip_led [phi:main::@40->print_chip_led]
    // [631] phi print_chip_led::tc#11 = GREEN [phi:main::@40->print_chip_led#0] -- vbum1=vbuc1 
    lda #GREEN
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#8 [phi:main::@40->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@95
    // unsigned long correct_bytes = flash_verify((ram_ptr_t)0x4000, flash_rom_bank, 0x4000)
    // [206] flash_verify::rom_bank_start#1 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta flash_verify.rom_bank_start
    // [207] call flash_verify
    // [779] phi from main::@95 to flash_verify [phi:main::@95->flash_verify]
    // [779] phi flash_verify::verify_ram_address#26 = (char *) 16384 [phi:main::@95->flash_verify#0] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_verify.verify_ram_address
    lda #>$4000
    sta.z flash_verify.verify_ram_address+1
    // [779] phi flash_verify::verify_size#5 = $4000 [phi:main::@95->flash_verify#1] -- vdum1=vduc1 
    lda #<$4000
    sta flash_verify.verify_size
    lda #>$4000
    sta flash_verify.verify_size+1
    lda #<$4000>>$10
    sta flash_verify.verify_size+2
    lda #>$4000>>$10
    sta flash_verify.verify_size+3
    // [779] phi flash_verify::rom_bank_start#10 = flash_verify::rom_bank_start#1 [phi:main::@95->flash_verify#2] -- register_copy 
    jsr flash_verify
    // unsigned long correct_bytes = flash_verify((ram_ptr_t)0x4000, flash_rom_bank, 0x4000)
    // [208] flash_verify::return#2 = flash_verify::correct_bytes#12
    // main::@96
    // [209] main::rom_verified_total#1 = flash_verify::return#2 -- vdum1=vdum2 
    lda flash_verify.return
    sta rom_verified_total
    lda flash_verify.return+1
    sta rom_verified_total+1
    lda flash_verify.return+2
    sta rom_verified_total+2
    lda flash_verify.return+3
    sta rom_verified_total+3
    // main::bank_set_bram6
    // BRAM = bank
    // [210] BRAM = main::bank_set_bram6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram6_bank
    sta.z BRAM
    // main::@41
    // flash_verify((ram_ptr_t)0xA000, flash_rom_bank + 1, rom_flash_total - 0x4000)
    // [211] flash_verify::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbum1=vbum2_plus_1 
    lda flash_rom_bank
    inc
    sta flash_verify.rom_bank_start
    // [212] flash_verify::verify_size#1 = main::rom_flash_total#10 - $4000 -- vdum1=vdum2_minus_vduc1 
    lda rom_flash_total_1
    sec
    sbc #<$4000
    sta flash_verify.verify_size
    lda rom_flash_total_1+1
    sbc #>$4000
    sta flash_verify.verify_size+1
    lda rom_flash_total_1+2
    sbc #<$4000>>$10
    sta flash_verify.verify_size+2
    lda rom_flash_total_1+3
    sbc #>$4000>>$10
    sta flash_verify.verify_size+3
    // [213] call flash_verify
    // [779] phi from main::@41 to flash_verify [phi:main::@41->flash_verify]
    // [779] phi flash_verify::verify_ram_address#26 = (char *) 40960 [phi:main::@41->flash_verify#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_verify.verify_ram_address
    lda #>$a000
    sta.z flash_verify.verify_ram_address+1
    // [779] phi flash_verify::verify_size#5 = flash_verify::verify_size#1 [phi:main::@41->flash_verify#1] -- register_copy 
    // [779] phi flash_verify::rom_bank_start#10 = flash_verify::rom_bank_start#2 [phi:main::@41->flash_verify#2] -- register_copy 
    jsr flash_verify
    // flash_verify((ram_ptr_t)0xA000, flash_rom_bank + 1, rom_flash_total - 0x4000)
    // [214] flash_verify::return#3 = flash_verify::correct_bytes#12
    // main::@97
    // correct_bytes = flash_verify((ram_ptr_t)0xA000, flash_rom_bank + 1, rom_flash_total - 0x4000)
    // [215] main::correct_bytes#1 = flash_verify::return#3 -- vdum1=vdum2 
    lda flash_verify.return
    sta correct_bytes
    lda flash_verify.return+1
    sta correct_bytes+1
    lda flash_verify.return+2
    sta correct_bytes+2
    lda flash_verify.return+3
    sta correct_bytes+3
    // rom_verified_total += correct_bytes
    // [216] main::rom_verified_total#10 = main::rom_verified_total#1 + main::correct_bytes#1 -- vdum1=vdum2_plus_vdum1 
    clc
    lda rom_verified_total_1
    adc rom_verified_total
    sta rom_verified_total_1
    lda rom_verified_total_1+1
    adc rom_verified_total+1
    sta rom_verified_total_1+1
    lda rom_verified_total_1+2
    adc rom_verified_total+2
    sta rom_verified_total_1+2
    lda rom_verified_total_1+3
    adc rom_verified_total+3
    sta rom_verified_total_1+3
    // main::bank_set_bram7
    // BRAM = bank
    // [217] BRAM = main::bank_set_bram7_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram7_bank
    sta.z BRAM
    // [218] phi from main::bank_set_bram7 to main::@42 [phi:main::bank_set_bram7->main::@42]
    // main::@42
    // bank_set_brom(4)
    // [219] call bank_set_brom
    // [576] phi from main::@42 to bank_set_brom [phi:main::@42->bank_set_brom]
    // [576] phi bank_set_brom::bank#8 = 4 [phi:main::@42->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [221] phi from main::CLI2 to main::@43 [phi:main::CLI2->main::@43]
    // main::@43
    // gotoxy(0, 57)
    // [222] call gotoxy
    // [323] phi from main::@43 to gotoxy [phi:main::@43->gotoxy]
    // [323] phi gotoxy::y#22 = $39 [phi:main::@43->gotoxy#0] -- vbuz1=vbuc1 
    lda #$39
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = 0 [phi:main::@43->gotoxy#1] -- vbuyy=vbuc1 
    ldy #0
    jsr gotoxy
    // main::@98
    // if (rom_verified_total == rom_flashed_total)
    // [223] if(main::rom_verified_total#10==main::rom_flashed_total#11) goto main::@22 -- vdum1_eq_vdum2_then_la1 
    lda rom_verified_total_1
    cmp rom_flashed_total_1
    bne !+
    lda rom_verified_total_1+1
    cmp rom_flashed_total_1+1
    bne !+
    lda rom_verified_total_1+2
    cmp rom_flashed_total_1+2
    bne !+
    lda rom_verified_total_1+3
    cmp rom_flashed_total_1+3
    beq __b22
  !:
    // main::@24
    // print_chip_led(flash_chip, RED, BLUE)
    // [224] print_chip_led::r#10 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [225] call print_chip_led
  // sprintf(buffer, "the flashing of %s in rom went wrong. press a key to flash the next chip ...", file);
  // print_text(buffer);
    // [631] phi from main::@24 to print_chip_led [phi:main::@24->print_chip_led]
    // [631] phi print_chip_led::tc#11 = RED [phi:main::@24->print_chip_led#0] -- vbum1=vbuc1 
    lda #RED
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#10 [phi:main::@24->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [226] phi from main::@22 main::@24 to main::@23 [phi:main::@22/main::@24->main::@23]
    // main::@23
  __b23:
    // wait_key()
    // [227] call wait_key
    // [560] phi from main::@23 to wait_key [phi:main::@23->wait_key]
    jsr wait_key
    jmp __b18
    // main::@22
  __b22:
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [228] print_chip_led::r#9 = main::flash_chip#10 -- vbuxx=vbum1 
    ldx flash_chip
    // [229] call print_chip_led
  // sprintf(buffer, "the flashing of %s in rom went perfectly ok. press a key to flash the next chip ...", file);
  // print_text(buffer);
    // [631] phi from main::@22 to print_chip_led [phi:main::@22->print_chip_led]
    // [631] phi print_chip_led::tc#11 = GREEN [phi:main::@22->print_chip_led#0] -- vbum1=vbuc1 
    lda #GREEN
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#9 [phi:main::@22->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    jmp __b23
    // [230] phi from main::@73 to main::@19 [phi:main::@73->main::@19]
    // main::@19
  __b19:
    // sprintf(file, "rom.bin", flash_chip)
    // [231] call snprintf_init
    jsr snprintf_init
    // [232] phi from main::@19 to main::@74 [phi:main::@19->main::@74]
    // main::@74
    // sprintf(file, "rom.bin", flash_chip)
    // [233] call printf_str
    // [551] phi from main::@74 to printf_str [phi:main::@74->printf_str]
    // [551] phi printf_str::putc#10 = &snputc [phi:main::@74->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [551] phi printf_str::s#10 = main::s2 [phi:main::@74->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@75
    // sprintf(file, "rom.bin", flash_chip)
    // [234] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [235] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b20
    // main::@4
  __b4:
    // rom_manufacturer_ids[rom_chip] = 0
    // [237] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [238] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // if (rom_address <= 0x100000)
    // [239] if(main::rom_address#10>$100000) goto main::@5 -- vdum1_gt_vduc1_then_la1 
    lda #>$100000>>$10
    cmp rom_address+3
    bcc __b5
    bne !+
    lda #<$100000>>$10
    cmp rom_address+2
    bcc __b5
    bne !+
    lda #>$100000
    cmp rom_address+1
    bcc __b5
    bne !+
    lda #<$100000
    cmp rom_address
    bcc __b5
  !:
    // [240] phi from main::@4 to main::@12 [phi:main::@4->main::@12]
    // main::@12
    // rom_unlock(0x05555, 0x90)
    // [241] call rom_unlock
    // [822] phi from main::@12 to rom_unlock [phi:main::@12->rom_unlock]
    // [822] phi rom_unlock::unlock_code#2 = $90 [phi:main::@12->rom_unlock#0] -- vbum1=vbuc1 
    lda #$90
    sta rom_unlock.unlock_code
    jsr rom_unlock
    // main::@63
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [242] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [243] main::rom_device_ids[main::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_unlock(0x05555, 0xF0)
    // [244] call rom_unlock
    // [822] phi from main::@63 to rom_unlock [phi:main::@63->rom_unlock]
    // [822] phi rom_unlock::unlock_code#2 = $f0 [phi:main::@63->rom_unlock#0] -- vbum1=vbuc1 
    lda #$f0
    sta rom_unlock.unlock_code
    jsr rom_unlock
    // [245] phi from main::@4 main::@63 to main::@5 [phi:main::@4/main::@63->main::@5]
    // main::@5
  __b5:
    // bank_set_brom(4)
    // [246] call bank_set_brom
  // Ensure the ROM is set to BASIC.
    // [576] phi from main::@5 to bank_set_brom [phi:main::@5->bank_set_brom]
    // [576] phi bank_set_brom::bank#8 = 4 [phi:main::@5->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // main::@62
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             break;
    // [247] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@6 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [248] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@7 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [249] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@8 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b8+
    jmp __b8
  !__b8:
    // main::@9
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [250] print_chip_led::r#4 = main::rom_chip#10 -- vbuxx=vbum1 
    ldx rom_chip
    // [251] call print_chip_led
    // [631] phi from main::@9 to print_chip_led [phi:main::@9->print_chip_led]
    // [631] phi print_chip_led::tc#11 = BLACK [phi:main::@9->print_chip_led#0] -- vbum1=vbuc1 
    lda #BLACK
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#4 [phi:main::@9->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@64
    // rom_device_ids[rom_chip] = UNKNOWN
    // [252] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // [253] phi from main::@64 to main::@10 [phi:main::@64->main::@10]
    // [253] phi main::rom_device#5 = main::rom_device#13 [phi:main::@64->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_4
    sta.z rom_device
    lda #>rom_device_4
    sta.z rom_device+1
    // main::@10
  __b10:
    // textcolor(WHITE)
    // [254] call textcolor
    // [305] phi from main::@10 to textcolor [phi:main::@10->textcolor]
    // [305] phi textcolor::color#16 = WHITE [phi:main::@10->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // main::@65
    // rom_chip * 10
    // [255] main::$139 = main::rom_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda rom_chip
    asl
    asl
    // [256] main::$140 = main::$139 + main::rom_chip#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip
    // [257] main::$64 = main::$140 << 1 -- vbum1=vbuaa_rol_1 
    asl
    sta __64
    // gotoxy(2 + rom_chip * 10, 56)
    // [258] gotoxy::x#14 = 2 + main::$64 -- vbuyy=vbuc1_plus_vbum1 
    lda #2
    clc
    adc __64
    tay
    // [259] call gotoxy
    // [323] phi from main::@65 to gotoxy [phi:main::@65->gotoxy]
    // [323] phi gotoxy::y#22 = $38 [phi:main::@65->gotoxy#0] -- vbuz1=vbuc1 
    lda #$38
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = gotoxy::x#14 [phi:main::@65->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@66
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [260] printf_uchar::uvalue#1 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbuxx=pbuc1_derefidx_vbum1 
    ldy rom_chip
    ldx rom_manufacturer_ids,y
    // [261] call printf_uchar
    // [583] phi from main::@66 to printf_uchar [phi:main::@66->printf_uchar]
    // [583] phi printf_uchar::format_zero_padding#3 = 0 [phi:main::@66->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [583] phi printf_uchar::format_min_length#3 = 0 [phi:main::@66->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [583] phi printf_uchar::putc#3 = &cputc [phi:main::@66->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [583] phi printf_uchar::format_radix#3 = HEXADECIMAL [phi:main::@66->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [583] phi printf_uchar::uvalue#3 = printf_uchar::uvalue#1 [phi:main::@66->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // main::@67
    // gotoxy(2 + rom_chip * 10, 57)
    // [262] gotoxy::x#15 = 2 + main::$64 -- vbuyy=vbuc1_plus_vbum1 
    lda #2
    clc
    adc __64
    tay
    // [263] call gotoxy
    // [323] phi from main::@67 to gotoxy [phi:main::@67->gotoxy]
    // [323] phi gotoxy::y#22 = $39 [phi:main::@67->gotoxy#0] -- vbuz1=vbuc1 
    lda #$39
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = gotoxy::x#15 [phi:main::@67->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@68
    // printf("%s", rom_device)
    // [264] printf_string::str#1 = main::rom_device#5 -- pbuz1=pbuz2 
    lda.z rom_device
    sta.z printf_string.str
    lda.z rom_device+1
    sta.z printf_string.str+1
    // [265] call printf_string
    // [676] phi from main::@68 to printf_string [phi:main::@68->printf_string]
    // [676] phi printf_string::str#10 = printf_string::str#1 [phi:main::@68->printf_string#0] -- register_copy 
    // [676] phi printf_string::format_min_length#3 = 0 [phi:main::@68->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@69
    // rom_chip++;
    // [266] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // main::@11
    // rom_address += 0x80000
    // [267] main::rom_address#1 = main::rom_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
    clc
    lda rom_address
    adc #<$80000
    sta rom_address
    lda rom_address+1
    adc #>$80000
    sta rom_address+1
    lda rom_address+2
    adc #<$80000>>$10
    sta rom_address+2
    lda rom_address+3
    adc #>$80000>>$10
    sta rom_address+3
    // [91] phi from main::@11 to main::@3 [phi:main::@11->main::@3]
    // [91] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@11->main::@3#0] -- register_copy 
    // [91] phi main::rom_address#10 = main::rom_address#1 [phi:main::@11->main::@3#1] -- register_copy 
    jmp __b3
    // main::@8
  __b8:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [268] print_chip_led::r#3 = main::rom_chip#10 -- vbuxx=vbum1 
    ldx rom_chip
    // [269] call print_chip_led
    // [631] phi from main::@8 to print_chip_led [phi:main::@8->print_chip_led]
    // [631] phi print_chip_led::tc#11 = WHITE [phi:main::@8->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#3 [phi:main::@8->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [253] phi from main::@8 to main::@10 [phi:main::@8->main::@10]
    // [253] phi main::rom_device#5 = main::rom_device#12 [phi:main::@8->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_3
    sta.z rom_device
    lda #>rom_device_3
    sta.z rom_device+1
    jmp __b10
    // main::@7
  __b7:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [270] print_chip_led::r#2 = main::rom_chip#10 -- vbuxx=vbum1 
    ldx rom_chip
    // [271] call print_chip_led
    // [631] phi from main::@7 to print_chip_led [phi:main::@7->print_chip_led]
    // [631] phi print_chip_led::tc#11 = WHITE [phi:main::@7->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#2 [phi:main::@7->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [253] phi from main::@7 to main::@10 [phi:main::@7->main::@10]
    // [253] phi main::rom_device#5 = main::rom_device#11 [phi:main::@7->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_2
    sta.z rom_device
    lda #>rom_device_2
    sta.z rom_device+1
    jmp __b10
    // main::@6
  __b6:
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [272] print_chip_led::r#1 = main::rom_chip#10 -- vbuxx=vbum1 
    ldx rom_chip
    // [273] call print_chip_led
    // [631] phi from main::@6 to print_chip_led [phi:main::@6->print_chip_led]
    // [631] phi print_chip_led::tc#11 = WHITE [phi:main::@6->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#1 [phi:main::@6->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [253] phi from main::@6 to main::@10 [phi:main::@6->main::@10]
    // [253] phi main::rom_device#5 = main::rom_device#1 [phi:main::@6->main::@10#0] -- pbuz1=pbuc1 
    lda #<rom_device_1
    sta.z rom_device
    lda #>rom_device_1
    sta.z rom_device+1
    jmp __b10
    // main::@2
  __b2:
    // r * 10
    // [274] main::$136 = main::r#10 << 2 -- vbuaa=vbum1_rol_2 
    lda r
    asl
    asl
    // [275] main::$137 = main::$136 + main::r#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc r
    // [276] main::$20 = main::$137 << 1 -- vbum1=vbuaa_rol_1 
    asl
    sta __20
    // print_chip_line(3 + r * 10, 45, ' ')
    // [277] print_chip_line::x#0 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [278] call print_chip_line
    // [829] phi from main::@2 to print_chip_line [phi:main::@2->print_chip_line]
    // [829] phi print_chip_line::c#10 = ' 'pm [phi:main::@2->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [829] phi print_chip_line::y#9 = $2d [phi:main::@2->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$2d
    // [829] phi print_chip_line::x#9 = print_chip_line::x#0 [phi:main::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@51
    // print_chip_line(3 + r * 10, 46, 'r')
    // [279] print_chip_line::x#1 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [280] call print_chip_line
    // [829] phi from main::@51 to print_chip_line [phi:main::@51->print_chip_line]
    // [829] phi print_chip_line::c#10 = 'r'pm [phi:main::@51->print_chip_line#0] -- vbum1=vbuc1 
    lda #'r'
    sta print_chip_line.c
    // [829] phi print_chip_line::y#9 = $2e [phi:main::@51->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$2e
    // [829] phi print_chip_line::x#9 = print_chip_line::x#1 [phi:main::@51->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@52
    // print_chip_line(3 + r * 10, 47, 'o')
    // [281] print_chip_line::x#2 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [282] call print_chip_line
    // [829] phi from main::@52 to print_chip_line [phi:main::@52->print_chip_line]
    // [829] phi print_chip_line::c#10 = 'o'pm [phi:main::@52->print_chip_line#0] -- vbum1=vbuc1 
    lda #'o'
    sta print_chip_line.c
    // [829] phi print_chip_line::y#9 = $2f [phi:main::@52->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$2f
    // [829] phi print_chip_line::x#9 = print_chip_line::x#2 [phi:main::@52->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@53
    // print_chip_line(3 + r * 10, 48, 'm')
    // [283] print_chip_line::x#3 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [284] call print_chip_line
    // [829] phi from main::@53 to print_chip_line [phi:main::@53->print_chip_line]
    // [829] phi print_chip_line::c#10 = 'm'pm [phi:main::@53->print_chip_line#0] -- vbum1=vbuc1 
    lda #'m'
    sta print_chip_line.c
    // [829] phi print_chip_line::y#9 = $30 [phi:main::@53->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$30
    // [829] phi print_chip_line::x#9 = print_chip_line::x#3 [phi:main::@53->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@54
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [285] print_chip_line::x#4 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [286] print_chip_line::c#4 = '0'pm + main::r#10 -- vbum1=vbuc1_plus_vbum2 
    lda #'0'
    clc
    adc r
    sta print_chip_line.c
    // [287] call print_chip_line
    // [829] phi from main::@54 to print_chip_line [phi:main::@54->print_chip_line]
    // [829] phi print_chip_line::c#10 = print_chip_line::c#4 [phi:main::@54->print_chip_line#0] -- register_copy 
    // [829] phi print_chip_line::y#9 = $31 [phi:main::@54->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$31
    // [829] phi print_chip_line::x#9 = print_chip_line::x#4 [phi:main::@54->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@55
    // print_chip_line(3 + r * 10, 50, ' ')
    // [288] print_chip_line::x#5 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [289] call print_chip_line
    // [829] phi from main::@55 to print_chip_line [phi:main::@55->print_chip_line]
    // [829] phi print_chip_line::c#10 = ' 'pm [phi:main::@55->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [829] phi print_chip_line::y#9 = $32 [phi:main::@55->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$32
    // [829] phi print_chip_line::x#9 = print_chip_line::x#5 [phi:main::@55->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@56
    // print_chip_line(3 + r * 10, 51, '5')
    // [290] print_chip_line::x#6 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [291] call print_chip_line
    // [829] phi from main::@56 to print_chip_line [phi:main::@56->print_chip_line]
    // [829] phi print_chip_line::c#10 = '5'pm [phi:main::@56->print_chip_line#0] -- vbum1=vbuc1 
    lda #'5'
    sta print_chip_line.c
    // [829] phi print_chip_line::y#9 = $33 [phi:main::@56->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$33
    // [829] phi print_chip_line::x#9 = print_chip_line::x#6 [phi:main::@56->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@57
    // print_chip_line(3 + r * 10, 52, '1')
    // [292] print_chip_line::x#7 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [293] call print_chip_line
    // [829] phi from main::@57 to print_chip_line [phi:main::@57->print_chip_line]
    // [829] phi print_chip_line::c#10 = '1'pm [phi:main::@57->print_chip_line#0] -- vbum1=vbuc1 
    lda #'1'
    sta print_chip_line.c
    // [829] phi print_chip_line::y#9 = $34 [phi:main::@57->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$34
    // [829] phi print_chip_line::x#9 = print_chip_line::x#7 [phi:main::@57->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@58
    // print_chip_line(3 + r * 10, 53, '2')
    // [294] print_chip_line::x#8 = 3 + main::$20 -- vbuyy=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    tay
    // [295] call print_chip_line
    // [829] phi from main::@58 to print_chip_line [phi:main::@58->print_chip_line]
    // [829] phi print_chip_line::c#10 = '2'pm [phi:main::@58->print_chip_line#0] -- vbum1=vbuc1 
    lda #'2'
    sta print_chip_line.c
    // [829] phi print_chip_line::y#9 = $35 [phi:main::@58->print_chip_line#1] -- vbuxx=vbuc1 
    ldx #$35
    // [829] phi print_chip_line::x#9 = print_chip_line::x#8 [phi:main::@58->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // main::@59
    // print_chip_end(3 + r * 10, 54)
    // [296] print_chip_end::x#0 = 3 + main::$20 -- vbuaa=vbuc1_plus_vbum1 
    lda #3
    clc
    adc __20
    // [297] call print_chip_end
    jsr print_chip_end
    // main::@60
    // print_chip_led(r, BLACK, BLUE)
    // [298] print_chip_led::r#0 = main::r#10 -- vbuxx=vbum1 
    ldx r
    // [299] call print_chip_led
    // [631] phi from main::@60 to print_chip_led [phi:main::@60->print_chip_led]
    // [631] phi print_chip_led::tc#11 = BLACK [phi:main::@60->print_chip_led#0] -- vbum1=vbuc1 
    lda #BLACK
    sta print_chip_led.tc
    // [631] phi print_chip_led::r#11 = print_chip_led::r#0 [phi:main::@60->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@61
    // for (unsigned char r = 0; r < 8; r++)
    // [300] main::r#1 = ++ main::r#10 -- vbum1=_inc_vbum1 
    inc r
    // [89] phi from main::@61 to main::@1 [phi:main::@61->main::@1]
    // [89] phi main::r#10 = main::r#1 [phi:main::@61->main::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom_device_ids: .byte 0
    .fill 7, 0
    rom_manufacturer_ids: .byte 0
    .fill 7, 0
    file: .text ""
    .byte 0
    .fill $f, 0
    s: .text "rom flash utility"
    .byte 0
    s1: .text "resetting commander x16 ..."
    .byte 0
    s2: .text "rom.bin"
    .byte 0
    s3: .text "rom"
    .byte 0
    s4: .text ".bin"
    .byte 0
    s5: .text "no file"
    .byte 0
    rom_device_1: .text "f010a"
    .byte 0
    rom_device_2: .text "f020a"
    .byte 0
    rom_device_3: .text "f040"
    .byte 0
    rom_device_4: .text "----"
    .byte 0
    __20: .byte 0
    __64: .byte 0
    .label __94 = rom_size.return
    r: .byte 0
    rom_chip: .byte 0
    rom_address: .dword 0
    flash_chip: .byte 0
    flash_rom_bank: .byte 0
    // sprintf(buffer, "reading %s in ram ...", file);
    // print_text(buffer);
    rom_flash_total: .dword 0
    flash_bytes: .dword 0
    // sprintf(buffer, "flashing %s in rom ...", file);
    // print_text(buffer);
    rom_flashed_total: .dword 0
    flashed_bytes: .dword 0
    // sprintf(buffer, "verify %s in ram with flashed rom.", file);
    // print_text(buffer);
    rom_verified_total: .dword 0
    correct_bytes: .dword 0
    v: .word 0
    w: .word 0
    // sprintf(buffer, "reading %s in ram ...", file);
    // print_text(buffer);
    .label rom_flash_total_1 = flash_bytes
    // sprintf(buffer, "verify %s in ram with flashed rom.", file);
    // print_text(buffer);
    .label rom_verified_total_1 = correct_bytes
    // sprintf(buffer, "flashing %s in rom ...", file);
    // print_text(buffer);
    .label rom_flashed_total_1 = flashed_bytes
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [301] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuxx=_deref_pbuc1 
    ldx VERA_L1_MAPBASE
    // [302] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [303] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [304] return 
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
    // [306] textcolor::$0 = *((char *)&__conio+$b) & $f0 -- vbuaa=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$b
    // __conio.color & 0xF0 | color
    // [307] textcolor::$1 = textcolor::$0 | textcolor::color#16 -- vbuaa=vbuaa_bor_vbuxx 
    stx.z $ff
    ora.z $ff
    // __conio.color = __conio.color & 0xF0 | color
    // [308] *((char *)&__conio+$b) = textcolor::$1 -- _deref_pbuc1=vbuaa 
    sta __conio+$b
    // textcolor::@return
    // }
    // [309] return 
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
    // [311] bgcolor::$0 = *((char *)&__conio+$b) & $f -- vbum1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$b
    sta __0
    // color << 4
    // [312] bgcolor::$1 = bgcolor::color#11 << 4 -- vbuaa=vbuxx_rol_4 
    txa
    asl
    asl
    asl
    asl
    // __conio.color & 0x0F | color << 4
    // [313] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuaa=vbum1_bor_vbuaa 
    ora __0
    // __conio.color = __conio.color & 0x0F | color << 4
    // [314] *((char *)&__conio+$b) = bgcolor::$2 -- _deref_pbuc1=vbuaa 
    sta __conio+$b
    // bgcolor::@return
    // }
    // [315] return 
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
    // [316] *((char *)&__conio+$a) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$a
    // cursor::@return
    // }
    // [317] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $50
    // __mem unsigned char x
    // [318] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [319] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [321] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [322] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__register(Y) char x, __zp($47) char y)
gotoxy: {
    .label y = $47
    // (x>=__conio.width)?__conio.width:x
    // [324] if(gotoxy::x#22>=*((char *)&__conio+4)) goto gotoxy::@1 -- vbuyy_ge__deref_pbuc1_then_la1 
    cpy __conio+4
    bcs __b1
    // [326] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [326] phi gotoxy::$3 = gotoxy::x#22 [phi:gotoxy->gotoxy::@2#0] -- vbuaa=vbuyy 
    tya
    jmp __b2
    // gotoxy::@1
  __b1:
    // [325] gotoxy::$2 = *((char *)&__conio+4) -- vbuaa=_deref_pbuc1 
    lda __conio+4
    // [326] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [326] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [327] *((char *)&__conio+$d) = gotoxy::$3 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // (y>=__conio.height)?__conio.height:y
    // [328] if(gotoxy::y#22>=*((char *)&__conio+5)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+5
    bcs __b3
    // gotoxy::@4
    // [329] gotoxy::$14 = gotoxy::y#22 -- vbuaa=vbuz1 
    // [330] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [330] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [331] *((char *)&__conio+$e) = gotoxy::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+$e
    // __conio.cursor_x << 1
    // [332] gotoxy::$8 = *((char *)&__conio+$d) << 1 -- vbuxx=_deref_pbuc1_rol_1 
    lda __conio+$d
    asl
    tax
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [333] gotoxy::$10 = gotoxy::y#22 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z y
    asl
    // [334] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwum1=pwuc1_derefidx_vbuaa_plus_vbuxx 
    tay
    txa
    clc
    adc __conio+$15,y
    sta __9
    lda __conio+$15+1,y
    adc #0
    sta __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [335] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwum1 
    lda __9
    sta __conio+$13
    lda __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [336] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [337] gotoxy::$6 = *((char *)&__conio+5) -- vbuaa=_deref_pbuc1 
    lda __conio+5
    jmp __b5
  .segment Data
    __9: .word 0
}
.segment Code
  // cputln
// Print a newline
cputln: {
    // __conio.cursor_x = 0
    // [338] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y++;
    // [339] *((char *)&__conio+$e) = ++ *((char *)&__conio+$e) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$e
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [340] cputln::$2 = *((char *)&__conio+$e) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    // [341] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [342] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [343] return 
    rts
}
  // cbm_x_charset
/**
 * @brief Sets the [character set](https://github.com/commanderx16/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-screen_set_charset).
 * 
 * @param charset The code of the charset to copy.
 * @param offset The offset of the character set in ram.
 */
// void cbm_x_charset(__zp($61) volatile char charset, __zp($5d) char * volatile offset)
cbm_x_charset: {
    .label charset = $61
    .label offset = $5d
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_CHRSET  }
    lda charset
    ldx.z <offset
    ldy.z >offset
    jsr CX16_CHRSET
    // cbm_x_charset::@return
    // }
    // [345] return 
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
    // [346] ((char *)&__conio+$f)[*((char *)&__conio)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio
    sta __conio+$f,y
    // scroll::@return
    // }
    // [347] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label line_text = $4b
    .label ch = $4b
    // unsigned int line_text = __conio.mapbase_offset
    // [348] clrscr::line_text#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z line_text
    lda __conio+1+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [349] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [350] clrscr::$0 = *((char *)&__conio+3) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [351] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [352] clrscr::l#0 = *((char *)&__conio+7) -- vbuyy=_deref_pbuc1 
    ldy __conio+7
    // [353] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [353] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [353] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [354] clrscr::$1 = byte0  clrscr::ch#0 -- vbuaa=_byte0_vwuz1 
    lda.z ch
    // *VERA_ADDRX_L = BYTE0(ch)
    // [355] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuaa 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [356] clrscr::$2 = byte1  clrscr::ch#0 -- vbuaa=_byte1_vwuz1 
    lda.z ch+1
    // *VERA_ADDRX_M = BYTE1(ch)
    // [357] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [358] clrscr::c#0 = *((char *)&__conio+6) -- vbuxx=_deref_pbuc1 
    ldx __conio+6
    // [359] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [359] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [360] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [361] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [362] clrscr::c#1 = -- clrscr::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [363] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [364] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+8
    sta.z line_text
    lda.z line_text+1
    adc __conio+8+1
    sta.z line_text+1
    // l--;
    // [365] clrscr::l#1 = -- clrscr::l#4 -- vbuyy=_dec_vbuyy 
    dey
    // while(l)
    // [366] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [367] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y = 0
    // [368] *((char *)&__conio+$e) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+$e
    // __conio.offset = __conio.mapbase_offset
    // [369] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+1) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+1
    sta __conio+$13
    lda __conio+1+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [370] return 
    rts
}
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [372] call textcolor
    // [305] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [305] phi textcolor::color#16 = WHITE [phi:frame_draw->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [373] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [374] call bgcolor
    // [310] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [375] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [376] call clrscr
    jsr clrscr
    // [377] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [377] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbum1=vbuc1 
    lda #0
    sta x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [378] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbum1_lt_vbuc1_then_la1 
    lda x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [379] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [380] call cputcxy
    // [933] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [933] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbuxx=vbuc1 
    ldx #0
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // [381] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [382] call cputcxy
    // [933] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [933] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbuxx=vbuc1 
    ldx #0
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // [383] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [384] call cputcxy
    // [933] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbuxx=vbuc1 
    ldx #1
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // [385] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [386] call cputcxy
    // [933] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbuxx=vbuc1 
    ldx #1
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // [387] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [387] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbum1=vbuc1 
    lda #0
    sta x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [388] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbum1_lt_vbuc1_then_la1 
    lda x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [389] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [390] call cputcxy
    // [933] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [933] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbuxx=vbuc1 
    ldx #2
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // [391] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [392] call cputcxy
    // [933] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [933] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbuxx=vbuc1 
    ldx #2
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // [393] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [394] call cputcxy
    // [933] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [933] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbuxx=vbuc1 
    ldx #2
    // [933] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$c
    jsr cputcxy
    // [395] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [395] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbum1=vbuc1 
    lda #3
    sta y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [396] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [397] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [397] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbum1=vbuc1 
    lda #0
    sta x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [398] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbum1_lt_vbuc1_then_la1 
    lda x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [399] cputcxy::y#13 = frame_draw::y#101 -- vbuxx=vbum1 
    ldx y
    // [400] call cputcxy
    // [933] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [933] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [401] cputcxy::y#14 = frame_draw::y#101 -- vbuxx=vbum1 
    ldx y
    // [402] call cputcxy
    // [933] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [933] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [403] cputcxy::y#15 = frame_draw::y#101 -- vbuxx=vbum1 
    ldx y
    // [404] call cputcxy
    // [933] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [933] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$c
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [405] frame_draw::y#5 = ++ frame_draw::y#101 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [406] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [406] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [407] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbum1_lt_vbuc1_then_la1 
    lda y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [408] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [408] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbum1=vbuc1 
    lda #0
    sta x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [409] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbum1_lt_vbuc1_then_la1 
    lda x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [410] cputcxy::y#19 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [411] call cputcxy
    // [933] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [933] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [412] cputcxy::y#20 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [413] call cputcxy
    // [933] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [933] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [414] cputcxy::y#21 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [415] call cputcxy
    // [933] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [933] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$a
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [416] cputcxy::y#22 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [417] call cputcxy
    // [933] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [933] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$14
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [418] cputcxy::y#23 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [419] call cputcxy
    // [933] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [933] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$1e
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [420] cputcxy::y#24 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [421] call cputcxy
    // [933] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [933] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$28
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [422] cputcxy::y#25 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [423] call cputcxy
    // [933] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [933] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$32
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [424] cputcxy::y#26 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [425] call cputcxy
    // [933] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [933] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$3c
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [426] cputcxy::y#27 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [427] call cputcxy
    // [933] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [933] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$46
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [428] cputcxy::y#28 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [429] call cputcxy
    // [933] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [933] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [430] frame_draw::y#7 = ++ frame_draw::y#102 -- vbum1=_inc_vbum2 
    lda y_1
    inc
    sta y_2
    // [431] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [431] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [432] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbum1_lt_vbuc1_then_la1 
    lda y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [433] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [433] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbum1=vbuc1 
    lda #0
    sta x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [434] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbum1_lt_vbuc1_then_la1 
    lda x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [435] cputcxy::y#39 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [436] call cputcxy
    // [933] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [933] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [437] cputcxy::y#40 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [438] call cputcxy
    // [933] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [933] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [439] cputcxy::y#41 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [440] call cputcxy
    // [933] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [933] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$a
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [441] cputcxy::y#42 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [442] call cputcxy
    // [933] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [933] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$14
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [443] cputcxy::y#43 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [444] call cputcxy
    // [933] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [933] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$1e
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [445] cputcxy::y#44 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [446] call cputcxy
    // [933] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [933] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$28
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [447] cputcxy::y#45 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [448] call cputcxy
    // [933] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [933] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$32
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [449] cputcxy::y#46 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [450] call cputcxy
    // [933] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [933] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$3c
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [451] cputcxy::y#47 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [452] call cputcxy
    // [933] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [933] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$46
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [453] frame_draw::y#9 = ++ frame_draw::y#104 -- vbum1=_inc_vbum2 
    lda y_2
    inc
    sta y_3
    // [454] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [454] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [455] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbum1_lt_vbuc1_then_la1 
    lda y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [456] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [456] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbum1=vbuc1 
    lda #0
    sta x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [457] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbum1_lt_vbuc1_then_la1 
    lda x5
    cmp #$4f
    bcc __b25
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [458] cputcxy::y#58 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [459] call cputcxy
    // [933] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [933] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [460] cputcxy::y#59 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [461] call cputcxy
    // [933] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [933] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [462] cputcxy::y#60 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [463] call cputcxy
    // [933] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [933] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$a
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [464] cputcxy::y#61 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [465] call cputcxy
    // [933] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [933] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$14
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [466] cputcxy::y#62 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [467] call cputcxy
    // [933] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [933] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$1e
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [468] cputcxy::y#63 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [469] call cputcxy
    // [933] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [933] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$28
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [470] cputcxy::y#64 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [471] call cputcxy
    // [933] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [933] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$32
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [472] cputcxy::y#65 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [473] call cputcxy
    // [933] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [933] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$3c
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [474] cputcxy::y#66 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [475] call cputcxy
    // [933] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [933] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$46
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [476] cputcxy::y#67 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [477] call cputcxy
    // [933] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [933] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@return
    // }
    // [478] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [479] cputcxy::x#57 = frame_draw::x5#2 -- vbuyy=vbum1 
    ldy x5
    // [480] cputcxy::y#57 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [481] call cputcxy
    // [933] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [933] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [482] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbum1=_inc_vbum1 
    inc x5
    // [456] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [456] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [483] cputcxy::y#48 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [484] call cputcxy
    // [933] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [485] cputcxy::y#49 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [486] call cputcxy
    // [933] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [487] cputcxy::y#50 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [488] call cputcxy
    // [933] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$a
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [489] cputcxy::y#51 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [490] call cputcxy
    // [933] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$14
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [491] cputcxy::y#52 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [492] call cputcxy
    // [933] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$1e
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [493] cputcxy::y#53 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [494] call cputcxy
    // [933] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$28
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [495] cputcxy::y#54 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [496] call cputcxy
    // [933] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$32
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [497] cputcxy::y#55 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [498] call cputcxy
    // [933] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$3c
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [499] cputcxy::y#56 = frame_draw::y#106 -- vbuxx=vbum1 
    ldx y_3
    // [500] call cputcxy
    // [933] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$46
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [501] frame_draw::y#10 = ++ frame_draw::y#106 -- vbum1=_inc_vbum1 
    inc y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [502] cputcxy::x#38 = frame_draw::x4#2 -- vbuyy=vbum1 
    ldy x4
    // [503] cputcxy::y#38 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [504] call cputcxy
    // [933] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [933] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [505] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbum1=_inc_vbum1 
    inc x4
    // [433] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [433] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [506] cputcxy::y#29 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [507] call cputcxy
    // [933] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [508] cputcxy::y#30 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [509] call cputcxy
    // [933] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [510] cputcxy::y#31 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [511] call cputcxy
    // [933] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$a
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [512] cputcxy::y#32 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [513] call cputcxy
    // [933] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$14
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [514] cputcxy::y#33 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [515] call cputcxy
    // [933] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$1e
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [516] cputcxy::y#34 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [517] call cputcxy
    // [933] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$28
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [518] cputcxy::y#35 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [519] call cputcxy
    // [933] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$32
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [520] cputcxy::y#36 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [521] call cputcxy
    // [933] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$3c
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [522] cputcxy::y#37 = frame_draw::y#104 -- vbuxx=vbum1 
    ldx y_2
    // [523] call cputcxy
    // [933] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$46
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [524] frame_draw::y#8 = ++ frame_draw::y#104 -- vbum1=_inc_vbum1 
    inc y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [525] cputcxy::x#18 = frame_draw::x3#2 -- vbuyy=vbum1 
    ldy x3
    // [526] cputcxy::y#18 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [527] call cputcxy
    // [933] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [933] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [528] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbum1=_inc_vbum1 
    inc x3
    // [408] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [408] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [529] cputcxy::y#16 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [530] call cputcxy
    // [933] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [531] cputcxy::y#17 = frame_draw::y#102 -- vbuxx=vbum1 
    ldx y_1
    // [532] call cputcxy
    // [933] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [533] frame_draw::y#6 = ++ frame_draw::y#102 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [534] cputcxy::x#12 = frame_draw::x2#2 -- vbuyy=vbum1 
    ldy x2
    // [535] cputcxy::y#12 = frame_draw::y#101 -- vbuxx=vbum1 
    ldx y
    // [536] call cputcxy
    // [933] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [933] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [537] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbum1=_inc_vbum1 
    inc x2
    // [397] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [397] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [538] cputcxy::y#9 = frame_draw::y#101 -- vbuxx=vbum1 
    ldx y
    // [539] call cputcxy
    // [933] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbuyy=vbuc1 
    ldy #0
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [540] cputcxy::y#10 = frame_draw::y#101 -- vbuxx=vbum1 
    ldx y
    // [541] call cputcxy
    // [933] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$c
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [542] cputcxy::y#11 = frame_draw::y#101 -- vbuxx=vbum1 
    ldx y
    // [543] call cputcxy
    // [933] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [933] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [933] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbuyy=vbuc1 
    ldy #$4f
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [544] frame_draw::y#4 = ++ frame_draw::y#101 -- vbum1=_inc_vbum1 
    inc y
    // [395] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [395] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [545] cputcxy::x#5 = frame_draw::x1#2 -- vbuyy=vbum1 
    ldy x1
    // [546] call cputcxy
    // [933] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [933] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbuxx=vbuc1 
    ldx #2
    // [933] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [547] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbum1=_inc_vbum1 
    inc x1
    // [387] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [387] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [548] cputcxy::x#0 = frame_draw::x#2 -- vbuyy=vbum1 
    ldy x
    // [549] call cputcxy
    // [933] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [933] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [933] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbuxx=vbuc1 
    ldx #0
    // [933] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [550] frame_draw::x#1 = ++ frame_draw::x#2 -- vbum1=_inc_vbum1 
    inc x
    // [377] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [377] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    x: .byte 0
    x1: .byte 0
    y: .byte 0
    x2: .byte 0
    y_1: .byte 0
    x3: .byte 0
    y_2: .byte 0
    x4: .byte 0
    y_3: .byte 0
    x5: .byte 0
}
.segment Code
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($4b) void (*putc)(char), __zp($3e) const char *s)
printf_str: {
    .label s = $3e
    .label putc = $4b
    // [552] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [552] phi printf_str::s#9 = printf_str::s#10 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [553] printf_str::c#1 = *printf_str::s#9 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [554] printf_str::s#0 = ++ printf_str::s#9 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [555] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // printf_str::@return
    // }
    // [556] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [557] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [558] callexecute *printf_str::putc#10  -- call__deref_pprz1 
    jsr icall4
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall4:
    jmp (putc)
}
  // wait_key
// Some addressing constants.
// The different device IDs that can be returned from the manufacturer ID read sequence.
// To print the graphics on the vera.
wait_key: {
    .const bank_set_bram1_bank = 0
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [561] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [562] phi from wait_key::bank_set_bram1 to wait_key::@2 [phi:wait_key::bank_set_bram1->wait_key::@2]
    // wait_key::@2
    // bank_set_brom(4)
    // [563] call bank_set_brom
    // [576] phi from wait_key::@2 to bank_set_brom [phi:wait_key::@2->bank_set_brom]
    // [576] phi bank_set_brom::bank#8 = 4 [phi:wait_key::@2->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #4
    jsr bank_set_brom
    // [564] phi from wait_key::@2 wait_key::@3 to wait_key::@1 [phi:wait_key::@2/wait_key::@3->wait_key::@1]
    // wait_key::@1
  __b1:
    // getin()
    // [565] call getin
    jsr getin
    // [566] getin::return#2 = getin::return#1
    // wait_key::@3
    // [567] wait_key::return#0 = getin::return#2
    // while (!(ch = getin()))
    // [568] if(0==wait_key::return#0) goto wait_key::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // wait_key::@return
    // }
    // [569] return 
    rts
}
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [571] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [572] phi from system_reset::bank_set_bram1 to system_reset::@1 [phi:system_reset::bank_set_bram1->system_reset::@1]
    // system_reset::@1
    // bank_set_brom(0)
    // [573] call bank_set_brom
    // [576] phi from system_reset::@1 to bank_set_brom [phi:system_reset::@1->bank_set_brom]
    // [576] phi bank_set_brom::bank#8 = 0 [phi:system_reset::@1->bank_set_brom#0] -- vbuaa=vbuc1 
    lda #0
    jsr bank_set_brom
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [575] return 
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
    // [577] BROM = bank_set_brom::bank#8 -- vbuz1=vbuaa 
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [578] return 
    rts
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [579] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [580] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [581] __snprintf_buffer = main::file -- pbuz1=pbuc1 
    lda #<main.file
    sta.z __snprintf_buffer
    lda #>main.file
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [582] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($45) void (*putc)(char), __register(X) char uvalue, __zp($4f) char format_min_length, char format_justify_left, char format_sign_always, __zp($4e) char format_zero_padding, char format_upper_case, __register(Y) char format_radix)
printf_uchar: {
    .label putc = $45
    .label format_min_length = $4f
    .label format_zero_padding = $4e
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [584] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [585] uctoa::value#1 = printf_uchar::uvalue#3
    // [586] uctoa::radix#0 = printf_uchar::format_radix#3
    // [587] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [588] printf_number_buffer::putc#1 = printf_uchar::putc#3
    // [589] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [590] printf_number_buffer::format_min_length#1 = printf_uchar::format_min_length#3 -- vbuxx=vbuz1 
    ldx.z format_min_length
    // [591] printf_number_buffer::format_zero_padding#1 = printf_uchar::format_zero_padding#3
    // [592] call printf_number_buffer
  // Print using format
    // [974] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [974] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [974] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [974] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [974] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [974] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [974] phi printf_number_buffer::format_min_length#2 = printf_number_buffer::format_min_length#1 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [593] return 
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
// __zp($4b) struct $1 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label fp = $4b
    .label return = $4b
    // FILE *fp = &__files[__filecount]
    // [594] fopen::$32 = __filecount << 2 -- vbuaa=vbum1_rol_2 
    lda __filecount
    asl
    asl
    // [595] fopen::$33 = fopen::$32 + __filecount -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc __filecount
    // [596] fopen::$11 = fopen::$33 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [597] fopen::fp#0 = __files + fopen::$11 -- pssz1=pssc1_plus_vbuaa 
    clc
    adc #<__files
    sta.z fp
    lda #>__files
    adc #0
    sta.z fp+1
    // fp->status = 0
    // [598] ((char *)fopen::fp#0)[$13] = 0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #0
    ldy #$13
    sta (fp),y
    // fp->channel = channel
    // [599] ((char *)fopen::fp#0)[$10] = fopen::channel#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #channel
    ldy #$10
    sta (fp),y
    // fp->device = device
    // [600] ((char *)fopen::fp#0)[$11] = fopen::device#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #device
    ldy #$11
    sta (fp),y
    // fp->secondary = secondary
    // [601] ((char *)fopen::fp#0)[$12] = fopen::secondary#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #secondary
    ldy #$12
    sta (fp),y
    // strncpy(fp->filename, filename, 16)
    // [602] strncpy::dst#1 = (char *)fopen::fp#0 -- pbuz1=pbuz2 
    lda.z fp
    sta.z strncpy.dst
    lda.z fp+1
    sta.z strncpy.dst+1
    // [603] call strncpy
    // [1015] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@5
    // cbm_k_setnam(filename)
    // [604] cbm_k_setnam::filename = main::file -- pbuz1=pbuc1 
    lda #<main.file
    sta.z cbm_k_setnam.filename
    lda #>main.file
    sta.z cbm_k_setnam.filename+1
    // [605] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@6
    // cbm_k_setlfs(channel, device, secondary)
    // [606] cbm_k_setlfs::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_setlfs.channel
    // [607] cbm_k_setlfs::device = fopen::device#0 -- vbuz1=vbuc1 
    lda #device
    sta.z cbm_k_setlfs.device
    // [608] cbm_k_setlfs::command = fopen::secondary#0 -- vbuz1=vbuc1 
    lda #secondary
    sta.z cbm_k_setlfs.command
    // [609] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [610] phi from fopen::@6 to fopen::@7 [phi:fopen::@6->fopen::@7]
    // fopen::@7
    // cbm_k_open()
    // [611] call cbm_k_open
    jsr cbm_k_open
    // [612] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@8
    // [613] fopen::$4 = cbm_k_open::return#2
    // fp->status = cbm_k_open()
    // [614] ((char *)fopen::fp#0)[$13] = fopen::$4 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [615] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // fopen::@3
    // cbm_k_close(channel)
    // [616] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [617] call cbm_k_close
    jsr cbm_k_close
    // [618] phi from fopen::@3 fopen::@4 to fopen::@return [phi:fopen::@3/fopen::@4->fopen::@return]
  __b3:
    // [618] phi fopen::return#1 = 0 [phi:fopen::@3/fopen::@4->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [619] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [620] cbm_k_chkin::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_chkin.channel
    // [621] call cbm_k_chkin
    jsr cbm_k_chkin
    // [622] phi from fopen::@1 to fopen::@9 [phi:fopen::@1->fopen::@9]
    // fopen::@9
    // cbm_k_readst()
    // [623] call cbm_k_readst
    jsr cbm_k_readst
    // [624] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@10
    // [625] fopen::$7 = cbm_k_readst::return#2
    // fp->status = cbm_k_readst()
    // [626] ((char *)fopen::fp#0)[$13] = fopen::$7 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if (fp->status)
    // [627] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@2 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b2
    // fopen::@4
    // cbm_k_close(channel)
    // [628] cbm_k_close::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_close.channel
    // [629] call cbm_k_close
    jsr cbm_k_close
    jmp __b3
    // fopen::@2
  __b2:
    // __filecount++;
    // [630] __filecount = ++ __filecount -- vbum1=_inc_vbum1 
    inc __filecount
    // [618] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [618] phi fopen::return#1 = fopen::fp#0 [phi:fopen::@2->fopen::@return#0] -- register_copy 
    rts
}
  // print_chip_led
// void print_chip_led(__register(X) char r, __mem() char tc, char bc)
print_chip_led: {
    // r * 10
    // [632] print_chip_led::$8 = print_chip_led::r#11 << 2 -- vbuaa=vbuxx_rol_2 
    txa
    asl
    asl
    // [633] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#11 -- vbuaa=vbuaa_plus_vbuxx 
    stx.z $ff
    clc
    adc.z $ff
    // [634] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // gotoxy(4 + r * 10, 43)
    // [635] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbuyy=vbuc1_plus_vbuaa 
    clc
    adc #4
    tay
    // [636] call gotoxy
    // [323] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [323] phi gotoxy::y#22 = $2b [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #$2b
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [637] textcolor::color#7 = print_chip_led::tc#11 -- vbuxx=vbum1 
    ldx tc
    // [638] call textcolor
    // [305] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [305] phi textcolor::color#16 = textcolor::color#7 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [639] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [640] call bgcolor
    // [310] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [641] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [642] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [644] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [645] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [647] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [648] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [650] return 
    rts
  .segment Data
    tc: .byte 0
}
.segment Code
  // table_chip_clear
// void table_chip_clear(__mem() char rom_bank)
table_chip_clear: {
    // textcolor(WHITE)
    // [652] call textcolor
    // [305] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [305] phi textcolor::color#16 = WHITE [phi:table_chip_clear->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [653] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [654] call bgcolor
    // [310] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [655] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [655] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [655] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbum1=vbuc1 
    lda #4
    sta y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [656] if(table_chip_clear::y#10<$24) goto table_chip_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #$24
    bcc __b2
    // table_chip_clear::@return
    // }
    // [657] return 
    rts
    // table_chip_clear::@2
  __b2:
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [658] rom_address::rom_bank#3 = table_chip_clear::rom_bank#11 -- vbuaa=vbum1 
    lda rom_bank
    // [659] call rom_address
    // [1053] phi from table_chip_clear::@2 to rom_address [phi:table_chip_clear::@2->rom_address]
    // [1053] phi rom_address::rom_bank#4 = rom_address::rom_bank#3 [phi:table_chip_clear::@2->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [660] rom_address::return#10 = rom_address::return#0
    // table_chip_clear::@4
    // [661] table_chip_clear::flash_rom_address#0 = rom_address::return#10
    // gotoxy(2, y)
    // [662] gotoxy::y#10 = table_chip_clear::y#10 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [663] call gotoxy
    // [323] phi from table_chip_clear::@4 to gotoxy [phi:table_chip_clear::@4->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#10 [phi:table_chip_clear::@4->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = 2 [phi:table_chip_clear::@4->gotoxy#1] -- vbuyy=vbuc1 
    ldy #2
    jsr gotoxy
    // table_chip_clear::@5
    // printf("%02x", rom_bank)
    // [664] printf_uchar::uvalue#0 = table_chip_clear::rom_bank#11 -- vbuxx=vbum1 
    ldx rom_bank
    // [665] call printf_uchar
    // [583] phi from table_chip_clear::@5 to printf_uchar [phi:table_chip_clear::@5->printf_uchar]
    // [583] phi printf_uchar::format_zero_padding#3 = 1 [phi:table_chip_clear::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [583] phi printf_uchar::format_min_length#3 = 2 [phi:table_chip_clear::@5->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [583] phi printf_uchar::putc#3 = &cputc [phi:table_chip_clear::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [583] phi printf_uchar::format_radix#3 = HEXADECIMAL [phi:table_chip_clear::@5->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [583] phi printf_uchar::uvalue#3 = printf_uchar::uvalue#0 [phi:table_chip_clear::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@6
    // gotoxy(5, y)
    // [666] gotoxy::y#11 = table_chip_clear::y#10 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [667] call gotoxy
    // [323] phi from table_chip_clear::@6 to gotoxy [phi:table_chip_clear::@6->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#11 [phi:table_chip_clear::@6->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = 5 [phi:table_chip_clear::@6->gotoxy#1] -- vbuyy=vbuc1 
    ldy #5
    jsr gotoxy
    // table_chip_clear::@7
    // printf("%06x", flash_rom_address)
    // [668] printf_ulong::uvalue#0 = table_chip_clear::flash_rom_address#0 -- vduz1=vdum2 
    lda flash_rom_address
    sta.z printf_ulong.uvalue
    lda flash_rom_address+1
    sta.z printf_ulong.uvalue+1
    lda flash_rom_address+2
    sta.z printf_ulong.uvalue+2
    lda flash_rom_address+3
    sta.z printf_ulong.uvalue+3
    // [669] call printf_ulong
    // [1057] phi from table_chip_clear::@7 to printf_ulong [phi:table_chip_clear::@7->printf_ulong]
    jsr printf_ulong
    // table_chip_clear::@8
    // gotoxy(14, y)
    // [670] gotoxy::y#12 = table_chip_clear::y#10 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [671] call gotoxy
    // [323] phi from table_chip_clear::@8 to gotoxy [phi:table_chip_clear::@8->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#12 [phi:table_chip_clear::@8->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = $e [phi:table_chip_clear::@8->gotoxy#1] -- vbuyy=vbuc1 
    ldy #$e
    jsr gotoxy
    // [672] phi from table_chip_clear::@8 to table_chip_clear::@9 [phi:table_chip_clear::@8->table_chip_clear::@9]
    // table_chip_clear::@9
    // printf("%64s", " ")
    // [673] call printf_string
    // [676] phi from table_chip_clear::@9 to printf_string [phi:table_chip_clear::@9->printf_string]
    // [676] phi printf_string::str#10 = table_chip_clear::str [phi:table_chip_clear::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [676] phi printf_string::format_min_length#3 = $40 [phi:table_chip_clear::@9->printf_string#1] -- vbuz1=vbuc1 
    lda #$40
    sta.z printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@10
    // rom_bank++;
    // [674] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#11 -- vbum1=_inc_vbum1 
    inc rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [675] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbum1=_inc_vbum1 
    inc y
    // [655] phi from table_chip_clear::@10 to table_chip_clear::@1 [phi:table_chip_clear::@10->table_chip_clear::@1]
    // [655] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@10->table_chip_clear::@1#0] -- register_copy 
    // [655] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@10->table_chip_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    str: .text " "
    .byte 0
    .label flash_rom_address = rom_address.return
    rom_bank: .byte 0
    y: .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($3e) char *str, __zp($4f) char format_min_length, char format_justify_left)
printf_string: {
    .label str = $3e
    .label format_min_length = $4f
    // if(format.min_length)
    // [677] if(0==printf_string::format_min_length#3) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b1
    // printf_string::@3
    // strlen(str)
    // [678] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [679] call strlen
    // [1064] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1064] phi strlen::str#6 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [680] strlen::return#4 = strlen::len#2
    // printf_string::@5
    // [681] printf_string::$9 = strlen::return#4 -- vwum1=vwuz2 
    lda.z strlen.return
    sta __9
    lda.z strlen.return+1
    sta __9+1
    // signed char len = (signed char)strlen(str)
    // [682] printf_string::len#0 = (signed char)printf_string::$9 -- vbsaa=_sbyte_vwum1 
    lda __9
    // padding = (signed char)format.min_length  - len
    // [683] printf_string::padding#1 = (signed char)printf_string::format_min_length#3 - printf_string::len#0 -- vbsaa=vbsz1_minus_vbsaa 
    eor #$ff
    sec
    adc.z format_min_length
    // if(padding<0)
    // [684] if(printf_string::padding#1>=0) goto printf_string::@7 -- vbsaa_ge_0_then_la1 
    cmp #0
    bpl __b6
    // [686] phi from printf_string printf_string::@5 to printf_string::@1 [phi:printf_string/printf_string::@5->printf_string::@1]
  __b1:
    // [686] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@5->printf_string::@1#0] -- vbsaa=vbsc1 
    lda #0
    // [685] phi from printf_string::@5 to printf_string::@7 [phi:printf_string::@5->printf_string::@7]
    // printf_string::@7
    // [686] phi from printf_string::@7 to printf_string::@1 [phi:printf_string::@7->printf_string::@1]
    // [686] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@7->printf_string::@1#0] -- register_copy 
    // printf_string::@1
    // printf_string::@6
  __b6:
    // if(!format.justify_left && padding)
    // [687] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsaa_then_la1 
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [688] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuaa 
    sta.z printf_padding.length
    // [689] call printf_padding
    // [1070] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1070] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1070] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1070] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [690] printf_str::s#2 = printf_string::str#10
    // [691] call printf_str
    // [551] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [551] phi printf_str::putc#10 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [551] phi printf_str::s#10 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@return
    // }
    // [692] return 
    rts
  .segment Data
    __9: .word 0
}
.segment Code
  // flash_read
// __mem() unsigned long flash_read(__zp($3e) struct $1 *fp, __zp($45) char *flash_ram_address, __mem() char rom_bank_start, __register(X) char rom_bank_size)
flash_read: {
    .label flash_ram_address = $45
    .label fp = $3e
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [694] rom_address::rom_bank#0 = flash_read::rom_bank_start#11 -- vbuaa=vbum1 
    lda rom_bank_start
    // [695] call rom_address
    // [1053] phi from flash_read to rom_address [phi:flash_read->rom_address]
    // [1053] phi rom_address::rom_bank#4 = rom_address::rom_bank#0 [phi:flash_read->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [696] rom_address::return#2 = rom_address::return#0 -- vdum1=vdum2 
    lda rom_address.return
    sta rom_address.return_1
    lda rom_address.return+1
    sta rom_address.return_1+1
    lda rom_address.return+2
    sta rom_address.return_1+2
    lda rom_address.return+3
    sta rom_address.return_1+3
    // flash_read::@9
    // [697] flash_read::flash_rom_address#0 = rom_address::return#2
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [698] rom_size::rom_banks#0 = flash_read::rom_bank_size#2 -- vbuaa=vbuxx 
    txa
    // [699] call rom_size
    // [728] phi from flash_read::@9 to rom_size [phi:flash_read::@9->rom_size]
    // [728] phi rom_size::rom_banks#2 = rom_size::rom_banks#0 [phi:flash_read::@9->rom_size#0] -- register_copy 
    jsr rom_size
    // unsigned long flash_size = rom_size(rom_bank_size)
    // [700] rom_size::return#2 = rom_size::return#0
    // flash_read::@10
    // [701] flash_read::flash_size#0 = rom_size::return#2
    // [702] phi from flash_read::@10 to flash_read::@1 [phi:flash_read::@10->flash_read::@1]
    // [702] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@10->flash_read::@1#0] -- register_copy 
    // [702] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@10->flash_read::@1#1] -- register_copy 
    // [702] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#0 [phi:flash_read::@10->flash_read::@1#2] -- register_copy 
    // [702] phi flash_read::return#2 = 0 [phi:flash_read::@10->flash_read::@1#3] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [702] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [702] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [702] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [702] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [702] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < flash_size)
    // [703] if(flash_read::return#2<flash_read::flash_size#0) goto flash_read::@2 -- vdum1_lt_vdum2_then_la1 
    lda return+3
    cmp flash_size+3
    bcc __b2
    bne !+
    lda return+2
    cmp flash_size+2
    bcc __b2
    bne !+
    lda return+1
    cmp flash_size+1
    bcc __b2
    bne !+
    lda return
    cmp flash_size
    bcc __b2
  !:
    // flash_read::@return
    // }
    // [704] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [705] flash_read::$3 = flash_read::flash_rom_address#10 & $4000-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address
    and #<$4000-1
    sta __3
    lda flash_rom_address+1
    and #>$4000-1
    sta __3+1
    lda flash_rom_address+2
    and #<$4000-1>>$10
    sta __3+2
    lda flash_rom_address+3
    and #>$4000-1>>$10
    sta __3+3
    // if (!(flash_rom_address % 0x04000))
    // [706] if(0!=flash_read::$3) goto flash_read::@3 -- 0_neq_vdum1_then_la1 
    lda __3
    ora __3+1
    ora __3+2
    ora __3+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [707] flash_read::$6 = flash_read::rom_bank_start#4 & $20-1 -- vbuaa=vbum1_band_vbuc1 
    lda #$20-1
    and rom_bank_start
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [708] gotoxy::y#7 = 4 + flash_read::$6 -- vbuz1=vbuc1_plus_vbuaa 
    clc
    adc #4
    sta.z gotoxy.y
    // [709] call gotoxy
    // [323] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#7 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = $e [phi:flash_read::@6->gotoxy#1] -- vbuyy=vbuc1 
    ldy #$e
    jsr gotoxy
    // flash_read::@12
    // rom_bank_start++;
    // [710] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbum1=_inc_vbum1 
    inc rom_bank_start
    // [711] phi from flash_read::@12 flash_read::@2 to flash_read::@3 [phi:flash_read::@12/flash_read::@2->flash_read::@3]
    // [711] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@12/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [712] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [713] fgets::fp#0 = flash_read::fp#10 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [714] call fgets
    jsr fgets
    // [715] fgets::return#5 = fgets::return#1
    // flash_read::@11
    // [716] flash_read::read_bytes#0 = fgets::return#5 -- vwum1=vwuz2 
    lda.z fgets.return
    sta read_bytes
    lda.z fgets.return+1
    sta read_bytes+1
    // if (!read_bytes)
    // [717] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwum1_then_la1 
    lda read_bytes
    ora read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [718] flash_read::$12 = flash_read::flash_rom_address#10 & $100-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address
    and #<$100-1
    sta __12
    lda flash_rom_address+1
    and #>$100-1
    sta __12+1
    lda flash_rom_address+2
    and #<$100-1>>$10
    sta __12+2
    lda flash_rom_address+3
    and #>$100-1>>$10
    sta __12+3
    // if (!(flash_rom_address % 0x100))
    // [719] if(0!=flash_read::$12) goto flash_read::@5 -- 0_neq_vdum1_then_la1 
    lda __12
    ora __12+1
    ora __12+2
    ora __12+3
    bne __b5
    // flash_read::@7
    // cputc(0xE0)
    // [720] stackpush(char) = $e0 -- _stackpushbyte_=vbuc1 
    lda #$e0
    pha
    // [721] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [723] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z flash_ram_address
    adc read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [724] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vdum1=vdum1_plus_vwum2 
    lda flash_rom_address
    clc
    adc read_bytes
    sta flash_rom_address
    lda flash_rom_address+1
    adc read_bytes+1
    sta flash_rom_address+1
    lda flash_rom_address+2
    adc #0
    sta flash_rom_address+2
    lda flash_rom_address+3
    adc #0
    sta flash_rom_address+3
    // flash_bytes += read_bytes
    // [725] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vdum1=vdum1_plus_vwum2 
    lda flash_bytes
    clc
    adc read_bytes
    sta flash_bytes
    lda flash_bytes+1
    adc read_bytes+1
    sta flash_bytes+1
    lda flash_bytes+2
    adc #0
    sta flash_bytes+2
    lda flash_bytes+3
    adc #0
    sta flash_bytes+3
    // if (flash_ram_address >= 0xC000)
    // [726] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // [727] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z flash_ram_address
    sec
    sbc #<$2000
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    sbc #>$2000
    sta.z flash_ram_address+1
    jmp __b1
  .segment Data
    __3: .dword 0
    __12: .dword 0
    flash_rom_address: .dword 0
    .label flash_size = rom_size.return
    read_bytes: .word 0
    rom_bank_start: .byte 0
    return: .dword 0
    .label flash_bytes = return
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
    // [729] rom_size::$1 = (unsigned long)rom_size::rom_banks#2 -- vdum1=_dword_vbuaa 
    sta __1
    lda #0
    sta __1+1
    sta __1+2
    sta __1+3
    // [730] rom_size::return#0 = rom_size::$1 << $e -- vdum1=vdum1_rol_vbuc1 
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
    // [731] return 
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
// int fclose(__zp($5b) struct $1 *fp)
fclose: {
    .label fp = $5b
    // cbm_k_close(fp->channel)
    // [732] cbm_k_close::channel = ((char *)fclose::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_close.channel
    // [733] call cbm_k_close
    jsr cbm_k_close
    // [734] cbm_k_close::return#4 = cbm_k_close::return#1
    // fclose::@2
    // [735] fclose::$0 = cbm_k_close::return#4
    // fp->status = cbm_k_close(fp->channel)
    // [736] ((char *)fclose::fp#0)[$13] = fclose::$0 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [737] if(0==((char *)fclose::fp#0)[$13]) goto fclose::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [738] return 
    rts
    // [739] phi from fclose::@2 to fclose::@1 [phi:fclose::@2->fclose::@1]
    // fclose::@1
  __b1:
    // cbm_k_clrchn()
    // [740] call cbm_k_clrchn
    jsr cbm_k_clrchn
    // fclose::@3
    // __filecount--;
    // [741] __filecount = -- __filecount -- vbum1=_dec_vbum1 
    dec __filecount
    rts
}
  // flash_write
// __mem() unsigned long flash_write(__zp($4b) char *flash_ram_address, __mem() char rom_bank_start, __mem() unsigned long flash_size)
flash_write: {
    .label flash_ram_address = $4b
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [743] rom_address::rom_bank#1 = flash_write::rom_bank_start#10 -- vbuaa=vbum1 
    lda rom_bank_start
    // [744] call rom_address
    // [1053] phi from flash_write to rom_address [phi:flash_write->rom_address]
    // [1053] phi rom_address::rom_bank#4 = rom_address::rom_bank#1 [phi:flash_write->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [745] rom_address::return#3 = rom_address::return#0 -- vdum1=vdum2 
    lda rom_address.return
    sta rom_address.return_2
    lda rom_address.return+1
    sta rom_address.return_2+1
    lda rom_address.return+2
    sta rom_address.return_2+2
    lda rom_address.return+3
    sta rom_address.return_2+3
    // flash_write::@15
    // [746] flash_write::flash_rom_address#0 = rom_address::return#3
    // [747] phi from flash_write::@15 to flash_write::@1 [phi:flash_write::@15->flash_write::@1]
    // [747] phi flash_write::flash_ram_address#12 = flash_write::flash_ram_address#24 [phi:flash_write::@15->flash_write::@1#0] -- register_copy 
    // [747] phi flash_write::rom_bank_start#4 = flash_write::rom_bank_start#10 [phi:flash_write::@15->flash_write::@1#1] -- register_copy 
    // [747] phi flash_write::flash_rom_address#12 = flash_write::flash_rom_address#0 [phi:flash_write::@15->flash_write::@1#2] -- register_copy 
    // [747] phi flash_write::flashed_bytes#11 = 0 [phi:flash_write::@15->flash_write::@1#3] -- vdum1=vduc1 
    lda #<0
    sta flashed_bytes
    sta flashed_bytes+1
    lda #<0>>$10
    sta flashed_bytes+2
    lda #>0>>$10
    sta flashed_bytes+3
  /// Holds the amount of bytes actually flashed in the ROM.
    // [747] phi from flash_write::@13 flash_write::@9 to flash_write::@1 [phi:flash_write::@13/flash_write::@9->flash_write::@1]
    // [747] phi flash_write::flash_ram_address#12 = flash_write::flash_ram_address#2 [phi:flash_write::@13/flash_write::@9->flash_write::@1#0] -- register_copy 
    // [747] phi flash_write::rom_bank_start#4 = flash_write::rom_bank_start#15 [phi:flash_write::@13/flash_write::@9->flash_write::@1#1] -- register_copy 
    // [747] phi flash_write::flash_rom_address#12 = flash_write::flash_rom_address#10 [phi:flash_write::@13/flash_write::@9->flash_write::@1#2] -- register_copy 
    // [747] phi flash_write::flashed_bytes#11 = flash_write::flashed_bytes#10 [phi:flash_write::@13/flash_write::@9->flash_write::@1#3] -- register_copy 
    // flash_write::@1
  __b1:
    // while (flashed_bytes < flash_size)
    // [748] if(flash_write::flashed_bytes#11<flash_write::flash_size#5) goto flash_write::@2 -- vdum1_lt_vdum2_then_la1 
    lda flashed_bytes+3
    cmp flash_size+3
    bcc __b2
    bne !+
    lda flashed_bytes+2
    cmp flash_size+2
    bcc __b2
    bne !+
    lda flashed_bytes+1
    cmp flash_size+1
    bcc __b2
    bne !+
    lda flashed_bytes
    cmp flash_size
    bcc __b2
  !:
    // flash_write::@return
    // }
    // [749] return 
    rts
    // flash_write::@2
  __b2:
    // flash_rom_address % 0x04000
    // [750] flash_write::$2 = flash_write::flash_rom_address#12 & $4000-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address
    and #<$4000-1
    sta __2
    lda flash_rom_address+1
    and #>$4000-1
    sta __2+1
    lda flash_rom_address+2
    and #<$4000-1>>$10
    sta __2+2
    lda flash_rom_address+3
    and #>$4000-1>>$10
    sta __2+3
    // if (!(flash_rom_address % 0x04000))
    // [751] if(0!=flash_write::$2) goto flash_write::@3 -- 0_neq_vdum1_then_la1 
    lda __2
    ora __2+1
    ora __2+2
    ora __2+3
    bne __b3
    // flash_write::@10
    // rom_bank_start % 32
    // [752] flash_write::$5 = flash_write::rom_bank_start#4 & $20-1 -- vbuaa=vbum1_band_vbuc1 
    lda #$20-1
    and rom_bank_start
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [753] gotoxy::y#8 = 4 + flash_write::$5 -- vbuz1=vbuc1_plus_vbuaa 
    clc
    adc #4
    sta.z gotoxy.y
    // [754] call gotoxy
    // [323] phi from flash_write::@10 to gotoxy [phi:flash_write::@10->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#8 [phi:flash_write::@10->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = $e [phi:flash_write::@10->gotoxy#1] -- vbuyy=vbuc1 
    ldy #$e
    jsr gotoxy
    // flash_write::@16
    // rom_bank_start++;
    // [755] flash_write::rom_bank_start#0 = ++ flash_write::rom_bank_start#4 -- vbum1=_inc_vbum1 
    inc rom_bank_start
    // [756] phi from flash_write::@16 flash_write::@2 to flash_write::@3 [phi:flash_write::@16/flash_write::@2->flash_write::@3]
    // [756] phi flash_write::rom_bank_start#15 = flash_write::rom_bank_start#0 [phi:flash_write::@16/flash_write::@2->flash_write::@3#0] -- register_copy 
    // flash_write::@3
  __b3:
    // flash_rom_address % 0x100
    // [757] flash_write::$8 = flash_write::flash_rom_address#12 & $100-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address
    and #<$100-1
    sta __8
    lda flash_rom_address+1
    and #>$100-1
    sta __8+1
    lda flash_rom_address+2
    and #<$100-1>>$10
    sta __8+2
    lda flash_rom_address+3
    and #>$100-1>>$10
    sta __8+3
    // if (!(flash_rom_address % 0x100))
    // [758] if(0!=flash_write::$8) goto flash_write::@4 -- 0_neq_vdum1_then_la1 
    lda __8
    ora __8+1
    ora __8+2
    ora __8+3
    bne __b4
    // flash_write::@11
    // cputc(0xE0)
    // [759] stackpush(char) = $e0 -- _stackpushbyte_=vbuc1 
    lda #$e0
    pha
    // [760] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_write::@4
  __b4:
    // flash_rom_address % 0x1000
    // [762] flash_write::$12 = flash_write::flash_rom_address#12 & $1000-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address
    and #<$1000-1
    sta __12
    lda flash_rom_address+1
    and #>$1000-1
    sta __12+1
    lda flash_rom_address+2
    and #<$1000-1>>$10
    sta __12+2
    lda flash_rom_address+3
    and #>$1000-1>>$10
    sta __12+3
    // if (!(flash_rom_address % 0x1000))
    // [763] if(0!=flash_write::$12) goto flash_write::@5 -- 0_neq_vdum1_then_la1 
    lda __12
    ora __12+1
    ora __12+2
    ora __12+3
    // [764] phi from flash_write::@4 to flash_write::@12 [phi:flash_write::@4->flash_write::@12]
    // flash_write::@12
    // [765] phi from flash_write::@12 flash_write::@4 to flash_write::@5 [phi:flash_write::@12/flash_write::@4->flash_write::@5]
    // [765] phi flash_write::flashed_bytes#10 = flash_write::flashed_bytes#11 [phi:flash_write::@12/flash_write::@4->flash_write::@5#0] -- register_copy 
    // [765] phi flash_write::flash_ram_address#10 = flash_write::flash_ram_address#12 [phi:flash_write::@12/flash_write::@4->flash_write::@5#1] -- register_copy 
    // [765] phi flash_write::flash_rom_address#10 = flash_write::flash_rom_address#12 [phi:flash_write::@12/flash_write::@4->flash_write::@5#2] -- register_copy 
    // [765] phi flash_write::b#2 = 0 [phi:flash_write::@12/flash_write::@4->flash_write::@5#3] -- vbuaa=vbuc1 
    lda #0
    // flash_write::@5
  __b5:
    // for (unsigned char b = 0; b < 128; b++)
    // [766] if(flash_write::b#2<$80) goto flash_write::@6 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$80
    bcc __b6
    // flash_write::@7
    // if (flash_ram_address >= 0xC000)
    // [767] if(flash_write::flash_ram_address#10<$c000) goto flash_write::@9 -- pbuz1_lt_vwuc1_then_la1 
    lda.z flash_ram_address+1
    cmp #>$c000
    bcc __b9
    bne !+
    lda.z flash_ram_address
    cmp #<$c000
    bcc __b9
  !:
    // flash_write::@8
    // flash_ram_address = flash_ram_address - 0x2000
    // [768] flash_write::flash_ram_address#1 = flash_write::flash_ram_address#10 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z flash_ram_address
    sec
    sbc #<$2000
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    sbc #>$2000
    sta.z flash_ram_address+1
    // flash_write::bank_get_bram1
    // return BRAM;
    // [769] flash_write::bank_get_bram1_return#0 = BRAM -- vbuaa=vbuz1 
    lda.z BRAM
    // flash_write::@14
    // bank_set_bram(bank_get_bram() + 1)
    // [770] flash_write::bank_set_bram1_bank#0 = flash_write::bank_get_bram1_return#0 + 1 -- vbuaa=vbuaa_plus_1 
    inc
    // flash_write::bank_set_bram1
    // BRAM = bank
    // [771] BRAM = flash_write::bank_set_bram1_bank#0 -- vbuz1=vbuaa 
    sta.z BRAM
    // [772] phi from flash_write::@7 flash_write::bank_set_bram1 to flash_write::@9 [phi:flash_write::@7/flash_write::bank_set_bram1->flash_write::@9]
    // [772] phi flash_write::flash_ram_address#7 = flash_write::flash_ram_address#10 [phi:flash_write::@7/flash_write::bank_set_bram1->flash_write::@9#0] -- register_copy 
    // flash_write::@9
  __b9:
    // if (flash_ram_address >= 0xC000)
    // [773] if(flash_write::flash_ram_address#7<$c000) goto flash_write::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // flash_write::@13
    // flash_ram_address = flash_ram_address - 0x2000
    // [774] flash_write::flash_ram_address#2 = flash_write::flash_ram_address#7 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z flash_ram_address
    sec
    sbc #<$2000
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    sbc #>$2000
    sta.z flash_ram_address+1
    jmp __b1
    // flash_write::@6
  __b6:
    // flash_rom_address++;
    // [775] flash_write::flash_rom_address#1 = ++ flash_write::flash_rom_address#10 -- vdum1=_inc_vdum1 
    inc flash_rom_address
    bne !+
    inc flash_rom_address+1
    bne !+
    inc flash_rom_address+2
    bne !+
    inc flash_rom_address+3
  !:
    // flash_ram_address++;
    // [776] flash_write::flash_ram_address#0 = ++ flash_write::flash_ram_address#10 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [777] flash_write::flashed_bytes#1 = ++ flash_write::flashed_bytes#10 -- vdum1=_inc_vdum1 
    inc flashed_bytes
    bne !+
    inc flashed_bytes+1
    bne !+
    inc flashed_bytes+2
    bne !+
    inc flashed_bytes+3
  !:
    // for (unsigned char b = 0; b < 128; b++)
    // [778] flash_write::b#1 = ++ flash_write::b#2 -- vbuaa=_inc_vbuaa 
    inc
    // [765] phi from flash_write::@6 to flash_write::@5 [phi:flash_write::@6->flash_write::@5]
    // [765] phi flash_write::flashed_bytes#10 = flash_write::flashed_bytes#1 [phi:flash_write::@6->flash_write::@5#0] -- register_copy 
    // [765] phi flash_write::flash_ram_address#10 = flash_write::flash_ram_address#0 [phi:flash_write::@6->flash_write::@5#1] -- register_copy 
    // [765] phi flash_write::flash_rom_address#10 = flash_write::flash_rom_address#1 [phi:flash_write::@6->flash_write::@5#2] -- register_copy 
    // [765] phi flash_write::b#2 = flash_write::b#1 [phi:flash_write::@6->flash_write::@5#3] -- register_copy 
    jmp __b5
  .segment Data
    __2: .dword 0
    __8: .dword 0
    __12: .dword 0
    flash_rom_address: .dword 0
    rom_bank_start: .byte 0
    flashed_bytes: .dword 0
    .label return = flashed_bytes
    flash_size: .dword 0
}
.segment Code
  // flash_verify
// __mem() unsigned long flash_verify(__zp($35) char *verify_ram_address, __mem() char rom_bank_start, __mem() unsigned long verify_size)
flash_verify: {
    .label verify_ram_address = $35
    // unsigned long verify_rom_address = rom_address(rom_bank_start)
    // [780] rom_address::rom_bank#2 = flash_verify::rom_bank_start#10 -- vbuaa=vbum1 
    lda rom_bank_start
    // [781] call rom_address
    // [1053] phi from flash_verify to rom_address [phi:flash_verify->rom_address]
    // [1053] phi rom_address::rom_bank#4 = rom_address::rom_bank#2 [phi:flash_verify->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long verify_rom_address = rom_address(rom_bank_start)
    // [782] rom_address::return#4 = rom_address::return#0 -- vdum1=vdum2 
    lda rom_address.return
    sta rom_address.return_3
    lda rom_address.return+1
    sta rom_address.return_3+1
    lda rom_address.return+2
    sta rom_address.return_3+2
    lda rom_address.return+3
    sta rom_address.return_3+3
    // flash_verify::@15
    // [783] flash_verify::verify_rom_address#0 = rom_address::return#4
    // [784] phi from flash_verify::@15 to flash_verify::@1 [phi:flash_verify::@15->flash_verify::@1]
    // [784] phi flash_verify::verify_ram_address#15 = flash_verify::verify_ram_address#26 [phi:flash_verify::@15->flash_verify::@1#0] -- register_copy 
    // [784] phi flash_verify::rom_bank_start#4 = flash_verify::rom_bank_start#10 [phi:flash_verify::@15->flash_verify::@1#1] -- register_copy 
    // [784] phi flash_verify::correct_bytes#12 = 0 [phi:flash_verify::@15->flash_verify::@1#2] -- vdum1=vduc1 
    lda #<0
    sta correct_bytes
    sta correct_bytes+1
    lda #<0>>$10
    sta correct_bytes+2
    lda #>0>>$10
    sta correct_bytes+3
    // [784] phi flash_verify::verify_rom_address#11 = flash_verify::verify_rom_address#0 [phi:flash_verify::@15->flash_verify::@1#3] -- register_copy 
    // [784] phi flash_verify::verified_bytes#15 = 0 [phi:flash_verify::@15->flash_verify::@1#4] -- vdum1=vduc1 
    lda #<0
    sta verified_bytes
    sta verified_bytes+1
    lda #<0>>$10
    sta verified_bytes+2
    lda #>0>>$10
    sta verified_bytes+3
  /// Holds the amount of correct and verified bytes flashed in the ROM.
    // [784] phi from flash_verify::@11 flash_verify::@13 to flash_verify::@1 [phi:flash_verify::@11/flash_verify::@13->flash_verify::@1]
    // [784] phi flash_verify::verify_ram_address#15 = flash_verify::verify_ram_address#10 [phi:flash_verify::@11/flash_verify::@13->flash_verify::@1#0] -- register_copy 
    // [784] phi flash_verify::rom_bank_start#4 = flash_verify::rom_bank_start#15 [phi:flash_verify::@11/flash_verify::@13->flash_verify::@1#1] -- register_copy 
    // [784] phi flash_verify::correct_bytes#12 = flash_verify::correct_bytes#10 [phi:flash_verify::@11/flash_verify::@13->flash_verify::@1#2] -- register_copy 
    // [784] phi flash_verify::verify_rom_address#11 = flash_verify::verify_rom_address#10 [phi:flash_verify::@11/flash_verify::@13->flash_verify::@1#3] -- register_copy 
    // [784] phi flash_verify::verified_bytes#15 = flash_verify::verified_bytes#10 [phi:flash_verify::@11/flash_verify::@13->flash_verify::@1#4] -- register_copy 
    // flash_verify::@1
  __b1:
    // while (verified_bytes < verify_size)
    // [785] if(flash_verify::verified_bytes#15<flash_verify::verify_size#5) goto flash_verify::@2 -- vdum1_lt_vdum2_then_la1 
    lda verified_bytes+3
    cmp verify_size+3
    bcc __b2
    bne !+
    lda verified_bytes+2
    cmp verify_size+2
    bcc __b2
    bne !+
    lda verified_bytes+1
    cmp verify_size+1
    bcc __b2
    bne !+
    lda verified_bytes
    cmp verify_size
    bcc __b2
  !:
    // flash_verify::@return
    // }
    // [786] return 
    rts
    // flash_verify::@2
  __b2:
    // verify_rom_address % 0x04000
    // [787] flash_verify::$2 = flash_verify::verify_rom_address#11 & $4000-1 -- vdum1=vdum2_band_vduc1 
    lda verify_rom_address
    and #<$4000-1
    sta __2
    lda verify_rom_address+1
    and #>$4000-1
    sta __2+1
    lda verify_rom_address+2
    and #<$4000-1>>$10
    sta __2+2
    lda verify_rom_address+3
    and #>$4000-1>>$10
    sta __2+3
    // if (!(verify_rom_address % 0x04000))
    // [788] if(0!=flash_verify::$2) goto flash_verify::@3 -- 0_neq_vdum1_then_la1 
    lda __2
    ora __2+1
    ora __2+2
    ora __2+3
    bne __b3
    // flash_verify::@12
    // rom_bank_start % 32
    // [789] flash_verify::$5 = flash_verify::rom_bank_start#4 & $20-1 -- vbuaa=vbum1_band_vbuc1 
    lda #$20-1
    and rom_bank_start
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [790] gotoxy::y#9 = 4 + flash_verify::$5 -- vbuz1=vbuc1_plus_vbuaa 
    clc
    adc #4
    sta.z gotoxy.y
    // [791] call gotoxy
    // [323] phi from flash_verify::@12 to gotoxy [phi:flash_verify::@12->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#9 [phi:flash_verify::@12->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = $e [phi:flash_verify::@12->gotoxy#1] -- vbuyy=vbuc1 
    ldy #$e
    jsr gotoxy
    // flash_verify::@16
    // rom_bank_start++;
    // [792] flash_verify::rom_bank_start#0 = ++ flash_verify::rom_bank_start#4 -- vbum1=_inc_vbum1 
    inc rom_bank_start
    // [793] phi from flash_verify::@16 flash_verify::@2 to flash_verify::@3 [phi:flash_verify::@16/flash_verify::@2->flash_verify::@3]
    // [793] phi flash_verify::rom_bank_start#15 = flash_verify::rom_bank_start#0 [phi:flash_verify::@16/flash_verify::@2->flash_verify::@3#0] -- register_copy 
    // flash_verify::@3
  __b3:
    // textcolor(GREEN)
    // [794] call textcolor
    // [305] phi from flash_verify::@3 to textcolor [phi:flash_verify::@3->textcolor]
    // [305] phi textcolor::color#16 = GREEN [phi:flash_verify::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREEN
    jsr textcolor
    // [795] phi from flash_verify::@3 to flash_verify::@4 [phi:flash_verify::@3->flash_verify::@4]
    // [795] phi flash_verify::verified_bytes#10 = flash_verify::verified_bytes#15 [phi:flash_verify::@3->flash_verify::@4#0] -- register_copy 
    // [795] phi flash_verify::correct_bytes#10 = flash_verify::correct_bytes#12 [phi:flash_verify::@3->flash_verify::@4#1] -- register_copy 
    // [795] phi flash_verify::verify_ram_address#11 = flash_verify::verify_ram_address#15 [phi:flash_verify::@3->flash_verify::@4#2] -- register_copy 
    // [795] phi flash_verify::verify_rom_address#10 = flash_verify::verify_rom_address#11 [phi:flash_verify::@3->flash_verify::@4#3] -- register_copy 
    // [795] phi flash_verify::v#2 = 0 [phi:flash_verify::@3->flash_verify::@4#4] -- vwum1=vwuc1 
    lda #<0
    sta v
    sta v+1
    // flash_verify::@4
  __b4:
    // for (unsigned int v = 0; v < 0x100; v++)
    // [796] if(flash_verify::v#2<$100) goto flash_verify::@5 -- vwum1_lt_vwuc1_then_la1 
    lda v+1
    cmp #>$100
    bcc __b5
    bne !+
    lda v
    cmp #<$100
    bcc __b5
  !:
    // flash_verify::@6
    // cputc(0xE0)
    // [797] stackpush(char) = $e0 -- _stackpushbyte_=vbuc1 
    lda #$e0
    pha
    // [798] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // if (verify_ram_address >= 0xC000)
    // [800] if(flash_verify::verify_ram_address#11<$c000) goto flash_verify::@11 -- pbuz1_lt_vwuc1_then_la1 
    lda.z verify_ram_address+1
    cmp #>$c000
    bcc __b11
    bne !+
    lda.z verify_ram_address
    cmp #<$c000
    bcc __b11
  !:
    // flash_verify::@10
    // verify_ram_address = verify_ram_address - 0x2000
    // [801] flash_verify::verify_ram_address#1 = flash_verify::verify_ram_address#11 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z verify_ram_address
    sec
    sbc #<$2000
    sta.z verify_ram_address
    lda.z verify_ram_address+1
    sbc #>$2000
    sta.z verify_ram_address+1
    // flash_verify::bank_get_bram1
    // return BRAM;
    // [802] flash_verify::bank_get_bram1_return#0 = BRAM -- vbuaa=vbuz1 
    lda.z BRAM
    // flash_verify::@14
    // bank_set_bram(bank_get_bram() + 1)
    // [803] flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_get_bram1_return#0 + 1 -- vbuaa=vbuaa_plus_1 
    inc
    // flash_verify::bank_set_bram1
    // BRAM = bank
    // [804] BRAM = flash_verify::bank_set_bram1_bank#0 -- vbuz1=vbuaa 
    sta.z BRAM
    // [805] phi from flash_verify::@6 flash_verify::bank_set_bram1 to flash_verify::@11 [phi:flash_verify::@6/flash_verify::bank_set_bram1->flash_verify::@11]
    // [805] phi flash_verify::verify_ram_address#10 = flash_verify::verify_ram_address#11 [phi:flash_verify::@6/flash_verify::bank_set_bram1->flash_verify::@11#0] -- register_copy 
    // flash_verify::@11
  __b11:
    // if (verify_ram_address >= 0xC000)
    // [806] if(flash_verify::verify_ram_address#10<$c000) goto flash_verify::@1 -- pbuz1_lt_vwuc1_then_la1 
    lda.z verify_ram_address+1
    cmp #>$c000
    bcs !__b1+
    jmp __b1
  !__b1:
    bne !+
    lda.z verify_ram_address
    cmp #<$c000
    bcs !__b1+
    jmp __b1
  !__b1:
  !:
    // flash_verify::@13
    // verify_ram_address = verify_ram_address - 0x2000
    // [807] flash_verify::verify_ram_address#2 = flash_verify::verify_ram_address#10 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z verify_ram_address
    sec
    sbc #<$2000
    sta.z verify_ram_address
    lda.z verify_ram_address+1
    sbc #>$2000
    sta.z verify_ram_address+1
    jmp __b1
    // flash_verify::@5
  __b5:
    // rom_byte_verify(verify_rom_address, *verify_ram_address)
    // [808] rom_byte_verify::address#0 = flash_verify::verify_rom_address#10 -- vdum1=vdum2 
    lda verify_rom_address
    sta rom_byte_verify.address
    lda verify_rom_address+1
    sta rom_byte_verify.address+1
    lda verify_rom_address+2
    sta rom_byte_verify.address+2
    lda verify_rom_address+3
    sta rom_byte_verify.address+3
    // [809] rom_byte_verify::value#0 = *flash_verify::verify_ram_address#11 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (verify_ram_address),y
    sta rom_byte_verify.value
    // [810] call rom_byte_verify
    jsr rom_byte_verify
    // [811] rom_byte_verify::return#2 = rom_byte_verify::return#0
    // flash_verify::@17
    // [812] flash_verify::$10 = rom_byte_verify::return#2
    // if (!rom_byte_verify(verify_rom_address, *verify_ram_address))
    // [813] if(0==flash_verify::$10) goto flash_verify::@7 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b7
    // flash_verify::@9
    // correct_bytes++;
    // [814] flash_verify::correct_bytes#1 = ++ flash_verify::correct_bytes#10 -- vdum1=_inc_vdum1 
    inc correct_bytes
    bne !+
    inc correct_bytes+1
    bne !+
    inc correct_bytes+2
    bne !+
    inc correct_bytes+3
  !:
    // [815] phi from flash_verify::@7 flash_verify::@9 to flash_verify::@8 [phi:flash_verify::@7/flash_verify::@9->flash_verify::@8]
    // [815] phi flash_verify::correct_bytes#13 = flash_verify::correct_bytes#10 [phi:flash_verify::@7/flash_verify::@9->flash_verify::@8#0] -- register_copy 
    // flash_verify::@8
  __b8:
    // verify_rom_address++;
    // [816] flash_verify::verify_rom_address#1 = ++ flash_verify::verify_rom_address#10 -- vdum1=_inc_vdum1 
    inc verify_rom_address
    bne !+
    inc verify_rom_address+1
    bne !+
    inc verify_rom_address+2
    bne !+
    inc verify_rom_address+3
  !:
    // verify_ram_address++;
    // [817] flash_verify::verify_ram_address#0 = ++ flash_verify::verify_ram_address#11 -- pbuz1=_inc_pbuz1 
    inc.z verify_ram_address
    bne !+
    inc.z verify_ram_address+1
  !:
    // verified_bytes++;
    // [818] flash_verify::verified_bytes#1 = ++ flash_verify::verified_bytes#10 -- vdum1=_inc_vdum1 
    inc verified_bytes
    bne !+
    inc verified_bytes+1
    bne !+
    inc verified_bytes+2
    bne !+
    inc verified_bytes+3
  !:
    // for (unsigned int v = 0; v < 0x100; v++)
    // [819] flash_verify::v#1 = ++ flash_verify::v#2 -- vwum1=_inc_vwum1 
    inc v
    bne !+
    inc v+1
  !:
    // [795] phi from flash_verify::@8 to flash_verify::@4 [phi:flash_verify::@8->flash_verify::@4]
    // [795] phi flash_verify::verified_bytes#10 = flash_verify::verified_bytes#1 [phi:flash_verify::@8->flash_verify::@4#0] -- register_copy 
    // [795] phi flash_verify::correct_bytes#10 = flash_verify::correct_bytes#13 [phi:flash_verify::@8->flash_verify::@4#1] -- register_copy 
    // [795] phi flash_verify::verify_ram_address#11 = flash_verify::verify_ram_address#0 [phi:flash_verify::@8->flash_verify::@4#2] -- register_copy 
    // [795] phi flash_verify::verify_rom_address#10 = flash_verify::verify_rom_address#1 [phi:flash_verify::@8->flash_verify::@4#3] -- register_copy 
    // [795] phi flash_verify::v#2 = flash_verify::v#1 [phi:flash_verify::@8->flash_verify::@4#4] -- register_copy 
    jmp __b4
    // [820] phi from flash_verify::@17 to flash_verify::@7 [phi:flash_verify::@17->flash_verify::@7]
    // flash_verify::@7
  __b7:
    // textcolor(RED)
    // [821] call textcolor
    // [305] phi from flash_verify::@7 to textcolor [phi:flash_verify::@7->textcolor]
    // [305] phi textcolor::color#16 = RED [phi:flash_verify::@7->textcolor#0] -- vbuxx=vbuc1 
    ldx #RED
    jsr textcolor
    jmp __b8
  .segment Data
    __2: .dword 0
    verify_rom_address: .dword 0
    rom_bank_start: .byte 0
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    correct_bytes: .dword 0
    verified_bytes: .dword 0
    v: .word 0
    .label return = correct_bytes
    verify_size: .dword 0
}
.segment Code
  // rom_unlock
/**
 * @brief Unlock a byte location for flashing using the 22 bit address.
 * This is a various purpose routine to unlock the ROM for flashing a byte.
 * The 3rd byte can be variable, depending on the write sequence used, so this byte is a parameter into the routine.
 *
 * @param address The 3rd write to model the specific unlock sequence.
 * @param unlock_code The 3rd write to model the specific unlock sequence.
 */
// void rom_unlock(unsigned long address, __mem() char unlock_code)
rom_unlock: {
    // rom_write_byte(0x05555, 0xAA)
    // [823] call rom_write_byte
    // [1134] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1134] phi rom_write_byte::value#3 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuyy=vbuc1 
    ldy #$aa
    // [1134] phi rom_write_byte::address#3 = $5555 [phi:rom_unlock->rom_write_byte#1] -- vdum1=vduc1 
    lda #<$5555
    sta rom_write_byte.address
    lda #>$5555
    sta rom_write_byte.address+1
    lda #<$5555>>$10
    sta rom_write_byte.address+2
    lda #>$5555>>$10
    sta rom_write_byte.address+3
    jsr rom_write_byte
    // [824] phi from rom_unlock to rom_unlock::@1 [phi:rom_unlock->rom_unlock::@1]
    // rom_unlock::@1
    // rom_write_byte(0x02AAA, 0x55)
    // [825] call rom_write_byte
    // [1134] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1134] phi rom_write_byte::value#3 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuyy=vbuc1 
    ldy #$55
    // [1134] phi rom_write_byte::address#3 = $2aaa [phi:rom_unlock::@1->rom_write_byte#1] -- vdum1=vduc1 
    lda #<$2aaa
    sta rom_write_byte.address
    lda #>$2aaa
    sta rom_write_byte.address+1
    lda #<$2aaa>>$10
    sta rom_write_byte.address+2
    lda #>$2aaa>>$10
    sta rom_write_byte.address+3
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [826] rom_write_byte::value#2 = rom_unlock::unlock_code#2 -- vbuyy=vbum1 
    ldy unlock_code
    // [827] call rom_write_byte
    // [1134] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1134] phi rom_write_byte::value#3 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1134] phi rom_write_byte::address#3 = $5555 [phi:rom_unlock::@2->rom_write_byte#1] -- vdum1=vduc1 
    lda #<$5555
    sta rom_write_byte.address
    lda #>$5555
    sta rom_write_byte.address+1
    lda #<$5555>>$10
    sta rom_write_byte.address+2
    lda #>$5555>>$10
    sta rom_write_byte.address+3
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [828] return 
    rts
  .segment Data
    unlock_code: .byte 0
}
.segment Code
  // print_chip_line
// void print_chip_line(__register(Y) char x, __register(X) char y, __mem() char c)
print_chip_line: {
    // gotoxy(x, y)
    // [830] gotoxy::x#4 = print_chip_line::x#9
    // [831] gotoxy::y#4 = print_chip_line::y#9 -- vbuz1=vbuxx 
    stx.z gotoxy.y
    // [832] call gotoxy
    // [323] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [833] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [834] call textcolor
    // [305] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [305] phi textcolor::color#16 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [835] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [836] call bgcolor
    // [310] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [837] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [838] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [840] call textcolor
    // [305] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [305] phi textcolor::color#16 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [841] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [842] call bgcolor
    // [310] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [310] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [843] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [844] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [846] stackpush(char) = print_chip_line::c#10 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [847] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [849] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [850] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [852] call textcolor
    // [305] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [305] phi textcolor::color#16 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [853] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [854] call bgcolor
    // [310] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [855] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [856] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [858] return 
    rts
  .segment Data
    c: .byte 0
}
.segment Code
  // print_chip_end
// void print_chip_end(__register(A) char x, char y)
print_chip_end: {
    .const y = $36
    // gotoxy(x, y)
    // [859] gotoxy::x#5 = print_chip_end::x#0 -- vbuyy=vbuaa 
    tay
    // [860] call gotoxy
    // [323] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [323] phi gotoxy::y#22 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #y
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [861] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [862] call textcolor
    // [305] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [305] phi textcolor::color#16 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [863] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [864] call bgcolor
    // [310] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [865] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [866] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [868] call textcolor
    // [305] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [305] phi textcolor::color#16 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr textcolor
    // [869] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [870] call bgcolor
    // [310] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [310] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [871] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [872] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [874] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [875] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [877] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [878] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [880] call textcolor
    // [305] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [305] phi textcolor::color#16 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [881] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [882] call bgcolor
    // [310] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [310] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [883] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [884] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [886] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __register(X) char mapbase, __zp($5a) char config)
screenlayer: {
    .label mapbase_offset = $50
    .label config = $5a
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [887] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [888] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [889] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // mapbase >> 7
    // [890] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuaa=vbuxx_ror_7 
    txa
    rol
    rol
    and #1
    // __conio.mapbase_bank = mapbase >> 7
    // [891] *((char *)&__conio+3) = screenlayer::$0 -- _deref_pbuc1=vbuaa 
    sta __conio+3
    // (mapbase)<<1
    // [892] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // MAKEWORD((mapbase)<<1,0)
    // [893] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuaa_word_vbuc1 
    ldy #0
    sta __2+1
    sty __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [894] *((unsigned int *)&__conio+1) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    tya
    sta __conio+1
    lda __2+1
    sta __conio+1+1
    // config & VERA_LAYER_WIDTH_MASK
    // [895] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuaa=vbuz1_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [896] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuxx=vbuaa_ror_4 
    lsr
    lsr
    lsr
    lsr
    tax
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [897] *((char *)&__conio+6) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuxx 
    lda VERA_LAYER_DIM,x
    sta __conio+6
    // config & VERA_LAYER_HEIGHT_MASK
    // [898] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuaa=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z config
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [899] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuaa=vbuaa_ror_6 
    rol
    rol
    rol
    and #3
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [900] *((char *)&__conio+7) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuaa 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+7
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [901] screenlayer::$16 = screenlayer::$8 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [902] *((unsigned int *)&__conio+8) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    tay
    lda VERA_LAYER_SKIP,y
    sta __conio+8
    lda VERA_LAYER_SKIP+1,y
    sta __conio+8+1
    // vera_dc_hscale_temp == 0x80
    // [903] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [904] screenlayer::$18 = (char)screenlayer::$9 -- vbuxx=vbuaa 
    tax
    // [905] screenlayer::$10 = $28 << screenlayer::$18 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$28
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [906] screenlayer::$11 = screenlayer::$10 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [907] *((char *)&__conio+4) = screenlayer::$11 -- _deref_pbuc1=vbuaa 
    sta __conio+4
    // vera_dc_vscale_temp == 0x80
    // [908] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [909] screenlayer::$19 = (char)screenlayer::$12 -- vbuxx=vbuaa 
    tax
    // [910] screenlayer::$13 = $1e << screenlayer::$19 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$1e
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [911] screenlayer::$14 = screenlayer::$13 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [912] *((char *)&__conio+5) = screenlayer::$14 -- _deref_pbuc1=vbuaa 
    sta __conio+5
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [913] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z mapbase_offset
    lda __conio+1+1
    sta.z mapbase_offset+1
    // [914] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [914] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [914] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [915] if(screenlayer::y#2<=*((char *)&__conio+5)) goto screenlayer::@2 -- vbuxx_le__deref_pbuc1_then_la1 
    lda __conio+5
    stx.z $ff
    cmp.z $ff
    bcs __b2
    // screenlayer::@return
    // }
    // [916] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [917] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [918] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuaa=vwuz1 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [919] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+8
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+8+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [920] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuxx=_inc_vbuxx 
    inx
    // [914] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [914] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [914] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    __2: .word 0
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [921] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [922] if(0!=((char *)&__conio+$f)[*((char *)&__conio)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [923] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // [924] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [925] call gotoxy
    // [323] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [323] phi gotoxy::y#22 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [323] phi gotoxy::x#22 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuyy=vbuc1 
    tay
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [926] return 
    rts
    // [927] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [928] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [929] gotoxy::y#2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z gotoxy.y
    // [930] call gotoxy
    // [323] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuyy=vbuc1 
    ldy #0
    jsr gotoxy
    // [931] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [932] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__register(Y) char x, __register(X) char y, __zp($4e) char c)
cputcxy: {
    .label c = $4e
    // gotoxy(x, y)
    // [934] gotoxy::x#0 = cputcxy::x#68
    // [935] gotoxy::y#0 = cputcxy::y#68 -- vbuz1=vbuxx 
    stx.z gotoxy.y
    // [936] call gotoxy
    // [323] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [323] phi gotoxy::y#22 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [323] phi gotoxy::x#22 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [937] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [938] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [940] return 
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
    // [941] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [943] getin::return#0 = getin::ch -- vbuaa=vbum1 
    // getin::@return
    // }
    // [944] getin::return#1 = getin::return#0
    // [945] return 
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
// void uctoa(__register(X) char value, __zp($3e) char *buffer, __register(Y) char radix)
uctoa: {
    .label buffer = $3e
    .label digit = $42
    .label started = $44
    .label max_digits = $48
    .label digit_values = $35
    // if(radix==DECIMAL)
    // [946] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #DECIMAL
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [947] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #HEXADECIMAL
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [948] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #OCTAL
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [949] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #BINARY
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [950] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [951] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [952] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [953] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [954] return 
    rts
    // [955] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [955] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [955] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [955] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [955] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [955] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [955] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [955] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [955] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [955] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [955] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [955] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [956] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [956] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [956] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [956] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [956] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [957] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuaa=vbuz1_minus_1 
    lda.z max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [958] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuaa_then_la1 
    cmp.z digit
    beq !+
    bcs __b7
  !:
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [959] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [960] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [961] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [962] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuyy=pbuz1_derefidx_vbuz2 
    ldy.z digit
    lda (digit_values),y
    tay
    // if (started || value >= digit_value)
    // [963] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [964] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuxx_ge_vbuyy_then_la1 
    sty.z $ff
    cpx.z $ff
    bcs __b10
    // [965] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [965] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [965] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [965] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [966] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [956] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [956] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [956] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [956] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [956] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [967] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [968] uctoa_append::value#0 = uctoa::value#2
    // [969] uctoa_append::sub#0 = uctoa::digit_value#0 -- vbuz1=vbuyy 
    sty.z uctoa_append.sub
    // [970] call uctoa_append
    // [1179] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [971] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [972] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [973] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [965] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [965] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [965] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [965] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($45) void (*putc)(char), __zp($42) char buffer_sign, char *buffer_digits, __register(X) char format_min_length, __zp($48) char format_justify_left, char format_sign_always, __zp($4e) char format_zero_padding, __zp($44) char format_upper_case, char format_radix)
printf_number_buffer: {
    .label buffer_sign = $42
    .label putc = $45
    .label format_zero_padding = $4e
    .label padding = $41
    .label format_justify_left = $48
    .label format_upper_case = $44
    // if(format.min_length)
    // [975] if(0==printf_number_buffer::format_min_length#2) goto printf_number_buffer::@1 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq __b6
    // [976] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [977] call strlen
    // [1064] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [1064] phi strlen::str#6 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [978] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@14
    // [979] printf_number_buffer::$19 = strlen::return#3 -- vwum1=vwuz2 
    lda.z strlen.return
    sta __19
    lda.z strlen.return+1
    sta __19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [980] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsyy=_sbyte_vwum1 
    // There is a minimum length - work out the padding
    ldy __19
    // if(buffer.sign)
    // [981] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [982] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsyy=_inc_vbsyy 
    iny
    // [983] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [983] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [984] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#2 - printf_number_buffer::len#2 -- vbsz1=vbsxx_minus_vbsyy 
    txa
    sty.z $ff
    sec
    sbc.z $ff
    sta.z padding
    // if(padding<0)
    // [985] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [987] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [987] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [986] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [987] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [987] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [988] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [989] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [990] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [991] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [992] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [993] call printf_padding
    // [1070] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1070] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1070] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@8->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1070] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [994] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [995] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [996] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall22
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [998] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [999] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1000] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1001] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1002] call printf_padding
    // [1070] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1070] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1070] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@10->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1070] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1003] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbuz1_then_la1 
    lda.z format_upper_case
    beq __b5
    // [1004] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1005] call strupr
    // [1186] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1006] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1007] call printf_str
    // [551] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [551] phi printf_str::putc#10 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [551] phi printf_str::s#10 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1008] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1009] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1010] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1011] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1012] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1013] call printf_padding
    // [1070] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1070] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1070] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@12->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1070] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1014] return 
    rts
    // Outside Flow
  icall22:
    jmp (putc)
  .segment Data
    __19: .word 0
}
.segment Code
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($37) char *dst, __zp($35) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label dst = $37
    .label i = $3e
    .label src = $35
    // [1016] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1016] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1016] phi strncpy::src#2 = main::file [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.file
    sta.z src
    lda #>main.file
    sta.z src+1
    // [1016] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1017] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuc1_then_la1 
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
    // [1018] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1019] strncpy::c#0 = *strncpy::src#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // if(c)
    // [1020] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // strncpy::@4
    // src++;
    // [1021] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1022] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1022] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1023] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1024] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1025] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1016] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1016] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1016] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1016] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_setnam
/**
 * @brief Sets the name of the file before opening.
 * 
 * @param filename The name of the file.
 */
// void cbm_k_setnam(__zp($52) char * volatile filename)
cbm_k_setnam: {
    .label filename = $52
    // strlen(filename)
    // [1026] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbuz2 
    lda.z filename
    sta.z strlen.str
    lda.z filename+1
    sta.z strlen.str+1
    // [1027] call strlen
    // [1064] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [1064] phi strlen::str#6 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1028] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [1029] cbm_k_setnam::$0 = strlen::return#0 -- vwum1=vwuz2 
    lda.z strlen.return
    sta __0
    lda.z strlen.return+1
    sta __0+1
    // __mem char filename_len = (char)strlen(filename)
    // [1030] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwum2 
    lda __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [1032] return 
    rts
  .segment Data
    filename_len: .byte 0
    __0: .word 0
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
// void cbm_k_setlfs(__zp($57) volatile char channel, __zp($56) volatile char device, __zp($54) volatile char command)
cbm_k_setlfs: {
    .label channel = $57
    .label device = $56
    .label command = $54
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1034] return 
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
    // [1035] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [1037] cbm_k_open::return#0 = cbm_k_open::status -- vbuaa=vbum1 
    // cbm_k_open::@return
    // }
    // [1038] cbm_k_open::return#1 = cbm_k_open::return#0
    // [1039] return 
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
// __register(A) char cbm_k_close(__zp($55) volatile char channel)
cbm_k_close: {
    .label channel = $55
    // __mem unsigned char status
    // [1040] cbm_k_close::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldachannel jsrCBM_CLOSE stastatus  }
    lda channel
    jsr CBM_CLOSE
    sta status
    // return status;
    // [1042] cbm_k_close::return#0 = cbm_k_close::status -- vbuaa=vbum1 
    // cbm_k_close::@return
    // }
    // [1043] cbm_k_close::return#1 = cbm_k_close::return#0
    // [1044] return 
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
// char cbm_k_chkin(__zp($4d) volatile char channel)
cbm_k_chkin: {
    .label channel = $4d
    // __mem unsigned char status
    // [1045] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [1047] return 
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
    // [1048] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [1050] cbm_k_readst::return#0 = cbm_k_readst::status -- vbuaa=vbum1 
    // cbm_k_readst::@return
    // }
    // [1051] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [1052] return 
    rts
  .segment Data
    status: .byte 0
}
.segment Code
  // rom_address
/**
 * @brief Calculates the 22 bit ROM address from the 8 bit ROM bank.
 * The ROM bank number is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM address.
 * @return unsigned long The 22 bit ROM address.
 */
// __mem() unsigned long rom_address(__register(A) char rom_bank)
rom_address: {
    // ((unsigned long)(rom_bank)) << 14
    // [1054] rom_address::$1 = (unsigned long)rom_address::rom_bank#4 -- vdum1=_dword_vbuaa 
    sta __1
    lda #0
    sta __1+1
    sta __1+2
    sta __1+3
    // [1055] rom_address::return#0 = rom_address::$1 << $e -- vdum1=vdum2_rol_vbuc1 
    ldy #$e
    lda __1
    sta return
    lda __1+1
    sta return+1
    lda __1+2
    sta return+2
    lda __1+3
    sta return+3
    cpy #0
    beq !e+
  !:
    asl return
    rol return+1
    rol return+2
    rol return+3
    dey
    bne !-
  !e:
    // rom_address::@return
    // }
    // [1056] return 
    rts
  .segment Data
    __1: .dword 0
    return: .dword 0
    .label return_1 = flash_read.flash_rom_address
    .label return_2 = flash_write.flash_rom_address
    .label return_3 = flash_verify.verify_rom_address
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($23) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .const format_min_length = 6
    .const format_justify_left = 0
    .const format_zero_padding = 1
    .const format_upper_case = 0
    .label putc = cputc
    .label uvalue = $23
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1058] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1059] ultoa::value#1 = printf_ulong::uvalue#0
    // [1060] call ultoa
  // Format number into buffer
    // [1196] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1061] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1062] call printf_number_buffer
  // Print using format
    // [974] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [974] phi printf_number_buffer::format_upper_case#10 = printf_ulong::format_upper_case#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #format_upper_case
    sta.z printf_number_buffer.format_upper_case
    // [974] phi printf_number_buffer::putc#10 = printf_ulong::putc#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [974] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [974] phi printf_number_buffer::format_zero_padding#10 = printf_ulong::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #format_zero_padding
    sta.z printf_number_buffer.format_zero_padding
    // [974] phi printf_number_buffer::format_justify_left#10 = printf_ulong::format_justify_left#0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #format_justify_left
    sta.z printf_number_buffer.format_justify_left
    // [974] phi printf_number_buffer::format_min_length#2 = printf_ulong::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbuxx=vbuc1 
    ldx #format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1063] return 
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($37) unsigned int strlen(__zp($35) char *str)
strlen: {
    .label str = $35
    .label return = $37
    .label len = $37
    // [1065] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1065] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1065] phi strlen::str#4 = strlen::str#6 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1066] if(0!=*strlen::str#4) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1067] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1068] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1069] strlen::str#1 = ++ strlen::str#4 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1065] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1065] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1065] phi strlen::str#4 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($37) void (*putc)(char), __zp($43) char pad, __zp($29) char length)
printf_padding: {
    .label i = $39
    .label putc = $37
    .label length = $29
    .label pad = $43
    // [1071] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1071] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1072] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1073] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1074] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1075] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall23
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1077] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1071] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1071] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall23:
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
// __zp($3c) unsigned int fgets(__zp($37) char *ptr, unsigned int size, __zp($49) struct $1 *fp)
fgets: {
    .const size = $80
    .label return = $3c
    .label bytes = $33
    .label read = $3c
    .label ptr = $37
    .label remaining = $35
    .label fp = $49
    // cbm_k_chkin(fp->channel)
    // [1078] cbm_k_chkin::channel = ((char *)fgets::fp#0)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_chkin.channel
    // [1079] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1080] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [1081] call cbm_k_readst
    jsr cbm_k_readst
    // [1082] cbm_k_readst::return#3 = cbm_k_readst::return#1
    // fgets::@12
    // [1083] fgets::$1 = cbm_k_readst::return#3
    // fp->status = cbm_k_readst()
    // [1084] ((char *)fgets::fp#0)[$13] = fgets::$1 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [1085] if(0==((char *)fgets::fp#0)[$13]) goto fgets::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b8
    // [1086] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [1086] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1087] return 
    rts
    // [1088] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [1088] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1088] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@12->fgets::@1#1] -- vwuz1=vwuc1 
    lda #<size
    sta.z remaining
    lda #>size
    sta.z remaining+1
    // [1088] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [1088] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [1088] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [1088] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [1088] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [1089] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwuz1_ge_vbuc1_then_la1 
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
    // [1090] cbm_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cbm_k_macptr.bytes
    // [1091] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1092] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1093] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [1094] fgets::bytes#3 = cbm_k_macptr::return#4
    // [1095] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [1095] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [1096] call cbm_k_readst
    jsr cbm_k_readst
    // [1097] cbm_k_readst::return#4 = cbm_k_readst::return#1
    // fgets::@15
    // [1098] fgets::$9 = cbm_k_readst::return#4
    // fp->status = cbm_k_readst()
    // [1099] ((char *)fgets::fp#0)[$13] = fgets::$9 -- pbuz1_derefidx_vbuc1=vbuaa 
    ldy #$13
    sta (fp),y
    // fp->status & 0xBF
    // [1100] fgets::$10 = ((char *)fgets::fp#0)[$13] & $bf -- vbuaa=pbuz1_derefidx_vbuc1_band_vbuc2 
    lda #$bf
    and (fp),y
    // if(fp->status & 0xBF)
    // [1101] if(0==fgets::$10) goto fgets::@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [1102] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1103] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1104] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1105] fgets::$14 = byte1  fgets::ptr#0 -- vbuaa=_byte1_pbuz1 
    // if(BYTE1(ptr) == 0xC0)
    // [1106] if(fgets::$14!=$c0) goto fgets::@6 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$c0
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [1107] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1108] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [1108] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [1109] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((fp->status == 0) && ((size && remaining) || !size))
    // [1110] if(((char *)fgets::fp#0)[$13]==0) goto fgets::@16 -- pbuz1_derefidx_vbuc1_eq_0_then_la1 
    ldy #$13
    lda (fp),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [1111] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [1112] cbm_k_chkin::channel = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin.channel
    // [1113] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1086] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [1086] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [1114] cbm_k_macptr::bytes = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cbm_k_macptr.bytes
    // [1115] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1116] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1117] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [1118] fgets::bytes#2 = cbm_k_macptr::return#3
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
    // [1120] return 
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
// __register(A) char rom_byte_verify(__mem() unsigned long address, __mem() char value)
rom_byte_verify: {
    .label ptr_rom = $49
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1121] rom_bank::address#1 = rom_byte_verify::address#0 -- vdum1=vdum2 
    lda address
    sta rom_bank.address
    lda address+1
    sta rom_bank.address+1
    lda address+2
    sta rom_bank.address+2
    lda address+3
    sta rom_bank.address+3
    // [1122] call rom_bank
    // [1222] phi from rom_byte_verify to rom_bank [phi:rom_byte_verify->rom_bank]
    // [1222] phi rom_bank::address#2 = rom_bank::address#1 [phi:rom_byte_verify->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1123] rom_bank::return#3 = rom_bank::return#0
    // rom_byte_verify::@3
    // [1124] rom_byte_verify::bank_rom#0 = rom_bank::return#3 -- vbuxx=vbuaa 
    tax
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1125] rom_ptr::address#1 = rom_byte_verify::address#0 -- vdum1=vdum2 
    lda address
    sta rom_ptr.address
    lda address+1
    sta rom_ptr.address+1
    lda address+2
    sta rom_ptr.address+2
    lda address+3
    sta rom_ptr.address+3
    // [1126] call rom_ptr
    // [1227] phi from rom_byte_verify::@3 to rom_ptr [phi:rom_byte_verify::@3->rom_ptr]
    // [1227] phi rom_ptr::address#2 = rom_ptr::address#1 [phi:rom_byte_verify::@3->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_byte_verify::@4
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1127] rom_byte_verify::ptr_rom#0 = (char *)rom_ptr::return#0
    // bank_set_brom(bank_rom)
    // [1128] bank_set_brom::bank#3 = rom_byte_verify::bank_rom#0 -- vbuaa=vbuxx 
    txa
    // [1129] call bank_set_brom
    // [576] phi from rom_byte_verify::@4 to bank_set_brom [phi:rom_byte_verify::@4->bank_set_brom]
    // [576] phi bank_set_brom::bank#8 = bank_set_brom::bank#3 [phi:rom_byte_verify::@4->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_byte_verify::@5
    // if (*ptr_rom != value)
    // [1130] if(*rom_byte_verify::ptr_rom#0==rom_byte_verify::value#0) goto rom_byte_verify::@1 -- _deref_pbuz1_eq_vbum2_then_la1 
    lda value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1131] phi from rom_byte_verify::@5 to rom_byte_verify::@2 [phi:rom_byte_verify::@5->rom_byte_verify::@2]
    // rom_byte_verify::@2
    // [1132] phi from rom_byte_verify::@2 to rom_byte_verify::@1 [phi:rom_byte_verify::@2->rom_byte_verify::@1]
    // [1132] phi rom_byte_verify::return#0 = 0 [phi:rom_byte_verify::@2->rom_byte_verify::@1#0] -- vbuaa=vbuc1 
    tya
    rts
    // [1132] phi from rom_byte_verify::@5 to rom_byte_verify::@1 [phi:rom_byte_verify::@5->rom_byte_verify::@1]
  __b2:
    // [1132] phi rom_byte_verify::return#0 = 1 [phi:rom_byte_verify::@5->rom_byte_verify::@1#0] -- vbuaa=vbuc1 
    lda #1
    // rom_byte_verify::@1
    // rom_byte_verify::@return
    // }
    // [1133] return 
    rts
  .segment Data
    address: .dword 0
    value: .byte 0
}
.segment Code
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
// void rom_write_byte(__mem() unsigned long address, __register(Y) char value)
rom_write_byte: {
    .label ptr_rom = $45
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1135] rom_bank::address#0 = rom_write_byte::address#3 -- vdum1=vdum2 
    lda address
    sta rom_bank.address
    lda address+1
    sta rom_bank.address+1
    lda address+2
    sta rom_bank.address+2
    lda address+3
    sta rom_bank.address+3
    // [1136] call rom_bank
    // [1222] phi from rom_write_byte to rom_bank [phi:rom_write_byte->rom_bank]
    // [1222] phi rom_bank::address#2 = rom_bank::address#0 [phi:rom_write_byte->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [1137] rom_bank::return#2 = rom_bank::return#0
    // rom_write_byte::@1
    // [1138] rom_write_byte::bank_rom#0 = rom_bank::return#2 -- vbum1=vbuaa 
    sta bank_rom
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1139] rom_ptr::address#0 = rom_write_byte::address#3
    // [1140] call rom_ptr
    // [1227] phi from rom_write_byte::@1 to rom_ptr [phi:rom_write_byte::@1->rom_ptr]
    // [1227] phi rom_ptr::address#2 = rom_ptr::address#0 [phi:rom_write_byte::@1->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_write_byte::@2
    // brom_ptr_t ptr_rom = rom_ptr((unsigned long)address)
    // [1141] rom_write_byte::ptr_rom#0 = (char *)rom_ptr::return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // bank_set_brom(bank_rom)
    // [1142] bank_set_brom::bank#2 = rom_write_byte::bank_rom#0 -- vbuaa=vbum1 
    lda bank_rom
    // [1143] call bank_set_brom
    // [576] phi from rom_write_byte::@2 to bank_set_brom [phi:rom_write_byte::@2->bank_set_brom]
    // [576] phi bank_set_brom::bank#8 = bank_set_brom::bank#2 [phi:rom_write_byte::@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_write_byte::@3
    // *ptr_rom = value
    // [1144] *rom_write_byte::ptr_rom#0 = rom_write_byte::value#3 -- _deref_pbuz1=vbuyy 
    tya
    ldy #0
    sta (ptr_rom),y
    // rom_write_byte::@return
    // }
    // [1145] return 
    rts
  .segment Data
    bank_rom: .byte 0
    address: .dword 0
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label width = $32
    .label y = $2e
    // __conio.width+1
    // [1146] insertup::$0 = *((char *)&__conio+4) + 1 -- vbuaa=_deref_pbuc1_plus_1 
    lda __conio+4
    inc
    // unsigned char width = (__conio.width+1) * 2
    // [1147] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuaa_rol_1 
    asl
    sta.z width
    // [1148] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1148] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1149] if(insertup::y#2<=*((char *)&__conio+$e)) goto insertup::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+$e
    cmp.z y
    bcs __b2
    // [1150] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1151] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1152] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1153] insertup::$4 = insertup::y#2 + 1 -- vbuxx=vbuz1_plus_1 
    ldx.z y
    inx
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1154] insertup::$6 = insertup::y#2 << 1 -- vbuyy=vbuz1_rol_1 
    lda.z y
    asl
    tay
    // [1155] insertup::$7 = insertup::$4 << 1 -- vbum1=vbuxx_rol_1 
    txa
    asl
    sta __7
    // [1156] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.dbank_vram
    // [1157] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuyy 
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1158] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+3) -- vbuxx=_deref_pbuc1 
    ldx __conio+3
    // [1159] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbum2 
    ldy __7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1160] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8
    // [1161] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [1162] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1148] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1148] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    __7: .byte 0
}
.segment Code
  // clearline
clearline: {
    .label addr = $2f
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1163] clearline::$3 = *((char *)&__conio+$e) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    // [1164] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1165] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1166] clearline::$0 = byte0  clearline::addr#0 -- vbuaa=_byte0_vwuz1 
    lda.z addr
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1167] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1168] clearline::$1 = byte1  clearline::addr#0 -- vbuaa=_byte1_vwuz1 
    lda.z addr+1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1169] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1170] clearline::$2 = *((char *)&__conio+3) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1171] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1172] clearline::c#0 = *((char *)&__conio+4) -- vbuxx=_deref_pbuc1 
    ldx __conio+4
    // [1173] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1173] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1174] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1175] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [1176] clearline::c#1 = -- clearline::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [1177] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clearline::@return
    // }
    // [1178] return 
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
// __register(X) char uctoa_append(__zp($33) char *buffer, __register(X) char value, __zp($29) char sub)
uctoa_append: {
    .label buffer = $33
    .label sub = $29
    // [1180] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1180] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuyy=vbuc1 
    ldy #0
    // [1180] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1181] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuxx_ge_vbuz1_then_la1 
    cpx.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1182] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuyy 
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1183] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1184] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuyy=_inc_vbuyy 
    iny
    // value -= sub
    // [1185] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuxx=vbuxx_minus_vbuz1 
    txa
    sec
    sbc.z sub
    tax
    // [1180] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1180] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1180] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label src = $35
    // [1187] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1187] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1188] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1189] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1190] toupper::ch#0 = *strupr::src#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // [1191] call toupper
    jsr toupper
    // [1192] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1193] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1194] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (src),y
    // src++;
    // [1195] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1187] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1187] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($23) unsigned long value, __zp($3c) char *buffer, char radix)
ultoa: {
    .const max_digits = 8
    .label digit_value = $2a
    .label buffer = $3c
    .label digit = $41
    .label value = $23
    // [1197] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1197] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1197] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // [1197] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1197] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    txa
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1198] if(ultoa::digit#2<ultoa::max_digits#2-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #max_digits-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1199] ultoa::$11 = (char)ultoa::value#2 -- vbuaa=_byte_vduz1 
    lda.z value
    // [1200] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuaa 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1201] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1202] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1203] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1204] ultoa::$10 = ultoa::digit#2 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z digit
    asl
    asl
    // [1205] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuaa 
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
    // [1206] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b5
    // ultoa::@7
    // [1207] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1208] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1208] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1208] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1208] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1209] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1197] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1197] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1197] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1197] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1197] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1210] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1211] ultoa_append::value#0 = ultoa::value#2
    // [1212] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1213] call ultoa_append
    // [1257] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1214] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1215] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1216] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1208] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1208] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1208] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuxx=vbuc1 
    ldx #1
    // [1208] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
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
// __zp($33) unsigned int cbm_k_macptr(__zp($40) volatile char bytes, __zp($3a) void * volatile buffer)
cbm_k_macptr: {
    .label bytes = $40
    .label buffer = $3a
    .label return = $33
    // __mem unsigned int bytes_read
    // [1217] cbm_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [1219] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwuz1=vwum2 
    lda bytes_read
    sta.z return
    lda bytes_read+1
    sta.z return+1
    // cbm_k_macptr::@return
    // }
    // [1220] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [1221] return 
    rts
  .segment Data
    bytes_read: .word 0
}
.segment Code
  // rom_bank
/**
 * @brief Calculates the 8 bit ROM bank from the 22 bit ROM address.
 * The ROM bank number is calcuated by taking the upper 8 bits (bit 18-14) and shifing those 14 bits to the right.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The ROM bank number for usage in ZP $01.
 */
// __register(A) char rom_bank(__mem() unsigned long address)
rom_bank: {
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [1223] rom_bank::$2 = rom_bank::address#2 & $3fc000 -- vdum1=vdum1_band_vduc1 
    lda __2
    and #<$3fc000
    sta __2
    lda __2+1
    and #>$3fc000
    sta __2+1
    lda __2+2
    and #<$3fc000>>$10
    sta __2+2
    lda __2+3
    and #>$3fc000>>$10
    sta __2+3
    // [1224] rom_bank::$1 = rom_bank::$2 >> $e -- vdum1=vdum2_ror_vbuc1 
    ldx #$e
    lda __2
    sta __1
    lda __2+1
    sta __1+1
    lda __2+2
    sta __1+2
    lda __2+3
    sta __1+3
    cpx #0
    beq !e+
  !:
    lsr __1+3
    ror __1+2
    ror __1+1
    ror __1
    dex
    bne !-
  !e:
    // return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
    // [1225] rom_bank::return#0 = (char)rom_bank::$1 -- vbuaa=_byte_vdum1 
    lda __1
    // rom_bank::@return
    // }
    // [1226] return 
    rts
  .segment Data
    __1: .dword 0
    .label __2 = address
    address: .dword 0
}
.segment Code
  // rom_ptr
/**
 * @brief Calcuates the 16 bit ROM pointer from the ROM using the 22 bit address.
 * The 16 bit ROM pointer is calculated by masking the lower 14 bits (bit 13-0), and then adding $C000 to it.
 * The 16 bit ROM pointer is returned as a char* (brom_ptr_t).
 * @param address The 22 bit ROM address.
 * @return brom_ptr_t The 16 bit ROM pointer for the main CPU addressing.
 */
// __zp($49) char * rom_ptr(__mem() unsigned long address)
rom_ptr: {
    .label return = $49
    // address & ROM_PTR_MASK
    // [1228] rom_ptr::$0 = rom_ptr::address#2 & $3fff -- vdum1=vdum1_band_vduc1 
    lda __0
    and #<$3fff
    sta __0
    lda __0+1
    and #>$3fff
    sta __0+1
    lda __0+2
    and #<$3fff>>$10
    sta __0+2
    lda __0+3
    and #>$3fff>>$10
    sta __0+3
    // (unsigned int)(address & ROM_PTR_MASK) + ROM_BASE
    // [1229] rom_ptr::$2 = (unsigned int)rom_ptr::$0 -- vwum1=_word_vdum2 
    lda __0
    sta __2
    lda __0+1
    sta __2+1
    // [1230] rom_ptr::return#0 = rom_ptr::$2 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda __2
    clc
    adc #<$c000
    sta.z return
    lda __2+1
    adc #>$c000
    sta.z return+1
    // rom_ptr::@return
    // }
    // [1231] return 
    rts
  .segment Data
    .label __0 = rom_write_byte.address
    __2: .word 0
    .label address = rom_write_byte.address
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
// void memcpy8_vram_vram(__zp($31) char dbank_vram, __zp($2f) unsigned int doffset_vram, __register(X) char sbank_vram, __zp($27) unsigned int soffset_vram, __register(X) char num8)
memcpy8_vram_vram: {
    .label dbank_vram = $31
    .label doffset_vram = $2f
    .label soffset_vram = $27
    .label num8 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1232] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1233] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z soffset_vram
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1234] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1235] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z soffset_vram+1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1236] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1237] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuaa=vbuxx_bor_vbuc1 
    txa
    ora #VERA_INC_1
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1238] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1239] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1240] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z doffset_vram
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1241] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1242] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z doffset_vram+1
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1243] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1244] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuaa=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z dbank_vram
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1245] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // [1246] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1246] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1247] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuxx=_dec_vbuz1 
    ldx.z num8
    dex
    // [1248] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1249] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1250] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1251] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuxx 
    stx.z num8
    jmp __b1
}
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __register(A) char toupper(__register(A) char ch)
toupper: {
    // if(ch>='a' && ch<='z')
    // [1252] if(toupper::ch#0<'a'pm) goto toupper::@return -- vbuaa_lt_vbuc1_then_la1 
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1253] if(toupper::ch#0<='z'pm) goto toupper::@1 -- vbuaa_le_vbuc1_then_la1 
    cmp #'z'
    bcc __b1
    beq __b1
    // [1255] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1255] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1254] toupper::return#0 = toupper::ch#0 + 'A'pm-'a'pm -- vbuaa=vbuaa_plus_vbuc1 
    clc
    adc #'A'-'a'
    // toupper::@return
  __breturn:
    // }
    // [1256] return 
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
// __zp($23) unsigned long ultoa_append(__zp($45) char *buffer, __zp($23) unsigned long value, __zp($2a) unsigned long sub)
ultoa_append: {
    .label buffer = $45
    .label value = $23
    .label sub = $2a
    .label return = $23
    // [1258] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1258] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [1258] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1259] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [1260] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1261] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1262] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [1263] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [1258] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1258] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1258] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
