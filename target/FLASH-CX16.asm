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
  ///< Check I/O errors.
  .const CBM_CHRIN = $ffcf
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
  .const SIZEOF_STRUCT___0 = $8f
  .const SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER = $c
  .const SIZEOF_STRUCT___1 = $88
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
    // [3] phi from __start::__init1 to __start::@2 [phi:__start::__init1->__start::@2]
    // __start::@2
    // #pragma constructor_for(conio_x16_init, cputc, clrscr, cscroll)
    // [4] call conio_x16_init
    // [8] phi from __start::@2 to conio_x16_init [phi:__start::@2->conio_x16_init]
    jsr conio_x16_init
    // [5] phi from __start::@2 to __start::@1 [phi:__start::@2->__start::@1]
    // __start::@1
    // [6] call main
    // [60] phi from __start::@1 to main [phi:__start::@1->main]
    jsr main
    // __start::@return
    // [7] return 
    rts
}
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    // screenlayer1()
    // [9] call screenlayer1
    jsr screenlayer1
    // [10] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [11] call textcolor
    // [472] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [12] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [13] call bgcolor
    // [477] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [14] phi from conio_x16_init::@2 to conio_x16_init::@3 [phi:conio_x16_init::@2->conio_x16_init::@3]
    // conio_x16_init::@3
    // cursor(0)
    // [15] call cursor
    jsr cursor
    // [16] phi from conio_x16_init::@3 to conio_x16_init::@4 [phi:conio_x16_init::@3->conio_x16_init::@4]
    // conio_x16_init::@4
    // cbm_k_plot_get()
    // [17] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [18] cbm_k_plot_get::return#2 = cbm_k_plot_get::return#0
    // conio_x16_init::@5
    // [19] conio_x16_init::$4 = cbm_k_plot_get::return#2
    // BYTE1(cbm_k_plot_get())
    // [20] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbum1=_byte1_vwum2 
    lda __4+1
    sta __5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [21] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbum1 
    sta __conio
    // cbm_k_plot_get()
    // [22] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [23] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [24] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [25] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbum1=_byte0_vwum2 
    lda __6
    sta __7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [26] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbum1 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [27] gotoxy::x#1 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta gotoxy.x
    // [28] gotoxy::y#1 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta gotoxy.y
    // [29] call gotoxy
    // [490] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
    jsr gotoxy
    // conio_x16_init::@7
    // __conio.scroll[0] = 1
    // [30] *((char *)&__conio+$f) = 1 -- _deref_pbuc1=vbuc2 
    lda #1
    sta __conio+$f
    // __conio.scroll[1] = 1
    // [31] *((char *)&__conio+$f+1) = 1 -- _deref_pbuc1=vbuc2 
    sta __conio+$f+1
    // conio_x16_init::@return
    // }
    // [32] return 
    rts
  .segment Data
    .label __4 = cbm_k_plot_get.return
    __5: .byte 0
    .label __6 = cbm_k_plot_get.return
    __7: .byte 0
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__mem() char c)
cputc: {
    .const OFFSET_STACK_C = 0
    // [33] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbum1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta c
    // if(c=='\n')
    // [34] if(cputc::c#0==' 'pm) goto cputc::@1 -- vbum1_eq_vbuc1_then_la1 
  .encoding "petscii_mixed"
    lda #'\n'
    cmp c
    beq __b1
    // cputc::@2
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [35] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [36] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbum1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta __1
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [37] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [38] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbum1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta __2
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [39] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [40] cputc::$3 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta __3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [41] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [42] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbum1 
    lda c
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [43] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // if(!__conio.hscroll[__conio.layer])
    // [44] if(0==((char *)&__conio+$11)[*((char *)&__conio+2)]) goto cputc::@5 -- 0_eq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$11,y
    cmp #0
    beq __b5
    // cputc::@3
    // if(__conio.cursor_x >= __conio.mapwidth)
    // [45] if(*((char *)&__conio)>=*((char *)&__conio+8)) goto cputc::@6 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+8
    bcs __b6
    // cputc::@4
    // __conio.cursor_x++;
    // [46] *((char *)&__conio) = ++ *((char *)&__conio) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio
    // cputc::@7
  __b7:
    // __conio.offset++;
    // [47] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // [48] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // cputc::@return
    // }
    // [49] return 
    rts
    // [50] phi from cputc::@3 to cputc::@6 [phi:cputc::@3->cputc::@6]
    // cputc::@6
  __b6:
    // cputln()
    // [51] call cputln
    jsr cputln
    jmp __b7
    // cputc::@5
  __b5:
    // if(__conio.cursor_x >= __conio.width)
    // [52] if(*((char *)&__conio)>=*((char *)&__conio+6)) goto cputc::@8 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+6
    bcs __b8
    // cputc::@9
    // __conio.cursor_x++;
    // [53] *((char *)&__conio) = ++ *((char *)&__conio) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio
    // __conio.offset++;
    // [54] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // [55] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    rts
    // [56] phi from cputc::@5 to cputc::@8 [phi:cputc::@5->cputc::@8]
    // cputc::@8
  __b8:
    // cputln()
    // [57] call cputln
    jsr cputln
    rts
    // [58] phi from cputc to cputc::@1 [phi:cputc->cputc::@1]
    // cputc::@1
  __b1:
    // cputln()
    // [59] call cputln
    jsr cputln
    rts
  .segment Data
    __1: .byte 0
    __2: .byte 0
    __3: .byte 0
    c: .byte 0
}
.segment Code
  // main
