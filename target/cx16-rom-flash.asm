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
 * The addressing of the ROM chips follow 19 bit wide addressing mode, and is implemented on the CX16 in a special way.  
 * The CX16 has 32 banks ROM of 16KB each, so it implements a banking solution to address the 19 bit wide ROM address, 
 * where the most significant 5 bits of the 19 bit wide ROM address are configured through zero page $01, 
 * configuring one of the 32 ROM banks, 
 * while the CX16 main address bus is used to addresses the remaining 14 bits of the 19 bit ROM address. 
 * 
 * This results in the following architecture, where this flashing program uses a combination of setting the ROM bank
 * and using the main address bus to select the 19 bit wide ROM addresses.
 * 
 * 
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *                                   | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *                                   | BANK (ZP $01)     | MAIN ADDRESS BUS (+ $C000)                            |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *      ROM_BANK_MASK  0x7C000       | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *      ROM_PTR_MASK   0x03FFF       | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *
 * Designing this program, there was also one important caveat to keep in mind ... What does the 6502 CPU see?  
 * The CPU uses zero page $01 to set the ROM banks, but the lower 14 bits of the 19 bit wide ROM address is visible for the CPU
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
 * @version 0.1
 * @date 2022-10-16
 * 
 * @copyright Copyright (c) 2022
 * 
 */
  // Upstart
.cpu _65c02
  // Commander X16 PRG executable file
.file [name="cx16-rom-flash.prg", type="prg", segments="Program"]
.segmentdef Program [segments="Basic, Code, Data"]
.segmentdef Basic [start=$0801]
.segmentdef Code [start=$80d]
.segmentdef Data [startAfter="Code"]
.segment Basic
:BasicUpstart(__start)
  // Global Constants & labels
  .const WHITE = 1
  .const BLUE = 6
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
  .const SIZEOF_STRUCT___1 = $8d
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
    .label __4 = $6b
    .label __5 = $69
    .label __6 = $6b
    .label __7 = $d0
    // screenlayer1()
    // [9] call screenlayer1
    jsr screenlayer1
    // [10] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [11] call textcolor
    jsr textcolor
    // [12] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [13] call bgcolor
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
    // [20] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwuz2 
    lda.z __4+1
    sta.z __5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [21] *((char *)&__conio+$d) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // cbm_k_plot_get()
    // [22] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [23] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [24] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [25] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuz1=_byte0_vwuz2 
    lda.z __6
    sta.z __7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [26] *((char *)&__conio+$e) = conio_x16_init::$7 -- _deref_pbuc1=vbuz1 
    sta __conio+$e
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [27] gotoxy::x#0 = *((char *)&__conio+$d) -- vbuz1=_deref_pbuc1 
    lda __conio+$d
    sta.z gotoxy.x
    // [28] gotoxy::y#0 = *((char *)&__conio+$e) -- vbuz1=_deref_pbuc1 
    lda __conio+$e
    sta.z gotoxy.y
    // [29] call gotoxy
    // [307] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [307] phi gotoxy::y#3 = gotoxy::y#0 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [307] phi gotoxy::x#3 = gotoxy::x#0 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
}
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__zp($2c) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label __1 = $22
    .label __2 = $44
    .label __3 = $45
    .label c = $2c
    // [33] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
    // if(c=='\n')
    // [34] if(cputc::c#0==' 'pm) goto cputc::@1 -- vbuz1_eq_vbuc1_then_la1 
  .encoding "petscii_mixed"
    lda #'\n'
    cmp.z c
    beq __b1
    // cputc::@2
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [35] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [36] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z __1
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [37] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [38] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z __2
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [39] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [40] cputc::$3 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [41] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [42] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuz1 
    lda.z c
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [43] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // if(!__conio.hscroll[__conio.layer])
    // [44] if(0==((char *)&__conio+$11)[*((char *)&__conio)]) goto cputc::@5 -- 0_eq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$11,y
    cmp #0
    beq __b5
    // cputc::@3
    // if(__conio.cursor_x >= __conio.mapwidth)
    // [45] if(*((char *)&__conio+$d)>=*((char *)&__conio+6)) goto cputc::@6 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio+$d
    cmp __conio+6
    bcs __b6
    // cputc::@4
    // __conio.cursor_x++;
    // [46] *((char *)&__conio+$d) = ++ *((char *)&__conio+$d) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$d
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
    // [52] if(*((char *)&__conio+$d)>=*((char *)&__conio+4)) goto cputc::@8 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio+$d
    cmp __conio+4
    bcs __b8
    // cputc::@9
    // __conio.cursor_x++;
    // [53] *((char *)&__conio+$d) = ++ *((char *)&__conio+$d) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$d
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
}
  // main
