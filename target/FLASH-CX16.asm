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
    // [445] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [12] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [13] call bgcolor
    // [450] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [463] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label fp = $4c
    .label read_ram_address = $46
    .label read_ram_address_sector = $44
    .label read_ram_address1 = $3f
    .label rom_device = $50
    .label pattern = $4a
    .label __188 = $37
    .label __189 = $25
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@60
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
    // [65] phi from main::@60 to main::@69 [phi:main::@60->main::@69]
    // main::@69
    // textcolor(WHITE)
    // [66] call textcolor
    // [445] phi from main::@69 to textcolor [phi:main::@69->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:main::@69->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [67] phi from main::@69 to main::@70 [phi:main::@69->main::@70]
    // main::@70
    // bgcolor(BLUE)
    // [68] call bgcolor
    // [450] phi from main::@70 to bgcolor [phi:main::@70->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:main::@70->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [69] phi from main::@70 to main::@71 [phi:main::@70->main::@71]
    // main::@71
    // scroll(0)
    // [70] call scroll
    jsr scroll
    // [71] phi from main::@71 to main::@72 [phi:main::@71->main::@72]
    // main::@72
    // clrscr()
    // [72] call clrscr
    jsr clrscr
    // [73] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // frame_draw()
    // [74] call frame_draw
    // [513] phi from main::@73 to frame_draw [phi:main::@73->frame_draw]
    jsr frame_draw
    // [75] phi from main::@73 to main::@74 [phi:main::@73->main::@74]
    // main::@74
    // gotoxy(2, 1)
    // [76] call gotoxy
    // [463] phi from main::@74 to gotoxy [phi:main::@74->gotoxy]
    // [463] phi gotoxy::y#25 = 1 [phi:main::@74->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = 2 [phi:main::@74->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [77] phi from main::@74 to main::@75 [phi:main::@74->main::@75]
    // main::@75
    // printf("commander x16 rom flash utility")
    // [78] call printf_str
    // [693] phi from main::@75 to printf_str [phi:main::@75->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@75->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s [phi:main::@75->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [79] phi from main::@75 to main::@76 [phi:main::@75->main::@76]
    // main::@76
    // print_chips()
    // [80] call print_chips
    // [702] phi from main::@76 to print_chips [phi:main::@76->print_chips]
    jsr print_chips
    // [81] phi from main::@76 to main::@1 [phi:main::@76->main::@1]
    // [81] phi main::rom_chip#10 = 0 [phi:main::@76->main::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [81] phi main::flash_rom_address#10 = 0 [phi:main::@76->main::@1#1] -- vdum1=vduc1 
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
    // [84] phi from main::CLI1 to main::@61 [phi:main::CLI1->main::@61]
    // main::@61
    // print_clear()
    // [85] call print_clear
    // [733] phi from main::@61 to print_clear [phi:main::@61->print_clear]
    jsr print_clear
    // [86] phi from main::@61 to main::@77 [phi:main::@61->main::@77]
    // main::@77
    // printf("%s", "press a key to start flashing.")
    // [87] call printf_string
    // [742] phi from main::@77 to printf_string [phi:main::@77->printf_string]
    // [742] phi printf_string::str#12 = main::str [phi:main::@77->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [742] phi printf_string::format_min_length#12 = 0 [phi:main::@77->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [88] phi from main::@77 to main::@78 [phi:main::@77->main::@78]
    // main::@78
    // wait_key()
    // [89] call wait_key
  // Ensure the ROM is set to BASIC.
    // [759] phi from main::@78 to wait_key [phi:main::@78->wait_key]
    jsr wait_key
    // [90] phi from main::@78 to main::@79 [phi:main::@78->main::@79]
    // main::@79
    // print_clear()
    // [91] call print_clear
    // [733] phi from main::@79 to print_clear [phi:main::@79->print_clear]
    jsr print_clear
    // [92] phi from main::@79 to main::@21 [phi:main::@79->main::@21]
    // [92] phi main::flash_chip#10 = 7 [phi:main::@79->main::@21#0] -- vbum1=vbuc1 
    lda #7
    sta flash_chip
    // main::@21
  __b21:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [93] if(main::flash_chip#10!=$ff) goto main::@22 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp flash_chip
    beq !__b22+
    jmp __b22
  !__b22:
    // [94] phi from main::@21 to main::@23 [phi:main::@21->main::@23]
    // main::@23
    // bank_set_brom(0)
    // [95] call bank_set_brom
    // [769] phi from main::@23 to bank_set_brom [phi:main::@23->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 0 [phi:main::@23->bank_set_brom#0] -- vbum1=vbuc1 
    lda #0
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [96] phi from main::@23 to main::@93 [phi:main::@23->main::@93]
    // main::@93
    // textcolor(WHITE)
    // [97] call textcolor
    // [445] phi from main::@93 to textcolor [phi:main::@93->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:main::@93->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [98] phi from main::@93 to main::@55 [phi:main::@93->main::@55]
    // [98] phi main::w#2 = $80 [phi:main::@93->main::@55#0] -- vwsm1=vwsc1 
    lda #<$80
    sta w
    lda #>$80
    sta w+1
    // main::@55
  __b55:
    // for (int w = 128; w >= 0; w--)
    // [99] if(main::w#2>=0) goto main::@57 -- vwsm1_ge_0_then_la1 
    lda w+1
    bpl __b11
    // [100] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
    // system_reset()
    // [101] call system_reset
    // [772] phi from main::@56 to system_reset [phi:main::@56->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [102] return 
    rts
    // [103] phi from main::@55 to main::@57 [phi:main::@55->main::@57]
  __b11:
    // [103] phi main::v#2 = 0 [phi:main::@55->main::@57#0] -- vwum1=vwuc1 
    lda #<0
    sta v
    sta v+1
    // main::@57
  __b57:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [104] if(main::v#2<$100*$80) goto main::@58 -- vwum1_lt_vwuc1_then_la1 
    lda v+1
    cmp #>$100*$80
    bcc __b58
    bne !+
    lda v
    cmp #<$100*$80
    bcc __b58
  !:
    // [105] phi from main::@57 to main::@59 [phi:main::@57->main::@59]
    // main::@59
    // print_clear()
    // [106] call print_clear
    // [733] phi from main::@59 to print_clear [phi:main::@59->print_clear]
    jsr print_clear
    // [107] phi from main::@59 to main::@162 [phi:main::@59->main::@162]
    // main::@162
    // printf("resetting commander x16 (%i)", w)
    // [108] call printf_str
    // [693] phi from main::@162 to printf_str [phi:main::@162->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@162->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s21 [phi:main::@162->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@163
    // printf("resetting commander x16 (%i)", w)
    // [109] printf_sint::value#1 = main::w#2 -- vwsm1=vwsm2 
    lda w
    sta printf_sint.value
    lda w+1
    sta printf_sint.value+1
    // [110] call printf_sint
    jsr printf_sint
    // [111] phi from main::@163 to main::@164 [phi:main::@163->main::@164]
    // main::@164
    // printf("resetting commander x16 (%i)", w)
    // [112] call printf_str
    // [693] phi from main::@164 to printf_str [phi:main::@164->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@164->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s22 [phi:main::@164->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@165
    // for (int w = 128; w >= 0; w--)
    // [113] main::w#1 = -- main::w#2 -- vwsm1=_dec_vwsm1 
    lda w
    bne !+
    dec w+1
  !:
    dec w
    // [98] phi from main::@165 to main::@55 [phi:main::@165->main::@55]
    // [98] phi main::w#2 = main::w#1 [phi:main::@165->main::@55#0] -- register_copy 
    jmp __b55
    // main::@58
  __b58:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [114] main::v#1 = ++ main::v#2 -- vwum1=_inc_vwum1 
    inc v
    bne !+
    inc v+1
  !:
    // [103] phi from main::@58 to main::@57 [phi:main::@58->main::@57]
    // [103] phi main::v#2 = main::v#1 [phi:main::@58->main::@57#0] -- register_copy 
    jmp __b57
    // main::@22
  __b22:
    // if (rom_device_ids[flash_chip] != UNKNOWN)
    // [115] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@24 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b24+
    jmp __b24
  !__b24:
    // [116] phi from main::@22 to main::@53 [phi:main::@22->main::@53]
    // main::@53
    // gotoxy(0, 2)
    // [117] call gotoxy
    // [463] phi from main::@53 to gotoxy [phi:main::@53->gotoxy]
    // [463] phi gotoxy::y#25 = 2 [phi:main::@53->gotoxy#0] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = 0 [phi:main::@53->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [118] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [119] phi from main::bank_set_bram1 to main::@62 [phi:main::bank_set_bram1->main::@62]
    // main::@62
    // bank_set_brom(0)
    // [120] call bank_set_brom
    // [769] phi from main::@62 to bank_set_brom [phi:main::@62->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 0 [phi:main::@62->bank_set_brom#0] -- vbum1=vbuc1 
    lda #0
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [121] phi from main::@62 to main::@94 [phi:main::@62->main::@94]
    // main::@94
    // strcpy(file, "rom")
    // [122] call strcpy
    // [788] phi from main::@94 to strcpy [phi:main::@94->strcpy]
    jsr strcpy
    // main::@95
    // if (flash_chip != 0)
    // [123] if(main::flash_chip#10==0) goto main::@25 -- vbum1_eq_0_then_la1 
    lda flash_chip
    beq __b25
    // [124] phi from main::@95 to main::@54 [phi:main::@95->main::@54]
    // main::@54
    // size_t len = strlen(file)
    // [125] call strlen
    // [796] phi from main::@54 to strlen [phi:main::@54->strlen]
    // [796] phi strlen::str#9 = file [phi:main::@54->strlen#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strlen.str
    lda #>file
    sta.z strlen.str+1
    jsr strlen
    // size_t len = strlen(file)
    // [126] strlen::return#14 = strlen::len#2
    // main::@102
    // [127] main::len#0 = strlen::return#14
    // 0x30 + flash_chip
    // [128] main::$56 = $30 + main::flash_chip#10 -- vbum1=vbuc1_plus_vbum2 
    lda #$30
    clc
    adc flash_chip
    sta __56
    // file[len] = 0x30 + flash_chip
    // [129] main::$188 = file + main::len#0 -- pbuz1=pbuc1_plus_vwum2 
    lda len
    clc
    adc #<file
    sta.z __188
    lda len+1
    adc #>file
    sta.z __188+1
    // [130] *main::$188 = main::$56 -- _deref_pbuz1=vbum2 
    lda __56
    ldy #0
    sta (__188),y
    // file[len+1] = '\0'
    // [131] main::$189 = file+1 + main::len#0 -- pbuz1=pbuc1_plus_vwum2 
    lda len
    clc
    adc #<file+1
    sta.z __189
    lda len+1
    adc #>file+1
    sta.z __189+1
    // [132] *main::$189 = '?'pm -- _deref_pbuz1=vbuc1 
    lda #'\$00'
    sta (__189),y
    // [133] phi from main::@102 main::@95 to main::@25 [phi:main::@102/main::@95->main::@25]
    // main::@25
  __b25:
    // strcat(file, ".bin")
    // [134] call strcat
    // [802] phi from main::@25 to strcat [phi:main::@25->strcat]
    jsr strcat
    // [135] phi from main::@25 to main::@96 [phi:main::@25->main::@96]
    // main::@96
    // print_clear()
    // [136] call print_clear
    // [733] phi from main::@96 to print_clear [phi:main::@96->print_clear]
    jsr print_clear
    // [137] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // printf("opening %s.", file)
    // [138] call printf_str
    // [693] phi from main::@97 to printf_str [phi:main::@97->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@97->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s1 [phi:main::@97->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [139] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // printf("opening %s.", file)
    // [140] call printf_string
    // [742] phi from main::@98 to printf_string [phi:main::@98->printf_string]
    // [742] phi printf_string::str#12 = file [phi:main::@98->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [742] phi printf_string::format_min_length#12 = 0 [phi:main::@98->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [141] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // printf("opening %s.", file)
    // [142] call printf_str
    // [693] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s2 [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@100
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
    // main::@101
    // [146] main::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [147] if((struct $1 *)0!=main::fp#0) goto main::@26 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    beq !__b26+
    jmp __b26
  !__b26:
    lda.z fp
    cmp #<0
    beq !__b26+
    jmp __b26
  !__b26:
    // main::@51
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [148] print_chip_led::r#6 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [149] call print_chip_led
    // [872] phi from main::@51 to print_chip_led [phi:main::@51->print_chip_led]
    // [872] phi print_chip_led::tc#10 = DARK_GREY [phi:main::@51->print_chip_led#0] -- vbum1=vbuc1 
    lda #DARK_GREY
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#6 [phi:main::@51->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [150] phi from main::@51 to main::@115 [phi:main::@51->main::@115]
    // main::@115
    // print_clear()
    // [151] call print_clear
    // [733] phi from main::@115 to print_clear [phi:main::@115->print_clear]
    jsr print_clear
    // [152] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [153] call printf_str
    // [693] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s5 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [154] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [155] call printf_string
    // [742] phi from main::@117 to printf_string [phi:main::@117->printf_string]
    // [742] phi printf_string::str#12 = file [phi:main::@117->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [742] phi printf_string::format_min_length#12 = 0 [phi:main::@117->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [156] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [157] call printf_str
    // [693] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s6 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [158] printf_uchar::uvalue#5 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [159] call printf_uchar
    // [892] phi from main::@119 to printf_uchar [phi:main::@119->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@119->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 0 [phi:main::@119->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@119->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#5 [phi:main::@119->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [160] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [161] call printf_str
    // [693] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s7 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@121
    // flash_chip * 10
    // [162] main::$196 = main::flash_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda flash_chip
    asl
    asl
    sta __196
    // [163] main::$197 = main::$196 + main::flash_chip#10 -- vbum1=vbum1_plus_vbum2 
    lda __197
    clc
    adc flash_chip
    sta __197
    // [164] main::$66 = main::$197 << 1 -- vbum1=vbum1_rol_1 
    asl __66
    // gotoxy(2 + flash_chip * 10, 58)
    // [165] gotoxy::x#19 = 2 + main::$66 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc __66
    sta gotoxy.x
    // [166] call gotoxy
    // [463] phi from main::@121 to gotoxy [phi:main::@121->gotoxy]
    // [463] phi gotoxy::y#25 = $3a [phi:main::@121->gotoxy#0] -- vbum1=vbuc1 
    lda #$3a
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = gotoxy::x#19 [phi:main::@121->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [167] phi from main::@121 to main::@122 [phi:main::@121->main::@122]
    // main::@122
    // printf("no file")
    // [168] call printf_str
    // [693] phi from main::@122 to printf_str [phi:main::@122->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@122->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s8 [phi:main::@122->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@27
  __b27:
    // if (flash_chip != 0)
    // [169] if(main::flash_chip#10==0) goto main::@24 -- vbum1_eq_0_then_la1 
    lda flash_chip
    beq __b24
    // [170] phi from main::@27 to main::@52 [phi:main::@27->main::@52]
    // main::@52
    // bank_set_brom(4)
    // [171] call bank_set_brom
    // [769] phi from main::@52 to bank_set_brom [phi:main::@52->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 4 [phi:main::@52->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // [173] phi from main::CLI3 to main::@68 [phi:main::CLI3->main::@68]
    // main::@68
    // wait_key()
    // [174] call wait_key
    // [759] phi from main::@68 to wait_key [phi:main::@68->wait_key]
    jsr wait_key
    // main::SEI4
    // asm
    // asm { sei  }
    sei
    // main::@24
  __b24:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [176] main::flash_chip#1 = -- main::flash_chip#10 -- vbum1=_dec_vbum1 
    dec flash_chip
    // [92] phi from main::@24 to main::@21 [phi:main::@24->main::@21]
    // [92] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@24->main::@21#0] -- register_copy 
    jmp __b21
    // main::@26
  __b26:
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
    // [902] phi from main::@26 to table_chip_clear [phi:main::@26->table_chip_clear]
    jsr table_chip_clear
    // [179] phi from main::@26 to main::@103 [phi:main::@26->main::@103]
    // main::@103
    // textcolor(WHITE)
    // [180] call textcolor
    // [445] phi from main::@103 to textcolor [phi:main::@103->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:main::@103->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@104
    // flash_chip * 10
    // [181] main::$172 = main::flash_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda flash_chip
    asl
    asl
    sta __172
    // [182] main::$194 = main::$172 + main::flash_chip#10 -- vbum1=vbum2_plus_vbum3 
    clc
    adc flash_chip
    sta __194
    // [183] main::$73 = main::$194 << 1 -- vbum1=vbum1_rol_1 
    asl __73
    // gotoxy(2 + flash_chip * 10, 58)
    // [184] gotoxy::x#18 = 2 + main::$73 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc __73
    sta gotoxy.x
    // [185] call gotoxy
    // [463] phi from main::@104 to gotoxy [phi:main::@104->gotoxy]
    // [463] phi gotoxy::y#25 = $3a [phi:main::@104->gotoxy#0] -- vbum1=vbuc1 
    lda #$3a
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = gotoxy::x#18 [phi:main::@104->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [186] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // printf("%s", file)
    // [187] call printf_string
    // [742] phi from main::@105 to printf_string [phi:main::@105->printf_string]
    // [742] phi printf_string::str#12 = file [phi:main::@105->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [742] phi printf_string::format_min_length#12 = 0 [phi:main::@105->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@106
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [188] print_chip_led::r#5 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [189] call print_chip_led
    // [872] phi from main::@106 to print_chip_led [phi:main::@106->print_chip_led]
    // [872] phi print_chip_led::tc#10 = CYAN [phi:main::@106->print_chip_led#0] -- vbum1=vbuc1 
    lda #CYAN
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#5 [phi:main::@106->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [190] phi from main::@106 to main::@107 [phi:main::@106->main::@107]
    // main::@107
    // print_clear()
    // [191] call print_clear
    // [733] phi from main::@107 to print_clear [phi:main::@107->print_clear]
    jsr print_clear
    // [192] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [193] call printf_str
    // [693] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s3 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [194] printf_uchar::uvalue#4 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [195] call printf_uchar
    // [892] phi from main::@109 to printf_uchar [phi:main::@109->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@109->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 0 [phi:main::@109->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@109->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#4 [phi:main::@109->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [196] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [197] call printf_str
    // [693] phi from main::@110 to printf_str [phi:main::@110->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@110->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s4 [phi:main::@110->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@111
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [198] rom_address::rom_bank#2 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta rom_address.rom_bank
    // [199] call rom_address
    // [927] phi from main::@111 to rom_address [phi:main::@111->rom_address]
    // [927] phi rom_address::rom_bank#5 = rom_address::rom_bank#2 [phi:main::@111->rom_address#0] -- register_copy 
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
    // main::@112
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
    // [931] phi from main::@112 to flash_read [phi:main::@112->flash_read]
    // [931] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@112->flash_read#0] -- register_copy 
    // [931] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@112->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [931] phi flash_read::read_size#4 = $4000 [phi:main::@112->flash_read#2] -- vdum1=vduc1 
    lda #<$4000
    sta flash_read.read_size
    lda #>$4000
    sta flash_read.read_size+1
    lda #<$4000>>$10
    sta flash_read.read_size+2
    lda #>$4000>>$10
    sta flash_read.read_size+3
    // [931] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@112->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, size)
    // [205] flash_read::return#3 = flash_read::return#2
    // main::@113
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
    // [963] phi from main::@113 to rom_size [phi:main::@113->rom_size]
    jsr rom_size
    // main::@114
    // if (flash_bytes != rom_size(1))
    // [208] if(main::flash_bytes#0==rom_size::return#0) goto main::@28 -- vdum1_eq_vduc1_then_la1 
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
    beq __b28
  !:
    rts
    // main::@28
  __b28:
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
    // main::@63
    // size = rom_sizes[flash_chip]
    // [211] main::size#1 = main::rom_sizes[main::$172] -- vdum1=pduc1_derefidx_vbum2 
    // read from bank 1 in bram.
    ldy __172
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
    // [931] phi from main::@63 to flash_read [phi:main::@63->flash_read]
    // [931] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@63->flash_read#0] -- register_copy 
    // [931] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@63->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [931] phi flash_read::read_size#4 = flash_read::read_size#1 [phi:main::@63->flash_read#2] -- register_copy 
    // [931] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@63->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [217] flash_read::return#4 = flash_read::return#2
    // main::@123
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
    // [223] phi from main::bank_set_bram3 to main::@64 [phi:main::bank_set_bram3->main::@64]
    // main::@64
    // bank_set_brom(4)
    // [224] call bank_set_brom
    // [769] phi from main::@64 to bank_set_brom [phi:main::@64->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 4 [phi:main::@64->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [225] phi from main::@64 to main::@124 [phi:main::@64->main::@124]
    // main::@124
    // print_clear()
    // [226] call print_clear
  // Now we compare the RAM with the actual ROM contents.
    // [733] phi from main::@124 to print_clear [phi:main::@124->print_clear]
    jsr print_clear
    // [227] phi from main::@124 to main::@125 [phi:main::@124->main::@125]
    // main::@125
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [228] call printf_str
    // [693] phi from main::@125 to printf_str [phi:main::@125->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@125->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s9 [phi:main::@125->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@126
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [229] printf_uchar::uvalue#6 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [230] call printf_uchar
    // [892] phi from main::@126 to printf_uchar [phi:main::@126->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@126->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 0 [phi:main::@126->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@126->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#6 [phi:main::@126->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [231] phi from main::@126 to main::@127 [phi:main::@126->main::@127]
    // main::@127
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [232] call printf_str
    // [693] phi from main::@127 to printf_str [phi:main::@127->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@127->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s10 [phi:main::@127->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@128
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [233] rom_address::rom_bank#3 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta rom_address.rom_bank
    // [234] call rom_address
    // [927] phi from main::@128 to rom_address [phi:main::@128->rom_address]
    // [927] phi rom_address::rom_bank#5 = rom_address::rom_bank#3 [phi:main::@128->rom_address#0] -- register_copy 
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
    // main::@129
    // [236] main::flash_rom_address1#0 = rom_address::return#11
    // gotoxy(x, y)
    // [237] call gotoxy
    // [463] phi from main::@129 to gotoxy [phi:main::@129->gotoxy]
    // [463] phi gotoxy::y#25 = 4 [phi:main::@129->gotoxy#0] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = $e [phi:main::@129->gotoxy#1] -- vbum1=vbuc1 
    lda #$e
    sta gotoxy.x
    jsr gotoxy
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [239] phi from main::SEI2 to main::@29 [phi:main::SEI2->main::@29]
    // [239] phi main::y_sector#10 = 4 [phi:main::SEI2->main::@29#0] -- vbum1=vbuc1 
    lda #4
    sta y_sector
    // [239] phi main::x_sector#10 = $e [phi:main::SEI2->main::@29#1] -- vbum1=vbuc1 
    lda #$e
    sta x_sector
    // [239] phi main::read_ram_address#10 = (char *) 16384 [phi:main::SEI2->main::@29#2] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address
    lda #>$4000
    sta.z read_ram_address+1
    // [239] phi main::read_ram_bank#13 = 0 [phi:main::SEI2->main::@29#3] -- vbum1=vbuc1 
    lda #0
    sta read_ram_bank
    // [239] phi main::flash_rom_address1#13 = main::flash_rom_address1#0 [phi:main::SEI2->main::@29#4] -- register_copy 
    // [239] phi from main::@35 to main::@29 [phi:main::@35->main::@29]
    // [239] phi main::y_sector#10 = main::y_sector#10 [phi:main::@35->main::@29#0] -- register_copy 
    // [239] phi main::x_sector#10 = main::x_sector#1 [phi:main::@35->main::@29#1] -- register_copy 
    // [239] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@35->main::@29#2] -- register_copy 
    // [239] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@35->main::@29#3] -- register_copy 
    // [239] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@35->main::@29#4] -- register_copy 
    // main::@29
  __b29:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [240] if(main::flash_rom_address1#13<main::flash_rom_address_boundary#11) goto main::@30 -- vdum1_lt_vdum2_then_la1 
    lda flash_rom_address1+3
    cmp flash_rom_address_boundary_2+3
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda flash_rom_address1+2
    cmp flash_rom_address_boundary_2+2
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda flash_rom_address1+1
    cmp flash_rom_address_boundary_2+1
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda flash_rom_address1
    cmp flash_rom_address_boundary_2
    bcs !__b30+
    jmp __b30
  !__b30:
  !:
    // [241] phi from main::@29 to main::@31 [phi:main::@29->main::@31]
    // main::@31
    // print_clear()
    // [242] call print_clear
    // [733] phi from main::@31 to print_clear [phi:main::@31->print_clear]
    jsr print_clear
    // [243] phi from main::@31 to main::@131 [phi:main::@31->main::@131]
    // main::@131
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [244] call printf_str
    // [693] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s11 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@132
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [245] printf_uchar::uvalue#7 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [246] call printf_uchar
    // [892] phi from main::@132 to printf_uchar [phi:main::@132->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@132->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 0 [phi:main::@132->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@132->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#7 [phi:main::@132->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [247] phi from main::@132 to main::@133 [phi:main::@132->main::@133]
    // main::@133
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [248] call printf_str
    // [693] phi from main::@133 to printf_str [phi:main::@133->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@133->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s12 [phi:main::@133->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // [249] phi from main::@133 to main::@134 [phi:main::@133->main::@134]
    // main::@134
    // bank_set_brom(4)
    // [250] call bank_set_brom
    // [769] phi from main::@134 to bank_set_brom [phi:main::@134->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 4 [phi:main::@134->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [252] phi from main::CLI2 to main::@65 [phi:main::CLI2->main::@65]
    // main::@65
    // wait_key()
    // [253] call wait_key
    // [759] phi from main::@65 to wait_key [phi:main::@65->wait_key]
    jsr wait_key
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::@66
    // rom_address(flash_rom_bank)
    // [255] rom_address::rom_bank#4 = main::flash_rom_bank#0 -- vbum1=vbum2 
    lda flash_rom_bank
    sta rom_address.rom_bank
    // [256] call rom_address
    // [927] phi from main::@66 to rom_address [phi:main::@66->rom_address]
    // [927] phi rom_address::rom_bank#5 = rom_address::rom_bank#4 [phi:main::@66->rom_address#0] -- register_copy 
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
    // main::@135
    // flash_rom_address_sector = rom_address(flash_rom_bank)
    // [258] main::flash_rom_address_sector#1 = rom_address::return#12
    // textcolor(WHITE)
    // [259] call textcolor
    // [445] phi from main::@135 to textcolor [phi:main::@135->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:main::@135->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@136
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [260] print_chip_led::r#7 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [261] call print_chip_led
    // [872] phi from main::@136 to print_chip_led [phi:main::@136->print_chip_led]
    // [872] phi print_chip_led::tc#10 = PURPLE [phi:main::@136->print_chip_led#0] -- vbum1=vbuc1 
    lda #PURPLE
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#7 [phi:main::@136->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [262] phi from main::@136 to main::@137 [phi:main::@136->main::@137]
    // main::@137
    // print_clear()
    // [263] call print_clear
    // [733] phi from main::@137 to print_clear [phi:main::@137->print_clear]
    jsr print_clear
    // [264] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [265] call printf_str
    // [693] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s13 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [266] printf_uchar::uvalue#8 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [267] call printf_uchar
    // [892] phi from main::@139 to printf_uchar [phi:main::@139->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@139->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 0 [phi:main::@139->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@139->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#8 [phi:main::@139->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [268] phi from main::@139 to main::@140 [phi:main::@139->main::@140]
    // main::@140
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [269] call printf_str
    // [693] phi from main::@140 to printf_str [phi:main::@140->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@140->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s14 [phi:main::@140->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // [270] phi from main::@140 to main::@38 [phi:main::@140->main::@38]
    // [270] phi main::y_sector1#13 = 4 [phi:main::@140->main::@38#0] -- vbum1=vbuc1 
    lda #4
    sta y_sector1
    // [270] phi main::x_sector1#10 = $e [phi:main::@140->main::@38#1] -- vbum1=vbuc1 
    lda #$e
    sta x_sector1
    // [270] phi main::read_ram_address_sector#10 = (char *) 16384 [phi:main::@140->main::@38#2] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address_sector
    lda #>$4000
    sta.z read_ram_address_sector+1
    // [270] phi main::read_ram_bank_sector#13 = 0 [phi:main::@140->main::@38#3] -- vbum1=vbuc1 
    lda #0
    sta read_ram_bank_sector
    // [270] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#1 [phi:main::@140->main::@38#4] -- register_copy 
    // [270] phi from main::@46 to main::@38 [phi:main::@46->main::@38]
    // [270] phi main::y_sector1#13 = main::y_sector1#13 [phi:main::@46->main::@38#0] -- register_copy 
    // [270] phi main::x_sector1#10 = main::x_sector1#1 [phi:main::@46->main::@38#1] -- register_copy 
    // [270] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@46->main::@38#2] -- register_copy 
    // [270] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@46->main::@38#3] -- register_copy 
    // [270] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@46->main::@38#4] -- register_copy 
    // main::@38
  __b38:
    // while (flash_rom_address_sector < flash_rom_address_boundary)
    // [271] if(main::flash_rom_address_sector#11<main::flash_rom_address_boundary#11) goto main::@39 -- vdum1_lt_vdum2_then_la1 
    lda flash_rom_address_sector+3
    cmp flash_rom_address_boundary_2+3
    bcs !__b39+
    jmp __b39
  !__b39:
    bne !+
    lda flash_rom_address_sector+2
    cmp flash_rom_address_boundary_2+2
    bcc __b39
    bne !+
    lda flash_rom_address_sector+1
    cmp flash_rom_address_boundary_2+1
    bcc __b39
    bne !+
    lda flash_rom_address_sector
    cmp flash_rom_address_boundary_2
    bcc __b39
  !:
    // main::bank_set_bram4
    // BRAM = bank
    // [272] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // [273] phi from main::bank_set_bram4 to main::@67 [phi:main::bank_set_bram4->main::@67]
    // main::@67
    // bank_set_brom(4)
    // [274] call bank_set_brom
    // [769] phi from main::@67 to bank_set_brom [phi:main::@67->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 4 [phi:main::@67->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [275] phi from main::@67 to main::@50 [phi:main::@67->main::@50]
    // main::@50
    // textcolor(GREEN)
    // [276] call textcolor
    // [445] phi from main::@50 to textcolor [phi:main::@50->textcolor]
    // [445] phi textcolor::color#23 = GREEN [phi:main::@50->textcolor#0] -- vbum1=vbuc1 
    lda #GREEN
    sta textcolor.color
    jsr textcolor
    // main::@157
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [277] print_chip_led::r#8 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta print_chip_led.r
    // [278] call print_chip_led
    // [872] phi from main::@157 to print_chip_led [phi:main::@157->print_chip_led]
    // [872] phi print_chip_led::tc#10 = GREEN [phi:main::@157->print_chip_led#0] -- vbum1=vbuc1 
    lda #GREEN
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#8 [phi:main::@157->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [279] phi from main::@157 to main::@158 [phi:main::@157->main::@158]
    // main::@158
    // print_clear()
    // [280] call print_clear
    // [733] phi from main::@158 to print_clear [phi:main::@158->print_clear]
    jsr print_clear
    // [281] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [282] call printf_str
    // [693] phi from main::@159 to printf_str [phi:main::@159->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@159->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s16 [phi:main::@159->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@160
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [283] printf_uchar::uvalue#9 = main::flash_chip#10 -- vbum1=vbum2 
    lda flash_chip
    sta printf_uchar.uvalue
    // [284] call printf_uchar
    // [892] phi from main::@160 to printf_uchar [phi:main::@160->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@160->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 0 [phi:main::@160->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@160->printf_uchar#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#9 [phi:main::@160->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [285] phi from main::@160 to main::@161 [phi:main::@160->main::@161]
    // main::@161
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [286] call printf_str
    // [693] phi from main::@161 to printf_str [phi:main::@161->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@161->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s17 [phi:main::@161->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    jmp __b27
    // main::@39
  __b39:
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [287] flash_verify::bank_ram#1 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta flash_verify.bank_ram
    // [288] flash_verify::ptr_ram#2 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address_sector+1
    sta.z flash_verify.ptr_ram+1
    // [289] flash_verify::verify_rom_address#1 = main::flash_rom_address_sector#11 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta flash_verify.verify_rom_address
    lda flash_rom_address_sector+1
    sta flash_verify.verify_rom_address+1
    lda flash_rom_address_sector+2
    sta flash_verify.verify_rom_address+2
    lda flash_rom_address_sector+3
    sta flash_verify.verify_rom_address+3
    // [290] call flash_verify
  // rom_sector_erase(flash_rom_address_sector);
    // [977] phi from main::@39 to flash_verify [phi:main::@39->flash_verify]
    // [977] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#2 [phi:main::@39->flash_verify#0] -- register_copy 
    // [977] phi flash_verify::verify_rom_size#11 = $1000 [phi:main::@39->flash_verify#1] -- vwum1=vwuc1 
    lda #<$1000
    sta flash_verify.verify_rom_size
    lda #>$1000
    sta flash_verify.verify_rom_size+1
    // [977] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#1 [phi:main::@39->flash_verify#2] -- register_copy 
    // [977] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#1 [phi:main::@39->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [291] flash_verify::return#3 = flash_verify::correct_bytes#2
    // main::@145
    // [292] main::equal_bytes1#0 = flash_verify::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [293] if(main::equal_bytes1#0!=$1000) goto main::@41 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes1+1
    cmp #>$1000
    beq !__b41+
    jmp __b41
  !__b41:
    lda equal_bytes1
    cmp #<$1000
    beq !__b41+
    jmp __b41
  !__b41:
    // [294] phi from main::@145 to main::@47 [phi:main::@145->main::@47]
    // main::@47
    // textcolor(WHITE)
    // [295] call textcolor
    // [445] phi from main::@47 to textcolor [phi:main::@47->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:main::@47->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@146
    // gotoxy(x_sector, y_sector)
    // [296] gotoxy::x#22 = main::x_sector1#10 -- vbum1=vbum2 
    lda x_sector1
    sta gotoxy.x
    // [297] gotoxy::y#22 = main::y_sector1#13 -- vbum1=vbum2 
    lda y_sector1
    sta gotoxy.y
    // [298] call gotoxy
    // [463] phi from main::@146 to gotoxy [phi:main::@146->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#22 [phi:main::@146->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = gotoxy::x#22 [phi:main::@146->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [299] phi from main::@146 to main::@147 [phi:main::@146->main::@147]
    // main::@147
    // printf("%s", pattern)
    // [300] call printf_string
    // [742] phi from main::@147 to printf_string [phi:main::@147->printf_string]
    // [742] phi printf_string::str#12 = main::pattern1#1 [phi:main::@147->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern1
    sta.z printf_string.str
    lda #>pattern1
    sta.z printf_string.str+1
    // [742] phi printf_string::format_min_length#12 = 0 [phi:main::@147->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@40
  __b40:
    // read_ram_address_sector += ROM_SECTOR
    // [301] main::read_ram_address_sector#2 = main::read_ram_address_sector#10 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address_sector
    clc
    adc #<$1000
    sta.z read_ram_address_sector
    lda.z read_ram_address_sector+1
    adc #>$1000
    sta.z read_ram_address_sector+1
    // flash_rom_address_sector += ROM_SECTOR
    // [302] main::flash_rom_address_sector#10 = main::flash_rom_address_sector#11 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [303] if(main::read_ram_address_sector#2!=$8000) goto main::@167 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$8000
    bne __b45
    lda.z read_ram_address_sector
    cmp #<$8000
    bne __b45
    // [305] phi from main::@40 to main::@45 [phi:main::@40->main::@45]
    // [305] phi main::read_ram_bank_sector#6 = 1 [phi:main::@40->main::@45#0] -- vbum1=vbuc1 
    lda #1
    sta read_ram_bank_sector
    // [305] phi main::read_ram_address_sector#8 = (char *) 40960 [phi:main::@40->main::@45#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [304] phi from main::@40 to main::@167 [phi:main::@40->main::@167]
    // main::@167
    // [305] phi from main::@167 to main::@45 [phi:main::@167->main::@45]
    // [305] phi main::read_ram_bank_sector#6 = main::read_ram_bank_sector#13 [phi:main::@167->main::@45#0] -- register_copy 
    // [305] phi main::read_ram_address_sector#8 = main::read_ram_address_sector#2 [phi:main::@167->main::@45#1] -- register_copy 
    // main::@45
  __b45:
    // if (read_ram_address_sector == 0xC000)
    // [306] if(main::read_ram_address_sector#8!=$c000) goto main::@46 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$c000
    bne __b46
    lda.z read_ram_address_sector
    cmp #<$c000
    bne __b46
    // main::@48
    // read_ram_bank_sector++;
    // [307] main::read_ram_bank_sector#3 = ++ main::read_ram_bank_sector#6 -- vbum1=_inc_vbum1 
    inc read_ram_bank_sector
    // [308] phi from main::@48 to main::@46 [phi:main::@48->main::@46]
    // [308] phi main::read_ram_address_sector#14 = (char *) 40960 [phi:main::@48->main::@46#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [308] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#3 [phi:main::@48->main::@46#1] -- register_copy 
    // [308] phi from main::@45 to main::@46 [phi:main::@45->main::@46]
    // [308] phi main::read_ram_address_sector#14 = main::read_ram_address_sector#8 [phi:main::@45->main::@46#0] -- register_copy 
    // [308] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#6 [phi:main::@45->main::@46#1] -- register_copy 
    // main::@46
  __b46:
    // x_sector += 16
    // [309] main::x_sector1#1 = main::x_sector1#10 + $10 -- vbum1=vbum1_plus_vbuc1 
    lda #$10
    clc
    adc x_sector1
    sta x_sector1
    // flash_rom_address_sector % 0x4000
    // [310] main::$145 = main::flash_rom_address_sector#10 & $4000-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address_sector
    and #<$4000-1
    sta __145
    lda flash_rom_address_sector+1
    and #>$4000-1
    sta __145+1
    lda flash_rom_address_sector+2
    and #<$4000-1>>$10
    sta __145+2
    lda flash_rom_address_sector+3
    and #>$4000-1>>$10
    sta __145+3
    // if (!(flash_rom_address_sector % 0x4000))
    // [311] if(0!=main::$145) goto main::@38 -- 0_neq_vdum1_then_la1 
    lda __145
    ora __145+1
    ora __145+2
    ora __145+3
    beq !__b38+
    jmp __b38
  !__b38:
    // main::@49
    // y_sector++;
    // [312] main::y_sector1#1 = ++ main::y_sector1#13 -- vbum1=_inc_vbum1 
    inc y_sector1
    // [270] phi from main::@49 to main::@38 [phi:main::@49->main::@38]
    // [270] phi main::y_sector1#13 = main::y_sector1#1 [phi:main::@49->main::@38#0] -- register_copy 
    // [270] phi main::x_sector1#10 = $e [phi:main::@49->main::@38#1] -- vbum1=vbuc1 
    lda #$e
    sta x_sector1
    // [270] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@49->main::@38#2] -- register_copy 
    // [270] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@49->main::@38#3] -- register_copy 
    // [270] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@49->main::@38#4] -- register_copy 
    jmp __b38
    // main::@41
  __b41:
    // rom_sector_erase(flash_rom_address_sector)
    // [313] rom_sector_erase::address#0 = main::flash_rom_address_sector#11 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta rom_sector_erase.address
    lda flash_rom_address_sector+1
    sta rom_sector_erase.address+1
    lda flash_rom_address_sector+2
    sta rom_sector_erase.address+2
    lda flash_rom_address_sector+3
    sta rom_sector_erase.address+3
    // [314] call rom_sector_erase
    // [1004] phi from main::@41 to rom_sector_erase [phi:main::@41->rom_sector_erase]
    jsr rom_sector_erase
    // main::@148
    // unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR
    // [315] main::flash_rom_address_boundary1#0 = main::flash_rom_address_sector#11 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [316] gotoxy::x#23 = main::x_sector1#10 -- vbum1=vbum2 
    lda x_sector1
    sta gotoxy.x
    // [317] gotoxy::y#23 = main::y_sector1#13 -- vbum1=vbum2 
    lda y_sector1
    sta gotoxy.y
    // [318] call gotoxy
    // [463] phi from main::@148 to gotoxy [phi:main::@148->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#23 [phi:main::@148->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = gotoxy::x#23 [phi:main::@148->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [319] phi from main::@148 to main::@149 [phi:main::@148->main::@149]
    // main::@149
    // printf("................")
    // [320] call printf_str
    // [693] phi from main::@149 to printf_str [phi:main::@149->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:main::@149->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = main::s15 [phi:main::@149->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@150
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [321] print_address::bram_bank#1 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta print_address.bram_bank
    // [322] print_address::bram_ptr#1 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z print_address.bram_ptr
    lda.z read_ram_address_sector+1
    sta.z print_address.bram_ptr+1
    // [323] print_address::brom_address#1 = main::flash_rom_address_sector#11 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta print_address.brom_address
    lda flash_rom_address_sector+1
    sta print_address.brom_address+1
    lda flash_rom_address_sector+2
    sta print_address.brom_address+2
    lda flash_rom_address_sector+3
    sta print_address.brom_address+3
    // [324] call print_address
    // [1016] phi from main::@150 to print_address [phi:main::@150->print_address]
    // [1016] phi print_address::bram_ptr#10 = print_address::bram_ptr#1 [phi:main::@150->print_address#0] -- register_copy 
    // [1016] phi print_address::bram_bank#10 = print_address::bram_bank#1 [phi:main::@150->print_address#1] -- register_copy 
    // [1016] phi print_address::brom_address#10 = print_address::brom_address#1 [phi:main::@150->print_address#2] -- register_copy 
    jsr print_address
    // main::@151
    // [325] main::flash_rom_address2#16 = main::flash_rom_address_sector#11 -- vdum1=vdum2 
    lda flash_rom_address_sector
    sta flash_rom_address2
    lda flash_rom_address_sector+1
    sta flash_rom_address2+1
    lda flash_rom_address_sector+2
    sta flash_rom_address2+2
    lda flash_rom_address_sector+3
    sta flash_rom_address2+3
    // [326] main::read_ram_address1#16 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z read_ram_address1
    lda.z read_ram_address_sector+1
    sta.z read_ram_address1+1
    // [327] main::x1#16 = main::x_sector1#10 -- vbum1=vbum2 
    lda x_sector1
    sta x1
    // [328] phi from main::@151 main::@156 to main::@42 [phi:main::@151/main::@156->main::@42]
    // [328] phi main::x1#10 = main::x1#16 [phi:main::@151/main::@156->main::@42#0] -- register_copy 
    // [328] phi main::read_ram_address1#10 = main::read_ram_address1#16 [phi:main::@151/main::@156->main::@42#1] -- register_copy 
    // [328] phi main::flash_rom_address2#11 = main::flash_rom_address2#16 [phi:main::@151/main::@156->main::@42#2] -- register_copy 
    // main::@42
  __b42:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [329] if(main::flash_rom_address2#11<main::flash_rom_address_boundary1#0) goto main::@43 -- vdum1_lt_vdum2_then_la1 
    lda flash_rom_address2+3
    cmp flash_rom_address_boundary1+3
    bcc __b43
    bne !+
    lda flash_rom_address2+2
    cmp flash_rom_address_boundary1+2
    bcc __b43
    bne !+
    lda flash_rom_address2+1
    cmp flash_rom_address_boundary1+1
    bcc __b43
    bne !+
    lda flash_rom_address2
    cmp flash_rom_address_boundary1
    bcc __b43
  !:
    jmp __b40
    // main::@43
  __b43:
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [330] print_address::bram_bank#2 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta print_address.bram_bank
    // [331] print_address::bram_ptr#2 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z print_address.bram_ptr
    lda.z read_ram_address1+1
    sta.z print_address.bram_ptr+1
    // [332] print_address::brom_address#2 = main::flash_rom_address2#11 -- vdum1=vdum2 
    lda flash_rom_address2
    sta print_address.brom_address
    lda flash_rom_address2+1
    sta print_address.brom_address+1
    lda flash_rom_address2+2
    sta print_address.brom_address+2
    lda flash_rom_address2+3
    sta print_address.brom_address+3
    // [333] call print_address
    // [1016] phi from main::@43 to print_address [phi:main::@43->print_address]
    // [1016] phi print_address::bram_ptr#10 = print_address::bram_ptr#2 [phi:main::@43->print_address#0] -- register_copy 
    // [1016] phi print_address::bram_bank#10 = print_address::bram_bank#2 [phi:main::@43->print_address#1] -- register_copy 
    // [1016] phi print_address::brom_address#10 = print_address::brom_address#2 [phi:main::@43->print_address#2] -- register_copy 
    jsr print_address
    // main::@152
    // unsigned long written_bytes = flash_write(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address)
    // [334] flash_write::flash_ram_bank#0 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta flash_write.flash_ram_bank
    // [335] flash_write::flash_ram_address#1 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_write.flash_ram_address
    lda.z read_ram_address1+1
    sta.z flash_write.flash_ram_address+1
    // [336] flash_write::flash_rom_address#1 = main::flash_rom_address2#11 -- vdum1=vdum2 
    lda flash_rom_address2
    sta flash_write.flash_rom_address
    lda flash_rom_address2+1
    sta flash_write.flash_rom_address+1
    lda flash_rom_address2+2
    sta flash_write.flash_rom_address+2
    lda flash_rom_address2+3
    sta flash_write.flash_rom_address+3
    // [337] call flash_write
    jsr flash_write
    // main::@153
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [338] flash_verify::bank_ram#2 = main::read_ram_bank_sector#13 -- vbum1=vbum2 
    lda read_ram_bank_sector
    sta flash_verify.bank_ram
    // [339] flash_verify::ptr_ram#3 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address1+1
    sta.z flash_verify.ptr_ram+1
    // [340] flash_verify::verify_rom_address#2 = main::flash_rom_address2#11 -- vdum1=vdum2 
    lda flash_rom_address2
    sta flash_verify.verify_rom_address
    lda flash_rom_address2+1
    sta flash_verify.verify_rom_address+1
    lda flash_rom_address2+2
    sta flash_verify.verify_rom_address+2
    lda flash_rom_address2+3
    sta flash_verify.verify_rom_address+3
    // [341] call flash_verify
    // [977] phi from main::@153 to flash_verify [phi:main::@153->flash_verify]
    // [977] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#3 [phi:main::@153->flash_verify#0] -- register_copy 
    // [977] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@153->flash_verify#1] -- vwum1=vwuc1 
    lda #<$100
    sta flash_verify.verify_rom_size
    lda #>$100
    sta flash_verify.verify_rom_size+1
    // [977] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#2 [phi:main::@153->flash_verify#2] -- register_copy 
    // [977] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#2 [phi:main::@153->flash_verify#3] -- register_copy 
    jsr flash_verify
    // main::@44
    // read_ram_address += 0x0100
    // [342] main::read_ram_address1#1 = main::read_ram_address1#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address1
    clc
    adc #<$100
    sta.z read_ram_address1
    lda.z read_ram_address1+1
    adc #>$100
    sta.z read_ram_address1+1
    // flash_rom_address += 0x0100
    // [343] main::flash_rom_address2#1 = main::flash_rom_address2#11 + $100 -- vdum1=vdum1_plus_vwuc1 
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
    // [344] call textcolor
    // [445] phi from main::@44 to textcolor [phi:main::@44->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:main::@44->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@154
    // gotoxy(x, y)
    // [345] gotoxy::x#24 = main::x1#10 -- vbum1=vbum2 
    lda x1
    sta gotoxy.x
    // [346] gotoxy::y#24 = main::y_sector1#13 -- vbum1=vbum2 
    lda y_sector1
    sta gotoxy.y
    // [347] call gotoxy
    // [463] phi from main::@154 to gotoxy [phi:main::@154->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#24 [phi:main::@154->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = gotoxy::x#24 [phi:main::@154->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [348] phi from main::@154 to main::@155 [phi:main::@154->main::@155]
    // main::@155
    // printf("%s", pattern)
    // [349] call printf_string
    // [742] phi from main::@155 to printf_string [phi:main::@155->printf_string]
    // [742] phi printf_string::str#12 = main::pattern1#3 [phi:main::@155->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern1_1
    sta.z printf_string.str
    lda #>pattern1_1
    sta.z printf_string.str+1
    // [742] phi printf_string::format_min_length#12 = 0 [phi:main::@155->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@156
    // x++;
    // [350] main::x1#1 = ++ main::x1#10 -- vbum1=_inc_vbum1 
    inc x1
    jmp __b42
    // main::@30
  __b30:
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [351] flash_verify::bank_ram#0 = main::read_ram_bank#13 -- vbum1=vbum2 
    lda read_ram_bank
    sta flash_verify.bank_ram
    // [352] flash_verify::ptr_ram#1 = main::read_ram_address#10 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address+1
    sta.z flash_verify.ptr_ram+1
    // [353] flash_verify::verify_rom_address#0 = main::flash_rom_address1#13 -- vdum1=vdum2 
    lda flash_rom_address1
    sta flash_verify.verify_rom_address
    lda flash_rom_address1+1
    sta flash_verify.verify_rom_address+1
    lda flash_rom_address1+2
    sta flash_verify.verify_rom_address+2
    lda flash_rom_address1+3
    sta flash_verify.verify_rom_address+3
    // [354] call flash_verify
    // [977] phi from main::@30 to flash_verify [phi:main::@30->flash_verify]
    // [977] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#1 [phi:main::@30->flash_verify#0] -- register_copy 
    // [977] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@30->flash_verify#1] -- vwum1=vwuc1 
    lda #<$100
    sta flash_verify.verify_rom_size
    lda #>$100
    sta flash_verify.verify_rom_size+1
    // [977] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#0 [phi:main::@30->flash_verify#2] -- register_copy 
    // [977] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#0 [phi:main::@30->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [355] flash_verify::return#2 = flash_verify::correct_bytes#2
    // main::@130
    // [356] main::equal_bytes#0 = flash_verify::return#2
    // if (equal_bytes != 0x0100)
    // [357] if(main::equal_bytes#0!=$100) goto main::@32 -- vwum1_neq_vwuc1_then_la1 
    // unsigned long equal_bytes = 0x100;
    lda equal_bytes+1
    cmp #>$100
    bne __b32
    lda equal_bytes
    cmp #<$100
    bne __b32
    // [359] phi from main::@130 to main::@33 [phi:main::@130->main::@33]
    // [359] phi main::pattern#3 = main::s2 [phi:main::@130->main::@33#0] -- pbuz1=pbuc1 
    lda #<s2
    sta.z pattern
    lda #>s2
    sta.z pattern+1
    jmp __b33
    // [358] phi from main::@130 to main::@32 [phi:main::@130->main::@32]
    // main::@32
  __b32:
    // [359] phi from main::@32 to main::@33 [phi:main::@32->main::@33]
    // [359] phi main::pattern#3 = main::pattern#1 [phi:main::@32->main::@33#0] -- pbuz1=pbuc1 
    lda #<pattern_1
    sta.z pattern
    lda #>pattern_1
    sta.z pattern+1
    // main::@33
  __b33:
    // read_ram_address += 0x0100
    // [360] main::read_ram_address#1 = main::read_ram_address#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address
    clc
    adc #<$100
    sta.z read_ram_address
    lda.z read_ram_address+1
    adc #>$100
    sta.z read_ram_address+1
    // flash_rom_address += 0x0100
    // [361] main::flash_rom_address1#1 = main::flash_rom_address1#13 + $100 -- vdum1=vdum1_plus_vwuc1 
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
    // [362] print_address::bram_bank#0 = main::read_ram_bank#13 -- vbum1=vbum2 
    lda read_ram_bank
    sta print_address.bram_bank
    // [363] print_address::bram_ptr#0 = main::read_ram_address#1 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z print_address.bram_ptr
    lda.z read_ram_address+1
    sta.z print_address.bram_ptr+1
    // [364] print_address::brom_address#0 = main::flash_rom_address1#1 -- vdum1=vdum2 
    lda flash_rom_address1
    sta print_address.brom_address
    lda flash_rom_address1+1
    sta print_address.brom_address+1
    lda flash_rom_address1+2
    sta print_address.brom_address+2
    lda flash_rom_address1+3
    sta print_address.brom_address+3
    // [365] call print_address
    // [1016] phi from main::@33 to print_address [phi:main::@33->print_address]
    // [1016] phi print_address::bram_ptr#10 = print_address::bram_ptr#0 [phi:main::@33->print_address#0] -- register_copy 
    // [1016] phi print_address::bram_bank#10 = print_address::bram_bank#0 [phi:main::@33->print_address#1] -- register_copy 
    // [1016] phi print_address::brom_address#10 = print_address::brom_address#0 [phi:main::@33->print_address#2] -- register_copy 
    jsr print_address
    // [366] phi from main::@33 to main::@141 [phi:main::@33->main::@141]
    // main::@141
    // textcolor(WHITE)
    // [367] call textcolor
    // [445] phi from main::@141 to textcolor [phi:main::@141->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:main::@141->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@142
    // gotoxy(x_sector, y_sector)
    // [368] gotoxy::x#21 = main::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [369] gotoxy::y#21 = main::y_sector#10 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [370] call gotoxy
    // [463] phi from main::@142 to gotoxy [phi:main::@142->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#21 [phi:main::@142->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = gotoxy::x#21 [phi:main::@142->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@143
    // printf("%s", pattern)
    // [371] printf_string::str#9 = main::pattern#3 -- pbuz1=pbuz2 
    lda.z pattern
    sta.z printf_string.str
    lda.z pattern+1
    sta.z printf_string.str+1
    // [372] call printf_string
    // [742] phi from main::@143 to printf_string [phi:main::@143->printf_string]
    // [742] phi printf_string::str#12 = printf_string::str#9 [phi:main::@143->printf_string#0] -- register_copy 
    // [742] phi printf_string::format_min_length#12 = 0 [phi:main::@143->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@144
    // x_sector++;
    // [373] main::x_sector#1 = ++ main::x_sector#10 -- vbum1=_inc_vbum1 
    inc x_sector
    // if (read_ram_address == 0x8000)
    // [374] if(main::read_ram_address#1!=$8000) goto main::@166 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$8000
    bne __b34
    lda.z read_ram_address
    cmp #<$8000
    bne __b34
    // [376] phi from main::@144 to main::@34 [phi:main::@144->main::@34]
    // [376] phi main::read_ram_bank#5 = 1 [phi:main::@144->main::@34#0] -- vbum1=vbuc1 
    lda #1
    sta read_ram_bank
    // [376] phi main::read_ram_address#7 = (char *) 40960 [phi:main::@144->main::@34#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [375] phi from main::@144 to main::@166 [phi:main::@144->main::@166]
    // main::@166
    // [376] phi from main::@166 to main::@34 [phi:main::@166->main::@34]
    // [376] phi main::read_ram_bank#5 = main::read_ram_bank#13 [phi:main::@166->main::@34#0] -- register_copy 
    // [376] phi main::read_ram_address#7 = main::read_ram_address#1 [phi:main::@166->main::@34#1] -- register_copy 
    // main::@34
  __b34:
    // if (read_ram_address == 0xC000)
    // [377] if(main::read_ram_address#7!=$c000) goto main::@35 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$c000
    bne __b35
    lda.z read_ram_address
    cmp #<$c000
    bne __b35
    // main::@36
    // read_ram_bank++;
    // [378] main::read_ram_bank#2 = ++ main::read_ram_bank#5 -- vbum1=_inc_vbum1 
    inc read_ram_bank
    // [379] phi from main::@36 to main::@35 [phi:main::@36->main::@35]
    // [379] phi main::read_ram_address#12 = (char *) 40960 [phi:main::@36->main::@35#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [379] phi main::read_ram_bank#10 = main::read_ram_bank#2 [phi:main::@36->main::@35#1] -- register_copy 
    // [379] phi from main::@34 to main::@35 [phi:main::@34->main::@35]
    // [379] phi main::read_ram_address#12 = main::read_ram_address#7 [phi:main::@34->main::@35#0] -- register_copy 
    // [379] phi main::read_ram_bank#10 = main::read_ram_bank#5 [phi:main::@34->main::@35#1] -- register_copy 
    // main::@35
  __b35:
    // flash_rom_address % 0x4000
    // [380] main::$107 = main::flash_rom_address1#1 & $4000-1 -- vdum1=vdum2_band_vduc1 
    lda flash_rom_address1
    and #<$4000-1
    sta __107
    lda flash_rom_address1+1
    and #>$4000-1
    sta __107+1
    lda flash_rom_address1+2
    and #<$4000-1>>$10
    sta __107+2
    lda flash_rom_address1+3
    and #>$4000-1>>$10
    sta __107+3
    // if (!(flash_rom_address % 0x4000))
    // [381] if(0!=main::$107) goto main::@29 -- 0_neq_vdum1_then_la1 
    lda __107
    ora __107+1
    ora __107+2
    ora __107+3
    beq !__b29+
    jmp __b29
  !__b29:
    // main::@37
    // y_sector++;
    // [382] main::y_sector#1 = ++ main::y_sector#10 -- vbum1=_inc_vbum1 
    inc y_sector
    // [239] phi from main::@37 to main::@29 [phi:main::@37->main::@29]
    // [239] phi main::y_sector#10 = main::y_sector#1 [phi:main::@37->main::@29#0] -- register_copy 
    // [239] phi main::x_sector#10 = $e [phi:main::@37->main::@29#1] -- vbum1=vbuc1 
    lda #$e
    sta x_sector
    // [239] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@37->main::@29#2] -- register_copy 
    // [239] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@37->main::@29#3] -- register_copy 
    // [239] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@37->main::@29#4] -- register_copy 
    jmp __b29
    // main::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [383] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [384] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // if (flash_rom_address == 0x0)
    // [385] if(main::flash_rom_address#10!=0) goto main::@3 -- vdum1_neq_0_then_la1 
    lda flash_rom_address
    ora flash_rom_address+1
    ora flash_rom_address+2
    ora flash_rom_address+3
    bne __b3
    // main::@14
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [386] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [387] main::rom_device_ids[main::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // main::@3
  __b3:
    // if (flash_rom_address == 0x80000)
    // [388] if(main::flash_rom_address#10!=$80000) goto main::@4 -- vdum1_neq_vduc1_then_la1 
    lda flash_rom_address+3
    cmp #>$80000>>$10
    bne __b4
    lda flash_rom_address+2
    cmp #<$80000>>$10
    bne __b4
    lda flash_rom_address+1
    cmp #>$80000
    bne __b4
    lda flash_rom_address
    cmp #<$80000
    bne __b4
    // main::@15
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [389] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [390] main::rom_device_ids[main::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // main::@4
  __b4:
    // if (flash_rom_address == 0x100000)
    // [391] if(main::flash_rom_address#10!=$100000) goto main::@5 -- vdum1_neq_vduc1_then_la1 
    lda flash_rom_address+3
    cmp #>$100000>>$10
    bne __b5
    lda flash_rom_address+2
    cmp #<$100000>>$10
    bne __b5
    lda flash_rom_address+1
    cmp #>$100000
    bne __b5
    lda flash_rom_address
    cmp #<$100000
    bne __b5
    // main::@16
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [392] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF020A
    // [393] main::rom_device_ids[main::rom_chip#10] = $b6 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b6
    sta rom_device_ids,y
    // main::@5
  __b5:
    // if (flash_rom_address == 0x180000)
    // [394] if(main::flash_rom_address#10!=$180000) goto main::@6 -- vdum1_neq_vduc1_then_la1 
    lda flash_rom_address+3
    cmp #>$180000>>$10
    bne __b6
    lda flash_rom_address+2
    cmp #<$180000>>$10
    bne __b6
    lda flash_rom_address+1
    cmp #>$180000
    bne __b6
    lda flash_rom_address
    cmp #<$180000
    bne __b6
    // main::@17
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [395] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF010A
    // [396] main::rom_device_ids[main::rom_chip#10] = $b5 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b5
    sta rom_device_ids,y
    // main::@6
  __b6:
    // if (flash_rom_address == 0x200000)
    // [397] if(main::flash_rom_address#10!=$200000) goto main::@7 -- vdum1_neq_vduc1_then_la1 
    lda flash_rom_address+3
    cmp #>$200000>>$10
    bne __b7
    lda flash_rom_address+2
    cmp #<$200000>>$10
    bne __b7
    lda flash_rom_address+1
    cmp #>$200000
    bne __b7
    lda flash_rom_address
    cmp #<$200000
    bne __b7
    // main::@18
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [398] main::rom_manufacturer_ids[main::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [399] main::rom_device_ids[main::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // [400] phi from main::@18 main::@6 to main::@7 [phi:main::@18/main::@6->main::@7]
    // main::@7
  __b7:
    // bank_set_brom(4)
    // [401] call bank_set_brom
  // Ensure the ROM is set to BASIC.
    // [769] phi from main::@7 to bank_set_brom [phi:main::@7->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 4 [phi:main::@7->bank_set_brom#0] -- vbum1=vbuc1 
    lda #4
    sta bank_set_brom.bank
    jsr bank_set_brom
    // main::@80
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_KB(rom_chip, "128");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [402] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@8 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip
    lda rom_device_ids,y
    cmp #$b5
    bne !__b8+
    jmp __b8
  !__b8:
    // main::@19
    // case SST39SF020A:
    //             rom_device = "f020a";
    //             print_chip_KB(rom_chip, "256");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             rom_sizes[rom_chip] = 256 * 1024;
    //             break;
    // [403] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@9 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b6
    bne !__b9+
    jmp __b9
  !__b9:
    // main::@20
    // case SST39SF040:
    //             rom_device = "f040";
    //             print_chip_KB(rom_chip, "512");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             rom_sizes[rom_chip] = 512 * 1024;
    //             break;
    // [404] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@10 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b10+
    jmp __b10
  !__b10:
    // main::@11
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [405] print_chip_led::r#4 = main::rom_chip#10 -- vbum1=vbum2 
    tya
    sta print_chip_led.r
    // [406] call print_chip_led
    // [872] phi from main::@11 to print_chip_led [phi:main::@11->print_chip_led]
    // [872] phi print_chip_led::tc#10 = BLACK [phi:main::@11->print_chip_led#0] -- vbum1=vbuc1 
    lda #BLACK
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#4 [phi:main::@11->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@87
    // rom_device_ids[rom_chip] = UNKNOWN
    // [407] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // [408] phi from main::@87 to main::@12 [phi:main::@87->main::@12]
    // [408] phi main::rom_device#5 = main::rom_device#10 [phi:main::@87->main::@12#0] -- pbuz1=pbuc1 
    lda #<rom_device_4
    sta.z rom_device
    lda #>rom_device_4
    sta.z rom_device+1
    // main::@12
  __b12:
    // textcolor(WHITE)
    // [409] call textcolor
    // [445] phi from main::@12 to textcolor [phi:main::@12->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:main::@12->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // main::@88
    // rom_chip * 10
    // [410] main::$190 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __190
    // [411] main::$191 = main::$190 + main::rom_chip#10 -- vbum1=vbum1_plus_vbum2 
    lda __191
    clc
    adc rom_chip
    sta __191
    // [412] main::$42 = main::$191 << 1 -- vbum1=vbum1_rol_1 
    asl __42
    // gotoxy(2 + rom_chip * 10, 56)
    // [413] gotoxy::x#15 = 2 + main::$42 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc __42
    sta gotoxy.x
    // [414] call gotoxy
    // [463] phi from main::@88 to gotoxy [phi:main::@88->gotoxy]
    // [463] phi gotoxy::y#25 = $38 [phi:main::@88->gotoxy#0] -- vbum1=vbuc1 
    lda #$38
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = gotoxy::x#15 [phi:main::@88->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@89
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [415] printf_uchar::uvalue#3 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_manufacturer_ids,y
    sta printf_uchar.uvalue
    // [416] call printf_uchar
    // [892] phi from main::@89 to printf_uchar [phi:main::@89->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@89->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 0 [phi:main::@89->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:main::@89->printf_uchar#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#3 [phi:main::@89->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // main::@90
    // gotoxy(2 + rom_chip * 10, 57)
    // [417] gotoxy::x#16 = 2 + main::$42 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc __42
    sta gotoxy.x
    // [418] call gotoxy
    // [463] phi from main::@90 to gotoxy [phi:main::@90->gotoxy]
    // [463] phi gotoxy::y#25 = $39 [phi:main::@90->gotoxy#0] -- vbum1=vbuc1 
    lda #$39
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = gotoxy::x#16 [phi:main::@90->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@91
    // printf("%s", rom_device)
    // [419] printf_string::str#5 = main::rom_device#5 -- pbuz1=pbuz2 
    lda.z rom_device
    sta.z printf_string.str
    lda.z rom_device+1
    sta.z printf_string.str+1
    // [420] call printf_string
    // [742] phi from main::@91 to printf_string [phi:main::@91->printf_string]
    // [742] phi printf_string::str#12 = printf_string::str#5 [phi:main::@91->printf_string#0] -- register_copy 
    // [742] phi printf_string::format_min_length#12 = 0 [phi:main::@91->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // main::@92
    // rom_chip++;
    // [421] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // main::@13
    // flash_rom_address += 0x80000
    // [422] main::flash_rom_address#1 = main::flash_rom_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [81] phi from main::@13 to main::@1 [phi:main::@13->main::@1]
    // [81] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@13->main::@1#0] -- register_copy 
    // [81] phi main::flash_rom_address#10 = main::flash_rom_address#1 [phi:main::@13->main::@1#1] -- register_copy 
    jmp __b1
    // main::@10
  __b10:
    // print_chip_KB(rom_chip, "512")
    // [423] print_chip_KB::rom_chip#2 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_KB.rom_chip
    // [424] call print_chip_KB
    // [1062] phi from main::@10 to print_chip_KB [phi:main::@10->print_chip_KB]
    // [1062] phi print_chip_KB::kb#3 = main::kb2 [phi:main::@10->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb2
    sta.z print_chip_KB.kb
    lda #>kb2
    sta.z print_chip_KB.kb+1
    // [1062] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#2 [phi:main::@10->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@85
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [425] print_chip_led::r#3 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_led.r
    // [426] call print_chip_led
    // [872] phi from main::@85 to print_chip_led [phi:main::@85->print_chip_led]
    // [872] phi print_chip_led::tc#10 = WHITE [phi:main::@85->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#3 [phi:main::@85->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@86
    // rom_sizes[rom_chip] = 512 * 1024
    // [427] main::$171 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __171
    // [428] main::rom_sizes[main::$171] = (unsigned long)$200*$400 -- pduc1_derefidx_vbum1=vduc2 
    tay
    lda #<$200*$400
    sta rom_sizes,y
    lda #>$200*$400
    sta rom_sizes+1,y
    lda #<$200*$400>>$10
    sta rom_sizes+2,y
    lda #>$200*$400>>$10
    sta rom_sizes+3,y
    // [408] phi from main::@86 to main::@12 [phi:main::@86->main::@12]
    // [408] phi main::rom_device#5 = main::rom_device#13 [phi:main::@86->main::@12#0] -- pbuz1=pbuc1 
    lda #<rom_device_3
    sta.z rom_device
    lda #>rom_device_3
    sta.z rom_device+1
    jmp __b12
    // main::@9
  __b9:
    // print_chip_KB(rom_chip, "256")
    // [429] print_chip_KB::rom_chip#1 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_KB.rom_chip
    // [430] call print_chip_KB
    // [1062] phi from main::@9 to print_chip_KB [phi:main::@9->print_chip_KB]
    // [1062] phi print_chip_KB::kb#3 = main::kb1 [phi:main::@9->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb1
    sta.z print_chip_KB.kb
    lda #>kb1
    sta.z print_chip_KB.kb+1
    // [1062] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#1 [phi:main::@9->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@83
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [431] print_chip_led::r#2 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_led.r
    // [432] call print_chip_led
    // [872] phi from main::@83 to print_chip_led [phi:main::@83->print_chip_led]
    // [872] phi print_chip_led::tc#10 = WHITE [phi:main::@83->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#2 [phi:main::@83->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@84
    // rom_sizes[rom_chip] = 256 * 1024
    // [433] main::$170 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __170
    // [434] main::rom_sizes[main::$170] = (unsigned long)$100*$400 -- pduc1_derefidx_vbum1=vduc2 
    tay
    lda #<$100*$400
    sta rom_sizes,y
    lda #>$100*$400
    sta rom_sizes+1,y
    lda #<$100*$400>>$10
    sta rom_sizes+2,y
    lda #>$100*$400>>$10
    sta rom_sizes+3,y
    // [408] phi from main::@84 to main::@12 [phi:main::@84->main::@12]
    // [408] phi main::rom_device#5 = main::rom_device#12 [phi:main::@84->main::@12#0] -- pbuz1=pbuc1 
    lda #<rom_device_2
    sta.z rom_device
    lda #>rom_device_2
    sta.z rom_device+1
    jmp __b12
    // main::@8
  __b8:
    // print_chip_KB(rom_chip, "128")
    // [435] print_chip_KB::rom_chip#0 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_KB.rom_chip
    // [436] call print_chip_KB
    // [1062] phi from main::@8 to print_chip_KB [phi:main::@8->print_chip_KB]
    // [1062] phi print_chip_KB::kb#3 = main::kb [phi:main::@8->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb
    sta.z print_chip_KB.kb
    lda #>kb
    sta.z print_chip_KB.kb+1
    // [1062] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#0 [phi:main::@8->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@81
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [437] print_chip_led::r#1 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta print_chip_led.r
    // [438] call print_chip_led
    // [872] phi from main::@81 to print_chip_led [phi:main::@81->print_chip_led]
    // [872] phi print_chip_led::tc#10 = WHITE [phi:main::@81->print_chip_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#1 [phi:main::@81->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@82
    // rom_sizes[rom_chip] = 128 * 1024
    // [439] main::$169 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __169
    // [440] main::rom_sizes[main::$169] = (unsigned long)$80*$400 -- pduc1_derefidx_vbum1=vduc2 
    tay
    lda #<$80*$400
    sta rom_sizes,y
    lda #>$80*$400
    sta rom_sizes+1,y
    lda #<$80*$400>>$10
    sta rom_sizes+2,y
    lda #>$80*$400>>$10
    sta rom_sizes+3,y
    // [408] phi from main::@82 to main::@12 [phi:main::@82->main::@12]
    // [408] phi main::rom_device#5 = main::rom_device#1 [phi:main::@82->main::@12#0] -- pbuz1=pbuc1 
    lda #<rom_device_1
    sta.z rom_device
    lda #>rom_device_1
    sta.z rom_device+1
    jmp __b12
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
    pattern1: .text "----------------"
    .byte 0
    pattern1_1: .text "+"
    .byte 0
    .label __42 = __190
    __56: .byte 0
    .label __66 = __196
    .label __73 = __194
    __107: .dword 0
    __145: .dword 0
    __169: .byte 0
    __170: .byte 0
    __171: .byte 0
    __172: .byte 0
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
    flash_rom_address2: .dword 0
    x1: .byte 0
    x_sector1: .byte 0
    read_ram_bank_sector: .byte 0
    y_sector1: .byte 0
    v: .word 0
    w: .word 0
    .label flash_rom_address_boundary_2 = flash_bytes_1
    __190: .byte 0
    .label __191 = __190
    __194: .byte 0
    __196: .byte 0
    .label __197 = __196
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [441] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [442] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [443] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [444] return 
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
    // [446] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbum1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta __0
    // __conio.color & 0xF0 | color
    // [447] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbum1=vbum2_bor_vbum1 
    lda __1
    ora __0
    sta __1
    // __conio.color = __conio.color & 0xF0 | color
    // [448] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbum1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [449] return 
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
    // [451] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbum1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta __0
    // color << 4
    // [452] bgcolor::$1 = bgcolor::color#11 << 4 -- vbum1=vbum1_rol_4 
    lda __1
    asl
    asl
    asl
    asl
    sta __1
    // __conio.color & 0x0F | color << 4
    // [453] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbum1=vbum1_bor_vbum2 
    lda __2
    ora __1
    sta __2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [454] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbum1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [455] return 
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
    // [456] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [457] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [458] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [459] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [461] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [462] return 
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
    // [464] if(gotoxy::x#25>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [466] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [466] phi gotoxy::$3 = gotoxy::x#25 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [465] gotoxy::$2 = *((char *)&__conio+6) -- vbum1=_deref_pbuc1 
    lda __conio+6
    sta __2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [467] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbum1 
    lda __3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [468] if(gotoxy::y#25>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [469] gotoxy::$14 = gotoxy::y#25 -- vbum1=vbum2 
    sta __14
    // [470] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [470] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [471] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbum1 
    lda __7
    sta __conio+1
    // __conio.cursor_x << 1
    // [472] gotoxy::$8 = *((char *)&__conio) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta __8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [473] gotoxy::$10 = gotoxy::y#25 << 1 -- vbum1=vbum1_rol_1 
    asl __10
    // [474] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwum1=pwuc1_derefidx_vbum2_plus_vbum3 
    ldy __10
    clc
    adc __conio+$15,y
    sta __9
    lda __conio+$15+1,y
    adc #0
    sta __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [475] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwum1 
    lda __9
    sta __conio+$13
    lda __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [476] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [477] gotoxy::$6 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
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
    // [478] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [479] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [480] cputln::$3 = *((char *)&__conio+1) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta __3
    // [481] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$3] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // if(__conio.scroll[__conio.layer])
    // [482] if(0==((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cputln::@return -- 0_eq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    beq __breturn
    // [483] phi from cputln to cputln::@1 [phi:cputln->cputln::@1]
    // cputln::@1
    // cscroll()
    // [484] call cscroll
    jsr cscroll
    // cputln::@return
  __breturn:
    // }
    // [485] return 
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
// void cbm_x_charset(__mem() volatile char charset, __zp($4e) char * volatile offset)
cbm_x_charset: {
    .label offset = $4e
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_CHRSET  }
    lda charset
    ldx.z <offset
    ldy.z >offset
    jsr CX16_CHRSET
    // cbm_x_charset::@return
    // }
    // [487] return 
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
    // [488] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [489] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    // unsigned int line_text = __conio.mapbase_offset
    // [490] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [491] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [492] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta __0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [493] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [494] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [495] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [495] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [495] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [496] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwum2 
    lda ch
    sta __1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [497] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [498] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwum2 
    lda ch+1
    sta __2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [499] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [500] clrscr::c#0 = *((char *)&__conio+8) -- vbum1=_deref_pbuc1 
    lda __conio+8
    sta c
    // [501] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [501] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [502] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [503] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [504] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [505] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [506] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [507] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [508] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [509] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [510] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [511] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [512] return 
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
    // [514] call textcolor
    // [445] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [515] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [516] call bgcolor
    // [450] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [517] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [518] call clrscr
    jsr clrscr
    // [519] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [519] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbum1=vbuc1 
    lda #0
    sta x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [520] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbum1_lt_vbuc1_then_la1 
    lda x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [521] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [522] call cputcxy
    // [1122] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [1122] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #$70
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbum1=vbuc1 
    sta cputcxy.x
    jsr cputcxy
    // [523] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [524] call cputcxy
    // [1122] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [1122] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbum1=vbuc1 
    lda #$6e
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // [525] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [526] call cputcxy
    // [1122] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbum1=vbuc1 
    lda #1
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // [527] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [528] call cputcxy
    // [1122] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbum1=vbuc1 
    lda #1
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // [529] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [529] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbum1=vbuc1 
    lda #0
    sta x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [530] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbum1_lt_vbuc1_then_la1 
    lda x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [531] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [532] call cputcxy
    // [1122] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [1122] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbum1=vbuc1 
    lda #$6b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbum1=vbuc1 
    lda #2
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // [533] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [534] call cputcxy
    // [1122] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [1122] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbum1=vbuc1 
    lda #2
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // [535] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [536] call cputcxy
    // [1122] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [1122] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbum1=vbuc1 
    lda #2
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbum1=vbuc1 
    lda #$c
    sta cputcxy.x
    jsr cputcxy
    // [537] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [537] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbum1=vbuc1 
    lda #3
    sta y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [538] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [539] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [539] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbum1=vbuc1 
    lda #0
    sta x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [540] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbum1_lt_vbuc1_then_la1 
    lda x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [541] cputcxy::y#13 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [542] call cputcxy
    // [1122] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [1122] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #$6b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [543] cputcxy::y#14 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [544] call cputcxy
    // [1122] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [1122] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [545] cputcxy::y#15 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [546] call cputcxy
    // [1122] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [1122] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbum1=vbuc1 
    lda #$c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [547] frame_draw::y#5 = ++ frame_draw::y#101 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [548] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [548] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [549] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbum1_lt_vbuc1_then_la1 
    lda y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [550] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [550] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbum1=vbuc1 
    lda #0
    sta x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [551] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbum1_lt_vbuc1_then_la1 
    lda x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [552] cputcxy::y#19 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [553] call cputcxy
    // [1122] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [1122] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbum1=vbuc1 
    lda #$6b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [554] cputcxy::y#20 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [555] call cputcxy
    // [1122] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [1122] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [556] cputcxy::y#21 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [557] call cputcxy
    // [1122] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [1122] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [558] cputcxy::y#22 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [559] call cputcxy
    // [1122] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [1122] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [560] cputcxy::y#23 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [561] call cputcxy
    // [1122] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [1122] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [562] cputcxy::y#24 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [563] call cputcxy
    // [1122] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [1122] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [564] cputcxy::y#25 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [565] call cputcxy
    // [1122] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [1122] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [566] cputcxy::y#26 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [567] call cputcxy
    // [1122] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [1122] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [568] cputcxy::y#27 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [569] call cputcxy
    // [1122] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [1122] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbum1=vbuc1 
    lda #$72
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [570] cputcxy::y#28 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [571] call cputcxy
    // [1122] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [1122] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [572] frame_draw::y#7 = ++ frame_draw::y#102 -- vbum1=_inc_vbum2 
    lda y_1
    inc
    sta y_2
    // [573] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [573] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [574] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbum1_lt_vbuc1_then_la1 
    lda y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [575] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [575] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbum1=vbuc1 
    lda #0
    sta x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [576] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbum1_lt_vbuc1_then_la1 
    lda x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [577] cputcxy::y#39 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [578] call cputcxy
    // [1122] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [1122] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbum1=vbuc1 
    lda #$6b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [579] cputcxy::y#40 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [580] call cputcxy
    // [1122] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [1122] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbum1=vbuc1 
    lda #$73
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [581] cputcxy::y#41 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [582] call cputcxy
    // [1122] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [1122] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [583] cputcxy::y#42 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [584] call cputcxy
    // [1122] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [1122] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [585] cputcxy::y#43 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [586] call cputcxy
    // [1122] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [1122] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [587] cputcxy::y#44 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [588] call cputcxy
    // [1122] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [1122] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [589] cputcxy::y#45 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [590] call cputcxy
    // [1122] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [1122] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [591] cputcxy::y#46 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [592] call cputcxy
    // [1122] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [1122] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [593] cputcxy::y#47 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [594] call cputcxy
    // [1122] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [1122] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbum1=vbuc1 
    lda #$5b
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [595] frame_draw::y#9 = ++ frame_draw::y#104 -- vbum1=_inc_vbum2 
    lda y_2
    inc
    sta y_3
    // [596] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [596] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [597] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbum1_lt_vbuc1_then_la1 
    lda y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [598] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [598] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbum1=vbuc1 
    lda #0
    sta x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [599] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbum1_lt_vbuc1_then_la1 
    lda x5
    cmp #$4f
    bcs !__b25+
    jmp __b25
  !__b25:
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [600] cputcxy::y#58 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [601] call cputcxy
    // [1122] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [1122] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbum1=vbuc1 
    lda #$6d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [602] cputcxy::y#59 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [603] call cputcxy
    // [1122] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [1122] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbum1=vbuc1 
    lda #$7d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [604] cputcxy::y#60 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [605] call cputcxy
    // [1122] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [1122] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [606] cputcxy::y#61 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [607] call cputcxy
    // [1122] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [1122] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [608] cputcxy::y#62 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [609] call cputcxy
    // [1122] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [1122] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [610] cputcxy::y#63 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [611] call cputcxy
    // [1122] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [1122] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [612] cputcxy::y#64 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [613] call cputcxy
    // [1122] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [1122] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [614] cputcxy::y#65 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [615] call cputcxy
    // [1122] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [1122] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [616] cputcxy::y#66 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [617] call cputcxy
    // [1122] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [1122] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbum1=vbuc1 
    lda #$71
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [618] cputcxy::y#67 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [619] call cputcxy
    // [1122] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [1122] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbum1=vbuc1 
    lda #$7d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@return
    // }
    // [620] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [621] cputcxy::x#57 = frame_draw::x5#2 -- vbum1=vbum2 
    lda x5
    sta cputcxy.x
    // [622] cputcxy::y#57 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [623] call cputcxy
    // [1122] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [1122] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [624] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbum1=_inc_vbum1 
    inc x5
    // [598] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [598] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [625] cputcxy::y#48 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [626] call cputcxy
    // [1122] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [627] cputcxy::y#49 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [628] call cputcxy
    // [1122] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [629] cputcxy::y#50 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [630] call cputcxy
    // [1122] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [631] cputcxy::y#51 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [632] call cputcxy
    // [1122] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [633] cputcxy::y#52 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [634] call cputcxy
    // [1122] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [635] cputcxy::y#53 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [636] call cputcxy
    // [1122] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [637] cputcxy::y#54 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [638] call cputcxy
    // [1122] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [639] cputcxy::y#55 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [640] call cputcxy
    // [1122] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [641] cputcxy::y#56 = frame_draw::y#106 -- vbum1=vbum2 
    lda y_3
    sta cputcxy.y
    // [642] call cputcxy
    // [1122] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [643] frame_draw::y#10 = ++ frame_draw::y#106 -- vbum1=_inc_vbum1 
    inc y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [644] cputcxy::x#38 = frame_draw::x4#2 -- vbum1=vbum2 
    lda x4
    sta cputcxy.x
    // [645] cputcxy::y#38 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [646] call cputcxy
    // [1122] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [1122] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [647] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbum1=_inc_vbum1 
    inc x4
    // [575] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [575] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [648] cputcxy::y#29 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [649] call cputcxy
    // [1122] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [650] cputcxy::y#30 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [651] call cputcxy
    // [1122] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [652] cputcxy::y#31 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [653] call cputcxy
    // [1122] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbum1=vbuc1 
    lda #$a
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [654] cputcxy::y#32 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [655] call cputcxy
    // [1122] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbum1=vbuc1 
    lda #$14
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [656] cputcxy::y#33 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [657] call cputcxy
    // [1122] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbum1=vbuc1 
    lda #$1e
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [658] cputcxy::y#34 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [659] call cputcxy
    // [1122] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbum1=vbuc1 
    lda #$28
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [660] cputcxy::y#35 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [661] call cputcxy
    // [1122] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbum1=vbuc1 
    lda #$32
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [662] cputcxy::y#36 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [663] call cputcxy
    // [1122] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbum1=vbuc1 
    lda #$3c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [664] cputcxy::y#37 = frame_draw::y#104 -- vbum1=vbum2 
    lda y_2
    sta cputcxy.y
    // [665] call cputcxy
    // [1122] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbum1=vbuc1 
    lda #$46
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [666] frame_draw::y#8 = ++ frame_draw::y#104 -- vbum1=_inc_vbum1 
    inc y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [667] cputcxy::x#18 = frame_draw::x3#2 -- vbum1=vbum2 
    lda x3
    sta cputcxy.x
    // [668] cputcxy::y#18 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [669] call cputcxy
    // [1122] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [1122] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [670] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbum1=_inc_vbum1 
    inc x3
    // [550] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [550] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [671] cputcxy::y#16 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [672] call cputcxy
    // [1122] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [673] cputcxy::y#17 = frame_draw::y#102 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [674] call cputcxy
    // [1122] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [675] frame_draw::y#6 = ++ frame_draw::y#102 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [676] cputcxy::x#12 = frame_draw::x2#2 -- vbum1=vbum2 
    lda x2
    sta cputcxy.x
    // [677] cputcxy::y#12 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [678] call cputcxy
    // [1122] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [1122] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [679] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbum1=_inc_vbum1 
    inc x2
    // [539] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [539] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [680] cputcxy::y#9 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [681] call cputcxy
    // [1122] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [682] cputcxy::y#10 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [683] call cputcxy
    // [1122] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbum1=vbuc1 
    lda #$c
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [684] cputcxy::y#11 = frame_draw::y#101 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [685] call cputcxy
    // [1122] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [1122] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbum1=vbuc1 
    lda #$5d
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [1122] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbum1=vbuc1 
    lda #$4f
    sta cputcxy.x
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [686] frame_draw::y#4 = ++ frame_draw::y#101 -- vbum1=_inc_vbum1 
    inc y
    // [537] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [537] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [687] cputcxy::x#5 = frame_draw::x1#2 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [688] call cputcxy
    // [1122] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [1122] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbum1=vbuc1 
    lda #2
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [689] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbum1=_inc_vbum1 
    inc x1
    // [529] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [529] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [690] cputcxy::x#0 = frame_draw::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [691] call cputcxy
    // [1122] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [1122] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$40
    sta cputcxy.c
    // [1122] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbum1=vbuc1 
    lda #0
    sta cputcxy.y
    // [1122] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [692] frame_draw::x#1 = ++ frame_draw::x#2 -- vbum1=_inc_vbum1 
    inc x
    // [519] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [519] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
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
// void printf_str(__zp($25) void (*putc)(char), __zp($29) const char *s)
printf_str: {
    .label s = $29
    .label putc = $25
    // [694] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [694] phi printf_str::s#33 = printf_str::s#34 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [695] printf_str::c#1 = *printf_str::s#33 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [696] printf_str::s#0 = ++ printf_str::s#33 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [697] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [698] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [699] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [700] callexecute *printf_str::putc#34  -- call__deref_pprz1 
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
    // [703] phi from print_chips to print_chips::@1 [phi:print_chips->print_chips::@1]
    // [703] phi print_chips::r#10 = 0 [phi:print_chips->print_chips::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // print_chips::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [704] if(print_chips::r#10<8) goto print_chips::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // print_chips::@return
    // }
    // [705] return 
    rts
    // print_chips::@2
  __b2:
    // r * 10
    // [706] print_chips::$33 = print_chips::r#10 << 2 -- vbum1=vbum2_rol_2 
    lda r
    asl
    asl
    sta __33
    // [707] print_chips::$34 = print_chips::$33 + print_chips::r#10 -- vbum1=vbum1_plus_vbum2 
    lda __34
    clc
    adc r
    sta __34
    // [708] print_chips::$4 = print_chips::$34 << 1 -- vbum1=vbum1_rol_1 
    asl __4
    // print_chip_line(3 + r * 10, 45, ' ')
    // [709] print_chip_line::x#0 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [710] call print_chip_line
    // [1130] phi from print_chips::@2 to print_chip_line [phi:print_chips::@2->print_chip_line]
    // [1130] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@2->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1130] phi print_chip_line::y#12 = $2d [phi:print_chips::@2->print_chip_line#1] -- vbum1=vbuc1 
    lda #$2d
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#0 [phi:print_chips::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@3
    // print_chip_line(3 + r * 10, 46, 'r')
    // [711] print_chip_line::x#1 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [712] call print_chip_line
    // [1130] phi from print_chips::@3 to print_chip_line [phi:print_chips::@3->print_chip_line]
    // [1130] phi print_chip_line::c#12 = 'r'pm [phi:print_chips::@3->print_chip_line#0] -- vbum1=vbuc1 
    lda #'r'
    sta print_chip_line.c
    // [1130] phi print_chip_line::y#12 = $2e [phi:print_chips::@3->print_chip_line#1] -- vbum1=vbuc1 
    lda #$2e
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#1 [phi:print_chips::@3->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@4
    // print_chip_line(3 + r * 10, 47, 'o')
    // [713] print_chip_line::x#2 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [714] call print_chip_line
    // [1130] phi from print_chips::@4 to print_chip_line [phi:print_chips::@4->print_chip_line]
    // [1130] phi print_chip_line::c#12 = 'o'pm [phi:print_chips::@4->print_chip_line#0] -- vbum1=vbuc1 
    lda #'o'
    sta print_chip_line.c
    // [1130] phi print_chip_line::y#12 = $2f [phi:print_chips::@4->print_chip_line#1] -- vbum1=vbuc1 
    lda #$2f
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#2 [phi:print_chips::@4->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@5
    // print_chip_line(3 + r * 10, 48, 'm')
    // [715] print_chip_line::x#3 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [716] call print_chip_line
    // [1130] phi from print_chips::@5 to print_chip_line [phi:print_chips::@5->print_chip_line]
    // [1130] phi print_chip_line::c#12 = 'm'pm [phi:print_chips::@5->print_chip_line#0] -- vbum1=vbuc1 
    lda #'m'
    sta print_chip_line.c
    // [1130] phi print_chip_line::y#12 = $30 [phi:print_chips::@5->print_chip_line#1] -- vbum1=vbuc1 
    lda #$30
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#3 [phi:print_chips::@5->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@6
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [717] print_chip_line::x#4 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [718] print_chip_line::c#4 = '0'pm + print_chips::r#10 -- vbum1=vbuc1_plus_vbum2 
    lda #'0'
    clc
    adc r
    sta print_chip_line.c
    // [719] call print_chip_line
    // [1130] phi from print_chips::@6 to print_chip_line [phi:print_chips::@6->print_chip_line]
    // [1130] phi print_chip_line::c#12 = print_chip_line::c#4 [phi:print_chips::@6->print_chip_line#0] -- register_copy 
    // [1130] phi print_chip_line::y#12 = $31 [phi:print_chips::@6->print_chip_line#1] -- vbum1=vbuc1 
    lda #$31
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#4 [phi:print_chips::@6->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@7
    // print_chip_line(3 + r * 10, 50, ' ')
    // [720] print_chip_line::x#5 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [721] call print_chip_line
    // [1130] phi from print_chips::@7 to print_chip_line [phi:print_chips::@7->print_chip_line]
    // [1130] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@7->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1130] phi print_chip_line::y#12 = $32 [phi:print_chips::@7->print_chip_line#1] -- vbum1=vbuc1 
    lda #$32
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#5 [phi:print_chips::@7->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@8
    // print_chip_line(3 + r * 10, 51, ' ')
    // [722] print_chip_line::x#6 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [723] call print_chip_line
    // [1130] phi from print_chips::@8 to print_chip_line [phi:print_chips::@8->print_chip_line]
    // [1130] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@8->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1130] phi print_chip_line::y#12 = $33 [phi:print_chips::@8->print_chip_line#1] -- vbum1=vbuc1 
    lda #$33
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#6 [phi:print_chips::@8->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@9
    // print_chip_line(3 + r * 10, 52, ' ')
    // [724] print_chip_line::x#7 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [725] call print_chip_line
    // [1130] phi from print_chips::@9 to print_chip_line [phi:print_chips::@9->print_chip_line]
    // [1130] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@9->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1130] phi print_chip_line::y#12 = $34 [phi:print_chips::@9->print_chip_line#1] -- vbum1=vbuc1 
    lda #$34
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#7 [phi:print_chips::@9->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@10
    // print_chip_line(3 + r * 10, 53, ' ')
    // [726] print_chip_line::x#8 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __4
    sta print_chip_line.x
    // [727] call print_chip_line
    // [1130] phi from print_chips::@10 to print_chip_line [phi:print_chips::@10->print_chip_line]
    // [1130] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@10->print_chip_line#0] -- vbum1=vbuc1 
    lda #' '
    sta print_chip_line.c
    // [1130] phi print_chip_line::y#12 = $35 [phi:print_chips::@10->print_chip_line#1] -- vbum1=vbuc1 
    lda #$35
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#8 [phi:print_chips::@10->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@11
    // print_chip_end(3 + r * 10, 54)
    // [728] print_chip_end::x#0 = 3 + print_chips::$4 -- vbum1=vbuc1_plus_vbum1 
    lda #3
    clc
    adc print_chip_end.x
    sta print_chip_end.x
    // [729] call print_chip_end
    jsr print_chip_end
    // print_chips::@12
    // print_chip_led(r, BLACK, BLUE)
    // [730] print_chip_led::r#0 = print_chips::r#10 -- vbum1=vbum2 
    lda r
    sta print_chip_led.r
    // [731] call print_chip_led
    // [872] phi from print_chips::@12 to print_chip_led [phi:print_chips::@12->print_chip_led]
    // [872] phi print_chip_led::tc#10 = BLACK [phi:print_chips::@12->print_chip_led#0] -- vbum1=vbuc1 
    lda #BLACK
    sta print_chip_led.tc
    // [872] phi print_chip_led::r#10 = print_chip_led::r#0 [phi:print_chips::@12->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // print_chips::@13
    // for (unsigned char r = 0; r < 8; r++)
    // [732] print_chips::r#1 = ++ print_chips::r#10 -- vbum1=_inc_vbum1 
    inc r
    // [703] phi from print_chips::@13 to print_chips::@1 [phi:print_chips::@13->print_chips::@1]
    // [703] phi print_chips::r#10 = print_chips::r#1 [phi:print_chips::@13->print_chips::@1#0] -- register_copy 
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
    // [734] call textcolor
    // [445] phi from print_clear to textcolor [phi:print_clear->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:print_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [735] phi from print_clear to print_clear::@1 [phi:print_clear->print_clear::@1]
    // print_clear::@1
    // gotoxy(2, 39)
    // [736] call gotoxy
    // [463] phi from print_clear::@1 to gotoxy [phi:print_clear::@1->gotoxy]
    // [463] phi gotoxy::y#25 = $27 [phi:print_clear::@1->gotoxy#0] -- vbum1=vbuc1 
    lda #$27
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = 2 [phi:print_clear::@1->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [737] phi from print_clear::@1 to print_clear::@2 [phi:print_clear::@1->print_clear::@2]
    // print_clear::@2
    // printf("%76s", " ")
    // [738] call printf_string
    // [742] phi from print_clear::@2 to printf_string [phi:print_clear::@2->printf_string]
    // [742] phi printf_string::str#12 = str [phi:print_clear::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [742] phi printf_string::format_min_length#12 = $4c [phi:print_clear::@2->printf_string#1] -- vbum1=vbuc1 
    lda #$4c
    sta printf_string.format_min_length
    jsr printf_string
    // [739] phi from print_clear::@2 to print_clear::@3 [phi:print_clear::@2->print_clear::@3]
    // print_clear::@3
    // gotoxy(2, 39)
    // [740] call gotoxy
    // [463] phi from print_clear::@3 to gotoxy [phi:print_clear::@3->gotoxy]
    // [463] phi gotoxy::y#25 = $27 [phi:print_clear::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #$27
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = 2 [phi:print_clear::@3->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // print_clear::@return
    // }
    // [741] return 
    rts
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($29) char *str, __mem() char format_min_length, char format_justify_left)
printf_string: {
    .label str = $29
    // if(format.min_length)
    // [743] if(0==printf_string::format_min_length#12) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b1
    // printf_string::@3
    // strlen(str)
    // [744] strlen::str#4 = printf_string::str#12 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [745] call strlen
    // [796] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [796] phi strlen::str#9 = strlen::str#4 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [746] strlen::return#12 = strlen::len#2
    // printf_string::@5
    // [747] printf_string::$9 = strlen::return#12
    // signed char len = (signed char)strlen(str)
    // [748] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwum2 
    lda __9
    sta len
    // padding = (signed char)format.min_length  - len
    // [749] printf_string::padding#1 = (signed char)printf_string::format_min_length#12 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [750] if(printf_string::padding#1>=0) goto printf_string::@7 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b6
    // [752] phi from printf_string printf_string::@5 to printf_string::@1 [phi:printf_string/printf_string::@5->printf_string::@1]
  __b1:
    // [752] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@5->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [751] phi from printf_string::@5 to printf_string::@7 [phi:printf_string::@5->printf_string::@7]
    // printf_string::@7
    // [752] phi from printf_string::@7 to printf_string::@1 [phi:printf_string::@7->printf_string::@1]
    // [752] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@7->printf_string::@1#0] -- register_copy 
    // printf_string::@1
    // printf_string::@6
  __b6:
    // if(!format.justify_left && padding)
    // [753] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [754] printf_padding::length#3 = (char)printf_string::padding#3
    // [755] call printf_padding
    // [1188] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1188] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1188] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1188] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [756] printf_str::s#2 = printf_string::str#12
    // [757] call printf_str
    // [693] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@return
    // }
    // [758] return 
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
    // [760] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [761] phi from wait_key::bank_set_bram1 to wait_key::@2 [phi:wait_key::bank_set_bram1->wait_key::@2]
    // wait_key::@2
    // bank_set_brom(0)
    // [762] call bank_set_brom
    // [769] phi from wait_key::@2 to bank_set_brom [phi:wait_key::@2->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 0 [phi:wait_key::@2->bank_set_brom#0] -- vbum1=vbuc1 
    lda #0
    sta bank_set_brom.bank
    jsr bank_set_brom
    // [763] phi from wait_key::@2 wait_key::@3 to wait_key::@1 [phi:wait_key::@2/wait_key::@3->wait_key::@1]
    // wait_key::@1
  __b1:
    // getin()
    // [764] call getin
    jsr getin
    // [765] getin::return#2 = getin::return#1
    // wait_key::@3
    // [766] wait_key::return#0 = getin::return#2
    // while (!(ch = getin()))
    // [767] if(0==wait_key::return#0) goto wait_key::@1 -- 0_eq_vbum1_then_la1 
    lda return
    beq __b1
    // wait_key::@return
    // }
    // [768] return 
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
    // [770] BROM = bank_set_brom::bank#11 -- vbuz1=vbum2 
    lda bank
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [771] return 
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
    // [773] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [774] phi from system_reset::bank_set_bram1 to system_reset::@1 [phi:system_reset::bank_set_bram1->system_reset::@1]
    // system_reset::@1
    // bank_set_brom(0)
    // [775] call bank_set_brom
    // [769] phi from system_reset::@1 to bank_set_brom [phi:system_reset::@1->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = 0 [phi:system_reset::@1->bank_set_brom#0] -- vbum1=vbuc1 
    lda #0
    sta bank_set_brom.bank
    jsr bank_set_brom
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [777] return 
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
    // [778] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // if(value<0)
    // [779] if(printf_sint::value#1<0) goto printf_sint::@1 -- vwsm1_lt_0_then_la1 
    lda value+1
    bmi __b1
    // [782] phi from printf_sint printf_sint::@1 to printf_sint::@2 [phi:printf_sint/printf_sint::@1->printf_sint::@2]
    // [782] phi printf_sint::value#4 = printf_sint::value#1 [phi:printf_sint/printf_sint::@1->printf_sint::@2#0] -- register_copy 
    jmp __b2
    // printf_sint::@1
  __b1:
    // value = -value
    // [780] printf_sint::value#0 = - printf_sint::value#1 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc value
    sta value
    lda #0
    sbc value+1
    sta value+1
    // printf_buffer.sign = '-'
    // [781] *((char *)&printf_buffer) = '-'pm -- _deref_pbuc1=vbuc2 
    lda #'-'
    sta printf_buffer
    // printf_sint::@2
  __b2:
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [783] utoa::value#1 = (unsigned int)printf_sint::value#4
    // [784] call utoa
    // [1202] phi from printf_sint::@2 to utoa [phi:printf_sint::@2->utoa]
    // [1202] phi utoa::value#10 = utoa::value#1 [phi:printf_sint::@2->utoa#0] -- register_copy 
    // [1202] phi utoa::radix#2 = DECIMAL [phi:printf_sint::@2->utoa#1] -- vbum1=vbuc1 
    lda #DECIMAL
    sta utoa.radix
    jsr utoa
    // printf_sint::@3
    // printf_number_buffer(putc, printf_buffer, format)
    // [785] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [786] call printf_number_buffer
  // Print using format
    // [1233] phi from printf_sint::@3 to printf_number_buffer [phi:printf_sint::@3->printf_number_buffer]
    // [1233] phi printf_number_buffer::format_upper_case#10 = printf_sint::format_upper_case#0 [phi:printf_sint::@3->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #format_upper_case
    sta printf_number_buffer.format_upper_case
    // [1233] phi printf_number_buffer::putc#10 = printf_sint::putc#0 [phi:printf_sint::@3->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [1233] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_sint::@3->printf_number_buffer#2] -- register_copy 
    // [1233] phi printf_number_buffer::format_zero_padding#10 = printf_sint::format_zero_padding#0 [phi:printf_sint::@3->printf_number_buffer#3] -- vbum1=vbuc1 
    lda #format_zero_padding
    sta printf_number_buffer.format_zero_padding
    // [1233] phi printf_number_buffer::format_justify_left#10 = printf_sint::format_justify_left#0 [phi:printf_sint::@3->printf_number_buffer#4] -- vbum1=vbuc1 
    lda #format_justify_left
    sta printf_number_buffer.format_justify_left
    // [1233] phi printf_number_buffer::format_min_length#4 = printf_sint::format_min_length#0 [phi:printf_sint::@3->printf_number_buffer#5] -- vbum1=vbuc1 
    lda #format_min_length
    sta printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_sint::@return
    // }
    // [787] return 
    rts
  .segment Data
    value: .word 0
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label dst = $29
    .label src = $25
    // [789] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [789] phi strcpy::dst#2 = file [phi:strcpy->strcpy::@1#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z dst
    lda #>file
    sta.z dst+1
    // [789] phi strcpy::src#2 = main::source [phi:strcpy->strcpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.source
    sta.z src
    lda #>main.source
    sta.z src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [790] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [791] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [792] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [793] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [794] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [795] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [789] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [789] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [789] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($25) char *str)
strlen: {
    .label str = $25
    // [797] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [797] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [797] phi strlen::str#7 = strlen::str#9 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [798] if(0!=*strlen::str#7) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [799] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [800] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [801] strlen::str#2 = ++ strlen::str#7 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [797] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [797] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [797] phi strlen::str#7 = strlen::str#2 [phi:strlen::@2->strlen::@1#1] -- register_copy 
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
    .label dst = $27
    .label src = $25
    // strlen(destination)
    // [803] call strlen
    // [796] phi from strcat to strlen [phi:strcat->strlen]
    // [796] phi strlen::str#9 = file [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strlen.str
    lda #>file
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [804] strlen::return#1 = strlen::len#2
    // strcat::@4
    // [805] strcat::$0 = strlen::return#1
    // char* dst = destination + strlen(destination)
    // [806] strcat::dst#0 = file + strcat::$0 -- pbuz1=pbuc1_plus_vwum2 
    lda __0
    clc
    adc #<file
    sta.z dst
    lda __0+1
    adc #>file
    sta.z dst+1
    // [807] phi from strcat::@4 to strcat::@1 [phi:strcat::@4->strcat::@1]
    // [807] phi strcat::dst#2 = strcat::dst#0 [phi:strcat::@4->strcat::@1#0] -- register_copy 
    // [807] phi strcat::src#2 = main::source1 [phi:strcat::@4->strcat::@1#1] -- pbuz1=pbuc1 
    lda #<main.source1
    sta.z src
    lda #>main.source1
    sta.z src+1
    // strcat::@1
  __b1:
    // while(*src)
    // [808] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [809] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [810] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [811] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [812] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [813] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [807] phi from strcat::@2 to strcat::@1 [phi:strcat::@2->strcat::@1]
    // [807] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2->strcat::@1#0] -- register_copy 
    // [807] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2->strcat::@1#1] -- register_copy 
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
// __zp($27) struct $1 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label stream = $27
    .label dst = $22
    .label return = $27
    .label __24 = $2d
    .label __25 = $31
    .label __26 = $29
    .label __27 = $41
    .label __28 = $2f
    .label __29 = $2b
    .label __30 = $3b
    .label __31 = $3d
    // unsigned int sp = __stdio_filecount
    // [814] fopen::sp#0 = (unsigned int)__stdio_filecount -- vwum1=_word_vbum2 
    lda __stdio_filecount
    sta sp
    lda #0
    sta sp+1
    // (unsigned int)sp | 0x8000
    // [815] fopen::stream#0 = fopen::sp#0 | $8000 -- vwuz1=vwum2_bor_vwuc1 
    lda sp
    ora #<$8000
    sta.z stream
    lda sp+1
    ora #>$8000
    sta.z stream+1
    // __stdio_file.status[sp] = 0
    // [816] fopen::$24 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __24
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __24+1
    // [817] *fopen::$24 = 0 -- _deref_pbuz1=vbuc1 
    // We set bit 7 of the high byte, to differentiate from NULL.
    lda #0
    tay
    sta (__24),y
    // __stdio_file.channel[sp] = channel
    // [818] fopen::$25 = (char *)&__stdio_file+$40 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$40
    sta.z __25
    lda sp+1
    adc #>__stdio_file+$40
    sta.z __25+1
    // [819] *fopen::$25 = fopen::channel#0 -- _deref_pbuz1=vbuc1 
    lda #channel
    sta (__25),y
    // __stdio_file.device[sp] = device
    // [820] fopen::$26 = (char *)&__stdio_file+$42 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$42
    sta.z __26
    lda sp+1
    adc #>__stdio_file+$42
    sta.z __26+1
    // [821] *fopen::$26 = fopen::device#0 -- _deref_pbuz1=vbuc1 
    lda #device
    sta (__26),y
    // __stdio_file.secondary[sp] = secondary
    // [822] fopen::$27 = (char *)&__stdio_file+$44 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$44
    sta.z __27
    lda sp+1
    adc #>__stdio_file+$44
    sta.z __27+1
    // [823] *fopen::$27 = fopen::secondary#0 -- _deref_pbuz1=vbuc1 
    lda #secondary
    sta (__27),y
    // sp * __STDIO_FILECOUNT
    // [824] fopen::$12 = fopen::sp#0 << 1 -- vwum1=vwum2_rol_1 
    lda sp
    asl
    sta __12
    lda sp+1
    rol
    sta __12+1
    // char* dst = &__stdio_file.filename[sp * __STDIO_FILECOUNT]
    // [825] fopen::dst#0 = (char *)&__stdio_file + fopen::$12 -- pbuz1=pbuc1_plus_vwum2 
    lda __12
    clc
    adc #<__stdio_file
    sta.z dst
    lda __12+1
    adc #>__stdio_file
    sta.z dst+1
    // strncpy(dst, filename, 16)
    // [826] strncpy::dst#1 = fopen::dst#0
    // [827] call strncpy
    // [1274] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@5
    // cbm_k_setnam(filename)
    // [828] cbm_k_setnam::filename = file -- pbuz1=pbuc1 
    lda #<file
    sta.z cbm_k_setnam.filename
    lda #>file
    sta.z cbm_k_setnam.filename+1
    // [829] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@6
    // cbm_k_setlfs(channel, device, secondary)
    // [830] cbm_k_setlfs::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_setlfs.channel
    // [831] cbm_k_setlfs::device = fopen::device#0 -- vbum1=vbuc1 
    lda #device
    sta cbm_k_setlfs.device
    // [832] cbm_k_setlfs::command = fopen::secondary#0 -- vbum1=vbuc1 
    lda #secondary
    sta cbm_k_setlfs.command
    // [833] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [834] phi from fopen::@6 to fopen::@7 [phi:fopen::@6->fopen::@7]
    // fopen::@7
    // cbm_k_open()
    // [835] call cbm_k_open
    jsr cbm_k_open
    // [836] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@8
    // [837] fopen::$6 = cbm_k_open::return#2
    // __stdio_file.status[sp] = cbm_k_open()
    // [838] fopen::$28 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __28
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __28+1
    // [839] *fopen::$28 = fopen::$6 -- _deref_pbuz1=vbum2 
    lda __6
    ldy #0
    sta (__28),y
    // if (__stdio_file.status[sp])
    // [840] fopen::$29 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __29
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __29+1
    // [841] if(0==*fopen::$29) goto fopen::@1 -- 0_eq__deref_pbuz1_then_la1 
    lda (__29),y
    cmp #0
    beq __b1
    // fopen::@3
    // ferror(stream)
    // [842] ferror::stream#0 = (struct $1 *)fopen::stream#0
    // [843] call ferror
  // The POSIX standard specifies that in case of file not found, NULL is returned.
  // However, the error needs to be cleared from the device.
  // This needs to be done using ferror, but this function needs a FILE* stream.
  // As fopen returns NULL in case file not found, the ferror must be called before return
  // to clear the error from the device. Otherwise the device is left with a red blicking led.
    // [1299] phi from fopen::@3 to ferror [phi:fopen::@3->ferror]
    // [1299] phi ferror::stream#2 = ferror::stream#0 [phi:fopen::@3->ferror#0] -- register_copy 
    jsr ferror
    // fopen::@11
    // printf("%s\n", __stdio_file.error + sp * __STDIO_FILECOUNT)
    // [844] printf_string::str#0 = (char *)&__stdio_file+$48 + fopen::$12 -- pbuz1=pbuc1_plus_vwum2 
    lda __12
    clc
    adc #<__stdio_file+$48
    sta.z printf_string.str
    lda __12+1
    adc #>__stdio_file+$48
    sta.z printf_string.str+1
    // [845] call printf_string
    // [742] phi from fopen::@11 to printf_string [phi:fopen::@11->printf_string]
    // [742] phi printf_string::str#12 = printf_string::str#0 [phi:fopen::@11->printf_string#0] -- register_copy 
    // [742] phi printf_string::format_min_length#12 = 0 [phi:fopen::@11->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [846] phi from fopen::@11 to fopen::@12 [phi:fopen::@11->fopen::@12]
    // fopen::@12
    // printf("%s\n", __stdio_file.error + sp * __STDIO_FILECOUNT)
    // [847] call printf_str
    // [693] phi from fopen::@12 to printf_str [phi:fopen::@12->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:fopen::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = fopen::s [phi:fopen::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // fopen::@13
    // cbm_k_close(channel)
    // [848] cbm_k_close::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_close.channel
    // [849] call cbm_k_close
    jsr cbm_k_close
    // [850] phi from fopen::@13 fopen::@16 to fopen::@return [phi:fopen::@13/fopen::@16->fopen::@return]
  __b3:
    // [850] phi fopen::return#1 = 0 [phi:fopen::@13/fopen::@16->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [851] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [852] cbm_k_chkin::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_chkin.channel
    // [853] call cbm_k_chkin
    jsr cbm_k_chkin
    // [854] phi from fopen::@1 to fopen::@9 [phi:fopen::@1->fopen::@9]
    // fopen::@9
    // cbm_k_readst()
    // [855] call cbm_k_readst
    jsr cbm_k_readst
    // [856] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@10
    // [857] fopen::$9 = cbm_k_readst::return#2
    // __stdio_file.status[sp] = cbm_k_readst()
    // [858] fopen::$30 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __30
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __30+1
    // [859] *fopen::$30 = fopen::$9 -- _deref_pbuz1=vbum2 
    lda __9
    ldy #0
    sta (__30),y
    // if (__stdio_file.status[sp])
    // [860] fopen::$31 = (char *)&__stdio_file+$46 + fopen::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __31
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __31+1
    // [861] if(0==*fopen::$31) goto fopen::@2 -- 0_eq__deref_pbuz1_then_la1 
    lda (__31),y
    cmp #0
    beq __b2
    // fopen::@4
    // ferror(stream)
    // [862] ferror::stream#1 = (struct $1 *)fopen::stream#0
    // [863] call ferror
    // [1299] phi from fopen::@4 to ferror [phi:fopen::@4->ferror]
    // [1299] phi ferror::stream#2 = ferror::stream#1 [phi:fopen::@4->ferror#0] -- register_copy 
    jsr ferror
    // fopen::@14
    // printf("%s\n", __stdio_file.error + sp * __STDIO_FILECOUNT)
    // [864] printf_string::str#1 = (char *)&__stdio_file+$48 + fopen::$12 -- pbuz1=pbuc1_plus_vwum2 
    lda __12
    clc
    adc #<__stdio_file+$48
    sta.z printf_string.str
    lda __12+1
    adc #>__stdio_file+$48
    sta.z printf_string.str+1
    // [865] call printf_string
    // [742] phi from fopen::@14 to printf_string [phi:fopen::@14->printf_string]
    // [742] phi printf_string::str#12 = printf_string::str#1 [phi:fopen::@14->printf_string#0] -- register_copy 
    // [742] phi printf_string::format_min_length#12 = 0 [phi:fopen::@14->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_min_length
    jsr printf_string
    // [866] phi from fopen::@14 to fopen::@15 [phi:fopen::@14->fopen::@15]
    // fopen::@15
    // printf("%s\n", __stdio_file.error + sp * __STDIO_FILECOUNT)
    // [867] call printf_str
    // [693] phi from fopen::@15 to printf_str [phi:fopen::@15->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:fopen::@15->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = fopen::s [phi:fopen::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // fopen::@16
    // cbm_k_close(channel)
    // [868] cbm_k_close::channel = fopen::channel#0 -- vbum1=vbuc1 
    lda #channel
    sta cbm_k_close.channel
    // [869] call cbm_k_close
    jsr cbm_k_close
    jmp __b3
    // fopen::@2
  __b2:
    // __stdio_filecount++;
    // [870] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [871] fopen::return#7 = (struct $1 *)fopen::stream#0
    // [850] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [850] phi fopen::return#1 = fopen::return#7 [phi:fopen::@2->fopen::@return#0] -- register_copy 
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
    // [873] print_chip_led::$8 = print_chip_led::r#10 << 2 -- vbum1=vbum2_rol_2 
    lda r
    asl
    asl
    sta __8
    // [874] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#10 -- vbum1=vbum2_plus_vbum1 
    lda __9
    clc
    adc __8
    sta __9
    // [875] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbum1=vbum1_rol_1 
    asl __0
    // gotoxy(4 + r * 10, 43)
    // [876] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbum1=vbuc1_plus_vbum2 
    lda #4
    clc
    adc __0
    sta gotoxy.x
    // [877] call gotoxy
    // [463] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [463] phi gotoxy::y#25 = $2b [phi:print_chip_led->gotoxy#0] -- vbum1=vbuc1 
    lda #$2b
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [878] textcolor::color#8 = print_chip_led::tc#10 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [879] call textcolor
    // [445] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [445] phi textcolor::color#23 = textcolor::color#8 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [880] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [881] call bgcolor
    // [450] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [882] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [883] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [885] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [886] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [888] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [889] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [891] return 
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
    // [893] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [894] uctoa::value#1 = printf_uchar::uvalue#11
    // [895] uctoa::radix#0 = printf_uchar::format_radix#11
    // [896] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [897] printf_number_buffer::buffer_sign#3 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [898] printf_number_buffer::format_min_length#3 = printf_uchar::format_min_length#11
    // [899] printf_number_buffer::format_zero_padding#3 = printf_uchar::format_zero_padding#11
    // [900] call printf_number_buffer
  // Print using format
    // [1233] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1233] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_upper_case
    // [1233] phi printf_number_buffer::putc#10 = &cputc [phi:printf_uchar::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1233] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#3 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1233] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#3 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [1233] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_justify_left
    // [1233] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#3 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [901] return 
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
    // [903] call textcolor
    // [445] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:table_chip_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [904] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [905] call bgcolor
    // [450] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [906] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [906] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [906] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbum1=vbuc1 
    lda #4
    sta y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [907] if(table_chip_clear::y#10<$24) goto table_chip_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #$24
    bcc __b2
    // table_chip_clear::@return
    // }
    // [908] return 
    rts
    // table_chip_clear::@2
  __b2:
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [909] rom_address::rom_bank#1 = table_chip_clear::rom_bank#11 -- vbum1=vbum2 
    lda rom_bank
    sta rom_address.rom_bank
    // [910] call rom_address
    // [927] phi from table_chip_clear::@2 to rom_address [phi:table_chip_clear::@2->rom_address]
    // [927] phi rom_address::rom_bank#5 = rom_address::rom_bank#1 [phi:table_chip_clear::@2->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [911] rom_address::return#3 = rom_address::return#0
    // table_chip_clear::@4
    // [912] table_chip_clear::flash_rom_address#0 = rom_address::return#3
    // gotoxy(2, y)
    // [913] gotoxy::y#9 = table_chip_clear::y#10 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [914] call gotoxy
    // [463] phi from table_chip_clear::@4 to gotoxy [phi:table_chip_clear::@4->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#9 [phi:table_chip_clear::@4->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = 2 [phi:table_chip_clear::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // table_chip_clear::@5
    // printf("%02x", rom_bank)
    // [915] printf_uchar::uvalue#2 = table_chip_clear::rom_bank#11 -- vbum1=vbum2 
    lda rom_bank
    sta printf_uchar.uvalue
    // [916] call printf_uchar
    // [892] phi from table_chip_clear::@5 to printf_uchar [phi:table_chip_clear::@5->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 1 [phi:table_chip_clear::@5->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 2 [phi:table_chip_clear::@5->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:table_chip_clear::@5->printf_uchar#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#2 [phi:table_chip_clear::@5->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@6
    // gotoxy(5, y)
    // [917] gotoxy::y#10 = table_chip_clear::y#10 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [918] call gotoxy
    // [463] phi from table_chip_clear::@6 to gotoxy [phi:table_chip_clear::@6->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#10 [phi:table_chip_clear::@6->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = 5 [phi:table_chip_clear::@6->gotoxy#1] -- vbum1=vbuc1 
    lda #5
    sta gotoxy.x
    jsr gotoxy
    // table_chip_clear::@7
    // printf("%06x", flash_rom_address)
    // [919] printf_ulong::uvalue#1 = table_chip_clear::flash_rom_address#0 -- vdum1=vdum2 
    lda flash_rom_address
    sta printf_ulong.uvalue
    lda flash_rom_address+1
    sta printf_ulong.uvalue+1
    lda flash_rom_address+2
    sta printf_ulong.uvalue+2
    lda flash_rom_address+3
    sta printf_ulong.uvalue+3
    // [920] call printf_ulong
    // [1386] phi from table_chip_clear::@7 to printf_ulong [phi:table_chip_clear::@7->printf_ulong]
    // [1386] phi printf_ulong::format_zero_padding#2 = 1 [phi:table_chip_clear::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1386] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:table_chip_clear::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // table_chip_clear::@8
    // gotoxy(14, y)
    // [921] gotoxy::y#11 = table_chip_clear::y#10 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [922] call gotoxy
    // [463] phi from table_chip_clear::@8 to gotoxy [phi:table_chip_clear::@8->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#11 [phi:table_chip_clear::@8->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = $e [phi:table_chip_clear::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #$e
    sta gotoxy.x
    jsr gotoxy
    // [923] phi from table_chip_clear::@8 to table_chip_clear::@9 [phi:table_chip_clear::@8->table_chip_clear::@9]
    // table_chip_clear::@9
    // printf("%64s", " ")
    // [924] call printf_string
    // [742] phi from table_chip_clear::@9 to printf_string [phi:table_chip_clear::@9->printf_string]
    // [742] phi printf_string::str#12 = str [phi:table_chip_clear::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [742] phi printf_string::format_min_length#12 = $40 [phi:table_chip_clear::@9->printf_string#1] -- vbum1=vbuc1 
    lda #$40
    sta printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@10
    // rom_bank++;
    // [925] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#11 -- vbum1=_inc_vbum1 
    inc rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [926] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbum1=_inc_vbum1 
    inc y
    // [906] phi from table_chip_clear::@10 to table_chip_clear::@1 [phi:table_chip_clear::@10->table_chip_clear::@1]
    // [906] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@10->table_chip_clear::@1#0] -- register_copy 
    // [906] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@10->table_chip_clear::@1#1] -- register_copy 
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
    // [928] rom_address::$1 = (unsigned long)rom_address::rom_bank#5 -- vdum1=_dword_vbum2 
    lda rom_bank
    sta __1
    lda #0
    sta __1+1
    sta __1+2
    sta __1+3
    // [929] rom_address::return#0 = rom_address::$1 << $e -- vdum1=vdum1_rol_vbuc1 
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
    // [930] return 
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
// __mem() unsigned long flash_read(__zp($29) struct $1 *fp, __zp($2b) char *flash_ram_address, __mem() char rom_bank_start, __mem() unsigned long read_size)
flash_read: {
    .label flash_ram_address = $2b
    .label fp = $29
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [932] rom_address::rom_bank#0 = flash_read::rom_bank_start#11 -- vbum1=vbum2 
    lda rom_bank_start
    sta rom_address.rom_bank
    // [933] call rom_address
    // [927] phi from flash_read to rom_address [phi:flash_read->rom_address]
    // [927] phi rom_address::rom_bank#5 = rom_address::rom_bank#0 [phi:flash_read->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [934] rom_address::return#2 = rom_address::return#0 -- vdum1=vdum2 
    lda rom_address.return
    sta rom_address.return_1
    lda rom_address.return+1
    sta rom_address.return_1+1
    lda rom_address.return+2
    sta rom_address.return_1+2
    lda rom_address.return+3
    sta rom_address.return_1+3
    // flash_read::@9
    // [935] flash_read::flash_rom_address#0 = rom_address::return#2
    // textcolor(WHITE)
    // [936] call textcolor
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [445] phi from flash_read::@9 to textcolor [phi:flash_read::@9->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:flash_read::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [937] phi from flash_read::@9 to flash_read::@1 [phi:flash_read::@9->flash_read::@1]
    // [937] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@9->flash_read::@1#0] -- register_copy 
    // [937] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@9->flash_read::@1#1] -- register_copy 
    // [937] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#0 [phi:flash_read::@9->flash_read::@1#2] -- register_copy 
    // [937] phi flash_read::return#2 = 0 [phi:flash_read::@9->flash_read::@1#3] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
    // [937] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [937] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [937] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [937] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [937] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < read_size)
    // [938] if(flash_read::return#2<flash_read::read_size#4) goto flash_read::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [939] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [940] flash_read::$3 = flash_read::flash_rom_address#10 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [941] if(0!=flash_read::$3) goto flash_read::@3 -- 0_neq_vdum1_then_la1 
    lda __3
    ora __3+1
    ora __3+2
    ora __3+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [942] flash_read::$6 = flash_read::rom_bank_start#4 & $20-1 -- vbum1=vbum2_band_vbuc1 
    lda #$20-1
    and rom_bank_start
    sta __6
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [943] gotoxy::y#8 = 4 + flash_read::$6 -- vbum1=vbuc1_plus_vbum2 
    lda #4
    clc
    adc __6
    sta gotoxy.y
    // [944] call gotoxy
    // [463] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#8 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = $e [phi:flash_read::@6->gotoxy#1] -- vbum1=vbuc1 
    lda #$e
    sta gotoxy.x
    jsr gotoxy
    // flash_read::@11
    // rom_bank_start++;
    // [945] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbum1=_inc_vbum1 
    inc rom_bank_start
    // [946] phi from flash_read::@11 flash_read::@2 to flash_read::@3 [phi:flash_read::@11/flash_read::@2->flash_read::@3]
    // [946] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@11/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [947] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [948] fgets::stream#0 = flash_read::fp#10
    // [949] call fgets
    jsr fgets
    // [950] fgets::return#5 = fgets::return#1
    // flash_read::@10
    // [951] flash_read::read_bytes#0 = fgets::return#5
    // if (!read_bytes)
    // [952] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwum1_then_la1 
    lda read_bytes
    ora read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [953] flash_read::$12 = flash_read::flash_rom_address#10 & $100-1 -- vdum1=vdum2_band_vduc1 
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
    // [954] if(0!=flash_read::$12) goto flash_read::@5 -- 0_neq_vdum1_then_la1 
    lda __12
    ora __12+1
    ora __12+2
    ora __12+3
    bne __b5
    // flash_read::@7
    // cputc('.')
    // [955] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    // cputc(0xE0);
    lda #'.'
    pha
    // [956] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [958] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z flash_ram_address
    adc read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [959] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vdum1=vdum1_plus_vwum2 
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
    // [960] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vdum1=vdum1_plus_vwum2 
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
    // [961] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // [962] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
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
    // [964] return 
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
// int fclose(__zp($4c) struct $1 *stream)
fclose: {
    .label stream = $4c
    .label __5 = $2d
    .label __6 = $31
    .label __7 = $29
    // unsigned int sp = (unsigned int)stream & ~0x8000
    // [965] fclose::sp#0 = (unsigned int)fclose::stream#0 & ~$8000 -- vwum1=vwuz2_band_vwuc1 
    lda.z stream
    and #<$8000^$ffff
    sta sp
    lda.z stream+1
    and #>$8000^$ffff
    sta sp+1
    // cbm_k_close(__stdio_file.channel[sp])
    // [966] fclose::$5 = (char *)&__stdio_file+$40 + fclose::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$40
    sta.z __5
    lda sp+1
    adc #>__stdio_file+$40
    sta.z __5+1
    // [967] cbm_k_close::channel = *fclose::$5 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (__5),y
    sta cbm_k_close.channel
    // [968] call cbm_k_close
    jsr cbm_k_close
    // [969] cbm_k_close::return#5 = cbm_k_close::return#1
    // fclose::@2
    // [970] fclose::$1 = cbm_k_close::return#5
    // __stdio_file.status[sp] = cbm_k_close(__stdio_file.channel[sp])
    // [971] fclose::$6 = (char *)&__stdio_file+$46 + fclose::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __6
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __6+1
    // [972] *fclose::$6 = fclose::$1 -- _deref_pbuz1=vbum2 
    lda __1
    ldy #0
    sta (__6),y
    // if(__stdio_file.status[sp])
    // [973] fclose::$7 = (char *)&__stdio_file+$46 + fclose::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __7
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __7+1
    // [974] if(0==*fclose::$7) goto fclose::@1 -- 0_eq__deref_pbuz1_then_la1 
    lda (__7),y
    cmp #0
    beq __b1
    rts
    // fclose::@1
  __b1:
    // __stdio_filecount--;
    // [975] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    // fclose::@return
    // }
    // [976] return 
    rts
  .segment Data
    .label __1 = cbm_k_close.return
    sp: .word 0
}
.segment Code
  // flash_verify
// __mem() unsigned int flash_verify(__mem() char bank_ram, __zp($2b) char *ptr_ram, __mem() unsigned long verify_rom_address, __mem() unsigned int verify_rom_size)
flash_verify: {
    .label rom_ptr1_return = $29
    .label ptr_rom = $29
    .label ptr_ram = $2b
    // flash_verify::bank_set_bram1
    // BRAM = bank
    // [978] BRAM = flash_verify::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // flash_verify::rom_bank1
    // BYTE2(address)
    // [979] flash_verify::rom_bank1_$0 = byte2  flash_verify::verify_rom_address#3 -- vbum1=_byte2_vdum2 
    lda verify_rom_address+2
    sta rom_bank1___0
    // BYTE1(address)
    // [980] flash_verify::rom_bank1_$1 = byte1  flash_verify::verify_rom_address#3 -- vbum1=_byte1_vdum2 
    lda verify_rom_address+1
    sta rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [981] flash_verify::rom_bank1_$2 = flash_verify::rom_bank1_$0 w= flash_verify::rom_bank1_$1 -- vwum1=vbum2_word_vbum3 
    lda rom_bank1___0
    sta rom_bank1___2+1
    lda rom_bank1___1
    sta rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [982] flash_verify::rom_bank1_bank_unshifted#0 = flash_verify::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [983] flash_verify::rom_bank1_return#0 = byte1  flash_verify::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // flash_verify::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [984] flash_verify::rom_ptr1_$2 = (unsigned int)flash_verify::verify_rom_address#3 -- vwum1=_word_vdum2 
    lda verify_rom_address
    sta rom_ptr1___2
    lda verify_rom_address+1
    sta rom_ptr1___2+1
    // [985] flash_verify::rom_ptr1_$0 = flash_verify::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [986] flash_verify::rom_ptr1_return#0 = flash_verify::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // flash_verify::@5
    // bank_set_brom(bank_rom)
    // [987] bank_set_brom::bank#3 = flash_verify::rom_bank1_return#0
    // [988] call bank_set_brom
    // [769] phi from flash_verify::@5 to bank_set_brom [phi:flash_verify::@5->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = bank_set_brom::bank#3 [phi:flash_verify::@5->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // flash_verify::@6
    // [989] flash_verify::ptr_rom#9 = (char *)flash_verify::rom_ptr1_return#0
    // [990] phi from flash_verify::@6 to flash_verify::@1 [phi:flash_verify::@6->flash_verify::@1]
    // [990] phi flash_verify::correct_bytes#2 = 0 [phi:flash_verify::@6->flash_verify::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta correct_bytes
    sta correct_bytes+1
    // [990] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#10 [phi:flash_verify::@6->flash_verify::@1#1] -- register_copy 
    // [990] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#9 [phi:flash_verify::@6->flash_verify::@1#2] -- register_copy 
    // [990] phi flash_verify::verified_bytes#2 = 0 [phi:flash_verify::@6->flash_verify::@1#3] -- vwum1=vwuc1 
    sta verified_bytes
    sta verified_bytes+1
    // flash_verify::@1
  __b1:
    // while (verified_bytes < verify_rom_size)
    // [991] if(flash_verify::verified_bytes#2<flash_verify::verify_rom_size#11) goto flash_verify::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [992] return 
    rts
    // flash_verify::@2
  __b2:
    // rom_byte_verify(ptr_rom, *ptr_ram)
    // [993] rom_byte_verify::ptr_rom#0 = flash_verify::ptr_rom#2
    // [994] rom_byte_verify::value#0 = *flash_verify::ptr_ram#4 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta rom_byte_verify.value
    // [995] call rom_byte_verify
    jsr rom_byte_verify
    // [996] rom_byte_verify::return#2 = rom_byte_verify::return#0
    // flash_verify::@7
    // [997] flash_verify::$5 = rom_byte_verify::return#2
    // if (rom_byte_verify(ptr_rom, *ptr_ram))
    // [998] if(0==flash_verify::$5) goto flash_verify::@3 -- 0_eq_vbum1_then_la1 
    lda __5
    beq __b3
    // flash_verify::@4
    // correct_bytes++;
    // [999] flash_verify::correct_bytes#1 = ++ flash_verify::correct_bytes#2 -- vwum1=_inc_vwum1 
    inc correct_bytes
    bne !+
    inc correct_bytes+1
  !:
    // [1000] phi from flash_verify::@4 flash_verify::@7 to flash_verify::@3 [phi:flash_verify::@4/flash_verify::@7->flash_verify::@3]
    // [1000] phi flash_verify::correct_bytes#6 = flash_verify::correct_bytes#1 [phi:flash_verify::@4/flash_verify::@7->flash_verify::@3#0] -- register_copy 
    // flash_verify::@3
  __b3:
    // ptr_rom++;
    // [1001] flash_verify::ptr_rom#1 = ++ flash_verify::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [1002] flash_verify::ptr_ram#0 = ++ flash_verify::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // verified_bytes++;
    // [1003] flash_verify::verified_bytes#1 = ++ flash_verify::verified_bytes#2 -- vwum1=_inc_vwum1 
    inc verified_bytes
    bne !+
    inc verified_bytes+1
  !:
    // [990] phi from flash_verify::@3 to flash_verify::@1 [phi:flash_verify::@3->flash_verify::@1]
    // [990] phi flash_verify::correct_bytes#2 = flash_verify::correct_bytes#6 [phi:flash_verify::@3->flash_verify::@1#0] -- register_copy 
    // [990] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#0 [phi:flash_verify::@3->flash_verify::@1#1] -- register_copy 
    // [990] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#1 [phi:flash_verify::@3->flash_verify::@1#2] -- register_copy 
    // [990] phi flash_verify::verified_bytes#2 = flash_verify::verified_bytes#1 [phi:flash_verify::@3->flash_verify::@1#3] -- register_copy 
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
    // [1005] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1___2
    lda address+1
    sta rom_ptr1___2+1
    // [1006] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1007] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [1008] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // [1009] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vdum1=vdum1_plus_vwuc1 
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
    // [1010] call rom_unlock
    // [1446] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1446] phi rom_unlock::unlock_code#3 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbum1=vbuc1 
    lda #$80
    sta rom_unlock.unlock_code
    // [1446] phi rom_unlock::address#3 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [1011] rom_unlock::address#1 = rom_sector_erase::address#0 -- vdum1=vdum2 
    lda address
    sta rom_unlock.address
    lda address+1
    sta rom_unlock.address+1
    lda address+2
    sta rom_unlock.address+2
    lda address+3
    sta rom_unlock.address+3
    // [1012] call rom_unlock
    // [1446] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1446] phi rom_unlock::unlock_code#3 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$30
    sta rom_unlock.unlock_code
    // [1446] phi rom_unlock::address#3 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [1013] rom_wait::ptr_rom#1 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [1014] call rom_wait
    // [1456] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [1456] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [1015] return 
    rts
  .segment Data
    .label rom_ptr1___0 = rom_ptr1___2
    rom_ptr1___2: .word 0
    .label rom_chip_address = rom_unlock.address
    address: .dword 0
}
.segment Code
  // print_address
// void print_address(__mem() char bram_bank, __zp($37) char *bram_ptr, __mem() unsigned long brom_address)
print_address: {
    .label brom_ptr = $41
    .label bram_ptr = $37
    // textcolor(WHITE)
    // [1017] call textcolor
    // [445] phi from print_address to textcolor [phi:print_address->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:print_address->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // print_address::rom_bank1
    // BYTE2(address)
    // [1018] print_address::rom_bank1_$0 = byte2  print_address::brom_address#10 -- vbum1=_byte2_vdum2 
    lda brom_address+2
    sta rom_bank1___0
    // BYTE1(address)
    // [1019] print_address::rom_bank1_$1 = byte1  print_address::brom_address#10 -- vbum1=_byte1_vdum2 
    lda brom_address+1
    sta rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1020] print_address::rom_bank1_$2 = print_address::rom_bank1_$0 w= print_address::rom_bank1_$1 -- vwum1=vbum2_word_vbum3 
    lda rom_bank1___0
    sta rom_bank1___2+1
    lda rom_bank1___1
    sta rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1021] print_address::rom_bank1_bank_unshifted#0 = print_address::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1022] print_address::brom_bank#0 = byte1  print_address::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta brom_bank
    // print_address::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1023] print_address::rom_ptr1_$2 = (unsigned int)print_address::brom_address#10 -- vwum1=_word_vdum2 
    lda brom_address
    sta rom_ptr1___2
    lda brom_address+1
    sta rom_ptr1___2+1
    // [1024] print_address::rom_ptr1_$0 = print_address::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1025] print_address::brom_ptr#0 = print_address::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z brom_ptr
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z brom_ptr+1
    // [1026] phi from print_address::rom_ptr1 to print_address::@1 [phi:print_address::rom_ptr1->print_address::@1]
    // print_address::@1
    // gotoxy(43, 1)
    // [1027] call gotoxy
    // [463] phi from print_address::@1 to gotoxy [phi:print_address::@1->gotoxy]
    // [463] phi gotoxy::y#25 = 1 [phi:print_address::@1->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = $2b [phi:print_address::@1->gotoxy#1] -- vbum1=vbuc1 
    lda #$2b
    sta gotoxy.x
    jsr gotoxy
    // [1028] phi from print_address::@1 to print_address::@2 [phi:print_address::@1->print_address::@2]
    // print_address::@2
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1029] call printf_str
    // [693] phi from print_address::@2 to printf_str [phi:print_address::@2->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:print_address::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = print_address::s [phi:print_address::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@3
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1030] printf_uchar::uvalue#0 = print_address::bram_bank#10
    // [1031] call printf_uchar
    // [892] phi from print_address::@3 to printf_uchar [phi:print_address::@3->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:print_address::@3->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 2 [phi:print_address::@3->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:print_address::@3->printf_uchar#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#0 [phi:print_address::@3->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [1032] phi from print_address::@3 to print_address::@4 [phi:print_address::@3->print_address::@4]
    // print_address::@4
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1033] call printf_str
    // [693] phi from print_address::@4 to printf_str [phi:print_address::@4->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:print_address::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = print_address::s1 [phi:print_address::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@5
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1034] printf_uint::uvalue#0 = (unsigned int)print_address::bram_ptr#10 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [1035] call printf_uint
    // [1463] phi from print_address::@5 to printf_uint [phi:print_address::@5->printf_uint]
    // [1463] phi printf_uint::uvalue#3 = printf_uint::uvalue#0 [phi:print_address::@5->printf_uint#0] -- register_copy 
    jsr printf_uint
    // [1036] phi from print_address::@5 to print_address::@6 [phi:print_address::@5->print_address::@6]
    // print_address::@6
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1037] call printf_str
    // [693] phi from print_address::@6 to printf_str [phi:print_address::@6->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:print_address::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = print_address::s2 [phi:print_address::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@7
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1038] printf_ulong::uvalue#0 = print_address::brom_address#10
    // [1039] call printf_ulong
    // [1386] phi from print_address::@7 to printf_ulong [phi:print_address::@7->printf_ulong]
    // [1386] phi printf_ulong::format_zero_padding#2 = 0 [phi:print_address::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1386] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:print_address::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1040] phi from print_address::@7 to print_address::@8 [phi:print_address::@7->print_address::@8]
    // print_address::@8
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1041] call printf_str
    // [693] phi from print_address::@8 to printf_str [phi:print_address::@8->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:print_address::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = print_address::s3 [phi:print_address::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@9
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1042] printf_uchar::uvalue#1 = print_address::brom_bank#0 -- vbum1=vbum2 
    lda brom_bank
    sta printf_uchar.uvalue
    // [1043] call printf_uchar
    // [892] phi from print_address::@9 to printf_uchar [phi:print_address::@9->printf_uchar]
    // [892] phi printf_uchar::format_zero_padding#11 = 0 [phi:print_address::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [892] phi printf_uchar::format_min_length#11 = 2 [phi:print_address::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [892] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:print_address::@9->printf_uchar#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [892] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#1 [phi:print_address::@9->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [1044] phi from print_address::@9 to print_address::@10 [phi:print_address::@9->print_address::@10]
    // print_address::@10
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1045] call printf_str
    // [693] phi from print_address::@10 to printf_str [phi:print_address::@10->printf_str]
    // [693] phi printf_str::putc#34 = &cputc [phi:print_address::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [693] phi printf_str::s#34 = print_address::s1 [phi:print_address::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@11
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1046] printf_uint::uvalue#1 = (unsigned int)(char *)print_address::brom_ptr#0 -- vwum1=vwuz2 
    lda.z brom_ptr
    sta printf_uint.uvalue
    lda.z brom_ptr+1
    sta printf_uint.uvalue+1
    // [1047] call printf_uint
    // [1463] phi from print_address::@11 to printf_uint [phi:print_address::@11->printf_uint]
    // [1463] phi printf_uint::uvalue#3 = printf_uint::uvalue#1 [phi:print_address::@11->printf_uint#0] -- register_copy 
    jsr printf_uint
    // print_address::@return
    // }
    // [1048] return 
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
// unsigned long flash_write(__mem() char flash_ram_bank, __zp($37) char *flash_ram_address, __mem() unsigned long flash_rom_address)
flash_write: {
    .label flash_ram_address = $37
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [1049] flash_write::rom_chip_address#0 = flash_write::flash_rom_address#1 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // [1050] BRAM = flash_write::flash_ram_bank#0 -- vbuz1=vbum2 
    lda flash_ram_bank
    sta.z BRAM
    // [1051] phi from flash_write::bank_set_bram1 to flash_write::@1 [phi:flash_write::bank_set_bram1->flash_write::@1]
    // [1051] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#0] -- register_copy 
    // [1051] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#1] -- register_copy 
    // [1051] phi flash_write::flashed_bytes#2 = 0 [phi:flash_write::bank_set_bram1->flash_write::@1#2] -- vdum1=vduc1 
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
    // [1052] if(flash_write::flashed_bytes#2<$100) goto flash_write::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [1053] return 
    rts
    // flash_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [1054] rom_unlock::address#2 = flash_write::rom_chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
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
    // [1055] call rom_unlock
    // [1446] phi from flash_write::@2 to rom_unlock [phi:flash_write::@2->rom_unlock]
    // [1446] phi rom_unlock::unlock_code#3 = $a0 [phi:flash_write::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$a0
    sta rom_unlock.unlock_code
    // [1446] phi rom_unlock::address#3 = rom_unlock::address#2 [phi:flash_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // flash_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [1056] rom_byte_program::address#0 = flash_write::flash_rom_address#3 -- vdum1=vdum2 
    lda flash_rom_address
    sta rom_byte_program.address
    lda flash_rom_address+1
    sta rom_byte_program.address+1
    lda flash_rom_address+2
    sta rom_byte_program.address+2
    lda flash_rom_address+3
    sta rom_byte_program.address+3
    // [1057] rom_byte_program::value#0 = *flash_write::flash_ram_address#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta rom_byte_program.value
    // [1058] call rom_byte_program
    // [1470] phi from flash_write::@3 to rom_byte_program [phi:flash_write::@3->rom_byte_program]
    jsr rom_byte_program
    // flash_write::@4
    // flash_rom_address++;
    // [1059] flash_write::flash_rom_address#0 = ++ flash_write::flash_rom_address#3 -- vdum1=_inc_vdum1 
    inc flash_rom_address
    bne !+
    inc flash_rom_address+1
    bne !+
    inc flash_rom_address+2
    bne !+
    inc flash_rom_address+3
  !:
    // flash_ram_address++;
    // [1060] flash_write::flash_ram_address#0 = ++ flash_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [1061] flash_write::flashed_bytes#1 = ++ flash_write::flashed_bytes#2 -- vdum1=_inc_vdum1 
    inc flashed_bytes
    bne !+
    inc flashed_bytes+1
    bne !+
    inc flashed_bytes+2
    bne !+
    inc flashed_bytes+3
  !:
    // [1051] phi from flash_write::@4 to flash_write::@1 [phi:flash_write::@4->flash_write::@1]
    // [1051] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#0 [phi:flash_write::@4->flash_write::@1#0] -- register_copy 
    // [1051] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#0 [phi:flash_write::@4->flash_write::@1#1] -- register_copy 
    // [1051] phi flash_write::flashed_bytes#2 = flash_write::flashed_bytes#1 [phi:flash_write::@4->flash_write::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip_address: .dword 0
    flash_rom_address: .dword 0
    flashed_bytes: .dword 0
    flash_ram_bank: .byte 0
}
.segment Code
  // print_chip_KB
// void print_chip_KB(__mem() char rom_chip, __zp($25) char *kb)
print_chip_KB: {
    .label kb = $25
    // rom_chip * 10
    // [1063] print_chip_KB::$9 = print_chip_KB::rom_chip#3 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta __9
    // [1064] print_chip_KB::$10 = print_chip_KB::$9 + print_chip_KB::rom_chip#3 -- vbum1=vbum2_plus_vbum1 
    lda __10
    clc
    adc __9
    sta __10
    // [1065] print_chip_KB::$3 = print_chip_KB::$10 << 1 -- vbum1=vbum1_rol_1 
    asl __3
    // print_chip_line(3 + rom_chip * 10, 51, kb[0])
    // [1066] print_chip_line::x#9 = 3 + print_chip_KB::$3 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __3
    sta print_chip_line.x
    // [1067] print_chip_line::c#9 = *print_chip_KB::kb#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (kb),y
    sta print_chip_line.c
    // [1068] call print_chip_line
    // [1130] phi from print_chip_KB to print_chip_line [phi:print_chip_KB->print_chip_line]
    // [1130] phi print_chip_line::c#12 = print_chip_line::c#9 [phi:print_chip_KB->print_chip_line#0] -- register_copy 
    // [1130] phi print_chip_line::y#12 = $33 [phi:print_chip_KB->print_chip_line#1] -- vbum1=vbuc1 
    lda #$33
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#9 [phi:print_chip_KB->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@1
    // print_chip_line(3 + rom_chip * 10, 52, kb[1])
    // [1069] print_chip_line::x#10 = 3 + print_chip_KB::$3 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __3
    sta print_chip_line.x
    // [1070] print_chip_line::c#10 = print_chip_KB::kb#3[1] -- vbum1=pbuz2_derefidx_vbuc1 
    ldy #1
    lda (kb),y
    sta print_chip_line.c
    // [1071] call print_chip_line
    // [1130] phi from print_chip_KB::@1 to print_chip_line [phi:print_chip_KB::@1->print_chip_line]
    // [1130] phi print_chip_line::c#12 = print_chip_line::c#10 [phi:print_chip_KB::@1->print_chip_line#0] -- register_copy 
    // [1130] phi print_chip_line::y#12 = $34 [phi:print_chip_KB::@1->print_chip_line#1] -- vbum1=vbuc1 
    lda #$34
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#10 [phi:print_chip_KB::@1->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@2
    // print_chip_line(3 + rom_chip * 10, 53, kb[2])
    // [1072] print_chip_line::x#11 = 3 + print_chip_KB::$3 -- vbum1=vbuc1_plus_vbum2 
    lda #3
    clc
    adc __3
    sta print_chip_line.x
    // [1073] print_chip_line::c#11 = print_chip_KB::kb#3[2] -- vbum1=pbuz2_derefidx_vbuc1 
    ldy #2
    lda (kb),y
    sta print_chip_line.c
    // [1074] call print_chip_line
    // [1130] phi from print_chip_KB::@2 to print_chip_line [phi:print_chip_KB::@2->print_chip_line]
    // [1130] phi print_chip_line::c#12 = print_chip_line::c#11 [phi:print_chip_KB::@2->print_chip_line#0] -- register_copy 
    // [1130] phi print_chip_line::y#12 = $35 [phi:print_chip_KB::@2->print_chip_line#1] -- vbum1=vbuc1 
    lda #$35
    sta print_chip_line.y
    // [1130] phi print_chip_line::x#12 = print_chip_line::x#11 [phi:print_chip_KB::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@return
    // }
    // [1075] return 
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
    .label y = $43
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1076] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1077] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1078] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1079] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta __0
    // __conio.mapbase_bank = mapbase >> 7
    // [1080] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1081] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbum1=vbum1_rol_1 
    asl __1
    // MAKEWORD((mapbase)<<1,0)
    // [1082] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbum2_word_vbuc1 
    lda #0
    ldy __1
    sty __2+1
    sta __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1083] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1084] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta __7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1085] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda __8
    lsr
    lsr
    lsr
    lsr
    sta __8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1086] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1087] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbum1=vbum1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and __5
    sta __5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1088] screenlayer::$6 = screenlayer::$5 >> 6 -- vbum1=vbum1_ror_6 
    lda __6
    rol
    rol
    rol
    and #3
    sta __6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1089] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1090] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl __16
    // [1091] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy __16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1092] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum1_eq_vbuc1 
    lda __9
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta __9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1093] screenlayer::$18 = (char)screenlayer::$9
    // [1094] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1095] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec __11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1096] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda __11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1097] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum1_eq_vbuc1 
    lda __12
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta __12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1098] screenlayer::$19 = (char)screenlayer::$12
    // [1099] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1100] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec __14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1101] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda __14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1102] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1103] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1103] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1103] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1104] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1105] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1106] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta __17
    // [1107] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1108] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1109] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1103] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1103] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1103] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1110] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1111] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1112] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1113] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1114] call gotoxy
    // [463] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [463] phi gotoxy::y#25 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1115] return 
    rts
    // [1116] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1117] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1118] gotoxy::y#2 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1119] call gotoxy
    // [463] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1120] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1121] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__mem() char x, __mem() char y, __mem() char c)