main: {
    .const bank_set_bram1_bank = 1
    .const bank_set_bram2_bank = 1
    .const bank_set_bram3_bank = 1
    .const bank_set_bram4_bank = 1
    .label fp = $4e
    .label read_ram_address = $46
    .label read_ram_address_sector = $43
    .label read_ram_address1 = $3f
    .label rom_device = $52
    .label pattern = $4c
    .label pattern1 = $24
    .label __185 = $26
    .label __186 = $3b
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@54
    // cbm_x_charset(3, (char *)0)
    // [62] cbm_x_charset::charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cbm_x_charset.charset
    // [63] cbm_x_charset::offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cbm_x_charset.offset
    sta.z cbm_x_charset.offset+1
    // [64] call cbm_x_charset
    // Set the charset to lower case.
    jsr cbm_x_charset
    // [65] phi from main::@54 to main::@63 [phi:main::@54->main::@63]
    // main::@63
    // textcolor(WHITE)
    // [66] call textcolor
    // [472] phi from main::@63 to textcolor [phi:main::@63->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:main::@63->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [67] phi from main::@63 to main::@64 [phi:main::@63->main::@64]
    // main::@64
    // bgcolor(BLUE)
    // [68] call bgcolor
    // [477] phi from main::@64 to bgcolor [phi:main::@64->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:main::@64->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [69] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
    // scroll(0)
    // [70] call scroll
    jsr scroll
    // [71] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // clrscr()
    // [72] call clrscr
    jsr clrscr
    // [73] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // frame_draw()
    // [74] call frame_draw
    // [540] phi from main::@67 to frame_draw [phi:main::@67->frame_draw]
    jsr frame_draw
    // [75] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // gotoxy(2, 1)
    // [76] call gotoxy
    // [490] phi from main::@68 to gotoxy [phi:main::@68->gotoxy]
    // [490] phi gotoxy::y#25 = 1 [phi:main::@68->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = 2 [phi:main::@68->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [77] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // printf("commander x16 rom flash utility")
    // [78] call printf_str
    // [720] phi from main::@69 to printf_str [phi:main::@69->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@69->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s [phi:main::@69->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [79] phi from main::@69 to main::@70 [phi:main::@69->main::@70]
    // main::@70
    // print_chips()
    // [80] call print_chips
    // [729] phi from main::@70 to print_chips [phi:main::@70->print_chips]
    jsr print_chips
    // [81] phi from main::@70 to main::@1 [phi:main::@70->main::@1]
    // [81] phi main::rom_chip#10 = 0 [phi:main::@70->main::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [81] phi main::flash_rom_address#10 = 0 [phi:main::@70->main::@1#1] -- vdum1=vduc1 
    sta flash_rom_address
    sta flash_rom_address+1
    lda #<0>>$10
    sta flash_rom_address+2
    lda #>0>>$10
    sta flash_rom_address+3
    // main::@1
  __b1:
    // for (unsigned long flash_rom_address = 0; flash_rom_address < 8 * 0x80000; flash_rom_address += 0x80000)
    // [82] if(main::flash_rom_address#10<8*$80000) goto main::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [84] phi from main::CLI1 to main::@55 [phi:main::CLI1->main::@55]
    // main::@55
    // print_clear()
    // [85] call print_clear
    // [760] phi from main::@55 to print_clear [phi:main::@55->print_clear]
    jsr print_clear
    // [86] phi from main::@55 to main::@76 [phi:main::@55->main::@76]
    // main::@76
    // printf("%s", "press a key to start flashing.")
    // [87] call printf_string
    // [769] phi from main::@76 to printf_string [phi:main::@76->printf_string]
    // [769] phi printf_string::str#12 = main::str [phi:main::@76->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [769] phi printf_string::format_min_length#12 = 0 [phi:main::@76->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [88] phi from main::@76 to main::@77 [phi:main::@76->main::@77]
    // main::@77
    // wait_key()
    // [89] call wait_key
  // Ensure the ROM is set to BASIC.
    // [786] phi from main::@77 to wait_key [phi:main::@77->wait_key]
    jsr wait_key
    // [90] phi from main::@77 to main::@78 [phi:main::@77->main::@78]
    // main::@78
    // print_clear()
    // [91] call print_clear
    // [760] phi from main::@78 to print_clear [phi:main::@78->print_clear]
    jsr print_clear
    // [92] phi from main::@78 to main::@11 [phi:main::@78->main::@11]
    // [92] phi main::flash_chip#10 = 7 [phi:main::@78->main::@11#0] -- vbum1=vbuc1 
    lda #7
    sta flash_chip
    // main::@11
  __b11:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [93] if(main::flash_chip#10!=$ff) goto main::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp flash_chip
    beq !__b12+
    jmp __b12
  !__b12:
    // [94] phi from main::@11 to main::@13 [phi:main::@11->main::@13]
    // main::@13
    // bank_set_brom(0)
    // [95] call bank_set_brom
    // [796] phi from main::@13 to bank_set_brom [phi:main::@13->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 0 [phi:main::@13->bank_set_brom#0] -- vbum1=vbuc1 
    lda #0
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [96] phi from main::@13 to main::@91 [phi:main::@13->main::@91]
    // main::@91
    // textcolor(WHITE)
    // [97] call textcolor
    // [472] phi from main::@91 to textcolor [phi:main::@91->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:main::@91->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [98] phi from main::@91 to main::@49 [phi:main::@91->main::@49]
    // [98] phi main::w#2 = $80 [phi:main::@91->main::@49#0] -- vwsm1=vwsc1 
    lda #<$80
    sta w
    lda #>$80
    sta w+1
    // main::@49
  __b49:
    // for (int w = 128; w >= 0; w--)
    // [99] if(main::w#2>=0) goto main::@51 -- vwsm1_ge_0_then_la1 
    lda w+1
    bpl __b6
    // [100] phi from main::@49 to main::@50 [phi:main::@49->main::@50]
    // main::@50
    // system_reset()
    // [101] call system_reset
    // [799] phi from main::@50 to system_reset [phi:main::@50->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [102] return 
    rts
    // [103] phi from main::@49 to main::@51 [phi:main::@49->main::@51]
  __b6:
    // [103] phi main::v#2 = 0 [phi:main::@49->main::@51#0] -- vwum1=vwuc1 
    lda #<0
    sta v
    sta v+1
    // main::@51
  __b51:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [104] if(main::v#2<$100*$80) goto main::@52 -- vwum1_lt_vwuc1_then_la1 
    lda v+1
    cmp #>$100*$80
    bcc __b52
    bne !+
    lda v
    cmp #<$100*$80
    bcc __b52
  !:
    // [105] phi from main::@51 to main::@53 [phi:main::@51->main::@53]
    // main::@53
    // print_clear()
    // [106] call print_clear
    // [760] phi from main::@53 to print_clear [phi:main::@53->print_clear]
    jsr print_clear
    // [107] phi from main::@53 to main::@169 [phi:main::@53->main::@169]
    // main::@169
    // printf("resetting commander x16 (%i)", w)
    // [108] call printf_str
    // [720] phi from main::@169 to printf_str [phi:main::@169->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@169->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s21 [phi:main::@169->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@170
    // printf("resetting commander x16 (%i)", w)
    // [109] printf_sint::value#1 = main::w#2 -- vwsm1=vwsm2 
    lda w
    sta printf_sint.value
    lda w+1
    sta printf_sint.value+1
    // [110] call printf_sint
    jsr printf_sint
    // [111] phi from main::@170 to main::@171 [phi:main::@170->main::@171]
    // main::@171
    // printf("resetting commander x16 (%i)", w)
    // [112] call printf_str
    // [720] phi from main::@171 to printf_str [phi:main::@171->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@171->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s22 [phi:main::@171->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@172
    // for (int w = 128; w >= 0; w--)
    // [113] main::w#1 = -- main::w#2 -- vwsm1=_dec_vwsm1 
    lda w
    bne !+
    dec w+1
  !:
    dec w
    // [98] phi from main::@172 to main::@49 [phi:main::@172->main::@49]
    // [98] phi main::w#2 = main::w#1 [phi:main::@172->main::@49#0] -- register_copy 
    jmp __b49
    // main::@52
  __b52:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [114] main::v#1 = ++ main::v#2 -- vwum1=_inc_vwum1 
    inc v
    bne !+
    inc v+1
  !:
    // [103] phi from main::@52 to main::@51 [phi:main::@52->main::@51]
    // [103] phi main::v#2 = main::v#1 [phi:main::@52->main::@51#0] -- register_copy 
    jmp __b51
    // main::@12
  __b12:
    // if (rom_device_ids[flash_chip] != UNKNOWN)
    // [115] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@14 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b14+
    jmp __b14
  !__b14:
    // [116] phi from main::@12 to main::@47 [phi:main::@12->main::@47]
    // main::@47
    // gotoxy(0, 2)
    // [117] call gotoxy
    // [490] phi from main::@47 to gotoxy [phi:main::@47->gotoxy]
    // [490] phi gotoxy::y#25 = 2 [phi:main::@47->gotoxy#0] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = 0 [phi:main::@47->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [118] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [119] phi from main::bank_set_bram1 to main::@56 [phi:main::bank_set_bram1->main::@56]
    // main::@56
    // bank_set_brom(0)
    // [120] call bank_set_brom
    // [796] phi from main::@56 to bank_set_brom [phi:main::@56->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 0 [phi:main::@56->bank_set_brom#0] -- vbum1=vbuc1 
    lda #0
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [121] phi from main::@56 to main::@92 [phi:main::@56->main::@92]
    // main::@92
    // strcpy(file, "rom")
    // [122] call strcpy
    // [815] phi from main::@92 to strcpy [phi:main::@92->strcpy]
    jsr strcpy
    // main::@93
    // if (flash_chip != 0)
    // [123] if(main::flash_chip#10==0) goto main::@15 -- vbum1_eq_0_then_la1 
    lda flash_chip
    beq __b15
    // [124] phi from main::@93 to main::@48 [phi:main::@93->main::@48]
    // main::@48
    // size_t len = strlen(file)
    // [125] call strlen
    // [823] phi from main::@48 to strlen [phi:main::@48->strlen]
    // [823] phi strlen::str#9 = file [phi:main::@48->strlen#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strlen.str
    lda #>file
    sta.z strlen.str+1
    jsr strlen
    // size_t len = strlen(file)
    // [126] strlen::return#14 = strlen::len#2
    // main::@100
    // [127] main::len#0 = strlen::return#14
    // 0x30 + flash_chip
    // [128] main::$53 = $30 + main::flash_chip#10 -- vbum1=vbuc1_plus_vbum2 
    lda #$30
    clc
    adc flash_chip
    sta __53
    // file[len] = 0x30 + flash_chip
    // [129] main::$185 = file + main::len#0 -- pbuz1=pbuc1_plus_vwum2 
    lda len
    clc
    adc #<file
    sta.z __185
    lda len+1
    adc #>file
    sta.z __185+1
    // [130] *main::$185 = main::$53 -- _deref_pbuz1=vbum2 
    lda __53
    ldy #0
    sta (__185),y
    // file[len+1] = '\0'
    // [131] main::$186 = file+1 + main::len#0 -- pbuz1=pbuc1_plus_vwum2 
    lda len
    clc
    adc #<file+1
    sta.z __186
    lda len+1
    adc #>file+1
    sta.z __186+1
    // [132] *main::$186 = '?'pm -- _deref_pbuz1=vbuc1 
    lda #'\$00'
    sta (__186),y
    // [133] phi from main::@100 main::@93 to main::@15 [phi:main::@100/main::@93->main::@15]
    // main::@15
  __b15:
    // strcat(file, ".bin")
    // [134] call strcat
    // [829] phi from main::@15 to strcat [phi:main::@15->strcat]
    jsr strcat
    // [135] phi from main::@15 to main::@94 [phi:main::@15->main::@94]
    // main::@94
    // print_clear()
    // [136] call print_clear
    // [760] phi from main::@94 to print_clear [phi:main::@94->print_clear]
    jsr print_clear
    // [137] phi from main::@94 to main::@95 [phi:main::@94->main::@95]
    // main::@95
    // printf("opening %s.", file)
    // [138] call printf_str
    // [720] phi from main::@95 to printf_str [phi:main::@95->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@95->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s1 [phi:main::@95->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [139] phi from main::@95 to main::@96 [phi:main::@95->main::@96]
    // main::@96
    // printf("opening %s.", file)
    // [140] call printf_string
    // [769] phi from main::@96 to printf_string [phi:main::@96->printf_string]
    // [769] phi printf_string::str#12 = file [phi:main::@96->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [769] phi printf_string::format_min_length#12 = 0 [phi:main::@96->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [141] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // printf("opening %s.", file)
    // [142] call printf_str
    // [720] phi from main::@97 to printf_str [phi:main::@97->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@97->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s2 [phi:main::@97->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@98
    // unsigned char flash_rom_bank = flash_chip * 32
    // [143] main::flash_rom_bank#0 = main::flash_chip#10 << 5 -- vbum1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta flash_rom_bank
    // FILE *fp = fopen(1, 8, 2, file)
    // [144] call fopen
    // Read the file content.
    jsr fopen
    // [145] fopen::return#4 = fopen::return#1
    // main::@99
    // [146] main::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [147] if((struct $1 *)0!=main::fp#0) goto main::@16 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    beq !__b16+
    jmp __b16
  !__b16:
    lda.z fp
    cmp #<0
    beq !__b16+
    jmp __b16
  !__b16:
    // main::@45
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [148] print_chip_led::r#6 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [149] call print_chip_led
    // [899] phi from main::@45 to print_chip_led [phi:main::@45->print_chip_led]
    // [899] phi print_chip_led::tc#10 = DARK_GREY [phi:main::@45->print_chip_led#0] -- vbum1=vbuc1 
    lda #DARK_GREY
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#6 [phi:main::@45->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [150] phi from main::@45 to main::@113 [phi:main::@45->main::@113]
    // main::@113
    // print_clear()
    // [151] call print_clear
    // [760] phi from main::@113 to print_clear [phi:main::@113->print_clear]
    jsr print_clear
    // [152] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [153] call printf_str
    // [720] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s5 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [154] phi from main::@114 to main::@115 [phi:main::@114->main::@115]
    // main::@115
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [155] call printf_string
    // [769] phi from main::@115 to printf_string [phi:main::@115->printf_string]
    // [769] phi printf_string::str#12 = file [phi:main::@115->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [769] phi printf_string::format_min_length#12 = 0 [phi:main::@115->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [156] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [157] call printf_str
    // [720] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s6 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@117
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [158] printf_uchar::uvalue#5 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [159] call printf_uchar
    // [919] phi from main::@117 to printf_uchar [phi:main::@117->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@117->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 0 [phi:main::@117->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@117->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#5 [phi:main::@117->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [160] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [161] call printf_str
    // [720] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s7 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // flash_chip * 10
    // [162] main::$193 = main::flash_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda flash_chip
    asl
    asl
    sta __193
    // [163] main::$194 = main::$193 + main::flash_chip#10 -- vbum1=vbum1_plus_vbum2 
    lda __194
    clc
    adc flash_chip
    sta __194
    // [164] main::$63 = main::$194 << 1 -- vbum1=vbum1_rol_1 
    asl __63
    // gotoxy(2 + flash_chip * 10, 58)
    // [165] gotoxy::x#19 = 2 + main::$63 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc __63
    sta gotoxy.x
    // [166] call gotoxy
    // [490] phi from main::@119 to gotoxy [phi:main::@119->gotoxy]
    // [490] phi gotoxy::y#25 = $3a [phi:main::@119->gotoxy#0] -- vbum1=vbuc1 
    lda #$3a
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = gotoxy::x#19 [phi:main::@119->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [167] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // printf("no file")
    // [168] call printf_str
    // [720] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s8 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@17
  __b17:
    // if (flash_chip != 0)
    // [169] if(main::flash_chip#10==0) goto main::@14 -- vbum1_eq_0_then_la1 
    lda flash_chip
    beq __b14
    // [170] phi from main::@17 to main::@46 [phi:main::@17->main::@46]
    // main::@46
    // bank_set_brom(4)
    // [171] call bank_set_brom
    // [796] phi from main::@46 to bank_set_brom [phi:main::@46->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 4 [phi:main::@46->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // [173] phi from main::CLI3 to main::@62 [phi:main::CLI3->main::@62]
    // main::@62
    // wait_key()
    // [174] call wait_key
    // [786] phi from main::@62 to wait_key [phi:main::@62->wait_key]
    jsr wait_key
    // main::SEI4
    // asm
    // asm { sei  }
    sei
    // main::@14
  __b14:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [176] main::flash_chip#1 = -- main::flash_chip#10 -- vbum1=_dec_vbum1 
    dec flash_chip
    // [92] phi from main::@14 to main::@11 [phi:main::@14->main::@11]
    // [92] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@14->main::@11#0] -- register_copy 
    jmp __b11
    // main::@16
  __b16:
    // table_chip_clear(flash_chip * 32)
    // [177] table_chip_clear::rom_bank#1 = main::flash_chip#10 << 5 -- vbum1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta table_chip_clear.rom_bank
    // [178] call table_chip_clear
    // [929] phi from main::@16 to table_chip_clear [phi:main::@16->table_chip_clear]
    jsr table_chip_clear
    // [179] phi from main::@16 to main::@101 [phi:main::@16->main::@101]
    // main::@101
    // textcolor(WHITE)
    // [180] call textcolor
    // [472] phi from main::@101 to textcolor [phi:main::@101->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:main::@101->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@102
    // flash_chip * 10
    // [181] main::$170 = main::flash_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda flash_chip
    asl
    asl
    sta __170
    // [182] main::$191 = main::$170 + main::flash_chip#10 -- vbum1=vbum2_plus_vbum3 
    clc
    adc flash_chip
    sta __191
    // [183] main::$70 = main::$191 << 1 -- vbum1=vbum1_rol_1 
    asl __70
    // gotoxy(2 + flash_chip * 10, 58)
    // [184] gotoxy::x#18 = 2 + main::$70 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc __70
    sta gotoxy.x
    // [185] call gotoxy
    // [490] phi from main::@102 to gotoxy [phi:main::@102->gotoxy]
    // [490] phi gotoxy::y#25 = $3a [phi:main::@102->gotoxy#0] -- vbum1=vbuc1 
    lda #$3a
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = gotoxy::x#18 [phi:main::@102->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [186] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // printf("%s", file)
    // [187] call printf_string
    // [769] phi from main::@103 to printf_string [phi:main::@103->printf_string]
    // [769] phi printf_string::str#12 = file [phi:main::@103->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [769] phi printf_string::format_min_length#12 = 0 [phi:main::@103->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@104
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [188] print_chip_led::r#5 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [189] call print_chip_led
    // [899] phi from main::@104 to print_chip_led [phi:main::@104->print_chip_led]
    // [899] phi print_chip_led::tc#10 = CYAN [phi:main::@104->print_chip_led#0] -- vbum1=vbuc1 
    lda #CYAN
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#5 [phi:main::@104->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [190] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // print_clear()
    // [191] call print_clear
    // [760] phi from main::@105 to print_clear [phi:main::@105->print_clear]
    jsr print_clear
    // [192] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [193] call printf_str
    // [720] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s3 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [194] printf_uchar::uvalue#4 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [195] call printf_uchar
    // [919] phi from main::@107 to printf_uchar [phi:main::@107->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@107->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 0 [phi:main::@107->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@107->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#4 [phi:main::@107->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [196] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [197] call printf_str
    // [720] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s4 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [198] rom_address::rom_bank#2 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta rom_address.rom_bank
    // [199] call rom_address
    // [954] phi from main::@109 to rom_address [phi:main::@109->rom_address]
    // [954] phi rom_address::rom_bank#5 = rom_address::rom_bank#2 [phi:main::@109->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [200] rom_address::return#10 = rom_address::return#0 -- vdum1=vdum2 
    lda rom_address.return
    sta rom_address.return_2
    lda rom_address.return+1
    sta rom_address.return_2+1
    lda rom_address.return+2
    sta rom_address.return_2+2
    lda rom_address.return+3
    sta rom_address.return_2+3
    // main::@110
    // [201] main::flash_rom_address_boundary#0 = rom_address::return#10
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, size)
    // [202] flash_read::fp#0 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [203] flash_read::rom_bank_start#1 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta flash_read.rom_bank_start
    // [204] call flash_read
    // [958] phi from main::@110 to flash_read [phi:main::@110->flash_read]
    // [958] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@110->flash_read#0] -- register_copy 
    // [958] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@110->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [958] phi flash_read::read_size#4 = $4000 [phi:main::@110->flash_read#2] -- vdum1=vduc1 
    lda #<$4000
    sta flash_read.read_size
    lda #>$4000
    sta flash_read.read_size+1
    lda #<$4000>>$10
    sta flash_read.read_size+2
    lda #>$4000>>$10
    sta flash_read.read_size+3
    // [958] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@110->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, size)
    // [205] flash_read::return#3 = flash_read::return#2
    // main::@111
    // [206] main::flash_bytes#0 = flash_read::return#3 -- vdum1=vdum2 
    lda flash_read.return
    sta flash_bytes
    lda flash_read.return+1
    sta flash_bytes+1
    lda flash_read.return+2
    sta flash_bytes+2
    lda flash_read.return+3
    sta flash_bytes+3
    // rom_size(1)
    // [207] call rom_size
    // [990] phi from main::@111 to rom_size [phi:main::@111->rom_size]
    jsr rom_size
    // main::@112
    // if (flash_bytes != rom_size(1))
    // [208] if(main::flash_bytes#0==rom_size::return#0) goto main::@18 -- vdum1_eq_vduc1_then_la1 
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
    beq __b18
  !:
    rts
    // main::@18
  __b18:
    // flash_rom_address_boundary += flash_bytes
    // [209] main::flash_rom_address_boundary#1 = main::flash_rom_address_boundary#0 + main::flash_bytes#0 -- vdum1=vdum2_plus_vdum1 
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
    // main::bank_set_bram2
    // BRAM = bank
    // [210] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@57
    // size = rom_sizes[flash_chip]
    // [211] main::size#1 = main::rom_sizes[main::$170] -- vdum1=pduc1_derefidx_vbum2 
    // read from bank 1 in bram.
    ldy __170
    lda rom_sizes,y
    sta size
    lda rom_sizes+1,y
    sta size+1
    lda rom_sizes+2,y
    sta size+2
    lda rom_sizes+3,y
    sta size+3
    // size -= 0x4000
    // [212] main::size#2 = main::size#1 - $4000 -- vdum1=vdum1_minus_vduc1 
    lda size
    sec
    sbc #<$4000
    sta size
    lda size+1
    sbc #>$4000
    sta size+1
    lda size+2
    sbc #<$4000>>$10
    sta size+2
    lda size+3
    sbc #>$4000>>$10
    sta size+3
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [213] flash_read::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbum1=vbum2_plus_1 
    lda flash_rom_bank
    inc
    sta flash_read.rom_bank_start
    // [214] flash_read::fp#1 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [215] flash_read::read_size#1 = main::size#2
    // [216] call flash_read
    // [958] phi from main::@57 to flash_read [phi:main::@57->flash_read]
    // [958] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@57->flash_read#0] -- register_copy 
    // [958] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@57->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [958] phi flash_read::read_size#4 = flash_read::read_size#1 [phi:main::@57->flash_read#2] -- register_copy 
    // [958] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@57->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [217] flash_read::return#4 = flash_read::return#2
    // main::@121
    // flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [218] main::flash_bytes#1 = flash_read::return#4 -- vdum1=vdum2 
    lda flash_read.return
    sta flash_bytes_1
    lda flash_read.return+1
    sta flash_bytes_1+1
    lda flash_read.return+2
    sta flash_bytes_1+2
    lda flash_read.return+3
    sta flash_bytes_1+3
    // flash_rom_address_boundary += flash_bytes
    // [219] main::flash_rom_address_boundary#11 = main::flash_rom_address_boundary#1 + main::flash_bytes#1 -- vdum1=vdum2_plus_vdum1 
    clc
    lda flash_rom_address_boundary_2
    adc flash_rom_address_boundary_1
    sta flash_rom_address_boundary_2
    lda flash_rom_address_boundary_2+1
    adc flash_rom_address_boundary_1+1
    sta flash_rom_address_boundary_2+1
    lda flash_rom_address_boundary_2+2
    adc flash_rom_address_boundary_1+2
    sta flash_rom_address_boundary_2+2
    lda flash_rom_address_boundary_2+3
    adc flash_rom_address_boundary_1+3
    sta flash_rom_address_boundary_2+3
    // fclose(fp)
    // [220] fclose::stream#0 = main::fp#0
    // [221] call fclose
    jsr fclose
    // main::bank_set_bram3
    // BRAM = bank
    // [222] BRAM = main::bank_set_bram3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram3_bank
    sta.z BRAM
    // [223] phi from main::bank_set_bram3 to main::@58 [phi:main::bank_set_bram3->main::@58]
    // main::@58
    // bank_set_brom(4)
    // [224] call bank_set_brom
    // [796] phi from main::@58 to bank_set_brom [phi:main::@58->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 4 [phi:main::@58->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [225] phi from main::@58 to main::@122 [phi:main::@58->main::@122]
    // main::@122
    // print_clear()
    // [226] call print_clear
  // Now we compare the RAM with the actual ROM contents.
    // [760] phi from main::@122 to print_clear [phi:main::@122->print_clear]
    jsr print_clear
    // [227] phi from main::@122 to main::@123 [phi:main::@122->main::@123]
    // main::@123
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [228] call printf_str
    // [720] phi from main::@123 to printf_str [phi:main::@123->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@123->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s9 [phi:main::@123->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@124
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [229] printf_uchar::uvalue#6 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [230] call printf_uchar
    // [919] phi from main::@124 to printf_uchar [phi:main::@124->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@124->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 0 [phi:main::@124->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@124->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#6 [phi:main::@124->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [231] phi from main::@124 to main::@125 [phi:main::@124->main::@125]
    // main::@125
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [232] call printf_str
    // [720] phi from main::@125 to printf_str [phi:main::@125->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@125->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s10 [phi:main::@125->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@126
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [233] rom_address::rom_bank#3 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta rom_address.rom_bank
    // [234] call rom_address
    // [954] phi from main::@126 to rom_address [phi:main::@126->rom_address]
    // [954] phi rom_address::rom_bank#5 = rom_address::rom_bank#3 [phi:main::@126->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [235] rom_address::return#11 = rom_address::return#0 -- vdum1=vdum2 
    lda rom_address.return
    sta rom_address.return_3
    lda rom_address.return+1
    sta rom_address.return_3+1
    lda rom_address.return+2
    sta rom_address.return_3+2
    lda rom_address.return+3
    sta rom_address.return_3+3
    // main::@127
    // [236] main::flash_rom_address1#0 = rom_address::return#11
    // gotoxy(x, y)
    // [237] call gotoxy
    // [490] phi from main::@127 to gotoxy [phi:main::@127->gotoxy]
    // [490] phi gotoxy::y#25 = 4 [phi:main::@127->gotoxy#0] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = $e [phi:main::@127->gotoxy#1] -- vbum1=vbuc1 
    lda #$e
    sta gotoxy.x
    jsr gotoxy
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [239] phi from main::SEI2 to main::@19 [phi:main::SEI2->main::@19]
    // [239] phi main::y_sector#10 = 4 [phi:main::SEI2->main::@19#0] -- vbum1=vbuc1 
    lda #4
    sta y_sector
    // [239] phi main::x_sector#10 = $e [phi:main::SEI2->main::@19#1] -- vbum1=vbuc1 
    lda #$e
    sta x_sector
    // [239] phi main::read_ram_address#10 = (char *) 16384 [phi:main::SEI2->main::@19#2] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address
    lda #>$4000
    sta.z read_ram_address+1
    // [239] phi main::read_ram_bank#13 = 0 [phi:main::SEI2->main::@19#3] -- vbum1=vbuc1 
    lda #0
    sta read_ram_bank
    // [239] phi main::flash_rom_address1#13 = main::flash_rom_address1#0 [phi:main::SEI2->main::@19#4] -- register_copy 
    // [239] phi from main::@25 to main::@19 [phi:main::@25->main::@19]
    // [239] phi main::y_sector#10 = main::y_sector#10 [phi:main::@25->main::@19#0] -- register_copy 
    // [239] phi main::x_sector#10 = main::x_sector#1 [phi:main::@25->main::@19#1] -- register_copy 
    // [239] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@25->main::@19#2] -- register_copy 
    // [239] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@25->main::@19#3] -- register_copy 
    // [239] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@25->main::@19#4] -- register_copy 
    // main::@19
  __b19:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [240] if(main::flash_rom_address1#13<main::flash_rom_address_boundary#11) goto main::@20 -- vdum1_lt_vdum2_then_la1 
    lda flash_rom_address1+3
    cmp flash_rom_address_boundary_2+3
    bcs !__b20+
    jmp __b20
  !__b20:
    bne !+
    lda flash_rom_address1+2
    cmp flash_rom_address_boundary_2+2
    bcs !__b20+
    jmp __b20
  !__b20:
    bne !+
    lda flash_rom_address1+1
    cmp flash_rom_address_boundary_2+1
    bcs !__b20+
    jmp __b20
  !__b20:
    bne !+
    lda flash_rom_address1
    cmp flash_rom_address_boundary_2
    bcs !__b20+
    jmp __b20
  !__b20:
  !:
    // [241] phi from main::@19 to main::@21 [phi:main::@19->main::@21]
    // main::@21
    // print_clear()
    // [242] call print_clear
    // [760] phi from main::@21 to print_clear [phi:main::@21->print_clear]
    jsr print_clear
    // [243] phi from main::@21 to main::@129 [phi:main::@21->main::@129]
    // main::@129
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [244] call printf_str
    // [720] phi from main::@129 to printf_str [phi:main::@129->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@129->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s11 [phi:main::@129->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@130
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [245] printf_uchar::uvalue#7 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [246] call printf_uchar
    // [919] phi from main::@130 to printf_uchar [phi:main::@130->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@130->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 0 [phi:main::@130->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@130->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#7 [phi:main::@130->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [247] phi from main::@130 to main::@131 [phi:main::@130->main::@131]
    // main::@131
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [248] call printf_str
    // [720] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s12 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // [249] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // bank_set_brom(4)
    // [250] call bank_set_brom
    // [796] phi from main::@132 to bank_set_brom [phi:main::@132->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 4 [phi:main::@132->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [252] phi from main::CLI2 to main::@59 [phi:main::CLI2->main::@59]
    // main::@59
    // wait_key()
    // [253] call wait_key
    // [786] phi from main::@59 to wait_key [phi:main::@59->wait_key]
    jsr wait_key
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::@60
    // rom_address(flash_rom_bank)
    // [255] rom_address::rom_bank#4 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta rom_address.rom_bank
    // [256] call rom_address
    // [954] phi from main::@60 to rom_address [phi:main::@60->rom_address]
    // [954] phi rom_address::rom_bank#5 = rom_address::rom_bank#4 [phi:main::@60->rom_address#0] -- register_copy 
    jsr rom_address
    // rom_address(flash_rom_bank)
    // [257] rom_address::return#12 = rom_address::return#0 -- vdum1=vdum2 
    lda rom_address.return
    sta rom_address.return_4
    lda rom_address.return+1
    sta rom_address.return_4+1
    lda rom_address.return+2
    sta rom_address.return_4+2
    lda rom_address.return+3
    sta rom_address.return_4+3
    // main::@133
    // flash_rom_address_sector = rom_address(flash_rom_bank)
    // [258] main::flash_rom_address_sector#1 = rom_address::return#12
    // textcolor(WHITE)
    // [259] call textcolor
    // [472] phi from main::@133 to textcolor [phi:main::@133->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:main::@133->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@134
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [260] print_chip_led::r#7 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [261] call print_chip_led
    // [899] phi from main::@134 to print_chip_led [phi:main::@134->print_chip_led]
    // [899] phi print_chip_led::tc#10 = PURPLE [phi:main::@134->print_chip_led#0] -- vbum1=vbuc1 
    lda #PURPLE
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#7 [phi:main::@134->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [262] phi from main::@134 to main::@135 [phi:main::@134->main::@135]
    // main::@135
    // print_clear()
    // [263] call print_clear
    // [760] phi from main::@135 to print_clear [phi:main::@135->print_clear]
    jsr print_clear
    // [264] phi from main::@135 to main::@136 [phi:main::@135->main::@136]
    // main::@136
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [265] call printf_str
    // [720] phi from main::@136 to printf_str [phi:main::@136->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@136->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s13 [phi:main::@136->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@137
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [266] printf_uchar::uvalue#8 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [267] call printf_uchar
    // [919] phi from main::@137 to printf_uchar [phi:main::@137->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@137->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 0 [phi:main::@137->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@137->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#8 [phi:main::@137->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [268] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [269] call printf_str
    // [720] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s14 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // [270] phi from main::@138 to main::@28 [phi:main::@138->main::@28]
    // [270] phi main::flash_errors_sector#10 = 0 [phi:main::@138->main::@28#0] -- vwum1=vwuc1 
    lda #<0
    sta flash_errors_sector
    sta flash_errors_sector+1
    // [270] phi main::y_sector1#13 = 4 [phi:main::@138->main::@28#1] -- vbum1=vbuc1 
    lda #4
    sta y_sector1
    // [270] phi main::x_sector1#10 = $e [phi:main::@138->main::@28#2] -- vbum1=vbuc1 
    lda #$e
    sta x_sector1
    // [270] phi main::read_ram_address_sector#10 = (char *) 16384 [phi:main::@138->main::@28#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address_sector
    lda #>$4000
    sta.z read_ram_address_sector+1
    // [270] phi main::read_ram_bank_sector#13 = 0 [phi:main::@138->main::@28#4] -- vbum1=vbuc1 
    lda #0
    sta read_ram_bank_sector
    // [270] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#1 [phi:main::@138->main::@28#5] -- register_copy 
    // [270] phi from main::@39 to main::@28 [phi:main::@39->main::@28]
    // [270] phi main::flash_errors_sector#10 = main::flash_errors_sector#19 [phi:main::@39->main::@28#0] -- register_copy 
    // [270] phi main::y_sector1#13 = main::y_sector1#13 [phi:main::@39->main::@28#1] -- register_copy 
    // [270] phi main::x_sector1#10 = main::x_sector1#1 [phi:main::@39->main::@28#2] -- register_copy 
    // [270] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@39->main::@28#3] -- register_copy 
    // [270] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@39->main::@28#4] -- register_copy 
    // [270] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@39->main::@28#5] -- register_copy 
    // main::@28
  __b28:
    // while (flash_rom_address_sector < flash_rom_address_boundary)
    // [271] if(main::flash_rom_address_sector#11<main::flash_rom_address_boundary#11) goto main::@29 -- vdum1_lt_vdum2_then_la1 
    lda flash_rom_address_sector+3
    cmp flash_rom_address_boundary_2+3
    bcs !__b29+
    jmp __b29
  !__b29:
    bne !+
    lda flash_rom_address_sector+2
    cmp flash_rom_address_boundary_2+2
    bcs !__b29+
    jmp __b29
  !__b29:
    bne !+
    lda flash_rom_address_sector+1
    cmp flash_rom_address_boundary_2+1
    bcs !__b29+
    jmp __b29
  !__b29:
    bne !+
    lda flash_rom_address_sector
    cmp flash_rom_address_boundary_2
    bcs !__b29+
    jmp __b29
  !__b29:
  !:
    // main::bank_set_bram4
    // BRAM = bank
    // [272] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // [273] phi from main::bank_set_bram4 to main::@61 [phi:main::bank_set_bram4->main::@61]
    // main::@61
    // bank_set_brom(4)
    // [274] call bank_set_brom
    // [796] phi from main::@61 to bank_set_brom [phi:main::@61->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 4 [phi:main::@61->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // main::@144
    // if (!flash_errors_sector)
    // [275] if(0==main::flash_errors_sector#10) goto main::@44 -- 0_eq_vwum1_then_la1 
    lda flash_errors_sector
    ora flash_errors_sector+1
    bne !__b44+
    jmp __b44
  !__b44:
    // [276] phi from main::@144 to main::@43 [phi:main::@144->main::@43]
    // main::@43
    // textcolor(RED)
    // [277] call textcolor
    // [472] phi from main::@43 to textcolor [phi:main::@43->textcolor]
    // [472] phi textcolor::color#23 = RED [phi:main::@43->textcolor#0] -- vbum1=vbuc1 
    lda #RED
    sta textcolor.color
    jsr textcolor
    // main::@162
    // print_chip_led(flash_chip, RED, BLUE)
    // [278] print_chip_led::r#9 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [279] call print_chip_led
    // [899] phi from main::@162 to print_chip_led [phi:main::@162->print_chip_led]
    // [899] phi print_chip_led::tc#10 = RED [phi:main::@162->print_chip_led#0] -- vbum1=vbuc1 
    lda #RED
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#9 [phi:main::@162->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [280] phi from main::@162 to main::@163 [phi:main::@162->main::@163]
    // main::@163
    // print_clear()
    // [281] call print_clear
    // [760] phi from main::@163 to print_clear [phi:main::@163->print_clear]
    jsr print_clear
    // [282] phi from main::@163 to main::@164 [phi:main::@163->main::@164]
    // main::@164
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [283] call printf_str
    // [720] phi from main::@164 to printf_str [phi:main::@164->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@164->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s16 [phi:main::@164->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@165
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [284] printf_uchar::uvalue#10 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [285] call printf_uchar
    // [919] phi from main::@165 to printf_uchar [phi:main::@165->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@165->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 0 [phi:main::@165->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@165->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#10 [phi:main::@165->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [286] phi from main::@165 to main::@166 [phi:main::@165->main::@166]
    // main::@166
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [287] call printf_str
    // [720] phi from main::@166 to printf_str [phi:main::@166->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@166->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s19 [phi:main::@166->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@167
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [288] printf_uint::uvalue#2 = main::flash_errors_sector#10 -- vwum1=vwum2 
    lda flash_errors_sector
    sta printf_uint.uvalue
    lda flash_errors_sector+1
    sta printf_uint.uvalue+1
    // [289] call printf_uint
    // [1004] phi from main::@167 to printf_uint [phi:main::@167->printf_uint]
    // [1004] phi printf_uint::format_min_length#3 = 0 [phi:main::@167->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_min_length
    // [1004] phi printf_uint::format_radix#3 = DECIMAL [phi:main::@167->printf_uint#1] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [1004] phi printf_uint::uvalue#3 = printf_uint::uvalue#2 [phi:main::@167->printf_uint#2] -- register_copy 
    jsr printf_uint
    // [290] phi from main::@167 to main::@168 [phi:main::@167->main::@168]
    // main::@168
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [291] call printf_str
    // [720] phi from main::@168 to printf_str [phi:main::@168->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@168->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s20 [phi:main::@168->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    jmp __b17
    // [292] phi from main::@144 to main::@44 [phi:main::@144->main::@44]
    // main::@44
  __b44:
    // textcolor(GREEN)
    // [293] call textcolor
    // [472] phi from main::@44 to textcolor [phi:main::@44->textcolor]
    // [472] phi textcolor::color#23 = GREEN [phi:main::@44->textcolor#0] -- vbum1=vbuc1 
    lda #GREEN
    sta textcolor.color
    jsr textcolor
    // main::@157
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [294] print_chip_led::r#8 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [295] call print_chip_led
    // [899] phi from main::@157 to print_chip_led [phi:main::@157->print_chip_led]
    // [899] phi print_chip_led::tc#10 = GREEN [phi:main::@157->print_chip_led#0] -- vbum1=vbuc1 
    lda #GREEN
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#8 [phi:main::@157->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [296] phi from main::@157 to main::@158 [phi:main::@157->main::@158]
    // main::@158
    // print_clear()
    // [297] call print_clear
    // [760] phi from main::@158 to print_clear [phi:main::@158->print_clear]
    jsr print_clear
    // [298] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [299] call printf_str
    // [720] phi from main::@159 to printf_str [phi:main::@159->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@159->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s16 [phi:main::@159->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@160
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [300] printf_uchar::uvalue#9 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [301] call printf_uchar
    // [919] phi from main::@160 to printf_uchar [phi:main::@160->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@160->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 0 [phi:main::@160->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@160->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#9 [phi:main::@160->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [302] phi from main::@160 to main::@161 [phi:main::@160->main::@161]
    // main::@161
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [303] call printf_str
    // [720] phi from main::@161 to printf_str [phi:main::@161->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@161->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s17 [phi:main::@161->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    jmp __b17
    // main::@29
  __b29:
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [304] flash_verify::bank_ram#1 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta flash_verify.bank_ram
    // [305] flash_verify::ptr_ram#2 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address_sector+1
    sta.z flash_verify.ptr_ram+1
    // [306] flash_verify::verify_rom_address#1 = main::flash_rom_address_sector#11 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta flash_verify.verify_rom_address
    lda flash_rom_address_sector+1
    sta flash_verify.verify_rom_address+1
    lda flash_rom_address_sector+2
    sta flash_verify.verify_rom_address+2
    lda flash_rom_address_sector+3
    sta flash_verify.verify_rom_address+3
    // [307] call flash_verify
  // rom_sector_erase(flash_rom_address_sector);
    // [1013] phi from main::@29 to flash_verify [phi:main::@29->flash_verify]
    // [1013] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#2 [phi:main::@29->flash_verify#0] -- register_copy 
    // [1013] phi flash_verify::verify_rom_size#11 = $1000 [phi:main::@29->flash_verify#1] -- vwum1=vwuc1 
    lda #<$1000
    sta flash_verify.verify_rom_size
    lda #>$1000
    sta flash_verify.verify_rom_size+1
    // [1013] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#1 [phi:main::@29->flash_verify#2] -- register_copy 
    // [1013] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#1 [phi:main::@29->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [308] flash_verify::return#3 = flash_verify::correct_bytes#2
    // main::@143
    // [309] main::equal_bytes1#0 = flash_verify::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [310] if(main::equal_bytes1#0!=$1000) goto main::@31 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes1+1
    cmp #>$1000
    beq !__b8+
    jmp __b8
  !__b8:
    lda equal_bytes1
    cmp #<$1000
    beq !__b8+
    jmp __b8
  !__b8:
    // [311] phi from main::@143 to main::@40 [phi:main::@143->main::@40]
    // main::@40
    // textcolor(WHITE)
    // [312] call textcolor
    // [472] phi from main::@40 to textcolor [phi:main::@40->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:main::@40->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@145
    // gotoxy(x_sector, y_sector)
    // [313] gotoxy::x#22 = main::x_sector1#10 -- vbum1=vbum2 
    lda x_sector1
    sta gotoxy.x
    // [314] gotoxy::y#22 = main::y_sector1#13 -- vbum1=vbum2 
    lda y_sector1
    sta gotoxy.y
    // [315] call gotoxy
    // [490] phi from main::@145 to gotoxy [phi:main::@145->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#22 [phi:main::@145->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = gotoxy::x#22 [phi:main::@145->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [316] phi from main::@145 to main::@146 [phi:main::@145->main::@146]
    // main::@146
    // printf("%s", pattern)
    // [317] call printf_string
    // [769] phi from main::@146 to printf_string [phi:main::@146->printf_string]
    // [769] phi printf_string::str#12 = main::pattern1#1 [phi:main::@146->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern1_1
    sta.z printf_string.str
    lda #>pattern1_1
    sta.z printf_string.str+1
    // [769] phi printf_string::format_min_length#12 = 0 [phi:main::@146->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [318] phi from main::@146 main::@37 to main::@30 [phi:main::@146/main::@37->main::@30]
    // [318] phi main::flash_errors_sector#19 = main::flash_errors_sector#10 [phi:main::@146/main::@37->main::@30#0] -- register_copy 
    // main::@30
  __b30:
    // read_ram_address_sector += ROM_SECTOR
    // [319] main::read_ram_address_sector#2 = main::read_ram_address_sector#10 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address_sector
    clc
    adc #<$1000
    sta.z read_ram_address_sector
    lda.z read_ram_address_sector+1
    adc #>$1000
    sta.z read_ram_address_sector+1
    // flash_rom_address_sector += ROM_SECTOR
    // [320] main::flash_rom_address_sector#10 = main::flash_rom_address_sector#11 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [321] if(main::read_ram_address_sector#2!=$8000) goto main::@175 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$8000
    bne __b38
    lda.z read_ram_address_sector
    cmp #<$8000
    bne __b38
    // [323] phi from main::@30 to main::@38 [phi:main::@30->main::@38]
    // [323] phi main::read_ram_bank_sector#6 = 1 [phi:main::@30->main::@38#0] -- vbum1=vbuc1 
    lda #1
    sta read_ram_bank_sector
    // [323] phi main::read_ram_address_sector#8 = (char *) 40960 [phi:main::@30->main::@38#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [322] phi from main::@30 to main::@175 [phi:main::@30->main::@175]
    // main::@175
    // [323] phi from main::@175 to main::@38 [phi:main::@175->main::@38]
    // [323] phi main::read_ram_bank_sector#6 = main::read_ram_bank_sector#13 [phi:main::@175->main::@38#0] -- register_copy 
    // [323] phi main::read_ram_address_sector#8 = main::read_ram_address_sector#2 [phi:main::@175->main::@38#1] -- register_copy 
    // main::@38
  __b38:
    // if (read_ram_address_sector == 0xC000)
    // [324] if(main::read_ram_address_sector#8!=$c000) goto main::@39 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$c000
    bne __b39
    lda.z read_ram_address_sector
    cmp #<$c000
    bne __b39
    // main::@41
    // read_ram_bank_sector++;
    // [325] main::read_ram_bank_sector#3 = ++ main::read_ram_bank_sector#6 -- vbum1=_inc_vbum1 
    inc read_ram_bank_sector
    // [326] phi from main::@41 to main::@39 [phi:main::@41->main::@39]
    // [326] phi main::read_ram_address_sector#14 = (char *) 40960 [phi:main::@41->main::@39#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [326] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#3 [phi:main::@41->main::@39#1] -- register_copy 
    // [326] phi from main::@38 to main::@39 [phi:main::@38->main::@39]
    // [326] phi main::read_ram_address_sector#14 = main::read_ram_address_sector#8 [phi:main::@38->main::@39#0] -- register_copy 
    // [326] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#6 [phi:main::@38->main::@39#1] -- register_copy 
    // main::@39
  __b39:
    // x_sector += 16
    // [327] main::x_sector1#1 = main::x_sector1#10 + $10 -- vbum1=vbum1_plus_vbuc1 
    lda #$10
    clc
    adc x_sector1
    sta x_sector1
    // flash_rom_address_sector % 0x4000
    // [328] main::$143 = main::flash_rom_address_sector#10 & $4000-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address_sector
    and #<$4000-1
    sta __143
    lda flash_rom_address_sector+1
    and #>$4000-1
    sta __143+1
    lda flash_rom_address_sector+2
    and #<$4000-1>>$10
    sta __143+2
    lda flash_rom_address_sector+3
    and #>$4000-1>>$10
    sta __143+3
    // if (!(flash_rom_address_sector % 0x4000))
    // [329] if(0!=main::$143) goto main::@28 -- 0_neq_vdum1_then_la1 
    lda __143
    ora __143+1
    ora __143+2
    ora __143+3
    beq !__b28+
    jmp __b28
  !__b28:
    // main::@42
    // y_sector++;
    // [330] main::y_sector1#1 = ++ main::y_sector1#13 -- vbum1=_inc_vbum1 
    inc y_sector1
    // [270] phi from main::@42 to main::@28 [phi:main::@42->main::@28]
    // [270] phi main::flash_errors_sector#10 = main::flash_errors_sector#19 [phi:main::@42->main::@28#0] -- register_copy 
    // [270] phi main::y_sector1#13 = main::y_sector1#1 [phi:main::@42->main::@28#1] -- register_copy 
    // [270] phi main::x_sector1#10 = $e [phi:main::@42->main::@28#2] -- vbum1=vbuc1 
    lda #$e
    sta x_sector1
    // [270] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@42->main::@28#3] -- register_copy 
    // [270] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@42->main::@28#4] -- register_copy 
    // [270] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@42->main::@28#5] -- register_copy 
    jmp __b28
    // [331] phi from main::@143 to main::@31 [phi:main::@143->main::@31]
  __b8:
    // [331] phi main::flash_errors#10 = 0 [phi:main::@143->main::@31#0] -- vbum1=vbuc1 
    lda #0
    sta flash_errors
    // [331] phi main::retries#10 = 0 [phi:main::@143->main::@31#1] -- vbum1=vbuc1 
    sta retries
    // [331] phi from main::@173 to main::@31 [phi:main::@173->main::@31]
    // [331] phi main::flash_errors#10 = main::flash_errors#11 [phi:main::@173->main::@31#0] -- register_copy 
    // [331] phi main::retries#10 = main::retries#1 [phi:main::@173->main::@31#1] -- register_copy 
    // main::@31
  __b31:
    // rom_sector_erase(flash_rom_address_sector)
    // [332] rom_sector_erase::address#0 = main::flash_rom_address_sector#11 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta rom_sector_erase.address
    lda flash_rom_address_sector+1
    sta rom_sector_erase.address+1
    lda flash_rom_address_sector+2
    sta rom_sector_erase.address+2
    lda flash_rom_address_sector+3
    sta rom_sector_erase.address+3
    // [333] call rom_sector_erase
    // [1040] phi from main::@31 to rom_sector_erase [phi:main::@31->rom_sector_erase]
    jsr rom_sector_erase
    // main::@147
    // unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR
    // [334] main::flash_rom_address_boundary1#0 = main::flash_rom_address_sector#11 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [335] gotoxy::x#23 = main::x_sector1#10 -- vbum1=vbum2 
    lda x_sector1
    sta gotoxy.x
    // [336] gotoxy::y#23 = main::y_sector1#13 -- vbum1=vbum2 
    lda y_sector1
    sta gotoxy.y
    // [337] call gotoxy
    // [490] phi from main::@147 to gotoxy [phi:main::@147->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#23 [phi:main::@147->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = gotoxy::x#23 [phi:main::@147->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [338] phi from main::@147 to main::@148 [phi:main::@147->main::@148]
    // main::@148
    // printf("................")
    // [339] call printf_str
    // [720] phi from main::@148 to printf_str [phi:main::@148->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:main::@148->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = main::s15 [phi:main::@148->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@149
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [340] print_address::bram_bank#1 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta print_address.bram_bank
    // [341] print_address::bram_ptr#1 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z print_address.bram_ptr
    lda.z read_ram_address_sector+1
    sta.z print_address.bram_ptr+1
    // [342] print_address::brom_address#1 = main::flash_rom_address_sector#11 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta print_address.brom_address
    lda flash_rom_address_sector+1
    sta print_address.brom_address+1
    lda flash_rom_address_sector+2
    sta print_address.brom_address+2
    lda flash_rom_address_sector+3
    sta print_address.brom_address+3
    // [343] call print_address
    // [1052] phi from main::@149 to print_address [phi:main::@149->print_address]
    // [1052] phi print_address::bram_ptr#10 = print_address::bram_ptr#1 [phi:main::@149->print_address#0] -- register_copy 
    // [1052] phi print_address::bram_bank#10 = print_address::bram_bank#1 [phi:main::@149->print_address#1] -- register_copy 
    // [1052] phi print_address::brom_address#10 = print_address::brom_address#1 [phi:main::@149->print_address#2] -- register_copy 
    jsr print_address
    // main::@150
    // [344] main::flash_rom_address2#16 = main::flash_rom_address_sector#11 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta flash_rom_address2
    lda flash_rom_address_sector+1
    sta flash_rom_address2+1
    lda flash_rom_address_sector+2
    sta flash_rom_address2+2
    lda flash_rom_address_sector+3
    sta flash_rom_address2+3
    // [345] main::read_ram_address1#16 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z read_ram_address1
    lda.z read_ram_address_sector+1
    sta.z read_ram_address1+1
    // [346] main::x1#16 = main::x_sector1#10 -- vbum1=vbum2 
    lda x_sector1
    sta x1
    // [347] phi from main::@150 main::@156 to main::@32 [phi:main::@150/main::@156->main::@32]
    // [347] phi main::x1#10 = main::x1#16 [phi:main::@150/main::@156->main::@32#0] -- register_copy 
    // [347] phi main::flash_errors#11 = main::flash_errors#10 [phi:main::@150/main::@156->main::@32#1] -- register_copy 
    // [347] phi main::read_ram_address1#10 = main::read_ram_address1#16 [phi:main::@150/main::@156->main::@32#2] -- register_copy 
    // [347] phi main::flash_rom_address2#11 = main::flash_rom_address2#16 [phi:main::@150/main::@156->main::@32#3] -- register_copy 
    // main::@32
  __b32:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [348] if(main::flash_rom_address2#11<main::flash_rom_address_boundary1#0) goto main::@33 -- vdum1_lt_vdum2_then_la1 
    lda flash_rom_address2+3
    cmp flash_rom_address_boundary1+3
    bcc __b33
    bne !+
    lda flash_rom_address2+2
    cmp flash_rom_address_boundary1+2
    bcc __b33
    bne !+
    lda flash_rom_address2+1
    cmp flash_rom_address_boundary1+1
    bcc __b33
    bne !+
    lda flash_rom_address2
    cmp flash_rom_address_boundary1
    bcc __b33
  !:
    // main::@34
    // retries++;
    // [349] main::retries#1 = ++ main::retries#10 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors && retries <= 3)
    // [350] if(0==main::flash_errors#11) goto main::@37 -- 0_eq_vbum1_then_la1 
    lda flash_errors
    beq __b37
    // main::@173
    // [351] if(main::retries#1<3+1) goto main::@31 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b31+
    jmp __b31
  !__b31:
    // main::@37
  __b37:
    // flash_errors_sector += flash_errors
    // [352] main::flash_errors_sector#1 = main::flash_errors_sector#10 + main::flash_errors#11 -- vwum1=vwum1_plus_vbum2 
    lda flash_errors
    clc
    adc flash_errors_sector
    sta flash_errors_sector
    bcc !+
    inc flash_errors_sector+1
  !:
    jmp __b30
    // main::@33
  __b33:
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [353] print_address::bram_bank#2 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta print_address.bram_bank
    // [354] print_address::bram_ptr#2 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z print_address.bram_ptr
    lda.z read_ram_address1+1
    sta.z print_address.bram_ptr+1
    // [355] print_address::brom_address#2 = main::flash_rom_address2#11 -- vdum1=vdum2 
    lda flash_rom_address2
    sta print_address.brom_address
    lda flash_rom_address2+1
    sta print_address.brom_address+1
    lda flash_rom_address2+2
    sta print_address.brom_address+2
    lda flash_rom_address2+3
    sta print_address.brom_address+3
    // [356] call print_address
    // [1052] phi from main::@33 to print_address [phi:main::@33->print_address]
    // [1052] phi print_address::bram_ptr#10 = print_address::bram_ptr#2 [phi:main::@33->print_address#0] -- register_copy 
    // [1052] phi print_address::bram_bank#10 = print_address::bram_bank#2 [phi:main::@33->print_address#1] -- register_copy 
    // [1052] phi print_address::brom_address#10 = print_address::brom_address#2 [phi:main::@33->print_address#2] -- register_copy 
    jsr print_address
    // main::@151
    // unsigned long written_bytes = flash_write(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address)
    // [357] flash_write::flash_ram_bank#0 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta flash_write.flash_ram_bank
    // [358] flash_write::flash_ram_address#1 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_write.flash_ram_address
    lda.z read_ram_address1+1
    sta.z flash_write.flash_ram_address+1
    // [359] flash_write::flash_rom_address#1 = main::flash_rom_address2#11 -- vdum1=vdum2 
    lda flash_rom_address2
    sta flash_write.flash_rom_address
    lda flash_rom_address2+1
    sta flash_write.flash_rom_address+1
    lda flash_rom_address2+2
    sta flash_write.flash_rom_address+2
    lda flash_rom_address2+3
    sta flash_write.flash_rom_address+3
    // [360] call flash_write
    jsr flash_write
    // main::@152
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [361] flash_verify::bank_ram#2 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta flash_verify.bank_ram
    // [362] flash_verify::ptr_ram#3 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address1+1
    sta.z flash_verify.ptr_ram+1
    // [363] flash_verify::verify_rom_address#2 = main::flash_rom_address2#11 -- vdum1=vdum2 
    lda flash_rom_address2
    sta flash_verify.verify_rom_address
    lda flash_rom_address2+1
    sta flash_verify.verify_rom_address+1
    lda flash_rom_address2+2
    sta flash_verify.verify_rom_address+2
    lda flash_rom_address2+3
    sta flash_verify.verify_rom_address+3
    // [364] call flash_verify
    // [1013] phi from main::@152 to flash_verify [phi:main::@152->flash_verify]
    // [1013] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#3 [phi:main::@152->flash_verify#0] -- register_copy 
    // [1013] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@152->flash_verify#1] -- vwum1=vwuc1 
    lda #<$100
    sta flash_verify.verify_rom_size
    lda #>$100
    sta flash_verify.verify_rom_size+1
    // [1013] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#2 [phi:main::@152->flash_verify#2] -- register_copy 
    // [1013] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#2 [phi:main::@152->flash_verify#3] -- register_copy 
    jsr flash_verify
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [365] flash_verify::return#4 = flash_verify::correct_bytes#2
    // main::@153
    // equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [366] main::equal_bytes1#1 = flash_verify::return#4
    // if (equal_bytes != 0x0100)
    // [367] if(main::equal_bytes1#1!=$100) goto main::@35 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes1+1
    cmp #>$100
    bne __b35
    lda equal_bytes1
    cmp #<$100
    bne __b35
    // [369] phi from main::@153 to main::@36 [phi:main::@153->main::@36]
    // [369] phi main::flash_errors#12 = main::flash_errors#11 [phi:main::@153->main::@36#0] -- register_copy 
    // [369] phi main::pattern1#5 = main::pattern1#3 [phi:main::@153->main::@36#1] -- pbuz1=pbuc1 
    lda #<pattern1_3
    sta.z pattern1
    lda #>pattern1_3
    sta.z pattern1+1
    jmp __b36
    // main::@35
  __b35:
    // flash_errors++;
    // [368] main::flash_errors#1 = ++ main::flash_errors#11 -- vbum1=_inc_vbum1 
    inc flash_errors
    // [369] phi from main::@35 to main::@36 [phi:main::@35->main::@36]
    // [369] phi main::flash_errors#12 = main::flash_errors#1 [phi:main::@35->main::@36#0] -- register_copy 
    // [369] phi main::pattern1#5 = main::pattern1#2 [phi:main::@35->main::@36#1] -- pbuz1=pbuc1 
    lda #<pattern1_2
    sta.z pattern1
    lda #>pattern1_2
    sta.z pattern1+1
    // main::@36
  __b36:
    // read_ram_address += 0x0100
    // [370] main::read_ram_address1#1 = main::read_ram_address1#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address1
    clc
    adc #<$100
    sta.z read_ram_address1
    lda.z read_ram_address1+1
    adc #>$100
    sta.z read_ram_address1+1
    // flash_rom_address += 0x0100
    // [371] main::flash_rom_address2#1 = main::flash_rom_address2#11 + $100 -- vdum1=vdum1_plus_vwuc1 
    clc
    lda flash_rom_address2
    adc #<$100
    sta flash_rom_address2
    lda flash_rom_address2+1
    adc #>$100
    sta flash_rom_address2+1
    lda flash_rom_address2+2
    adc #0
    sta flash_rom_address2+2
    lda flash_rom_address2+3
    adc #0
    sta flash_rom_address2+3
    // textcolor(WHITE)
    // [372] call textcolor
    // [472] phi from main::@36 to textcolor [phi:main::@36->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:main::@36->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@154
    // gotoxy(x, y)
    // [373] gotoxy::x#24 = main::x1#10 -- vbum1=vbum2 
    lda x1
    sta gotoxy.x
    // [374] gotoxy::y#24 = main::y_sector1#13 -- vbum1=vbum2 
    lda y_sector1
    sta gotoxy.y
    // [375] call gotoxy
    // [490] phi from main::@154 to gotoxy [phi:main::@154->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#24 [phi:main::@154->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = gotoxy::x#24 [phi:main::@154->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@155
    // printf("%s", pattern)
    // [376] printf_string::str#11 = main::pattern1#5
    // [377] call printf_string
    // [769] phi from main::@155 to printf_string [phi:main::@155->printf_string]
    // [769] phi printf_string::str#12 = printf_string::str#11 [phi:main::@155->printf_string#0] -- register_copy 
    // [769] phi printf_string::format_min_length#12 = 0 [phi:main::@155->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@156
    // x++;
    // [378] main::x1#1 = ++ main::x1#10 -- vbum1=_inc_vbum1 
    inc x1
    jmp __b32
    // main::@20
  __b20:
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [379] flash_verify::bank_ram#0 = main::read_ram_bank#13 -- vbum1=vbum2 
    lda read_ram_bank
    sta flash_verify.bank_ram
    // [380] flash_verify::ptr_ram#1 = main::read_ram_address#10 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address+1
    sta.z flash_verify.ptr_ram+1
    // [381] flash_verify::verify_rom_address#0 = main::flash_rom_address1#13 -- vdum1=vdum2 
    lda flash_rom_address1
    sta flash_verify.verify_rom_address
    lda flash_rom_address1+1
    sta flash_verify.verify_rom_address+1
    lda flash_rom_address1+2
    sta flash_verify.verify_rom_address+2
    lda flash_rom_address1+3
    sta flash_verify.verify_rom_address+3
    // [382] call flash_verify
    // [1013] phi from main::@20 to flash_verify [phi:main::@20->flash_verify]
    // [1013] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#1 [phi:main::@20->flash_verify#0] -- register_copy 
    // [1013] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@20->flash_verify#1] -- vwum1=vwuc1 
    lda #<$100
    sta flash_verify.verify_rom_size
    lda #>$100
    sta flash_verify.verify_rom_size+1
    // [1013] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#0 [phi:main::@20->flash_verify#2] -- register_copy 
    // [1013] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#0 [phi:main::@20->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [383] flash_verify::return#2 = flash_verify::correct_bytes#2
    // main::@128
    // [384] main::equal_bytes#0 = flash_verify::return#2
    // if (equal_bytes != 0x0100)
    // [385] if(main::equal_bytes#0!=$100) goto main::@22 -- vwum1_neq_vwuc1_then_la1 
    // unsigned long equal_bytes = 0x100;
    lda equal_bytes+1
    cmp #>$100
    bne __b22
    lda equal_bytes
    cmp #<$100
    bne __b22
    // [387] phi from main::@128 to main::@23 [phi:main::@128->main::@23]
    // [387] phi main::pattern#3 = main::s2 [phi:main::@128->main::@23#0] -- pbuz1=pbuc1 
    lda #<s2
    sta.z pattern
    lda #>s2
    sta.z pattern+1
    jmp __b23
    // [386] phi from main::@128 to main::@22 [phi:main::@128->main::@22]
    // main::@22
  __b22:
    // [387] phi from main::@22 to main::@23 [phi:main::@22->main::@23]
    // [387] phi main::pattern#3 = main::pattern#1 [phi:main::@22->main::@23#0] -- pbuz1=pbuc1 
    lda #<pattern_1
    sta.z pattern
    lda #>pattern_1
    sta.z pattern+1
    // main::@23
  __b23:
    // read_ram_address += 0x0100
    // [388] main::read_ram_address#1 = main::read_ram_address#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address
    clc
    adc #<$100
    sta.z read_ram_address
    lda.z read_ram_address+1
    adc #>$100
    sta.z read_ram_address+1
    // flash_rom_address += 0x0100
    // [389] main::flash_rom_address1#1 = main::flash_rom_address1#13 + $100 -- vdum1=vdum1_plus_vwuc1 
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
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [390] print_address::bram_bank#0 = main::read_ram_bank#13 -- vbum1=vbum2 
    lda read_ram_bank
    sta print_address.bram_bank
    // [391] print_address::bram_ptr#0 = main::read_ram_address#1 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z print_address.bram_ptr
    lda.z read_ram_address+1
    sta.z print_address.bram_ptr+1
    // [392] print_address::brom_address#0 = main::flash_rom_address1#1 -- vdum1=vdum2 
    lda flash_rom_address1
    sta print_address.brom_address
    lda flash_rom_address1+1
    sta print_address.brom_address+1
    lda flash_rom_address1+2
    sta print_address.brom_address+2
    lda flash_rom_address1+3
    sta print_address.brom_address+3
    // [393] call print_address
    // [1052] phi from main::@23 to print_address [phi:main::@23->print_address]
    // [1052] phi print_address::bram_ptr#10 = print_address::bram_ptr#0 [phi:main::@23->print_address#0] -- register_copy 
    // [1052] phi print_address::bram_bank#10 = print_address::bram_bank#0 [phi:main::@23->print_address#1] -- register_copy 
    // [1052] phi print_address::brom_address#10 = print_address::brom_address#0 [phi:main::@23->print_address#2] -- register_copy 
    jsr print_address
    // [394] phi from main::@23 to main::@139 [phi:main::@23->main::@139]
    // main::@139
    // textcolor(WHITE)
    // [395] call textcolor
    // [472] phi from main::@139 to textcolor [phi:main::@139->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:main::@139->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@140
    // gotoxy(x_sector, y_sector)
    // [396] gotoxy::x#21 = main::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [397] gotoxy::y#21 = main::y_sector#10 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [398] call gotoxy
    // [490] phi from main::@140 to gotoxy [phi:main::@140->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#21 [phi:main::@140->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = gotoxy::x#21 [phi:main::@140->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@141
    // printf("%s", pattern)
    // [399] printf_string::str#9 = main::pattern#3 -- pbuz1=pbuz2 
    lda.z pattern
    sta.z printf_string.str
    lda.z pattern+1
    sta.z printf_string.str+1
    // [400] call printf_string
    // [769] phi from main::@141 to printf_string [phi:main::@141->printf_string]
    // [769] phi printf_string::str#12 = printf_string::str#9 [phi:main::@141->printf_string#0] -- register_copy 
    // [769] phi printf_string::format_min_length#12 = 0 [phi:main::@141->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@142
    // x_sector++;
    // [401] main::x_sector#1 = ++ main::x_sector#10 -- vbum1=_inc_vbum1 
    inc x_sector
    // if (read_ram_address == 0x8000)
    // [402] if(main::read_ram_address#1!=$8000) goto main::@174 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$8000
    bne __b24
    lda.z read_ram_address
    cmp #<$8000
    bne __b24
    // [404] phi from main::@142 to main::@24 [phi:main::@142->main::@24]
    // [404] phi main::read_ram_bank#5 = 1 [phi:main::@142->main::@24#0] -- vbum1=vbuc1 
    lda #1
    sta read_ram_bank
    // [404] phi main::read_ram_address#7 = (char *) 40960 [phi:main::@142->main::@24#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [403] phi from main::@142 to main::@174 [phi:main::@142->main::@174]
    // main::@174
    // [404] phi from main::@174 to main::@24 [phi:main::@174->main::@24]
    // [404] phi main::read_ram_bank#5 = main::read_ram_bank#13 [phi:main::@174->main::@24#0] -- register_copy 
    // [404] phi main::read_ram_address#7 = main::read_ram_address#1 [phi:main::@174->main::@24#1] -- register_copy 
    // main::@24
  __b24:
    // if (read_ram_address == 0xC000)
    // [405] if(main::read_ram_address#7!=$c000) goto main::@25 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$c000
    bne __b25
    lda.z read_ram_address
    cmp #<$c000
    bne __b25
    // main::@26
    // read_ram_bank++;
    // [406] main::read_ram_bank#2 = ++ main::read_ram_bank#5 -- vbum1=_inc_vbum1 
    inc read_ram_bank
    // [407] phi from main::@26 to main::@25 [phi:main::@26->main::@25]
    // [407] phi main::read_ram_address#12 = (char *) 40960 [phi:main::@26->main::@25#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [407] phi main::read_ram_bank#10 = main::read_ram_bank#2 [phi:main::@26->main::@25#1] -- register_copy 
    // [407] phi from main::@24 to main::@25 [phi:main::@24->main::@25]
    // [407] phi main::read_ram_address#12 = main::read_ram_address#7 [phi:main::@24->main::@25#0] -- register_copy 
    // [407] phi main::read_ram_bank#10 = main::read_ram_bank#5 [phi:main::@24->main::@25#1] -- register_copy 
    // main::@25
  __b25:
    // flash_rom_address % 0x4000
    // [408] main::$104 = main::flash_rom_address1#1 & $4000-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address1
    and #<$4000-1
    sta __104
    lda flash_rom_address1+1
    and #>$4000-1
    sta __104+1
    lda flash_rom_address1+2
    and #<$4000-1>>$10
    sta __104+2
    lda flash_rom_address1+3
    and #>$4000-1>>$10
    sta __104+3
    // if (!(flash_rom_address % 0x4000))
    // [409] if(0!=main::$104) goto main::@19 -- 0_neq_vdum1_then_la1 
    lda __104
    ora __104+1
    ora __104+2
    ora __104+3
    beq !__b19+
    jmp __b19
  !__b19:
    // main::@27
    // y_sector++;
    // [410] main::y_sector#1 = ++ main::y_sector#10 -- vbum1=_inc_vbum1 
    inc y_sector
    // [239] phi from main::@27 to main::@19 [phi:main::@27->main::@19]
    // [239] phi main::y_sector#10 = main::y_sector#1 [phi:main::@27->main::@19#0] -- register_copy 
    // [239] phi main::x_sector#10 = $e [phi:main::@27->main::@19#1] -- vbum1=vbuc1 
    lda #$e
    sta x_sector
    // [239] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@27->main::@19#2] -- register_copy 
    // [239] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@27->main::@19#3] -- register_copy 
    // [239] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@27->main::@19#4] -- register_copy 
    jmp __b19
    // main::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [411] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [412] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0x90)
    // [413] rom_unlock::address#3 = main::flash_rom_address#10 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda flash_rom_address
    adc #<$5555
    sta rom_unlock.address
    lda flash_rom_address+1
    adc #>$5555
    sta rom_unlock.address+1
    lda flash_rom_address+2
    adc #0
    sta rom_unlock.address+2
    lda flash_rom_address+3
    adc #0
    sta rom_unlock.address+3
    // [414] call rom_unlock
    // [1098] phi from main::@2 to rom_unlock [phi:main::@2->rom_unlock]
    // [1098] phi rom_unlock::unlock_code#5 = $90 [phi:main::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$90
    sta rom_unlock.unlock_code
    // [1098] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:main::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // main::@71
    // rom_read_byte(flash_rom_address)
    // [415] rom_read_byte::address#0 = main::flash_rom_address#10 -- vdum1=vdum2 
    lda flash_rom_address
    sta rom_read_byte.address
    lda flash_rom_address+1
    sta rom_read_byte.address+1
    lda flash_rom_address+2
    sta rom_read_byte.address+2
    lda flash_rom_address+3
    sta rom_read_byte.address+3
    // [416] call rom_read_byte
    // [1108] phi from main::@71 to rom_read_byte [phi:main::@71->rom_read_byte]
    // [1108] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:main::@71->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(flash_rom_address)
    // [417] rom_read_byte::return#2 = rom_read_byte::return#0
    // main::@72
    // [418] main::$21 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(flash_rom_address)
    // [419] main::rom_manufacturer_ids[main::rom_chip#10] = main::$21 -- pbuc1_derefidx_vbum1=vbum2 
    lda __21
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(flash_rom_address + 1)
    // [420] rom_read_byte::address#1 = main::flash_rom_address#10 + 1 -- vdum1=vdum2_plus_1 
    lda flash_rom_address
    clc
    adc #1
    sta rom_read_byte.address
    lda flash_rom_address+1
    adc #0
    sta rom_read_byte.address+1
    lda flash_rom_address+2
    adc #0
    sta rom_read_byte.address+2
    lda flash_rom_address+3
    adc #0
    sta rom_read_byte.address+3
    // [421] call rom_read_byte
    // [1108] phi from main::@72 to rom_read_byte [phi:main::@72->rom_read_byte]
    // [1108] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:main::@72->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(flash_rom_address + 1)
    // [422] rom_read_byte::return#3 = rom_read_byte::return#0
    // main::@73
    // [423] main::$23 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(flash_rom_address + 1)
    // [424] main::rom_device_ids[main::rom_chip#10] = main::$23 -- pbuc1_derefidx_vbum1=vbum2 
    lda __23
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0xF0)
    // [425] rom_unlock::address#4 = main::flash_rom_address#10 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda flash_rom_address
    adc #<$5555
    sta rom_unlock.address
    lda flash_rom_address+1
    adc #>$5555
    sta rom_unlock.address+1
    lda flash_rom_address+2
    adc #0
    sta rom_unlock.address+2
    lda flash_rom_address+3
    adc #0
    sta rom_unlock.address+3
    // [426] call rom_unlock
    // [1098] phi from main::@73 to rom_unlock [phi:main::@73->rom_unlock]
    // [1098] phi rom_unlock::unlock_code#5 = $f0 [phi:main::@73->rom_unlock#0] -- vbum1=vbuc1 
    lda #$f0
    sta rom_unlock.unlock_code
    // [1098] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:main::@73->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // [427] phi from main::@73 to main::@74 [phi:main::@73->main::@74]
    // main::@74
    // bank_set_brom(4)
    // [428] call bank_set_brom
  // Ensure the ROM is set to BASIC.
    // [796] phi from main::@74 to bank_set_brom [phi:main::@74->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 4 [phi:main::@74->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // main::@75
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_KB(rom_chip, "128");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [429] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    //             rom_sizes[rom_chip] = 256 * 1024;
    //             break;
    // [430] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [431] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b5+
    jmp __b5
  !__b5:
    // main::@6
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [432] print_chip_led::r#4 = main::rom_chip#10 -- vbum1=vbum2 
    tya
    sta print_chip_led.r
    // [433] call print_chip_led
    // [899] phi from main::@6 to print_chip_led [phi:main::@6->print_chip_led]
    // [899] phi print_chip_led::tc#10 = BLACK [phi:main::@6->print_chip_led#0] -- vbum1=vbuc1 
    lda #BLACK
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#4 [phi:main::@6->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@85
    // rom_device_ids[rom_chip] = UNKNOWN
    // [434] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // [435] phi from main::@85 to main::@7 [phi:main::@85->main::@7]
    // [435] phi main::rom_device#5 = main::rom_device#13 [phi:main::@85->main::@7#0] -- pbuz1=pbuc1 
    lda #<rom_device_4
    sta.z rom_device
    lda #>rom_device_4
    sta.z rom_device+1
    // main::@7
  __b7:
    // textcolor(WHITE)
    // [436] call textcolor
    // [472] phi from main::@7 to textcolor [phi:main::@7->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:main::@7->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@86
    // rom_chip * 10
    // [437] main::$187 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __187
    // [438] main::$188 = main::$187 + main::rom_chip#10 -- vbum1=vbum1_plus_vbum2 
    lda __188
    clc
    adc rom_chip
    sta __188
    // [439] main::$39 = main::$188 << 1 -- vbum1=vbum1_rol_1 
    asl __39
    // gotoxy(2 + rom_chip * 10, 56)
    // [440] gotoxy::x#15 = 2 + main::$39 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc __39
    sta gotoxy.x
    // [441] call gotoxy
    // [490] phi from main::@86 to gotoxy [phi:main::@86->gotoxy]
    // [490] phi gotoxy::y#25 = $38 [phi:main::@86->gotoxy#0] -- vbum1=vbuc1 
    lda #$38
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = gotoxy::x#15 [phi:main::@86->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@87
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [442] printf_uchar::uvalue#3 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_manufacturer_ids,y
    sta printf_uchar.uvalue
    // [443] call printf_uchar
    // [919] phi from main::@87 to printf_uchar [phi:main::@87->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@87->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 0 [phi:main::@87->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:main::@87->printf_uchar#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#3 [phi:main::@87->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // main::@88
    // gotoxy(2 + rom_chip * 10, 57)
    // [444] gotoxy::x#16 = 2 + main::$39 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc __39
    sta gotoxy.x
    // [445] call gotoxy
    // [490] phi from main::@88 to gotoxy [phi:main::@88->gotoxy]
    // [490] phi gotoxy::y#25 = $39 [phi:main::@88->gotoxy#0] -- vbum1=vbuc1 
    lda #$39
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = gotoxy::x#16 [phi:main::@88->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@89
    // printf("%s", rom_device)
    // [446] printf_string::str#5 = main::rom_device#5 -- pbuz1=pbuz2 
    lda.z rom_device
    sta.z printf_string.str
    lda.z rom_device+1
    sta.z printf_string.str+1
    // [447] call printf_string
    // [769] phi from main::@89 to printf_string [phi:main::@89->printf_string]
    // [769] phi printf_string::str#12 = printf_string::str#5 [phi:main::@89->printf_string#0] -- register_copy 
    // [769] phi printf_string::format_min_length#12 = 0 [phi:main::@89->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@90
    // rom_chip++;
    // [448] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // main::@8
    // flash_rom_address += 0x80000
    // [449] main::flash_rom_address#1 = main::flash_rom_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [81] phi from main::@8 to main::@1 [phi:main::@8->main::@1]
    // [81] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@8->main::@1#0] -- register_copy 
    // [81] phi main::flash_rom_address#10 = main::flash_rom_address#1 [phi:main::@8->main::@1#1] -- register_copy 
    jmp __b1
    // main::@5
  __b5:
    // print_chip_KB(rom_chip, "512")
    // [450] print_chip_KB::rom_chip#2 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_KB.rom_chip
    // [451] call print_chip_KB
    // [1121] phi from main::@5 to print_chip_KB [phi:main::@5->print_chip_KB]
    // [1121] phi print_chip_KB::kb#3 = main::kb2 [phi:main::@5->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb2
    sta.z print_chip_KB.kb
    lda #>kb2
    sta.z print_chip_KB.kb+1
    // [1121] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#2 [phi:main::@5->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@83
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [452] print_chip_led::r#3 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_led.r
    // [453] call print_chip_led
    // [899] phi from main::@83 to print_chip_led [phi:main::@83->print_chip_led]
    // [899] phi print_chip_led::tc#10 = WHITE [phi:main::@83->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#3 [phi:main::@83->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@84
    // rom_sizes[rom_chip] = 512 * 1024
    // [454] main::$169 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __169
    // [455] main::rom_sizes[main::$169] = (unsigned long)$200*$400 -- pduc1_derefidx_vbum1=vduc2 
    tay
    lda #<$200*$400
    sta rom_sizes,y
    lda #>$200*$400
    sta rom_sizes+1,y
    lda #<$200*$400>>$10
    sta rom_sizes+2,y
    lda #>$200*$400>>$10
    sta rom_sizes+3,y
    // [435] phi from main::@84 to main::@7 [phi:main::@84->main::@7]
    // [435] phi main::rom_device#5 = main::rom_device#12 [phi:main::@84->main::@7#0] -- pbuz1=pbuc1 
    lda #<rom_device_3
    sta.z rom_device
    lda #>rom_device_3
    sta.z rom_device+1
    jmp __b7
    // main::@4
  __b4:
    // print_chip_KB(rom_chip, "256")
    // [456] print_chip_KB::rom_chip#1 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_KB.rom_chip
    // [457] call print_chip_KB
    // [1121] phi from main::@4 to print_chip_KB [phi:main::@4->print_chip_KB]
    // [1121] phi print_chip_KB::kb#3 = main::kb1 [phi:main::@4->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb1
    sta.z print_chip_KB.kb
    lda #>kb1
    sta.z print_chip_KB.kb+1
    // [1121] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#1 [phi:main::@4->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@81
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [458] print_chip_led::r#2 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_led.r
    // [459] call print_chip_led
    // [899] phi from main::@81 to print_chip_led [phi:main::@81->print_chip_led]
    // [899] phi print_chip_led::tc#10 = WHITE [phi:main::@81->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#2 [phi:main::@81->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@82
    // rom_sizes[rom_chip] = 256 * 1024
    // [460] main::$168 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __168
    // [461] main::rom_sizes[main::$168] = (unsigned long)$100*$400 -- pduc1_derefidx_vbum1=vduc2 
    tay
    lda #<$100*$400
    sta rom_sizes,y
    lda #>$100*$400
    sta rom_sizes+1,y
    lda #<$100*$400>>$10
    sta rom_sizes+2,y
    lda #>$100*$400>>$10
    sta rom_sizes+3,y
    // [435] phi from main::@82 to main::@7 [phi:main::@82->main::@7]
    // [435] phi main::rom_device#5 = main::rom_device#11 [phi:main::@82->main::@7#0] -- pbuz1=pbuc1 
    lda #<rom_device_2
    sta.z rom_device
    lda #>rom_device_2
    sta.z rom_device+1
    jmp __b7
    // main::@3
  __b3:
    // print_chip_KB(rom_chip, "128")
    // [462] print_chip_KB::rom_chip#0 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_KB.rom_chip
    // [463] call print_chip_KB
    // [1121] phi from main::@3 to print_chip_KB [phi:main::@3->print_chip_KB]
    // [1121] phi print_chip_KB::kb#3 = main::kb [phi:main::@3->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb
    sta.z print_chip_KB.kb
    lda #>kb
    sta.z print_chip_KB.kb+1
    // [1121] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#0 [phi:main::@3->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@79
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [464] print_chip_led::r#1 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_led.r
    // [465] call print_chip_led
    // [899] phi from main::@79 to print_chip_led [phi:main::@79->print_chip_led]
    // [899] phi print_chip_led::tc#10 = WHITE [phi:main::@79->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#1 [phi:main::@79->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@80
    // rom_sizes[rom_chip] = 128 * 1024
    // [466] main::$167 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __167
    // [467] main::rom_sizes[main::$167] = (unsigned long)$80*$400 -- pduc1_derefidx_vbum1=vduc2 
    tay
    lda #<$80*$400
    sta rom_sizes,y
    lda #>$80*$400
    sta rom_sizes+1,y
    lda #<$80*$400>>$10
    sta rom_sizes+2,y
    lda #>$80*$400>>$10
    sta rom_sizes+3,y
    // [435] phi from main::@80 to main::@7 [phi:main::@80->main::@7]
    // [435] phi main::rom_device#5 = main::rom_device#1 [phi:main::@80->main::@7#0] -- pbuz1=pbuc1 
    lda #<rom_device_1
    sta.z rom_device
    lda #>rom_device_1
    sta.z rom_device+1
    jmp __b7
  .segment Data
    rom_device_ids: .byte 0
    .fill 7, 0
    rom_manufacturer_ids: .byte 0
    .fill 7, 0
    rom_sizes: .dword 0
    .fill 4*7, 0
    s: .text "commander x16 rom flash utility"
    .byte 0
    str: .text "press a key to start flashing."
    .byte 0
    kb: .text "128"
    .byte 0
    kb1: .text "256"
    .byte 0
    kb2: .text "512"
    .byte 0
    source: .text "rom"
    .byte 0
    source1: .text ".bin"
    .byte 0
    s1: .text "opening "
    .byte 0
    s2: .text "."
    .byte 0
    s3: .text "reading file for rom"
    .byte 0
    s4: .text " in ram ..."
    .byte 0
    s5: .text "there is no "
    .byte 0
    s6: .text " file on the sdcard to flash rom"
    .byte 0
    s7: .text ". press a key ..."
    .byte 0
    s8: .text "no file"
    .byte 0
    s9: .text "verifying rom"
    .byte 0
    s10: .text " with file ... (.) same, (*) different."
    .byte 0
    s11: .text "verified rom"
    .byte 0
    s12: .text " ... (.) same, (*) different. press a key to flash ..."
    .byte 0
    s13: .text "flashing rom"
    .byte 0
    s14: .text " from ram ... (-) unchanged, (+) flashed, (!) error."
    .byte 0
    s15: .text "................"
    .byte 0
    s16: .text "the flashing of rom"
    .byte 0
    s17: .text " went perfectly ok. press a key ..."
    .byte 0
    s19: .text " went wrong, "
    .byte 0
    s20: .text " errors. press a key ..."
    .byte 0
    s21: .text "resetting commander x16 ("
    .byte 0
    s22: .text ")"
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
    pattern1_1: .text "----------------"
    .byte 0
    pattern1_2: .text "!"
    .byte 0
    pattern1_3: .text "+"
    .byte 0
    .label __21 = rom_read_byte.return
    .label __23 = rom_read_byte.return
    .label __39 = __187
    __53: .byte 0
    .label __63 = __193
    .label __70 = __191
    __104: .dword 0
    __143: .dword 0
    __167: .byte 0
    __168: .byte 0
    __169: .byte 0
    __170: .byte 0
    rom_chip: .byte 0
    flash_rom_address: .dword 0
    flash_chip: .byte 0
    flash_rom_bank: .byte 0
    .label len = strlen.len
    .label flash_rom_address_boundary = rom_address.return_2
    flash_bytes: .dword 0
    .label flash_rom_address_boundary_1 = flash_bytes
    .label size = flash_read.read_size
    flash_bytes_1: .dword 0
    flash_rom_address1: .dword 0
    .label equal_bytes = flash_verify.correct_bytes
    flash_rom_address_sector: .dword 0
    x_sector: .byte 0
    read_ram_bank: .byte 0
    y_sector: .byte 0
    .label equal_bytes1 = flash_verify.correct_bytes
    flash_rom_address_boundary1: .dword 0
    retries: .byte 0
    flash_errors: .byte 0
    flash_rom_address2: .dword 0
    x1: .byte 0
    flash_errors_sector: .word 0
    x_sector1: .byte 0
    read_ram_bank_sector: .byte 0
    y_sector1: .byte 0
    v: .word 0
    w: .word 0
    .label flash_rom_address_boundary_2 = flash_bytes_1
    __187: .byte 0
    .label __188 = __187
    __191: .byte 0
    __193: .byte 0
    .label __194 = __193
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [468] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [469] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [470] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [471] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    // __conio.color & 0xF0
    // [473] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbum1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta __0
    // __conio.color & 0xF0 | color
    // [474] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbum1=vbum2_bor_vbum1 
    lda __1
    ora __0
    sta __1
    // __conio.color = __conio.color & 0xF0 | color
    // [475] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbum1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [476] return 
    rts
  .segment Data
    __0: .byte 0
    .label __1 = color
    color: .byte 0
}
.segment Code
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__mem() char color)
bgcolor: {
    // __conio.color & 0x0F
    // [478] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbum1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta __0
    // color << 4
    // [479] bgcolor::$1 = bgcolor::color#11 << 4 -- vbum1=vbum1_rol_4 
    lda __1
    asl
    asl
    asl
    asl
    sta __1
    // __conio.color & 0x0F | color << 4
    // [480] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbum1=vbum1_bor_vbum2 
    lda __2
    ora __1
    sta __2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [481] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbum1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [482] return 
    rts
  .segment Data
    __0: .byte 0
    .label __1 = color
    .label __2 = __0
    color: .byte 0
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
    // [483] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [484] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [485] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [486] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [488] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [489] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    return: .word 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__mem() char x, __mem() char y)
gotoxy: {
    // (x>=__conio.width)?__conio.width:x
    // [491] if(gotoxy::x#25>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [493] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [493] phi gotoxy::$3 = gotoxy::x#25 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [492] gotoxy::$2 = *((char *)&__conio+6) -- vbum1=_deref_pbuc1 
    lda __conio+6
    sta __2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [494] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbum1 
    lda __3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [495] if(gotoxy::y#25>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [496] gotoxy::$14 = gotoxy::y#25 -- vbum1=vbum2 
    sta __14
    // [497] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [497] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [498] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbum1 
    lda __7
    sta __conio+1
    // __conio.cursor_x << 1
    // [499] gotoxy::$8 = *((char *)&__conio) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta __8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [500] gotoxy::$10 = gotoxy::y#25 << 1 -- vbum1=vbum1_rol_1 
    asl __10
    // [501] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwum1=pwuc1_derefidx_vbum2_plus_vbum3 
    ldy __10
    clc
    adc __conio+$15,y
    sta __9
    lda __conio+$15+1,y
    adc #0
    sta __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [502] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwum1 
    lda __9
    sta __conio+$13
    lda __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [503] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [504] gotoxy::$6 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta __6
    jmp __b5
  .segment Data
    .label __2 = __3
    __3: .byte 0
    .label __6 = __7
    __7: .byte 0
    __8: .byte 0
    __9: .word 0
    .label __10 = y
    .label x = __3
    y: .byte 0
    .label __14 = __7
}
.segment Code
  // cputln
// Print a newline
cputln: {
    // __conio.cursor_x = 0
    // [505] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [506] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [507] cputln::$3 = *((char *)&__conio+1) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta __3
    // [508] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$3] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // if(__conio.scroll[__conio.layer])
    // [509] if(0==((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cputln::@return -- 0_eq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    beq __breturn
    // [510] phi from cputln to cputln::@1 [phi:cputln->cputln::@1]
    // cputln::@1
    // cscroll()
    // [511] call cscroll
    jsr cscroll
    // cputln::@return
  __breturn:
    // }
    // [512] return 
    rts
  .segment Data
    __3: .byte 0
}
.segment Code
  // cbm_x_charset
/**
 * @brief Sets the [character set](https://github.com/commanderx16/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-screen_set_charset).
 * 
 * @param charset The code of the charset to copy.
 * @param offset The offset of the character set in ram.
 */
// void cbm_x_charset(__mem() volatile char charset, __zp($50) char * volatile offset)
cbm_x_charset: {
    .label offset = $50
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_CHRSET  }
    lda charset
    ldx.z <offset
    ldy.z >offset
    jsr CX16_CHRSET
    // cbm_x_charset::@return
    // }
    // [514] return 
    rts
  .segment Data
    charset: .byte 0
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
    // [515] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [516] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    // unsigned int line_text = __conio.mapbase_offset
    // [517] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [518] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [519] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta __0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [520] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [521] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [522] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [522] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [522] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [523] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwum2 
    lda ch
    sta __1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [524] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [525] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwum2 
    lda ch+1
    sta __2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [526] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [527] clrscr::c#0 = *((char *)&__conio+8) -- vbum1=_deref_pbuc1 
    lda __conio+8
    sta c
    // [528] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [528] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [529] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [530] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [531] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [532] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [533] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [534] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [535] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [536] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [537] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [538] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [539] return 
    rts
  .segment Data
    __0: .byte 0
    __1: .byte 0
    __2: .byte 0
    .label line_text = ch
    l: .byte 0
    ch: .word 0
    c: .byte 0
}
.segment Code
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [541] call textcolor
    // [472] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [542] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [543] call bgcolor
    // [477] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [544] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [545] call clrscr
    jsr clrscr
    // [546] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [546] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbum1=vbuc1 
    lda #0
    sta x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [547] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbum1_lt_vbuc1_then_la1 
    lda x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [548] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [549] call cputcxy
    // [1181] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [1181] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #$70
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbum1=vbuc1 
    sta cputcxy.x
    jsr cputcxy
    // [550] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [551] call cputcxy
    // [1181] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [1181] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbum1=vbuc1 
    lda #$6e
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // [552] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [553] call cputcxy
    // [1181] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbum1=vbuc1 
    lda #1
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // [554] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [555] call cputcxy
    // [1181] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbum1=vbuc1 
    lda #1
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // [556] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [556] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbum1=vbuc1 
    lda #0
    sta x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [557] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbum1_lt_vbuc1_then_la1 
    lda x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [558] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [559] call cputcxy
    // [1181] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [1181] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbum1=vbuc1 
    lda #$6b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbum1=vbuc1 
    lda #2
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // [560] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [561] call cputcxy
    // [1181] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [1181] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbum1=vbuc1 
    lda #2
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // [562] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [563] call cputcxy
    // [1181] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [1181] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbum1=vbuc1 
    lda #2
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbum1=vbuc1 
    lda #$c
    sta cputcxy.x
    jsr cputcxy
    // [564] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [564] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbum1=vbuc1 
    lda #3
    sta y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [565] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [566] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [566] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbum1=vbuc1 
    lda #0
    sta x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [567] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbum1_lt_vbuc1_then_la1 
    lda x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [568] cputcxy::y#13 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [569] call cputcxy
    // [1181] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [1181] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #$6b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [570] cputcxy::y#14 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [571] call cputcxy
    // [1181] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [1181] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [572] cputcxy::y#15 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [573] call cputcxy
    // [1181] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [1181] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbum1=vbuc1 
    lda #$c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [574] frame_draw::y#5 = ++ frame_draw::y#101 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [575] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [575] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [576] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbum1_lt_vbuc1_then_la1 
    lda y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [577] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [577] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbum1=vbuc1 
    lda #0
    sta x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [578] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbum1_lt_vbuc1_then_la1 
    lda x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [579] cputcxy::y#19 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [580] call cputcxy
    // [1181] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [1181] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbum1=vbuc1 
    lda #$6b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [581] cputcxy::y#20 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [582] call cputcxy
    // [1181] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [1181] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [583] cputcxy::y#21 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [584] call cputcxy
    // [1181] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [1181] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [585] cputcxy::y#22 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [586] call cputcxy
    // [1181] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [1181] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [587] cputcxy::y#23 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [588] call cputcxy
    // [1181] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [1181] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [589] cputcxy::y#24 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [590] call cputcxy
    // [1181] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [1181] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [591] cputcxy::y#25 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [592] call cputcxy
    // [1181] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [1181] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [593] cputcxy::y#26 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [594] call cputcxy
    // [1181] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [1181] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [595] cputcxy::y#27 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [596] call cputcxy
    // [1181] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [1181] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [597] cputcxy::y#28 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [598] call cputcxy
    // [1181] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [1181] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [599] frame_draw::y#7 = ++ frame_draw::y#102 -- vbum1=_inc_vbum2 
    lda y_1
    inc
    sta y_2
    // [600] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [600] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [601] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbum1_lt_vbuc1_then_la1 
    lda y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [602] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [602] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbum1=vbuc1 
    lda #0
    sta x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [603] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbum1_lt_vbuc1_then_la1 
    lda x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [604] cputcxy::y#39 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [605] call cputcxy
    // [1181] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [1181] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbum1=vbuc1 
    lda #$6b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [606] cputcxy::y#40 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [607] call cputcxy
    // [1181] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [1181] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [608] cputcxy::y#41 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [609] call cputcxy
    // [1181] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [1181] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [610] cputcxy::y#42 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [611] call cputcxy
    // [1181] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [1181] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [612] cputcxy::y#43 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [613] call cputcxy
    // [1181] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [1181] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [614] cputcxy::y#44 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [615] call cputcxy
    // [1181] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [1181] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [616] cputcxy::y#45 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [617] call cputcxy
    // [1181] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [1181] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [618] cputcxy::y#46 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [619] call cputcxy
    // [1181] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [1181] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [620] cputcxy::y#47 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [621] call cputcxy
    // [1181] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [1181] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [622] frame_draw::y#9 = ++ frame_draw::y#104 -- vbum1=_inc_vbum2 
    lda y_2
    inc
    sta y_3
    // [623] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [623] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [624] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbum1_lt_vbuc1_then_la1 
    lda y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [625] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [625] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbum1=vbuc1 
    lda #0
    sta x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [626] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbum1_lt_vbuc1_then_la1 
    lda x5
    cmp #$4f
    bcs !__b25+
    jmp __b25
  !__b25:
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [627] cputcxy::y#58 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [628] call cputcxy
    // [1181] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [1181] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbum1=vbuc1 
    lda #$6d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [629] cputcxy::y#59 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [630] call cputcxy
    // [1181] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [1181] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbum1=vbuc1 
    lda #$7d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [631] cputcxy::y#60 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [632] call cputcxy
    // [1181] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [1181] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [633] cputcxy::y#61 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [634] call cputcxy
    // [1181] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [1181] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [635] cputcxy::y#62 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [636] call cputcxy
    // [1181] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [1181] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [637] cputcxy::y#63 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [638] call cputcxy
    // [1181] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [1181] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [639] cputcxy::y#64 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [640] call cputcxy
    // [1181] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [1181] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [641] cputcxy::y#65 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [642] call cputcxy
    // [1181] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [1181] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [643] cputcxy::y#66 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [644] call cputcxy
    // [1181] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [1181] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [645] cputcxy::y#67 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [646] call cputcxy
    // [1181] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [1181] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbum1=vbuc1 
    lda #$7d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@return
    // }
    // [647] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [648] cputcxy::x#57 = frame_draw::x5#2 -- vbum1=vbum2 
    lda x5
    sta cputcxy.x
    // [649] cputcxy::y#57 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [650] call cputcxy
    // [1181] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [1181] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [651] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbum1=_inc_vbum1 
    inc x5
    // [625] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [625] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [652] cputcxy::y#48 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [653] call cputcxy
    // [1181] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [654] cputcxy::y#49 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [655] call cputcxy
    // [1181] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [656] cputcxy::y#50 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [657] call cputcxy
    // [1181] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [658] cputcxy::y#51 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [659] call cputcxy
    // [1181] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [660] cputcxy::y#52 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [661] call cputcxy
    // [1181] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [662] cputcxy::y#53 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [663] call cputcxy
    // [1181] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [664] cputcxy::y#54 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [665] call cputcxy
    // [1181] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [666] cputcxy::y#55 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [667] call cputcxy
    // [1181] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [668] cputcxy::y#56 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [669] call cputcxy
    // [1181] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [670] frame_draw::y#10 = ++ frame_draw::y#106 -- vbum1=_inc_vbum1 
    inc y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [671] cputcxy::x#38 = frame_draw::x4#2 -- vbum1=vbum2 
    lda x4
    sta cputcxy.x
    // [672] cputcxy::y#38 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [673] call cputcxy
    // [1181] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [1181] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [674] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbum1=_inc_vbum1 
    inc x4
    // [602] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [602] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [675] cputcxy::y#29 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [676] call cputcxy
    // [1181] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [677] cputcxy::y#30 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [678] call cputcxy
    // [1181] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [679] cputcxy::y#31 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [680] call cputcxy
    // [1181] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [681] cputcxy::y#32 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [682] call cputcxy
    // [1181] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [683] cputcxy::y#33 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [684] call cputcxy
    // [1181] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [685] cputcxy::y#34 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [686] call cputcxy
    // [1181] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [687] cputcxy::y#35 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [688] call cputcxy
    // [1181] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [689] cputcxy::y#36 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [690] call cputcxy
    // [1181] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [691] cputcxy::y#37 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [692] call cputcxy
    // [1181] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [693] frame_draw::y#8 = ++ frame_draw::y#104 -- vbum1=_inc_vbum1 
    inc y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [694] cputcxy::x#18 = frame_draw::x3#2 -- vbum1=vbum2 
    lda x3
    sta cputcxy.x
    // [695] cputcxy::y#18 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [696] call cputcxy
    // [1181] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [1181] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [697] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbum1=_inc_vbum1 
    inc x3
    // [577] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [577] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [698] cputcxy::y#16 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [699] call cputcxy
    // [1181] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [700] cputcxy::y#17 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [701] call cputcxy
    // [1181] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [702] frame_draw::y#6 = ++ frame_draw::y#102 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [703] cputcxy::x#12 = frame_draw::x2#2 -- vbum1=vbum2 
    lda x2
    sta cputcxy.x
    // [704] cputcxy::y#12 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [705] call cputcxy
    // [1181] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [1181] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [706] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbum1=_inc_vbum1 
    inc x2
    // [566] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [566] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [707] cputcxy::y#9 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [708] call cputcxy
    // [1181] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [709] cputcxy::y#10 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [710] call cputcxy
    // [1181] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbum1=vbuc1 
    lda #$c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [711] cputcxy::y#11 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [712] call cputcxy
    // [1181] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [1181] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [1181] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [713] frame_draw::y#4 = ++ frame_draw::y#101 -- vbum1=_inc_vbum1 
    inc y
    // [564] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [564] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [714] cputcxy::x#5 = frame_draw::x1#2 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [715] call cputcxy
    // [1181] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [1181] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbum1=vbuc1 
    lda #2
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [716] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbum1=_inc_vbum1 
    inc x1
    // [556] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [556] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [717] cputcxy::x#0 = frame_draw::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [718] call cputcxy
    // [1181] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [1181] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1181] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.y
    // [1181] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [719] frame_draw::x#1 = ++ frame_draw::x#2 -- vbum1=_inc_vbum1 
    inc x
    // [546] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [546] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
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
// void printf_str(__zp($3b) void (*putc)(char), __zp($24) const char *s)
printf_str: {
    .label s = $24
    .label putc = $3b
    // [721] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [721] phi printf_str::s#33 = printf_str::s#34 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [722] printf_str::c#1 = *printf_str::s#33 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [723] printf_str::s#0 = ++ printf_str::s#33 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [724] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [725] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [726] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [727] callexecute *printf_str::putc#34  -- call__deref_pprz1 
    jsr icall1
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall1:
    jmp (putc)
  .segment Data
    c: .byte 0
}
.segment Code
  // print_chips
print_chips: {
    // [730] phi from print_chips to print_chips::@1 [phi:print_chips->print_chips::@1]
    // [730] phi print_chips::r#10 = 0 [phi:print_chips->print_chips::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // print_chips::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [731] if(print_chips::r#10<8) goto print_chips::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // print_chips::@return
    // }
    // [732] return 
    rts
    // print_chips::@2
  __b2:
    // r * 10
    // [733] print_chips::$33 = print_chips::r#10 << 2 -- vbum1=vbum2_rol_2 
    lda r
    asl
    asl
    sta __33
    // [734] print_chips::$34 = print_chips::$33 + print_chips::r#10 -- vbum1=vbum1_plus_vbum2 
    lda __34
    clc
    adc r
    sta __34
    // [735] print_chips::$4 = print_chips::$34 << 1 -- vbum1=vbum1_rol_1 
    asl __4
    // print_chip_line(3 + r * 10, 45, ' ')
    // [736] print_chip_line::x#0 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [737] call print_chip_line
    // [1189] phi from print_chips::@2 to print_chip_line [phi:print_chips::@2->print_chip_line]
    // [1189] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@2->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1189] phi print_chip_line::y#12 = $2d [phi:print_chips::@2->print_chip_line#1] -- vbum1=vbuc1 
    lda #$2d
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#0 [phi:print_chips::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@3
    // print_chip_line(3 + r * 10, 46, 'r')
    // [738] print_chip_line::x#1 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [739] call print_chip_line
    // [1189] phi from print_chips::@3 to print_chip_line [phi:print_chips::@3->print_chip_line]
    // [1189] phi print_chip_line::c#12 = 'r'pm [phi:print_chips::@3->print_chip_line#0] -- vbum1=vbuc1 
    lda #'r'
    sta print_chip_line.c
    // [1189] phi print_chip_line::y#12 = $2e [phi:print_chips::@3->print_chip_line#1] -- vbum1=vbuc1 
    lda #$2e
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#1 [phi:print_chips::@3->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@4
    // print_chip_line(3 + r * 10, 47, 'o')
    // [740] print_chip_line::x#2 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [741] call print_chip_line
    // [1189] phi from print_chips::@4 to print_chip_line [phi:print_chips::@4->print_chip_line]
    // [1189] phi print_chip_line::c#12 = 'o'pm [phi:print_chips::@4->print_chip_line#0] -- vbum1=vbuc1 
    lda #'o'
    sta print_chip_line.c
    // [1189] phi print_chip_line::y#12 = $2f [phi:print_chips::@4->print_chip_line#1] -- vbum1=vbuc1 
    lda #$2f
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#2 [phi:print_chips::@4->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@5
    // print_chip_line(3 + r * 10, 48, 'm')
    // [742] print_chip_line::x#3 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [743] call print_chip_line
    // [1189] phi from print_chips::@5 to print_chip_line [phi:print_chips::@5->print_chip_line]
    // [1189] phi print_chip_line::c#12 = 'm'pm [phi:print_chips::@5->print_chip_line#0] -- vbum1=vbuc1 
    lda #'m'
    sta print_chip_line.c
    // [1189] phi print_chip_line::y#12 = $30 [phi:print_chips::@5->print_chip_line#1] -- vbum1=vbuc1 
    lda #$30
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#3 [phi:print_chips::@5->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@6
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [744] print_chip_line::x#4 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [745] print_chip_line::c#4 = '0'pm + print_chips::r#10 -- vbum1=vbuc1_plus_vbum2 
    lda #'0'
    clc
    adc r
    sta print_chip_line.c
    // [746] call print_chip_line
    // [1189] phi from print_chips::@6 to print_chip_line [phi:print_chips::@6->print_chip_line]
    // [1189] phi print_chip_line::c#12 = print_chip_line::c#4 [phi:print_chips::@6->print_chip_line#0] -- register_copy 
    // [1189] phi print_chip_line::y#12 = $31 [phi:print_chips::@6->print_chip_line#1] -- vbum1=vbuc1 
    lda #$31
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#4 [phi:print_chips::@6->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@7
    // print_chip_line(3 + r * 10, 50, ' ')
    // [747] print_chip_line::x#5 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [748] call print_chip_line
    // [1189] phi from print_chips::@7 to print_chip_line [phi:print_chips::@7->print_chip_line]
    // [1189] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@7->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1189] phi print_chip_line::y#12 = $32 [phi:print_chips::@7->print_chip_line#1] -- vbum1=vbuc1 
    lda #$32
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#5 [phi:print_chips::@7->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@8
    // print_chip_line(3 + r * 10, 51, ' ')
    // [749] print_chip_line::x#6 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [750] call print_chip_line
    // [1189] phi from print_chips::@8 to print_chip_line [phi:print_chips::@8->print_chip_line]
    // [1189] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@8->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1189] phi print_chip_line::y#12 = $33 [phi:print_chips::@8->print_chip_line#1] -- vbum1=vbuc1 
    lda #$33
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#6 [phi:print_chips::@8->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@9
    // print_chip_line(3 + r * 10, 52, ' ')
    // [751] print_chip_line::x#7 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [752] call print_chip_line
    // [1189] phi from print_chips::@9 to print_chip_line [phi:print_chips::@9->print_chip_line]
    // [1189] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@9->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1189] phi print_chip_line::y#12 = $34 [phi:print_chips::@9->print_chip_line#1] -- vbum1=vbuc1 
    lda #$34
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#7 [phi:print_chips::@9->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@10
    // print_chip_line(3 + r * 10, 53, ' ')
    // [753] print_chip_line::x#8 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [754] call print_chip_line
    // [1189] phi from print_chips::@10 to print_chip_line [phi:print_chips::@10->print_chip_line]
    // [1189] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@10->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1189] phi print_chip_line::y#12 = $35 [phi:print_chips::@10->print_chip_line#1] -- vbum1=vbuc1 
    lda #$35
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#8 [phi:print_chips::@10->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@11
    // print_chip_end(3 + r * 10, 54)
    // [755] print_chip_end::x#0 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum1 
    lda #3
    clc
    adc print_chip_end.x
    sta print_chip_end.x
    // [756] call print_chip_end
    jsr print_chip_end
    // print_chips::@12
    // print_chip_led(r, BLACK, BLUE)
    // [757] print_chip_led::r#0 = print_chips::r#10 -- vbum1=vbum2 
    lda r
    sta print_chip_led.r
    // [758] call print_chip_led
    // [899] phi from print_chips::@12 to print_chip_led [phi:print_chips::@12->print_chip_led]
    // [899] phi print_chip_led::tc#10 = BLACK [phi:print_chips::@12->print_chip_led#0] -- vbum1=vbuc1 
    lda #BLACK
    sta print_chip_led.tc
    // [899] phi print_chip_led::r#10 = print_chip_led::r#0 [phi:print_chips::@12->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // print_chips::@13
    // for (unsigned char r = 0; r < 8; r++)
    // [759] print_chips::r#1 = ++ print_chips::r#10 -- vbum1=_inc_vbum1 
    inc r
    // [730] phi from print_chips::@13 to print_chips::@1 [phi:print_chips::@13->print_chips::@1]
    // [730] phi print_chips::r#10 = print_chips::r#1 [phi:print_chips::@13->print_chips::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label __4 = __33
    r: .byte 0
    __33: .byte 0
    .label __34 = __33
}
.segment Code
  // print_clear
print_clear: {
    // textcolor(WHITE)
    // [761] call textcolor
    // [472] phi from print_clear to textcolor [phi:print_clear->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:print_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [762] phi from print_clear to print_clear::@1 [phi:print_clear->print_clear::@1]
    // print_clear::@1
    // gotoxy(2, 39)
    // [763] call gotoxy
    // [490] phi from print_clear::@1 to gotoxy [phi:print_clear::@1->gotoxy]
    // [490] phi gotoxy::y#25 = $27 [phi:print_clear::@1->gotoxy#0] -- vbum1=vbuc1 
    lda #$27
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = 2 [phi:print_clear::@1->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [764] phi from print_clear::@1 to print_clear::@2 [phi:print_clear::@1->print_clear::@2]
    // print_clear::@2
    // printf("%76s", " ")
    // [765] call printf_string
    // [769] phi from print_clear::@2 to printf_string [phi:print_clear::@2->printf_string]
    // [769] phi printf_string::str#12 = str [phi:print_clear::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [769] phi printf_string::format_min_length#12 = $4c [phi:print_clear::@2->printf_string#1] -- vbum1=vbuc1 
    lda #$4c
    sta printf_string.format_min_length
    jsr printf_string
    // [766] phi from print_clear::@2 to print_clear::@3 [phi:print_clear::@2->print_clear::@3]
    // print_clear::@3
    // gotoxy(2, 39)
    // [767] call gotoxy
    // [490] phi from print_clear::@3 to gotoxy [phi:print_clear::@3->gotoxy]
    // [490] phi gotoxy::y#25 = $27 [phi:print_clear::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #$27
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = 2 [phi:print_clear::@3->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // print_clear::@return
    // }
    // [768] return 
    rts
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($24) char *str, __mem() char format_min_length, char format_justify_left)
printf_string: {
    .label str = $24
    // if(format.min_length)
    // [770] if(0==printf_string::format_min_length#12) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b1
    // printf_string::@3
    // strlen(str)
    // [771] strlen::str#4 = printf_string::str#12 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [772] call strlen
    // [823] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [823] phi strlen::str#9 = strlen::str#4 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [773] strlen::return#12 = strlen::len#2
    // printf_string::@5
    // [774] printf_string::$9 = strlen::return#12
    // signed char len = (signed char)strlen(str)
    // [775] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwum2 
    lda __9
    sta len
    // padding = (signed char)format.min_length  - len
    // [776] printf_string::padding#1 = (signed char)printf_string::format_min_length#12 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [777] if(printf_string::padding#1>=0) goto printf_string::@7 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b6
    // [779] phi from printf_string printf_string::@5 to printf_string::@1 [phi:printf_string/printf_string::@5->printf_string::@1]
  __b1:
    // [779] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@5->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [778] phi from printf_string::@5 to printf_string::@7 [phi:printf_string::@5->printf_string::@7]
    // printf_string::@7
    // [779] phi from printf_string::@7 to printf_string::@1 [phi:printf_string::@7->printf_string::@1]
    // [779] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@7->printf_string::@1#0] -- register_copy 
    // printf_string::@1
    // printf_string::@6
  __b6:
    // if(!format.justify_left && padding)
    // [780] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [781] printf_padding::length#3 = (char)printf_string::padding#3
    // [782] call printf_padding
    // [1247] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1247] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1247] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1247] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [783] printf_str::s#2 = printf_string::str#12
    // [784] call printf_str
    // [720] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@return
    // }
    // [785] return 
    rts
  .segment Data
    .label __9 = strlen.len
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
}
.segment Code
  // wait_key
wait_key: {
    .const bank_set_bram1_bank = 0
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [787] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [788] phi from wait_key::bank_set_bram1 to wait_key::@2 [phi:wait_key::bank_set_bram1->wait_key::@2]
    // wait_key::@2
    // bank_set_brom(0)
    // [789] call bank_set_brom
    // [796] phi from wait_key::@2 to bank_set_brom [phi:wait_key::@2->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 0 [phi:wait_key::@2->bank_set_brom#0] -- vbum1=vbuc1 
    lda #0
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [790] phi from wait_key::@2 wait_key::@3 to wait_key::@1 [phi:wait_key::@2/wait_key::@3->wait_key::@1]
    // wait_key::@1
  __b1:
    // getin()
    // [791] call getin
    jsr getin
    // [792] getin::return#2 = getin::return#1
    // wait_key::@3
    // [793] wait_key::return#0 = getin::return#2
    // while (!(ch = getin()))
    // [794] if(0==wait_key::return#0) goto wait_key::@1 -- 0_eq_vbum1_then_la1 
    lda return
    beq __b1
    // wait_key::@return
    // }
    // [795] return 
    rts
  .segment Data
    .label return = getin.return
}
.segment Code
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
// void bank_set_brom(__mem() char bank)
bank_set_brom: {
    // BROM = bank
    // [797] BROM = bank_set_brom::bank#12 -- vbuz1=vbum2 
    lda bank
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [798] return 
    rts
  .segment Data
    bank: .byte 0
}
.segment Code
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [800] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [801] phi from system_reset::bank_set_bram1 to system_reset::@1 [phi:system_reset::bank_set_bram1->system_reset::@1]
    // system_reset::@1
    // bank_set_brom(0)
    // [802] call bank_set_brom
    // [796] phi from system_reset::@1 to bank_set_brom [phi:system_reset::@1->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = 0 [phi:system_reset::@1->bank_set_brom#0] -- vbum1=vbuc1 
    lda #0
    sta bank_set_brom.bank
    jsr bank_set_brom
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [804] return 
}
  // printf_sint
// Print a signed integer using a specific format
// void printf_sint(void (*putc)(char), __mem() int value, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_sint: {
    .const format_min_length = 0
    .const format_justify_left = 0
    .const format_zero_padding = 0
    .const format_upper_case = 0
    .label putc = cputc
    // printf_buffer.sign = 0
    // [805] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // if(value<0)
    // [806] if(printf_sint::value#1<0) goto printf_sint::@1 -- vwsm1_lt_0_then_la1 
    lda value+1
    bmi __b1
    // [809] phi from printf_sint printf_sint::@1 to printf_sint::@2 [phi:printf_sint/printf_sint::@1->printf_sint::@2]
    // [809] phi printf_sint::value#4 = printf_sint::value#1 [phi:printf_sint/printf_sint::@1->printf_sint::@2#0] -- register_copy 
    jmp __b2
    // printf_sint::@1
  __b1:
    // value = -value
    // [807] printf_sint::value#0 = - printf_sint::value#1 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc value
    sta value
    lda #0
    sbc value+1
    sta value+1
    // printf_buffer.sign = '-'
    // [808] *((char *)&printf_buffer) = '-'pm -- _deref_pbuc1=vbuc2 
    lda #'-'
    sta printf_buffer
    // printf_sint::@2
  __b2:
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [810] utoa::value#1 = (unsigned int)printf_sint::value#4
    // [811] call utoa
    // [1261] phi from printf_sint::@2 to utoa [phi:printf_sint::@2->utoa]
    // [1261] phi utoa::value#10 = utoa::value#1 [phi:printf_sint::@2->utoa#0] -- register_copy 
    // [1261] phi utoa::radix#2 = DECIMAL [phi:printf_sint::@2->utoa#1] -- vbum1=vbuc1 
    lda #DECIMAL
    sta utoa.radix
    jsr utoa
    // printf_sint::@3
    // printf_number_buffer(putc, printf_buffer, format)
    // [812] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [813] call printf_number_buffer
  // Print using format
    // [1292] phi from printf_sint::@3 to printf_number_buffer [phi:printf_sint::@3->printf_number_buffer]
    // [1292] phi printf_number_buffer::format_upper_case#10 = printf_sint::format_upper_case#0 [phi:printf_sint::@3->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #format_upper_case
    sta printf_number_buffer.format_upper_case
    // [1292] phi printf_number_buffer::putc#10 = printf_sint::putc#0 [phi:printf_sint::@3->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [1292] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_sint::@3->printf_number_buffer#2] -- register_copy 
    // [1292] phi printf_number_buffer::format_zero_padding#10 = printf_sint::format_zero_padding#0 [phi:printf_sint::@3->printf_number_buffer#3] -- vbum1=vbuc1 
    lda #format_zero_padding
    sta printf_number_buffer.format_zero_padding
    // [1292] phi printf_number_buffer::format_justify_left#10 = printf_sint::format_justify_left#0 [phi:printf_sint::@3->printf_number_buffer#4] -- vbum1=vbuc1 
    lda #format_justify_left
    sta printf_number_buffer.format_justify_left
    // [1292] phi printf_number_buffer::format_min_length#4 = printf_sint::format_min_length#0 [phi:printf_sint::@3->printf_number_buffer#5] -- vbum1=vbuc1 
    lda #format_min_length
    sta printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_sint::@return
    // }
    // [814] return 
    rts
  .segment Data
    value: .word 0
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label dst = $22
    .label src = $3b
    // [816] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [816] phi strcpy::dst#2 = file [phi:strcpy->strcpy::@1#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z dst
    lda #>file
    sta.z dst+1
    // [816] phi strcpy::src#2 = main::source [phi:strcpy->strcpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.source
    sta.z src
    lda #>main.source
    sta.z src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [817] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [818] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [819] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [820] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [821] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [822] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [816] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [816] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [816] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($22) char *str)
strlen: {
    .label str = $22
    // [824] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [824] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [824] phi strlen::str#7 = strlen::str#9 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [825] if(0!=*strlen::str#7) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [826] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [827] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [828] strlen::str#2 = ++ strlen::str#7 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [824] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [824] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [824] phi strlen::str#7 = strlen::str#2 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, char *source)
strcat: {
    .label dst = $22
    .label src = $3b
    // strlen(destination)
    // [830] call strlen
    // [823] phi from strcat to strlen [phi:strcat->strlen]
    // [823] phi strlen::str#9 = file [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strlen.str
    lda #>file
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [831] strlen::return#1 = strlen::len#2
    // strcat::@4
    // [832] strcat::$0 = strlen::return#1
    // char* dst = destination + strlen(destination)
    // [833] strcat::dst#0 = file + strcat::$0 -- pbuz1=pbuc1_plus_vwum2 
    lda __0
    clc
    adc #<file
    sta.z dst
    lda __0+1
    adc #>file
    sta.z dst+1
    // [834] phi from strcat::@4 to strcat::@1 [phi:strcat::@4->strcat::@1]
    // [834] phi strcat::dst#2 = strcat::dst#0 [phi:strcat::@4->strcat::@1#0] -- register_copy 
    // [834] phi strcat::src#2 = main::source1 [phi:strcat::@4->strcat::@1#1] -- pbuz1=pbuc1 
    lda #<main.source1
    sta.z src
    lda #>main.source1
    sta.z src+1
    // strcat::@1
  __b1:
    // while(*src)
    // [835] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [836] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [837] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [838] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [839] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [840] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [834] phi from strcat::@2 to strcat::@1 [phi:strcat::@2->strcat::@1]
    // [834] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2->strcat::@1#0] -- register_copy 
    // [834] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2->strcat::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label __0 = strlen.len
}
.segment Code
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
// __zp($3b) struct $1 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label stream = $3b
    .label dst = $22
    .label return = $3b
    .label __24 = $31
    .label __25 = $29
    .label __26 = $2f
    .label __27 = $41
    .label __28 = $4a
    .label __29 = $2b
    .label __30 = $2d
    .label __31 = $33
    // unsigned int sp = __stdio_filecount
    // [841] fopen::sp#0 = (unsigned int)__stdio_filecount -- vwum1=_word_vbum2 
    lda __stdio_filecount
    sta sp
    lda #0
    sta sp+1
    // (unsigned int)sp | 0x8000
    // [842] fopen::stream#0 = fopen::sp#0 | $8000 -- vwuz1=vwum2_bor_vwuc1 
    lda sp
    ora #<$8000
    sta.z stream
    lda sp+1
    ora #>$8000
    sta.z stream+1
    // __stdio_file.status[sp] = 0
    // [843] fopen::$24 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __24
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __24+1
    // [844] *fopen::$24 = 0 -- _deref_pbuz1=vbuc1 
    // We set bit 7 of the high byte, to differentiate from NULL.
    lda #0
    tay
    sta (__24),y
    // __stdio_file.channel[sp] = channel
    // [845] fopen::$25 = (char *)&__stdio_file+$40 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$40
    sta.z __25
    lda sp+1
    adc #>__stdio_file+$40
    sta.z __25+1
    // [846] *fopen::$25 = fopen::channel#0 -- _deref_pbuz1=vbuc1 
    lda #channel
    sta (__25),y
    // __stdio_file.device[sp] = device
    // [847] fopen::$26 = (char *)&__stdio_file+$42 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$42
    sta.z __26
    lda sp+1
    adc #>__stdio_file+$42
    sta.z __26+1
    // [848] *fopen::$26 = fopen::device#0 -- _deref_pbuz1=vbuc1 
    lda #device
    sta (__26),y
    // __stdio_file.secondary[sp] = secondary
    // [849] fopen::$27 = (char *)&__stdio_file+$44 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$44
    sta.z __27
    lda sp+1
    adc #>__stdio_file+$44
    sta.z __27+1
    // [850] *fopen::$27 = fopen::secondary#0 -- _deref_pbuz1=vbuc1 
    lda #secondary
    sta (__27),y
    // sp * __STDIO_FILECOUNT
    // [851] fopen::$12 = fopen::sp#0 << 1 -- vwum1=vwum2_rol_1 
    lda sp
    asl
    sta __12
    lda sp+1
    rol
    sta __12+1
    // char* dst = &__stdio_file.filename[sp * __STDIO_FILECOUNT]
    // [852] fopen::dst#0 = (char *)&__stdio_file + fopen::$12 -- pbuz1=pbuc1_plus_vwum2 
    lda __12
    clc
    adc #<__stdio_file
    sta.z dst
    lda __12+1
    adc #>__stdio_file
    sta.z dst+1
    // strncpy(dst, filename, 16)
    // [853] strncpy::dst#1 = fopen::dst#0
    // [854] call strncpy
    // [1333] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@5
    // cbm_k_setnam(filename)
    // [855] cbm_k_setnam::filename = file -- pbuz1=pbuc1 
    lda #<file
    sta.z cbm_k_setnam.filename
    lda #>file
    sta.z cbm_k_setnam.filename+1
    // [856] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@6
    // cbm_k_setlfs(channel, device, secondary)
    // [857] cbm_k_setlfs::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_setlfs.channel
    // [858] cbm_k_setlfs::device = fopen::device#0 -- vbum1=vbuc1 
    lda #device
    sta cbm_k_setlfs.device
    // [859] cbm_k_setlfs::command = fopen::secondary#0 -- vbum1=vbuc1 
    lda #secondary
    sta cbm_k_setlfs.command
    // [860] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [861] phi from fopen::@6 to fopen::@7 [phi:fopen::@6->fopen::@7]
    // fopen::@7
    // cbm_k_open()
    // [862] call cbm_k_open
    jsr cbm_k_open
    // [863] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@8
    // [864] fopen::$6 = cbm_k_open::return#2
    // __stdio_file.status[sp] = cbm_k_open()
    // [865] fopen::$28 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __28
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __28+1
    // [866] *fopen::$28 = fopen::$6 -- _deref_pbuz1=vbum2 
    lda __6
    ldy #0
    sta (__28),y
    // if (__stdio_file.status[sp])
    // [867] fopen::$29 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __29
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __29+1
    // [868] if(0==*fopen::$29) goto fopen::@1 -- 0_eq__deref_pbuz1_then_la1 
    lda (__29),y
    cmp #0
    beq __b1
    // fopen::@3
    // ferror(stream)
    // [869] ferror::stream#0 = (struct $1 *)fopen::stream#0
    // [870] call ferror
  // The POSIX standard specifies that in case of file not found, NULL is returned.
  // However, the error needs to be cleared from the device.
  // This needs to be done using ferror, but this function needs a FILE* stream.
  // As fopen returns NULL in case file not found, the ferror must be called before return
  // to clear the error from the device. Otherwise the device is left with a red blicking led.
    // [1358] phi from fopen::@3 to ferror [phi:fopen::@3->ferror]
    // [1358] phi ferror::stream#2 = ferror::stream#0 [phi:fopen::@3->ferror#0] -- register_copy 
    jsr ferror
    // fopen::@11
    // printf("%s\n", __stdio_file.error + sp * __STDIO_FILECOUNT)
    // [871] printf_string::str#0 = (char *)&__stdio_file+$48 + fopen::$12 -- pbuz1=pbuc1_plus_vwum2 
    lda __12
    clc
    adc #<__stdio_file+$48
    sta.z printf_string.str
    lda __12+1
    adc #>__stdio_file+$48
    sta.z printf_string.str+1
    // [872] call printf_string
    // [769] phi from fopen::@11 to printf_string [phi:fopen::@11->printf_string]
    // [769] phi printf_string::str#12 = printf_string::str#0 [phi:fopen::@11->printf_string#0] -- register_copy 
    // [769] phi printf_string::format_min_length#12 = 0 [phi:fopen::@11->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [873] phi from fopen::@11 to fopen::@12 [phi:fopen::@11->fopen::@12]
    // fopen::@12
    // printf("%s\n", __stdio_file.error + sp * __STDIO_FILECOUNT)
    // [874] call printf_str
    // [720] phi from fopen::@12 to printf_str [phi:fopen::@12->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:fopen::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = fopen::s [phi:fopen::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // fopen::@13
    // cbm_k_close(channel)
    // [875] cbm_k_close::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_close.channel
    // [876] call cbm_k_close
    jsr cbm_k_close
    // [877] phi from fopen::@13 fopen::@16 to fopen::@return [phi:fopen::@13/fopen::@16->fopen::@return]
  __b3:
    // [877] phi fopen::return#1 = 0 [phi:fopen::@13/fopen::@16->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [878] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [879] cbm_k_chkin::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_chkin.channel
    // [880] call cbm_k_chkin
    jsr cbm_k_chkin
    // [881] phi from fopen::@1 to fopen::@9 [phi:fopen::@1->fopen::@9]
    // fopen::@9
    // cbm_k_readst()
    // [882] call cbm_k_readst
    jsr cbm_k_readst
    // [883] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@10
    // [884] fopen::$9 = cbm_k_readst::return#2
    // __stdio_file.status[sp] = cbm_k_readst()
    // [885] fopen::$30 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __30
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __30+1
    // [886] *fopen::$30 = fopen::$9 -- _deref_pbuz1=vbum2 
    lda __9
    ldy #0
    sta (__30),y
    // if (__stdio_file.status[sp])
    // [887] fopen::$31 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __31
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __31+1
    // [888] if(0==*fopen::$31) goto fopen::@2 -- 0_eq__deref_pbuz1_then_la1 
    lda (__31),y
    cmp #0
    beq __b2
    // fopen::@4
    // ferror(stream)
    // [889] ferror::stream#1 = (struct $1 *)fopen::stream#0
    // [890] call ferror
    // [1358] phi from fopen::@4 to ferror [phi:fopen::@4->ferror]
    // [1358] phi ferror::stream#2 = ferror::stream#1 [phi:fopen::@4->ferror#0] -- register_copy 
    jsr ferror
    // fopen::@14
    // printf("%s\n", __stdio_file.error + sp * __STDIO_FILECOUNT)
    // [891] printf_string::str#1 = (char *)&__stdio_file+$48 + fopen::$12 -- pbuz1=pbuc1_plus_vwum2 
    lda __12
    clc
    adc #<__stdio_file+$48
    sta.z printf_string.str
    lda __12+1
    adc #>__stdio_file+$48
    sta.z printf_string.str+1
    // [892] call printf_string
    // [769] phi from fopen::@14 to printf_string [phi:fopen::@14->printf_string]
    // [769] phi printf_string::str#12 = printf_string::str#1 [phi:fopen::@14->printf_string#0] -- register_copy 
    // [769] phi printf_string::format_min_length#12 = 0 [phi:fopen::@14->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [893] phi from fopen::@14 to fopen::@15 [phi:fopen::@14->fopen::@15]
    // fopen::@15
    // printf("%s\n", __stdio_file.error + sp * __STDIO_FILECOUNT)
    // [894] call printf_str
    // [720] phi from fopen::@15 to printf_str [phi:fopen::@15->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:fopen::@15->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = fopen::s [phi:fopen::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // fopen::@16
    // cbm_k_close(channel)
    // [895] cbm_k_close::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_close.channel
    // [896] call cbm_k_close
    jsr cbm_k_close
    jmp __b3
    // fopen::@2
  __b2:
    // __stdio_filecount++;
    // [897] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [898] fopen::return#7 = (struct $1 *)fopen::stream#0
    // [877] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [877] phi fopen::return#1 = fopen::return#7 [phi:fopen::@2->fopen::@return#0] -- register_copy 
    rts
  .segment Data
    s: .text @"\n"
    .byte 0
    .label __6 = cbm_k_open.return
    .label __9 = cbm_k_readst.return
    __12: .word 0
    sp: .word 0
}
.segment Code
  // print_chip_led
// void print_chip_led(__mem() char r, __mem() char tc, char bc)
print_chip_led: {
    // r * 10
    // [900] print_chip_led::$8 = print_chip_led::r#10 << 2 -- vbum1=vbum2_rol_2 
    lda r
    asl
    asl
    sta __8
    // [901] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#10 -- vbum1=vbum2_plus_vbum1 
    lda __9
    clc
    adc __8
    sta __9
    // [902] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbum1=vbum1_rol_1 
    asl __0
    // gotoxy(4 + r * 10, 43)
    // [903] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbum1=vbuc1_plus_vbum2 
    lda #4
    clc
    adc __0
    sta gotoxy.x
    // [904] call gotoxy
    // [490] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [490] phi gotoxy::y#25 = $2b [phi:print_chip_led->gotoxy#0] -- vbum1=vbuc1 
    lda #$2b
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [905] textcolor::color#8 = print_chip_led::tc#10 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [906] call textcolor
    // [472] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [472] phi textcolor::color#23 = textcolor::color#8 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [907] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [908] call bgcolor
    // [477] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [909] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [910] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [912] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [913] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [915] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [916] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [918] return 
    rts
  .segment Data
    .label __0 = r
    r: .byte 0
    tc: .byte 0
    __8: .byte 0
    .label __9 = r
}
.segment Code
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [920] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [921] uctoa::value#1 = printf_uchar::uvalue#11
    // [922] uctoa::radix#0 = printf_uchar::format_radix#11
    // [923] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [924] printf_number_buffer::buffer_sign#3 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [925] printf_number_buffer::format_min_length#3 = printf_uchar::format_min_length#11
    // [926] printf_number_buffer::format_zero_padding#3 = printf_uchar::format_zero_padding#11
    // [927] call printf_number_buffer
  // Print using format
    // [1292] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1292] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_upper_case
    // [1292] phi printf_number_buffer::putc#10 = &cputc [phi:printf_uchar::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1292] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#3 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1292] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#3 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [1292] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_justify_left
    // [1292] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#3 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [928] return 
    rts
  .segment Data
    uvalue: .byte 0
    format_radix: .byte 0
    format_min_length: .byte 0
    format_zero_padding: .byte 0
}
.segment Code
  // table_chip_clear
// void table_chip_clear(__mem() char rom_bank)
table_chip_clear: {
    // textcolor(WHITE)
    // [930] call textcolor
    // [472] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:table_chip_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [931] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [932] call bgcolor
    // [477] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [933] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [933] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [933] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbum1=vbuc1 
    lda #4
    sta y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [934] if(table_chip_clear::y#10<$24) goto table_chip_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #$24
    bcc __b2
    // table_chip_clear::@return
    // }
    // [935] return 
    rts
    // table_chip_clear::@2
  __b2:
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [936] rom_address::rom_bank#1 = table_chip_clear::rom_bank#11 -- vbum1=vbum2 
    lda rom_bank
    sta rom_address.rom_bank
    // [937] call rom_address
    // [954] phi from table_chip_clear::@2 to rom_address [phi:table_chip_clear::@2->rom_address]
    // [954] phi rom_address::rom_bank#5 = rom_address::rom_bank#1 [phi:table_chip_clear::@2->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [938] rom_address::return#3 = rom_address::return#0
    // table_chip_clear::@4
    // [939] table_chip_clear::flash_rom_address#0 = rom_address::return#3
    // gotoxy(2, y)
    // [940] gotoxy::y#9 = table_chip_clear::y#10 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [941] call gotoxy
    // [490] phi from table_chip_clear::@4 to gotoxy [phi:table_chip_clear::@4->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#9 [phi:table_chip_clear::@4->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = 2 [phi:table_chip_clear::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // table_chip_clear::@5
    // printf("%02x", rom_bank)
    // [942] printf_uchar::uvalue#2 = table_chip_clear::rom_bank#11 -- vbum1=vbum2 
    lda rom_bank
    sta printf_uchar.uvalue
    // [943] call printf_uchar
    // [919] phi from table_chip_clear::@5 to printf_uchar [phi:table_chip_clear::@5->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 1 [phi:table_chip_clear::@5->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 2 [phi:table_chip_clear::@5->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:table_chip_clear::@5->printf_uchar#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#2 [phi:table_chip_clear::@5->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@6
    // gotoxy(5, y)
    // [944] gotoxy::y#10 = table_chip_clear::y#10 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [945] call gotoxy
    // [490] phi from table_chip_clear::@6 to gotoxy [phi:table_chip_clear::@6->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#10 [phi:table_chip_clear::@6->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = 5 [phi:table_chip_clear::@6->gotoxy#1] -- vbum1=vbuc1 
    lda #5
    sta gotoxy.x
    jsr gotoxy
    // table_chip_clear::@7
    // printf("%06x", flash_rom_address)
    // [946] printf_ulong::uvalue#1 = table_chip_clear::flash_rom_address#0 -- vdum1=vdum2 
    lda flash_rom_address
    sta printf_ulong.uvalue
    lda flash_rom_address+1
    sta printf_ulong.uvalue+1
    lda flash_rom_address+2
    sta printf_ulong.uvalue+2
    lda flash_rom_address+3
    sta printf_ulong.uvalue+3
    // [947] call printf_ulong
    // [1445] phi from table_chip_clear::@7 to printf_ulong [phi:table_chip_clear::@7->printf_ulong]
    // [1445] phi printf_ulong::format_zero_padding#2 = 1 [phi:table_chip_clear::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1445] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:table_chip_clear::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // table_chip_clear::@8
    // gotoxy(14, y)
    // [948] gotoxy::y#11 = table_chip_clear::y#10 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [949] call gotoxy
    // [490] phi from table_chip_clear::@8 to gotoxy [phi:table_chip_clear::@8->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#11 [phi:table_chip_clear::@8->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = $e [phi:table_chip_clear::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #$e
    sta gotoxy.x
    jsr gotoxy
    // [950] phi from table_chip_clear::@8 to table_chip_clear::@9 [phi:table_chip_clear::@8->table_chip_clear::@9]
    // table_chip_clear::@9
    // printf("%64s", " ")
    // [951] call printf_string
    // [769] phi from table_chip_clear::@9 to printf_string [phi:table_chip_clear::@9->printf_string]
    // [769] phi printf_string::str#12 = str [phi:table_chip_clear::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [769] phi printf_string::format_min_length#12 = $40 [phi:table_chip_clear::@9->printf_string#1] -- vbum1=vbuc1 
    lda #$40
    sta printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@10
    // rom_bank++;
    // [952] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#11 -- vbum1=_inc_vbum1 
    inc rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [953] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbum1=_inc_vbum1 
    inc y
    // [933] phi from table_chip_clear::@10 to table_chip_clear::@1 [phi:table_chip_clear::@10->table_chip_clear::@1]
    // [933] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@10->table_chip_clear::@1#0] -- register_copy 
    // [933] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@10->table_chip_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label flash_rom_address = rom_address.return
    rom_bank: .byte 0
    y: .byte 0
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
/* inline */
// __mem() unsigned long rom_address(__mem() char rom_bank)
rom_address: {
    // ((unsigned long)(rom_bank)) << 14
    // [955] rom_address::$1 = (unsigned long)rom_address::rom_bank#5 -- vdum1=_dword_vbum2 
    lda rom_bank
    sta __1
    lda #0
    sta __1+1
    sta __1+2
    sta __1+3
    // [956] rom_address::return#0 = rom_address::$1 << $e -- vdum1=vdum1_rol_vbuc1 
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
    // rom_address::@return
    // }
    // [957] return 
    rts
  .segment Data
    .label __1 = return
    return: .dword 0
    rom_bank: .byte 0
    .label return_1 = flash_read.flash_rom_address
    return_2: .dword 0
    .label return_3 = main.flash_rom_address1
    .label return_4 = main.flash_rom_address_sector
}
.segment Code
  // flash_read
// __mem() unsigned long flash_read(__zp($22) struct $1 *fp, __zp($2f) char *flash_ram_address, __mem() char rom_bank_start, __mem() unsigned long read_size)
flash_read: {
    .label flash_ram_address = $2f
    .label fp = $22
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [959] rom_address::rom_bank#0 = flash_read::rom_bank_start#11 -- vbum1=vbum2 
    lda rom_bank_start
    sta rom_address.rom_bank
    // [960] call rom_address
    // [954] phi from flash_read to rom_address [phi:flash_read->rom_address]
    // [954] phi rom_address::rom_bank#5 = rom_address::rom_bank#0 [phi:flash_read->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [961] rom_address::return#2 = rom_address::return#0 -- vdum1=vdum2 
    lda rom_address.return
    sta rom_address.return_1
    lda rom_address.return+1
    sta rom_address.return_1+1
    lda rom_address.return+2
    sta rom_address.return_1+2
    lda rom_address.return+3
    sta rom_address.return_1+3
    // flash_read::@9
    // [962] flash_read::flash_rom_address#0 = rom_address::return#2
    // textcolor(WHITE)
    // [963] call textcolor
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [472] phi from flash_read::@9 to textcolor [phi:flash_read::@9->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:flash_read::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [964] phi from flash_read::@9 to flash_read::@1 [phi:flash_read::@9->flash_read::@1]
    // [964] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@9->flash_read::@1#0] -- register_copy 
    // [964] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@9->flash_read::@1#1] -- register_copy 
    // [964] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#0 [phi:flash_read::@9->flash_read::@1#2] -- register_copy 
    // [964] phi flash_read::return#2 = 0 [phi:flash_read::@9->flash_read::@1#3] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
    // [964] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [964] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [964] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [964] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [964] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < read_size)
    // [965] if(flash_read::return#2<flash_read::read_size#4) goto flash_read::@2 -- vdum1_lt_vdum2_then_la1 
    lda return+3
    cmp read_size+3
    bcc __b2
    bne !+
    lda return+2
    cmp read_size+2
    bcc __b2
    bne !+
    lda return+1
    cmp read_size+1
    bcc __b2
    bne !+
    lda return
    cmp read_size
    bcc __b2
  !:
    // flash_read::@return
    // }
    // [966] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [967] flash_read::$3 = flash_read::flash_rom_address#10 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [968] if(0!=flash_read::$3) goto flash_read::@3 -- 0_neq_vdum1_then_la1 
    lda __3
    ora __3+1
    ora __3+2
    ora __3+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [969] flash_read::$6 = flash_read::rom_bank_start#4 & $20-1 -- vbum1=vbum2_band_vbuc1 
    lda #$20-1
    and rom_bank_start
    sta __6
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [970] gotoxy::y#8 = 4 + flash_read::$6 -- vbum1=vbuc1_plus_vbum2 
    lda #4
    clc
    adc __6
    sta gotoxy.y
    // [971] call gotoxy
    // [490] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#8 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = $e [phi:flash_read::@6->gotoxy#1] -- vbum1=vbuc1 
    lda #$e
    sta gotoxy.x
    jsr gotoxy
    // flash_read::@11
    // rom_bank_start++;
    // [972] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbum1=_inc_vbum1 
    inc rom_bank_start
    // [973] phi from flash_read::@11 flash_read::@2 to flash_read::@3 [phi:flash_read::@11/flash_read::@2->flash_read::@3]
    // [973] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@11/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [974] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [975] fgets::stream#0 = flash_read::fp#10
    // [976] call fgets
    jsr fgets
    // [977] fgets::return#5 = fgets::return#1
    // flash_read::@10
    // [978] flash_read::read_bytes#0 = fgets::return#5
    // if (!read_bytes)
    // [979] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwum1_then_la1 
    lda read_bytes
    ora read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [980] flash_read::$12 = flash_read::flash_rom_address#10 & $100-1 -- vdum1=vdum2_band_vduc1 
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
    // [981] if(0!=flash_read::$12) goto flash_read::@5 -- 0_neq_vdum1_then_la1 
    lda __12
    ora __12+1
    ora __12+2
    ora __12+3
    bne __b5
    // flash_read::@7
    // cputc('.')
    // [982] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    // cputc(0xE0);
    lda #'.'
    pha
    // [983] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [985] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z flash_ram_address
    adc read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [986] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vdum1=vdum1_plus_vwum2 
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
    // [987] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vdum1=vdum1_plus_vwum2 
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
    // [988] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // [989] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
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
    __6: .byte 0
    __12: .dword 0
    flash_rom_address: .dword 0
    .label read_bytes = fgets.read
    rom_bank_start: .byte 0
    return: .dword 0
    .label flash_bytes = return
    read_size: .dword 0
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
// unsigned long rom_size(char rom_banks)
rom_size: {
    .const rom_banks = 1
    .label return = rom_banks<<$e
    // rom_size::@return
    // }
    // [991] return 
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
// int fclose(__zp($4e) struct $1 *stream)
fclose: {
    .label stream = $4e
    .label __5 = $31
    .label __6 = $29
    .label __7 = $2f
    // unsigned int sp = (unsigned int)stream & ~0x8000
    // [992] fclose::sp#0 = (unsigned int)fclose::stream#0 & ~$8000 -- vwum1=vwuz2_band_vwuc1 
    lda.z stream
    and #<$8000^$ffff
    sta sp
    lda.z stream+1
    and #>$8000^$ffff
    sta sp+1
    // cbm_k_close(__stdio_file.channel[sp])
    // [993] fclose::$5 = (char *)&__stdio_file+$40 + fclose::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$40
    sta.z __5
    lda sp+1
    adc #>__stdio_file+$40
    sta.z __5+1
    // [994] cbm_k_close::channel = *fclose::$5 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (__5),y
    sta cbm_k_close.channel
    // [995] call cbm_k_close
    jsr cbm_k_close
    // [996] cbm_k_close::return#5 = cbm_k_close::return#1
    // fclose::@2
    // [997] fclose::$1 = cbm_k_close::return#5
    // __stdio_file.status[sp] = cbm_k_close(__stdio_file.channel[sp])
    // [998] fclose::$6 = (char *)&__stdio_file+$46 + fclose::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __6
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __6+1
    // [999] *fclose::$6 = fclose::$1 -- _deref_pbuz1=vbum2 
    lda __1
    ldy #0
    sta (__6),y
    // if(__stdio_file.status[sp])
    // [1000] fclose::$7 = (char *)&__stdio_file+$46 + fclose::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __7
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __7+1
    // [1001] if(0==*fclose::$7) goto fclose::@1 -- 0_eq__deref_pbuz1_then_la1 
    lda (__7),y
    cmp #0
    beq __b1
    rts
    // fclose::@1
  __b1:
    // __stdio_filecount--;
    // [1002] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    // fclose::@return
    // }
    // [1003] return 
    rts
  .segment Data
    .label __1 = cbm_k_close.return
    sp: .word 0
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1005] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1006] utoa::value#2 = printf_uint::uvalue#3
    // [1007] utoa::radix#1 = printf_uint::format_radix#3
    // [1008] call utoa
  // Format number into buffer
    // [1261] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    // [1261] phi utoa::value#10 = utoa::value#2 [phi:printf_uint::@1->utoa#0] -- register_copy 
    // [1261] phi utoa::radix#2 = utoa::radix#1 [phi:printf_uint::@1->utoa#1] -- register_copy 
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1009] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1010] printf_number_buffer::format_min_length#2 = printf_uint::format_min_length#3
    // [1011] call printf_number_buffer
  // Print using format
    // [1292] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1292] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_upper_case
    // [1292] phi printf_number_buffer::putc#10 = &cputc [phi:printf_uint::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1292] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1292] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_zero_padding
    // [1292] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbum1=vbuc1 
    sta printf_number_buffer.format_justify_left
    // [1292] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#2 [phi:printf_uint::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1012] return 
    rts
  .segment Data
    .label uvalue = printf_sint.value
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
}
.segment Code
  // flash_verify
// __mem() unsigned int flash_verify(__mem() char bank_ram, __zp($33) char *ptr_ram, __mem() unsigned long verify_rom_address, __mem() unsigned int verify_rom_size)
flash_verify: {
    .label rom_ptr1_return = $2f
    .label ptr_rom = $2f
    .label ptr_ram = $33
    // flash_verify::bank_set_bram1
    // BRAM = bank
    // [1014] BRAM = flash_verify::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // flash_verify::rom_bank1
    // BYTE2(address)
    // [1015] flash_verify::rom_bank1_$0 = byte2  flash_verify::verify_rom_address#3 -- vbum1=_byte2_vdum2 
    lda verify_rom_address+2
    sta rom_bank1___0
    // BYTE1(address)
    // [1016] flash_verify::rom_bank1_$1 = byte1  flash_verify::verify_rom_address#3 -- vbum1=_byte1_vdum2 
    lda verify_rom_address+1
    sta rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1017] flash_verify::rom_bank1_$2 = flash_verify::rom_bank1_$0 w= flash_verify::rom_bank1_$1 -- vwum1=vbum2_word_vbum3 
    lda rom_bank1___0
    sta rom_bank1___2+1
    lda rom_bank1___1
    sta rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1018] flash_verify::rom_bank1_bank_unshifted#0 = flash_verify::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1019] flash_verify::rom_bank1_return#0 = byte1  flash_verify::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // flash_verify::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1020] flash_verify::rom_ptr1_$2 = (unsigned int)flash_verify::verify_rom_address#3 -- vwum1=_word_vdum2 
    lda verify_rom_address
    sta rom_ptr1___2
    lda verify_rom_address+1
    sta rom_ptr1___2+1
    // [1021] flash_verify::rom_ptr1_$0 = flash_verify::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1022] flash_verify::rom_ptr1_return#0 = flash_verify::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // flash_verify::@5
    // bank_set_brom(bank_rom)
    // [1023] bank_set_brom::bank#4 = flash_verify::rom_bank1_return#0
    // [1024] call bank_set_brom
    // [796] phi from flash_verify::@5 to bank_set_brom [phi:flash_verify::@5->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = bank_set_brom::bank#4 [phi:flash_verify::@5->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // flash_verify::@6
    // [1025] flash_verify::ptr_rom#9 = (char *)flash_verify::rom_ptr1_return#0
    // [1026] phi from flash_verify::@6 to flash_verify::@1 [phi:flash_verify::@6->flash_verify::@1]
    // [1026] phi flash_verify::correct_bytes#2 = 0 [phi:flash_verify::@6->flash_verify::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta correct_bytes
    sta correct_bytes+1
    // [1026] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#10 [phi:flash_verify::@6->flash_verify::@1#1] -- register_copy 
    // [1026] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#9 [phi:flash_verify::@6->flash_verify::@1#2] -- register_copy 
    // [1026] phi flash_verify::verified_bytes#2 = 0 [phi:flash_verify::@6->flash_verify::@1#3] -- vwum1=vwuc1 
    sta verified_bytes
    sta verified_bytes+1
    // flash_verify::@1
  __b1:
    // while (verified_bytes < verify_rom_size)
    // [1027] if(flash_verify::verified_bytes#2<flash_verify::verify_rom_size#11) goto flash_verify::@2 -- vwum1_lt_vwum2_then_la1 
    lda verified_bytes+1
    cmp verify_rom_size+1
    bcc __b2
    bne !+
    lda verified_bytes
    cmp verify_rom_size
    bcc __b2
  !:
    // flash_verify::@return
    // }
    // [1028] return 
    rts
    // flash_verify::@2
  __b2:
    // rom_byte_verify(ptr_rom, *ptr_ram)
    // [1029] rom_byte_verify::ptr_rom#0 = flash_verify::ptr_rom#2
    // [1030] rom_byte_verify::value#0 = *flash_verify::ptr_ram#4 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta rom_byte_verify.value
    // [1031] call rom_byte_verify
    jsr rom_byte_verify
    // [1032] rom_byte_verify::return#2 = rom_byte_verify::return#0
    // flash_verify::@7
    // [1033] flash_verify::$5 = rom_byte_verify::return#2
    // if (rom_byte_verify(ptr_rom, *ptr_ram))
    // [1034] if(0==flash_verify::$5) goto flash_verify::@3 -- 0_eq_vbum1_then_la1 
    lda __5
    beq __b3
    // flash_verify::@4
    // correct_bytes++;
    // [1035] flash_verify::correct_bytes#1 = ++ flash_verify::correct_bytes#2 -- vwum1=_inc_vwum1 
    inc correct_bytes
    bne !+
    inc correct_bytes+1
  !:
    // [1036] phi from flash_verify::@4 flash_verify::@7 to flash_verify::@3 [phi:flash_verify::@4/flash_verify::@7->flash_verify::@3]
    // [1036] phi flash_verify::correct_bytes#6 = flash_verify::correct_bytes#1 [phi:flash_verify::@4/flash_verify::@7->flash_verify::@3#0] -- register_copy 
    // flash_verify::@3
  __b3:
    // ptr_rom++;
    // [1037] flash_verify::ptr_rom#1 = ++ flash_verify::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [1038] flash_verify::ptr_ram#0 = ++ flash_verify::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // verified_bytes++;
    // [1039] flash_verify::verified_bytes#1 = ++ flash_verify::verified_bytes#2 -- vwum1=_inc_vwum1 
    inc verified_bytes
    bne !+
    inc verified_bytes+1
  !:
    // [1026] phi from flash_verify::@3 to flash_verify::@1 [phi:flash_verify::@3->flash_verify::@1]
    // [1026] phi flash_verify::correct_bytes#2 = flash_verify::correct_bytes#6 [phi:flash_verify::@3->flash_verify::@1#0] -- register_copy 
    // [1026] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#0 [phi:flash_verify::@3->flash_verify::@1#1] -- register_copy 
    // [1026] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#1 [phi:flash_verify::@3->flash_verify::@1#2] -- register_copy 
    // [1026] phi flash_verify::verified_bytes#2 = flash_verify::verified_bytes#1 [phi:flash_verify::@3->flash_verify::@1#3] -- register_copy 
    jmp __b1
  .segment Data
    .label __5 = rom_byte_verify.return
    rom_bank1___0: .byte 0
    rom_bank1___1: .byte 0
    rom_bank1___2: .word 0
    .label rom_ptr1___0 = rom_ptr1___2
    rom_ptr1___2: .word 0
    bank_set_bram1_bank: .byte 0
    .label rom_bank1_bank_unshifted = rom_bank1___2
    .label rom_bank1_return = bank_set_brom.bank
    verified_bytes: .word 0
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    correct_bytes: .word 0
    .label bank_ram = bank_set_bram1_bank
    verify_rom_address: .dword 0
    .label return = correct_bytes
    verify_rom_size: .word 0
}
.segment Code
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
// void rom_sector_erase(__mem() unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_return = $22
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1041] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1___2
    lda address+1
    sta rom_ptr1___2+1
    // [1042] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1043] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [1044] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vdum1=vdum2_band_vduc1 
    lda address
    and #<$380000
    sta rom_chip_address
    lda address+1
    and #>$380000
    sta rom_chip_address+1
    lda address+2
    and #<$380000>>$10
    sta rom_chip_address+2
    lda address+3
    and #>$380000>>$10
    sta rom_chip_address+3
    // rom_unlock(rom_chip_address + 0x05555, 0x80)
    // [1045] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_unlock.address
    adc #<$5555
    sta rom_unlock.address
    lda rom_unlock.address+1
    adc #>$5555
    sta rom_unlock.address+1
    lda rom_unlock.address+2
    adc #0
    sta rom_unlock.address+2
    lda rom_unlock.address+3
    adc #0
    sta rom_unlock.address+3
    // [1046] call rom_unlock
    // [1098] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1098] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbum1=vbuc1 
    lda #$80
    sta rom_unlock.unlock_code
    // [1098] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [1047] rom_unlock::address#1 = rom_sector_erase::address#0 -- vdum1=vdum2 
    lda address
    sta rom_unlock.address
    lda address+1
    sta rom_unlock.address+1
    lda address+2
    sta rom_unlock.address+2
    lda address+3
    sta rom_unlock.address+3
    // [1048] call rom_unlock
    // [1098] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1098] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$30
    sta rom_unlock.unlock_code
    // [1098] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [1049] rom_wait::ptr_rom#1 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [1050] call rom_wait
    // [1505] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [1505] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [1051] return 
    rts
  .segment Data
    .label rom_ptr1___0 = rom_ptr1___2
    rom_ptr1___2: .word 0
    .label rom_chip_address = rom_unlock.address
    address: .dword 0
}
.segment Code
  // print_address
