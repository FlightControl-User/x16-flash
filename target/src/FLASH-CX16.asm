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
  /**
 * @file kernal.h
 * @author your name (you@domain.com)
 * @brief Most common CBM Kernal calls with it's dialects in the different CBM kernal family platforms.
 * Please refer to http://sta.c64.org/cbm64krnfunc.html for the list of standard CBM C64 kernal functions.
 *
 * @version 1.0
 * @date 2023-03-22
 *
 * @copyright Copyright (c) 2023
 *
 */
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
  .const CBM_GETIN = $ffe4
  ///< Scan a character from the keyboard.
  .const CBM_CLOSE = $ffc3
  ///< Close a logical file.
  .const CBM_CLRCHN = $ffcc
  ///< Load a logical file.
  .const CBM_PLOT = $fff0
  ///< CX16 Set/Get screen mode.
  .const CX16_SCREEN_SET_CHARSET = $ff62
  ///< CX16 Set character set.
  .const CX16_MACPTR = $ff44
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
  .const SIZEOF_STRUCT___1 = $8f
  .const SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER = $c
  .const SIZEOF_STRUCT___2 = $48
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
  .label __errno = $ba
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
    // volatile unsigned char __stdio_filecount = 0
    // [3] __stdio_filecount = 0 -- vbum1=vbuc1 
    lda #0
    sta __stdio_filecount
    // [4] phi from __start::__init1 to __start::@2 [phi:__start::__init1->__start::@2]
    // __start::@2
    // #pragma constructor_for(conio_x16_init, cputc, clrscr, cscroll)
    // [5] call conio_x16_init
    // [9] phi from __start::@2 to conio_x16_init [phi:__start::@2->conio_x16_init]
    jsr conio_x16_init
    // [6] phi from __start::@2 to __start::@1 [phi:__start::@2->__start::@1]
    // __start::@1
    // [7] call main
    // [61] phi from __start::@1 to main [phi:__start::@1->main]
    jsr main
    // __start::@return
    // [8] return 
    rts
}
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    .label conio_x16_init__4 = $dd
    .label conio_x16_init__5 = $a9
    .label conio_x16_init__6 = $dd
    // screenlayer1()
    // [10] call screenlayer1
    jsr screenlayer1
    // [11] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [12] call textcolor
    // [467] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [13] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [14] call bgcolor
    // [472] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [15] phi from conio_x16_init::@2 to conio_x16_init::@3 [phi:conio_x16_init::@2->conio_x16_init::@3]
    // conio_x16_init::@3
    // cursor(0)
    // [16] call cursor
    jsr cursor
    // [17] phi from conio_x16_init::@3 to conio_x16_init::@4 [phi:conio_x16_init::@3->conio_x16_init::@4]
    // conio_x16_init::@4
    // cbm_k_plot_get()
    // [18] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [19] cbm_k_plot_get::return#2 = cbm_k_plot_get::return#0
    // conio_x16_init::@5
    // [20] conio_x16_init::$4 = cbm_k_plot_get::return#2
    // BYTE1(cbm_k_plot_get())
    // [21] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwuz2 
    lda.z conio_x16_init__4+1
    sta.z conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [22] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
    sta __conio
    // cbm_k_plot_get()
    // [23] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [24] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [25] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [26] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbum1=_byte0_vwuz2 
    lda.z conio_x16_init__6
    sta conio_x16_init__7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [27] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbum1 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [28] gotoxy::x#1 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z gotoxy.x
    // [29] gotoxy::y#1 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z gotoxy.y
    // [30] call gotoxy
    // [485] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#1 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = gotoxy::x#1 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
    jsr gotoxy
    // conio_x16_init::@7
    // __conio.scroll[0] = 1
    // [31] *((char *)&__conio+$f) = 1 -- _deref_pbuc1=vbuc2 
    lda #1
    sta __conio+$f
    // __conio.scroll[1] = 1
    // [32] *((char *)&__conio+$f+1) = 1 -- _deref_pbuc1=vbuc2 
    sta __conio+$f+1
    // conio_x16_init::@return
    // }
    // [33] return 
    rts
  .segment Data
    conio_x16_init__7: .byte 0
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__zp($5d) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $36
    .label cputc__2 = $ae
    .label cputc__3 = $af
    .label c = $5d
    // [34] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
    // if(c=='\n')
    // [35] if(cputc::c#0==' 'pm) goto cputc::@1 -- vbuz1_eq_vbuc1_then_la1 
  .encoding "petscii_mixed"
    lda #'\n'
    cmp.z c
    beq __b1
    // cputc::@2
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [36] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [37] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cputc__1
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [38] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [39] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cputc__2
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [40] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [41] cputc::$3 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z cputc__3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [42] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [43] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuz1 
    lda.z c
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [44] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // if(!__conio.hscroll[__conio.layer])
    // [45] if(0==((char *)&__conio+$11)[*((char *)&__conio+2)]) goto cputc::@5 -- 0_eq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$11,y
    cmp #0
    beq __b5
    // cputc::@3
    // if(__conio.cursor_x >= __conio.mapwidth)
    // [46] if(*((char *)&__conio)>=*((char *)&__conio+8)) goto cputc::@6 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+8
    bcs __b6
    // cputc::@4
    // __conio.cursor_x++;
    // [47] *((char *)&__conio) = ++ *((char *)&__conio) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio
    // cputc::@7
  __b7:
    // __conio.offset++;
    // [48] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // [49] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // cputc::@return
    // }
    // [50] return 
    rts
    // [51] phi from cputc::@3 to cputc::@6 [phi:cputc::@3->cputc::@6]
    // cputc::@6
  __b6:
    // cputln()
    // [52] call cputln
    jsr cputln
    jmp __b7
    // cputc::@5
  __b5:
    // if(__conio.cursor_x >= __conio.width)
    // [53] if(*((char *)&__conio)>=*((char *)&__conio+6)) goto cputc::@8 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+6
    bcs __b8
    // cputc::@9
    // __conio.cursor_x++;
    // [54] *((char *)&__conio) = ++ *((char *)&__conio) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio
    // __conio.offset++;
    // [55] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // [56] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    rts
    // [57] phi from cputc::@5 to cputc::@8 [phi:cputc::@5->cputc::@8]
    // cputc::@8
  __b8:
    // cputln()
    // [58] call cputln
    jsr cputln
    rts
    // [59] phi from cputc to cputc::@1 [phi:cputc->cputc::@1]
    // cputc::@1
  __b1:
    // cputln()
    // [60] call cputln
    jsr cputln
    rts
}
  // main
