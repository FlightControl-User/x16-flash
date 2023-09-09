  // File Comments
/**
 * @mainpage cx16-rom-flash.c
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @brief COMMANDER X16 ROM FLASH UTILITY
 *
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
.file [name="FLASH-CX16-SMC.prg", type="prg", segments="Program"]
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
  .const BLUE = 6
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
  ///< CX16 Faster loading from SDCARD.
  .const CX16_I2C_READ_BYTE = $fec6
  .const VERA_INC_1 = $10
  .const VERA_DCSEL = 2
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
  /// $9F29	DC_HSTART (DCSEL=1)	Active Display H-Start (9:2)
  .label VERA_DC_HSTART = $9f29
  /// $9F2A	DC_HSTOP (DCSEL=1)	Active Display H-Stop (9:2)
  .label VERA_DC_HSTOP = $9f2a
  /// $9F2B	DC_VSTART (DCSEL=1)	Active Display V-Start (8:1)
  .label VERA_DC_VSTART = $9f2b
  /// $9F2C	DC_VSTOP (DCSEL=1)	Active Display V-Stop (8:1)
  .label VERA_DC_VSTOP = $9f2c
  /// $9F34	L1_CONFIG   Layer 1 Configuration
  .label VERA_L1_CONFIG = $9f34
  /// $9F35	L1_MAPBASE	    Layer 1 Map Base Address (16:9)
  .label VERA_L1_MAPBASE = $9f35
  .label BRAM = 0
  .label BROM = 1
  .label __stdio_filecount = $d8
  .label __errno = $76
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
    // [3] __stdio_filecount = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z __stdio_filecount
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
    .label conio_x16_init__4 = $6b
    .label conio_x16_init__5 = $4f
    .label conio_x16_init__6 = $6b
    .label conio_x16_init__7 = $d7
    // screenlayer1()
    // [10] call screenlayer1
    jsr screenlayer1
    // [11] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [12] call textcolor
    // [168] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [13] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [14] call bgcolor
    // [173] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [26] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuz1=_byte0_vwuz2 
    lda.z conio_x16_init__6
    sta.z conio_x16_init__7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [27] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbuz1 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [28] gotoxy::x#2 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z gotoxy.x
    // [29] gotoxy::y#2 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z gotoxy.y
    // [30] call gotoxy
    // [186] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [186] phi gotoxy::y#17 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [186] phi gotoxy::x#17 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
}
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__zp($2c) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $39
    .label cputc__3 = $3a
    .label c = $2c
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
/*
unsigned long flash_smc_verify(unsigned char y, unsigned char w, unsigned char b, unsigned int r, ram_ptr_t flash_ram_address, unsigned int flash_size) {

    unsigned long flash_smc_difference = 0; /// Holds the amount of bytes that are different.
    unsigned int flash_row_total = 0;

    textcolor(WHITE);
    gotoxy(0, y);

    unsigned int smc_difference = 0;

    // We compare b bytes at a time, and each b bytes we plot a dot.
    // Every r bytes we move to the next line.
    while (smc_difference = smc_compare(flash_ram_address, b)) {

        if (flash_row_total == r) {
            gotoxy(0, ++y);
            flash_row_total = 0;
        }

        if(smc_difference)
            cputc('*');
        else
            cputc('.');

        flash_ram_address += b;
        flash_smc_difference += smc_difference;
        flash_row_total += b;
        smc_difference = 0;
    }

    // We return the total smc difference.
    return smc_difference;
}

*/
main: {
    .const bank_set_bram1_bank = 1
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 4
    .label smc_bootloader = $43
    .label fp = $49
    .label flash_bytes = $b8
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [63] phi from main::CLI1 to main::@9 [phi:main::CLI1->main::@9]
    // main::@9
    // frame_init()
    // [64] call frame_init
    // [207] phi from main::@9 to frame_init [phi:main::@9->frame_init]
    jsr frame_init
    // [65] phi from main::@9 to main::@13 [phi:main::@9->main::@13]
    // main::@13
    // frame_draw()
    // [66] call frame_draw
    // [229] phi from main::@13 to frame_draw [phi:main::@13->frame_draw]
    jsr frame_draw
    // [67] phi from main::@13 to main::@14 [phi:main::@13->main::@14]
    // main::@14
    // gotoxy(2, 1)
    // [68] call gotoxy
  // wait_key();
    // [186] phi from main::@14 to gotoxy [phi:main::@14->gotoxy]
    // [186] phi gotoxy::y#17 = 1 [phi:main::@14->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = 2 [phi:main::@14->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [69] phi from main::@14 to main::@15 [phi:main::@14->main::@15]
    // main::@15
    // printf("commander x16 flash utility")
    // [70] call printf_str
    // [266] phi from main::@15 to printf_str [phi:main::@15->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@15->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s [phi:main::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [72] phi from main::CLI2 to main::@10 [phi:main::CLI2->main::@10]
    // main::@10
    // print_smc_chip()
    // [73] call print_smc_chip
    // [275] phi from main::@10 to print_smc_chip [phi:main::@10->print_smc_chip]
    jsr print_smc_chip
    // [74] phi from main::@10 to main::@16 [phi:main::@10->main::@16]
    // main::@16
    // print_vera_chip()
    // [75] call print_vera_chip
    // [280] phi from main::@16 to print_vera_chip [phi:main::@16->print_vera_chip]
    jsr print_vera_chip
    // [76] phi from main::@16 to main::@17 [phi:main::@16->main::@17]
    // main::@17
    // print_rom_chips()
    // [77] call print_rom_chips
    // [285] phi from main::@17 to print_rom_chips [phi:main::@17->print_rom_chips]
    jsr print_rom_chips
    // [78] phi from main::@17 to main::@18 [phi:main::@17->main::@18]
    // main::@18
    // progress_chip_clear(17, 64, 32)
    // [79] call progress_chip_clear
    // [299] phi from main::@18 to progress_chip_clear [phi:main::@18->progress_chip_clear]
    jsr progress_chip_clear
    // [80] phi from main::@18 to main::@19 [phi:main::@18->main::@19]
    // main::@19
    // print_clear()
    // [81] call print_clear
    // [315] phi from main::@19 to print_clear [phi:main::@19->print_clear]
    jsr print_clear
    // [82] phi from main::@19 to main::@20 [phi:main::@19->main::@20]
    // main::@20
    // printf("%s", "Detecting rom chipset and bootloader presence.")
    // [83] call printf_string
    // [324] phi from main::@20 to printf_string [phi:main::@20->printf_string]
    // [324] phi printf_string::str#10 = main::str [phi:main::@20->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [324] phi printf_string::format_min_length#3 = 0 [phi:main::@20->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // [84] phi from main::@20 to main::@21 [phi:main::@20->main::@21]
    // main::@21
    // gotoxy(0, 2)
    // [85] call gotoxy
    // [186] phi from main::@21 to gotoxy [phi:main::@21->gotoxy]
    // [186] phi gotoxy::y#17 = 2 [phi:main::@21->gotoxy#0] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = 0 [phi:main::@21->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [86] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::bank_set_brom1
    // BROM = bank
    // [87] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [88] phi from main::bank_set_brom1 to main::@11 [phi:main::bank_set_brom1->main::@11]
    // main::@11
    // unsigned int smc_bootloader = flash_smc_detect()
    // [89] call flash_smc_detect
    // Detect the SMC bootloader and turn the SMC chip GREY if there is a bootloader present.
    // Otherwise, stop flashing and display next steps.
    jsr flash_smc_detect
    // [90] flash_smc_detect::return#4 = flash_smc_detect::return#1
    // main::@22
    // [91] main::smc_bootloader#0 = flash_smc_detect::return#4
    // if(smc_bootloader == 0x0100)
    // [92] if(main::smc_bootloader#0!=$100) goto main::@1 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_bootloader+1
    cmp #>$100
    bne __b1
    lda.z smc_bootloader
    cmp #<$100
    bne __b1
    // [93] phi from main::@22 to main::@4 [phi:main::@22->main::@4]
    // main::@4
    // print_clear()
    // [94] call print_clear
    // [315] phi from main::@4 to print_clear [phi:main::@4->print_clear]
    jsr print_clear
    // [95] phi from main::@4 to main::@23 [phi:main::@4->main::@23]
    // main::@23
    // printf("there is no smc bootloader on this x16 board. exiting ...")
    // [96] call printf_str
    // [266] phi from main::@23 to printf_str [phi:main::@23->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s1 [phi:main::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [97] phi from main::@23 to main::@24 [phi:main::@23->main::@24]
    // main::@24
    // wait_key()
    // [98] call wait_key
    // [352] phi from main::@24 to wait_key [phi:main::@24->wait_key]
    jsr wait_key
    // main::@return
    // }
    // [99] return 
    rts
    // main::@1
  __b1:
    // if(smc_bootloader == 0x0200)
    // [100] if(main::smc_bootloader#0!=$200) goto main::@2 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_bootloader+1
    cmp #>$200
    bne __b2
    lda.z smc_bootloader
    cmp #<$200
    bne __b2
    // [101] phi from main::@1 to main::@5 [phi:main::@1->main::@5]
    // main::@5
    // print_clear()
    // [102] call print_clear
    // [315] phi from main::@5 to print_clear [phi:main::@5->print_clear]
    jsr print_clear
    // [103] phi from main::@5 to main::@34 [phi:main::@5->main::@34]
    // main::@34
    // printf("there was an error reading the i2c api. exiting ...")
    // [104] call printf_str
    // [266] phi from main::@34 to printf_str [phi:main::@34->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@34->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s5 [phi:main::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [105] phi from main::@34 to main::@35 [phi:main::@34->main::@35]
    // main::@35
    // wait_key()
    // [106] call wait_key
    // [352] phi from main::@35 to wait_key [phi:main::@35->wait_key]
    jsr wait_key
    rts
    // [107] phi from main::@1 to main::@2 [phi:main::@1->main::@2]
    // main::@2
  __b2:
    // print_clear()
    // [108] call print_clear
    // [315] phi from main::@2 to print_clear [phi:main::@2->print_clear]
    jsr print_clear
    // [109] phi from main::@2 to main::@25 [phi:main::@2->main::@25]
    // main::@25
    // printf("this x16 board has an smc bootloader version %u", smc_bootloader)
    // [110] call printf_str
    // [266] phi from main::@25 to printf_str [phi:main::@25->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@25->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s2 [phi:main::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@26
    // printf("this x16 board has an smc bootloader version %u", smc_bootloader)
    // [111] printf_uint::uvalue#0 = main::smc_bootloader#0
    // [112] call printf_uint
    // [363] phi from main::@26 to printf_uint [phi:main::@26->printf_uint]
    jsr printf_uint
    // [113] phi from main::@26 to main::@27 [phi:main::@26->main::@27]
    // main::@27
    // print_clear()
    // [114] call print_clear
    // [315] phi from main::@27 to print_clear [phi:main::@27->print_clear]
    jsr print_clear
    // [115] phi from main::@27 to main::@28 [phi:main::@27->main::@28]
    // main::@28
    // printf("opening %s.", file)
    // [116] call printf_str
    // [266] phi from main::@28 to printf_str [phi:main::@28->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@28->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s3 [phi:main::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // [117] phi from main::@28 to main::@29 [phi:main::@28->main::@29]
    // main::@29
    // printf("opening %s.", file)
    // [118] call printf_string
    // [324] phi from main::@29 to printf_string [phi:main::@29->printf_string]
    // [324] phi printf_string::str#10 = file [phi:main::@29->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [324] phi printf_string::format_min_length#3 = 0 [phi:main::@29->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_min_length
    jsr printf_string
    // [119] phi from main::@29 to main::@30 [phi:main::@29->main::@30]
    // main::@30
    // printf("opening %s.", file)
    // [120] call printf_str
    // [266] phi from main::@30 to printf_str [phi:main::@30->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@30->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s4 [phi:main::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [121] phi from main::@30 to main::@31 [phi:main::@30->main::@31]
    // main::@31
    // strcpy(file, "smc.bin")
    // [122] call strcpy
    // [370] phi from main::@31 to strcpy [phi:main::@31->strcpy]
    jsr strcpy
    // [123] phi from main::@31 to main::@32 [phi:main::@31->main::@32]
    // main::@32
    // FILE *fp = fopen(file,"r")
    // [124] call fopen
    // Read the smc file content.
    jsr fopen
    // [125] fopen::return#3 = fopen::return#2
    // main::@33
    // [126] main::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [127] if((struct $2 *)0!=main::fp#0) goto main::@3 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    bne __b3
    lda.z fp
    cmp #<0
    bne __b3
    // [128] phi from main::@33 to main::@6 [phi:main::@33->main::@6]
    // main::@6
    // print_clear()
    // [129] call print_clear
    // [315] phi from main::@6 to print_clear [phi:main::@6->print_clear]
    jsr print_clear
    // [130] phi from main::@6 to main::@42 [phi:main::@6->main::@42]
    // main::@42
    // printf("there is no smc.bin file on the sdcard to flash the smc chip. press a key ...")
    // [131] call printf_str
    // [266] phi from main::@42 to printf_str [phi:main::@42->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@42->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s7 [phi:main::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // [132] phi from main::@42 to main::@43 [phi:main::@42->main::@43]
    // main::@43
    // gotoxy(2, 58)
    // [133] call gotoxy
    // [186] phi from main::@43 to gotoxy [phi:main::@43->gotoxy]
    // [186] phi gotoxy::y#17 = $3a [phi:main::@43->gotoxy#0] -- vbuz1=vbuc1 
    lda #$3a
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = 2 [phi:main::@43->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [134] phi from main::@43 to main::@44 [phi:main::@43->main::@44]
    // main::@44
    // printf("no file")
    // [135] call printf_str
    // [266] phi from main::@44 to printf_str [phi:main::@44->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@44->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s8 [phi:main::@44->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [136] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // [138] phi from main::CLI3 to main::@12 [phi:main::CLI3->main::@12]
    // main::@12
    // wait_key()
    // [139] call wait_key
    // [352] phi from main::@12 to wait_key [phi:main::@12->wait_key]
    jsr wait_key
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    rts
    // [141] phi from main::@33 to main::@3 [phi:main::@33->main::@3]
    // main::@3
  __b3:
    // progress_chip_clear(17, 64, 32)
    // [142] call progress_chip_clear
    // [299] phi from main::@3 to progress_chip_clear [phi:main::@3->progress_chip_clear]
    jsr progress_chip_clear
    // [143] phi from main::@3 to main::@36 [phi:main::@3->main::@36]
    // main::@36
    // textcolor(WHITE)
    // [144] call textcolor
    // [168] phi from main::@36 to textcolor [phi:main::@36->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:main::@36->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [145] phi from main::@36 to main::@37 [phi:main::@36->main::@37]
    // main::@37
    // print_smc_led(CYAN)
    // [146] call print_smc_led
  // We first detect if there is a bootloader routine present on the SMC.
  // In the case there isn't a bootloader, the X16 board update process cannot continue
  // and a manual update process needs to be conducted. 
    // [457] phi from main::@37 to print_smc_led [phi:main::@37->print_smc_led]
    // [457] phi print_smc_led::c#2 = CYAN [phi:main::@37->print_smc_led#0] -- vbuz1=vbuc1 
    lda #CYAN
    sta.z print_smc_led.c
    jsr print_smc_led
    // [147] phi from main::@37 to main::@38 [phi:main::@37->main::@38]
    // main::@38
    // print_clear()
    // [148] call print_clear
    // [315] phi from main::@38 to print_clear [phi:main::@38->print_clear]
    jsr print_clear
    // [149] phi from main::@38 to main::@39 [phi:main::@38->main::@39]
    // main::@39
    // printf("reading data for smc update in ram ...")
    // [150] call printf_str
    // [266] phi from main::@39 to printf_str [phi:main::@39->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@39->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s6 [phi:main::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@40
    // unsigned long flash_bytes = flash_read(17, 64, 4, 256, fp, (ram_ptr_t)0x4000)
    // [151] flash_read::fp#0 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [152] call flash_read
    // [461] phi from main::@40 to flash_read [phi:main::@40->flash_read]
    jsr flash_read
    // unsigned long flash_bytes = flash_read(17, 64, 4, 256, fp, (ram_ptr_t)0x4000)
    // [153] flash_read::return#2 = flash_read::flash_bytes#2
    // main::@41
    // [154] main::flash_bytes#0 = flash_read::return#2
    // if (flash_bytes == 0)
    // [155] if(main::flash_bytes#0!=0) goto main::@8 -- vduz1_neq_0_then_la1 
    lda.z flash_bytes
    ora.z flash_bytes+1
    ora.z flash_bytes+2
    ora.z flash_bytes+3
    bne __b8
    // [156] phi from main::@41 to main::@7 [phi:main::@41->main::@7]
    // main::@7
    // printf("error reading file.")
    // [157] call printf_str
    // [266] phi from main::@7 to printf_str [phi:main::@7->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@7->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s10 [phi:main::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    rts
    // main::@8
  __b8:
    // fclose(fp)
    // [158] fclose::stream#0 = main::fp#0
    // [159] call fclose
    jsr fclose
    // [160] phi from main::@8 to main::@45 [phi:main::@8->main::@45]
    // main::@45
    // print_clear()
    // [161] call print_clear
  // Now we compare the smc update data with the actual smc contents before flashing.
  // If everything is the same, we don't flash.
    // [315] phi from main::@45 to print_clear [phi:main::@45->print_clear]
    jsr print_clear
    // [162] phi from main::@45 to main::@46 [phi:main::@45->main::@46]
    // main::@46
    // printf("comparing smc with update ... (.) same, (*) different.")
    // [163] call printf_str
    // [266] phi from main::@46 to printf_str [phi:main::@46->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:main::@46->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = main::s9 [phi:main::@46->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    jmp bank_set_brom2
  .segment Data
    s: .text "commander x16 flash utility"
    .byte 0
    str: .text "Detecting rom chipset and bootloader presence."
    .byte 0
    s1: .text "there is no smc bootloader on this x16 board. exiting ..."
    .byte 0
    s2: .text "this x16 board has an smc bootloader version "
    .byte 0
    s3: .text "opening "
    .byte 0
    s4: .text "."
    .byte 0
    source: .text "smc.bin"
    .byte 0
    s5: .text "there was an error reading the i2c api. exiting ..."
    .byte 0
    s6: .text "reading data for smc update in ram ..."
    .byte 0
    s7: .text "there is no smc.bin file on the sdcard to flash the smc chip. press a key ..."
    .byte 0
    s8: .text "no file"
    .byte 0
    s9: .text "comparing smc with update ... (.) same, (*) different."
    .byte 0
    s10: .text "error reading file."
    .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [164] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [165] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [166] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [167] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($4f) char color)
textcolor: {
    .label textcolor__0 = $56
    .label textcolor__1 = $4f
    .label color = $4f
    // __conio.color & 0xF0
    // [169] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [170] textcolor::$1 = textcolor::$0 | textcolor::color#16 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [171] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [172] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($4f) char color)
bgcolor: {
    .label bgcolor__0 = $52
    .label bgcolor__1 = $4f
    .label bgcolor__2 = $52
    .label color = $4f
    // __conio.color & 0x0F
    // [174] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [175] bgcolor::$1 = bgcolor::color#13 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [176] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [177] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [178] return 
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
    // [179] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [180] return 
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
    // [181] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [182] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [184] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [185] return 
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
    .label gotoxy__2 = $33
    .label gotoxy__3 = $33
    .label gotoxy__6 = $32
    .label gotoxy__7 = $32
    .label gotoxy__8 = $37
    .label gotoxy__9 = $35
    .label gotoxy__10 = $34
    .label x = $33
    .label y = $34
    .label gotoxy__14 = $32
    // (x>=__conio.width)?__conio.width:x
    // [187] if(gotoxy::x#17>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [189] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [189] phi gotoxy::$3 = gotoxy::x#17 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [188] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [190] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [191] if(gotoxy::y#17>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [192] gotoxy::$14 = gotoxy::y#17 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [193] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [193] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [194] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [195] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [196] gotoxy::$10 = gotoxy::y#17 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [197] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [198] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [199] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [200] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $38
    // __conio.cursor_x = 0
    // [201] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [202] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [203] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [204] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [205] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [206] return 
    rts
}
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    .label cx16_k_screen_set_charset1_charset = $d1
    .label cx16_k_screen_set_charset1_offset = $c8
    // screenlayer1()
    // [208] call screenlayer1
    jsr screenlayer1
    // frame_init::@2
    // cx16_k_screen_set_charset(3, (char *)0)
    // [209] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbuz1=vbuc1 
    lda #3
    sta.z cx16_k_screen_set_charset1_charset
    // [210] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cx16_k_screen_set_charset1_offset
    sta.z cx16_k_screen_set_charset1_offset+1
    // frame_init::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // [212] phi from frame_init::cx16_k_screen_set_charset1 to frame_init::@1 [phi:frame_init::cx16_k_screen_set_charset1->frame_init::@1]
    // frame_init::@1
    // textcolor(WHITE)
    // [213] call textcolor
    // [168] phi from frame_init::@1 to textcolor [phi:frame_init::@1->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:frame_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [214] phi from frame_init::@1 to frame_init::@3 [phi:frame_init::@1->frame_init::@3]
    // frame_init::@3
    // bgcolor(BLUE)
    // [215] call bgcolor
    // [173] phi from frame_init::@3 to bgcolor [phi:frame_init::@3->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:frame_init::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [216] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // scroll(0)
    // [217] call scroll
    jsr scroll
    // [218] phi from frame_init::@4 to frame_init::@5 [phi:frame_init::@4->frame_init::@5]
    // frame_init::@5
    // clrscr()
    // [219] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [220] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [221] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [222] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [223] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [224] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [225] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [226] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [227] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@return
    // }
    // [228] return 
    rts
}
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [230] call textcolor
    // [168] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [231] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [232] call bgcolor
    // [173] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [233] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [234] call clrscr
    jsr clrscr
    // [235] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 15)
    // [236] call frame
    // [582] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [582] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [582] phi frame::y1#14 = $f [phi:frame_draw::@3->frame#1] -- vbuz1=vbuc1 
    lda #$f
    sta.z frame.y1
    // [582] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [582] phi frame::x1#14 = $43 [phi:frame_draw::@3->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [237] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [238] call frame
    // [582] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [582] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [582] phi frame::y1#14 = 2 [phi:frame_draw::@4->frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y1
    // [582] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [582] phi frame::x1#14 = $43 [phi:frame_draw::@4->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [239] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 13)
    // [240] call frame
    // [582] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@5->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [582] phi frame::x1#14 = $43 [phi:frame_draw::@5->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [241] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 13, 67, 15)
    // [242] call frame
    // [582] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [582] phi frame::y#0 = $d [phi:frame_draw::@6->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [582] phi frame::y1#14 = $f [phi:frame_draw::@6->frame#1] -- vbuz1=vbuc1 
    lda #$f
    sta.z frame.y1
    // [582] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [582] phi frame::x1#14 = $43 [phi:frame_draw::@6->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [243] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(0, 2, 8, 13)
    // [244] call frame
    // [582] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@7->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = 0 [phi:frame_draw::@7->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [582] phi frame::x1#14 = 8 [phi:frame_draw::@7->frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x1
    jsr frame
    // [245] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(8, 2, 19, 13)
    // [246] call frame
    // [582] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@8->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = 8 [phi:frame_draw::@8->frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x
    // [582] phi frame::x1#14 = $13 [phi:frame_draw::@8->frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x1
    jsr frame
    // [247] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(19, 2, 25, 13)
    // [248] call frame
    // [582] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@9->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = $13 [phi:frame_draw::@9->frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x
    // [582] phi frame::x1#14 = $19 [phi:frame_draw::@9->frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x1
    jsr frame
    // [249] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(25, 2, 31, 13)
    // [250] call frame
    // [582] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@10->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = $19 [phi:frame_draw::@10->frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x
    // [582] phi frame::x1#14 = $1f [phi:frame_draw::@10->frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x1
    jsr frame
    // [251] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(31, 2, 37, 13)
    // [252] call frame
    // [582] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@11->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = $1f [phi:frame_draw::@11->frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x
    // [582] phi frame::x1#14 = $25 [phi:frame_draw::@11->frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x1
    jsr frame
    // [253] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(37, 2, 43, 13)
    // [254] call frame
    // [582] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@12->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = $25 [phi:frame_draw::@12->frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x
    // [582] phi frame::x1#14 = $2b [phi:frame_draw::@12->frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x1
    jsr frame
    // [255] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(43, 2, 49, 13)
    // [256] call frame
    // [582] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@13->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = $2b [phi:frame_draw::@13->frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x
    // [582] phi frame::x1#14 = $31 [phi:frame_draw::@13->frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x1
    jsr frame
    // [257] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(49, 2, 55, 13)
    // [258] call frame
    // [582] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@14->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = $31 [phi:frame_draw::@14->frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x
    // [582] phi frame::x1#14 = $37 [phi:frame_draw::@14->frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x1
    jsr frame
    // [259] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(55, 2, 61, 13)
    // [260] call frame
    // [582] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@15->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = $37 [phi:frame_draw::@15->frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x
    // [582] phi frame::x1#14 = $3d [phi:frame_draw::@15->frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x1
    jsr frame
    // [261] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(61, 2, 67, 13)
    // [262] call frame
    // [582] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [582] phi frame::y#0 = 2 [phi:frame_draw::@16->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [582] phi frame::y1#14 = $d [phi:frame_draw::@16->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [582] phi frame::x#0 = $3d [phi:frame_draw::@16->frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x
    // [582] phi frame::x1#14 = $43 [phi:frame_draw::@16->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [263] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // cputsxy(2, 14, "status")
    // [264] call cputsxy
  // cputsxy(2, 3, "led colors");
  // cputsxy(2, 5, "    no chip"); print_chip_led(2, 5, DARK_GREY, BLUE);
  // cputsxy(2, 6, "    update"); print_chip_led(2, 6, CYAN, BLUE);
  // cputsxy(2, 7, "    ok"); print_chip_led(2, 7, WHITE, BLUE);
  // cputsxy(2, 8, "    todo"); print_chip_led(2, 8, PURPLE, BLUE);
  // cputsxy(2, 9, "    error"); print_chip_led(2, 9, RED, BLUE);
  // cputsxy(2, 10, "    no file"); print_chip_led(2, 10, GREY, BLUE);
    // [716] phi from frame_draw::@17 to cputsxy [phi:frame_draw::@17->cputsxy]
    jsr cputsxy
    // frame_draw::@return
    // }
    // [265] return 
    rts
  .segment Data
    s: .text "status"
    .byte 0
}
.segment Code
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($b3) void (*putc)(char), __zp($3b) const char *s)
printf_str: {
    .label c = $5e
    .label s = $3b
    .label putc = $b3
    // [267] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [267] phi printf_str::s#14 = printf_str::s#15 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [268] printf_str::c#1 = *printf_str::s#14 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [269] printf_str::s#0 = ++ printf_str::s#14 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [270] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [271] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [272] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [273] callexecute *printf_str::putc#15  -- call__deref_pprz1 
    jsr icall1
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall1:
    jmp (putc)
}
  // print_smc_chip