// void print_address(__mem() char bram_bank, __zp($33) char *bram_ptr, __mem() unsigned long brom_address)
print_address: {
    .label brom_ptr = $41
    .label bram_ptr = $33
    // textcolor(WHITE)
    // [1053] call textcolor
    // [472] phi from print_address to textcolor [phi:print_address->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:print_address->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // print_address::rom_bank1
    // BYTE2(address)
    // [1054] print_address::rom_bank1_$0 = byte2  print_address::brom_address#10 -- vbum1=_byte2_vdum2 
    lda brom_address+2
    sta rom_bank1___0
    // BYTE1(address)
    // [1055] print_address::rom_bank1_$1 = byte1  print_address::brom_address#10 -- vbum1=_byte1_vdum2 
    lda brom_address+1
    sta rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1056] print_address::rom_bank1_$2 = print_address::rom_bank1_$0 w= print_address::rom_bank1_$1 -- vwum1=vbum2_word_vbum3 
    lda rom_bank1___0
    sta rom_bank1___2+1
    lda rom_bank1___1
    sta rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1057] print_address::rom_bank1_bank_unshifted#0 = print_address::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1058] print_address::brom_bank#0 = byte1  print_address::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta brom_bank
    // print_address::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1059] print_address::rom_ptr1_$2 = (unsigned int)print_address::brom_address#10 -- vwum1=_word_vdum2 
    lda brom_address
    sta rom_ptr1___2
    lda brom_address+1
    sta rom_ptr1___2+1
    // [1060] print_address::rom_ptr1_$0 = print_address::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1061] print_address::brom_ptr#0 = print_address::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z brom_ptr
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z brom_ptr+1
    // [1062] phi from print_address::rom_ptr1 to print_address::@1 [phi:print_address::rom_ptr1->print_address::@1]
    // print_address::@1
    // gotoxy(43, 1)
    // [1063] call gotoxy
    // [490] phi from print_address::@1 to gotoxy [phi:print_address::@1->gotoxy]
    // [490] phi gotoxy::y#25 = 1 [phi:print_address::@1->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = $2b [phi:print_address::@1->gotoxy#1] -- vbum1=vbuc1 
    lda #$2b
    sta gotoxy.x
    jsr gotoxy
    // [1064] phi from print_address::@1 to print_address::@2 [phi:print_address::@1->print_address::@2]
    // print_address::@2
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1065] call printf_str
    // [720] phi from print_address::@2 to printf_str [phi:print_address::@2->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:print_address::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = print_address::s [phi:print_address::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@3
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1066] printf_uchar::uvalue#0 = print_address::bram_bank#10
    // [1067] call printf_uchar
    // [919] phi from print_address::@3 to printf_uchar [phi:print_address::@3->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:print_address::@3->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 2 [phi:print_address::@3->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:print_address::@3->printf_uchar#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#0 [phi:print_address::@3->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [1068] phi from print_address::@3 to print_address::@4 [phi:print_address::@3->print_address::@4]
    // print_address::@4
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1069] call printf_str
    // [720] phi from print_address::@4 to printf_str [phi:print_address::@4->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:print_address::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = print_address::s1 [phi:print_address::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@5
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1070] printf_uint::uvalue#0 = (unsigned int)print_address::bram_ptr#10 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [1071] call printf_uint
    // [1004] phi from print_address::@5 to printf_uint [phi:print_address::@5->printf_uint]
    // [1004] phi printf_uint::format_min_length#3 = 4 [phi:print_address::@5->printf_uint#0] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1004] phi printf_uint::format_radix#3 = HEXADECIMAL [phi:print_address::@5->printf_uint#1] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1004] phi printf_uint::uvalue#3 = printf_uint::uvalue#0 [phi:print_address::@5->printf_uint#2] -- register_copy 
    jsr printf_uint
    // [1072] phi from print_address::@5 to print_address::@6 [phi:print_address::@5->print_address::@6]
    // print_address::@6
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1073] call printf_str
    // [720] phi from print_address::@6 to printf_str [phi:print_address::@6->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:print_address::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = print_address::s2 [phi:print_address::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@7
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1074] printf_ulong::uvalue#0 = print_address::brom_address#10
    // [1075] call printf_ulong
    // [1445] phi from print_address::@7 to printf_ulong [phi:print_address::@7->printf_ulong]
    // [1445] phi printf_ulong::format_zero_padding#2 = 0 [phi:print_address::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1445] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:print_address::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1076] phi from print_address::@7 to print_address::@8 [phi:print_address::@7->print_address::@8]
    // print_address::@8
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1077] call printf_str
    // [720] phi from print_address::@8 to printf_str [phi:print_address::@8->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:print_address::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = print_address::s3 [phi:print_address::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@9
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1078] printf_uchar::uvalue#1 = print_address::brom_bank#0 -- vbum1=vbum2 
    lda brom_bank
    sta printf_uchar.uvalue
    // [1079] call printf_uchar
    // [919] phi from print_address::@9 to printf_uchar [phi:print_address::@9->printf_uchar]
    // [919] phi printf_uchar::format_zero_padding#11 = 0 [phi:print_address::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [919] phi printf_uchar::format_min_length#11 = 2 [phi:print_address::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [919] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:print_address::@9->printf_uchar#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [919] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#1 [phi:print_address::@9->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [1080] phi from print_address::@9 to print_address::@10 [phi:print_address::@9->print_address::@10]
    // print_address::@10
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1081] call printf_str
    // [720] phi from print_address::@10 to printf_str [phi:print_address::@10->printf_str]
    // [720] phi printf_str::putc#34 = &cputc [phi:print_address::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [720] phi printf_str::s#34 = print_address::s1 [phi:print_address::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@11
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1082] printf_uint::uvalue#1 = (unsigned int)(char *)print_address::brom_ptr#0 -- vwum1=vwuz2 
    lda.z brom_ptr
    sta printf_uint.uvalue
    lda.z brom_ptr+1
    sta printf_uint.uvalue+1
    // [1083] call printf_uint
    // [1004] phi from print_address::@11 to printf_uint [phi:print_address::@11->printf_uint]
    // [1004] phi printf_uint::format_min_length#3 = 4 [phi:print_address::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1004] phi printf_uint::format_radix#3 = HEXADECIMAL [phi:print_address::@11->printf_uint#1] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1004] phi printf_uint::uvalue#3 = printf_uint::uvalue#1 [phi:print_address::@11->printf_uint#2] -- register_copy 
    jsr printf_uint
    // print_address::@return
    // }
    // [1084] return 
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
    rom_bank1___0: .byte 0
    rom_bank1___1: .byte 0
    rom_bank1___2: .word 0
    .label rom_ptr1___0 = rom_ptr1___2
    rom_ptr1___2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1___2
    brom_bank: .byte 0
    .label bram_bank = printf_uchar.uvalue
    brom_address: .dword 0
}
.segment Code
  // flash_write