main: {
    .const bank_set_brom1_bank = 4
    .const bank_set_brom2_bank = 0
    .const bank_set_bram1_bank = 1
    .const bank_set_brom3_bank = 0
    .const bank_set_bram2_bank = 1
    .const bank_set_bram3_bank = 1
    .const bank_set_brom4_bank = 4
    .const bank_set_brom5_bank = 4
    .const bank_set_bram4_bank = 1
    .const bank_set_brom6_bank = 4
    .const bank_set_brom7_bank = 4
    .label main__21 = $27
    .label main__23 = $27
    .label main__53 = $55
    .label main__63 = $2a
    .label main__70 = $7f
    .label main__104 = $c6
    .label main__143 = $66
    .label main__167 = $53
    .label main__168 = $ca
    .label main__169 = $6a
    .label len = $40
    .label flash_rom_address_boundary = $56
    .label size = $ce
    .label flash_rom_address1 = $eb
    .label equal_bytes = $39
    .label flash_rom_address_sector = $e5
    .label read_ram_address = $d8
    .label x_sector = $f4
    .label read_ram_bank = $cd
    .label y_sector = $f7
    .label equal_bytes1 = $39
    .label read_ram_address_sector = $d2
    .label flash_rom_address_boundary1 = $d4
    .label retries = $cb
    .label flash_errors = $b9
    .label read_ram_address1 = $c3
    .label flash_rom_address2 = $bf
    .label x1 = $bc
    .label flash_errors_sector = $da
    .label x_sector1 = $e4
    .label read_ram_bank_sector = $cc
    .label y_sector1 = $df
    .label v = $f2
    .label pattern1 = $3e
    .label main__185 = $3c
    .label main__186 = $40
    .label main__191 = $7f
    .label main__193 = $2a
    .label main__194 = $2a
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@52
    // cx16_k_screen_set_charset(3, (char *)0)
    // [63] main::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [64] main::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
    lda #<0
    sta cx16_k_screen_set_charset1_offset
    sta cx16_k_screen_set_charset1_offset+1
    // main::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // [66] phi from main::cx16_k_screen_set_charset1 to main::@53 [phi:main::cx16_k_screen_set_charset1->main::@53]
    // main::@53
    // textcolor(WHITE)
    // [67] call textcolor
    // [467] phi from main::@53 to textcolor [phi:main::@53->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:main::@53->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [68] phi from main::@53 to main::@64 [phi:main::@53->main::@64]
    // main::@64
    // bgcolor(BLUE)
    // [69] call bgcolor
    // [472] phi from main::@64 to bgcolor [phi:main::@64->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:main::@64->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [70] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
    // scroll(0)
    // [71] call scroll
    jsr scroll
    // [72] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // clrscr()
    // [73] call clrscr
    jsr clrscr
    // [74] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // frame_draw()
    // [75] call frame_draw
    // [531] phi from main::@67 to frame_draw [phi:main::@67->frame_draw]
    jsr frame_draw
    // [76] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // gotoxy(2, 1)
    // [77] call gotoxy
    // [485] phi from main::@68 to gotoxy [phi:main::@68->gotoxy]
    // [485] phi gotoxy::y#25 = 1 [phi:main::@68->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = 2 [phi:main::@68->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [78] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // printf("commander x16 rom flash utility")
    // [79] call printf_str
    // [711] phi from main::@69 to printf_str [phi:main::@69->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@69->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s [phi:main::@69->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [80] phi from main::@69 to main::@70 [phi:main::@69->main::@70]
    // main::@70
    // print_chips()
    // [81] call print_chips
    // [720] phi from main::@70 to print_chips [phi:main::@70->print_chips]
    jsr print_chips
    // [82] phi from main::@70 to main::@1 [phi:main::@70->main::@1]
    // [82] phi main::rom_chip#10 = 0 [phi:main::@70->main::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [82] phi main::flash_rom_address#10 = 0 [phi:main::@70->main::@1#1] -- vdum1=vduc1 
    sta flash_rom_address
    sta flash_rom_address+1
    lda #<0>>$10
    sta flash_rom_address+2
    lda #>0>>$10
    sta flash_rom_address+3
    // main::@1
  __b1:
    // for (unsigned long flash_rom_address = 0; flash_rom_address < 8 * 0x80000; flash_rom_address += 0x80000)
    // [83] if(main::flash_rom_address#10<8*$80000) goto main::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [85] phi from main::CLI1 to main::@55 [phi:main::CLI1->main::@55]
    // main::@55
    // info_line_clear()
    // [86] call info_line_clear
    // [751] phi from main::@55 to info_line_clear [phi:main::@55->info_line_clear]
    jsr info_line_clear
    // [87] phi from main::@55 to main::@74 [phi:main::@55->main::@74]
    // main::@74
    // printf("%s", "press a key to start flashing.")
    // [88] call printf_string
    // [760] phi from main::@74 to printf_string [phi:main::@74->printf_string]
    // [760] phi printf_string::str#10 = main::str [phi:main::@74->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [760] phi printf_string::format_min_length#10 = 0 [phi:main::@74->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // [89] phi from main::@74 to main::@75 [phi:main::@74->main::@75]
    // main::@75
    // wait_key()
    // [90] call wait_key
  // Ensure the ROM is set to BASIC.
    // [777] phi from main::@75 to wait_key [phi:main::@75->wait_key]
    jsr wait_key
    // [91] phi from main::@75 to main::@76 [phi:main::@75->main::@76]
    // main::@76
    // info_line_clear()
    // [92] call info_line_clear
    // [751] phi from main::@76 to info_line_clear [phi:main::@76->info_line_clear]
    jsr info_line_clear
    // [93] phi from main::@76 to main::@11 [phi:main::@76->main::@11]
    // [93] phi __errno#109 = 0 [phi:main::@76->main::@11#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    // [93] phi main::flash_chip#10 = 7 [phi:main::@76->main::@11#1] -- vbum1=vbuc1 
    lda #7
    sta flash_chip
    // main::@11
  __b11:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [94] if(main::flash_chip#10!=$ff) goto main::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp flash_chip
    bne __b12
    // main::bank_set_brom2
    // BROM = bank
    // [95] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // [96] phi from main::bank_set_brom2 to main::@56 [phi:main::bank_set_brom2->main::@56]
    // main::@56
    // textcolor(WHITE)
    // [97] call textcolor
    // [467] phi from main::@56 to textcolor [phi:main::@56->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:main::@56->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [98] phi from main::@56 to main::@47 [phi:main::@56->main::@47]
    // [98] phi main::w#2 = $80 [phi:main::@56->main::@47#0] -- vwsm1=vwsc1 
    lda #<$80
    sta w
    lda #>$80
    sta w+1
    // main::@47
  __b47:
    // for (int w = 128; w >= 0; w--)
    // [99] if(main::w#2>=0) goto main::@49 -- vwsm1_ge_0_then_la1 
    lda w+1
    bpl __b6
    // [100] phi from main::@47 to main::@48 [phi:main::@47->main::@48]
    // main::@48
    // system_reset()
    // [101] call system_reset
    // [788] phi from main::@48 to system_reset [phi:main::@48->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [102] return 
    rts
    // [103] phi from main::@47 to main::@49 [phi:main::@47->main::@49]
  __b6:
    // [103] phi main::v#2 = 0 [phi:main::@47->main::@49#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z v
    sta.z v+1
    // main::@49
  __b49:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [104] if(main::v#2<$100*$80) goto main::@50 -- vwuz1_lt_vwuc1_then_la1 
    lda.z v+1
    cmp #>$100*$80
    bcc __b50
    bne !+
    lda.z v
    cmp #<$100*$80
    bcc __b50
  !:
    // [105] phi from main::@49 to main::@51 [phi:main::@49->main::@51]
    // main::@51
    // info_line_clear()
    // [106] call info_line_clear
    // [751] phi from main::@51 to info_line_clear [phi:main::@51->info_line_clear]
    jsr info_line_clear
    // [107] phi from main::@51 to main::@162 [phi:main::@51->main::@162]
    // main::@162
    // printf("resetting commander x16 (%i)", w)
    // [108] call printf_str
    // [711] phi from main::@162 to printf_str [phi:main::@162->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@162->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s21 [phi:main::@162->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@163
    // printf("resetting commander x16 (%i)", w)
    // [109] printf_sint::value#1 = main::w#2 -- vwsz1=vwsm2 
    lda w
    sta.z printf_sint.value
    lda w+1
    sta.z printf_sint.value+1
    // [110] call printf_sint
    jsr printf_sint
    // [111] phi from main::@163 to main::@164 [phi:main::@163->main::@164]
    // main::@164
    // printf("resetting commander x16 (%i)", w)
    // [112] call printf_str
    // [711] phi from main::@164 to printf_str [phi:main::@164->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@164->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s22 [phi:main::@164->printf_str#1] -- pbuz1=pbuc1 
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
    // [98] phi from main::@165 to main::@47 [phi:main::@165->main::@47]
    // [98] phi main::w#2 = main::w#1 [phi:main::@165->main::@47#0] -- register_copy 
    jmp __b47
    // main::@50
  __b50:
    // for (unsigned int v = 0; v < 256 * 128; v++)
    // [114] main::v#1 = ++ main::v#2 -- vwuz1=_inc_vwuz1 
    inc.z v
    bne !+
    inc.z v+1
  !:
    // [103] phi from main::@50 to main::@49 [phi:main::@50->main::@49]
    // [103] phi main::v#2 = main::v#1 [phi:main::@50->main::@49#0] -- register_copy 
    jmp __b49
    // main::@12
  __b12:
    // if (rom_device_ids[flash_chip] != UNKNOWN)
    // [115] if(main::rom_device_ids[main::flash_chip#10]==$55) goto main::@13 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy flash_chip
    lda rom_device_ids,y
    cmp #$55
    bne !__b13+
    jmp __b13
  !__b13:
    // [116] phi from main::@12 to main::@45 [phi:main::@12->main::@45]
    // main::@45
    // gotoxy(0, 2)
    // [117] call gotoxy
    // [485] phi from main::@45 to gotoxy [phi:main::@45->gotoxy]
    // [485] phi gotoxy::y#25 = 2 [phi:main::@45->gotoxy#0] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = 0 [phi:main::@45->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [118] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::bank_set_brom3
    // BROM = bank
    // [119] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // [120] phi from main::bank_set_brom3 to main::@57 [phi:main::bank_set_brom3->main::@57]
    // main::@57
    // strcpy(file, "rom")
    // [121] call strcpy
    // [803] phi from main::@57 to strcpy [phi:main::@57->strcpy]
    jsr strcpy
    // main::@89
    // if (flash_chip != 0)
    // [122] if(main::flash_chip#10==0) goto main::@14 -- vbum1_eq_0_then_la1 
    lda flash_chip
    beq __b14
    // [123] phi from main::@89 to main::@46 [phi:main::@89->main::@46]
    // main::@46
    // size_t len = strlen(file)
    // [124] call strlen
    // [811] phi from main::@46 to strlen [phi:main::@46->strlen]
    // [811] phi strlen::str#9 = file [phi:main::@46->strlen#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strlen.str
    lda #>file
    sta.z strlen.str+1
    jsr strlen
    // size_t len = strlen(file)
    // [125] strlen::return#14 = strlen::len#2
    // main::@96
    // [126] main::len#0 = strlen::return#14
    // 0x30 + flash_chip
    // [127] main::$53 = $30 + main::flash_chip#10 -- vbuz1=vbuc1_plus_vbum2 
    lda #$30
    clc
    adc flash_chip
    sta.z main__53
    // file[len] = 0x30 + flash_chip
    // [128] main::$185 = file + main::len#0 -- pbuz1=pbuc1_plus_vwuz2 
    lda.z len
    clc
    adc #<file
    sta.z main__185
    lda.z len+1
    adc #>file
    sta.z main__185+1
    // [129] *main::$185 = main::$53 -- _deref_pbuz1=vbuz2 
    lda.z main__53
    ldy #0
    sta (main__185),y
    // file[len+1] = '\0'
    // [130] main::$186 = file+1 + main::len#0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z main__186
    clc
    adc #<file+1
    sta.z main__186
    lda.z main__186+1
    adc #>file+1
    sta.z main__186+1
    // [131] *main::$186 = '?'pm -- _deref_pbuz1=vbuc1 
    lda #'\$00'
    sta (main__186),y
    // [132] phi from main::@89 main::@96 to main::@14 [phi:main::@89/main::@96->main::@14]
    // main::@14
  __b14:
    // strcat(file, ".bin")
    // [133] call strcat
    // [817] phi from main::@14 to strcat [phi:main::@14->strcat]
    jsr strcat
    // [134] phi from main::@14 to main::@90 [phi:main::@14->main::@90]
    // main::@90
    // info_line_clear()
    // [135] call info_line_clear
    // [751] phi from main::@90 to info_line_clear [phi:main::@90->info_line_clear]
    jsr info_line_clear
    // [136] phi from main::@90 to main::@91 [phi:main::@90->main::@91]
    // main::@91
    // printf("opening %s.", file)
    // [137] call printf_str
    // [711] phi from main::@91 to printf_str [phi:main::@91->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@91->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s1 [phi:main::@91->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [138] phi from main::@91 to main::@92 [phi:main::@91->main::@92]
    // main::@92
    // printf("opening %s.", file)
    // [139] call printf_string
    // [760] phi from main::@92 to printf_string [phi:main::@92->printf_string]
    // [760] phi printf_string::str#10 = file [phi:main::@92->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [760] phi printf_string::format_min_length#10 = 0 [phi:main::@92->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // [140] phi from main::@92 to main::@93 [phi:main::@92->main::@93]
    // main::@93
    // printf("opening %s.", file)
    // [141] call printf_str
    // [711] phi from main::@93 to printf_str [phi:main::@93->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@93->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s2 [phi:main::@93->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@94
    // unsigned char flash_rom_bank = flash_chip * 32
    // [142] main::flash_rom_bank#0 = main::flash_chip#10 << 5 -- vbum1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta flash_rom_bank
    // FILE *fp = fopen(file,"r")
    // [143] call fopen
    // Read the file content.
    jsr fopen
    // [144] fopen::return#3 = fopen::return#2
    // main::@95
    // [145] main::fp#0 = fopen::return#3 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [146] if((struct $2 *)0!=main::fp#0) goto main::@15 -- pssc1_neq_pssm1_then_la1 
    cmp #>0
    beq !__b15+
    jmp __b15
  !__b15:
    lda fp
    cmp #<0
    beq !__b15+
    jmp __b15
  !__b15:
    // main::@44
    // print_chip_led(flash_chip, DARK_GREY, BLUE)
    // [147] print_chip_led::r#6 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [148] call print_chip_led
    // [908] phi from main::@44 to print_chip_led [phi:main::@44->print_chip_led]
    // [908] phi print_chip_led::tc#10 = DARK_GREY [phi:main::@44->print_chip_led#0] -- vbuz1=vbuc1 
    lda #DARK_GREY
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#6 [phi:main::@44->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [149] phi from main::@44 to main::@109 [phi:main::@44->main::@109]
    // main::@109
    // info_line_clear()
    // [150] call info_line_clear
    // [751] phi from main::@109 to info_line_clear [phi:main::@109->info_line_clear]
    jsr info_line_clear
    // [151] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [152] call printf_str
    // [711] phi from main::@110 to printf_str [phi:main::@110->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@110->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s5 [phi:main::@110->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [153] phi from main::@110 to main::@111 [phi:main::@110->main::@111]
    // main::@111
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [154] call printf_string
    // [760] phi from main::@111 to printf_string [phi:main::@111->printf_string]
    // [760] phi printf_string::str#10 = file [phi:main::@111->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [760] phi printf_string::format_min_length#10 = 0 [phi:main::@111->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // [155] phi from main::@111 to main::@112 [phi:main::@111->main::@112]
    // main::@112
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [156] call printf_str
    // [711] phi from main::@112 to printf_str [phi:main::@112->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@112->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s6 [phi:main::@112->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@113
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [157] printf_uchar::uvalue#5 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [158] call printf_uchar
    // [928] phi from main::@113 to printf_uchar [phi:main::@113->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@113->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 0 [phi:main::@113->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@113->printf_uchar#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#5 [phi:main::@113->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [159] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // printf("there is no %s file on the sdcard to flash rom%u. press a key ...", file, flash_chip)
    // [160] call printf_str
    // [711] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s7 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // flash_chip * 10
    // [161] main::$193 = main::flash_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda flash_chip
    asl
    asl
    sta.z main__193
    // [162] main::$194 = main::$193 + main::flash_chip#10 -- vbuz1=vbuz1_plus_vbum2 
    lda flash_chip
    clc
    adc.z main__194
    sta.z main__194
    // [163] main::$63 = main::$194 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z main__63
    // gotoxy(2 + flash_chip * 10, 58)
    // [164] gotoxy::x#19 = 2 + main::$63 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z main__63
    sta.z gotoxy.x
    // [165] call gotoxy
    // [485] phi from main::@115 to gotoxy [phi:main::@115->gotoxy]
    // [485] phi gotoxy::y#25 = $3a [phi:main::@115->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = gotoxy::x#19 [phi:main::@115->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [166] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // printf("no file")
    // [167] call printf_str
    // [711] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s8 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@16
  __b16:
    // if (flash_chip != 0)
    // [168] if(main::flash_chip#10==0) goto main::@13 -- vbum1_eq_0_then_la1 
    lda flash_chip
    beq __b13
    // main::bank_set_brom7
    // BROM = bank
    // [169] BROM = main::bank_set_brom7_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom7_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // [171] phi from main::CLI3 to main::@63 [phi:main::CLI3->main::@63]
    // main::@63
    // wait_key()
    // [172] call wait_key
    // [777] phi from main::@63 to wait_key [phi:main::@63->wait_key]
    jsr wait_key
    // main::SEI4
    // asm
    // asm { sei  }
    sei
    // [174] phi from main::@12 main::@16 main::SEI4 to main::@13 [phi:main::@12/main::@16/main::SEI4->main::@13]
    // [174] phi __errno#77 = __errno#109 [phi:main::@12/main::@16/main::SEI4->main::@13#0] -- register_copy 
    // main::@13
  __b13:
    // for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--)
    // [175] main::flash_chip#1 = -- main::flash_chip#10 -- vbum1=_dec_vbum1 
    dec flash_chip
    // [93] phi from main::@13 to main::@11 [phi:main::@13->main::@11]
    // [93] phi __errno#109 = __errno#77 [phi:main::@13->main::@11#0] -- register_copy 
    // [93] phi main::flash_chip#10 = main::flash_chip#1 [phi:main::@13->main::@11#1] -- register_copy 
    jmp __b11
    // main::@15
  __b15:
    // table_chip_clear(flash_chip * 32)
    // [176] table_chip_clear::rom_bank#1 = main::flash_chip#10 << 5 -- vbuz1=vbum2_rol_5 
    lda flash_chip
    asl
    asl
    asl
    asl
    asl
    sta.z table_chip_clear.rom_bank
    // [177] call table_chip_clear
    // [938] phi from main::@15 to table_chip_clear [phi:main::@15->table_chip_clear]
    jsr table_chip_clear
    // [178] phi from main::@15 to main::@97 [phi:main::@15->main::@97]
    // main::@97
    // textcolor(WHITE)
    // [179] call textcolor
    // [467] phi from main::@97 to textcolor [phi:main::@97->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:main::@97->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@98
    // flash_chip * 10
    // [180] main::$170 = main::flash_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda flash_chip
    asl
    asl
    sta main__170
    // [181] main::$191 = main::$170 + main::flash_chip#10 -- vbuz1=vbum2_plus_vbum3 
    clc
    adc flash_chip
    sta.z main__191
    // [182] main::$70 = main::$191 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z main__70
    // gotoxy(2 + flash_chip * 10, 58)
    // [183] gotoxy::x#18 = 2 + main::$70 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z main__70
    sta.z gotoxy.x
    // [184] call gotoxy
    // [485] phi from main::@98 to gotoxy [phi:main::@98->gotoxy]
    // [485] phi gotoxy::y#25 = $3a [phi:main::@98->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = gotoxy::x#18 [phi:main::@98->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [185] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // printf("%s", file)
    // [186] call printf_string
    // [760] phi from main::@99 to printf_string [phi:main::@99->printf_string]
    // [760] phi printf_string::str#10 = file [phi:main::@99->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [760] phi printf_string::format_min_length#10 = 0 [phi:main::@99->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@100
    // print_chip_led(flash_chip, CYAN, BLUE)
    // [187] print_chip_led::r#5 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [188] call print_chip_led
    // [908] phi from main::@100 to print_chip_led [phi:main::@100->print_chip_led]
    // [908] phi print_chip_led::tc#10 = CYAN [phi:main::@100->print_chip_led#0] -- vbuz1=vbuc1 
    lda #CYAN
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#5 [phi:main::@100->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [189] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // info_line_clear()
    // [190] call info_line_clear
    // [751] phi from main::@101 to info_line_clear [phi:main::@101->info_line_clear]
    jsr info_line_clear
    // [191] phi from main::@101 to main::@102 [phi:main::@101->main::@102]
    // main::@102
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [192] call printf_str
    // [711] phi from main::@102 to printf_str [phi:main::@102->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@102->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s3 [phi:main::@102->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@103
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [193] printf_uchar::uvalue#4 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [194] call printf_uchar
    // [928] phi from main::@103 to printf_uchar [phi:main::@103->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@103->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 0 [phi:main::@103->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@103->printf_uchar#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#4 [phi:main::@103->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [195] phi from main::@103 to main::@104 [phi:main::@103->main::@104]
    // main::@104
    // printf("reading file for rom%u in ram ...", flash_chip)
    // [196] call printf_str
    // [711] phi from main::@104 to printf_str [phi:main::@104->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@104->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s4 [phi:main::@104->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@105
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [197] rom_address::rom_bank#2 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [198] call rom_address
    // [963] phi from main::@105 to rom_address [phi:main::@105->rom_address]
    // [963] phi rom_address::rom_bank#5 = rom_address::rom_bank#2 [phi:main::@105->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank)
    // [199] rom_address::return#10 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_2
    lda.z rom_address.return+1
    sta.z rom_address.return_2+1
    lda.z rom_address.return+2
    sta.z rom_address.return_2+2
    lda.z rom_address.return+3
    sta.z rom_address.return_2+3
    // main::@106
    // [200] main::flash_rom_address_boundary#0 = rom_address::return#10
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, size)
    // [201] flash_read::fp#0 = main::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z flash_read.fp
    lda fp+1
    sta.z flash_read.fp+1
    // [202] flash_read::rom_bank_start#1 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z flash_read.rom_bank_start
    // [203] call flash_read
    // [967] phi from main::@106 to flash_read [phi:main::@106->flash_read]
    // [967] phi flash_read::fp#10 = flash_read::fp#0 [phi:main::@106->flash_read#0] -- register_copy 
    // [967] phi flash_read::flash_ram_address#14 = (char *) 16384 [phi:main::@106->flash_read#1] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_read.flash_ram_address
    lda #>$4000
    sta.z flash_read.flash_ram_address+1
    // [967] phi flash_read::read_size#4 = $4000 [phi:main::@106->flash_read#2] -- vduz1=vduc1 
    lda #<$4000
    sta.z flash_read.read_size
    lda #>$4000
    sta.z flash_read.read_size+1
    lda #<$4000>>$10
    sta.z flash_read.read_size+2
    lda #>$4000>>$10
    sta.z flash_read.read_size+3
    // [967] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#1 [phi:main::@106->flash_read#3] -- register_copy 
    jsr flash_read
    // unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, size)
    // [204] flash_read::return#3 = flash_read::return#2
    // main::@107
    // [205] main::flash_bytes#0 = flash_read::return#3 -- vdum1=vduz2 
    lda.z flash_read.return
    sta flash_bytes
    lda.z flash_read.return+1
    sta flash_bytes+1
    lda.z flash_read.return+2
    sta flash_bytes+2
    lda.z flash_read.return+3
    sta flash_bytes+3
    // rom_size(1)
    // [206] call rom_size
    // [999] phi from main::@107 to rom_size [phi:main::@107->rom_size]
    jsr rom_size
    // main::@108
    // if (flash_bytes != rom_size(1))
    // [207] if(main::flash_bytes#0==rom_size::return#0) goto main::@17 -- vdum1_eq_vduc1_then_la1 
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
    beq __b17
  !:
    rts
    // main::@17
  __b17:
    // flash_rom_address_boundary += flash_bytes
    // [208] main::flash_rom_address_boundary#1 = main::flash_rom_address_boundary#0 + main::flash_bytes#0 -- vdum1=vduz2_plus_vdum1 
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
    // [209] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::@58
    // size = rom_sizes[flash_chip]
    // [210] main::size#1 = main::rom_sizes[main::$170] -- vduz1=pduc1_derefidx_vbum2 
    // read from bank 1 in bram.
    ldy main__170
    lda rom_sizes,y
    sta.z size
    lda rom_sizes+1,y
    sta.z size+1
    lda rom_sizes+2,y
    sta.z size+2
    lda rom_sizes+3,y
    sta.z size+3
    // size -= 0x4000
    // [211] main::size#2 = main::size#1 - $4000 -- vduz1=vduz1_minus_vduc1 
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
    // [212] flash_read::rom_bank_start#2 = main::flash_rom_bank#0 + 1 -- vbuz1=vbum2_plus_1 
    lda flash_rom_bank
    inc
    sta.z flash_read.rom_bank_start
    // [213] flash_read::fp#1 = main::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z flash_read.fp
    lda fp+1
    sta.z flash_read.fp+1
    // [214] flash_read::read_size#1 = main::size#2
    // [215] call flash_read
    // [967] phi from main::@58 to flash_read [phi:main::@58->flash_read]
    // [967] phi flash_read::fp#10 = flash_read::fp#1 [phi:main::@58->flash_read#0] -- register_copy 
    // [967] phi flash_read::flash_ram_address#14 = (char *) 40960 [phi:main::@58->flash_read#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z flash_read.flash_ram_address
    lda #>$a000
    sta.z flash_read.flash_ram_address+1
    // [967] phi flash_read::read_size#4 = flash_read::read_size#1 [phi:main::@58->flash_read#2] -- register_copy 
    // [967] phi flash_read::rom_bank_start#11 = flash_read::rom_bank_start#2 [phi:main::@58->flash_read#3] -- register_copy 
    jsr flash_read
    // flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [216] flash_read::return#4 = flash_read::return#2
    // main::@117
    // flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, size)
    // [217] main::flash_bytes#1 = flash_read::return#4 -- vdum1=vduz2 
    lda.z flash_read.return
    sta flash_bytes_1
    lda.z flash_read.return+1
    sta flash_bytes_1+1
    lda.z flash_read.return+2
    sta flash_bytes_1+2
    lda.z flash_read.return+3
    sta flash_bytes_1+3
    // flash_rom_address_boundary += flash_bytes
    // [218] main::flash_rom_address_boundary#11 = main::flash_rom_address_boundary#1 + main::flash_bytes#1 -- vdum1=vdum2_plus_vdum1 
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
    // [219] fclose::stream#0 = main::fp#0
    // [220] call fclose
    jsr fclose
    // main::bank_set_bram3
    // BRAM = bank
    // [221] BRAM = main::bank_set_bram3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram3_bank
    sta.z BRAM
    // main::bank_set_brom4
    // BROM = bank
    // [222] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // [223] phi from main::bank_set_brom4 to main::@59 [phi:main::bank_set_brom4->main::@59]
    // main::@59
    // info_line_clear()
    // [224] call info_line_clear
  // Now we compare the RAM with the actual ROM contents.
    // [751] phi from main::@59 to info_line_clear [phi:main::@59->info_line_clear]
    jsr info_line_clear
    // [225] phi from main::@59 to main::@118 [phi:main::@59->main::@118]
    // main::@118
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [226] call printf_str
    // [711] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s9 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [227] printf_uchar::uvalue#6 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [228] call printf_uchar
    // [928] phi from main::@119 to printf_uchar [phi:main::@119->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@119->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 0 [phi:main::@119->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@119->printf_uchar#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#6 [phi:main::@119->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [229] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // printf("verifying rom%u with file ... (.) same, (*) different.", flash_chip)
    // [230] call printf_str
    // [711] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s10 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@121
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [231] rom_address::rom_bank#3 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [232] call rom_address
    // [963] phi from main::@121 to rom_address [phi:main::@121->rom_address]
    // [963] phi rom_address::rom_bank#5 = rom_address::rom_bank#3 [phi:main::@121->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address_sector = rom_address(flash_rom_bank)
    // [233] rom_address::return#11 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_3
    lda.z rom_address.return+1
    sta.z rom_address.return_3+1
    lda.z rom_address.return+2
    sta.z rom_address.return_3+2
    lda.z rom_address.return+3
    sta.z rom_address.return_3+3
    // main::@122
    // [234] main::flash_rom_address1#0 = rom_address::return#11
    // gotoxy(x, y)
    // [235] call gotoxy
    // [485] phi from main::@122 to gotoxy [phi:main::@122->gotoxy]
    // [485] phi gotoxy::y#25 = 4 [phi:main::@122->gotoxy#0] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = $e [phi:main::@122->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [237] phi from main::SEI2 to main::@18 [phi:main::SEI2->main::@18]
    // [237] phi main::y_sector#10 = 4 [phi:main::SEI2->main::@18#0] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector
    // [237] phi main::x_sector#10 = $e [phi:main::SEI2->main::@18#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [237] phi main::read_ram_address#10 = (char *) 16384 [phi:main::SEI2->main::@18#2] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address
    lda #>$4000
    sta.z read_ram_address+1
    // [237] phi main::read_ram_bank#13 = 0 [phi:main::SEI2->main::@18#3] -- vbuz1=vbuc1 
    lda #0
    sta.z read_ram_bank
    // [237] phi main::flash_rom_address1#13 = main::flash_rom_address1#0 [phi:main::SEI2->main::@18#4] -- register_copy 
    // [237] phi from main::@24 to main::@18 [phi:main::@24->main::@18]
    // [237] phi main::y_sector#10 = main::y_sector#10 [phi:main::@24->main::@18#0] -- register_copy 
    // [237] phi main::x_sector#10 = main::x_sector#1 [phi:main::@24->main::@18#1] -- register_copy 
    // [237] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@24->main::@18#2] -- register_copy 
    // [237] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@24->main::@18#3] -- register_copy 
    // [237] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@24->main::@18#4] -- register_copy 
    // main::@18
  __b18:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [238] if(main::flash_rom_address1#13<main::flash_rom_address_boundary#11) goto main::@19 -- vduz1_lt_vdum2_then_la1 
    lda.z flash_rom_address1+3
    cmp flash_rom_address_boundary_2+3
    bcs !__b19+
    jmp __b19
  !__b19:
    bne !+
    lda.z flash_rom_address1+2
    cmp flash_rom_address_boundary_2+2
    bcs !__b19+
    jmp __b19
  !__b19:
    bne !+
    lda.z flash_rom_address1+1
    cmp flash_rom_address_boundary_2+1
    bcs !__b19+
    jmp __b19
  !__b19:
    bne !+
    lda.z flash_rom_address1
    cmp flash_rom_address_boundary_2
    bcs !__b19+
    jmp __b19
  !__b19:
  !:
    // [239] phi from main::@18 to main::@20 [phi:main::@18->main::@20]
    // main::@20
    // info_line_clear()
    // [240] call info_line_clear
    // [751] phi from main::@20 to info_line_clear [phi:main::@20->info_line_clear]
    jsr info_line_clear
    // [241] phi from main::@20 to main::@124 [phi:main::@20->main::@124]
    // main::@124
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [242] call printf_str
    // [711] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s11 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@125
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [243] printf_uchar::uvalue#7 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [244] call printf_uchar
    // [928] phi from main::@125 to printf_uchar [phi:main::@125->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@125->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 0 [phi:main::@125->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@125->printf_uchar#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#7 [phi:main::@125->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [245] phi from main::@125 to main::@126 [phi:main::@125->main::@126]
    // main::@126
    // printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip)
    // [246] call printf_str
    // [711] phi from main::@126 to printf_str [phi:main::@126->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@126->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s12 [phi:main::@126->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::bank_set_brom5
    // BROM = bank
    // [247] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [249] phi from main::CLI2 to main::@60 [phi:main::CLI2->main::@60]
    // main::@60
    // wait_key()
    // [250] call wait_key
    // [777] phi from main::@60 to wait_key [phi:main::@60->wait_key]
    jsr wait_key
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::@61
    // rom_address(flash_rom_bank)
    // [252] rom_address::rom_bank#4 = main::flash_rom_bank#0 -- vbuz1=vbum2 
    lda flash_rom_bank
    sta.z rom_address.rom_bank
    // [253] call rom_address
    // [963] phi from main::@61 to rom_address [phi:main::@61->rom_address]
    // [963] phi rom_address::rom_bank#5 = rom_address::rom_bank#4 [phi:main::@61->rom_address#0] -- register_copy 
    jsr rom_address
    // rom_address(flash_rom_bank)
    // [254] rom_address::return#12 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_4
    lda.z rom_address.return+1
    sta.z rom_address.return_4+1
    lda.z rom_address.return+2
    sta.z rom_address.return_4+2
    lda.z rom_address.return+3
    sta.z rom_address.return_4+3
    // main::@127
    // flash_rom_address_sector = rom_address(flash_rom_bank)
    // [255] main::flash_rom_address_sector#1 = rom_address::return#12
    // textcolor(WHITE)
    // [256] call textcolor
    // [467] phi from main::@127 to textcolor [phi:main::@127->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:main::@127->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@128
    // print_chip_led(flash_chip, PURPLE, BLUE)
    // [257] print_chip_led::r#7 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [258] call print_chip_led
    // [908] phi from main::@128 to print_chip_led [phi:main::@128->print_chip_led]
    // [908] phi print_chip_led::tc#10 = PURPLE [phi:main::@128->print_chip_led#0] -- vbuz1=vbuc1 
    lda #PURPLE
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#7 [phi:main::@128->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [259] phi from main::@128 to main::@129 [phi:main::@128->main::@129]
    // main::@129
    // info_line_clear()
    // [260] call info_line_clear
    // [751] phi from main::@129 to info_line_clear [phi:main::@129->info_line_clear]
    jsr info_line_clear
    // [261] phi from main::@129 to main::@130 [phi:main::@129->main::@130]
    // main::@130
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [262] call printf_str
    // [711] phi from main::@130 to printf_str [phi:main::@130->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@130->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s13 [phi:main::@130->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@131
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [263] printf_uchar::uvalue#8 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [264] call printf_uchar
    // [928] phi from main::@131 to printf_uchar [phi:main::@131->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@131->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 0 [phi:main::@131->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@131->printf_uchar#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#8 [phi:main::@131->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [265] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip)
    // [266] call printf_str
    // [711] phi from main::@132 to printf_str [phi:main::@132->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@132->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s14 [phi:main::@132->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // [267] phi from main::@132 to main::@27 [phi:main::@132->main::@27]
    // [267] phi main::flash_errors_sector#10 = 0 [phi:main::@132->main::@27#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [267] phi main::y_sector1#13 = 4 [phi:main::@132->main::@27#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y_sector1
    // [267] phi main::x_sector1#10 = $e [phi:main::@132->main::@27#2] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector1
    // [267] phi main::read_ram_address_sector#10 = (char *) 16384 [phi:main::@132->main::@27#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z read_ram_address_sector
    lda #>$4000
    sta.z read_ram_address_sector+1
    // [267] phi main::read_ram_bank_sector#13 = 0 [phi:main::@132->main::@27#4] -- vbuz1=vbuc1 
    lda #0
    sta.z read_ram_bank_sector
    // [267] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#1 [phi:main::@132->main::@27#5] -- register_copy 
    // [267] phi from main::@38 to main::@27 [phi:main::@38->main::@27]
    // [267] phi main::flash_errors_sector#10 = main::flash_errors_sector#23 [phi:main::@38->main::@27#0] -- register_copy 
    // [267] phi main::y_sector1#13 = main::y_sector1#13 [phi:main::@38->main::@27#1] -- register_copy 
    // [267] phi main::x_sector1#10 = main::x_sector1#1 [phi:main::@38->main::@27#2] -- register_copy 
    // [267] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@38->main::@27#3] -- register_copy 
    // [267] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@38->main::@27#4] -- register_copy 
    // [267] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@38->main::@27#5] -- register_copy 
    // main::@27
  __b27:
    // while (flash_rom_address_sector < flash_rom_address_boundary)
    // [268] if(main::flash_rom_address_sector#11<main::flash_rom_address_boundary#11) goto main::@28 -- vduz1_lt_vdum2_then_la1 
    lda.z flash_rom_address_sector+3
    cmp flash_rom_address_boundary_2+3
    bcs !__b28+
    jmp __b28
  !__b28:
    bne !+
    lda.z flash_rom_address_sector+2
    cmp flash_rom_address_boundary_2+2
    bcs !__b28+
    jmp __b28
  !__b28:
    bne !+
    lda.z flash_rom_address_sector+1
    cmp flash_rom_address_boundary_2+1
    bcs !__b28+
    jmp __b28
  !__b28:
    bne !+
    lda.z flash_rom_address_sector
    cmp flash_rom_address_boundary_2
    bcs !__b28+
    jmp __b28
  !__b28:
  !:
    // main::bank_set_bram4
    // BRAM = bank
    // [269] BRAM = main::bank_set_bram4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram4_bank
    sta.z BRAM
    // main::bank_set_brom6
    // BROM = bank
    // [270] BROM = main::bank_set_brom6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom6_bank
    sta.z BROM
    // main::@62
    // if (!flash_errors_sector)
    // [271] if(0==main::flash_errors_sector#10) goto main::@43 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b43
    // [272] phi from main::@62 to main::@42 [phi:main::@62->main::@42]
    // main::@42
    // textcolor(RED)
    // [273] call textcolor
    // [467] phi from main::@42 to textcolor [phi:main::@42->textcolor]
    // [467] phi textcolor::color#23 = RED [phi:main::@42->textcolor#0] -- vbuz1=vbuc1 
    lda #RED
    sta.z textcolor.color
    jsr textcolor
    // main::@155
    // print_chip_led(flash_chip, RED, BLUE)
    // [274] print_chip_led::r#9 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [275] call print_chip_led
    // [908] phi from main::@155 to print_chip_led [phi:main::@155->print_chip_led]
    // [908] phi print_chip_led::tc#10 = RED [phi:main::@155->print_chip_led#0] -- vbuz1=vbuc1 
    lda #RED
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#9 [phi:main::@155->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [276] phi from main::@155 to main::@156 [phi:main::@155->main::@156]
    // main::@156
    // info_line_clear()
    // [277] call info_line_clear
    // [751] phi from main::@156 to info_line_clear [phi:main::@156->info_line_clear]
    jsr info_line_clear
    // [278] phi from main::@156 to main::@157 [phi:main::@156->main::@157]
    // main::@157
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [279] call printf_str
    // [711] phi from main::@157 to printf_str [phi:main::@157->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@157->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s16 [phi:main::@157->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@158
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [280] printf_uchar::uvalue#10 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [281] call printf_uchar
    // [928] phi from main::@158 to printf_uchar [phi:main::@158->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@158->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 0 [phi:main::@158->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@158->printf_uchar#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#10 [phi:main::@158->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [282] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [283] call printf_str
    // [711] phi from main::@159 to printf_str [phi:main::@159->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@159->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s19 [phi:main::@159->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@160
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [284] printf_uint::uvalue#2 = main::flash_errors_sector#10 -- vwuz1=vwuz2 
    lda.z flash_errors_sector
    sta.z printf_uint.uvalue
    lda.z flash_errors_sector+1
    sta.z printf_uint.uvalue+1
    // [285] call printf_uint
    // [1028] phi from main::@160 to printf_uint [phi:main::@160->printf_uint]
    // [1028] phi printf_uint::format_min_length#3 = 0 [phi:main::@160->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_min_length
    // [1028] phi printf_uint::format_radix#3 = DECIMAL [phi:main::@160->printf_uint#1] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1028] phi printf_uint::uvalue#3 = printf_uint::uvalue#2 [phi:main::@160->printf_uint#2] -- register_copy 
    jsr printf_uint
    // [286] phi from main::@160 to main::@161 [phi:main::@160->main::@161]
    // main::@161
    // printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector)
    // [287] call printf_str
    // [711] phi from main::@161 to printf_str [phi:main::@161->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@161->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s20 [phi:main::@161->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    jmp __b16
    // [288] phi from main::@62 to main::@43 [phi:main::@62->main::@43]
    // main::@43
  __b43:
    // textcolor(GREEN)
    // [289] call textcolor
    // [467] phi from main::@43 to textcolor [phi:main::@43->textcolor]
    // [467] phi textcolor::color#23 = GREEN [phi:main::@43->textcolor#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z textcolor.color
    jsr textcolor
    // main::@150
    // print_chip_led(flash_chip, GREEN, BLUE)
    // [290] print_chip_led::r#8 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z print_chip_led.r
    // [291] call print_chip_led
    // [908] phi from main::@150 to print_chip_led [phi:main::@150->print_chip_led]
    // [908] phi print_chip_led::tc#10 = GREEN [phi:main::@150->print_chip_led#0] -- vbuz1=vbuc1 
    lda #GREEN
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#8 [phi:main::@150->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // [292] phi from main::@150 to main::@151 [phi:main::@150->main::@151]
    // main::@151
    // info_line_clear()
    // [293] call info_line_clear
    // [751] phi from main::@151 to info_line_clear [phi:main::@151->info_line_clear]
    jsr info_line_clear
    // [294] phi from main::@151 to main::@152 [phi:main::@151->main::@152]
    // main::@152
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [295] call printf_str
    // [711] phi from main::@152 to printf_str [phi:main::@152->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@152->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s16 [phi:main::@152->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@153
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [296] printf_uchar::uvalue#9 = main::flash_chip#10 -- vbuz1=vbum2 
    lda flash_chip
    sta.z printf_uchar.uvalue
    // [297] call printf_uchar
    // [928] phi from main::@153 to printf_uchar [phi:main::@153->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@153->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 0 [phi:main::@153->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@153->printf_uchar#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#9 [phi:main::@153->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [298] phi from main::@153 to main::@154 [phi:main::@153->main::@154]
    // main::@154
    // printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip)
    // [299] call printf_str
    // [711] phi from main::@154 to printf_str [phi:main::@154->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@154->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s17 [phi:main::@154->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    jmp __b16
    // main::@28
  __b28:
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [300] flash_verify::bank_ram#1 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_verify.bank_ram
    // [301] flash_verify::ptr_ram#2 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address_sector+1
    sta.z flash_verify.ptr_ram+1
    // [302] flash_verify::verify_rom_address#1 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address_sector+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address_sector+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address_sector+3
    sta.z flash_verify.verify_rom_address+3
    // [303] call flash_verify
  // rom_sector_erase(flash_rom_address_sector);
    // [1037] phi from main::@28 to flash_verify [phi:main::@28->flash_verify]
    // [1037] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#2 [phi:main::@28->flash_verify#0] -- register_copy 
    // [1037] phi flash_verify::verify_rom_size#11 = $1000 [phi:main::@28->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z flash_verify.verify_rom_size
    lda #>$1000
    sta.z flash_verify.verify_rom_size+1
    // [1037] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#1 [phi:main::@28->flash_verify#2] -- register_copy 
    // [1037] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#1 [phi:main::@28->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR)
    // [304] flash_verify::return#3 = flash_verify::correct_bytes#2
    // main::@137
    // [305] main::equal_bytes1#0 = flash_verify::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [306] if(main::equal_bytes1#0!=$1000) goto main::@30 -- vwuz1_neq_vwuc1_then_la1 
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
    // [307] phi from main::@137 to main::@39 [phi:main::@137->main::@39]
    // main::@39
    // textcolor(WHITE)
    // [308] call textcolor
    // [467] phi from main::@39 to textcolor [phi:main::@39->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:main::@39->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@138
    // gotoxy(x_sector, y_sector)
    // [309] gotoxy::x#22 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z gotoxy.x
    // [310] gotoxy::y#22 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [311] call gotoxy
    // [485] phi from main::@138 to gotoxy [phi:main::@138->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#22 [phi:main::@138->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = gotoxy::x#22 [phi:main::@138->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [312] phi from main::@138 to main::@139 [phi:main::@138->main::@139]
    // main::@139
    // printf("%s", pattern)
    // [313] call printf_string
    // [760] phi from main::@139 to printf_string [phi:main::@139->printf_string]
    // [760] phi printf_string::str#10 = main::pattern1#1 [phi:main::@139->printf_string#0] -- pbuz1=pbuc1 
    lda #<pattern1_1
    sta.z printf_string.str
    lda #>pattern1_1
    sta.z printf_string.str+1
    // [760] phi printf_string::format_min_length#10 = 0 [phi:main::@139->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // [314] phi from main::@139 main::@36 to main::@29 [phi:main::@139/main::@36->main::@29]
    // [314] phi main::flash_errors_sector#23 = main::flash_errors_sector#10 [phi:main::@139/main::@36->main::@29#0] -- register_copy 
    // main::@29
  __b29:
    // read_ram_address_sector += ROM_SECTOR
    // [315] main::read_ram_address_sector#2 = main::read_ram_address_sector#10 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address_sector
    clc
    adc #<$1000
    sta.z read_ram_address_sector
    lda.z read_ram_address_sector+1
    adc #>$1000
    sta.z read_ram_address_sector+1
    // flash_rom_address_sector += ROM_SECTOR
    // [316] main::flash_rom_address_sector#10 = main::flash_rom_address_sector#11 + $1000 -- vduz1=vduz1_plus_vwuc1 
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
    // [317] if(main::read_ram_address_sector#2!=$8000) goto main::@168 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$8000
    bne __b37
    lda.z read_ram_address_sector
    cmp #<$8000
    bne __b37
    // [319] phi from main::@29 to main::@37 [phi:main::@29->main::@37]
    // [319] phi main::read_ram_bank_sector#6 = 1 [phi:main::@29->main::@37#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank_sector
    // [319] phi main::read_ram_address_sector#8 = (char *) 40960 [phi:main::@29->main::@37#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [318] phi from main::@29 to main::@168 [phi:main::@29->main::@168]
    // main::@168
    // [319] phi from main::@168 to main::@37 [phi:main::@168->main::@37]
    // [319] phi main::read_ram_bank_sector#6 = main::read_ram_bank_sector#13 [phi:main::@168->main::@37#0] -- register_copy 
    // [319] phi main::read_ram_address_sector#8 = main::read_ram_address_sector#2 [phi:main::@168->main::@37#1] -- register_copy 
    // main::@37
  __b37:
    // if (read_ram_address_sector == 0xC000)
    // [320] if(main::read_ram_address_sector#8!=$c000) goto main::@38 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address_sector+1
    cmp #>$c000
    bne __b38
    lda.z read_ram_address_sector
    cmp #<$c000
    bne __b38
    // main::@40
    // read_ram_bank_sector++;
    // [321] main::read_ram_bank_sector#3 = ++ main::read_ram_bank_sector#6 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank_sector
    // [322] phi from main::@40 to main::@38 [phi:main::@40->main::@38]
    // [322] phi main::read_ram_address_sector#14 = (char *) 40960 [phi:main::@40->main::@38#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address_sector
    lda #>$a000
    sta.z read_ram_address_sector+1
    // [322] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#3 [phi:main::@40->main::@38#1] -- register_copy 
    // [322] phi from main::@37 to main::@38 [phi:main::@37->main::@38]
    // [322] phi main::read_ram_address_sector#14 = main::read_ram_address_sector#8 [phi:main::@37->main::@38#0] -- register_copy 
    // [322] phi main::read_ram_bank_sector#11 = main::read_ram_bank_sector#6 [phi:main::@37->main::@38#1] -- register_copy 
    // main::@38
  __b38:
    // x_sector += 16
    // [323] main::x_sector1#1 = main::x_sector1#10 + $10 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$10
    clc
    adc.z x_sector1
    sta.z x_sector1
    // flash_rom_address_sector % 0x4000
    // [324] main::$143 = main::flash_rom_address_sector#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address_sector
    and #<$4000-1
    sta.z main__143
    lda.z flash_rom_address_sector+1
    and #>$4000-1
    sta.z main__143+1
    lda.z flash_rom_address_sector+2
    and #<$4000-1>>$10
    sta.z main__143+2
    lda.z flash_rom_address_sector+3
    and #>$4000-1>>$10
    sta.z main__143+3
    // if (!(flash_rom_address_sector % 0x4000))
    // [325] if(0!=main::$143) goto main::@27 -- 0_neq_vduz1_then_la1 
    lda.z main__143
    ora.z main__143+1
    ora.z main__143+2
    ora.z main__143+3
    beq !__b27+
    jmp __b27
  !__b27:
    // main::@41
    // y_sector++;
    // [326] main::y_sector1#1 = ++ main::y_sector1#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector1
    // [267] phi from main::@41 to main::@27 [phi:main::@41->main::@27]
    // [267] phi main::flash_errors_sector#10 = main::flash_errors_sector#23 [phi:main::@41->main::@27#0] -- register_copy 
    // [267] phi main::y_sector1#13 = main::y_sector1#1 [phi:main::@41->main::@27#1] -- register_copy 
    // [267] phi main::x_sector1#10 = $e [phi:main::@41->main::@27#2] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector1
    // [267] phi main::read_ram_address_sector#10 = main::read_ram_address_sector#14 [phi:main::@41->main::@27#3] -- register_copy 
    // [267] phi main::read_ram_bank_sector#13 = main::read_ram_bank_sector#11 [phi:main::@41->main::@27#4] -- register_copy 
    // [267] phi main::flash_rom_address_sector#11 = main::flash_rom_address_sector#10 [phi:main::@41->main::@27#5] -- register_copy 
    jmp __b27
    // [327] phi from main::@137 to main::@30 [phi:main::@137->main::@30]
  __b8:
    // [327] phi main::flash_errors#10 = 0 [phi:main::@137->main::@30#0] -- vbuz1=vbuc1 
    lda #0
    sta.z flash_errors
    // [327] phi main::retries#10 = 0 [phi:main::@137->main::@30#1] -- vbuz1=vbuc1 
    sta.z retries
    // [327] phi from main::@166 to main::@30 [phi:main::@166->main::@30]
    // [327] phi main::flash_errors#10 = main::flash_errors#11 [phi:main::@166->main::@30#0] -- register_copy 
    // [327] phi main::retries#10 = main::retries#1 [phi:main::@166->main::@30#1] -- register_copy 
    // main::@30
  __b30:
    // rom_sector_erase(flash_rom_address_sector)
    // [328] rom_sector_erase::address#0 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z rom_sector_erase.address
    lda.z flash_rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda.z flash_rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda.z flash_rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [329] call rom_sector_erase
    // [1063] phi from main::@30 to rom_sector_erase [phi:main::@30->rom_sector_erase]
    jsr rom_sector_erase
    // main::@140
    // unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR
    // [330] main::flash_rom_address_boundary1#0 = main::flash_rom_address_sector#11 + $1000 -- vduz1=vduz2_plus_vwuc1 
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
    // [331] gotoxy::x#23 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z gotoxy.x
    // [332] gotoxy::y#23 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [333] call gotoxy
    // [485] phi from main::@140 to gotoxy [phi:main::@140->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#23 [phi:main::@140->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = gotoxy::x#23 [phi:main::@140->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [334] phi from main::@140 to main::@141 [phi:main::@140->main::@141]
    // main::@141
    // printf("................")
    // [335] call printf_str
    // [711] phi from main::@141 to printf_str [phi:main::@141->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:main::@141->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = main::s15 [phi:main::@141->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@142
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [336] print_address::bram_bank#1 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z print_address.bram_bank
    // [337] print_address::bram_ptr#1 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z print_address.bram_ptr
    lda.z read_ram_address_sector+1
    sta.z print_address.bram_ptr+1
    // [338] print_address::brom_address#1 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z print_address.brom_address
    lda.z flash_rom_address_sector+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address_sector+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address_sector+3
    sta.z print_address.brom_address+3
    // [339] call print_address
    // [1075] phi from main::@142 to print_address [phi:main::@142->print_address]
    // [1075] phi print_address::bram_ptr#10 = print_address::bram_ptr#1 [phi:main::@142->print_address#0] -- register_copy 
    // [1075] phi print_address::bram_bank#10 = print_address::bram_bank#1 [phi:main::@142->print_address#1] -- register_copy 
    // [1075] phi print_address::brom_address#10 = print_address::brom_address#1 [phi:main::@142->print_address#2] -- register_copy 
    jsr print_address
    // main::@143
    // [340] main::flash_rom_address2#16 = main::flash_rom_address_sector#11 -- vduz1=vduz2 
    lda.z flash_rom_address_sector
    sta.z flash_rom_address2
    lda.z flash_rom_address_sector+1
    sta.z flash_rom_address2+1
    lda.z flash_rom_address_sector+2
    sta.z flash_rom_address2+2
    lda.z flash_rom_address_sector+3
    sta.z flash_rom_address2+3
    // [341] main::read_ram_address1#16 = main::read_ram_address_sector#10 -- pbuz1=pbuz2 
    lda.z read_ram_address_sector
    sta.z read_ram_address1
    lda.z read_ram_address_sector+1
    sta.z read_ram_address1+1
    // [342] main::x1#16 = main::x_sector1#10 -- vbuz1=vbuz2 
    lda.z x_sector1
    sta.z x1
    // [343] phi from main::@143 main::@149 to main::@31 [phi:main::@143/main::@149->main::@31]
    // [343] phi main::x1#10 = main::x1#16 [phi:main::@143/main::@149->main::@31#0] -- register_copy 
    // [343] phi main::flash_errors#11 = main::flash_errors#10 [phi:main::@143/main::@149->main::@31#1] -- register_copy 
    // [343] phi main::read_ram_address1#10 = main::read_ram_address1#16 [phi:main::@143/main::@149->main::@31#2] -- register_copy 
    // [343] phi main::flash_rom_address2#11 = main::flash_rom_address2#16 [phi:main::@143/main::@149->main::@31#3] -- register_copy 
    // main::@31
  __b31:
    // while (flash_rom_address < flash_rom_address_boundary)
    // [344] if(main::flash_rom_address2#11<main::flash_rom_address_boundary1#0) goto main::@32 -- vduz1_lt_vduz2_then_la1 
    lda.z flash_rom_address2+3
    cmp.z flash_rom_address_boundary1+3
    bcc __b32
    bne !+
    lda.z flash_rom_address2+2
    cmp.z flash_rom_address_boundary1+2
    bcc __b32
    bne !+
    lda.z flash_rom_address2+1
    cmp.z flash_rom_address_boundary1+1
    bcc __b32
    bne !+
    lda.z flash_rom_address2
    cmp.z flash_rom_address_boundary1
    bcc __b32
  !:
    // main::@33
    // retries++;
    // [345] main::retries#1 = ++ main::retries#10 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors && retries <= 3)
    // [346] if(0==main::flash_errors#11) goto main::@36 -- 0_eq_vbuz1_then_la1 
    lda.z flash_errors
    beq __b36
    // main::@166
    // [347] if(main::retries#1<3+1) goto main::@30 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b30+
    jmp __b30
  !__b30:
    // main::@36
  __b36:
    // flash_errors_sector += flash_errors
    // [348] main::flash_errors_sector#1 = main::flash_errors_sector#10 + main::flash_errors#11 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z flash_errors
    clc
    adc.z flash_errors_sector
    sta.z flash_errors_sector
    bcc !+
    inc.z flash_errors_sector+1
  !:
    jmp __b29
    // main::@32
  __b32:
    // print_address(read_ram_bank, read_ram_address, flash_rom_address)
    // [349] print_address::bram_bank#2 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z print_address.bram_bank
    // [350] print_address::bram_ptr#2 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z print_address.bram_ptr
    lda.z read_ram_address1+1
    sta.z print_address.bram_ptr+1
    // [351] print_address::brom_address#2 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z print_address.brom_address
    lda.z flash_rom_address2+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address2+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address2+3
    sta.z print_address.brom_address+3
    // [352] call print_address
    // [1075] phi from main::@32 to print_address [phi:main::@32->print_address]
    // [1075] phi print_address::bram_ptr#10 = print_address::bram_ptr#2 [phi:main::@32->print_address#0] -- register_copy 
    // [1075] phi print_address::bram_bank#10 = print_address::bram_bank#2 [phi:main::@32->print_address#1] -- register_copy 
    // [1075] phi print_address::brom_address#10 = print_address::brom_address#2 [phi:main::@32->print_address#2] -- register_copy 
    jsr print_address
    // main::@144
    // unsigned long written_bytes = flash_write(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address)
    // [353] flash_write::flash_ram_bank#0 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_write.flash_ram_bank
    // [354] flash_write::flash_ram_address#1 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_write.flash_ram_address
    lda.z read_ram_address1+1
    sta.z flash_write.flash_ram_address+1
    // [355] flash_write::flash_rom_address#1 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z flash_write.flash_rom_address
    lda.z flash_rom_address2+1
    sta.z flash_write.flash_rom_address+1
    lda.z flash_rom_address2+2
    sta.z flash_write.flash_rom_address+2
    lda.z flash_rom_address2+3
    sta.z flash_write.flash_rom_address+3
    // [356] call flash_write
    jsr flash_write
    // main::@145
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [357] flash_verify::bank_ram#2 = main::read_ram_bank_sector#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank_sector
    sta.z flash_verify.bank_ram
    // [358] flash_verify::ptr_ram#3 = main::read_ram_address1#10 -- pbuz1=pbuz2 
    lda.z read_ram_address1
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address1+1
    sta.z flash_verify.ptr_ram+1
    // [359] flash_verify::verify_rom_address#2 = main::flash_rom_address2#11 -- vduz1=vduz2 
    lda.z flash_rom_address2
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address2+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address2+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address2+3
    sta.z flash_verify.verify_rom_address+3
    // [360] call flash_verify
    // [1037] phi from main::@145 to flash_verify [phi:main::@145->flash_verify]
    // [1037] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#3 [phi:main::@145->flash_verify#0] -- register_copy 
    // [1037] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@145->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    // [1037] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#2 [phi:main::@145->flash_verify#2] -- register_copy 
    // [1037] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#2 [phi:main::@145->flash_verify#3] -- register_copy 
    jsr flash_verify
    // flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [361] flash_verify::return#4 = flash_verify::correct_bytes#2
    // main::@146
    // equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [362] main::equal_bytes1#1 = flash_verify::return#4
    // if (equal_bytes != 0x0100)
    // [363] if(main::equal_bytes1#1!=$100) goto main::@34 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes1+1
    cmp #>$100
    bne __b34
    lda.z equal_bytes1
    cmp #<$100
    bne __b34
    // [365] phi from main::@146 to main::@35 [phi:main::@146->main::@35]
    // [365] phi main::flash_errors#12 = main::flash_errors#11 [phi:main::@146->main::@35#0] -- register_copy 
    // [365] phi main::pattern1#5 = main::pattern1#3 [phi:main::@146->main::@35#1] -- pbuz1=pbuc1 
    lda #<pattern1_3
    sta.z pattern1
    lda #>pattern1_3
    sta.z pattern1+1
    jmp __b35
    // main::@34
  __b34:
    // flash_errors++;
    // [364] main::flash_errors#1 = ++ main::flash_errors#11 -- vbuz1=_inc_vbuz1 
    inc.z flash_errors
    // [365] phi from main::@34 to main::@35 [phi:main::@34->main::@35]
    // [365] phi main::flash_errors#12 = main::flash_errors#1 [phi:main::@34->main::@35#0] -- register_copy 
    // [365] phi main::pattern1#5 = main::pattern1#2 [phi:main::@34->main::@35#1] -- pbuz1=pbuc1 
    lda #<pattern1_2
    sta.z pattern1
    lda #>pattern1_2
    sta.z pattern1+1
    // main::@35
  __b35:
    // read_ram_address += 0x0100
    // [366] main::read_ram_address1#1 = main::read_ram_address1#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address1
    clc
    adc #<$100
    sta.z read_ram_address1
    lda.z read_ram_address1+1
    adc #>$100
    sta.z read_ram_address1+1
    // flash_rom_address += 0x0100
    // [367] main::flash_rom_address2#1 = main::flash_rom_address2#11 + $100 -- vduz1=vduz1_plus_vwuc1 
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
    // [368] call textcolor
    // [467] phi from main::@35 to textcolor [phi:main::@35->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:main::@35->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@147
    // gotoxy(x, y)
    // [369] gotoxy::x#24 = main::x1#10 -- vbuz1=vbuz2 
    lda.z x1
    sta.z gotoxy.x
    // [370] gotoxy::y#24 = main::y_sector1#13 -- vbuz1=vbuz2 
    lda.z y_sector1
    sta.z gotoxy.y
    // [371] call gotoxy
    // [485] phi from main::@147 to gotoxy [phi:main::@147->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#24 [phi:main::@147->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = gotoxy::x#24 [phi:main::@147->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@148
    // printf("%s", pattern)
    // [372] printf_string::str#9 = main::pattern1#5
    // [373] call printf_string
    // [760] phi from main::@148 to printf_string [phi:main::@148->printf_string]
    // [760] phi printf_string::str#10 = printf_string::str#9 [phi:main::@148->printf_string#0] -- register_copy 
    // [760] phi printf_string::format_min_length#10 = 0 [phi:main::@148->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@149
    // x++;
    // [374] main::x1#1 = ++ main::x1#10 -- vbuz1=_inc_vbuz1 
    inc.z x1
    jmp __b31
    // main::@19
  __b19:
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [375] flash_verify::bank_ram#0 = main::read_ram_bank#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank
    sta.z flash_verify.bank_ram
    // [376] flash_verify::ptr_ram#1 = main::read_ram_address#10 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z flash_verify.ptr_ram
    lda.z read_ram_address+1
    sta.z flash_verify.ptr_ram+1
    // [377] flash_verify::verify_rom_address#0 = main::flash_rom_address1#13 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z flash_verify.verify_rom_address
    lda.z flash_rom_address1+1
    sta.z flash_verify.verify_rom_address+1
    lda.z flash_rom_address1+2
    sta.z flash_verify.verify_rom_address+2
    lda.z flash_rom_address1+3
    sta.z flash_verify.verify_rom_address+3
    // [378] call flash_verify
    // [1037] phi from main::@19 to flash_verify [phi:main::@19->flash_verify]
    // [1037] phi flash_verify::ptr_ram#10 = flash_verify::ptr_ram#1 [phi:main::@19->flash_verify#0] -- register_copy 
    // [1037] phi flash_verify::verify_rom_size#11 = $100 [phi:main::@19->flash_verify#1] -- vwuz1=vwuc1 
    lda #<$100
    sta.z flash_verify.verify_rom_size
    lda #>$100
    sta.z flash_verify.verify_rom_size+1
    // [1037] phi flash_verify::verify_rom_address#3 = flash_verify::verify_rom_address#0 [phi:main::@19->flash_verify#2] -- register_copy 
    // [1037] phi flash_verify::bank_set_bram1_bank#0 = flash_verify::bank_ram#0 [phi:main::@19->flash_verify#3] -- register_copy 
    jsr flash_verify
    // unsigned int equal_bytes = flash_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100)
    // [379] flash_verify::return#2 = flash_verify::correct_bytes#2
    // main::@123
    // [380] main::equal_bytes#0 = flash_verify::return#2
    // if (equal_bytes != 0x0100)
    // [381] if(main::equal_bytes#0!=$100) goto main::@21 -- vwuz1_neq_vwuc1_then_la1 
    // unsigned long equal_bytes = 0x100;
    lda.z equal_bytes+1
    cmp #>$100
    bne __b21
    lda.z equal_bytes
    cmp #<$100
    bne __b21
    // [383] phi from main::@123 to main::@22 [phi:main::@123->main::@22]
    // [383] phi main::pattern#3 = main::s2 [phi:main::@123->main::@22#0] -- pbum1=pbuc1 
    lda #<s2
    sta pattern
    lda #>s2
    sta pattern+1
    jmp __b22
    // [382] phi from main::@123 to main::@21 [phi:main::@123->main::@21]
    // main::@21
  __b21:
    // [383] phi from main::@21 to main::@22 [phi:main::@21->main::@22]
    // [383] phi main::pattern#3 = main::pattern#1 [phi:main::@21->main::@22#0] -- pbum1=pbuc1 
    lda #<pattern_1
    sta pattern
    lda #>pattern_1
    sta pattern+1
    // main::@22
  __b22:
    // read_ram_address += 0x0100
    // [384] main::read_ram_address#1 = main::read_ram_address#10 + $100 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z read_ram_address
    clc
    adc #<$100
    sta.z read_ram_address
    lda.z read_ram_address+1
    adc #>$100
    sta.z read_ram_address+1
    // flash_rom_address += 0x0100
    // [385] main::flash_rom_address1#1 = main::flash_rom_address1#13 + $100 -- vduz1=vduz1_plus_vwuc1 
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
    // [386] print_address::bram_bank#0 = main::read_ram_bank#13 -- vbuz1=vbuz2 
    lda.z read_ram_bank
    sta.z print_address.bram_bank
    // [387] print_address::bram_ptr#0 = main::read_ram_address#1 -- pbuz1=pbuz2 
    lda.z read_ram_address
    sta.z print_address.bram_ptr
    lda.z read_ram_address+1
    sta.z print_address.bram_ptr+1
    // [388] print_address::brom_address#0 = main::flash_rom_address1#1 -- vduz1=vduz2 
    lda.z flash_rom_address1
    sta.z print_address.brom_address
    lda.z flash_rom_address1+1
    sta.z print_address.brom_address+1
    lda.z flash_rom_address1+2
    sta.z print_address.brom_address+2
    lda.z flash_rom_address1+3
    sta.z print_address.brom_address+3
    // [389] call print_address
    // [1075] phi from main::@22 to print_address [phi:main::@22->print_address]
    // [1075] phi print_address::bram_ptr#10 = print_address::bram_ptr#0 [phi:main::@22->print_address#0] -- register_copy 
    // [1075] phi print_address::bram_bank#10 = print_address::bram_bank#0 [phi:main::@22->print_address#1] -- register_copy 
    // [1075] phi print_address::brom_address#10 = print_address::brom_address#0 [phi:main::@22->print_address#2] -- register_copy 
    jsr print_address
    // [390] phi from main::@22 to main::@133 [phi:main::@22->main::@133]
    // main::@133
    // textcolor(WHITE)
    // [391] call textcolor
    // [467] phi from main::@133 to textcolor [phi:main::@133->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:main::@133->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@134
    // gotoxy(x_sector, y_sector)
    // [392] gotoxy::x#21 = main::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z gotoxy.x
    // [393] gotoxy::y#21 = main::y_sector#10 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z gotoxy.y
    // [394] call gotoxy
    // [485] phi from main::@134 to gotoxy [phi:main::@134->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#21 [phi:main::@134->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = gotoxy::x#21 [phi:main::@134->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@135
    // printf("%s", pattern)
    // [395] printf_string::str#7 = main::pattern#3 -- pbuz1=pbum2 
    lda pattern
    sta.z printf_string.str
    lda pattern+1
    sta.z printf_string.str+1
    // [396] call printf_string
    // [760] phi from main::@135 to printf_string [phi:main::@135->printf_string]
    // [760] phi printf_string::str#10 = printf_string::str#7 [phi:main::@135->printf_string#0] -- register_copy 
    // [760] phi printf_string::format_min_length#10 = 0 [phi:main::@135->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@136
    // x_sector++;
    // [397] main::x_sector#1 = ++ main::x_sector#10 -- vbuz1=_inc_vbuz1 
    inc.z x_sector
    // if (read_ram_address == 0x8000)
    // [398] if(main::read_ram_address#1!=$8000) goto main::@167 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$8000
    bne __b23
    lda.z read_ram_address
    cmp #<$8000
    bne __b23
    // [400] phi from main::@136 to main::@23 [phi:main::@136->main::@23]
    // [400] phi main::read_ram_bank#5 = 1 [phi:main::@136->main::@23#0] -- vbuz1=vbuc1 
    lda #1
    sta.z read_ram_bank
    // [400] phi main::read_ram_address#7 = (char *) 40960 [phi:main::@136->main::@23#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [399] phi from main::@136 to main::@167 [phi:main::@136->main::@167]
    // main::@167
    // [400] phi from main::@167 to main::@23 [phi:main::@167->main::@23]
    // [400] phi main::read_ram_bank#5 = main::read_ram_bank#13 [phi:main::@167->main::@23#0] -- register_copy 
    // [400] phi main::read_ram_address#7 = main::read_ram_address#1 [phi:main::@167->main::@23#1] -- register_copy 
    // main::@23
  __b23:
    // if (read_ram_address == 0xC000)
    // [401] if(main::read_ram_address#7!=$c000) goto main::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z read_ram_address+1
    cmp #>$c000
    bne __b24
    lda.z read_ram_address
    cmp #<$c000
    bne __b24
    // main::@25
    // read_ram_bank++;
    // [402] main::read_ram_bank#2 = ++ main::read_ram_bank#5 -- vbuz1=_inc_vbuz1 
    inc.z read_ram_bank
    // [403] phi from main::@25 to main::@24 [phi:main::@25->main::@24]
    // [403] phi main::read_ram_address#12 = (char *) 40960 [phi:main::@25->main::@24#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z read_ram_address
    lda #>$a000
    sta.z read_ram_address+1
    // [403] phi main::read_ram_bank#10 = main::read_ram_bank#2 [phi:main::@25->main::@24#1] -- register_copy 
    // [403] phi from main::@23 to main::@24 [phi:main::@23->main::@24]
    // [403] phi main::read_ram_address#12 = main::read_ram_address#7 [phi:main::@23->main::@24#0] -- register_copy 
    // [403] phi main::read_ram_bank#10 = main::read_ram_bank#5 [phi:main::@23->main::@24#1] -- register_copy 
    // main::@24
  __b24:
    // flash_rom_address % 0x4000
    // [404] main::$104 = main::flash_rom_address1#1 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address1
    and #<$4000-1
    sta.z main__104
    lda.z flash_rom_address1+1
    and #>$4000-1
    sta.z main__104+1
    lda.z flash_rom_address1+2
    and #<$4000-1>>$10
    sta.z main__104+2
    lda.z flash_rom_address1+3
    and #>$4000-1>>$10
    sta.z main__104+3
    // if (!(flash_rom_address % 0x4000))
    // [405] if(0!=main::$104) goto main::@18 -- 0_neq_vduz1_then_la1 
    lda.z main__104
    ora.z main__104+1
    ora.z main__104+2
    ora.z main__104+3
    beq !__b18+
    jmp __b18
  !__b18:
    // main::@26
    // y_sector++;
    // [406] main::y_sector#1 = ++ main::y_sector#10 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [237] phi from main::@26 to main::@18 [phi:main::@26->main::@18]
    // [237] phi main::y_sector#10 = main::y_sector#1 [phi:main::@26->main::@18#0] -- register_copy 
    // [237] phi main::x_sector#10 = $e [phi:main::@26->main::@18#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z x_sector
    // [237] phi main::read_ram_address#10 = main::read_ram_address#12 [phi:main::@26->main::@18#2] -- register_copy 
    // [237] phi main::read_ram_bank#13 = main::read_ram_bank#10 [phi:main::@26->main::@18#3] -- register_copy 
    // [237] phi main::flash_rom_address1#13 = main::flash_rom_address1#1 [phi:main::@26->main::@18#4] -- register_copy 
    jmp __b18
    // main::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [407] main::rom_manufacturer_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [408] main::rom_device_ids[main::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0x90)
    // [409] rom_unlock::address#3 = main::flash_rom_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
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
    // [410] call rom_unlock
    // [1121] phi from main::@2 to rom_unlock [phi:main::@2->rom_unlock]
    // [1121] phi rom_unlock::unlock_code#5 = $90 [phi:main::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1121] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:main::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // main::@71
    // rom_read_byte(flash_rom_address)
    // [411] rom_read_byte::address#0 = main::flash_rom_address#10 -- vduz1=vdum2 
    lda flash_rom_address
    sta.z rom_read_byte.address
    lda flash_rom_address+1
    sta.z rom_read_byte.address+1
    lda flash_rom_address+2
    sta.z rom_read_byte.address+2
    lda flash_rom_address+3
    sta.z rom_read_byte.address+3
    // [412] call rom_read_byte
    // [1131] phi from main::@71 to rom_read_byte [phi:main::@71->rom_read_byte]
    // [1131] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:main::@71->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(flash_rom_address)
    // [413] rom_read_byte::return#2 = rom_read_byte::return#0
    // main::@72
    // [414] main::$21 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(flash_rom_address)
    // [415] main::rom_manufacturer_ids[main::rom_chip#10] = main::$21 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z main__21
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(flash_rom_address + 1)
    // [416] rom_read_byte::address#1 = main::flash_rom_address#10 + 1 -- vduz1=vdum2_plus_1 
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
    // [417] call rom_read_byte
    // [1131] phi from main::@72 to rom_read_byte [phi:main::@72->rom_read_byte]
    // [1131] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:main::@72->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(flash_rom_address + 1)
    // [418] rom_read_byte::return#3 = rom_read_byte::return#0
    // main::@73
    // [419] main::$23 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(flash_rom_address + 1)
    // [420] main::rom_device_ids[main::rom_chip#10] = main::$23 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z main__23
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(flash_rom_address + 0x05555, 0xF0)
    // [421] rom_unlock::address#4 = main::flash_rom_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
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
    // [422] call rom_unlock
    // [1121] phi from main::@73 to rom_unlock [phi:main::@73->rom_unlock]
    // [1121] phi rom_unlock::unlock_code#5 = $f0 [phi:main::@73->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1121] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:main::@73->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // main::bank_set_brom1
    // BROM = bank
    // [423] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // main::@54
    // case SST39SF010A:
    //             rom_device = "f010a";
    //             print_chip_KB(rom_chip, "128");
    //             print_chip_led(rom_chip, WHITE, BLUE);
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [424] if(main::rom_device_ids[main::rom_chip#10]==$b5) goto main::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [425] if(main::rom_device_ids[main::rom_chip#10]==$b6) goto main::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [426] if(main::rom_device_ids[main::rom_chip#10]==$b7) goto main::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b5+
    jmp __b5
  !__b5:
    // main::@6
    // print_chip_led(rom_chip, BLACK, BLUE)
    // [427] print_chip_led::r#4 = main::rom_chip#10 -- vbuz1=vbum2 
    tya
    sta.z print_chip_led.r
    // [428] call print_chip_led
    // [908] phi from main::@6 to print_chip_led [phi:main::@6->print_chip_led]
    // [908] phi print_chip_led::tc#10 = BLACK [phi:main::@6->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#4 [phi:main::@6->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@83
    // rom_device_ids[rom_chip] = UNKNOWN
    // [429] main::rom_device_ids[main::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // [430] phi from main::@83 to main::@7 [phi:main::@83->main::@7]
    // [430] phi main::rom_device#5 = main::rom_device#13 [phi:main::@83->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_4
    sta rom_device
    lda #>rom_device_4
    sta rom_device+1
    // main::@7
  __b7:
    // textcolor(WHITE)
    // [431] call textcolor
    // [467] phi from main::@7 to textcolor [phi:main::@7->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:main::@7->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // main::@84
    // rom_chip * 10
    // [432] main::$187 = main::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta main__187
    // [433] main::$188 = main::$187 + main::rom_chip#10 -- vbum1=vbum1_plus_vbum2 
    lda main__188
    clc
    adc rom_chip
    sta main__188
    // [434] main::$39 = main::$188 << 1 -- vbum1=vbum1_rol_1 
    asl main__39
    // gotoxy(2 + rom_chip * 10, 56)
    // [435] gotoxy::x#15 = 2 + main::$39 -- vbuz1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc main__39
    sta.z gotoxy.x
    // [436] call gotoxy
    // [485] phi from main::@84 to gotoxy [phi:main::@84->gotoxy]
    // [485] phi gotoxy::y#25 = $38 [phi:main::@84->gotoxy#0] -- vbuz1=vbuc1 
    lda #$38
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = gotoxy::x#15 [phi:main::@84->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@85
    // printf("%x", rom_manufacturer_ids[rom_chip])
    // [437] printf_uchar::uvalue#3 = main::rom_manufacturer_ids[main::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_manufacturer_ids,y
    sta.z printf_uchar.uvalue
    // [438] call printf_uchar
    // [928] phi from main::@85 to printf_uchar [phi:main::@85->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@85->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 0 [phi:main::@85->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:main::@85->printf_uchar#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#3 [phi:main::@85->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // main::@86
    // gotoxy(2 + rom_chip * 10, 57)
    // [439] gotoxy::x#16 = 2 + main::$39 -- vbuz1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc main__39
    sta.z gotoxy.x
    // [440] call gotoxy
    // [485] phi from main::@86 to gotoxy [phi:main::@86->gotoxy]
    // [485] phi gotoxy::y#25 = $39 [phi:main::@86->gotoxy#0] -- vbuz1=vbuc1 
    lda #$39
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = gotoxy::x#16 [phi:main::@86->gotoxy#1] -- register_copy 
    jsr gotoxy
    // main::@87
    // printf("%s", rom_device)
    // [441] printf_string::str#3 = main::rom_device#5 -- pbuz1=pbum2 
    lda rom_device
    sta.z printf_string.str
    lda rom_device+1
    sta.z printf_string.str+1
    // [442] call printf_string
    // [760] phi from main::@87 to printf_string [phi:main::@87->printf_string]
    // [760] phi printf_string::str#10 = printf_string::str#3 [phi:main::@87->printf_string#0] -- register_copy 
    // [760] phi printf_string::format_min_length#10 = 0 [phi:main::@87->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@88
    // rom_chip++;
    // [443] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // main::@8
    // flash_rom_address += 0x80000
    // [444] main::flash_rom_address#1 = main::flash_rom_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [82] phi from main::@8 to main::@1 [phi:main::@8->main::@1]
    // [82] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@8->main::@1#0] -- register_copy 
    // [82] phi main::flash_rom_address#10 = main::flash_rom_address#1 [phi:main::@8->main::@1#1] -- register_copy 
    jmp __b1
    // main::@5
  __b5:
    // print_chip_KB(rom_chip, "512")
    // [445] print_chip_KB::rom_chip#2 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_KB.rom_chip
    // [446] call print_chip_KB
    // [1143] phi from main::@5 to print_chip_KB [phi:main::@5->print_chip_KB]
    // [1143] phi print_chip_KB::kb#3 = main::kb2 [phi:main::@5->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb2
    sta.z print_chip_KB.kb
    lda #>kb2
    sta.z print_chip_KB.kb+1
    // [1143] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#2 [phi:main::@5->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@81
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [447] print_chip_led::r#3 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_led.r
    // [448] call print_chip_led
    // [908] phi from main::@81 to print_chip_led [phi:main::@81->print_chip_led]
    // [908] phi print_chip_led::tc#10 = WHITE [phi:main::@81->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#3 [phi:main::@81->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@82
    // rom_sizes[rom_chip] = 512 * 1024
    // [449] main::$169 = main::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z main__169
    // [450] main::rom_sizes[main::$169] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$200*$400
    sta rom_sizes,y
    lda #>$200*$400
    sta rom_sizes+1,y
    lda #<$200*$400>>$10
    sta rom_sizes+2,y
    lda #>$200*$400>>$10
    sta rom_sizes+3,y
    // [430] phi from main::@82 to main::@7 [phi:main::@82->main::@7]
    // [430] phi main::rom_device#5 = main::rom_device#12 [phi:main::@82->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_3
    sta rom_device
    lda #>rom_device_3
    sta rom_device+1
    jmp __b7
    // main::@4
  __b4:
    // print_chip_KB(rom_chip, "256")
    // [451] print_chip_KB::rom_chip#1 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_KB.rom_chip
    // [452] call print_chip_KB
    // [1143] phi from main::@4 to print_chip_KB [phi:main::@4->print_chip_KB]
    // [1143] phi print_chip_KB::kb#3 = main::kb1 [phi:main::@4->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb1
    sta.z print_chip_KB.kb
    lda #>kb1
    sta.z print_chip_KB.kb+1
    // [1143] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#1 [phi:main::@4->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@79
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [453] print_chip_led::r#2 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_led.r
    // [454] call print_chip_led
    // [908] phi from main::@79 to print_chip_led [phi:main::@79->print_chip_led]
    // [908] phi print_chip_led::tc#10 = WHITE [phi:main::@79->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#2 [phi:main::@79->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@80
    // rom_sizes[rom_chip] = 256 * 1024
    // [455] main::$168 = main::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z main__168
    // [456] main::rom_sizes[main::$168] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$100*$400
    sta rom_sizes,y
    lda #>$100*$400
    sta rom_sizes+1,y
    lda #<$100*$400>>$10
    sta rom_sizes+2,y
    lda #>$100*$400>>$10
    sta rom_sizes+3,y
    // [430] phi from main::@80 to main::@7 [phi:main::@80->main::@7]
    // [430] phi main::rom_device#5 = main::rom_device#11 [phi:main::@80->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_2
    sta rom_device
    lda #>rom_device_2
    sta rom_device+1
    jmp __b7
    // main::@3
  __b3:
    // print_chip_KB(rom_chip, "128")
    // [457] print_chip_KB::rom_chip#0 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_KB.rom_chip
    // [458] call print_chip_KB
    // [1143] phi from main::@3 to print_chip_KB [phi:main::@3->print_chip_KB]
    // [1143] phi print_chip_KB::kb#3 = main::kb [phi:main::@3->print_chip_KB#0] -- pbuz1=pbuc1 
    lda #<kb
    sta.z print_chip_KB.kb
    lda #>kb
    sta.z print_chip_KB.kb+1
    // [1143] phi print_chip_KB::rom_chip#3 = print_chip_KB::rom_chip#0 [phi:main::@3->print_chip_KB#1] -- register_copy 
    jsr print_chip_KB
    // main::@77
    // print_chip_led(rom_chip, WHITE, BLUE)
    // [459] print_chip_led::r#1 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z print_chip_led.r
    // [460] call print_chip_led
    // [908] phi from main::@77 to print_chip_led [phi:main::@77->print_chip_led]
    // [908] phi print_chip_led::tc#10 = WHITE [phi:main::@77->print_chip_led#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#1 [phi:main::@77->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // main::@78
    // rom_sizes[rom_chip] = 128 * 1024
    // [461] main::$167 = main::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z main__167
    // [462] main::rom_sizes[main::$167] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$80*$400
    sta rom_sizes,y
    lda #>$80*$400
    sta rom_sizes+1,y
    lda #<$80*$400>>$10
    sta rom_sizes+2,y
    lda #>$80*$400>>$10
    sta rom_sizes+3,y
    // [430] phi from main::@78 to main::@7 [phi:main::@78->main::@7]
    // [430] phi main::rom_device#5 = main::rom_device#1 [phi:main::@78->main::@7#0] -- pbum1=pbuc1 
    lda #<rom_device_1
    sta rom_device
    lda #>rom_device_1
    sta rom_device+1
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
    .label main__39 = main__187
    main__170: .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
    rom_chip: .byte 0
    flash_rom_address: .dword 0
    flash_chip: .byte 0
    flash_rom_bank: .byte 0
    fp: .word 0
    flash_bytes: .dword 0
    .label flash_rom_address_boundary_1 = flash_bytes
    flash_bytes_1: .dword 0
    w: .word 0
    rom_device: .word 0
    pattern: .word 0
    .label flash_rom_address_boundary_2 = flash_bytes_1
    main__187: .byte 0
    .label main__188 = main__187
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [463] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [464] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [465] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [466] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($a9) char color)
textcolor: {
    .label textcolor__0 = $aa
    .label textcolor__1 = $a9
    .label color = $a9
    // __conio.color & 0xF0
    // [468] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [469] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [470] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [471] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($a9) char color)
bgcolor: {
    .label bgcolor__0 = $c5
    .label bgcolor__1 = $a9
    .label bgcolor__2 = $c5
    .label color = $a9
    // __conio.color & 0x0F
    // [473] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [474] bgcolor::$1 = bgcolor::color#11 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [475] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [476] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [477] return 
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
    // [478] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [479] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $dd
    // __mem unsigned char x
    // [480] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [481] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [483] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [484] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($78) char x, __zp($7a) char y)
gotoxy: {
    .label gotoxy__2 = $78
    .label gotoxy__3 = $78
    .label gotoxy__6 = $75
    .label gotoxy__7 = $75
    .label gotoxy__8 = $7d
    .label gotoxy__9 = $7b
    .label gotoxy__10 = $7a
    .label x = $78
    .label y = $7a
    .label gotoxy__14 = $75
    // (x>=__conio.width)?__conio.width:x
    // [486] if(gotoxy::x#25>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [488] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [488] phi gotoxy::$3 = gotoxy::x#25 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [487] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [489] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [490] if(gotoxy::y#25>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [491] gotoxy::$14 = gotoxy::y#25 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [492] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [492] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [493] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [494] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [495] gotoxy::$10 = gotoxy::y#25 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [496] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [497] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [498] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [499] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $ab
    // __conio.cursor_x = 0
    // [500] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [501] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [502] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [503] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [504] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [505] return 
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
    // [506] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [507] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $42
    .label clrscr__1 = $b8
    .label clrscr__2 = $38
    .label line_text = $39
    .label l = $3b
    .label ch = $39
    .label c = $4b
    // unsigned int line_text = __conio.mapbase_offset
    // [508] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [509] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [510] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [511] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [512] clrscr::l#0 = *((char *)&__conio+9) -- vbuz1=_deref_pbuc1 
    lda __conio+9
    sta.z l
    // [513] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [513] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [513] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [514] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [515] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [516] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [517] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [518] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta.z c
    // [519] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [519] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [520] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [521] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [522] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [523] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [524] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [525] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [526] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [527] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [528] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [529] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [530] return 
    rts
}
  // frame_draw
frame_draw: {
    .label x = $3b
    .label x1 = $4b
    .label y = $4e
    .label x2 = $32
    .label y_1 = $5a
    .label x3 = $22
    .label y_2 = $47
    .label x4 = $55
    .label y_3 = $2a
    .label x5 = $7f
    // textcolor(WHITE)
    // [532] call textcolor
    // [467] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [533] phi from frame_draw to frame_draw::@27 [phi:frame_draw->frame_draw::@27]
    // frame_draw::@27
    // bgcolor(BLUE)
    // [534] call bgcolor
    // [472] phi from frame_draw::@27 to bgcolor [phi:frame_draw::@27->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:frame_draw::@27->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [535] phi from frame_draw::@27 to frame_draw::@28 [phi:frame_draw::@27->frame_draw::@28]
    // frame_draw::@28
    // clrscr()
    // [536] call clrscr
    jsr clrscr
    // [537] phi from frame_draw::@28 to frame_draw::@1 [phi:frame_draw::@28->frame_draw::@1]
    // [537] phi frame_draw::x#2 = 0 [phi:frame_draw::@28->frame_draw::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x
    // frame_draw::@1
  __b1:
    // for (unsigned char x = 0; x < 79; x++)
    // [538] if(frame_draw::x#2<$4f) goto frame_draw::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x
    cmp #$4f
    bcs !__b2+
    jmp __b2
  !__b2:
    // [539] phi from frame_draw::@1 to frame_draw::@3 [phi:frame_draw::@1->frame_draw::@3]
    // frame_draw::@3
    // cputcxy(0, y, 0x70)
    // [540] call cputcxy
    // [1203] phi from frame_draw::@3 to cputcxy [phi:frame_draw::@3->cputcxy]
    // [1203] phi cputcxy::c#68 = $70 [phi:frame_draw::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 0 [phi:frame_draw::@3->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@3->cputcxy#2] -- vbuz1=vbuc1 
    sta.z cputcxy.x
    jsr cputcxy
    // [541] phi from frame_draw::@3 to frame_draw::@30 [phi:frame_draw::@3->frame_draw::@30]
    // frame_draw::@30
    // cputcxy(79, y, 0x6E)
    // [542] call cputcxy
    // [1203] phi from frame_draw::@30 to cputcxy [phi:frame_draw::@30->cputcxy]
    // [1203] phi cputcxy::c#68 = $6e [phi:frame_draw::@30->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 0 [phi:frame_draw::@30->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@30->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [543] phi from frame_draw::@30 to frame_draw::@31 [phi:frame_draw::@30->frame_draw::@31]
    // frame_draw::@31
    // cputcxy(0, y, 0x5d)
    // [544] call cputcxy
    // [1203] phi from frame_draw::@31 to cputcxy [phi:frame_draw::@31->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@31->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 1 [phi:frame_draw::@31->cputcxy#1] -- vbuz1=vbuc1 
    lda #1
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@31->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // [545] phi from frame_draw::@31 to frame_draw::@32 [phi:frame_draw::@31->frame_draw::@32]
    // frame_draw::@32
    // cputcxy(79, y, 0x5d)
    // [546] call cputcxy
    // [1203] phi from frame_draw::@32 to cputcxy [phi:frame_draw::@32->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@32->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 1 [phi:frame_draw::@32->cputcxy#1] -- vbuz1=vbuc1 
    lda #1
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@32->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [547] phi from frame_draw::@32 to frame_draw::@4 [phi:frame_draw::@32->frame_draw::@4]
    // [547] phi frame_draw::x1#2 = 0 [phi:frame_draw::@32->frame_draw::@4#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x1
    // frame_draw::@4
  __b4:
    // for (unsigned char x = 0; x < 79; x++)
    // [548] if(frame_draw::x1#2<$4f) goto frame_draw::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x1
    cmp #$4f
    bcs !__b5+
    jmp __b5
  !__b5:
    // [549] phi from frame_draw::@4 to frame_draw::@6 [phi:frame_draw::@4->frame_draw::@6]
    // frame_draw::@6
    // cputcxy(0, y, 0x6B)
    // [550] call cputcxy
    // [1203] phi from frame_draw::@6 to cputcxy [phi:frame_draw::@6->cputcxy]
    // [1203] phi cputcxy::c#68 = $6b [phi:frame_draw::@6->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 2 [phi:frame_draw::@6->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@6->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // [551] phi from frame_draw::@6 to frame_draw::@34 [phi:frame_draw::@6->frame_draw::@34]
    // frame_draw::@34
    // cputcxy(79, y, 0x73)
    // [552] call cputcxy
    // [1203] phi from frame_draw::@34 to cputcxy [phi:frame_draw::@34->cputcxy]
    // [1203] phi cputcxy::c#68 = $73 [phi:frame_draw::@34->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 2 [phi:frame_draw::@34->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@34->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // [553] phi from frame_draw::@34 to frame_draw::@35 [phi:frame_draw::@34->frame_draw::@35]
    // frame_draw::@35
    // cputcxy(12, y, 0x72)
    // [554] call cputcxy
    // [1203] phi from frame_draw::@35 to cputcxy [phi:frame_draw::@35->cputcxy]
    // [1203] phi cputcxy::c#68 = $72 [phi:frame_draw::@35->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 2 [phi:frame_draw::@35->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = $c [phi:frame_draw::@35->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // [555] phi from frame_draw::@35 to frame_draw::@7 [phi:frame_draw::@35->frame_draw::@7]
    // [555] phi frame_draw::y#101 = 3 [phi:frame_draw::@35->frame_draw::@7#0] -- vbuz1=vbuc1 
    lda #3
    sta.z y
    // frame_draw::@7
  __b7:
    // for (; y < 37; y++)
    // [556] if(frame_draw::y#101<$25) goto frame_draw::@8 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$25
    bcs !__b8+
    jmp __b8
  !__b8:
    // [557] phi from frame_draw::@7 to frame_draw::@9 [phi:frame_draw::@7->frame_draw::@9]
    // [557] phi frame_draw::x2#2 = 0 [phi:frame_draw::@7->frame_draw::@9#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x2
    // frame_draw::@9
  __b9:
    // for (unsigned char x = 0; x < 79; x++)
    // [558] if(frame_draw::x2#2<$4f) goto frame_draw::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x2
    cmp #$4f
    bcs !__b10+
    jmp __b10
  !__b10:
    // frame_draw::@11
    // cputcxy(0, y, 0x6B)
    // [559] cputcxy::y#13 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [560] call cputcxy
    // [1203] phi from frame_draw::@11 to cputcxy [phi:frame_draw::@11->cputcxy]
    // [1203] phi cputcxy::c#68 = $6b [phi:frame_draw::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#13 [phi:frame_draw::@11->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@11->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@40
    // cputcxy(79, y, 0x73)
    // [561] cputcxy::y#14 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [562] call cputcxy
    // [1203] phi from frame_draw::@40 to cputcxy [phi:frame_draw::@40->cputcxy]
    // [1203] phi cputcxy::c#68 = $73 [phi:frame_draw::@40->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#14 [phi:frame_draw::@40->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@40->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@41
    // cputcxy(12, y, 0x71)
    // [563] cputcxy::y#15 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [564] call cputcxy
    // [1203] phi from frame_draw::@41 to cputcxy [phi:frame_draw::@41->cputcxy]
    // [1203] phi cputcxy::c#68 = $71 [phi:frame_draw::@41->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#15 [phi:frame_draw::@41->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $c [phi:frame_draw::@41->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@42
    // y++;
    // [565] frame_draw::y#5 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [566] phi from frame_draw::@42 frame_draw::@44 to frame_draw::@12 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12]
    // [566] phi frame_draw::y#102 = frame_draw::y#5 [phi:frame_draw::@42/frame_draw::@44->frame_draw::@12#0] -- register_copy 
    // frame_draw::@12
  __b12:
    // for (; y < 41; y++)
    // [567] if(frame_draw::y#102<$29) goto frame_draw::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_1
    cmp #$29
    bcs !__b13+
    jmp __b13
  !__b13:
    // [568] phi from frame_draw::@12 to frame_draw::@14 [phi:frame_draw::@12->frame_draw::@14]
    // [568] phi frame_draw::x3#2 = 0 [phi:frame_draw::@12->frame_draw::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x3
    // frame_draw::@14
  __b14:
    // for (unsigned char x = 0; x < 79; x++)
    // [569] if(frame_draw::x3#2<$4f) goto frame_draw::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x3
    cmp #$4f
    bcs !__b15+
    jmp __b15
  !__b15:
    // frame_draw::@16
    // cputcxy(0, y, 0x6B)
    // [570] cputcxy::y#19 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [571] call cputcxy
    // [1203] phi from frame_draw::@16 to cputcxy [phi:frame_draw::@16->cputcxy]
    // [1203] phi cputcxy::c#68 = $6b [phi:frame_draw::@16->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#19 [phi:frame_draw::@16->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@16->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@46
    // cputcxy(79, y, 0x73)
    // [572] cputcxy::y#20 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [573] call cputcxy
    // [1203] phi from frame_draw::@46 to cputcxy [phi:frame_draw::@46->cputcxy]
    // [1203] phi cputcxy::c#68 = $73 [phi:frame_draw::@46->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#20 [phi:frame_draw::@46->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@46->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@47
    // cputcxy(10, y, 0x72)
    // [574] cputcxy::y#21 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [575] call cputcxy
    // [1203] phi from frame_draw::@47 to cputcxy [phi:frame_draw::@47->cputcxy]
    // [1203] phi cputcxy::c#68 = $72 [phi:frame_draw::@47->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#21 [phi:frame_draw::@47->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $a [phi:frame_draw::@47->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@48
    // cputcxy(20, y, 0x72)
    // [576] cputcxy::y#22 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [577] call cputcxy
    // [1203] phi from frame_draw::@48 to cputcxy [phi:frame_draw::@48->cputcxy]
    // [1203] phi cputcxy::c#68 = $72 [phi:frame_draw::@48->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#22 [phi:frame_draw::@48->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $14 [phi:frame_draw::@48->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@49
    // cputcxy(30, y, 0x72)
    // [578] cputcxy::y#23 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [579] call cputcxy
    // [1203] phi from frame_draw::@49 to cputcxy [phi:frame_draw::@49->cputcxy]
    // [1203] phi cputcxy::c#68 = $72 [phi:frame_draw::@49->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#23 [phi:frame_draw::@49->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $1e [phi:frame_draw::@49->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@50
    // cputcxy(40, y, 0x72)
    // [580] cputcxy::y#24 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [581] call cputcxy
    // [1203] phi from frame_draw::@50 to cputcxy [phi:frame_draw::@50->cputcxy]
    // [1203] phi cputcxy::c#68 = $72 [phi:frame_draw::@50->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#24 [phi:frame_draw::@50->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $28 [phi:frame_draw::@50->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@51
    // cputcxy(50, y, 0x72)
    // [582] cputcxy::y#25 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [583] call cputcxy
    // [1203] phi from frame_draw::@51 to cputcxy [phi:frame_draw::@51->cputcxy]
    // [1203] phi cputcxy::c#68 = $72 [phi:frame_draw::@51->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#25 [phi:frame_draw::@51->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $32 [phi:frame_draw::@51->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@52
    // cputcxy(60, y, 0x72)
    // [584] cputcxy::y#26 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [585] call cputcxy
    // [1203] phi from frame_draw::@52 to cputcxy [phi:frame_draw::@52->cputcxy]
    // [1203] phi cputcxy::c#68 = $72 [phi:frame_draw::@52->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#26 [phi:frame_draw::@52->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $3c [phi:frame_draw::@52->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@53
    // cputcxy(70, y, 0x72)
    // [586] cputcxy::y#27 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [587] call cputcxy
    // [1203] phi from frame_draw::@53 to cputcxy [phi:frame_draw::@53->cputcxy]
    // [1203] phi cputcxy::c#68 = $72 [phi:frame_draw::@53->cputcxy#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#27 [phi:frame_draw::@53->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $46 [phi:frame_draw::@53->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@54
    // cputcxy(79, y, 0x73)
    // [588] cputcxy::y#28 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [589] call cputcxy
    // [1203] phi from frame_draw::@54 to cputcxy [phi:frame_draw::@54->cputcxy]
    // [1203] phi cputcxy::c#68 = $73 [phi:frame_draw::@54->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#28 [phi:frame_draw::@54->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@54->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@55
    // y++;
    // [590] frame_draw::y#7 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz2 
    lda.z y_1
    inc
    sta.z y_2
    // [591] phi from frame_draw::@55 frame_draw::@64 to frame_draw::@17 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17]
    // [591] phi frame_draw::y#104 = frame_draw::y#7 [phi:frame_draw::@55/frame_draw::@64->frame_draw::@17#0] -- register_copy 
    // frame_draw::@17
  __b17:
    // for (; y < 55; y++)
    // [592] if(frame_draw::y#104<$37) goto frame_draw::@18 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_2
    cmp #$37
    bcs !__b18+
    jmp __b18
  !__b18:
    // [593] phi from frame_draw::@17 to frame_draw::@19 [phi:frame_draw::@17->frame_draw::@19]
    // [593] phi frame_draw::x4#2 = 0 [phi:frame_draw::@17->frame_draw::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x4
    // frame_draw::@19
  __b19:
    // for (unsigned char x = 0; x < 79; x++)
    // [594] if(frame_draw::x4#2<$4f) goto frame_draw::@20 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x4
    cmp #$4f
    bcs !__b20+
    jmp __b20
  !__b20:
    // frame_draw::@21
    // cputcxy(0, y, 0x6B)
    // [595] cputcxy::y#39 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [596] call cputcxy
    // [1203] phi from frame_draw::@21 to cputcxy [phi:frame_draw::@21->cputcxy]
    // [1203] phi cputcxy::c#68 = $6b [phi:frame_draw::@21->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#39 [phi:frame_draw::@21->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@21->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@66
    // cputcxy(79, y, 0x73)
    // [597] cputcxy::y#40 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [598] call cputcxy
    // [1203] phi from frame_draw::@66 to cputcxy [phi:frame_draw::@66->cputcxy]
    // [1203] phi cputcxy::c#68 = $73 [phi:frame_draw::@66->cputcxy#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#40 [phi:frame_draw::@66->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@66->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@67
    // cputcxy(10, y, 0x5B)
    // [599] cputcxy::y#41 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [600] call cputcxy
    // [1203] phi from frame_draw::@67 to cputcxy [phi:frame_draw::@67->cputcxy]
    // [1203] phi cputcxy::c#68 = $5b [phi:frame_draw::@67->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#41 [phi:frame_draw::@67->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $a [phi:frame_draw::@67->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@68
    // cputcxy(20, y, 0x5B)
    // [601] cputcxy::y#42 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [602] call cputcxy
    // [1203] phi from frame_draw::@68 to cputcxy [phi:frame_draw::@68->cputcxy]
    // [1203] phi cputcxy::c#68 = $5b [phi:frame_draw::@68->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#42 [phi:frame_draw::@68->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $14 [phi:frame_draw::@68->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@69
    // cputcxy(30, y, 0x5B)
    // [603] cputcxy::y#43 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [604] call cputcxy
    // [1203] phi from frame_draw::@69 to cputcxy [phi:frame_draw::@69->cputcxy]
    // [1203] phi cputcxy::c#68 = $5b [phi:frame_draw::@69->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#43 [phi:frame_draw::@69->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $1e [phi:frame_draw::@69->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@70
    // cputcxy(40, y, 0x5B)
    // [605] cputcxy::y#44 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [606] call cputcxy
    // [1203] phi from frame_draw::@70 to cputcxy [phi:frame_draw::@70->cputcxy]
    // [1203] phi cputcxy::c#68 = $5b [phi:frame_draw::@70->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#44 [phi:frame_draw::@70->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $28 [phi:frame_draw::@70->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@71
    // cputcxy(50, y, 0x5B)
    // [607] cputcxy::y#45 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [608] call cputcxy
    // [1203] phi from frame_draw::@71 to cputcxy [phi:frame_draw::@71->cputcxy]
    // [1203] phi cputcxy::c#68 = $5b [phi:frame_draw::@71->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#45 [phi:frame_draw::@71->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $32 [phi:frame_draw::@71->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@72
    // cputcxy(60, y, 0x5B)
    // [609] cputcxy::y#46 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [610] call cputcxy
    // [1203] phi from frame_draw::@72 to cputcxy [phi:frame_draw::@72->cputcxy]
    // [1203] phi cputcxy::c#68 = $5b [phi:frame_draw::@72->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#46 [phi:frame_draw::@72->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $3c [phi:frame_draw::@72->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@73
    // cputcxy(70, y, 0x5B)
    // [611] cputcxy::y#47 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [612] call cputcxy
    // [1203] phi from frame_draw::@73 to cputcxy [phi:frame_draw::@73->cputcxy]
    // [1203] phi cputcxy::c#68 = $5b [phi:frame_draw::@73->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#47 [phi:frame_draw::@73->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $46 [phi:frame_draw::@73->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@74
    // y++;
    // [613] frame_draw::y#9 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz2 
    lda.z y_2
    inc
    sta.z y_3
    // [614] phi from frame_draw::@74 frame_draw::@83 to frame_draw::@22 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22]
    // [614] phi frame_draw::y#106 = frame_draw::y#9 [phi:frame_draw::@74/frame_draw::@83->frame_draw::@22#0] -- register_copy 
    // frame_draw::@22
  __b22:
    // for (; y < 59; y++)
    // [615] if(frame_draw::y#106<$3b) goto frame_draw::@23 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y_3
    cmp #$3b
    bcs !__b23+
    jmp __b23
  !__b23:
    // [616] phi from frame_draw::@22 to frame_draw::@24 [phi:frame_draw::@22->frame_draw::@24]
    // [616] phi frame_draw::x5#2 = 0 [phi:frame_draw::@22->frame_draw::@24#0] -- vbuz1=vbuc1 
    lda #0
    sta.z x5
    // frame_draw::@24
  __b24:
    // for (unsigned char x = 0; x < 79; x++)
    // [617] if(frame_draw::x5#2<$4f) goto frame_draw::@25 -- vbuz1_lt_vbuc1_then_la1 
    lda.z x5
    cmp #$4f
    bcs !__b25+
    jmp __b25
  !__b25:
    // frame_draw::@26
    // cputcxy(0, y, 0x6D)
    // [618] cputcxy::y#58 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [619] call cputcxy
    // [1203] phi from frame_draw::@26 to cputcxy [phi:frame_draw::@26->cputcxy]
    // [1203] phi cputcxy::c#68 = $6d [phi:frame_draw::@26->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#58 [phi:frame_draw::@26->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@26->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@85
    // cputcxy(79, y, 0x7D)
    // [620] cputcxy::y#59 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [621] call cputcxy
    // [1203] phi from frame_draw::@85 to cputcxy [phi:frame_draw::@85->cputcxy]
    // [1203] phi cputcxy::c#68 = $7d [phi:frame_draw::@85->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#59 [phi:frame_draw::@85->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@85->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@86
    // cputcxy(10, y, 0x71)
    // [622] cputcxy::y#60 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [623] call cputcxy
    // [1203] phi from frame_draw::@86 to cputcxy [phi:frame_draw::@86->cputcxy]
    // [1203] phi cputcxy::c#68 = $71 [phi:frame_draw::@86->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#60 [phi:frame_draw::@86->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $a [phi:frame_draw::@86->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@87
    // cputcxy(20, y, 0x71)
    // [624] cputcxy::y#61 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [625] call cputcxy
    // [1203] phi from frame_draw::@87 to cputcxy [phi:frame_draw::@87->cputcxy]
    // [1203] phi cputcxy::c#68 = $71 [phi:frame_draw::@87->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#61 [phi:frame_draw::@87->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $14 [phi:frame_draw::@87->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@88
    // cputcxy(30, y, 0x71)
    // [626] cputcxy::y#62 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [627] call cputcxy
    // [1203] phi from frame_draw::@88 to cputcxy [phi:frame_draw::@88->cputcxy]
    // [1203] phi cputcxy::c#68 = $71 [phi:frame_draw::@88->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#62 [phi:frame_draw::@88->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $1e [phi:frame_draw::@88->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@89
    // cputcxy(40, y, 0x71)
    // [628] cputcxy::y#63 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [629] call cputcxy
    // [1203] phi from frame_draw::@89 to cputcxy [phi:frame_draw::@89->cputcxy]
    // [1203] phi cputcxy::c#68 = $71 [phi:frame_draw::@89->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#63 [phi:frame_draw::@89->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $28 [phi:frame_draw::@89->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@90
    // cputcxy(50, y, 0x71)
    // [630] cputcxy::y#64 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [631] call cputcxy
    // [1203] phi from frame_draw::@90 to cputcxy [phi:frame_draw::@90->cputcxy]
    // [1203] phi cputcxy::c#68 = $71 [phi:frame_draw::@90->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#64 [phi:frame_draw::@90->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $32 [phi:frame_draw::@90->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@91
    // cputcxy(60, y, 0x71)
    // [632] cputcxy::y#65 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [633] call cputcxy
    // [1203] phi from frame_draw::@91 to cputcxy [phi:frame_draw::@91->cputcxy]
    // [1203] phi cputcxy::c#68 = $71 [phi:frame_draw::@91->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#65 [phi:frame_draw::@91->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $3c [phi:frame_draw::@91->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@92
    // cputcxy(70, y, 0x71)
    // [634] cputcxy::y#66 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [635] call cputcxy
    // [1203] phi from frame_draw::@92 to cputcxy [phi:frame_draw::@92->cputcxy]
    // [1203] phi cputcxy::c#68 = $71 [phi:frame_draw::@92->cputcxy#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#66 [phi:frame_draw::@92->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $46 [phi:frame_draw::@92->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@93
    // cputcxy(79, y, 0x7D)
    // [636] cputcxy::y#67 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [637] call cputcxy
    // [1203] phi from frame_draw::@93 to cputcxy [phi:frame_draw::@93->cputcxy]
    // [1203] phi cputcxy::c#68 = $7d [phi:frame_draw::@93->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#67 [phi:frame_draw::@93->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@93->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@return
    // }
    // [638] return 
    rts
    // frame_draw::@25
  __b25:
    // cputcxy(x, y, 0x40)
    // [639] cputcxy::x#57 = frame_draw::x5#2 -- vbuz1=vbuz2 
    lda.z x5
    sta.z cputcxy.x
    // [640] cputcxy::y#57 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [641] call cputcxy
    // [1203] phi from frame_draw::@25 to cputcxy [phi:frame_draw::@25->cputcxy]
    // [1203] phi cputcxy::c#68 = $40 [phi:frame_draw::@25->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#57 [phi:frame_draw::@25->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = cputcxy::x#57 [phi:frame_draw::@25->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@84
    // for (unsigned char x = 0; x < 79; x++)
    // [642] frame_draw::x5#1 = ++ frame_draw::x5#2 -- vbuz1=_inc_vbuz1 
    inc.z x5
    // [616] phi from frame_draw::@84 to frame_draw::@24 [phi:frame_draw::@84->frame_draw::@24]
    // [616] phi frame_draw::x5#2 = frame_draw::x5#1 [phi:frame_draw::@84->frame_draw::@24#0] -- register_copy 
    jmp __b24
    // frame_draw::@23
  __b23:
    // cputcxy(0, y, 0x5D)
    // [643] cputcxy::y#48 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [644] call cputcxy
    // [1203] phi from frame_draw::@23 to cputcxy [phi:frame_draw::@23->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@23->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#48 [phi:frame_draw::@23->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@23->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@75
    // cputcxy(79, y, 0x5D)
    // [645] cputcxy::y#49 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [646] call cputcxy
    // [1203] phi from frame_draw::@75 to cputcxy [phi:frame_draw::@75->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@75->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#49 [phi:frame_draw::@75->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@75->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@76
    // cputcxy(10, y, 0x5D)
    // [647] cputcxy::y#50 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [648] call cputcxy
    // [1203] phi from frame_draw::@76 to cputcxy [phi:frame_draw::@76->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@76->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#50 [phi:frame_draw::@76->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $a [phi:frame_draw::@76->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@77
    // cputcxy(20, y, 0x5D)
    // [649] cputcxy::y#51 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [650] call cputcxy
    // [1203] phi from frame_draw::@77 to cputcxy [phi:frame_draw::@77->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@77->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#51 [phi:frame_draw::@77->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $14 [phi:frame_draw::@77->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@78
    // cputcxy(30, y, 0x5D)
    // [651] cputcxy::y#52 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [652] call cputcxy
    // [1203] phi from frame_draw::@78 to cputcxy [phi:frame_draw::@78->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@78->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#52 [phi:frame_draw::@78->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $1e [phi:frame_draw::@78->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@79
    // cputcxy(40, y, 0x5D)
    // [653] cputcxy::y#53 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [654] call cputcxy
    // [1203] phi from frame_draw::@79 to cputcxy [phi:frame_draw::@79->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@79->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#53 [phi:frame_draw::@79->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $28 [phi:frame_draw::@79->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@80
    // cputcxy(50, y, 0x5D)
    // [655] cputcxy::y#54 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [656] call cputcxy
    // [1203] phi from frame_draw::@80 to cputcxy [phi:frame_draw::@80->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@80->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#54 [phi:frame_draw::@80->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $32 [phi:frame_draw::@80->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@81
    // cputcxy(60, y, 0x5D)
    // [657] cputcxy::y#55 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [658] call cputcxy
    // [1203] phi from frame_draw::@81 to cputcxy [phi:frame_draw::@81->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@81->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#55 [phi:frame_draw::@81->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $3c [phi:frame_draw::@81->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@82
    // cputcxy(70, y, 0x5D)
    // [659] cputcxy::y#56 = frame_draw::y#106 -- vbuz1=vbuz2 
    lda.z y_3
    sta.z cputcxy.y
    // [660] call cputcxy
    // [1203] phi from frame_draw::@82 to cputcxy [phi:frame_draw::@82->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@82->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#56 [phi:frame_draw::@82->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $46 [phi:frame_draw::@82->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@83
    // for (; y < 59; y++)
    // [661] frame_draw::y#10 = ++ frame_draw::y#106 -- vbuz1=_inc_vbuz1 
    inc.z y_3
    jmp __b22
    // frame_draw::@20
  __b20:
    // cputcxy(x, y, 0x40)
    // [662] cputcxy::x#38 = frame_draw::x4#2 -- vbuz1=vbuz2 
    lda.z x4
    sta.z cputcxy.x
    // [663] cputcxy::y#38 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [664] call cputcxy
    // [1203] phi from frame_draw::@20 to cputcxy [phi:frame_draw::@20->cputcxy]
    // [1203] phi cputcxy::c#68 = $40 [phi:frame_draw::@20->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#38 [phi:frame_draw::@20->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = cputcxy::x#38 [phi:frame_draw::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@65
    // for (unsigned char x = 0; x < 79; x++)
    // [665] frame_draw::x4#1 = ++ frame_draw::x4#2 -- vbuz1=_inc_vbuz1 
    inc.z x4
    // [593] phi from frame_draw::@65 to frame_draw::@19 [phi:frame_draw::@65->frame_draw::@19]
    // [593] phi frame_draw::x4#2 = frame_draw::x4#1 [phi:frame_draw::@65->frame_draw::@19#0] -- register_copy 
    jmp __b19
    // frame_draw::@18
  __b18:
    // cputcxy(0, y, 0x5D)
    // [666] cputcxy::y#29 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [667] call cputcxy
    // [1203] phi from frame_draw::@18 to cputcxy [phi:frame_draw::@18->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@18->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#29 [phi:frame_draw::@18->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@18->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@56
    // cputcxy(79, y, 0x5D)
    // [668] cputcxy::y#30 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [669] call cputcxy
    // [1203] phi from frame_draw::@56 to cputcxy [phi:frame_draw::@56->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@56->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#30 [phi:frame_draw::@56->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@56->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@57
    // cputcxy(10, y, 0x5D)
    // [670] cputcxy::y#31 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [671] call cputcxy
    // [1203] phi from frame_draw::@57 to cputcxy [phi:frame_draw::@57->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@57->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#31 [phi:frame_draw::@57->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $a [phi:frame_draw::@57->cputcxy#2] -- vbuz1=vbuc1 
    lda #$a
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@58
    // cputcxy(20, y, 0x5D)
    // [672] cputcxy::y#32 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [673] call cputcxy
    // [1203] phi from frame_draw::@58 to cputcxy [phi:frame_draw::@58->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@58->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#32 [phi:frame_draw::@58->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $14 [phi:frame_draw::@58->cputcxy#2] -- vbuz1=vbuc1 
    lda #$14
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@59
    // cputcxy(30, y, 0x5D)
    // [674] cputcxy::y#33 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [675] call cputcxy
    // [1203] phi from frame_draw::@59 to cputcxy [phi:frame_draw::@59->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@59->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#33 [phi:frame_draw::@59->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $1e [phi:frame_draw::@59->cputcxy#2] -- vbuz1=vbuc1 
    lda #$1e
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@60
    // cputcxy(40, y, 0x5D)
    // [676] cputcxy::y#34 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [677] call cputcxy
    // [1203] phi from frame_draw::@60 to cputcxy [phi:frame_draw::@60->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@60->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#34 [phi:frame_draw::@60->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $28 [phi:frame_draw::@60->cputcxy#2] -- vbuz1=vbuc1 
    lda #$28
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@61
    // cputcxy(50, y, 0x5D)
    // [678] cputcxy::y#35 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [679] call cputcxy
    // [1203] phi from frame_draw::@61 to cputcxy [phi:frame_draw::@61->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@61->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#35 [phi:frame_draw::@61->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $32 [phi:frame_draw::@61->cputcxy#2] -- vbuz1=vbuc1 
    lda #$32
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@62
    // cputcxy(60, y, 0x5D)
    // [680] cputcxy::y#36 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [681] call cputcxy
    // [1203] phi from frame_draw::@62 to cputcxy [phi:frame_draw::@62->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@62->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#36 [phi:frame_draw::@62->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $3c [phi:frame_draw::@62->cputcxy#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@63
    // cputcxy(70, y, 0x5D)
    // [682] cputcxy::y#37 = frame_draw::y#104 -- vbuz1=vbuz2 
    lda.z y_2
    sta.z cputcxy.y
    // [683] call cputcxy
    // [1203] phi from frame_draw::@63 to cputcxy [phi:frame_draw::@63->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@63->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#37 [phi:frame_draw::@63->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $46 [phi:frame_draw::@63->cputcxy#2] -- vbuz1=vbuc1 
    lda #$46
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@64
    // for (; y < 55; y++)
    // [684] frame_draw::y#8 = ++ frame_draw::y#104 -- vbuz1=_inc_vbuz1 
    inc.z y_2
    jmp __b17
    // frame_draw::@15
  __b15:
    // cputcxy(x, y, 0x40)
    // [685] cputcxy::x#18 = frame_draw::x3#2 -- vbuz1=vbuz2 
    lda.z x3
    sta.z cputcxy.x
    // [686] cputcxy::y#18 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [687] call cputcxy
    // [1203] phi from frame_draw::@15 to cputcxy [phi:frame_draw::@15->cputcxy]
    // [1203] phi cputcxy::c#68 = $40 [phi:frame_draw::@15->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#18 [phi:frame_draw::@15->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = cputcxy::x#18 [phi:frame_draw::@15->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@45
    // for (unsigned char x = 0; x < 79; x++)
    // [688] frame_draw::x3#1 = ++ frame_draw::x3#2 -- vbuz1=_inc_vbuz1 
    inc.z x3
    // [568] phi from frame_draw::@45 to frame_draw::@14 [phi:frame_draw::@45->frame_draw::@14]
    // [568] phi frame_draw::x3#2 = frame_draw::x3#1 [phi:frame_draw::@45->frame_draw::@14#0] -- register_copy 
    jmp __b14
    // frame_draw::@13
  __b13:
    // cputcxy(0, y, 0x5D)
    // [689] cputcxy::y#16 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [690] call cputcxy
    // [1203] phi from frame_draw::@13 to cputcxy [phi:frame_draw::@13->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@13->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#16 [phi:frame_draw::@13->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@13->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@43
    // cputcxy(79, y, 0x5D)
    // [691] cputcxy::y#17 = frame_draw::y#102 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [692] call cputcxy
    // [1203] phi from frame_draw::@43 to cputcxy [phi:frame_draw::@43->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@43->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#17 [phi:frame_draw::@43->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@43->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@44
    // for (; y < 41; y++)
    // [693] frame_draw::y#6 = ++ frame_draw::y#102 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b12
    // frame_draw::@10
  __b10:
    // cputcxy(x, y, 0x40)
    // [694] cputcxy::x#12 = frame_draw::x2#2 -- vbuz1=vbuz2 
    lda.z x2
    sta.z cputcxy.x
    // [695] cputcxy::y#12 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [696] call cputcxy
    // [1203] phi from frame_draw::@10 to cputcxy [phi:frame_draw::@10->cputcxy]
    // [1203] phi cputcxy::c#68 = $40 [phi:frame_draw::@10->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#12 [phi:frame_draw::@10->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = cputcxy::x#12 [phi:frame_draw::@10->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@39
    // for (unsigned char x = 0; x < 79; x++)
    // [697] frame_draw::x2#1 = ++ frame_draw::x2#2 -- vbuz1=_inc_vbuz1 
    inc.z x2
    // [557] phi from frame_draw::@39 to frame_draw::@9 [phi:frame_draw::@39->frame_draw::@9]
    // [557] phi frame_draw::x2#2 = frame_draw::x2#1 [phi:frame_draw::@39->frame_draw::@9#0] -- register_copy 
    jmp __b9
    // frame_draw::@8
  __b8:
    // cputcxy(0, y, 0x5D)
    // [698] cputcxy::y#9 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [699] call cputcxy
    // [1203] phi from frame_draw::@8 to cputcxy [phi:frame_draw::@8->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@8->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#9 [phi:frame_draw::@8->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = 0 [phi:frame_draw::@8->cputcxy#2] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@36
    // cputcxy(12, y, 0x5D)
    // [700] cputcxy::y#10 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [701] call cputcxy
    // [1203] phi from frame_draw::@36 to cputcxy [phi:frame_draw::@36->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@36->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#10 [phi:frame_draw::@36->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $c [phi:frame_draw::@36->cputcxy#2] -- vbuz1=vbuc1 
    lda #$c
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@37
    // cputcxy(79, y, 0x5D)
    // [702] cputcxy::y#11 = frame_draw::y#101 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [703] call cputcxy
    // [1203] phi from frame_draw::@37 to cputcxy [phi:frame_draw::@37->cputcxy]
    // [1203] phi cputcxy::c#68 = $5d [phi:frame_draw::@37->cputcxy#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = cputcxy::y#11 [phi:frame_draw::@37->cputcxy#1] -- register_copy 
    // [1203] phi cputcxy::x#68 = $4f [phi:frame_draw::@37->cputcxy#2] -- vbuz1=vbuc1 
    lda #$4f
    sta.z cputcxy.x
    jsr cputcxy
    // frame_draw::@38
    // for (; y < 37; y++)
    // [704] frame_draw::y#4 = ++ frame_draw::y#101 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [555] phi from frame_draw::@38 to frame_draw::@7 [phi:frame_draw::@38->frame_draw::@7]
    // [555] phi frame_draw::y#101 = frame_draw::y#4 [phi:frame_draw::@38->frame_draw::@7#0] -- register_copy 
    jmp __b7
    // frame_draw::@5
  __b5:
    // cputcxy(x, y, 0x40)
    // [705] cputcxy::x#5 = frame_draw::x1#2 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [706] call cputcxy
    // [1203] phi from frame_draw::@5 to cputcxy [phi:frame_draw::@5->cputcxy]
    // [1203] phi cputcxy::c#68 = $40 [phi:frame_draw::@5->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 2 [phi:frame_draw::@5->cputcxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = cputcxy::x#5 [phi:frame_draw::@5->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@33
    // for (unsigned char x = 0; x < 79; x++)
    // [707] frame_draw::x1#1 = ++ frame_draw::x1#2 -- vbuz1=_inc_vbuz1 
    inc.z x1
    // [547] phi from frame_draw::@33 to frame_draw::@4 [phi:frame_draw::@33->frame_draw::@4]
    // [547] phi frame_draw::x1#2 = frame_draw::x1#1 [phi:frame_draw::@33->frame_draw::@4#0] -- register_copy 
    jmp __b4
    // frame_draw::@2
  __b2:
    // cputcxy(x, y, 0x40)
    // [708] cputcxy::x#0 = frame_draw::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [709] call cputcxy
    // [1203] phi from frame_draw::@2 to cputcxy [phi:frame_draw::@2->cputcxy]
    // [1203] phi cputcxy::c#68 = $40 [phi:frame_draw::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z cputcxy.c
    // [1203] phi cputcxy::y#68 = 0 [phi:frame_draw::@2->cputcxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z cputcxy.y
    // [1203] phi cputcxy::x#68 = cputcxy::x#0 [phi:frame_draw::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame_draw::@29
    // for (unsigned char x = 0; x < 79; x++)
    // [710] frame_draw::x#1 = ++ frame_draw::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [537] phi from frame_draw::@29 to frame_draw::@1 [phi:frame_draw::@29->frame_draw::@1]
    // [537] phi frame_draw::x#2 = frame_draw::x#1 [phi:frame_draw::@29->frame_draw::@1#0] -- register_copy 
    jmp __b1
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($39) void (*putc)(char), __zp($3e) const char *s)
printf_str: {
    .label c = $42
    .label s = $3e
    .label putc = $39
    // [712] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [712] phi printf_str::s#31 = printf_str::s#32 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [713] printf_str::c#1 = *printf_str::s#31 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [714] printf_str::s#0 = ++ printf_str::s#31 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [715] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [716] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [717] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [718] callexecute *printf_str::putc#32  -- call__deref_pprz1 
    jsr icall1
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall1:
    jmp (putc)
}
  // print_chips
print_chips: {
    .label print_chips__4 = $b8
    .label r = $4a
    .label print_chips__33 = $b8
    .label print_chips__34 = $b8
    // [721] phi from print_chips to print_chips::@1 [phi:print_chips->print_chips::@1]
    // [721] phi print_chips::r#10 = 0 [phi:print_chips->print_chips::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // print_chips::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [722] if(print_chips::r#10<8) goto print_chips::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // print_chips::@return
    // }
    // [723] return 
    rts
    // print_chips::@2
  __b2:
    // r * 10
    // [724] print_chips::$33 = print_chips::r#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z r
    asl
    asl
    sta.z print_chips__33
    // [725] print_chips::$34 = print_chips::$33 + print_chips::r#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z print_chips__34
    clc
    adc.z r
    sta.z print_chips__34
    // [726] print_chips::$4 = print_chips::$34 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_chips__4
    // print_chip_line(3 + r * 10, 45, ' ')
    // [727] print_chip_line::x#0 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [728] call print_chip_line
    // [1211] phi from print_chips::@2 to print_chip_line [phi:print_chips::@2->print_chip_line]
    // [1211] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@2->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1211] phi print_chip_line::y#12 = $2d [phi:print_chips::@2->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2d
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#0 [phi:print_chips::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@3
    // print_chip_line(3 + r * 10, 46, 'r')
    // [729] print_chip_line::x#1 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [730] call print_chip_line
    // [1211] phi from print_chips::@3 to print_chip_line [phi:print_chips::@3->print_chip_line]
    // [1211] phi print_chip_line::c#12 = 'r'pm [phi:print_chips::@3->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'r'
    sta.z print_chip_line.c
    // [1211] phi print_chip_line::y#12 = $2e [phi:print_chips::@3->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2e
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#1 [phi:print_chips::@3->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@4
    // print_chip_line(3 + r * 10, 47, 'o')
    // [731] print_chip_line::x#2 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [732] call print_chip_line
    // [1211] phi from print_chips::@4 to print_chip_line [phi:print_chips::@4->print_chip_line]
    // [1211] phi print_chip_line::c#12 = 'o'pm [phi:print_chips::@4->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'o'
    sta.z print_chip_line.c
    // [1211] phi print_chip_line::y#12 = $2f [phi:print_chips::@4->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$2f
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#2 [phi:print_chips::@4->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@5
    // print_chip_line(3 + r * 10, 48, 'm')
    // [733] print_chip_line::x#3 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [734] call print_chip_line
    // [1211] phi from print_chips::@5 to print_chip_line [phi:print_chips::@5->print_chip_line]
    // [1211] phi print_chip_line::c#12 = 'm'pm [phi:print_chips::@5->print_chip_line#0] -- vbuz1=vbuc1 
    lda #'m'
    sta.z print_chip_line.c
    // [1211] phi print_chip_line::y#12 = $30 [phi:print_chips::@5->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$30
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#3 [phi:print_chips::@5->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@6
    // print_chip_line(3 + r * 10, 49, '0' + r)
    // [735] print_chip_line::x#4 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [736] print_chip_line::c#4 = '0'pm + print_chips::r#10 -- vbuz1=vbuc1_plus_vbuz2 
    lda #'0'
    clc
    adc.z r
    sta.z print_chip_line.c
    // [737] call print_chip_line
    // [1211] phi from print_chips::@6 to print_chip_line [phi:print_chips::@6->print_chip_line]
    // [1211] phi print_chip_line::c#12 = print_chip_line::c#4 [phi:print_chips::@6->print_chip_line#0] -- register_copy 
    // [1211] phi print_chip_line::y#12 = $31 [phi:print_chips::@6->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#4 [phi:print_chips::@6->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@7
    // print_chip_line(3 + r * 10, 50, ' ')
    // [738] print_chip_line::x#5 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [739] call print_chip_line
    // [1211] phi from print_chips::@7 to print_chip_line [phi:print_chips::@7->print_chip_line]
    // [1211] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@7->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1211] phi print_chip_line::y#12 = $32 [phi:print_chips::@7->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$32
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#5 [phi:print_chips::@7->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@8
    // print_chip_line(3 + r * 10, 51, ' ')
    // [740] print_chip_line::x#6 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [741] call print_chip_line
    // [1211] phi from print_chips::@8 to print_chip_line [phi:print_chips::@8->print_chip_line]
    // [1211] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@8->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1211] phi print_chip_line::y#12 = $33 [phi:print_chips::@8->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$33
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#6 [phi:print_chips::@8->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@9
    // print_chip_line(3 + r * 10, 52, ' ')
    // [742] print_chip_line::x#7 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [743] call print_chip_line
    // [1211] phi from print_chips::@9 to print_chip_line [phi:print_chips::@9->print_chip_line]
    // [1211] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@9->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1211] phi print_chip_line::y#12 = $34 [phi:print_chips::@9->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$34
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#7 [phi:print_chips::@9->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@10
    // print_chip_line(3 + r * 10, 53, ' ')
    // [744] print_chip_line::x#8 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chips__4
    sta.z print_chip_line.x
    // [745] call print_chip_line
    // [1211] phi from print_chips::@10 to print_chip_line [phi:print_chips::@10->print_chip_line]
    // [1211] phi print_chip_line::c#12 = ' 'pm [phi:print_chips::@10->print_chip_line#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z print_chip_line.c
    // [1211] phi print_chip_line::y#12 = $35 [phi:print_chips::@10->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$35
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#8 [phi:print_chips::@10->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chips::@11
    // print_chip_end(3 + r * 10, 54)
    // [746] print_chip_end::x#0 = 3 + print_chips::$4 -- vbuz1=vbuc1_plus_vbuz1 
    lda #3
    clc
    adc.z print_chip_end.x
    sta.z print_chip_end.x
    // [747] call print_chip_end
    jsr print_chip_end
    // print_chips::@12
    // print_chip_led(r, BLACK, BLUE)
    // [748] print_chip_led::r#0 = print_chips::r#10 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_chip_led.r
    // [749] call print_chip_led
    // [908] phi from print_chips::@12 to print_chip_led [phi:print_chips::@12->print_chip_led]
    // [908] phi print_chip_led::tc#10 = BLACK [phi:print_chips::@12->print_chip_led#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z print_chip_led.tc
    // [908] phi print_chip_led::r#10 = print_chip_led::r#0 [phi:print_chips::@12->print_chip_led#1] -- register_copy 
    jsr print_chip_led
    // print_chips::@13
    // for (unsigned char r = 0; r < 8; r++)
    // [750] print_chips::r#1 = ++ print_chips::r#10 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [721] phi from print_chips::@13 to print_chips::@1 [phi:print_chips::@13->print_chips::@1]
    // [721] phi print_chips::r#10 = print_chips::r#1 [phi:print_chips::@13->print_chips::@1#0] -- register_copy 
    jmp __b1
}
  // info_line_clear
info_line_clear: {
    // textcolor(WHITE)
    // [752] call textcolor
    // [467] phi from info_line_clear to textcolor [phi:info_line_clear->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:info_line_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [753] phi from info_line_clear to info_line_clear::@1 [phi:info_line_clear->info_line_clear::@1]
    // info_line_clear::@1
    // gotoxy(2, 39)
    // [754] call gotoxy
    // [485] phi from info_line_clear::@1 to gotoxy [phi:info_line_clear::@1->gotoxy]
    // [485] phi gotoxy::y#25 = $27 [phi:info_line_clear::@1->gotoxy#0] -- vbuz1=vbuc1 
    lda #$27
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = 2 [phi:info_line_clear::@1->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [755] phi from info_line_clear::@1 to info_line_clear::@2 [phi:info_line_clear::@1->info_line_clear::@2]
    // info_line_clear::@2
    // printf("%76s", " ")
    // [756] call printf_string
    // [760] phi from info_line_clear::@2 to printf_string [phi:info_line_clear::@2->printf_string]
    // [760] phi printf_string::str#10 = str [phi:info_line_clear::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [760] phi printf_string::format_min_length#10 = $4c [phi:info_line_clear::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #$4c
    sta.z printf_string.format_min_length
    jsr printf_string
    // [757] phi from info_line_clear::@2 to info_line_clear::@3 [phi:info_line_clear::@2->info_line_clear::@3]
    // info_line_clear::@3
    // gotoxy(2, 39)
    // [758] call gotoxy
    // [485] phi from info_line_clear::@3 to gotoxy [phi:info_line_clear::@3->gotoxy]
    // [485] phi gotoxy::y#25 = $27 [phi:info_line_clear::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #$27
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = 2 [phi:info_line_clear::@3->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_line_clear::@return
    // }
    // [759] return 
    rts
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($3e) char *str, __zp($4e) char format_min_length, char format_justify_left)
printf_string: {
    .label printf_string__9 = $40
    .label len = $38
    .label padding = $4e
    .label str = $3e
    .label format_min_length = $4e
    // if(format.min_length)
    // [761] if(0==printf_string::format_min_length#10) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b1
    // printf_string::@3
    // strlen(str)
    // [762] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [763] call strlen
    // [811] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [811] phi strlen::str#9 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [764] strlen::return#11 = strlen::len#2
    // printf_string::@5
    // [765] printf_string::$9 = strlen::return#11
    // signed char len = (signed char)strlen(str)
    // [766] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [767] printf_string::padding#1 = (signed char)printf_string::format_min_length#10 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [768] if(printf_string::padding#1>=0) goto printf_string::@7 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b6
    // [770] phi from printf_string printf_string::@5 to printf_string::@1 [phi:printf_string/printf_string::@5->printf_string::@1]
  __b1:
    // [770] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@5->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [769] phi from printf_string::@5 to printf_string::@7 [phi:printf_string::@5->printf_string::@7]
    // printf_string::@7
    // [770] phi from printf_string::@7 to printf_string::@1 [phi:printf_string::@7->printf_string::@1]
    // [770] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@7->printf_string::@1#0] -- register_copy 
    // printf_string::@1
    // printf_string::@6
  __b6:
    // if(!format.justify_left && padding)
    // [771] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [772] printf_padding::length#3 = (char)printf_string::padding#3
    // [773] call printf_padding
    // [1269] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1269] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1269] phi printf_padding::pad#7 = ' 'pm [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1269] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [774] printf_str::s#2 = printf_string::str#10
    // [775] call printf_str
    // [711] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@return
    // }
    // [776] return 
    rts
}
  // wait_key
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label kbhit1_return = $b8
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [778] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [779] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [780] phi from wait_key::@1 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@1/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [782] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [783] call cbm_k_getin
    jsr cbm_k_getin
    // [784] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@2
    // [785] wait_key::kbhit1_return#0 = cbm_k_getin::return#2
    // wait_key::@1
    // while (!(ch = kbhit()))
    // [786] if(0==wait_key::kbhit1_return#0) goto wait_key::kbhit1 -- 0_eq_vbuz1_then_la1 
    lda.z kbhit1_return
    beq kbhit1
    // wait_key::@return
    // }
    // [787] return 
    rts
}
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [789] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [790] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@1
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [792] return 
}
  // printf_sint
// Print a signed integer using a specific format
// void printf_sint(void (*putc)(char), __zp($28) int value, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_sint: {
    .const format_min_length = 0
    .const format_justify_left = 0
    .const format_zero_padding = 0
    .const format_upper_case = 0
    .label putc = cputc
    .label value = $28
    // printf_buffer.sign = 0
    // [793] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // if(value<0)
    // [794] if(printf_sint::value#1<0) goto printf_sint::@1 -- vwsz1_lt_0_then_la1 
    lda.z value+1
    bmi __b1
    // [797] phi from printf_sint printf_sint::@1 to printf_sint::@2 [phi:printf_sint/printf_sint::@1->printf_sint::@2]
    // [797] phi printf_sint::value#4 = printf_sint::value#1 [phi:printf_sint/printf_sint::@1->printf_sint::@2#0] -- register_copy 
    jmp __b2
    // printf_sint::@1
  __b1:
    // value = -value
    // [795] printf_sint::value#0 = - printf_sint::value#1 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z value
    sta.z value
    lda #0
    sbc.z value+1
    sta.z value+1
    // printf_buffer.sign = '-'
    // [796] *((char *)&printf_buffer) = '-'pm -- _deref_pbuc1=vbuc2 
    lda #'-'
    sta printf_buffer
    // printf_sint::@2
  __b2:
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [798] utoa::value#1 = (unsigned int)printf_sint::value#4
    // [799] call utoa
    // [1282] phi from printf_sint::@2 to utoa [phi:printf_sint::@2->utoa]
    // [1282] phi utoa::value#10 = utoa::value#1 [phi:printf_sint::@2->utoa#0] -- register_copy 
    // [1282] phi utoa::radix#2 = DECIMAL [phi:printf_sint::@2->utoa#1] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z utoa.radix
    jsr utoa
    // printf_sint::@3
    // printf_number_buffer(putc, printf_buffer, format)
    // [800] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [801] call printf_number_buffer
  // Print using format
    // [1313] phi from printf_sint::@3 to printf_number_buffer [phi:printf_sint::@3->printf_number_buffer]
    // [1313] phi printf_number_buffer::format_upper_case#10 = printf_sint::format_upper_case#0 [phi:printf_sint::@3->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #format_upper_case
    sta.z printf_number_buffer.format_upper_case
    // [1313] phi printf_number_buffer::putc#10 = printf_sint::putc#0 [phi:printf_sint::@3->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [1313] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_sint::@3->printf_number_buffer#2] -- register_copy 
    // [1313] phi printf_number_buffer::format_zero_padding#10 = printf_sint::format_zero_padding#0 [phi:printf_sint::@3->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #format_zero_padding
    sta.z printf_number_buffer.format_zero_padding
    // [1313] phi printf_number_buffer::format_justify_left#10 = printf_sint::format_justify_left#0 [phi:printf_sint::@3->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #format_justify_left
    sta.z printf_number_buffer.format_justify_left
    // [1313] phi printf_number_buffer::format_min_length#4 = printf_sint::format_min_length#0 [phi:printf_sint::@3->printf_number_buffer#5] -- vbuz1=vbuc1 
    lda #format_min_length
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_sint::@return
    // }
    // [802] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label dst = $39
    .label src = $28
    // [804] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [804] phi strcpy::dst#2 = file [phi:strcpy->strcpy::@1#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z dst
    lda #>file
    sta.z dst+1
    // [804] phi strcpy::src#2 = main::source [phi:strcpy->strcpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.source
    sta.z src
    lda #>main.source
    sta.z src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [805] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [806] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [807] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [808] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [809] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [810] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [804] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [804] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [804] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($40) unsigned int strlen(__zp($39) char *str)
strlen: {
    .label return = $40
    .label len = $40
    .label str = $39
    // [812] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [812] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [812] phi strlen::str#7 = strlen::str#9 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [813] if(0!=*strlen::str#7) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [814] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [815] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [816] strlen::str#1 = ++ strlen::str#7 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [812] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [812] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [812] phi strlen::str#7 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, char *source)
strcat: {
    .label strcat__0 = $40
    .label dst = $40
    .label src = $28
    // strlen(destination)
    // [818] call strlen
    // [811] phi from strcat to strlen [phi:strcat->strlen]
    // [811] phi strlen::str#9 = file [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strlen.str
    lda #>file
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [819] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [820] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [821] strcat::dst#0 = file + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<file
    sta.z dst
    lda.z dst+1
    adc #>file
    sta.z dst+1
    // [822] phi from strcat::@4 to strcat::@1 [phi:strcat::@4->strcat::@1]
    // [822] phi strcat::dst#2 = strcat::dst#0 [phi:strcat::@4->strcat::@1#0] -- register_copy 
    // [822] phi strcat::src#2 = main::source1 [phi:strcat::@4->strcat::@1#1] -- pbuz1=pbuc1 
    lda #<main.source1
    sta.z src
    lda #>main.source1
    sta.z src+1
    // strcat::@1
  __b1:
    // while(*src)
    // [823] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [824] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [825] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [826] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [827] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [828] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [822] phi from strcat::@2 to strcat::@1 [phi:strcat::@2->strcat::@1]
    // [822] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2->strcat::@1#0] -- register_copy 
    // [822] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2->strcat::@1#1] -- register_copy 
    jmp __b1
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
// __zp($6b) struct $2 * fopen(__zp($39) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $3b
    .label fopen__9 = $4b
    .label fopen__11 = $43
    .label fopen__15 = $b2
    .label fopen__16 = $ac
    .label fopen__26 = $45
    .label fopen__28 = $48
    .label fopen__30 = $6b
    .label cbm_k_setnam1_fopen__0 = $40
    .label sp = $b8
    .label stream = $6b
    .label pathpos = $38
    .label pathpos_1 = $5a
    .label pathtoken = $28
    .label pathcmp = $42
    .label path = $39
    // Parse path
    .label pathstep = $32
    .label num = $22
    .label cbm_k_readst1_return = $b2
    .label return = $6b
    // unsigned char sp = __stdio_filecount
    // [829] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [830] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [831] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [832] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z sp
    asl
    sta.z pathpos
    // __logical = 0
    // [833] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [834] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [835] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // [836] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [837] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [837] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z num
    // [837] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [837] phi fopen::path#13 = file [phi:fopen->fopen::@8#2] -- pbuz1=pbuc1 
    lda #<file
    sta.z path
    lda #>file
    sta.z path+1
    // [837] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    lda #0
    sta.z pathstep
    // [837] phi fopen::pathtoken#10 = file [phi:fopen->fopen::@8#4] -- pbuz1=pbuc1 
    lda #<file
    sta.z pathtoken
    lda #>file
    sta.z pathtoken+1
  // Iterate while path is not \0.
    // [837] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [837] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [837] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [837] phi fopen::path#13 = fopen::path#10 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [837] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [837] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [838] if(*fopen::pathtoken#10==','pm) goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [839] if(*fopen::pathtoken#10=='?'pm) goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'\$00'
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [840] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [841] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbuz2 
    lda (pathtoken),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [842] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [843] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [843] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [843] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [843] phi fopen::path#10 = fopen::path#12 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [843] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [844] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken
    bne !+
    inc.z pathtoken+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [845] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [846] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [847] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [848] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [849] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [850] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [851] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [852] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [853] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [854] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [855] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [856] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [857] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbuz2 
    lda.z fopen__11
    sta cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [858] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [859] call strlen
    // [811] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [811] phi strlen::str#9 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [860] strlen::return#12 = strlen::len#2
    // fopen::@31
    // [861] fopen::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [862] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [864] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [865] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$42,y
    sta.z cbm_k_setlfs.device
    // [866] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$44,y
    sta.z cbm_k_setlfs.command
    // [867] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [869] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [871] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [872] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [873] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [874] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [875] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [876] call ferror
    jsr ferror
    // [877] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [878] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [879] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [880] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [882] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [882] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [883] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [884] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [885] fopen::return#6 = (struct $2 *)fopen::stream#0
    // [882] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [882] phi fopen::return#2 = fopen::return#6 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [886] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [887] ((char *)&__stdio_file)[fopen::pathpos#10] = '?'pm -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'\$00'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [888] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    // [889] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [889] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [889] phi fopen::path#12 = fopen::path#15 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [890] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [891] fopen::pathcmp#0 = *fopen::path#13 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [892] if(fopen::pathcmp#0=='D'pm) goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [893] if(fopen::pathcmp#0=='L'pm) goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [894] if(fopen::pathcmp#0=='C'pm) goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [895] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [895] phi fopen::path#15 = fopen::path#13 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [895] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [896] if(fopen::pathcmp#0=='L'pm) goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [897] if(fopen::pathcmp#0=='D'pm) goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [898] if(fopen::pathcmp#0!='C'pm) goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [899] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [900] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [901] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [902] atoi::str#0 = fopen::path#13 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [903] call atoi
    // [1408] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [1408] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [904] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [905] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [906] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [907] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
}
.segment Code
  // print_chip_led
// void print_chip_led(__zp($47) char r, __zp($33) char tc, char bc)
print_chip_led: {
    .label print_chip_led__0 = $47
    .label r = $47
    .label tc = $33
    .label print_chip_led__8 = $38
    .label print_chip_led__9 = $47
    // r * 10
    // [909] print_chip_led::$8 = print_chip_led::r#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z r
    asl
    asl
    sta.z print_chip_led__8
    // [910] print_chip_led::$9 = print_chip_led::$8 + print_chip_led::r#10 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z print_chip_led__9
    clc
    adc.z print_chip_led__8
    sta.z print_chip_led__9
    // [911] print_chip_led::$0 = print_chip_led::$9 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_chip_led__0
    // gotoxy(4 + r * 10, 43)
    // [912] gotoxy::x#6 = 4 + print_chip_led::$0 -- vbuz1=vbuc1_plus_vbuz2 
    lda #4
    clc
    adc.z print_chip_led__0
    sta.z gotoxy.x
    // [913] call gotoxy
    // [485] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [485] phi gotoxy::y#25 = $2b [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #$2b
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = gotoxy::x#6 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@1
    // textcolor(tc)
    // [914] textcolor::color#8 = print_chip_led::tc#10 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [915] call textcolor
    // [467] phi from print_chip_led::@1 to textcolor [phi:print_chip_led::@1->textcolor]
    // [467] phi textcolor::color#23 = textcolor::color#8 [phi:print_chip_led::@1->textcolor#0] -- register_copy 
    jsr textcolor
    // [916] phi from print_chip_led::@1 to print_chip_led::@2 [phi:print_chip_led::@1->print_chip_led::@2]
    // print_chip_led::@2
    // bgcolor(bc)
    // [917] call bgcolor
    // [472] phi from print_chip_led::@2 to bgcolor [phi:print_chip_led::@2->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:print_chip_led::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@3
    // cputc(VERA_REV_SPACE)
    // [918] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [919] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [921] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [922] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [924] stackpush(char) = $a0 -- _stackpushbyte_=vbuc1 
    lda #$a0
    pha
    // [925] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_led::@return
    // }
    // [927] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(void (*putc)(char), __zp($27) char uvalue, __zp($2a) char format_min_length, char format_justify_left, char format_sign_always, __zp($7f) char format_zero_padding, char format_upper_case, __zp($55) char format_radix)
printf_uchar: {
    .label uvalue = $27
    .label format_radix = $55
    .label format_min_length = $2a
    .label format_zero_padding = $7f
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [929] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [930] uctoa::value#1 = printf_uchar::uvalue#11
    // [931] uctoa::radix#0 = printf_uchar::format_radix#11
    // [932] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [933] printf_number_buffer::buffer_sign#3 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [934] printf_number_buffer::format_min_length#3 = printf_uchar::format_min_length#11
    // [935] printf_number_buffer::format_zero_padding#3 = printf_uchar::format_zero_padding#11
    // [936] call printf_number_buffer
  // Print using format
    // [1313] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1313] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1313] phi printf_number_buffer::putc#10 = &cputc [phi:printf_uchar::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1313] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#3 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1313] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#3 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [1313] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_justify_left
    // [1313] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#3 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [937] return 
    rts
}
  // table_chip_clear
// void table_chip_clear(__zp($ca) char rom_bank)
table_chip_clear: {
    .label flash_rom_address = $b4
    .label rom_bank = $ca
    .label y = $6a
    // textcolor(WHITE)
    // [939] call textcolor
    // [467] phi from table_chip_clear to textcolor [phi:table_chip_clear->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:table_chip_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [940] phi from table_chip_clear to table_chip_clear::@3 [phi:table_chip_clear->table_chip_clear::@3]
    // table_chip_clear::@3
    // bgcolor(BLUE)
    // [941] call bgcolor
    // [472] phi from table_chip_clear::@3 to bgcolor [phi:table_chip_clear::@3->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:table_chip_clear::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [942] phi from table_chip_clear::@3 to table_chip_clear::@1 [phi:table_chip_clear::@3->table_chip_clear::@1]
    // [942] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#1 [phi:table_chip_clear::@3->table_chip_clear::@1#0] -- register_copy 
    // [942] phi table_chip_clear::y#10 = 4 [phi:table_chip_clear::@3->table_chip_clear::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z y
    // table_chip_clear::@1
  __b1:
    // for (unsigned char y = 4; y < 36; y++)
    // [943] if(table_chip_clear::y#10<$24) goto table_chip_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #$24
    bcc __b2
    // table_chip_clear::@return
    // }
    // [944] return 
    rts
    // table_chip_clear::@2
  __b2:
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [945] rom_address::rom_bank#1 = table_chip_clear::rom_bank#11 -- vbuz1=vbuz2 
    lda.z rom_bank
    sta.z rom_address.rom_bank
    // [946] call rom_address
    // [963] phi from table_chip_clear::@2 to rom_address [phi:table_chip_clear::@2->rom_address]
    // [963] phi rom_address::rom_bank#5 = rom_address::rom_bank#1 [phi:table_chip_clear::@2->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank)
    // [947] rom_address::return#3 = rom_address::return#0
    // table_chip_clear::@4
    // [948] table_chip_clear::flash_rom_address#0 = rom_address::return#3
    // gotoxy(2, y)
    // [949] gotoxy::y#9 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [950] call gotoxy
    // [485] phi from table_chip_clear::@4 to gotoxy [phi:table_chip_clear::@4->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#9 [phi:table_chip_clear::@4->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = 2 [phi:table_chip_clear::@4->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // table_chip_clear::@5
    // printf("%02x", rom_bank)
    // [951] printf_uchar::uvalue#2 = table_chip_clear::rom_bank#11 -- vbuz1=vbuz2 
    lda.z rom_bank
    sta.z printf_uchar.uvalue
    // [952] call printf_uchar
    // [928] phi from table_chip_clear::@5 to printf_uchar [phi:table_chip_clear::@5->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 1 [phi:table_chip_clear::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 2 [phi:table_chip_clear::@5->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:table_chip_clear::@5->printf_uchar#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#2 [phi:table_chip_clear::@5->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // table_chip_clear::@6
    // gotoxy(5, y)
    // [953] gotoxy::y#10 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [954] call gotoxy
    // [485] phi from table_chip_clear::@6 to gotoxy [phi:table_chip_clear::@6->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#10 [phi:table_chip_clear::@6->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = 5 [phi:table_chip_clear::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #5
    sta.z gotoxy.x
    jsr gotoxy
    // table_chip_clear::@7
    // printf("%06x", flash_rom_address)
    // [955] printf_ulong::uvalue#1 = table_chip_clear::flash_rom_address#0 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z printf_ulong.uvalue
    lda.z flash_rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z flash_rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z flash_rom_address+3
    sta.z printf_ulong.uvalue+3
    // [956] call printf_ulong
    // [1452] phi from table_chip_clear::@7 to printf_ulong [phi:table_chip_clear::@7->printf_ulong]
    // [1452] phi printf_ulong::format_zero_padding#2 = 1 [phi:table_chip_clear::@7->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1452] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:table_chip_clear::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // table_chip_clear::@8
    // gotoxy(14, y)
    // [957] gotoxy::y#11 = table_chip_clear::y#10 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [958] call gotoxy
    // [485] phi from table_chip_clear::@8 to gotoxy [phi:table_chip_clear::@8->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#11 [phi:table_chip_clear::@8->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = $e [phi:table_chip_clear::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // [959] phi from table_chip_clear::@8 to table_chip_clear::@9 [phi:table_chip_clear::@8->table_chip_clear::@9]
    // table_chip_clear::@9
    // printf("%64s", " ")
    // [960] call printf_string
    // [760] phi from table_chip_clear::@9 to printf_string [phi:table_chip_clear::@9->printf_string]
    // [760] phi printf_string::str#10 = str [phi:table_chip_clear::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [760] phi printf_string::format_min_length#10 = $40 [phi:table_chip_clear::@9->printf_string#1] -- vbuz1=vbuc1 
    lda #$40
    sta.z printf_string.format_min_length
    jsr printf_string
    // table_chip_clear::@10
    // rom_bank++;
    // [961] table_chip_clear::rom_bank#0 = ++ table_chip_clear::rom_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank
    // for (unsigned char y = 4; y < 36; y++)
    // [962] table_chip_clear::y#1 = ++ table_chip_clear::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [942] phi from table_chip_clear::@10 to table_chip_clear::@1 [phi:table_chip_clear::@10->table_chip_clear::@1]
    // [942] phi table_chip_clear::rom_bank#11 = table_chip_clear::rom_bank#0 [phi:table_chip_clear::@10->table_chip_clear::@1#0] -- register_copy 
    // [942] phi table_chip_clear::y#10 = table_chip_clear::y#1 [phi:table_chip_clear::@10->table_chip_clear::@1#1] -- register_copy 
    jmp __b1
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
// __zp($e5) unsigned long rom_address(__zp($4a) char rom_bank)
rom_address: {
    .label rom_address__1 = $b4
    .label return = $b4
    .label rom_bank = $4a
    .label return_1 = $66
    .label return_2 = $56
    .label return_3 = $eb
    .label return_4 = $e5
    // ((unsigned long)(rom_bank)) << 14
    // [964] rom_address::$1 = (unsigned long)rom_address::rom_bank#5 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address__1
    lda #0
    sta.z rom_address__1+1
    sta.z rom_address__1+2
    sta.z rom_address__1+3
    // [965] rom_address::return#0 = rom_address::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [966] return 
    rts
}
  // flash_read
// __zp($62) unsigned long flash_read(__zp($39) struct $2 *fp, __zp($6b) char *flash_ram_address, __zp($54) char rom_bank_start, __zp($ce) unsigned long read_size)
flash_read: {
    .label flash_read__3 = $b4
    .label flash_read__6 = $3b
    .label flash_read__12 = $70
    .label flash_rom_address = $66
    .label read_bytes = $3c
    .label rom_bank_start = $54
    .label return = $62
    .label flash_ram_address = $6b
    .label flash_bytes = $62
    .label fp = $39
    .label read_size = $ce
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [968] rom_address::rom_bank#0 = flash_read::rom_bank_start#11 -- vbuz1=vbuz2 
    lda.z rom_bank_start
    sta.z rom_address.rom_bank
    // [969] call rom_address
    // [963] phi from flash_read to rom_address [phi:flash_read->rom_address]
    // [963] phi rom_address::rom_bank#5 = rom_address::rom_bank#0 [phi:flash_read->rom_address#0] -- register_copy 
    jsr rom_address
    // unsigned long flash_rom_address = rom_address(rom_bank_start)
    // [970] rom_address::return#2 = rom_address::return#0 -- vduz1=vduz2 
    lda.z rom_address.return
    sta.z rom_address.return_1
    lda.z rom_address.return+1
    sta.z rom_address.return_1+1
    lda.z rom_address.return+2
    sta.z rom_address.return_1+2
    lda.z rom_address.return+3
    sta.z rom_address.return_1+3
    // flash_read::@9
    // [971] flash_read::flash_rom_address#0 = rom_address::return#2
    // textcolor(WHITE)
    // [972] call textcolor
  /// Holds the amount of bytes actually read in the memory to be flashed.
    // [467] phi from flash_read::@9 to textcolor [phi:flash_read::@9->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:flash_read::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [973] phi from flash_read::@9 to flash_read::@1 [phi:flash_read::@9->flash_read::@1]
    // [973] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#11 [phi:flash_read::@9->flash_read::@1#0] -- register_copy 
    // [973] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#14 [phi:flash_read::@9->flash_read::@1#1] -- register_copy 
    // [973] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#0 [phi:flash_read::@9->flash_read::@1#2] -- register_copy 
    // [973] phi flash_read::return#2 = 0 [phi:flash_read::@9->flash_read::@1#3] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // [973] phi from flash_read::@5 flash_read::@8 to flash_read::@1 [phi:flash_read::@5/flash_read::@8->flash_read::@1]
    // [973] phi flash_read::rom_bank_start#4 = flash_read::rom_bank_start#10 [phi:flash_read::@5/flash_read::@8->flash_read::@1#0] -- register_copy 
    // [973] phi flash_read::flash_ram_address#10 = flash_read::flash_ram_address#0 [phi:flash_read::@5/flash_read::@8->flash_read::@1#1] -- register_copy 
    // [973] phi flash_read::flash_rom_address#10 = flash_read::flash_rom_address#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#2] -- register_copy 
    // [973] phi flash_read::return#2 = flash_read::flash_bytes#1 [phi:flash_read::@5/flash_read::@8->flash_read::@1#3] -- register_copy 
    // flash_read::@1
  __b1:
    // while (flash_bytes < read_size)
    // [974] if(flash_read::return#2<flash_read::read_size#4) goto flash_read::@2 -- vduz1_lt_vduz2_then_la1 
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
    // [975] return 
    rts
    // flash_read::@2
  __b2:
    // flash_rom_address % 0x04000
    // [976] flash_read::$3 = flash_read::flash_rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address
    and #<$4000-1
    sta.z flash_read__3
    lda.z flash_rom_address+1
    and #>$4000-1
    sta.z flash_read__3+1
    lda.z flash_rom_address+2
    and #<$4000-1>>$10
    sta.z flash_read__3+2
    lda.z flash_rom_address+3
    and #>$4000-1>>$10
    sta.z flash_read__3+3
    // if (!(flash_rom_address % 0x04000))
    // [977] if(0!=flash_read::$3) goto flash_read::@3 -- 0_neq_vduz1_then_la1 
    lda.z flash_read__3
    ora.z flash_read__3+1
    ora.z flash_read__3+2
    ora.z flash_read__3+3
    bne __b3
    // flash_read::@6
    // rom_bank_start % 32
    // [978] flash_read::$6 = flash_read::rom_bank_start#4 & $20-1 -- vbuz1=vbuz2_band_vbuc1 
    lda #$20-1
    and.z rom_bank_start
    sta.z flash_read__6
    // gotoxy(14, 4 + (rom_bank_start % 32))
    // [979] gotoxy::y#8 = 4 + flash_read::$6 -- vbuz1=vbuc1_plus_vbuz2 
    lda #4
    clc
    adc.z flash_read__6
    sta.z gotoxy.y
    // [980] call gotoxy
    // [485] phi from flash_read::@6 to gotoxy [phi:flash_read::@6->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#8 [phi:flash_read::@6->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = $e [phi:flash_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.x
    jsr gotoxy
    // flash_read::@11
    // rom_bank_start++;
    // [981] flash_read::rom_bank_start#0 = ++ flash_read::rom_bank_start#4 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank_start
    // [982] phi from flash_read::@11 flash_read::@2 to flash_read::@3 [phi:flash_read::@11/flash_read::@2->flash_read::@3]
    // [982] phi flash_read::rom_bank_start#10 = flash_read::rom_bank_start#0 [phi:flash_read::@11/flash_read::@2->flash_read::@3#0] -- register_copy 
    // flash_read::@3
  __b3:
    // unsigned int read_bytes = fgets(flash_ram_address, 128, fp)
    // [983] fgets::ptr#2 = flash_read::flash_ram_address#10 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [984] fgets::stream#0 = flash_read::fp#10
    // [985] call fgets
    jsr fgets
    // [986] fgets::return#5 = fgets::return#1
    // flash_read::@10
    // [987] flash_read::read_bytes#0 = fgets::return#5
    // if (!read_bytes)
    // [988] if(0!=flash_read::read_bytes#0) goto flash_read::@4 -- 0_neq_vwuz1_then_la1 
    lda.z read_bytes
    ora.z read_bytes+1
    bne __b4
    rts
    // flash_read::@4
  __b4:
    // flash_rom_address % 0x100
    // [989] flash_read::$12 = flash_read::flash_rom_address#10 & $100-1 -- vduz1=vduz2_band_vduc1 
    lda.z flash_rom_address
    and #<$100-1
    sta.z flash_read__12
    lda.z flash_rom_address+1
    and #>$100-1
    sta.z flash_read__12+1
    lda.z flash_rom_address+2
    and #<$100-1>>$10
    sta.z flash_read__12+2
    lda.z flash_rom_address+3
    and #>$100-1>>$10
    sta.z flash_read__12+3
    // if (!(flash_rom_address % 0x100))
    // [990] if(0!=flash_read::$12) goto flash_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z flash_read__12
    ora.z flash_read__12+1
    ora.z flash_read__12+2
    ora.z flash_read__12+3
    bne __b5
    // flash_read::@7
    // cputc('.')
    // [991] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    // cputc(0xE0);
    lda #'.'
    pha
    // [992] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_read::@5
  __b5:
    // flash_ram_address += read_bytes
    // [994] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#10 + flash_read::read_bytes#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z read_bytes+1
    sta.z flash_ram_address+1
    // flash_rom_address += read_bytes
    // [995] flash_read::flash_rom_address#1 = flash_read::flash_rom_address#10 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [996] flash_read::flash_bytes#1 = flash_read::return#2 + flash_read::read_bytes#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [997] if(flash_read::flash_ram_address#0<$c000) goto flash_read::@1 -- pbuz1_lt_vwuc1_then_la1 
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
    // [998] flash_read::flash_ram_address#1 = flash_read::flash_ram_address#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
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
    // [1000] return 
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
// int fclose(__mem() struct $2 *stream)
fclose: {
    .label fclose__1 = $b2
    .label fclose__4 = $42
    .label fclose__6 = $4b
    .label sp = $4b
    .label cbm_k_readst1_return = $b2
    .label cbm_k_readst2_return = $42
    // unsigned char sp = (unsigned char)stream
    // [1001] fclose::sp#0 = (char)fclose::stream#0 -- vbuz1=_byte_pssm2 
    lda stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1002] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [1003] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [1005] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1007] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [1008] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [1009] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1010] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1011] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [1012] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [1013] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [1015] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1017] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [1018] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [1019] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1020] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1021] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [1022] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [1023] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [1024] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [1025] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z fclose__6
    // *__filename = '\0'
    // [1026] ((char *)&__stdio_file)[fclose::$6] = '?'pm -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'\$00'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [1027] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
  .segment Data
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_readst2_status: .byte 0
    .label stream = main.fp
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __zp($28) unsigned int uvalue, __zp($2a) char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, __zp($33) char format_radix)
printf_uint: {
    .label uvalue = $28
    .label format_radix = $33
    .label format_min_length = $2a
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1029] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1030] utoa::value#2 = printf_uint::uvalue#3
    // [1031] utoa::radix#1 = printf_uint::format_radix#3
    // [1032] call utoa
  // Format number into buffer
    // [1282] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    // [1282] phi utoa::value#10 = utoa::value#2 [phi:printf_uint::@1->utoa#0] -- register_copy 
    // [1282] phi utoa::radix#2 = utoa::radix#1 [phi:printf_uint::@1->utoa#1] -- register_copy 
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1033] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1034] printf_number_buffer::format_min_length#2 = printf_uint::format_min_length#3
    // [1035] call printf_number_buffer
  // Print using format
    // [1313] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1313] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1313] phi printf_number_buffer::putc#10 = &cputc [phi:printf_uint::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1313] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1313] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_zero_padding
    // [1313] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [1313] phi printf_number_buffer::format_min_length#4 = printf_number_buffer::format_min_length#2 [phi:printf_uint::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1036] return 
    rts
}
  // flash_verify