main: {
    .const bank_set_bram1_bank = 1
    .const bank_set_bram2_bank = 1
    .const bank_set_bram5_bank = 0
    .label __43 = $c2
    .label __51 = $be
    .label __60 = $49
    .label __63 = $4f
    .label __67 = $38
    .label __71 = $ba
    .label __79 = $58
    .label __83 = $ad
    .label __87 = $60
    .label rom_manufacturer_id = $4c
    .label fp = $d4
    .label bytes = $55
    .label bytes_1 = $67
    // read from bank 1 in bram.
    // read from bank 1 in bram.
    .label ram_addr = $c8
    .label rom_addr = $b4
    // read from bank 1 in bram.
    // read from bank 1 in bram.
    .label ram_addr_1 = $b2
    .label rom_addr_1 = $79
    // read from bank 1 in bram.
    // read from bank 1 in bram.
    .label ram_addr_2 = $ab
    .label b = $78
    .label b1 = $7d
    // read from bank 1 in bram.
    // read from bank 1 in bram.
    .label ram_addr_3 = $71
    .label bank = $74
    .label v = $75
    .label w = $b8
    .label rom_device = $cc
    .label rom_device_id = $cb
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@49
    // cbm_x_charset(3, (char*)0)
    // [62] cbm_x_charset::charset = 3 -- vbuz1=vbuc1 
    lda #3
    sta.z cbm_x_charset.charset
    // [63] cbm_x_charset::offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cbm_x_charset.offset
    sta.z cbm_x_charset.offset+1
    // [64] call cbm_x_charset
    jsr cbm_x_charset
    // [65] phi from main::@49 to main::@55 [phi:main::@49->main::@55]
    // main::@55
    // clrscr()
    // [66] call clrscr
    jsr clrscr
    // [67] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
    // printf("rom flash utility\n")
    // [68] call printf_str
    // [353] phi from main::@56 to printf_str [phi:main::@56->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@56->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s [phi:main::@56->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [69] phi from main::@56 to main::@57 [phi:main::@56->main::@57]
    // main::@57
    // printf("\nrom chipset device determination:\n\n")
    // [70] call printf_str
    // [353] phi from main::@57 to printf_str [phi:main::@57->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@57->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s1 [phi:main::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [71] phi from main::@57 to main::@58 [phi:main::@57->main::@58]
    // main::@58
    // rom_unlock(0x05555, 0x90)
    // [72] call rom_unlock
    // [362] phi from main::@58 to rom_unlock [phi:main::@58->rom_unlock]
    // [362] phi rom_unlock::unlock_code#10 = $90 [phi:main::@58->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [362] phi rom_unlock::address#10 = $5555 [phi:main::@58->rom_unlock#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_unlock.address
    lda #>$5555
    sta.z rom_unlock.address+1
    lda #<$5555>>$10
    sta.z rom_unlock.address+2
    lda #>$5555>>$10
    sta.z rom_unlock.address+3
    jsr rom_unlock
    // [73] phi from main::@58 to main::@59 [phi:main::@58->main::@59]
    // main::@59
    // rom_read_byte(0x00000)
    // [74] call rom_read_byte
    // [370] phi from main::@59 to rom_read_byte [phi:main::@59->rom_read_byte]
    // [370] phi rom_read_byte::address#4 = 0 [phi:main::@59->rom_read_byte#0] -- vduz1=vbuc1 
    lda #0
    sta.z rom_read_byte.address
    sta.z rom_read_byte.address+1
    sta.z rom_read_byte.address+2
    sta.z rom_read_byte.address+3
    jsr rom_read_byte
    // [75] phi from main::@59 to main::@60 [phi:main::@59->main::@60]
    // main::@60
    // rom_read_byte(0x00001)
    // [76] call rom_read_byte
    // [370] phi from main::@60 to rom_read_byte [phi:main::@60->rom_read_byte]
    // [370] phi rom_read_byte::address#4 = 1 [phi:main::@60->rom_read_byte#0] -- vduz1=vbuc1 
    lda #1
    sta.z rom_read_byte.address
    lda #0
    sta.z rom_read_byte.address+1
    sta.z rom_read_byte.address+2
    sta.z rom_read_byte.address+3
    jsr rom_read_byte
    // [77] phi from main::@60 to main::@61 [phi:main::@60->main::@61]
    // main::@61
    // rom_unlock(0x05555, 0xF0)
    // [78] call rom_unlock
    // [362] phi from main::@61 to rom_unlock [phi:main::@61->rom_unlock]
    // [362] phi rom_unlock::unlock_code#10 = $f0 [phi:main::@61->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [362] phi rom_unlock::address#10 = $5555 [phi:main::@61->rom_unlock#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_unlock.address
    lda #>$5555
    sta.z rom_unlock.address+1
    lda #<$5555>>$10
    sta.z rom_unlock.address+2
    lda #>$5555>>$10
    sta.z rom_unlock.address+3
    jsr rom_unlock
    // [79] phi from main::@61 to main::@62 [phi:main::@61->main::@62]
    // main::@62
    // rom_unlock(0x05555, 0x90)
    // [80] call rom_unlock
    // [362] phi from main::@62 to rom_unlock [phi:main::@62->rom_unlock]
    // [362] phi rom_unlock::unlock_code#10 = $90 [phi:main::@62->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [362] phi rom_unlock::address#10 = $5555 [phi:main::@62->rom_unlock#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_unlock.address
    lda #>$5555
    sta.z rom_unlock.address+1
    lda #<$5555>>$10
    sta.z rom_unlock.address+2
    lda #>$5555>>$10
    sta.z rom_unlock.address+3
    jsr rom_unlock
    // [81] phi from main::@62 to main::@63 [phi:main::@62->main::@63]
    // main::@63
    // rom_read_byte(0x00000)
    // [82] call rom_read_byte
    // [370] phi from main::@63 to rom_read_byte [phi:main::@63->rom_read_byte]
    // [370] phi rom_read_byte::address#4 = 0 [phi:main::@63->rom_read_byte#0] -- vduz1=vbuc1 
    lda #0
    sta.z rom_read_byte.address
    sta.z rom_read_byte.address+1
    sta.z rom_read_byte.address+2
    sta.z rom_read_byte.address+3
    jsr rom_read_byte
    // rom_read_byte(0x00000)
    // [83] rom_read_byte::return#4 = rom_read_byte::return#0
    // main::@64
    // rom_manufacturer_id = rom_read_byte(0x00000)
    // [84] main::rom_manufacturer_id#2 = rom_read_byte::return#4 -- vbuz1=vbuz2 
    lda.z rom_read_byte.return
    sta.z rom_manufacturer_id
    // rom_read_byte(0x00001)
    // [85] call rom_read_byte
    // [370] phi from main::@64 to rom_read_byte [phi:main::@64->rom_read_byte]
    // [370] phi rom_read_byte::address#4 = 1 [phi:main::@64->rom_read_byte#0] -- vduz1=vbuc1 
    lda #1
    sta.z rom_read_byte.address
    lda #0
    sta.z rom_read_byte.address+1
    sta.z rom_read_byte.address+2
    sta.z rom_read_byte.address+3
    jsr rom_read_byte
    // rom_read_byte(0x00001)
    // [86] rom_read_byte::return#10 = rom_read_byte::return#0
    // main::@65
    // rom_device_id = rom_read_byte(0x00001)
    // [87] main::rom_device_id#10 = rom_read_byte::return#10
    // rom_unlock(0x05555, 0xF0)
    // [88] call rom_unlock
    // [362] phi from main::@65 to rom_unlock [phi:main::@65->rom_unlock]
    // [362] phi rom_unlock::unlock_code#10 = $f0 [phi:main::@65->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [362] phi rom_unlock::address#10 = $5555 [phi:main::@65->rom_unlock#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_unlock.address
    lda #>$5555
    sta.z rom_unlock.address+1
    lda #<$5555>>$10
    sta.z rom_unlock.address+2
    lda #>$5555>>$10
    sta.z rom_unlock.address+3
    jsr rom_unlock
    // [89] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // bank_set_brom(4)
    // [90] call bank_set_brom
    // [382] phi from main::@66 to bank_set_brom [phi:main::@66->bank_set_brom]
    // [382] phi bank_set_brom::bank#5 = 4 [phi:main::@66->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [91] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // printf("manufacturer id = %x\n", rom_manufacturer_id)
    // [92] call printf_str
    // [353] phi from main::@67 to printf_str [phi:main::@67->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@67->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s2 [phi:main::@67->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@68
    // printf("manufacturer id = %x\n", rom_manufacturer_id)
    // [93] printf_uchar::uvalue#0 = main::rom_manufacturer_id#2
    // [94] call printf_uchar
    // [385] phi from main::@68 to printf_uchar [phi:main::@68->printf_uchar]
    // [385] phi printf_uchar::format_radix#3 = HEXADECIMAL [phi:main::@68->printf_uchar#0] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [385] phi printf_uchar::uvalue#3 = printf_uchar::uvalue#0 [phi:main::@68->printf_uchar#1] -- register_copy 
    jsr printf_uchar
    // [95] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // printf("manufacturer id = %x\n", rom_manufacturer_id)
    // [96] call printf_str
    // [353] phi from main::@69 to printf_str [phi:main::@69->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@69->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s3 [phi:main::@69->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@70
    // case SST39SF010A:
    //             rom_device = "sst39sf010a";
    //             break;
    // [97] if(main::rom_device_id#10==$b5) goto main::@5 -- vbuz1_eq_vbuc1_then_la1 
    lda #$b5
    cmp.z rom_device_id
    beq __b3
    // main::@2
    // case SST39SF020A:
    //             rom_device = "sst39sf020a";
    //             break;
    // [98] if(main::rom_device_id#10==$b6) goto main::@5 -- vbuz1_eq_vbuc1_then_la1 
    lda #$b6
    cmp.z rom_device_id
    beq __b2
    // main::@3
    // case SST39SF040:
    //             rom_device = "sst39sf040";
    //             break;
    // [99] if(main::rom_device_id#10==$b7) goto main::@4 -- vbuz1_eq_vbuc1_then_la1 
    lda #$b7
    cmp.z rom_device_id
    beq __b4
    // [101] phi from main::@3 to main::@5 [phi:main::@3->main::@5]
    // [101] phi main::rom_device#5 = main::rom_device#4 [phi:main::@3->main::@5#0] -- pbuz1=pbuc1 
    lda #<rom_device_4
    sta.z rom_device
    lda #>rom_device_4
    sta.z rom_device+1
    jmp __b5
    // [100] phi from main::@3 to main::@4 [phi:main::@3->main::@4]
    // main::@4
  __b4:
    // [101] phi from main::@4 to main::@5 [phi:main::@4->main::@5]
    // [101] phi main::rom_device#5 = main::rom_device#3 [phi:main::@4->main::@5#0] -- pbuz1=pbuc1 
    lda #<rom_device_3
    sta.z rom_device
    lda #>rom_device_3
    sta.z rom_device+1
    jmp __b5
    // [101] phi from main::@2 to main::@5 [phi:main::@2->main::@5]
  __b2:
    // [101] phi main::rom_device#5 = main::rom_device#2 [phi:main::@2->main::@5#0] -- pbuz1=pbuc1 
    lda #<rom_device_2
    sta.z rom_device
    lda #>rom_device_2
    sta.z rom_device+1
    jmp __b5
    // [101] phi from main::@70 to main::@5 [phi:main::@70->main::@5]
  __b3:
    // [101] phi main::rom_device#5 = main::rom_device#1 [phi:main::@70->main::@5#0] -- pbuz1=pbuc1 
    lda #<rom_device_1
    sta.z rom_device
    lda #>rom_device_1
    sta.z rom_device+1
    // main::@5
  __b5:
    // printf("device id = %s (%x)\n", rom_device, rom_device_id )
    // [102] call printf_str
    // [353] phi from main::@5 to printf_str [phi:main::@5->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@5->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s4 [phi:main::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@71
    // printf("device id = %s (%x)\n", rom_device, rom_device_id )
    // [103] printf_string::str#0 = main::rom_device#5
    // [104] call printf_string
    // [393] phi from main::@71 to printf_string [phi:main::@71->printf_string]
    jsr printf_string
    // [105] phi from main::@71 to main::@72 [phi:main::@71->main::@72]
    // main::@72
    // printf("device id = %s (%x)\n", rom_device, rom_device_id )
    // [106] call printf_str
    // [353] phi from main::@72 to printf_str [phi:main::@72->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@72->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s5 [phi:main::@72->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@73
    // printf("device id = %s (%x)\n", rom_device, rom_device_id )
    // [107] printf_uchar::uvalue#1 = main::rom_device_id#10 -- vbuz1=vbuz2 
    lda.z rom_device_id
    sta.z printf_uchar.uvalue
    // [108] call printf_uchar
    // [385] phi from main::@73 to printf_uchar [phi:main::@73->printf_uchar]
    // [385] phi printf_uchar::format_radix#3 = HEXADECIMAL [phi:main::@73->printf_uchar#0] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [385] phi printf_uchar::uvalue#3 = printf_uchar::uvalue#1 [phi:main::@73->printf_uchar#1] -- register_copy 
    jsr printf_uchar
    // [109] phi from main::@73 to main::@74 [phi:main::@73->main::@74]
    // main::@74
    // printf("device id = %s (%x)\n", rom_device, rom_device_id )
    // [110] call printf_str
    // [353] phi from main::@74 to printf_str [phi:main::@74->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@74->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s6 [phi:main::@74->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // main::bank_set_bram1
    // BRAM = bank
    // [112] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // [113] phi from main::bank_set_bram1 to main::@50 [phi:main::bank_set_bram1->main::@50]
    // main::@50
    // bank_set_brom(4)
    // [114] call bank_set_brom
    // [382] phi from main::@50 to bank_set_brom [phi:main::@50->bank_set_brom]
    // [382] phi bank_set_brom::bank#5 = 4 [phi:main::@50->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #4
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // [115] phi from main::@50 to main::@75 [phi:main::@50->main::@75]
    // main::@75
    // printf("\nopening file rom.bin from the sd card ... ")
    // [116] call printf_str
    // [353] phi from main::@75 to printf_str [phi:main::@75->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@75->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s7 [phi:main::@75->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // [117] phi from main::@75 to main::@76 [phi:main::@75->main::@76]
    // main::@76
    // FILE* fp = fopen(1, 8, 2, "rom.bin")
    // [118] call fopen
    jsr fopen
    // [119] fopen::return#4 = fopen::return#1
    // main::@77
    // [120] main::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if(!fp)
    // [121] if((struct $0 *)0!=main::fp#0) goto main::@1 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    bne __b1
    lda.z fp
    cmp #<0
    bne __b1
    // [122] phi from main::@77 to main::@6 [phi:main::@77->main::@6]
    // main::@6
    // printf("error!\n")
    // [123] call printf_str
    // [353] phi from main::@6 to printf_str [phi:main::@6->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s10 [phi:main::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // [124] phi from main::@6 to main::@79 [phi:main::@6->main::@79]
    // main::@79
    // printf("error code = %u\n", fp->status)
    // [125] call printf_str
    // [353] phi from main::@79 to printf_str [phi:main::@79->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@79->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s11 [phi:main::@79->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@80
    // printf("error code = %u\n", fp->status)
    // [126] printf_uchar::uvalue#2 = ((char *)main::fp#0)[$13] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$13
    lda (fp),y
    sta.z printf_uchar.uvalue
    // [127] call printf_uchar
    // [385] phi from main::@80 to printf_uchar [phi:main::@80->printf_uchar]
    // [385] phi printf_uchar::format_radix#3 = DECIMAL [phi:main::@80->printf_uchar#0] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [385] phi printf_uchar::uvalue#3 = printf_uchar::uvalue#2 [phi:main::@80->printf_uchar#1] -- register_copy 
    jsr printf_uchar
    // [128] phi from main::@80 to main::@81 [phi:main::@80->main::@81]
    // main::@81
    // printf("error code = %u\n", fp->status)
    // [129] call printf_str
    // [353] phi from main::@81 to printf_str [phi:main::@81->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@81->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s3 [phi:main::@81->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@return
    // }
    // [130] return 
    rts
    // [131] phi from main::@77 to main::@1 [phi:main::@77->main::@1]
    // main::@1
  __b1:
    // printf("success ...\n")
    // [132] call printf_str
    // [353] phi from main::@1 to printf_str [phi:main::@1->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@1->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s8 [phi:main::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // [133] phi from main::@1 to main::@78 [phi:main::@1->main::@78]
    // main::@78
    // printf("\nloading kernal rom in main memory ...\n")
    // [134] call printf_str
    // [353] phi from main::@78 to printf_str [phi:main::@78->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@78->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s9 [phi:main::@78->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // [135] phi from main::@78 to main::@7 [phi:main::@78->main::@7]
    // [135] phi main::ram_addr#10 = (char *) 16384 [phi:main::@78->main::@7#0] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z ram_addr
    lda #>$4000
    sta.z ram_addr+1
    // [135] phi main::rom_addr#31 = 0 [phi:main::@78->main::@7#1] -- vduz1=vduc1 
    lda #<0
    sta.z rom_addr
    sta.z rom_addr+1
    lda #<0>>$10
    sta.z rom_addr+2
    lda #>0>>$10
    sta.z rom_addr+3
    // main::@7
  __b7:
    // while(rom_addr < 0x4000)
    // [136] if(main::rom_addr#31<$4000) goto main::@8 -- vduz1_lt_vduc1_then_la1 
    lda.z rom_addr+3
    cmp #>$4000>>$10
    bcs !__b8+
    jmp __b8
  !__b8:
    bne !+
    lda.z rom_addr+2
    cmp #<$4000>>$10
    bcs !__b8+
    jmp __b8
  !__b8:
    bne !+
    lda.z rom_addr+1
    cmp #>$4000
    bcs !__b8+
    jmp __b8
  !__b8:
    bne !+
    lda.z rom_addr
    cmp #<$4000
    bcs !__b8+
    jmp __b8
  !__b8:
  !:
    // [137] phi from main::@7 to main::@9 [phi:main::@7->main::@9]
    // main::@9
    // printf("\n\nloading remaining rom in banked memory ...\n")
    // [138] call printf_str
    // [353] phi from main::@9 to printf_str [phi:main::@9->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@9->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s13 [phi:main::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::bank_set_bram2
    // BRAM = bank
    // [139] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@51
    // fgets(ram_addr, 128, fp)
    // [140] fgets::fp#1 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [141] call fgets
    // [430] phi from main::@51 to fgets [phi:main::@51->fgets]
    // [430] phi fgets::ptr#13 = (char *) 40960 [phi:main::@51->fgets#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z fgets.ptr
    lda #>$a000
    sta.z fgets.ptr+1
    // [430] phi fgets::fp#20 = fgets::fp#1 [phi:main::@51->fgets#1] -- register_copy 
    jsr fgets
    // fgets(ram_addr, 128, fp)
    // [142] fgets::return#10 = fgets::return#1
    // main::@83
    // bytes = fgets(ram_addr, 128, fp)
    // [143] main::bytes#2 = fgets::return#10
    // [144] phi from main::@83 to main::@14 [phi:main::@83->main::@14]
    // [144] phi main::ram_addr#12 = (char *) 40960 [phi:main::@83->main::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_addr_1
    lda #>$a000
    sta.z ram_addr_1+1
    // [144] phi main::bytes#10 = main::bytes#2 [phi:main::@83->main::@14#1] -- register_copy 
    // [144] phi main::rom_addr#10 = main::rom_addr#31 [phi:main::@83->main::@14#2] -- register_copy 
  // this will load 128 bytes from the rom.bin file or less if EOF is reached.
    // main::@14
  __b14:
    // while(bytes && rom_addr < 0x28000)
    // [145] if(0==main::bytes#10) goto main::@16 -- 0_eq_vwuz1_then_la1 
    lda.z bytes_1
    ora.z bytes_1+1
    beq __b16
    // main::@102
    // [146] if(main::rom_addr#10<$28000) goto main::@15 -- vduz1_lt_vduc1_then_la1 
    lda.z rom_addr+3
    cmp #>$28000>>$10
    bcs !__b15+
    jmp __b15
  !__b15:
    bne !+
    lda.z rom_addr+2
    cmp #<$28000>>$10
    bcs !__b15+
    jmp __b15
  !__b15:
    bne !+
    lda.z rom_addr+1
    cmp #>$28000
    bcs !__b15+
    jmp __b15
  !__b15:
    bne !+
    lda.z rom_addr
    cmp #<$28000
    bcs !__b15+
    jmp __b15
  !__b15:
  !:
    // [147] phi from main::@102 main::@14 to main::@16 [phi:main::@102/main::@14->main::@16]
    // main::@16
  __b16:
    // printf("\n\na total of %06x rom bytes to be upgraded from rom.bin ...", rom_total)
    // [148] call printf_str
    // [353] phi from main::@16 to printf_str [phi:main::@16->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@16->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s17 [phi:main::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@86
    // printf("\n\na total of %06x rom bytes to be upgraded from rom.bin ...", rom_total)
    // [149] printf_ulong::uvalue#1 = main::rom_addr#10 -- vduz1=vduz2 
    lda.z rom_addr
    sta.z printf_ulong.uvalue
    lda.z rom_addr+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_addr+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_addr+3
    sta.z printf_ulong.uvalue+3
    // [150] call printf_ulong
    // [472] phi from main::@86 to printf_ulong [phi:main::@86->printf_ulong]
    // [472] phi printf_ulong::uvalue#5 = printf_ulong::uvalue#1 [phi:main::@86->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [151] phi from main::@86 to main::@87 [phi:main::@86->main::@87]
    // main::@87
    // printf("\n\na total of %06x rom bytes to be upgraded from rom.bin ...", rom_total)
    // [152] call printf_str
    // [353] phi from main::@87 to printf_str [phi:main::@87->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@87->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s18 [phi:main::@87->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // [153] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // printf("\npress any key to upgrade to the new rom ...\n")
    // [154] call printf_str
    // [353] phi from main::@88 to printf_str [phi:main::@88->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@88->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s19 [phi:main::@88->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // [155] phi from main::@88 main::@92 to main::@21 [phi:main::@88/main::@92->main::@21]
    // main::@21
  __b21:
    // getin()
    // [156] call getin
    jsr getin
    // [157] getin::return#2 = getin::return#1
    // main::@92
    // [158] main::$60 = getin::return#2
    // while(!getin())
    // [159] if(0==main::$60) goto main::@21 -- 0_eq_vbuz1_then_la1 
    lda.z __60
    beq __b21
    // [160] phi from main::@92 to main::@22 [phi:main::@92->main::@22]
    // main::@22
    // clrscr()
    // [161] call clrscr
    jsr clrscr
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [163] phi from main::SEI2 to main::@52 [phi:main::SEI2->main::@52]
    // main::@52
    // printf("\nupgrading kernal rom from main memory ...\n")
    // [164] call printf_str
    // [353] phi from main::@52 to printf_str [phi:main::@52->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@52->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s22 [phi:main::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // [165] phi from main::@52 to main::@23 [phi:main::@52->main::@23]
    // [165] phi main::ram_addr#37 = (char *) 16384 [phi:main::@52->main::@23#0] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z ram_addr_2
    lda #>$4000
    sta.z ram_addr_2+1
    // [165] phi main::rom_addr#15 = 0 [phi:main::@52->main::@23#1] -- vduz1=vbuc1 
    lda #0
    sta.z rom_addr_1
    sta.z rom_addr_1+1
    sta.z rom_addr_1+2
    sta.z rom_addr_1+3
    // main::@23
  __b23:
    // while(rom_addr < 0x4000)
    // [166] if(main::rom_addr#15<$4000) goto main::@24 -- vduz1_lt_vduc1_then_la1 
    lda.z rom_addr_1+3
    cmp #>$4000>>$10
    bcs !__b24+
    jmp __b24
  !__b24:
    bne !+
    lda.z rom_addr_1+2
    cmp #<$4000>>$10
    bcs !__b24+
    jmp __b24
  !__b24:
    bne !+
    lda.z rom_addr_1+1
    cmp #>$4000
    bcs !__b24+
    jmp __b24
  !__b24:
    bne !+
    lda.z rom_addr_1
    cmp #<$4000
    bcs !__b24+
    jmp __b24
  !__b24:
  !:
    // [167] phi from main::@23 to main::@25 [phi:main::@23->main::@25]
    // main::@25
    // printf("\n\nflashing remaining rom from banked memory ...\n")
    // [168] call printf_str
    // [353] phi from main::@25 to printf_str [phi:main::@25->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@25->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s23 [phi:main::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s23
    sta.z printf_str.s
    lda #>s23
    sta.z printf_str.s+1
    jsr printf_str
    // main::bank_set_bram3
    // BRAM = bank
    // [169] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // [170] phi from main::bank_set_bram3 to main::@33 [phi:main::bank_set_bram3->main::@33]
    // [170] phi main::bank#10 = 1 [phi:main::bank_set_bram3->main::@33#0] -- vbuz1=vbuc1 
    sta.z bank
    // [170] phi main::ram_addr#38 = (char *) 40960 [phi:main::bank_set_bram3->main::@33#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_addr_3
    lda #>$a000
    sta.z ram_addr_3+1
    // [170] phi main::rom_addr#23 = main::rom_addr#15 [phi:main::bank_set_bram3->main::@33#2] -- register_copy 
    // main::@33
  __b33:
    // while(rom_addr < rom_total)
    // [171] if(main::rom_addr#23<main::rom_addr#10) goto main::@34 -- vduz1_lt_vduz2_then_la1 
    lda.z rom_addr_1+3
    cmp.z rom_addr+3
    bcc __b34
    bne !+
    lda.z rom_addr_1+2
    cmp.z rom_addr+2
    bcc __b34
    bne !+
    lda.z rom_addr_1+1
    cmp.z rom_addr+1
    bcc __b34
    bne !+
    lda.z rom_addr_1
    cmp.z rom_addr
    bcc __b34
  !:
    // [172] phi from main::@33 to main::@35 [phi:main::@33->main::@35]
    // main::@35
    // printf("\n\nflashing of new rom successful ... resetting commander x16 to new rom...\n")
    // [173] call printf_str
    // [353] phi from main::@35 to printf_str [phi:main::@35->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@35->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s26 [phi:main::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s26
    sta.z printf_str.s
    lda #>s26
    sta.z printf_str.s+1
    jsr printf_str
    // [174] phi from main::@35 to main::@45 [phi:main::@35->main::@45]
    // [174] phi main::w#2 = 0 [phi:main::@35->main::@45#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z w
    sta.z w+1
    // main::@45
  __b45:
    // for(unsigned int w=0; w<64; w++)
    // [175] if(main::w#2<$40) goto main::@46 -- vwuz1_lt_vbuc1_then_la1 
    lda.z w+1
    bne !+
    lda.z w
    cmp #$40
    bcc __b6
  !:
    // main::bank_set_bram5
    // BRAM = bank
    // [176] BRAM = main::bank_set_bram5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram5_bank
    sta.z BRAM
    // [177] phi from main::bank_set_bram5 to main::@54 [phi:main::bank_set_bram5->main::@54]
    // main::@54
    // bank_set_brom(0)
    // [178] call bank_set_brom
    // [382] phi from main::@54 to bank_set_brom [phi:main::@54->bank_set_brom]
    // [382] phi bank_set_brom::bank#5 = 0 [phi:main::@54->bank_set_brom#0] -- vbuz1=vbuc1 
    lda #0
    sta.z bank_set_brom.bank
    jsr bank_set_brom
    // main::@101
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [180] phi from main::@45 to main::@46 [phi:main::@45->main::@46]
  __b6:
    // [180] phi main::v#2 = 0 [phi:main::@45->main::@46#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z v
    sta.z v+1
    // main::@46
  __b46:
    // for(unsigned int v=0; v<256*64; v++)
    // [181] if(main::v#2<$100*$40) goto main::@47 -- vwuz1_lt_vwuc1_then_la1 
    lda.z v+1
    cmp #>$100*$40
    bcc __b47
    bne !+
    lda.z v
    cmp #<$100*$40
    bcc __b47
  !:
    // main::@48
    // cputc('.')
    // [182] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [183] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(unsigned int w=0; w<64; w++)
    // [185] main::w#1 = ++ main::w#2 -- vwuz1=_inc_vwuz1 
    inc.z w
    bne !+
    inc.z w+1
  !:
    // [174] phi from main::@48 to main::@45 [phi:main::@48->main::@45]
    // [174] phi main::w#2 = main::w#1 [phi:main::@48->main::@45#0] -- register_copy 
    jmp __b45
    // main::@47
  __b47:
    // for(unsigned int v=0; v<256*64; v++)
    // [186] main::v#1 = ++ main::v#2 -- vwuz1=_inc_vwuz1 
    inc.z v
    bne !+
    inc.z v+1
  !:
    // [180] phi from main::@47 to main::@46 [phi:main::@47->main::@46]
    // [180] phi main::v#2 = main::v#1 [phi:main::@47->main::@46#0] -- register_copy 
    jmp __b46
    // main::@34
  __b34:
    // rom_addr % 0x2000
    // [187] main::$79 = main::rom_addr#23 & $2000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_addr_1
    and #<$2000-1
    sta.z __79
    lda.z rom_addr_1+1
    and #>$2000-1
    sta.z __79+1
    lda.z rom_addr_1+2
    and #<$2000-1>>$10
    sta.z __79+2
    lda.z rom_addr_1+3
    and #>$2000-1>>$10
    sta.z __79+3
    // if (!(rom_addr % 0x2000))
    // [188] if(0!=main::$79) goto main::@36 -- 0_neq_vduz1_then_la1 
    lda.z __79
    ora.z __79+1
    ora.z __79+2
    ora.z __79+3
    bne __b36
    // [189] phi from main::@34 to main::@42 [phi:main::@34->main::@42]
    // main::@42
    // printf("\n%06x : ", rom_addr)
    // [190] call printf_str
    // [353] phi from main::@42 to printf_str [phi:main::@42->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@42->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s3 [phi:main::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@97
    // printf("\n%06x : ", rom_addr)
    // [191] printf_ulong::uvalue#4 = main::rom_addr#23 -- vduz1=vduz2 
    lda.z rom_addr_1
    sta.z printf_ulong.uvalue
    lda.z rom_addr_1+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_addr_1+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_addr_1+3
    sta.z printf_ulong.uvalue+3
    // [192] call printf_ulong
    // [472] phi from main::@97 to printf_ulong [phi:main::@97->printf_ulong]
    // [472] phi printf_ulong::uvalue#5 = printf_ulong::uvalue#4 [phi:main::@97->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [193] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // printf("\n%06x : ", rom_addr)
    // [194] call printf_str
    // [353] phi from main::@98 to printf_str [phi:main::@98->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@98->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s16 [phi:main::@98->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@36
  __b36:
    // rom_addr % 0x80
    // [195] main::$83 = main::rom_addr#23 & $80-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_addr_1
    and #<$80-1
    sta.z __83
    lda.z rom_addr_1+1
    and #>$80-1
    sta.z __83+1
    lda.z rom_addr_1+2
    and #<$80-1>>$10
    sta.z __83+2
    lda.z rom_addr_1+3
    and #>$80-1>>$10
    sta.z __83+3
    // if (!(rom_addr % 0x80))
    // [196] if(0!=main::$83) goto main::@37 -- 0_neq_vduz1_then_la1 
    lda.z __83
    ora.z __83+1
    ora.z __83+2
    ora.z __83+3
    bne __b37
    // main::@43
    // cputc('.')
    // [197] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [198] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // main::@37
  __b37:
    // rom_addr % 0x1000
    // [200] main::$87 = main::rom_addr#23 & $1000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_addr_1
    and #<$1000-1
    sta.z __87
    lda.z rom_addr_1+1
    and #>$1000-1
    sta.z __87+1
    lda.z rom_addr_1+2
    and #<$1000-1>>$10
    sta.z __87+2
    lda.z rom_addr_1+3
    and #>$1000-1>>$10
    sta.z __87+3
    // if (!(rom_addr % 0x1000))
    // [201] if(0!=main::$87) goto main::@38 -- 0_neq_vduz1_then_la1 
    lda.z __87
    ora.z __87+1
    ora.z __87+2
    ora.z __87+3
    bne __b9
    // main::@44
    // rom_sector_erase(rom_addr)
    // [202] rom_sector_erase::address#1 = main::rom_addr#23 -- vduz1=vduz2 
    lda.z rom_addr_1
    sta.z rom_sector_erase.address
    lda.z rom_addr_1+1
    sta.z rom_sector_erase.address+1
    lda.z rom_addr_1+2
    sta.z rom_sector_erase.address+2
    lda.z rom_addr_1+3
    sta.z rom_sector_erase.address+3
    // [203] call rom_sector_erase
    // [484] phi from main::@44 to rom_sector_erase [phi:main::@44->rom_sector_erase]
    // [484] phi rom_sector_erase::address#2 = rom_sector_erase::address#1 [phi:main::@44->rom_sector_erase#0] -- register_copy 
    jsr rom_sector_erase
    // [204] phi from main::@37 main::@44 to main::@38 [phi:main::@37/main::@44->main::@38]
  __b9:
    // [204] phi main::bank#3 = main::bank#10 [phi:main::@37/main::@44->main::@38#0] -- register_copy 
    // [204] phi main::ram_addr#17 = main::ram_addr#38 [phi:main::@37/main::@44->main::@38#1] -- register_copy 
    // [204] phi main::rom_addr#29 = main::rom_addr#23 [phi:main::@37/main::@44->main::@38#2] -- register_copy 
    // [204] phi main::b1#2 = 0 [phi:main::@37/main::@44->main::@38#3] -- vbuz1=vbuc1 
    lda #0
    sta.z b1
    // main::@38
  __b38:
    // for(unsigned char b=0; b<128; b++)
    // [205] if(main::b1#2<$80) goto main::@39 -- vbuz1_lt_vbuc1_then_la1 
    lda.z b1
    cmp #$80
    bcc __b39
    // [170] phi from main::@38 to main::@33 [phi:main::@38->main::@33]
    // [170] phi main::bank#10 = main::bank#3 [phi:main::@38->main::@33#0] -- register_copy 
    // [170] phi main::ram_addr#38 = main::ram_addr#17 [phi:main::@38->main::@33#1] -- register_copy 
    // [170] phi main::rom_addr#23 = main::rom_addr#29 [phi:main::@38->main::@33#2] -- register_copy 
    jmp __b33
    // [206] phi from main::@38 to main::@39 [phi:main::@38->main::@39]
    // main::@39
  __b39:
    // rom_unlock(0x05555, 0xA0)
    // [207] call rom_unlock
    // [362] phi from main::@39 to rom_unlock [phi:main::@39->rom_unlock]
    // [362] phi rom_unlock::unlock_code#10 = $a0 [phi:main::@39->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [362] phi rom_unlock::address#10 = $5555 [phi:main::@39->rom_unlock#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_unlock.address
    lda #>$5555
    sta.z rom_unlock.address+1
    lda #<$5555>>$10
    sta.z rom_unlock.address+2
    lda #>$5555>>$10
    sta.z rom_unlock.address+3
    jsr rom_unlock
    // main::@99
    // rom_byte_program(rom_addr, *ram_addr)
    // [208] rom_byte_program::address#1 = main::rom_addr#29 -- vduz1=vduz2 
    lda.z rom_addr_1
    sta.z rom_byte_program.address
    lda.z rom_addr_1+1
    sta.z rom_byte_program.address+1
    lda.z rom_addr_1+2
    sta.z rom_byte_program.address+2
    lda.z rom_addr_1+3
    sta.z rom_byte_program.address+3
    // [209] rom_byte_program::value#1 = *main::ram_addr#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ram_addr_3),y
    sta.z rom_byte_program.value
    // [210] call rom_byte_program
    // [494] phi from main::@99 to rom_byte_program [phi:main::@99->rom_byte_program]
    // [494] phi rom_byte_program::value#2 = rom_byte_program::value#1 [phi:main::@99->rom_byte_program#0] -- register_copy 
    // [494] phi rom_byte_program::address#2 = rom_byte_program::address#1 [phi:main::@99->rom_byte_program#1] -- register_copy 
    jsr rom_byte_program
    // main::@100
    // rom_addr++;
    // [211] main::rom_addr#5 = ++ main::rom_addr#29 -- vduz1=_inc_vduz1 
    inc.z rom_addr_1
    bne !+
    inc.z rom_addr_1+1
    bne !+
    inc.z rom_addr_1+2
    bne !+
    inc.z rom_addr_1+3
  !:
    // ram_addr++;
    // [212] main::ram_addr#19 = ++ main::ram_addr#17 -- pbuz1=_inc_pbuz1 
    inc.z ram_addr_3
    bne !+
    inc.z ram_addr_3+1
  !:
    // if(ram_addr >= 0xC000)
    // [213] if(main::ram_addr#19<$c000) goto main::@40 -- pbuz1_lt_vwuc1_then_la1 
    lda.z ram_addr_3+1
    cmp #>$c000
    bcc __b40
    bne !+
    lda.z ram_addr_3
    cmp #<$c000
    bcc __b40
  !:
    // main::@41
    // ram_addr = ram_addr - 0x2000
    // [214] main::ram_addr#9 = main::ram_addr#19 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ram_addr_3
    sec
    sbc #<$2000
    sta.z ram_addr_3
    lda.z ram_addr_3+1
    sbc #>$2000
    sta.z ram_addr_3+1
    // bank++;
    // [215] main::bank#1 = ++ main::bank#3 -- vbuz1=_inc_vbuz1 
    inc.z bank
    // [216] phi from main::@100 main::@41 to main::@40 [phi:main::@100/main::@41->main::@40]
    // [216] phi main::ram_addr#39 = main::ram_addr#19 [phi:main::@100/main::@41->main::@40#0] -- register_copy 
    // [216] phi main::bank#12 = main::bank#3 [phi:main::@100/main::@41->main::@40#1] -- register_copy 
    // main::@40
  __b40:
    // main::bank_set_bram4
    // BRAM = bank
    // [217] BRAM = main::bank#12 -- vbuz1=vbuz2 
    lda.z bank
    sta.z BRAM
    // main::@53
    // for(unsigned char b=0; b<128; b++)
    // [218] main::b1#1 = ++ main::b1#2 -- vbuz1=_inc_vbuz1 
    inc.z b1
    // [204] phi from main::@53 to main::@38 [phi:main::@53->main::@38]
    // [204] phi main::bank#3 = main::bank#12 [phi:main::@53->main::@38#0] -- register_copy 
    // [204] phi main::ram_addr#17 = main::ram_addr#39 [phi:main::@53->main::@38#1] -- register_copy 
    // [204] phi main::rom_addr#29 = main::rom_addr#5 [phi:main::@53->main::@38#2] -- register_copy 
    // [204] phi main::b1#2 = main::b1#1 [phi:main::@53->main::@38#3] -- register_copy 
    jmp __b38
    // main::@24
  __b24:
    // rom_addr % 0x2000
    // [219] main::$63 = main::rom_addr#15 & $2000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_addr_1
    and #<$2000-1
    sta.z __63
    lda.z rom_addr_1+1
    and #>$2000-1
    sta.z __63+1
    lda.z rom_addr_1+2
    and #<$2000-1>>$10
    sta.z __63+2
    lda.z rom_addr_1+3
    and #>$2000-1>>$10
    sta.z __63+3
    // if (!(rom_addr % 0x2000))
    // [220] if(0!=main::$63) goto main::@26 -- 0_neq_vduz1_then_la1 
    lda.z __63
    ora.z __63+1
    ora.z __63+2
    ora.z __63+3
    bne __b26
    // [221] phi from main::@24 to main::@30 [phi:main::@24->main::@30]
    // main::@30
    // printf("\n%06x : ", rom_addr)
    // [222] call printf_str
    // [353] phi from main::@30 to printf_str [phi:main::@30->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@30->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s3 [phi:main::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@93
    // printf("\n%06x : ", rom_addr)
    // [223] printf_ulong::uvalue#3 = main::rom_addr#15 -- vduz1=vduz2 
    lda.z rom_addr_1
    sta.z printf_ulong.uvalue
    lda.z rom_addr_1+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_addr_1+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_addr_1+3
    sta.z printf_ulong.uvalue+3
    // [224] call printf_ulong
    // [472] phi from main::@93 to printf_ulong [phi:main::@93->printf_ulong]
    // [472] phi printf_ulong::uvalue#5 = printf_ulong::uvalue#3 [phi:main::@93->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [225] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // printf("\n%06x : ", rom_addr)
    // [226] call printf_str
    // [353] phi from main::@94 to printf_str [phi:main::@94->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@94->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s16 [phi:main::@94->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@26
  __b26:
    // rom_addr % 0x80
    // [227] main::$67 = main::rom_addr#15 & $80-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_addr_1
    and #<$80-1
    sta.z __67
    lda.z rom_addr_1+1
    and #>$80-1
    sta.z __67+1
    lda.z rom_addr_1+2
    and #<$80-1>>$10
    sta.z __67+2
    lda.z rom_addr_1+3
    and #>$80-1>>$10
    sta.z __67+3
    // if (!(rom_addr % 0x80))
    // [228] if(0!=main::$67) goto main::@27 -- 0_neq_vduz1_then_la1 
    lda.z __67
    ora.z __67+1
    ora.z __67+2
    ora.z __67+3
    bne __b27
    // main::@31
    // cputc('.')
    // [229] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [230] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // main::@27
  __b27:
    // rom_addr % 0x1000
    // [232] main::$71 = main::rom_addr#15 & $1000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_addr_1
    and #<$1000-1
    sta.z __71
    lda.z rom_addr_1+1
    and #>$1000-1
    sta.z __71+1
    lda.z rom_addr_1+2
    and #<$1000-1>>$10
    sta.z __71+2
    lda.z rom_addr_1+3
    and #>$1000-1>>$10
    sta.z __71+3
    // if (!(rom_addr % 0x1000))
    // [233] if(0!=main::$71) goto main::@28 -- 0_neq_vduz1_then_la1 
    lda.z __71
    ora.z __71+1
    ora.z __71+2
    ora.z __71+3
    bne __b12
    // main::@32
    // rom_sector_erase(rom_addr)
    // [234] rom_sector_erase::address#0 = main::rom_addr#15 -- vduz1=vduz2 
    lda.z rom_addr_1
    sta.z rom_sector_erase.address
    lda.z rom_addr_1+1
    sta.z rom_sector_erase.address+1
    lda.z rom_addr_1+2
    sta.z rom_sector_erase.address+2
    lda.z rom_addr_1+3
    sta.z rom_sector_erase.address+3
    // [235] call rom_sector_erase
    // [484] phi from main::@32 to rom_sector_erase [phi:main::@32->rom_sector_erase]
    // [484] phi rom_sector_erase::address#2 = rom_sector_erase::address#0 [phi:main::@32->rom_sector_erase#0] -- register_copy 
    jsr rom_sector_erase
    // [236] phi from main::@27 main::@32 to main::@28 [phi:main::@27/main::@32->main::@28]
  __b12:
    // [236] phi main::ram_addr#15 = main::ram_addr#37 [phi:main::@27/main::@32->main::@28#0] -- register_copy 
    // [236] phi main::rom_addr#21 = main::rom_addr#15 [phi:main::@27/main::@32->main::@28#1] -- register_copy 
    // [236] phi main::b#2 = 0 [phi:main::@27/main::@32->main::@28#2] -- vbuz1=vbuc1 
    lda #0
    sta.z b
    // main::@28
  __b28:
    // for(unsigned char b=0; b<128; b++)
    // [237] if(main::b#2<$80) goto main::@29 -- vbuz1_lt_vbuc1_then_la1 
    lda.z b
    cmp #$80
    bcc __b29
    // [165] phi from main::@28 to main::@23 [phi:main::@28->main::@23]
    // [165] phi main::ram_addr#37 = main::ram_addr#15 [phi:main::@28->main::@23#0] -- register_copy 
    // [165] phi main::rom_addr#15 = main::rom_addr#21 [phi:main::@28->main::@23#1] -- register_copy 
    jmp __b23
    // [238] phi from main::@28 to main::@29 [phi:main::@28->main::@29]
    // main::@29
  __b29:
    // rom_unlock(0x05555, 0xA0)
    // [239] call rom_unlock
    // [362] phi from main::@29 to rom_unlock [phi:main::@29->rom_unlock]
    // [362] phi rom_unlock::unlock_code#10 = $a0 [phi:main::@29->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [362] phi rom_unlock::address#10 = $5555 [phi:main::@29->rom_unlock#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_unlock.address
    lda #>$5555
    sta.z rom_unlock.address+1
    lda #<$5555>>$10
    sta.z rom_unlock.address+2
    lda #>$5555>>$10
    sta.z rom_unlock.address+3
    jsr rom_unlock
    // main::@95
    // rom_byte_program(rom_addr, *ram_addr)
    // [240] rom_byte_program::address#0 = main::rom_addr#21 -- vduz1=vduz2 
    lda.z rom_addr_1
    sta.z rom_byte_program.address
    lda.z rom_addr_1+1
    sta.z rom_byte_program.address+1
    lda.z rom_addr_1+2
    sta.z rom_byte_program.address+2
    lda.z rom_addr_1+3
    sta.z rom_byte_program.address+3
    // [241] rom_byte_program::value#0 = *main::ram_addr#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ram_addr_2),y
    sta.z rom_byte_program.value
    // [242] call rom_byte_program
    // [494] phi from main::@95 to rom_byte_program [phi:main::@95->rom_byte_program]
    // [494] phi rom_byte_program::value#2 = rom_byte_program::value#0 [phi:main::@95->rom_byte_program#0] -- register_copy 
    // [494] phi rom_byte_program::address#2 = rom_byte_program::address#0 [phi:main::@95->rom_byte_program#1] -- register_copy 
    jsr rom_byte_program
    // main::@96
    // rom_addr++;
    // [243] main::rom_addr#4 = ++ main::rom_addr#21 -- vduz1=_inc_vduz1 
    inc.z rom_addr_1
    bne !+
    inc.z rom_addr_1+1
    bne !+
    inc.z rom_addr_1+2
    bne !+
    inc.z rom_addr_1+3
  !:
    // ram_addr++;
    // [244] main::ram_addr#7 = ++ main::ram_addr#15 -- pbuz1=_inc_pbuz1 
    inc.z ram_addr_2
    bne !+
    inc.z ram_addr_2+1
  !:
    // for(unsigned char b=0; b<128; b++)
    // [245] main::b#1 = ++ main::b#2 -- vbuz1=_inc_vbuz1 
    inc.z b
    // [236] phi from main::@96 to main::@28 [phi:main::@96->main::@28]
    // [236] phi main::ram_addr#15 = main::ram_addr#7 [phi:main::@96->main::@28#0] -- register_copy 
    // [236] phi main::rom_addr#21 = main::rom_addr#4 [phi:main::@96->main::@28#1] -- register_copy 
    // [236] phi main::b#2 = main::b#1 [phi:main::@96->main::@28#2] -- register_copy 
    jmp __b28
    // main::@15
  __b15:
    // rom_addr % 0x2000
    // [246] main::$51 = main::rom_addr#10 & $2000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_addr
    and #<$2000-1
    sta.z __51
    lda.z rom_addr+1
    and #>$2000-1
    sta.z __51+1
    lda.z rom_addr+2
    and #<$2000-1>>$10
    sta.z __51+2
    lda.z rom_addr+3
    and #>$2000-1>>$10
    sta.z __51+3
    // if (!(rom_addr % 0x2000))
    // [247] if(0!=main::$51) goto main::@17 -- 0_neq_vduz1_then_la1 
    lda.z __51
    ora.z __51+1
    ora.z __51+2
    ora.z __51+3
    bne __b17
    // [248] phi from main::@15 to main::@19 [phi:main::@15->main::@19]
    // main::@19
    // printf("\n%06x : ", rom_addr)
    // [249] call printf_str
    // [353] phi from main::@19 to printf_str [phi:main::@19->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@19->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s3 [phi:main::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@89
    // printf("\n%06x : ", rom_addr)
    // [250] printf_ulong::uvalue#2 = main::rom_addr#10 -- vduz1=vduz2 
    lda.z rom_addr
    sta.z printf_ulong.uvalue
    lda.z rom_addr+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_addr+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_addr+3
    sta.z printf_ulong.uvalue+3
    // [251] call printf_ulong
    // [472] phi from main::@89 to printf_ulong [phi:main::@89->printf_ulong]
    // [472] phi printf_ulong::uvalue#5 = printf_ulong::uvalue#2 [phi:main::@89->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [252] phi from main::@89 to main::@90 [phi:main::@89->main::@90]
    // main::@90
    // printf("\n%06x : ", rom_addr)
    // [253] call printf_str
    // [353] phi from main::@90 to printf_str [phi:main::@90->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@90->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s16 [phi:main::@90->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@17
  __b17:
    // cputc('.')
    // [254] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [255] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_addr += bytes
    // [257] main::ram_addr#14 = main::ram_addr#12 + main::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    // show the user something has been read.
    clc
    lda.z ram_addr_1
    adc.z bytes_1
    sta.z ram_addr_1
    lda.z ram_addr_1+1
    adc.z bytes_1+1
    sta.z ram_addr_1+1
    // rom_addr += bytes
    // [258] main::rom_addr#2 = main::rom_addr#10 + main::bytes#10 -- vduz1=vduz1_plus_vwuz2 
    lda.z rom_addr
    clc
    adc.z bytes_1
    sta.z rom_addr
    lda.z rom_addr+1
    adc.z bytes_1+1
    sta.z rom_addr+1
    lda.z rom_addr+2
    adc #0
    sta.z rom_addr+2
    lda.z rom_addr+3
    adc #0
    sta.z rom_addr+3
    // if(ram_addr >= 0xC000)
    // [259] if(main::ram_addr#14<$c000) goto main::@18 -- pbuz1_lt_vwuc1_then_la1 
    lda.z ram_addr_1+1
    cmp #>$c000
    bcc __b18
    bne !+
    lda.z ram_addr_1
    cmp #<$c000
    bcc __b18
  !:
    // main::@20
    // ram_addr = ram_addr - 0x2000
    // [260] main::ram_addr#4 = main::ram_addr#14 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ram_addr_1
    sec
    sbc #<$2000
    sta.z ram_addr_1
    lda.z ram_addr_1+1
    sbc #>$2000
    sta.z ram_addr_1+1
    // [261] phi from main::@17 main::@20 to main::@18 [phi:main::@17/main::@20->main::@18]
    // [261] phi main::ram_addr#13 = main::ram_addr#14 [phi:main::@17/main::@20->main::@18#0] -- register_copy 
    // main::@18
  __b18:
    // fgets(ram_addr, 128, fp)
    // [262] fgets::ptr#4 = main::ram_addr#13 -- pbuz1=pbuz2 
    lda.z ram_addr_1
    sta.z fgets.ptr
    lda.z ram_addr_1+1
    sta.z fgets.ptr+1
    // [263] fgets::fp#2 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [264] call fgets
    // [430] phi from main::@18 to fgets [phi:main::@18->fgets]
    // [430] phi fgets::ptr#13 = fgets::ptr#4 [phi:main::@18->fgets#0] -- register_copy 
    // [430] phi fgets::fp#20 = fgets::fp#2 [phi:main::@18->fgets#1] -- register_copy 
    jsr fgets
    // fgets(ram_addr, 128, fp)
    // [265] fgets::return#11 = fgets::return#1
    // main::@91
    // bytes = fgets(ram_addr, 128, fp)
    // [266] main::bytes#3 = fgets::return#11
    // [144] phi from main::@91 to main::@14 [phi:main::@91->main::@14]
    // [144] phi main::ram_addr#12 = main::ram_addr#13 [phi:main::@91->main::@14#0] -- register_copy 
    // [144] phi main::bytes#10 = main::bytes#3 [phi:main::@91->main::@14#1] -- register_copy 
    // [144] phi main::rom_addr#10 = main::rom_addr#2 [phi:main::@91->main::@14#2] -- register_copy 
    jmp __b14
    // main::@8
  __b8:
    // fgets(ram_addr, 128, fp)
    // [267] fgets::ptr#2 = main::ram_addr#10 -- pbuz1=pbuz2 
    lda.z ram_addr
    sta.z fgets.ptr
    lda.z ram_addr+1
    sta.z fgets.ptr+1
    // [268] fgets::fp#0 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.fp
    lda.z fp+1
    sta.z fgets.fp+1
    // [269] call fgets
    // [430] phi from main::@8 to fgets [phi:main::@8->fgets]
    // [430] phi fgets::ptr#13 = fgets::ptr#2 [phi:main::@8->fgets#0] -- register_copy 
    // [430] phi fgets::fp#20 = fgets::fp#0 [phi:main::@8->fgets#1] -- register_copy 
    jsr fgets
    // fgets(ram_addr, 128, fp)
    // [270] fgets::return#5 = fgets::return#1
    // main::@82
    // bytes = fgets(ram_addr, 128, fp)
    // [271] main::bytes#1 = fgets::return#5 -- vwuz1=vwuz2 
    lda.z fgets.return
    sta.z bytes
    lda.z fgets.return+1
    sta.z bytes+1
    // if(!bytes)
    // [272] if(0==main::bytes#1) goto main::@10 -- 0_eq_vwuz1_then_la1 
    // this will load 128 bytes from the rom.bin file or less if EOF is reached.
    lda.z bytes
    ora.z bytes+1
    bne !__b10+
    jmp __b10
  !__b10:
    // main::@12
    // rom_addr % 0x02000
    // [273] main::$43 = main::rom_addr#31 & $2000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_addr
    and #<$2000-1
    sta.z __43
    lda.z rom_addr+1
    and #>$2000-1
    sta.z __43+1
    lda.z rom_addr+2
    and #<$2000-1>>$10
    sta.z __43+2
    lda.z rom_addr+3
    and #>$2000-1>>$10
    sta.z __43+3
    // if (!(rom_addr % 0x02000))
    // [274] if(0!=main::$43) goto main::@11 -- 0_neq_vduz1_then_la1 
    lda.z __43
    ora.z __43+1
    ora.z __43+2
    ora.z __43+3
    bne __b11
    // [275] phi from main::@12 to main::@13 [phi:main::@12->main::@13]
    // main::@13
    // printf("\n%06x : ", rom_addr)
    // [276] call printf_str
    // [353] phi from main::@13 to printf_str [phi:main::@13->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@13->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s3 [phi:main::@13->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@84
    // printf("\n%06x : ", rom_addr)
    // [277] printf_ulong::uvalue#0 = main::rom_addr#31 -- vduz1=vduz2 
    lda.z rom_addr
    sta.z printf_ulong.uvalue
    lda.z rom_addr+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_addr+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_addr+3
    sta.z printf_ulong.uvalue+3
    // [278] call printf_ulong
    // [472] phi from main::@84 to printf_ulong [phi:main::@84->printf_ulong]
    // [472] phi printf_ulong::uvalue#5 = printf_ulong::uvalue#0 [phi:main::@84->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [279] phi from main::@84 to main::@85 [phi:main::@84->main::@85]
    // main::@85
    // printf("\n%06x : ", rom_addr)
    // [280] call printf_str
    // [353] phi from main::@85 to printf_str [phi:main::@85->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@85->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s16 [phi:main::@85->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@11
  __b11:
    // cputc('.')
    // [281] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [282] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_addr += bytes
    // [284] main::ram_addr#2 = main::ram_addr#10 + main::bytes#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_addr
    adc.z bytes
    sta.z ram_addr
    lda.z ram_addr+1
    adc.z bytes+1
    sta.z ram_addr+1
    // rom_addr += bytes
    // [285] main::rom_addr#1 = main::rom_addr#31 + main::bytes#1 -- vduz1=vduz1_plus_vwuz2 
    lda.z rom_addr
    clc
    adc.z bytes
    sta.z rom_addr
    lda.z rom_addr+1
    adc.z bytes+1
    sta.z rom_addr+1
    lda.z rom_addr+2
    adc #0
    sta.z rom_addr+2
    lda.z rom_addr+3
    adc #0
    sta.z rom_addr+3
    // [135] phi from main::@11 to main::@7 [phi:main::@11->main::@7]
    // [135] phi main::ram_addr#10 = main::ram_addr#2 [phi:main::@11->main::@7#0] -- register_copy 
    // [135] phi main::rom_addr#31 = main::rom_addr#1 [phi:main::@11->main::@7#1] -- register_copy 
    jmp __b7
    // [286] phi from main::@82 to main::@10 [phi:main::@82->main::@10]
    // main::@10
  __b10:
    // printf("error: rom.bin is incomplete!")
    // [287] call printf_str
    // [353] phi from main::@10 to printf_str [phi:main::@10->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:main::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = main::s14 [phi:main::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    rts
  .segment Data
    s: .text @"rom flash utility\n"
    .byte 0
    s1: .text @"\nrom chipset device determination:\n\n"
    .byte 0
    s2: .text "manufacturer id = "
    .byte 0
    s3: .text @"\n"
    .byte 0
    s4: .text "device id = "
    .byte 0
    s5: .text " ("
    .byte 0
    s6: .text @")\n"
    .byte 0
    s7: .text @"\nopening file rom.bin from the sd card ... "
    .byte 0
    filename: .text "rom.bin"
    .byte 0
    s8: .text @"success ...\n"
    .byte 0
    s9: .text @"\nloading kernal rom in main memory ...\n"
    .byte 0
    s10: .text @"error!\n"
    .byte 0
    s11: .text "error code = "
    .byte 0
    s13: .text @"\n\nloading remaining rom in banked memory ...\n"
    .byte 0
    s14: .text "error: rom.bin is incomplete!"
    .byte 0
    s16: .text " : "
    .byte 0
    s17: .text @"\n\na total of "
    .byte 0
    s18: .text " rom bytes to be upgraded from rom.bin ..."
    .byte 0
    s19: .text @"\npress any key to upgrade to the new rom ...\n"
    .byte 0
    s22: .text @"\nupgrading kernal rom from main memory ...\n"
    .byte 0
    s23: .text @"\n\nflashing remaining rom from banked memory ...\n"
    .byte 0
    s26: .text @"\n\nflashing of new rom successful ... resetting commander x16 to new rom...\n"
    .byte 0
    rom_device_1: .text "sst39sf010a"
    .byte 0
    rom_device_2: .text "sst39sf020a"
    .byte 0
    rom_device_3: .text "sst39sf040"
    .byte 0
    rom_device_4: .text "unknown"
    .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [288] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [289] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [290] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [291] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(char color)
textcolor: {
    .label __0 = $77
    .label __1 = $77
    // __conio.color & 0xF0
    // [292] textcolor::$0 = *((char *)&__conio+$b) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$b
    sta.z __0
    // __conio.color & 0xF0 | color
    // [293] textcolor::$1 = textcolor::$0 | WHITE -- vbuz1=vbuz1_bor_vbuc1 
    lda #WHITE
    ora.z __1
    sta.z __1
    // __conio.color = __conio.color & 0xF0 | color
    // [294] *((char *)&__conio+$b) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$b
    // textcolor::@return
    // }
    // [295] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(char color)
bgcolor: {
    .label __0 = $73
    .label __2 = $73
    // __conio.color & 0x0F
    // [296] bgcolor::$0 = *((char *)&__conio+$b) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$b
    sta.z __0
    // __conio.color & 0x0F | color << 4
    // [297] bgcolor::$2 = bgcolor::$0 | BLUE<<4 -- vbuz1=vbuz1_bor_vbuc1 
    lda #BLUE<<4
    ora.z __2
    sta.z __2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [298] *((char *)&__conio+$b) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$b
    // bgcolor::@return
    // }
    // [299] return 
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
    // [300] *((char *)&__conio+$a) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$a
    // cursor::@return
    // }
    // [301] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $6b
    // __mem unsigned char x
    // [302] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [303] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [305] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [306] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($33) char x, __zp($34) char y)
gotoxy: {
    .label __2 = $33
    .label __3 = $33
    .label __6 = $32
    .label __7 = $32
    .label __8 = $37
    .label __9 = $35
    .label __10 = $34
    .label x = $33
    .label y = $34
    .label __14 = $32
    // (x>=__conio.width)?__conio.width:x
    // [308] if(gotoxy::x#3>=*((char *)&__conio+4)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+4
    bcs __b1
    // [310] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [310] phi gotoxy::$3 = gotoxy::x#3 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [309] gotoxy::$2 = *((char *)&__conio+4) -- vbuz1=_deref_pbuc1 
    lda __conio+4
    sta.z __2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [311] *((char *)&__conio+$d) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z __3
    sta __conio+$d
    // (y>=__conio.height)?__conio.height:y
    // [312] if(gotoxy::y#3>=*((char *)&__conio+5)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+5
    bcs __b3
    // gotoxy::@4
    // [313] gotoxy::$14 = gotoxy::y#3 -- vbuz1=vbuz2 
    sta.z __14
    // [314] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [314] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [315] *((char *)&__conio+$e) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z __7
    sta __conio+$e
    // __conio.cursor_x << 1
    // [316] gotoxy::$8 = *((char *)&__conio+$d) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$d
    asl
    sta.z __8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [317] gotoxy::$10 = gotoxy::y#3 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __10
    // [318] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z __10
    clc
    adc __conio+$15,y
    sta.z __9
    lda __conio+$15+1,y
    adc #0
    sta.z __9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [319] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z __9
    sta __conio+$13
    lda.z __9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [320] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [321] gotoxy::$6 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z __6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label __2 = $41
    // __conio.cursor_x = 0
    // [322] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y++;
    // [323] *((char *)&__conio+$e) = ++ *((char *)&__conio+$e) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+$e
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [324] cputln::$2 = *((char *)&__conio+$e) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    sta.z __2
    // [325] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [326] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [327] return 
    rts
}
  // cbm_x_charset
/**
 * @brief Sets the [character set](https://github.com/commanderx16/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-screen_set_charset).
 * 
 * @param charset The code of the charset to copy.
 * @param offset The offset of the character set in ram.
 */
// void cbm_x_charset(__zp($d3) volatile char charset, __zp($d1) char * volatile offset)
cbm_x_charset: {
    .label charset = $d3
    .label offset = $d1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_CHRSET  }
    lda charset
    ldx.z <offset
    ldy.z >offset
    jsr CX16_CHRSET
    // cbm_x_charset::@return
    // }
    // [329] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label __0 = $48
    .label __1 = $6d
    .label __2 = $5d
    .label line_text = $4d
    .label l = $42
    .label ch = $4d
    .label c = $5c
    // unsigned int line_text = __conio.mapbase_offset
    // [330] clrscr::line_text#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z line_text
    lda __conio+1+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [331] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [332] clrscr::$0 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [333] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [334] clrscr::l#0 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z l
    // [335] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [335] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [335] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [336] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z __1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [337] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [338] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z __2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [339] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth
    // [340] clrscr::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [341] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [341] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [342] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [343] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [344] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [345] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [346] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+8
    sta.z line_text
    lda.z line_text+1
    adc __conio+8+1
    sta.z line_text+1
    // l--;
    // [347] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [348] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [349] *((char *)&__conio+$d) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+$d
    // __conio.cursor_y = 0
    // [350] *((char *)&__conio+$e) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+$e
    // __conio.offset = __conio.mapbase_offset
    // [351] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+1) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+1
    sta __conio+$13
    lda __conio+1+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [352] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($4d) void (*putc)(char), __zp($4a) const char *s)
printf_str: {
    .label c = $48
    .label s = $4a
    .label putc = $4d
    // [354] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [354] phi printf_str::s#32 = printf_str::s#33 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [355] printf_str::c#1 = *printf_str::s#32 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [356] printf_str::s#0 = ++ printf_str::s#32 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [357] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [358] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [359] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [360] callexecute *printf_str::putc#33  -- call__deref_pprz1 
    jsr icall6
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall6:
    jmp (putc)
}
  // rom_unlock
/**
 * @brief Unlock a byte location for flashing using the 19 bit address.
 * This is a various purpose routine to unlock the ROM for flashing a byte.
 * The 3rd byte can be variable, depending on the write sequence used, so this byte is a parameter into the routine.
 * 
 * @param address The 3rd write to model the specific unlock sequence.
 * @param unlock_code The 3rd write to model the specific unlock sequence.
 */
// void rom_unlock(__zp($38) unsigned long address, __zp($42) char unlock_code)
rom_unlock: {
    .label address = $38
    .label unlock_code = $42
    // rom_write_byte(0x05555, 0xAA)
    // [363] call rom_write_byte
    // [550] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [550] phi rom_write_byte::value#4 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [550] phi rom_write_byte::address#4 = $5555 [phi:rom_unlock->rom_write_byte#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_write_byte.address
    lda #>$5555
    sta.z rom_write_byte.address+1
    lda #<$5555>>$10
    sta.z rom_write_byte.address+2
    lda #>$5555>>$10
    sta.z rom_write_byte.address+3
    jsr rom_write_byte
    // [364] phi from rom_unlock to rom_unlock::@1 [phi:rom_unlock->rom_unlock::@1]
    // rom_unlock::@1
    // rom_write_byte(0x02AAA, 0x55)
    // [365] call rom_write_byte
    // [550] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [550] phi rom_write_byte::value#4 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [550] phi rom_write_byte::address#4 = $2aaa [phi:rom_unlock::@1->rom_write_byte#1] -- vduz1=vduc1 
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
    // [366] rom_write_byte::address#2 = rom_unlock::address#10 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [367] rom_write_byte::value#2 = rom_unlock::unlock_code#10 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [368] call rom_write_byte
    // [550] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [550] phi rom_write_byte::value#4 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [550] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [369] return 
    rts
}
  // rom_read_byte
/**
 * @brief Read a byte from the ROM using the 19 bit address.
 * The lower 14 bits of the 19 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 5 bits of the 19 bit ROM address are transformed into the **bank_rom** 5 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to read the byte.
 * 
 * @param address The 19 bit ROM address.
 * @return unsigned char The byte read from the ROM.
 */
// __zp($cb) char rom_read_byte(__zp($58) unsigned long address)
rom_read_byte: {
    .label bank_rom = $5c
    .label ptr_rom = $4d
    .label return = $cb
    .label address = $58
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [371] rom_bank::address#0 = rom_read_byte::address#4 -- vduz1=vduz2 
    lda.z address
    sta.z rom_bank.address
    lda.z address+1
    sta.z rom_bank.address+1
    lda.z address+2
    sta.z rom_bank.address+2
    lda.z address+3
    sta.z rom_bank.address+3
    // [372] call rom_bank
    // [562] phi from rom_read_byte to rom_bank [phi:rom_read_byte->rom_bank]
    // [562] phi rom_bank::address#2 = rom_bank::address#0 [phi:rom_read_byte->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [373] rom_bank::return#2 = rom_bank::return#0
    // rom_read_byte::@1
    // [374] rom_read_byte::bank_rom#0 = rom_bank::return#2
    // brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address)
    // [375] rom_ptr::address#0 = rom_read_byte::address#4
    // [376] call rom_ptr
    // [567] phi from rom_read_byte::@1 to rom_ptr [phi:rom_read_byte::@1->rom_ptr]
    // [567] phi rom_ptr::address#4 = rom_ptr::address#0 [phi:rom_read_byte::@1->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_read_byte::@2
    // brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address)
    // [377] rom_read_byte::ptr_rom#0 = (char *)rom_ptr::return#0
    // bank_set_brom(bank_rom)
    // [378] bank_set_brom::bank#0 = rom_read_byte::bank_rom#0
    // [379] call bank_set_brom
    // [382] phi from rom_read_byte::@2 to bank_set_brom [phi:rom_read_byte::@2->bank_set_brom]
    // [382] phi bank_set_brom::bank#5 = bank_set_brom::bank#0 [phi:rom_read_byte::@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_read_byte::@3
    // return *ptr_rom;
    // [380] rom_read_byte::return#0 = *rom_read_byte::ptr_rom#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [381] return 
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
// void bank_set_brom(__zp($5c) char bank)
bank_set_brom: {
    .label bank = $5c
    // BROM = bank
    // [383] BROM = bank_set_brom::bank#5 -- vbuz1=vbuz2 
    lda.z bank
    sta.z BROM
    // bank_set_brom::@return
    // }
    // [384] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(void (*putc)(char), __zp($4c) char uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, __zp($6d) char format_radix)
printf_uchar: {
    .label uvalue = $4c
    .label format_radix = $6d
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [386] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [387] uctoa::value#1 = printf_uchar::uvalue#3
    // [388] uctoa::radix#0 = printf_uchar::format_radix#3
    // [389] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [390] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [391] call printf_number_buffer
  // Print using format
    // [600] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [600] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [600] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_zero_padding
    // [600] phi printf_number_buffer::format_min_length#2 = 0 [phi:printf_uchar::@2->printf_number_buffer#2] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [392] return 
    rts
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($cc) char *str, char format_min_length, char format_justify_left)
printf_string: {
    .label putc = cputc
    .label str = $cc
    // printf_string::@1
    // printf_str(putc, str)
    // [394] printf_str::s#2 = printf_string::str#0 -- pbuz1=pbuz2 
    lda.z str
    sta.z printf_str.s
    lda.z str+1
    sta.z printf_str.s+1
    // [395] call printf_str
    // [353] phi from printf_string::@1 to printf_str [phi:printf_string::@1->printf_str]
    // [353] phi printf_str::putc#33 = printf_string::putc#0 [phi:printf_string::@1->printf_str#0] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_str.putc
    lda #>putc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = printf_str::s#2 [phi:printf_string::@1->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@return
    // }
    // [396] return 
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
// __zp($4a) struct $0 * fopen(char channel, char device, char secondary, char *filename)
fopen: {
    .const channel = 1
    .const device = 8
    .const secondary = 2
    .label __4 = $5d
    .label __7 = $3c
    .label __9 = $6d
    .label fp = $4a
    .label return = $4a
    .label __30 = $6d
    .label __31 = $6d
    // FILE* fp = &__files[__filecount]
    // [397] fopen::$30 = __filecount << 2 -- vbuz1=vbum2_rol_2 
    lda __filecount
    asl
    asl
    sta.z __30
    // [398] fopen::$31 = fopen::$30 + __filecount -- vbuz1=vbuz1_plus_vbum2 
    lda __filecount
    clc
    adc.z __31
    sta.z __31
    // [399] fopen::$9 = fopen::$31 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z __9
    asl
    asl
    sta.z __9
    // [400] fopen::fp#0 = __files + fopen::$9 -- pssz1=pssc1_plus_vbuz2 
    clc
    adc #<__files
    sta.z fp
    lda #>__files
    adc #0
    sta.z fp+1
    // fp->status = 0
    // [401] ((char *)fopen::fp#0)[$13] = 0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #0
    ldy #$13
    sta (fp),y
    // fp->channel = channel
    // [402] ((char *)fopen::fp#0)[$10] = fopen::channel#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #channel
    ldy #$10
    sta (fp),y
    // fp->device = device
    // [403] ((char *)fopen::fp#0)[$11] = fopen::device#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #device
    ldy #$11
    sta (fp),y
    // fp->secondary = secondary
    // [404] ((char *)fopen::fp#0)[$12] = fopen::secondary#0 -- pbuz1_derefidx_vbuc1=vbuc2 
    lda #secondary
    ldy #$12
    sta (fp),y
    // strncpy(fp->filename, filename, 16)
    // [405] strncpy::dst#1 = (char *)fopen::fp#0 -- pbuz1=pbuz2 
    lda.z fp
    sta.z strncpy.dst
    lda.z fp+1
    sta.z strncpy.dst+1
    // [406] call strncpy
    // [629] phi from fopen to strncpy [phi:fopen->strncpy]
    jsr strncpy
    // fopen::@3
    // cbm_k_setnam(filename)
    // [407] cbm_k_setnam::filename = main::filename -- pbuz1=pbuc1 
    lda #<main.filename
    sta.z cbm_k_setnam.filename
    lda #>main.filename
    sta.z cbm_k_setnam.filename+1
    // [408] call cbm_k_setnam
    jsr cbm_k_setnam
    // fopen::@4
    // cbm_k_setlfs(channel, device, secondary)
    // [409] cbm_k_setlfs::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_setlfs.channel
    // [410] cbm_k_setlfs::device = fopen::device#0 -- vbuz1=vbuc1 
    lda #device
    sta.z cbm_k_setlfs.device
    // [411] cbm_k_setlfs::command = fopen::secondary#0 -- vbuz1=vbuc1 
    lda #secondary
    sta.z cbm_k_setlfs.command
    // [412] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // [413] phi from fopen::@4 to fopen::@5 [phi:fopen::@4->fopen::@5]
    // fopen::@5
    // cbm_k_open()
    // [414] call cbm_k_open
    jsr cbm_k_open
    // [415] cbm_k_open::return#2 = cbm_k_open::return#1
    // fopen::@6
    // [416] fopen::$4 = cbm_k_open::return#2
    // fp->status = cbm_k_open()
    // [417] ((char *)fopen::fp#0)[$13] = fopen::$4 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __4
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [418] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b1
    // [419] phi from fopen::@6 fopen::@8 to fopen::@return [phi:fopen::@6/fopen::@8->fopen::@return]
  __b3:
    // [419] phi fopen::return#1 = 0 [phi:fopen::@6/fopen::@8->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [420] return 
    rts
    // fopen::@1
  __b1:
    // cbm_k_chkin(channel)
    // [421] cbm_k_chkin::channel = fopen::channel#0 -- vbuz1=vbuc1 
    lda #channel
    sta.z cbm_k_chkin.channel
    // [422] call cbm_k_chkin
    jsr cbm_k_chkin
    // [423] phi from fopen::@1 to fopen::@7 [phi:fopen::@1->fopen::@7]
    // fopen::@7
    // cbm_k_readst()
    // [424] call cbm_k_readst
    jsr cbm_k_readst
    // [425] cbm_k_readst::return#2 = cbm_k_readst::return#1
    // fopen::@8
    // [426] fopen::$7 = cbm_k_readst::return#2
    // fp->status = cbm_k_readst()
    // [427] ((char *)fopen::fp#0)[$13] = fopen::$7 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __7
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [428] if(0==((char *)fopen::fp#0)[$13]) goto fopen::@2 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b2
    jmp __b3
    // fopen::@2
  __b2:
    // __filecount++;
    // [429] __filecount = ++ __filecount -- vbum1=_inc_vbum1 
    inc __filecount
    // [419] phi from fopen::@2 to fopen::@return [phi:fopen::@2->fopen::@return]
    // [419] phi fopen::return#1 = fopen::fp#0 [phi:fopen::@2->fopen::@return#0] -- register_copy 
    rts
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
// __zp($67) unsigned int fgets(__zp($53) char *ptr, unsigned int size, __zp($4d) struct $0 *fp)
fgets: {
    .label __1 = $3c
    .label __9 = $3c
    .label __10 = $48
    .label __14 = $43
    .label return = $67
    .label bytes = $55
    .label read = $67
    .label ptr = $53
    .label remaining = $46
    .label fp = $4d
    // cbm_k_chkin(fp->channel)
    // [431] cbm_k_chkin::channel = ((char *)fgets::fp#20)[$10] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #$10
    lda (fp),y
    sta.z cbm_k_chkin.channel
    // [432] call cbm_k_chkin
    jsr cbm_k_chkin
    // [433] phi from fgets to fgets::@11 [phi:fgets->fgets::@11]
    // fgets::@11
    // cbm_k_readst()
    // [434] call cbm_k_readst
    jsr cbm_k_readst
    // [435] cbm_k_readst::return#3 = cbm_k_readst::return#1
    // fgets::@12
    // [436] fgets::$1 = cbm_k_readst::return#3
    // fp->status = cbm_k_readst()
    // [437] ((char *)fgets::fp#20)[$13] = fgets::$1 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __1
    ldy #$13
    sta (fp),y
    // if(fp->status)
    // [438] if(0==((char *)fgets::fp#20)[$13]) goto fgets::@1 -- 0_eq_pbuz1_derefidx_vbuc1_then_la1 
    lda (fp),y
    cmp #0
    beq __b8
    // [439] phi from fgets::@12 fgets::@15 fgets::@4 to fgets::@return [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return]
  __b1:
    // [439] phi fgets::return#1 = 0 [phi:fgets::@12/fgets::@15/fgets::@4->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [440] return 
    rts
    // [441] phi from fgets::@12 to fgets::@1 [phi:fgets::@12->fgets::@1]
  __b8:
    // [441] phi fgets::read#10 = 0 [phi:fgets::@12->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [441] phi fgets::remaining#11 = $80 [phi:fgets::@12->fgets::@1#1] -- vwuz1=vbuc1 
    lda #<$80
    sta.z remaining
    lda #>$80
    sta.z remaining+1
    // [441] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@12->fgets::@1#2] -- register_copy 
    // [441] phi from fgets::@16 to fgets::@1 [phi:fgets::@16->fgets::@1]
    // [441] phi fgets::read#10 = fgets::read#1 [phi:fgets::@16->fgets::@1#0] -- register_copy 
    // [441] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@16->fgets::@1#1] -- register_copy 
    // [441] phi fgets::ptr#10 = fgets::ptr#14 [phi:fgets::@16->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@7
  __b7:
    // if(remaining >= 128)
    // [442] if(fgets::remaining#11>=$80) goto fgets::@2 -- vwuz1_ge_vbuc1_then_la1 
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
    // [443] cbm_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cbm_k_macptr.bytes
    // [444] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [445] call cbm_k_macptr
    jsr cbm_k_macptr
    // [446] cbm_k_macptr::return#4 = cbm_k_macptr::return#1
    // fgets::@14
    // bytes = cbm_k_macptr(remaining, ptr)
    // [447] fgets::bytes#3 = cbm_k_macptr::return#4
    // [448] phi from fgets::@13 fgets::@14 to fgets::@3 [phi:fgets::@13/fgets::@14->fgets::@3]
    // [448] phi fgets::bytes#4 = fgets::bytes#2 [phi:fgets::@13/fgets::@14->fgets::@3#0] -- register_copy 
    // fgets::@3
  __b3:
    // cbm_k_readst()
    // [449] call cbm_k_readst
    jsr cbm_k_readst
    // [450] cbm_k_readst::return#4 = cbm_k_readst::return#1
    // fgets::@15
    // [451] fgets::$9 = cbm_k_readst::return#4
    // fp->status = cbm_k_readst()
    // [452] ((char *)fgets::fp#20)[$13] = fgets::$9 -- pbuz1_derefidx_vbuc1=vbuz2 
    lda.z __9
    ldy #$13
    sta (fp),y
    // fp->status & 0xBF
    // [453] fgets::$10 = ((char *)fgets::fp#20)[$13] & $bf -- vbuz1=pbuz2_derefidx_vbuc1_band_vbuc2 
    lda #$bf
    and (fp),y
    sta.z __10
    // if(fp->status & 0xBF)
    // [454] if(0==fgets::$10) goto fgets::@4 -- 0_eq_vbuz1_then_la1 
    beq __b4
    jmp __b1
    // fgets::@4
  __b4:
    // if(bytes == 0xFFFF)
    // [455] if(fgets::bytes#4!=$ffff) goto fgets::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [456] fgets::read#1 = fgets::read#10 + fgets::bytes#4 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [457] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#4 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [458] fgets::$14 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z __14
    // if(BYTE1(ptr) == 0xC0)
    // [459] if(fgets::$14!=$c0) goto fgets::@6 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z __14
    bne __b6
    // fgets::@9
    // ptr -= 0x2000
    // [460] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [461] phi from fgets::@5 fgets::@9 to fgets::@6 [phi:fgets::@5/fgets::@9->fgets::@6]
    // [461] phi fgets::ptr#14 = fgets::ptr#0 [phi:fgets::@5/fgets::@9->fgets::@6#0] -- register_copy 
    // fgets::@6
  __b6:
    // remaining -= bytes
    // [462] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#4 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((fp->status == 0) && ((size && remaining) || !size))
    // [463] if(((char *)fgets::fp#20)[$13]==0) goto fgets::@16 -- pbuz1_derefidx_vbuc1_eq_0_then_la1 
    ldy #$13
    lda (fp),y
    cmp #0
    beq __b16
    jmp __b10
    // fgets::@16
  __b16:
    // [464] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b7+
    jmp __b7
  !__b7:
    // fgets::@10
  __b10:
    // cbm_k_chkin(0)
    // [465] cbm_k_chkin::channel = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin.channel
    // [466] call cbm_k_chkin
    jsr cbm_k_chkin
    // [439] phi from fgets::@10 to fgets::@return [phi:fgets::@10->fgets::@return]
    // [439] phi fgets::return#1 = fgets::read#1 [phi:fgets::@10->fgets::@return#0] -- register_copy 
    rts
    // fgets::@2
  __b2:
    // cbm_k_macptr(128, ptr)
    // [467] cbm_k_macptr::bytes = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cbm_k_macptr.bytes
    // [468] cbm_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cbm_k_macptr.buffer
    lda.z ptr+1
    sta.z cbm_k_macptr.buffer+1
    // [469] call cbm_k_macptr
    jsr cbm_k_macptr
    // [470] cbm_k_macptr::return#3 = cbm_k_macptr::return#1
    // fgets::@13
    // bytes = cbm_k_macptr(128, ptr)
    // [471] fgets::bytes#2 = cbm_k_macptr::return#3
    jmp __b3
}
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($38) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $38
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [473] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [474] ultoa::value#1 = printf_ulong::uvalue#5
    // [475] call ultoa
  // Format number into buffer
    // [667] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [476] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [477] call printf_number_buffer
  // Print using format
    // [600] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [600] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [600] phi printf_number_buffer::format_zero_padding#10 = 1 [phi:printf_ulong::@2->printf_number_buffer#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_number_buffer.format_zero_padding
    // [600] phi printf_number_buffer::format_min_length#2 = 6 [phi:printf_ulong::@2->printf_number_buffer#2] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [478] return 
    rts
}
  // getin
/**
 * @brief Get a character from keyboard.
 * 
 * @return char The character read.
 */
getin: {
    .label return = $49
    // __mem unsigned char ch
    // [479] getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsr$ffe4 stach  }
    jsr $ffe4
    sta ch
    // return ch;
    // [481] getin::return#0 = getin::ch -- vbuz1=vbum2 
    sta.z return
    // getin::@return
    // }
    // [482] getin::return#1 = getin::return#0
    // [483] return 
    rts
  .segment Data
    ch: .byte 0
}
.segment Code
  // rom_sector_erase
/**
 * @brief Erases a 1KB sector of the ROM using the 19 bit address.
 * This is required before any new bytes can be flashed into the ROM.
 * Erasing a sector of the ROM requires an erase sector sequence to be initiated, which has the following steps:
 * 
 *   1. Write byte $AA into ROM address $005555.
 *   2. Write byte $55 into ROM address $002AAA.
 *   3. Write byte $80 into ROM address $005555.
 *   4. Write byte $AA into ROM address $005555.
 *   5. Write byte $55 into ROM address $002AAA.
 * 
 * Once this write sequence is finished, the ROM sector is erased by writing byte $30 into the 19 bit ROM sector address.
 * Then it waits until the chip has correctly flashed the ROM erasure.
 * 
 * Note that a ROM sector is 1KB (not 4KB), so the most 7 significant bits (18-12) are used. 
 * The remainder 12 low bits are ignored.
 * 
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *                                   | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *      SECTOR              0x7F000  | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *      IGNORED             0x00FFF  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 * 
 * @param address The 19 bit ROM address.
 */
// void rom_sector_erase(__zp($ad) unsigned long address)
rom_sector_erase: {
    .label ptr_rom = $46
    .label address = $ad
    // brom_ptr_t ptr_rom  = rom_ptr((unsigned long)address)
    // [485] rom_ptr::address#3 = rom_sector_erase::address#2 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [486] call rom_ptr
    // [567] phi from rom_sector_erase to rom_ptr [phi:rom_sector_erase->rom_ptr]
    // [567] phi rom_ptr::address#4 = rom_ptr::address#3 [phi:rom_sector_erase->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_sector_erase::@1
    // brom_ptr_t ptr_rom  = rom_ptr((unsigned long)address)
    // [487] rom_sector_erase::ptr_rom#0 = (char *)rom_ptr::return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // rom_unlock(0x05555, 0x80)
    // [488] call rom_unlock
    // [362] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [362] phi rom_unlock::unlock_code#10 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [362] phi rom_unlock::address#10 = $5555 [phi:rom_sector_erase::@1->rom_unlock#1] -- vduz1=vduc1 
    lda #<$5555
    sta.z rom_unlock.address
    lda #>$5555
    sta.z rom_unlock.address+1
    lda #<$5555>>$10
    sta.z rom_unlock.address+2
    lda #>$5555>>$10
    sta.z rom_unlock.address+3
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [489] rom_unlock::address#1 = rom_sector_erase::address#2 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [490] call rom_unlock
    // [362] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [362] phi rom_unlock::unlock_code#10 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [362] phi rom_unlock::address#10 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [491] rom_wait::ptr_rom#1 = rom_sector_erase::ptr_rom#0
    // [492] call rom_wait
    // [688] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [688] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [493] return 
    rts
}
  // rom_byte_program
/**
 * @brief Write a byte and wait until the byte has been successfully flashed into the ROM.
 * 
 * @param address The 19 bit ROM address.
 * @param value The byte value to be written.
 */
// void rom_byte_program(__zp($60) unsigned long address, __zp($6d) char value)
rom_byte_program: {
    .label ptr_rom = $4a
    .label address = $60
    .label value = $6d
    // brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address)
    // [495] rom_ptr::address#2 = rom_byte_program::address#2 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [496] call rom_ptr
    // [567] phi from rom_byte_program to rom_ptr [phi:rom_byte_program->rom_ptr]
    // [567] phi rom_ptr::address#4 = rom_ptr::address#2 [phi:rom_byte_program->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_byte_program::@1
    // brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address)
    // [497] rom_byte_program::ptr_rom#0 = (char *)rom_ptr::return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // rom_write_byte(address, value)
    // [498] rom_write_byte::address#3 = rom_byte_program::address#2
    // [499] rom_write_byte::value#3 = rom_byte_program::value#2 -- vbuz1=vbuz2 
    lda.z value
    sta.z rom_write_byte.value
    // [500] call rom_write_byte
    // [550] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [550] phi rom_write_byte::value#4 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [550] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [501] rom_wait::ptr_rom#0 = rom_byte_program::ptr_rom#0 -- pbuz1=pbuz2 
    lda.z ptr_rom
    sta.z rom_wait.ptr_rom
    lda.z ptr_rom+1
    sta.z rom_wait.ptr_rom+1
    // [502] call rom_wait
    // [688] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [688] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [503] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($77) char mapbase, __zp($73) char config)
screenlayer: {
    .label __0 = $7e
    .label __1 = $77
    .label __2 = $a9
    .label __5 = $73
    .label __6 = $73
    .label __7 = $70
    .label __8 = $70
    .label __9 = $6e
    .label __10 = $6e
    .label __11 = $6e
    .label __12 = $6f
    .label __13 = $6f
    .label __14 = $6f
    .label __16 = $70
    .label __17 = $6a
    .label __18 = $6e
    .label __19 = $6f
    .label mapbase_offset = $6b
    .label y = $69
    .label mapbase = $77
    .label config = $73
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [504] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [505] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [506] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // mapbase >> 7
    // [507] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z __0
    // __conio.mapbase_bank = mapbase >> 7
    // [508] *((char *)&__conio+3) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+3
    // (mapbase)<<1
    // [509] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __1
    // MAKEWORD((mapbase)<<1,0)
    // [510] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z __1
    sty.z __2+1
    sta.z __2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [511] *((unsigned int *)&__conio+1) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+1
    tya
    sta __conio+1+1
    // config & VERA_LAYER_WIDTH_MASK
    // [512] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z __7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [513] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z __8
    lsr
    lsr
    lsr
    lsr
    sta.z __8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [514] *((char *)&__conio+6) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+6
    // config & VERA_LAYER_HEIGHT_MASK
    // [515] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z __5
    sta.z __5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [516] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z __6
    rol
    rol
    rol
    and #3
    sta.z __6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [517] *((char *)&__conio+7) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+7
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [518] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __16
    // [519] *((unsigned int *)&__conio+8) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z __16
    lda VERA_LAYER_SKIP,y
    sta __conio+8
    lda VERA_LAYER_SKIP+1,y
    sta __conio+8+1
    // vera_dc_hscale_temp == 0x80
    // [520] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z __9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [521] screenlayer::$18 = (char)screenlayer::$9
    // [522] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [523] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z __11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [524] *((char *)&__conio+4) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z __11
    sta __conio+4
    // vera_dc_vscale_temp == 0x80
    // [525] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z __12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [526] screenlayer::$19 = (char)screenlayer::$12
    // [527] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [528] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z __14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [529] *((char *)&__conio+5) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z __14
    sta __conio+5
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [530] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+1) -- vwuz1=_deref_pwuc1 
    lda __conio+1
    sta.z mapbase_offset
    lda __conio+1+1
    sta.z mapbase_offset+1
    // [531] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [531] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [531] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<__conio.height; y++)
    // [532] if(screenlayer::y#2<*((char *)&__conio+5)) goto screenlayer::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+5
    bcc __b2
    // screenlayer::@return
    // }
    // [533] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [534] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z __17
    // [535] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [536] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+8) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+8
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+8+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<__conio.height; y++)
    // [537] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [531] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [531] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [531] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [538] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [539] if(0!=((char *)&__conio+$f)[*((char *)&__conio)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [540] if(*((char *)&__conio+$e)<=*((char *)&__conio+5)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+5
    cmp __conio+$e
    bcs __breturn
    // [541] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [542] call gotoxy
    // [307] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [307] phi gotoxy::y#3 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [307] phi gotoxy::x#3 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [543] return 
    rts
    // [544] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [545] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [546] gotoxy::y#1 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z gotoxy.y
    // [547] call gotoxy
    // [307] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [307] phi gotoxy::y#3 = gotoxy::y#1 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [307] phi gotoxy::x#3 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [548] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [549] call clearline
    jsr clearline
    rts
}
  // rom_write_byte
/**
 * @brief Write a byte to the ROM using the 19 bit address.
 * The lower 14 bits of the 19 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 5 bits of the 19 bit ROM address are transformed into the **bank_rom** 5 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 * 
 * @param address The 19 bit ROM address.
 * @param value The byte value to be written.
 */
// void rom_write_byte(__zp($60) unsigned long address, __zp($57) char value)
rom_write_byte: {
    .label bank_rom = $3c
    .label ptr_rom = $5e
    .label address = $60
    .label value = $57
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [551] rom_bank::address#1 = rom_write_byte::address#4 -- vduz1=vduz2 
    lda.z address
    sta.z rom_bank.address
    lda.z address+1
    sta.z rom_bank.address+1
    lda.z address+2
    sta.z rom_bank.address+2
    lda.z address+3
    sta.z rom_bank.address+3
    // [552] call rom_bank
    // [562] phi from rom_write_byte to rom_bank [phi:rom_write_byte->rom_bank]
    // [562] phi rom_bank::address#2 = rom_bank::address#1 [phi:rom_write_byte->rom_bank#0] -- register_copy 
    jsr rom_bank
    // brom_bank_t bank_rom = rom_bank((unsigned long)address)
    // [553] rom_bank::return#3 = rom_bank::return#0 -- vbuz1=vbuz2 
    lda.z rom_bank.return
    sta.z rom_bank.return_1
    // rom_write_byte::@1
    // [554] rom_write_byte::bank_rom#0 = rom_bank::return#3
    // brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address)
    // [555] rom_ptr::address#1 = rom_write_byte::address#4 -- vduz1=vduz2 
    lda.z address
    sta.z rom_ptr.address
    lda.z address+1
    sta.z rom_ptr.address+1
    lda.z address+2
    sta.z rom_ptr.address+2
    lda.z address+3
    sta.z rom_ptr.address+3
    // [556] call rom_ptr
    // [567] phi from rom_write_byte::@1 to rom_ptr [phi:rom_write_byte::@1->rom_ptr]
    // [567] phi rom_ptr::address#4 = rom_ptr::address#1 [phi:rom_write_byte::@1->rom_ptr#0] -- register_copy 
    jsr rom_ptr
    // rom_write_byte::@2
    // brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address)
    // [557] rom_write_byte::ptr_rom#0 = (char *)rom_ptr::return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr.return
    sta.z ptr_rom
    lda.z rom_ptr.return+1
    sta.z ptr_rom+1
    // bank_set_brom(bank_rom)
    // [558] bank_set_brom::bank#1 = rom_write_byte::bank_rom#0 -- vbuz1=vbuz2 
    lda.z bank_rom
    sta.z bank_set_brom.bank
    // [559] call bank_set_brom
    // [382] phi from rom_write_byte::@2 to bank_set_brom [phi:rom_write_byte::@2->bank_set_brom]
    // [382] phi bank_set_brom::bank#5 = bank_set_brom::bank#1 [phi:rom_write_byte::@2->bank_set_brom#0] -- register_copy 
    jsr bank_set_brom
    // rom_write_byte::@3
    // *ptr_rom = value
    // [560] *rom_write_byte::ptr_rom#0 = rom_write_byte::value#4 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (ptr_rom),y
    // rom_write_byte::@return
    // }
    // [561] return 
    rts
}
  // rom_bank
// Some addressing constants.
// The different device IDs that can be returned from the manufacturer ID read sequence.
/**
 * @brief Calculates the 5 bit ROM bank from the ROM 19 bit address.
 * The ROM bank number is calcuated by taking the upper 5 bits (bit 18-14) and shifing those 14 bits to the right.
 * 
 * @param address The 19 bit ROM address.
 * @return unsigned char The ROM bank number for usage in ZP $01.
 */
// __zp($3c) char rom_bank(__zp($4f) unsigned long address)
rom_bank: {
    .label __1 = $4f
    .label __2 = $4f
    .label return = $5c
    .label address = $4f
    .label return_1 = $3c
    // (unsigned long)(address & ROM_BANK_MASK) >> 14
    // [563] rom_bank::$2 = rom_bank::address#2 & $7c000 -- vduz1=vduz1_band_vduc1 
    lda.z __2
    and #<$7c000
    sta.z __2
    lda.z __2+1
    and #>$7c000
    sta.z __2+1
    lda.z __2+2
    and #<$7c000>>$10
    sta.z __2+2
    lda.z __2+3
    and #>$7c000>>$10
    sta.z __2+3
    // [564] rom_bank::$1 = rom_bank::$2 >> $e -- vduz1=vduz1_ror_vbuc1 
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
    // [565] rom_bank::return#0 = (char)rom_bank::$1 -- vbuz1=_byte_vduz2 
    lda.z __1
    sta.z return
    // rom_bank::@return
    // }
    // [566] return 
    rts
}
  // rom_ptr
/**
 * @brief Calcuates the 16 bit ROM pointer from the ROM using the 19 bit address.
 * The 16 bit ROM pointer is calculated by masking the lower 14 bits (bit 13-0), and then adding $C000 to it.
 * The 16 bit ROM pointer is returned as a char* (brom_ptr_t).
 * @param address The 19 bit ROM address.
 * @return brom_ptr_t The 16 bit ROM pointer for the main CPU addressing.
 */
// __zp($4d) char * rom_ptr(__zp($58) unsigned long address)
rom_ptr: {
    .label __0 = $58
    .label __2 = $4d
    .label return = $4d
    .label address = $58
    // address & ROM_PTR_MASK
    // [568] rom_ptr::$0 = rom_ptr::address#4 & $3fff -- vduz1=vduz1_band_vduc1 
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
    // [569] rom_ptr::$2 = (unsigned int)rom_ptr::$0 -- vwuz1=_word_vduz2 
    lda.z __0
    sta.z __2
    lda.z __0+1
    sta.z __2+1
    // [570] rom_ptr::return#0 = rom_ptr::$2 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z return
    clc
    adc #<$c000
    sta.z return
    lda.z return+1
    adc #>$c000
    sta.z return+1
    // rom_ptr::@return
    // }
    // [571] return 
    rts
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($4c) char value, __zp($53) char *buffer, __zp($6d) char radix)
uctoa: {
    .label __4 = $48
    .label digit_value = $43
    .label buffer = $53
    .label digit = $42
    .label value = $4c
    .label radix = $6d
    .label started = $5c
    .label max_digits = $57
    .label digit_values = $4d
    // if(radix==DECIMAL)
    // [572] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [573] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [574] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [575] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [576] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [577] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [578] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [579] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [580] return 
    rts
    // [581] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [581] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [581] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [581] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [581] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [581] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [581] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [581] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [581] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [581] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [581] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [581] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [582] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [582] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [582] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [582] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [582] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [583] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z __4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [584] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z __4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [585] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [586] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [587] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [588] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [589] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [590] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [591] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [591] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [591] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [591] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [592] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [582] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [582] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [582] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [582] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [582] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [593] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [594] uctoa_append::value#0 = uctoa::value#2
    // [595] uctoa_append::sub#0 = uctoa::digit_value#0
    // [596] call uctoa_append
    // [728] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [597] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [598] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [599] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [591] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [591] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [591] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [591] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(void (*putc)(char), __zp($57) char buffer_sign, char *buffer_digits, __zp($42) char format_min_length, char format_justify_left, char format_sign_always, __zp($5c) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label __19 = $4d
    .label buffer_sign = $57
    .label len = $5d
    .label padding = $42
    .label format_min_length = $42
    .label format_zero_padding = $5c
    // if(format.min_length)
    // [601] if(0==printf_number_buffer::format_min_length#2) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [602] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [603] call strlen
    // [735] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [735] phi strlen::str#6 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [604] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [605] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [606] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z __19
    sta.z len
    // if(buffer.sign)
    // [607] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [608] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [609] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [609] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [610] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#2 - printf_number_buffer::len#2 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [611] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [613] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [613] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [612] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [613] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [613] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [614] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [615] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [616] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [617] call printf_padding
    // [741] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [741] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@7->printf_padding#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [741] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#1] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [618] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [619] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [620] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [622] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [623] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    // [626] phi from printf_number_buffer::@14 printf_number_buffer::@3 printf_number_buffer::@9 to printf_number_buffer::@4 [phi:printf_number_buffer::@14/printf_number_buffer::@3/printf_number_buffer::@9->printf_number_buffer::@4]
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [624] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [625] call printf_padding
    // [741] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [741] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@9->printf_padding#0] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [741] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#1] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [627] call printf_str
    // [353] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [353] phi printf_str::putc#33 = &cputc [phi:printf_number_buffer::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [353] phi printf_str::s#33 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [628] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($53) char *dst, __zp($55) const char *src, unsigned int n)
strncpy: {
    .const n = $10
    .label c = $48
    .label dst = $53
    .label i = $46
    .label src = $55
    // [630] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [630] phi strncpy::dst#2 = strncpy::dst#1 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [630] phi strncpy::src#2 = main::filename [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.filename
    sta.z src
    lda #>main.filename
    sta.z src+1
    // [630] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [631] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuc1_then_la1 
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
    // [632] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [633] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [634] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [635] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [636] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [636] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [637] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [638] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [639] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [630] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [630] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [630] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [630] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_setnam
/**
 * @brief Sets the name of the file before opening.
 * 
 * @param filename The name of the file.
 */
// void cbm_k_setnam(__zp($c6) char * volatile filename)
cbm_k_setnam: {
    .label filename = $c6
    .label __0 = $4d
    // strlen(filename)
    // [640] strlen::str#0 = cbm_k_setnam::filename -- pbuz1=pbuz2 
    lda.z filename
    sta.z strlen.str
    lda.z filename+1
    sta.z strlen.str+1
    // [641] call strlen
    // [735] phi from cbm_k_setnam to strlen [phi:cbm_k_setnam->strlen]
    // [735] phi strlen::str#6 = strlen::str#0 [phi:cbm_k_setnam->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [642] strlen::return#0 = strlen::len#2
    // cbm_k_setnam::@1
    // [643] cbm_k_setnam::$0 = strlen::return#0
    // __mem char filename_len = (char)strlen(filename)
    // [644] cbm_k_setnam::filename_len = (char)cbm_k_setnam::$0 -- vbum1=_byte_vwuz2 
    lda.z __0
    sta filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx filename
    ldy filename+1
    jsr CBM_SETNAM
    // cbm_k_setnam::@return
    // }
    // [646] return 
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
// void cbm_k_setlfs(__zp($cf) volatile char channel, __zp($ce) volatile char device, __zp($ca) volatile char command)
cbm_k_setlfs: {
    .label channel = $cf
    .label device = $ce
    .label command = $ca
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [648] return 
    rts
}
  // cbm_k_open
/**
 * @brief Open a logical file.
 * 
 * @return char The status.
 */
cbm_k_open: {
    .label return = $5d
    // __mem unsigned char status
    // [649] cbm_k_open::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_OPEN stastatus  }
    jsr CBM_OPEN
    sta status
    // return status;
    // [651] cbm_k_open::return#0 = cbm_k_open::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_open::@return
    // }
    // [652] cbm_k_open::return#1 = cbm_k_open::return#0
    // [653] return 
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
// char cbm_k_chkin(__zp($b1) volatile char channel)
cbm_k_chkin: {
    .label channel = $b1
    // __mem unsigned char status
    // [654] cbm_k_chkin::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx channel
    jsr CBM_CHKIN
    sta status
    // cbm_k_chkin::@return
    // }
    // [656] return 
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
    .label return = $3c
    // __mem unsigned char status
    // [657] cbm_k_readst::status = 0 -- vbum1=vbuc1 
    lda #0
    sta status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta status
    // return status;
    // [659] cbm_k_readst::return#0 = cbm_k_readst::status -- vbuz1=vbum2 
    sta.z return
    // cbm_k_readst::@return
    // }
    // [660] cbm_k_readst::return#1 = cbm_k_readst::return#0
    // [661] return 
    rts
  .segment Data
    status: .byte 0
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
// __zp($55) unsigned int cbm_k_macptr(__zp($66) volatile char bytes, __zp($64) void * volatile buffer)
cbm_k_macptr: {
    .label bytes = $66
    .label buffer = $64
    .label return = $55
    // __mem unsigned int bytes_read
    // [662] cbm_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [664] cbm_k_macptr::return#0 = cbm_k_macptr::bytes_read -- vwuz1=vwum2 
    lda bytes_read
    sta.z return
    lda bytes_read+1
    sta.z return+1
    // cbm_k_macptr::@return
    // }
    // [665] cbm_k_macptr::return#1 = cbm_k_macptr::return#0
    // [666] return 
    rts
  .segment Data
    bytes_read: .word 0
}
.segment Code
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($38) unsigned long value, __zp($53) char *buffer, char radix)
ultoa: {
    .label __10 = $43
    .label __11 = $48
    .label digit_value = $3d
    .label buffer = $53
    .label digit = $57
    .label value = $38
    .label started = $5d
    // [668] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [668] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [668] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [668] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [668] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [669] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [670] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z __11
    // [671] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [672] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [673] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [674] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [675] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z __10
    // [676] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [677] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [678] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [679] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [679] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [679] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [679] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [680] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [668] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [668] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [668] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [668] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [668] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [681] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [682] ultoa_append::value#0 = ultoa::value#2
    // [683] ultoa_append::sub#0 = ultoa::digit_value#0
    // [684] call ultoa_append
    // [749] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [685] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [686] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [687] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [679] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [679] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [679] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [679] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
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
// void rom_wait(__zp($46) char *ptr_rom)
rom_wait: {
    .label __0 = $43
    .label __1 = $42
    .label test1 = $43
    .label test2 = $42
    .label ptr_rom = $46
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [689] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [690] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [691] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z __0
    sta.z __0
    // test2 & 0x40
    // [692] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z __1
    sta.z __1
    // while((test1 & 0x40) != (test2 & 0x40))
    // [693] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z __0
    cmp.z __1
    bne __b1
    // rom_wait::@return
    // }
    // [694] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label __0 = $31
    .label __4 = $2f
    .label __6 = $30
    .label __7 = $2f
    .label width = $31
    .label y = $2c
    // __conio.width+1
    // [695] insertup::$0 = *((char *)&__conio+4) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+4
    inc
    sta.z __0
    // unsigned char width = (__conio.width+1) * 2
    // [696] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z width
    // [697] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [697] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [698] if(insertup::y#2<=*((char *)&__conio+$e)) goto insertup::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+$e
    cmp.z y
    bcs __b2
    // [699] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [700] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [701] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [702] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z __4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [703] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z __6
    // [704] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z __7
    // [705] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.dbank_vram
    // [706] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [707] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+3) -- vbuz1=_deref_pbuc1 
    lda __conio+3
    sta.z memcpy8_vram_vram.sbank_vram
    // [708] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z __7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [709] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [710] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<=__conio.cursor_y; y++)
    // [711] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [697] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [697] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label __0 = $24
    .label __1 = $26
    .label __2 = $27
    .label __3 = $25
    .label addr = $2d
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [712] clearline::$3 = *((char *)&__conio+$e) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+$e
    asl
    sta.z __3
    // [713] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [714] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [715] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z __0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [716] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [717] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z __1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [718] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [719] clearline::$2 = *((char *)&__conio+3) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+3
    sta.z __2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [720] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [721] clearline::c#0 = *((char *)&__conio+4) -- vbuz1=_deref_pbuc1 
    lda __conio+4
    sta.z c
    // [722] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [722] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [723] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [724] *VERA_DATA0 = *((char *)&__conio+$b) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$b
    sta VERA_DATA0
    // c--;
    // [725] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [726] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [727] return 
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
// __zp($4c) char uctoa_append(__zp($4a) char *buffer, __zp($4c) char value, __zp($43) char sub)
uctoa_append: {
    .label buffer = $4a
    .label value = $4c
    .label sub = $43
    .label return = $4c
    .label digit = $48
    // [729] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [729] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [729] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [730] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [731] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [732] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [733] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [734] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [729] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [729] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [729] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($4d) unsigned int strlen(__zp($46) char *str)
strlen: {
    .label str = $46
    .label return = $4d
    .label len = $4d
    // [736] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [736] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [736] phi strlen::str#4 = strlen::str#6 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [737] if(0!=*strlen::str#4) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [738] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [739] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [740] strlen::str#1 = ++ strlen::str#4 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [736] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [736] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [736] phi strlen::str#4 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(void (*putc)(char), __zp($3c) char pad, __zp($48) char length)
printf_padding: {
    .label i = $49
    .label length = $48
    .label pad = $3c
    // [742] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [742] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [743] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [744] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [745] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [746] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [748] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [742] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [742] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
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
// __zp($38) unsigned long ultoa_append(__zp($5e) char *buffer, __zp($38) unsigned long value, __zp($3d) unsigned long sub)
ultoa_append: {
    .label buffer = $5e
    .label value = $38
    .label sub = $3d
    .label return = $38
    .label digit = $3c
    // [750] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [750] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [750] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [751] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [752] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [753] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [754] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [755] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [750] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [750] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [750] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
// void memcpy8_vram_vram(__zp($25) char dbank_vram, __zp($2d) unsigned int doffset_vram, __zp($24) char sbank_vram, __zp($2a) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label __0 = $26
    .label __1 = $27
    .label __2 = $24
    .label __3 = $28
    .label __4 = $29
    .label __5 = $25
    .label num8 = $23
    .label dbank_vram = $25
    .label doffset_vram = $2d
    .label sbank_vram = $24
    .label soffset_vram = $2a
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [756] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [757] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z __0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [758] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [759] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z __1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [760] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [761] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z __2
    sta.z __2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [762] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [763] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [764] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z __3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [765] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [766] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z __4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [767] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [768] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z __5
    sta.z __5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [769] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [770] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [770] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [771] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [772] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [773] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [774] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [775] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
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
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_LONG: .dword $10000000, $1000000, $100000, $10000, $1000, $100, $10
  __files: .fill $14*4, 0
  __filecount: .byte 0
  __conio: .fill SIZEOF_STRUCT___1, 0
  // Buffer used for stringified number being printed
  printf_buffer: .fill SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER, 0