/* inline */
// unsigned long flash_write(__mem() char flash_ram_bank, __zp($26) char *flash_ram_address, __mem() unsigned long flash_rom_address)
flash_write: {
    .label flash_ram_address = $26
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [1085] flash_write::rom_chip_address#0 = flash_write::flash_rom_address#1 & $380000 -- vdum1=vdum2_band_vduc1 
    /// Holds the amount of bytes actually flashed in the ROM.
    lda flash_rom_address
    and #<$380000
    sta rom_chip_address
    lda flash_rom_address+1
    and #>$380000
    sta rom_chip_address+1
    lda flash_rom_address+2
    and #<$380000>>$10
    sta rom_chip_address+2
    lda flash_rom_address+3
    and #>$380000>>$10
    sta rom_chip_address+3
    // flash_write::bank_set_bram1
    // BRAM = bank
    // [1086] BRAM = flash_write::flash_ram_bank#0 -- vbuz1=vbum2 
    lda flash_ram_bank
    sta.z BRAM
    // [1087] phi from flash_write::bank_set_bram1 to flash_write::@1 [phi:flash_write::bank_set_bram1->flash_write::@1]
    // [1087] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#0] -- register_copy 
    // [1087] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#1] -- register_copy 
    // [1087] phi flash_write::flashed_bytes#2 = 0 [phi:flash_write::bank_set_bram1->flash_write::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flashed_bytes
    sta flashed_bytes+1
    lda #<0>>$10
    sta flashed_bytes+2
    lda #>0>>$10
    sta flashed_bytes+3
    // flash_write::@1
  __b1:
    // while (flashed_bytes < 0x0100)
    // [1088] if(flash_write::flashed_bytes#2<$100) goto flash_write::@2 -- vdum1_lt_vduc1_then_la1 
    lda flashed_bytes+3
    cmp #>$100>>$10
    bcc __b2
    bne !+
    lda flashed_bytes+2
    cmp #<$100>>$10
    bcc __b2
    bne !+
    lda flashed_bytes+1
    cmp #>$100
    bcc __b2
    bne !+
    lda flashed_bytes
    cmp #<$100
    bcc __b2
  !:
    // flash_write::@return
    // }
    // [1089] return 
    rts
    // flash_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [1090] rom_unlock::address#2 = flash_write::rom_chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda rom_chip_address
    adc #<$5555
    sta rom_unlock.address
    lda rom_chip_address+1
    adc #>$5555
    sta rom_unlock.address+1
    lda rom_chip_address+2
    adc #0
    sta rom_unlock.address+2
    lda rom_chip_address+3
    adc #0
    sta rom_unlock.address+3
    // [1091] call rom_unlock
    // [1098] phi from flash_write::@2 to rom_unlock [phi:flash_write::@2->rom_unlock]
    // [1098] phi rom_unlock::unlock_code#5 = $a0 [phi:flash_write::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$a0
    sta rom_unlock.unlock_code
    // [1098] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:flash_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // flash_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [1092] rom_byte_program::address#0 = flash_write::flash_rom_address#3 -- vdum1=vdum2 
    lda flash_rom_address
    sta rom_byte_program.address
    lda flash_rom_address+1
    sta rom_byte_program.address+1
    lda flash_rom_address+2
    sta rom_byte_program.address+2
    lda flash_rom_address+3
    sta rom_byte_program.address+3
    // [1093] rom_byte_program::value#0 = *flash_write::flash_ram_address#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta rom_byte_program.value
    // [1094] call rom_byte_program
    // [1512] phi from flash_write::@3 to rom_byte_program [phi:flash_write::@3->rom_byte_program]
    jsr rom_byte_program
    // flash_write::@4
    // flash_rom_address++;
    // [1095] flash_write::flash_rom_address#0 = ++ flash_write::flash_rom_address#3 -- vdum1=_inc_vdum1 
    inc flash_rom_address
    bne !+
    inc flash_rom_address+1
    bne !+
    inc flash_rom_address+2
    bne !+
    inc flash_rom_address+3
  !:
    // flash_ram_address++;
    // [1096] flash_write::flash_ram_address#0 = ++ flash_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [1097] flash_write::flashed_bytes#1 = ++ flash_write::flashed_bytes#2 -- vdum1=_inc_vdum1 
    inc flashed_bytes
    bne !+
    inc flashed_bytes+1
    bne !+
    inc flashed_bytes+2
    bne !+
    inc flashed_bytes+3
  !:
    // [1087] phi from flash_write::@4 to flash_write::@1 [phi:flash_write::@4->flash_write::@1]
    // [1087] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#0 [phi:flash_write::@4->flash_write::@1#0] -- register_copy 
    // [1087] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#0 [phi:flash_write::@4->flash_write::@1#1] -- register_copy 
    // [1087] phi flash_write::flashed_bytes#2 = flash_write::flashed_bytes#1 [phi:flash_write::@4->flash_write::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip_address: .dword 0
    flash_rom_address: .dword 0
    flashed_bytes: .dword 0
    flash_ram_bank: .byte 0
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
/* inline */
// void rom_unlock(__mem() unsigned long address, __mem() char unlock_code)
rom_unlock: {
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1099] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vdum1=vdum2_band_vduc1 
    lda address
    and #<$380000
    sta chip_address
    lda address+1
    and #>$380000
    sta chip_address+1
    lda address+2
    and #<$380000>>$10
    sta chip_address+2
    lda address+3
    and #>$380000>>$10
    sta chip_address+3
    // rom_write_byte(chip_address + 0x05555, 0xAA)
    // [1100] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda chip_address
    adc #<$5555
    sta rom_write_byte.address
    lda chip_address+1
    adc #>$5555
    sta rom_write_byte.address+1
    lda chip_address+2
    adc #0
    sta rom_write_byte.address+2
    lda chip_address+3
    adc #0
    sta rom_write_byte.address+3
    // [1101] call rom_write_byte
    // [1522] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1522] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbum1=vbuc1 
    lda #$aa
    sta rom_write_byte.value
    // [1522] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1102] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vdum1=vdum2_plus_vwuc1 
    clc
    lda chip_address
    adc #<$2aaa
    sta rom_write_byte.address
    lda chip_address+1
    adc #>$2aaa
    sta rom_write_byte.address+1
    lda chip_address+2
    adc #0
    sta rom_write_byte.address+2
    lda chip_address+3
    adc #0
    sta rom_write_byte.address+3
    // [1103] call rom_write_byte
    // [1522] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1522] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbum1=vbuc1 
    lda #$55
    sta rom_write_byte.value
    // [1522] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1104] rom_write_byte::address#2 = rom_unlock::address#5 -- vdum1=vdum2 
    lda address
    sta rom_write_byte.address
    lda address+1
    sta rom_write_byte.address+1
    lda address+2
    sta rom_write_byte.address+2
    lda address+3
    sta rom_write_byte.address+3
    // [1105] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbum1=vbum2 
    lda unlock_code
    sta rom_write_byte.value
    // [1106] call rom_write_byte
    // [1522] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1522] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1522] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1107] return 
    rts
  .segment Data
    chip_address: .dword 0
    address: .dword 0
    unlock_code: .byte 0
}
.segment Code
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
// __mem() char rom_read_byte(__mem() unsigned long address)
rom_read_byte: {
    .label rom_ptr1_return = $4a
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1109] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbum1=_byte2_vdum2 
    lda address+2
    sta rom_bank1___0
    // BYTE1(address)
    // [1110] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbum1=_byte1_vdum2 
    lda address+1
    sta rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1111] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbum2_word_vbum3 
    lda rom_bank1___0
    sta rom_bank1___2+1
    lda rom_bank1___1
    sta rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1112] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1113] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1114] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1___2
    lda address+1
    sta rom_ptr1___2+1
    // [1115] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1116] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::@1
    // bank_set_brom(bank_rom)
    // [1117] bank_set_brom::bank#2 = rom_read_byte::rom_bank1_return#0
    // [1118] call bank_set_brom
    // [796] phi from rom_read_byte::@1 to bank_set_brom [phi:rom_read_byte::@1->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = bank_set_brom::bank#2 [phi:rom_read_byte::@1->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_read_byte::@2
    // return *ptr_rom;
    // [1119] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbum1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta return
    // rom_read_byte::@return
    // }
    // [1120] return 
    rts
  .segment Data
    rom_bank1___0: .byte 0
    rom_bank1___1: .byte 0
    rom_bank1___2: .word 0
    .label rom_ptr1___0 = rom_ptr1___2
    rom_ptr1___2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1___2
    .label rom_bank1_return = bank_set_brom.bank
    return: .byte 0
    address: .dword 0
}
.segment Code
  // print_chip_KB