// __zp($39) unsigned int flash_verify(__zp($27) char bank_ram, __zp($43) char *ptr_ram, __zp($62) unsigned long verify_rom_address, __zp($6b) unsigned int verify_rom_size)
flash_verify: {
    .label flash_verify__5 = $5a
    .label rom_bank1_flash_verify__0 = $3b
    .label rom_bank1_flash_verify__1 = $4b
    .label rom_bank1_flash_verify__2 = $48
    .label rom_ptr1_flash_verify__0 = $45
    .label rom_ptr1_flash_verify__2 = $45
    .label bank_set_bram1_bank = $27
    .label rom_bank1_bank_unshifted = $48
    .label rom_bank1_return = $b2
    .label rom_ptr1_return = $45
    .label ptr_rom = $45
    .label ptr_ram = $43
    .label verified_bytes = $34
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label correct_bytes = $39
    .label bank_ram = $27
    .label verify_rom_address = $62
    .label return = $39
    .label verify_rom_size = $6b
    // flash_verify::bank_set_bram1
    // BRAM = bank
    // [1038] BRAM = flash_verify::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // flash_verify::rom_bank1
    // BYTE2(address)
    // [1039] flash_verify::rom_bank1_$0 = byte2  flash_verify::verify_rom_address#3 -- vbuz1=_byte2_vduz2 
    lda.z verify_rom_address+2
    sta.z rom_bank1_flash_verify__0
    // BYTE1(address)
    // [1040] flash_verify::rom_bank1_$1 = byte1  flash_verify::verify_rom_address#3 -- vbuz1=_byte1_vduz2 
    lda.z verify_rom_address+1
    sta.z rom_bank1_flash_verify__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1041] flash_verify::rom_bank1_$2 = flash_verify::rom_bank1_$0 w= flash_verify::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_flash_verify__0
    sta.z rom_bank1_flash_verify__2+1
    lda.z rom_bank1_flash_verify__1
    sta.z rom_bank1_flash_verify__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1042] flash_verify::rom_bank1_bank_unshifted#0 = flash_verify::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1043] flash_verify::rom_bank1_return#0 = byte1  flash_verify::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // flash_verify::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1044] flash_verify::rom_ptr1_$2 = (unsigned int)flash_verify::verify_rom_address#3 -- vwuz1=_word_vduz2 
    lda.z verify_rom_address
    sta.z rom_ptr1_flash_verify__2
    lda.z verify_rom_address+1
    sta.z rom_ptr1_flash_verify__2+1
    // [1045] flash_verify::rom_ptr1_$0 = flash_verify::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_flash_verify__0
    and #<$3fff
    sta.z rom_ptr1_flash_verify__0
    lda.z rom_ptr1_flash_verify__0+1
    and #>$3fff
    sta.z rom_ptr1_flash_verify__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1046] flash_verify::rom_ptr1_return#0 = flash_verify::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // flash_verify::bank_set_brom1
    // BROM = bank
    // [1047] BROM = flash_verify::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [1048] flash_verify::ptr_rom#9 = (char *)flash_verify::rom_ptr1_return#0
    // [1049] phi from flash_verify::bank_set_brom1 to flash_verify::@1 [phi:flash_verify::bank_set_brom1->flash_verify::@1]
    // [1049] phi flash_verify::correct_bytes#2 = 0 [phi:flash_verify::bank_set_brom1->flash_verify::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z correct_bytes
    sta.z correct_bytes+1
    // [1049] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#10 [phi:flash_verify::bank_set_brom1->flash_verify::@1#1] -- register_copy 
    // [1049] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#9 [phi:flash_verify::bank_set_brom1->flash_verify::@1#2] -- register_copy 
    // [1049] phi flash_verify::verified_bytes#2 = 0 [phi:flash_verify::bank_set_brom1->flash_verify::@1#3] -- vwuz1=vwuc1 
    sta.z verified_bytes
    sta.z verified_bytes+1
    // flash_verify::@1
  __b1:
    // while (verified_bytes < verify_rom_size)
    // [1050] if(flash_verify::verified_bytes#2<flash_verify::verify_rom_size#11) goto flash_verify::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1051] return 
    rts
    // flash_verify::@2
  __b2:
    // rom_byte_verify(ptr_rom, *ptr_ram)
    // [1052] rom_byte_verify::ptr_rom#0 = flash_verify::ptr_rom#2
    // [1053] rom_byte_verify::value#0 = *flash_verify::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_verify.value
    // [1054] call rom_byte_verify
    jsr rom_byte_verify
    // [1055] rom_byte_verify::return#2 = rom_byte_verify::return#0
    // flash_verify::@5
    // [1056] flash_verify::$5 = rom_byte_verify::return#2
    // if (rom_byte_verify(ptr_rom, *ptr_ram))
    // [1057] if(0==flash_verify::$5) goto flash_verify::@3 -- 0_eq_vbuz1_then_la1 
    lda.z flash_verify__5
    beq __b3
    // flash_verify::@4
    // correct_bytes++;
    // [1058] flash_verify::correct_bytes#1 = ++ flash_verify::correct_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z correct_bytes
    bne !+
    inc.z correct_bytes+1
  !:
    // [1059] phi from flash_verify::@4 flash_verify::@5 to flash_verify::@3 [phi:flash_verify::@4/flash_verify::@5->flash_verify::@3]
    // [1059] phi flash_verify::correct_bytes#6 = flash_verify::correct_bytes#1 [phi:flash_verify::@4/flash_verify::@5->flash_verify::@3#0] -- register_copy 
    // flash_verify::@3
  __b3:
    // ptr_rom++;
    // [1060] flash_verify::ptr_rom#1 = ++ flash_verify::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [1061] flash_verify::ptr_ram#0 = ++ flash_verify::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // verified_bytes++;
    // [1062] flash_verify::verified_bytes#1 = ++ flash_verify::verified_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z verified_bytes
    bne !+
    inc.z verified_bytes+1
  !:
    // [1049] phi from flash_verify::@3 to flash_verify::@1 [phi:flash_verify::@3->flash_verify::@1]
    // [1049] phi flash_verify::correct_bytes#2 = flash_verify::correct_bytes#6 [phi:flash_verify::@3->flash_verify::@1#0] -- register_copy 
    // [1049] phi flash_verify::ptr_ram#4 = flash_verify::ptr_ram#0 [phi:flash_verify::@3->flash_verify::@1#1] -- register_copy 
    // [1049] phi flash_verify::ptr_rom#2 = flash_verify::ptr_rom#1 [phi:flash_verify::@3->flash_verify::@1#2] -- register_copy 
    // [1049] phi flash_verify::verified_bytes#2 = flash_verify::verified_bytes#1 [phi:flash_verify::@3->flash_verify::@1#3] -- register_copy 
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
// void rom_sector_erase(__zp($c6) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $34
    .label rom_ptr1_rom_sector_erase__2 = $34
    .label rom_ptr1_return = $34
    .label rom_chip_address = $62
    .label address = $c6
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1064] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [1065] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1066] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [1067] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1068] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [1069] call rom_unlock
    // [1121] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1121] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1121] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [1070] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [1071] call rom_unlock
    // [1121] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1121] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1121] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [1072] rom_wait::ptr_rom#1 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [1073] call rom_wait
    // [1508] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [1508] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [1074] return 
    rts
}
  // print_address