print_smc_chip: {
    // print_smc_led(GREY)
    // [276] call print_smc_led
    // [457] phi from print_smc_chip to print_smc_led [phi:print_smc_chip->print_smc_led]
    // [457] phi print_smc_led::c#2 = GREY [phi:print_smc_chip->print_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_smc_led.c
    jsr print_smc_led
    // [277] phi from print_smc_chip to print_smc_chip::@1 [phi:print_smc_chip->print_smc_chip::@1]
    // print_smc_chip::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ")
    // [278] call print_chip
    // [721] phi from print_smc_chip::@1 to print_chip [phi:print_smc_chip::@1->print_chip]
    // [721] phi print_chip::text#11 = print_smc_chip::text [phi:print_smc_chip::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [721] phi print_chip::w#10 = 5 [phi:print_smc_chip::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip.w
    // [721] phi print_chip::x#10 = 1 [phi:print_smc_chip::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z print_chip.x
    jsr print_chip
    // print_smc_chip::@return
    // }
    // [279] return 
    rts
  .segment Data
    text: .text "smc     "
    .byte 0
}
.segment Code
  // print_vera_chip
print_vera_chip: {
    // print_vera_led(GREY)
    // [281] call print_vera_led
    // [765] phi from print_vera_chip to print_vera_led [phi:print_vera_chip->print_vera_led]
    jsr print_vera_led
    // [282] phi from print_vera_chip to print_vera_chip::@1 [phi:print_vera_chip->print_vera_chip::@1]
    // print_vera_chip::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ")
    // [283] call print_chip
    // [721] phi from print_vera_chip::@1 to print_chip [phi:print_vera_chip::@1->print_chip]
    // [721] phi print_chip::text#11 = print_vera_chip::text [phi:print_vera_chip::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [721] phi print_chip::w#10 = 7 [phi:print_vera_chip::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #7
    sta.z print_chip.w
    // [721] phi print_chip::x#10 = 9 [phi:print_vera_chip::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z print_chip.x
    jsr print_chip
    // print_vera_chip::@return
    // }
    // [284] return 
    rts
  .segment Data
    text: .text "vera     "
    .byte 0
}
.segment Code
  // print_rom_chips