// void print_chip_KB(__mem() char rom_chip, __zp($26) char *kb)
print_chip_KB: {
    .label kb = $26
    // rom_chip * 10
    // [1122] print_chip_KB::$9 = print_chip_KB::rom_chip#3 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __9
    // [1123] print_chip_KB::$10 = print_chip_KB::$9 + print_chip_KB::rom_chip#3 -- vbum1=vbum2_plus_vbum1 
    lda __10
    clc
    adc __9
    sta __10
    // [1124] print_chip_KB::$3 = print_chip_KB::$10 << 1 -- vbum1=vbum1_rol_1 
    asl __3
    // print_chip_line(3 + rom_chip * 10, 51, kb[0])
    // [1125] print_chip_line::x#9 = 3 + print_chip_KB::$3 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __3
    sta print_chip_line.x
    // [1126] print_chip_line::c#9 = *print_chip_KB::kb#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (kb),y
    sta print_chip_line.c
    // [1127] call print_chip_line
    // [1189] phi from print_chip_KB to print_chip_line [phi:print_chip_KB->print_chip_line]
    // [1189] phi print_chip_line::c#12 = print_chip_line::c#9 [phi:print_chip_KB->print_chip_line#0] -- register_copy 
    // [1189] phi print_chip_line::y#12 = $33 [phi:print_chip_KB->print_chip_line#1] -- vbum1=vbuc1 
    lda #$33
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#9 [phi:print_chip_KB->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@1
    // print_chip_line(3 + rom_chip * 10, 52, kb[1])
    // [1128] print_chip_line::x#10 = 3 + print_chip_KB::$3 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __3
    sta print_chip_line.x
    // [1129] print_chip_line::c#10 = print_chip_KB::kb#3[1] -- vbum1=pbuz2_derefidx_vbuc1 
    ldy #1
    lda (kb),y
    sta print_chip_line.c
    // [1130] call print_chip_line
    // [1189] phi from print_chip_KB::@1 to print_chip_line [phi:print_chip_KB::@1->print_chip_line]
    // [1189] phi print_chip_line::c#12 = print_chip_line::c#10 [phi:print_chip_KB::@1->print_chip_line#0] -- register_copy 
    // [1189] phi print_chip_line::y#12 = $34 [phi:print_chip_KB::@1->print_chip_line#1] -- vbum1=vbuc1 
    lda #$34
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#10 [phi:print_chip_KB::@1->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@2
    // print_chip_line(3 + rom_chip * 10, 53, kb[2])
    // [1131] print_chip_line::x#11 = 3 + print_chip_KB::$3 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __3
    sta print_chip_line.x
    // [1132] print_chip_line::c#11 = print_chip_KB::kb#3[2] -- vbum1=pbuz2_derefidx_vbuc1 
    ldy #2
    lda (kb),y
    sta print_chip_line.c
    // [1133] call print_chip_line
    // [1189] phi from print_chip_KB::@2 to print_chip_line [phi:print_chip_KB::@2->print_chip_line]
    // [1189] phi print_chip_line::c#12 = print_chip_line::c#11 [phi:print_chip_KB::@2->print_chip_line#0] -- register_copy 
    // [1189] phi print_chip_line::y#12 = $35 [phi:print_chip_KB::@2->print_chip_line#1] -- vbum1=vbuc1 
    lda #$35
    sta print_chip_line.y
    // [1189] phi print_chip_line::x#12 = print_chip_line::x#11 [phi:print_chip_KB::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@return
    // }
    // [1134] return 
    rts
  .segment Data
    .label __3 = rom_chip
    rom_chip: .byte 0
    __9: .byte 0
    .label __10 = rom_chip
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label y = $45
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1135] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1136] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1137] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1138] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta __0
    // __conio.mapbase_bank = mapbase >> 7
    // [1139] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1140] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbum1=vbum1_rol_1 
    asl __1
    // MAKEWORD((mapbase)<<1,0)
    // [1141] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbum2_word_vbuc1 
    lda #0
    ldy __1
    sty __2+1
    sta __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1142] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1143] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta __7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1144] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda __8
    lsr
    lsr
    lsr
    lsr
    sta __8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1145] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1146] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbum1=vbum1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and __5
    sta __5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1147] screenlayer::$6 = screenlayer::$5 >> 6 -- vbum1=vbum1_ror_6 
    lda __6
    rol
    rol
    rol
    and #3
    sta __6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1148] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1149] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl __16
    // [1150] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy __16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1151] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum1_eq_vbuc1 
    lda __9
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta __9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1152] screenlayer::$18 = (char)screenlayer::$9
    // [1153] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
    lda #$28
    ldy __10
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta __10
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1154] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec __11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1155] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda __11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1156] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum1_eq_vbuc1 
    lda __12
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta __12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1157] screenlayer::$19 = (char)screenlayer::$12
    // [1158] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
    lda #$1e
    ldy __13
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta __13
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1159] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec __14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1160] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda __14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1161] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1162] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1162] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1162] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1163] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1164] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1165] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta __17
    // [1166] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1167] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1168] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1162] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1162] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1162] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    __0: .byte 0
    .label __1 = mapbase
    __2: .word 0
    .label __5 = config
    .label __6 = config
    __7: .byte 0
    .label __8 = __7
    .label __9 = vera_dc_hscale_temp
    .label __10 = vera_dc_hscale_temp
    .label __11 = vera_dc_hscale_temp
    .label __12 = vera_dc_vscale_temp
    .label __13 = vera_dc_vscale_temp
    .label __14 = vera_dc_vscale_temp
    .label __16 = __7
    __17: .byte 0
    .label __18 = vera_dc_hscale_temp
    .label __19 = vera_dc_vscale_temp
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
    mapbase_offset: .word 0
    mapbase: .byte 0
    config: .byte 0
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [1169] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1170] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1171] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1172] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1173] call gotoxy
    // [490] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [490] phi gotoxy::y#25 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1174] return 
    rts
    // [1175] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1176] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1177] gotoxy::y#2 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1178] call gotoxy
    // [490] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1179] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1180] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__mem() char x, __mem() char y, __mem() char c)