// void print_address(__zp($27) char bram_bank, __zp($28) char *bram_ptr, __zp($23) unsigned long brom_address)
print_address: {
    .label rom_bank1_print_address__0 = $3b
    .label rom_bank1_print_address__1 = $4b
    .label rom_bank1_print_address__2 = $43
    .label rom_ptr1_print_address__0 = $ac
    .label rom_ptr1_print_address__2 = $ac
    .label rom_bank1_bank_unshifted = $43
    .label brom_bank = $b2
    .label brom_ptr = $ac
    .label bram_bank = $27
    .label bram_ptr = $28
    .label brom_address = $23
    // textcolor(WHITE)
    // [1076] call textcolor
    // [467] phi from print_address to textcolor [phi:print_address->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:print_address->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // print_address::rom_bank1
    // BYTE2(address)
    // [1077] print_address::rom_bank1_$0 = byte2  print_address::brom_address#10 -- vbuz1=_byte2_vduz2 
    lda.z brom_address+2
    sta.z rom_bank1_print_address__0
    // BYTE1(address)
    // [1078] print_address::rom_bank1_$1 = byte1  print_address::brom_address#10 -- vbuz1=_byte1_vduz2 
    lda.z brom_address+1
    sta.z rom_bank1_print_address__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1079] print_address::rom_bank1_$2 = print_address::rom_bank1_$0 w= print_address::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_print_address__0
    sta.z rom_bank1_print_address__2+1
    lda.z rom_bank1_print_address__1
    sta.z rom_bank1_print_address__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1080] print_address::rom_bank1_bank_unshifted#0 = print_address::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1081] print_address::brom_bank#0 = byte1  print_address::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z brom_bank
    // print_address::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1082] print_address::rom_ptr1_$2 = (unsigned int)print_address::brom_address#10 -- vwuz1=_word_vduz2 
    lda.z brom_address
    sta.z rom_ptr1_print_address__2
    lda.z brom_address+1
    sta.z rom_ptr1_print_address__2+1
    // [1083] print_address::rom_ptr1_$0 = print_address::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_print_address__0
    and #<$3fff
    sta.z rom_ptr1_print_address__0
    lda.z rom_ptr1_print_address__0+1
    and #>$3fff
    sta.z rom_ptr1_print_address__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1084] print_address::brom_ptr#0 = print_address::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z brom_ptr
    clc
    adc #<$c000
    sta.z brom_ptr
    lda.z brom_ptr+1
    adc #>$c000
    sta.z brom_ptr+1
    // [1085] phi from print_address::rom_ptr1 to print_address::@1 [phi:print_address::rom_ptr1->print_address::@1]
    // print_address::@1
    // gotoxy(43, 1)
    // [1086] call gotoxy
    // [485] phi from print_address::@1 to gotoxy [phi:print_address::@1->gotoxy]
    // [485] phi gotoxy::y#25 = 1 [phi:print_address::@1->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = $2b [phi:print_address::@1->gotoxy#1] -- vbuz1=vbuc1 
    lda #$2b
    sta.z gotoxy.x
    jsr gotoxy
    // [1087] phi from print_address::@1 to print_address::@2 [phi:print_address::@1->print_address::@2]
    // print_address::@2
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1088] call printf_str
    // [711] phi from print_address::@2 to printf_str [phi:print_address::@2->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:print_address::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = print_address::s [phi:print_address::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@3
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1089] printf_uchar::uvalue#0 = print_address::bram_bank#10
    // [1090] call printf_uchar
    // [928] phi from print_address::@3 to printf_uchar [phi:print_address::@3->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:print_address::@3->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 2 [phi:print_address::@3->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:print_address::@3->printf_uchar#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#0 [phi:print_address::@3->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [1091] phi from print_address::@3 to print_address::@4 [phi:print_address::@3->print_address::@4]
    // print_address::@4
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1092] call printf_str
    // [711] phi from print_address::@4 to printf_str [phi:print_address::@4->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:print_address::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = print_address::s1 [phi:print_address::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@5
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1093] printf_uint::uvalue#0 = (unsigned int)print_address::bram_ptr#10
    // [1094] call printf_uint
    // [1028] phi from print_address::@5 to printf_uint [phi:print_address::@5->printf_uint]
    // [1028] phi printf_uint::format_min_length#3 = 4 [phi:print_address::@5->printf_uint#0] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1028] phi printf_uint::format_radix#3 = HEXADECIMAL [phi:print_address::@5->printf_uint#1] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1028] phi printf_uint::uvalue#3 = printf_uint::uvalue#0 [phi:print_address::@5->printf_uint#2] -- register_copy 
    jsr printf_uint
    // [1095] phi from print_address::@5 to print_address::@6 [phi:print_address::@5->print_address::@6]
    // print_address::@6
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1096] call printf_str
    // [711] phi from print_address::@6 to printf_str [phi:print_address::@6->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:print_address::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = print_address::s2 [phi:print_address::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@7
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1097] printf_ulong::uvalue#0 = print_address::brom_address#10
    // [1098] call printf_ulong
    // [1452] phi from print_address::@7 to printf_ulong [phi:print_address::@7->printf_ulong]
    // [1452] phi printf_ulong::format_zero_padding#2 = 0 [phi:print_address::@7->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1452] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:print_address::@7->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1099] phi from print_address::@7 to print_address::@8 [phi:print_address::@7->print_address::@8]
    // print_address::@8
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1100] call printf_str
    // [711] phi from print_address::@8 to printf_str [phi:print_address::@8->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:print_address::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = print_address::s3 [phi:print_address::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@9
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1101] printf_uchar::uvalue#1 = print_address::brom_bank#0 -- vbuz1=vbuz2 
    lda.z brom_bank
    sta.z printf_uchar.uvalue
    // [1102] call printf_uchar
    // [928] phi from print_address::@9 to printf_uchar [phi:print_address::@9->printf_uchar]
    // [928] phi printf_uchar::format_zero_padding#11 = 0 [phi:print_address::@9->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [928] phi printf_uchar::format_min_length#11 = 2 [phi:print_address::@9->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [928] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:print_address::@9->printf_uchar#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [928] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#1 [phi:print_address::@9->printf_uchar#3] -- register_copy 
    jsr printf_uchar
    // [1103] phi from print_address::@9 to print_address::@10 [phi:print_address::@9->print_address::@10]
    // print_address::@10
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1104] call printf_str
    // [711] phi from print_address::@10 to printf_str [phi:print_address::@10->printf_str]
    // [711] phi printf_str::putc#32 = &cputc [phi:print_address::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [711] phi printf_str::s#32 = print_address::s1 [phi:print_address::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // print_address::@11
    // printf("ram = %2x/%4p, rom = %6x,%2x/%4p", bram_bank, bram_ptr, brom_address, brom_bank, brom_ptr)
    // [1105] printf_uint::uvalue#1 = (unsigned int)(char *)print_address::brom_ptr#0 -- vwuz1=vwuz2 
    lda.z brom_ptr
    sta.z printf_uint.uvalue
    lda.z brom_ptr+1
    sta.z printf_uint.uvalue+1
    // [1106] call printf_uint
    // [1028] phi from print_address::@11 to printf_uint [phi:print_address::@11->printf_uint]
    // [1028] phi printf_uint::format_min_length#3 = 4 [phi:print_address::@11->printf_uint#0] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1028] phi printf_uint::format_radix#3 = HEXADECIMAL [phi:print_address::@11->printf_uint#1] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1028] phi printf_uint::uvalue#3 = printf_uint::uvalue#1 [phi:print_address::@11->printf_uint#2] -- register_copy 
    jsr printf_uint
    // print_address::@return
    // }
    // [1107] return 
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
// unsigned long flash_write(__zp($27) char flash_ram_bank, __zp($6b) char *flash_ram_address, __zp($23) unsigned long flash_rom_address)
flash_write: {
    .label rom_chip_address = $70
    .label flash_rom_address = $23
    .label flash_ram_address = $6b
    .label flashed_bytes = $66
    .label flash_ram_bank = $27
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [1108] flash_write::rom_chip_address#0 = flash_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1109] BRAM = flash_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [1110] phi from flash_write::bank_set_bram1 to flash_write::@1 [phi:flash_write::bank_set_bram1->flash_write::@1]
    // [1110] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#0] -- register_copy 
    // [1110] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#1 [phi:flash_write::bank_set_bram1->flash_write::@1#1] -- register_copy 
    // [1110] phi flash_write::flashed_bytes#2 = 0 [phi:flash_write::bank_set_bram1->flash_write::@1#2] -- vduz1=vduc1 
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
    // [1111] if(flash_write::flashed_bytes#2<$100) goto flash_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [1112] return 
    rts
    // flash_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [1113] rom_unlock::address#2 = flash_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1114] call rom_unlock
    // [1121] phi from flash_write::@2 to rom_unlock [phi:flash_write::@2->rom_unlock]
    // [1121] phi rom_unlock::unlock_code#5 = $a0 [phi:flash_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1121] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:flash_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // flash_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [1115] rom_byte_program::address#0 = flash_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [1116] rom_byte_program::value#0 = *flash_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [1117] call rom_byte_program
    // [1515] phi from flash_write::@3 to rom_byte_program [phi:flash_write::@3->rom_byte_program]
    jsr rom_byte_program
    // flash_write::@4
    // flash_rom_address++;
    // [1118] flash_write::flash_rom_address#0 = ++ flash_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [1119] flash_write::flash_ram_address#0 = ++ flash_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [1120] flash_write::flashed_bytes#1 = ++ flash_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [1110] phi from flash_write::@4 to flash_write::@1 [phi:flash_write::@4->flash_write::@1]
    // [1110] phi flash_write::flash_ram_address#2 = flash_write::flash_ram_address#0 [phi:flash_write::@4->flash_write::@1#0] -- register_copy 
    // [1110] phi flash_write::flash_rom_address#3 = flash_write::flash_rom_address#0 [phi:flash_write::@4->flash_write::@1#1] -- register_copy 
    // [1110] phi flash_write::flashed_bytes#2 = flash_write::flashed_bytes#1 [phi:flash_write::@4->flash_write::@1#2] -- register_copy 
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
// void rom_unlock(__zp($62) unsigned long address, __zp($6a) char unlock_code)
rom_unlock: {
    .label chip_address = $2c
    .label address = $62
    .label unlock_code = $6a
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1122] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1123] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1124] call rom_write_byte
    // [1525] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1525] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [1525] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1125] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [1126] call rom_write_byte
    // [1525] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1525] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [1525] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1127] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1128] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1129] call rom_write_byte
    // [1525] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1525] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1525] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1130] return 
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
// __zp($27) char rom_read_byte(__zp($62) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $42
    .label rom_bank1_rom_read_byte__1 = $7e
    .label rom_bank1_rom_read_byte__2 = $30
    .label rom_ptr1_rom_read_byte__0 = $48
    .label rom_ptr1_rom_read_byte__2 = $48
    .label rom_bank1_bank_unshifted = $30
    .label rom_bank1_return = $47
    .label rom_ptr1_return = $48
    .label return = $27
    .label address = $62
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1132] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [1133] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1134] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta.z rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta.z rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1135] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1136] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1137] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [1138] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1139] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [1140] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [1141] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [1142] return 
    rts
}
  // print_chip_KB
