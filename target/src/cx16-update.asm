  // File Comments
/**
 * @mainpage cx16-update.c
 * 
 * @author Wavicle -- Overall support and startup assistance for the chipset upgrade program.
 * @author Stefan Jakobsson -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde -- Creation of this program, under guidance of the SME of the people above.
 * 
 * @brief COMMANDER X16 FIRMWARE UPDATE UTILITY
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */
  // Upstart
.cpu _65c02
  .file                               [name="cx16-update.prg", type="prg", segments="Program"]
.segmentdef Program                 [segments="Basic, Code, Data" + 
                                     ", CodeIntro" +
                                     ", CodeVera" +
                                     ", DataIntro" +
                                     ", DataVera"
                                     ]
.segmentdef Basic                   [start=$0801]
.segmentdef Code                    [start=$80d]
.segmentdef Data                    [startAfter="Code"]
.segmentdef CodeIntro               [startAfter="Data"] 
.segmentdef CodeVera                [startAfter="CodeIntro"] 
.segmentdef DataIntro               [startAfter="CodeVera"] 
.segmentdef DataVera                [startAfter="DataIntro"] 



.segment Basic
:BasicUpstart(__start)
.segment Code
.segment Data


  // Global Constants & labels
  // To print the graphics on the vera.
  .const PROGRESS_X = 2
  .const PROGRESS_Y = $20
  .const PROGRESS_W = $40
  .const PROGRESS_H = $10
  /// The colors of the C64
  .const BLACK = 0
  .const WHITE = 1
  .const RED = 2
  .const CYAN = 3
  .const PURPLE = 4
  .const GREEN = 5
  .const BLUE = 6
  .const YELLOW = 7
  .const PINK = $a
  .const GREY = $c
  .const LIGHT_BLUE = $e
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
  .const CX16_SCREEN_MODE = $ff5f
  ///< CX16 Set/Get screen mode.
  .const CX16_SCREEN_SET_CHARSET = $ff62
  ///< CX16 Set character set.
  .const CX16_MACPTR = $ff44
  ///< CX16 Faster loading from SDCARD.
  .const CX16_I2C_READ_BYTE = $fec6
  ///< CX16 I2C read byte.
  .const CX16_I2C_WRITE_BYTE = $fec9
  .const BINARY = 2
  .const OCTAL = 8
  .const DECIMAL = $a
  .const HEXADECIMAL = $10
  .const VERA_INC_1 = $10
  .const VERA_DCSEL = 2
  .const VERA_ADDRSEL = 1
  .const VERA_SPRITES_ENABLE = $40
  .const VERA_LAYER1_ENABLE = $20
  .const VERA_LAYER0_ENABLE = $10
  .const VERA_LAYER_WIDTH_MASK = $30
  .const VERA_LAYER_HEIGHT_MASK = $c0
  .const display_intro_briefing_count = $f
  .const display_intro_colors_count = $10
  .const display_jp1_spi_vera_count = $10
  .const display_smc_rom_issue_count = 8
  .const display_smc_unsupported_rom_count = 7
  .const display_debriefing_count_smc = $e
  .const display_debriefing_count_rom = 4
  /**
 * @file cx16-smc.h
 * 
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @author Stefan Jakobsson from CX16 forums (
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)

 * @brief COMMANDER X16 SMC FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */
  .const SMC_CHIP_SIZE = $2000
  .const vera_size = $20000
  .const STATUS_NONE = 0
  .const STATUS_SKIP = 1
  .const STATUS_DETECTED = 2
  .const STATUS_CHECKING = 3
  .const STATUS_READING = 4
  .const STATUS_COMPARING = 5
  .const STATUS_FLASH = 6
  .const STATUS_FLASHING = 7
  .const STATUS_FLASHED = 8
  .const STATUS_ISSUE = 9
  .const STATUS_ERROR = $a
  .const ROM_PROGRESS_CELL = $200
  // A progress frame cell represents about 512 bytes for a ROM update.
  .const ROM_PROGRESS_ROW = $8000
  // A progress frame row represents about 32768 bytes for a ROM update.
  .const SMC_PROGRESS_CELL = 8
  // A progress frame cell represents about 8 bytes for a SMC update.
  .const SMC_PROGRESS_ROW = $200
  // A progress frame row represents about 512 bytes for a SMC update.
  .const VERA_PROGRESS_CELL = $80
  // A progress frame cell represents about 128 bytes for a VERA compare.
  .const VERA_PROGRESS_PAGE = $100
  // A progress frame cell represents about 256 bytes for a VERA flash.
  .const VERA_PROGRESS_ROW = $2000
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
  /// $9F29	DC_VIDEO (DCSEL=0)
  /// Bit 7: Current Field     Read-only bit which reflects the active interlaced field in composite and RGB modes. (0: even, 1: odd)
  /// Bit 6: Sprites Enable	Enable output from the Sprites renderer
  /// Bit 5: Layer1 Enable	    Enable output from the Layer1 renderer
  /// Bit 4: Layer0 Enable	    Enable output from the Layer0 renderer
  /// Bit 2: Chroma Disable    Setting 'Chroma Disable' disables output of chroma in NTSC composite mode and will give a better picture on a monochrome display. (Setting this bit will also disable the chroma output on the S-video output.)
  /// Bit 0-1: Output Mode     0: Video disabled, 1: VGA output, 2: NTSC composite, 3: RGB interlaced, composite sync (via VGA connector)
  .label VERA_DC_VIDEO = $9f29
  /// $9F2A	DC_HSCALE (DCSEL=0)	Active Display H-Scale
  .label VERA_DC_HSCALE = $9f2a
  /// $9F2B	DC_VSCALE (DCSEL=0)	Active Display V-Scale
  .label VERA_DC_VSCALE = $9f2b
  /// $9F2C	DC_BORDER (DCSEL=0)	Border Color
  .label VERA_DC_BORDER = $9f2c
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
  .label vera_reg_SPIData = $9f3e
  .label vera_reg_SPICtrl = $9f3f
  .label BRAM = 0
  .label BROM = 1
  /// Current position in the buffer being filled ( initially *s passed to snprintf()
  /// Used to hold state while printing
  .label __snprintf_buffer = $65
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
// void snputc(__mem() char c)
snputc: {
    .const OFFSET_STACK_C = 0
    // [9] snputc::c#0 = stackidx(char,snputc::OFFSET_STACK_C) -- vbum1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta c
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
    // [15] phi snputc::c#2 = 0 [phi:snputc::@1->snputc::@2#0] -- vbum1=vbuc1 
    lda #0
    sta c
    // [14] phi from snputc::@1 to snputc::@3 [phi:snputc::@1->snputc::@3]
    // snputc::@3
    // [15] phi from snputc::@3 to snputc::@2 [phi:snputc::@3->snputc::@2]
    // [15] phi snputc::c#2 = snputc::c#0 [phi:snputc::@3->snputc::@2#0] -- register_copy 
    // snputc::@2
  __b2:
    // *(__snprintf_buffer++) = c
    // [16] *__snprintf_buffer = snputc::c#2 -- _deref_pbuz1=vbum2 
    // Append char
    lda c
    ldy #0
    sta (__snprintf_buffer),y
    // *(__snprintf_buffer++) = c;
    // [17] __snprintf_buffer = ++ __snprintf_buffer -- pbuz1=_inc_pbuz1 
    inc.z __snprintf_buffer
    bne !+
    inc.z __snprintf_buffer+1
  !:
    rts
  .segment Data
    c: .byte 0
}
.segment Code
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    .label conio_x16_init__5 = $7f
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [754] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [759] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
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
    // [29] conio_x16_init::$4 = cbm_k_plot_get::return#2 -- vwum1=vwum2 
    lda cbm_k_plot_get.return
    sta conio_x16_init__4
    lda cbm_k_plot_get.return+1
    sta conio_x16_init__4+1
    // BYTE1(cbm_k_plot_get())
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwum2 
    sta.z conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
    sta __conio
    // cbm_k_plot_get()
    // [32] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [33] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [34] conio_x16_init::$6 = cbm_k_plot_get::return#3 -- vwum1=vwum2 
    lda cbm_k_plot_get.return
    sta conio_x16_init__6
    lda cbm_k_plot_get.return+1
    sta conio_x16_init__6+1
    // BYTE0(cbm_k_plot_get())
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbum1=_byte0_vwum2 
    lda conio_x16_init__6
    sta conio_x16_init__7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbum1 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#2 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta gotoxy.x
    // [38] gotoxy::y#2 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta gotoxy.y
    // [39] call gotoxy
    // [772] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    conio_x16_init__4: .word 0
    conio_x16_init__6: .word 0
    conio_x16_init__7: .byte 0
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__mem() char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $49
    .label cputc__3 = $4a
    // [43] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbum1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta c
    // if(c=='\n')
    // [44] if(cputc::c#0==' ') goto cputc::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #'\n'
    cmp c
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
    sta.z cputc__1
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [47] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [48] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cputc__2
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [49] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [50] cputc::$3 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z cputc__3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [51] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [52] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbum1 
    lda c
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [53] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // if(!__conio.hscroll[__conio.layer])
    // [54] if(0==((char *)&__conio+$11)[*((char *)&__conio+2)]) goto cputc::@5 -- 0_eq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$11,y
    cmp #0
    beq __b5
    // cputc::@3
    // if(__conio.cursor_x >= __conio.mapwidth)
    // [55] if(*((char *)&__conio)>=*((char *)&__conio+8)) goto cputc::@6 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+8
    bcs __b6
    // cputc::@4
    // __conio.cursor_x++;
    // [56] *((char *)&__conio) = ++ *((char *)&__conio) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio
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
    rts
    // cputc::@5
  __b5:
    // if(__conio.cursor_x >= __conio.width)
    // [62] if(*((char *)&__conio)>=*((char *)&__conio+6)) goto cputc::@7 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+6
    bcs __b7
    // cputc::@8
    // __conio.cursor_x++;
    // [63] *((char *)&__conio) = ++ *((char *)&__conio) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio
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
    // [66] phi from cputc::@5 to cputc::@7 [phi:cputc::@5->cputc::@7]
    // cputc::@7
  __b7:
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
  .segment Data
    c: .byte 0
}
.segment Code
  // main
main: {
    .const bank_set_brom1_bank = 4
    .const bank_set_brom3_bank = 4
    .const bank_set_brom4_bank = 0
    .const bank_set_brom5_bank = 0
    .const bank_set_brom6_bank = 4
    .const bank_push_set_bram1_bank = 1
    .const bank_set_bram1_bank = 0
    .const bank_set_brom7_bank = 4
    .const bank_set_brom8_bank = 0
    .const bank_set_brom9_bank = 0
    .const bank_set_brom10_bank = 4
    .label main__87 = $cb
    .label main__111 = $e1
    .label main__112 = $e2
    .label main__113 = $ca
    .label main__192 = $5f
    .label check_status_smc1_main__0 = $6b
    .label check_status_rom1_main__0 = $e3
    .label check_status_smc11_main__0 = $e4
    .label check_status_smc12_main__0 = $e5
    .label rom_chip = $d3
    .label rom_chip1 = $d4
    .label rom_chip2 = $d8
    .label rom_bytes_read = $e6
    .label rom_file_modulo = $dd
    .label rom_file_prefix = $ea
    .label rom_chip3 = $ce
    .label flashed_bytes = $79
    .label rom_chip4 = $d7
    .label file1 = $cc
    .label rom_bytes_read1 = $d9
    .label rom_differences = $f1
    .label rom_flash_errors = $f5
    .label w = $d6
    .label w1 = $d5
    .label main__372 = $cb
    .label main__373 = $cb
    .label main__374 = $cb
    .label main__376 = $ca
    .label main__377 = $ca
    .label main__378 = $ca
    // display_frame_init_64()
    // [71] call display_frame_init_64
    // Get the current screen mode ...
    /**
    screen_mode = cx16_k_screen_get_mode();
    printf("Screen mode: %x, x:%x, y:%x", screen_mode.mode, screen_mode.x, screen_mode.y);
    if(cx16_k_screen_mode_is_40(&screen_mode)) {
        printf("Running in 40 columns\n");
        wait_key("Press a key ...", NULL);
    } else {
        if(cx16_k_screen_mode_is_80(&screen_mode)) {
            printf("Running in 40 columns\n");
            wait_key("Press a key ...", NULL);
        } else {
            printf("Screen mode now known ...\n");
            wait_key("Press a key ...", NULL);
        }
    }
    */
    jsr display_frame_init_64
    // [72] phi from main to main::@93 [phi:main->main::@93]
    // main::@93
    // display_frame_draw()
    // [73] call display_frame_draw
  // ST1 | Reset canvas to 64 columns
    // [821] phi from main::@93 to display_frame_draw [phi:main::@93->display_frame_draw]
    jsr display_frame_draw
    // [74] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // display_frame_title("Commander X16 Update Utility (v2.2.0).")
    // [75] call display_frame_title
    // [862] phi from main::@94 to display_frame_title [phi:main::@94->display_frame_title]
    jsr display_frame_title
    // [76] phi from main::@94 to main::display_info_title1 [phi:main::@94->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [77] call cputsxy
    // [867] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [867] phi cputsxy::s#4 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [867] phi cputsxy::y#4 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [867] phi cputsxy::x#4 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [78] phi from main::display_info_title1 to main::@95 [phi:main::display_info_title1->main::@95]
    // main::@95
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [79] call cputsxy
    // [867] phi from main::@95 to cputsxy [phi:main::@95->cputsxy]
    // [867] phi cputsxy::s#4 = main::s1 [phi:main::@95->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [867] phi cputsxy::y#4 = $11-1 [phi:main::@95->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [867] phi cputsxy::x#4 = 4-2 [phi:main::@95->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [80] phi from main::@95 to main::@61 [phi:main::@95->main::@61]
    // main::@61
    // display_action_progress("Introduction, please read carefully the below!")
    // [81] call display_action_progress
    // [874] phi from main::@61 to display_action_progress [phi:main::@61->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text [phi:main::@61->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [82] phi from main::@61 to main::@96 [phi:main::@61->main::@96]
    // main::@96
    // display_progress_clear()
    // [83] call display_progress_clear
    // [888] phi from main::@96 to display_progress_clear [phi:main::@96->display_progress_clear]
    jsr display_progress_clear
    // [84] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // display_chip_smc()
    // [85] call display_chip_smc
    // [903] phi from main::@97 to display_chip_smc [phi:main::@97->display_chip_smc]
    jsr display_chip_smc
    // [86] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // display_chip_vera()
    // [87] call display_chip_vera
    // [908] phi from main::@98 to display_chip_vera [phi:main::@98->display_chip_vera]
    jsr display_chip_vera
    // [88] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // display_chip_rom()
    // [89] call display_chip_rom
    // [913] phi from main::@99 to display_chip_rom [phi:main::@99->display_chip_rom]
    jsr display_chip_rom
    // [90] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [91] call display_info_smc
    // [932] phi from main::@100 to display_info_smc [phi:main::@100->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = 0 [phi:main::@100->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = 0 [phi:main::@100->display_info_smc#1] -- vwum1=vwuc1 
    sta smc_bootloader
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = BLACK [phi:main::@100->display_info_smc#2] -- vbum1=vbuc1 
    lda #BLACK
    sta display_info_smc.info_status
    jsr display_info_smc
    // [92] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // display_info_vera(STATUS_NONE, NULL)
    // [93] call display_info_vera
    // [968] phi from main::@101 to display_info_vera [phi:main::@101->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = 0 [phi:main::@101->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 0 [phi:main::@101->display_info_vera#1] -- vbum1=vbuc1 
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 0 [phi:main::@101->display_info_vera#2] -- vbum1=vbuc1 
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 0 [phi:main::@101->display_info_vera#3] -- vbum1=vbuc1 
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_NONE [phi:main::@101->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_vera.info_status
    jsr display_info_vera
    // [94] phi from main::@101 to main::@11 [phi:main::@101->main::@11]
    // [94] phi main::rom_chip#2 = 0 [phi:main::@101->main::@11#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // main::@11
  __b11:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [95] if(main::rom_chip#2<8) goto main::@12 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcs !__b12+
    jmp __b12
  !__b12:
    // [96] phi from main::@11 to main::@13 [phi:main::@11->main::@13]
    // main::@13
    // main_intro()
    // [97] call main_intro
    // [1008] phi from main::@13 to main_intro [phi:main::@13->main_intro]
    jsr main_intro
    // [98] phi from main::@13 to main::@104 [phi:main::@13->main::@104]
    // main::@104
    // smc_detect()
    // [99] call smc_detect
    // [1025] phi from main::@104 to smc_detect [phi:main::@104->smc_detect]
    jsr smc_detect
    // [100] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // strcpy(smc_version_text, "0.0.0")
    // [101] call strcpy
    // [1027] phi from main::@105 to strcpy [phi:main::@105->strcpy]
    // [1027] phi strcpy::dst#0 = smc_version_text [phi:main::@105->strcpy#0] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z strcpy.dst
    lda #>smc_version_text
    sta.z strcpy.dst+1
    // [1027] phi strcpy::src#0 = main::source1 [phi:main::@105->strcpy#1] -- pbuz1=pbuc1 
    lda #<source1
    sta.z strcpy.src
    lda #>source1
    sta.z strcpy.src+1
    jsr strcpy
    // [102] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // display_chip_smc()
    // [103] call display_chip_smc
    // [903] phi from main::@106 to display_chip_smc [phi:main::@106->display_chip_smc]
    jsr display_chip_smc
    // main::@14
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [104] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [105] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [106] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [107] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // main::@107
    // smc_release = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [108] smc_release#0 = cx16_k_i2c_read_byte::return#12 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_release
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [109] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [110] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [111] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [112] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // main::@108
    // smc_major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [113] smc_major#0 = cx16_k_i2c_read_byte::return#13 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_major
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [114] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [115] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [116] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [117] cx16_k_i2c_read_byte::return#14 = cx16_k_i2c_read_byte::return#1
    // main::@109
    // smc_minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [118] smc_minor#0 = cx16_k_i2c_read_byte::return#14 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_minor
    // smc_get_version_text(smc_version_text, smc_release, smc_major, smc_minor)
    // [119] smc_get_version_text::release#0 = smc_release#0 -- vbum1=vbum2 
    lda smc_release
    sta smc_get_version_text.release
    // [120] smc_get_version_text::major#0 = smc_major#0 -- vbum1=vbum2 
    lda smc_major
    sta smc_get_version_text.major
    // [121] smc_get_version_text::minor#0 = smc_minor#0 -- vbum1=vbum2 
    lda smc_minor
    sta smc_get_version_text.minor
    // [122] call smc_get_version_text
    // [1040] phi from main::@109 to smc_get_version_text [phi:main::@109->smc_get_version_text]
    // [1040] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#0 [phi:main::@109->smc_get_version_text#0] -- register_copy 
    // [1040] phi smc_get_version_text::major#2 = smc_get_version_text::major#0 [phi:main::@109->smc_get_version_text#1] -- register_copy 
    // [1040] phi smc_get_version_text::release#2 = smc_get_version_text::release#0 [phi:main::@109->smc_get_version_text#2] -- register_copy 
    // [1040] phi smc_get_version_text::version_string#2 = smc_version_text [phi:main::@109->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [123] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // display_info_smc(STATUS_DETECTED, NULL)
    // [124] call display_info_smc
    // [932] phi from main::@110 to display_info_smc [phi:main::@110->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = 0 [phi:main::@110->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@110->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_DETECTED [phi:main::@110->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_smc.info_status
    jsr display_info_smc
    // [125] phi from main::@110 to main::@1 [phi:main::@110->main::@1]
    // main::@1
    // main_vera_detect()
    // [126] call main_vera_detect
    // [1057] phi from main::@1 to main_vera_detect [phi:main::@1->main_vera_detect]
    jsr main_vera_detect
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [128] phi from main::SEI1 to main::@62 [phi:main::SEI1->main::@62]
    // main::@62
    // rom_detect()
    // [129] call rom_detect
  // Detecting ROM chips
    // [1063] phi from main::@62 to rom_detect [phi:main::@62->rom_detect]
    jsr rom_detect
    // [130] phi from main::@62 to main::@111 [phi:main::@62->main::@111]
    // main::@111
    // display_chip_rom()
    // [131] call display_chip_rom
    // [913] phi from main::@111 to display_chip_rom [phi:main::@111->display_chip_rom]
    jsr display_chip_rom
    // [132] phi from main::@111 to main::@15 [phi:main::@111->main::@15]
    // [132] phi main::rom_chip1#10 = 0 [phi:main::@111->main::@15#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip1
    // main::@15
  __b15:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [133] if(main::rom_chip1#10<8) goto main::@16 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip1
    cmp #8
    bcs !__b16+
    jmp __b16
  !__b16:
    // main::bank_set_brom1
    // BROM = bank
    // [134] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc1
    // status_smc == status
    // [136] main::check_status_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [137] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0 -- vbum1=vbuz2 
    sta check_status_smc1_return
    // main::@63
    // if(check_status_smc(STATUS_DETECTED))
    // [138] if(0==main::check_status_smc1_return#0) goto main::CLI2 -- 0_eq_vbum1_then_la1 
    bne !__b1+
    jmp __b1
  !__b1:
    // [139] phi from main::@63 to main::@19 [phi:main::@63->main::@19]
    // main::@19
    // display_action_progress("Checking SMC.BIN ...")
    // [140] call display_action_progress
    // [874] phi from main::@19 to display_action_progress [phi:main::@19->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text3 [phi:main::@19->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [141] phi from main::@19 to main::@117 [phi:main::@19->main::@117]
    // main::@117
    // smc_read(STATUS_CHECKING)
    // [142] call smc_read
    // [1117] phi from main::@117 to smc_read [phi:main::@117->smc_read]
    // [1117] phi __errno#102 = 0 [phi:main::@117->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [1117] phi __stdio_filecount#128 = 0 [phi:main::@117->smc_read#1] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [1117] phi smc_read::info_status#10 = STATUS_CHECKING [phi:main::@117->smc_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_CHECKING)
    // [143] smc_read::return#2 = smc_read::return#0
    // main::@118
    // smc_file_size = smc_read(STATUS_CHECKING)
    // [144] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [145] if(0==smc_file_size#0) goto main::@22 -- 0_eq_vwum1_then_la1 
    lda smc_file_size
    ora smc_file_size+1
    bne !__b22+
    jmp __b22
  !__b22:
    // main::@20
    // if(smc_file_size > 0x1E00)
    // [146] if(smc_file_size#0>$1e00) goto main::@23 -- vwum1_gt_vwuc1_then_la1 
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b23+
    jmp __b23
  !__b23:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b23+
    jmp __b23
  !__b23:
  !:
    // main::@21
    // smc_file_release = smc_file_header[0]
    // [147] smc_file_release#0 = *smc_file_header -- vbum1=_deref_pbuc1 
    // SF4 | SMC.BIN and all ok | Display the SMC.BIN file version and set SMC to Flash. | Flash
    // The first 3 bytes of the smc file header is the version of the SMC file.
    lda smc_file_header
    sta smc_file_release
    // smc_file_major = smc_file_header[1]
    // [148] smc_file_major#0 = *(smc_file_header+1) -- vbum1=_deref_pbuc1 
    lda smc_file_header+1
    sta smc_file_major
    // smc_file_minor = smc_file_header[2]
    // [149] smc_file_minor#0 = *(smc_file_header+2) -- vbum1=_deref_pbuc1 
    lda smc_file_header+2
    sta smc_file_minor
    // smc_get_version_text(smc_file_version_text, smc_file_release, smc_file_major, smc_file_minor)
    // [150] smc_get_version_text::release#1 = smc_file_release#0 -- vbum1=vbum2 
    lda smc_file_release
    sta smc_get_version_text.release
    // [151] smc_get_version_text::major#1 = smc_file_major#0 -- vbum1=vbum2 
    lda smc_file_major
    sta smc_get_version_text.major
    // [152] smc_get_version_text::minor#1 = smc_file_minor#0 -- vbum1=vbum2 
    lda smc_file_minor
    sta smc_get_version_text.minor
    // [153] call smc_get_version_text
    // [1040] phi from main::@21 to smc_get_version_text [phi:main::@21->smc_get_version_text]
    // [1040] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#1 [phi:main::@21->smc_get_version_text#0] -- register_copy 
    // [1040] phi smc_get_version_text::major#2 = smc_get_version_text::major#1 [phi:main::@21->smc_get_version_text#1] -- register_copy 
    // [1040] phi smc_get_version_text::release#2 = smc_get_version_text::release#1 [phi:main::@21->smc_get_version_text#2] -- register_copy 
    // [1040] phi smc_get_version_text::version_string#2 = main::smc_file_version_text [phi:main::@21->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_file_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [154] phi from main::@21 to main::@119 [phi:main::@21->main::@119]
    // main::@119
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [155] call snprintf_init
    // [1167] phi from main::@119 to snprintf_init [phi:main::@119->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@119->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [156] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [157] call printf_str
    // [1172] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s4 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [158] phi from main::@120 to main::@121 [phi:main::@120->main::@121]
    // main::@121
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [159] call printf_string
    // [1181] phi from main::@121 to printf_string [phi:main::@121->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:main::@121->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = main::smc_file_version_text [phi:main::@121->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z printf_string.str
    lda #>smc_file_version_text
    sta.z printf_string.str+1
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:main::@121->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:main::@121->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@122
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [160] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [161] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_FLASH, info_text)
    // [163] call display_info_smc
  // All ok, display file version.
    // [932] phi from main::@122 to display_info_smc [phi:main::@122->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = info_text [phi:main::@122->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@122->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_FLASH [phi:main::@122->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [164] phi from main::@122 to main::CLI2 [phi:main::@122->main::CLI2]
    // [164] phi smc_file_minor#301 = smc_file_minor#0 [phi:main::@122->main::CLI2#0] -- register_copy 
    // [164] phi smc_file_major#301 = smc_file_major#0 [phi:main::@122->main::CLI2#1] -- register_copy 
    // [164] phi smc_file_release#301 = smc_file_release#0 [phi:main::@122->main::CLI2#2] -- register_copy 
    // [164] phi __stdio_filecount#109 = __stdio_filecount#39 [phi:main::@122->main::CLI2#3] -- register_copy 
    // [164] phi __errno#112 = __errno#122 [phi:main::@122->main::CLI2#4] -- register_copy 
    jmp CLI2
    // [164] phi from main::@63 to main::CLI2 [phi:main::@63->main::CLI2]
  __b1:
    // [164] phi smc_file_minor#301 = 0 [phi:main::@63->main::CLI2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [164] phi smc_file_major#301 = 0 [phi:main::@63->main::CLI2#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [164] phi smc_file_release#301 = 0 [phi:main::@63->main::CLI2#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [164] phi __stdio_filecount#109 = 0 [phi:main::@63->main::CLI2#3] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [164] phi __errno#112 = 0 [phi:main::@63->main::CLI2#4] -- vwsm1=vwsc1 
    sta __errno
    sta __errno+1
    // main::CLI2
  CLI2:
    // asm
    // asm { cli  }
    cli
    // main::bank_set_brom3
    // BROM = bank
    // [166] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // [168] phi from main::CLI3 to main::@65 [phi:main::CLI3->main::@65]
    // main::@65
    // display_progress_clear()
    // [169] call display_progress_clear
    // [888] phi from main::@65 to display_progress_clear [phi:main::@65->display_progress_clear]
    jsr display_progress_clear
    // [170] phi from main::@65 to main::@116 [phi:main::@65->main::@116]
    // main::@116
    // main_vera_check()
    // [171] call main_vera_check
    // [1206] phi from main::@116 to main_vera_check [phi:main::@116->main_vera_check]
    jsr main_vera_check
    // main::bank_set_brom4
    // BROM = bank
    // [172] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::SEI3
    // asm { sei  }
    sei
    // [175] phi from main::SEI3 to main::@24 [phi:main::SEI3->main::@24]
    // [175] phi __stdio_filecount#111 = __stdio_filecount#36 [phi:main::SEI3->main::@24#0] -- register_copy 
    // [175] phi __errno#114 = __errno#122 [phi:main::SEI3->main::@24#1] -- register_copy 
    // [175] phi main::rom_chip2#10 = 0 [phi:main::SEI3->main::@24#2] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip2
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@24
  __b24:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [176] if(main::rom_chip2#10<8) goto main::bank_set_brom5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip2
    cmp #8
    bcs !bank_set_brom5+
    jmp bank_set_brom5
  !bank_set_brom5:
    // main::bank_set_brom6
    // BROM = bank
    // [177] BROM = main::bank_set_brom6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom6_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc2
    // status_smc == status
    // [179] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [180] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0 -- vbum1=vbum2 
    sta check_status_smc2_return
    // [181] phi from main::check_status_smc2 to main::check_status_cx16_rom1 [phi:main::check_status_smc2->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [182] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [183] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom1_check_status_rom1_return
    // main::@67
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [184] if(0!=main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc2_return
    bne check_status_smc3
    // main::@233
    // [185] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@31 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom1_check_status_rom1_return
    beq !__b31+
    jmp __b31
  !__b31:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [186] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [187] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0 -- vbum1=vbum2 
    sta check_status_smc3_return
    // [188] phi from main::check_status_smc3 to main::check_status_cx16_rom2 [phi:main::check_status_smc3->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [189] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_NONE -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [190] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom2_check_status_rom1_return
    // main::@70
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [191] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbum1_then_la1 
    // VA3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
    lda check_status_smc3_return
    beq check_status_smc4
    // main::@234
    // [192] if(0!=main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@2 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom2_check_status_rom1_return
    beq !__b2+
    jmp __b2
  !__b2:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [193] main::check_status_smc4_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [194] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0 -- vbum1=vbum2 
    sta check_status_smc4_return
    // [195] phi from main::check_status_smc4 to main::check_status_cx16_rom3 [phi:main::check_status_smc4->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [196] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [197] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom3_check_status_rom1_return
    // main::@71
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [198] if(0==main::check_status_smc4_return#0) goto main::check_status_smc5 -- 0_eq_vbum1_then_la1 
    lda check_status_smc4_return
    beq check_status_smc5
    // main::@235
    // [199] if(0==main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@4 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom3_check_status_rom1_return
    bne !__b4+
    jmp __b4
  !__b4:
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [200] main::check_status_smc5_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [201] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0 -- vbum1=vbum2 
    sta check_status_smc5_return
    // [202] phi from main::check_status_smc5 to main::check_status_cx16_rom4 [phi:main::check_status_smc5->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [203] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [204] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom4_check_status_rom1_return
    // main::@72
    // smc_supported_rom(rom_release[0])
    // [205] smc_supported_rom::rom_release#0 = *rom_release -- vbum1=_deref_pbuc1 
    lda rom_release
    sta smc_supported_rom.rom_release
    // [206] call smc_supported_rom
    // [1231] phi from main::@72 to smc_supported_rom [phi:main::@72->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_release[0])
    // [207] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@157
    // [208] main::$45 = smc_supported_rom::return#3 -- vbum1=vbum2 
    lda smc_supported_rom.return
    sta main__45
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_release[0]))
    // [209] if(0==main::check_status_smc5_return#0) goto main::check_status_smc6 -- 0_eq_vbum1_then_la1 
    lda check_status_smc5_return
    beq check_status_smc6
    // main::@237
    // [210] if(0==main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::check_status_smc6 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom4_check_status_rom1_return
    beq check_status_smc6
    // main::@236
    // [211] if(0==main::$45) goto main::@5 -- 0_eq_vbum1_then_la1 
    lda main__45
    bne !__b5+
    jmp __b5
  !__b5:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [212] main::check_status_smc6_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [213] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0 -- vbum1=vbum2 
    sta check_status_smc6_return
    // main::@73
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [214] if(0==main::check_status_smc6_return#0) goto main::check_status_smc7 -- 0_eq_vbum1_then_la1 
    beq check_status_smc7
    // main::@240
    // [215] if(smc_release#0==smc_file_release#301) goto main::@239 -- vbum1_eq_vbum2_then_la1 
    lda smc_release
    cmp smc_file_release
    bne !__b239+
    jmp __b239
  !__b239:
    // main::check_status_smc7
  check_status_smc7:
    // status_smc == status
    // [216] main::check_status_smc7_$0 = status_smc#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [217] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0 -- vbum1=vbum2 
    sta check_status_smc7_return
    // main::check_status_vera1
    // status_vera == status
    // [218] main::check_status_vera1_$0 = status_vera#115 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [219] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0 -- vbum1=vbum2 
    sta check_status_vera1_return
    // [220] phi from main::check_status_vera1 to main::@74 [phi:main::check_status_vera1->main::@74]
    // main::@74
    // check_status_roms(STATUS_ISSUE)
    // [221] call check_status_roms
    // [1238] phi from main::@74 to check_status_roms [phi:main::@74->check_status_roms]
    // [1238] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@74->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [222] check_status_roms::return#3 = check_status_roms::return#2
    // main::@162
    // [223] main::$62 = check_status_roms::return#3 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__62
    // main::check_status_smc8
    // status_smc == status
    // [224] main::check_status_smc8_$0 = status_smc#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [225] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0 -- vbum1=vbum2 
    sta check_status_smc8_return
    // main::check_status_vera2
    // status_vera == status
    // [226] main::check_status_vera2_$0 = status_vera#115 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [227] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0 -- vbum1=vbum2 
    sta check_status_vera2_return
    // [228] phi from main::check_status_vera2 to main::@75 [phi:main::check_status_vera2->main::@75]
    // main::@75
    // check_status_roms(STATUS_ERROR)
    // [229] call check_status_roms
    // [1238] phi from main::@75 to check_status_roms [phi:main::@75->check_status_roms]
    // [1238] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@75->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [230] check_status_roms::return#4 = check_status_roms::return#2
    // main::@163
    // [231] main::$71 = check_status_roms::return#4 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__71
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [232] if(0!=main::check_status_smc7_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc7_return
    bne check_status_vera3
    // main::@245
    // [233] if(0==main::check_status_vera1_return#0) goto main::@244 -- 0_eq_vbum1_then_la1 
    lda check_status_vera1_return
    bne !__b244+
    jmp __b244
  !__b244:
    // main::check_status_vera3
  check_status_vera3:
    // status_vera == status
    // [234] main::check_status_vera3_$0 = status_vera#115 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [235] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0 -- vbum1=vbum2 
    sta check_status_vera3_return
    // main::@76
    // if(check_status_vera(STATUS_ERROR))
    // [236] if(0==main::check_status_vera3_return#0) goto main::check_status_smc13 -- 0_eq_vbum1_then_la1 
    bne !check_status_smc13+
    jmp check_status_smc13
  !check_status_smc13:
    // main::bank_set_brom10
    // BROM = bank
    // [237] BROM = main::bank_set_brom10_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom10_bank
    sta.z BROM
    // main::CLI6
    // asm
    // asm { cli  }
    cli
    // main::vera_display_set_border_color1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [239] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [240] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [241] phi from main::vera_display_set_border_color1 to main::@85 [phi:main::vera_display_set_border_color1->main::@85]
    // main::@85
    // textcolor(WHITE)
    // [242] call textcolor
    // [754] phi from main::@85 to textcolor [phi:main::@85->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:main::@85->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [243] phi from main::@85 to main::@200 [phi:main::@85->main::@200]
    // main::@200
    // bgcolor(BLUE)
    // [244] call bgcolor
    // [759] phi from main::@200 to bgcolor [phi:main::@200->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:main::@200->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [245] phi from main::@200 to main::@201 [phi:main::@200->main::@201]
    // main::@201
    // clrscr()
    // [246] call clrscr
    jsr clrscr
    // [247] phi from main::@201 to main::@202 [phi:main::@201->main::@202]
    // main::@202
    // printf("There was a severe error updating your VERA!")
    // [248] call printf_str
    // [1172] phi from main::@202 to printf_str [phi:main::@202->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:main::@202->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s15 [phi:main::@202->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // [249] phi from main::@202 to main::@203 [phi:main::@202->main::@203]
    // main::@203
    // printf("You are back at the READY prompt without resetting your CX16.\n\n")
    // [250] call printf_str
    // [1172] phi from main::@203 to printf_str [phi:main::@203->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:main::@203->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s16 [phi:main::@203->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // [251] phi from main::@203 to main::@204 [phi:main::@203->main::@204]
    // main::@204
    // printf("Please don't reset or shut down your VERA until you've\n")
    // [252] call printf_str
    // [1172] phi from main::@204 to printf_str [phi:main::@204->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:main::@204->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s17 [phi:main::@204->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // [253] phi from main::@204 to main::@205 [phi:main::@204->main::@205]
    // main::@205
    // printf("managed to either reflash your VERA with the previous firmware ")
    // [254] call printf_str
    // [1172] phi from main::@205 to printf_str [phi:main::@205->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:main::@205->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s18 [phi:main::@205->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // [255] phi from main::@205 to main::@206 [phi:main::@205->main::@206]
    // main::@206
    // printf("or have update successs retrying!\n\n")
    // [256] call printf_str
    // [1172] phi from main::@206 to printf_str [phi:main::@206->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:main::@206->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s19 [phi:main::@206->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // [257] phi from main::@206 to main::@207 [phi:main::@206->main::@207]
    // main::@207
    // printf("PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n")
    // [258] call printf_str
    // [1172] phi from main::@207 to printf_str [phi:main::@207->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:main::@207->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s20 [phi:main::@207->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // [259] phi from main::@207 to main::@208 [phi:main::@207->main::@208]
    // main::@208
    // wait_moment(32)
    // [260] call wait_moment
    // [1270] phi from main::@208 to wait_moment [phi:main::@208->wait_moment]
    // [1270] phi wait_moment::w#13 = $20 [phi:main::@208->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [261] phi from main::@208 to main::@209 [phi:main::@208->main::@209]
    // main::@209
    // system_reset()
    // [262] call system_reset
    // [1278] phi from main::@209 to system_reset [phi:main::@209->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [263] return 
    rts
    // main::check_status_smc13
  check_status_smc13:
    // status_smc == status
    // [264] main::check_status_smc13_$0 = status_smc#0 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc13_main__0
    // return (unsigned char)(status_smc == status);
    // [265] main::check_status_smc13_return#0 = (char)main::check_status_smc13_$0 -- vbum1=vbum2 
    sta check_status_smc13_return
    // main::check_status_smc14
    // status_smc == status
    // [266] main::check_status_smc14_$0 = status_smc#0 == STATUS_NONE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc14_main__0
    // return (unsigned char)(status_smc == status);
    // [267] main::check_status_smc14_return#0 = (char)main::check_status_smc14_$0 -- vbum1=vbum2 
    sta check_status_smc14_return
    // main::check_status_vera6
    // status_vera == status
    // [268] main::check_status_vera6_$0 = status_vera#115 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera6_main__0
    // return (unsigned char)(status_vera == status);
    // [269] main::check_status_vera6_return#0 = (char)main::check_status_vera6_$0 -- vbum1=vbum2 
    sta check_status_vera6_return
    // main::check_status_vera7
    // status_vera == status
    // [270] main::check_status_vera7_$0 = status_vera#115 == STATUS_NONE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera7_main__0
    // return (unsigned char)(status_vera == status);
    // [271] main::check_status_vera7_return#0 = (char)main::check_status_vera7_$0 -- vbum1=vbum2 
    sta check_status_vera7_return
    // [272] phi from main::check_status_vera7 to main::@84 [phi:main::check_status_vera7->main::@84]
    // main::@84
    // check_status_roms_less(STATUS_SKIP)
    // [273] call check_status_roms_less
    // [1283] phi from main::@84 to check_status_roms_less [phi:main::@84->check_status_roms_less]
    jsr check_status_roms_less
    // check_status_roms_less(STATUS_SKIP)
    // [274] check_status_roms_less::return#3 = check_status_roms_less::return#2
    // main::@199
    // [275] main::$84 = check_status_roms_less::return#3 -- vbum1=vbum2 
    lda check_status_roms_less.return
    sta main__84
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        check_status_roms_less(STATUS_SKIP))
    // [276] if(0!=main::check_status_smc13_return#0) goto main::@253 -- 0_neq_vbum1_then_la1 
    lda check_status_smc13_return
    beq !__b253+
    jmp __b253
  !__b253:
    // main::@254
    // [277] if(0!=main::check_status_smc14_return#0) goto main::@253 -- 0_neq_vbum1_then_la1 
    lda check_status_smc14_return
    beq !__b253+
    jmp __b253
  !__b253:
    // main::check_status_smc15
  check_status_smc15:
    // status_smc == status
    // [278] main::check_status_smc15_$0 = status_smc#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc15_main__0
    // return (unsigned char)(status_smc == status);
    // [279] main::check_status_smc15_return#0 = (char)main::check_status_smc15_$0 -- vbum1=vbum2 
    sta check_status_smc15_return
    // main::check_status_vera8
    // status_vera == status
    // [280] main::check_status_vera8_$0 = status_vera#115 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera8_main__0
    // return (unsigned char)(status_vera == status);
    // [281] main::check_status_vera8_return#0 = (char)main::check_status_vera8_$0 -- vbum1=vbum2 
    sta check_status_vera8_return
    // [282] phi from main::check_status_vera8 to main::@87 [phi:main::check_status_vera8->main::@87]
    // main::@87
    // check_status_roms(STATUS_ERROR)
    // [283] call check_status_roms
    // [1238] phi from main::@87 to check_status_roms [phi:main::@87->check_status_roms]
    // [1238] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@87->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [284] check_status_roms::return#10 = check_status_roms::return#2
    // main::@210
    // [285] main::$275 = check_status_roms::return#10 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__275
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [286] if(0!=main::check_status_smc15_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc15_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@256
    // [287] if(0!=main::check_status_vera8_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera8_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@255
    // [288] if(0!=main::$275) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda main__275
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::check_status_smc16
    // status_smc == status
    // [289] main::check_status_smc16_$0 = status_smc#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc16_main__0
    // return (unsigned char)(status_smc == status);
    // [290] main::check_status_smc16_return#0 = (char)main::check_status_smc16_$0 -- vbum1=vbum2 
    sta check_status_smc16_return
    // main::check_status_vera9
    // status_vera == status
    // [291] main::check_status_vera9_$0 = status_vera#115 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera9_main__0
    // return (unsigned char)(status_vera == status);
    // [292] main::check_status_vera9_return#0 = (char)main::check_status_vera9_$0 -- vbum1=vbum2 
    sta check_status_vera9_return
    // [293] phi from main::check_status_vera9 to main::@89 [phi:main::check_status_vera9->main::@89]
    // main::@89
    // check_status_roms(STATUS_ISSUE)
    // [294] call check_status_roms
    // [1238] phi from main::@89 to check_status_roms [phi:main::@89->check_status_roms]
    // [1238] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@89->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [295] check_status_roms::return#11 = check_status_roms::return#2
    // main::@212
    // [296] main::$280 = check_status_roms::return#11 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__280
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [297] if(0!=main::check_status_smc16_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_smc16_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@258
    // [298] if(0!=main::check_status_vera9_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_vera9_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@257
    // [299] if(0!=main::$280) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda main__280
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::vera_display_set_border_color5
    // *VERA_CTRL &= ~VERA_DCSEL
    // [300] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [301] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [302] phi from main::vera_display_set_border_color5 to main::@91 [phi:main::vera_display_set_border_color5->main::@91]
    // main::@91
    // display_action_progress("Your CX16 update is a success!")
    // [303] call display_action_progress
    // [874] phi from main::@91 to display_action_progress [phi:main::@91->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text37 [phi:main::@91->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text37
    sta.z display_action_progress.info_text
    lda #>info_text37
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc17
    // status_smc == status
    // [304] main::check_status_smc17_$0 = status_smc#0 == STATUS_FLASHED -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc17_main__0
    // return (unsigned char)(status_smc == status);
    // [305] main::check_status_smc17_return#0 = (char)main::check_status_smc17_$0 -- vbum1=vbum2 
    sta check_status_smc17_return
    // main::@92
    // if(check_status_smc(STATUS_FLASHED))
    // [306] if(0!=main::check_status_smc17_return#0) goto main::@56 -- 0_neq_vbum1_then_la1 
    beq !__b56+
    jmp __b56
  !__b56:
    // [307] phi from main::@92 to main::@10 [phi:main::@92->main::@10]
    // main::@10
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [308] call display_progress_text
    // [1292] phi from main::@10 to display_progress_text [phi:main::@10->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_debriefing_text_rom [phi:main::@10->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_debriefing_count_rom [phi:main::@10->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_rom
    sta display_progress_text.lines
    jsr display_progress_text
    // [309] phi from main::@10 main::@86 main::@90 to main::@3 [phi:main::@10/main::@86/main::@90->main::@3]
    // main::@3
  __b3:
    // textcolor(PINK)
    // [310] call textcolor
  // DE6 | Wait until reset
    // [754] phi from main::@3 to textcolor [phi:main::@3->textcolor]
    // [754] phi textcolor::color#23 = PINK [phi:main::@3->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [311] phi from main::@3 to main::@225 [phi:main::@3->main::@225]
    // main::@225
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [312] call display_progress_line
    // [1302] phi from main::@225 to display_progress_line [phi:main::@225->display_progress_line]
    // [1302] phi display_progress_line::text#3 = main::text [phi:main::@225->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1302] phi display_progress_line::line#3 = 2 [phi:main::@225->display_progress_line#1] -- vbum1=vbuc1 
    lda #2
    sta display_progress_line.line
    jsr display_progress_line
    // [313] phi from main::@225 to main::@226 [phi:main::@225->main::@226]
    // main::@226
    // textcolor(WHITE)
    // [314] call textcolor
    // [754] phi from main::@226 to textcolor [phi:main::@226->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:main::@226->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [315] phi from main::@226 to main::@58 [phi:main::@226->main::@58]
    // [315] phi main::w1#2 = $78 [phi:main::@226->main::@58#0] -- vbuz1=vbuc1 
    lda #$78
    sta.z w1
    // main::@58
  __b58:
    // for (unsigned char w=120; w>0; w--)
    // [316] if(main::w1#2>0) goto main::@59 -- vbuz1_gt_0_then_la1 
    lda.z w1
    bne __b59
    // [317] phi from main::@58 to main::@60 [phi:main::@58->main::@60]
    // main::@60
    // system_reset()
    // [318] call system_reset
    // [1278] phi from main::@60 to system_reset [phi:main::@60->system_reset]
    jsr system_reset
    rts
    // [319] phi from main::@58 to main::@59 [phi:main::@58->main::@59]
    // main::@59
  __b59:
    // wait_moment(1)
    // [320] call wait_moment
    // [1270] phi from main::@59 to wait_moment [phi:main::@59->wait_moment]
    // [1270] phi wait_moment::w#13 = 1 [phi:main::@59->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [321] phi from main::@59 to main::@227 [phi:main::@59->main::@227]
    // main::@227
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [322] call snprintf_init
    // [1167] phi from main::@227 to snprintf_init [phi:main::@227->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@227->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [323] phi from main::@227 to main::@228 [phi:main::@227->main::@228]
    // main::@228
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [324] call printf_str
    // [1172] phi from main::@228 to printf_str [phi:main::@228->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@228->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s24 [phi:main::@228->printf_str#1] -- pbuz1=pbuc1 
    lda #<s24
    sta.z printf_str.s
    lda #>s24
    sta.z printf_str.s+1
    jsr printf_str
    // main::@229
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [325] printf_uchar::uvalue#20 = main::w1#2 -- vbum1=vbuz2 
    lda.z w1
    sta printf_uchar.uvalue
    // [326] call printf_uchar
    // [1307] phi from main::@229 to printf_uchar [phi:main::@229->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:main::@229->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:main::@229->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:main::@229->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:main::@229->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#20 [phi:main::@229->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [327] phi from main::@229 to main::@230 [phi:main::@229->main::@230]
    // main::@230
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [328] call printf_str
    // [1172] phi from main::@230 to printf_str [phi:main::@230->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@230->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s25 [phi:main::@230->printf_str#1] -- pbuz1=pbuc1 
    lda #<s25
    sta.z printf_str.s
    lda #>s25
    sta.z printf_str.s+1
    jsr printf_str
    // main::@231
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [329] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [330] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [332] call display_action_text
    // [1318] phi from main::@231 to display_action_text [phi:main::@231->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:main::@231->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@232
    // for (unsigned char w=120; w>0; w--)
    // [333] main::w1#1 = -- main::w1#2 -- vbuz1=_dec_vbuz1 
    dec.z w1
    // [315] phi from main::@232 to main::@58 [phi:main::@232->main::@58]
    // [315] phi main::w1#2 = main::w1#1 [phi:main::@232->main::@58#0] -- register_copy 
    jmp __b58
    // [334] phi from main::@92 to main::@56 [phi:main::@92->main::@56]
    // main::@56
  __b56:
    // smc_reset()
    // [335] call smc_reset
    // [1332] phi from main::@56 to smc_reset [phi:main::@56->smc_reset]
    jsr smc_reset
    // [336] phi from main::@56 to main::@51 [phi:main::@56->main::@51]
    // main::@51
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [337] call display_progress_text
    // [1292] phi from main::@51 to display_progress_text [phi:main::@51->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_debriefing_text_smc [phi:main::@51->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_debriefing_count_smc [phi:main::@51->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_smc
    sta display_progress_text.lines
    jsr display_progress_text
    // [338] phi from main::@51 to main::@213 [phi:main::@51->main::@213]
    // main::@213
    // textcolor(PINK)
    // [339] call textcolor
    // [754] phi from main::@213 to textcolor [phi:main::@213->textcolor]
    // [754] phi textcolor::color#23 = PINK [phi:main::@213->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [340] phi from main::@213 to main::@214 [phi:main::@213->main::@214]
    // main::@214
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [341] call display_progress_line
    // [1302] phi from main::@214 to display_progress_line [phi:main::@214->display_progress_line]
    // [1302] phi display_progress_line::text#3 = main::text [phi:main::@214->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1302] phi display_progress_line::line#3 = 2 [phi:main::@214->display_progress_line#1] -- vbum1=vbuc1 
    lda #2
    sta display_progress_line.line
    jsr display_progress_line
    // [342] phi from main::@214 to main::@215 [phi:main::@214->main::@215]
    // main::@215
    // textcolor(WHITE)
    // [343] call textcolor
    // [754] phi from main::@215 to textcolor [phi:main::@215->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:main::@215->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [344] phi from main::@215 to main::@52 [phi:main::@215->main::@52]
    // [344] phi main::w#2 = $78 [phi:main::@215->main::@52#0] -- vbuz1=vbuc1 
    lda #$78
    sta.z w
    // main::@52
  __b52:
    // for (unsigned char w=120; w>0; w--)
    // [345] if(main::w#2>0) goto main::@53 -- vbuz1_gt_0_then_la1 
    lda.z w
    bne __b53
    // [346] phi from main::@52 to main::@54 [phi:main::@52->main::@54]
    // main::@54
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [347] call snprintf_init
    // [1167] phi from main::@54 to snprintf_init [phi:main::@54->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@54->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [348] phi from main::@54 to main::@222 [phi:main::@54->main::@222]
    // main::@222
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [349] call printf_str
    // [1172] phi from main::@222 to printf_str [phi:main::@222->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@222->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s23 [phi:main::@222->printf_str#1] -- pbuz1=pbuc1 
    lda #<s23
    sta.z printf_str.s
    lda #>s23
    sta.z printf_str.s+1
    jsr printf_str
    // main::@223
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [350] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [351] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [353] call display_action_text
    // [1318] phi from main::@223 to display_action_text [phi:main::@223->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:main::@223->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [354] phi from main::@223 to main::@224 [phi:main::@223->main::@224]
    // main::@224
    // smc_reset()
    // [355] call smc_reset
  // DE5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [1332] phi from main::@224 to smc_reset [phi:main::@224->smc_reset]
    jsr smc_reset
    // [356] phi from main::@224 main::@55 to main::@55 [phi:main::@224/main::@55->main::@55]
  __b6:
  // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
    // main::@55
    jmp __b6
    // [357] phi from main::@52 to main::@53 [phi:main::@52->main::@53]
    // main::@53
  __b53:
    // wait_moment(1)
    // [358] call wait_moment
    // [1270] phi from main::@53 to wait_moment [phi:main::@53->wait_moment]
    // [1270] phi wait_moment::w#13 = 1 [phi:main::@53->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [359] phi from main::@53 to main::@216 [phi:main::@53->main::@216]
    // main::@216
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [360] call snprintf_init
    // [1167] phi from main::@216 to snprintf_init [phi:main::@216->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@216->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [361] phi from main::@216 to main::@217 [phi:main::@216->main::@217]
    // main::@217
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [362] call printf_str
    // [1172] phi from main::@217 to printf_str [phi:main::@217->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@217->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s21 [phi:main::@217->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@218
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [363] printf_uchar::uvalue#19 = main::w#2 -- vbum1=vbuz2 
    lda.z w
    sta printf_uchar.uvalue
    // [364] call printf_uchar
    // [1307] phi from main::@218 to printf_uchar [phi:main::@218->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:main::@218->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 3 [phi:main::@218->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:main::@218->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:main::@218->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#19 [phi:main::@218->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [365] phi from main::@218 to main::@219 [phi:main::@218->main::@219]
    // main::@219
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [366] call printf_str
    // [1172] phi from main::@219 to printf_str [phi:main::@219->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@219->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s22 [phi:main::@219->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@220
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [367] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [368] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [370] call display_action_text
    // [1318] phi from main::@220 to display_action_text [phi:main::@220->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:main::@220->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@221
    // for (unsigned char w=120; w>0; w--)
    // [371] main::w#1 = -- main::w#2 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [344] phi from main::@221 to main::@52 [phi:main::@221->main::@52]
    // [344] phi main::w#2 = main::w#1 [phi:main::@221->main::@52#0] -- register_copy 
    jmp __b52
    // main::vera_display_set_border_color4
  vera_display_set_border_color4:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [372] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [373] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [374] phi from main::vera_display_set_border_color4 to main::@90 [phi:main::vera_display_set_border_color4->main::@90]
    // main::@90
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [375] call display_action_progress
    // [874] phi from main::@90 to display_action_progress [phi:main::@90->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text36 [phi:main::@90->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text36
    sta.z display_action_progress.info_text
    lda #>info_text36
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b3
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [376] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [377] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [378] phi from main::vera_display_set_border_color3 to main::@88 [phi:main::vera_display_set_border_color3->main::@88]
    // main::@88
    // display_action_progress("Update Failure! Your CX16 may no longer boot!")
    // [379] call display_action_progress
    // [874] phi from main::@88 to display_action_progress [phi:main::@88->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text34 [phi:main::@88->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text34
    sta.z display_action_progress.info_text
    lda #>info_text34
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [380] phi from main::@88 to main::@211 [phi:main::@88->main::@211]
    // main::@211
    // display_action_text("Take a photo of this screen, shut down power and retry!")
    // [381] call display_action_text
    // [1318] phi from main::@211 to display_action_text [phi:main::@211->display_action_text]
    // [1318] phi display_action_text::info_text#23 = main::info_text35 [phi:main::@211->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text35
    sta.z display_action_text.info_text
    lda #>info_text35
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [382] phi from main::@211 main::@57 to main::@57 [phi:main::@211/main::@57->main::@57]
    // main::@57
  __b57:
    jmp __b57
    // main::@253
  __b253:
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        check_status_roms_less(STATUS_SKIP))
    // [383] if(0!=main::check_status_vera6_return#0) goto main::@252 -- 0_neq_vbum1_then_la1 
    lda check_status_vera6_return
    bne __b252
    // main::@260
    // [384] if(0==main::check_status_vera7_return#0) goto main::check_status_smc15 -- 0_eq_vbum1_then_la1 
    lda check_status_vera7_return
    bne !check_status_smc15+
    jmp check_status_smc15
  !check_status_smc15:
    // main::@252
  __b252:
    // [385] if(0!=main::$84) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda main__84
    bne vera_display_set_border_color2
    jmp check_status_smc15
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [386] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [387] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [388] phi from main::vera_display_set_border_color2 to main::@86 [phi:main::vera_display_set_border_color2->main::@86]
    // main::@86
    // display_action_progress("No CX16 component has been updated with new firmware!")
    // [389] call display_action_progress
    // [874] phi from main::@86 to display_action_progress [phi:main::@86->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text33 [phi:main::@86->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text33
    sta.z display_action_progress.info_text
    lda #>info_text33
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b3
    // main::@244
  __b244:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [390] if(0!=main::$62) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda main__62
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@243
    // [391] if(0==main::check_status_smc8_return#0) goto main::@242 -- 0_eq_vbum1_then_la1 
    lda check_status_smc8_return
    beq __b242
    jmp check_status_vera3
    // main::@242
  __b242:
    // [392] if(0!=main::check_status_vera2_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera2_return
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@241
    // [393] if(0==main::$71) goto main::check_status_vera4 -- 0_eq_vbum1_then_la1 
    lda main__71
    beq check_status_vera4
    jmp check_status_vera3
    // main::check_status_vera4
  check_status_vera4:
    // status_vera == status
    // [394] main::check_status_vera4_$0 = status_vera#115 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera4_main__0
    // return (unsigned char)(status_vera == status);
    // [395] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0 -- vbum1=vbum2 
    sta check_status_vera4_return
    // main::check_status_smc9
    // status_smc == status
    // [396] main::check_status_smc9_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [397] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0 -- vbum1=vbum2 
    sta check_status_smc9_return
    // [398] phi from main::check_status_smc9 to main::check_status_cx16_rom5 [phi:main::check_status_smc9->main::check_status_cx16_rom5]
    // main::check_status_cx16_rom5
    // main::check_status_cx16_rom5_check_status_rom1
    // status_rom[rom_chip] == status
    // [399] main::check_status_cx16_rom5_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom5_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [400] main::check_status_cx16_rom5_check_status_rom1_return#0 = (char)main::check_status_cx16_rom5_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom5_check_status_rom1_return
    // [401] phi from main::check_status_cx16_rom5_check_status_rom1 to main::@77 [phi:main::check_status_cx16_rom5_check_status_rom1->main::@77]
    // main::@77
    // check_status_card_roms(STATUS_FLASH)
    // [402] call check_status_card_roms
    // [1341] phi from main::@77 to check_status_card_roms [phi:main::@77->check_status_card_roms]
    jsr check_status_card_roms
    // check_status_card_roms(STATUS_FLASH)
    // [403] check_status_card_roms::return#3 = check_status_card_roms::return#2
    // main::@166
    // [404] main::$187 = check_status_card_roms::return#3 -- vbum1=vbum2 
    lda check_status_card_roms.return
    sta main__187
    // if(check_status_vera(STATUS_FLASH) || check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [405] if(0!=main::check_status_vera4_return#0) goto main::@8 -- 0_neq_vbum1_then_la1 
    lda check_status_vera4_return
    beq !__b8+
    jmp __b8
  !__b8:
    // main::@248
    // [406] if(0!=main::check_status_smc9_return#0) goto main::@8 -- 0_neq_vbum1_then_la1 
    lda check_status_smc9_return
    beq !__b8+
    jmp __b8
  !__b8:
    // main::@247
    // [407] if(0!=main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::@8 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom5_check_status_rom1_return
    beq !__b8+
    jmp __b8
  !__b8:
    // main::@246
    // [408] if(0!=main::$187) goto main::@8 -- 0_neq_vbum1_then_la1 
    lda main__187
    beq !__b8+
    jmp __b8
  !__b8:
    // main::bank_set_bram1
  bank_set_bram1:
    // BRAM = bank
    // [409] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::SEI4
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom7
    // BROM = bank
    // [411] BROM = main::bank_set_brom7_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom7_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // main::check_status_vera5
    // status_vera == status
    // [413] main::check_status_vera5_$0 = status_vera#115 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera5_main__0
    // return (unsigned char)(status_vera == status);
    // [414] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0 -- vbum1=vbum2 
    sta check_status_vera5_return
    // main::@78
    // if(check_status_vera(STATUS_FLASH))
    // [415] if(0==main::check_status_vera5_return#0) goto main::SEI5 -- 0_eq_vbum1_then_la1 
    beq SEI5
    // [416] phi from main::@78 to main::@46 [phi:main::@78->main::@46]
    // main::@46
    // display_progress_text(display_jp1_spi_vera_text, display_jp1_spi_vera_count)
    // [417] call display_progress_text
    // [1292] phi from main::@46 to display_progress_text [phi:main::@46->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_jp1_spi_vera_text [phi:main::@46->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_jp1_spi_vera_text
    sta.z display_progress_text.text
    lda #>display_jp1_spi_vera_text
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_jp1_spi_vera_count [phi:main::@46->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_jp1_spi_vera_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [418] phi from main::@46 to main::@172 [phi:main::@46->main::@172]
    // main::@172
    // util_wait_space()
    // [419] call util_wait_space
    // [1350] phi from main::@172 to util_wait_space [phi:main::@172->util_wait_space]
    jsr util_wait_space
    // [420] phi from main::@172 to main::@173 [phi:main::@172->main::@173]
    // main::@173
    // main_vera_flash()
    // [421] call main_vera_flash
    // [1353] phi from main::@173 to main_vera_flash [phi:main::@173->main_vera_flash]
    jsr main_vera_flash
    // [422] phi from main::@173 main::@78 to main::SEI5 [phi:main::@173/main::@78->main::SEI5]
    // [422] phi __stdio_filecount#113 = __stdio_filecount#36 [phi:main::@173/main::@78->main::SEI5#0] -- register_copy 
    // [422] phi __errno#116 = __errno#122 [phi:main::@173/main::@78->main::SEI5#1] -- register_copy 
    // main::SEI5
  SEI5:
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom8
    // BROM = bank
    // [424] BROM = main::bank_set_brom8_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom8_bank
    sta.z BROM
    // [425] phi from main::bank_set_brom8 to main::@79 [phi:main::bank_set_brom8->main::@79]
    // main::@79
    // display_progress_clear()
    // [426] call display_progress_clear
    // [888] phi from main::@79 to display_progress_clear [phi:main::@79->display_progress_clear]
    jsr display_progress_clear
    // main::check_status_smc10
    // status_smc == status
    // [427] main::check_status_smc10_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [428] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0 -- vbum1=vbum2 
    sta check_status_smc10_return
    // [429] phi from main::check_status_smc10 to main::check_status_cx16_rom6 [phi:main::check_status_smc10->main::check_status_cx16_rom6]
    // main::check_status_cx16_rom6
    // main::check_status_cx16_rom6_check_status_rom1
    // status_rom[rom_chip] == status
    // [430] main::check_status_cx16_rom6_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom6_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [431] main::check_status_cx16_rom6_check_status_rom1_return#0 = (char)main::check_status_cx16_rom6_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom6_check_status_rom1_return
    // main::@80
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [432] if(0==main::check_status_smc10_return#0) goto main::SEI6 -- 0_eq_vbum1_then_la1 
    lda check_status_smc10_return
    beq SEI6
    // main::@249
    // [433] if(0!=main::check_status_cx16_rom6_check_status_rom1_return#0) goto main::@47 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom6_check_status_rom1_return
    beq !__b47+
    jmp __b47
  !__b47:
    // [434] phi from main::@249 to main::SEI6 [phi:main::@249->main::SEI6]
    // [434] phi from main::@176 main::@35 main::@36 main::@50 main::@80 to main::SEI6 [phi:main::@176/main::@35/main::@36/main::@50/main::@80->main::SEI6]
    // [434] phi __stdio_filecount#553 = __stdio_filecount#39 [phi:main::@176/main::@35/main::@36/main::@50/main::@80->main::SEI6#0] -- register_copy 
    // [434] phi __errno#560 = __errno#122 [phi:main::@176/main::@35/main::@36/main::@50/main::@80->main::SEI6#1] -- register_copy 
    // main::SEI6
  SEI6:
    // asm
    // asm { sei  }
    sei
    // [436] phi from main::SEI6 to main::@37 [phi:main::SEI6->main::@37]
    // [436] phi __stdio_filecount#114 = __stdio_filecount#553 [phi:main::SEI6->main::@37#0] -- register_copy 
    // [436] phi __errno#117 = __errno#560 [phi:main::SEI6->main::@37#1] -- register_copy 
    // [436] phi main::rom_chip4#10 = 7 [phi:main::SEI6->main::@37#2] -- vbuz1=vbuc1 
    lda #7
    sta.z rom_chip4
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@37
  __b37:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [437] if(main::rom_chip4#10!=$ff) goto main::check_status_rom1 -- vbuz1_neq_vbuc1_then_la1 
    lda #$ff
    cmp.z rom_chip4
    bne check_status_rom1
    // [438] phi from main::@37 to main::@38 [phi:main::@37->main::@38]
    // main::@38
    // display_progress_clear()
    // [439] call display_progress_clear
    // [888] phi from main::@38 to display_progress_clear [phi:main::@38->display_progress_clear]
    jsr display_progress_clear
    jmp check_status_vera3
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [440] main::check_status_rom1_$0 = status_rom[main::rom_chip4#10] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy.z rom_chip4
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [441] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // main::@81
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [442] if(0==main::check_status_rom1_return#0) goto main::@39 -- 0_eq_vbum1_then_la1 
    beq __b39
    // main::check_status_smc11
    // status_smc == status
    // [443] main::check_status_smc11_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc11_main__0
    // return (unsigned char)(status_smc == status);
    // [444] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0 -- vbum1=vbuz2 
    sta check_status_smc11_return
    // main::check_status_smc12
    // status_smc == status
    // [445] main::check_status_smc12_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc12_main__0
    // return (unsigned char)(status_smc == status);
    // [446] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0 -- vbum1=vbuz2 
    sta check_status_smc12_return
    // main::@82
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [447] if(main::rom_chip4#10==0) goto main::@251 -- vbuz1_eq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda.z rom_chip4
    bne !__b251+
    jmp __b251
  !__b251:
    // main::@250
  __b250:
    // [448] if(main::rom_chip4#10!=0) goto main::bank_set_brom9 -- vbuz1_neq_0_then_la1 
    lda.z rom_chip4
    bne bank_set_brom9
    // main::@45
    // display_info_rom(rom_chip, STATUS_ISSUE, "SMC Update failed!")
    // [449] display_info_rom::rom_chip#11 = main::rom_chip4#10 -- vbum1=vbuz2 
    sta display_info_rom.rom_chip
    // [450] call display_info_rom
    // [1440] phi from main::@45 to display_info_rom [phi:main::@45->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = main::info_text29 [phi:main::@45->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_info_rom.info_text
    lda #>info_text29
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#11 [phi:main::@45->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:main::@45->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    // [451] phi from main::@187 main::@198 main::@40 main::@44 main::@45 main::@81 to main::@39 [phi:main::@187/main::@198/main::@40/main::@44/main::@45/main::@81->main::@39]
    // [451] phi __stdio_filecount#554 = __stdio_filecount#12 [phi:main::@187/main::@198/main::@40/main::@44/main::@45/main::@81->main::@39#0] -- register_copy 
    // [451] phi __errno#561 = __errno#122 [phi:main::@187/main::@198/main::@40/main::@44/main::@45/main::@81->main::@39#1] -- register_copy 
    // main::@39
  __b39:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [452] main::rom_chip4#1 = -- main::rom_chip4#10 -- vbuz1=_dec_vbuz1 
    dec.z rom_chip4
    // [436] phi from main::@39 to main::@37 [phi:main::@39->main::@37]
    // [436] phi __stdio_filecount#114 = __stdio_filecount#554 [phi:main::@39->main::@37#0] -- register_copy 
    // [436] phi __errno#117 = __errno#561 [phi:main::@39->main::@37#1] -- register_copy 
    // [436] phi main::rom_chip4#10 = main::rom_chip4#1 [phi:main::@39->main::@37#2] -- register_copy 
    jmp __b37
    // main::bank_set_brom9
  bank_set_brom9:
    // BROM = bank
    // [453] BROM = main::bank_set_brom9_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom9_bank
    sta.z BROM
    // [454] phi from main::bank_set_brom9 to main::@83 [phi:main::bank_set_brom9->main::@83]
    // main::@83
    // display_progress_clear()
    // [455] call display_progress_clear
    // [888] phi from main::@83 to display_progress_clear [phi:main::@83->display_progress_clear]
    jsr display_progress_clear
    // main::@180
    // unsigned char rom_bank = rom_chip * 32
    // [456] main::rom_bank1#0 = main::rom_chip4#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z rom_chip4
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [457] rom_file::rom_chip#1 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_file.rom_chip
    // [458] call rom_file
    // [1485] phi from main::@180 to rom_file [phi:main::@180->rom_file]
    // [1485] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@180->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [459] rom_file::return#5 = rom_file::return#2
    // main::@181
    // [460] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [461] call snprintf_init
    // [1167] phi from main::@181 to snprintf_init [phi:main::@181->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@181->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [462] phi from main::@181 to main::@182 [phi:main::@181->main::@182]
    // main::@182
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [463] call printf_str
    // [1172] phi from main::@182 to printf_str [phi:main::@182->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@182->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s11 [phi:main::@182->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@183
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [464] printf_string::str#25 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z printf_string.str
    lda.z file1+1
    sta.z printf_string.str+1
    // [465] call printf_string
    // [1181] phi from main::@183 to printf_string [phi:main::@183->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:main::@183->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#25 [phi:main::@183->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:main::@183->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:main::@183->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [466] phi from main::@183 to main::@184 [phi:main::@183->main::@184]
    // main::@184
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [467] call printf_str
    // [1172] phi from main::@184 to printf_str [phi:main::@184->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@184->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s12 [phi:main::@184->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@185
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [468] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [469] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [471] call display_action_progress
    // [874] phi from main::@185 to display_action_progress [phi:main::@185->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = info_text [phi:main::@185->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@186
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [472] main::$318 = main::rom_chip4#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip4
    asl
    asl
    sta main__318
    // [473] rom_read::file#1 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z rom_read.file
    lda.z file1+1
    sta.z rom_read.file+1
    // [474] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_read.brom_bank_start
    // [475] rom_read::rom_size#1 = rom_sizes[main::$318] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__318
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [476] call rom_read
    // [1491] phi from main::@186 to rom_read [phi:main::@186->rom_read]
    // [1491] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@186->rom_read#0] -- register_copy 
    // [1491] phi __errno#105 = __errno#117 [phi:main::@186->rom_read#1] -- register_copy 
    // [1491] phi __stdio_filecount#100 = __stdio_filecount#114 [phi:main::@186->rom_read#2] -- register_copy 
    // [1491] phi rom_read::file#10 = rom_read::file#1 [phi:main::@186->rom_read#3] -- register_copy 
    // [1491] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#2 [phi:main::@186->rom_read#4] -- register_copy 
    // [1491] phi rom_read::info_status#12 = STATUS_READING [phi:main::@186->rom_read#5] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [477] rom_read::return#3 = rom_read::return#0
    // main::@187
    // [478] main::rom_bytes_read1#0 = rom_read::return#3 -- vduz1=vdum2 
    lda rom_read.return
    sta.z rom_bytes_read1
    lda rom_read.return+1
    sta.z rom_bytes_read1+1
    lda rom_read.return+2
    sta.z rom_bytes_read1+2
    lda rom_read.return+3
    sta.z rom_bytes_read1+3
    // if(rom_bytes_read)
    // [479] if(0==main::rom_bytes_read1#0) goto main::@39 -- 0_eq_vduz1_then_la1 
    lda.z rom_bytes_read1
    ora.z rom_bytes_read1+1
    ora.z rom_bytes_read1+2
    ora.z rom_bytes_read1+3
    bne !__b39+
    jmp __b39
  !__b39:
    // [480] phi from main::@187 to main::@42 [phi:main::@187->main::@42]
    // main::@42
    // display_action_progress("Comparing ... (.) data, (=) same, (*) different.")
    // [481] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [874] phi from main::@42 to display_action_progress [phi:main::@42->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text30 [phi:main::@42->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z display_action_progress.info_text
    lda #>info_text30
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@188
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [482] display_info_rom::rom_chip#12 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [483] call display_info_rom
    // [1440] phi from main::@188 to display_info_rom [phi:main::@188->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text26 [phi:main::@188->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_rom.info_text
    lda #>info_text26
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#12 [phi:main::@188->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:main::@188->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@189
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [484] rom_verify::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_verify.rom_chip
    // [485] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_verify.rom_bank_start
    // [486] rom_verify::file_size#0 = file_sizes[main::$318] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__318
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [487] call rom_verify
  // Verify the ROM...
    // [1564] phi from main::@189 to rom_verify [phi:main::@189->rom_verify]
    jsr rom_verify
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [488] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@190
    // [489] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vdum2 
    lda rom_verify.return
    sta.z rom_differences
    lda rom_verify.return+1
    sta.z rom_differences+1
    lda rom_verify.return+2
    sta.z rom_differences+2
    lda rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [490] if(0==main::rom_differences#0) goto main::@40 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b40+
    jmp __b40
  !__b40:
    // [491] phi from main::@190 to main::@43 [phi:main::@190->main::@43]
    // main::@43
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [492] call snprintf_init
    // [1167] phi from main::@43 to snprintf_init [phi:main::@43->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@43->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@191
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [493] printf_ulong::uvalue#13 = main::rom_differences#0 -- vdum1=vduz2 
    lda.z rom_differences
    sta printf_ulong.uvalue
    lda.z rom_differences+1
    sta printf_ulong.uvalue+1
    lda.z rom_differences+2
    sta printf_ulong.uvalue+2
    lda.z rom_differences+3
    sta printf_ulong.uvalue+3
    // [494] call printf_ulong
    // [1628] phi from main::@191 to printf_ulong [phi:main::@191->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:main::@191->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:main::@191->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main::@191->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#13 [phi:main::@191->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [495] phi from main::@191 to main::@192 [phi:main::@191->main::@192]
    // main::@192
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [496] call printf_str
    // [1172] phi from main::@192 to printf_str [phi:main::@192->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@192->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s13 [phi:main::@192->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@193
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [497] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [498] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [500] display_info_rom::rom_chip#14 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [501] call display_info_rom
    // [1440] phi from main::@193 to display_info_rom [phi:main::@193->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text [phi:main::@193->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#14 [phi:main::@193->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@193->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@194
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [502] rom_flash::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_flash.rom_chip
    // [503] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [504] rom_flash::file_size#0 = file_sizes[main::$318] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__318
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [505] call rom_flash
    // [1638] phi from main::@194 to rom_flash [phi:main::@194->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [506] rom_flash::return#2 = rom_flash::flash_errors#12
    // main::@195
    // [507] main::rom_flash_errors#0 = rom_flash::return#2 -- vduz1=vdum2 
    lda rom_flash.return
    sta.z rom_flash_errors
    lda rom_flash.return+1
    sta.z rom_flash_errors+1
    lda rom_flash.return+2
    sta.z rom_flash_errors+2
    lda rom_flash.return+3
    sta.z rom_flash_errors+3
    // if(rom_flash_errors)
    // [508] if(0!=main::rom_flash_errors#0) goto main::@41 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash_errors
    ora.z rom_flash_errors+1
    ora.z rom_flash_errors+2
    ora.z rom_flash_errors+3
    bne __b41
    // main::@44
    // display_info_rom(rom_chip, STATUS_FLASHED, NULL)
    // [509] display_info_rom::rom_chip#16 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [510] call display_info_rom
  // RFL3 | Flash ROM and all ok
    // [1440] phi from main::@44 to display_info_rom [phi:main::@44->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = 0 [phi:main::@44->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#16 [phi:main::@44->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_FLASHED [phi:main::@44->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b39
    // [511] phi from main::@195 to main::@41 [phi:main::@195->main::@41]
    // main::@41
  __b41:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [512] call snprintf_init
    // [1167] phi from main::@41 to snprintf_init [phi:main::@41->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@41->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@196
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [513] printf_ulong::uvalue#14 = main::rom_flash_errors#0 -- vdum1=vduz2 
    lda.z rom_flash_errors
    sta printf_ulong.uvalue
    lda.z rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda.z rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda.z rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [514] call printf_ulong
    // [1628] phi from main::@196 to printf_ulong [phi:main::@196->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 0 [phi:main::@196->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 0 [phi:main::@196->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = DECIMAL [phi:main::@196->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#14 [phi:main::@196->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [515] phi from main::@196 to main::@197 [phi:main::@196->main::@197]
    // main::@197
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [516] call printf_str
    // [1172] phi from main::@197 to printf_str [phi:main::@197->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@197->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s14 [phi:main::@197->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@198
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [517] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [518] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [520] display_info_rom::rom_chip#15 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [521] call display_info_rom
    // [1440] phi from main::@198 to display_info_rom [phi:main::@198->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text [phi:main::@198->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#15 [phi:main::@198->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:main::@198->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b39
    // main::@40
  __b40:
    // display_info_rom(rom_chip, STATUS_SKIP, "No update required")
    // [522] display_info_rom::rom_chip#13 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [523] call display_info_rom
  // RFL1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Flashed. | None
    // [1440] phi from main::@40 to display_info_rom [phi:main::@40->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text32 [phi:main::@40->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text32
    sta.z display_info_rom.info_text
    lda #>info_text32
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#13 [phi:main::@40->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@40->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b39
    // main::@251
  __b251:
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [524] if(0!=main::check_status_smc11_return#0) goto main::bank_set_brom9 -- 0_neq_vbum1_then_la1 
    lda check_status_smc11_return
    beq !bank_set_brom9+
    jmp bank_set_brom9
  !bank_set_brom9:
    // main::@259
    // [525] if(0!=main::check_status_smc12_return#0) goto main::bank_set_brom9 -- 0_neq_vbum1_then_la1 
    lda check_status_smc12_return
    beq !bank_set_brom9+
    jmp bank_set_brom9
  !bank_set_brom9:
    jmp __b250
    // [526] phi from main::@249 to main::@47 [phi:main::@249->main::@47]
    // main::@47
  __b47:
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [527] call display_action_progress
    // [874] phi from main::@47 to display_action_progress [phi:main::@47->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text23 [phi:main::@47->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_action_progress.info_text
    lda #>info_text23
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [528] phi from main::@47 to main::@174 [phi:main::@47->main::@174]
    // main::@174
    // display_progress_clear()
    // [529] call display_progress_clear
    // [888] phi from main::@174 to display_progress_clear [phi:main::@174->display_progress_clear]
    jsr display_progress_clear
    // [530] phi from main::@174 to main::@175 [phi:main::@174->main::@175]
    // main::@175
    // smc_read(STATUS_READING)
    // [531] call smc_read
    // [1117] phi from main::@175 to smc_read [phi:main::@175->smc_read]
    // [1117] phi __errno#102 = __errno#116 [phi:main::@175->smc_read#0] -- register_copy 
    // [1117] phi __stdio_filecount#128 = __stdio_filecount#113 [phi:main::@175->smc_read#1] -- register_copy 
    // [1117] phi smc_read::info_status#10 = STATUS_READING [phi:main::@175->smc_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_READING)
    // [532] smc_read::return#3 = smc_read::return#0
    // main::@176
    // smc_file_size = smc_read(STATUS_READING)
    // [533] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [534] if(0==smc_file_size#1) goto main::SEI6 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !SEI6+
    jmp SEI6
  !SEI6:
    // [535] phi from main::@176 to main::@48 [phi:main::@176->main::@48]
    // main::@48
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [536] call display_action_text
  // Flash the SMC chip.
    // [1318] phi from main::@48 to display_action_text [phi:main::@48->display_action_text]
    // [1318] phi display_action_text::info_text#23 = main::info_text24 [phi:main::@48->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_action_text.info_text
    lda #>info_text24
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [537] phi from main::@48 to main::@177 [phi:main::@48->main::@177]
    // main::@177
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [538] call display_info_smc
    // [932] phi from main::@177 to display_info_smc [phi:main::@177->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text25 [phi:main::@177->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z display_info_smc.info_text
    lda #>info_text25
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@177->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_FLASHING [phi:main::@177->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_smc.info_status
    jsr display_info_smc
    // main::@178
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [539] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta smc_flash.smc_bytes_total+1
    // [540] call smc_flash
    // [1735] phi from main::@178 to smc_flash [phi:main::@178->smc_flash]
    jsr smc_flash
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [541] smc_flash::return#5 = smc_flash::return#1
    // main::@179
    // [542] main::flashed_bytes#0 = smc_flash::return#5 -- vwuz1=vwum2 
    lda smc_flash.return
    sta.z flashed_bytes
    lda smc_flash.return+1
    sta.z flashed_bytes+1
    // if(flashed_bytes)
    // [543] if(0!=main::flashed_bytes#0) goto main::@35 -- 0_neq_vwuz1_then_la1 
    lda.z flashed_bytes
    ora.z flashed_bytes+1
    bne __b35
    // main::@49
    // if(flashed_bytes == (unsigned int)0xFFFF)
    // [544] if(main::flashed_bytes#0==$ffff) goto main::@36 -- vwuz1_eq_vwuc1_then_la1 
    lda.z flashed_bytes
    cmp #<$ffff
    bne !+
    lda.z flashed_bytes+1
    cmp #>$ffff
    beq __b36
  !:
    // [545] phi from main::@49 to main::@50 [phi:main::@49->main::@50]
    // main::@50
    // display_info_smc(STATUS_ISSUE, "POWER/RESET not pressed!")
    // [546] call display_info_smc
  // SFL2 | no action on POWER/RESET press request
    // [932] phi from main::@50 to display_info_smc [phi:main::@50->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text28 [phi:main::@50->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_info_smc.info_text
    lda #>info_text28
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@50->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@50->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // [547] phi from main::@49 to main::@36 [phi:main::@49->main::@36]
    // main::@36
  __b36:
    // display_info_smc(STATUS_ERROR, "SMC has errors!")
    // [548] call display_info_smc
  // SFL3 | errors during flash
    // [932] phi from main::@36 to display_info_smc [phi:main::@36->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text27 [phi:main::@36->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_info_smc.info_text
    lda #>info_text27
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@36->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main::@36->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // [549] phi from main::@179 to main::@35 [phi:main::@179->main::@35]
    // main::@35
  __b35:
    // display_info_smc(STATUS_FLASHED, "")
    // [550] call display_info_smc
  // SFL1 | and POWER/RESET pressed
    // [932] phi from main::@35 to display_info_smc [phi:main::@35->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = info_text26 [phi:main::@35->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_smc.info_text
    lda #>info_text26
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@35->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_FLASHED [phi:main::@35->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // [551] phi from main::@166 main::@246 main::@247 main::@248 to main::@8 [phi:main::@166/main::@246/main::@247/main::@248->main::@8]
    // main::@8
  __b8:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [552] call display_action_progress
    // [874] phi from main::@8 to display_action_progress [phi:main::@8->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text17 [phi:main::@8->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_action_progress.info_text
    lda #>info_text17
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [553] phi from main::@8 to main::@167 [phi:main::@8->main::@167]
    // main::@167
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [554] call util_wait_key
    // [1884] phi from main::@167 to util_wait_key [phi:main::@167->util_wait_key]
    // [1884] phi util_wait_key::filter#13 = main::filter1 [phi:main::@167->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z util_wait_key.filter
    lda #>filter1
    sta.z util_wait_key.filter+1
    // [1884] phi util_wait_key::info_text#3 = main::info_text18 [phi:main::@167->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z util_wait_key.info_text
    lda #>info_text18
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [555] util_wait_key::return#4 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return_1
    // main::@168
    // [556] main::ch1#0 = util_wait_key::return#4 -- vbum1=vbum2 
    sta ch1
    // strchr("nN", ch)
    // [557] strchr::c#1 = main::ch1#0 -- vbum1=vbum2 
    sta strchr.c
    // [558] call strchr
    // [1908] phi from main::@168 to strchr [phi:main::@168->strchr]
    // [1908] phi strchr::c#4 = strchr::c#1 [phi:main::@168->strchr#0] -- register_copy 
    // [1908] phi strchr::str#2 = (const void *)main::$345 [phi:main::@168->strchr#1] -- pvoz1=pvoc1 
    lda #<main__345
    sta.z strchr.str
    lda #>main__345
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [559] strchr::return#4 = strchr::return#2
    // main::@169
    // [560] main::$192 = strchr::return#4
    // if(strchr("nN", ch))
    // [561] if((void *)0==main::$192) goto main::bank_set_bram1 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__192
    cmp #<0
    bne !+
    lda.z main__192+1
    cmp #>0
    bne !bank_set_bram1+
    jmp bank_set_bram1
  !bank_set_bram1:
  !:
    // [562] phi from main::@169 to main::@9 [phi:main::@169->main::@9]
    // main::@9
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [563] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [932] phi from main::@9 to display_info_smc [phi:main::@9->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text19 [phi:main::@9->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@9->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@9->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [564] phi from main::@9 to main::@170 [phi:main::@9->main::@170]
    // main::@170
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [565] call display_info_vera
    // [968] phi from main::@170 to display_info_vera [phi:main::@170->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = main::info_text19 [phi:main::@170->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_vera.info_text
    lda #>info_text19
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main::@170->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main::@170->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main::@170->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main::@170->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [566] phi from main::@170 to main::@32 [phi:main::@170->main::@32]
    // [566] phi main::rom_chip3#2 = 0 [phi:main::@170->main::@32#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip3
    // main::@32
  __b32:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [567] if(main::rom_chip3#2<8) goto main::@33 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip3
    cmp #8
    bcc __b33
    // [568] phi from main::@32 to main::@34 [phi:main::@32->main::@34]
    // main::@34
    // display_action_text("You have selected not to cancel the update ... ")
    // [569] call display_action_text
    // [1318] phi from main::@34 to display_action_text [phi:main::@34->display_action_text]
    // [1318] phi display_action_text::info_text#23 = main::info_text22 [phi:main::@34->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_text.info_text
    lda #>info_text22
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_bram1
    // main::@33
  __b33:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [570] display_info_rom::rom_chip#10 = main::rom_chip3#2 -- vbum1=vbuz2 
    lda.z rom_chip3
    sta display_info_rom.rom_chip
    // [571] call display_info_rom
    // [1440] phi from main::@33 to display_info_rom [phi:main::@33->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = main::info_text19 [phi:main::@33->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_rom.info_text
    lda #>info_text19
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#10 [phi:main::@33->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@33->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@171
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [572] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip3
    // [566] phi from main::@171 to main::@32 [phi:main::@171->main::@32]
    // [566] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@171->main::@32#0] -- register_copy 
    jmp __b32
    // main::@239
  __b239:
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [573] if(smc_major#0!=smc_file_major#301) goto main::check_status_smc7 -- vbum1_neq_vbum2_then_la1 
    lda smc_major
    cmp smc_file_major
    beq !check_status_smc7+
    jmp check_status_smc7
  !check_status_smc7:
    // main::@238
    // [574] if(smc_minor#0==smc_file_minor#301) goto main::@7 -- vbum1_eq_vbum2_then_la1 
    lda smc_minor
    cmp smc_file_minor
    beq __b7
    jmp check_status_smc7
    // [575] phi from main::@238 to main::@7 [phi:main::@238->main::@7]
    // main::@7
  __b7:
    // display_action_progress("The SMC chip and SMC.BIN versions are equal, no flash required!")
    // [576] call display_action_progress
    // [874] phi from main::@7 to display_action_progress [phi:main::@7->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text15 [phi:main::@7->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_progress.info_text
    lda #>info_text15
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [577] phi from main::@7 to main::@164 [phi:main::@7->main::@164]
    // main::@164
    // util_wait_space()
    // [578] call util_wait_space
    // [1350] phi from main::@164 to util_wait_space [phi:main::@164->util_wait_space]
    jsr util_wait_space
    // [579] phi from main::@164 to main::@165 [phi:main::@164->main::@165]
    // main::@165
    // display_info_smc(STATUS_SKIP, "SMC.BIN and SMC equal.")
    // [580] call display_info_smc
    // [932] phi from main::@165 to display_info_smc [phi:main::@165->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text16 [phi:main::@165->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_info_smc.info_text
    lda #>info_text16
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@165->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@165->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_smc7
    // [581] phi from main::@236 to main::@5 [phi:main::@236->main::@5]
    // main::@5
  __b5:
    // display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!")
    // [582] call display_action_progress
    // [874] phi from main::@5 to display_action_progress [phi:main::@5->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text13 [phi:main::@5->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [583] phi from main::@5 to main::@158 [phi:main::@5->main::@158]
    // main::@158
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [584] call display_progress_text
    // [1292] phi from main::@158 to display_progress_text [phi:main::@158->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_smc_unsupported_rom_text [phi:main::@158->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_smc_unsupported_rom_count [phi:main::@158->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [585] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [586] call util_wait_key
    // [1884] phi from main::@159 to util_wait_key [phi:main::@159->util_wait_key]
    // [1884] phi util_wait_key::filter#13 = main::filter [phi:main::@159->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1884] phi util_wait_key::info_text#3 = main::info_text14 [phi:main::@159->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z util_wait_key.info_text
    lda #>info_text14
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [587] util_wait_key::return#3 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return
    // main::@160
    // [588] main::ch#0 = util_wait_key::return#3 -- vbum1=vbum2 
    sta ch
    // if(ch == 'N')
    // [589] if(main::ch#0!='N') goto main::check_status_smc6 -- vbum1_neq_vbuc1_then_la1 
    lda #'N'
    cmp ch
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // [590] phi from main::@160 to main::@6 [phi:main::@160->main::@6]
    // main::@6
    // display_info_smc(STATUS_ISSUE, NULL)
    // [591] call display_info_smc
  // Cancel flash
    // [932] phi from main::@6 to display_info_smc [phi:main::@6->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = 0 [phi:main::@6->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@6->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@6->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [592] phi from main::@6 to main::@161 [phi:main::@6->main::@161]
    // main::@161
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [593] call display_info_cx16_rom
    // [1917] phi from main::@161 to display_info_cx16_rom [phi:main::@161->display_info_cx16_rom]
    // [1917] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@161->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1917] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@161->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc6
    // [594] phi from main::@235 to main::@4 [phi:main::@235->main::@4]
    // main::@4
  __b4:
    // display_action_progress("CX16 ROM update issue!")
    // [595] call display_action_progress
    // [874] phi from main::@4 to display_action_progress [phi:main::@4->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text11 [phi:main::@4->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_action_progress.info_text
    lda #>info_text11
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [596] phi from main::@4 to main::@153 [phi:main::@4->main::@153]
    // main::@153
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [597] call display_progress_text
    // [1292] phi from main::@153 to display_progress_text [phi:main::@153->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@153->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@153->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [598] phi from main::@153 to main::@154 [phi:main::@153->main::@154]
    // main::@154
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [599] call display_info_smc
    // [932] phi from main::@154 to display_info_smc [phi:main::@154->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text9 [phi:main::@154->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@154->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@154->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [600] phi from main::@154 to main::@155 [phi:main::@154->main::@155]
    // main::@155
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [601] call display_info_cx16_rom
    // [1917] phi from main::@155 to display_info_cx16_rom [phi:main::@155->display_info_cx16_rom]
    // [1917] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@155->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1917] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@155->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [602] phi from main::@155 to main::@156 [phi:main::@155->main::@156]
    // main::@156
    // util_wait_space()
    // [603] call util_wait_space
    // [1350] phi from main::@156 to util_wait_space [phi:main::@156->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc5
    // [604] phi from main::@234 to main::@2 [phi:main::@234->main::@2]
    // main::@2
  __b2:
    // display_action_progress("CX16 ROM update issue, ROM not detected!")
    // [605] call display_action_progress
    // [874] phi from main::@2 to display_action_progress [phi:main::@2->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text8 [phi:main::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [606] phi from main::@2 to main::@149 [phi:main::@2->main::@149]
    // main::@149
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [607] call display_progress_text
    // [1292] phi from main::@149 to display_progress_text [phi:main::@149->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@149->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@149->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [608] phi from main::@149 to main::@150 [phi:main::@149->main::@150]
    // main::@150
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [609] call display_info_smc
    // [932] phi from main::@150 to display_info_smc [phi:main::@150->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text9 [phi:main::@150->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@150->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@150->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [610] phi from main::@150 to main::@151 [phi:main::@150->main::@151]
    // main::@151
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [611] call display_info_cx16_rom
    // [1917] phi from main::@151 to display_info_cx16_rom [phi:main::@151->display_info_cx16_rom]
    // [1917] phi display_info_cx16_rom::info_text#4 = main::info_text10 [phi:main::@151->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_cx16_rom.info_text
    lda #>info_text10
    sta.z display_info_cx16_rom.info_text+1
    // [1917] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@151->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [612] phi from main::@151 to main::@152 [phi:main::@151->main::@152]
    // main::@152
    // util_wait_space()
    // [613] call util_wait_space
    // [1350] phi from main::@152 to util_wait_space [phi:main::@152->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc5
    // [614] phi from main::@233 to main::@31 [phi:main::@233->main::@31]
    // main::@31
  __b31:
    // display_action_progress("SMC update issue!")
    // [615] call display_action_progress
    // [874] phi from main::@31 to display_action_progress [phi:main::@31->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main::info_text6 [phi:main::@31->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_action_progress.info_text
    lda #>info_text6
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [616] phi from main::@31 to main::@145 [phi:main::@31->main::@145]
    // main::@145
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [617] call display_progress_text
    // [1292] phi from main::@145 to display_progress_text [phi:main::@145->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@145->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@145->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [618] phi from main::@145 to main::@146 [phi:main::@145->main::@146]
    // main::@146
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [619] call display_info_cx16_rom
    // [1917] phi from main::@146 to display_info_cx16_rom [phi:main::@146->display_info_cx16_rom]
    // [1917] phi display_info_cx16_rom::info_text#4 = main::info_text7 [phi:main::@146->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_info_cx16_rom.info_text
    lda #>info_text7
    sta.z display_info_cx16_rom.info_text+1
    // [1917] phi display_info_cx16_rom::info_status#4 = STATUS_SKIP [phi:main::@146->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [620] phi from main::@146 to main::@147 [phi:main::@146->main::@147]
    // main::@147
    // display_info_smc(STATUS_ISSUE, NULL)
    // [621] call display_info_smc
    // [932] phi from main::@147 to display_info_smc [phi:main::@147->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = 0 [phi:main::@147->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@147->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@147->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [622] phi from main::@147 to main::@148 [phi:main::@147->main::@148]
    // main::@148
    // util_wait_space()
    // [623] call util_wait_space
    // [1350] phi from main::@148 to util_wait_space [phi:main::@148->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [624] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::@66
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [625] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@25 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b25+
    jmp __b25
  !__b25:
    // [626] phi from main::@66 to main::@28 [phi:main::@66->main::@28]
    // main::@28
    // display_progress_clear()
    // [627] call display_progress_clear
    // [888] phi from main::@28 to display_progress_clear [phi:main::@28->display_progress_clear]
    jsr display_progress_clear
    // main::@123
    // unsigned char rom_bank = rom_chip * 32
    // [628] main::rom_bank#0 = main::rom_chip2#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [629] rom_file::rom_chip#0 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta rom_file.rom_chip
    // [630] call rom_file
    // [1485] phi from main::@123 to rom_file [phi:main::@123->rom_file]
    // [1485] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@123->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [631] rom_file::return#4 = rom_file::return#2
    // main::@124
    // [632] main::file#0 = rom_file::return#4 -- pbum1=pbuz2 
    lda.z rom_file.return
    sta file
    lda.z rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ...", file)
    // [633] call snprintf_init
    // [1167] phi from main::@124 to snprintf_init [phi:main::@124->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@124->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [634] phi from main::@124 to main::@125 [phi:main::@124->main::@125]
    // main::@125
    // sprintf(info_text, "Checking %s ...", file)
    // [635] call printf_str
    // [1172] phi from main::@125 to printf_str [phi:main::@125->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@125->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s5 [phi:main::@125->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@126
    // sprintf(info_text, "Checking %s ...", file)
    // [636] printf_string::str#20 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [637] call printf_string
    // [1181] phi from main::@126 to printf_string [phi:main::@126->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:main::@126->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#20 [phi:main::@126->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:main::@126->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:main::@126->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [638] phi from main::@126 to main::@127 [phi:main::@126->main::@127]
    // main::@127
    // sprintf(info_text, "Checking %s ...", file)
    // [639] call printf_str
    // [1172] phi from main::@127 to printf_str [phi:main::@127->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@127->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s6 [phi:main::@127->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@128
    // sprintf(info_text, "Checking %s ...", file)
    // [640] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [641] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [643] call display_action_progress
    // [874] phi from main::@128 to display_action_progress [phi:main::@128->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = info_text [phi:main::@128->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@129
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [644] main::$316 = main::rom_chip2#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip2
    asl
    asl
    sta main__316
    // [645] rom_read::file#0 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z rom_read.file
    lda file+1
    sta.z rom_read.file+1
    // [646] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbum1=vbum2 
    lda rom_bank
    sta rom_read.brom_bank_start
    // [647] rom_read::rom_size#0 = rom_sizes[main::$316] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__316
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [648] call rom_read
  // Read the ROM(n).BIN file.
    // [1491] phi from main::@129 to rom_read [phi:main::@129->rom_read]
    // [1491] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@129->rom_read#0] -- register_copy 
    // [1491] phi __errno#105 = __errno#114 [phi:main::@129->rom_read#1] -- register_copy 
    // [1491] phi __stdio_filecount#100 = __stdio_filecount#111 [phi:main::@129->rom_read#2] -- register_copy 
    // [1491] phi rom_read::file#10 = rom_read::file#0 [phi:main::@129->rom_read#3] -- register_copy 
    // [1491] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#1 [phi:main::@129->rom_read#4] -- register_copy 
    // [1491] phi rom_read::info_status#12 = STATUS_CHECKING [phi:main::@129->rom_read#5] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [649] rom_read::return#2 = rom_read::return#0
    // main::@130
    // [650] main::rom_bytes_read#0 = rom_read::return#2 -- vduz1=vdum2 
    lda rom_read.return
    sta.z rom_bytes_read
    lda rom_read.return+1
    sta.z rom_bytes_read+1
    lda rom_read.return+2
    sta.z rom_bytes_read+2
    lda rom_read.return+3
    sta.z rom_bytes_read+3
    // if (!rom_bytes_read)
    // [651] if(0==main::rom_bytes_read#0) goto main::@26 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z rom_bytes_read
    ora.z rom_bytes_read+1
    ora.z rom_bytes_read+2
    ora.z rom_bytes_read+3
    bne !__b26+
    jmp __b26
  !__b26:
    // main::@29
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [652] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_bytes_read
    and #<$4000-1
    sta.z rom_file_modulo
    lda.z rom_bytes_read+1
    and #>$4000-1
    sta.z rom_file_modulo+1
    lda.z rom_bytes_read+2
    and #<$4000-1>>$10
    sta.z rom_file_modulo+2
    lda.z rom_bytes_read+3
    and #>$4000-1>>$10
    sta.z rom_file_modulo+3
    // if(rom_file_modulo)
    // [653] if(0!=main::rom_file_modulo#0) goto main::@27 -- 0_neq_vduz1_then_la1 
    lda.z rom_file_modulo
    ora.z rom_file_modulo+1
    ora.z rom_file_modulo+2
    ora.z rom_file_modulo+3
    beq !__b27+
    jmp __b27
  !__b27:
    // main::@30
    // file_sizes[rom_chip] = rom_bytes_read
    // [654] file_sizes[main::$316] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vduz2 
    // RF5 | ROM.BIN all ok | Display the ROM.BIN release version and github commit id (if any) and set ROM to Flash | Flash
    // We know the file size, so we indicate it in the status panel.
    ldy main__316
    lda.z rom_bytes_read
    sta file_sizes,y
    lda.z rom_bytes_read+1
    sta file_sizes+1,y
    lda.z rom_bytes_read+2
    sta file_sizes+2,y
    lda.z rom_bytes_read+3
    sta file_sizes+3,y
    // rom_get_github_commit_id(rom_file_github, (char*)RAM_BASE)
    // [655] call rom_get_github_commit_id
    // [1922] phi from main::@30 to rom_get_github_commit_id [phi:main::@30->rom_get_github_commit_id]
    // [1922] phi rom_get_github_commit_id::commit_id#6 = main::rom_file_github [phi:main::@30->rom_get_github_commit_id#0] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_file_github
    sta.z rom_get_github_commit_id.commit_id+1
    // [1922] phi rom_get_github_commit_id::from#6 = (char *)$7800 [phi:main::@30->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_get_github_commit_id.from
    lda #>$7800
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::bank_push_set_bram1
    // asm
    // asm { lda$00 pha  }
    lda.z 0
    pha
    // BRAM = bank
    // [657] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@68
    // unsigned char rom_file_release = rom_get_release(*((char*)0xBF80))
    // [658] rom_get_release::release#2 = *((char *) 49024) -- vbum1=_deref_pbuc1 
    lda $bf80
    sta rom_get_release.release
    // [659] call rom_get_release
    // [1939] phi from main::@68 to rom_get_release [phi:main::@68->rom_get_release]
    // [1939] phi rom_get_release::release#3 = rom_get_release::release#2 [phi:main::@68->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char rom_file_release = rom_get_release(*((char*)0xBF80))
    // [660] rom_get_release::return#3 = rom_get_release::return#0
    // main::@138
    // [661] main::rom_file_release#0 = rom_get_release::return#3 -- vbum1=vbum2 
    lda rom_get_release.return
    sta rom_file_release
    // unsigned char rom_file_prefix = rom_get_prefix(*((char*)0xBF80))
    // [662] rom_get_prefix::release#1 = *((char *) 49024) -- vbum1=_deref_pbuc1 
    lda $bf80
    sta rom_get_prefix.release
    // [663] call rom_get_prefix
    // [1946] phi from main::@138 to rom_get_prefix [phi:main::@138->rom_get_prefix]
    // [1946] phi rom_get_prefix::release#2 = rom_get_prefix::release#1 [phi:main::@138->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char rom_file_prefix = rom_get_prefix(*((char*)0xBF80))
    // [664] rom_get_prefix::return#3 = rom_get_prefix::return#0
    // main::@139
    // [665] main::rom_file_prefix#0 = rom_get_prefix::return#3 -- vbuz1=vbum2 
    lda rom_get_prefix.return
    sta.z rom_file_prefix
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // main::@69
    // rom_get_version_text(rom_file_release_text, rom_file_prefix, rom_file_release, rom_file_github)
    // [667] rom_get_version_text::prefix#1 = main::rom_file_prefix#0 -- vbum1=vbuz2 
    lda.z rom_file_prefix
    sta rom_get_version_text.prefix
    // [668] rom_get_version_text::release#1 = main::rom_file_release#0 -- vbum1=vbum2 
    lda rom_file_release
    sta rom_get_version_text.release
    // [669] call rom_get_version_text
    // [1955] phi from main::@69 to rom_get_version_text [phi:main::@69->rom_get_version_text]
    // [1955] phi rom_get_version_text::github#2 = main::rom_file_github [phi:main::@69->rom_get_version_text#0] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z rom_get_version_text.github
    lda #>rom_file_github
    sta.z rom_get_version_text.github+1
    // [1955] phi rom_get_version_text::release#2 = rom_get_version_text::release#1 [phi:main::@69->rom_get_version_text#1] -- register_copy 
    // [1955] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#1 [phi:main::@69->rom_get_version_text#2] -- register_copy 
    // [1955] phi rom_get_version_text::release_info#2 = main::rom_file_release_text [phi:main::@69->rom_get_version_text#3] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_file_release_text
    sta.z rom_get_version_text.release_info+1
    jsr rom_get_version_text
    // [670] phi from main::@69 to main::@140 [phi:main::@69->main::@140]
    // main::@140
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [671] call snprintf_init
    // [1167] phi from main::@140 to snprintf_init [phi:main::@140->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@140->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@141
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [672] printf_string::str#23 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [673] call printf_string
    // [1181] phi from main::@141 to printf_string [phi:main::@141->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:main::@141->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#23 [phi:main::@141->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:main::@141->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:main::@141->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [674] phi from main::@141 to main::@142 [phi:main::@141->main::@142]
    // main::@142
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [675] call printf_str
    // [1172] phi from main::@142 to printf_str [phi:main::@142->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@142->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s2 [phi:main::@142->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [676] phi from main::@142 to main::@143 [phi:main::@142->main::@143]
    // main::@143
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [677] call printf_string
    // [1181] phi from main::@143 to printf_string [phi:main::@143->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:main::@143->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = main::rom_file_release_text [phi:main::@143->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z printf_string.str
    lda #>rom_file_release_text
    sta.z printf_string.str+1
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:main::@143->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:main::@143->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@144
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [678] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [679] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [681] display_info_rom::rom_chip#9 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [682] call display_info_rom
    // [1440] phi from main::@144 to display_info_rom [phi:main::@144->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text [phi:main::@144->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#9 [phi:main::@144->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@144->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // [683] phi from main::@133 main::@137 main::@144 main::@66 to main::@25 [phi:main::@133/main::@137/main::@144/main::@66->main::@25]
    // [683] phi __stdio_filecount#394 = __stdio_filecount#12 [phi:main::@133/main::@137/main::@144/main::@66->main::@25#0] -- register_copy 
    // [683] phi __errno#379 = __errno#122 [phi:main::@133/main::@137/main::@144/main::@66->main::@25#1] -- register_copy 
    // main::@25
  __b25:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [684] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip2
    // [175] phi from main::@25 to main::@24 [phi:main::@25->main::@24]
    // [175] phi __stdio_filecount#111 = __stdio_filecount#394 [phi:main::@25->main::@24#0] -- register_copy 
    // [175] phi __errno#114 = __errno#379 [phi:main::@25->main::@24#1] -- register_copy 
    // [175] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@25->main::@24#2] -- register_copy 
    jmp __b24
    // [685] phi from main::@29 to main::@27 [phi:main::@29->main::@27]
    // main::@27
  __b27:
    // sprintf(info_text, "File %s size error!", file)
    // [686] call snprintf_init
    // [1167] phi from main::@27 to snprintf_init [phi:main::@27->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@27->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [687] phi from main::@27 to main::@134 [phi:main::@27->main::@134]
    // main::@134
    // sprintf(info_text, "File %s size error!", file)
    // [688] call printf_str
    // [1172] phi from main::@134 to printf_str [phi:main::@134->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@134->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s8 [phi:main::@134->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@135
    // sprintf(info_text, "File %s size error!", file)
    // [689] printf_string::str#22 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [690] call printf_string
    // [1181] phi from main::@135 to printf_string [phi:main::@135->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:main::@135->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#22 [phi:main::@135->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:main::@135->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:main::@135->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [691] phi from main::@135 to main::@136 [phi:main::@135->main::@136]
    // main::@136
    // sprintf(info_text, "File %s size error!", file)
    // [692] call printf_str
    // [1172] phi from main::@136 to printf_str [phi:main::@136->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@136->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s9 [phi:main::@136->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@137
    // sprintf(info_text, "File %s size error!", file)
    // [693] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [694] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ISSUE, info_text)
    // [696] display_info_rom::rom_chip#8 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [697] call display_info_rom
    // [1440] phi from main::@137 to display_info_rom [phi:main::@137->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text [phi:main::@137->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#8 [phi:main::@137->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:main::@137->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b25
    // [698] phi from main::@130 to main::@26 [phi:main::@130->main::@26]
    // main::@26
  __b26:
    // sprintf(info_text, "No %s", file)
    // [699] call snprintf_init
    // [1167] phi from main::@26 to snprintf_init [phi:main::@26->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main::@26->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [700] phi from main::@26 to main::@131 [phi:main::@26->main::@131]
    // main::@131
    // sprintf(info_text, "No %s", file)
    // [701] call printf_str
    // [1172] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main::s7 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@132
    // sprintf(info_text, "No %s", file)
    // [702] printf_string::str#21 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [703] call printf_string
    // [1181] phi from main::@132 to printf_string [phi:main::@132->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:main::@132->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#21 [phi:main::@132->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:main::@132->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:main::@132->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@133
    // sprintf(info_text, "No %s", file)
    // [704] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [705] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_SKIP, info_text)
    // [707] display_info_rom::rom_chip#7 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [708] call display_info_rom
    // [1440] phi from main::@133 to display_info_rom [phi:main::@133->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text [phi:main::@133->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#7 [phi:main::@133->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@133->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b25
    // [709] phi from main::@20 to main::@23 [phi:main::@20->main::@23]
    // main::@23
  __b23:
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [710] call display_info_smc
  // SF3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
    // [932] phi from main::@23 to display_info_smc [phi:main::@23->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text5 [phi:main::@23->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_smc.info_text
    lda #>info_text5
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@23->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@23->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [164] phi from main::@22 main::@23 to main::CLI2 [phi:main::@22/main::@23->main::CLI2]
  __b9:
    // [164] phi smc_file_minor#301 = 0 [phi:main::@22/main::@23->main::CLI2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [164] phi smc_file_major#301 = 0 [phi:main::@22/main::@23->main::CLI2#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [164] phi smc_file_release#301 = 0 [phi:main::@22/main::@23->main::CLI2#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [164] phi __stdio_filecount#109 = __stdio_filecount#39 [phi:main::@22/main::@23->main::CLI2#3] -- register_copy 
    // [164] phi __errno#112 = __errno#122 [phi:main::@22/main::@23->main::CLI2#4] -- register_copy 
    jmp CLI2
    // [711] phi from main::@118 to main::@22 [phi:main::@118->main::@22]
    // main::@22
  __b22:
    // display_info_smc(STATUS_SKIP, "No SMC.BIN!")
    // [712] call display_info_smc
  // SF1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
  // SF2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
    // [932] phi from main::@22 to display_info_smc [phi:main::@22->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = main::info_text4 [phi:main::@22->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main::@22->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@22->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b9
    // main::@16
  __b16:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [713] if(rom_device_ids[main::rom_chip1#10]!=$55) goto main::@17 -- pbuc1_derefidx_vbuz1_neq_vbuc2_then_la1 
    lda #$55
    ldy.z rom_chip1
    cmp rom_device_ids,y
    bne __b17
    // main::@18
  __b18:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [714] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip1
    // [132] phi from main::@18 to main::@15 [phi:main::@18->main::@15]
    // [132] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@18->main::@15#0] -- register_copy 
    jmp __b15
    // main::@17
  __b17:
    // bank_set_brom(rom_chip*32)
    // [715] main::bank_set_brom2_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta bank_set_brom2_bank
    // main::bank_set_brom2
    // BROM = bank
    // [716] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbum2 
    sta.z BROM
    // main::@64
    // rom_chip*8
    // [717] main::$115 = main::rom_chip1#10 << 3 -- vbum1=vbuz2_rol_3 
    lda.z rom_chip1
    asl
    asl
    asl
    sta main__115
    // rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000)
    // [718] rom_get_github_commit_id::commit_id#0 = rom_github + main::$115 -- pbuz1=pbuc1_plus_vbum2 
    clc
    adc #<rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [719] call rom_get_github_commit_id
    // [1922] phi from main::@64 to rom_get_github_commit_id [phi:main::@64->rom_get_github_commit_id]
    // [1922] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#0 [phi:main::@64->rom_get_github_commit_id#0] -- register_copy 
    // [1922] phi rom_get_github_commit_id::from#6 = (char *) 49152 [phi:main::@64->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z rom_get_github_commit_id.from
    lda #>$c000
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::@112
    // rom_get_release(*((char*)0xFF80))
    // [720] rom_get_release::release#1 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_release.release
    // [721] call rom_get_release
    // [1939] phi from main::@112 to rom_get_release [phi:main::@112->rom_get_release]
    // [1939] phi rom_get_release::release#3 = rom_get_release::release#1 [phi:main::@112->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)0xFF80))
    // [722] rom_get_release::return#2 = rom_get_release::return#0
    // main::@113
    // [723] main::$111 = rom_get_release::return#2 -- vbuz1=vbum2 
    lda rom_get_release.return
    sta.z main__111
    // rom_release[rom_chip] = rom_get_release(*((char*)0xFF80))
    // [724] rom_release[main::rom_chip1#10] = main::$111 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z rom_chip1
    sta rom_release,y
    // rom_get_prefix(*((char*)0xFF80))
    // [725] rom_get_prefix::release#0 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_prefix.release
    // [726] call rom_get_prefix
    // [1946] phi from main::@113 to rom_get_prefix [phi:main::@113->rom_get_prefix]
    // [1946] phi rom_get_prefix::release#2 = rom_get_prefix::release#0 [phi:main::@113->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)0xFF80))
    // [727] rom_get_prefix::return#2 = rom_get_prefix::return#0
    // main::@114
    // [728] main::$112 = rom_get_prefix::return#2 -- vbuz1=vbum2 
    lda rom_get_prefix.return
    sta.z main__112
    // rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80))
    // [729] rom_prefix[main::rom_chip1#10] = main::$112 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z rom_chip1
    sta rom_prefix,y
    // rom_chip*13
    // [730] main::$376 = main::rom_chip1#10 << 1 -- vbuz1=vbuz2_rol_1 
    tya
    asl
    sta.z main__376
    // [731] main::$377 = main::$376 + main::rom_chip1#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__377
    clc
    adc.z rom_chip1
    sta.z main__377
    // [732] main::$378 = main::$377 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__378
    asl
    asl
    sta.z main__378
    // [733] main::$113 = main::$378 + main::rom_chip1#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__113
    clc
    adc.z rom_chip1
    sta.z main__113
    // rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8])
    // [734] rom_get_version_text::release_info#0 = rom_release_text + main::$113 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_release_text
    adc #0
    sta.z rom_get_version_text.release_info+1
    // [735] rom_get_version_text::github#0 = rom_github + main::$115 -- pbuz1=pbuc1_plus_vbum2 
    lda main__115
    clc
    adc #<rom_github
    sta.z rom_get_version_text.github
    lda #>rom_github
    adc #0
    sta.z rom_get_version_text.github+1
    // [736] rom_get_version_text::prefix#0 = rom_prefix[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbuz2 
    lda rom_prefix,y
    sta rom_get_version_text.prefix
    // [737] rom_get_version_text::release#0 = rom_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbuz2 
    lda rom_release,y
    sta rom_get_version_text.release
    // [738] call rom_get_version_text
    // [1955] phi from main::@114 to rom_get_version_text [phi:main::@114->rom_get_version_text]
    // [1955] phi rom_get_version_text::github#2 = rom_get_version_text::github#0 [phi:main::@114->rom_get_version_text#0] -- register_copy 
    // [1955] phi rom_get_version_text::release#2 = rom_get_version_text::release#0 [phi:main::@114->rom_get_version_text#1] -- register_copy 
    // [1955] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#0 [phi:main::@114->rom_get_version_text#2] -- register_copy 
    // [1955] phi rom_get_version_text::release_info#2 = rom_get_version_text::release_info#0 [phi:main::@114->rom_get_version_text#3] -- register_copy 
    jsr rom_get_version_text
    // main::@115
    // display_info_rom(rom_chip, STATUS_DETECTED, NULL)
    // [739] display_info_rom::rom_chip#6 = main::rom_chip1#10 -- vbum1=vbuz2 
    lda.z rom_chip1
    sta display_info_rom.rom_chip
    // [740] call display_info_rom
    // [1440] phi from main::@115 to display_info_rom [phi:main::@115->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = 0 [phi:main::@115->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#6 [phi:main::@115->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_DETECTED [phi:main::@115->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b18
    // main::@12
  __b12:
    // rom_chip*13
    // [741] main::$372 = main::rom_chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z main__372
    // [742] main::$373 = main::$372 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__373
    clc
    adc.z rom_chip
    sta.z main__373
    // [743] main::$374 = main::$373 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__374
    asl
    asl
    sta.z main__374
    // [744] main::$87 = main::$374 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__87
    clc
    adc.z rom_chip
    sta.z main__87
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [745] strcpy::destination#1 = rom_release_text + main::$87 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [746] call strcpy
    // [1027] phi from main::@12 to strcpy [phi:main::@12->strcpy]
    // [1027] phi strcpy::dst#0 = strcpy::destination#1 [phi:main::@12->strcpy#0] -- register_copy 
    // [1027] phi strcpy::src#0 = main::source [phi:main::@12->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@102
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [747] display_info_rom::rom_chip#5 = main::rom_chip#2 -- vbum1=vbuz2 
    lda.z rom_chip
    sta display_info_rom.rom_chip
    // [748] call display_info_rom
    // [1440] phi from main::@102 to display_info_rom [phi:main::@102->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = 0 [phi:main::@102->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#5 [phi:main::@102->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@102->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@103
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [749] main::rom_chip#1 = ++ main::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [94] phi from main::@103 to main::@11 [phi:main::@103->main::@11]
    // [94] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@103->main::@11#0] -- register_copy 
    jmp __b11
  .segment Data
    smc_file_version_text: .fill $d, 0
    // Fill the version data ...
    rom_file_github: .fill 8, 0
    rom_file_release_text: .fill $d, 0
    title_text: .text "Commander X16 Update Utility (v2.2.0)."
    .byte 0
    s: .text "# Chip Status    Type   Curr. Release Update Info"
    .byte 0
    s1: .text "- ---- --------- ------ ------------- --------------------------"
    .byte 0
    info_text: .text "Introduction, please read carefully the below!"
    .byte 0
    source: .text "          "
    .byte 0
    source1: .text "0.0.0"
    .byte 0
    info_text3: .text "Checking SMC.BIN ..."
    .byte 0
    info_text4: .text "No SMC.BIN!"
    .byte 0
    info_text5: .text "SMC.BIN too large!"
    .byte 0
    s4: .text "SMC.BIN:"
    .byte 0
    s5: .text "Checking "
    .byte 0
    s7: .text "No "
    .byte 0
    s8: .text "File "
    .byte 0
    s9: .text " size error!"
    .byte 0
    info_text6: .text "SMC update issue!"
    .byte 0
    info_text7: .text "Issue with SMC!"
    .byte 0
    info_text8: .text "CX16 ROM update issue, ROM not detected!"
    .byte 0
    info_text9: .text "Issue with main CX16 ROM!"
    .byte 0
    info_text10: .text "Are J1 jumper pins closed?"
    .byte 0
    info_text11: .text "CX16 ROM update issue!"
    .byte 0
    info_text13: .text "Compatibility between ROM.BIN and SMC.BIN can't be assured!"
    .byte 0
    info_text14: .text "Continue with flashing anyway? [Y/N]"
    .byte 0
    filter: .text "YN"
    .byte 0
    info_text15: .text "The SMC chip and SMC.BIN versions are equal, no flash required!"
    .byte 0
    info_text16: .text "SMC.BIN and SMC equal."
    .byte 0
    info_text17: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text18: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter1: .text "nyNY"
    .byte 0
    main__345: .text "nN"
    .byte 0
    info_text19: .text "Cancelled"
    .byte 0
    info_text22: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text23: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    info_text24: .text "Press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text25: .text "Press POWER/RESET!"
    .byte 0
    info_text27: .text "SMC has errors!"
    .byte 0
    info_text28: .text "POWER/RESET not pressed!"
    .byte 0
    s11: .text "Reading "
    .byte 0
    s12: .text " ... (.) data ( ) empty"
    .byte 0
    info_text29: .text "SMC Update failed!"
    .byte 0
    info_text30: .text "Comparing ... (.) data, (=) same, (*) different."
    .byte 0
    s14: .text " flash errors!"
    .byte 0
    s15: .text "There was a severe error updating your VERA!"
    .byte 0
    s16: .text @"You are back at the READY prompt without resetting your CX16.\n\n"
    .byte 0
    s17: .text @"Please don't reset or shut down your VERA until you've\n"
    .byte 0
    s18: .text "managed to either reflash your VERA with the previous firmware "
    .byte 0
    s19: .text @"or have update successs retrying!\n\n"
    .byte 0
    s20: .text @"PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n"
    .byte 0
    info_text33: .text "No CX16 component has been updated with new firmware!"
    .byte 0
    info_text34: .text "Update Failure! Your CX16 may no longer boot!"
    .byte 0
    info_text35: .text "Take a photo of this screen, shut down power and retry!"
    .byte 0
    info_text36: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text37: .text "Your CX16 update is a success!"
    .byte 0
    text: .text "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!"
    .byte 0
    s22: .text "] Please read carefully the below ..."
    .byte 0
    s23: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s24: .text "("
    .byte 0
    s25: .text ") Your CX16 will reset after countdown ..."
    .byte 0
    main__45: .byte 0
    main__62: .byte 0
    main__71: .byte 0
    main__84: .byte 0
    main__115: .byte 0
    main__187: .byte 0
    main__275: .byte 0
    main__280: .byte 0
    main__316: .byte 0
    main__318: .byte 0
    check_status_smc2_main__0: .byte 0
    check_status_cx16_rom1_check_status_rom1_main__0: .byte 0
    check_status_smc3_main__0: .byte 0
    check_status_cx16_rom2_check_status_rom1_main__0: .byte 0
    check_status_smc4_main__0: .byte 0
    check_status_cx16_rom3_check_status_rom1_main__0: .byte 0
    check_status_smc5_main__0: .byte 0
    check_status_cx16_rom4_check_status_rom1_main__0: .byte 0
    check_status_smc6_main__0: .byte 0
    check_status_smc7_main__0: .byte 0
    check_status_vera1_main__0: .byte 0
    check_status_smc8_main__0: .byte 0
    check_status_vera2_main__0: .byte 0
    check_status_vera3_main__0: .byte 0
    check_status_vera4_main__0: .byte 0
    check_status_smc9_main__0: .byte 0
    check_status_cx16_rom5_check_status_rom1_main__0: .byte 0
    check_status_vera5_main__0: .byte 0
    check_status_smc10_main__0: .byte 0
    check_status_cx16_rom6_check_status_rom1_main__0: .byte 0
    check_status_smc13_main__0: .byte 0
    check_status_smc14_main__0: .byte 0
    check_status_vera6_main__0: .byte 0
    check_status_vera7_main__0: .byte 0
    check_status_smc15_main__0: .byte 0
    check_status_vera8_main__0: .byte 0
    check_status_smc16_main__0: .byte 0
    check_status_vera9_main__0: .byte 0
    check_status_smc17_main__0: .byte 0
    check_status_smc1_return: .byte 0
    bank_set_brom2_bank: .byte 0
    check_status_smc2_return: .byte 0
    check_status_cx16_rom1_check_status_rom1_return: .byte 0
    rom_bank: .byte 0
    file: .word 0
    rom_file_release: .byte 0
    check_status_smc3_return: .byte 0
    check_status_cx16_rom2_check_status_rom1_return: .byte 0
    check_status_smc4_return: .byte 0
    check_status_cx16_rom3_check_status_rom1_return: .byte 0
    check_status_smc5_return: .byte 0
    check_status_cx16_rom4_check_status_rom1_return: .byte 0
    check_status_smc6_return: .byte 0
    ch: .byte 0
    check_status_smc7_return: .byte 0
    check_status_vera1_return: .byte 0
    check_status_smc8_return: .byte 0
    check_status_vera2_return: .byte 0
    check_status_vera3_return: .byte 0
    check_status_vera4_return: .byte 0
    check_status_smc9_return: .byte 0
    check_status_cx16_rom5_check_status_rom1_return: .byte 0
    check_status_vera5_return: .byte 0
    ch1: .byte 0
    check_status_smc10_return: .byte 0
    check_status_cx16_rom6_check_status_rom1_return: .byte 0
    check_status_rom1_return: .byte 0
    check_status_smc11_return: .byte 0
    check_status_smc12_return: .byte 0
    rom_bank1: .byte 0
    check_status_smc13_return: .byte 0
    check_status_smc14_return: .byte 0
    check_status_vera6_return: .byte 0
    check_status_vera7_return: .byte 0
    check_status_smc15_return: .byte 0
    check_status_vera8_return: .byte 0
    check_status_smc16_return: .byte 0
    check_status_vera9_return: .byte 0
    check_status_smc17_return: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [750] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [751] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [752] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [753] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $5d
    .label textcolor__1 = $5d
    // __conio.color & 0xF0
    // [755] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [756] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [757] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [758] return 
    rts
  .segment Data
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
    .label bgcolor__0 = $5d
    .label bgcolor__1 = $5e
    .label bgcolor__2 = $5d
    // __conio.color & 0x0F
    // [760] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [761] bgcolor::$1 = bgcolor::color#15 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [762] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [763] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [764] return 
    rts
  .segment Data
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
    // [765] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [766] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [767] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [768] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [770] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [771] return 
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
    .label gotoxy__2 = $2c
    .label gotoxy__3 = $2c
    .label gotoxy__6 = $2b
    .label gotoxy__7 = $2b
    .label gotoxy__8 = $33
    .label gotoxy__9 = $30
    .label gotoxy__10 = $2f
    .label gotoxy__14 = $2b
    // (x>=__conio.width)?__conio.width:x
    // [773] if(gotoxy::x#38>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [775] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [775] phi gotoxy::$3 = gotoxy::x#38 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [774] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [775] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [775] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [776] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [777] if(gotoxy::y#38>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [778] gotoxy::$14 = gotoxy::y#38 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [779] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [779] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [780] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [781] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [782] gotoxy::$10 = gotoxy::y#38 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [783] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [784] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [785] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [786] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $44
    // __conio.cursor_x = 0
    // [787] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [788] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [789] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [790] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [791] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [792] return 
    rts
}
  // display_frame_init_64
/**
 * @brief Initialize the display and size the borders for 64 characters horizontally.
 */
display_frame_init_64: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    .label cx16_k_screen_set_charset1_offset = $eb
    // cx16_k_screen_set_mode(0)
    // [793] cx16_k_screen_set_mode::mode = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_screen_set_mode.mode
    // [794] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [795] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // screenlayer1()
    // [796] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // display_frame_init_64::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [797] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [798] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cx16_k_screen_set_charset1_offset
    sta.z cx16_k_screen_set_charset1_offset+1
    // display_frame_init_64::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [800] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [801] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [802] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [803] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [804] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [805] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [806] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [807] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [808] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [809] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [810] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [811] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [812] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [813] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [814] phi from display_frame_init_64::vera_layer1_show1 to display_frame_init_64::@1 [phi:display_frame_init_64::vera_layer1_show1->display_frame_init_64::@1]
    // display_frame_init_64::@1
    // textcolor(WHITE)
    // [815] call textcolor
  // Layer 1 is the current text canvas.
    // [754] phi from display_frame_init_64::@1 to textcolor [phi:display_frame_init_64::@1->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:display_frame_init_64::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [816] phi from display_frame_init_64::@1 to display_frame_init_64::@4 [phi:display_frame_init_64::@1->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // bgcolor(BLUE)
    // [817] call bgcolor
  // Default text color is white.
    // [759] phi from display_frame_init_64::@4 to bgcolor [phi:display_frame_init_64::@4->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_frame_init_64::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [818] phi from display_frame_init_64::@4 to display_frame_init_64::@5 [phi:display_frame_init_64::@4->display_frame_init_64::@5]
    // display_frame_init_64::@5
    // clrscr()
    // [819] call clrscr
    // With a blue background.
    // cx16-conio.c won't compile scrolling code for this program with the underlying define, resulting in less code overhead!
    jsr clrscr
    // display_frame_init_64::@return
    // }
    // [820] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
}
.segment Code
  // display_frame_draw
/**
 * @brief Create the CX16 update frame for X = 64, Y = 40 positions.
 */
display_frame_draw: {
    // textcolor(LIGHT_BLUE)
    // [822] call textcolor
    // [754] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [754] phi textcolor::color#23 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [823] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [824] call bgcolor
    // [759] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [825] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [826] call clrscr
    jsr clrscr
    // [827] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [828] call display_frame
    // [2020] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [2020] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [829] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [830] call display_frame
    // [2020] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [2020] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [831] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [832] call display_frame
    // [2020] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [833] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [834] call display_frame
  // Chipset areas
    // [2020] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x1
    jsr display_frame
    // [835] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [836] call display_frame
    // [2020] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x1
    jsr display_frame
    // [837] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [838] call display_frame
    // [2020] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x1
    jsr display_frame
    // [839] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [840] call display_frame
    // [2020] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x1
    jsr display_frame
    // [841] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [842] call display_frame
    // [2020] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x1
    jsr display_frame
    // [843] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [844] call display_frame
    // [2020] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x1
    jsr display_frame
    // [845] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [846] call display_frame
    // [2020] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x1
    jsr display_frame
    // [847] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [848] call display_frame
    // [2020] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x1
    jsr display_frame
    // [849] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [850] call display_frame
    // [2020] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x1
    jsr display_frame
    // [851] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [852] call display_frame
    // [2020] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [2020] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [853] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [854] call display_frame
  // Progress area
    // [2020] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [2020] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [855] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [856] call display_frame
    // [2020] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [2020] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [857] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [858] call display_frame
    // [2020] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [2020] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [2020] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [2020] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2020] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [859] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [860] call textcolor
    // [754] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [861] return 
    rts
}
  // display_frame_title
/**
 * @brief Print the frame title.
 * 
 * @param title_text The title.
 */
// void display_frame_title(char *title_text)
display_frame_title: {
    // gotoxy(2, 1)
    // [863] call gotoxy
    // [772] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [772] phi gotoxy::y#38 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [864] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [865] call printf_string
    // [1181] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [866] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($56) const char *s)
cputsxy: {
    .label s = $56
    // gotoxy(x, y)
    // [868] gotoxy::x#1 = cputsxy::x#4 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [869] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [870] call gotoxy
    // [772] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [871] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [872] call cputs
    // [2154] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [873] return 
    rts
  .segment Data
    y: .byte 0
    x: .byte 0
}
.segment Code
  // display_action_progress
/**
 * @brief Print the progress at the action frame, which is the first line.
 * 
 * @param info_text The progress text to be displayed.
 */
// void display_action_progress(__zp($47) char *info_text)
display_action_progress: {
    .label info_text = $47
    // unsigned char x = wherex()
    // [875] call wherex
    jsr wherex
    // [876] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [877] display_action_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [878] call wherey
    jsr wherey
    // [879] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [880] display_action_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [881] call gotoxy
    // [772] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [882] printf_string::str#1 = display_action_progress::info_text#25
    // [883] call printf_string
    // [1181] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [884] gotoxy::x#15 = display_action_progress::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [885] gotoxy::y#15 = display_action_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [886] call gotoxy
    // [772] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#15 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#15 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [887] return 
    rts
  .segment Data
    .label x = wherex.return
    .label y = wherey.return
}
.segment Code
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    // textcolor(WHITE)
    // [889] call textcolor
    // [754] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [890] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [891] call bgcolor
    // [759] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [892] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [892] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [893] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [894] return 
    rts
    // [895] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [895] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x
    // [895] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [896] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [897] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [892] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [892] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [898] cputcxy::x#15 = display_progress_clear::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [899] cputcxy::y#15 = display_progress_clear::y#2 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [900] call cputcxy
    // [2167] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [2167] phi cputcxy::c#18 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [2167] phi cputcxy::y#18 = cputcxy::y#15 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#15 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [901] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbum1=_inc_vbum1 
    inc x
    // for(unsigned char i = 0; i < w; i++)
    // [902] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [895] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [895] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [895] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
  .segment Data
    x: .byte 0
    i: .byte 0
    y: .byte 0
}
.segment Code
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [904] call display_smc_led
    // [2175] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [2175] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_smc_led.c
    jsr display_smc_led
    // [905] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [906] call display_print_chip
    // [2181] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [2181] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2181] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta display_print_chip.w
    // [2181] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #1
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [907] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [909] call display_vera_led
    // [2225] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [2225] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_vera_led.c
    jsr display_vera_led
    // [910] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [911] call display_print_chip
    // [2181] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [2181] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2181] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta display_print_chip.w
    // [2181] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #9
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [912] return 
    rts
  .segment Data
    text: .text "VERA     "
    .byte 0
}
.segment Code
  // display_chip_rom
/**
 * @brief Print all ROM chips.
 * 
 */
display_chip_rom: {
    .label display_chip_rom__4 = $51
    .label display_chip_rom__6 = $3c
    .label display_chip_rom__11 = $3c
    .label display_chip_rom__12 = $3c
    // [914] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [914] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [915] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [916] return 
    rts
    // [917] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [918] call strcpy
    // [1027] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [1027] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [1027] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [919] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbum2_rol_1 
    lda r
    asl
    sta.z display_chip_rom__11
    // [920] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [921] call strcat
    // [2231] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [922] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [923] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [924] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [925] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbum1=vbum2 
    lda r
    sta display_rom_led.chip
    // [926] call display_rom_led
    // [2243] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [2243] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_rom_led.c
    // [2243] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [927] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbum2 
    lda r
    clc
    adc.z display_chip_rom__12
    sta.z display_chip_rom__12
    // [928] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [929] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbum1=vbuc1_plus_vbuz2 
    lda #$14
    clc
    adc.z display_chip_rom__6
    sta display_print_chip.x
    // [930] call display_print_chip
    // [2181] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [2181] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [2181] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta display_print_chip.w
    // [2181] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [931] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [914] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [914] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    r: .byte 0
}
.segment Code
  // display_info_smc
/**
 * @brief Display the SMC status in the info frame.
 * 
 * @param status The STATUS_ 
 * 
 * @remark The smc_booloader is a global variable. 
 */
// void display_info_smc(__mem() char info_status, __zp($40) char *info_text)
display_info_smc: {
    .label display_info_smc__9 = $3c
    .label info_text = $40
    // unsigned char x = wherex()
    // [933] call wherex
    jsr wherex
    // [934] wherex::return#10 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_2
    // display_info_smc::@3
    // [935] display_info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [936] call wherey
    jsr wherey
    // [937] wherey::return#10 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_2
    // display_info_smc::@4
    // [938] display_info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [939] status_smc#0 = display_info_smc::info_status#20 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [940] display_smc_led::c#1 = status_color[display_info_smc::info_status#20] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_smc_led.c
    // [941] call display_smc_led
    // [2175] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [2175] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [942] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [943] call gotoxy
    // [772] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [772] phi gotoxy::y#38 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [944] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [945] call printf_str
    // [1172] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [946] display_info_smc::$9 = display_info_smc::info_status#20 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_smc__9
    // [947] printf_string::str#3 = status_text[display_info_smc::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [948] call printf_string
    // [1181] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [949] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [950] call printf_str
    // [1172] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [951] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [952] call printf_string
    // [1181] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = smc_version_text [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 8 [phi:display_info_smc::@9->printf_string#3] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [953] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [954] call printf_str
    // [1172] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [955] printf_uint::uvalue#3 = smc_bootloader#14 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [956] call printf_uint
    // [2254] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 0 [phi:display_info_smc::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 0 [phi:display_info_smc::@11->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &cputc [phi:display_info_smc::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = DECIMAL [phi:display_info_smc::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = printf_uint::uvalue#3 [phi:display_info_smc::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [957] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [958] call printf_str
    // [1172] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [959] if((char *)0==display_info_smc::info_text#20) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [960] phi from display_info_smc::@13 to display_info_smc::@2 [phi:display_info_smc::@13->display_info_smc::@2]
    // display_info_smc::@2
    // gotoxy(INFO_X+64-28, INFO_Y)
    // [961] call gotoxy
    // [772] phi from display_info_smc::@2 to gotoxy [phi:display_info_smc::@2->gotoxy]
    // [772] phi gotoxy::y#38 = $11 [phi:display_info_smc::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = 4+$40-$1c [phi:display_info_smc::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_smc::@14
    // printf("%-25s", info_text)
    // [962] printf_string::str#5 = display_info_smc::info_text#20 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [963] call printf_string
    // [1181] phi from display_info_smc::@14 to printf_string [phi:display_info_smc::@14->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@14->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#5 [phi:display_info_smc::@14->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@14->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = $19 [phi:display_info_smc::@14->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [964] gotoxy::x#19 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [965] gotoxy::y#19 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [966] call gotoxy
    // [772] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#19 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#19 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [967] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " BL:"
    .byte 0
    .label x = wherex.return_2
    .label y = wherey.return_2
    info_status: .byte 0
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__mem() char info_status, __zp($5f) char *info_text)
display_info_vera: {
    .label display_info_vera__9 = $51
    .label info_text = $5f
    // unsigned char x = wherex()
    // [969] call wherex
    jsr wherex
    // [970] wherex::return#11 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_3
    // display_info_vera::@3
    // [971] display_info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [972] call wherey
    jsr wherey
    // [973] wherey::return#11 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_3
    // display_info_vera::@4
    // [974] display_info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [975] status_vera#115 = display_info_vera::info_status#15 -- vbum1=vbum2 
    lda info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [976] display_vera_led::c#1 = status_color[display_info_vera::info_status#15] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_vera_led.c
    // [977] call display_vera_led
    // [2225] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [2225] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [978] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [979] call gotoxy
    // [772] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [772] phi gotoxy::y#38 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [980] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [981] call printf_str
    // [1172] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [982] display_info_vera::$9 = display_info_vera::info_status#15 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_vera__9
    // [983] printf_string::str#6 = status_text[display_info_vera::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [984] call printf_string
    // [1181] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [985] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [986] call printf_str
    // [1172] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [987] printf_uchar::uvalue#4 = spi_manufacturer#10 -- vbum1=vbum2 
    lda spi_manufacturer
    sta printf_uchar.uvalue
    // [988] call printf_uchar
    // [1307] phi from display_info_vera::@9 to printf_uchar [phi:display_info_vera::@9->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:display_info_vera::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:display_info_vera::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &cputc [phi:display_info_vera::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:display_info_vera::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#4 [phi:display_info_vera::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [989] phi from display_info_vera::@9 to display_info_vera::@10 [phi:display_info_vera::@9->display_info_vera::@10]
    // display_info_vera::@10
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [990] call printf_str
    // [1172] phi from display_info_vera::@10 to printf_str [phi:display_info_vera::@10->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_vera::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:display_info_vera::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@11
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [991] printf_uchar::uvalue#5 = spi_memory_type#10 -- vbum1=vbum2 
    lda spi_memory_type
    sta printf_uchar.uvalue
    // [992] call printf_uchar
    // [1307] phi from display_info_vera::@11 to printf_uchar [phi:display_info_vera::@11->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:display_info_vera::@11->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:display_info_vera::@11->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &cputc [phi:display_info_vera::@11->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:display_info_vera::@11->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#5 [phi:display_info_vera::@11->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [993] phi from display_info_vera::@11 to display_info_vera::@12 [phi:display_info_vera::@11->display_info_vera::@12]
    // display_info_vera::@12
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [994] call printf_str
    // [1172] phi from display_info_vera::@12 to printf_str [phi:display_info_vera::@12->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_vera::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:display_info_vera::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@13
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [995] printf_uchar::uvalue#6 = spi_memory_capacity#10 -- vbum1=vbum2 
    lda spi_memory_capacity
    sta printf_uchar.uvalue
    // [996] call printf_uchar
    // [1307] phi from display_info_vera::@13 to printf_uchar [phi:display_info_vera::@13->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:display_info_vera::@13->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:display_info_vera::@13->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &cputc [phi:display_info_vera::@13->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:display_info_vera::@13->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#6 [phi:display_info_vera::@13->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [997] phi from display_info_vera::@13 to display_info_vera::@14 [phi:display_info_vera::@13->display_info_vera::@14]
    // display_info_vera::@14
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [998] call printf_str
    // [1172] phi from display_info_vera::@14 to printf_str [phi:display_info_vera::@14->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_vera::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_info_vera::s4 [phi:display_info_vera::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@15
    // if(info_text)
    // [999] if((char *)0==display_info_vera::info_text#15) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [1000] phi from display_info_vera::@15 to display_info_vera::@2 [phi:display_info_vera::@15->display_info_vera::@2]
    // display_info_vera::@2
    // gotoxy(INFO_X+64-28, INFO_Y+1)
    // [1001] call gotoxy
    // [772] phi from display_info_vera::@2 to gotoxy [phi:display_info_vera::@2->gotoxy]
    // [772] phi gotoxy::y#38 = $11+1 [phi:display_info_vera::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = 4+$40-$1c [phi:display_info_vera::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_vera::@16
    // printf("%-25s", info_text)
    // [1002] printf_string::str#7 = display_info_vera::info_text#15 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1003] call printf_string
    // [1181] phi from display_info_vera::@16 to printf_string [phi:display_info_vera::@16->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_vera::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#7 [phi:display_info_vera::@16->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_vera::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = $19 [phi:display_info_vera::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [1004] gotoxy::x#22 = display_info_vera::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1005] gotoxy::y#22 = display_info_vera::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1006] call gotoxy
    // [772] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#22 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#22 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [1007] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " SPI "
    .byte 0
    s4: .text "              "
    .byte 0
    .label x = wherex.return_3
    .label y = wherey.return_3
    info_status: .byte 0
}
.segment CodeIntro
  // main_intro
main_intro: {
    .label intro_status = $c6
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [1009] call display_progress_text
    // [1292] phi from main_intro to display_progress_text [phi:main_intro->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_into_briefing_text [phi:main_intro->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_intro_briefing_count [phi:main_intro->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_briefing_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [1010] phi from main_intro to main_intro::@4 [phi:main_intro->main_intro::@4]
    // main_intro::@4
    // util_wait_space()
    // [1011] call util_wait_space
    // [1350] phi from main_intro::@4 to util_wait_space [phi:main_intro::@4->util_wait_space]
    jsr util_wait_space
    // [1012] phi from main_intro::@4 to main_intro::@5 [phi:main_intro::@4->main_intro::@5]
    // main_intro::@5
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [1013] call display_progress_text
    // [1292] phi from main_intro::@5 to display_progress_text [phi:main_intro::@5->display_progress_text]
    // [1292] phi display_progress_text::text#13 = display_into_colors_text [phi:main_intro::@5->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [1292] phi display_progress_text::lines#12 = display_intro_colors_count [phi:main_intro::@5->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_colors_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [1014] phi from main_intro::@5 to main_intro::@1 [phi:main_intro::@5->main_intro::@1]
    // [1014] phi main_intro::intro_status#2 = 0 [phi:main_intro::@5->main_intro::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_status
    // main_intro::@1
  __b1:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [1015] if(main_intro::intro_status#2<$b) goto main_intro::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_status
    cmp #$b
    bcc __b2
    // [1016] phi from main_intro::@1 to main_intro::@3 [phi:main_intro::@1->main_intro::@3]
    // main_intro::@3
    // util_wait_space()
    // [1017] call util_wait_space
    // [1350] phi from main_intro::@3 to util_wait_space [phi:main_intro::@3->util_wait_space]
    jsr util_wait_space
    // [1018] phi from main_intro::@3 to main_intro::@7 [phi:main_intro::@3->main_intro::@7]
    // main_intro::@7
    // display_progress_clear()
    // [1019] call display_progress_clear
    // [888] phi from main_intro::@7 to display_progress_clear [phi:main_intro::@7->display_progress_clear]
    jsr display_progress_clear
    // main_intro::@return
    // }
    // [1020] return 
    rts
    // main_intro::@2
  __b2:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [1021] display_info_led::y#3 = PROGRESS_Y+3 + main_intro::intro_status#2 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y+3
    clc
    adc.z intro_status
    sta display_info_led.y
    // [1022] display_info_led::tc#3 = status_color[main_intro::intro_status#2] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z intro_status
    lda status_color,y
    sta display_info_led.tc
    // [1023] call display_info_led
    // [2265] phi from main_intro::@2 to display_info_led [phi:main_intro::@2->display_info_led]
    // [2265] phi display_info_led::y#4 = display_info_led::y#3 [phi:main_intro::@2->display_info_led#0] -- register_copy 
    // [2265] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main_intro::@2->display_info_led#1] -- vbum1=vbuc1 
    lda #PROGRESS_X+3
    sta display_info_led.x
    // [2265] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main_intro::@2->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main_intro::@6
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [1024] main_intro::intro_status#1 = ++ main_intro::intro_status#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_status
    // [1014] phi from main_intro::@6 to main_intro::@1 [phi:main_intro::@6->main_intro::@1]
    // [1014] phi main_intro::intro_status#2 = main_intro::intro_status#1 [phi:main_intro::@6->main_intro::@1#0] -- register_copy 
    jmp __b1
}
.segment Code
  // smc_detect
/**
 * @brief Detect the SMC chip on the CX16 board, and the bootloader version contained in it.
 * 
 * @return unsigned int bootloader version in the SMC chip, if all is OK.
 * @return unsigned int 0x0100 if there is no bootloader in the SMC chip.
 * @return unsigned int 0x0200 if there is a technical error reading or detecting the SMC chip. 
 */
smc_detect: {
    // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    .label return = 1
    // smc_detect::@return
    // }
    // [1026] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($47) char *destination, char *source)
strcpy: {
    .label src = $56
    .label dst = $47
    .label destination = $47
    // [1028] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [1028] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1028] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [1029] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1030] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1031] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1032] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1033] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1034] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
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
// __mem() unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    // unsigned int result
    // [1035] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
    lda #<0
    sta result
    sta result+1
    // asm
    // asm { ldxdevice ldyoffset stzresult+1 jsrCX16_I2C_READ_BYTE staresult rolresult+1  }
    ldx device
    ldy offset
    stz result+1
    jsr CX16_I2C_READ_BYTE
    sta result
    rol result+1
    // return result;
    // [1037] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1038] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1039] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    .label return = printf_uint.uvalue
}
.segment Code
  // smc_get_version_text
/**
 * @brief Detect and write the SMC version number into the info_text.
 * 
 * @param version_string The string containing the SMC version filled upon return.
 */
// unsigned long smc_get_version_text(__zp($40) char *version_string, __mem() char release, __mem() char major, __mem() char minor)
smc_get_version_text: {
    .label version_string = $40
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1041] snprintf_init::s#6 = smc_get_version_text::version_string#2
    // [1042] call snprintf_init
    // [1167] phi from smc_get_version_text to snprintf_init [phi:smc_get_version_text->snprintf_init]
    // [1167] phi snprintf_init::s#33 = snprintf_init::s#6 [phi:smc_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // smc_get_version_text::@1
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1043] printf_uchar::uvalue#10 = smc_get_version_text::release#2
    // [1044] call printf_uchar
    // [1307] phi from smc_get_version_text::@1 to printf_uchar [phi:smc_get_version_text::@1->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:smc_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:smc_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:smc_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:smc_get_version_text::@1->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#10 [phi:smc_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1045] phi from smc_get_version_text::@1 to smc_get_version_text::@2 [phi:smc_get_version_text::@1->smc_get_version_text::@2]
    // smc_get_version_text::@2
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1046] call printf_str
    // [1172] phi from smc_get_version_text::@2 to printf_str [phi:smc_get_version_text::@2->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = smc_get_version_text::s [phi:smc_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@3
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1047] printf_uchar::uvalue#11 = smc_get_version_text::major#2 -- vbum1=vbum2 
    lda major
    sta printf_uchar.uvalue
    // [1048] call printf_uchar
    // [1307] phi from smc_get_version_text::@3 to printf_uchar [phi:smc_get_version_text::@3->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:smc_get_version_text::@3->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:smc_get_version_text::@3->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:smc_get_version_text::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:smc_get_version_text::@3->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#11 [phi:smc_get_version_text::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1049] phi from smc_get_version_text::@3 to smc_get_version_text::@4 [phi:smc_get_version_text::@3->smc_get_version_text::@4]
    // smc_get_version_text::@4
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1050] call printf_str
    // [1172] phi from smc_get_version_text::@4 to printf_str [phi:smc_get_version_text::@4->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_get_version_text::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = smc_get_version_text::s [phi:smc_get_version_text::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@5
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1051] printf_uchar::uvalue#12 = smc_get_version_text::minor#2 -- vbum1=vbum2 
    lda minor
    sta printf_uchar.uvalue
    // [1052] call printf_uchar
    // [1307] phi from smc_get_version_text::@5 to printf_uchar [phi:smc_get_version_text::@5->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:smc_get_version_text::@5->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:smc_get_version_text::@5->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:smc_get_version_text::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:smc_get_version_text::@5->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#12 [phi:smc_get_version_text::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_get_version_text::@6
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1053] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1054] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_get_version_text::@return
    // }
    // [1056] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
    release: .byte 0
    major: .byte 0
    minor: .byte 0
}
.segment CodeVera
  // main_vera_detect
main_vera_detect: {
    // [1058] phi from main_vera_detect to main_vera_detect::@1 [phi:main_vera_detect->main_vera_detect::@1]
    // main_vera_detect::@1
    // display_chip_vera()
    // [1059] call display_chip_vera
    // [908] phi from main_vera_detect::@1 to display_chip_vera [phi:main_vera_detect::@1->display_chip_vera]
    jsr display_chip_vera
    // [1060] phi from main_vera_detect::@1 to main_vera_detect::@2 [phi:main_vera_detect::@1->main_vera_detect::@2]
    // main_vera_detect::@2
    // display_info_vera(STATUS_DETECTED, NULL)
    // [1061] call display_info_vera
    // [968] phi from main_vera_detect::@2 to display_info_vera [phi:main_vera_detect::@2->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = 0 [phi:main_vera_detect::@2->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_detect::@2->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_detect::@2->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_detect::@2->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_DETECTED [phi:main_vera_detect::@2->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_detect::@return
    // }
    // [1062] return 
    rts
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__14 = $3c
    .label rom_detect__19 = $51
    .label rom_detect__20 = $5c
    .label rom_detect__23 = $78
    .label rom_detect__26 = $34
    .label rom_detect__29 = $3b
    // [1064] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [1064] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [1064] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vdum1=vduc1 
    sta rom_detect_address
    sta rom_detect_address+1
    lda #<0>>$10
    sta rom_detect_address+2
    lda #>0>>$10
    sta rom_detect_address+3
  // Ensure the ROM is set to BASIC.
  // bank_set_brom(4);
    // rom_detect::@1
  __b1:
    // for (unsigned long rom_detect_address = 0; rom_detect_address < 8 * 0x80000; rom_detect_address += 0x80000)
    // [1065] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vdum1_lt_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>8*$80000>>$10
    bcc __b2
    bne !+
    lda rom_detect_address+2
    cmp #<8*$80000>>$10
    bcc __b2
    bne !+
    lda rom_detect_address+1
    cmp #>8*$80000
    bcc __b2
    bne !+
    lda rom_detect_address
    cmp #<8*$80000
    bcc __b2
  !:
    // rom_detect::@return
    // }
    // [1066] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [1067] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [1068] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // if (rom_detect_address == 0x0)
    // [1069] if(rom_detect::rom_detect_address#10!=0) goto rom_detect::@3 -- vdum1_neq_0_then_la1 
    lda rom_detect_address
    ora rom_detect_address+1
    ora rom_detect_address+2
    ora rom_detect_address+3
    bne __b3
    // rom_detect::@14
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [1070] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [1071] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@3
  __b3:
    // if (rom_detect_address == 0x80000)
    // [1072] if(rom_detect::rom_detect_address#10!=$80000) goto rom_detect::@4 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$80000>>$10
    bne __b4
    lda rom_detect_address+2
    cmp #<$80000>>$10
    bne __b4
    lda rom_detect_address+1
    cmp #>$80000
    bne __b4
    lda rom_detect_address
    cmp #<$80000
    bne __b4
    // rom_detect::@15
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [1073] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [1074] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@4
  __b4:
    // if (rom_detect_address == 0x100000)
    // [1075] if(rom_detect::rom_detect_address#10!=$100000) goto rom_detect::@5 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$100000>>$10
    bne __b5
    lda rom_detect_address+2
    cmp #<$100000>>$10
    bne __b5
    lda rom_detect_address+1
    cmp #>$100000
    bne __b5
    lda rom_detect_address
    cmp #<$100000
    bne __b5
    // rom_detect::@16
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [1076] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF020A
    // [1077] rom_device_ids[rom_detect::rom_chip#10] = $b6 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b6
    sta rom_device_ids,y
    // rom_detect::@5
  __b5:
    // if (rom_detect_address == 0x180000)
    // [1078] if(rom_detect::rom_detect_address#10!=$180000) goto rom_detect::@6 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$180000>>$10
    bne __b6
    lda rom_detect_address+2
    cmp #<$180000>>$10
    bne __b6
    lda rom_detect_address+1
    cmp #>$180000
    bne __b6
    lda rom_detect_address
    cmp #<$180000
    bne __b6
    // rom_detect::@17
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [1079] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF010A
    // [1080] rom_device_ids[rom_detect::rom_chip#10] = $b5 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b5
    sta rom_device_ids,y
    // rom_detect::@6
  __b6:
    // if (rom_detect_address == 0x200000)
    // [1081] if(rom_detect::rom_detect_address#10!=$200000) goto rom_detect::@7 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$200000>>$10
    bne __b7
    lda rom_detect_address+2
    cmp #<$200000>>$10
    bne __b7
    lda rom_detect_address+1
    cmp #>$200000
    bne __b7
    lda rom_detect_address
    cmp #<$200000
    bne __b7
    // rom_detect::@18
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [1082] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [1083] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // if (rom_detect_address == 0x280000)
    // [1084] if(rom_detect::rom_detect_address#10!=$280000) goto rom_detect::bank_set_brom1 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$280000>>$10
    bne bank_set_brom1
    lda rom_detect_address+2
    cmp #<$280000>>$10
    bne bank_set_brom1
    lda rom_detect_address+1
    cmp #>$280000
    bne bank_set_brom1
    lda rom_detect_address
    cmp #<$280000
    bne bank_set_brom1
    // rom_detect::@19
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [1085] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [1086] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::bank_set_brom1
  bank_set_brom1:
    // BROM = bank
    // [1087] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@22
    // rom_chip*3
    // [1088] rom_detect::$19 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z rom_detect__19
    // [1089] rom_detect::$14 = rom_detect::$19 + rom_detect::rom_chip#10 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z rom_detect__19
    sta.z rom_detect__14
    // gotoxy(rom_chip*3+40, 1)
    // [1090] gotoxy::x#31 = rom_detect::$14 + $28 -- vbum1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__14
    sta gotoxy.x
    // [1091] call gotoxy
    // [772] phi from rom_detect::@22 to gotoxy [phi:rom_detect::@22->gotoxy]
    // [772] phi gotoxy::y#38 = 1 [phi:rom_detect::@22->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = gotoxy::x#31 [phi:rom_detect::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@23
    // printf("%02x", rom_device_ids[rom_chip])
    // [1092] printf_uchar::uvalue#17 = rom_device_ids[rom_detect::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta printf_uchar.uvalue
    // [1093] call printf_uchar
    // [1307] phi from rom_detect::@23 to printf_uchar [phi:rom_detect::@23->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:rom_detect::@23->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 2 [phi:rom_detect::@23->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &cputc [phi:rom_detect::@23->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:rom_detect::@23->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#17 [phi:rom_detect::@23->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@24
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [1094] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@8 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip
    lda rom_device_ids,y
    cmp #$b5
    bne !__b8+
    jmp __b8
  !__b8:
    // rom_detect::@20
    // case SST39SF020A:
    //             rom_device_names[rom_chip] = "f020a";
    //             rom_size_strings[rom_chip] = "256";
    //             rom_sizes[rom_chip] = 256 * 1024;
    //             break;
    // [1095] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@9 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b6
    bne !__b9+
    jmp __b9
  !__b9:
    // rom_detect::@21
    // case SST39SF040:
    //             rom_device_names[rom_chip] = "f040";
    //             rom_size_strings[rom_chip] = "512";
    //             rom_sizes[rom_chip] = 512 * 1024;
    //             break;
    // [1096] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@10 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b10
    // rom_detect::@11
    // rom_manufacturer_ids[rom_chip] = 0
    // [1097] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [1098] rom_device_names[rom_detect::$19] = rom_detect::$36 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__19
    lda #<rom_detect__36
    sta rom_device_names,y
    lda #>rom_detect__36
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [1099] rom_size_strings[rom_detect::$19] = rom_detect::$37 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__37
    sta rom_size_strings,y
    lda #>rom_detect__37
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [1100] rom_detect::$29 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__29
    // [1101] rom_sizes[rom_detect::$29] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [1102] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@12
  __b12:
    // rom_chip++;
    // [1103] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@13
    // rom_detect_address += 0x80000
    // [1104] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
    clc
    lda rom_detect_address
    adc #<$80000
    sta rom_detect_address
    lda rom_detect_address+1
    adc #>$80000
    sta rom_detect_address+1
    lda rom_detect_address+2
    adc #<$80000>>$10
    sta rom_detect_address+2
    lda rom_detect_address+3
    adc #>$80000>>$10
    sta rom_detect_address+3
    // [1064] phi from rom_detect::@13 to rom_detect::@1 [phi:rom_detect::@13->rom_detect::@1]
    // [1064] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@13->rom_detect::@1#0] -- register_copy 
    // [1064] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@13->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@10
  __b10:
    // rom_device_names[rom_chip] = "f040"
    // [1105] rom_device_names[rom_detect::$19] = rom_detect::$34 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__19
    lda #<rom_detect__34
    sta rom_device_names,y
    lda #>rom_detect__34
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [1106] rom_size_strings[rom_detect::$19] = rom_detect::$35 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__35
    sta rom_size_strings,y
    lda #>rom_detect__35
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [1107] rom_detect::$26 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__26
    // [1108] rom_sizes[rom_detect::$26] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$200*$400
    sta rom_sizes,y
    lda #>$200*$400
    sta rom_sizes+1,y
    lda #<$200*$400>>$10
    sta rom_sizes+2,y
    lda #>$200*$400>>$10
    sta rom_sizes+3,y
    jmp __b12
    // rom_detect::@9
  __b9:
    // rom_device_names[rom_chip] = "f020a"
    // [1109] rom_device_names[rom_detect::$19] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__19
    lda #<rom_detect__32
    sta rom_device_names,y
    lda #>rom_detect__32
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [1110] rom_size_strings[rom_detect::$19] = rom_detect::$33 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__33
    sta rom_size_strings,y
    lda #>rom_detect__33
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [1111] rom_detect::$23 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__23
    // [1112] rom_sizes[rom_detect::$23] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$100*$400
    sta rom_sizes,y
    lda #>$100*$400
    sta rom_sizes+1,y
    lda #<$100*$400>>$10
    sta rom_sizes+2,y
    lda #>$100*$400>>$10
    sta rom_sizes+3,y
    jmp __b12
    // rom_detect::@8
  __b8:
    // rom_device_names[rom_chip] = "f010a"
    // [1113] rom_device_names[rom_detect::$19] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__19
    lda #<rom_detect__30
    sta rom_device_names,y
    lda #>rom_detect__30
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [1114] rom_size_strings[rom_detect::$19] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__31
    sta rom_size_strings,y
    lda #>rom_detect__31
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [1115] rom_detect::$20 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__20
    // [1116] rom_sizes[rom_detect::$20] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$80*$400
    sta rom_sizes,y
    lda #>$80*$400
    sta rom_sizes+1,y
    lda #<$80*$400>>$10
    sta rom_sizes+2,y
    lda #>$80*$400>>$10
    sta rom_sizes+3,y
    jmp __b12
  .segment Data
    rom_detect__30: .text "f010a"
    .byte 0
    rom_detect__31: .text "128"
    .byte 0
    rom_detect__32: .text "f020a"
    .byte 0
    rom_detect__33: .text "256"
    .byte 0
    rom_detect__34: .text "f040"
    .byte 0
    rom_detect__35: .text "512"
    .byte 0
    rom_detect__36: .text "----"
    .byte 0
    rom_detect__37: .text "000"
    .byte 0
    rom_chip: .byte 0
    rom_detect_address: .dword 0
}
.segment Code
  // smc_read
/**
 * @brief Read the SMC.BIN file into RAM_BASE.
 * The maximum size of SMC.BIN data that should be in the file is 0x1E00.
 * 
 * @return unsigned int The amount of bytes read from SMC.BIN to be flashed.
 */
// __mem() unsigned int smc_read(__mem() char info_status)
smc_read: {
    .const smc_bram_bank = 1
    .label fp = $ab
    .label smc_bram_ptr = $45
    .label smc_action_text = $76
    // if(info_status == STATUS_READING)
    // [1118] if(smc_read::info_status#10==STATUS_READING) goto smc_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [1120] phi from smc_read to smc_read::@2 [phi:smc_read->smc_read::@2]
    // [1120] phi smc_read::smc_action_text#12 = smc_action_text#2 [phi:smc_read->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z smc_action_text
    lda #>smc_action_text_1
    sta.z smc_action_text+1
    jmp __b2
    // [1119] phi from smc_read to smc_read::@1 [phi:smc_read->smc_read::@1]
    // smc_read::@1
  __b1:
    // [1120] phi from smc_read::@1 to smc_read::@2 [phi:smc_read::@1->smc_read::@2]
    // [1120] phi smc_read::smc_action_text#12 = smc_action_text#1 [phi:smc_read::@1->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z smc_action_text
    lda #>smc_action_text
    sta.z smc_action_text+1
    // smc_read::@2
  __b2:
    // smc_read::bank_set_bram1
    // BRAM = bank
    // [1121] BRAM = smc_read::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1122] phi from smc_read::bank_set_bram1 to smc_read::@16 [phi:smc_read::bank_set_bram1->smc_read::@16]
    // smc_read::@16
    // textcolor(WHITE)
    // [1123] call textcolor
    // [754] phi from smc_read::@16 to textcolor [phi:smc_read::@16->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:smc_read::@16->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1124] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // gotoxy(x, y)
    // [1125] call gotoxy
    // [772] phi from smc_read::@17 to gotoxy [phi:smc_read::@17->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y [phi:smc_read::@17->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:smc_read::@17->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1126] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1127] call fopen
    // [2276] phi from smc_read::@18 to fopen [phi:smc_read::@18->fopen]
    // [2276] phi __errno#458 = __errno#102 [phi:smc_read::@18->fopen#0] -- register_copy 
    // [2276] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@18->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2276] phi __stdio_filecount#27 = __stdio_filecount#128 [phi:smc_read::@18->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1128] fopen::return#4 = fopen::return#2
    // smc_read::@19
    // [1129] smc_read::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1130] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    bne !__b5+
    jmp __b5
  !__b5:
  !:
    // smc_read::@4
    // fgets(smc_file_header, 32, fp)
    // [1131] fgets::stream#1 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1132] call fgets
    // [2357] phi from smc_read::@4 to fgets [phi:smc_read::@4->fgets]
    // [2357] phi fgets::ptr#14 = smc_file_header [phi:smc_read::@4->fgets#0] -- pbuz1=pbuc1 
    lda #<smc_file_header
    sta.z fgets.ptr
    lda #>smc_file_header
    sta.z fgets.ptr+1
    // [2357] phi fgets::size#10 = $20 [phi:smc_read::@4->fgets#1] -- vwum1=vbuc1 
    lda #<$20
    sta fgets.size
    lda #>$20
    sta fgets.size+1
    // [2357] phi fgets::stream#4 = fgets::stream#1 [phi:smc_read::@4->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_file_header, 32, fp)
    // [1133] fgets::return#11 = fgets::return#1
    // smc_read::@20
    // smc_file_read = fgets(smc_file_header, 32, fp)
    // [1134] smc_read::smc_file_read#1 = fgets::return#11
    // if(smc_file_read)
    // [1135] if(0==smc_read::smc_file_read#1) goto smc_read::@3 -- 0_eq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    beq __b5
    // smc_read::@5
    // if(info_status == STATUS_CHECKING)
    // [1136] if(smc_read::info_status#10!=STATUS_CHECKING) goto smc_read::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b4
    // [1137] phi from smc_read::@5 to smc_read::@6 [phi:smc_read::@5->smc_read::@6]
    // smc_read::@6
    // [1138] phi from smc_read::@6 to smc_read::@7 [phi:smc_read::@6->smc_read::@7]
    // [1138] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@6->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1138] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@6->smc_read::@7#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1138] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@6->smc_read::@7#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [1138] phi smc_read::smc_bram_ptr#10 = (char *) 1024 [phi:smc_read::@6->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    jmp __b7
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // [1138] phi from smc_read::@5 to smc_read::@7 [phi:smc_read::@5->smc_read::@7]
  __b4:
    // [1138] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@5->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1138] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@5->smc_read::@7#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1138] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@5->smc_read::@7#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [1138] phi smc_read::smc_bram_ptr#10 = (char *)$a000 [phi:smc_read::@5->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // smc_read::@7
  __b7:
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1139] fgets::ptr#4 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z fgets.ptr
    lda.z smc_bram_ptr+1
    sta.z fgets.ptr+1
    // [1140] fgets::stream#2 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1141] call fgets
    // [2357] phi from smc_read::@7 to fgets [phi:smc_read::@7->fgets]
    // [2357] phi fgets::ptr#14 = fgets::ptr#4 [phi:smc_read::@7->fgets#0] -- register_copy 
    // [2357] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@7->fgets#1] -- vwum1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta fgets.size
    lda #>SMC_PROGRESS_CELL
    sta fgets.size+1
    // [2357] phi fgets::stream#4 = fgets::stream#2 [phi:smc_read::@7->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1142] fgets::return#12 = fgets::return#1
    // smc_read::@21
    // smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1143] smc_read::smc_file_read#10 = fgets::return#12
    // while (smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp))
    // [1144] if(0!=smc_read::smc_file_read#10) goto smc_read::@8 -- 0_neq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    bne __b8
    // smc_read::@9
    // fclose(fp)
    // [1145] fclose::stream#1 = smc_read::fp#0
    // [1146] call fclose
    // [2411] phi from smc_read::@9 to fclose [phi:smc_read::@9->fclose]
    // [2411] phi fclose::stream#3 = fclose::stream#1 [phi:smc_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [1147] phi from smc_read::@9 to smc_read::@3 [phi:smc_read::@9->smc_read::@3]
    // [1147] phi __stdio_filecount#39 = __stdio_filecount#2 [phi:smc_read::@9->smc_read::@3#0] -- register_copy 
    // [1147] phi smc_read::return#0 = smc_read::smc_file_size#10 [phi:smc_read::@9->smc_read::@3#1] -- register_copy 
    rts
    // [1147] phi from smc_read::@19 smc_read::@20 to smc_read::@3 [phi:smc_read::@19/smc_read::@20->smc_read::@3]
  __b5:
    // [1147] phi __stdio_filecount#39 = __stdio_filecount#1 [phi:smc_read::@19/smc_read::@20->smc_read::@3#0] -- register_copy 
    // [1147] phi smc_read::return#0 = 0 [phi:smc_read::@19/smc_read::@20->smc_read::@3#1] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@3
    // smc_read::@return
    // }
    // [1148] return 
    rts
    // smc_read::@8
  __b8:
    // display_action_text_reading(smc_action_text, "SMC.BIN", smc_file_size, SMC_CHIP_SIZE, smc_bram_bank, smc_bram_ptr)
    // [1149] display_action_text_reading::action#1 = smc_read::smc_action_text#12 -- pbuz1=pbuz2 
    lda.z smc_action_text
    sta.z display_action_text_reading.action
    lda.z smc_action_text+1
    sta.z display_action_text_reading.action+1
    // [1150] display_action_text_reading::bytes#1 = smc_read::smc_file_size#10 -- vdum1=vwum2 
    lda smc_file_size
    sta display_action_text_reading.bytes
    lda smc_file_size+1
    sta display_action_text_reading.bytes+1
    lda #0
    sta display_action_text_reading.bytes+2
    sta display_action_text_reading.bytes+3
    // [1151] display_action_text_reading::bram_ptr#1 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1152] call display_action_text_reading
    // [2440] phi from smc_read::@8 to display_action_text_reading [phi:smc_read::@8->display_action_text_reading]
    // [2440] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#1 [phi:smc_read::@8->display_action_text_reading#0] -- register_copy 
    // [2440] phi display_action_text_reading::bram_bank#10 = smc_read::smc_bram_bank [phi:smc_read::@8->display_action_text_reading#1] -- vbum1=vbuc1 
    lda #smc_bram_bank
    sta display_action_text_reading.bram_bank
    // [2440] phi display_action_text_reading::size#10 = SMC_CHIP_SIZE [phi:smc_read::@8->display_action_text_reading#2] -- vdum1=vduc1 
    lda #<SMC_CHIP_SIZE
    sta display_action_text_reading.size
    lda #>SMC_CHIP_SIZE
    sta display_action_text_reading.size+1
    lda #<SMC_CHIP_SIZE>>$10
    sta display_action_text_reading.size+2
    lda #>SMC_CHIP_SIZE>>$10
    sta display_action_text_reading.size+3
    // [2440] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#1 [phi:smc_read::@8->display_action_text_reading#3] -- register_copy 
    // [2440] phi display_action_text_reading::file#3 = smc_read::path [phi:smc_read::@8->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2440] phi display_action_text_reading::action#3 = display_action_text_reading::action#1 [phi:smc_read::@8->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // smc_read::@22
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1153] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b10
    lda progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b10
    // smc_read::@13
    // gotoxy(x, ++y);
    // [1154] smc_read::y#1 = ++ smc_read::y#12 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1155] gotoxy::y#28 = smc_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1156] call gotoxy
    // [772] phi from smc_read::@13 to gotoxy [phi:smc_read::@13->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#28 [phi:smc_read::@13->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:smc_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1157] phi from smc_read::@13 to smc_read::@10 [phi:smc_read::@13->smc_read::@10]
    // [1157] phi smc_read::y#13 = smc_read::y#1 [phi:smc_read::@13->smc_read::@10#0] -- register_copy 
    // [1157] phi smc_read::progress_row_bytes#11 = 0 [phi:smc_read::@13->smc_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1157] phi from smc_read::@22 to smc_read::@10 [phi:smc_read::@22->smc_read::@10]
    // [1157] phi smc_read::y#13 = smc_read::y#12 [phi:smc_read::@22->smc_read::@10#0] -- register_copy 
    // [1157] phi smc_read::progress_row_bytes#11 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@10#1] -- register_copy 
    // smc_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [1158] if(smc_read::info_status#10!=STATUS_READING) goto smc_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // smc_read::@14
    // cputc('.')
    // [1159] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1160] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_read::@11
  __b11:
    // if(info_status == STATUS_CHECKING)
    // [1162] if(smc_read::info_status#10==STATUS_CHECKING) goto smc_read::@12 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    beq __b6
    // smc_read::@15
    // smc_bram_ptr += smc_file_read
    // [1163] smc_read::smc_bram_ptr#3 = smc_read::smc_bram_ptr#10 + smc_read::smc_file_read#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z smc_bram_ptr
    adc smc_file_read
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    adc smc_file_read+1
    sta.z smc_bram_ptr+1
    // [1164] phi from smc_read::@15 to smc_read::@12 [phi:smc_read::@15->smc_read::@12]
    // [1164] phi smc_read::smc_bram_ptr#7 = smc_read::smc_bram_ptr#3 [phi:smc_read::@15->smc_read::@12#0] -- register_copy 
    jmp __b12
    // [1164] phi from smc_read::@11 to smc_read::@12 [phi:smc_read::@11->smc_read::@12]
  __b6:
    // [1164] phi smc_read::smc_bram_ptr#7 = (char *) 1024 [phi:smc_read::@11->smc_read::@12#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    // smc_read::@12
  __b12:
    // smc_file_size += smc_file_read
    // [1165] smc_read::smc_file_size#1 = smc_read::smc_file_size#10 + smc_read::smc_file_read#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda smc_file_size
    adc smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1166] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#11 + smc_read::smc_file_read#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_bytes
    adc smc_file_read
    sta progress_row_bytes
    lda progress_row_bytes+1
    adc smc_file_read+1
    sta progress_row_bytes+1
    // [1138] phi from smc_read::@12 to smc_read::@7 [phi:smc_read::@12->smc_read::@7]
    // [1138] phi smc_read::y#12 = smc_read::y#13 [phi:smc_read::@12->smc_read::@7#0] -- register_copy 
    // [1138] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@12->smc_read::@7#1] -- register_copy 
    // [1138] phi smc_read::smc_file_size#10 = smc_read::smc_file_size#1 [phi:smc_read::@12->smc_read::@7#2] -- register_copy 
    // [1138] phi smc_read::smc_bram_ptr#10 = smc_read::smc_bram_ptr#7 [phi:smc_read::@12->smc_read::@7#3] -- register_copy 
    jmp __b7
  .segment Data
    path: .text "SMC.BIN"
    .byte 0
    return: .word 0
    .label smc_file_read = fgets.read
    y: .byte 0
    .label smc_file_size = return
    /// Holds the amount of bytes actually read in the memory to be flashed.
    progress_row_bytes: .word 0
    info_status: .byte 0
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($40) char *s, unsigned int n)
snprintf_init: {
    .label s = $40
    // __snprintf_capacity = n
    // [1168] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [1169] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [1170] __snprintf_buffer = snprintf_init::s#33 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [1171] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($58) void (*putc)(char), __zp($47) const char *s)
printf_str: {
    .label s = $47
    .label putc = $58
    // [1173] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [1173] phi printf_str::s#88 = printf_str::s#89 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [1174] printf_str::c#1 = *printf_str::s#88 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1175] printf_str::s#0 = ++ printf_str::s#88 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1176] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [1177] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [1178] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1179] callexecute *printf_str::putc#89  -- call__deref_pprz1 
    jsr icall14
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall14:
    jmp (putc)
  .segment Data
    c: .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($35) void (*putc)(char), __zp($47) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $2d
    .label str = $47
    .label str_1 = $b2
    .label putc = $35
    // if(format.min_length)
    // [1182] if(0==printf_string::format_min_length#26) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1183] strlen::str#3 = printf_string::str#26 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1184] call strlen
    // [2471] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2471] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1185] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1186] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1187] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1188] printf_string::padding#1 = (signed char)printf_string::format_min_length#26 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1189] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1191] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1191] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1190] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1191] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1191] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1192] if(0!=printf_string::format_justify_left#26) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1193] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1194] printf_padding::putc#3 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1195] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1196] call printf_padding
    // [2477] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2477] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2477] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2477] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1197] printf_str::putc#1 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1198] printf_str::s#2 = printf_string::str#26
    // [1199] call printf_str
    // [1172] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [1172] phi printf_str::putc#89 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [1172] phi printf_str::s#89 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1200] if(0==printf_string::format_justify_left#26) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1201] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1202] printf_padding::putc#4 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1203] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1204] call printf_padding
    // [2477] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2477] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2477] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2477] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1205] return 
    rts
  .segment Data
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
    format_justify_left: .byte 0
}
.segment CodeVera
  // main_vera_check
main_vera_check: {
    .label vera_bytes_read = $cf
    // display_action_progress("Checking VERA.BIN ...")
    // [1207] call display_action_progress
    // [874] phi from main_vera_check to display_action_progress [phi:main_vera_check->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main_vera_check::info_text [phi:main_vera_check->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1208] phi from main_vera_check to main_vera_check::@4 [phi:main_vera_check->main_vera_check::@4]
    // main_vera_check::@4
    // unsigned long vera_bytes_read = vera_read(STATUS_CHECKING)
    // [1209] call vera_read
  // Read the VERA.BIN file.
    // [2485] phi from main_vera_check::@4 to vera_read [phi:main_vera_check::@4->vera_read]
    // [2485] phi __errno#100 = __errno#112 [phi:main_vera_check::@4->vera_read#0] -- register_copy 
    // [2485] phi __stdio_filecount#123 = __stdio_filecount#109 [phi:main_vera_check::@4->vera_read#1] -- register_copy 
    // [2485] phi vera_read::info_status#12 = STATUS_CHECKING [phi:main_vera_check::@4->vera_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta vera_read.info_status
    jsr vera_read
    // unsigned long vera_bytes_read = vera_read(STATUS_CHECKING)
    // [1210] vera_read::return#2 = vera_read::return#0
    // main_vera_check::@5
    // [1211] main_vera_check::vera_bytes_read#0 = vera_read::return#2 -- vduz1=vdum2 
    lda vera_read.return
    sta.z vera_bytes_read
    lda vera_read.return+1
    sta.z vera_bytes_read+1
    lda vera_read.return+2
    sta.z vera_bytes_read+2
    lda vera_read.return+3
    sta.z vera_bytes_read+3
    // wait_moment(10)
    // [1212] call wait_moment
    // [1270] phi from main_vera_check::@5 to wait_moment [phi:main_vera_check::@5->wait_moment]
    // [1270] phi wait_moment::w#13 = $a [phi:main_vera_check::@5->wait_moment#0] -- vbum1=vbuc1 
    lda #$a
    sta wait_moment.w
    jsr wait_moment
    // main_vera_check::@6
    // if (!vera_bytes_read)
    // [1213] if(0==main_vera_check::vera_bytes_read#0) goto main_vera_check::@1 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    beq __b1
    // main_vera_check::@3
    // vera_file_size = vera_bytes_read
    // [1214] vera_file_size#0 = main_vera_check::vera_bytes_read#0 -- vdum1=vduz2 
    // VF5 | VERA.BIN all ok | Display the VERA.BIN release version and github commit id (if any) and set VERA to Flash | Flash
    // We know the file size, so we indicate it in the status panel.
    lda.z vera_bytes_read
    sta vera_file_size
    lda.z vera_bytes_read+1
    sta vera_file_size+1
    lda.z vera_bytes_read+2
    sta vera_file_size+2
    lda.z vera_bytes_read+3
    sta vera_file_size+3
    // sprintf(info_text, "VERA.BIN:%s", "RELEASE TEXT TODO")
    // [1215] call snprintf_init
    // [1167] phi from main_vera_check::@3 to snprintf_init [phi:main_vera_check::@3->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main_vera_check::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1216] phi from main_vera_check::@3 to main_vera_check::@7 [phi:main_vera_check::@3->main_vera_check::@7]
    // main_vera_check::@7
    // sprintf(info_text, "VERA.BIN:%s", "RELEASE TEXT TODO")
    // [1217] call printf_str
    // [1172] phi from main_vera_check::@7 to printf_str [phi:main_vera_check::@7->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main_vera_check::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main_vera_check::s [phi:main_vera_check::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [1218] phi from main_vera_check::@7 to main_vera_check::@8 [phi:main_vera_check::@7->main_vera_check::@8]
    // main_vera_check::@8
    // sprintf(info_text, "VERA.BIN:%s", "RELEASE TEXT TODO")
    // [1219] call printf_string
    // [1181] phi from main_vera_check::@8 to printf_string [phi:main_vera_check::@8->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:main_vera_check::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = main_vera_check::str [phi:main_vera_check::@8->printf_string#1] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:main_vera_check::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:main_vera_check::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main_vera_check::@9
    // sprintf(info_text, "VERA.BIN:%s", "RELEASE TEXT TODO")
    // [1220] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1221] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_FLASH, info_text)
    // [1223] call display_info_vera
    // [968] phi from main_vera_check::@9 to display_info_vera [phi:main_vera_check::@9->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = info_text [phi:main_vera_check::@9->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_check::@9->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_check::@9->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_check::@9->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_FLASH [phi:main_vera_check::@9->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1224] phi from main_vera_check::@9 to main_vera_check::@2 [phi:main_vera_check::@9->main_vera_check::@2]
    // [1224] phi vera_file_size#1 = vera_file_size#0 [phi:main_vera_check::@9->main_vera_check::@2#0] -- register_copy 
    // main_vera_check::@2
  __b2:
    // vera_preamable_SPI()
    // [1225] call vera_preamable_SPI
    jsr vera_preamable_SPI
    // [1226] phi from main_vera_check::@2 to main_vera_check::@10 [phi:main_vera_check::@2->main_vera_check::@10]
    // main_vera_check::@10
    // wait_moment(16)
    // [1227] call wait_moment
    // [1270] phi from main_vera_check::@10 to wait_moment [phi:main_vera_check::@10->wait_moment]
    // [1270] phi wait_moment::w#13 = $10 [phi:main_vera_check::@10->wait_moment#0] -- vbum1=vbuc1 
    lda #$10
    sta wait_moment.w
    jsr wait_moment
    // main_vera_check::@return
    // }
    // [1228] return 
    rts
    // [1229] phi from main_vera_check::@6 to main_vera_check::@1 [phi:main_vera_check::@6->main_vera_check::@1]
    // main_vera_check::@1
  __b1:
    // display_info_vera(STATUS_SKIP, "No VERA.BIN")
    // [1230] call display_info_vera
  // VF1 | no VERA.BIN  | Ask the user to place the VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // VF2 | VERA.BIN size 0 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // TODO: VF4 | ROM.BIN size over 0x20000 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
    // [968] phi from main_vera_check::@1 to display_info_vera [phi:main_vera_check::@1->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = main_vera_check::info_text1 [phi:main_vera_check::@1->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_check::@1->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_check::@1->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_check::@1->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main_vera_check::@1->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1224] phi from main_vera_check::@1 to main_vera_check::@2 [phi:main_vera_check::@1->main_vera_check::@2]
    // [1224] phi vera_file_size#1 = 0 [phi:main_vera_check::@1->main_vera_check::@2#0] -- vdum1=vduc1 
    lda #<0
    sta vera_file_size
    sta vera_file_size+1
    lda #<0>>$10
    sta vera_file_size+2
    lda #>0>>$10
    sta vera_file_size+3
    jmp __b2
  .segment DataVera
    info_text: .text "Checking VERA.BIN ..."
    .byte 0
    info_text1: .text "No VERA.BIN"
    .byte 0
    s: .text "VERA.BIN:"
    .byte 0
    str: .text "RELEASE TEXT TODO"
    .byte 0
}
.segment Code
  // smc_supported_rom
/**
 * @brief Search in the smc file header for supported ROM.BIN releases.
 * The first 3 bytes of the smc file header contain the SMC.BIN version, major and minor numbers.
 * 
 * @param rom_release The ROM release to search for.
 * @return unsigned char true if found.
 */
// __mem() char smc_supported_rom(__mem() char rom_release)
smc_supported_rom: {
    // [1232] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [1232] phi smc_supported_rom::i#2 = $1f [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbum1=vbuc1 
    lda #$1f
    sta i
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=31; i>3; i--)
    // [1233] if(smc_supported_rom::i#2>=3+1) goto smc_supported_rom::@2 -- vbum1_ge_vbuc1_then_la1 
    lda i
    cmp #3+1
    bcs __b2
    // [1235] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [1235] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_file_header[i] == rom_release)
    // [1234] if(smc_file_header[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbum1_neq_vbum2_then_la1 
    lda rom_release
    ldy i
    cmp smc_file_header,y
    bne __b3
    // [1235] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [1235] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // smc_supported_rom::@return
    // }
    // [1236] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=31; i>3; i--)
    // [1237] smc_supported_rom::i#1 = -- smc_supported_rom::i#2 -- vbum1=_dec_vbum1 
    dec i
    // [1232] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [1232] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    return: .byte 0
    rom_release: .byte 0
}
.segment Code
  // check_status_roms
/**
 * @brief Check the status of all the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
// __mem() char check_status_roms(__mem() char status)
check_status_roms: {
    .label check_status_rom1_check_status_roms__0 = $51
    // [1239] phi from check_status_roms to check_status_roms::@1 [phi:check_status_roms->check_status_roms::@1]
    // [1239] phi check_status_roms::rom_chip#2 = 0 [phi:check_status_roms->check_status_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1240] if(check_status_roms::rom_chip#2<8) goto check_status_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1241] phi from check_status_roms::@1 to check_status_roms::@return [phi:check_status_roms::@1->check_status_roms::@return]
    // [1241] phi check_status_roms::return#2 = 0 [phi:check_status_roms::@1->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_roms::@return
    // }
    // [1242] return 
    rts
    // check_status_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1243] check_status_roms::check_status_rom1_$0 = status_rom[check_status_roms::rom_chip#2] == check_status_roms::status#6 -- vboz1=pbuc1_derefidx_vbum2_eq_vbum3 
    lda status
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1244] check_status_roms::check_status_rom1_return#0 = (char)check_status_roms::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1245] if(0==check_status_roms::check_status_rom1_return#0) goto check_status_roms::@2 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [1241] phi from check_status_roms::@3 to check_status_roms::@return [phi:check_status_roms::@3->check_status_roms::@return]
    // [1241] phi check_status_roms::return#2 = 1 [phi:check_status_roms::@3->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_roms::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1246] check_status_roms::rom_chip#1 = ++ check_status_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1239] phi from check_status_roms::@2 to check_status_roms::@1 [phi:check_status_roms::@2->check_status_roms::@1]
    // [1239] phi check_status_roms::rom_chip#2 = check_status_roms::rom_chip#1 [phi:check_status_roms::@2->check_status_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    check_status_rom1_return: .byte 0
    rom_chip: .byte 0
    return: .byte 0
    status: .byte 0
}
.segment Code
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $3c
    .label clrscr__1 = $3b
    .label clrscr__2 = $34
    // unsigned int line_text = __conio.mapbase_offset
    // [1247] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1248] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1249] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1250] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1251] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1252] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1252] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1252] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1253] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1254] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1255] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1256] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1257] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1258] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1258] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1259] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1260] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1261] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1262] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1263] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1264] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1265] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1266] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1267] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1268] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1269] return 
    rts
  .segment Data
    .label line_text = ch
    l: .byte 0
    ch: .word 0
    c: .byte 0
}
.segment Code
  // wait_moment
/**
 * @brief 
 * 
 */
// void wait_moment(__mem() char w)
wait_moment: {
    // [1271] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1271] phi wait_moment::j#2 = 0 [phi:wait_moment->wait_moment::@1#0] -- vbum1=vbuc1 
    lda #0
    sta j
    // wait_moment::@1
  __b1:
    // for(unsigned char j=0; j<w; j++)
    // [1272] if(wait_moment::j#2<wait_moment::w#13) goto wait_moment::@2 -- vbum1_lt_vbum2_then_la1 
    lda j
    cmp w
    bcc __b4
    // wait_moment::@return
    // }
    // [1273] return 
    rts
    // [1274] phi from wait_moment::@1 to wait_moment::@2 [phi:wait_moment::@1->wait_moment::@2]
  __b4:
    // [1274] phi wait_moment::i#2 = $ffff [phi:wait_moment::@1->wait_moment::@2#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta i
    lda #>$ffff
    sta i+1
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1275] if(wait_moment::i#2>0) goto wait_moment::@3 -- vwum1_gt_0_then_la1 
    lda i+1
    bne __b3
    lda i
    bne __b3
  !:
    // wait_moment::@4
    // for(unsigned char j=0; j<w; j++)
    // [1276] wait_moment::j#1 = ++ wait_moment::j#2 -- vbum1=_inc_vbum1 
    inc j
    // [1271] phi from wait_moment::@4 to wait_moment::@1 [phi:wait_moment::@4->wait_moment::@1]
    // [1271] phi wait_moment::j#2 = wait_moment::j#1 [phi:wait_moment::@4->wait_moment::@1#0] -- register_copy 
    jmp __b1
    // wait_moment::@3
  __b3:
    // for(unsigned int i=65535; i>0; i--)
    // [1277] wait_moment::i#1 = -- wait_moment::i#2 -- vwum1=_dec_vwum1 
    lda i
    bne !+
    dec i+1
  !:
    dec i
    // [1274] phi from wait_moment::@3 to wait_moment::@2 [phi:wait_moment::@3->wait_moment::@2]
    // [1274] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@3->wait_moment::@2#0] -- register_copy 
    jmp __b2
  .segment Data
    i: .word 0
    j: .byte 0
    w: .byte 0
}
.segment Code
  // system_reset
/**
 * @brief 
 * 
 */
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [1279] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1280] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1282] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
    // system_reset::@1
  __b1:
    jmp __b1
}
  // check_status_roms_less
/**
 * @brief Check the status of all the ROMs mutually.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if all chips are equal to the status.
 */
// __mem() char check_status_roms_less(char status)
check_status_roms_less: {
    .label check_status_rom1_check_status_roms_less__0 = $78
    // [1284] phi from check_status_roms_less to check_status_roms_less::@1 [phi:check_status_roms_less->check_status_roms_less::@1]
    // [1284] phi check_status_roms_less::rom_chip#2 = 0 [phi:check_status_roms_less->check_status_roms_less::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms_less::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1285] if(check_status_roms_less::rom_chip#2<8) goto check_status_roms_less::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1286] phi from check_status_roms_less::@1 to check_status_roms_less::@return [phi:check_status_roms_less::@1->check_status_roms_less::@return]
    // [1286] phi check_status_roms_less::return#2 = 1 [phi:check_status_roms_less::@1->check_status_roms_less::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // check_status_roms_less::@return
    // }
    // [1287] return 
    rts
    // check_status_roms_less::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1288] check_status_roms_less::check_status_rom1_$0 = status_rom[check_status_roms_less::rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms_less__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1289] check_status_roms_less::check_status_rom1_return#0 = (char)check_status_roms_less::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_roms_less::@3
    // if(check_status_rom(rom_chip, status) > status)
    // [1290] if(check_status_roms_less::check_status_rom1_return#0<STATUS_SKIP+1) goto check_status_roms_less::@2 -- vbum1_lt_vbuc1_then_la1 
    cmp #STATUS_SKIP+1
    bcc __b2
    // [1286] phi from check_status_roms_less::@3 to check_status_roms_less::@return [phi:check_status_roms_less::@3->check_status_roms_less::@return]
    // [1286] phi check_status_roms_less::return#2 = 0 [phi:check_status_roms_less::@3->check_status_roms_less::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // check_status_roms_less::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1291] check_status_roms_less::rom_chip#1 = ++ check_status_roms_less::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1284] phi from check_status_roms_less::@2 to check_status_roms_less::@1 [phi:check_status_roms_less::@2->check_status_roms_less::@1]
    // [1284] phi check_status_roms_less::rom_chip#2 = check_status_roms_less::rom_chip#1 [phi:check_status_roms_less::@2->check_status_roms_less::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    check_status_rom1_return: .byte 0
    rom_chip: .byte 0
    return: .byte 0
}
.segment Code
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($58) char **text, __mem() char lines)
display_progress_text: {
    .label display_progress_text__3 = $5c
    .label text = $58
    // display_progress_clear()
    // [1293] call display_progress_clear
    // [888] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [1294] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [1294] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [1295] if(display_progress_text::l#2<display_progress_text::lines#12) goto display_progress_text::@2 -- vbum1_lt_vbum2_then_la1 
    lda l
    cmp lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [1296] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [1297] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbum2_rol_1 
    lda l
    asl
    sta.z display_progress_text__3
    // [1298] display_progress_line::line#0 = display_progress_text::l#2 -- vbum1=vbum2 
    lda l
    sta display_progress_line.line
    // [1299] display_progress_line::text#0 = display_progress_text::text#13[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [1300] call display_progress_line
    // [1302] phi from display_progress_text::@2 to display_progress_line [phi:display_progress_text::@2->display_progress_line]
    // [1302] phi display_progress_line::text#3 = display_progress_line::text#0 [phi:display_progress_text::@2->display_progress_line#0] -- register_copy 
    // [1302] phi display_progress_line::line#3 = display_progress_line::line#0 [phi:display_progress_text::@2->display_progress_line#1] -- register_copy 
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [1301] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [1294] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [1294] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    l: .byte 0
    lines: .byte 0
}
.segment Code
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__mem() char line, __zp($56) char *text)
display_progress_line: {
    .label text = $56
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1303] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#3 -- vbum1=vbuc1_plus_vbum1 
    lda #PROGRESS_Y
    clc
    adc cputsxy.y
    sta cputsxy.y
    // [1304] cputsxy::s#0 = display_progress_line::text#3
    // [1305] call cputsxy
    // [867] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [867] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [867] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [867] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1306] return 
    rts
  .segment Data
    .label line = cputsxy.y
}
.segment Code
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($58) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $58
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1308] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1309] uctoa::value#1 = printf_uchar::uvalue#21
    // [1310] uctoa::radix#0 = printf_uchar::format_radix#21
    // [1311] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1312] printf_number_buffer::putc#2 = printf_uchar::putc#21
    // [1313] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1314] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#21
    // [1315] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#21
    // [1316] call printf_number_buffer
  // Print using format
    // [2622] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [2622] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [2622] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [2622] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [2622] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1317] return 
    rts
  .segment Data
    .label uvalue = smc_get_version_text.release
    format_radix: .byte 0
    format_min_length: .byte 0
    format_zero_padding: .byte 0
}
.segment Code
  // display_action_text
/**
 * @brief Print an info line at the action frame, which is the second line.
 * 
 * @param info_text The info text to be displayed.
 */
// void display_action_text(__zp($35) char *info_text)
display_action_text: {
    .label info_text = $35
    // unsigned char x = wherex()
    // [1319] call wherex
    jsr wherex
    // [1320] wherex::return#3 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_1
    // display_action_text::@1
    // [1321] display_action_text::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [1322] call wherey
    jsr wherey
    // [1323] wherey::return#3 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_1
    // display_action_text::@2
    // [1324] display_action_text::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [1325] call gotoxy
    // [772] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1326] printf_string::str#2 = display_action_text::info_text#23 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1327] call printf_string
    // [1181] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1328] gotoxy::x#17 = display_action_text::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1329] gotoxy::y#17 = display_action_text::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1330] call gotoxy
    // [772] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#17 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#17 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1331] return 
    rts
  .segment Data
    .label x = wherex.return_1
    .label y = wherey.return_1
}
.segment Code
  // smc_reset
/**
 * @brief Shut down the CX16 through an SMC reboot.
 * The CX16 can be restarted using the POWER button on the CX16 board.
 * But this function can only be called once the SMC has flashed.
 * Otherwise, the SMC will get corrupted.
 * 
 */
smc_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // smc_reset::bank_set_bram1
    // BRAM = bank
    // [1333] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1334] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@1
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1335] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1336] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1337] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1338] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // smc_reset::@return
    // }
    // [1340] return 
    rts
  .segment Data
    cx16_k_i2c_write_byte1_device: .byte 0
    cx16_k_i2c_write_byte1_offset: .byte 0
    cx16_k_i2c_write_byte1_value: .byte 0
    cx16_k_i2c_write_byte1_result: .byte 0
}
.segment Code
  // check_status_card_roms
/**
 * @brief Check the status of all card ROMs. 
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
// __mem() char check_status_card_roms(char status)
check_status_card_roms: {
    .label check_status_rom1_check_status_card_roms__0 = $3b
    // [1342] phi from check_status_card_roms to check_status_card_roms::@1 [phi:check_status_card_roms->check_status_card_roms::@1]
    // [1342] phi check_status_card_roms::rom_chip#2 = 1 [phi:check_status_card_roms->check_status_card_roms::@1#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip
    // check_status_card_roms::@1
  __b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1343] if(check_status_card_roms::rom_chip#2<8) goto check_status_card_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1344] phi from check_status_card_roms::@1 to check_status_card_roms::@return [phi:check_status_card_roms::@1->check_status_card_roms::@return]
    // [1344] phi check_status_card_roms::return#2 = 0 [phi:check_status_card_roms::@1->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_card_roms::@return
    // }
    // [1345] return 
    rts
    // check_status_card_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1346] check_status_card_roms::check_status_rom1_$0 = status_rom[check_status_card_roms::rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_card_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1347] check_status_card_roms::check_status_rom1_return#0 = (char)check_status_card_roms::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_card_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1348] if(0==check_status_card_roms::check_status_rom1_return#0) goto check_status_card_roms::@2 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [1344] phi from check_status_card_roms::@3 to check_status_card_roms::@return [phi:check_status_card_roms::@3->check_status_card_roms::@return]
    // [1344] phi check_status_card_roms::return#2 = 1 [phi:check_status_card_roms::@3->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_card_roms::@2
  __b2:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1349] check_status_card_roms::rom_chip#1 = ++ check_status_card_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1342] phi from check_status_card_roms::@2 to check_status_card_roms::@1 [phi:check_status_card_roms::@2->check_status_card_roms::@1]
    // [1342] phi check_status_card_roms::rom_chip#2 = check_status_card_roms::rom_chip#1 [phi:check_status_card_roms::@2->check_status_card_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    check_status_rom1_return: .byte 0
    rom_chip: .byte 0
    return: .byte 0
}
.segment Code
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [1351] call util_wait_key
    // [1884] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1884] phi util_wait_key::filter#13 = filter [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1884] phi util_wait_key::info_text#3 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [1352] return 
    rts
  .segment Data
    info_text: .text "Press [SPACE] to continue ..."
    .byte 0
}
.segment CodeVera
  // main_vera_flash
main_vera_flash: {
    .label vera_bytes_read = $cf
    .label vera_differences1 = $ed
    // display_progress_clear()
    // [1354] call display_progress_clear
    // [888] phi from main_vera_flash to display_progress_clear [phi:main_vera_flash->display_progress_clear]
    jsr display_progress_clear
    // [1355] phi from main_vera_flash to main_vera_flash::@9 [phi:main_vera_flash->main_vera_flash::@9]
    // main_vera_flash::@9
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1356] call snprintf_init
    // [1167] phi from main_vera_flash::@9 to snprintf_init [phi:main_vera_flash::@9->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main_vera_flash::@9->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1357] phi from main_vera_flash::@9 to main_vera_flash::@10 [phi:main_vera_flash::@9->main_vera_flash::@10]
    // main_vera_flash::@10
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1358] call printf_str
    // [1172] phi from main_vera_flash::@10 to printf_str [phi:main_vera_flash::@10->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main_vera_flash::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main_vera_flash::s [phi:main_vera_flash::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@11
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1359] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1360] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [1362] call display_action_progress
    // [874] phi from main_vera_flash::@11 to display_action_progress [phi:main_vera_flash::@11->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = info_text [phi:main_vera_flash::@11->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1363] phi from main_vera_flash::@11 to main_vera_flash::@12 [phi:main_vera_flash::@11->main_vera_flash::@12]
    // main_vera_flash::@12
    // unsigned long vera_bytes_read = vera_read(STATUS_READING)
    // [1364] call vera_read
    // [2485] phi from main_vera_flash::@12 to vera_read [phi:main_vera_flash::@12->vera_read]
    // [2485] phi __errno#100 = __errno#114 [phi:main_vera_flash::@12->vera_read#0] -- register_copy 
    // [2485] phi __stdio_filecount#123 = __stdio_filecount#111 [phi:main_vera_flash::@12->vera_read#1] -- register_copy 
    // [2485] phi vera_read::info_status#12 = STATUS_READING [phi:main_vera_flash::@12->vera_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta vera_read.info_status
    jsr vera_read
    // unsigned long vera_bytes_read = vera_read(STATUS_READING)
    // [1365] vera_read::return#3 = vera_read::return#0
    // main_vera_flash::@13
    // [1366] main_vera_flash::vera_bytes_read#0 = vera_read::return#3 -- vduz1=vdum2 
    lda vera_read.return
    sta.z vera_bytes_read
    lda vera_read.return+1
    sta.z vera_bytes_read+1
    lda vera_read.return+2
    sta.z vera_bytes_read+2
    lda vera_read.return+3
    sta.z vera_bytes_read+3
    // if(vera_bytes_read)
    // [1367] if(0==main_vera_flash::vera_bytes_read#0) goto main_vera_flash::@1 -- 0_eq_vduz1_then_la1 
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    bne !__b1+
    jmp __b1
  !__b1:
    // [1368] phi from main_vera_flash::@13 to main_vera_flash::@2 [phi:main_vera_flash::@13->main_vera_flash::@2]
    // main_vera_flash::@2
    // display_action_progress("Comparing VERA ... (.) data, (=) same, (*) different.")
    // [1369] call display_action_progress
  // Now we compare the RAM with the actual VERA contents.
    // [874] phi from main_vera_flash::@2 to display_action_progress [phi:main_vera_flash::@2->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main_vera_flash::info_text [phi:main_vera_flash::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1370] phi from main_vera_flash::@2 to main_vera_flash::@14 [phi:main_vera_flash::@2->main_vera_flash::@14]
    // main_vera_flash::@14
    // display_info_vera(STATUS_COMPARING, NULL)
    // [1371] call display_info_vera
    // [968] phi from main_vera_flash::@14 to display_info_vera [phi:main_vera_flash::@14->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = 0 [phi:main_vera_flash::@14->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_flash::@14->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_flash::@14->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_flash::@14->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_COMPARING [phi:main_vera_flash::@14->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1372] phi from main_vera_flash::@14 to main_vera_flash::@15 [phi:main_vera_flash::@14->main_vera_flash::@15]
    // main_vera_flash::@15
    // unsigned long vera_differences = vera_verify()
    // [1373] call vera_verify
  // Verify VERA ...
    // [2653] phi from main_vera_flash::@15 to vera_verify [phi:main_vera_flash::@15->vera_verify]
    jsr vera_verify
    // unsigned long vera_differences = vera_verify()
    // [1374] vera_verify::return#2 = vera_verify::vera_different_bytes#11
    // main_vera_flash::@16
    // [1375] main_vera_flash::vera_differences#0 = vera_verify::return#2 -- vdum1=vdum2 
    lda vera_verify.return
    sta vera_differences
    lda vera_verify.return+1
    sta vera_differences+1
    lda vera_verify.return+2
    sta vera_differences+2
    lda vera_verify.return+3
    sta vera_differences+3
    // if (!vera_differences)
    // [1376] if(0==main_vera_flash::vera_differences#0) goto main_vera_flash::@4 -- 0_eq_vdum1_then_la1 
    lda vera_differences
    ora vera_differences+1
    ora vera_differences+2
    ora vera_differences+3
    bne !__b4+
    jmp __b4
  !__b4:
    // [1377] phi from main_vera_flash::@16 to main_vera_flash::@3 [phi:main_vera_flash::@16->main_vera_flash::@3]
    // main_vera_flash::@3
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1378] call snprintf_init
    // [1167] phi from main_vera_flash::@3 to snprintf_init [phi:main_vera_flash::@3->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main_vera_flash::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@17
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1379] printf_ulong::uvalue#10 = main_vera_flash::vera_differences#0 -- vdum1=vdum2 
    lda vera_differences
    sta printf_ulong.uvalue
    lda vera_differences+1
    sta printf_ulong.uvalue+1
    lda vera_differences+2
    sta printf_ulong.uvalue+2
    lda vera_differences+3
    sta printf_ulong.uvalue+3
    // [1380] call printf_ulong
    // [1628] phi from main_vera_flash::@17 to printf_ulong [phi:main_vera_flash::@17->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:main_vera_flash::@17->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:main_vera_flash::@17->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@17->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#10 [phi:main_vera_flash::@17->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1381] phi from main_vera_flash::@17 to main_vera_flash::@18 [phi:main_vera_flash::@17->main_vera_flash::@18]
    // main_vera_flash::@18
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1382] call printf_str
    // [1172] phi from main_vera_flash::@18 to printf_str [phi:main_vera_flash::@18->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main_vera_flash::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s13 [phi:main_vera_flash::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@19
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1383] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1384] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_FLASH, info_text)
    // [1386] call display_info_vera
    // [968] phi from main_vera_flash::@19 to display_info_vera [phi:main_vera_flash::@19->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@19->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_flash::@19->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_flash::@19->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_flash::@19->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_FLASH [phi:main_vera_flash::@19->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1387] phi from main_vera_flash::@19 to main_vera_flash::@20 [phi:main_vera_flash::@19->main_vera_flash::@20]
    // main_vera_flash::@20
    // unsigned char vera_erase_error = vera_erase()
    // [1388] call vera_erase
    jsr vera_erase
    // [1389] phi from main_vera_flash::@20 to main_vera_flash::@5 [phi:main_vera_flash::@20->main_vera_flash::@5]
    // main_vera_flash::@5
    // unsigned long vera_flashed = vera_flash()
    // [1390] call vera_flash
    // [2719] phi from main_vera_flash::@5 to vera_flash [phi:main_vera_flash::@5->vera_flash]
    jsr vera_flash
    // unsigned long vera_flashed = vera_flash()
    // [1391] vera_flash::return#3 = vera_flash::return#2
    // main_vera_flash::@21
    // [1392] main_vera_flash::vera_flashed#0 = vera_flash::return#3 -- vdum1=vdum2 
    lda vera_flash.return
    sta vera_flashed
    lda vera_flash.return+1
    sta vera_flashed+1
    lda vera_flash.return+2
    sta vera_flashed+2
    lda vera_flash.return+3
    sta vera_flashed+3
    // if(vera_flashed)
    // [1393] if(0!=main_vera_flash::vera_flashed#0) goto main_vera_flash::@6 -- 0_neq_vdum1_then_la1 
    lda vera_flashed
    ora vera_flashed+1
    ora vera_flashed+2
    ora vera_flashed+3
    bne __b6
    // [1394] phi from main_vera_flash::@21 to main_vera_flash::@7 [phi:main_vera_flash::@21->main_vera_flash::@7]
    // main_vera_flash::@7
    // display_info_vera(STATUS_ERROR, info_text)
    // [1395] call display_info_vera
  // VFL2 | Flash VERA resulting in errors
    // [968] phi from main_vera_flash::@7 to display_info_vera [phi:main_vera_flash::@7->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@7->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_flash::@7->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_flash::@7->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_flash::@7->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@7->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1396] phi from main_vera_flash::@7 to main_vera_flash::@30 [phi:main_vera_flash::@7->main_vera_flash::@30]
    // main_vera_flash::@30
    // display_action_progress("There was an error updating your VERA flash memory!")
    // [1397] call display_action_progress
    // [874] phi from main_vera_flash::@30 to display_action_progress [phi:main_vera_flash::@30->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = main_vera_flash::info_text5 [phi:main_vera_flash::@30->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_action_progress.info_text
    lda #>info_text5
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1398] phi from main_vera_flash::@30 to main_vera_flash::@31 [phi:main_vera_flash::@30->main_vera_flash::@31]
    // main_vera_flash::@31
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [1399] call display_action_text
    // [1318] phi from main_vera_flash::@31 to display_action_text [phi:main_vera_flash::@31->display_action_text]
    // [1318] phi display_action_text::info_text#23 = main_vera_flash::info_text3 [phi:main_vera_flash::@31->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_text.info_text
    lda #>info_text3
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1400] phi from main_vera_flash::@31 to main_vera_flash::@32 [phi:main_vera_flash::@31->main_vera_flash::@32]
    // main_vera_flash::@32
    // display_info_vera(STATUS_ERROR, "FLASH ERROR!")
    // [1401] call display_info_vera
    // [968] phi from main_vera_flash::@32 to display_info_vera [phi:main_vera_flash::@32->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = main_vera_flash::info_text7 [phi:main_vera_flash::@32->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_info_vera.info_text
    lda #>info_text7
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_flash::@32->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_flash::@32->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_flash::@32->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@32->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1402] phi from main_vera_flash::@32 to main_vera_flash::@33 [phi:main_vera_flash::@32->main_vera_flash::@33]
    // main_vera_flash::@33
    // display_info_smc(STATUS_ERROR, NULL)
    // [1403] call display_info_smc
    // [932] phi from main_vera_flash::@33 to display_info_smc [phi:main_vera_flash::@33->display_info_smc]
    // [932] phi display_info_smc::info_text#20 = 0 [phi:main_vera_flash::@33->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [932] phi smc_bootloader#14 = smc_detect::return#0 [phi:main_vera_flash::@33->display_info_smc#1] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta smc_bootloader
    lda #>smc_detect.return
    sta smc_bootloader+1
    // [932] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main_vera_flash::@33->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    // [1404] phi from main_vera_flash::@33 to main_vera_flash::@34 [phi:main_vera_flash::@33->main_vera_flash::@34]
    // main_vera_flash::@34
    // display_info_roms(STATUS_ERROR, NULL)
    // [1405] call display_info_roms
    // [2767] phi from main_vera_flash::@34 to display_info_roms [phi:main_vera_flash::@34->display_info_roms]
    jsr display_info_roms
    // [1406] phi from main_vera_flash::@34 to main_vera_flash::@35 [phi:main_vera_flash::@34->main_vera_flash::@35]
    // main_vera_flash::@35
    // wait_moment(32)
    // [1407] call wait_moment
    // [1270] phi from main_vera_flash::@35 to wait_moment [phi:main_vera_flash::@35->wait_moment]
    // [1270] phi wait_moment::w#13 = $20 [phi:main_vera_flash::@35->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [1408] phi from main_vera_flash::@35 to main_vera_flash::@36 [phi:main_vera_flash::@35->main_vera_flash::@36]
    // main_vera_flash::@36
    // spi_deselect()
    // [1409] call spi_deselect
    jsr spi_deselect
    // main_vera_flash::@return
    // }
    // [1410] return 
    rts
    // [1411] phi from main_vera_flash::@21 to main_vera_flash::@6 [phi:main_vera_flash::@21->main_vera_flash::@6]
    // main_vera_flash::@6
  __b6:
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1412] call snprintf_init
    // [1167] phi from main_vera_flash::@6 to snprintf_init [phi:main_vera_flash::@6->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main_vera_flash::@6->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@22
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1413] printf_ulong::uvalue#11 = main_vera_flash::vera_flashed#0 -- vdum1=vdum2 
    lda vera_flashed
    sta printf_ulong.uvalue
    lda vera_flashed+1
    sta printf_ulong.uvalue+1
    lda vera_flashed+2
    sta printf_ulong.uvalue+2
    lda vera_flashed+3
    sta printf_ulong.uvalue+3
    // [1414] call printf_ulong
    // [1628] phi from main_vera_flash::@22 to printf_ulong [phi:main_vera_flash::@22->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 0 [phi:main_vera_flash::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 0 [phi:main_vera_flash::@22->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#11 [phi:main_vera_flash::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1415] phi from main_vera_flash::@22 to main_vera_flash::@23 [phi:main_vera_flash::@22->main_vera_flash::@23]
    // main_vera_flash::@23
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1416] call printf_str
    // [1172] phi from main_vera_flash::@23 to printf_str [phi:main_vera_flash::@23->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main_vera_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = main_vera_flash::s2 [phi:main_vera_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@24
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1417] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1418] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_FLASHED, info_text)
    // [1420] call display_info_vera
    // [968] phi from main_vera_flash::@24 to display_info_vera [phi:main_vera_flash::@24->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@24->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_flash::@24->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_flash::@24->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_flash::@24->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_FLASHED [phi:main_vera_flash::@24->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1421] phi from main_vera_flash::@24 to main_vera_flash::@25 [phi:main_vera_flash::@24->main_vera_flash::@25]
    // main_vera_flash::@25
    // unsigned long vera_differences = vera_verify()
    // [1422] call vera_verify
    // [2653] phi from main_vera_flash::@25 to vera_verify [phi:main_vera_flash::@25->vera_verify]
    jsr vera_verify
    // unsigned long vera_differences = vera_verify()
    // [1423] vera_verify::return#3 = vera_verify::vera_different_bytes#11
    // main_vera_flash::@26
    // [1424] main_vera_flash::vera_differences1#0 = vera_verify::return#3 -- vduz1=vdum2 
    lda vera_verify.return
    sta.z vera_differences1
    lda vera_verify.return+1
    sta.z vera_differences1+1
    lda vera_verify.return+2
    sta.z vera_differences1+2
    lda vera_verify.return+3
    sta.z vera_differences1+3
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1425] call snprintf_init
    // [1167] phi from main_vera_flash::@26 to snprintf_init [phi:main_vera_flash::@26->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:main_vera_flash::@26->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@27
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1426] printf_ulong::uvalue#12 = main_vera_flash::vera_differences1#0 -- vdum1=vduz2 
    lda.z vera_differences1
    sta printf_ulong.uvalue
    lda.z vera_differences1+1
    sta printf_ulong.uvalue+1
    lda.z vera_differences1+2
    sta printf_ulong.uvalue+2
    lda.z vera_differences1+3
    sta printf_ulong.uvalue+3
    // [1427] call printf_ulong
    // [1628] phi from main_vera_flash::@27 to printf_ulong [phi:main_vera_flash::@27->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:main_vera_flash::@27->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:main_vera_flash::@27->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@27->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#12 [phi:main_vera_flash::@27->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1428] phi from main_vera_flash::@27 to main_vera_flash::@28 [phi:main_vera_flash::@27->main_vera_flash::@28]
    // main_vera_flash::@28
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1429] call printf_str
    // [1172] phi from main_vera_flash::@28 to printf_str [phi:main_vera_flash::@28->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:main_vera_flash::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s13 [phi:main_vera_flash::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@29
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1430] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1431] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_FLASHED, info_text)
    // [1433] call display_info_vera
    // [968] phi from main_vera_flash::@29 to display_info_vera [phi:main_vera_flash::@29->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@29->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_flash::@29->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_flash::@29->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_flash::@29->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_FLASHED [phi:main_vera_flash::@29->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1434] phi from main_vera_flash::@29 main_vera_flash::@4 to main_vera_flash::@8 [phi:main_vera_flash::@29/main_vera_flash::@4->main_vera_flash::@8]
    // main_vera_flash::@8
  __b8:
    // wait_moment(32)
    // [1435] call wait_moment
    // [1270] phi from main_vera_flash::@8 to wait_moment [phi:main_vera_flash::@8->wait_moment]
    // [1270] phi wait_moment::w#13 = $20 [phi:main_vera_flash::@8->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [1436] phi from main_vera_flash::@13 main_vera_flash::@8 to main_vera_flash::@1 [phi:main_vera_flash::@13/main_vera_flash::@8->main_vera_flash::@1]
    // main_vera_flash::@1
  __b1:
    // spi_deselect()
    // [1437] call spi_deselect
    jsr spi_deselect
    rts
    // [1438] phi from main_vera_flash::@16 to main_vera_flash::@4 [phi:main_vera_flash::@16->main_vera_flash::@4]
    // main_vera_flash::@4
  __b4:
    // display_info_vera(STATUS_SKIP, "No update required")
    // [1439] call display_info_vera
  // VFL1 | VERA and VERA.BIN equal | Display that there are no differences between the VERA and VERA.BIN. Set VERA to Flashed. | None
    // [968] phi from main_vera_flash::@4 to display_info_vera [phi:main_vera_flash::@4->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = info_text32 [phi:main_vera_flash::@4->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text32
    sta.z display_info_vera.info_text
    lda #>info_text32
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:main_vera_flash::@4->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:main_vera_flash::@4->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:main_vera_flash::@4->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main_vera_flash::@4->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b8
  .segment DataVera
    s: .text "Reading VERA.BIN ... (.) data ( ) empty"
    .byte 0
    info_text: .text "Comparing VERA ... (.) data, (=) same, (*) different."
    .byte 0
    info_text3: .text "DO NOT RESET or REBOOT YOUR CX16 AND WAIT!"
    .byte 0
    s2: .text " bytes flashed!"
    .byte 0
    info_text5: .text "There was an error updating your VERA flash memory!"
    .byte 0
    info_text7: .text "FLASH ERROR!"
    .byte 0
    vera_differences: .dword 0
    vera_flashed: .dword 0
}
.segment Code
  // display_info_rom
/**
 * @brief Display the ROM status of a specific rom chip. 
 * 
 * @param rom_chip The ROM chip, 0 is the main CX16 ROM chip, maximum 7 ROMs.
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_rom(__mem() char rom_chip, __mem() char info_status, __zp($37) char *info_text)
display_info_rom: {
    .label display_info_rom__6 = $34
    .label display_info_rom__15 = $78
    .label display_info_rom__16 = $3b
    .label info_text = $37
    .label display_info_rom__19 = $34
    .label display_info_rom__20 = $34
    // unsigned char x = wherex()
    // [1441] call wherex
    jsr wherex
    // [1442] wherex::return#12 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_4
    // display_info_rom::@3
    // [1443] display_info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1444] call wherey
    jsr wherey
    // [1445] wherey::return#12 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_4
    // display_info_rom::@4
    // [1446] display_info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1447] status_rom[display_info_rom::rom_chip#17] = display_info_rom::info_status#17 -- pbuc1_derefidx_vbum1=vbum2 
    lda info_status
    ldy rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1448] display_rom_led::chip#1 = display_info_rom::rom_chip#17 -- vbum1=vbum2 
    tya
    sta display_rom_led.chip
    // [1449] display_rom_led::c#1 = status_color[display_info_rom::info_status#17] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_rom_led.c
    // [1450] call display_rom_led
    // [2243] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [2243] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [2243] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1451] gotoxy::y#24 = display_info_rom::rom_chip#17 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1452] call gotoxy
    // [772] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#24 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1453] display_info_rom::$16 = display_info_rom::rom_chip#17 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z display_info_rom__16
    // rom_chip*13
    // [1454] display_info_rom::$19 = display_info_rom::$16 + display_info_rom::rom_chip#17 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z display_info_rom__16
    sta.z display_info_rom__19
    // [1455] display_info_rom::$20 = display_info_rom::$19 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z display_info_rom__20
    asl
    asl
    sta.z display_info_rom__20
    // [1456] display_info_rom::$6 = display_info_rom::$20 + display_info_rom::rom_chip#17 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z display_info_rom__6
    sta.z display_info_rom__6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1457] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta.z printf_string.str_1+1
    // [1458] call printf_str
    // [1172] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = chip [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z printf_str.s
    lda #>chip
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1459] printf_uchar::uvalue#7 = display_info_rom::rom_chip#17 -- vbum1=vbum2 
    lda rom_chip
    sta printf_uchar.uvalue
    // [1460] call printf_uchar
    // [1307] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#7 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1461] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1462] call printf_str
    // [1172] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1463] display_info_rom::$15 = display_info_rom::info_status#17 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_rom__15
    // [1464] printf_string::str#8 = status_text[display_info_rom::$15] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1465] call printf_string
    // [1181] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1466] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1467] call printf_str
    // [1172] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1468] printf_string::str#9 = rom_device_names[display_info_rom::$16] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__16
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1469] call printf_string
    // [1181] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1470] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1471] call printf_str
    // [1172] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1472] printf_string::str#41 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z printf_string.str_1
    sta.z printf_string.str
    lda.z printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1473] call printf_string
    // [1181] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#41 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = $d [phi:display_info_rom::@13->printf_string#3] -- vbum1=vbuc1 
    lda #$d
    sta printf_string.format_min_length
    jsr printf_string
    // [1474] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1475] call printf_str
    // [1172] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1476] if((char *)0==display_info_rom::info_text#17) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // gotoxy(INFO_X+64-28, INFO_Y+rom_chip+2)
    // [1477] gotoxy::y#26 = display_info_rom::rom_chip#17 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1478] call gotoxy
    // [772] phi from display_info_rom::@2 to gotoxy [phi:display_info_rom::@2->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#26 [phi:display_info_rom::@2->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = 4+$40-$1c [phi:display_info_rom::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@16
    // printf("%-25s", info_text)
    // [1479] printf_string::str#11 = display_info_rom::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1480] call printf_string
    // [1181] phi from display_info_rom::@16 to printf_string [phi:display_info_rom::@16->printf_string]
    // [1181] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#11 [phi:display_info_rom::@16->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = $19 [phi:display_info_rom::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1481] gotoxy::x#25 = display_info_rom::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1482] gotoxy::y#25 = display_info_rom::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1483] call gotoxy
    // [772] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#25 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#25 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1484] return 
    rts
  .segment Data
    .label x = wherex.return_4
    .label y = wherey.return_4
    info_status: .byte 0
    rom_chip: .byte 0
}
.segment Code
  // rom_file
// __zp($cc) char * rom_file(__mem() char rom_chip)
rom_file: {
    .label rom_file__0 = $34
    .label return = $cc
    // if(rom_chip)
    // [1486] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbum1_then_la1 
    lda rom_chip
    bne __b1
    // [1489] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1489] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_cx16
    sta.z return
    lda #>file_rom_cx16
    sta.z return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1487] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #'0'
    clc
    adc rom_chip
    sta.z rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1488] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuz1 
    sta file_rom_card+3
    // [1489] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1489] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_card
    sta.z return
    lda #>file_rom_card
    sta.z return+1
    // rom_file::@return
    // }
    // [1490] return 
    rts
  .segment Data
    file_rom_cx16: .text "ROM.BIN"
    .byte 0
    file_rom_card: .text "ROMn.BIN"
    .byte 0
    rom_chip: .byte 0
}
.segment Code
  // rom_read
// __mem() unsigned long rom_read(char rom_chip, __zp($4d) char *file, __mem() char info_status, __mem() char brom_bank_start, __mem() unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__13 = $72
    .label fp = $61
    .label rom_bram_ptr = $79
    .label file = $4d
    .label rom_action_text = $4b
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1492] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1493] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_read::@18
    // if(info_status == STATUS_READING)
    // [1494] if(rom_read::info_status#12==STATUS_READING) goto rom_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [1496] phi from rom_read::@18 to rom_read::@2 [phi:rom_read::@18->rom_read::@2]
    // [1496] phi rom_read::rom_action_text#10 = smc_action_text#2 [phi:rom_read::@18->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z rom_action_text
    lda #>smc_action_text_1
    sta.z rom_action_text+1
    jmp __b2
    // [1495] phi from rom_read::@18 to rom_read::@1 [phi:rom_read::@18->rom_read::@1]
    // rom_read::@1
  __b1:
    // [1496] phi from rom_read::@1 to rom_read::@2 [phi:rom_read::@1->rom_read::@2]
    // [1496] phi rom_read::rom_action_text#10 = smc_action_text#1 [phi:rom_read::@1->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z rom_action_text
    lda #>smc_action_text
    sta.z rom_action_text+1
    // rom_read::@2
  __b2:
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1497] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#10 -- vbum1=vbum2 
    lda brom_bank_start
    sta rom_address_from_bank.rom_bank
    // [1498] call rom_address_from_bank
    // [2777] phi from rom_read::@2 to rom_address_from_bank [phi:rom_read::@2->rom_address_from_bank]
    // [2777] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read::@2->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1499] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@20
    // [1500] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1501] call snprintf_init
    // [1167] phi from rom_read::@20 to snprintf_init [phi:rom_read::@20->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:rom_read::@20->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1502] phi from rom_read::@20 to rom_read::@21 [phi:rom_read::@20->rom_read::@21]
    // rom_read::@21
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1503] call printf_str
    // [1172] phi from rom_read::@21 to printf_str [phi:rom_read::@21->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:rom_read::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = rom_read::s [phi:rom_read::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@22
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1504] printf_string::str#17 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1505] call printf_string
    // [1181] phi from rom_read::@22 to printf_string [phi:rom_read::@22->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:rom_read::@22->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#17 [phi:rom_read::@22->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:rom_read::@22->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:rom_read::@22->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1506] phi from rom_read::@22 to rom_read::@23 [phi:rom_read::@22->rom_read::@23]
    // rom_read::@23
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1507] call printf_str
    // [1172] phi from rom_read::@23 to printf_str [phi:rom_read::@23->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:rom_read::@23->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = rom_read::s1 [phi:rom_read::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@24
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1508] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1509] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1511] call display_action_text
    // [1318] phi from rom_read::@24 to display_action_text [phi:rom_read::@24->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:rom_read::@24->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@25
    // FILE *fp = fopen(file, "r")
    // [1512] fopen::path#4 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1513] call fopen
    // [2276] phi from rom_read::@25 to fopen [phi:rom_read::@25->fopen]
    // [2276] phi __errno#458 = __errno#105 [phi:rom_read::@25->fopen#0] -- register_copy 
    // [2276] phi fopen::pathtoken#0 = fopen::path#4 [phi:rom_read::@25->fopen#1] -- register_copy 
    // [2276] phi __stdio_filecount#27 = __stdio_filecount#100 [phi:rom_read::@25->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1514] fopen::return#5 = fopen::return#2
    // rom_read::@26
    // [1515] rom_read::fp#0 = fopen::return#5 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1516] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [1517] phi from rom_read::@26 to rom_read::@4 [phi:rom_read::@26->rom_read::@4]
    // rom_read::@4
    // gotoxy(x, y)
    // [1518] call gotoxy
    // [772] phi from rom_read::@4 to gotoxy [phi:rom_read::@4->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y [phi:rom_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:rom_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1519] phi from rom_read::@4 to rom_read::@5 [phi:rom_read::@4->rom_read::@5]
    // [1519] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@4->rom_read::@5#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1519] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@4->rom_read::@5#1] -- vwum1=vwuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1519] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#10 [phi:rom_read::@4->rom_read::@5#2] -- register_copy 
    // [1519] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@4->rom_read::@5#3] -- register_copy 
    // [1519] phi rom_read::rom_bram_ptr#13 = (char *)$7800 [phi:rom_read::@4->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1519] phi rom_read::rom_bram_bank#10 = 0 [phi:rom_read::@4->rom_read::@5#5] -- vbum1=vbuc1 
    lda #0
    sta rom_bram_bank
    // [1519] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@4->rom_read::@5#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@5
  __b5:
    // while (rom_file_size < rom_size)
    // [1520] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@6 -- vdum1_lt_vdum2_then_la1 
    lda rom_file_size+3
    cmp rom_size+3
    bcc __b6
    bne !+
    lda rom_file_size+2
    cmp rom_size+2
    bcc __b6
    bne !+
    lda rom_file_size+1
    cmp rom_size+1
    bcc __b6
    bne !+
    lda rom_file_size
    cmp rom_size
    bcc __b6
  !:
    // rom_read::@10
  __b10:
    // fclose(fp)
    // [1521] fclose::stream#2 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [1522] call fclose
    // [2411] phi from rom_read::@10 to fclose [phi:rom_read::@10->fclose]
    // [2411] phi fclose::stream#3 = fclose::stream#2 [phi:rom_read::@10->fclose#0] -- register_copy 
    jsr fclose
    // [1523] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1523] phi __stdio_filecount#12 = __stdio_filecount#2 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1523] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    rts
    // [1523] phi from rom_read::@26 to rom_read::@3 [phi:rom_read::@26->rom_read::@3]
  __b4:
    // [1523] phi __stdio_filecount#12 = __stdio_filecount#1 [phi:rom_read::@26->rom_read::@3#0] -- register_copy 
    // [1523] phi rom_read::return#0 = 0 [phi:rom_read::@26->rom_read::@3#1] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
    // rom_read::@3
    // rom_read::@return
    // }
    // [1524] return 
    rts
    // rom_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [1525] if(rom_read::info_status#12!=STATUS_CHECKING) goto rom_read::@30 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b7
    // [1527] phi from rom_read::@6 to rom_read::@7 [phi:rom_read::@6->rom_read::@7]
    // [1527] phi rom_read::rom_bram_ptr#10 = (char *) 1024 [phi:rom_read::@6->rom_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z rom_bram_ptr
    lda #>$400
    sta.z rom_bram_ptr+1
    // [1526] phi from rom_read::@6 to rom_read::@30 [phi:rom_read::@6->rom_read::@30]
    // rom_read::@30
    // [1527] phi from rom_read::@30 to rom_read::@7 [phi:rom_read::@30->rom_read::@7]
    // [1527] phi rom_read::rom_bram_ptr#10 = rom_read::rom_bram_ptr#13 [phi:rom_read::@30->rom_read::@7#0] -- register_copy 
    // rom_read::@7
  __b7:
    // display_action_text_reading(rom_action_text, file, rom_file_size, rom_size, rom_bram_bank, rom_bram_ptr)
    // [1528] display_action_text_reading::action#2 = rom_read::rom_action_text#10 -- pbuz1=pbuz2 
    lda.z rom_action_text
    sta.z display_action_text_reading.action
    lda.z rom_action_text+1
    sta.z display_action_text_reading.action+1
    // [1529] display_action_text_reading::file#2 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z display_action_text_reading.file
    lda.z file+1
    sta.z display_action_text_reading.file+1
    // [1530] display_action_text_reading::bytes#2 = rom_read::rom_file_size#11 -- vdum1=vdum2 
    lda rom_file_size
    sta display_action_text_reading.bytes
    lda rom_file_size+1
    sta display_action_text_reading.bytes+1
    lda rom_file_size+2
    sta display_action_text_reading.bytes+2
    lda rom_file_size+3
    sta display_action_text_reading.bytes+3
    // [1531] display_action_text_reading::size#2 = rom_read::rom_size#12 -- vdum1=vdum2 
    lda rom_size
    sta display_action_text_reading.size
    lda rom_size+1
    sta display_action_text_reading.size+1
    lda rom_size+2
    sta display_action_text_reading.size+2
    lda rom_size+3
    sta display_action_text_reading.size+3
    // [1532] display_action_text_reading::bram_bank#2 = rom_read::rom_bram_bank#10 -- vbum1=vbum2 
    lda rom_bram_bank
    sta display_action_text_reading.bram_bank
    // [1533] display_action_text_reading::bram_ptr#2 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z rom_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1534] call display_action_text_reading
    // [2440] phi from rom_read::@7 to display_action_text_reading [phi:rom_read::@7->display_action_text_reading]
    // [2440] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#2 [phi:rom_read::@7->display_action_text_reading#0] -- register_copy 
    // [2440] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#2 [phi:rom_read::@7->display_action_text_reading#1] -- register_copy 
    // [2440] phi display_action_text_reading::size#10 = display_action_text_reading::size#2 [phi:rom_read::@7->display_action_text_reading#2] -- register_copy 
    // [2440] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#2 [phi:rom_read::@7->display_action_text_reading#3] -- register_copy 
    // [2440] phi display_action_text_reading::file#3 = display_action_text_reading::file#2 [phi:rom_read::@7->display_action_text_reading#4] -- register_copy 
    // [2440] phi display_action_text_reading::action#3 = display_action_text_reading::action#2 [phi:rom_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // rom_read::@27
    // rom_address % 0x04000
    // [1535] rom_read::$13 = rom_read::rom_address#10 & $4000-1 -- vduz1=vdum2_band_vduc1 
    lda rom_address
    and #<$4000-1
    sta.z rom_read__13
    lda rom_address+1
    and #>$4000-1
    sta.z rom_read__13+1
    lda rom_address+2
    and #<$4000-1>>$10
    sta.z rom_read__13+2
    lda rom_address+3
    and #>$4000-1>>$10
    sta.z rom_read__13+3
    // if (!(rom_address % 0x04000))
    // [1536] if(0!=rom_read::$13) goto rom_read::@8 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__13
    ora.z rom_read__13+1
    ora.z rom_read__13+2
    ora.z rom_read__13+3
    bne __b8
    // rom_read::@14
    // brom_bank_start++;
    // [1537] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#11 -- vbum1=_inc_vbum1 
    inc brom_bank_start
    // [1538] phi from rom_read::@14 rom_read::@27 to rom_read::@8 [phi:rom_read::@14/rom_read::@27->rom_read::@8]
    // [1538] phi rom_read::brom_bank_start#16 = rom_read::brom_bank_start#0 [phi:rom_read::@14/rom_read::@27->rom_read::@8#0] -- register_copy 
    // rom_read::@8
  __b8:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1539] BRAM = rom_read::rom_bram_bank#10 -- vbuz1=vbum2 
    lda rom_bram_bank
    sta.z BRAM
    // rom_read::@19
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1540] fgets::ptr#5 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z fgets.ptr
    lda.z rom_bram_ptr+1
    sta.z fgets.ptr+1
    // [1541] fgets::stream#3 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1542] call fgets
    // [2357] phi from rom_read::@19 to fgets [phi:rom_read::@19->fgets]
    // [2357] phi fgets::ptr#14 = fgets::ptr#5 [phi:rom_read::@19->fgets#0] -- register_copy 
    // [2357] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@19->fgets#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta fgets.size
    lda #>ROM_PROGRESS_CELL
    sta fgets.size+1
    // [2357] phi fgets::stream#4 = fgets::stream#3 [phi:rom_read::@19->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1543] fgets::return#13 = fgets::return#1
    // rom_read::@28
    // [1544] rom_read::rom_package_read#0 = fgets::return#13 -- vwum1=vwum2 
    lda fgets.return
    sta rom_package_read
    lda fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1545] if(0!=rom_read::rom_package_read#0) goto rom_read::@9 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b9
    jmp __b10
    // rom_read::@9
  __b9:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1546] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@11 -- vwum1_neq_vwuc1_then_la1 
    lda rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b11
    lda rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b11
    // rom_read::@15
    // gotoxy(x, ++y);
    // [1547] rom_read::y#1 = ++ rom_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1548] gotoxy::y#33 = rom_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1549] call gotoxy
    // [772] phi from rom_read::@15 to gotoxy [phi:rom_read::@15->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#33 [phi:rom_read::@15->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:rom_read::@15->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1550] phi from rom_read::@15 to rom_read::@11 [phi:rom_read::@15->rom_read::@11]
    // [1550] phi rom_read::y#26 = rom_read::y#1 [phi:rom_read::@15->rom_read::@11#0] -- register_copy 
    // [1550] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@15->rom_read::@11#1] -- vwum1=vbuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1550] phi from rom_read::@9 to rom_read::@11 [phi:rom_read::@9->rom_read::@11]
    // [1550] phi rom_read::y#26 = rom_read::y#11 [phi:rom_read::@9->rom_read::@11#0] -- register_copy 
    // [1550] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@9->rom_read::@11#1] -- register_copy 
    // rom_read::@11
  __b11:
    // if(info_status == STATUS_READING)
    // [1551] if(rom_read::info_status#12!=STATUS_READING) goto rom_read::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b12
    // rom_read::@16
    // cputc('.')
    // [1552] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1553] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_read::@12
  __b12:
    // rom_bram_ptr += rom_package_read
    // [1555] rom_read::rom_bram_ptr#2 = rom_read::rom_bram_ptr#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z rom_bram_ptr
    adc rom_package_read
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc rom_package_read+1
    sta.z rom_bram_ptr+1
    // rom_address += rom_package_read
    // [1556] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
    lda rom_address
    clc
    adc rom_package_read
    sta rom_address
    lda rom_address+1
    adc rom_package_read+1
    sta rom_address+1
    lda rom_address+2
    adc #0
    sta rom_address+2
    lda rom_address+3
    adc #0
    sta rom_address+3
    // rom_file_size += rom_package_read
    // [1557] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
    lda rom_file_size
    clc
    adc rom_package_read
    sta rom_file_size
    lda rom_file_size+1
    adc rom_package_read+1
    sta rom_file_size+1
    lda rom_file_size+2
    adc #0
    sta rom_file_size+2
    lda rom_file_size+3
    adc #0
    sta rom_file_size+3
    // rom_row_current += rom_package_read
    // [1558] rom_read::rom_row_current#17 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda rom_row_current
    adc rom_package_read
    sta rom_row_current
    lda rom_row_current+1
    adc rom_package_read+1
    sta rom_row_current+1
    // if (rom_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [1559] if(rom_read::rom_bram_ptr#2!=(char *)$c000) goto rom_read::@13 -- pbuz1_neq_pbuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b13
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b13
    // rom_read::@17
    // rom_bram_bank++;
    // [1560] rom_read::rom_bram_bank#1 = ++ rom_read::rom_bram_bank#10 -- vbum1=_inc_vbum1 
    inc rom_bram_bank
    // [1561] phi from rom_read::@17 to rom_read::@13 [phi:rom_read::@17->rom_read::@13]
    // [1561] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#1 [phi:rom_read::@17->rom_read::@13#0] -- register_copy 
    // [1561] phi rom_read::rom_bram_ptr#8 = (char *)$a000 [phi:rom_read::@17->rom_read::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1561] phi from rom_read::@12 to rom_read::@13 [phi:rom_read::@12->rom_read::@13]
    // [1561] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#10 [phi:rom_read::@12->rom_read::@13#0] -- register_copy 
    // [1561] phi rom_read::rom_bram_ptr#8 = rom_read::rom_bram_ptr#2 [phi:rom_read::@12->rom_read::@13#1] -- register_copy 
    // rom_read::@13
  __b13:
    // if (rom_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [1562] if(rom_read::rom_bram_ptr#8!=(char *)$9800) goto rom_read::@29 -- pbuz1_neq_pbuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$9800
    beq !__b5+
    jmp __b5
  !__b5:
    lda.z rom_bram_ptr
    cmp #<$9800
    beq !__b5+
    jmp __b5
  !__b5:
    // [1519] phi from rom_read::@13 to rom_read::@5 [phi:rom_read::@13->rom_read::@5]
    // [1519] phi rom_read::y#11 = rom_read::y#26 [phi:rom_read::@13->rom_read::@5#0] -- register_copy 
    // [1519] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#17 [phi:rom_read::@13->rom_read::@5#1] -- register_copy 
    // [1519] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@13->rom_read::@5#2] -- register_copy 
    // [1519] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@13->rom_read::@5#3] -- register_copy 
    // [1519] phi rom_read::rom_bram_ptr#13 = (char *)$a000 [phi:rom_read::@13->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1519] phi rom_read::rom_bram_bank#10 = 1 [phi:rom_read::@13->rom_read::@5#5] -- vbum1=vbuc1 
    lda #1
    sta rom_bram_bank
    // [1519] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@13->rom_read::@5#6] -- register_copy 
    jmp __b5
    // [1563] phi from rom_read::@13 to rom_read::@29 [phi:rom_read::@13->rom_read::@29]
    // rom_read::@29
    // [1519] phi from rom_read::@29 to rom_read::@5 [phi:rom_read::@29->rom_read::@5]
    // [1519] phi rom_read::y#11 = rom_read::y#26 [phi:rom_read::@29->rom_read::@5#0] -- register_copy 
    // [1519] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#17 [phi:rom_read::@29->rom_read::@5#1] -- register_copy 
    // [1519] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@29->rom_read::@5#2] -- register_copy 
    // [1519] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@29->rom_read::@5#3] -- register_copy 
    // [1519] phi rom_read::rom_bram_ptr#13 = rom_read::rom_bram_ptr#8 [phi:rom_read::@29->rom_read::@5#4] -- register_copy 
    // [1519] phi rom_read::rom_bram_bank#10 = rom_read::rom_bram_bank#14 [phi:rom_read::@29->rom_read::@5#5] -- register_copy 
    // [1519] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@29->rom_read::@5#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    rom_address: .dword 0
    return: .dword 0
    rom_package_read: .word 0
    brom_bank_start: .byte 0
    y: .byte 0
    .label rom_file_size = return
    // We start for ROM from 0x0:0x7800 !!!!
    rom_bram_bank: .byte 0
    rom_size: .dword 0
    /// Holds the amount of bytes actually read in the memory to be flashed.
    rom_row_current: .word 0
    info_status: .byte 0
}
.segment Code
  // rom_verify
// __mem() unsigned long rom_verify(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__17 = $ab
    .label rom_bram_ptr = $52
    // rom_verify::bank_set_bram1
    // BRAM = bank
    // [1565] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_verify::@11
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1566] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1567] call rom_address_from_bank
    // [2777] phi from rom_verify::@11 to rom_address_from_bank [phi:rom_verify::@11->rom_address_from_bank]
    // [2777] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify::@11->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1568] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_1
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_1+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_1+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_1+3
    // rom_verify::@12
    // [1569] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1570] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vdum2_plus_vdum1 
    clc
    lda rom_boundary
    adc rom_address
    sta rom_boundary
    lda rom_boundary+1
    adc rom_address+1
    sta rom_boundary+1
    lda rom_boundary+2
    adc rom_address+2
    sta rom_boundary+2
    lda rom_boundary+3
    adc rom_address+3
    sta rom_boundary+3
    // display_info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [1571] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1572] call display_info_rom
    // [1440] phi from rom_verify::@12 to display_info_rom [phi:rom_verify::@12->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = rom_verify::info_text [phi:rom_verify::@12->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#1 [phi:rom_verify::@12->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:rom_verify::@12->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1573] phi from rom_verify::@12 to rom_verify::@13 [phi:rom_verify::@12->rom_verify::@13]
    // rom_verify::@13
    // gotoxy(x, y)
    // [1574] call gotoxy
    // [772] phi from rom_verify::@13 to gotoxy [phi:rom_verify::@13->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y [phi:rom_verify::@13->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:rom_verify::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1575] phi from rom_verify::@13 to rom_verify::@1 [phi:rom_verify::@13->rom_verify::@1]
    // [1575] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@13->rom_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1575] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@13->rom_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1575] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@13->rom_verify::@1#2] -- vdum1=vduc1 
    sta rom_different_bytes
    sta rom_different_bytes+1
    lda #<0>>$10
    sta rom_different_bytes+2
    lda #>0>>$10
    sta rom_different_bytes+3
    // [1575] phi rom_verify::rom_bram_ptr#10 = (char *)$7800 [phi:rom_verify::@13->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1575] phi rom_verify::rom_bram_bank#11 = 0 [phi:rom_verify::@13->rom_verify::@1#4] -- vbum1=vbuc1 
    lda #0
    sta rom_bram_bank
    // [1575] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@13->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1576] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vdum1_lt_vdum2_then_la1 
    lda rom_address+3
    cmp rom_boundary+3
    bcc __b2
    bne !+
    lda rom_address+2
    cmp rom_boundary+2
    bcc __b2
    bne !+
    lda rom_address+1
    cmp rom_boundary+1
    bcc __b2
    bne !+
    lda rom_address
    cmp rom_boundary
    bcc __b2
  !:
    // rom_verify::@return
    // }
    // [1577] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1578] rom_compare::bank_ram#0 = rom_verify::rom_bram_bank#11 -- vbum1=vbum2 
    lda rom_bram_bank
    sta rom_compare.bank_ram
    // [1579] rom_compare::ptr_ram#1 = rom_verify::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z rom_compare.ptr_ram
    lda.z rom_bram_ptr+1
    sta.z rom_compare.ptr_ram+1
    // [1580] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vdum1=vdum2 
    lda rom_address
    sta rom_compare.rom_compare_address
    lda rom_address+1
    sta rom_compare.rom_compare_address+1
    lda rom_address+2
    sta rom_compare.rom_compare_address+2
    lda rom_address+3
    sta rom_compare.rom_compare_address+3
    // [1581] call rom_compare
  // {asm{.byte $db}}
    // [2781] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2781] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2781] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size+1
    // [2781] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2781] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1582] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@14
    // [1583] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1584] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1585] rom_verify::y#1 = ++ rom_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1586] gotoxy::y#35 = rom_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1587] call gotoxy
    // [772] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#35 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1588] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1588] phi rom_verify::y#11 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1588] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1588] phi from rom_verify::@14 to rom_verify::@3 [phi:rom_verify::@14->rom_verify::@3]
    // [1588] phi rom_verify::y#11 = rom_verify::y#3 [phi:rom_verify::@14->rom_verify::@3#0] -- register_copy 
    // [1588] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@14->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1589] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes+1
    cmp #>ROM_PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    lda equal_bytes
    cmp #<ROM_PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    // rom_verify::@9
    // cputc('=')
    // [1590] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1591] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // rom_bram_ptr += ROM_PROGRESS_CELL
    // [1593] rom_verify::rom_bram_ptr#1 = rom_verify::rom_bram_ptr#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z rom_bram_ptr
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc #>ROM_PROGRESS_CELL
    sta.z rom_bram_ptr+1
    // rom_address += ROM_PROGRESS_CELL
    // [1594] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_address
    adc #<ROM_PROGRESS_CELL
    sta rom_address
    lda rom_address+1
    adc #>ROM_PROGRESS_CELL
    sta rom_address+1
    lda rom_address+2
    adc #0
    sta rom_address+2
    lda rom_address+3
    adc #0
    sta rom_address+3
    // progress_row_current += ROM_PROGRESS_CELL
    // [1595] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwum1=vwum1_plus_vwuc1 
    lda progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta progress_row_current
    lda progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta progress_row_current+1
    // if (rom_bram_ptr == BRAM_HIGH)
    // [1596] if(rom_verify::rom_bram_ptr#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // rom_bram_bank++;
    // [1597] rom_verify::rom_bram_bank#1 = ++ rom_verify::rom_bram_bank#11 -- vbum1=_inc_vbum1 
    inc rom_bram_bank
    // [1598] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1598] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1598] phi rom_verify::rom_bram_ptr#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1598] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1598] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1598] phi rom_verify::rom_bram_ptr#6 = rom_verify::rom_bram_ptr#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (rom_bram_ptr == RAM_HIGH)
    // [1599] if(rom_verify::rom_bram_ptr#6!=$9800) goto rom_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$9800
    bne __b7
    lda.z rom_bram_ptr
    cmp #<$9800
    bne __b7
    // [1601] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1601] phi rom_verify::rom_bram_ptr#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1601] phi rom_verify::rom_bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta rom_bram_bank
    // [1600] phi from rom_verify::@6 to rom_verify::@24 [phi:rom_verify::@6->rom_verify::@24]
    // rom_verify::@24
    // [1601] phi from rom_verify::@24 to rom_verify::@7 [phi:rom_verify::@24->rom_verify::@7]
    // [1601] phi rom_verify::rom_bram_ptr#11 = rom_verify::rom_bram_ptr#6 [phi:rom_verify::@24->rom_verify::@7#0] -- register_copy 
    // [1601] phi rom_verify::rom_bram_bank#10 = rom_verify::rom_bram_bank#25 [phi:rom_verify::@24->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1602] rom_verify::$17 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<ROM_PROGRESS_CELL
    sbc equal_bytes
    sta.z rom_verify__17
    lda #>ROM_PROGRESS_CELL
    sbc equal_bytes+1
    sta.z rom_verify__17+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1603] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$17 -- vdum1=vdum1_plus_vwuz2 
    lda rom_different_bytes
    clc
    adc.z rom_verify__17
    sta rom_different_bytes
    lda rom_different_bytes+1
    adc.z rom_verify__17+1
    sta rom_different_bytes+1
    lda rom_different_bytes+2
    adc #0
    sta rom_different_bytes+2
    lda rom_different_bytes+3
    adc #0
    sta rom_different_bytes+3
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1604] call snprintf_init
    // [1167] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1605] phi from rom_verify::@7 to rom_verify::@15 [phi:rom_verify::@7->rom_verify::@15]
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1606] call printf_str
    // [1172] phi from rom_verify::@15 to printf_str [phi:rom_verify::@15->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:rom_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s [phi:rom_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1607] printf_ulong::uvalue#7 = rom_verify::rom_different_bytes#1 -- vdum1=vdum2 
    lda rom_different_bytes
    sta printf_ulong.uvalue
    lda rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1608] call printf_ulong
    // [1628] phi from rom_verify::@16 to printf_ulong [phi:rom_verify::@16->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:rom_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:rom_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:rom_verify::@16->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#7 [phi:rom_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1609] phi from rom_verify::@16 to rom_verify::@17 [phi:rom_verify::@16->rom_verify::@17]
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1610] call printf_str
    // [1172] phi from rom_verify::@17 to printf_str [phi:rom_verify::@17->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:rom_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s1 [phi:rom_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1611] printf_uchar::uvalue#18 = rom_verify::rom_bram_bank#10 -- vbum1=vbum2 
    lda rom_bram_bank
    sta printf_uchar.uvalue
    // [1612] call printf_uchar
    // [1307] phi from rom_verify::@18 to printf_uchar [phi:rom_verify::@18->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:rom_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 2 [phi:rom_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:rom_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:rom_verify::@18->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#18 [phi:rom_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1613] phi from rom_verify::@18 to rom_verify::@19 [phi:rom_verify::@18->rom_verify::@19]
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1614] call printf_str
    // [1172] phi from rom_verify::@19 to printf_str [phi:rom_verify::@19->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:rom_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s2 [phi:rom_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1615] printf_uint::uvalue#8 = (unsigned int)rom_verify::rom_bram_ptr#11 -- vwum1=vwuz2 
    lda.z rom_bram_ptr
    sta printf_uint.uvalue
    lda.z rom_bram_ptr+1
    sta printf_uint.uvalue+1
    // [1616] call printf_uint
    // [2254] phi from rom_verify::@20 to printf_uint [phi:rom_verify::@20->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 1 [phi:rom_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 4 [phi:rom_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &snputc [phi:rom_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:rom_verify::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = printf_uint::uvalue#8 [phi:rom_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1617] phi from rom_verify::@20 to rom_verify::@21 [phi:rom_verify::@20->rom_verify::@21]
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1618] call printf_str
    // [1172] phi from rom_verify::@21 to printf_str [phi:rom_verify::@21->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:rom_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s3 [phi:rom_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1619] printf_ulong::uvalue#8 = rom_verify::rom_address#1 -- vdum1=vdum2 
    lda rom_address
    sta printf_ulong.uvalue
    lda rom_address+1
    sta printf_ulong.uvalue+1
    lda rom_address+2
    sta printf_ulong.uvalue+2
    lda rom_address+3
    sta printf_ulong.uvalue+3
    // [1620] call printf_ulong
    // [1628] phi from rom_verify::@22 to printf_ulong [phi:rom_verify::@22->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:rom_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:rom_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:rom_verify::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#8 [phi:rom_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // rom_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1621] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1622] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1624] call display_action_text
    // [1318] phi from rom_verify::@23 to display_action_text [phi:rom_verify::@23->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:rom_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1575] phi from rom_verify::@23 to rom_verify::@1 [phi:rom_verify::@23->rom_verify::@1]
    // [1575] phi rom_verify::y#3 = rom_verify::y#11 [phi:rom_verify::@23->rom_verify::@1#0] -- register_copy 
    // [1575] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@23->rom_verify::@1#1] -- register_copy 
    // [1575] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@23->rom_verify::@1#2] -- register_copy 
    // [1575] phi rom_verify::rom_bram_ptr#10 = rom_verify::rom_bram_ptr#11 [phi:rom_verify::@23->rom_verify::@1#3] -- register_copy 
    // [1575] phi rom_verify::rom_bram_bank#11 = rom_verify::rom_bram_bank#10 [phi:rom_verify::@23->rom_verify::@1#4] -- register_copy 
    // [1575] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@23->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1625] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1626] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b5
  .segment Data
    info_text: .text "Comparing ..."
    .byte 0
    rom_address: .dword 0
    .label rom_boundary = file_size
    .label equal_bytes = rom_compare.equal_bytes
    y: .byte 0
    // We start for ROM from 0x0:0x7800 !!!!
    rom_bram_bank: .byte 0
    rom_different_bytes: .dword 0
    .label rom_chip = display_info_rom.rom_chip
    .label rom_bank_start = rom_address_from_bank.rom_bank
    file_size: .dword 0
    .label return = rom_different_bytes
    progress_row_current: .word 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_ulong: {
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1629] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1630] ultoa::value#1 = printf_ulong::uvalue#15
    // [1631] ultoa::radix#0 = printf_ulong::format_radix#15
    // [1632] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1633] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1634] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#15
    // [1635] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#15
    // [1636] call printf_number_buffer
  // Print using format
    // [2622] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [2622] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [2622] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [2622] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [2622] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1637] return 
    rts
  .segment Data
    uvalue: .dword 0
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
  // rom_flash
// __mem() unsigned long rom_flash(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label rom_flash__29 = $72
    .label ram_address_sector = $7b
    .label ram_address = $5a
    // rom_flash::bank_set_bram1
    // BRAM = bank
    // [1639] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // [1640] phi from rom_flash::bank_set_bram1 to rom_flash::@19 [phi:rom_flash::bank_set_bram1->rom_flash::@19]
    // rom_flash::@19
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1641] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [874] phi from rom_flash::@19 to display_action_progress [phi:rom_flash::@19->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = string_0 [phi:rom_flash::@19->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<string_0
    sta.z display_action_progress.info_text
    lda #>string_0
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@20
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1642] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1643] call rom_address_from_bank
    // [2777] phi from rom_flash::@20 to rom_address_from_bank [phi:rom_flash::@20->rom_address_from_bank]
    // [2777] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@20->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1644] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@21
    // [1645] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1646] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
    lda rom_address_sector
    clc
    adc file_size
    sta rom_boundary
    lda rom_address_sector+1
    adc file_size+1
    sta rom_boundary+1
    lda rom_address_sector+2
    adc file_size+2
    sta rom_boundary+2
    lda rom_address_sector+3
    adc file_size+3
    sta rom_boundary+3
    // display_info_rom(rom_chip, STATUS_FLASHING, "Flashing ...")
    // [1647] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1648] call display_info_rom
    // [1440] phi from rom_flash::@21 to display_info_rom [phi:rom_flash::@21->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text1 [phi:rom_flash::@21->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#2 [phi:rom_flash::@21->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@21->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1649] phi from rom_flash::@21 to rom_flash::@1 [phi:rom_flash::@21->rom_flash::@1]
    // [1649] phi rom_flash::flash_errors#12 = 0 [phi:rom_flash::@21->rom_flash::@1#0] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1649] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@21->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1649] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@21->rom_flash::@1#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1649] phi rom_flash::ram_address_sector#11 = (char *)$7800 [phi:rom_flash::@21->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address_sector
    lda #>$7800
    sta.z ram_address_sector+1
    // [1649] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@21->rom_flash::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank_sector
    // [1649] phi rom_flash::rom_address_sector#13 = rom_flash::rom_address_sector#0 [phi:rom_flash::@21->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1650] if(rom_flash::rom_address_sector#13<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
    lda rom_address_sector+3
    cmp rom_boundary+3
    bcc __b2
    bne !+
    lda rom_address_sector+2
    cmp rom_boundary+2
    bcc __b2
    bne !+
    lda rom_address_sector+1
    cmp rom_boundary+1
    bcc __b2
    bne !+
    lda rom_address_sector
    cmp rom_boundary
    bcc __b2
  !:
    // rom_flash::@3
    // display_action_text_flashed(rom_address_sector, "ROM")
    // [1651] display_action_text_flashed::bytes#2 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta display_action_text_flashed.bytes
    lda rom_address_sector+1
    sta display_action_text_flashed.bytes+1
    lda rom_address_sector+2
    sta display_action_text_flashed.bytes+2
    lda rom_address_sector+3
    sta display_action_text_flashed.bytes+3
    // [1652] call display_action_text_flashed
    // [2837] phi from rom_flash::@3 to display_action_text_flashed [phi:rom_flash::@3->display_action_text_flashed]
    // [2837] phi display_action_text_flashed::chip#3 = chip [phi:rom_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2837] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#2 [phi:rom_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1653] phi from rom_flash::@3 to rom_flash::@23 [phi:rom_flash::@3->rom_flash::@23]
    // rom_flash::@23
    // wait_moment(32)
    // [1654] call wait_moment
    // [1270] phi from rom_flash::@23 to wait_moment [phi:rom_flash::@23->wait_moment]
    // [1270] phi wait_moment::w#13 = $20 [phi:rom_flash::@23->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // rom_flash::@return
    // }
    // [1655] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1656] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_compare.bank_ram
    // [1657] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1658] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta rom_compare.rom_compare_address+3
    // [1659] call rom_compare
  // {asm{.byte $db}}
    // [2781] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2781] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2781] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwum1=vwuc1 
    lda #<$1000
    sta rom_compare.rom_compare_size
    lda #>$1000
    sta rom_compare.rom_compare_size+1
    // [2781] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2781] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1660] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@22
    // [1661] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1662] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes+1
    cmp #>$1000
    beq !__b3+
    jmp __b3
  !__b3:
    lda equal_bytes
    cmp #<$1000
    beq !__b3+
    jmp __b3
  !__b3:
    // rom_flash::@16
    // cputsxy(x_sector, y_sector, "--------")
    // [1663] cputsxy::x#1 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta cputsxy.x
    // [1664] cputsxy::y#1 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputsxy.y
    // [1665] call cputsxy
    // [867] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [867] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [867] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [867] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1666] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1666] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1667] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1668] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#13 + $1000 -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_address_sector
    adc #<$1000
    sta rom_address_sector
    lda rom_address_sector+1
    adc #>$1000
    sta rom_address_sector+1
    lda rom_address_sector+2
    adc #0
    sta rom_address_sector+2
    lda rom_address_sector+3
    adc #0
    sta rom_address_sector+3
    // if (ram_address_sector == BRAM_HIGH)
    // [1669] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1670] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbum1=_inc_vbum1 
    inc bram_bank_sector
    // [1671] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1671] phi rom_flash::bram_bank_sector#40 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1671] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1671] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1671] phi rom_flash::bram_bank_sector#40 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1671] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1672] if(rom_flash::ram_address_sector#8!=$9800) goto rom_flash::@36 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$9800
    bne __b14
    lda.z ram_address_sector
    cmp #<$9800
    bne __b14
    // [1674] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1674] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1674] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank_sector
    // [1673] phi from rom_flash::@13 to rom_flash::@36 [phi:rom_flash::@13->rom_flash::@36]
    // rom_flash::@36
    // [1674] phi from rom_flash::@36 to rom_flash::@14 [phi:rom_flash::@36->rom_flash::@14]
    // [1674] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@36->rom_flash::@14#0] -- register_copy 
    // [1674] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#40 [phi:rom_flash::@36->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1675] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1676] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
    lda rom_address_sector
    and #<ROM_PROGRESS_ROW-1
    sta.z rom_flash__29
    lda rom_address_sector+1
    and #>ROM_PROGRESS_ROW-1
    sta.z rom_flash__29+1
    lda rom_address_sector+2
    and #<ROM_PROGRESS_ROW-1>>$10
    sta.z rom_flash__29+2
    lda rom_address_sector+3
    and #>ROM_PROGRESS_ROW-1>>$10
    sta.z rom_flash__29+3
    // if (!(rom_address_sector % ROM_PROGRESS_ROW))
    // [1677] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1678] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1679] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1679] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1679] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1679] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1679] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1679] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1680] call snprintf_init
    // [1167] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@32
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1681] printf_ulong::uvalue#9 = rom_flash::flash_errors#10 -- vdum1=vdum2 
    lda flash_errors
    sta printf_ulong.uvalue
    lda flash_errors+1
    sta printf_ulong.uvalue+1
    lda flash_errors+2
    sta printf_ulong.uvalue+2
    lda flash_errors+3
    sta printf_ulong.uvalue+3
    // [1682] call printf_ulong
    // [1628] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = DECIMAL [phi:rom_flash::@32->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#9 [phi:rom_flash::@32->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1683] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1684] call printf_str
    // [1172] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = rom_flash::s2 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1685] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1686] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1688] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1689] call display_info_rom
    // [1440] phi from rom_flash::@34 to display_info_rom [phi:rom_flash::@34->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = info_text [phi:rom_flash::@34->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#3 [phi:rom_flash::@34->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@34->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1649] phi from rom_flash::@34 to rom_flash::@1 [phi:rom_flash::@34->rom_flash::@1]
    // [1649] phi rom_flash::flash_errors#12 = rom_flash::flash_errors#10 [phi:rom_flash::@34->rom_flash::@1#0] -- register_copy 
    // [1649] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@34->rom_flash::@1#1] -- register_copy 
    // [1649] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@34->rom_flash::@1#2] -- register_copy 
    // [1649] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@34->rom_flash::@1#3] -- register_copy 
    // [1649] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@34->rom_flash::@1#4] -- register_copy 
    // [1649] phi rom_flash::rom_address_sector#13 = rom_flash::rom_address_sector#1 [phi:rom_flash::@34->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1690] phi from rom_flash::@22 to rom_flash::@5 [phi:rom_flash::@22->rom_flash::@5]
  __b3:
    // [1690] phi rom_flash::flash_errors_sector#10 = 0 [phi:rom_flash::@22->rom_flash::@5#0] -- vwum1=vwuc1 
    lda #<0
    sta flash_errors_sector
    sta flash_errors_sector+1
    // [1690] phi rom_flash::retries#12 = 0 [phi:rom_flash::@22->rom_flash::@5#1] -- vbum1=vbuc1 
    sta retries
    // [1690] phi from rom_flash::@35 to rom_flash::@5 [phi:rom_flash::@35->rom_flash::@5]
    // [1690] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@35->rom_flash::@5#0] -- register_copy 
    // [1690] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@35->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_flash::@24
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1691] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#13 + $1000 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda rom_address_sector
    adc #<$1000
    sta rom_sector_boundary
    lda rom_address_sector+1
    adc #>$1000
    sta rom_sector_boundary+1
    lda rom_address_sector+2
    adc #0
    sta rom_sector_boundary+2
    lda rom_address_sector+3
    adc #0
    sta rom_sector_boundary+3
    // gotoxy(x, y)
    // [1692] gotoxy::x#36 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [1693] gotoxy::y#36 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1694] call gotoxy
    // [772] phi from rom_flash::@24 to gotoxy [phi:rom_flash::@24->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#36 [phi:rom_flash::@24->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#36 [phi:rom_flash::@24->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1695] phi from rom_flash::@24 to rom_flash::@25 [phi:rom_flash::@24->rom_flash::@25]
    // rom_flash::@25
    // printf("........")
    // [1696] call printf_str
    // [1172] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [1172] phi printf_str::putc#89 = &cputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = rom_flash::s1 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // [1697] rom_flash::rom_address#16 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_address
    lda rom_address_sector+1
    sta rom_address+1
    lda rom_address_sector+2
    sta rom_address+2
    lda rom_address_sector+3
    sta rom_address+3
    // [1698] rom_flash::ram_address#16 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1699] rom_flash::x#16 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta x
    // [1700] phi from rom_flash::@10 rom_flash::@26 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6]
    // [1700] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#0] -- register_copy 
    // [1700] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#1] -- register_copy 
    // [1700] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#7 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#2] -- register_copy 
    // [1700] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1701] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vdum1_lt_vdum2_then_la1 
    lda rom_address+3
    cmp rom_sector_boundary+3
    bcc __b7
    bne !+
    lda rom_address+2
    cmp rom_sector_boundary+2
    bcc __b7
    bne !+
    lda rom_address+1
    cmp rom_sector_boundary+1
    bcc __b7
    bne !+
    lda rom_address
    cmp rom_sector_boundary
    bcc __b7
  !:
    // rom_flash::@8
    // retries++;
    // [1702] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors_sector && retries <= 3)
    // [1703] if(0==rom_flash::flash_errors_sector#11) goto rom_flash::@12 -- 0_eq_vwum1_then_la1 
    lda flash_errors_sector
    ora flash_errors_sector+1
    beq __b12
    // rom_flash::@35
    // [1704] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1705] rom_flash::flash_errors#1 = rom_flash::flash_errors#12 + rom_flash::flash_errors_sector#11 -- vdum1=vdum1_plus_vwum2 
    lda flash_errors
    clc
    adc flash_errors_sector
    sta flash_errors
    lda flash_errors+1
    adc flash_errors_sector+1
    sta flash_errors+1
    lda flash_errors+2
    adc #0
    sta flash_errors+2
    lda flash_errors+3
    adc #0
    sta flash_errors+3
    jmp __b4
    // rom_flash::@7
  __b7:
    // display_action_text_flashing( ROM_SECTOR, "ROM", bram_bank_sector, ram_address_sector, rom_address_sector)
    // [1706] display_action_text_flashing::bram_bank#2 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta display_action_text_flashing.bram_bank
    // [1707] display_action_text_flashing::bram_ptr#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z display_action_text_flashing.bram_ptr
    lda.z ram_address_sector+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1708] display_action_text_flashing::address#2 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta display_action_text_flashing.address
    lda rom_address_sector+1
    sta display_action_text_flashing.address+1
    lda rom_address_sector+2
    sta display_action_text_flashing.address+2
    lda rom_address_sector+3
    sta display_action_text_flashing.address+3
    // [1709] call display_action_text_flashing
    // [2854] phi from rom_flash::@7 to display_action_text_flashing [phi:rom_flash::@7->display_action_text_flashing]
    // [2854] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#2 [phi:rom_flash::@7->display_action_text_flashing#0] -- register_copy 
    // [2854] phi display_action_text_flashing::chip#10 = chip [phi:rom_flash::@7->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2854] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#2 [phi:rom_flash::@7->display_action_text_flashing#2] -- register_copy 
    // [2854] phi display_action_text_flashing::bram_bank#3 = display_action_text_flashing::bram_bank#2 [phi:rom_flash::@7->display_action_text_flashing#3] -- register_copy 
    // [2854] phi display_action_text_flashing::bytes#3 = $1000 [phi:rom_flash::@7->display_action_text_flashing#4] -- vdum1=vduc1 
    lda #<$1000
    sta display_action_text_flashing.bytes
    lda #>$1000
    sta display_action_text_flashing.bytes+1
    lda #<$1000>>$10
    sta display_action_text_flashing.bytes+2
    lda #>$1000>>$10
    sta display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // rom_flash::@27
    // unsigned long written_bytes = rom_write(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1710] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_write.flash_ram_bank
    // [1711] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1712] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vdum1=vdum2 
    lda rom_address
    sta rom_write.flash_rom_address
    lda rom_address+1
    sta rom_write.flash_rom_address+1
    lda rom_address+2
    sta rom_write.flash_rom_address+2
    lda rom_address+3
    sta rom_write.flash_rom_address+3
    // [1713] call rom_write
    // [2883] phi from rom_flash::@27 to rom_write [phi:rom_flash::@27->rom_write]
    jsr rom_write
    // rom_flash::@28
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1714] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_compare.bank_ram
    // [1715] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1716] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vdum1=vdum2 
    lda rom_address
    sta rom_compare.rom_compare_address
    lda rom_address+1
    sta rom_compare.rom_compare_address+1
    lda rom_address+2
    sta rom_compare.rom_compare_address+2
    lda rom_address+3
    sta rom_compare.rom_compare_address+3
    // [1717] call rom_compare
    // [2781] phi from rom_flash::@28 to rom_compare [phi:rom_flash::@28->rom_compare]
    // [2781] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@28->rom_compare#0] -- register_copy 
    // [2781] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@28->rom_compare#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size+1
    // [2781] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@28->rom_compare#2] -- register_copy 
    // [2781] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@28->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1718] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@29
    // equal_bytes = rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1719] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwum1=vwum2 
    lda rom_compare.return
    sta equal_bytes_1
    lda rom_compare.return+1
    sta equal_bytes_1+1
    // gotoxy(x, y)
    // [1720] gotoxy::x#37 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1721] gotoxy::y#37 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1722] call gotoxy
    // [772] phi from rom_flash::@29 to gotoxy [phi:rom_flash::@29->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#37 [phi:rom_flash::@29->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#37 [phi:rom_flash::@29->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@30
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1723] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1724] cputcxy::x#17 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1725] cputcxy::y#17 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1726] call cputcxy
    // [2167] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [2167] phi cputcxy::c#18 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [2167] phi cputcxy::y#18 = cputcxy::y#17 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#17 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1727] phi from rom_flash::@11 rom_flash::@31 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10]
    // [1727] phi rom_flash::flash_errors_sector#7 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1728] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1729] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_address
    adc #<ROM_PROGRESS_CELL
    sta rom_address
    lda rom_address+1
    adc #>ROM_PROGRESS_CELL
    sta rom_address+1
    lda rom_address+2
    adc #0
    sta rom_address+2
    lda rom_address+3
    adc #0
    sta rom_address+3
    // x++;
    // [1730] rom_flash::x#1 = ++ rom_flash::x#10 -- vbum1=_inc_vbum1 
    inc x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1731] cputcxy::x#16 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1732] cputcxy::y#16 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1733] call cputcxy
    // [2167] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [2167] phi cputcxy::c#18 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'!'
    sta cputcxy.c
    // [2167] phi cputcxy::y#18 = cputcxy::y#16 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#16 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@31
    // flash_errors_sector++;
    // [1734] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#11 -- vwum1=_inc_vwum1 
    inc flash_errors_sector
    bne !+
    inc flash_errors_sector+1
  !:
    jmp __b10
  .segment Data
    s: .text "--------"
    .byte 0
    s1: .text "........"
    .byte 0
    s2: .text " flash errors ..."
    .byte 0
    rom_address_sector: .dword 0
    rom_boundary: .dword 0
    .label equal_bytes = rom_compare.equal_bytes
    rom_sector_boundary: .dword 0
    equal_bytes_1: .word 0
    retries: .byte 0
    flash_errors_sector: .word 0
    rom_address: .dword 0
    x: .byte 0
    flash_errors: .dword 0
    // We start for ROM from 0x0:0x7800 !!!!
    bram_bank_sector: .byte 0
    x_sector: .byte 0
    y_sector: .byte 0
    rom_chip: .byte 0
    .label rom_bank_start = rom_address_from_bank.rom_bank
    file_size: .dword 0
    .label return = flash_errors
}
.segment Code
  // smc_flash
/**
 * @brief Flash the SMC using the new firmware stored in RAM.
 * The bootloader starts from address 0x1E00 in the SMC, and should never be overwritten!
 * The flashing starts by pressing the POWER and RESET button on the CX16 board simultaneously.
 * 
 * @param smc_bytes_total Total bytes to flash the SMC from RAM.
 * @return unsigned int Total bytes flashed, 0 if there is an error.
 */
// __mem() unsigned int smc_flash(__mem() unsigned int smc_bytes_total)
smc_flash: {
    .const smc_bram_bank = 1
    .label smc_flash__29 = $78
    .label smc_flash__30 = $78
    .label smc_bram_ptr = $6c
    // smc_flash::bank_set_bram1
    // BRAM = bank
    // [1736] BRAM = smc_flash::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1737] phi from smc_flash::bank_set_bram1 to smc_flash::@24 [phi:smc_flash::bank_set_bram1->smc_flash::@24]
    // smc_flash::@24
    // display_action_progress("To start the SMC update, do the following ...")
    // [1738] call display_action_progress
    // [874] phi from smc_flash::@24 to display_action_progress [phi:smc_flash::@24->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = smc_flash::info_text [phi:smc_flash::@24->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@28
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1739] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1740] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1741] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1742] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // return result;
    // [1744] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbum1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta cx16_k_i2c_write_byte1_return
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1745] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1746] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [1747] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbum1_then_la1 
    lda smc_bootloader_start
    beq __b6
    // [1748] phi from smc_flash::@25 to smc_flash::@2 [phi:smc_flash::@25->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1749] call snprintf_init
    // [1167] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1750] phi from smc_flash::@2 to smc_flash::@29 [phi:smc_flash::@2->smc_flash::@29]
    // smc_flash::@29
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1751] call printf_str
    // [1172] phi from smc_flash::@29 to printf_str [phi:smc_flash::@29->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = smc_flash::s [phi:smc_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1752] printf_uchar::uvalue#13 = smc_flash::smc_bootloader_start#0 -- vbum1=vbum2 
    lda smc_bootloader_start
    sta printf_uchar.uvalue
    // [1753] call printf_uchar
    // [1307] phi from smc_flash::@30 to printf_uchar [phi:smc_flash::@30->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:smc_flash::@30->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:smc_flash::@30->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:smc_flash::@30->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:smc_flash::@30->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#13 [phi:smc_flash::@30->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1754] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1755] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1757] call display_action_text
    // [1318] phi from smc_flash::@31 to display_action_text [phi:smc_flash::@31->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:smc_flash::@31->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@32
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1758] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1759] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1760] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1761] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1763] phi from smc_flash::@50 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@50/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1763] phi smc_flash::return#1 = 0 [phi:smc_flash::@50/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // smc_flash::@return
    // }
    // [1764] return 
    rts
    // [1765] phi from smc_flash::@25 to smc_flash::@3 [phi:smc_flash::@25->smc_flash::@3]
  __b6:
    // [1765] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@25->smc_flash::@3#0] -- vbum1=vbuc1 
    lda #$80
    sta smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1766] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1767] phi from smc_flash::@3 smc_flash::@33 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@33->smc_flash::@7]
  __b9:
    // [1767] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@33->smc_flash::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1768] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1769] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1770] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1771] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1772] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@45
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1773] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#10
    // if(smc_bootloader_not_activated)
    // [1774] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwum1_then_la1 
    lda smc_bootloader_not_activated
    ora smc_bootloader_not_activated+1
    beq __b1
    // [1775] phi from smc_flash::@45 to smc_flash::@10 [phi:smc_flash::@45->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1776] call snprintf_init
    // [1167] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1777] phi from smc_flash::@10 to smc_flash::@48 [phi:smc_flash::@10->smc_flash::@48]
    // smc_flash::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1778] call printf_str
    // [1172] phi from smc_flash::@48 to printf_str [phi:smc_flash::@48->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_flash::@48->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = smc_flash::s5 [phi:smc_flash::@48->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@49
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1779] printf_uint::uvalue#6 = smc_flash::smc_bootloader_not_activated#1
    // [1780] call printf_uint
    // [2254] phi from smc_flash::@49 to printf_uint [phi:smc_flash::@49->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 0 [phi:smc_flash::@49->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 0 [phi:smc_flash::@49->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@49->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@49->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = printf_uint::uvalue#6 [phi:smc_flash::@49->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@50
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1781] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1782] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1784] call display_action_text
    // [1318] phi from smc_flash::@50 to display_action_text [phi:smc_flash::@50->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:smc_flash::@50->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1785] phi from smc_flash::@45 to smc_flash::@1 [phi:smc_flash::@45->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1786] call display_action_progress
    // [874] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1787] phi from smc_flash::@1 to smc_flash::@46 [phi:smc_flash::@1->smc_flash::@46]
    // smc_flash::@46
    // textcolor(WHITE)
    // [1788] call textcolor
    // [754] phi from smc_flash::@46 to textcolor [phi:smc_flash::@46->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:smc_flash::@46->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1789] phi from smc_flash::@46 to smc_flash::@47 [phi:smc_flash::@46->smc_flash::@47]
    // smc_flash::@47
    // gotoxy(x, y)
    // [1790] call gotoxy
    // [772] phi from smc_flash::@47 to gotoxy [phi:smc_flash::@47->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y [phi:smc_flash::@47->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:smc_flash::@47->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1791] phi from smc_flash::@47 to smc_flash::@11 [phi:smc_flash::@47->smc_flash::@11]
    // [1791] phi smc_flash::y#36 = PROGRESS_Y [phi:smc_flash::@47->smc_flash::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1791] phi smc_flash::smc_row_bytes#16 = 0 [phi:smc_flash::@47->smc_flash::@11#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1791] phi smc_flash::smc_bram_ptr#14 = (char *)$a000 [phi:smc_flash::@47->smc_flash::@11#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // [1791] phi smc_flash::smc_bytes_flashed#13 = 0 [phi:smc_flash::@47->smc_flash::@11#3] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [1791] phi from smc_flash::@15 to smc_flash::@11 [phi:smc_flash::@15->smc_flash::@11]
    // [1791] phi smc_flash::y#36 = smc_flash::y#21 [phi:smc_flash::@15->smc_flash::@11#0] -- register_copy 
    // [1791] phi smc_flash::smc_row_bytes#16 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@15->smc_flash::@11#1] -- register_copy 
    // [1791] phi smc_flash::smc_bram_ptr#14 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@15->smc_flash::@11#2] -- register_copy 
    // [1791] phi smc_flash::smc_bytes_flashed#13 = smc_flash::smc_bytes_flashed#12 [phi:smc_flash::@15->smc_flash::@11#3] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1792] if(smc_flash::smc_bytes_flashed#13<smc_flash::smc_bytes_total#0) goto smc_flash::@13 -- vwum1_lt_vwum2_then_la1 
    lda smc_bytes_flashed+1
    cmp smc_bytes_total+1
    bcc __b10
    bne !+
    lda smc_bytes_flashed
    cmp smc_bytes_total
    bcc __b10
  !:
    // smc_flash::@12
    // display_action_text_flashed(smc_bytes_flashed, "SMC")
    // [1793] display_action_text_flashed::bytes#1 = smc_flash::smc_bytes_flashed#13 -- vdum1=vwum2 
    lda smc_bytes_flashed
    sta display_action_text_flashed.bytes
    lda smc_bytes_flashed+1
    sta display_action_text_flashed.bytes+1
    lda #0
    sta display_action_text_flashed.bytes+2
    sta display_action_text_flashed.bytes+3
    // [1794] call display_action_text_flashed
    // [2837] phi from smc_flash::@12 to display_action_text_flashed [phi:smc_flash::@12->display_action_text_flashed]
    // [2837] phi display_action_text_flashed::chip#3 = smc_flash::chip [phi:smc_flash::@12->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2837] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#1 [phi:smc_flash::@12->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1763] phi from smc_flash::@12 to smc_flash::@return [phi:smc_flash::@12->smc_flash::@return]
    // [1763] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#13 [phi:smc_flash::@12->smc_flash::@return#0] -- register_copy 
    rts
    // [1795] phi from smc_flash::@11 to smc_flash::@13 [phi:smc_flash::@11->smc_flash::@13]
  __b10:
    // [1795] phi smc_flash::y#21 = smc_flash::y#36 [phi:smc_flash::@11->smc_flash::@13#0] -- register_copy 
    // [1795] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#16 [phi:smc_flash::@11->smc_flash::@13#1] -- register_copy 
    // [1795] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#13 [phi:smc_flash::@11->smc_flash::@13#2] -- register_copy 
    // [1795] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#14 [phi:smc_flash::@11->smc_flash::@13#3] -- register_copy 
    // [1795] phi smc_flash::smc_attempts_flashed#15 = 0 [phi:smc_flash::@11->smc_flash::@13#4] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1795] phi smc_flash::smc_package_committed#10 = 0 [phi:smc_flash::@11->smc_flash::@13#5] -- vbum1=vbuc1 
    sta smc_package_committed
    // smc_flash::@13
  __b13:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1796] if(0!=smc_flash::smc_package_committed#10) goto smc_flash::@15 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b15
    // smc_flash::@55
    // [1797] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b14
    // smc_flash::@15
  __b15:
    // if(smc_attempts_flashed >= 10)
    // [1798] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1799] phi from smc_flash::@15 to smc_flash::@23 [phi:smc_flash::@15->smc_flash::@23]
    // smc_flash::@23
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1800] call snprintf_init
    // [1167] phi from smc_flash::@23 to snprintf_init [phi:smc_flash::@23->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:smc_flash::@23->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1801] phi from smc_flash::@23 to smc_flash::@52 [phi:smc_flash::@23->smc_flash::@52]
    // smc_flash::@52
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1802] call printf_str
    // [1172] phi from smc_flash::@52 to printf_str [phi:smc_flash::@52->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_flash::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = smc_flash::s6 [phi:smc_flash::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@53
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1803] printf_uint::uvalue#7 = smc_flash::smc_bytes_flashed#12 -- vwum1=vwum2 
    lda smc_bytes_flashed
    sta printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1804] call printf_uint
    // [2254] phi from smc_flash::@53 to printf_uint [phi:smc_flash::@53->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_flash::@53->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 4 [phi:smc_flash::@53->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@53->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = printf_uint::uvalue#7 [phi:smc_flash::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@54
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1805] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1806] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1808] call display_action_text
    // [1318] phi from smc_flash::@54 to display_action_text [phi:smc_flash::@54->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:smc_flash::@54->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1763] phi from smc_flash::@54 to smc_flash::@return [phi:smc_flash::@54->smc_flash::@return]
    // [1763] phi smc_flash::return#1 = $ffff [phi:smc_flash::@54->smc_flash::@return#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta return
    lda #>$ffff
    sta return+1
    rts
    // smc_flash::@14
  __b14:
    // display_action_text_flashing(8, "SMC", smc_bram_bank, smc_bram_ptr, smc_bytes_flashed)
    // [1809] display_action_text_flashing::bram_ptr#1 = smc_flash::smc_bram_ptr#12 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1810] display_action_text_flashing::address#1 = smc_flash::smc_bytes_flashed#12 -- vdum1=vwum2 
    lda smc_bytes_flashed
    sta display_action_text_flashing.address
    lda smc_bytes_flashed+1
    sta display_action_text_flashing.address+1
    lda #0
    sta display_action_text_flashing.address+2
    sta display_action_text_flashing.address+3
    // [1811] call display_action_text_flashing
    // [2854] phi from smc_flash::@14 to display_action_text_flashing [phi:smc_flash::@14->display_action_text_flashing]
    // [2854] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#1 [phi:smc_flash::@14->display_action_text_flashing#0] -- register_copy 
    // [2854] phi display_action_text_flashing::chip#10 = smc_flash::chip [phi:smc_flash::@14->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2854] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#1 [phi:smc_flash::@14->display_action_text_flashing#2] -- register_copy 
    // [2854] phi display_action_text_flashing::bram_bank#3 = smc_flash::smc_bram_bank [phi:smc_flash::@14->display_action_text_flashing#3] -- vbum1=vbuc1 
    lda #smc_bram_bank
    sta display_action_text_flashing.bram_bank
    // [2854] phi display_action_text_flashing::bytes#3 = 8 [phi:smc_flash::@14->display_action_text_flashing#4] -- vdum1=vbuc1 
    lda #8
    sta display_action_text_flashing.bytes
    lda #0
    sta display_action_text_flashing.bytes+1
    sta display_action_text_flashing.bytes+2
    sta display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [1812] phi from smc_flash::@14 to smc_flash::@16 [phi:smc_flash::@14->smc_flash::@16]
    // [1812] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@14->smc_flash::@16#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [1812] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@14->smc_flash::@16#1] -- register_copy 
    // [1812] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@14->smc_flash::@16#2] -- vwum1=vwuc1 
    sta smc_package_flashed
    sta smc_package_flashed+1
    // smc_flash::@16
  __b16:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1813] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@17 -- vwum1_lt_vbuc1_then_la1 
    lda smc_package_flashed+1
    bne !+
    lda smc_package_flashed
    cmp #SMC_PROGRESS_CELL
    bcs !__b17+
    jmp __b17
  !__b17:
  !:
    // smc_flash::@18
    // smc_bytes_checksum ^ 0xFF
    // [1814] smc_flash::$29 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbum2_bxor_vbuc1 
    lda #$ff
    eor smc_bytes_checksum
    sta.z smc_flash__29
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1815] smc_flash::$30 = smc_flash::$29 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z smc_flash__30
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1816] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1817] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1818] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$30 -- vbum1=vbuz2 
    lda.z smc_flash__30
    sta cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1819] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte4_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte4_device
    ldy cx16_k_i2c_write_byte4_offset
    lda cx16_k_i2c_write_byte4_value
    stz cx16_k_i2c_write_byte4_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte4_result
    // smc_flash::@27
    // unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT)
    // [1821] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1822] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1823] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1824] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@51
    // [1825] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#11
    // if(smc_commit_result == 1)
    // [1826] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@20 -- vwum1_eq_vbuc1_then_la1 
    lda smc_commit_result+1
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b20
  !:
    // smc_flash::@19
    // smc_bram_ptr -= SMC_PROGRESS_CELL
    // [1827] smc_flash::smc_bram_ptr#2 = smc_flash::smc_bram_ptr#10 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_bram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    sbc #0
    sta.z smc_bram_ptr+1
    // smc_attempts_flashed++;
    // [1828] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#15 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1795] phi from smc_flash::@19 to smc_flash::@13 [phi:smc_flash::@19->smc_flash::@13]
    // [1795] phi smc_flash::y#21 = smc_flash::y#21 [phi:smc_flash::@19->smc_flash::@13#0] -- register_copy 
    // [1795] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@19->smc_flash::@13#1] -- register_copy 
    // [1795] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#12 [phi:smc_flash::@19->smc_flash::@13#2] -- register_copy 
    // [1795] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#2 [phi:smc_flash::@19->smc_flash::@13#3] -- register_copy 
    // [1795] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@19->smc_flash::@13#4] -- register_copy 
    // [1795] phi smc_flash::smc_package_committed#10 = smc_flash::smc_package_committed#10 [phi:smc_flash::@19->smc_flash::@13#5] -- register_copy 
    jmp __b13
    // smc_flash::@20
  __b20:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1829] if(smc_flash::smc_row_bytes#11!=SMC_PROGRESS_ROW) goto smc_flash::@21 -- vwum1_neq_vwuc1_then_la1 
    lda smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b21
    lda smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b21
    // smc_flash::@22
    // gotoxy(x, ++y);
    // [1830] smc_flash::y#1 = ++ smc_flash::y#21 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1831] gotoxy::y#30 = smc_flash::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1832] call gotoxy
    // [772] phi from smc_flash::@22 to gotoxy [phi:smc_flash::@22->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#30 [phi:smc_flash::@22->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:smc_flash::@22->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1833] phi from smc_flash::@22 to smc_flash::@21 [phi:smc_flash::@22->smc_flash::@21]
    // [1833] phi smc_flash::y#38 = smc_flash::y#1 [phi:smc_flash::@22->smc_flash::@21#0] -- register_copy 
    // [1833] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@22->smc_flash::@21#1] -- vwum1=vbuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1833] phi from smc_flash::@20 to smc_flash::@21 [phi:smc_flash::@20->smc_flash::@21]
    // [1833] phi smc_flash::y#38 = smc_flash::y#21 [phi:smc_flash::@20->smc_flash::@21#0] -- register_copy 
    // [1833] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@20->smc_flash::@21#1] -- register_copy 
    // smc_flash::@21
  __b21:
    // cputc('+')
    // [1834] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1835] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1837] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#12 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1838] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_row_bytes
    sta smc_row_bytes
    bcc !+
    inc smc_row_bytes+1
  !:
    // [1795] phi from smc_flash::@21 to smc_flash::@13 [phi:smc_flash::@21->smc_flash::@13]
    // [1795] phi smc_flash::y#21 = smc_flash::y#38 [phi:smc_flash::@21->smc_flash::@13#0] -- register_copy 
    // [1795] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@21->smc_flash::@13#1] -- register_copy 
    // [1795] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@21->smc_flash::@13#2] -- register_copy 
    // [1795] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#10 [phi:smc_flash::@21->smc_flash::@13#3] -- register_copy 
    // [1795] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#15 [phi:smc_flash::@21->smc_flash::@13#4] -- register_copy 
    // [1795] phi smc_flash::smc_package_committed#10 = 1 [phi:smc_flash::@21->smc_flash::@13#5] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b13
    // smc_flash::@17
  __b17:
    // unsigned char smc_byte_upload = *smc_bram_ptr
    // [1839] smc_flash::smc_byte_upload#0 = *smc_flash::smc_bram_ptr#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_bram_ptr),y
    sta smc_byte_upload
    // smc_bram_ptr++;
    // [1840] smc_flash::smc_bram_ptr#1 = ++ smc_flash::smc_bram_ptr#10 -- pbuz1=_inc_pbuz1 
    inc.z smc_bram_ptr
    bne !+
    inc.z smc_bram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1841] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbum1=vbum1_plus_vbum2 
    lda smc_bytes_checksum
    clc
    adc smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1842] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1843] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1844] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1845] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte3_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte3_device
    ldy cx16_k_i2c_write_byte3_offset
    lda cx16_k_i2c_write_byte3_value
    stz cx16_k_i2c_write_byte3_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte3_result
    // smc_flash::@26
    // smc_package_flashed++;
    // [1847] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwum1=_inc_vwum1 
    inc smc_package_flashed
    bne !+
    inc smc_package_flashed+1
  !:
    // [1812] phi from smc_flash::@26 to smc_flash::@16 [phi:smc_flash::@26->smc_flash::@16]
    // [1812] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@26->smc_flash::@16#0] -- register_copy 
    // [1812] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#1 [phi:smc_flash::@26->smc_flash::@16#1] -- register_copy 
    // [1812] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@26->smc_flash::@16#2] -- register_copy 
    jmp __b16
    // [1848] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment(1)
    // [1849] call wait_moment
    // [1270] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    // [1270] phi wait_moment::w#13 = 1 [phi:smc_flash::@8->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [1850] phi from smc_flash::@8 to smc_flash::@39 [phi:smc_flash::@8->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1851] call snprintf_init
    // [1167] phi from smc_flash::@39 to snprintf_init [phi:smc_flash::@39->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:smc_flash::@39->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1852] phi from smc_flash::@39 to smc_flash::@40 [phi:smc_flash::@39->smc_flash::@40]
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1853] call printf_str
    // [1172] phi from smc_flash::@40 to printf_str [phi:smc_flash::@40->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_flash::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = smc_flash::s3 [phi:smc_flash::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@41
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1854] printf_uchar::uvalue#15 = smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta printf_uchar.uvalue
    // [1855] call printf_uchar
    // [1307] phi from smc_flash::@41 to printf_uchar [phi:smc_flash::@41->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:smc_flash::@41->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:smc_flash::@41->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:smc_flash::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:smc_flash::@41->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#15 [phi:smc_flash::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1856] phi from smc_flash::@41 to smc_flash::@42 [phi:smc_flash::@41->smc_flash::@42]
    // smc_flash::@42
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1857] call printf_str
    // [1172] phi from smc_flash::@42 to printf_str [phi:smc_flash::@42->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_flash::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s6 [phi:smc_flash::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s6
    sta.z printf_str.s
    lda #>@s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@43
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1858] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1859] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1861] call display_action_text
    // [1318] phi from smc_flash::@43 to display_action_text [phi:smc_flash::@43->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:smc_flash::@43->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@44
    // smc_bootloader_activation_countdown--;
    // [1862] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1767] phi from smc_flash::@44 to smc_flash::@7 [phi:smc_flash::@44->smc_flash::@7]
    // [1767] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@44->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1863] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1864] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1865] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1866] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@33
    // [1867] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [1868] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1869] phi from smc_flash::@33 to smc_flash::@5 [phi:smc_flash::@33->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment(1)
    // [1870] call wait_moment
    // [1270] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    // [1270] phi wait_moment::w#13 = 1 [phi:smc_flash::@5->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [1871] phi from smc_flash::@5 to smc_flash::@34 [phi:smc_flash::@5->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1872] call snprintf_init
    // [1167] phi from smc_flash::@34 to snprintf_init [phi:smc_flash::@34->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:smc_flash::@34->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1873] phi from smc_flash::@34 to smc_flash::@35 [phi:smc_flash::@34->smc_flash::@35]
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1874] call printf_str
    // [1172] phi from smc_flash::@35 to printf_str [phi:smc_flash::@35->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_flash::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s21 [phi:smc_flash::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@36
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1875] printf_uchar::uvalue#14 = smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown
    sta printf_uchar.uvalue
    // [1876] call printf_uchar
    // [1307] phi from smc_flash::@36 to printf_uchar [phi:smc_flash::@36->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:smc_flash::@36->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 3 [phi:smc_flash::@36->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:smc_flash::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:smc_flash::@36->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#14 [phi:smc_flash::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1877] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1878] call printf_str
    // [1172] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = smc_flash::s2 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1879] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1880] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1882] call display_action_text
    // [1318] phi from smc_flash::@38 to display_action_text [phi:smc_flash::@38->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:smc_flash::@38->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [1883] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1765] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1765] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
    jmp __b3
  .segment Data
    info_text: .text "To start the SMC update, do the following ..."
    .byte 0
    s: .text "There was a problem starting the SMC bootloader: "
    .byte 0
    s2: .text "] Press POWER and RESET on the CX16 to start the SMC update!"
    .byte 0
    s3: .text "Updating SMC in "
    .byte 0
    info_text1: .text "Updating SMC firmware ... (+) Updated"
    .byte 0
    s5: .text "There was a problem activating the SMC bootloader: "
    .byte 0
    chip: .text "SMC"
    .byte 0
    s6: .text "There were too many attempts trying to flash the SMC at location "
    .byte 0
    cx16_k_i2c_write_byte1_device: .byte 0
    cx16_k_i2c_write_byte1_offset: .byte 0
    cx16_k_i2c_write_byte1_value: .byte 0
    cx16_k_i2c_write_byte1_result: .byte 0
    cx16_k_i2c_write_byte2_device: .byte 0
    cx16_k_i2c_write_byte2_offset: .byte 0
    cx16_k_i2c_write_byte2_value: .byte 0
    cx16_k_i2c_write_byte2_result: .byte 0
    cx16_k_i2c_write_byte3_device: .byte 0
    cx16_k_i2c_write_byte3_offset: .byte 0
    cx16_k_i2c_write_byte3_value: .byte 0
    cx16_k_i2c_write_byte3_result: .byte 0
    cx16_k_i2c_write_byte4_device: .byte 0
    cx16_k_i2c_write_byte4_offset: .byte 0
    cx16_k_i2c_write_byte4_value: .byte 0
    cx16_k_i2c_write_byte4_result: .byte 0
    cx16_k_i2c_write_byte1_return: .byte 0
    .label smc_bootloader_start = cx16_k_i2c_write_byte1_return
    return: .word 0
    .label smc_bootloader_not_activated1 = printf_uint.uvalue
    // Waiting a bit to ensure the bootloader is activated.
    smc_bootloader_activation_countdown: .byte 0
    // Waiting a bit to ensure the bootloader is activated.
    smc_bootloader_activation_countdown_1: .byte 0
    .label smc_bootloader_not_activated = printf_uint.uvalue
    smc_byte_upload: .byte 0
    smc_bytes_checksum: .byte 0
    smc_package_flashed: .word 0
    .label smc_commit_result = printf_uint.uvalue
    smc_attempts_flashed: .byte 0
    .label smc_bytes_flashed = return
    smc_row_bytes: .word 0
    y: .byte 0
    smc_bytes_total: .word 0
    smc_package_committed: .byte 0
}
.segment Code
  // util_wait_key
/**
 * @brief 
 * 
 * @param info_text 
 * @param filter 
 * @return unsigned char 
 */
// __mem() char util_wait_key(__zp($35) char *info_text, __zp($4f) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__9 = $5f
    .label info_text = $35
    .label filter = $4f
    // display_action_text(info_text)
    // [1885] display_action_text::info_text#12 = util_wait_key::info_text#3
    // [1886] call display_action_text
    // [1318] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1318] phi display_action_text::info_text#23 = display_action_text::info_text#12 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1887] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1888] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1889] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1890] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1891] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1893] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1894] call cbm_k_getin
    jsr cbm_k_getin
    // [1895] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1896] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbum2 
    lda cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [1897] if((char *)0!=util_wait_key::filter#13) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1898] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1899] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1900] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1901] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1902] strchr::str#0 = (const void *)util_wait_key::filter#13 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1903] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [1904] call strchr
    // [1908] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1908] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1908] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1905] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1906] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1907] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__9
    ora.z util_wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    bram: .byte 0
    bank_get_brom1_return: .byte 0
    return: .byte 0
    return_1: .byte 0
    ch: .word 0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($5f) void * strchr(__zp($5f) const void *str, __mem() char c)
strchr: {
    .label ptr = $5f
    .label return = $5f
    .label str = $5f
    // [1909] strchr::ptr#6 = (char *)strchr::str#2
    // [1910] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1910] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1911] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1912] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1912] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1913] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1914] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1915] strchr::return#8 = (void *)strchr::ptr#2
    // [1912] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1912] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1916] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
  // display_info_cx16_rom
/**
 * @brief Display the ROM status of the main CX16 ROM chip.
 * 
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_cx16_rom(__mem() char info_status, __zp($37) char *info_text)
display_info_cx16_rom: {
    .label info_text = $37
    // display_info_rom(0, info_status, info_text)
    // [1918] display_info_rom::info_status#0 = display_info_cx16_rom::info_status#4
    // [1919] display_info_rom::info_text#0 = display_info_cx16_rom::info_text#4
    // [1920] call display_info_rom
    // [1440] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = display_info_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1440] phi display_info_rom::rom_chip#17 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbum1=vbuc1 
    lda #0
    sta display_info_rom.rom_chip
    // [1440] phi display_info_rom::info_status#17 = display_info_rom::info_status#0 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1921] return 
    rts
  .segment Data
    .label info_status = display_info_rom.info_status
}
.segment Code
  // rom_get_github_commit_id
/**
 * @brief Copy the github commit_id only if the commit_id contains hexadecimal characters. 
 * 
 * @param commit_id The target commit_id.
 * @param from The source ptr in ROM or RAM.
 */
// void rom_get_github_commit_id(__zp($52) char *commit_id, __zp($37) char *from)
rom_get_github_commit_id: {
    .label commit_id = $52
    .label from = $37
    // [1923] phi from rom_get_github_commit_id to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2]
    // [1923] phi rom_get_github_commit_id::commit_id_ok#2 = true [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#0] -- vbom1=vboc1 
    lda #1
    sta commit_id_ok
    // [1923] phi rom_get_github_commit_id::c#2 = 0 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#1] -- vbum1=vbuc1 
    lda #0
    sta c
    // rom_get_github_commit_id::@2
  __b2:
    // for(unsigned char c=0; c<7; c++)
    // [1924] if(rom_get_github_commit_id::c#2<7) goto rom_get_github_commit_id::@3 -- vbum1_lt_vbuc1_then_la1 
    lda c
    cmp #7
    bcc __b3
    // rom_get_github_commit_id::@4
    // if(commit_id_ok)
    // [1925] if(rom_get_github_commit_id::commit_id_ok#2) goto rom_get_github_commit_id::@1 -- vbom1_then_la1 
    lda commit_id_ok
    cmp #0
    bne __b1
    // rom_get_github_commit_id::@6
    // *commit_id = '\0'
    // [1926] *rom_get_github_commit_id::commit_id#6 = '@' -- _deref_pbuz1=vbuc1 
    lda #'@'
    ldy #0
    sta (commit_id),y
    // rom_get_github_commit_id::@return
    // }
    // [1927] return 
    rts
    // rom_get_github_commit_id::@1
  __b1:
    // strncpy(commit_id, from, 7)
    // [1928] strncpy::dst#2 = rom_get_github_commit_id::commit_id#6
    // [1929] strncpy::src#2 = rom_get_github_commit_id::from#6
    // [1930] call strncpy
    // [2896] phi from rom_get_github_commit_id::@1 to strncpy [phi:rom_get_github_commit_id::@1->strncpy]
    // [2896] phi strncpy::dst#8 = strncpy::dst#2 [phi:rom_get_github_commit_id::@1->strncpy#0] -- register_copy 
    // [2896] phi strncpy::src#6 = strncpy::src#2 [phi:rom_get_github_commit_id::@1->strncpy#1] -- register_copy 
    // [2896] phi strncpy::n#3 = 7 [phi:rom_get_github_commit_id::@1->strncpy#2] -- vwum1=vbuc1 
    lda #<7
    sta strncpy.n
    lda #>7
    sta strncpy.n+1
    jsr strncpy
    rts
    // rom_get_github_commit_id::@3
  __b3:
    // unsigned char ch = from[c]
    // [1931] rom_get_github_commit_id::ch#0 = rom_get_github_commit_id::from#6[rom_get_github_commit_id::c#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy c
    lda (from),y
    sta ch
    // if(!(ch >= 48 && ch <= 48+9 || ch >= 65 && ch <= 65+26))
    // [1932] if(rom_get_github_commit_id::ch#0<$30) goto rom_get_github_commit_id::@7 -- vbum1_lt_vbuc1_then_la1 
    cmp #$30
    bcc __b7
    // rom_get_github_commit_id::@8
    // [1933] if(rom_get_github_commit_id::ch#0<$30+9+1) goto rom_get_github_commit_id::@5 -- vbum1_lt_vbuc1_then_la1 
    cmp #$30+9+1
    bcc __b5
    // rom_get_github_commit_id::@7
  __b7:
    // [1934] if(rom_get_github_commit_id::ch#0<$41) goto rom_get_github_commit_id::@5 -- vbum1_lt_vbuc1_then_la1 
    lda ch
    cmp #$41
    bcc __b4
    // rom_get_github_commit_id::@9
    // [1935] if(rom_get_github_commit_id::ch#0<$41+$1a+1) goto rom_get_github_commit_id::@10 -- vbum1_lt_vbuc1_then_la1 
    cmp #$41+$1a+1
    bcc __b5
    // [1937] phi from rom_get_github_commit_id::@7 rom_get_github_commit_id::@9 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5]
  __b4:
    // [1937] phi rom_get_github_commit_id::commit_id_ok#4 = false [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5#0] -- vbom1=vboc1 
    lda #0
    sta commit_id_ok
    // [1936] phi from rom_get_github_commit_id::@9 to rom_get_github_commit_id::@10 [phi:rom_get_github_commit_id::@9->rom_get_github_commit_id::@10]
    // rom_get_github_commit_id::@10
    // [1937] phi from rom_get_github_commit_id::@10 rom_get_github_commit_id::@8 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5]
    // [1937] phi rom_get_github_commit_id::commit_id_ok#4 = rom_get_github_commit_id::commit_id_ok#2 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5#0] -- register_copy 
    // rom_get_github_commit_id::@5
  __b5:
    // for(unsigned char c=0; c<7; c++)
    // [1938] rom_get_github_commit_id::c#1 = ++ rom_get_github_commit_id::c#2 -- vbum1=_inc_vbum1 
    inc c
    // [1923] phi from rom_get_github_commit_id::@5 to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2]
    // [1923] phi rom_get_github_commit_id::commit_id_ok#2 = rom_get_github_commit_id::commit_id_ok#4 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#0] -- register_copy 
    // [1923] phi rom_get_github_commit_id::c#2 = rom_get_github_commit_id::c#1 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#1] -- register_copy 
    jmp __b2
  .segment Data
    ch: .byte 0
    c: .byte 0
    commit_id_ok: .byte 0
}
.segment Code
  // rom_get_release
/**
 * @brief Calculate the correct ROM release number.
 * The 2's complement is taken if bit 7 is set of the release number.
 * 
 * @param release The raw release number.
 * @return unsigned char The release potentially taken 2's complement.
 */
// __mem() char rom_get_release(__mem() char release)
rom_get_release: {
    .label rom_get_release__0 = $5c
    .label rom_get_release__2 = $3b
    // release & 0x80
    // [1940] rom_get_release::$0 = rom_get_release::release#3 & $80 -- vbuz1=vbum2_band_vbuc1 
    lda #$80
    and release
    sta.z rom_get_release__0
    // if(release & 0x80)
    // [1941] if(0==rom_get_release::$0) goto rom_get_release::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // rom_get_release::@2
    // ~release
    // [1942] rom_get_release::$2 = ~ rom_get_release::release#3 -- vbuz1=_bnot_vbum2 
    lda release
    eor #$ff
    sta.z rom_get_release__2
    // release = ~release + 1
    // [1943] rom_get_release::release#0 = rom_get_release::$2 + 1 -- vbum1=vbuz2_plus_1 
    inc
    sta release
    // [1944] phi from rom_get_release rom_get_release::@2 to rom_get_release::@1 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1]
    // [1944] phi rom_get_release::return#0 = rom_get_release::release#3 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1#0] -- register_copy 
    // rom_get_release::@1
  __b1:
    // rom_get_release::@return
    // }
    // [1945] return 
    rts
  .segment Data
    return: .byte 0
    .label release = return
}
.segment Code
  // rom_get_prefix
/**
 * @brief Determine the prefix of the ROM release number.
 * If the version is 0xFF or bit 7 of the version is set, then the release is a preview.
 * 
 * @param rom_chip The ROM chip to calculate the release.
 * @param release The release potentially taken 2's complement.
 * @return unsigned char 'r' if the release is official, 'p' if the release is inofficial of 0xFF.
 */
// __mem() char rom_get_prefix(__mem() char release)
rom_get_prefix: {
    .label rom_get_prefix__2 = $5c
    // if(release == 0xFF)
    // [1947] if(rom_get_prefix::release#2!=$ff) goto rom_get_prefix::@1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp release
    bne __b3
    // [1948] phi from rom_get_prefix to rom_get_prefix::@3 [phi:rom_get_prefix->rom_get_prefix::@3]
    // rom_get_prefix::@3
    // [1949] phi from rom_get_prefix::@3 to rom_get_prefix::@1 [phi:rom_get_prefix::@3->rom_get_prefix::@1]
    // [1949] phi rom_get_prefix::prefix#4 = 'p' [phi:rom_get_prefix::@3->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'p'
    sta prefix
    jmp __b1
    // [1949] phi from rom_get_prefix to rom_get_prefix::@1 [phi:rom_get_prefix->rom_get_prefix::@1]
  __b3:
    // [1949] phi rom_get_prefix::prefix#4 = 'r' [phi:rom_get_prefix->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'r'
    sta prefix
    // rom_get_prefix::@1
  __b1:
    // release & 0x80
    // [1950] rom_get_prefix::$2 = rom_get_prefix::release#2 & $80 -- vbuz1=vbum2_band_vbuc1 
    lda #$80
    and release
    sta.z rom_get_prefix__2
    // if(release & 0x80)
    // [1951] if(0==rom_get_prefix::$2) goto rom_get_prefix::@4 -- 0_eq_vbuz1_then_la1 
    beq __b2
    // [1953] phi from rom_get_prefix::@1 to rom_get_prefix::@2 [phi:rom_get_prefix::@1->rom_get_prefix::@2]
    // [1953] phi rom_get_prefix::return#0 = 'p' [phi:rom_get_prefix::@1->rom_get_prefix::@2#0] -- vbum1=vbuc1 
    lda #'p'
    sta return
    rts
    // [1952] phi from rom_get_prefix::@1 to rom_get_prefix::@4 [phi:rom_get_prefix::@1->rom_get_prefix::@4]
    // rom_get_prefix::@4
    // [1953] phi from rom_get_prefix::@4 to rom_get_prefix::@2 [phi:rom_get_prefix::@4->rom_get_prefix::@2]
    // [1953] phi rom_get_prefix::return#0 = rom_get_prefix::prefix#4 [phi:rom_get_prefix::@4->rom_get_prefix::@2#0] -- register_copy 
    // rom_get_prefix::@2
  __b2:
    // rom_get_prefix::@return
    // }
    // [1954] return 
    rts
  .segment Data
    return: .byte 0
    release: .byte 0
    // If the release is 0xFF, then the release is a preview.
    // If bit 7 of the release is set, then the release is a preview.
    .label prefix = return
}
.segment Code
  // rom_get_version_text
// void rom_get_version_text(__zp($40) char *release_info, __mem() char prefix, __mem() char release, __zp($3e) char *github)
rom_get_version_text: {
    .label release_info = $40
    .label github = $3e
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1956] snprintf_init::s#12 = rom_get_version_text::release_info#2
    // [1957] call snprintf_init
    // [1167] phi from rom_get_version_text to snprintf_init [phi:rom_get_version_text->snprintf_init]
    // [1167] phi snprintf_init::s#33 = snprintf_init::s#12 [phi:rom_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // rom_get_version_text::@1
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1958] stackpush(char) = rom_get_version_text::prefix#2 -- _stackpushbyte_=vbum1 
    lda prefix
    pha
    // [1959] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1961] printf_uchar::uvalue#16 = rom_get_version_text::release#2 -- vbum1=vbum2 
    lda release
    sta printf_uchar.uvalue
    // [1962] call printf_uchar
    // [1307] phi from rom_get_version_text::@1 to printf_uchar [phi:rom_get_version_text::@1->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:rom_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:rom_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:rom_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:rom_get_version_text::@1->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#16 [phi:rom_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1963] phi from rom_get_version_text::@1 to rom_get_version_text::@2 [phi:rom_get_version_text::@1->rom_get_version_text::@2]
    // rom_get_version_text::@2
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1964] call printf_str
    // [1172] phi from rom_get_version_text::@2 to printf_str [phi:rom_get_version_text::@2->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:rom_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:rom_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@3
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1965] printf_string::str#16 = rom_get_version_text::github#2 -- pbuz1=pbuz2 
    lda.z github
    sta.z printf_string.str
    lda.z github+1
    sta.z printf_string.str+1
    // [1966] call printf_string
    // [1181] phi from rom_get_version_text::@3 to printf_string [phi:rom_get_version_text::@3->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:rom_get_version_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#16 [phi:rom_get_version_text::@3->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:rom_get_version_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:rom_get_version_text::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // rom_get_version_text::@4
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1967] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1968] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_get_version_text::@return
    // }
    // [1970] return 
    rts
  .segment Data
    prefix: .byte 0
    release: .byte 0
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $5e
    .label screenlayer__1 = $5d
    .label screenlayer__2 = $ba
    .label screenlayer__5 = $b7
    .label screenlayer__6 = $b7
    .label screenlayer__7 = $b6
    .label screenlayer__8 = $b6
    .label screenlayer__9 = $b4
    .label screenlayer__10 = $b4
    .label screenlayer__11 = $b4
    .label screenlayer__12 = $b5
    .label screenlayer__13 = $b5
    .label screenlayer__14 = $b5
    .label screenlayer__16 = $b6
    .label screenlayer__17 = $ad
    .label screenlayer__18 = $b4
    .label screenlayer__19 = $b5
    .label y = $7f
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1971] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1972] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1973] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1974] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1975] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1976] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1977] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1978] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1979] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1980] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1981] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1982] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1983] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1984] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1985] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [1986] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1987] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1988] screenlayer::$18 = (char)screenlayer::$9
    // [1989] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1990] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1991] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1992] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1993] screenlayer::$19 = (char)screenlayer::$12
    // [1994] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1995] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1996] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1997] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1998] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1998] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1998] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1999] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [2000] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [2001] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [2002] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [2003] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [2004] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1998] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1998] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1998] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    mapbase: .byte 0
    config: .byte 0
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
    mapbase_offset: .word 0
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [2005] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [2006] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [2007] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [2008] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [2009] call gotoxy
    // [772] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [772] phi gotoxy::y#38 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [2010] return 
    rts
    // [2011] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [2012] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [2013] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [2014] call gotoxy
    // [772] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [2015] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [2016] call clearline
    jsr clearline
    rts
}
  // cx16_k_screen_set_mode
/**
 * @brief Sets the screen mode.
 *
 * @return cx16_k_screen_mode_error_t Contains 1 if there is an error.
 */
// char cx16_k_screen_set_mode(__mem() volatile char mode)
cx16_k_screen_set_mode: {
    // cx16_k_screen_mode_error_t error = 0
    // [2017] cx16_k_screen_set_mode::error = 0 -- vbum1=vbuc1 
    lda #0
    sta error
    // asm
    // asm { clc ldamode jsrCX16_SCREEN_MODE rolerror  }
    clc
    lda mode
    jsr CX16_SCREEN_MODE
    rol error
    // cx16_k_screen_set_mode::@return
    // }
    // [2019] return 
    rts
  .segment Data
    mode: .byte 0
    error: .byte 0
}
.segment Code
  // display_frame
/**
 * @brief Draw a rectangle or a line given the coordinates.
 * Draw a line horizontal from a given xy position and a given length.  
 * The line should calculate the matching characters to draw and glue them.  
 * So it first needs to peek the characters at the given position.  
 * And then calculate the resulting characters to draw.
 * 
 * @param x0 Left up X position, counting from 0.
 * @param y0 Left up Y position, counting from 0,
 * @param x1 Right down X position, counting from 0.
 * @param y1 Right down Y position, counting from 0.
 */
// void display_frame(char x0, char y0, __mem() char x1, __mem() char y1)
display_frame: {
    // unsigned char w = x1 - x0
    // [2021] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbum2_minus_vbum3 
    lda x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [2022] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2023] display_frame_maskxy::x#0 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2024] display_frame_maskxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2025] call display_frame_maskxy
    // [2940] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2940] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [2940] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2026] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [2027] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [2028] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = display_frame_char(mask)
    // [2029] display_frame_char::mask#0 = display_frame::mask#1
    // [2030] call display_frame_char
  // Add a corner.
    // [2966] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2966] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [2031] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [2032] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [2033] cputcxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2034] cputcxy::y#3 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2035] cputcxy::c#3 = display_frame::c#0
    // [2036] call cputcxy
    // [2167] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#3 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#3 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#3 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [2037] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [2038] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [2039] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [2039] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [2040] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [2041] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [2041] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [2042] display_frame_maskxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta display_frame_maskxy.x
    // [2043] display_frame_maskxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2044] call display_frame_maskxy
    // [2940] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2940] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [2940] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2045] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [2046] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [2047] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2048] display_frame_char::mask#1 = display_frame::mask#3
    // [2049] call display_frame_char
    // [2966] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2966] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2050] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [2051] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [2052] cputcxy::x#4 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [2053] cputcxy::y#4 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2054] cputcxy::c#4 = display_frame::c#1
    // [2055] call cputcxy
    // [2167] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#4 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#4 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#4 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [2056] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [2057] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [2058] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [2058] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [2059] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbum2_then_la1 
    lda y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [2060] display_frame_maskxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2061] display_frame_maskxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2062] call display_frame_maskxy
    // [2940] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2940] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [2940] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2063] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [2064] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [2065] display_frame::mask#11 = display_frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2066] display_frame_char::mask#5 = display_frame::mask#11
    // [2067] call display_frame_char
    // [2966] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2966] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2068] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [2069] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [2070] cputcxy::x#8 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2071] cputcxy::y#8 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2072] cputcxy::c#8 = display_frame::c#5
    // [2073] call cputcxy
    // [2167] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#8 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#8 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#8 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [2074] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [2075] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [2076] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [2076] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [2077] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbum2_then_la1 
    lda x
    cmp x1
    bcc __b12
    // [2078] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [2078] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [2079] display_frame_maskxy::x#6 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2080] display_frame_maskxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2081] call display_frame_maskxy
    // [2940] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2940] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [2940] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2082] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [2083] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [2084] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2085] display_frame_char::mask#6 = display_frame::mask#13
    // [2086] call display_frame_char
    // [2966] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2966] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2087] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [2088] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [2089] cputcxy::x#9 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2090] cputcxy::y#9 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2091] cputcxy::c#9 = display_frame::c#6
    // [2092] call cputcxy
    // [2167] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#9 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#9 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#9 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [2093] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [2094] display_frame_maskxy::x#7 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2095] display_frame_maskxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2096] call display_frame_maskxy
    // [2940] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2940] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [2940] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2097] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [2098] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [2099] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2100] display_frame_char::mask#7 = display_frame::mask#15
    // [2101] call display_frame_char
    // [2966] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2966] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2102] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [2103] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [2104] cputcxy::x#10 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2105] cputcxy::y#10 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2106] cputcxy::c#10 = display_frame::c#7
    // [2107] call cputcxy
    // [2167] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#10 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#10 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#10 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [2108] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [2109] display_frame_maskxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2110] display_frame_maskxy::y#3 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2111] call display_frame_maskxy
    // [2940] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2940] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [2940] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [2112] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [2113] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [2114] display_frame::mask#7 = display_frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2115] display_frame_char::mask#3 = display_frame::mask#7
    // [2116] call display_frame_char
    // [2966] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2966] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2117] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [2118] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [2119] cputcxy::x#6 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2120] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2121] cputcxy::c#6 = display_frame::c#3
    // [2122] call cputcxy
    // [2167] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#6 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#6 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#6 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [2123] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta display_frame_maskxy.x
    // [2124] display_frame_maskxy::y#4 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2125] call display_frame_maskxy
    // [2940] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2940] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [2940] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [2126] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [2127] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [2128] display_frame::mask#9 = display_frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2129] display_frame_char::mask#4 = display_frame::mask#9
    // [2130] call display_frame_char
    // [2966] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2966] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2131] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [2132] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [2133] cputcxy::x#7 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [2134] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2135] cputcxy::c#7 = display_frame::c#4
    // [2136] call cputcxy
    // [2167] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#7 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#7 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#7 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [2137] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [2138] display_frame_maskxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta display_frame_maskxy.x
    // [2139] display_frame_maskxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2140] call display_frame_maskxy
    // [2940] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2940] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [2940] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2141] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [2142] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [2143] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2144] display_frame_char::mask#2 = display_frame::mask#5
    // [2145] call display_frame_char
    // [2966] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2966] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2146] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [2147] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [2148] cputcxy::x#5 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [2149] cputcxy::y#5 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2150] cputcxy::c#5 = display_frame::c#2
    // [2151] call cputcxy
    // [2167] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#5 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#5 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#5 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [2152] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [2153] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta x_1
    jmp __b1
  .segment Data
    w: .byte 0
    h: .byte 0
    x: .byte 0
    y: .byte 0
    .label mask = display_frame_maskxy.return
    .label c = cputcxy.c
    x_1: .byte 0
    y_1: .byte 0
    x1: .byte 0
    y1: .byte 0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($3e) const char *s)
cputs: {
    .label s = $3e
    // [2155] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [2155] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [2156] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [2157] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [2158] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [2159] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [2160] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [2161] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
  // wherex
// Return the x position of the cursor
wherex: {
    // return __conio.cursor_x;
    // [2163] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [2164] return 
    rts
  .segment Data
    return: .byte 0
    return_1: .byte 0
    return_2: .byte 0
    return_3: .byte 0
    return_4: .byte 0
}
.segment Code
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [2165] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [2166] return 
    rts
  .segment Data
    return: .byte 0
    return_1: .byte 0
    return_2: .byte 0
    return_3: .byte 0
    return_4: .byte 0
}
.segment Code
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__mem() char x, __mem() char y, __mem() char c)
cputcxy: {
    // gotoxy(x, y)
    // [2168] gotoxy::x#0 = cputcxy::x#18 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [2169] gotoxy::y#0 = cputcxy::y#18 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2170] call gotoxy
    // [772] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [2171] stackpush(char) = cputcxy::c#18 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [2172] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [2174] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    c: .byte 0
}
.segment Code
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__mem() char c)
display_smc_led: {
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [2176] display_chip_led::tc#0 = display_smc_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2177] call display_chip_led
    // [2981] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2981] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #5
    sta display_chip_led.w
    // [2981] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbum1=vbuc1 
    lda #1+1
    sta display_chip_led.x
    // [2981] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [2178] display_info_led::tc#0 = display_smc_led::c#2
    // [2179] call display_info_led
    // [2265] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [2265] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbum1=vbuc1 
    lda #$11
    sta display_info_led.y
    // [2265] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2265] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [2180] return 
    rts
  .segment Data
    c: .byte 0
}
.segment Code
  // display_print_chip
/**
 * @brief Print a full chip.
 * 
 * @param x Start X
 * @param y Start Y
 * @param w Width
 * @param text Vertical text to be displayed in the chip, starting from the top.
 */
// void display_print_chip(__mem() char x, char y, __mem() char w, __zp($70) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $70
    .label text_1 = $6e
    .label text_2 = $42
    .label text_3 = $67
    .label text_4 = $69
    .label text_5 = $2d
    .label text_6 = $b2
    // display_chip_line(x, y++, w, *text++)
    // [2182] display_chip_line::x#0 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2183] display_chip_line::w#0 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2184] display_chip_line::c#0 = *display_print_chip::text#11 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta display_chip_line.c
    // [2185] call display_chip_line
    // [2999] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2999] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2999] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2999] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [2999] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [2186] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [2187] display_chip_line::x#1 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2188] display_chip_line::w#1 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2189] display_chip_line::c#1 = *display_print_chip::text#0 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta display_chip_line.c
    // [2190] call display_chip_line
    // [2999] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2999] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2999] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2999] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [2999] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [2191] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [2192] display_chip_line::x#2 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2193] display_chip_line::w#2 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2194] display_chip_line::c#2 = *display_print_chip::text#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta display_chip_line.c
    // [2195] call display_chip_line
    // [2999] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2999] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2999] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2999] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [2999] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [2196] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [2197] display_chip_line::x#3 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2198] display_chip_line::w#3 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2199] display_chip_line::c#3 = *display_print_chip::text#15 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta display_chip_line.c
    // [2200] call display_chip_line
    // [2999] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2999] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2999] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2999] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [2999] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [2201] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [2202] display_chip_line::x#4 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2203] display_chip_line::w#4 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2204] display_chip_line::c#4 = *display_print_chip::text#16 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta display_chip_line.c
    // [2205] call display_chip_line
    // [2999] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2999] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2999] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2999] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [2999] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [2206] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [2207] display_chip_line::x#5 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2208] display_chip_line::w#5 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2209] display_chip_line::c#5 = *display_print_chip::text#17 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta display_chip_line.c
    // [2210] call display_chip_line
    // [2999] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2999] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2999] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2999] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [2999] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [2211] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [2212] display_chip_line::x#6 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2213] display_chip_line::w#6 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2214] display_chip_line::c#6 = *display_print_chip::text#18 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [2215] call display_chip_line
    // [2999] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2999] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2999] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2999] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [2999] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [2216] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [2217] display_chip_line::x#7 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2218] display_chip_line::w#7 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2219] display_chip_line::c#7 = *display_print_chip::text#19 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [2220] call display_chip_line
    // [2999] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2999] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2999] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2999] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [2999] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [2221] display_chip_end::x#0 = display_print_chip::x#10
    // [2222] display_chip_end::w#0 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_end.w
    // [2223] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [2224] return 
    rts
  .segment Data
    x: .byte 0
    w: .byte 0
}
.segment Code
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__mem() char c)
display_vera_led: {
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [2226] display_chip_led::tc#1 = display_vera_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2227] call display_chip_led
    // [2981] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2981] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #8
    sta display_chip_led.w
    // [2981] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbum1=vbuc1 
    lda #9+1
    sta display_chip_led.x
    // [2981] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [2228] display_info_led::tc#1 = display_vera_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_info_led.tc
    // [2229] call display_info_led
    // [2265] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [2265] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbum1=vbuc1 
    lda #$11+1
    sta display_info_led.y
    // [2265] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2265] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [2230] return 
    rts
  .segment Data
    c: .byte 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($42) char *source)
strcat: {
    .label strcat__0 = $76
    .label dst = $76
    .label src = $42
    .label source = $42
    // strlen(destination)
    // [2232] call strlen
    // [2471] phi from strcat to strlen [phi:strcat->strlen]
    // [2471] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [2233] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [2234] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [2235] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [2236] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [2236] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [2236] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [2237] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [2238] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [2239] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [2240] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [2241] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [2242] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // display_rom_led
/**
 * @brief Print ROM led above the ROM chip.
 * 
 * @param chip ROM chip number (0 is main rom chip of CX16)
 * @param c Led color
 */
// void display_rom_led(__mem() char chip, __mem() char c)
display_rom_led: {
    .label display_rom_led__0 = $3b
    .label display_rom_led__7 = $3b
    .label display_rom_led__8 = $3b
    // chip*6
    // [2244] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbum2_rol_1 
    lda chip
    asl
    sta.z display_rom_led__7
    // [2245] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbum2 
    lda chip
    clc
    adc.z display_rom_led__8
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [2246] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [2247] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbum1=vbuz2_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_rom_led__0
    sta display_chip_led.x
    // [2248] display_chip_led::tc#2 = display_rom_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2249] call display_chip_led
    // [2981] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2981] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #3
    sta display_chip_led.w
    // [2981] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2981] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [2250] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc chip
    sta display_info_led.y
    // [2251] display_info_led::tc#2 = display_rom_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_info_led.tc
    // [2252] call display_info_led
    // [2265] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [2265] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [2265] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2265] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [2253] return 
    rts
  .segment Data
    chip: .byte 0
    c: .byte 0
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($58) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $58
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [2255] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [2256] utoa::value#1 = printf_uint::uvalue#10
    // [2257] utoa::radix#0 = printf_uint::format_radix#10
    // [2258] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [2259] printf_number_buffer::putc#1 = printf_uint::putc#10
    // [2260] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [2261] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#10
    // [2262] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#10
    // [2263] call printf_number_buffer
  // Print using format
    // [2622] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [2622] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [2622] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [2622] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [2622] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [2264] return 
    rts
  .segment Data
    uvalue: .word 0
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
  // display_info_led
/**
 * @brief Print the colored led of an info line in the info frame.
 * 
 * @param x Start X
 * @param y Start Y
 * @param tc Fore color
 * @param bc Back color
 */
// void display_info_led(__mem() char x, __mem() char y, __mem() char tc, char bc)
display_info_led: {
    // textcolor(tc)
    // [2266] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [2267] call textcolor
    // [754] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [754] phi textcolor::color#23 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2268] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [2269] call bgcolor
    // [759] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [2270] cputcxy::x#14 = display_info_led::x#4
    // [2271] cputcxy::y#14 = display_info_led::y#4
    // [2272] call cputcxy
    // [2167] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [2167] phi cputcxy::c#18 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [2167] phi cputcxy::y#18 = cputcxy::y#14 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#14 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [2273] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [2274] call textcolor
    // [754] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [2275] return 
    rts
  .segment Data
    .label tc = display_smc_led.c
    .label y = cputcxy.y
    .label x = cputcxy.x
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
// __zp($56) struct $2 * fopen(__zp($5a) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $3b
    .label fopen__9 = $3d
    .label fopen__11 = $4f
    .label fopen__15 = $51
    .label fopen__16 = $3e
    .label fopen__26 = $47
    .label fopen__28 = $42
    .label fopen__30 = $56
    .label cbm_k_setnam1_filename = $c4
    .label cbm_k_setnam1_fopen__0 = $40
    .label stream = $56
    .label pathtoken = $5a
    .label pathtoken_1 = $7b
    .label path = $5a
    .label return = $56
    // unsigned char sp = __stdio_filecount
    // [2277] fopen::sp#0 = __stdio_filecount#27 -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [2278] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2279] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2280] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [2281] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2282] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2283] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [2284] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [2285] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [2286] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2286] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [2286] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2286] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2286] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [2286] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2286] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2286] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2286] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2286] phi fopen::path#10 = fopen::path#12 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2286] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2286] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2287] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2288] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2289] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2290] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2291] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [2292] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2292] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2292] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2292] phi fopen::path#12 = fopen::path#14 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2292] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2293] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2294] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [2295] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [2296] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2297] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2298] fopen::$4 = __stdio_filecount#27 + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [2299] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2300] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2301] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2302] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2303] fopen::$9 = __stdio_filecount#27 + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [2304] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2305] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [2306] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2307] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2308] call strlen
    // [2471] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2471] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2309] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2310] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [2311] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2313] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2314] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2315] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2316] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2318] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2320] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2321] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2322] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [2323] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2324] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2325] call ferror
    jsr ferror
    // [2326] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2327] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [2328] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2329] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2331] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2331] phi __stdio_filecount#1 = __stdio_filecount#27 [phi:fopen::cbm_k_close1->fopen::@return#0] -- register_copy 
    // [2331] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#1] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2332] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2333] __stdio_filecount#0 = ++ __stdio_filecount#27 -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2334] fopen::return#10 = (struct $2 *)fopen::stream#0
    // [2331] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2331] phi __stdio_filecount#1 = __stdio_filecount#0 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    // [2331] phi fopen::return#2 = fopen::return#10 [phi:fopen::@4->fopen::@return#1] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2335] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2336] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2337] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2338] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2338] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2338] phi fopen::path#14 = fopen::path#17 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2339] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2340] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2341] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2342] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2343] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2344] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2344] phi fopen::path#17 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2344] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2345] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2346] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2347] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2348] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2349] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2350] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2351] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2352] call atoi
    // [3144] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [3144] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2353] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2354] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2355] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2356] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    sp: .byte 0
    pathpos: .byte 0
    pathpos_1: .byte 0
    pathcmp: .byte 0
    // Parse path
    pathstep: .byte 0
    num: .byte 0
    cbm_k_readst1_return: .byte 0
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
// __mem() unsigned int fgets(__zp($4f) char *ptr, __mem() unsigned int size, __zp($6c) struct $2 *stream)
fgets: {
    .label fgets__1 = $3b
    .label fgets__8 = $3d
    .label fgets__9 = $51
    .label fgets__13 = $3c
    .label ptr = $4f
    .label stream = $6c
    // unsigned char sp = (unsigned char)stream
    // [2358] fgets::sp#0 = (char)fgets::stream#4 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2359] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2360] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2362] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2364] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2365] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2366] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2367] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2368] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2369] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2369] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2370] return 
    rts
    // fgets::@1
  __b1:
    // [2371] fgets::remaining#22 = fgets::size#10 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2372] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2372] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2372] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2372] phi fgets::ptr#11 = fgets::ptr#14 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2372] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2372] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2372] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2372] phi fgets::ptr#11 = fgets::ptr#15 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2373] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2374] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
    lda remaining+1
    cmp #>$200
    bcc !+
    beq !__b4+
    jmp __b4
  !__b4:
    lda remaining
    cmp #<$200
    bcc !__b4+
    jmp __b4
  !__b4:
  !:
    // fgets::@9
    // cx16_k_macptr(remaining, ptr)
    // [2375] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2376] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2377] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2378] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2379] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2380] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2380] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2381] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2383] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2384] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2385] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2386] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2387] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2388] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2389] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
    lda bytes+1
    cmp #>$ffff
    bne __b6
    lda bytes
    cmp #<$ffff
    bne __b6
    jmp __b8
    // fgets::@6
  __b6:
    // read += bytes
    // [2390] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2391] fgets::ptr#0 = fgets::ptr#11 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2392] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2393] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2394] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2395] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2395] phi fgets::ptr#15 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2396] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2397] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2369] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2369] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2398] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2399] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2400] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2401] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2402] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2403] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2404] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2405] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2406] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2407] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2408] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2409] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2410] fgets::bytes#1 = cx16_k_macptr::return#2
    jmp __b15
  .segment Data
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_readst2_status: .byte 0
    sp: .byte 0
    cbm_k_readst1_return: .byte 0
    .label return = read
    bytes: .word 0
    cbm_k_readst2_return: .byte 0
    read: .word 0
    remaining: .word 0
    size: .word 0
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
// int fclose(__zp($ab) struct $2 *stream)
fclose: {
    .label fclose__1 = $3c
    .label fclose__4 = $3d
    .label fclose__6 = $51
    .label stream = $ab
    // unsigned char sp = (unsigned char)stream
    // [2412] fclose::sp#0 = (char)fclose::stream#3 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2413] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2414] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2416] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2418] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2419] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2420] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [2421] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2422] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2423] phi from fclose::@2 fclose::@3 fclose::@4 to fclose::@return [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return]
    // [2423] phi __stdio_filecount#2 = __stdio_filecount#3 [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return#0] -- register_copy 
    // fclose::@return
    // }
    // [2424] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2425] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2427] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2429] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2430] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2431] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2432] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2433] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2434] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2435] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2436] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2437] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2438] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2439] __stdio_filecount#3 = -- __stdio_filecount#1 -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
  .segment Data
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_readst2_status: .byte 0
    sp: .byte 0
    cbm_k_readst1_return: .byte 0
    cbm_k_readst2_return: .byte 0
}
.segment Code
  // display_action_text_reading
// void display_action_text_reading(__zp($47) char *action, __zp($70) char *file, __mem() unsigned long bytes, __mem() unsigned long size, __mem() char bram_bank, __zp($6e) char *bram_ptr)
display_action_text_reading: {
    .label action = $47
    .label bram_ptr = $6e
    .label file = $70
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2441] call snprintf_init
    // [1167] phi from display_action_text_reading to snprintf_init [phi:display_action_text_reading->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:display_action_text_reading->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // display_action_text_reading::@1
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2442] printf_string::str#14 = display_action_text_reading::action#3
    // [2443] call printf_string
    // [1181] phi from display_action_text_reading::@1 to printf_string [phi:display_action_text_reading::@1->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:display_action_text_reading::@1->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#14 [phi:display_action_text_reading::@1->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_reading::@1->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_reading::@1->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2444] phi from display_action_text_reading::@1 to display_action_text_reading::@2 [phi:display_action_text_reading::@1->display_action_text_reading::@2]
    // display_action_text_reading::@2
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2445] call printf_str
    // [1172] phi from display_action_text_reading::@2 to printf_str [phi:display_action_text_reading::@2->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_reading::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = filter [phi:display_action_text_reading::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<filter
    sta.z printf_str.s
    lda #>filter
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@3
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2446] printf_string::str#15 = display_action_text_reading::file#3 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [2447] call printf_string
    // [1181] phi from display_action_text_reading::@3 to printf_string [phi:display_action_text_reading::@3->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:display_action_text_reading::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#15 [phi:display_action_text_reading::@3->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_reading::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_reading::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2448] phi from display_action_text_reading::@3 to display_action_text_reading::@4 [phi:display_action_text_reading::@3->display_action_text_reading::@4]
    // display_action_text_reading::@4
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2449] call printf_str
    // [1172] phi from display_action_text_reading::@4 to printf_str [phi:display_action_text_reading::@4->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_reading::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s2 [phi:display_action_text_reading::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@5
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2450] printf_ulong::uvalue#5 = display_action_text_reading::bytes#3
    // [2451] call printf_ulong
    // [1628] phi from display_action_text_reading::@5 to printf_ulong [phi:display_action_text_reading::@5->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_reading::@5->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_reading::@5->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_reading::@5->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#5 [phi:display_action_text_reading::@5->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2452] phi from display_action_text_reading::@5 to display_action_text_reading::@6 [phi:display_action_text_reading::@5->display_action_text_reading::@6]
    // display_action_text_reading::@6
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2453] call printf_str
    // [1172] phi from display_action_text_reading::@6 to printf_str [phi:display_action_text_reading::@6->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_reading::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s4 [phi:display_action_text_reading::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@7
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2454] printf_ulong::uvalue#6 = display_action_text_reading::size#10 -- vdum1=vdum2 
    lda size
    sta printf_ulong.uvalue
    lda size+1
    sta printf_ulong.uvalue+1
    lda size+2
    sta printf_ulong.uvalue+2
    lda size+3
    sta printf_ulong.uvalue+3
    // [2455] call printf_ulong
    // [1628] phi from display_action_text_reading::@7 to printf_ulong [phi:display_action_text_reading::@7->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_reading::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_reading::@7->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_reading::@7->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#6 [phi:display_action_text_reading::@7->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2456] phi from display_action_text_reading::@7 to display_action_text_reading::@8 [phi:display_action_text_reading::@7->display_action_text_reading::@8]
    // display_action_text_reading::@8
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2457] call printf_str
    // [1172] phi from display_action_text_reading::@8 to printf_str [phi:display_action_text_reading::@8->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_reading::@8->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_action_text_reading::s3 [phi:display_action_text_reading::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@9
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2458] printf_uchar::uvalue#9 = display_action_text_reading::bram_bank#10 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [2459] call printf_uchar
    // [1307] phi from display_action_text_reading::@9 to printf_uchar [phi:display_action_text_reading::@9->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:display_action_text_reading::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 2 [phi:display_action_text_reading::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:display_action_text_reading::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:display_action_text_reading::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#9 [phi:display_action_text_reading::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2460] phi from display_action_text_reading::@9 to display_action_text_reading::@10 [phi:display_action_text_reading::@9->display_action_text_reading::@10]
    // display_action_text_reading::@10
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2461] call printf_str
    // [1172] phi from display_action_text_reading::@10 to printf_str [phi:display_action_text_reading::@10->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_reading::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s2 [phi:display_action_text_reading::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@11
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2462] printf_uint::uvalue#5 = (unsigned int)display_action_text_reading::bram_ptr#10 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2463] call printf_uint
    // [2254] phi from display_action_text_reading::@11 to printf_uint [phi:display_action_text_reading::@11->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_reading::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_reading::@11->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &snputc [phi:display_action_text_reading::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = printf_uint::uvalue#5 [phi:display_action_text_reading::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2464] phi from display_action_text_reading::@11 to display_action_text_reading::@12 [phi:display_action_text_reading::@11->display_action_text_reading::@12]
    // display_action_text_reading::@12
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2465] call printf_str
    // [1172] phi from display_action_text_reading::@12 to printf_str [phi:display_action_text_reading::@12->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_reading::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s6 [phi:display_action_text_reading::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@13
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2466] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2467] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2469] call display_action_text
    // [1318] phi from display_action_text_reading::@13 to display_action_text [phi:display_action_text_reading::@13->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:display_action_text_reading::@13->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_reading::@return
    // }
    // [2470] return 
    rts
  .segment Data
    s3: .text " -> RAM:"
    .byte 0
    .label bytes = printf_ulong.uvalue
    bram_bank: .byte 0
    size: .dword 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($2d) char *str)
strlen: {
    .label str = $2d
    // [2472] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2472] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [2472] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2473] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2474] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2475] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [2476] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2472] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2472] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2472] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($56) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $56
    // [2478] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2478] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2479] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [2480] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2481] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [2482] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall37
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2484] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2478] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2478] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall37:
    jmp (putc)
  .segment Data
    i: .byte 0
    length: .byte 0
    pad: .byte 0
}
.segment CodeVera
  // vera_read
// __mem() unsigned long vera_read(__mem() char info_status)
vera_read: {
    .const bank_set_brom1_bank = 0
    .label fp = $c7
    // We start for VERA from 0x1:0xA000.
    .label vera_bram_ptr = $a9
    .label vera_action_text = $63
    // vera_read::bank_set_bram1
    // BRAM = bank
    // [2486] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // vera_read::@16
    // if(info_status == STATUS_READING)
    // [2487] if(vera_read::info_status#12==STATUS_READING) goto vera_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [2489] phi from vera_read::@16 to vera_read::@2 [phi:vera_read::@16->vera_read::@2]
    // [2489] phi vera_read::vera_bram_bank#14 = 0 [phi:vera_read::@16->vera_read::@2#0] -- vbum1=vbuc1 
    lda #0
    sta vera_bram_bank
    // [2489] phi vera_read::vera_action_text#10 = smc_action_text#2 [phi:vera_read::@16->vera_read::@2#1] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z vera_action_text
    lda #>smc_action_text_1
    sta.z vera_action_text+1
    jmp __b2
    // [2488] phi from vera_read::@16 to vera_read::@1 [phi:vera_read::@16->vera_read::@1]
    // vera_read::@1
  __b1:
    // [2489] phi from vera_read::@1 to vera_read::@2 [phi:vera_read::@1->vera_read::@2]
    // [2489] phi vera_read::vera_bram_bank#14 = 1 [phi:vera_read::@1->vera_read::@2#0] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2489] phi vera_read::vera_action_text#10 = smc_action_text#1 [phi:vera_read::@1->vera_read::@2#1] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z vera_action_text
    lda #>smc_action_text
    sta.z vera_action_text+1
    // vera_read::@2
  __b2:
    // vera_read::bank_set_brom1
    // BROM = bank
    // [2490] BROM = vera_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [2491] phi from vera_read::bank_set_brom1 to vera_read::@17 [phi:vera_read::bank_set_brom1->vera_read::@17]
    // vera_read::@17
    // display_action_text("Opening VERA.BIN from SD card ...")
    // [2492] call display_action_text
    // [1318] phi from vera_read::@17 to display_action_text [phi:vera_read::@17->display_action_text]
    // [1318] phi display_action_text::info_text#23 = vera_read::info_text [phi:vera_read::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2493] phi from vera_read::@17 to vera_read::@19 [phi:vera_read::@17->vera_read::@19]
    // vera_read::@19
    // FILE *fp = fopen("VERA.BIN", "r")
    // [2494] call fopen
    // [2276] phi from vera_read::@19 to fopen [phi:vera_read::@19->fopen]
    // [2276] phi __errno#458 = __errno#100 [phi:vera_read::@19->fopen#0] -- register_copy 
    // [2276] phi fopen::pathtoken#0 = vera_read::path [phi:vera_read::@19->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2276] phi __stdio_filecount#27 = __stdio_filecount#123 [phi:vera_read::@19->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("VERA.BIN", "r")
    // [2495] fopen::return#3 = fopen::return#2
    // vera_read::@20
    // [2496] vera_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [2497] if((struct $2 *)0==vera_read::fp#0) goto vera_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [2498] phi from vera_read::@20 to vera_read::@4 [phi:vera_read::@20->vera_read::@4]
    // vera_read::@4
    // gotoxy(x, y)
    // [2499] call gotoxy
    // [772] phi from vera_read::@4 to gotoxy [phi:vera_read::@4->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y [phi:vera_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:vera_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2500] phi from vera_read::@4 to vera_read::@5 [phi:vera_read::@4->vera_read::@5]
    // [2500] phi vera_read::y#11 = PROGRESS_Y [phi:vera_read::@4->vera_read::@5#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2500] phi vera_read::progress_row_current#10 = 0 [phi:vera_read::@4->vera_read::@5#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2500] phi vera_read::vera_bram_ptr#13 = (char *)$a000 [phi:vera_read::@4->vera_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2500] phi vera_read::vera_bram_bank#10 = vera_read::vera_bram_bank#14 [phi:vera_read::@4->vera_read::@5#3] -- register_copy 
    // [2500] phi vera_read::vera_file_size#11 = 0 [phi:vera_read::@4->vera_read::@5#4] -- vdum1=vduc1 
    lda #<0
    sta vera_file_size
    sta vera_file_size+1
    lda #<0>>$10
    sta vera_file_size+2
    lda #>0>>$10
    sta vera_file_size+3
    // vera_read::@5
  __b5:
    // while (vera_file_size < vera_size)
    // [2501] if(vera_read::vera_file_size#11<vera_size) goto vera_read::@6 -- vdum1_lt_vduc1_then_la1 
    lda vera_file_size+3
    cmp #>vera_size>>$10
    bcc __b6
    bne !+
    lda vera_file_size+2
    cmp #<vera_size>>$10
    bcc __b6
    bne !+
    lda vera_file_size+1
    cmp #>vera_size
    bcc __b6
    bne !+
    lda vera_file_size
    cmp #<vera_size
    bcc __b6
  !:
    // vera_read::@9
  __b9:
    // fclose(fp)
    // [2502] fclose::stream#0 = vera_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [2503] call fclose
    // [2411] phi from vera_read::@9 to fclose [phi:vera_read::@9->fclose]
    // [2411] phi fclose::stream#3 = fclose::stream#0 [phi:vera_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [2504] phi from vera_read::@9 to vera_read::@3 [phi:vera_read::@9->vera_read::@3]
    // [2504] phi __stdio_filecount#36 = __stdio_filecount#2 [phi:vera_read::@9->vera_read::@3#0] -- register_copy 
    // [2504] phi vera_read::return#0 = vera_read::vera_file_size#11 [phi:vera_read::@9->vera_read::@3#1] -- register_copy 
    rts
    // [2504] phi from vera_read::@20 to vera_read::@3 [phi:vera_read::@20->vera_read::@3]
  __b4:
    // [2504] phi __stdio_filecount#36 = __stdio_filecount#1 [phi:vera_read::@20->vera_read::@3#0] -- register_copy 
    // [2504] phi vera_read::return#0 = 0 [phi:vera_read::@20->vera_read::@3#1] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
    // vera_read::@3
    // vera_read::@return
    // }
    // [2505] return 
    rts
    // vera_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [2506] if(vera_read::info_status#12!=STATUS_CHECKING) goto vera_read::@23 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b7
    // [2508] phi from vera_read::@6 to vera_read::@7 [phi:vera_read::@6->vera_read::@7]
    // [2508] phi vera_read::vera_bram_ptr#10 = (char *) 1024 [phi:vera_read::@6->vera_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z vera_bram_ptr
    lda #>$400
    sta.z vera_bram_ptr+1
    // [2507] phi from vera_read::@6 to vera_read::@23 [phi:vera_read::@6->vera_read::@23]
    // vera_read::@23
    // [2508] phi from vera_read::@23 to vera_read::@7 [phi:vera_read::@23->vera_read::@7]
    // [2508] phi vera_read::vera_bram_ptr#10 = vera_read::vera_bram_ptr#13 [phi:vera_read::@23->vera_read::@7#0] -- register_copy 
    // vera_read::@7
  __b7:
    // display_action_text_reading(vera_action_text, "VERA.BIN", vera_file_size, vera_size, vera_bram_bank, vera_bram_ptr)
    // [2509] display_action_text_reading::action#0 = vera_read::vera_action_text#10 -- pbuz1=pbuz2 
    lda.z vera_action_text
    sta.z display_action_text_reading.action
    lda.z vera_action_text+1
    sta.z display_action_text_reading.action+1
    // [2510] display_action_text_reading::bytes#0 = vera_read::vera_file_size#11 -- vdum1=vdum2 
    lda vera_file_size
    sta display_action_text_reading.bytes
    lda vera_file_size+1
    sta display_action_text_reading.bytes+1
    lda vera_file_size+2
    sta display_action_text_reading.bytes+2
    lda vera_file_size+3
    sta display_action_text_reading.bytes+3
    // [2511] display_action_text_reading::bram_bank#0 = vera_read::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta display_action_text_reading.bram_bank
    // [2512] display_action_text_reading::bram_ptr#0 = vera_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [2513] call display_action_text_reading
    // [2440] phi from vera_read::@7 to display_action_text_reading [phi:vera_read::@7->display_action_text_reading]
    // [2440] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#0 [phi:vera_read::@7->display_action_text_reading#0] -- register_copy 
    // [2440] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#0 [phi:vera_read::@7->display_action_text_reading#1] -- register_copy 
    // [2440] phi display_action_text_reading::size#10 = vera_size [phi:vera_read::@7->display_action_text_reading#2] -- vdum1=vduc1 
    lda #<vera_size
    sta display_action_text_reading.size
    lda #>vera_size
    sta display_action_text_reading.size+1
    lda #<vera_size>>$10
    sta display_action_text_reading.size+2
    lda #>vera_size>>$10
    sta display_action_text_reading.size+3
    // [2440] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#0 [phi:vera_read::@7->display_action_text_reading#3] -- register_copy 
    // [2440] phi display_action_text_reading::file#3 = vera_read::path [phi:vera_read::@7->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2440] phi display_action_text_reading::action#3 = display_action_text_reading::action#0 [phi:vera_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // vera_read::bank_set_bram2
    // BRAM = bank
    // [2514] BRAM = vera_read::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // vera_read::@18
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [2515] fgets::ptr#2 = vera_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z fgets.ptr
    lda.z vera_bram_ptr+1
    sta.z fgets.ptr+1
    // [2516] fgets::stream#0 = vera_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [2517] call fgets
    // [2357] phi from vera_read::@18 to fgets [phi:vera_read::@18->fgets]
    // [2357] phi fgets::ptr#14 = fgets::ptr#2 [phi:vera_read::@18->fgets#0] -- register_copy 
    // [2357] phi fgets::size#10 = VERA_PROGRESS_CELL [phi:vera_read::@18->fgets#1] -- vwum1=vbuc1 
    lda #<VERA_PROGRESS_CELL
    sta fgets.size
    lda #>VERA_PROGRESS_CELL
    sta fgets.size+1
    // [2357] phi fgets::stream#4 = fgets::stream#0 [phi:vera_read::@18->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [2518] fgets::return#10 = fgets::return#1
    // vera_read::@21
    // [2519] vera_read::vera_package_read#0 = fgets::return#10 -- vwum1=vwum2 
    lda fgets.return
    sta vera_package_read
    lda fgets.return+1
    sta vera_package_read+1
    // if (!vera_package_read)
    // [2520] if(0!=vera_read::vera_package_read#0) goto vera_read::@8 -- 0_neq_vwum1_then_la1 
    lda vera_package_read
    ora vera_package_read+1
    bne __b8
    jmp __b9
    // vera_read::@8
  __b8:
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [2521] if(vera_read::progress_row_current#10!=VERA_PROGRESS_ROW) goto vera_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b10
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b10
    // vera_read::@13
    // gotoxy(x, ++y);
    // [2522] vera_read::y#1 = ++ vera_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [2523] gotoxy::y#7 = vera_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2524] call gotoxy
    // [772] phi from vera_read::@13 to gotoxy [phi:vera_read::@13->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#7 [phi:vera_read::@13->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:vera_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2525] phi from vera_read::@13 to vera_read::@10 [phi:vera_read::@13->vera_read::@10]
    // [2525] phi vera_read::y#22 = vera_read::y#1 [phi:vera_read::@13->vera_read::@10#0] -- register_copy 
    // [2525] phi vera_read::progress_row_current#4 = 0 [phi:vera_read::@13->vera_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2525] phi from vera_read::@8 to vera_read::@10 [phi:vera_read::@8->vera_read::@10]
    // [2525] phi vera_read::y#22 = vera_read::y#11 [phi:vera_read::@8->vera_read::@10#0] -- register_copy 
    // [2525] phi vera_read::progress_row_current#4 = vera_read::progress_row_current#10 [phi:vera_read::@8->vera_read::@10#1] -- register_copy 
    // vera_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [2526] if(vera_read::info_status#12!=STATUS_READING) goto vera_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // vera_read::@14
    // cputc('.')
    // [2527] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [2528] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_read::@11
  __b11:
    // vera_bram_ptr += vera_package_read
    // [2530] vera_read::vera_bram_ptr#2 = vera_read::vera_bram_ptr#10 + vera_read::vera_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z vera_bram_ptr
    adc vera_package_read
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc vera_package_read+1
    sta.z vera_bram_ptr+1
    // vera_file_size += vera_package_read
    // [2531] vera_read::vera_file_size#1 = vera_read::vera_file_size#11 + vera_read::vera_package_read#0 -- vdum1=vdum1_plus_vwum2 
    lda vera_file_size
    clc
    adc vera_package_read
    sta vera_file_size
    lda vera_file_size+1
    adc vera_package_read+1
    sta vera_file_size+1
    lda vera_file_size+2
    adc #0
    sta vera_file_size+2
    lda vera_file_size+3
    adc #0
    sta vera_file_size+3
    // progress_row_current += vera_package_read
    // [2532] vera_read::progress_row_current#15 = vera_read::progress_row_current#4 + vera_read::vera_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_current
    adc vera_package_read
    sta progress_row_current
    lda progress_row_current+1
    adc vera_package_read+1
    sta progress_row_current+1
    // if (vera_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [2533] if(vera_read::vera_bram_ptr#2!=(char *)$c000) goto vera_read::@12 -- pbuz1_neq_pbuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b12
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b12
    // vera_read::@15
    // vera_bram_bank++;
    // [2534] vera_read::vera_bram_bank#2 = ++ vera_read::vera_bram_bank#10 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2535] phi from vera_read::@15 to vera_read::@12 [phi:vera_read::@15->vera_read::@12]
    // [2535] phi vera_read::vera_bram_bank#13 = vera_read::vera_bram_bank#2 [phi:vera_read::@15->vera_read::@12#0] -- register_copy 
    // [2535] phi vera_read::vera_bram_ptr#8 = (char *)$a000 [phi:vera_read::@15->vera_read::@12#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2535] phi from vera_read::@11 to vera_read::@12 [phi:vera_read::@11->vera_read::@12]
    // [2535] phi vera_read::vera_bram_bank#13 = vera_read::vera_bram_bank#10 [phi:vera_read::@11->vera_read::@12#0] -- register_copy 
    // [2535] phi vera_read::vera_bram_ptr#8 = vera_read::vera_bram_ptr#2 [phi:vera_read::@11->vera_read::@12#1] -- register_copy 
    // vera_read::@12
  __b12:
    // if (vera_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [2536] if(vera_read::vera_bram_ptr#8!=(char *)$9800) goto vera_read::@22 -- pbuz1_neq_pbuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    beq !__b5+
    jmp __b5
  !__b5:
    lda.z vera_bram_ptr
    cmp #<$9800
    beq !__b5+
    jmp __b5
  !__b5:
    // [2500] phi from vera_read::@12 to vera_read::@5 [phi:vera_read::@12->vera_read::@5]
    // [2500] phi vera_read::y#11 = vera_read::y#22 [phi:vera_read::@12->vera_read::@5#0] -- register_copy 
    // [2500] phi vera_read::progress_row_current#10 = vera_read::progress_row_current#15 [phi:vera_read::@12->vera_read::@5#1] -- register_copy 
    // [2500] phi vera_read::vera_bram_ptr#13 = (char *)$a000 [phi:vera_read::@12->vera_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2500] phi vera_read::vera_bram_bank#10 = 1 [phi:vera_read::@12->vera_read::@5#3] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2500] phi vera_read::vera_file_size#11 = vera_read::vera_file_size#1 [phi:vera_read::@12->vera_read::@5#4] -- register_copy 
    jmp __b5
    // [2537] phi from vera_read::@12 to vera_read::@22 [phi:vera_read::@12->vera_read::@22]
    // vera_read::@22
    // [2500] phi from vera_read::@22 to vera_read::@5 [phi:vera_read::@22->vera_read::@5]
    // [2500] phi vera_read::y#11 = vera_read::y#22 [phi:vera_read::@22->vera_read::@5#0] -- register_copy 
    // [2500] phi vera_read::progress_row_current#10 = vera_read::progress_row_current#15 [phi:vera_read::@22->vera_read::@5#1] -- register_copy 
    // [2500] phi vera_read::vera_bram_ptr#13 = vera_read::vera_bram_ptr#8 [phi:vera_read::@22->vera_read::@5#2] -- register_copy 
    // [2500] phi vera_read::vera_bram_bank#10 = vera_read::vera_bram_bank#13 [phi:vera_read::@22->vera_read::@5#3] -- register_copy 
    // [2500] phi vera_read::vera_file_size#11 = vera_read::vera_file_size#1 [phi:vera_read::@22->vera_read::@5#4] -- register_copy 
  .segment DataVera
    info_text: .text "Opening VERA.BIN from SD card ..."
    .byte 0
    path: .text "VERA.BIN"
    .byte 0
    return: .dword 0
    vera_package_read: .word 0
    y: .byte 0
    .label vera_file_size = return
    vera_bram_bank: .byte 0
    progress_row_current: .word 0
    info_status: .byte 0
}
.segment CodeVera
  // vera_preamable_SPI
vera_preamable_SPI: {
    // Display the header until the preamable has been found.
    .label vera_file_preamable_byte = $c2
    // unsigned long vera_boundary = vera_file_size
    // [2538] vera_preamable_SPI::vera_boundary#0 = vera_file_size#1 -- vdum1=vdum2 
    lda vera_file_size
    sta vera_boundary
    lda vera_file_size+1
    sta vera_boundary+1
    lda vera_file_size+2
    sta vera_boundary+2
    lda vera_file_size+3
    sta vera_boundary+3
    // gotoxy(x, y)
    // [2539] call gotoxy
    // [772] phi from vera_preamable_SPI to gotoxy [phi:vera_preamable_SPI->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y [phi:vera_preamable_SPI->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:vera_preamable_SPI->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // vera_preamable_SPI::@13
    // if(*vera_file_preamable_byte == 0xFF)
    // [2540] if(*((char *)$7800)==$ff) goto vera_preamable_SPI::@1 -- _deref_pbuc1_eq_vbuc2_then_la1 
    lda #$ff
    cmp $7800
    beq __b1
    // vera_preamable_SPI::@return
  __breturn:
    // }
    // [2541] return 
    rts
    // [2542] phi from vera_preamable_SPI::@13 to vera_preamable_SPI::@1 [phi:vera_preamable_SPI::@13->vera_preamable_SPI::@1]
    // vera_preamable_SPI::@1
  __b1:
    // sprintf(info_text, "Premable byte %u: %x", vera_file_pos, *vera_file_preamable_byte)
    // [2543] call snprintf_init
    // [1167] phi from vera_preamable_SPI::@1 to snprintf_init [phi:vera_preamable_SPI::@1->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:vera_preamable_SPI::@1->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2544] phi from vera_preamable_SPI::@1 to vera_preamable_SPI::@14 [phi:vera_preamable_SPI::@1->vera_preamable_SPI::@14]
    // vera_preamable_SPI::@14
    // sprintf(info_text, "Premable byte %u: %x", vera_file_pos, *vera_file_preamable_byte)
    // [2545] call printf_str
    // [1172] phi from vera_preamable_SPI::@14 to printf_str [phi:vera_preamable_SPI::@14->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_preamable_SPI::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = vera_preamable_SPI::s [phi:vera_preamable_SPI::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [2546] phi from vera_preamable_SPI::@14 to vera_preamable_SPI::@15 [phi:vera_preamable_SPI::@14->vera_preamable_SPI::@15]
    // vera_preamable_SPI::@15
    // sprintf(info_text, "Premable byte %u: %x", vera_file_pos, *vera_file_preamable_byte)
    // [2547] call printf_uint
    // [2254] phi from vera_preamable_SPI::@15 to printf_uint [phi:vera_preamable_SPI::@15->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 0 [phi:vera_preamable_SPI::@15->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 0 [phi:vera_preamable_SPI::@15->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &snputc [phi:vera_preamable_SPI::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = DECIMAL [phi:vera_preamable_SPI::@15->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = 0 [phi:vera_preamable_SPI::@15->printf_uint#4] -- vwum1=vwuc1 
    lda #<0
    sta printf_uint.uvalue
    sta printf_uint.uvalue+1
    jsr printf_uint
    // [2548] phi from vera_preamable_SPI::@15 to vera_preamable_SPI::@16 [phi:vera_preamable_SPI::@15->vera_preamable_SPI::@16]
    // vera_preamable_SPI::@16
    // sprintf(info_text, "Premable byte %u: %x", vera_file_pos, *vera_file_preamable_byte)
    // [2549] call printf_str
    // [1172] phi from vera_preamable_SPI::@16 to printf_str [phi:vera_preamable_SPI::@16->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_preamable_SPI::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = vera_preamable_SPI::s1 [phi:vera_preamable_SPI::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // vera_preamable_SPI::@17
    // sprintf(info_text, "Premable byte %u: %x", vera_file_pos, *vera_file_preamable_byte)
    // [2550] printf_uchar::uvalue#0 = *((char *)$7800) -- vbum1=_deref_pbuc1 
    lda $7800
    sta printf_uchar.uvalue
    // [2551] call printf_uchar
    // [1307] phi from vera_preamable_SPI::@17 to printf_uchar [phi:vera_preamable_SPI::@17->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:vera_preamable_SPI::@17->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:vera_preamable_SPI::@17->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:vera_preamable_SPI::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:vera_preamable_SPI::@17->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#0 [phi:vera_preamable_SPI::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // vera_preamable_SPI::@18
    // sprintf(info_text, "Premable byte %u: %x", vera_file_pos, *vera_file_preamable_byte)
    // [2552] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2553] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2555] call display_action_text
    // [1318] phi from vera_preamable_SPI::@18 to display_action_text [phi:vera_preamable_SPI::@18->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:vera_preamable_SPI::@18->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2556] phi from vera_preamable_SPI::@18 to vera_preamable_SPI::@2 [phi:vera_preamable_SPI::@18->vera_preamable_SPI::@2]
    // [2556] phi vera_preamable_SPI::x#10 = PROGRESS_X [phi:vera_preamable_SPI::@18->vera_preamable_SPI::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x
    // [2556] phi vera_preamable_SPI::y#10 = PROGRESS_Y [phi:vera_preamable_SPI::@18->vera_preamable_SPI::@2#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2556] phi vera_preamable_SPI::vera_file_preamable_pos#10 = 0 [phi:vera_preamable_SPI::@18->vera_preamable_SPI::@2#2] -- vbum1=vbuc1 
    lda #0
    sta vera_file_preamable_pos
    // [2556] phi vera_preamable_SPI::vera_file_pos#3 = 0 [phi:vera_preamable_SPI::@18->vera_preamable_SPI::@2#3] -- vwum1=vwuc1 
    sta vera_file_pos
    sta vera_file_pos+1
    // [2556] phi vera_preamable_SPI::vera_file_preamable_byte#11 = (char *)$7800 [phi:vera_preamable_SPI::@18->vera_preamable_SPI::@2#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z vera_file_preamable_byte
    lda #>$7800
    sta.z vera_file_preamable_byte+1
    // [2556] phi vera_preamable_SPI::vera_address#2 = 0 [phi:vera_preamable_SPI::@18->vera_preamable_SPI::@2#5] -- vdum1=vduc1 
    lda #<0
    sta vera_address
    sta vera_address+1
    lda #<0>>$10
    sta vera_address+2
    lda #>0>>$10
    sta vera_address+3
    // vera_preamable_SPI::@2
  __b2:
    // while(vera_address <= vera_boundary)
    // [2557] if(vera_preamable_SPI::vera_address#2<=vera_preamable_SPI::vera_boundary#0) goto vera_preamable_SPI::@3 -- vdum1_le_vdum2_then_la1 
    lda vera_boundary+3
    cmp vera_address+3
    bcc !+
    bne __b3
    lda vera_boundary+2
    cmp vera_address+2
    bcc !+
    bne __b3
    lda vera_boundary+1
    cmp vera_address+1
    bcc !+
    bne __b3
    lda vera_boundary
    cmp vera_address
    bcs __b3
  !:
    rts
    // vera_preamable_SPI::@3
  __b3:
    // vera_file_preamable_byte++;
    // [2558] vera_preamable_SPI::vera_file_preamable_byte#1 = ++ vera_preamable_SPI::vera_file_preamable_byte#11 -- pbuz1=_inc_pbuz1 
    inc.z vera_file_preamable_byte
    bne !+
    inc.z vera_file_preamable_byte+1
  !:
    // vera_file_pos++;
    // [2559] vera_preamable_SPI::vera_file_pos#1 = ++ vera_preamable_SPI::vera_file_pos#3 -- vwum1=_inc_vwum1 
    inc vera_file_pos
    bne !+
    inc vera_file_pos+1
  !:
    // vera_address++;
    // [2560] vera_preamable_SPI::vera_address#1 = ++ vera_preamable_SPI::vera_address#2 -- vdum1=_inc_vdum1 
    inc vera_address
    bne !+
    inc vera_address+1
    bne !+
    inc vera_address+2
    bne !+
    inc vera_address+3
  !:
    // sprintf(info_text, "Premable byte %u: %u/%x",  vera_file_pos, vera_file_preamable_pos, *vera_file_preamable_byte)
    // [2561] call snprintf_init
    // [1167] phi from vera_preamable_SPI::@3 to snprintf_init [phi:vera_preamable_SPI::@3->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:vera_preamable_SPI::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2562] phi from vera_preamable_SPI::@3 to vera_preamable_SPI::@19 [phi:vera_preamable_SPI::@3->vera_preamable_SPI::@19]
    // vera_preamable_SPI::@19
    // sprintf(info_text, "Premable byte %u: %u/%x",  vera_file_pos, vera_file_preamable_pos, *vera_file_preamable_byte)
    // [2563] call printf_str
    // [1172] phi from vera_preamable_SPI::@19 to printf_str [phi:vera_preamable_SPI::@19->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_preamable_SPI::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = vera_preamable_SPI::s [phi:vera_preamable_SPI::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // vera_preamable_SPI::@20
    // sprintf(info_text, "Premable byte %u: %u/%x",  vera_file_pos, vera_file_preamable_pos, *vera_file_preamable_byte)
    // [2564] printf_uint::uvalue#1 = vera_preamable_SPI::vera_file_pos#1 -- vwum1=vwum2 
    lda vera_file_pos
    sta printf_uint.uvalue
    lda vera_file_pos+1
    sta printf_uint.uvalue+1
    // [2565] call printf_uint
    // [2254] phi from vera_preamable_SPI::@20 to printf_uint [phi:vera_preamable_SPI::@20->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 0 [phi:vera_preamable_SPI::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 0 [phi:vera_preamable_SPI::@20->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &snputc [phi:vera_preamable_SPI::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = DECIMAL [phi:vera_preamable_SPI::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = printf_uint::uvalue#1 [phi:vera_preamable_SPI::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2566] phi from vera_preamable_SPI::@20 to vera_preamable_SPI::@21 [phi:vera_preamable_SPI::@20->vera_preamable_SPI::@21]
    // vera_preamable_SPI::@21
    // sprintf(info_text, "Premable byte %u: %u/%x",  vera_file_pos, vera_file_preamable_pos, *vera_file_preamable_byte)
    // [2567] call printf_str
    // [1172] phi from vera_preamable_SPI::@21 to printf_str [phi:vera_preamable_SPI::@21->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_preamable_SPI::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = vera_preamable_SPI::s1 [phi:vera_preamable_SPI::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // vera_preamable_SPI::@22
    // sprintf(info_text, "Premable byte %u: %u/%x",  vera_file_pos, vera_file_preamable_pos, *vera_file_preamable_byte)
    // [2568] printf_uchar::uvalue#1 = vera_preamable_SPI::vera_file_preamable_pos#10 -- vbum1=vbum2 
    lda vera_file_preamable_pos
    sta printf_uchar.uvalue
    // [2569] call printf_uchar
    // [1307] phi from vera_preamable_SPI::@22 to printf_uchar [phi:vera_preamable_SPI::@22->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:vera_preamable_SPI::@22->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:vera_preamable_SPI::@22->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:vera_preamable_SPI::@22->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = DECIMAL [phi:vera_preamable_SPI::@22->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#1 [phi:vera_preamable_SPI::@22->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2570] phi from vera_preamable_SPI::@22 to vera_preamable_SPI::@23 [phi:vera_preamable_SPI::@22->vera_preamable_SPI::@23]
    // vera_preamable_SPI::@23
    // sprintf(info_text, "Premable byte %u: %u/%x",  vera_file_pos, vera_file_preamable_pos, *vera_file_preamable_byte)
    // [2571] call printf_str
    // [1172] phi from vera_preamable_SPI::@23 to printf_str [phi:vera_preamable_SPI::@23->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_preamable_SPI::@23->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s4 [phi:vera_preamable_SPI::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // vera_preamable_SPI::@24
    // sprintf(info_text, "Premable byte %u: %u/%x",  vera_file_pos, vera_file_preamable_pos, *vera_file_preamable_byte)
    // [2572] printf_uchar::uvalue#2 = *vera_preamable_SPI::vera_file_preamable_byte#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (vera_file_preamable_byte),y
    sta printf_uchar.uvalue
    // [2573] call printf_uchar
    // [1307] phi from vera_preamable_SPI::@24 to printf_uchar [phi:vera_preamable_SPI::@24->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 0 [phi:vera_preamable_SPI::@24->printf_uchar#0] -- vbum1=vbuc1 
    tya
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 0 [phi:vera_preamable_SPI::@24->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:vera_preamable_SPI::@24->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:vera_preamable_SPI::@24->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#2 [phi:vera_preamable_SPI::@24->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // vera_preamable_SPI::@25
    // sprintf(info_text, "Premable byte %u: %u/%x",  vera_file_pos, vera_file_preamable_pos, *vera_file_preamable_byte)
    // [2574] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2575] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2577] call display_action_text
    // [1318] phi from vera_preamable_SPI::@25 to display_action_text [phi:vera_preamable_SPI::@25->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:vera_preamable_SPI::@25->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // vera_preamable_SPI::@26
    // if(vera_file_preamable_pos < 4 && *vera_file_preamable_byte == vera_file_preamable[vera_file_preamable_pos])
    // [2578] if(vera_preamable_SPI::vera_file_preamable_pos#10>=4) goto vera_preamable_SPI::@8 -- vbum1_ge_vbuc1_then_la1 
    lda vera_file_preamable_pos
    cmp #4
    bcs __b8
    // vera_preamable_SPI::@27
    // [2579] if(*vera_preamable_SPI::vera_file_preamable_byte#1==vera_preamable_SPI::vera_file_preamable[vera_preamable_SPI::vera_file_preamable_pos#10]) goto vera_preamable_SPI::@4 -- _deref_pbuz1_eq_pbuc1_derefidx_vbum2_then_la1 
    tay
    lda vera_file_preamable,y
    ldy #0
    cmp (vera_file_preamable_byte),y
    beq __b4
    // vera_preamable_SPI::@8
  __b8:
    // if(*vera_file_preamable_byte == vera_file_preamable[vera_file_preamable_pos])
    // [2580] if(*vera_preamable_SPI::vera_file_preamable_byte#1!=*vera_preamable_SPI::vera_file_preamable) goto vera_preamable_SPI::@5 -- _deref_pbuz1_neq__deref_pbuc1_then_la1 
    ldy #0
    lda (vera_file_preamable_byte),y
    cmp vera_file_preamable
    bne __b9
    // [2581] phi from vera_preamable_SPI::@8 to vera_preamable_SPI::@9 [phi:vera_preamable_SPI::@8->vera_preamable_SPI::@9]
    // vera_preamable_SPI::@9
    // [2582] phi from vera_preamable_SPI::@9 to vera_preamable_SPI::@5 [phi:vera_preamable_SPI::@9->vera_preamable_SPI::@5]
    // [2582] phi vera_preamable_SPI::vera_file_preamable_pos#17 = 1 [phi:vera_preamable_SPI::@9->vera_preamable_SPI::@5#0] -- vbum1=vbuc1 
    lda #1
    sta vera_file_preamable_pos
    jmp __b5
    // [2582] phi from vera_preamable_SPI::@8 to vera_preamable_SPI::@5 [phi:vera_preamable_SPI::@8->vera_preamable_SPI::@5]
  __b9:
    // [2582] phi vera_preamable_SPI::vera_file_preamable_pos#17 = 0 [phi:vera_preamable_SPI::@8->vera_preamable_SPI::@5#0] -- vbum1=vbuc1 
    lda #0
    sta vera_file_preamable_pos
    // vera_preamable_SPI::@5
  __b5:
    // if(*vera_file_preamable_byte)
    // [2583] if(0!=*vera_preamable_SPI::vera_file_preamable_byte#1) goto vera_preamable_SPI::@6 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (vera_file_preamable_byte),y
    cmp #0
    bne __b6
    // vera_preamable_SPI::@11
    // y++;
    // [2584] vera_preamable_SPI::y#1 = ++ vera_preamable_SPI::y#10 -- vbum1=_inc_vbum1 
    inc y
    // [2556] phi from vera_preamable_SPI::@11 to vera_preamable_SPI::@2 [phi:vera_preamable_SPI::@11->vera_preamable_SPI::@2]
    // [2556] phi vera_preamable_SPI::x#10 = PROGRESS_X [phi:vera_preamable_SPI::@11->vera_preamable_SPI::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x
    // [2556] phi vera_preamable_SPI::y#10 = vera_preamable_SPI::y#1 [phi:vera_preamable_SPI::@11->vera_preamable_SPI::@2#1] -- register_copy 
    // [2556] phi vera_preamable_SPI::vera_file_preamable_pos#10 = vera_preamable_SPI::vera_file_preamable_pos#17 [phi:vera_preamable_SPI::@11->vera_preamable_SPI::@2#2] -- register_copy 
    // [2556] phi vera_preamable_SPI::vera_file_pos#3 = vera_preamable_SPI::vera_file_pos#1 [phi:vera_preamable_SPI::@11->vera_preamable_SPI::@2#3] -- register_copy 
    // [2556] phi vera_preamable_SPI::vera_file_preamable_byte#11 = vera_preamable_SPI::vera_file_preamable_byte#1 [phi:vera_preamable_SPI::@11->vera_preamable_SPI::@2#4] -- register_copy 
    // [2556] phi vera_preamable_SPI::vera_address#2 = vera_preamable_SPI::vera_address#1 [phi:vera_preamable_SPI::@11->vera_preamable_SPI::@2#5] -- register_copy 
    jmp __b2
    // vera_preamable_SPI::@6
  __b6:
    // if(*vera_file_preamable_byte >= 20 && *vera_file_preamable_byte <= 0x7F)
    // [2585] if(*vera_preamable_SPI::vera_file_preamable_byte#1<$14) goto vera_preamable_SPI::@7 -- _deref_pbuz1_lt_vbuc1_then_la1 
    ldy #0
    lda (vera_file_preamable_byte),y
    cmp #$14
    bcc __b7
    // vera_preamable_SPI::@28
    // [2586] if(*vera_preamable_SPI::vera_file_preamable_byte#1<$7f+1) goto vera_preamable_SPI::@12 -- _deref_pbuz1_lt_vbuc1_then_la1 
    lda (vera_file_preamable_byte),y
    cmp #$7f+1
    bcc __b12
    jmp __b7
    // vera_preamable_SPI::@12
  __b12:
    // cputcxy(x, y, *vera_file_preamable_byte)
    // [2587] cputcxy::x#0 = vera_preamable_SPI::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2588] cputcxy::y#0 = vera_preamable_SPI::y#10 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2589] cputcxy::c#0 = *vera_preamable_SPI::vera_file_preamable_byte#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (vera_file_preamable_byte),y
    sta cputcxy.c
    // [2590] call cputcxy
    // [2167] phi from vera_preamable_SPI::@12 to cputcxy [phi:vera_preamable_SPI::@12->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#0 [phi:vera_preamable_SPI::@12->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#0 [phi:vera_preamable_SPI::@12->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#0 [phi:vera_preamable_SPI::@12->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_preamable_SPI::@7
  __b7:
    // x++;
    // [2591] vera_preamable_SPI::x#2 = ++ vera_preamable_SPI::x#10 -- vbum1=_inc_vbum1 
    inc x
    // [2556] phi from vera_preamable_SPI::@7 to vera_preamable_SPI::@2 [phi:vera_preamable_SPI::@7->vera_preamable_SPI::@2]
    // [2556] phi vera_preamable_SPI::x#10 = vera_preamable_SPI::x#2 [phi:vera_preamable_SPI::@7->vera_preamable_SPI::@2#0] -- register_copy 
    // [2556] phi vera_preamable_SPI::y#10 = vera_preamable_SPI::y#10 [phi:vera_preamable_SPI::@7->vera_preamable_SPI::@2#1] -- register_copy 
    // [2556] phi vera_preamable_SPI::vera_file_preamable_pos#10 = vera_preamable_SPI::vera_file_preamable_pos#17 [phi:vera_preamable_SPI::@7->vera_preamable_SPI::@2#2] -- register_copy 
    // [2556] phi vera_preamable_SPI::vera_file_pos#3 = vera_preamable_SPI::vera_file_pos#1 [phi:vera_preamable_SPI::@7->vera_preamable_SPI::@2#3] -- register_copy 
    // [2556] phi vera_preamable_SPI::vera_file_preamable_byte#11 = vera_preamable_SPI::vera_file_preamable_byte#1 [phi:vera_preamable_SPI::@7->vera_preamable_SPI::@2#4] -- register_copy 
    // [2556] phi vera_preamable_SPI::vera_address#2 = vera_preamable_SPI::vera_address#1 [phi:vera_preamable_SPI::@7->vera_preamable_SPI::@2#5] -- register_copy 
    jmp __b2
    // vera_preamable_SPI::@4
  __b4:
    // if(vera_file_preamable_pos == 3)
    // [2592] if(vera_preamable_SPI::vera_file_preamable_pos#10==3) goto vera_preamable_SPI::@return -- vbum1_eq_vbuc1_then_la1 
    lda #3
    cmp vera_file_preamable_pos
    bne !__breturn+
    jmp __breturn
  !__breturn:
    // vera_preamable_SPI::@10
    // vera_file_preamable_pos++;
    // [2593] vera_preamable_SPI::vera_file_preamable_pos#3 = ++ vera_preamable_SPI::vera_file_preamable_pos#10 -- vbum1=_inc_vbum1 
    inc vera_file_preamable_pos
    // [2582] phi from vera_preamable_SPI::@10 to vera_preamable_SPI::@5 [phi:vera_preamable_SPI::@10->vera_preamable_SPI::@5]
    // [2582] phi vera_preamable_SPI::vera_file_preamable_pos#17 = vera_preamable_SPI::vera_file_preamable_pos#3 [phi:vera_preamable_SPI::@10->vera_preamable_SPI::@5#0] -- register_copy 
    jmp __b5
  .segment DataVera
    vera_file_preamable: .byte $7e, $aa, $99, $7e
    s: .text "Premable byte "
    .byte 0
    s1: .text ": "
    .byte 0
    vera_boundary: .dword 0
    vera_file_pos: .word 0
    vera_address: .dword 0
    vera_file_preamable_pos: .byte 0
    y: .byte 0
    x: .byte 0
}
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__mem() char value, __zp($35) char *buffer, __mem() char radix)
uctoa: {
    .label uctoa__4 = $3d
    .label buffer = $35
    .label digit_values = $2d
    // if(radix==DECIMAL)
    // [2594] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2595] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2596] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2597] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2598] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2599] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2600] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2601] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2602] return 
    rts
    // [2603] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2603] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2603] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2603] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2603] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2603] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2603] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2603] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2603] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2603] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2603] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2603] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2604] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2604] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2604] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2604] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2604] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2605] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2606] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2607] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2608] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2609] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2610] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [2611] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2612] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [2613] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2613] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2613] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2613] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2614] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2604] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2604] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2604] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2604] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2604] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2615] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2616] uctoa_append::value#0 = uctoa::value#2
    // [2617] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2618] call uctoa_append
    // [3165] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2619] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2620] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2621] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2613] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2613] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2613] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2613] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .byte 0
    digit: .byte 0
    .label value = smc_get_version_text.release
    .label radix = printf_uchar.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($58) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $4f
    .label putc = $58
    // if(format.min_length)
    // [2623] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [2624] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [2625] call strlen
    // [2471] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2471] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [2626] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [2627] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [2628] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [2629] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [2630] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [2631] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [2631] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [2632] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [2633] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [2635] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [2635] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [2634] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [2635] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [2635] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [2636] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [2637] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [2638] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2639] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2640] call printf_padding
    // [2477] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2477] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2477] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2477] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2641] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2642] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [2643] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall41
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2645] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2646] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2647] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2648] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2649] call printf_padding
    // [2477] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2477] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2477] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [2477] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2650] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2651] call printf_str
    // [1172] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [1172] phi printf_str::putc#89 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [1172] phi printf_str::s#89 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2652] return 
    rts
    // Outside Flow
  icall41:
    jmp (putc)
  .segment Data
    buffer_sign: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
    len: .byte 0
    .label padding = len
}
.segment CodeVera
  // vera_verify
vera_verify: {
    .label vera_verify__16 = $a9
    .label vera_bram_address = $c0
    // vera_verify::bank_set_bram1
    // BRAM = bank
    // [2654] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // vera_verify::@11
    // unsigned long vera_boundary = vera_file_size
    // [2655] vera_verify::vera_boundary#0 = vera_file_size#1 -- vdum1=vdum2 
    lda vera_file_size
    sta vera_boundary
    lda vera_file_size+1
    sta vera_boundary+1
    lda vera_file_size+2
    sta vera_boundary+2
    lda vera_file_size+3
    sta vera_boundary+3
    // display_info_vera(STATUS_COMPARING, "Comparing VERA ...")
    // [2656] call display_info_vera
    // [968] phi from vera_verify::@11 to display_info_vera [phi:vera_verify::@11->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = vera_verify::info_text [phi:vera_verify::@11->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_vera.info_text
    lda #>info_text
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:vera_verify::@11->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:vera_verify::@11->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:vera_verify::@11->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_COMPARING [phi:vera_verify::@11->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [2657] phi from vera_verify::@11 to vera_verify::@12 [phi:vera_verify::@11->vera_verify::@12]
    // vera_verify::@12
    // gotoxy(x, y)
    // [2658] call gotoxy
    // [772] phi from vera_verify::@12 to gotoxy [phi:vera_verify::@12->gotoxy]
    // [772] phi gotoxy::y#38 = PROGRESS_Y [phi:vera_verify::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:vera_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2659] phi from vera_verify::@12 to vera_verify::@13 [phi:vera_verify::@12->vera_verify::@13]
    // vera_verify::@13
    // spi_read_flash(0UL)
    // [2660] call spi_read_flash
    // [3172] phi from vera_verify::@13 to spi_read_flash [phi:vera_verify::@13->spi_read_flash]
    jsr spi_read_flash
    // [2661] phi from vera_verify::@13 to vera_verify::@1 [phi:vera_verify::@13->vera_verify::@1]
    // [2661] phi vera_verify::y#3 = PROGRESS_Y [phi:vera_verify::@13->vera_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2661] phi vera_verify::progress_row_current#3 = 0 [phi:vera_verify::@13->vera_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2661] phi vera_verify::vera_different_bytes#11 = 0 [phi:vera_verify::@13->vera_verify::@1#2] -- vdum1=vduc1 
    sta vera_different_bytes
    sta vera_different_bytes+1
    lda #<0>>$10
    sta vera_different_bytes+2
    lda #>0>>$10
    sta vera_different_bytes+3
    // [2661] phi vera_verify::vera_bram_address#10 = (char *)$a000 [phi:vera_verify::@13->vera_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_address
    lda #>$a000
    sta.z vera_bram_address+1
    // [2661] phi vera_verify::vera_bram_bank#11 = 0 [phi:vera_verify::@13->vera_verify::@1#4] -- vbum1=vbuc1 
    lda #0
    sta vera_bram_bank
    // [2661] phi vera_verify::vera_address#11 = 0 [phi:vera_verify::@13->vera_verify::@1#5] -- vdum1=vduc1 
    sta vera_address
    sta vera_address+1
    lda #<0>>$10
    sta vera_address+2
    lda #>0>>$10
    sta vera_address+3
    // vera_verify::@1
  __b1:
    // while (vera_address < vera_boundary)
    // [2662] if(vera_verify::vera_address#11<vera_verify::vera_boundary#0) goto vera_verify::@2 -- vdum1_lt_vdum2_then_la1 
    lda vera_address+3
    cmp vera_boundary+3
    bcc __b2
    bne !+
    lda vera_address+2
    cmp vera_boundary+2
    bcc __b2
    bne !+
    lda vera_address+1
    cmp vera_boundary+1
    bcc __b2
    bne !+
    lda vera_address
    cmp vera_boundary
    bcc __b2
  !:
    // vera_verify::@return
    // }
    // [2663] return 
    rts
    // vera_verify::@2
  __b2:
    // unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_address, VERA_PROGRESS_CELL)
    // [2664] vera_compare::bank_ram#0 = vera_verify::vera_bram_bank#11 -- vbum1=vbum2 
    lda vera_bram_bank
    sta vera_compare.bank_ram
    // [2665] vera_compare::bram_ptr#0 = vera_verify::vera_bram_address#10 -- pbuz1=pbuz2 
    lda.z vera_bram_address
    sta.z vera_compare.bram_ptr
    lda.z vera_bram_address+1
    sta.z vera_compare.bram_ptr+1
    // [2666] call vera_compare
  // {asm{.byte $db}}
    // [3183] phi from vera_verify::@2 to vera_compare [phi:vera_verify::@2->vera_compare]
    jsr vera_compare
    // unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_address, VERA_PROGRESS_CELL)
    // [2667] vera_compare::return#0 = vera_compare::equal_bytes#2
    // vera_verify::@14
    // [2668] vera_verify::equal_bytes#0 = vera_compare::return#0
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [2669] if(vera_verify::progress_row_current#3!=VERA_PROGRESS_ROW) goto vera_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b3
    // vera_verify::@8
    // gotoxy(x, ++y);
    // [2670] vera_verify::y#1 = ++ vera_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [2671] gotoxy::y#9 = vera_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2672] call gotoxy
    // [772] phi from vera_verify::@8 to gotoxy [phi:vera_verify::@8->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#9 [phi:vera_verify::@8->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = PROGRESS_X [phi:vera_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2673] phi from vera_verify::@8 to vera_verify::@3 [phi:vera_verify::@8->vera_verify::@3]
    // [2673] phi vera_verify::y#10 = vera_verify::y#1 [phi:vera_verify::@8->vera_verify::@3#0] -- register_copy 
    // [2673] phi vera_verify::progress_row_current#4 = 0 [phi:vera_verify::@8->vera_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2673] phi from vera_verify::@14 to vera_verify::@3 [phi:vera_verify::@14->vera_verify::@3]
    // [2673] phi vera_verify::y#10 = vera_verify::y#3 [phi:vera_verify::@14->vera_verify::@3#0] -- register_copy 
    // [2673] phi vera_verify::progress_row_current#4 = vera_verify::progress_row_current#3 [phi:vera_verify::@14->vera_verify::@3#1] -- register_copy 
    // vera_verify::@3
  __b3:
    // if (equal_bytes != VERA_PROGRESS_CELL)
    // [2674] if(vera_verify::equal_bytes#0!=VERA_PROGRESS_CELL) goto vera_verify::@4 -- vwum1_neq_vbuc1_then_la1 
    lda equal_bytes+1
    beq !__b4+
    jmp __b4
  !__b4:
    lda equal_bytes
    cmp #VERA_PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    // vera_verify::@9
    // cputc('=')
    // [2675] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [2676] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_verify::@5
  __b5:
    // vera_bram_address += VERA_PROGRESS_CELL
    // [2678] vera_verify::vera_bram_address#1 = vera_verify::vera_bram_address#10 + VERA_PROGRESS_CELL -- pbuz1=pbuz1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc.z vera_bram_address
    sta.z vera_bram_address
    bcc !+
    inc.z vera_bram_address+1
  !:
    // vera_address += VERA_PROGRESS_CELL
    // [2679] vera_verify::vera_address#1 = vera_verify::vera_address#11 + VERA_PROGRESS_CELL -- vdum1=vdum1_plus_vbuc1 
    lda vera_address
    clc
    adc #VERA_PROGRESS_CELL
    sta vera_address
    bcc !+
    inc vera_address+1
    bne !+
    inc vera_address+2
    bne !+
    inc vera_address+3
  !:
    // progress_row_current += VERA_PROGRESS_CELL
    // [2680] vera_verify::progress_row_current#11 = vera_verify::progress_row_current#4 + VERA_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc progress_row_current
    sta progress_row_current
    bcc !+
    inc progress_row_current+1
  !:
    // if (vera_bram_address == BRAM_HIGH)
    // [2681] if(vera_verify::vera_bram_address#1!=$c000) goto vera_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_address+1
    cmp #>$c000
    bne __b6
    lda.z vera_bram_address
    cmp #<$c000
    bne __b6
    // vera_verify::@10
    // vera_bram_bank++;
    // [2682] vera_verify::vera_bram_bank#1 = ++ vera_verify::vera_bram_bank#11 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2683] phi from vera_verify::@10 to vera_verify::@6 [phi:vera_verify::@10->vera_verify::@6]
    // [2683] phi vera_verify::vera_bram_bank#25 = vera_verify::vera_bram_bank#1 [phi:vera_verify::@10->vera_verify::@6#0] -- register_copy 
    // [2683] phi vera_verify::vera_bram_address#6 = (char *)$a000 [phi:vera_verify::@10->vera_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_address
    lda #>$a000
    sta.z vera_bram_address+1
    // [2683] phi from vera_verify::@5 to vera_verify::@6 [phi:vera_verify::@5->vera_verify::@6]
    // [2683] phi vera_verify::vera_bram_bank#25 = vera_verify::vera_bram_bank#11 [phi:vera_verify::@5->vera_verify::@6#0] -- register_copy 
    // [2683] phi vera_verify::vera_bram_address#6 = vera_verify::vera_bram_address#1 [phi:vera_verify::@5->vera_verify::@6#1] -- register_copy 
    // vera_verify::@6
  __b6:
    // if (vera_bram_address == RAM_HIGH)
    // [2684] if(vera_verify::vera_bram_address#6!=$9800) goto vera_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_address+1
    cmp #>$9800
    bne __b7
    lda.z vera_bram_address
    cmp #<$9800
    bne __b7
    // [2686] phi from vera_verify::@6 to vera_verify::@7 [phi:vera_verify::@6->vera_verify::@7]
    // [2686] phi vera_verify::vera_bram_address#11 = (char *)$a000 [phi:vera_verify::@6->vera_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_address
    lda #>$a000
    sta.z vera_bram_address+1
    // [2686] phi vera_verify::vera_bram_bank#10 = 1 [phi:vera_verify::@6->vera_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2685] phi from vera_verify::@6 to vera_verify::@24 [phi:vera_verify::@6->vera_verify::@24]
    // vera_verify::@24
    // [2686] phi from vera_verify::@24 to vera_verify::@7 [phi:vera_verify::@24->vera_verify::@7]
    // [2686] phi vera_verify::vera_bram_address#11 = vera_verify::vera_bram_address#6 [phi:vera_verify::@24->vera_verify::@7#0] -- register_copy 
    // [2686] phi vera_verify::vera_bram_bank#10 = vera_verify::vera_bram_bank#25 [phi:vera_verify::@24->vera_verify::@7#1] -- register_copy 
    // vera_verify::@7
  __b7:
    // VERA_PROGRESS_CELL - equal_bytes
    // [2687] vera_verify::$16 = VERA_PROGRESS_CELL - vera_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<VERA_PROGRESS_CELL
    sbc equal_bytes
    sta.z vera_verify__16
    lda #>VERA_PROGRESS_CELL
    sbc equal_bytes+1
    sta.z vera_verify__16+1
    // vera_different_bytes += (VERA_PROGRESS_CELL - equal_bytes)
    // [2688] vera_verify::vera_different_bytes#1 = vera_verify::vera_different_bytes#11 + vera_verify::$16 -- vdum1=vdum1_plus_vwuz2 
    lda vera_different_bytes
    clc
    adc.z vera_verify__16
    sta vera_different_bytes
    lda vera_different_bytes+1
    adc.z vera_verify__16+1
    sta vera_different_bytes+1
    lda vera_different_bytes+2
    adc #0
    sta vera_different_bytes+2
    lda vera_different_bytes+3
    adc #0
    sta vera_different_bytes+3
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2689] call snprintf_init
    // [1167] phi from vera_verify::@7 to snprintf_init [phi:vera_verify::@7->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:vera_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2690] phi from vera_verify::@7 to vera_verify::@15 [phi:vera_verify::@7->vera_verify::@15]
    // vera_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2691] call printf_str
    // [1172] phi from vera_verify::@15 to printf_str [phi:vera_verify::@15->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s [phi:vera_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2692] printf_ulong::uvalue#0 = vera_verify::vera_different_bytes#1 -- vdum1=vdum2 
    lda vera_different_bytes
    sta printf_ulong.uvalue
    lda vera_different_bytes+1
    sta printf_ulong.uvalue+1
    lda vera_different_bytes+2
    sta printf_ulong.uvalue+2
    lda vera_different_bytes+3
    sta printf_ulong.uvalue+3
    // [2693] call printf_ulong
    // [1628] phi from vera_verify::@16 to printf_ulong [phi:vera_verify::@16->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:vera_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:vera_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:vera_verify::@16->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#0 [phi:vera_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2694] phi from vera_verify::@16 to vera_verify::@17 [phi:vera_verify::@16->vera_verify::@17]
    // vera_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2695] call printf_str
    // [1172] phi from vera_verify::@17 to printf_str [phi:vera_verify::@17->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s1 [phi:vera_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2696] printf_uchar::uvalue#3 = vera_verify::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta printf_uchar.uvalue
    // [2697] call printf_uchar
    // [1307] phi from vera_verify::@18 to printf_uchar [phi:vera_verify::@18->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:vera_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 2 [phi:vera_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:vera_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:vera_verify::@18->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#3 [phi:vera_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2698] phi from vera_verify::@18 to vera_verify::@19 [phi:vera_verify::@18->vera_verify::@19]
    // vera_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2699] call printf_str
    // [1172] phi from vera_verify::@19 to printf_str [phi:vera_verify::@19->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s2 [phi:vera_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2700] printf_uint::uvalue#2 = (unsigned int)vera_verify::vera_bram_address#11 -- vwum1=vwuz2 
    lda.z vera_bram_address
    sta printf_uint.uvalue
    lda.z vera_bram_address+1
    sta printf_uint.uvalue+1
    // [2701] call printf_uint
    // [2254] phi from vera_verify::@20 to printf_uint [phi:vera_verify::@20->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 1 [phi:vera_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 4 [phi:vera_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &snputc [phi:vera_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:vera_verify::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = printf_uint::uvalue#2 [phi:vera_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2702] phi from vera_verify::@20 to vera_verify::@21 [phi:vera_verify::@20->vera_verify::@21]
    // vera_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2703] call printf_str
    // [1172] phi from vera_verify::@21 to printf_str [phi:vera_verify::@21->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:vera_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s3 [phi:vera_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2704] printf_ulong::uvalue#1 = vera_verify::vera_address#1 -- vdum1=vdum2 
    lda vera_address
    sta printf_ulong.uvalue
    lda vera_address+1
    sta printf_ulong.uvalue+1
    lda vera_address+2
    sta printf_ulong.uvalue+2
    lda vera_address+3
    sta printf_ulong.uvalue+3
    // [2705] call printf_ulong
    // [1628] phi from vera_verify::@22 to printf_ulong [phi:vera_verify::@22->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:vera_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:vera_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:vera_verify::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#1 [phi:vera_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // vera_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address)
    // [2706] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2707] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2709] call display_action_text
    // [1318] phi from vera_verify::@23 to display_action_text [phi:vera_verify::@23->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:vera_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2661] phi from vera_verify::@23 to vera_verify::@1 [phi:vera_verify::@23->vera_verify::@1]
    // [2661] phi vera_verify::y#3 = vera_verify::y#10 [phi:vera_verify::@23->vera_verify::@1#0] -- register_copy 
    // [2661] phi vera_verify::progress_row_current#3 = vera_verify::progress_row_current#11 [phi:vera_verify::@23->vera_verify::@1#1] -- register_copy 
    // [2661] phi vera_verify::vera_different_bytes#11 = vera_verify::vera_different_bytes#1 [phi:vera_verify::@23->vera_verify::@1#2] -- register_copy 
    // [2661] phi vera_verify::vera_bram_address#10 = vera_verify::vera_bram_address#11 [phi:vera_verify::@23->vera_verify::@1#3] -- register_copy 
    // [2661] phi vera_verify::vera_bram_bank#11 = vera_verify::vera_bram_bank#10 [phi:vera_verify::@23->vera_verify::@1#4] -- register_copy 
    // [2661] phi vera_verify::vera_address#11 = vera_verify::vera_address#1 [phi:vera_verify::@23->vera_verify::@1#5] -- register_copy 
    jmp __b1
    // vera_verify::@4
  __b4:
    // cputc('*')
    // [2710] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [2711] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b5
  .segment DataVera
    info_text: .text "Comparing VERA ..."
    .byte 0
    vera_boundary: .dword 0
    .label equal_bytes = vera_compare.equal_bytes
    y: .byte 0
    vera_address: .dword 0
    vera_bram_bank: .byte 0
    vera_different_bytes: .dword 0
    .label return = vera_different_bytes
    progress_row_current: .word 0
}
.segment CodeVera
  // vera_erase
vera_erase: {
    .label vera_erase__0 = $c9
    // BYTE2(vera_file_size)
    // [2713] vera_erase::$0 = byte2  vera_file_size#1 -- vbuz1=_byte2_vdum2 
    lda vera_file_size+2
    sta.z vera_erase__0
    // unsigned char vera_total_64k_blocks = BYTE2(vera_file_size)+1
    // [2714] vera_erase::vera_total_64k_blocks#0 = vera_erase::$0 + 1 -- vbum1=vbuz2_plus_1 
    inc
    sta vera_total_64k_blocks
    // [2715] phi from vera_erase to vera_erase::@1 [phi:vera_erase->vera_erase::@1]
    // [2715] phi vera_erase::vera_current_64k_block#2 = 0 [phi:vera_erase->vera_erase::@1#0] -- vbum1=vbuc1 
    lda #0
    sta vera_current_64k_block
    // vera_erase::@1
  __b1:
    // while(vera_current_64k_block < vera_total_64k_blocks)
    // [2716] if(vera_erase::vera_current_64k_block#2<vera_erase::vera_total_64k_blocks#0) goto vera_erase::@2 -- vbum1_lt_vbum2_then_la1 
    lda vera_current_64k_block
    cmp vera_total_64k_blocks
    bcc __b2
    // vera_erase::@return
    // }
    // [2717] return 
    rts
    // vera_erase::@2
  __b2:
    // vera_current_64k_block++;
    // [2718] vera_erase::vera_current_64k_block#1 = ++ vera_erase::vera_current_64k_block#2 -- vbum1=_inc_vbum1 
    inc vera_current_64k_block
    // [2715] phi from vera_erase::@2 to vera_erase::@1 [phi:vera_erase::@2->vera_erase::@1]
    // [2715] phi vera_erase::vera_current_64k_block#2 = vera_erase::vera_current_64k_block#1 [phi:vera_erase::@2->vera_erase::@1#0] -- register_copy 
    jmp __b1
  .segment DataVera
    vera_total_64k_blocks: .byte 0
    vera_current_64k_block: .byte 0
}
.segment CodeVera
  // vera_flash
vera_flash: {
    .label vera_flash__18 = $ae
    .label vera_bram_ptr = $7d
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [2720] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [874] phi from vera_flash to display_action_progress [phi:vera_flash->display_action_progress]
    // [874] phi display_action_progress::info_text#25 = string_0 [phi:vera_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<string_0
    sta.z display_action_progress.info_text
    lda #>string_0
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [2721] phi from vera_flash to vera_flash::@14 [phi:vera_flash->vera_flash::@14]
    // vera_flash::@14
    // display_info_vera(STATUS_FLASHING, "Flashing ...")
    // [2722] call display_info_vera
    // [968] phi from vera_flash::@14 to display_info_vera [phi:vera_flash::@14->display_info_vera]
    // [968] phi display_info_vera::info_text#15 = info_text1 [phi:vera_flash::@14->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [968] phi spi_memory_capacity#10 = 3 [phi:vera_flash::@14->display_info_vera#1] -- vbum1=vbuc1 
    lda #3
    sta spi_memory_capacity
    // [968] phi spi_memory_type#10 = 2 [phi:vera_flash::@14->display_info_vera#2] -- vbum1=vbuc1 
    lda #2
    sta spi_memory_type
    // [968] phi spi_manufacturer#10 = 1 [phi:vera_flash::@14->display_info_vera#3] -- vbum1=vbuc1 
    lda #1
    sta spi_manufacturer
    // [968] phi display_info_vera::info_status#15 = STATUS_FLASHING [phi:vera_flash::@14->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [2723] phi from vera_flash::@14 to vera_flash::@1 [phi:vera_flash::@14->vera_flash::@1]
    // [2723] phi vera_flash::vera_bram_ptr#10 = (char *)$a000 [phi:vera_flash::@14->vera_flash::@1#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2723] phi vera_flash::vera_bram_bank#11 = 1 [phi:vera_flash::@14->vera_flash::@1#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2723] phi vera_flash::y_sector#14 = PROGRESS_Y [phi:vera_flash::@14->vera_flash::@1#2] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [2723] phi vera_flash::x_sector#14 = PROGRESS_X [phi:vera_flash::@14->vera_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [2723] phi vera_flash::return#2 = 0 [phi:vera_flash::@14->vera_flash::@1#4] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
    // [2723] phi from vera_flash::@11 to vera_flash::@1 [phi:vera_flash::@11->vera_flash::@1]
    // [2723] phi vera_flash::vera_bram_ptr#10 = vera_flash::vera_bram_ptr#18 [phi:vera_flash::@11->vera_flash::@1#0] -- register_copy 
    // [2723] phi vera_flash::vera_bram_bank#11 = vera_flash::vera_bram_bank#14 [phi:vera_flash::@11->vera_flash::@1#1] -- register_copy 
    // [2723] phi vera_flash::y_sector#14 = vera_flash::y_sector#14 [phi:vera_flash::@11->vera_flash::@1#2] -- register_copy 
    // [2723] phi vera_flash::x_sector#14 = vera_flash::x_sector#1 [phi:vera_flash::@11->vera_flash::@1#3] -- register_copy 
    // [2723] phi vera_flash::return#2 = vera_flash::vera_address_page#12 [phi:vera_flash::@11->vera_flash::@1#4] -- register_copy 
    // vera_flash::@1
  __b1:
    // while (vera_address_page < vera_file_size)
    // [2724] if(vera_flash::return#2<vera_file_size#1) goto vera_flash::@2 -- vdum1_lt_vdum2_then_la1 
    lda return+3
    cmp vera_file_size+3
    bcc __b2
    bne !+
    lda return+2
    cmp vera_file_size+2
    bcc __b2
    bne !+
    lda return+1
    cmp vera_file_size+1
    bcc __b2
    bne !+
    lda return
    cmp vera_file_size
    bcc __b2
  !:
    // vera_flash::@3
    // display_action_text_flashed(vera_address_page, "VERA")
    // [2725] display_action_text_flashed::bytes#0 = vera_flash::return#2 -- vdum1=vdum2 
    lda return
    sta display_action_text_flashed.bytes
    lda return+1
    sta display_action_text_flashed.bytes+1
    lda return+2
    sta display_action_text_flashed.bytes+2
    lda return+3
    sta display_action_text_flashed.bytes+3
    // [2726] call display_action_text_flashed
    // [2837] phi from vera_flash::@3 to display_action_text_flashed [phi:vera_flash::@3->display_action_text_flashed]
    // [2837] phi display_action_text_flashed::chip#3 = vera_flash::chip [phi:vera_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2837] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#0 [phi:vera_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [2727] phi from vera_flash::@3 to vera_flash::@16 [phi:vera_flash::@3->vera_flash::@16]
    // vera_flash::@16
    // wait_moment(32)
    // [2728] call wait_moment
    // [1270] phi from vera_flash::@16 to wait_moment [phi:vera_flash::@16->wait_moment]
    // [1270] phi wait_moment::w#13 = $20 [phi:vera_flash::@16->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // vera_flash::@return
    // }
    // [2729] return 
    rts
    // vera_flash::@2
  __b2:
    // unsigned long vera_page_boundary = vera_address_page + VERA_PROGRESS_PAGE
    // [2730] vera_flash::vera_page_boundary#0 = vera_flash::return#2 + VERA_PROGRESS_PAGE -- vdum1=vdum2_plus_vwuc1 
    // {asm{.byte $db}}
    clc
    lda return
    adc #<VERA_PROGRESS_PAGE
    sta vera_page_boundary
    lda return+1
    adc #>VERA_PROGRESS_PAGE
    sta vera_page_boundary+1
    lda return+2
    adc #0
    sta vera_page_boundary+2
    lda return+3
    adc #0
    sta vera_page_boundary+3
    // cputcxy(x,y,'.')
    // [2731] cputcxy::x#1 = vera_flash::x_sector#14 -- vbum1=vbum2 
    lda x_sector
    sta cputcxy.x
    // [2732] cputcxy::y#1 = vera_flash::y_sector#14 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [2733] call cputcxy
    // [2167] phi from vera_flash::@2 to cputcxy [phi:vera_flash::@2->cputcxy]
    // [2167] phi cputcxy::c#18 = '.' [phi:vera_flash::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #'.'
    sta cputcxy.c
    // [2167] phi cputcxy::y#18 = cputcxy::y#1 [phi:vera_flash::@2->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#1 [phi:vera_flash::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_flash::@15
    // cputc('.')
    // [2734] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [2735] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_flash::bank_set_bram1
    // BRAM = bank
    // [2737] BRAM = vera_flash::vera_bram_bank#11 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // [2738] vera_flash::vera_address#13 = vera_flash::return#2 -- vdum1=vdum2 
    lda return
    sta vera_address
    lda return+1
    sta vera_address+1
    lda return+2
    sta vera_address+2
    lda return+3
    sta vera_address+3
    // [2739] phi from vera_flash::@17 vera_flash::bank_set_bram1 to vera_flash::@5 [phi:vera_flash::@17/vera_flash::bank_set_bram1->vera_flash::@5]
    // [2739] phi vera_flash::vera_address_page#12 = vera_flash::vera_address_page#1 [phi:vera_flash::@17/vera_flash::bank_set_bram1->vera_flash::@5#0] -- register_copy 
    // [2739] phi vera_flash::vera_bram_ptr#13 = vera_flash::vera_bram_ptr#1 [phi:vera_flash::@17/vera_flash::bank_set_bram1->vera_flash::@5#1] -- register_copy 
    // [2739] phi vera_flash::vera_address#10 = vera_flash::vera_address#1 [phi:vera_flash::@17/vera_flash::bank_set_bram1->vera_flash::@5#2] -- register_copy 
    // vera_flash::@5
  __b5:
    // while (vera_address < vera_page_boundary)
    // [2740] if(vera_flash::vera_address#10<vera_flash::vera_page_boundary#0) goto vera_flash::@6 -- vdum1_lt_vdum2_then_la1 
    lda vera_address+3
    cmp vera_page_boundary+3
    bcs !__b6+
    jmp __b6
  !__b6:
    bne !+
    lda vera_address+2
    cmp vera_page_boundary+2
    bcs !__b6+
    jmp __b6
  !__b6:
    bne !+
    lda vera_address+1
    cmp vera_page_boundary+1
    bcc __b6
    bne !+
    lda vera_address
    cmp vera_page_boundary
    bcc __b6
  !:
    // vera_flash::@4
    // if (vera_bram_ptr == BRAM_HIGH)
    // [2741] if(vera_flash::vera_bram_ptr#13!=$c000) goto vera_flash::@10 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b10
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b10
    // vera_flash::@12
    // vera_bram_bank++;
    // [2742] vera_flash::vera_bram_bank#1 = ++ vera_flash::vera_bram_bank#11 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2743] phi from vera_flash::@12 to vera_flash::@10 [phi:vera_flash::@12->vera_flash::@10]
    // [2743] phi vera_flash::vera_bram_bank#21 = vera_flash::vera_bram_bank#1 [phi:vera_flash::@12->vera_flash::@10#0] -- register_copy 
    // [2743] phi vera_flash::vera_bram_ptr#7 = (char *)$a000 [phi:vera_flash::@12->vera_flash::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2743] phi from vera_flash::@4 to vera_flash::@10 [phi:vera_flash::@4->vera_flash::@10]
    // [2743] phi vera_flash::vera_bram_bank#21 = vera_flash::vera_bram_bank#11 [phi:vera_flash::@4->vera_flash::@10#0] -- register_copy 
    // [2743] phi vera_flash::vera_bram_ptr#7 = vera_flash::vera_bram_ptr#13 [phi:vera_flash::@4->vera_flash::@10#1] -- register_copy 
    // vera_flash::@10
  __b10:
    // if (vera_bram_ptr == RAM_HIGH)
    // [2744] if(vera_flash::vera_bram_ptr#7!=$9800) goto vera_flash::@18 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b11
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b11
    // [2746] phi from vera_flash::@10 to vera_flash::@11 [phi:vera_flash::@10->vera_flash::@11]
    // [2746] phi vera_flash::vera_bram_ptr#18 = (char *)$a000 [phi:vera_flash::@10->vera_flash::@11#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2746] phi vera_flash::vera_bram_bank#14 = 1 [phi:vera_flash::@10->vera_flash::@11#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2745] phi from vera_flash::@10 to vera_flash::@18 [phi:vera_flash::@10->vera_flash::@18]
    // vera_flash::@18
    // [2746] phi from vera_flash::@18 to vera_flash::@11 [phi:vera_flash::@18->vera_flash::@11]
    // [2746] phi vera_flash::vera_bram_ptr#18 = vera_flash::vera_bram_ptr#7 [phi:vera_flash::@18->vera_flash::@11#0] -- register_copy 
    // [2746] phi vera_flash::vera_bram_bank#14 = vera_flash::vera_bram_bank#21 [phi:vera_flash::@18->vera_flash::@11#1] -- register_copy 
    // vera_flash::@11
  __b11:
    // x_sector += 2
    // [2747] vera_flash::x_sector#1 = vera_flash::x_sector#14 + 2 -- vbum1=vbum1_plus_2 
    lda x_sector
    clc
    adc #2
    sta x_sector
    // vera_address_page % VERA_PROGRESS_ROW
    // [2748] vera_flash::$18 = vera_flash::vera_address_page#12 & VERA_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
    lda vera_address_page
    and #<VERA_PROGRESS_ROW-1
    sta.z vera_flash__18
    lda vera_address_page+1
    and #>VERA_PROGRESS_ROW-1
    sta.z vera_flash__18+1
    lda vera_address_page+2
    and #<VERA_PROGRESS_ROW-1>>$10
    sta.z vera_flash__18+2
    lda vera_address_page+3
    and #>VERA_PROGRESS_ROW-1>>$10
    sta.z vera_flash__18+3
    // if (!(vera_address_page % VERA_PROGRESS_ROW))
    // [2749] if(0!=vera_flash::$18) goto vera_flash::@1 -- 0_neq_vduz1_then_la1 
    lda.z vera_flash__18
    ora.z vera_flash__18+1
    ora.z vera_flash__18+2
    ora.z vera_flash__18+3
    beq !__b1+
    jmp __b1
  !__b1:
    // vera_flash::@13
    // y_sector++;
    // [2750] vera_flash::y_sector#1 = ++ vera_flash::y_sector#14 -- vbum1=_inc_vbum1 
    inc y_sector
    // [2723] phi from vera_flash::@13 to vera_flash::@1 [phi:vera_flash::@13->vera_flash::@1]
    // [2723] phi vera_flash::vera_bram_ptr#10 = vera_flash::vera_bram_ptr#18 [phi:vera_flash::@13->vera_flash::@1#0] -- register_copy 
    // [2723] phi vera_flash::vera_bram_bank#11 = vera_flash::vera_bram_bank#14 [phi:vera_flash::@13->vera_flash::@1#1] -- register_copy 
    // [2723] phi vera_flash::y_sector#14 = vera_flash::y_sector#1 [phi:vera_flash::@13->vera_flash::@1#2] -- register_copy 
    // [2723] phi vera_flash::x_sector#14 = PROGRESS_X [phi:vera_flash::@13->vera_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [2723] phi vera_flash::return#2 = vera_flash::vera_address_page#12 [phi:vera_flash::@13->vera_flash::@1#4] -- register_copy 
    jmp __b1
    // vera_flash::@6
  __b6:
    // display_action_text_flashing(VERA_PROGRESS_PAGE, "VERA", vera_bram_bank, vera_bram_ptr, vera_address)
    // [2751] display_action_text_flashing::bram_bank#0 = vera_flash::vera_bram_bank#11 -- vbum1=vbum2 
    lda vera_bram_bank
    sta display_action_text_flashing.bram_bank
    // [2752] display_action_text_flashing::bram_ptr#0 = vera_flash::vera_bram_ptr#13 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [2753] display_action_text_flashing::address#0 = vera_flash::vera_address#10 -- vdum1=vdum2 
    lda vera_address
    sta display_action_text_flashing.address
    lda vera_address+1
    sta display_action_text_flashing.address+1
    lda vera_address+2
    sta display_action_text_flashing.address+2
    lda vera_address+3
    sta display_action_text_flashing.address+3
    // [2754] call display_action_text_flashing
    // [2854] phi from vera_flash::@6 to display_action_text_flashing [phi:vera_flash::@6->display_action_text_flashing]
    // [2854] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#0 [phi:vera_flash::@6->display_action_text_flashing#0] -- register_copy 
    // [2854] phi display_action_text_flashing::chip#10 = vera_flash::chip [phi:vera_flash::@6->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2854] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#0 [phi:vera_flash::@6->display_action_text_flashing#2] -- register_copy 
    // [2854] phi display_action_text_flashing::bram_bank#3 = display_action_text_flashing::bram_bank#0 [phi:vera_flash::@6->display_action_text_flashing#3] -- register_copy 
    // [2854] phi display_action_text_flashing::bytes#3 = VERA_PROGRESS_PAGE [phi:vera_flash::@6->display_action_text_flashing#4] -- vdum1=vduc1 
    lda #<VERA_PROGRESS_PAGE
    sta display_action_text_flashing.bytes
    lda #>VERA_PROGRESS_PAGE
    sta display_action_text_flashing.bytes+1
    lda #<VERA_PROGRESS_PAGE>>$10
    sta display_action_text_flashing.bytes+2
    lda #>VERA_PROGRESS_PAGE>>$10
    sta display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [2755] phi from vera_flash::@6 to vera_flash::@7 [phi:vera_flash::@6->vera_flash::@7]
    // [2755] phi vera_flash::i#2 = 0 [phi:vera_flash::@6->vera_flash::@7#0] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // vera_flash::@7
  __b7:
    // for(unsigned int i=0; i<=255; i++)
    // [2756] if(vera_flash::i#2<=$ff) goto vera_flash::@8 -- vwum1_le_vbuc1_then_la1 
    lda #$ff
    cmp i
    bcc !+
    lda i+1
    beq __b8
  !:
    // vera_flash::@9
    // cputcxy(x,y,'+')
    // [2757] cputcxy::x#2 = vera_flash::x_sector#14 -- vbum1=vbum2 
    lda x_sector
    sta cputcxy.x
    // [2758] cputcxy::y#2 = vera_flash::y_sector#14 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [2759] call cputcxy
    // [2167] phi from vera_flash::@9 to cputcxy [phi:vera_flash::@9->cputcxy]
    // [2167] phi cputcxy::c#18 = '+' [phi:vera_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [2167] phi cputcxy::y#18 = cputcxy::y#2 [phi:vera_flash::@9->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#2 [phi:vera_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_flash::@17
    // cputc('+')
    // [2760] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [2761] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_bram_ptr += VERA_PROGRESS_PAGE
    // [2763] vera_flash::vera_bram_ptr#1 = vera_flash::vera_bram_ptr#13 + VERA_PROGRESS_PAGE -- pbuz1=pbuz1_plus_vwuc1 
    lda.z vera_bram_ptr
    clc
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr+1
    // vera_address += VERA_PROGRESS_PAGE
    // [2764] vera_flash::vera_address#1 = vera_flash::vera_address#10 + VERA_PROGRESS_PAGE -- vdum1=vdum1_plus_vwuc1 
    clc
    lda vera_address
    adc #<VERA_PROGRESS_PAGE
    sta vera_address
    lda vera_address+1
    adc #>VERA_PROGRESS_PAGE
    sta vera_address+1
    lda vera_address+2
    adc #0
    sta vera_address+2
    lda vera_address+3
    adc #0
    sta vera_address+3
    // vera_address_page += VERA_PROGRESS_PAGE
    // [2765] vera_flash::vera_address_page#1 = vera_flash::vera_address_page#12 + VERA_PROGRESS_PAGE -- vdum1=vdum1_plus_vwuc1 
    clc
    lda vera_address_page
    adc #<VERA_PROGRESS_PAGE
    sta vera_address_page
    lda vera_address_page+1
    adc #>VERA_PROGRESS_PAGE
    sta vera_address_page+1
    lda vera_address_page+2
    adc #0
    sta vera_address_page+2
    lda vera_address_page+3
    adc #0
    sta vera_address_page+3
    jmp __b5
    // vera_flash::@8
  __b8:
    // for(unsigned int i=0; i<=255; i++)
    // [2766] vera_flash::i#1 = ++ vera_flash::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [2755] phi from vera_flash::@8 to vera_flash::@7 [phi:vera_flash::@8->vera_flash::@7]
    // [2755] phi vera_flash::i#2 = vera_flash::i#1 [phi:vera_flash::@8->vera_flash::@7#0] -- register_copy 
    jmp __b7
  .segment DataVera
    chip: .text "VERA"
    .byte 0
    vera_page_boundary: .dword 0
    // TODO: ERROR!!!
    return: .dword 0
    i: .word 0
    vera_address: .dword 0
    .label vera_address_page = return
    vera_bram_bank: .byte 0
    x_sector: .byte 0
    y_sector: .byte 0
}
.segment Code
  // display_info_roms
/**
 * @brief Display all the ROM statuses.
 * 
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_roms(char info_status, char *info_text)
display_info_roms: {
    .label info_text = 0
    // [2768] phi from display_info_roms to display_info_roms::@1 [phi:display_info_roms->display_info_roms::@1]
    // [2768] phi display_info_roms::rom_chip#2 = 0 [phi:display_info_roms->display_info_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // display_info_roms::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [2769] if(display_info_roms::rom_chip#2<8) goto display_info_roms::@2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b2
    // display_info_roms::@return
    // }
    // [2770] return 
    rts
    // display_info_roms::@2
  __b2:
    // display_info_rom(rom_chip, info_status, info_text)
    // [2771] display_info_rom::rom_chip#4 = display_info_roms::rom_chip#2 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [2772] call display_info_rom
    // [1440] phi from display_info_roms::@2 to display_info_rom [phi:display_info_roms::@2->display_info_rom]
    // [1440] phi display_info_rom::info_text#17 = display_info_roms::info_text#1 [phi:display_info_roms::@2->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1440] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#4 [phi:display_info_roms::@2->display_info_rom#1] -- register_copy 
    // [1440] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:display_info_roms::@2->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    // display_info_roms::@3
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [2773] display_info_roms::rom_chip#1 = ++ display_info_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [2768] phi from display_info_roms::@3 to display_info_roms::@1 [phi:display_info_roms::@3->display_info_roms::@1]
    // [2768] phi display_info_roms::rom_chip#2 = display_info_roms::rom_chip#1 [phi:display_info_roms::@3->display_info_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip: .byte 0
}
.segment CodeVera
  // spi_deselect
spi_deselect: {
    // *vera_reg_SPICtrl &= 0xfe
    // [2774] *vera_reg_SPICtrl = *vera_reg_SPICtrl & $fe -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    /*
.proc spi_deselect
    lda Vera::Reg::SPICtrl
    and #$fe
    sta Vera::Reg::SPICtrl
    jsr spi_read
	rts
.endproc
*/
    lda #$fe
    and vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // unsigned char value = spi_read()
    // [2775] call spi_read
    jsr spi_read
    // spi_deselect::@return
    // }
    // [2776] return 
    rts
}
.segment Code
  // rom_address_from_bank
/**
 * @brief Calculates the 22 bit ROM address from the 8 bit ROM bank.
 * The ROM bank number is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM address.
 * @return unsigned long The 22 bit ROM address.
 */
/* inline */
// __mem() unsigned long rom_address_from_bank(__mem() char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $bc
    // ((unsigned long)(rom_bank)) << 14
    // [2778] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbum2 
    lda rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2779] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vdum1=vduz2_rol_vbuc1 
    ldy #$e
    lda.z rom_address_from_bank__1
    sta return
    lda.z rom_address_from_bank__1+1
    sta return+1
    lda.z rom_address_from_bank__1+2
    sta return+2
    lda.z rom_address_from_bank__1+3
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
    // rom_address_from_bank::@return
    // }
    // [2780] return 
    rts
  .segment Data
    .label return = rom_read.rom_address
    rom_bank: .byte 0
    .label return_1 = rom_verify.rom_address
    .label return_2 = rom_flash.rom_address_sector
}
.segment Code
  // rom_compare
// __mem() unsigned int rom_compare(__mem() char bank_ram, __zp($4d) char *ptr_ram, __mem() unsigned long rom_compare_address, __mem() unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $3b
    .label rom_bank1_rom_compare__0 = $51
    .label rom_bank1_rom_compare__1 = $3c
    .label rom_bank1_rom_compare__2 = $61
    .label rom_ptr1_rom_compare__0 = $45
    .label rom_ptr1_rom_compare__2 = $45
    .label rom_ptr1_return = $45
    .label ptr_rom = $45
    .label ptr_ram = $4d
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2782] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2783] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vdum2 
    lda rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2784] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vdum2 
    lda rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2785] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2786] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_compare__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2787] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2788] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vdum2 
    lda rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2789] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2790] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2791] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // [2792] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2793] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2793] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [2793] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2793] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2793] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2794] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwum1_lt_vwum2_then_la1 
    lda compared_bytes+1
    cmp rom_compare_size+1
    bcc __b2
    bne !+
    lda compared_bytes
    cmp rom_compare_size
    bcc __b2
  !:
    // rom_compare::@return
    // }
    // [2795] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2796] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2797] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta rom_byte_compare.value
    // [2798] call rom_byte_compare
    jsr rom_byte_compare
    // [2799] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2800] rom_compare::$5 = rom_byte_compare::return#2 -- vbuz1=vbum2 
    lda rom_byte_compare.return
    sta.z rom_compare__5
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2801] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2802] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [2803] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2803] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2804] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2805] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2806] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [2793] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2793] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2793] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2793] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2793] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
  .segment Data
    bank_set_bram1_bank: .byte 0
    rom_bank1_bank_unshifted: .word 0
    rom_bank1_return: .byte 0
    compared_bytes: .word 0
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    equal_bytes: .word 0
    .label bank_ram = bank_set_bram1_bank
    rom_compare_address: .dword 0
    .label return = equal_bytes
    rom_compare_size: .word 0
}
.segment Code
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__mem() unsigned long value, __zp($37) char *buffer, __mem() char radix)
ultoa: {
    .label ultoa__4 = $3c
    .label ultoa__10 = $34
    .label ultoa__11 = $3b
    .label buffer = $37
    .label digit_values = $35
    // if(radix==DECIMAL)
    // [2807] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2808] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2809] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2810] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2811] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2812] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2813] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2814] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2815] return 
    rts
    // [2816] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2816] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2816] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2816] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2816] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2816] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2816] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2816] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2816] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2816] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2816] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2816] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2817] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2817] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2817] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2817] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2817] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2818] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2819] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2820] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2821] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2822] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2823] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2824] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2825] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    iny
    lda (digit_values),y
    sta digit_value+2
    iny
    lda (digit_values),y
    sta digit_value+3
    // if (started || value >= digit_value)
    // [2826] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2827] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
    lda value+3
    cmp digit_value+3
    bcc !+
    bne __b10
    lda value+2
    cmp digit_value+2
    bcc !+
    bne __b10
    lda value+1
    cmp digit_value+1
    bcc !+
    bne __b10
    lda value
    cmp digit_value
    bcs __b10
  !:
    // [2828] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2828] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2828] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2828] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2829] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2817] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2817] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2817] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2817] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2817] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2830] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2831] ultoa_append::value#0 = ultoa::value#2
    // [2832] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2833] call ultoa_append
    // [3206] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2834] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2835] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2836] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2828] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2828] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2828] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2828] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .dword 0
    digit: .byte 0
    .label value = printf_ulong.uvalue
    .label radix = printf_ulong.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // display_action_text_flashed
// void display_action_text_flashed(__mem() unsigned long bytes, __zp($39) char *chip)
display_action_text_flashed: {
    .label chip = $39
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2838] call snprintf_init
    // [1167] phi from display_action_text_flashed to snprintf_init [phi:display_action_text_flashed->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:display_action_text_flashed->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2839] phi from display_action_text_flashed to display_action_text_flashed::@1 [phi:display_action_text_flashed->display_action_text_flashed::@1]
    // display_action_text_flashed::@1
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2840] call printf_str
    // [1172] phi from display_action_text_flashed::@1 to printf_str [phi:display_action_text_flashed::@1->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashed::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_action_text_flashed::s [phi:display_action_text_flashed::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@2
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2841] printf_ulong::uvalue#4 = display_action_text_flashed::bytes#3 -- vdum1=vdum2 
    lda bytes
    sta printf_ulong.uvalue
    lda bytes+1
    sta printf_ulong.uvalue+1
    lda bytes+2
    sta printf_ulong.uvalue+2
    lda bytes+3
    sta printf_ulong.uvalue+3
    // [2842] call printf_ulong
    // [1628] phi from display_action_text_flashed::@2 to printf_ulong [phi:display_action_text_flashed::@2->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 0 [phi:display_action_text_flashed::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 0 [phi:display_action_text_flashed::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = DECIMAL [phi:display_action_text_flashed::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#4 [phi:display_action_text_flashed::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2843] phi from display_action_text_flashed::@2 to display_action_text_flashed::@3 [phi:display_action_text_flashed::@2->display_action_text_flashed::@3]
    // display_action_text_flashed::@3
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2844] call printf_str
    // [1172] phi from display_action_text_flashed::@3 to printf_str [phi:display_action_text_flashed::@3->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashed::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_action_text_flashed::s1 [phi:display_action_text_flashed::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@4
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2845] printf_string::str#13 = display_action_text_flashed::chip#3 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [2846] call printf_string
    // [1181] phi from display_action_text_flashed::@4 to printf_string [phi:display_action_text_flashed::@4->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:display_action_text_flashed::@4->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#13 [phi:display_action_text_flashed::@4->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_flashed::@4->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_flashed::@4->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2847] phi from display_action_text_flashed::@4 to display_action_text_flashed::@5 [phi:display_action_text_flashed::@4->display_action_text_flashed::@5]
    // display_action_text_flashed::@5
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2848] call printf_str
    // [1172] phi from display_action_text_flashed::@5 to printf_str [phi:display_action_text_flashed::@5->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashed::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s5 [phi:display_action_text_flashed::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@6
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2849] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2850] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2852] call display_action_text
    // [1318] phi from display_action_text_flashed::@6 to display_action_text [phi:display_action_text_flashed::@6->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:display_action_text_flashed::@6->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashed::@return
    // }
    // [2853] return 
    rts
  .segment Data
    s: .text "Flashed "
    .byte 0
    s1: .text " bytes from RAM -> "
    .byte 0
    bytes: .dword 0
}
.segment Code
  // display_action_text_flashing
// void display_action_text_flashing(__mem() unsigned long bytes, __zp($69) char *chip, __mem() char bram_bank, __zp($67) char *bram_ptr, __mem() unsigned long address)
display_action_text_flashing: {
    .label bram_ptr = $67
    .label chip = $69
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2855] call snprintf_init
    // [1167] phi from display_action_text_flashing to snprintf_init [phi:display_action_text_flashing->snprintf_init]
    // [1167] phi snprintf_init::s#33 = info_text [phi:display_action_text_flashing->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2856] phi from display_action_text_flashing to display_action_text_flashing::@1 [phi:display_action_text_flashing->display_action_text_flashing::@1]
    // display_action_text_flashing::@1
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2857] call printf_str
    // [1172] phi from display_action_text_flashing::@1 to printf_str [phi:display_action_text_flashing::@1->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashing::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_action_text_flashing::s [phi:display_action_text_flashing::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@2
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2858] printf_ulong::uvalue#2 = display_action_text_flashing::bytes#3 -- vdum1=vdum2 
    lda bytes
    sta printf_ulong.uvalue
    lda bytes+1
    sta printf_ulong.uvalue+1
    lda bytes+2
    sta printf_ulong.uvalue+2
    lda bytes+3
    sta printf_ulong.uvalue+3
    // [2859] call printf_ulong
    // [1628] phi from display_action_text_flashing::@2 to printf_ulong [phi:display_action_text_flashing::@2->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 0 [phi:display_action_text_flashing::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 0 [phi:display_action_text_flashing::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = DECIMAL [phi:display_action_text_flashing::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#2 [phi:display_action_text_flashing::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2860] phi from display_action_text_flashing::@2 to display_action_text_flashing::@3 [phi:display_action_text_flashing::@2->display_action_text_flashing::@3]
    // display_action_text_flashing::@3
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2861] call printf_str
    // [1172] phi from display_action_text_flashing::@3 to printf_str [phi:display_action_text_flashing::@3->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashing::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_action_text_flashing::s1 [phi:display_action_text_flashing::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@4
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2862] printf_uchar::uvalue#8 = display_action_text_flashing::bram_bank#3 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [2863] call printf_uchar
    // [1307] phi from display_action_text_flashing::@4 to printf_uchar [phi:display_action_text_flashing::@4->printf_uchar]
    // [1307] phi printf_uchar::format_zero_padding#21 = 1 [phi:display_action_text_flashing::@4->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1307] phi printf_uchar::format_min_length#21 = 2 [phi:display_action_text_flashing::@4->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1307] phi printf_uchar::putc#21 = &snputc [phi:display_action_text_flashing::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1307] phi printf_uchar::format_radix#21 = HEXADECIMAL [phi:display_action_text_flashing::@4->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1307] phi printf_uchar::uvalue#21 = printf_uchar::uvalue#8 [phi:display_action_text_flashing::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2864] phi from display_action_text_flashing::@4 to display_action_text_flashing::@5 [phi:display_action_text_flashing::@4->display_action_text_flashing::@5]
    // display_action_text_flashing::@5
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2865] call printf_str
    // [1172] phi from display_action_text_flashing::@5 to printf_str [phi:display_action_text_flashing::@5->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashing::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s2 [phi:display_action_text_flashing::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@6
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2866] printf_uint::uvalue#4 = (unsigned int)display_action_text_flashing::bram_ptr#3 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2867] call printf_uint
    // [2254] phi from display_action_text_flashing::@6 to printf_uint [phi:display_action_text_flashing::@6->printf_uint]
    // [2254] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2254] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_flashing::@6->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2254] phi printf_uint::putc#10 = &snputc [phi:display_action_text_flashing::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2254] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@6->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2254] phi printf_uint::uvalue#10 = printf_uint::uvalue#4 [phi:display_action_text_flashing::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2868] phi from display_action_text_flashing::@6 to display_action_text_flashing::@7 [phi:display_action_text_flashing::@6->display_action_text_flashing::@7]
    // display_action_text_flashing::@7
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2869] call printf_str
    // [1172] phi from display_action_text_flashing::@7 to printf_str [phi:display_action_text_flashing::@7->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashing::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = display_action_text_flashing::s3 [phi:display_action_text_flashing::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@8
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2870] printf_string::str#12 = display_action_text_flashing::chip#10 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [2871] call printf_string
    // [1181] phi from display_action_text_flashing::@8 to printf_string [phi:display_action_text_flashing::@8->printf_string]
    // [1181] phi printf_string::putc#26 = &snputc [phi:display_action_text_flashing::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1181] phi printf_string::str#26 = printf_string::str#12 [phi:display_action_text_flashing::@8->printf_string#1] -- register_copy 
    // [1181] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_flashing::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1181] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_flashing::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2872] phi from display_action_text_flashing::@8 to display_action_text_flashing::@9 [phi:display_action_text_flashing::@8->display_action_text_flashing::@9]
    // display_action_text_flashing::@9
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2873] call printf_str
    // [1172] phi from display_action_text_flashing::@9 to printf_str [phi:display_action_text_flashing::@9->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashing::@9->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s2 [phi:display_action_text_flashing::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@10
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2874] printf_ulong::uvalue#3 = display_action_text_flashing::address#10 -- vdum1=vdum2 
    lda address
    sta printf_ulong.uvalue
    lda address+1
    sta printf_ulong.uvalue+1
    lda address+2
    sta printf_ulong.uvalue+2
    lda address+3
    sta printf_ulong.uvalue+3
    // [2875] call printf_ulong
    // [1628] phi from display_action_text_flashing::@10 to printf_ulong [phi:display_action_text_flashing::@10->printf_ulong]
    // [1628] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_flashing::@10->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1628] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_flashing::@10->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1628] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_flashing::@10->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1628] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#3 [phi:display_action_text_flashing::@10->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2876] phi from display_action_text_flashing::@10 to display_action_text_flashing::@11 [phi:display_action_text_flashing::@10->display_action_text_flashing::@11]
    // display_action_text_flashing::@11
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2877] call printf_str
    // [1172] phi from display_action_text_flashing::@11 to printf_str [phi:display_action_text_flashing::@11->printf_str]
    // [1172] phi printf_str::putc#89 = &snputc [phi:display_action_text_flashing::@11->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1172] phi printf_str::s#89 = s5 [phi:display_action_text_flashing::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@12
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2878] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2879] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2881] call display_action_text
    // [1318] phi from display_action_text_flashing::@12 to display_action_text [phi:display_action_text_flashing::@12->display_action_text]
    // [1318] phi display_action_text::info_text#23 = info_text [phi:display_action_text_flashing::@12->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashing::@return
    // }
    // [2882] return 
    rts
  .segment Data
    s: .text "Flashing "
    .byte 0
    s1: .text " bytes from RAM:"
    .byte 0
    s3: .text " -> "
    .byte 0
    bram_bank: .byte 0
    address: .dword 0
    bytes: .dword 0
}
.segment Code
  // rom_write
/* inline */
// unsigned long rom_write(__mem() char flash_ram_bank, __zp($4b) char *flash_ram_address, __mem() unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label flash_ram_address = $4b
    // rom_write::bank_set_bram1
    // BRAM = bank
    // [2884] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbum2 
    lda flash_ram_bank
    sta.z BRAM
    // [2885] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2885] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2885] phi rom_write::flash_rom_address#2 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2885] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flashed_bytes
    sta flashed_bytes+1
    lda #<0>>$10
    sta flashed_bytes+2
    lda #>0>>$10
    sta flashed_bytes+3
    // rom_write::@1
  __b1:
    // while (flashed_bytes < flash_rom_size)
    // [2886] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vdum1_lt_vduc1_then_la1 
    lda flashed_bytes+3
    cmp #>ROM_PROGRESS_CELL>>$10
    bcc __b2
    bne !+
    lda flashed_bytes+2
    cmp #<ROM_PROGRESS_CELL>>$10
    bcc __b2
    bne !+
    lda flashed_bytes+1
    cmp #>ROM_PROGRESS_CELL
    bcc __b2
    bne !+
    lda flashed_bytes
    cmp #<ROM_PROGRESS_CELL
    bcc __b2
  !:
    // rom_write::@return
    // }
    // [2887] return 
    rts
    // rom_write::@2
  __b2:
    // flash_rom_address++;
    // [2888] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#2 -- vdum1=_inc_vdum1 
    inc flash_rom_address
    bne !+
    inc flash_rom_address+1
    bne !+
    inc flash_rom_address+2
    bne !+
    inc flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2889] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2890] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vdum1=_inc_vdum1 
    inc flashed_bytes
    bne !+
    inc flashed_bytes+1
    bne !+
    inc flashed_bytes+2
    bne !+
    inc flashed_bytes+3
  !:
    // [2885] phi from rom_write::@2 to rom_write::@1 [phi:rom_write::@2->rom_write::@1]
    // [2885] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@2->rom_write::@1#0] -- register_copy 
    // [2885] phi rom_write::flash_rom_address#2 = rom_write::flash_rom_address#0 [phi:rom_write::@2->rom_write::@1#1] -- register_copy 
    // [2885] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@2->rom_write::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    flash_rom_address: .dword 0
    flashed_bytes: .dword 0
    flash_ram_bank: .byte 0
}
.segment Code
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    // __mem unsigned char ch
    // [2891] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [2893] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [2894] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [2895] return 
    rts
  .segment Data
    ch: .byte 0
    return: .byte 0
}
.segment Code
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($52) char *dst, __zp($37) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $52
    .label src = $37
    // [2897] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2897] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [2897] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [2897] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2898] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
    lda i+1
    cmp n+1
    bcc __b2
    bne !+
    lda i
    cmp n
    bcc __b2
  !:
    // strncpy::@return
    // }
    // [2899] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2900] strncpy::c#0 = *strncpy::src#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [2901] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [2902] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2903] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2903] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2904] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2905] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2906] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [2897] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2897] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2897] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2897] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
    i: .word 0
    n: .word 0
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $32
    .label insertup__4 = $29
    .label insertup__6 = $2a
    .label insertup__7 = $29
    // __conio.width+1
    // [2907] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2908] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [2909] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2909] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2910] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [2911] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2912] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2913] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2914] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2915] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [2916] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2917] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [2918] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [2919] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [2920] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [2921] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [2922] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2923] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [2909] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2909] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    width: .byte 0
    y: .byte 0
}
.segment Code
  // clearline
clearline: {
    .label clearline__0 = $24
    .label clearline__1 = $25
    .label clearline__2 = $26
    .label clearline__3 = $23
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [2924] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2925] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2926] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2927] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2928] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2929] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2930] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2931] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2932] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2933] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2934] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2934] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2935] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2936] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2937] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2938] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2939] return 
    rts
  .segment Data
    addr: .word 0
}
.segment Code
  // display_frame_maskxy
/**
 * @brief 
 * 
 * @param x 
 * @param y 
 * @return unsigned char 
 */
// __mem() char display_frame_maskxy(__mem() char x, __mem() char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $34
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $3b
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $5c
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2941] gotoxy::x#10 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [2942] gotoxy::y#10 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [2943] call gotoxy
    // [772] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#10 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#10 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2944] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2945] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2946] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2947] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2948] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2949] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2950] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2951] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbum1=_deref_pbuc1 
    lda VERA_DATA0
    sta c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2952] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$70
    cmp c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2953] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6e
    cmp c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2954] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6d
    cmp c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2955] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$7d
    cmp c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2956] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2957] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$5d
    cmp c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2958] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6b
    cmp c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2959] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$73
    cmp c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2960] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$72
    cmp c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2961] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$71
    cmp c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2962] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbum1_eq_vbuc1_then_la1 
    lda #$5b
    cmp c
    beq __b11
    // [2964] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2964] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [2963] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2964] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2964] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2964] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2964] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2964] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2964] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2964] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2964] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2964] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2964] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2964] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [2964] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2964] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // display_frame_maskxy::@return
    // }
    // [2965] return 
    rts
  .segment Data
    cpeekcxy1_x: .byte 0
    cpeekcxy1_y: .byte 0
    c: .byte 0
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
    return: .byte 0
    .label x = cpeekcxy1_x
    .label y = cpeekcxy1_y
}
.segment Code
  // display_frame_char
/**
 * @brief 
 * 
 * @param mask 
 * @return unsigned char 
 */
// __mem() char display_frame_char(__mem() char mask)
display_frame_char: {
    // case 0b0110:
    //             return 0x70;
    // [2967] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2968] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2969] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2970] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2971] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2972] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2973] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2974] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2975] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2976] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2977] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [2979] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2979] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$20
    sta return
    rts
    // [2978] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2979] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2979] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5b
    sta return
    rts
    // [2979] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2979] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$70
    sta return
    rts
    // [2979] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2979] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6e
    sta return
    rts
    // [2979] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2979] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6d
    sta return
    rts
    // [2979] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2979] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$7d
    sta return
    rts
    // [2979] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2979] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$40
    sta return
    rts
    // [2979] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2979] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5d
    sta return
    rts
    // [2979] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2979] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6b
    sta return
    rts
    // [2979] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2979] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$73
    sta return
    rts
    // [2979] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2979] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$72
    sta return
    rts
    // [2979] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2979] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$71
    sta return
    // display_frame_char::@return
    // }
    // [2980] return 
    rts
  .segment Data
    .label return = cputcxy.c
    .label mask = display_frame_maskxy.return
}
.segment Code
  // display_chip_led
/**
 * @brief Print the colored led of a chip figure.
 * 
 * @param x Start X
 * @param y Start Y
 * @param w width
 * @param tc Fore color
 * @param bc Back color
 */
// void display_chip_led(__mem() char x, char y, __mem() char w, __mem() char tc, char bc)
display_chip_led: {
    // textcolor(tc)
    // [2982] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [2983] call textcolor
    // [754] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [754] phi textcolor::color#23 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2984] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2985] call bgcolor
    // [759] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [2986] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2986] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2986] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2987] cputcxy::x#12 = display_chip_led::x#4 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2988] call cputcxy
    // [2167] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [2167] phi cputcxy::c#18 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [2167] phi cputcxy::y#18 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [2167] phi cputcxy::x#18 = cputcxy::x#12 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2989] cputcxy::x#13 = display_chip_led::x#4 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2990] call cputcxy
    // [2167] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [2167] phi cputcxy::c#18 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [2167] phi cputcxy::y#18 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [2167] phi cputcxy::x#18 = cputcxy::x#13 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2991] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbum1=_inc_vbum1 
    inc x
    // while(--w)
    // [2992] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbum1=_dec_vbum1 
    dec w
    // [2993] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbum1_then_la1 
    lda w
    bne __b1
    // [2994] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2995] call textcolor
    // [754] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2996] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2997] call bgcolor
    // [759] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2998] return 
    rts
  .segment Data
    x: .byte 0
    w: .byte 0
    tc: .byte 0
}
.segment Code
  // display_chip_line
/**
 * @brief Print one line of a chip figure.
 * 
 * @param x Start X
 * @param y Start Y
 * @param w Width
 * @param c Fore color
 */
// void display_chip_line(__mem() char x, __mem() char y, __mem() char w, __mem() char c)
display_chip_line: {
    // gotoxy(x, y)
    // [3000] gotoxy::x#12 = display_chip_line::x#16 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [3001] gotoxy::y#12 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [3002] call gotoxy
    // [772] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [772] phi gotoxy::y#38 = gotoxy::y#12 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [772] phi gotoxy::x#38 = gotoxy::x#12 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [3003] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [3004] call textcolor
    // [754] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [754] phi textcolor::color#23 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3005] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [3006] call bgcolor
    // [759] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [3007] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [3008] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [3010] call textcolor
    // [754] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [3011] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [3012] call bgcolor
    // [759] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [759] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [3013] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [3013] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [3014] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [3015] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [3016] call textcolor
    // [754] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [754] phi textcolor::color#23 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3017] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [3018] call bgcolor
    // [759] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [3019] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [3020] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [3022] call textcolor
    // [754] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [754] phi textcolor::color#23 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [3023] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [3024] call bgcolor
    // [759] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [759] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [3025] cputcxy::x#11 = display_chip_line::x#16 + 2 -- vbum1=vbum2_plus_2 
    lda x
    clc
    adc #2
    sta cputcxy.x
    // [3026] cputcxy::y#11 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [3027] cputcxy::c#11 = display_chip_line::c#15 -- vbum1=vbum2 
    lda c
    sta cputcxy.c
    // [3028] call cputcxy
    // [2167] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [2167] phi cputcxy::c#18 = cputcxy::c#11 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [2167] phi cputcxy::y#18 = cputcxy::y#11 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [2167] phi cputcxy::x#18 = cputcxy::x#11 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [3029] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [3030] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [3031] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [3033] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [3013] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [3013] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    x: .byte 0
    w: .byte 0
    c: .byte 0
    y: .byte 0
}
.segment Code
  // display_chip_end
/**
 * @brief Print last line of a chip figure.
 * 
 * @param x Start X
 * @param y Start Y
 * @param w Width
 */
// void display_chip_end(__mem() char x, char y, __mem() char w)
display_chip_end: {
    // gotoxy(x, y)
    // [3034] gotoxy::x#13 = display_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [3035] call gotoxy
    // [772] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [772] phi gotoxy::y#38 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [772] phi gotoxy::x#38 = gotoxy::x#13 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [3036] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [3037] call textcolor
    // [754] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [754] phi textcolor::color#23 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3038] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [3039] call bgcolor
    // [759] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [3040] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [3041] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [3043] call textcolor
    // [754] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [754] phi textcolor::color#23 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [3044] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [3045] call bgcolor
    // [759] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [759] phi bgcolor::color#15 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [3046] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [3046] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [3047] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [3048] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [3049] call textcolor
    // [754] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [754] phi textcolor::color#23 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3050] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [3051] call bgcolor
    // [759] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [759] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [3052] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [3053] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [3055] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [3056] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [3057] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [3059] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [3046] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [3046] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    .label x = display_print_chip.x
    w: .byte 0
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($39) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $3b
    .label utoa__10 = $34
    .label utoa__11 = $5c
    .label buffer = $39
    .label digit_values = $37
    // if(radix==DECIMAL)
    // [3060] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [3061] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [3062] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [3063] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [3064] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [3065] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [3066] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [3067] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [3068] return 
    rts
    // [3069] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [3069] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [3069] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [3069] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [3069] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [3069] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [3069] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [3069] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [3069] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [3069] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [3069] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [3069] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [3070] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [3070] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [3070] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [3070] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [3070] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [3071] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [3072] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [3073] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [3074] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [3075] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [3076] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [3077] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [3078] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [3079] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [3080] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [3081] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [3081] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [3081] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [3081] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [3082] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [3070] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [3070] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [3070] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [3070] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [3070] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [3083] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [3084] utoa_append::value#0 = utoa::value#2
    // [3085] utoa_append::sub#0 = utoa::digit_value#0
    // [3086] call utoa_append
    // [3233] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [3087] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [3088] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [3089] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [3081] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [3081] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [3081] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [3081] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .word 0
    digit: .byte 0
    .label value = printf_uint.uvalue
    .label radix = printf_uint.format_radix
    started: .byte 0
    max_digits: .byte 0
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
    // [3091] return 
    rts
  .segment Data
    channel: .byte 0
    device: .byte 0
    command: .byte 0
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
// __mem() int ferror(__zp($56) struct $2 *stream)
ferror: {
    .label ferror__6 = $34
    .label ferror__15 = $5c
    .label cbm_k_setnam1_filename = $b8
    .label cbm_k_setnam1_ferror__0 = $58
    .label stream = $56
    .label errno_len = $6b
    // unsigned char sp = (unsigned char)stream
    // [3092] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [3093] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [3094] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [3095] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [3096] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [3097] ferror::cbm_k_setnam1_filename = info_text26 -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z cbm_k_setnam1_filename
    lda #>info_text26
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [3098] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [3099] call strlen
    // [2471] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2471] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [3100] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [3101] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [3102] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_ferror__0
    sta cbm_k_setnam1_filename_len
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
    // [3105] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [3106] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [3108] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [3110] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [3111] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [3112] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [3113] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [3113] phi __errno#122 = __errno#458 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [3113] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [3113] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [3113] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [3114] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [3116] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [3117] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [3118] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [3119] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [3120] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [3121] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [3122] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [3124] ferror::return#1 = __errno#122 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [3125] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [3126] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [3127] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [3128] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [3129] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [3130] call strncpy
    // [2896] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [2896] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [2896] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [2896] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [3131] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [3132] call atoi
    // [3144] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [3144] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [3133] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [3134] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [3135] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [3135] phi __errno#178 = __errno#122 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [3135] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [3136] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [3137] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [3138] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [3140] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [3141] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [3142] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [3143] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [3113] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [3113] phi __errno#122 = __errno#178 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [3113] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [3113] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [3113] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_chrin1_ch: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_chrin2_ch: .byte 0
    return: .word 0
    sp: .byte 0
    .label cbm_k_chrin1_return = ch
    ch: .byte 0
    cbm_k_readst1_return: .byte 0
    st: .byte 0
    cbm_k_chrin2_return: .byte 0
    errno_parsed: .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __mem() int atoi(__zp($5a) const char *str)
atoi: {
    .label atoi__6 = $52
    .label atoi__7 = $52
    .label str = $5a
    .label atoi__10 = $52
    .label atoi__11 = $52
    // if (str[i] == '-')
    // [3145] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [3146] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [3147] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [3147] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [3147] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [3147] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [3147] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [3147] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [3147] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [3147] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [3148] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [3149] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [3150] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [3152] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [3152] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [3151] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [3153] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [3154] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [3155] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [3156] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [3157] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [3158] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [3159] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [3147] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [3147] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [3147] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [3147] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
    jmp __b3
  .segment Data
    .label res = return
    // Initialize sign as positive
    i: .byte 0
    return: .word 0
    // Initialize result
    negative: .byte 0
}
.segment Code
  // cx16_k_macptr
/**
 * @brief Read a number of bytes from the sdcard using kernal macptr call.
 * BRAM bank needs to be set properly before the load between adressed A000 and BFFF.
 *
 * @return x the size of bytes read
 * @return y the size of bytes read
 * @return if carry is set there is an error
 */
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($54) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $54
    // unsigned int bytes_read
    // [3160] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
    lda #<0
    sta bytes_read
    sta bytes_read+1
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
    // [3162] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [3163] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [3164] return 
    rts
  .segment Data
    bytes: .byte 0
    bytes_read: .word 0
    .label return = fgets.bytes
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
// __mem() char uctoa_append(__zp($42) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $42
    // [3166] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [3166] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3166] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [3167] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [3168] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [3169] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [3170] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3171] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [3166] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [3166] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [3166] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = smc_get_version_text.release
    .label sub = uctoa.digit_value
    .label return = smc_get_version_text.release
    digit: .byte 0
}
.segment CodeVera
  // spi_read_flash
// void spi_read_flash(unsigned long spi_data)
spi_read_flash: {
    // spi_select()
    // [3173] call spi_select
  /* 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_read_flash
    pha

    jsr spi_select
    lda #$03
    jsr spi_write
    pla
    jsr spi_write
    tya
    jsr spi_write
    txa
    jsr spi_write

    rts
.endproc
 */
    // [3240] phi from spi_read_flash to spi_select [phi:spi_read_flash->spi_select]
    jsr spi_select
    // spi_read_flash::@1
    // spi_write(0x03)
    // [3174] spi_write::data = 3 -- vbum1=vbuc1 
    lda #3
    sta spi_write.data
    // [3175] call spi_write
    jsr spi_write
    // spi_read_flash::@2
    // spi_write(BYTE2(spi_data))
    // [3176] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3177] call spi_write
    jsr spi_write
    // spi_read_flash::@3
    // spi_write(BYTE1(spi_data))
    // [3178] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3179] call spi_write
    jsr spi_write
    // spi_read_flash::@4
    // spi_write(BYTE0(spi_data))
    // [3180] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3181] call spi_write
    jsr spi_write
    // spi_read_flash::@return
    // }
    // [3182] return 
    rts
}
  // vera_compare
// __mem() unsigned int vera_compare(__mem() char bank_ram, __zp($63) char *bram_ptr, unsigned int vera_compare_size)
vera_compare: {
    .label bram_ptr = $63
    // vera_compare::bank_set_bram1
    // BRAM = bank
    // [3184] BRAM = vera_compare::bank_ram#0 -- vbuz1=vbum2 
    lda bank_ram
    sta.z BRAM
    // [3185] phi from vera_compare::bank_set_bram1 to vera_compare::@1 [phi:vera_compare::bank_set_bram1->vera_compare::@1]
    // [3185] phi vera_compare::bram_ptr#2 = vera_compare::bram_ptr#0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#0] -- register_copy 
    // [3185] phi vera_compare::equal_bytes#2 = 0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [3185] phi vera_compare::compared_bytes#2 = 0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#2] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // vera_compare::@1
  __b1:
    // while (compared_bytes < vera_compare_size)
    // [3186] if(vera_compare::compared_bytes#2<VERA_PROGRESS_CELL) goto vera_compare::@2 -- vwum1_lt_vbuc1_then_la1 
    lda compared_bytes+1
    bne !+
    lda compared_bytes
    cmp #VERA_PROGRESS_CELL
    bcc __b2
  !:
    // vera_compare::@return
    // }
    // [3187] return 
    rts
    // [3188] phi from vera_compare::@1 to vera_compare::@2 [phi:vera_compare::@1->vera_compare::@2]
    // vera_compare::@2
  __b2:
    // unsigned char vera_byte = spi_read()
    // [3189] call spi_read
    jsr spi_read
    // [3190] spi_read::return#3 = spi_read::return#1
    // vera_compare::@5
    // [3191] vera_compare::vera_byte#0 = spi_read::return#3
    // if (vera_byte == *bram_ptr)
    // [3192] if(vera_compare::vera_byte#0!=*vera_compare::bram_ptr#2) goto vera_compare::@3 -- vbum1_neq__deref_pbuz2_then_la1 
    ldy #0
    lda (bram_ptr),y
    cmp vera_byte
    bne __b3
    // vera_compare::@4
    // equal_bytes++;
    // [3193] vera_compare::equal_bytes#1 = ++ vera_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [3194] phi from vera_compare::@4 vera_compare::@5 to vera_compare::@3 [phi:vera_compare::@4/vera_compare::@5->vera_compare::@3]
    // [3194] phi vera_compare::equal_bytes#6 = vera_compare::equal_bytes#1 [phi:vera_compare::@4/vera_compare::@5->vera_compare::@3#0] -- register_copy 
    // vera_compare::@3
  __b3:
    // bram_ptr++;
    // [3195] vera_compare::bram_ptr#1 = ++ vera_compare::bram_ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z bram_ptr
    bne !+
    inc.z bram_ptr+1
  !:
    // compared_bytes++;
    // [3196] vera_compare::compared_bytes#1 = ++ vera_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [3185] phi from vera_compare::@3 to vera_compare::@1 [phi:vera_compare::@3->vera_compare::@1]
    // [3185] phi vera_compare::bram_ptr#2 = vera_compare::bram_ptr#1 [phi:vera_compare::@3->vera_compare::@1#0] -- register_copy 
    // [3185] phi vera_compare::equal_bytes#2 = vera_compare::equal_bytes#6 [phi:vera_compare::@3->vera_compare::@1#1] -- register_copy 
    // [3185] phi vera_compare::compared_bytes#2 = vera_compare::compared_bytes#1 [phi:vera_compare::@3->vera_compare::@1#2] -- register_copy 
    jmp __b1
  .segment DataVera
    bank_ram: .byte 0
    .label return = equal_bytes
    .label vera_byte = spi_read.return
    compared_bytes: .word 0
    /// Holds the amount of bytes actually verified between the VERA and the RAM.
    equal_bytes: .word 0
}
.segment CodeVera
  // spi_read
spi_read: {
    // unsigned char SPIData
    // [3197] spi_read::SPIData = 0 -- vbum1=vbuc1 
    /*
    .proc spi_read
	stz Vera::Reg::SPIData
@1:	bit Vera::Reg::SPICtrl
	bmi @1
    lda Vera::Reg::SPIData
	rts
.endproc
*/
    lda #0
    sta SPIData
    // asm
    // asm { stzvera_reg_SPIData !: bitvera_reg_SPICtrl bmi!- ldavera_reg_SPIData staSPIData  }
    stz vera_reg_SPIData
  !:
    bit vera_reg_SPICtrl
    bmi !-
    lda vera_reg_SPIData
    sta SPIData
    // return SPIData;
    // [3199] spi_read::return#0 = spi_read::SPIData -- vbum1=vbum2 
    sta return
    // spi_read::@return
    // }
    // [3200] spi_read::return#1 = spi_read::return#0
    // [3201] return 
    rts
  .segment DataVera
    SPIData: .byte 0
    return: .byte 0
}
.segment Code
  // rom_byte_compare
/**
 * @brief Verify a byte with the flashed ROM using the 22 bit rom address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
// __mem() char rom_byte_compare(__zp($45) char *ptr_rom, __mem() char value)
rom_byte_compare: {
    .label ptr_rom = $45
    // if (*ptr_rom != value)
    // [3202] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbum2_then_la1 
    lda value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [3203] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [3204] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [3204] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    tya
    sta return
    rts
    // [3204] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [3204] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [3205] return 
    rts
  .segment Data
    return: .byte 0
    value: .byte 0
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
// __mem() unsigned long ultoa_append(__zp($40) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $40
    // [3207] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [3207] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3207] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [3208] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [3209] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [3210] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [3211] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3212] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [3207] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [3207] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [3207] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_ulong.uvalue
    .label sub = ultoa.digit_value
    .label return = printf_ulong.uvalue
    digit: .byte 0
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
    .label memcpy8_vram_vram__0 = $23
    .label memcpy8_vram_vram__1 = $24
    .label memcpy8_vram_vram__2 = $25
    .label memcpy8_vram_vram__3 = $26
    .label memcpy8_vram_vram__4 = $27
    .label memcpy8_vram_vram__5 = $28
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [3213] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [3214] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [3215] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [3216] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [3217] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [3218] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [3219] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [3220] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [3221] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [3222] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [3223] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [3224] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [3225] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [3226] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [3227] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [3227] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [3228] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [3229] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [3230] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [3231] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [3232] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
    lda num8
    sta num8_1
    jmp __b1
  .segment Data
    num8: .byte 0
    dbank_vram: .byte 0
    doffset_vram: .word 0
    sbank_vram: .byte 0
    soffset_vram: .word 0
    num8_1: .byte 0
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
// __mem() unsigned int utoa_append(__zp($3e) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $3e
    // [3234] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [3234] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3234] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [3235] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [3236] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [3237] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [3238] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3239] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [3234] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [3234] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [3234] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uint.uvalue
    .label sub = utoa.digit_value
    .label return = printf_uint.uvalue
    digit: .byte 0
}
.segment CodeVera
  // spi_select
spi_select: {
    // spi_deselect()
    // [3241] call spi_deselect
    /*
.proc spi_select
    jsr spi_deselect

    lda Vera::Reg::SPICtrl
    ora #$01
    sta Vera::Reg::SPICtrl
	rts
.endproc
*/
    jsr spi_deselect
    // spi_select::@1
    // *vera_reg_SPICtrl |= 1
    // [3242] *vera_reg_SPICtrl = *vera_reg_SPICtrl | 1 -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #1
    ora vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // spi_select::@return
    // }
    // [3243] return 
    rts
}
  // spi_write
/**
 * @brief 
 * 
 * 
 */
// void spi_write(__mem() volatile char data)
spi_write: {
    // asm
    // asm { ldadata stavera_reg_SPIData !: bitvera_reg_SPICtrl bmi!-  }
    /*
.proc spi_write
	sta Vera::Reg::SPIData
@1:	bit Vera::Reg::SPICtrl
	bmi @1
	rts
.endproc
*/
    lda data
    sta vera_reg_SPIData
  !:
    bit vera_reg_SPICtrl
    bmi !-
    // spi_write::@return
    // }
    // [3245] return 
    rts
  .segment DataVera
    data: .byte 0
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
  // Values of binary digits
  RADIX_BINARY_VALUES_LONG: .dword $80000000, $40000000, $20000000, $10000000, $8000000, $4000000, $2000000, $1000000, $800000, $400000, $200000, $100000, $80000, $40000, $20000, $10000, $8000, $4000, $2000, $1000, $800, $400, $200, $100, $80, $40, $20, $10, 8, 4, 2
  // Values of octal digits
  RADIX_OCTAL_VALUES_LONG: .dword $40000000, $8000000, $1000000, $200000, $40000, $8000, $1000, $200, $40, 8
  // Values of decimal digits
  RADIX_DECIMAL_VALUES_LONG: .dword $3b9aca00, $5f5e100, $989680, $f4240, $186a0, $2710, $3e8, $64, $a
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_LONG: .dword $10000000, $1000000, $100000, $10000, $1000, $100, $10
.segment DataIntro
  display_into_briefing_text: .word __3, __4, info_text26, __6, __7, __8, __9, __10, __11, info_text26, __13, __14, info_text26, __16, __17
  display_into_colors_text: .word __18, __19, info_text26, __21, __22, __23, __24, __25, __26, __27, __28, __29, __30, __31, info_text26, __33
.segment DataVera
  display_jp1_spi_vera_text: .word __34, info_text26, __36, __37, __38, __39, __40, info_text26, __42, __43, info_text26, __45, __46, __47, info_text26, __49
.segment Data
  display_smc_rom_issue_text: .word __59, info_text26, __69, __62, info_text26, __64, __65, __66
  display_smc_unsupported_rom_text: .word __67, info_text26, __69, __70, info_text26, __72, __73
  display_debriefing_text_smc: .word __88, info_text26, main.text, info_text26, __78, __79, __80, info_text26, __82, info_text26, __84, __85, __86, __87
  display_debriefing_text_rom: .word __88, info_text26, __90, __91
  smc_file_header: .fill $20, 0
  smc_version_text: .fill $10, 0
  // Globals
  rom_device_ids: .byte 0
  .fill 7, 0
  rom_device_names: .word 0
  .fill 2*7, 0
  rom_size_strings: .word 0
  .fill 2*7, 0
  rom_release_text: .fill 8*$d, 0
  rom_release: .fill 8, 0
  rom_prefix: .fill 8, 0
  rom_github: .fill 8*8, 0
  rom_manufacturer_ids: .byte 0
  .fill 7, 0
  rom_sizes: .dword 0
  .fill 4*7, 0
  file_sizes: .dword 0
  .fill 4*7, 0
  status_rom: .byte 0
  .fill 7, 0
  info_text: .fill $50, 0
  status_text: .word __92, __93, __94, smc_action_text_1, smc_action_text, __97, __98, __99, __100, __101, __102, __103
  status_color: .byte BLACK, GREY, WHITE, CYAN, PURPLE, CYAN, PURPLE, PURPLE, GREEN, YELLOW, RED, PINK
  __3: .text "Welcome to the CX16 update tool! This program updates the"
  .byte 0
  __4: .text "chipsets on your CX16 and ROM expansion boards."
  .byte 0
  __6: .text "Depending on the files found on the SDCard, various"
  .byte 0
  __7: .text "components will be updated:"
  .byte 0
  __8: .text "- Mandatory: SMC.BIN for the SMC firmware."
  .byte 0
  __9: .text "- Mandatory: ROM.BIN for the main ROM."
  .byte 0
  __10: .text "- Optional: VERA.BIN for the VERA firmware."
  .byte 0
  __11: .text "- Optional: ROMn.BIN for a ROM expansion board or cartridge."
  .byte 0
  __13: .text "  Important: Ensure J1 write-enable jumper is closed"
  .byte 0
  __14: .text "  on both the main board and any ROM expansion board."
  .byte 0
  __16: .text "Please carefully read the step-by-step instructions at "
  .byte 0
  __17: .text "https://flightcontrol-user.github.io/x16-flash"
  .byte 0
  __18: .text "The panels above indicate the update progress,"
  .byte 0
  __19: .text "using status indicators and colors as specified below:"
  .byte 0
  __21: .text " -   None       Not detected, no action."
  .byte 0
  __22: .text " -   Skipped    Detected, but no action, eg. no file."
  .byte 0
  __23: .text " -   Detected   Detected, verification pending."
  .byte 0
  __24: .text " -   Checking   Verifying size of the update file."
  .byte 0
  __25: .text " -   Reading    Reading the update file into RAM."
  .byte 0
  __26: .text " -   Comparing  Comparing the RAM with the ROM."
  .byte 0
  __27: .text " -   Update     Ready to update the firmware."
  .byte 0
  __28: .text " -   Updating   Updating the firmware."
  .byte 0
  __29: .text " -   Updated    Updated the firmware succesfully."
  .byte 0
  __30: .text " -   Issue      Problem identified during update."
  .byte 0
  __31: .text " -   Error      Error found during update."
  .byte 0
  __33: .text "Errors can indicate J1 jumpers are not closed!"
  .byte 0
  __34: .text "The following steps are IMPORTANT to update the VERA:"
  .byte 0
  __36: .text "1. In the next step you will be asked to close the JP1 jumper"
  .byte 0
  __37: .text "   pins on the VERA board."
  .byte 0
  __38: .text "   The closure of the JP1 jumper pins is required"
  .byte 0
  __39: .text "   to allow the program to access VERA flash memory"
  .byte 0
  __40: .text "   instead of the SDCard!"
  .byte 0
  __42: .text "2. Once the VERA has been updated, you will be asked top open"
  .byte 0
  __43: .text "   the JP1 jumper pins!"
  .byte 0
  __45: .text "Reminder:"
  .byte 0
  __46: .text " - DON'T CLOSE THE JP1 JUMPER PINS BEFORE BEING ASKED!"
  .byte 0
  __47: .text " - DON'T OPEN THE JP1 JUMPER PINS WHILE VERA IS BEING UPDATED!"
  .byte 0
  __49: .text "The program continues once the JP1 pins are opened/closed."
  .byte 0
  __59: .text "There is an issue with the CX16 SMC or ROM flash readiness."
  .byte 0
  __62: .text "to avoid possible conflicts of firmware, bricking your CX16."
  .byte 0
  __64: .text "Therefore, ensure you have the correct SMC.BIN and ROM.BIN"
  .byte 0
  __65: .text "files placed on your SDcard. Also ensure that the"
  .byte 0
  __66: .text "J1 jumper pins on the CX16 board are closed."
  .byte 0
  __67: .text "There is an issue with the CX16 SMC or ROM flash versions."
  .byte 0
  __69: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __70: .text "to avoid possible conflicts, risking bricking your CX16."
  .byte 0
  __72: .text "The SMC.BIN and ROM.BIN found on your SDCard may not be"
  .byte 0
  __73: .text "mutually compatible. Update the CX16 at your own risk!"
  .byte 0
  __78: .text "Because your SMC chipset has been updated,"
  .byte 0
  __79: .text "the restart process differs, depending on the"
  .byte 0
  __80: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __82: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __84: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __85: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __86: .text "  The power-off button won't work!"
  .byte 0
  __87: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __88: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __90: .text "Since your CX16 system SMC chip has not been updated"
  .byte 0
  __91: .text "your CX16 will just reset automatically after count down."
  .byte 0
  __92: .text "None"
  .byte 0
  __93: .text "Skip"
  .byte 0
  __94: .text "Detected"
  .byte 0
  __97: .text "Comparing"
  .byte 0
  __98: .text "Update"
  .byte 0
  __99: .text "Updating"
  .byte 0
  __100: .text "Updated"
  .byte 0
  __101: .text "Issue"
  .byte 0
  __102: .text "Error"
  .byte 0
  __103: .text "Waiting"
  .byte 0
  s4: .text "/"
  .byte 0
  s: .text "Comparing: "
  .byte 0
  s1: .text " differences between RAM:"
  .byte 0
  s2: .text ":"
  .byte 0
  s3: .text " <-> ROM:"
  .byte 0
  string_0: .text "Flashing ... (-) equal, (+) flashed, (!) error."
  .byte 0
  info_text1: .text "Flashing ..."
  .byte 0
  filter: .text " "
  .byte 0
  chip: .text "ROM"
  .byte 0
  s5: .text " ... "
  .byte 0
  s6: .text " ..."
  .byte 0
  s21: .text "["
  .byte 0
  info_text32: .text "No update required"
  .byte 0
  s13: .text " differences!"
  .byte 0
  smc_action_text: .text "Reading"
  .byte 0
  smc_action_text_1: .text "Checking"
  .byte 0
  info_text26: .text ""
  .byte 0
  isr_vsync: .word $314
  __conio: .fill SIZEOF_STRUCT___1, 0
  // Buffer used for stringified number being printed
  printf_buffer: .fill SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER, 0
  /// The capacity of the buffer (n passed to snprintf())
  /// Used to hold state while printing
  __snprintf_capacity: .word 0
  // The number of chars that would have been filled when printing without capacity. Grows even after size>capacity.
  /// Used to hold state while printing
  __snprintf_size: .word 0
  __stdio_file: .fill SIZEOF_STRUCT___2, 0
  __stdio_filecount: .byte 0
  __errno: .word 0
  // Globals
  status_smc: .byte 0
.segment DataVera
  vera_file_size: .dword 0
.segment Data
  smc_release: .byte 0
  smc_major: .byte 0
  smc_minor: .byte 0
  smc_file_size: .word 0
  smc_file_release: .byte 0
  smc_file_major: .byte 0
  smc_file_minor: .byte 0
  smc_file_size_1: .word 0
.segment DataVera
  // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
  spi_manufacturer: .byte 0
  spi_memory_type: .byte 0
  spi_memory_capacity: .byte 0
.segment Data
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader: .word 0
  status_vera: .byte 0