cputcxy: {
    // gotoxy(x, y)
    // [1123] gotoxy::x#0 = cputcxy::x#68 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1124] gotoxy::y#0 = cputcxy::y#68 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1125] call gotoxy
    // [463] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1126] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1127] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1129] return 
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
    // [1131] gotoxy::x#4 = print_chip_line::x#12 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1132] gotoxy::y#4 = print_chip_line::y#12 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1133] call gotoxy
    // [463] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [463] phi gotoxy::y#25 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [463] phi gotoxy::x#25 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1134] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [1135] call textcolor
    // [445] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [445] phi textcolor::color#23 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1136] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [1137] call bgcolor
    // [450] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [1138] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1139] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1141] call textcolor
    // [445] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [445] phi textcolor::color#23 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1142] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [1143] call bgcolor
    // [450] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [450] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [1144] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1145] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [1147] stackpush(char) = print_chip_line::c#12 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1148] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [1150] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1151] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1153] call textcolor
    // [445] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [445] phi textcolor::color#23 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1154] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [1155] call bgcolor
    // [450] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [1156] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1157] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [1159] return 
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
    // [1160] gotoxy::x#5 = print_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1161] call gotoxy
    // [463] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [463] phi gotoxy::y#25 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #y
    sta gotoxy.y
    // [463] phi gotoxy::x#25 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1162] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [1163] call textcolor
    // [445] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [445] phi textcolor::color#23 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1164] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [1165] call bgcolor
    // [450] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [1166] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1167] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1169] call textcolor
    // [445] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [445] phi textcolor::color#23 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [1170] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [1171] call bgcolor
    // [450] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [450] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [1172] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1173] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1175] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1176] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1178] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1179] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1181] call textcolor
    // [445] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [445] phi textcolor::color#23 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1182] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [1183] call bgcolor
    // [450] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [450] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [1184] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1185] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1187] return 
    rts
  .segment Data
    .label x = print_chips.__33
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($25) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $25
    // [1189] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1189] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1190] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [1191] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1192] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [1193] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall17
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1195] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1189] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1189] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
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
    // [1196] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // cbm_k_clrchn()
    // [1197] call cbm_k_clrchn
    jsr cbm_k_clrchn
    // getin::@1
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [1199] getin::return#0 = getin::ch -- vbum1=vbum2 
    sta return
    // getin::@return
    // }
    // [1200] getin::return#1 = getin::return#0
    // [1201] return 
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
// void utoa(__mem() unsigned int value, __zp($25) char *buffer, __mem() char radix)
utoa: {
    .label buffer = $25
    .label digit_values = $2b
    // if(radix==DECIMAL)
    // [1203] if(utoa::radix#2==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1204] if(utoa::radix#2==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1205] if(utoa::radix#2==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1206] if(utoa::radix#2==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1207] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1208] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1209] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1210] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1211] return 
    rts
    // [1212] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1212] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1212] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [1212] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1212] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1212] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [1212] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1212] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1212] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [1212] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1212] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1212] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [1213] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1213] phi utoa::buffer#10 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1213] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1213] phi utoa::value#3 = utoa::value#10 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1213] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1214] utoa::$4 = utoa::max_digits#7 - 1 -- vbum1=vbum2_minus_1 
    ldx max_digits
    dex
    stx __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1215] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbum2_then_la1 
    lda digit
    cmp __4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1216] utoa::$11 = (char)utoa::value#3 -- vbum1=_byte_vwum2 
    lda value
    sta __11
    // [1217] *utoa::buffer#10 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1218] utoa::buffer#3 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1219] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1220] utoa::$10 = utoa::digit#2 << 1 -- vbum1=vbum2_rol_1 
    lda digit
    asl
    sta __10
    // [1221] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbum3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1222] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [1223] if(utoa::value#3>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [1224] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1224] phi utoa::buffer#15 = utoa::buffer#10 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1224] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1224] phi utoa::value#7 = utoa::value#3 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1225] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1213] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1213] phi utoa::buffer#10 = utoa::buffer#15 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1213] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1213] phi utoa::value#3 = utoa::value#7 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1213] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1226] utoa_append::buffer#0 = utoa::buffer#10 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1227] utoa_append::value#0 = utoa::value#3
    // [1228] utoa_append::sub#0 = utoa::digit_value#0
    // [1229] call utoa_append
    // [1515] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1230] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1231] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1232] utoa::buffer#4 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1224] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1224] phi utoa::buffer#15 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1224] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1224] phi utoa::value#7 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    __4: .byte 0
    __10: .byte 0
    __11: .byte 0
    digit_value: .word 0
    digit: .byte 0
    .label value = printf_sint.value
    radix: .byte 0
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($2b) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, __mem() char format_justify_left, char format_sign_always, __mem() char format_zero_padding, __mem() char format_upper_case, char format_radix)
printf_number_buffer: {
    .label putc = $2b
    // if(format.min_length)
    // [1234] if(0==printf_number_buffer::format_min_length#4) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b6
    // [1235] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [1236] call strlen
    // [796] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [796] phi strlen::str#9 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1237] strlen::return#11 = strlen::len#2
    // printf_number_buffer::@14
    // [1238] printf_number_buffer::$19 = strlen::return#11
    // signed char len = (signed char)strlen(buffer.digits)
    // [1239] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwum2 
    // There is a minimum length - work out the padding
    lda __19
    sta len
    // if(buffer.sign)
    // [1240] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [1241] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1242] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [1242] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [1243] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#4 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1244] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1246] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [1246] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1245] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [1246] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [1246] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1247] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [1248] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [1249] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [1250] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1251] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1252] call printf_padding
    // [1188] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1188] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1188] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@8->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1188] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1253] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [1254] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1255] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall18
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1257] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [1258] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1259] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1260] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1261] call printf_padding
    // [1188] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1188] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1188] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@10->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [1188] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1262] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbum1_then_la1 
    lda format_upper_case
    beq __b5
    // [1263] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1264] call strupr
    // [1522] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1265] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1266] call printf_str
    // [693] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [693] phi printf_str::putc#34 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [693] phi printf_str::s#34 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1267] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1268] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1269] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1270] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1271] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1272] call printf_padding
    // [1188] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1188] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1188] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@12->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1188] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1273] return 
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
// char * strncpy(__zp($22) char *dst, __zp($25) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label dst = $22
    .label src = $25
    // [1275] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1275] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1275] phi strncpy::src#2 = file [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z src
    lda #>file
    sta.z src+1
    // [1275] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1276] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwum1_lt_vwuc1_then_la1 
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
    // [1277] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1278] strncpy::c#0 = *strncpy::src#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [1279] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1280] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1281] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1281] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1282] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1283] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1284] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [1275] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1275] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1275] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1275] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
    // [1285] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbuz2 
    lda.z filename
    sta.z strlen.str
    lda.z filename+1
    sta.z strlen.str+1
    // [1286] call strlen
    // [796] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [796] phi strlen::str#9 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1287] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [1288] cbm_k_setnam::$0 = strlen::return#0
    // __mem char filename_len = (char)strlen(filename)
    // [1289] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwum2 
    lda __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [1291] return 
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
    // [1293] return 
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
    // [1294] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [1296] cbm_k_open::return#0 = cbm_k_open::status -- vbum1=vbum2 
    sta return
    // cbm_k_open::@return
    // }
    // [1297] cbm_k_open::return#1 = cbm_k_open::return#0
    // [1298] return 
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
// int ferror(__zp($27) struct $1 *stream)
ferror: {
    .label stream = $27
    .label msg = $25
    .label __22 = $2d
    .label __23 = $31
    .label __24 = $33
    .label __25 = $35
    // unsigned int sp = (unsigned int)stream & ~0x8000
    // [1300] ferror::sp#0 = (unsigned int)ferror::stream#2 & ~$8000 -- vwum1=vwuz2_band_vwuc1 
    lda.z stream
    and #<$8000^$ffff
    sta sp
    lda.z stream+1
    and #>$8000^$ffff
    sta sp+1
    // cbm_k_readst()
    // [1301] call cbm_k_readst
    jsr cbm_k_readst
    // [1302] cbm_k_readst::return#12 = cbm_k_readst::return#1
    // ferror::@4
    // [1303] ferror::$1 = cbm_k_readst::return#12
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1304] ferror::$22 = (char *)&__stdio_file+$46 + ferror::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __22
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __22+1
    // [1305] *ferror::$22 = ferror::$1 -- _deref_pbuz1=vbum2 
    lda __1
    ldy #0
    sta (__22),y
    // cbm_k_setlfs(15, 8, 15)
    // [1306] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [1307] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [1308] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [1309] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@5
    // cbm_k_setnam("")
    // [1310] cbm_k_setnam::filename = ferror::filename -- pbuz1=pbuc1 
    lda #<filename
    sta.z cbm_k_setnam.filename
    lda #>filename
    sta.z cbm_k_setnam.filename+1
    // [1311] call cbm_k_setnam
    jsr cbm_k_setnam
    // [1312] phi from ferror::@5 to ferror::@6 [phi:ferror::@5->ferror::@6]
    // ferror::@6
    // cbm_k_open()
    // [1313] call cbm_k_open
    jsr cbm_k_open
    // ferror::@7
    // cbm_k_chkin(15)
    // [1314] cbm_k_chkin::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin.channel
    // [1315] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1316] phi from ferror::@7 to ferror::@8 [phi:ferror::@7->ferror::@8]
    // ferror::@8
    // char ch = cbm_k_chrin()
    // [1317] call cbm_k_chrin
    jsr cbm_k_chrin
    // [1318] cbm_k_chrin::return#2 = cbm_k_chrin::return#1
    // ferror::@9
    // [1319] ferror::ch#0 = cbm_k_chrin::return#2
    // sp * __STDIO_FILECOUNT
    // [1320] ferror::$14 = ferror::sp#0 << 1 -- vwum1=vwum2_rol_1 
    lda sp
    asl
    sta __14
    lda sp+1
    rol
    sta __14+1
    // char *msg = __stdio_file.error + sp * __STDIO_FILECOUNT
    // [1321] ferror::msg#0 = (char *)&__stdio_file+$48 + ferror::$14 -- pbuz1=pbuc1_plus_vwum2 
    lda __14
    clc
    adc #<__stdio_file+$48
    sta.z msg
    lda __14+1
    adc #>__stdio_file+$48
    sta.z msg+1
    // cbm_k_readst()
    // [1322] call cbm_k_readst
    jsr cbm_k_readst
    // [1323] cbm_k_readst::return#13 = cbm_k_readst::return#1
    // ferror::@10
    // [1324] ferror::$12 = cbm_k_readst::return#13
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1325] ferror::$23 = (char *)&__stdio_file+$46 + ferror::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __23
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __23+1
    // [1326] *ferror::$23 = ferror::$12 -- _deref_pbuz1=vbum2 
    lda __12
    ldy #0
    sta (__23),y
    // [1327] phi from ferror::@10 ferror::@12 to ferror::@1 [phi:ferror::@10/ferror::@12->ferror::@1]
    // [1327] phi ferror::msg#2 = ferror::msg#0 [phi:ferror::@10/ferror::@12->ferror::@1#0] -- register_copy 
    // [1327] phi ferror::ch#2 = ferror::ch#0 [phi:ferror::@10/ferror::@12->ferror::@1#1] -- register_copy 
    // ferror::@1
  __b1:
    // while(!__stdio_file.status[sp])
    // [1328] ferror::$24 = (char *)&__stdio_file+$46 + ferror::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __24
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __24+1
    // [1329] if(0==*ferror::$24) goto ferror::@2 -- 0_eq__deref_pbuz1_then_la1 
    ldy #0
    lda (__24),y
    cmp #0
    beq __b2
    // ferror::@3
    // cbm_k_close(15)
    // [1330] cbm_k_close::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close.channel
    // [1331] call cbm_k_close
    jsr cbm_k_close
    // ferror::@13
    // strlen(__stdio_file.error + sp * __STDIO_FILECOUNT)
    // [1332] strlen::str#5 = (char *)&__stdio_file+$48 + ferror::$14 -- pbuz1=pbuc1_plus_vwum2 
    lda __14
    clc
    adc #<__stdio_file+$48
    sta.z strlen.str
    lda __14+1
    adc #>__stdio_file+$48
    sta.z strlen.str+1
    // [1333] call strlen
    // [796] phi from ferror::@13 to strlen [phi:ferror::@13->strlen]
    // [796] phi strlen::str#9 = strlen::str#5 [phi:ferror::@13->strlen#0] -- register_copy 
    jsr strlen
    // ferror::@return
    // }
    // [1334] return 
    rts
    // ferror::@2
  __b2:
    // *msg = ch
    // [1335] *ferror::msg#2 = ferror::ch#2 -- _deref_pbuz1=vbum2 
    lda ch
    ldy #0
    sta (msg),y
    // msg++;
    // [1336] ferror::msg#1 = ++ ferror::msg#2 -- pbuz1=_inc_pbuz1 
    inc.z msg
    bne !+
    inc.z msg+1
  !:
    // cbm_k_chrin()
    // [1337] call cbm_k_chrin
    jsr cbm_k_chrin
    // [1338] cbm_k_chrin::return#3 = cbm_k_chrin::return#1
    // ferror::@11
    // ch = cbm_k_chrin()
    // [1339] ferror::ch#1 = cbm_k_chrin::return#3
    // cbm_k_readst()
    // [1340] call cbm_k_readst
    jsr cbm_k_readst
    // [1341] cbm_k_readst::return#14 = cbm_k_readst::return#1
    // ferror::@12
    // [1342] ferror::$19 = cbm_k_readst::return#14
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1343] ferror::$25 = (char *)&__stdio_file+$46 + ferror::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __25
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __25+1
    // [1344] *ferror::$25 = ferror::$19 -- _deref_pbuz1=vbum2 
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
    // [1345] cbm_k_close::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldachannel jsrCBM_CLOSE stastatus  }
    lda channel
    jsr CBM_CLOSE
    sta status
    // return status;
    // [1347] cbm_k_close::return#0 = cbm_k_close::status -- vbum1=vbum2 
    sta return
    // cbm_k_close::@return
    // }
    // [1348] cbm_k_close::return#1 = cbm_k_close::return#0
    // [1349] return 
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
    // [1350] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [1352] return 
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
    // [1353] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [1355] cbm_k_readst::return#0 = cbm_k_readst::status -- vbum1=vbum2 
    sta return
    // cbm_k_readst::@return
    // }
    // [1356] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [1357] return 
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
// void uctoa(__mem() char value, __zp($25) char *buffer, __mem() char radix)
uctoa: {
    .label buffer = $25
    .label digit_values = $22
    // if(radix==DECIMAL)
    // [1358] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1359] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1360] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1361] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1362] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1363] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1364] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1365] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1366] return 
    rts
    // [1367] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1367] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1367] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1367] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1367] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1367] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [1367] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1367] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1367] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1367] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1367] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1367] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [1368] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1368] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1368] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1368] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1368] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1369] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbum1=vbum2_minus_1 
    ldx max_digits
    dex
    stx __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1370] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbum2_then_la1 
    lda digit
    cmp __4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1371] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1372] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1373] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1374] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [1375] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [1376] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [1377] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1377] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1377] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1377] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1378] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1368] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1368] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1368] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1368] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1368] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1379] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1380] uctoa_append::value#0 = uctoa::value#2
    // [1381] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1382] call uctoa_append
    // [1537] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1383] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1384] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1385] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1377] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1377] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1377] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1377] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
    // [1387] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1388] ultoa::value#1 = printf_ulong::uvalue#2
    // [1389] call ultoa
  // Format number into buffer
    // [1544] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1390] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1391] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#2
    // [1392] call printf_number_buffer
  // Print using format
    // [1233] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1233] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_upper_case
    // [1233] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1233] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1233] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    // [1233] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_justify_left
    // [1233] phi printf_number_buffer::format_min_length#4 = 6 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbum1=vbuc1 
    lda #6
    sta printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1393] return 
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
// __mem() unsigned int fgets(__zp($22) char *ptr, unsigned int size, __zp($29) struct $1 *stream)
fgets: {
    .const size = $80
    .label ptr = $22
    .label stream = $29
    .label __30 = $3b
    .label __31 = $3d
    .label __32 = $2d
    .label __33 = $31
    .label __34 = $33
    .label __35 = $35
    // unsigned int sp = (unsigned int)stream & ~0x8000
    // [1394] fgets::sp#0 = (unsigned int)fgets::stream#0 & ~$8000 -- vwum1=vwuz2_band_vwuc1 
    lda.z stream
    and #<$8000^$ffff
    sta sp
    lda.z stream+1
    and #>$8000^$ffff
    sta sp+1
    // cbm_k_chkin(__stdio_file.channel[sp])
    // [1395] fgets::$30 = (char *)&__stdio_file+$40 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$40
    sta.z __30
    lda sp+1
    adc #>__stdio_file+$40
    sta.z __30+1
    // [1396] cbm_k_chkin::channel = *fgets::$30 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (__30),y
    sta cbm_k_chkin.channel
    // [1397] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1398] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [1399] call cbm_k_readst
    jsr cbm_k_readst
    // [1400] cbm_k_readst::return#10 = cbm_k_readst::return#1
    // fgets::@12
    // [1401] fgets::$2 = cbm_k_readst::return#10
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1402] fgets::$31 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __31
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __31+1
    // [1403] *fgets::$31 = fgets::$2 -- _deref_pbuz1=vbum2 
    lda __2
    ldy #0
    sta (__31),y
    // if(__stdio_file.status[sp])
    // [1404] fgets::$32 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __32
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __32+1
    // [1405] if(0==*fgets::$32) goto fgets::@1 -- 0_eq__deref_pbuz1_then_la1 
    lda (__32),y
    cmp #0
    beq __b8
    // [1406] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [1406] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [1407] return 
    rts
    // [1408] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [1408] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [1408] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@12->fgets::@1#1] -- vwum1=vwuc1 
    lda #<size
    sta remaining
    lda #>size
    sta remaining+1
    // [1408] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [1408] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [1408] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [1408] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [1408] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [1409] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwum1_ge_vbuc1_then_la1 
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
    // [1410] cbm_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cbm_k_macptr.bytes
    // [1411] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1412] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1413] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [1414] fgets::bytes#3 = cbm_k_macptr::return#4
    // [1415] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [1415] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [1416] call cbm_k_readst
    jsr cbm_k_readst
    // [1417] cbm_k_readst::return#11 = cbm_k_readst::return#1
    // fgets::@15
    // [1418] fgets::$10 = cbm_k_readst::return#11
    // __stdio_file.status[sp] = cbm_k_readst()
    // [1419] fgets::$33 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __33
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __33+1
    // [1420] *fgets::$33 = fgets::$10 -- _deref_pbuz1=vbum2 
    lda __10
    ldy #0
    sta (__33),y
    // __stdio_file.status[sp] & 0xBF
    // [1421] fgets::$34 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __34
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __34+1
    // [1422] fgets::$11 = *fgets::$34 & $bf -- vbum1=_deref_pbuz2_band_vbuc1 
    lda #$bf
    and (__34),y
    sta __11
    // if(__stdio_file.status[sp] & 0xBF)
    // [1423] if(0==fgets::$11) goto fgets::@4 -- 0_eq_vbum1_then_la1 
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [1424] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwum1_neq_vwuc1_then_la1 
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
    // [1425] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [1426] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1427] fgets::$15 = byte1  fgets::ptr#0 -- vbum1=_byte1_pbuz2 
    sta __15
    // if(BYTE1(ptr) == 0xC0)
    // [1428] if(fgets::$15!=$c0) goto fgets::@6 -- vbum1_neq_vbuc1_then_la1 
    lda #$c0
    cmp __15
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [1429] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1430] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [1430] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [1431] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // __stdio_file.status[sp] == 0
    // [1432] fgets::$35 = (char *)&__stdio_file+$46 + fgets::sp#0 -- pbuz1=pbuc1_plus_vwum2 
    lda sp
    clc
    adc #<__stdio_file+$46
    sta.z __35
    lda sp+1
    adc #>__stdio_file+$46
    sta.z __35+1
    // while ((__stdio_file.status[sp] == 0) && ((size && remaining) || !size))
    // [1433] if(*fgets::$35==0) goto fgets::@16 -- _deref_pbuz1_eq_0_then_la1 
    ldy #0
    lda (__35),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [1434] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [1435] cbm_k_chkin::channel = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin.channel
    // [1436] call cbm_k_chkin
    jsr cbm_k_chkin
    // [1406] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [1406] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [1437] cbm_k_macptr::bytes = $80 -- vbum1=vbuc1 
    lda #$80
    sta cbm_k_macptr.bytes
    // [1438] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [1439] call cbm_k_macptr
    jsr cbm_k_macptr
    // [1440] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [1441] fgets::bytes#2 = cbm_k_macptr::return#3
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
// __mem() char rom_byte_verify(__zp($29) char *ptr_rom, __mem() char value)
rom_byte_verify: {
    .label ptr_rom = $29
    // if (*ptr_rom != value)
    // [1442] if(*rom_byte_verify::ptr_rom#0==rom_byte_verify::value#0) goto rom_byte_verify::@1 -- _deref_pbuz1_eq_vbum2_then_la1 
    lda value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1443] phi from rom_byte_verify to rom_byte_verify::@2 [phi:rom_byte_verify->rom_byte_verify::@2]
    // rom_byte_verify::@2
    // [1444] phi from rom_byte_verify::@2 to rom_byte_verify::@1 [phi:rom_byte_verify::@2->rom_byte_verify::@1]
    // [1444] phi rom_byte_verify::return#0 = 0 [phi:rom_byte_verify::@2->rom_byte_verify::@1#0] -- vbum1=vbuc1 
    tya
    sta return
    rts
    // [1444] phi from rom_byte_verify to rom_byte_verify::@1 [phi:rom_byte_verify->rom_byte_verify::@1]
  __b2:
    // [1444] phi rom_byte_verify::return#0 = 1 [phi:rom_byte_verify->rom_byte_verify::@1#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // rom_byte_verify::@1
    // rom_byte_verify::@return
    // }
    // [1445] return 
    rts
  .segment Data
    return: .byte 0
    value: .byte 0
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
    // [1447] rom_unlock::chip_address#0 = rom_unlock::address#3 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // [1448] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
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
    // [1449] call rom_write_byte
    // [1570] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1570] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbum1=vbuc1 
    lda #$aa
    sta rom_write_byte.value
    // [1570] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1450] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vdum1=vdum2_plus_vwuc1 
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
    // [1451] call rom_write_byte
    // [1570] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1570] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbum1=vbuc1 
    lda #$55
    sta rom_write_byte.value
    // [1570] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1452] rom_write_byte::address#2 = rom_unlock::address#3 -- vdum1=vdum2 
    lda address
    sta rom_write_byte.address
    lda address+1
    sta rom_write_byte.address+1
    lda address+2
    sta rom_write_byte.address+2
    lda address+3
    sta rom_write_byte.address+3
    // [1453] rom_write_byte::value#2 = rom_unlock::unlock_code#3 -- vbum1=vbum2 
    lda unlock_code
    sta rom_write_byte.value
    // [1454] call rom_write_byte
    // [1570] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1570] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1570] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1455] return 
    rts
  .segment Data
    chip_address: .dword 0
    address: .dword 0
    unlock_code: .byte 0
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
    // [1457] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [1458] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    lda (ptr_rom),y
    sta test2
    // test1 & 0x40
    // [1459] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbum1=vbum1_band_vbuc1 
    lda #$40
    and __0
    sta __0
    // test2 & 0x40
    // [1460] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbum1=vbum1_band_vbuc1 
    lda #$40
    and __1
    sta __1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [1461] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbum1_neq_vbum2_then_la1 
    lda __0
    cmp __1
    bne __b1
    // rom_wait::@return
    // }
    // [1462] return 
    rts
  .segment Data
    .label __0 = test1
    .label __1 = test2
    test1: .byte 0
    test2: .byte 0
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __mem() unsigned int uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uint: {
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1464] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1465] utoa::value#2 = printf_uint::uvalue#3
    // [1466] call utoa
  // Format number into buffer
    // [1202] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    // [1202] phi utoa::value#10 = utoa::value#2 [phi:printf_uint::@1->utoa#0] -- register_copy 
    // [1202] phi utoa::radix#2 = HEXADECIMAL [phi:printf_uint::@1->utoa#1] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta utoa.radix
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1467] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1468] call printf_number_buffer
  // Print using format
    // [1233] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1233] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_upper_case
    // [1233] phi printf_number_buffer::putc#10 = &cputc [phi:printf_uint::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1233] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1233] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_zero_padding
    // [1233] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbum1=vbuc1 
    sta printf_number_buffer.format_justify_left
    // [1233] phi printf_number_buffer::format_min_length#4 = 4 [phi:printf_uint::@2->printf_number_buffer#5] -- vbum1=vbuc1 
    lda #4
    sta printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1469] return 
    rts
  .segment Data
    .label uvalue = printf_sint.value
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
    .label rom_ptr1_return = $2d
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1471] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1___2
    lda address+1
    sta rom_ptr1___2+1
    // [1472] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1473] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [1474] rom_write_byte::address#3 = rom_byte_program::address#0
    // [1475] rom_write_byte::value#3 = rom_byte_program::value#0
    // [1476] call rom_write_byte
    // [1570] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [1570] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [1570] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [1477] rom_wait::ptr_rom#0 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [1478] call rom_wait
    // [1456] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [1456] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [1479] return 
    rts
  .segment Data
    .label rom_ptr1___0 = rom_ptr1___2
    rom_ptr1___2: .word 0
    .label address = rom_write_byte.address
    .label value = rom_write_byte.value
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    // __conio.width+1
    // [1480] insertup::$0 = *((char *)&__conio+6) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta __0
    // unsigned char width = (__conio.width+1) * 2
    // [1481] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbum1_rol_1 
    // {asm{.byte $db}}
    asl width
    // [1482] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1482] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1483] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [1484] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1485] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1486] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1487] insertup::$4 = insertup::y#2 + 1 -- vbum1=vbum2_plus_1 
    lda y
    inc
    sta __4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1488] insertup::$6 = insertup::y#2 << 1 -- vbum1=vbum2_rol_1 
    lda y
    asl
    sta __6
    // [1489] insertup::$7 = insertup::$4 << 1 -- vbum1=vbum1_rol_1 
    asl __7
    // [1490] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [1491] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbum2 
    ldy __6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [1492] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [1493] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbum2 
    ldy __7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [1494] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [1495] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1496] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [1482] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1482] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    .label c = $24
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1497] clearline::$3 = *((char *)&__conio+1) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta __3
    // [1498] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbum2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1499] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1500] clearline::$0 = byte0  clearline::addr#0 -- vbum1=_byte0_vwum2 
    lda addr
    sta __0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1501] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1502] clearline::$1 = byte1  clearline::addr#0 -- vbum1=_byte1_vwum2 
    lda addr+1
    sta __1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1503] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1504] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta __2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1505] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1506] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1507] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1507] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1508] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1509] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1510] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1511] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1512] return 
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
    // [1514] return 
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
// __mem() unsigned int utoa_append(__zp($2f) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $2f
    // [1516] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1516] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1516] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1517] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [1518] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1519] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1520] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1521] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [1516] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1516] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1516] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
    .label src = $27
    // [1523] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1523] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1524] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1525] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1526] toupper::ch#0 = *strupr::src#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta toupper.ch
    // [1527] call toupper
    jsr toupper
    // [1528] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1529] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1530] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbum2 
    lda __0
    ldy #0
    sta (src),y
    // src++;
    // [1531] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1523] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1523] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
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
    // [1532] cbm_k_chrin::value = 0 -- vbum1=vbuc1 
    lda #0
    sta value
    // asm
    // asm { jsrCBM_CHRIN stavalue  }
    jsr CBM_CHRIN
    sta value
    // return value;
    // [1534] cbm_k_chrin::return#0 = cbm_k_chrin::value -- vbum1=vbum2 
    sta return
    // cbm_k_chrin::@return
    // }
    // [1535] cbm_k_chrin::return#1 = cbm_k_chrin::return#0
    // [1536] return 
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
// __mem() char uctoa_append(__zp($2b) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $2b
    // [1538] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1538] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1538] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1539] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1540] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
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
    // [1542] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1543] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [1538] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1538] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1538] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// void ultoa(__mem() unsigned long value, __zp($27) char *buffer, char radix)