// void print_chip_KB(__zp($53) char rom_chip, __zp($34) char *kb)
print_chip_KB: {
    .label print_chip_KB__3 = $53
    .label rom_chip = $53
    .label kb = $34
    .label print_chip_KB__9 = $7e
    .label print_chip_KB__10 = $53
    // rom_chip * 10
    // [1144] print_chip_KB::$9 = print_chip_KB::rom_chip#3 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z print_chip_KB__9
    // [1145] print_chip_KB::$10 = print_chip_KB::$9 + print_chip_KB::rom_chip#3 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z print_chip_KB__10
    clc
    adc.z print_chip_KB__9
    sta.z print_chip_KB__10
    // [1146] print_chip_KB::$3 = print_chip_KB::$10 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_chip_KB__3
    // print_chip_line(3 + rom_chip * 10, 51, kb[0])
    // [1147] print_chip_line::x#9 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chip_KB__3
    sta.z print_chip_line.x
    // [1148] print_chip_line::c#9 = *print_chip_KB::kb#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (kb),y
    sta.z print_chip_line.c
    // [1149] call print_chip_line
    // [1211] phi from print_chip_KB to print_chip_line [phi:print_chip_KB->print_chip_line]
    // [1211] phi print_chip_line::c#12 = print_chip_line::c#9 [phi:print_chip_KB->print_chip_line#0] -- register_copy 
    // [1211] phi print_chip_line::y#12 = $33 [phi:print_chip_KB->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$33
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#9 [phi:print_chip_KB->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@1
    // print_chip_line(3 + rom_chip * 10, 52, kb[1])
    // [1150] print_chip_line::x#10 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chip_KB__3
    sta.z print_chip_line.x
    // [1151] print_chip_line::c#10 = print_chip_KB::kb#3[1] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #1
    lda (kb),y
    sta.z print_chip_line.c
    // [1152] call print_chip_line
    // [1211] phi from print_chip_KB::@1 to print_chip_line [phi:print_chip_KB::@1->print_chip_line]
    // [1211] phi print_chip_line::c#12 = print_chip_line::c#10 [phi:print_chip_KB::@1->print_chip_line#0] -- register_copy 
    // [1211] phi print_chip_line::y#12 = $34 [phi:print_chip_KB::@1->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$34
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#10 [phi:print_chip_KB::@1->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@2
    // print_chip_line(3 + rom_chip * 10, 53, kb[2])
    // [1153] print_chip_line::x#11 = 3 + print_chip_KB::$3 -- vbuz1=vbuc1_plus_vbuz2 
    lda #3
    clc
    adc.z print_chip_KB__3
    sta.z print_chip_line.x
    // [1154] print_chip_line::c#11 = print_chip_KB::kb#3[2] -- vbuz1=pbuz2_derefidx_vbuc1 
    ldy #2
    lda (kb),y
    sta.z print_chip_line.c
    // [1155] call print_chip_line
    // [1211] phi from print_chip_KB::@2 to print_chip_line [phi:print_chip_KB::@2->print_chip_line]
    // [1211] phi print_chip_line::c#12 = print_chip_line::c#11 [phi:print_chip_KB::@2->print_chip_line#0] -- register_copy 
    // [1211] phi print_chip_line::y#12 = $35 [phi:print_chip_KB::@2->print_chip_line#1] -- vbuz1=vbuc1 
    lda #$35
    sta.z print_chip_line.y
    // [1211] phi print_chip_line::x#12 = print_chip_line::x#11 [phi:print_chip_KB::@2->print_chip_line#2] -- register_copy 
    jsr print_chip_line
    // print_chip_KB::@return
    // }
    // [1156] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($aa) char mapbase, __zp($c5) char config)
screenlayer: {
    .label screenlayer__0 = $f9
    .label screenlayer__1 = $aa
    .label screenlayer__2 = $fa
    .label screenlayer__5 = $c5
    .label screenlayer__6 = $c5
    .label screenlayer__7 = $f1
    .label screenlayer__8 = $f1
    .label screenlayer__9 = $e9
    .label screenlayer__10 = $e9
    .label screenlayer__11 = $e9
    .label screenlayer__12 = $ea
    .label screenlayer__13 = $ea
    .label screenlayer__14 = $ea
    .label screenlayer__16 = $f1
    .label screenlayer__17 = $dc
    .label screenlayer__18 = $e9
    .label screenlayer__19 = $ea
    .label mapbase = $aa
    .label config = $c5
    .label mapbase_offset = $dd
    .label y = $a9
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1157] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1158] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1159] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1160] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1161] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1162] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1163] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1164] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1165] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1166] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1167] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1168] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1169] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1170] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1171] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [1172] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1173] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1174] screenlayer::$18 = (char)screenlayer::$9
    // [1175] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
    lda #$28
    ldy.z screenlayer__10
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta.z screenlayer__10
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1176] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1177] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1178] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1179] screenlayer::$19 = (char)screenlayer::$12
    // [1180] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
    lda #$1e
    ldy.z screenlayer__13
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta.z screenlayer__13
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1181] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1182] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1183] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z mapbase_offset
    lda __conio+3+1
    sta.z mapbase_offset+1
    // [1184] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1184] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1184] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1185] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1186] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1187] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [1188] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1189] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+$a
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+$a+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1190] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1184] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1184] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1184] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1191] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1192] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1193] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1194] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1195] call gotoxy
    // [485] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [485] phi gotoxy::y#25 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1196] return 
    rts
    // [1197] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1198] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1199] gotoxy::y#2 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [1200] call gotoxy
    // [485] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#2 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1201] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1202] call clearline
    jsr clearline
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($ca) char x, __zp($54) char y, __zp($38) char c)
cputcxy: {
    .label x = $ca
    .label y = $54
    .label c = $38
    // gotoxy(x, y)
    // [1204] gotoxy::x#0 = cputcxy::x#68 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1205] gotoxy::y#0 = cputcxy::y#68 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1206] call gotoxy
    // [485] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1207] stackpush(char) = cputcxy::c#68 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1208] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1210] return 
    rts
}
  // print_chip_line