print_rom_chips: {
    .label print_rom_chips__1 = $59
    .label print_rom_chips__3 = $67
    .label r = $68
    .label print_rom_chips__6 = $67
    .label print_rom_chips__7 = $67
    // [286] phi from print_rom_chips to print_rom_chips::@1 [phi:print_rom_chips->print_rom_chips::@1]
    // [286] phi print_rom_chips::r#2 = 0 [phi:print_rom_chips->print_rom_chips::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // print_rom_chips::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [287] if(print_rom_chips::r#2<8) goto print_rom_chips::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // print_rom_chips::@return
    // }
    // [288] return 
    rts
    // print_rom_chips::@2
  __b2:
    // r+'0'
    // [289] print_rom_chips::$1 = print_rom_chips::r#2 + '0'pm -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z print_rom_chips__1
    // *(rom+3) = r+'0'
    // [290] *(print_rom_chips::rom+3) = print_rom_chips::$1 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // print_rom_led(r, GREY)
    // [291] print_rom_led::chip#0 = print_rom_chips::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_rom_led.chip
    // [292] call print_rom_led
    jsr print_rom_led
    // print_rom_chips::@3
    // r*6
    // [293] print_rom_chips::$6 = print_rom_chips::r#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z r
    asl
    sta.z print_rom_chips__6
    // [294] print_rom_chips::$7 = print_rom_chips::$6 + print_rom_chips::r#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z print_rom_chips__7
    clc
    adc.z r
    sta.z print_rom_chips__7
    // [295] print_rom_chips::$3 = print_rom_chips::$7 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_chips__3
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+1, CHIP_ROM_W, rom)
    // [296] print_chip::x#2 = $14 + print_rom_chips::$3 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z print_chip.x
    sta.z print_chip.x
    // [297] call print_chip
    // [721] phi from print_rom_chips::@3 to print_chip [phi:print_rom_chips::@3->print_chip]
    // [721] phi print_chip::text#11 = print_rom_chips::rom [phi:print_rom_chips::@3->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [721] phi print_chip::w#10 = 3 [phi:print_rom_chips::@3->print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip.w
    // [721] phi print_chip::x#10 = print_chip::x#2 [phi:print_rom_chips::@3->print_chip#2] -- register_copy 
    jsr print_chip
    // print_rom_chips::@4
    // for (unsigned char r = 0; r < 8; r++)
    // [298] print_rom_chips::r#1 = ++ print_rom_chips::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [286] phi from print_rom_chips::@4 to print_rom_chips::@1 [phi:print_rom_chips::@4->print_rom_chips::@1]
    // [286] phi print_rom_chips::r#2 = print_rom_chips::r#1 [phi:print_rom_chips::@4->print_rom_chips::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .text "rom0 000"
    .byte 0
}
.segment Code
  // progress_chip_clear
/**
 * @brief Clean the progress area for the flashing.
 * 
 * @param y y start position
 * @param w width of the progress area
 * @param h height of the progress area
 */
// void progress_chip_clear(__zp($4e) char y, char w, char h)
progress_chip_clear: {
    .const h = $20+$11
    .label i = $55
    .label y = $4e
    // textcolor(WHITE)
    // [300] call textcolor
    // [168] phi from progress_chip_clear to textcolor [phi:progress_chip_clear->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:progress_chip_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [301] phi from progress_chip_clear to progress_chip_clear::@6 [phi:progress_chip_clear->progress_chip_clear::@6]
    // progress_chip_clear::@6
    // bgcolor(BLUE)
    // [302] call bgcolor
    // [173] phi from progress_chip_clear::@6 to bgcolor [phi:progress_chip_clear::@6->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:progress_chip_clear::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [303] phi from progress_chip_clear::@6 to progress_chip_clear::@1 [phi:progress_chip_clear::@6->progress_chip_clear::@1]
    // [303] phi progress_chip_clear::y#11 = $11 [phi:progress_chip_clear::@6->progress_chip_clear::@1#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z y
    // progress_chip_clear::@1
  __b1:
    // while (y < h)
    // [304] if(progress_chip_clear::y#11<progress_chip_clear::h#0) goto progress_chip_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b2
    // progress_chip_clear::@return
    // }
    // [305] return 
    rts
    // progress_chip_clear::@2
  __b2:
    // gotoxy(0, y)
    // [306] gotoxy::y#11 = progress_chip_clear::y#11 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [307] call gotoxy
    // [186] phi from progress_chip_clear::@2 to gotoxy [phi:progress_chip_clear::@2->gotoxy]
    // [186] phi gotoxy::y#17 = gotoxy::y#11 [phi:progress_chip_clear::@2->gotoxy#0] -- register_copy 
    // [186] phi gotoxy::x#17 = 0 [phi:progress_chip_clear::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [308] phi from progress_chip_clear::@2 to progress_chip_clear::@3 [phi:progress_chip_clear::@2->progress_chip_clear::@3]
    // [308] phi progress_chip_clear::i#2 = 0 [phi:progress_chip_clear::@2->progress_chip_clear::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // progress_chip_clear::@3
  __b3:
    // for(unsigned char i = 0; i < w; i++)
    // [309] if(progress_chip_clear::i#2<$40) goto progress_chip_clear::@4 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #$40
    bcc __b4
    // progress_chip_clear::@5
    // y++;
    // [310] progress_chip_clear::y#0 = ++ progress_chip_clear::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [303] phi from progress_chip_clear::@5 to progress_chip_clear::@1 [phi:progress_chip_clear::@5->progress_chip_clear::@1]
    // [303] phi progress_chip_clear::y#11 = progress_chip_clear::y#0 [phi:progress_chip_clear::@5->progress_chip_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_chip_clear::@4
  __b4:
    // cputc('.')
    // [311] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [312] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(unsigned char i = 0; i < w; i++)
    // [314] progress_chip_clear::i#1 = ++ progress_chip_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [308] phi from progress_chip_clear::@4 to progress_chip_clear::@3 [phi:progress_chip_clear::@4->progress_chip_clear::@3]
    // [308] phi progress_chip_clear::i#2 = progress_chip_clear::i#1 [phi:progress_chip_clear::@4->progress_chip_clear::@3#0] -- register_copy 
    jmp __b3
}
  // print_clear
print_clear: {
    // textcolor(WHITE)
    // [316] call textcolor
    // [168] phi from print_clear to textcolor [phi:print_clear->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:print_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [317] phi from print_clear to print_clear::@1 [phi:print_clear->print_clear::@1]
    // print_clear::@1
    // gotoxy(2, 14)
    // [318] call gotoxy
    // [186] phi from print_clear::@1 to gotoxy [phi:print_clear::@1->gotoxy]
    // [186] phi gotoxy::y#17 = $e [phi:print_clear::@1->gotoxy#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = 2 [phi:print_clear::@1->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [319] phi from print_clear::@1 to print_clear::@2 [phi:print_clear::@1->print_clear::@2]
    // print_clear::@2
    // printf("%60s", " ")
    // [320] call printf_string
    // [324] phi from print_clear::@2 to printf_string [phi:print_clear::@2->printf_string]
    // [324] phi printf_string::str#10 = print_clear::str [phi:print_clear::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [324] phi printf_string::format_min_length#3 = $3c [phi:print_clear::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #$3c
    sta.z printf_string.format_min_length
    jsr printf_string
    // [321] phi from print_clear::@2 to print_clear::@3 [phi:print_clear::@2->print_clear::@3]
    // print_clear::@3
    // gotoxy(2, 14)
    // [322] call gotoxy
    // [186] phi from print_clear::@3 to gotoxy [phi:print_clear::@3->gotoxy]
    // [186] phi gotoxy::y#17 = $e [phi:print_clear::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = 2 [phi:print_clear::@3->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // print_clear::@return
    // }
    // [323] return 
    rts
  .segment Data
    str: .text " "
    .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($3b) char *str, __zp($75) char format_min_length, char format_justify_left)