cputcxy: {
    // gotoxy(x, y)
    // [1182] gotoxy::x#0 = cputcxy::x#68 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1183] gotoxy::y#0 = cputcxy::y#68 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1184] call gotoxy
    // [490] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1185] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1186] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1188] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    c: .byte 0
}
.segment Code
  // print_chip_line
// void print_chip_line(__mem() char x, __mem() char y, __mem() char c)
print_chip_line: {
    // gotoxy(x, y)
    // [1190] gotoxy::x#4 = print_chip_line::x#12 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1191] gotoxy::y#4 = print_chip_line::y#12 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1192] call gotoxy
    // [490] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [490] phi gotoxy::y#25 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [490] phi gotoxy::x#25 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1193] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [1194] call textcolor
    // [472] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [472] phi textcolor::color#23 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1195] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [1196] call bgcolor
    // [477] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [1197] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1198] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1200] call textcolor
    // [472] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [472] phi textcolor::color#23 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1201] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [1202] call bgcolor
    // [477] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [477] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [1203] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1204] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [1206] stackpush(char) = print_chip_line::c#12 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1207] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [1209] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1210] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1212] call textcolor
    // [472] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [472] phi textcolor::color#23 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1213] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [1214] call bgcolor
    // [477] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [1215] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1216] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [1218] return 
    rts
  .segment Data
    x: .byte 0
    c: .byte 0
    y: .byte 0
}
.segment Code
  // print_chip_end