// void print_chip_line(__zp($38) char x, __zp($3b) char y, __zp($42) char c)
print_chip_line: {
    .label x = $38
    .label c = $42
    .label y = $3b
    // gotoxy(x, y)
    // [1212] gotoxy::x#4 = print_chip_line::x#12 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1213] gotoxy::y#4 = print_chip_line::y#12 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1214] call gotoxy
    // [485] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [485] phi gotoxy::y#25 = gotoxy::y#4 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [485] phi gotoxy::x#25 = gotoxy::x#4 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1215] phi from print_chip_line to print_chip_line::@1 [phi:print_chip_line->print_chip_line::@1]
    // print_chip_line::@1
    // textcolor(GREY)
    // [1216] call textcolor
    // [467] phi from print_chip_line::@1 to textcolor [phi:print_chip_line::@1->textcolor]
    // [467] phi textcolor::color#23 = GREY [phi:print_chip_line::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1217] phi from print_chip_line::@1 to print_chip_line::@2 [phi:print_chip_line::@1->print_chip_line::@2]
    // print_chip_line::@2
    // bgcolor(BLUE)
    // [1218] call bgcolor
    // [472] phi from print_chip_line::@2 to bgcolor [phi:print_chip_line::@2->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@3
    // cputc(VERA_CHR_UR)
    // [1219] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1220] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1222] call textcolor
    // [467] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [467] phi textcolor::color#23 = WHITE [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1223] phi from print_chip_line::@3 to print_chip_line::@4 [phi:print_chip_line::@3->print_chip_line::@4]
    // print_chip_line::@4
    // bgcolor(BLACK)
    // [1224] call bgcolor
    // [472] phi from print_chip_line::@4 to bgcolor [phi:print_chip_line::@4->bgcolor]
    // [472] phi bgcolor::color#11 = BLACK [phi:print_chip_line::@4->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@5
    // cputc(VERA_CHR_SPACE)
    // [1225] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1226] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(c)
    // [1228] stackpush(char) = print_chip_line::c#12 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1229] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputc(VERA_CHR_SPACE)
    // [1231] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1232] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1234] call textcolor
    // [467] phi from print_chip_line::@5 to textcolor [phi:print_chip_line::@5->textcolor]
    // [467] phi textcolor::color#23 = GREY [phi:print_chip_line::@5->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1235] phi from print_chip_line::@5 to print_chip_line::@6 [phi:print_chip_line::@5->print_chip_line::@6]
    // print_chip_line::@6
    // bgcolor(BLUE)
    // [1236] call bgcolor
    // [472] phi from print_chip_line::@6 to bgcolor [phi:print_chip_line::@6->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:print_chip_line::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@7
    // cputc(VERA_CHR_UL)
    // [1237] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1238] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_line::@return
    // }
    // [1240] return 
    rts
}
  // print_chip_end