printf_string: {
    .label printf_string__9 = $6e
    .label len = $5f
    .label padding = $75
    .label format_min_length = $75
    .label str = $3b
    // if(format.min_length)
    // [325] if(0==printf_string::format_min_length#3) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b1
    // printf_string::@3
    // strlen(str)
    // [326] strlen::str#2 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [327] call strlen
    // [774] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [774] phi strlen::str#7 = strlen::str#2 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [328] strlen::return#3 = strlen::len#2
    // printf_string::@5
    // [329] printf_string::$9 = strlen::return#3
    // signed char len = (signed char)strlen(str)
    // [330] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [331] printf_string::padding#1 = (signed char)printf_string::format_min_length#3 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [332] if(printf_string::padding#1>=0) goto printf_string::@7 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b6
    // [334] phi from printf_string printf_string::@5 to printf_string::@1 [phi:printf_string/printf_string::@5->printf_string::@1]
  __b1:
    // [334] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@5->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [333] phi from printf_string::@5 to printf_string::@7 [phi:printf_string::@5->printf_string::@7]
    // printf_string::@7
    // [334] phi from printf_string::@7 to printf_string::@1 [phi:printf_string::@7->printf_string::@1]
    // [334] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@7->printf_string::@1#0] -- register_copy 
    // printf_string::@1
    // printf_string::@6
  __b6:
    // if(!format.justify_left && padding)
    // [335] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [336] printf_padding::length#3 = (char)printf_string::padding#3
    // [337] call printf_padding
    // [780] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [338] printf_str::s#2 = printf_string::str#10
    // [339] call printf_str
    // [266] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [266] phi printf_str::putc#15 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@return
    // }
    // [340] return 
    rts
}
  // flash_smc_detect
flash_smc_detect: {
    .label flash_smc_detect__1 = $62
    .label smc_bootloader_version = $43
    // When the bootloader is not present, 0xFF is returned.
    .label return = $43
    // unsigned int smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [341] cx16_k_i2c_read_byte::device = $42 -- vbuz1=vbuc1 
    lda #$42
    sta.z cx16_k_i2c_read_byte.device
    // [342] cx16_k_i2c_read_byte::offset = $8e -- vbuz1=vbuc1 
    lda #$8e
    sta.z cx16_k_i2c_read_byte.offset
    // [343] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [344] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc_detect::@3
    // [345] flash_smc_detect::smc_bootloader_version#0 = cx16_k_i2c_read_byte::return#2
    // BYTE1(smc_bootloader_version)
    // [346] flash_smc_detect::$1 = byte1  flash_smc_detect::smc_bootloader_version#0 -- vbuz1=_byte1_vwuz2 
    lda.z smc_bootloader_version+1
    sta.z flash_smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [347] if(0==flash_smc_detect::$1) goto flash_smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [350] phi from flash_smc_detect::@3 to flash_smc_detect::@return [phi:flash_smc_detect::@3->flash_smc_detect::@return]
    // [350] phi flash_smc_detect::return#1 = $200 [phi:flash_smc_detect::@3->flash_smc_detect::@return#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // flash_smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [348] if(flash_smc_detect::smc_bootloader_version#0!=$ff) goto flash_smc_detect::@2 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [350] phi from flash_smc_detect::@1 to flash_smc_detect::@return [phi:flash_smc_detect::@1->flash_smc_detect::@return]
    // [350] phi flash_smc_detect::return#1 = $100 [phi:flash_smc_detect::@1->flash_smc_detect::@return#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [349] phi from flash_smc_detect::@1 to flash_smc_detect::@2 [phi:flash_smc_detect::@1->flash_smc_detect::@2]
    // flash_smc_detect::@2
  __b2:
    // [350] phi from flash_smc_detect::@2 to flash_smc_detect::@return [phi:flash_smc_detect::@2->flash_smc_detect::@return]
    // [350] phi flash_smc_detect::return#1 = flash_smc_detect::smc_bootloader_version#0 [phi:flash_smc_detect::@2->flash_smc_detect::@return#0] -- register_copy 
    // flash_smc_detect::@return
    // }
    // [351] return 
    rts
}
  // wait_key
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label kbhit1_return = $6d
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [353] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [354] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [355] phi from wait_key::@1 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@1/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [357] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [358] call cbm_k_getin
    jsr cbm_k_getin
    // [359] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@2
    // [360] wait_key::kbhit1_return#0 = cbm_k_getin::return#2
    // wait_key::@1
    // while (!(ch = kbhit()))
    // [361] if(0==wait_key::kbhit1_return#0) goto wait_key::kbhit1 -- 0_eq_vbuz1_then_la1 
    lda.z kbhit1_return
    beq kbhit1
    // wait_key::@return
    // }
    // [362] return 
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __zp($43) unsigned int uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uint: {
    .label putc = cputc
    .label uvalue = $43
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [364] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [365] utoa::value#1 = printf_uint::uvalue#0
    // [366] call utoa
  // Format number into buffer
    // [798] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [367] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [368] call printf_number_buffer
  // Print using format
    // [819] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [369] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label dst = $3b
    .label src = $b3
    // [371] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [371] phi strcpy::dst#2 = file [phi:strcpy->strcpy::@1#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z dst
    lda #>file
    sta.z dst+1
    // [371] phi strcpy::src#2 = main::source [phi:strcpy->strcpy::@1#1] -- pbuz1=pbuc1 
    lda #<main.source
    sta.z src
    lda #>main.source
    sta.z src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [372] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [373] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [374] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [375] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [376] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [377] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [371] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [371] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [371] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
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
// __zp($57) struct $2 * fopen(__zp($53) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $66
    .label fopen__9 = $78
    .label fopen__11 = $b1
    .label fopen__15 = $a9
    .label fopen__16 = $af
    .label fopen__26 = $3b
    .label fopen__28 = $b6
    .label fopen__30 = $57
    .label cbm_k_setnam1_filename = $d5
    .label cbm_k_setnam1_filename_len = $ca
    .label cbm_k_setnam1_fopen__0 = $6e
    .label cbm_k_readst1_status = $cb
    .label cbm_k_close1_channel = $cc
    .label sp = $42
    .label stream = $57
    .label pathpos = $75
    .label pathpos_1 = $4e
    .label pathtoken = $b3
    .label pathcmp = $69
    .label path = $53
    // Parse path
    .label pathstep = $68
    .label num = $55
    .label cbm_k_readst1_return = $a9
    .label return = $57
    // unsigned char sp = __stdio_filecount
    // [378] fopen::sp#0 = __stdio_filecount -- vbuz1=vbuz2 
    lda.z __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [379] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [380] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [381] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z sp
    asl
    sta.z pathpos
    // __logical = 0
    // [382] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [383] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [384] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // [385] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [386] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [386] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z num
    // [386] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [386] phi fopen::path#13 = file [phi:fopen->fopen::@8#2] -- pbuz1=pbuc1 
    lda #<file
    sta.z path
    lda #>file
    sta.z path+1
    // [386] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    lda #0
    sta.z pathstep
    // [386] phi fopen::pathtoken#10 = file [phi:fopen->fopen::@8#4] -- pbuz1=pbuc1 
    lda #<file
    sta.z pathtoken
    lda #>file
    sta.z pathtoken+1
  // Iterate while path is not \0.
    // [386] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [386] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [386] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [386] phi fopen::path#13 = fopen::path#10 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [386] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [386] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [387] if(*fopen::pathtoken#10==','pm) goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [388] if(*fopen::pathtoken#10=='?'pm) goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'\$00'
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [389] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [390] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbuz2 
    lda (pathtoken),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [391] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [392] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [392] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [392] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [392] phi fopen::path#10 = fopen::path#12 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [392] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [393] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken
    bne !+
    inc.z pathtoken+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [394] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [395] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [396] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [397] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [398] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbuz2_plus_1 
    lda.z __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [399] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [400] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [401] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [402] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [403] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbuz2_plus_2 
    lda.z __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [404] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [405] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [406] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [407] strlen::str#3 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [408] call strlen
    // [774] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [774] phi strlen::str#7 = strlen::str#3 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [409] strlen::return#4 = strlen::len#2
    // fopen::@31
    // [410] fopen::cbm_k_setnam1_$0 = strlen::return#4
    // char filename_len = (char)strlen(filename)
    // [411] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta.z cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [413] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta.z cbm_k_setlfs.channel
    // [414] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$42,y
    sta.z cbm_k_setlfs.device
    // [415] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$44,y
    sta.z cbm_k_setlfs.command
    // [416] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [418] fopen::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [420] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [421] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [422] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [423] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [424] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [425] call ferror
    jsr ferror
    // [426] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [427] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [428] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [429] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta.z cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [431] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [431] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [432] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [433] __stdio_filecount = ++ __stdio_filecount -- vbuz1=_inc_vbuz1 
    inc.z __stdio_filecount
    // [434] fopen::return#6 = (struct $2 *)fopen::stream#0
    // [431] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [431] phi fopen::return#2 = fopen::return#6 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [435] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [436] ((char *)&__stdio_file)[fopen::pathpos#10] = '?'pm -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'\$00'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [437] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    // [438] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [438] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [438] phi fopen::path#12 = fopen::path#15 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [439] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [440] fopen::pathcmp#0 = *fopen::path#13 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [441] if(fopen::pathcmp#0=='D'pm) goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [442] if(fopen::pathcmp#0=='L'pm) goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [443] if(fopen::pathcmp#0=='C'pm) goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [444] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [444] phi fopen::path#15 = fopen::path#13 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [444] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [445] if(fopen::pathcmp#0=='L'pm) goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [446] if(fopen::pathcmp#0=='D'pm) goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [447] if(fopen::pathcmp#0!='C'pm) goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [448] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [449] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [450] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [451] atoi::str#0 = fopen::path#13 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [452] call atoi
    // [881] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [881] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [453] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [454] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [455] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [456] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    jmp __b14
}
  // print_smc_led
// void print_smc_led(__zp($66) char c)
print_smc_led: {
    .label c = $66
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [458] print_chip_led::tc#0 = print_smc_led::c#2
    // [459] call print_chip_led
    // [897] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [897] phi print_chip_led::w#5 = 5 [phi:print_smc_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip_led.w
    // [897] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#1] -- register_copy 
    // [897] phi print_chip_led::x#3 = 1+1 [phi:print_smc_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #1+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_smc_led::@return
    // }
    // [460] return 
    rts
}
  // flash_read