// void print_chip_end(__mem() char x, char y)
print_chip_end: {
    .const y = $36
    // gotoxy(x, y)
    // [1219] gotoxy::x#5 = print_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1220] call gotoxy
    // [490] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [490] phi gotoxy::y#25 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #y
    sta gotoxy.y
    // [490] phi gotoxy::x#25 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1221] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [1222] call textcolor
    // [472] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [472] phi textcolor::color#23 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1223] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [1224] call bgcolor
    // [477] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [1225] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1226] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1228] call textcolor
    // [472] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [472] phi textcolor::color#23 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [1229] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [1230] call bgcolor
    // [477] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [477] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [1231] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1232] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1234] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1235] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1237] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1238] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1240] call textcolor
    // [472] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [472] phi textcolor::color#23 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1241] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [1242] call bgcolor
    // [477] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [477] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [1243] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1244] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1246] return 
    rts
  .segment Data
    .label x = print_chips.__33
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($2f) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $2f
    // [1248] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1248] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1249] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [1250] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1251] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [1252] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall17
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1254] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1248] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1248] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall17:
    jmp (putc)
  .segment Data
    i: .byte 0
    .label length = printf_string.format_min_length
    pad: .byte 0
}
.segment Code
  // getin
/**
 * @brief Get a character from keyboard.
 * 
 * @return char The character read.
 */
getin: {
    // __mem unsigned char ch
    // [1255] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // cbm_k_clrchn()
    // [1256] call cbm_k_clrchn
    jsr cbm_k_clrchn
    // getin::@1
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [1258] getin::return#0 = getin::ch -- vbum1=vbum2 
    sta return
    // getin::@return
    // }
    // [1259] getin::return#1 = getin::return#0
    // [1260] return 
    rts
  .segment Data
    ch: .byte 0
    return: .byte 0
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($26) char *buffer, __mem() char radix)
utoa: {
    .label buffer = $26
    .label digit_values = $2f
    // if(radix==DECIMAL)
    // [1262] if(utoa::radix#2==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1263] if(utoa::radix#2==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1264] if(utoa::radix#2==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1265] if(utoa::radix#2==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1266] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1267] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1268] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1269] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1270] return 
    rts
    // [1271] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1271] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1271] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [1271] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1271] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1271] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [1271] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1271] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1271] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [1271] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1271] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1271] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [1272] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1272] phi utoa::buffer#10 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1272] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1272] phi utoa::value#3 = utoa::value#10 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1272] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1273] utoa::$4 = utoa::max_digits#7 - 1 -- vbum1=vbum2_minus_1 
    ldx max_digits
    dex
    stx __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1274] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbum2_then_la1 
    lda digit
    cmp __4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1275] utoa::$11 = (char)utoa::value#3 -- vbum1=_byte_vwum2 
    lda value
    sta __11
    // [1276] *utoa::buffer#10 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1277] utoa::buffer#3 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1278] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1279] utoa::$10 = utoa::digit#2 << 1 -- vbum1=vbum2_rol_1 
    lda digit
    asl
    sta __10
    // [1280] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbum3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1281] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [1282] if(utoa::value#3>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [1283] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1283] phi utoa::buffer#15 = utoa::buffer#10 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1283] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1283] phi utoa::value#7 = utoa::value#3 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1284] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1272] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1272] phi utoa::buffer#10 = utoa::buffer#15 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1272] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1272] phi utoa::value#3 = utoa::value#7 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1272] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1285] utoa_append::buffer#0 = utoa::buffer#10 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1286] utoa_append::value#0 = utoa::value#3
    // [1287] utoa_append::sub#0 = utoa::digit_value#0
    // [1288] call utoa_append
    // [1570] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1289] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1290] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1291] utoa::buffer#4 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1283] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1283] phi utoa::buffer#15 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1283] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1283] phi utoa::value#7 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    __4: .byte 0
    __10: .byte 0
    __11: .byte 0
    digit_value: .word 0
    digit: .byte 0
    .label value = printf_sint.value
    .label radix = printf_uint.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($26) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, __mem() char format_justify_left, char format_sign_always, __mem() char format_zero_padding, __mem() char format_upper_case, char format_radix)
printf_number_buffer: {
    .label putc = $26
    // if(format.min_length)
    // [1293] if(0==printf_number_buffer::format_min_length#4) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b6
    // [1294] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [1295] call strlen
    // [823] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [823] phi strlen::str#9 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1296] strlen::return#11 = strlen::len#2
    // printf_number_buffer::@14
    // [1297] printf_number_buffer::$19 = strlen::return#11
    // signed char len = (signed char)strlen(buffer.digits)
    // [1298] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwum2 
    // There is a minimum length - work out the padding
    lda __19
    sta len
    // if(buffer.sign)
    // [1299] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [1300] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1301] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [1301] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [1302] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#4 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1303] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1305] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [1305] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1304] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [1305] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [1305] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1306] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [1307] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [1308] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [1309] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1310] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1311] call printf_padding
    // [1247] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1247] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1247] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@8->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1247] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1312] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [1313] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1314] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall18
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1316] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [1317] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1318] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1319] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1320] call printf_padding
    // [1247] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1247] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1247] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@10->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [1247] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1321] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbum1_then_la1 
    lda format_upper_case
    beq __b5
    // [1322] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1323] call strupr
    // [1577] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1324] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1325] call printf_str
    // [720] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [720] phi printf_str::putc#34 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [720] phi printf_str::s#34 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1326] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1327] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1328] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1329] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1330] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1331] call printf_padding
    // [1247] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1247] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1247] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@12->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1247] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1332] return 
    rts
    // Outside Flow
  icall18:
    jmp (putc)
  .segment Data
    .label __19 = strlen.len
    buffer_sign: .byte 0
    .label format_zero_padding = printf_uchar.format_zero_padding
    .label format_min_length = printf_uchar.format_min_length
    len: .byte 0
    .label padding = len
    format_justify_left: .byte 0
    format_upper_case: .byte 0
}
.segment Code
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($22) char *dst, __zp($33) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label dst = $22
    .label src = $33
    // [1334] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1334] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1334] phi strncpy::src#2 = file [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z src
    lda #>file
    sta.z src+1
    // [1334] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1335] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwum1_lt_vwuc1_then_la1 
    lda i+1
    cmp #>n
    bcc __b2
    bne !+
    lda i
    cmp #<n
    bcc __b2
  !:
    // strncpy::@return
    // }
    // [1336] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1337] strncpy::c#0 = *strncpy::src#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [1338] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1339] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1340] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1340] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1341] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1342] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1343] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [1334] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1334] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1334] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1334] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
    i: .word 0
}
.segment Code
  // cbm_k_setnam
/**
 * @brief Sets the name of the file before opening.
 * 
 * @param filename The name of the file.
 */
// void cbm_k_setnam(__zp($48) char * volatile filename)
cbm_k_setnam: {
    .label filename = $48
    // strlen(filename)
    // [1344] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbuz2 
    lda.z filename
    sta.z strlen.str
    lda.z filename+1
    sta.z strlen.str+1
    // [1345] call strlen
    // [823] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [823] phi strlen::str#9 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1346] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [1347] cbm_k_setnam::$0 = strlen::return#0
    // __mem char filename_len = (char)strlen(filename)
    // [1348] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwum2 
    lda __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [1350] return 
    rts
  .segment Data
    filename_len: .byte 0
    .label __0 = strlen.len
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
    // [1352] return 
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
    // [1353] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [1355] cbm_k_open::return#0 = cbm_k_open::status -- vbum1=vbum2 
    sta return
    // cbm_k_open::@return
    // }
    // [1356] cbm_k_open::return#1 = cbm_k_open::return#0
    // [1357] return 
    rts
  .segment Data
    status: .byte 0
    return: .byte 0
}
.segment Code
  // ferror
/**
 * @brief POSIX equivalent of ferror for the CBM C language.
 * This routine reads from secondary 15 the error message from the device!
 * The result is an error string, including the error code, message, track, sector.
 * The error string can be a maximum of 32 characters.
 * 
 * @param stream FILE* stream.
 * @return int Contains a non-zero value if there is an error.
 */