// void print_chip_end(__zp($b8) char x, char y)
print_chip_end: {
    .const y = $36
    .label x = $b8
    // gotoxy(x, y)
    // [1241] gotoxy::x#5 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1242] call gotoxy
    // [485] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [485] phi gotoxy::y#25 = print_chip_end::y#0 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #y
    sta.z gotoxy.y
    // [485] phi gotoxy::x#25 = gotoxy::x#5 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1243] phi from print_chip_end to print_chip_end::@1 [phi:print_chip_end->print_chip_end::@1]
    // print_chip_end::@1
    // textcolor(GREY)
    // [1244] call textcolor
    // [467] phi from print_chip_end::@1 to textcolor [phi:print_chip_end::@1->textcolor]
    // [467] phi textcolor::color#23 = GREY [phi:print_chip_end::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1245] phi from print_chip_end::@1 to print_chip_end::@2 [phi:print_chip_end::@1->print_chip_end::@2]
    // print_chip_end::@2
    // bgcolor(BLUE)
    // [1246] call bgcolor
    // [472] phi from print_chip_end::@2 to bgcolor [phi:print_chip_end::@2->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@3
    // cputc(VERA_CHR_UR)
    // [1247] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1248] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1250] call textcolor
    // [467] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [467] phi textcolor::color#23 = BLUE [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [1251] phi from print_chip_end::@3 to print_chip_end::@4 [phi:print_chip_end::@3->print_chip_end::@4]
    // print_chip_end::@4
    // bgcolor(BLACK)
    // [1252] call bgcolor
    // [472] phi from print_chip_end::@4 to bgcolor [phi:print_chip_end::@4->bgcolor]
    // [472] phi bgcolor::color#11 = BLACK [phi:print_chip_end::@4->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@5
    // cputc(VERA_CHR_HL)
    // [1253] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1254] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1256] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1257] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1259] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1260] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(GREY)
    // [1262] call textcolor
    // [467] phi from print_chip_end::@5 to textcolor [phi:print_chip_end::@5->textcolor]
    // [467] phi textcolor::color#23 = GREY [phi:print_chip_end::@5->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1263] phi from print_chip_end::@5 to print_chip_end::@6 [phi:print_chip_end::@5->print_chip_end::@6]
    // print_chip_end::@6
    // bgcolor(BLUE)
    // [1264] call bgcolor
    // [472] phi from print_chip_end::@6 to bgcolor [phi:print_chip_end::@6->bgcolor]
    // [472] phi bgcolor::color#11 = BLUE [phi:print_chip_end::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@7
    // cputc(VERA_CHR_UL)
    // [1265] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1266] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1268] return 
    rts
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($45) void (*putc)(char), __zp($53) char pad, __zp($4e) char length)
printf_padding: {
    .label i = $3b
    .label putc = $45
    .label length = $4e
    .label pad = $53
    // [1270] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1270] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1271] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1272] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1273] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1274] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall17
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1276] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1270] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1270] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall17:
    jmp (putc)
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    .label return = $b8
    // __mem unsigned char ch
    // [1277] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1279] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [1280] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1281] return 
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
// void utoa(__zp($28) unsigned int value, __zp($34) char *buffer, __zp($33) char radix)
utoa: {
    .label utoa__4 = $47
    .label utoa__10 = $2b
    .label utoa__11 = $7e
    .label digit_value = $30
    .label buffer = $34
    .label digit = $4b
    .label value = $28
    .label radix = $33
    .label started = $32
    .label max_digits = $42
    .label digit_values = $43
    // if(radix==DECIMAL)
    // [1283] if(utoa::radix#2==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1284] if(utoa::radix#2==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1285] if(utoa::radix#2==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1286] if(utoa::radix#2==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1287] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1288] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1289] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1290] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1291] return 
    rts
    // [1292] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1292] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1292] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1292] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1292] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1292] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1292] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1292] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1292] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1292] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1292] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1292] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1293] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1293] phi utoa::buffer#10 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1293] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1293] phi utoa::value#3 = utoa::value#10 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1293] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1294] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1295] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1296] utoa::$11 = (char)utoa::value#3 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1297] *utoa::buffer#10 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1298] utoa::buffer#3 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1299] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1300] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1301] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1302] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1303] if(utoa::value#3>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1304] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1304] phi utoa::buffer#15 = utoa::buffer#10 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1304] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1304] phi utoa::value#7 = utoa::value#3 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1305] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1293] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1293] phi utoa::buffer#10 = utoa::buffer#15 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1293] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1293] phi utoa::value#3 = utoa::value#7 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1293] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1306] utoa_append::buffer#0 = utoa::buffer#10 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1307] utoa_append::value#0 = utoa::value#3
    // [1308] utoa_append::sub#0 = utoa::digit_value#0
    // [1309] call utoa_append
    // [1570] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1310] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1311] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1312] utoa::buffer#4 = ++ utoa::buffer#10 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1304] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1304] phi utoa::buffer#15 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1304] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1304] phi utoa::value#7 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($34) void (*putc)(char), __zp($32) char buffer_sign, char *buffer_digits, __zp($2a) char format_min_length, __zp($4b) char format_justify_left, char format_sign_always, __zp($7f) char format_zero_padding, __zp($47) char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $40
    .label buffer_sign = $32
    .label format_zero_padding = $7f
    .label format_min_length = $2a
    .label len = $4a
    .label padding = $4a
    .label putc = $34
    .label format_justify_left = $4b
    .label format_upper_case = $47
    // if(format.min_length)
    // [1314] if(0==printf_number_buffer::format_min_length#4) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b6
    // [1315] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [1316] call strlen
    // [811] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [811] phi strlen::str#9 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1317] strlen::return#10 = strlen::len#2
    // printf_number_buffer::@14
    // [1318] printf_number_buffer::$19 = strlen::return#10
    // signed char len = (signed char)strlen(buffer.digits)
    // [1319] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [1320] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [1321] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1322] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [1322] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [1323] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#4 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1324] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1326] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [1326] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1325] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [1326] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [1326] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1327] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [1328] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [1329] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [1330] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1331] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1332] call printf_padding
    // [1269] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1269] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1269] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@8->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1269] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1333] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [1334] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1335] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall18
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1337] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [1338] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1339] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1340] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1341] call printf_padding
    // [1269] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1269] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1269] phi printf_padding::pad#7 = '0'pm [phi:printf_number_buffer::@10->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1269] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1342] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbuz1_then_la1 
    lda.z format_upper_case
    beq __b5
    // [1343] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1344] call strupr
    // [1577] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1345] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1346] call printf_str
    // [711] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [711] phi printf_str::putc#32 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [711] phi printf_str::s#32 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1347] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1348] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1349] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1350] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1351] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1352] call printf_padding
    // [1269] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1269] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1269] phi printf_padding::pad#7 = ' 'pm [phi:printf_number_buffer::@12->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1269] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1353] return 
    rts
    // Outside Flow
  icall18:
    jmp (putc)
}
  // cbm_k_setlfs