// __zp($b8) unsigned long flash_read(__zp($78) char y, char w, char b, unsigned int r, __zp($b6) struct $2 *fp, __zp($b3) char *flash_ram_address)
flash_read: {
    .const r = $100
    .label b = 4
    .label read_bytes = $45
    .label flash_ram_address = $b3
    .label flash_bytes = $b8
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label flash_row_total = $53
    .label y = $78
    .label fp = $b6
    .label return = $b8
    // textcolor(WHITE)
    // [462] call textcolor
    // [168] phi from flash_read to textcolor [phi:flash_read->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:flash_read->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [463] phi from flash_read to flash_read::@5 [phi:flash_read->flash_read::@5]
    // flash_read::@5
    // gotoxy(0, y)
    // [464] call gotoxy
    // [186] phi from flash_read::@5 to gotoxy [phi:flash_read::@5->gotoxy]
    // [186] phi gotoxy::y#17 = $11 [phi:flash_read::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = 0 [phi:flash_read::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [465] phi from flash_read::@5 to flash_read::@1 [phi:flash_read::@5->flash_read::@1]
    // [465] phi flash_read::y#3 = $11 [phi:flash_read::@5->flash_read::@1#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z y
    // [465] phi flash_read::flash_bytes#2 = 0 [phi:flash_read::@5->flash_read::@1#1] -- vduz1=vduc1 
    lda #<0
    sta.z flash_bytes
    sta.z flash_bytes+1
    lda #<0>>$10
    sta.z flash_bytes+2
    lda #>0>>$10
    sta.z flash_bytes+3
    // [465] phi flash_read::flash_row_total#3 = 0 [phi:flash_read::@5->flash_read::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_row_total
    sta.z flash_row_total+1
    // [465] phi flash_read::flash_ram_address#2 = (char *) 16384 [phi:flash_read::@5->flash_read::@1#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_ram_address
    lda #>$4000
    sta.z flash_ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // flash_read::@1
  __b1:
    // fgets(flash_ram_address, b, fp)
    // [466] fgets::ptr#2 = flash_read::flash_ram_address#2 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [467] fgets::stream#0 = flash_read::fp#0
    // [468] call fgets
    jsr fgets
    // [469] fgets::return#5 = fgets::return#1
    // flash_read::@6
    // read_bytes = fgets(flash_ram_address, b, fp)
    // [470] flash_read::read_bytes#1 = fgets::return#5
    // while (read_bytes = fgets(flash_ram_address, b, fp))
    // [471] if(0!=flash_read::read_bytes#1) goto flash_read::@2 -- 0_neq_vwuz1_then_la1 
    lda.z read_bytes
    ora.z read_bytes+1
    bne __b2
    // flash_read::@return
    // }
    // [472] return 
    rts
    // flash_read::@2
  __b2:
    // if (flash_row_total == r)
    // [473] if(flash_read::flash_row_total#3!=flash_read::r#0) goto flash_read::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z flash_row_total+1
    cmp #>r
    bne __b3
    lda.z flash_row_total
    cmp #<r
    bne __b3
    // flash_read::@4
    // gotoxy(0, ++y);
    // [474] flash_read::y#0 = ++ flash_read::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(0, ++y)
    // [475] gotoxy::y#13 = flash_read::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [476] call gotoxy
    // [186] phi from flash_read::@4 to gotoxy [phi:flash_read::@4->gotoxy]
    // [186] phi gotoxy::y#17 = gotoxy::y#13 [phi:flash_read::@4->gotoxy#0] -- register_copy 
    // [186] phi gotoxy::x#17 = 0 [phi:flash_read::@4->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [477] phi from flash_read::@4 to flash_read::@3 [phi:flash_read::@4->flash_read::@3]
    // [477] phi flash_read::y#8 = flash_read::y#0 [phi:flash_read::@4->flash_read::@3#0] -- register_copy 
    // [477] phi flash_read::flash_row_total#4 = 0 [phi:flash_read::@4->flash_read::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z flash_row_total
    sta.z flash_row_total+1
    // [477] phi from flash_read::@2 to flash_read::@3 [phi:flash_read::@2->flash_read::@3]
    // [477] phi flash_read::y#8 = flash_read::y#3 [phi:flash_read::@2->flash_read::@3#0] -- register_copy 
    // [477] phi flash_read::flash_row_total#4 = flash_read::flash_row_total#3 [phi:flash_read::@2->flash_read::@3#1] -- register_copy 
    // flash_read::@3
  __b3:
    // cputc('.')
    // [478] stackpush(char) = '.'pm -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [479] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_ram_address += read_bytes
    // [481] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#2 + flash_read::read_bytes#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z read_bytes+1
    sta.z flash_ram_address+1
    // flash_bytes += read_bytes
    // [482] flash_read::flash_bytes#1 = flash_read::flash_bytes#2 + flash_read::read_bytes#1 -- vduz1=vduz1_plus_vwuz2 
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
    // flash_row_total += read_bytes
    // [483] flash_read::flash_row_total#1 = flash_read::flash_row_total#4 + flash_read::read_bytes#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z flash_row_total
    adc.z read_bytes
    sta.z flash_row_total
    lda.z flash_row_total+1
    adc.z read_bytes+1
    sta.z flash_row_total+1
    // [465] phi from flash_read::@3 to flash_read::@1 [phi:flash_read::@3->flash_read::@1]
    // [465] phi flash_read::y#3 = flash_read::y#8 [phi:flash_read::@3->flash_read::@1#0] -- register_copy 
    // [465] phi flash_read::flash_bytes#2 = flash_read::flash_bytes#1 [phi:flash_read::@3->flash_read::@1#1] -- register_copy 
    // [465] phi flash_read::flash_row_total#3 = flash_read::flash_row_total#1 [phi:flash_read::@3->flash_read::@1#2] -- register_copy 
    // [465] phi flash_read::flash_ram_address#2 = flash_read::flash_ram_address#0 [phi:flash_read::@3->flash_read::@1#3] -- register_copy 
    jmp __b1
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
// int fclose(__zp($49) struct $2 *stream)
fclose: {
    .label fclose__1 = $66
    .label fclose__4 = $78
    .label fclose__6 = $75
    .label cbm_k_chkin1_channel = $d3
    .label cbm_k_chkin1_status = $cd
    .label cbm_k_readst1_status = $ce
    .label cbm_k_close1_channel = $cf
    .label cbm_k_readst2_status = $d0
    .label sp = $75
    .label cbm_k_readst1_return = $66
    .label cbm_k_readst2_return = $78
    .label stream = $49
    // unsigned char sp = (unsigned char)stream
    // [484] fclose::sp#0 = (char)fclose::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [485] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta.z cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [486] fclose::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [488] fclose::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [490] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [491] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [492] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [493] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [494] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [495] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [496] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta.z cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [498] fclose::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [500] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [501] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [502] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [503] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [504] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [505] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [506] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [507] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [508] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z fclose__6
    // *__filename = '\0'
    // [509] ((char *)&__stdio_file)[fclose::$6] = '?'pm -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'\$00'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [510] __stdio_filecount = -- __stdio_filecount -- vbuz1=_dec_vbuz1 
    dec.z __stdio_filecount
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($56) char mapbase, __zp($52) char config)
screenlayer: {
    .label screenlayer__0 = $7b
    .label screenlayer__1 = $56
    .label screenlayer__2 = $7c
    .label screenlayer__5 = $52
    .label screenlayer__6 = $52
    .label screenlayer__7 = $73
    .label screenlayer__8 = $73
    .label screenlayer__9 = $71
    .label screenlayer__10 = $71
    .label screenlayer__11 = $71
    .label screenlayer__12 = $72
    .label screenlayer__13 = $72
    .label screenlayer__14 = $72
    .label screenlayer__16 = $73
    .label screenlayer__17 = $6a
    .label screenlayer__18 = $71
    .label screenlayer__19 = $72
    .label mapbase = $56
    .label config = $52
    .label mapbase_offset = $6b
    .label y = $4f
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [511] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [512] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [513] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [514] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [515] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [516] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [517] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [518] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [519] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [520] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [521] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [522] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [523] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [524] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [525] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [526] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [527] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [528] screenlayer::$18 = (char)screenlayer::$9
    // [529] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [530] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [531] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [532] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [533] screenlayer::$19 = (char)screenlayer::$12
    // [534] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [535] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [536] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [537] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z mapbase_offset
    lda __conio+3+1
    sta.z mapbase_offset+1
    // [538] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [538] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [538] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [539] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [540] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [541] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [542] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [543] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+$a
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+$a+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [544] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [538] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [538] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [538] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [545] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [546] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [547] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [548] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [549] call gotoxy
    // [186] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [186] phi gotoxy::y#17 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [550] return 
    rts
    // [551] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [552] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [553] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [554] call gotoxy
    // [186] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [186] phi gotoxy::y#17 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [186] phi gotoxy::x#17 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [555] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [556] call clearline
    jsr clearline
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
    // [557] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [558] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $a9
    .label clrscr__1 = $69
    .label clrscr__2 = $7a
    .label line_text = $57
    .label l = $75
    .label ch = $57
    .label c = $66
    // unsigned int line_text = __conio.mapbase_offset
    // [559] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [560] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [561] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [562] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [563] clrscr::l#0 = *((char *)&__conio+9) -- vbuz1=_deref_pbuc1 
    lda __conio+9
    sta.z l
    // [564] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [564] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [564] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [565] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [566] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [567] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [568] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [569] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta.z c
    // [570] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [570] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [571] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [572] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [573] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [574] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [575] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [576] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [577] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [578] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [579] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [580] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [581] return 
    rts
}
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __zp($a9) char x1, __zp($aa) char y1)
frame: {
    .label w = $7a
    .label h = $79
    .label x = $4d
    .label y = $70
    .label mask = $5a
    .label c = $5e
    .label x_1 = $74
    .label y_1 = $40
    .label x1 = $a9
    .label y1 = $aa
    // unsigned char w = x1 - x0
    // [583] frame::w#0 = frame::x1#14 - frame::x#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [584] frame::h#0 = frame::y1#14 - frame::y#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta.z h
    // unsigned char mask = frame_maskxy(x, y)
    // [585] frame_maskxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [586] frame_maskxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [587] call frame_maskxy
    // [992] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [992] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [992] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [588] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [589] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [590] frame::mask#1 = frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = frame_char(mask)
    // [591] frame_char::mask#0 = frame::mask#1
    // [592] call frame_char
  // Add a corner.
    // [1018] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [1018] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [593] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [594] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [595] cputcxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [596] cputcxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [597] cputcxy::c#0 = frame::c#0
    // [598] call cputcxy
    // [1033] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [599] if(frame::w#0<2) goto frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [600] frame::x#1 = ++ frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [601] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [601] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [602] if(frame::x#10<frame::x1#14) goto frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [603] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [603] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [604] frame_maskxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [605] frame_maskxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [606] call frame_maskxy
    // [992] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [992] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [992] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [607] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [608] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [609] frame::mask#3 = frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [610] frame_char::mask#1 = frame::mask#3
    // [611] call frame_char
    // [1018] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [1018] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [612] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [613] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [614] cputcxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [615] cputcxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [616] cputcxy::c#1 = frame::c#1
    // [617] call cputcxy
    // [1033] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [618] if(frame::h#0<2) goto frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [619] frame::y#1 = ++ frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [620] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [620] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [621] if(frame::y#10<frame::y1#14) goto frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // frame::@8
    // frame_maskxy(x, y)
    // [622] frame_maskxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [623] frame_maskxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [624] call frame_maskxy
    // [992] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [992] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [992] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [625] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [626] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [627] frame::mask#11 = frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [628] frame_char::mask#5 = frame::mask#11
    // [629] call frame_char
    // [1018] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [1018] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [630] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [631] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [632] cputcxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [633] cputcxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [634] cputcxy::c#5 = frame::c#5
    // [635] call cputcxy
    // [1033] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [636] if(frame::w#0<2) goto frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [637] frame::x#4 = ++ frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [638] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [638] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [639] if(frame::x#18<frame::x1#14) goto frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [640] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [640] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [641] frame_maskxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [642] frame_maskxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [643] call frame_maskxy
    // [992] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [992] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [992] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [644] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [645] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [646] frame::mask#13 = frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [647] frame_char::mask#6 = frame::mask#13
    // [648] call frame_char
    // [1018] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [1018] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [649] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [650] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [651] cputcxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [652] cputcxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [653] cputcxy::c#6 = frame::c#6
    // [654] call cputcxy
    // [1033] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [655] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [656] frame_maskxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [657] frame_maskxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [658] call frame_maskxy
    // [992] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [992] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [992] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [659] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [660] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [661] frame::mask#15 = frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [662] frame_char::mask#7 = frame::mask#15
    // [663] call frame_char
    // [1018] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [1018] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [664] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [665] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [666] cputcxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [667] cputcxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [668] cputcxy::c#7 = frame::c#7
    // [669] call cputcxy
    // [1033] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [670] frame::x#5 = ++ frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [671] frame_maskxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [672] frame_maskxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [673] call frame_maskxy
    // [992] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [992] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [992] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [674] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [675] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [676] frame::mask#7 = frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [677] frame_char::mask#3 = frame::mask#7
    // [678] call frame_char
    // [1018] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [1018] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [679] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [680] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [681] cputcxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [682] cputcxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [683] cputcxy::c#3 = frame::c#3
    // [684] call cputcxy
    // [1033] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [685] frame_maskxy::x#4 = frame::x1#14 -- vbuz1=vbuz2 
    lda.z x1
    sta.z frame_maskxy.x
    // [686] frame_maskxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [687] call frame_maskxy
    // [992] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [992] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [992] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [688] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [689] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [690] frame::mask#9 = frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [691] frame_char::mask#4 = frame::mask#9
    // [692] call frame_char
    // [1018] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [1018] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [693] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [694] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [695] cputcxy::x#4 = frame::x1#14 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [696] cputcxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [697] cputcxy::c#4 = frame::c#4
    // [698] call cputcxy
    // [1033] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [699] frame::y#2 = ++ frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [700] frame_maskxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [701] frame_maskxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [702] call frame_maskxy
    // [992] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [992] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [992] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [703] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [704] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [705] frame::mask#5 = frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [706] frame_char::mask#2 = frame::mask#5
    // [707] call frame_char
    // [1018] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [1018] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [708] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [709] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [710] cputcxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [711] cputcxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [712] cputcxy::c#2 = frame::c#2
    // [713] call cputcxy
    // [1033] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [714] frame::x#2 = ++ frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // frame::@36
  __b36:
    // [715] frame::x#30 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(char x, char y, const char *s)
cputsxy: {
    .const x = 2
    .const y = $e
    // gotoxy(x, y)
    // [717] call gotoxy
    // [186] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [186] phi gotoxy::y#17 = cputsxy::y#0 [phi:cputsxy->gotoxy#0] -- vbuz1=vbuc1 
    lda #y
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = cputsxy::x#0 [phi:cputsxy->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [718] phi from cputsxy to cputsxy::@1 [phi:cputsxy->cputsxy::@1]
    // cputsxy::@1
    // cputs(s)
    // [719] call cputs
    // [1041] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [720] return 
    rts
}
  // print_chip
// void print_chip(__zp($67) char x, char y, __zp($69) char w, __zp($b1) char *text)
print_chip: {
    .label y = 3+1+1+1+1+1+1+1+1+1
    .label text = $b1
    .label text_1 = $af
    .label x = $67
    .label text_2 = $3d
    .label text_3 = $50
    .label text_4 = $7e
    .label text_5 = $5c
    .label text_6 = $47
    .label w = $69
    // print_chip_line(x, y++, w, *text++)
    // [722] print_chip_line::x#0 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [723] print_chip_line::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [724] print_chip_line::c#0 = *print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z print_chip_line.c
    // [725] call print_chip_line
    // [1050] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [1050] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [1050] phi print_chip_line::w#10 = print_chip_line::w#0 [phi:print_chip->print_chip_line#1] -- register_copy 
    // [1050] phi print_chip_line::y#16 = 3+1 [phi:print_chip->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1
    sta.z print_chip_line.y
    // [1050] phi print_chip_line::x#16 = print_chip_line::x#0 [phi:print_chip->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++);
    // [726] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // print_chip_line(x, y++, w, *text++)
    // [727] print_chip_line::x#1 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [728] print_chip_line::w#1 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [729] print_chip_line::c#1 = *print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z print_chip_line.c
    // [730] call print_chip_line
    // [1050] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [1050] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [1050] phi print_chip_line::w#10 = print_chip_line::w#1 [phi:print_chip::@1->print_chip_line#1] -- register_copy 
    // [1050] phi print_chip_line::y#16 = ++3+1 [phi:print_chip::@1->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1
    sta.z print_chip_line.y
    // [1050] phi print_chip_line::x#16 = print_chip_line::x#1 [phi:print_chip::@1->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++);
    // [731] print_chip::text#1 = ++ print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // print_chip_line(x, y++, w, *text++)
    // [732] print_chip_line::x#2 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [733] print_chip_line::w#2 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [734] print_chip_line::c#2 = *print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z print_chip_line.c
    // [735] call print_chip_line
    // [1050] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [1050] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [1050] phi print_chip_line::w#10 = print_chip_line::w#2 [phi:print_chip::@2->print_chip_line#1] -- register_copy 
    // [1050] phi print_chip_line::y#16 = ++++3+1 [phi:print_chip::@2->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1
    sta.z print_chip_line.y
    // [1050] phi print_chip_line::x#16 = print_chip_line::x#2 [phi:print_chip::@2->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++);
    // [736] print_chip::text#15 = ++ print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // print_chip_line(x, y++, w, *text++)
    // [737] print_chip_line::x#3 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [738] print_chip_line::w#3 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [739] print_chip_line::c#3 = *print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z print_chip_line.c
    // [740] call print_chip_line
    // [1050] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [1050] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [1050] phi print_chip_line::w#10 = print_chip_line::w#3 [phi:print_chip::@3->print_chip_line#1] -- register_copy 
    // [1050] phi print_chip_line::y#16 = ++++++3+1 [phi:print_chip::@3->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1
    sta.z print_chip_line.y
    // [1050] phi print_chip_line::x#16 = print_chip_line::x#3 [phi:print_chip::@3->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++);
    // [741] print_chip::text#16 = ++ print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // print_chip_line(x, y++, w, *text++)
    // [742] print_chip_line::x#4 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [743] print_chip_line::w#4 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [744] print_chip_line::c#4 = *print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z print_chip_line.c
    // [745] call print_chip_line
    // [1050] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [1050] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [1050] phi print_chip_line::w#10 = print_chip_line::w#4 [phi:print_chip::@4->print_chip_line#1] -- register_copy 
    // [1050] phi print_chip_line::y#16 = ++++++++3+1 [phi:print_chip::@4->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1
    sta.z print_chip_line.y
    // [1050] phi print_chip_line::x#16 = print_chip_line::x#4 [phi:print_chip::@4->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++);
    // [746] print_chip::text#17 = ++ print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // print_chip_line(x, y++, w, *text++)
    // [747] print_chip_line::x#5 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [748] print_chip_line::w#5 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [749] print_chip_line::c#5 = *print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z print_chip_line.c
    // [750] call print_chip_line
    // [1050] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [1050] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [1050] phi print_chip_line::w#10 = print_chip_line::w#5 [phi:print_chip::@5->print_chip_line#1] -- register_copy 
    // [1050] phi print_chip_line::y#16 = ++++++++++3+1 [phi:print_chip::@5->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1050] phi print_chip_line::x#16 = print_chip_line::x#5 [phi:print_chip::@5->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++);
    // [751] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // print_chip_line(x, y++, w, *text++)
    // [752] print_chip_line::x#6 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [753] print_chip_line::w#6 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [754] print_chip_line::c#6 = *print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [755] call print_chip_line
    // [1050] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [1050] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [1050] phi print_chip_line::w#10 = print_chip_line::w#6 [phi:print_chip::@6->print_chip_line#1] -- register_copy 
    // [1050] phi print_chip_line::y#16 = ++++++++++++3+1 [phi:print_chip::@6->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1050] phi print_chip_line::x#16 = print_chip_line::x#6 [phi:print_chip::@6->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++);
    // [756] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // print_chip_line(x, y++, w, *text++)
    // [757] print_chip_line::x#7 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [758] print_chip_line::w#7 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [759] print_chip_line::c#7 = *print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [760] call print_chip_line
    // [1050] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [1050] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [1050] phi print_chip_line::w#10 = print_chip_line::w#7 [phi:print_chip::@7->print_chip_line#1] -- register_copy 
    // [1050] phi print_chip_line::y#16 = ++++++++++++++3+1 [phi:print_chip::@7->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1050] phi print_chip_line::x#16 = print_chip_line::x#7 [phi:print_chip::@7->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [761] print_chip_end::x#0 = print_chip::x#10
    // [762] print_chip_end::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_end.w
    // [763] call print_chip_end
    jsr print_chip_end
    // print_chip::@return
    // }
    // [764] return 
    rts
}
  // print_vera_led
// void print_vera_led(char c)
print_vera_led: {
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [766] call print_chip_led
    // [897] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [897] phi print_chip_led::w#5 = 7 [phi:print_vera_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #7
    sta.z print_chip_led.w
    // [897] phi print_chip_led::tc#3 = GREY [phi:print_vera_led->print_chip_led#1] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_chip_led.tc
    // [897] phi print_chip_led::x#3 = 9+1 [phi:print_vera_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #9+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_vera_led::@return
    // }
    // [767] return 
    rts
}
  // print_rom_led
// void print_rom_led(__zp($69) char chip, char c)
print_rom_led: {
    .label print_rom_led__0 = $69
    .label chip = $69
    .label print_rom_led__4 = $79
    .label print_rom_led__5 = $69
    // chip*6
    // [768] print_rom_led::$4 = print_rom_led::chip#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__4
    // [769] print_rom_led::$5 = print_rom_led::$4 + print_rom_led::chip#0 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z print_rom_led__5
    clc
    adc.z print_rom_led__4
    sta.z print_rom_led__5
    // CHIP_ROM_X+chip*6
    // [770] print_rom_led::$0 = print_rom_led::$5 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [771] print_chip_led::x#2 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z print_chip_led.x
    sta.z print_chip_led.x
    // [772] call print_chip_led
    // [897] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [897] phi print_chip_led::w#5 = 3 [phi:print_rom_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip_led.w
    // [897] phi print_chip_led::tc#3 = GREY [phi:print_rom_led->print_chip_led#1] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_chip_led.tc
    // [897] phi print_chip_led::x#3 = print_chip_led::x#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@return
    // }
    // [773] return 
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($6e) unsigned int strlen(__zp($3d) char *str)
strlen: {
    .label len = $6e
    .label str = $3d
    .label return = $6e
    // [775] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [775] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [775] phi strlen::str#5 = strlen::str#7 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [776] if(0!=*strlen::str#5) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [777] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [778] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [779] strlen::str#0 = ++ strlen::str#5 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [775] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [775] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [775] phi strlen::str#5 = strlen::str#0 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(void (*putc)(char), char pad, __zp($75) char length)
printf_padding: {
    .label i = $64
    .label length = $75
    // [781] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [781] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [782] if(printf_padding::i#2<printf_padding::length#3) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [783] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [784] stackpush(char) = ' 'pm -- _stackpushbyte_=vbuc1 
    lda #' '
    pha
    // [785] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [787] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [781] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [781] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
}
  // cx16_k_i2c_read_byte
/**
 * @brief Read a byte at a given offset from a given I2C device.
 * Description: The routine i2c_read_byte reads a single byte  
 * at offset .Y from I2C device .X and returns the result in .A.  
 * .C is 0 if the read was successful, and 1 if no such device exists.
 * @example
 * LDX #$6F ; RTC device
 * LDY #$20 ; start of NVRAM inside RTC
 * JSR i2c_read_byte ; read first byte of NVRAM
*/
// __zp($43) unsigned int cx16_k_i2c_read_byte(__zp($d4) volatile char device, __zp($d2) volatile char offset)
cx16_k_i2c_read_byte: {
    .label device = $d4
    .label offset = $d2
    .label result = $bc
    .label return = $43
    // unsigned int result
    // [788] cx16_k_i2c_read_byte::result = 0 -- vwuz1=vwuc1 
    lda #<0
    sta.z result
    sta.z result+1
    // asm
    // asm { ldxdevice ldyoffset lda#0 staresult staresult+1 jsrCX16_I2C_READ_BYTE staresult rolresult+1  }
    ldx device
    ldy offset
    sta result
    sta result+1
    jsr CX16_I2C_READ_BYTE
    sta result
    rol result+1
    // return result;
    // [790] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwuz2 
    sta.z return
    lda.z result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [791] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [792] return 
    rts
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    .label return = $6d
    // __mem unsigned char ch
    // [793] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [795] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [796] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [797] return 
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
// void utoa(__zp($43) unsigned int value, __zp($6e) char *buffer, char radix)
utoa: {
    .const max_digits = 5
    .label utoa__10 = $67
    .label utoa__11 = $63
    .label digit_value = $50
    .label buffer = $6e
    .label digit = $78
    .label value = $43
    .label started = $a9
    // [799] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
    // [799] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa->utoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [799] phi utoa::started#2 = 0 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [799] phi utoa::value#2 = utoa::value#1 [phi:utoa->utoa::@1#2] -- register_copy 
    // [799] phi utoa::digit#2 = 0 [phi:utoa->utoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [800] if(utoa::digit#2<utoa::max_digits#1-1) goto utoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #max_digits-1
    bcc __b2
    // utoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [801] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [802] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [803] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [804] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // utoa::@return
    // }
    // [805] return 
    rts
    // utoa::@2
  __b2:
    // unsigned int digit_value = digit_values[digit]
    // [806] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [807] utoa::digit_value#0 = RADIX_DECIMAL_VALUES[utoa::$10] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda RADIX_DECIMAL_VALUES,y
    sta.z digit_value
    lda RADIX_DECIMAL_VALUES+1,y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [808] if(0!=utoa::started#2) goto utoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // utoa::@7
    // [809] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@5 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b5
  !:
    bcc __b5
    // [810] phi from utoa::@7 to utoa::@4 [phi:utoa::@7->utoa::@4]
    // [810] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@7->utoa::@4#0] -- register_copy 
    // [810] phi utoa::started#4 = utoa::started#2 [phi:utoa::@7->utoa::@4#1] -- register_copy 
    // [810] phi utoa::value#6 = utoa::value#2 [phi:utoa::@7->utoa::@4#2] -- register_copy 
    // utoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [811] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [799] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
    // [799] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@4->utoa::@1#0] -- register_copy 
    // [799] phi utoa::started#2 = utoa::started#4 [phi:utoa::@4->utoa::@1#1] -- register_copy 
    // [799] phi utoa::value#2 = utoa::value#6 [phi:utoa::@4->utoa::@1#2] -- register_copy 
    // [799] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@4->utoa::@1#3] -- register_copy 
    jmp __b1
    // utoa::@5
  __b5:
    // utoa_append(buffer++, value, digit_value)
    // [812] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [813] utoa_append::value#0 = utoa::value#2
    // [814] utoa_append::sub#0 = utoa::digit_value#0
    // [815] call utoa_append
    // [1111] phi from utoa::@5 to utoa_append [phi:utoa::@5->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [816] utoa_append::return#0 = utoa_append::value#2
    // utoa::@6
    // value = utoa_append(buffer++, value, digit_value)
    // [817] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [818] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [810] phi from utoa::@6 to utoa::@4 [phi:utoa::@6->utoa::@4]
    // [810] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@6->utoa::@4#0] -- register_copy 
    // [810] phi utoa::started#4 = 1 [phi:utoa::@6->utoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [810] phi utoa::value#6 = utoa::value#0 [phi:utoa::@6->utoa::@4#2] -- register_copy 
    jmp __b4
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(void (*putc)(char), __zp($41) char buffer_sign, char *buffer_digits, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label buffer_digits = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label buffer_sign = $41
    // printf_number_buffer::@1
    // if(buffer.sign)
    // [820] if(0==printf_number_buffer::buffer_sign#0) goto printf_number_buffer::@2 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b2
    // printf_number_buffer::@3
    // putc(buffer.sign)
    // [821] stackpush(char) = printf_number_buffer::buffer_sign#0 -- _stackpushbyte_=vbuz1 
    pha
    // [822] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [824] phi from printf_number_buffer::@1 printf_number_buffer::@3 to printf_number_buffer::@2 [phi:printf_number_buffer::@1/printf_number_buffer::@3->printf_number_buffer::@2]
    // printf_number_buffer::@2
  __b2:
    // printf_str(putc, buffer.digits)
    // [825] call printf_str
    // [266] phi from printf_number_buffer::@2 to printf_str [phi:printf_number_buffer::@2->printf_str]
    // [266] phi printf_str::putc#15 = printf_uint::putc#0 [phi:printf_number_buffer::@2->printf_str#0] -- pprz1=pprc1 
    lda #<printf_uint.putc
    sta.z printf_str.putc
    lda #>printf_uint.putc
    sta.z printf_str.putc+1
    // [266] phi printf_str::s#15 = printf_number_buffer::buffer_digits#0 [phi:printf_number_buffer::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<buffer_digits
    sta.z printf_str.s
    lda #>buffer_digits
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [826] return 
    rts
}
  // cbm_k_setlfs
/**
 * @brief Sets the logical file channel.
 *
 * @param channel the logical file number.
 * @param device the device number.
 * @param command the command.
 */
// void cbm_k_setlfs(__zp($c7) volatile char channel, __zp($c6) volatile char device, __zp($c2) volatile char command)
cbm_k_setlfs: {
    .label channel = $c7
    .label device = $c6
    .label command = $c2
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [828] return 
    rts
}
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
// __zp($af) int ferror(__zp($57) struct $2 *stream)
ferror: {
    .label ferror__6 = $40
    .label ferror__15 = $70
    .label cbm_k_setnam1_filename = $c4
    .label cbm_k_setnam1_filename_len = $be
    .label cbm_k_setnam1_ferror__0 = $6e
    .label cbm_k_chkin1_channel = $c3
    .label cbm_k_chkin1_status = $bf
    .label cbm_k_chrin1_ch = $c0
    .label cbm_k_readst1_status = $ab
    .label cbm_k_close1_channel = $c1
    .label cbm_k_chrin2_ch = $ac
    .label stream = $57
    .label return = $af
    .label sp = $67
    .label cbm_k_chrin1_return = $70
    .label ch = $70
    .label cbm_k_readst1_return = $40
    .label st = $40
    .label errno_len = $74
    .label cbm_k_chrin2_return = $70
    .label errno_parsed = $aa
    // unsigned char sp = (unsigned char)stream
    // [829] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [830] cbm_k_setlfs::channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.channel
    // [831] cbm_k_setlfs::device = 8 -- vbuz1=vbuc1 
    lda #8
    sta.z cbm_k_setlfs.device
    // [832] cbm_k_setlfs::command = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.command
    // [833] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [834] ferror::cbm_k_setnam1_filename = ferror::$18 -- pbuz1=pbuc1 
    lda #<ferror__18
    sta.z cbm_k_setnam1_filename
    lda #>ferror__18
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [835] strlen::str#4 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [836] call strlen
    // [774] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [774] phi strlen::str#7 = strlen::str#4 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [837] strlen::return#10 = strlen::len#2
    // ferror::@12
    // [838] ferror::cbm_k_setnam1_$0 = strlen::return#10
    // char filename_len = (char)strlen(filename)
    // [839] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
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
    // [842] ferror::cbm_k_chkin1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [843] ferror::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [845] ferror::cbm_k_chrin1_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [847] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [848] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [849] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [850] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [850] phi __errno#11 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    // [850] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    sta.z errno_len
    // [850] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [850] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [851] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [853] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [854] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [855] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [856] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [857] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [858] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [859] ferror::cbm_k_close1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [861] ferror::return#1 = __errno#11 -- vwsz1=vwsz2 
    lda.z __errno
    sta.z return
    lda.z __errno+1
    sta.z return+1
    // ferror::@return
    // }
    // [862] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [863] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [864] if(ferror::ch#10!=','pm) goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [865] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [866] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [867] call strncpy
    // [1118] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [868] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [869] call atoi
    // [881] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [881] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [870] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [871] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [872] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [872] phi __errno#60 = __errno#11 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [872] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [873] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [874] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [875] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [877] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [878] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [879] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [880] ferror::ch#1 = ferror::$15
    // [850] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [850] phi __errno#11 = __errno#60 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [850] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [850] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [850] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    ferror__18: .text ""
    .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($3b) int atoi(__zp($53) const char *str)
atoi: {
    .label atoi__6 = $3b
    .label atoi__7 = $3b
    .label res = $3b
    // Initialize sign as positive
    .label i = $40
    .label return = $3b
    .label str = $53
    // Initialize result
    .label negative = $4d
    .label atoi__10 = $47
    .label atoi__11 = $3b
    // if (str[i] == '-')
    // [882] if(*atoi::str#2!='-'pm) goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [883] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [884] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [884] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [884] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [884] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [884] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [884] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [884] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [884] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [885] if(atoi::str#2[atoi::i#4]<'0'pm) goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [886] if(atoi::str#2[atoi::i#4]<='9'pm) goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [887] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [889] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [889] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [888] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [890] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [891] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [892] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [893] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [894] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [895] atoi::res#1 = atoi::$7 - '0'pm -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [896] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [884] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [884] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [884] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [884] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
    jmp __b3
}
  // print_chip_led
// void print_chip_led(__zp($69) char x, char y, __zp($5a) char w, __zp($66) char tc, char bc)
print_chip_led: {
    .label i = $3f
    .label tc = $66
    .label x = $69
    .label w = $5a
    // gotoxy(x, y)
    // [898] gotoxy::x#8 = print_chip_led::x#3 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [899] call gotoxy
    // [186] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [186] phi gotoxy::y#17 = 3 [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #3
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = gotoxy::x#8 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@4
    // textcolor(tc)
    // [900] textcolor::color#10 = print_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [901] call textcolor
    // [168] phi from print_chip_led::@4 to textcolor [phi:print_chip_led::@4->textcolor]
    // [168] phi textcolor::color#16 = textcolor::color#10 [phi:print_chip_led::@4->textcolor#0] -- register_copy 
    jsr textcolor
    // [902] phi from print_chip_led::@4 to print_chip_led::@5 [phi:print_chip_led::@4->print_chip_led::@5]
    // print_chip_led::@5
    // bgcolor(bc)
    // [903] call bgcolor
    // [173] phi from print_chip_led::@5 to bgcolor [phi:print_chip_led::@5->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:print_chip_led::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [904] phi from print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@5->print_chip_led::@1]
    // [904] phi print_chip_led::i#2 = 0 [phi:print_chip_led::@5->print_chip_led::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_led::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [905] if(print_chip_led::i#2<print_chip_led::w#5) goto print_chip_led::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [906] phi from print_chip_led::@1 to print_chip_led::@3 [phi:print_chip_led::@1->print_chip_led::@3]
    // print_chip_led::@3
    // textcolor(WHITE)
    // [907] call textcolor
    // [168] phi from print_chip_led::@3 to textcolor [phi:print_chip_led::@3->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:print_chip_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [908] phi from print_chip_led::@3 to print_chip_led::@6 [phi:print_chip_led::@3->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [909] call bgcolor
    // [173] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [910] return 
    rts
    // print_chip_led::@2
  __b2:
    // cputc(0xE2)
    // [911] stackpush(char) = $e2 -- _stackpushbyte_=vbuc1 
    lda #$e2
    pha
    // [912] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [914] print_chip_led::i#1 = ++ print_chip_led::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [904] phi from print_chip_led::@2 to print_chip_led::@1 [phi:print_chip_led::@2->print_chip_led::@1]
    // [904] phi print_chip_led::i#2 = print_chip_led::i#1 [phi:print_chip_led::@2->print_chip_led::@1#0] -- register_copy 
    jmp __b1
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
// __zp($45) unsigned int fgets(__zp($3b) char *ptr, unsigned int size, __zp($b6) struct $2 *stream)
fgets: {
    .label fgets__1 = $68
    .label fgets__8 = $4e
    .label fgets__9 = $55
    .label fgets__13 = $3f
    .label cbm_k_chkin1_channel = $b5
    .label cbm_k_chkin1_status = $ad
    .label cbm_k_readst1_status = $ae
    .label cbm_k_readst2_status = $5b
    .label sp = $40
    .label cbm_k_readst1_return = $68
    .label return = $45
    .label bytes = $3d
    .label cbm_k_readst2_return = $4e
    .label read = $45
    .label ptr = $3b
    .label remaining = $57
    .label stream = $b6
    // unsigned char sp = (unsigned char)stream
    // [915] fgets::sp#0 = (char)fgets::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [916] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [917] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [919] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [921] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [922] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@9
    // cbm_k_readst()
    // [923] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [924] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [925] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b8
    // [926] phi from fgets::@10 fgets::@3 fgets::@9 to fgets::@return [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return]
  __b1:
    // [926] phi fgets::return#1 = 0 [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [927] return 
    rts
    // [928] phi from fgets::@13 to fgets::@1 [phi:fgets::@13->fgets::@1]
    // [928] phi fgets::read#10 = fgets::read#1 [phi:fgets::@13->fgets::@1#0] -- register_copy 
    // [928] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@13->fgets::@1#1] -- register_copy 
    // [928] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@13->fgets::@1#2] -- register_copy 
    // [928] phi from fgets::@9 to fgets::@1 [phi:fgets::@9->fgets::@1]
  __b8:
    // [928] phi fgets::read#10 = 0 [phi:fgets::@9->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [928] phi fgets::remaining#11 = flash_read::b#0 [phi:fgets::@9->fgets::@1#1] -- vwuz1=vbuc1 
    lda #<flash_read.b
    sta.z remaining
    lda #>flash_read.b
    sta.z remaining+1
    // [928] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@9->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@6
  __b6:
    // if (remaining >= 512)
    // [929] if(fgets::remaining#11>=$200) goto fgets::@2 -- vwuz1_ge_vwuc1_then_la1 
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
    // [930] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [931] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [932] call cx16_k_macptr
    jsr cx16_k_macptr
    // [933] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@12
  __b12:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [934] fgets::bytes#3 = cx16_k_macptr::return#4
    // [935] phi from fgets::@11 fgets::@12 to fgets::cbm_k_readst2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2]
    // [935] phi fgets::bytes#10 = fgets::bytes#2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [936] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [938] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [939] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@10
    // cbm_k_readst()
    // [940] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [941] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [942] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [943] if(0==fgets::$9) goto fgets::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    jmp __b1
    // fgets::@3
  __b3:
    // if (bytes == 0xFFFF)
    // [944] if(fgets::bytes#10!=$ffff) goto fgets::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [945] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [946] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [947] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [948] if(fgets::$13!=$c0) goto fgets::@5 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b5
    // fgets::@8
    // ptr -= 0x2000
    // [949] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [950] phi from fgets::@4 fgets::@8 to fgets::@5 [phi:fgets::@4/fgets::@8->fgets::@5]
    // [950] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@4/fgets::@8->fgets::@5#0] -- register_copy 
    // fgets::@5
  __b5:
    // remaining -= bytes
    // [951] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [952] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@13 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b13
    // [926] phi from fgets::@13 fgets::@5 to fgets::@return [phi:fgets::@13/fgets::@5->fgets::@return]
    // [926] phi fgets::return#1 = fgets::read#1 [phi:fgets::@13/fgets::@5->fgets::@return#0] -- register_copy 
    rts
    // fgets::@13
  __b13:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [953] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b6+
    jmp __b6
  !__b6:
    rts
    // fgets::@2
  __b2:
    // cx16_k_macptr(512, ptr)
    // [954] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [955] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [956] call cx16_k_macptr
    jsr cx16_k_macptr
    // [957] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@11
    // bytes = cx16_k_macptr(512, ptr)
    // [958] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b12
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $31
    .label insertup__4 = $2f
    .label insertup__6 = $30
    .label insertup__7 = $2f
    .label width = $31
    .label y = $2c
    // __conio.width+1
    // [959] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [960] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [961] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [961] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [962] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [963] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [964] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [965] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [966] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [967] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [968] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [969] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [970] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [971] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [972] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [973] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [974] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [975] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [961] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [961] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $24
    .label clearline__1 = $26
    .label clearline__2 = $27
    .label clearline__3 = $25
    .label addr = $2d
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [976] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [977] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [978] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [979] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [980] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [981] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [982] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [983] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [984] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [985] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [986] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [986] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [987] *VERA_DATA0 = ' 'pm -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [988] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [989] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [990] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [991] return 
    rts
}
  // frame_maskxy
// __zp($5a) char frame_maskxy(__zp($67) char x, __zp($64) char y)
frame_maskxy: {
    .label cpeekcxy1_cpeekc1_frame_maskxy__0 = $68
    .label cpeekcxy1_cpeekc1_frame_maskxy__1 = $4e
    .label cpeekcxy1_cpeekc1_frame_maskxy__2 = $55
    .label cpeekcxy1_x = $67
    .label cpeekcxy1_y = $64
    .label c = $3f
    // DR corner.
    // DL corner.
    // UR corner.
    // UL corner.
    // HL line.
    // VL line.
    // VR junction.
    // VL junction.
    // HD junction.
    // HU junction.
    // HV junction.
    .label return = $5a
    .label x = $67
    .label y = $64
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [993] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_x
    sta.z gotoxy.x
    // [994] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_y
    sta.z gotoxy.y
    // [995] call gotoxy
    // [186] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [186] phi gotoxy::y#17 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [186] phi gotoxy::x#17 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [996] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [997] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [998] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [999] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1000] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1001] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1002] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1003] frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1004] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1005] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1006] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1007] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1008] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1009] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1010] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1011] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1012] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1013] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1014] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [1016] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [1016] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [1015] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [1016] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [1016] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [1016] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [1016] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [1016] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [1016] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [1016] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [1016] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [1016] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [1016] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [1016] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [1016] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [1016] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // frame_maskxy::@return
    // }
    // [1017] return 
    rts
}
  // frame_char
// __zp($5e) char frame_char(__zp($5a) char mask)
frame_char: {
    .label return = $5e
    .label mask = $5a
    // case 0b0110:
    //             return 0x70;
    // [1019] if(frame_char::mask#10==6) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1020] if(frame_char::mask#10==3) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1021] if(frame_char::mask#10==$c) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1022] if(frame_char::mask#10==9) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1023] if(frame_char::mask#10==5) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1024] if(frame_char::mask#10==$a) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1025] if(frame_char::mask#10==$e) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1026] if(frame_char::mask#10==$b) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1027] if(frame_char::mask#10==7) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1028] if(frame_char::mask#10==$d) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1029] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [1031] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [1031] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [1030] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [1031] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [1031] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [1031] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [1031] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [1031] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [1031] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [1031] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [1031] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [1031] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [1031] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [1031] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [1031] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [1031] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [1031] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [1031] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [1031] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [1031] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [1031] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [1031] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [1031] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [1031] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [1031] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // frame_char::@return
    // }
    // [1032] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($59) char x, __zp($5f) char y, __zp($5e) char c)
cputcxy: {
    .label x = $59
    .label y = $5f
    .label c = $5e
    // gotoxy(x, y)
    // [1034] gotoxy::x#0 = cputcxy::x#9 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1035] gotoxy::y#0 = cputcxy::y#9 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1036] call gotoxy
    // [186] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [186] phi gotoxy::y#17 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [186] phi gotoxy::x#17 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1037] stackpush(char) = cputcxy::c#10 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1038] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1040] return 
    rts
}
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($57) const char *s)
cputs: {
    .label c = $4d
    .label s = $57
    // [1042] phi from cputs to cputs::@1 [phi:cputs->cputs::@1]
    // [1042] phi cputs::s#2 = frame_draw::s [phi:cputs->cputs::@1#0] -- pbuz1=pbuc1 
    lda #<frame_draw.s
    sta.z s
    lda #>frame_draw.s
    sta.z s+1
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1043] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [1044] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1045] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [1046] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1047] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1048] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1042] phi from cputs::@2 to cputs::@1 [phi:cputs::@2->cputs::@1]
    // [1042] phi cputs::s#2 = cputs::s#0 [phi:cputs::@2->cputs::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_line
// void print_chip_line(__zp($59) char x, __zp($5f) char y, __zp($62) char w, __zp($6d) char c)
print_chip_line: {
    .label i = $41
    .label x = $59
    .label w = $62
    .label c = $6d
    .label y = $5f
    // gotoxy(x, y)
    // [1051] gotoxy::x#6 = print_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1052] gotoxy::y#6 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1053] call gotoxy
    // [186] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [186] phi gotoxy::y#17 = gotoxy::y#6 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [186] phi gotoxy::x#17 = gotoxy::x#6 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1054] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [1055] call textcolor
    // [168] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [168] phi textcolor::color#16 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1056] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [1057] call bgcolor
    // [173] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1058] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1059] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1061] call textcolor
    // [168] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1062] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [1063] call bgcolor
    // [173] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [173] phi bgcolor::color#13 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1064] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [1064] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1065] if(print_chip_line::i#2<print_chip_line::w#10) goto print_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1066] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [1067] call textcolor
    // [168] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [168] phi textcolor::color#16 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1068] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [1069] call bgcolor
    // [173] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [1070] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1071] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1073] call textcolor
    // [168] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [168] phi textcolor::color#16 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1074] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [1075] call bgcolor
    // [173] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [173] phi bgcolor::color#13 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [1076] cputcxy::x#8 = print_chip_line::x#16 + 2 -- vbuz1=vbuz1_plus_2 
    lda.z cputcxy.x
    clc
    adc #2
    sta.z cputcxy.x
    // [1077] cputcxy::y#8 = print_chip_line::y#16
    // [1078] cputcxy::c#8 = print_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [1079] call cputcxy
    // [1033] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [1033] phi cputcxy::c#10 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [1033] phi cputcxy::y#9 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [1033] phi cputcxy::x#9 = cputcxy::x#8 [phi:print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [1080] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [1081] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1082] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1084] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1064] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [1064] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_end
// void print_chip_end(__zp($67) char x, char y, __zp($63) char w)
print_chip_end: {
    .label i = $42
    .label x = $67
    .label w = $63
    // gotoxy(x, y)
    // [1085] gotoxy::x#7 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1086] call gotoxy
    // [186] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [186] phi gotoxy::y#17 = print_chip::y#21 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #print_chip.y
    sta.z gotoxy.y
    // [186] phi gotoxy::x#17 = gotoxy::x#7 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1087] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [1088] call textcolor
    // [168] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [168] phi textcolor::color#16 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1089] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [1090] call bgcolor
    // [173] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [1091] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1092] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1094] call textcolor
    // [168] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [168] phi textcolor::color#16 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [1095] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [1096] call bgcolor
    // [173] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [173] phi bgcolor::color#13 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1097] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [1097] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1098] if(print_chip_end::i#2<print_chip_end::w#0) goto print_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1099] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [1100] call textcolor
    // [168] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [168] phi textcolor::color#16 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1101] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [1102] call bgcolor
    // [173] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [173] phi bgcolor::color#13 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [1103] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1104] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1106] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [1107] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1108] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1110] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1097] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [1097] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
    jmp __b1
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
// __zp($43) unsigned int utoa_append(__zp($7e) char *buffer, __zp($43) unsigned int value, __zp($50) unsigned int sub)
utoa_append: {
    .label buffer = $7e
    .label value = $43
    .label sub = $50
    .label return = $43
    .label digit = $3f
    // [1112] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1112] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1112] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1113] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1114] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1115] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1116] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1117] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1112] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1112] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1112] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($49) char *dst, __zp($3d) const char *src, __zp($5c) unsigned int n)
strncpy: {
    .label c = $4d
    .label dst = $49
    .label i = $45
    .label src = $3d
    .label n = $5c
    // [1119] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1119] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [1119] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [1119] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1120] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1121] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1122] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1123] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1124] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1125] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1125] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1126] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1127] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1128] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1119] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1119] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1119] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1119] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
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
// __zp($3d) unsigned int cx16_k_macptr(__zp($65) volatile char bytes, __zp($60) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $65
    .label buffer = $60
    .label bytes_read = $4b
    .label return = $3d
    // unsigned int bytes_read
    // [1129] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [1131] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [1132] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [1133] return 
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
// void memcpy8_vram_vram(__zp($25) char dbank_vram, __zp($2d) unsigned int doffset_vram, __zp($24) char sbank_vram, __zp($2a) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $26
    .label memcpy8_vram_vram__1 = $27
    .label memcpy8_vram_vram__2 = $24
    .label memcpy8_vram_vram__3 = $28
    .label memcpy8_vram_vram__4 = $29
    .label memcpy8_vram_vram__5 = $25
    .label num8 = $23
    .label dbank_vram = $25
    .label doffset_vram = $2d
    .label sbank_vram = $24
    .label soffset_vram = $2a
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1134] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1135] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1136] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1137] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1138] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1139] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1140] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1141] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1142] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1143] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1144] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1145] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1146] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1147] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1148] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1148] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1149] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [1150] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1151] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1152] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1153] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
    lda.z num8
    sta.z num8_1
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
  // Values of decimal digits
  RADIX_DECIMAL_VALUES: .word $2710, $3e8, $64, $a
  // Some addressing constants.
  // The different device IDs that can be returned from the manufacturer ID read sequence.
  // To print the graphics on the vera.
  file: .fill $20, 0
  isr_vsync: .word $314
  __conio: .fill SIZEOF_STRUCT___1, 0
  // Buffer used for stringified number being printed
  printf_buffer: .fill SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER, 0
  __stdio_file: .fill SIZEOF_STRUCT___2, 0