// int ferror(__zp($3b) struct $1 *stream)
ferror: {
    .label stream = $3b
    .label msg = $33
    .label __22 = $29
    .label __23 = $3d
    .label __24 = $35
    .label __25 = $37
    // unsigned int sp = (unsigned int)stream & ~0x8000
    // [1359] ferror::sp#0 = (unsigned int)ferror::stream#2 & ~$8000 -- vwum1=vwuz2_band_vwuc1 
    lda.z stream
    and #<$8000^$ffff
    sta sp
    lda.z stream+1
    and #>$8000^$ffff
    sta sp+1
    // cbm_k_readst()
    // [1360] call cbm_k_readst
    jsr cbm_k_readst
    // [1361] cbm_k_readst::return#12 = cbm_k_readst::return#1
    // ferror::@4
    // [1362] ferror::$1 = cbm_k_readst::return#12
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1363] ferror::$22 = (char *)&__stdio_file+$46 + ferror::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __22
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __22+1
    // [1364] *ferror::$22 = ferror::$1 -- _deref_pbuz1=vbum2 
    lda __1
    ldy #0
    sta (__22),y
    // cbm_k_setlfs(15, 8, 15)
    // [1365] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [1366] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [1367] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [1368] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@5
    // cbm_k_setnam("")
    // [1369] cbm_k_setnam::filename = ferror::filename -- pbuz1=pbuc1 
    lda #<filename
    sta.z cbm_k_setnam.filename
    lda #>filename
    sta.z cbm_k_setnam.filename+1
    // [1370] call cbm_k_setnam
    jsr cbm_k_setnam
    // [1371] phi from ferror::@5 to ferror::@6 [phi:ferror::@5->ferror::@6]
    // ferror::@6
    // cbm_k_open()
    // [1372] call cbm_k_open
    jsr cbm_k_open
    // ferror::@7
    // cbm_k_chkin(15)
    // [1373] cbm_k_chkin::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin.channel
    // [1374] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1375] phi from ferror::@7 to ferror::@8 [phi:ferror::@7->ferror::@8]
    // ferror::@8
    // char ch = cbm_k_chrin()
    // [1376] call cbm_k_chrin
    jsr cbm_k_chrin
    // [1377] cbm_k_chrin::return#2 = cbm_k_chrin::return#1
    // ferror::@9
    // [1378] ferror::ch#0 = cbm_k_chrin::return#2
    // sp * __STDIO_FILECOUNT
    // [1379] ferror::$14 = ferror::sp#0 << 1 -- vwum1=vwum2_rol_1 
    lda sp
    asl
    sta __14
    lda sp+1
    rol
    sta __14+1
    // char *msg = __stdio_file.error + sp * __STDIO_FILECOUNT
    // [1380] ferror::msg#0 = (char *)&__stdio_file+$48 + ferror::$14 -- pbuz1=pbuc1_plus_vwum2 
    lda __14
    clc
    adc #<__stdio_file+$48
    sta.z msg
    lda __14+1
    adc #>__stdio_file+$48
    sta.z msg+1
    // cbm_k_readst()
    // [1381] call cbm_k_readst
    jsr cbm_k_readst
    // [1382] cbm_k_readst::return#13 = cbm_k_readst::return#1
    // ferror::@10
    // [1383] ferror::$12 = cbm_k_readst::return#13
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1384] ferror::$23 = (char *)&__stdio_file+$46 + ferror::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __23
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __23+1
    // [1385] *ferror::$23 = ferror::$12 -- _deref_pbuz1=vbum2 
    lda __12
    ldy #0
    sta (__23),y
    // [1386] phi from ferror::@10 ferror::@12 to ferror::@1 [phi:ferror::@10/ferror::@12->ferror::@1]
    // [1386] phi ferror::msg#2 = ferror::msg#0 [phi:ferror::@10/ferror::@12->ferror::@1#0] -- register_copy 
    // [1386] phi ferror::ch#2 = ferror::ch#0 [phi:ferror::@10/ferror::@12->ferror::@1#1] -- register_copy 
    // ferror::@1
  __b1:
    // while(!__stdio_file.status[sp])
    // [1387] ferror::$24 = (char *)&__stdio_file+$46 + ferror::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __24
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __24+1
    // [1388] if(0==*ferror::$24) goto ferror::@2 -- 0_eq__deref_pbuz1_then_la1 
    ldy #0
    lda (__24),y
    cmp #0
    beq __b2
    // ferror::@3
    // cbm_k_close(15)
    // [1389] cbm_k_close::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close.channel
    // [1390] call cbm_k_close
    jsr cbm_k_close
    // ferror::@13
    // strlen(__stdio_file.error + sp * __STDIO_FILECOUNT)
    // [1391] strlen::str#5 = (char *)&__stdio_file+$48 + ferror::$14 -- pbuz1=pbuc1_plus_vwum2 
    lda __14
    clc
    adc #<__stdio_file+$48
    sta.z strlen.str
    lda __14+1
    adc #>__stdio_file+$48
    sta.z strlen.str+1
    // [1392] call strlen
    // [823] phi from ferror::@13 to strlen [phi:ferror::@13->strlen]
    // [823] phi strlen::str#9 = strlen::str#5 [phi:ferror::@13->strlen#0] -- register_copy 
    jsr strlen
    // ferror::@return
    // }
    // [1393] return 
    rts
    // ferror::@2
  __b2:
    // *msg = ch
    // [1394] *ferror::msg#2 = ferror::ch#2 -- _deref_pbuz1=vbum2 
    lda ch
    ldy #0
    sta (msg),y
    // msg++;
    // [1395] ferror::msg#1 = ++ ferror::msg#2 -- pbuz1=_inc_pbuz1 
    inc.z msg
    bne !+
    inc.z msg+1
  !:
    // cbm_k_chrin()
    // [1396] call cbm_k_chrin
    jsr cbm_k_chrin
    // [1397] cbm_k_chrin::return#3 = cbm_k_chrin::return#1
    // ferror::@11
    // ch = cbm_k_chrin()
    // [1398] ferror::ch#1 = cbm_k_chrin::return#3
    // cbm_k_readst()
    // [1399] call cbm_k_readst
    jsr cbm_k_readst
    // [1400] cbm_k_readst::return#14 = cbm_k_readst::return#1
    // ferror::@12
    // [1401] ferror::$19 = cbm_k_readst::return#14
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1402] ferror::$25 = (char *)&__stdio_file+$46 + ferror::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __25
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __25+1
    // [1403] *ferror::$25 = ferror::$19 -- _deref_pbuz1=vbum2 
    lda __19
    ldy #0
    sta (__25),y
    jmp __b1
  .segment Data
    filename: .text ""
    .byte 0
    .label __1 = cbm_k_readst.return
    .label __12 = cbm_k_readst.return
    __14: .word 0
    .label __19 = cbm_k_readst.return
    sp: .word 0
    ch: .byte 0
}
.segment Code
  // cbm_k_close
/**
 * @brief Close a logical file.
 * 
 * @param channel The channel to close.
 * @return char Status.
 */
// __mem() char cbm_k_close(__mem() volatile char channel)
cbm_k_close: {
    // __mem unsigned char status
    // [1404] cbm_k_close::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldachannel jsrCBM_CLOSE stastatus  }
    lda channel
    jsr CBM_CLOSE
    sta status
    // return status;
    // [1406] cbm_k_close::return#0 = cbm_k_close::status -- vbum1=vbum2 
    sta return
    // cbm_k_close::@return
    // }
    // [1407] cbm_k_close::return#1 = cbm_k_close::return#0
    // [1408] return 
    rts
  .segment Data
    channel: .byte 0
    status: .byte 0
    return: .byte 0
}
.segment Code
  // cbm_k_chkin
/**
 * @brief Open a channel for input.
 * 
 * @param channel 
 * @return char 
 */
// char cbm_k_chkin(__mem() volatile char channel)
cbm_k_chkin: {
    // __mem unsigned char status
    // [1409] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [1411] return 
    rts
  .segment Data
    channel: .byte 0
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
    // [1412] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [1414] cbm_k_readst::return#0 = cbm_k_readst::status -- vbum1=vbum2 
    sta return
    // cbm_k_readst::@return
    // }
    // [1415] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [1416] return 
    rts
  .segment Data
    status: .byte 0
    return: .byte 0
}
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__mem() char value, __zp($26) char *buffer, __mem() char radix)
uctoa: {
    .label buffer = $26
    .label digit_values = $22
    // if(radix==DECIMAL)
    // [1417] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1418] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1419] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1420] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1421] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1422] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1423] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1424] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1425] return 
    rts
    // [1426] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1426] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1426] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1426] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1426] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1426] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [1426] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1426] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1426] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1426] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1426] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1426] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [1427] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1427] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1427] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1427] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1427] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1428] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbum1=vbum2_minus_1 
    ldx max_digits
    dex
    stx __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1429] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbum2_then_la1 
    lda digit
    cmp __4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1430] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1431] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1432] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1433] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [1434] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [1435] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [1436] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1436] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1436] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1436] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1437] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1427] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1427] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1427] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1427] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1427] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1438] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1439] uctoa_append::value#0 = uctoa::value#2
    // [1440] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1441] call uctoa_append
    // [1592] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1442] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1443] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1444] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1436] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1436] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1436] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1436] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    __4: .byte 0
    digit_value: .byte 0
    digit: .byte 0
    .label value = printf_uchar.uvalue
    .label radix = printf_uchar.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __mem() unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1446] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1447] ultoa::value#1 = printf_ulong::uvalue#2
    // [1448] call ultoa
  // Format number into buffer
    // [1599] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1449] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1450] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#2
    // [1451] call printf_number_buffer
  // Print using format
    // [1292] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1292] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_upper_case
    // [1292] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1292] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1292] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    // [1292] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_justify_left
    // [1292] phi printf_number_buffer::format_min_length#4 = 6 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbum1=vbuc1 
    lda #6
    sta printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1452] return 
    rts
  .segment Data
    .label uvalue = print_address.brom_address
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
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
// __mem() unsigned int fgets(__zp($26) char *ptr, unsigned int size, __zp($22) struct $1 *stream)
fgets: {
    .const size = $80
    .label ptr = $26
    .label stream = $22
    .label __30 = $33
    .label __31 = $29
    .label __32 = $3d
    .label __33 = $35
    .label __34 = $37
    .label __35 = $31
    // unsigned int sp = (unsigned int)stream & ~0x8000
    // [1453] fgets::sp#0 = (unsigned int)fgets::stream#0 & ~$8000 -- vwum1=vwuz2_band_vwuc1 
    lda.z stream
    and #<$8000^$ffff
    sta sp
    lda.z stream+1
    and #>$8000^$ffff
    sta sp+1
    // cbm_k_chkin(__stdio_file.channel[sp])
    // [1454] fgets::$30 = (char *)&__stdio_file+$40 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$40
    sta.z __30
    lda sp+1
    adc #>__stdio_file+$40
    sta.z __30+1
    // [1455] cbm_k_chkin::channel = *fgets::$30 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (__30),y
    sta cbm_k_chkin.channel
    // [1456] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1457] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [1458] call cbm_k_readst
    jsr cbm_k_readst
    // [1459] cbm_k_readst::return#10 = cbm_k_readst::return#1
    // fgets::@12
    // [1460] fgets::$2 = cbm_k_readst::return#10
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1461] fgets::$31 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __31
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __31+1
    // [1462] *fgets::$31 = fgets::$2 -- _deref_pbuz1=vbum2 
    lda __2
    ldy #0
    sta (__31),y
    // if(__stdio_file.status[sp])
    // [1463] fgets::$32 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __32
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __32+1
    // [1464] if(0==*fgets::$32) goto fgets::@1 -- 0_eq__deref_pbuz1_then_la1 
    lda (__32),y
    cmp #0
    beq __b8
    // [1465] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [1465] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [1466] return 
    rts
    // [1467] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [1467] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [1467] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@12->fgets::@1#1] -- vwum1=vwuc1 
    lda #<size
    sta remaining
    lda #>size
    sta remaining+1
    // [1467] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [1467] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [1467] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [1467] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [1467] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [1468] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwum1_ge_vbuc1_then_la1 
    lda remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    lda remaining
    cmp #$80
    bcc !__b2+
    jmp __b2
  !__b2:
  !:
    // fgets::@8
    // cbm_k_macptr(remaining, ptr)
    // [1469] cbm_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cbm_k_macptr.bytes
    // [1470] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1471] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1472] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [1473] fgets::bytes#3 = cbm_k_macptr::return#4
    // [1474] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [1474] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [1475] call cbm_k_readst
    jsr cbm_k_readst
    // [1476] cbm_k_readst::return#11 = cbm_k_readst::return#1
    // fgets::@15
    // [1477] fgets::$10 = cbm_k_readst::return#11
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1478] fgets::$33 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __33
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __33+1
    // [1479] *fgets::$33 = fgets::$10 -- _deref_pbuz1=vbum2 
    lda __10
    ldy #0
    sta (__33),y
    // __stdio_file.status[sp] & 0xBF
    // [1480] fgets::$34 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __34
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __34+1
    // [1481] fgets::$11 = *fgets::$34 & $bf -- vbum1=_deref_pbuz2_band_vbuc1 
    lda #$bf
    and (__34),y
    sta __11
    // if(__stdio_file.status[sp] & 0xBF)
    // [1482] if(0==fgets::$11) goto fgets::@4 -- 0_eq_vbum1_then_la1 
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [1483] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwum1_neq_vwuc1_then_la1 
    lda bytes+1
    cmp #>$ffff
    bne __b5
    lda bytes
    cmp #<$ffff
    bne __b5
    jmp __b1
    // fgets::@5
  __b5:
    // read += bytes
    // [1484] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [1485] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1486] fgets::$15 = byte1  fgets::ptr#0 -- vbum1=_byte1_pbuz2 
    sta __15
    // if(BYTE1(ptr) == 0xC0)
    // [1487] if(fgets::$15!=$c0) goto fgets::@6 -- vbum1_neq_vbuc1_then_la1 
    lda #$c0
    cmp __15
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [1488] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1489] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [1489] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [1490] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // __stdio_file.status[sp] == 0
    // [1491] fgets::$35 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __35
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __35+1
    // while ((__stdio_file.status[sp] == 0) && ((size && remaining) || !size))
    // [1492] if(*fgets::$35==0) goto fgets::@16 -- _deref_pbuz1_eq_0_then_la1 
    ldy #0
    lda (__35),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [1493] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [1494] cbm_k_chkin::channel = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin.channel
    // [1495] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1465] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [1465] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [1496] cbm_k_macptr::bytes = $80 -- vbum1=vbuc1 
    lda #$80
    sta cbm_k_macptr.bytes
    // [1497] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1498] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1499] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [1500] fgets::bytes#2 = cbm_k_macptr::return#3
    jmp __b3
  .segment Data
    .label __2 = cbm_k_readst.return
    .label __10 = cbm_k_readst.return
    __11: .byte 0
    __15: .byte 0
    sp: .word 0
    .label return = read
    bytes: .word 0
    read: .word 0
    remaining: .word 0
}
.segment Code
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
// __mem() char rom_byte_verify(__zp($2f) char *ptr_rom, __mem() char value)
rom_byte_verify: {
    .label ptr_rom = $2f
    // if (*ptr_rom != value)
    // [1501] if(*rom_byte_verify::ptr_rom#0==rom_byte_verify::value#0) goto rom_byte_verify::@1 -- _deref_pbuz1_eq_vbum2_then_la1 
    lda value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1502] phi from rom_byte_verify to rom_byte_verify::@2 [phi:rom_byte_verify->rom_byte_verify::@2]
    // rom_byte_verify::@2
    // [1503] phi from rom_byte_verify::@2 to rom_byte_verify::@1 [phi:rom_byte_verify::@2->rom_byte_verify::@1]
    // [1503] phi rom_byte_verify::return#0 = 0 [phi:rom_byte_verify::@2->rom_byte_verify::@1#0] -- vbum1=vbuc1 
    tya
    sta return
    rts
    // [1503] phi from rom_byte_verify to rom_byte_verify::@1 [phi:rom_byte_verify->rom_byte_verify::@1]
  __b2:
    // [1503] phi rom_byte_verify::return#0 = 1 [phi:rom_byte_verify->rom_byte_verify::@1#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // rom_byte_verify::@1
    // rom_byte_verify::@return
    // }
    // [1504] return 
    rts
  .segment Data
    return: .byte 0
    value: .byte 0
}
.segment Code
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
// void rom_wait(__zp($22) char *ptr_rom)
rom_wait: {
    .label ptr_rom = $22
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [1506] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [1507] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    lda (ptr_rom),y
    sta test2
    // test1 & 0x40
    // [1508] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbum1=vbum1_band_vbuc1 
    lda #$40
    and __0
    sta __0
    // test2 & 0x40
    // [1509] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbum1=vbum1_band_vbuc1 
    lda #$40
    and __1
    sta __1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [1510] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbum1_neq_vbum2_then_la1 
    lda __0
    cmp __1
    bne __b1
    // rom_wait::@return
    // }
    // [1511] return 
    rts
  .segment Data
    .label __0 = test1
    .label __1 = test2
    test1: .byte 0
    test2: .byte 0
}
.segment Code
  // rom_byte_program
/**
 * @brief Write a byte and wait until the byte has been successfully flashed into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
/* inline */
// void rom_byte_program(__mem() unsigned long address, __mem() char value)
rom_byte_program: {
    .label rom_ptr1_return = $31
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1513] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1___2
    lda address+1
    sta rom_ptr1___2+1
    // [1514] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1515] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [1516] rom_write_byte::address#3 = rom_byte_program::address#0
    // [1517] rom_write_byte::value#3 = rom_byte_program::value#0
    // [1518] call rom_write_byte
    // [1522] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [1522] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [1522] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [1519] rom_wait::ptr_rom#0 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [1520] call rom_wait
    // [1505] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [1505] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [1521] return 
    rts
  .segment Data
    .label rom_ptr1___0 = rom_ptr1___2
    rom_ptr1___2: .word 0
    .label address = rom_write_byte.address
    .label value = rom_write_byte.value
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
// void rom_write_byte(__mem() unsigned long address, __mem() char value)
rom_write_byte: {
    .label rom_ptr1_return = $29
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [1523] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbum1=_byte2_vdum2 
    lda address+2
    sta rom_bank1___0
    // BYTE1(address)
    // [1524] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbum1=_byte1_vdum2 
    lda address+1
    sta rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1525] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwum1=vbum2_word_vbum3 
    lda rom_bank1___0
    sta rom_bank1___2+1
    lda rom_bank1___1
    sta rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1526] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1527] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1528] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1___2
    lda address+1
    sta rom_ptr1___2+1
    // [1529] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1530] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::@1
    // bank_set_brom(bank_rom)
    // [1531] bank_set_brom::bank#3 = rom_write_byte::rom_bank1_return#0
    // [1532] call bank_set_brom
    // [796] phi from rom_write_byte::@1 to bank_set_brom [phi:rom_write_byte::@1->bank_set_brom]
    // [796] phi bank_set_brom::bank#12 = bank_set_brom::bank#3 [phi:rom_write_byte::@1->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_write_byte::@2
    // *ptr_rom = value
    // [1533] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbum2 
    lda value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [1534] return 
    rts
  .segment Data
    rom_bank1___0: .byte 0
    rom_bank1___1: .byte 0
    rom_bank1___2: .word 0
    .label rom_ptr1___0 = rom_ptr1___2
    rom_ptr1___2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1___2
    .label rom_bank1_return = bank_set_brom.bank
    address: .dword 0
    value: .byte 0
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    // __conio.width+1
    // [1535] insertup::$0 = *((char *)&__conio+6) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta __0
    // unsigned char width = (__conio.width+1) * 2
    // [1536] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbum1_rol_1 
    // {asm{.byte $db}}
    asl width
    // [1537] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1537] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1538] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [1539] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1540] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1541] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1542] insertup::$4 = insertup::y#2 + 1 -- vbum1=vbum2_plus_1 
    lda y
    inc
    sta __4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1543] insertup::$6 = insertup::y#2 << 1 -- vbum1=vbum2_rol_1 
    lda y
    asl
    sta __6
    // [1544] insertup::$7 = insertup::$4 << 1 -- vbum1=vbum1_rol_1 
    asl __7
    // [1545] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [1546] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbum2 
    ldy __6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [1547] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [1548] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbum2 
    ldy __7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [1549] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [1550] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1551] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [1537] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1537] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    __0: .byte 0
    __4: .byte 0
    __6: .byte 0
    .label __7 = __4
    .label width = __0
    y: .byte 0
}
.segment Code
  // clearline
clearline: {
    .label c = $28
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1552] clearline::$3 = *((char *)&__conio+1) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta __3
    // [1553] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbum2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1554] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1555] clearline::$0 = byte0  clearline::addr#0 -- vbum1=_byte0_vwum2 
    lda addr
    sta __0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1556] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1557] clearline::$1 = byte1  clearline::addr#0 -- vbum1=_byte1_vwum2 
    lda addr+1
    sta __1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1558] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1559] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta __2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1560] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1561] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1562] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1562] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1563] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1564] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1565] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1566] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1567] return 
    rts
  .segment Data
    __0: .byte 0
    __1: .byte 0
    __2: .byte 0
    __3: .byte 0
    addr: .word 0
}
.segment Code
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
    // [1569] return 
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
// __mem() unsigned int utoa_append(__zp($2b) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $2b
    // [1571] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1571] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1571] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1572] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
    lda sub+1
    cmp value+1
    bne !+
    lda sub
    cmp value
    beq __b2
  !:
    bcc __b2
    // utoa_append::@3
    // *buffer = DIGITS[digit]
    // [1573] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1574] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1575] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1576] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [1571] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1571] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1571] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_sint.value
    .label sub = utoa.digit_value
    .label return = printf_sint.value
    digit: .byte 0
}
.segment Code
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label src = $22
    // [1578] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1578] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1579] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1580] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1581] toupper::ch#0 = *strupr::src#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta toupper.ch
    // [1582] call toupper
    jsr toupper
    // [1583] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1584] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1585] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbum2 
    lda __0
    ldy #0
    sta (src),y
    // src++;
    // [1586] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1578] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1578] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label __0 = toupper.return
}
.segment Code
  // cbm_k_chrin
/**
 * @brief Get a character from the input channel.
 * 
 * @return char 
 */
cbm_k_chrin: {
    // __mem unsigned char value
    // [1587] cbm_k_chrin::value = 0 -- vbum1=vbuc1 
    lda #0
    sta value
    // asm
    // asm { jsrCBM_CHRIN stavalue  }
    jsr CBM_CHRIN
    sta value
    // return value;
    // [1589] cbm_k_chrin::return#0 = cbm_k_chrin::value -- vbum1=vbum2 
    sta return
    // cbm_k_chrin::@return
    // }
    // [1590] cbm_k_chrin::return#1 = cbm_k_chrin::return#0
    // [1591] return 
    rts
  .segment Data
    value: .byte 0
    .label return = ferror.ch
}
.segment Code
  // uctoa_append
// Used to convert a single digit of an unsigned number value to a string representation
// Counts a single digit up from '0' as long as the value is larger than sub.
// Each time the digit is increased sub is subtracted from value.
// - buffer : pointer to the char that receives the digit
// - value : The value where the digit will be derived from
// - sub : the value of a '1' in the digit. Subtracted continually while the digit is increased.
//        (For decimal the subs used are 10000, 1000, 100, 10, 1)
// returns : the value reduced by sub * digit so that it is less than sub.
// __mem() char uctoa_append(__zp($2d) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $2d
    // [1593] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1593] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1593] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1594] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1595] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1596] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1597] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1598] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [1593] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1593] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1593] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uchar.uvalue
    .label sub = uctoa.digit_value
    .label return = printf_uchar.uvalue
    digit: .byte 0
}
.segment Code
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__mem() unsigned long value, __zp($26) char *buffer, char radix)
ultoa: {
    .label buffer = $26
    // [1600] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1600] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1600] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1600] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1600] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1601] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbum1_lt_vbuc1_then_la1 
    lda digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1602] ultoa::$11 = (char)ultoa::value#2 -- vbum1=_byte_vdum2 
    lda value
    sta __11
    // [1603] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1604] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1605] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1606] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1607] ultoa::$10 = ultoa::digit#2 << 2 -- vbum1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta __10
    // [1608] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vdum1=pduc1_derefidx_vbum2 
    tay
    lda RADIX_HEXADECIMAL_VALUES_LONG,y
    sta digit_value
    lda RADIX_HEXADECIMAL_VALUES_LONG+1,y
    sta digit_value+1
    lda RADIX_HEXADECIMAL_VALUES_LONG+2,y
    sta digit_value+2
    lda RADIX_HEXADECIMAL_VALUES_LONG+3,y
    sta digit_value+3
    // if (started || value >= digit_value)
    // [1609] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b5
    // ultoa::@7
    // [1610] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vdum1_ge_vdum2_then_la1 
    lda value+3
    cmp digit_value+3
    bcc !+
    bne __b5
    lda value+2
    cmp digit_value+2
    bcc !+
    bne __b5
    lda value+1
    cmp digit_value+1
    bcc !+
    bne __b5
    lda value
    cmp digit_value
    bcs __b5
  !:
    // [1611] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1611] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1611] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1611] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1612] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1600] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1600] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1600] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1600] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1600] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1613] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1614] ultoa_append::value#0 = ultoa::value#2
    // [1615] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1616] call ultoa_append
    // [1650] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1617] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1618] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1619] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1611] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1611] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1611] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1611] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
  .segment Data
    __10: .byte 0
    __11: .byte 0
    digit_value: .dword 0
    digit: .byte 0
    .label value = print_address.brom_address
    started: .byte 0
}
.segment Code
  // cbm_k_macptr
/**
 * @brief Read a number of bytes from the sdcard using kernal macptr call.
 * BRAM bank needs to be set properly before the load between adressed A000 and BFFF.
 * 
 * @return x the size of bytes read
 * @return y the size of bytes read
 * @return if carry is set there is an error
 */
// __mem() unsigned int cbm_k_macptr(__mem() volatile char bytes, __zp($39) void * volatile buffer)
cbm_k_macptr: {
    .label buffer = $39
    // __mem unsigned int bytes_read
    // [1620] cbm_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [1622] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cbm_k_macptr::@return
    // }
    // [1623] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [1624] return 
    rts
  .segment Data
    bytes: .byte 0
    bytes_read: .word 0
    .label return = fgets.bytes
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
// void memcpy8_vram_vram(__mem() char dbank_vram, __mem() unsigned int doffset_vram, __mem() char sbank_vram, __mem() unsigned int soffset_vram, __mem() char num8)
memcpy8_vram_vram: {
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1625] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1626] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbum1=_byte0_vwum2 
    lda soffset_vram
    sta __0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1627] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1628] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbum1=_byte1_vwum2 
    lda soffset_vram+1
    sta __1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1629] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1630] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbum1=vbum1_bor_vbuc1 
    lda #VERA_INC_1
    ora __2
    sta __2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1631] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1632] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1633] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbum1=_byte0_vwum2 
    lda doffset_vram
    sta __3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1634] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1635] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbum1=_byte1_vwum2 
    lda doffset_vram+1
    sta __4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1636] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1637] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbum1=vbum1_bor_vbuc1 
    lda #VERA_INC_1
    ora __5
    sta __5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1638] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // [1639] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1639] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1640] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [1641] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1642] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1643] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1644] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
    lda num8
    sta num8_1
    jmp __b1
  .segment Data
    __0: .byte 0
    __1: .byte 0
    .label __2 = sbank_vram
    __3: .byte 0
    __4: .byte 0
    .label __5 = dbank_vram
    num8: .byte 0
    dbank_vram: .byte 0
    doffset_vram: .word 0
    sbank_vram: .byte 0
    soffset_vram: .word 0
    num8_1: .byte 0
}
.segment Code
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __mem() char toupper(__mem() char ch)
toupper: {
    // if(ch>='a' && ch<='z')
    // [1645] if(toupper::ch#0<'a'pm) goto toupper::@return -- vbum1_lt_vbuc1_then_la1 
    lda ch
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1646] if(toupper::ch#0<='z'pm) goto toupper::@1 -- vbum1_le_vbuc1_then_la1 
    lda #'z'
    cmp ch
    bcs __b1
    // [1648] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1648] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1647] toupper::return#0 = toupper::ch#0 + 'A'pm-'a'pm -- vbum1=vbum1_plus_vbuc1 
    lda #'A'-'a'
    clc
    adc return
    sta return
    // toupper::@return
  __breturn:
    // }
    // [1649] return 
    rts
  .segment Data
    return: .byte 0
    .label ch = return
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
// __mem() unsigned long ultoa_append(__zp($29) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $29
    // [1651] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1651] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1651] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1652] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
    lda value+3
    cmp sub+3
    bcc !+
    bne __b2
    lda value+2
    cmp sub+2
    bcc !+
    bne __b2
    lda value+1
    cmp sub+1
    bcc !+
    bne __b2
    lda value
    cmp sub
    bcs __b2
  !:
    // ultoa_append::@3
    // *buffer = DIGITS[digit]
    // [1653] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1654] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1655] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1656] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    lda value+2
    sbc sub+2
    sta value+2
    lda value+3
    sbc sub+3
    sta value+3
    // [1651] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1651] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1651] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = print_address.brom_address
    .label sub = ultoa.digit_value
    .label return = print_address.brom_address
    digit: .byte 0
}
  // File Data
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
  // Some addressing constants.
  // The different device IDs that can be returned from the manufacturer ID read sequence.
  // To print the graphics on the vera.
  file: .fill $10, 0
  str: .text " "
  .byte 0
  __conio: .fill SIZEOF_STRUCT___0, 0
  // Buffer used for stringified number being printed
  printf_buffer: .fill SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER, 0
  __stdio_file: .fill SIZEOF_STRUCT___1, 0
  __stdio_filecount: .byte 0