/**
 * @brief Sets the logical file channel.
 *
 * @param channel the logical file number.
 * @param device the device number.
 * @param command the command.
 */
// void cbm_k_setlfs(__mem() volatile char channel, __zp($f8) volatile char device, __zp($ef) volatile char command)
cbm_k_setlfs: {
    .label device = $f8
    .label command = $ef
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1355] return 
    rts
  .segment Data
    channel: .byte 0
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
// __zp($ac) int ferror(__zp($6b) struct $2 *stream)
ferror: {
    .label ferror__6 = $2b
    .label ferror__15 = $4a
    .label cbm_k_setnam1_filename = $f5
    .label cbm_k_setnam1_filename_len = $e0
    .label cbm_k_setnam1_ferror__0 = $40
    .label cbm_k_chkin1_channel = $f0
    .label cbm_k_chkin1_status = $e1
    .label cbm_k_chrin1_ch = $e2
    .label cbm_k_readst1_status = $bd
    .label cbm_k_close1_channel = $e3
    .label cbm_k_chrin2_ch = $be
    .label stream = $6b
    .label return = $ac
    .label sp = $7e
    .label cbm_k_chrin1_return = $4a
    .label ch = $4a
    .label cbm_k_readst1_return = $2b
    .label st = $2b
    .label errno_len = $4e
    .label cbm_k_chrin2_return = $4a
    .label errno_parsed = $47
    // unsigned char sp = (unsigned char)stream
    // [1356] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [1357] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [1358] cbm_k_setlfs::device = 8 -- vbuz1=vbuc1 
    lda #8
    sta.z cbm_k_setlfs.device
    // [1359] cbm_k_setlfs::command = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.command
    // [1360] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [1361] ferror::cbm_k_setnam1_filename = ferror::$18 -- pbuz1=pbuc1 
    lda #<ferror__18
    sta.z cbm_k_setnam1_filename
    lda #>ferror__18
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [1362] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1363] call strlen
    // [811] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [811] phi strlen::str#9 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1364] strlen::return#13 = strlen::len#2
    // ferror::@12
    // [1365] ferror::cbm_k_setnam1_$0 = strlen::return#13
    // char filename_len = (char)strlen(filename)
    // [1366] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
    lda.z cbm_k_setnam1_ferror__0
    sta.z cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // ferror::cbm_k_open1
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // ferror::@6
    // cbm_k_chkin(15)
    // [1369] ferror::cbm_k_chkin1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [1370] ferror::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [1372] ferror::cbm_k_chrin1_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [1374] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [1375] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [1376] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [1377] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [1377] phi __errno#11 = __errno#109 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [1377] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [1377] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [1377] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [1378] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1380] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [1381] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [1382] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [1383] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [1384] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [1385] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [1386] ferror::cbm_k_close1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [1388] ferror::return#1 = __errno#11 -- vwsz1=vwsz2 
    lda.z __errno
    sta.z return
    lda.z __errno+1
    sta.z return+1
    // ferror::@return
    // }
    // [1389] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [1390] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [1391] if(ferror::ch#10!=','pm) goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [1392] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [1393] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [1394] call strncpy
    // [1587] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [1395] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [1396] call atoi
    // [1408] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [1408] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [1397] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [1398] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [1399] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [1399] phi __errno#52 = __errno#11 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [1399] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [1400] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [1401] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [1402] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [1404] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [1405] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [1406] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [1407] ferror::ch#1 = ferror::$15
    // [1377] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [1377] phi __errno#11 = __errno#52 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [1377] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [1377] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [1377] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    ferror__18: .text ""
    .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($45) int atoi(__zp($39) const char *str)
atoi: {
    .label atoi__6 = $45
    .label atoi__7 = $45
    .label res = $45
    // Initialize sign as positive
    .label i = $33
    .label return = $45
    .label str = $39
    // Initialize result
    .label negative = $54
    .label atoi__10 = $30
    .label atoi__11 = $45
    // if (str[i] == '-')
    // [1409] if(*atoi::str#2!='-'pm) goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [1410] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [1411] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [1411] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [1411] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [1411] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [1411] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [1411] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [1411] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [1411] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [1412] if(atoi::str#2[atoi::i#4]<'0'pm) goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [1413] if(atoi::str#2[atoi::i#4]<='9'pm) goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [1414] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [1416] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [1416] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [1415] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [1417] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [1418] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [1419] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [1420] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [1421] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [1422] atoi::res#1 = atoi::$7 - '0'pm -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [1423] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1411] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [1411] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [1411] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [1411] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
    jmp __b3
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($27) char value, __zp($43) char *buffer, __zp($55) char radix)
uctoa: {
    .label uctoa__4 = $47
    .label digit_value = $2b
    .label buffer = $43
    .label digit = $33
    .label value = $27
    .label radix = $55
    .label started = $54
    .label max_digits = $4e
    .label digit_values = $45
    // if(radix==DECIMAL)
    // [1424] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1425] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1426] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1427] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1428] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e'pm -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1429] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r'pm -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1430] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r'pm -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1431] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1432] return 
    rts
    // [1433] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1433] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1433] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1433] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1433] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1433] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1433] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1433] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1433] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1433] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1433] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1433] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1434] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1434] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1434] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1434] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1434] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1435] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1436] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1437] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1438] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1439] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1440] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1441] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1442] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1443] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1443] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1443] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1443] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1444] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1434] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1434] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1434] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1434] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1434] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1445] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1446] uctoa_append::value#0 = uctoa::value#2
    // [1447] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1448] call uctoa_append
    // [1598] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1449] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1450] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1451] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1443] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1443] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1443] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1443] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($23) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, __zp($7f) char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $23
    .label format_zero_padding = $7f
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1453] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1454] ultoa::value#1 = printf_ulong::uvalue#2
    // [1455] call ultoa
  // Format number into buffer
    // [1605] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1456] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1457] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#2
    // [1458] call printf_number_buffer
  // Print using format
    // [1313] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1313] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [1313] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1313] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1313] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    // [1313] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_justify_left
    // [1313] phi printf_number_buffer::format_min_length#4 = 6 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1459] return 
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
// __zp($3c) unsigned int fgets(__zp($43) char *ptr, unsigned int size, __zp($39) struct $2 *stream)
fgets: {
    .const size = $80
    .label fgets__1 = $2b
    .label fgets__8 = $33
    .label fgets__9 = $32
    .label fgets__13 = $4a
    .label cbm_k_chkin1_channel = $b3
    .label cbm_k_chkin1_status = $b0
    .label cbm_k_readst1_status = $b1
    .label cbm_k_readst2_status = $74
    .label sp = $47
    .label cbm_k_readst1_return = $2b
    .label return = $3c
    .label bytes = $48
    .label cbm_k_readst2_return = $33
    .label read = $3c
    .label ptr = $43
    .label remaining = $34
    .label stream = $39
    // unsigned char sp = (unsigned char)stream
    // [1460] fgets::sp#0 = (char)fgets::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1461] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1462] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1464] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1466] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [1467] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@9
    // cbm_k_readst()
    // [1468] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1469] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1470] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b8
    // [1471] phi from fgets::@10 fgets::@3 fgets::@9 to fgets::@return [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return]
  __b1:
    // [1471] phi fgets::return#1 = 0 [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1472] return 
    rts
    // [1473] phi from fgets::@13 to fgets::@1 [phi:fgets::@13->fgets::@1]
    // [1473] phi fgets::read#10 = fgets::read#1 [phi:fgets::@13->fgets::@1#0] -- register_copy 
    // [1473] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@13->fgets::@1#1] -- register_copy 
    // [1473] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@13->fgets::@1#2] -- register_copy 
    // [1473] phi from fgets::@9 to fgets::@1 [phi:fgets::@9->fgets::@1]
  __b8:
    // [1473] phi fgets::read#10 = 0 [phi:fgets::@9->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1473] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@9->fgets::@1#1] -- vwuz1=vwuc1 
    lda #<size
    sta.z remaining
    lda #>size
    sta.z remaining+1
    // [1473] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@9->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@6
  __b6:
    // if (remaining >= 512)
    // [1474] if(fgets::remaining#11>=$200) goto fgets::@2 -- vwuz1_ge_vwuc1_then_la1 
    lda.z remaining+1
    cmp #>$200
    bcc !+
    beq !__b2+
    jmp __b2
  !__b2:
    lda.z remaining
    cmp #<$200
    bcc !__b2+
    jmp __b2
  !__b2:
  !:
    // fgets::@7
    // cx16_k_macptr(remaining, ptr)
    // [1475] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [1476] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1477] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1478] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@12
  __b12:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1479] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1480] phi from fgets::@11 fgets::@12 to fgets::cbm_k_readst2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2]
    // [1480] phi fgets::bytes#10 = fgets::bytes#2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1481] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1483] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [1484] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@10
    // cbm_k_readst()
    // [1485] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1486] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [1487] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [1488] if(0==fgets::$9) goto fgets::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    jmp __b1
    // fgets::@3
  __b3:
    // if (bytes == 0xFFFF)
    // [1489] if(fgets::bytes#10!=$ffff) goto fgets::@4 -- vwuz1_neq_vwuc1_then_la1 
    lda.z bytes+1
    cmp #>$ffff
    bne __b4
    lda.z bytes
    cmp #<$ffff
    bne __b4
    jmp __b1
    // fgets::@4
  __b4:
    // read += bytes
    // [1490] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1491] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1492] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [1493] if(fgets::$13!=$c0) goto fgets::@5 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b5
    // fgets::@8
    // ptr -= 0x2000
    // [1494] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1495] phi from fgets::@4 fgets::@8 to fgets::@5 [phi:fgets::@4/fgets::@8->fgets::@5]
    // [1495] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@4/fgets::@8->fgets::@5#0] -- register_copy 
    // fgets::@5
  __b5:
    // remaining -= bytes
    // [1496] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1497] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@13 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b13
    // [1471] phi from fgets::@13 fgets::@5 to fgets::@return [phi:fgets::@13/fgets::@5->fgets::@return]
    // [1471] phi fgets::return#1 = fgets::read#1 [phi:fgets::@13/fgets::@5->fgets::@return#0] -- register_copy 
    rts
    // fgets::@13
  __b13:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1498] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b6+
    jmp __b6
  !__b6:
    rts
    // fgets::@2
  __b2:
    // cx16_k_macptr(512, ptr)
    // [1499] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [1500] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1501] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1502] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@11
    // bytes = cx16_k_macptr(512, ptr)
    // [1503] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b12
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
// __zp($5a) char rom_byte_verify(__zp($45) char *ptr_rom, __zp($42) char value)
rom_byte_verify: {
    .label return = $5a
    .label ptr_rom = $45
    .label value = $42
    // if (*ptr_rom != value)
    // [1504] if(*rom_byte_verify::ptr_rom#0==rom_byte_verify::value#0) goto rom_byte_verify::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1505] phi from rom_byte_verify to rom_byte_verify::@2 [phi:rom_byte_verify->rom_byte_verify::@2]
    // rom_byte_verify::@2
    // [1506] phi from rom_byte_verify::@2 to rom_byte_verify::@1 [phi:rom_byte_verify::@2->rom_byte_verify::@1]
    // [1506] phi rom_byte_verify::return#0 = 0 [phi:rom_byte_verify::@2->rom_byte_verify::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [1506] phi from rom_byte_verify to rom_byte_verify::@1 [phi:rom_byte_verify->rom_byte_verify::@1]
  __b2:
    // [1506] phi rom_byte_verify::return#0 = 1 [phi:rom_byte_verify->rom_byte_verify::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_verify::@1
    // rom_byte_verify::@return
    // }
    // [1507] return 
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
// void rom_wait(__zp($34) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $33
    .label rom_wait__1 = $32
    .label test1 = $33
    .label test2 = $32
    .label ptr_rom = $34
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [1509] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [1510] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [1511] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [1512] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [1513] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [1514] return 
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
// void rom_byte_program(__zp($56) unsigned long address, __zp($5a) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $48
    .label rom_ptr1_rom_byte_program__2 = $48
    .label rom_ptr1_return = $48
    .label address = $56
    .label value = $5a
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1516] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [1517] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1518] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [1519] rom_write_byte::address#3 = rom_byte_program::address#0
    // [1520] rom_write_byte::value#3 = rom_byte_program::value#0
    // [1521] call rom_write_byte
    // [1525] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [1525] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [1525] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [1522] rom_wait::ptr_rom#0 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [1523] call rom_wait
    // [1508] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [1508] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [1524] return 
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
// void rom_write_byte(__zp($56) unsigned long address, __zp($5a) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $4a
    .label rom_bank1_rom_write_byte__1 = $33
    .label rom_bank1_rom_write_byte__2 = $45
    .label rom_ptr1_rom_write_byte__0 = $43
    .label rom_ptr1_rom_write_byte__2 = $43
    .label rom_bank1_bank_unshifted = $45
    .label rom_bank1_return = $32
    .label rom_ptr1_return = $43
    .label address = $56
    .label value = $5a
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [1526] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [1527] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1528] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1529] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1530] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1531] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [1532] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1533] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [1534] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [1535] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [1536] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $6d
    .label insertup__4 = $60
    .label insertup__6 = $61
    .label insertup__7 = $60
    .label width = $6d
    .label y = $5d
    // __conio.width+1
    // [1537] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [1538] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [1539] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1539] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1540] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [1541] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1542] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1543] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1544] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1545] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [1546] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [1547] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [1548] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1549] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [1550] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1551] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [1552] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1553] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1539] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1539] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $4c
    .label clearline__1 = $4f
    .label clearline__2 = $50
    .label clearline__3 = $4d
    .label addr = $5e
    .label c = $36
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1554] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [1555] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1556] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1557] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1558] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1559] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1560] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1561] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1562] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1563] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1564] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1564] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1565] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1566] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1567] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1568] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
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
// __zp($28) unsigned int utoa_append(__zp($48) char *buffer, __zp($28) unsigned int value, __zp($30) unsigned int sub)
utoa_append: {
    .label buffer = $48
    .label value = $28
    .label sub = $30
    .label return = $28
    .label digit = $22
    // [1571] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1571] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1571] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1572] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1573] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
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
    // [1575] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1576] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1571] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1571] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1571] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label strupr__0 = $38
    .label src = $3c
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
    // [1581] toupper::ch#0 = *strupr::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z toupper.ch
    // [1582] call toupper
    jsr toupper
    // [1583] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1584] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1585] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbuz2 
    lda.z strupr__0
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
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($3c) char *dst, __zp($34) const char *src, __zp($30) unsigned int n)
strncpy: {
    .label c = $33
    .label dst = $3c
    .label i = $48
    .label src = $34
    .label n = $30
    // [1588] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1588] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [1588] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [1588] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1589] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
    lda.z i+1
    cmp.z n+1
    bcc __b2
    bne !+
    lda.z i
    cmp.z n
    bcc __b2
  !:
    // strncpy::@return
    // }
    // [1590] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1591] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1592] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1593] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1594] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1594] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1595] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1596] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1597] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1588] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1588] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1588] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1588] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
// __zp($27) char uctoa_append(__zp($48) char *buffer, __zp($27) char value, __zp($2b) char sub)
uctoa_append: {
    .label buffer = $48
    .label value = $27
    .label sub = $2b
    .label return = $27
    .label digit = $22
    // [1599] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1599] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1599] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1600] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1601] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1602] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1603] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1604] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [1599] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1599] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1599] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($23) unsigned long value, __zp($34) char *buffer, char radix)
ultoa: {
    .label ultoa__10 = $4a
    .label ultoa__11 = $32
    .label digit_value = $2c
    .label buffer = $34
    .label digit = $38
    .label value = $23
    .label started = $55
    // [1606] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1606] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1606] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1606] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1606] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1607] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1608] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [1609] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1610] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1611] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1612] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1613] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [1614] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [1615] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [1616] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1617] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1617] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1617] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1617] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1618] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1606] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1606] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1606] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1606] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1606] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1619] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1620] ultoa_append::value#0 = ultoa::value#2
    // [1621] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1622] call ultoa_append
    // [1656] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1623] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1624] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1625] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1617] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1617] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1617] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1617] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
}
  // cx16_k_macptr
/**
 * @brief Read a number of bytes from the sdcard using kernal macptr call.
 * BRAM bank needs to be set properly before the load between adressed A000 and BFFF.
 *
 * @return x the size of bytes read
 * @return y the size of bytes read
 * @return if carry is set there is an error
 */
// __zp($48) unsigned int cx16_k_macptr(__zp($79) volatile char bytes, __zp($76) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $79
    .label buffer = $76
    .label bytes_read = $6e
    .label return = $48
    // unsigned int bytes_read
    // [1626] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
    lda #<0
    sta.z bytes_read
    sta.z bytes_read+1
    // asm
    // asm { ldabytes ldxbuffer ldybuffer+1 clc jsrCX16_MACPTR stxbytes_read stybytes_read+1 bcc!+ lda#$FF stabytes_read stabytes_read+1 !:  }
    lda bytes
    ldx buffer
    ldy buffer+1
    clc
    jsr CX16_MACPTR
    stx bytes_read
    sty bytes_read+1
    bcc !+
    lda #$ff
    sta bytes_read
    sta bytes_read+1
  !:
    // return bytes_read;
    // [1628] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [1629] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [1630] return 
    rts
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
// void memcpy8_vram_vram(__zp($4d) char dbank_vram, __zp($5e) unsigned int doffset_vram, __zp($4c) char sbank_vram, __zp($5b) unsigned int soffset_vram, __zp($37) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $4f
    .label memcpy8_vram_vram__1 = $50
    .label memcpy8_vram_vram__2 = $4c
    .label memcpy8_vram_vram__3 = $51
    .label memcpy8_vram_vram__4 = $52
    .label memcpy8_vram_vram__5 = $4d
    .label num8 = $37
    .label dbank_vram = $4d
    .label doffset_vram = $5e
    .label sbank_vram = $4c
    .label soffset_vram = $5b
    .label num8_1 = $36
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1631] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1632] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1633] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1634] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1635] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1636] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1637] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1638] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1639] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1640] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1641] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1642] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1643] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1644] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1645] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1645] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1646] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [1647] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1648] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1649] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1650] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
    lda.z num8
    sta.z num8_1
    jmp __b1
}
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __zp($38) char toupper(__zp($38) char ch)
toupper: {
    .label return = $38
    .label ch = $38
    // if(ch>='a' && ch<='z')
    // [1651] if(toupper::ch#0<'a'pm) goto toupper::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z ch
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1652] if(toupper::ch#0<='z'pm) goto toupper::@1 -- vbuz1_le_vbuc1_then_la1 
    lda #'z'
    cmp.z ch
    bcs __b1
    // [1654] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1654] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1653] toupper::return#0 = toupper::ch#0 + 'A'pm-'a'pm -- vbuz1=vbuz1_plus_vbuc1 
    lda #'A'-'a'
    clc
    adc.z return
    sta.z return
    // toupper::@return
  __breturn:
    // }
    // [1655] return 
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
// __zp($23) unsigned long ultoa_append(__zp($45) char *buffer, __zp($23) unsigned long value, __zp($2c) unsigned long sub)
ultoa_append: {
    .label buffer = $45
    .label value = $23
    .label sub = $2c
    .label return = $23
    .label digit = $2a
    // [1657] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1657] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1657] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1658] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [1659] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1660] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1661] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1662] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [1657] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1657] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1657] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // File Data
.segment Data
  /**
 * @file errno.c
 * @author Sven Van de Velde (sven.van.de.velde@telenet.be)
 * @brief Contains the POSIX implementation of errno, which contains the last error detected.
 * @version 0.1
 * @date 2023-03-18
 * 
 * @copyright Copyright (c) 2023
 * 
 */
  __errno_error: .fill $20, 0
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
  file: .fill $20, 0
  str: .text " "
  .byte 0
  isr_vsync: .word $314
  __conio: .fill SIZEOF_STRUCT___1, 0
  // Buffer used for stringified number being printed
  printf_buffer: .fill SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER, 0
  __stdio_file: .fill SIZEOF_STRUCT___2, 0
  __stdio_filecount: .byte 0