ultoa: {
    .label buffer = $27
    // [1545] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1545] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1545] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1545] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1545] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1546] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbum1_lt_vbuc1_then_la1 
    lda digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1547] ultoa::$11 = (char)ultoa::value#2 -- vbum1=_byte_vdum2 
    lda value
    sta __11
    // [1548] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
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
    // [1552] ultoa::$10 = ultoa::digit#2 << 2 -- vbum1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta __10
    // [1553] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vdum1=pduc1_derefidx_vbum2 
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
    // [1554] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b5
    // ultoa::@7
    // [1555] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vdum1_ge_vdum2_then_la1 
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
    // [1556] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1556] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1556] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1556] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1557] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
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
    // [1608] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
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
    // [1556] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1556] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
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
    // [1567] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cbm_k_macptr::@return
    // }
    // [1568] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [1569] return 
    rts
  .segment Data
    bytes: .byte 0
    bytes_read: .word 0
    .label return = fgets.bytes
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
    .label rom_ptr1_return = $31
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [1571] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbum1=_byte2_vdum2 
    lda address+2
    sta rom_bank1___0
    // BYTE1(address)
    // [1572] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbum1=_byte1_vdum2 
    lda address+1
    sta rom_bank1___1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1573] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwum1=vbum2_word_vbum3 
    lda rom_bank1___0
    sta rom_bank1___2+1
    lda rom_bank1___1
    sta rom_bank1___2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1574] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1575] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1576] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1___2
    lda address+1
    sta rom_ptr1___2+1
    // [1577] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1___0
    and #<$3fff
    sta rom_ptr1___0
    lda rom_ptr1___0+1
    and #>$3fff
    sta rom_ptr1___0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1578] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwum2_plus_vwuc1 
    lda rom_ptr1___0
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda rom_ptr1___0+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::@1
    // bank_set_brom(bank_rom)
    // [1579] bank_set_brom::bank#2 = rom_write_byte::rom_bank1_return#0
    // [1580] call bank_set_brom
    // [769] phi from rom_write_byte::@1 to bank_set_brom [phi:rom_write_byte::@1->bank_set_brom]
    // [769] phi bank_set_brom::bank#11 = bank_set_brom::bank#2 [phi:rom_write_byte::@1->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_write_byte::@2
    // *ptr_rom = value
    // [1581] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbum2 
    lda value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [1582] return 
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
    // [1583] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1584] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbum1=_byte0_vwum2 
    lda soffset_vram
    sta __0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1585] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1586] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbum1=_byte1_vwum2 
    lda soffset_vram+1
    sta __1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1587] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1588] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbum1=vbum1_bor_vbuc1 
    lda #VERA_INC_1
    ora __2
    sta __2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1589] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1590] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1591] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbum1=_byte0_vwum2 
    lda doffset_vram
    sta __3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1592] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1593] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbum1=_byte1_vwum2 
    lda doffset_vram+1
    sta __4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1594] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1595] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbum1=vbum1_bor_vbuc1 
    lda #VERA_INC_1
    ora __5
    sta __5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1596] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // [1597] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1597] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1598] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [1599] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1600] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1601] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1602] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
    // [1603] if(toupper::ch#0<'a'pm) goto toupper::@return -- vbum1_lt_vbuc1_then_la1 
    lda ch
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1604] if(toupper::ch#0<='z'pm) goto toupper::@1 -- vbum1_le_vbuc1_then_la1 
    lda #'z'
    cmp ch
    bcs __b1
    // [1606] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1606] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1605] toupper::return#0 = toupper::ch#0 + 'A'pm-'a'pm -- vbum1=vbum1_plus_vbuc1 
    lda #'A'-'a'
    clc
    adc return
    sta return
    // toupper::@return
  __breturn:
    // }
    // [1607] return 
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
// __mem() unsigned long ultoa_append(__zp($2d) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $2d
    // [1609] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1609] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1609] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1610] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [1611] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1612] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1613] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1614] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [1609] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1609] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1609] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
