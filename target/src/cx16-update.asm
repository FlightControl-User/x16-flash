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
  // Some addressing constants.
  // These pre-processor directives allow to disable specific ROM flashing functions (for emulator development purposes).
  // Normally they should be all activated.
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
  .const display_no_valid_smc_bootloader_count = 9
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
  .const STATUS_WAITING = $b
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
  .label __snprintf_buffer = $68
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
    .label conio_x16_init__5 = $ad
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [783] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [788] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [801] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label cputc__2 = $52
    .label cputc__3 = $53
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
    .label main__87 = $d1
    .label main__111 = $e7
    .label main__112 = $e8
    .label main__113 = $d0
    .label main__192 = $63
    .label check_status_smc1_main__0 = $71
    .label check_status_rom1_main__0 = $ea
    .label check_status_smc11_main__0 = $eb
    .label check_status_smc12_main__0 = $ec
    .label rom_chip = $d9
    .label rom_chip1 = $da
    .label rom_chip2 = $de
    .label rom_bytes_read = $ed
    .label rom_file_modulo = $e3
    .label rom_file_prefix = $f1
    .label rom_chip3 = $d4
    .label flashed_bytes = $c7
    .label rom_chip4 = $dd
    .label file1 = $d2
    .label rom_bytes_read1 = $df
    .label rom_differences = $f8
    .label w = $dc
    .label w1 = $db
    .label main__372 = $d1
    .label main__373 = $d1
    .label main__374 = $d1
    .label main__376 = $d0
    .label main__377 = $d0
    .label main__378 = $d0
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
    // [72] phi from main to main::@99 [phi:main->main::@99]
    // main::@99
    // display_frame_draw()
    // [73] call display_frame_draw
  // ST1 | Reset canvas to 64 columns
    // [850] phi from main::@99 to display_frame_draw [phi:main::@99->display_frame_draw]
    jsr display_frame_draw
    // [74] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // display_frame_title("Commander X16 Update Utility (v2.2.0).")
    // [75] call display_frame_title
    // [891] phi from main::@100 to display_frame_title [phi:main::@100->display_frame_title]
    jsr display_frame_title
    // [76] phi from main::@100 to main::display_info_title1 [phi:main::@100->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [77] call cputsxy
    // [896] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [896] phi cputsxy::s#4 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [896] phi cputsxy::y#4 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [896] phi cputsxy::x#4 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [78] phi from main::display_info_title1 to main::@101 [phi:main::display_info_title1->main::@101]
    // main::@101
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [79] call cputsxy
    // [896] phi from main::@101 to cputsxy [phi:main::@101->cputsxy]
    // [896] phi cputsxy::s#4 = main::s1 [phi:main::@101->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [896] phi cputsxy::y#4 = $11-1 [phi:main::@101->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [896] phi cputsxy::x#4 = 4-2 [phi:main::@101->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [80] phi from main::@101 to main::@67 [phi:main::@101->main::@67]
    // main::@67
    // display_action_progress("Introduction, please read carefully the below!")
    // [81] call display_action_progress
    // [903] phi from main::@67 to display_action_progress [phi:main::@67->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text [phi:main::@67->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [82] phi from main::@67 to main::@102 [phi:main::@67->main::@102]
    // main::@102
    // display_progress_clear()
    // [83] call display_progress_clear
    // [917] phi from main::@102 to display_progress_clear [phi:main::@102->display_progress_clear]
    jsr display_progress_clear
    // [84] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // display_chip_smc()
    // [85] call display_chip_smc
    // [932] phi from main::@103 to display_chip_smc [phi:main::@103->display_chip_smc]
    jsr display_chip_smc
    // [86] phi from main::@103 to main::@104 [phi:main::@103->main::@104]
    // main::@104
    // display_chip_vera()
    // [87] call display_chip_vera
    // [937] phi from main::@104 to display_chip_vera [phi:main::@104->display_chip_vera]
    jsr display_chip_vera
    // [88] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // display_chip_rom()
    // [89] call display_chip_rom
    // [942] phi from main::@105 to display_chip_rom [phi:main::@105->display_chip_rom]
    jsr display_chip_rom
    // [90] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [91] call display_info_smc
    // [961] phi from main::@106 to display_info_smc [phi:main::@106->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = 0 [phi:main::@106->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = 0 [phi:main::@106->display_info_smc#1] -- vwum1=vwuc1 
    sta smc_bootloader_1
    sta smc_bootloader_1+1
    // [961] phi display_info_smc::info_status#20 = BLACK [phi:main::@106->display_info_smc#2] -- vbum1=vbuc1 
    lda #BLACK
    sta display_info_smc.info_status
    jsr display_info_smc
    // [92] phi from main::@106 to main::@107 [phi:main::@106->main::@107]
    // main::@107
    // display_info_vera(STATUS_NONE, NULL)
    // [93] call display_info_vera
    // [997] phi from main::@107 to display_info_vera [phi:main::@107->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = 0 [phi:main::@107->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = 0 [phi:main::@107->display_info_vera#1] -- vbum1=vbuc1 
    sta spi_memory_capacity
    // [997] phi spi_memory_type#107 = 0 [phi:main::@107->display_info_vera#2] -- vbum1=vbuc1 
    sta spi_memory_type
    // [997] phi spi_manufacturer#108 = 0 [phi:main::@107->display_info_vera#3] -- vbum1=vbuc1 
    sta spi_manufacturer
    // [997] phi display_info_vera::info_status#19 = STATUS_NONE [phi:main::@107->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_vera.info_status
    jsr display_info_vera
    // [94] phi from main::@107 to main::@12 [phi:main::@107->main::@12]
    // [94] phi main::rom_chip#2 = 0 [phi:main::@107->main::@12#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // main::@12
  __b12:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [95] if(main::rom_chip#2<8) goto main::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcs !__b13+
    jmp __b13
  !__b13:
    // [96] phi from main::@12 to main::@14 [phi:main::@12->main::@14]
    // main::@14
    // main_intro()
    // [97] call main_intro
    // [1037] phi from main::@14 to main_intro [phi:main::@14->main_intro]
    jsr main_intro
    // [98] phi from main::@14 to main::@110 [phi:main::@14->main::@110]
    // main::@110
    // smc_detect()
    // [99] call smc_detect
    jsr smc_detect
    // [100] smc_detect::return#2 = smc_detect::return#0
    // main::@111
    // smc_bootloader = smc_detect()
    // [101] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwum2 
    lda smc_detect.return
    sta smc_bootloader
    lda smc_detect.return+1
    sta smc_bootloader+1
    // strcpy(smc_version_text, "0.0.0")
    // [102] call strcpy
    // [1065] phi from main::@111 to strcpy [phi:main::@111->strcpy]
    // [1065] phi strcpy::dst#0 = smc_version_text [phi:main::@111->strcpy#0] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z strcpy.dst
    lda #>smc_version_text
    sta.z strcpy.dst+1
    // [1065] phi strcpy::src#0 = main::source1 [phi:main::@111->strcpy#1] -- pbuz1=pbuc1 
    lda #<source1
    sta.z strcpy.src
    lda #>source1
    sta.z strcpy.src+1
    jsr strcpy
    // [103] phi from main::@111 to main::@112 [phi:main::@111->main::@112]
    // main::@112
    // display_chip_smc()
    // [104] call display_chip_smc
    // [932] phi from main::@112 to display_chip_smc [phi:main::@112->display_chip_smc]
    jsr display_chip_smc
    // main::@113
    // if(smc_bootloader == 0x0100)
    // [105] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$100
    bne !+
    lda smc_bootloader+1
    cmp #>$100
    bne !__b1+
    jmp __b1
  !__b1:
  !:
    // main::@15
    // if(smc_bootloader == 0x0200)
    // [106] if(smc_bootloader#0==$200) goto main::@18 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$200
    bne !+
    lda smc_bootloader+1
    cmp #>$200
    bne !__b18+
    jmp __b18
  !__b18:
  !:
    // main::@16
    // if(smc_bootloader > 0x2)
    // [107] if(smc_bootloader#0>=2+1) goto main::@19 -- vwum1_ge_vbuc1_then_la1 
    lda smc_bootloader+1
    beq !__b19+
    jmp __b19
  !__b19:
    lda smc_bootloader
    cmp #2+1
    bcc !__b19+
    jmp __b19
  !__b19:
  !:
    // main::@17
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [108] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [109] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [110] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [111] cx16_k_i2c_read_byte::return#14 = cx16_k_i2c_read_byte::return#1
    // main::@120
    // smc_release = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [112] smc_release#0 = cx16_k_i2c_read_byte::return#14 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_release
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [113] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [114] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [115] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [116] cx16_k_i2c_read_byte::return#15 = cx16_k_i2c_read_byte::return#1
    // main::@121
    // smc_major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [117] smc_major#0 = cx16_k_i2c_read_byte::return#15 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_major
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [118] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [119] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [120] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [121] cx16_k_i2c_read_byte::return#16 = cx16_k_i2c_read_byte::return#1
    // main::@122
    // smc_minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [122] smc_minor#0 = cx16_k_i2c_read_byte::return#16 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_minor
    // smc_get_version_text(smc_version_text, smc_release, smc_major, smc_minor)
    // [123] smc_get_version_text::release#0 = smc_release#0 -- vbum1=vbum2 
    lda smc_release
    sta smc_get_version_text.release
    // [124] smc_get_version_text::major#0 = smc_major#0 -- vbum1=vbum2 
    lda smc_major
    sta smc_get_version_text.major
    // [125] smc_get_version_text::minor#0 = smc_minor#0 -- vbum1=vbum2 
    lda smc_minor
    sta smc_get_version_text.minor
    // [126] call smc_get_version_text
    // [1078] phi from main::@122 to smc_get_version_text [phi:main::@122->smc_get_version_text]
    // [1078] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#0 [phi:main::@122->smc_get_version_text#0] -- register_copy 
    // [1078] phi smc_get_version_text::major#2 = smc_get_version_text::major#0 [phi:main::@122->smc_get_version_text#1] -- register_copy 
    // [1078] phi smc_get_version_text::release#2 = smc_get_version_text::release#0 [phi:main::@122->smc_get_version_text#2] -- register_copy 
    // [1078] phi smc_get_version_text::version_string#2 = smc_version_text [phi:main::@122->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // main::@123
    // [127] smc_bootloader#508 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_DETECTED, NULL)
    // [128] call display_info_smc
    // [961] phi from main::@123 to display_info_smc [phi:main::@123->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = 0 [phi:main::@123->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#508 [phi:main::@123->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_DETECTED [phi:main::@123->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_smc.info_status
    jsr display_info_smc
    // [129] phi from main::@123 to main::@2 [phi:main::@123->main::@2]
    // [129] phi smc_minor#403 = smc_minor#0 [phi:main::@123->main::@2#0] -- register_copy 
    // [129] phi smc_major#404 = smc_major#0 [phi:main::@123->main::@2#1] -- register_copy 
    // [129] phi smc_release#405 = smc_release#0 [phi:main::@123->main::@2#2] -- register_copy 
    // main::@2
  __b2:
    // main_vera_detect()
    // [130] call main_vera_detect
    // [1095] phi from main::@2 to main_vera_detect [phi:main::@2->main_vera_detect]
    jsr main_vera_detect
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [132] phi from main::SEI1 to main::@68 [phi:main::SEI1->main::@68]
    // main::@68
    // rom_detect()
    // [133] call rom_detect
  // Detecting ROM chips
    // [1104] phi from main::@68 to rom_detect [phi:main::@68->rom_detect]
    jsr rom_detect
    // [134] phi from main::@68 to main::@124 [phi:main::@68->main::@124]
    // main::@124
    // display_chip_rom()
    // [135] call display_chip_rom
    // [942] phi from main::@124 to display_chip_rom [phi:main::@124->display_chip_rom]
    jsr display_chip_rom
    // [136] phi from main::@124 to main::@20 [phi:main::@124->main::@20]
    // [136] phi main::rom_chip1#10 = 0 [phi:main::@124->main::@20#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip1
    // main::@20
  __b20:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [137] if(main::rom_chip1#10<8) goto main::@21 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip1
    cmp #8
    bcs !__b21+
    jmp __b21
  !__b21:
    // main::bank_set_brom1
    // BROM = bank
    // [138] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc1
    // status_smc == status
    // [140] main::check_status_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [141] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0 -- vbum1=vbuz2 
    sta check_status_smc1_return
    // main::@69
    // if(check_status_smc(STATUS_DETECTED))
    // [142] if(0==main::check_status_smc1_return#0) goto main::CLI2 -- 0_eq_vbum1_then_la1 
    bne !__b7+
    jmp __b7
  !__b7:
    // [143] phi from main::@69 to main::@24 [phi:main::@69->main::@24]
    // main::@24
    // display_action_progress("Checking SMC.BIN ...")
    // [144] call display_action_progress
    // [903] phi from main::@24 to display_action_progress [phi:main::@24->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text3 [phi:main::@24->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [145] phi from main::@24 to main::@130 [phi:main::@24->main::@130]
    // main::@130
    // smc_read(STATUS_CHECKING)
    // [146] call smc_read
    // [1154] phi from main::@130 to smc_read [phi:main::@130->smc_read]
    // [1154] phi __errno#102 = 0 [phi:main::@130->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [1154] phi __stdio_filecount#128 = 0 [phi:main::@130->smc_read#1] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [1154] phi smc_read::info_status#10 = STATUS_CHECKING [phi:main::@130->smc_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_CHECKING)
    // [147] smc_read::return#2 = smc_read::return#0
    // main::@131
    // smc_file_size = smc_read(STATUS_CHECKING)
    // [148] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [149] if(0==smc_file_size#0) goto main::@27 -- 0_eq_vwum1_then_la1 
    lda smc_file_size
    ora smc_file_size+1
    bne !__b27+
    jmp __b27
  !__b27:
    // main::@25
    // if(smc_file_size > 0x1E00)
    // [150] if(smc_file_size#0>$1e00) goto main::@28 -- vwum1_gt_vwuc1_then_la1 
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b28+
    jmp __b28
  !__b28:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b28+
    jmp __b28
  !__b28:
  !:
    // main::@26
    // smc_file_release = smc_file_header[0]
    // [151] smc_file_release#0 = *smc_file_header -- vbum1=_deref_pbuc1 
    // SF4 | SMC.BIN and all ok | Display the SMC.BIN file version and set SMC to Flash. | Flash
    // The first 3 bytes of the smc file header is the version of the SMC file.
    lda smc_file_header
    sta smc_file_release
    // smc_file_major = smc_file_header[1]
    // [152] smc_file_major#0 = *(smc_file_header+1) -- vbum1=_deref_pbuc1 
    lda smc_file_header+1
    sta smc_file_major
    // smc_file_minor = smc_file_header[2]
    // [153] smc_file_minor#0 = *(smc_file_header+2) -- vbum1=_deref_pbuc1 
    lda smc_file_header+2
    sta smc_file_minor
    // smc_get_version_text(smc_file_version_text, smc_file_release, smc_file_major, smc_file_minor)
    // [154] smc_get_version_text::release#1 = smc_file_release#0 -- vbum1=vbum2 
    lda smc_file_release
    sta smc_get_version_text.release
    // [155] smc_get_version_text::major#1 = smc_file_major#0 -- vbum1=vbum2 
    lda smc_file_major
    sta smc_get_version_text.major
    // [156] smc_get_version_text::minor#1 = smc_file_minor#0 -- vbum1=vbum2 
    lda smc_file_minor
    sta smc_get_version_text.minor
    // [157] call smc_get_version_text
    // [1078] phi from main::@26 to smc_get_version_text [phi:main::@26->smc_get_version_text]
    // [1078] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#1 [phi:main::@26->smc_get_version_text#0] -- register_copy 
    // [1078] phi smc_get_version_text::major#2 = smc_get_version_text::major#1 [phi:main::@26->smc_get_version_text#1] -- register_copy 
    // [1078] phi smc_get_version_text::release#2 = smc_get_version_text::release#1 [phi:main::@26->smc_get_version_text#2] -- register_copy 
    // [1078] phi smc_get_version_text::version_string#2 = main::smc_file_version_text [phi:main::@26->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_file_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [158] phi from main::@26 to main::@132 [phi:main::@26->main::@132]
    // main::@132
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [159] call snprintf_init
    // [1204] phi from main::@132 to snprintf_init [phi:main::@132->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@132->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [160] phi from main::@132 to main::@133 [phi:main::@132->main::@133]
    // main::@133
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [161] call printf_str
    // [1209] phi from main::@133 to printf_str [phi:main::@133->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@133->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s4 [phi:main::@133->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [162] phi from main::@133 to main::@134 [phi:main::@133->main::@134]
    // main::@134
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [163] call printf_string
    // [1218] phi from main::@134 to printf_string [phi:main::@134->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:main::@134->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = main::smc_file_version_text [phi:main::@134->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z printf_string.str
    lda #>smc_file_version_text
    sta.z printf_string.str+1
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:main::@134->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:main::@134->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@135
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [164] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [165] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [167] smc_bootloader#510 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, info_text)
    // [168] call display_info_smc
  // All ok, display file version.
    // [961] phi from main::@135 to display_info_smc [phi:main::@135->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = info_text [phi:main::@135->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#510 [phi:main::@135->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_FLASH [phi:main::@135->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [169] phi from main::@135 to main::CLI2 [phi:main::@135->main::CLI2]
    // [169] phi smc_file_minor#301 = smc_file_minor#0 [phi:main::@135->main::CLI2#0] -- register_copy 
    // [169] phi smc_file_major#301 = smc_file_major#0 [phi:main::@135->main::CLI2#1] -- register_copy 
    // [169] phi smc_file_release#301 = smc_file_release#0 [phi:main::@135->main::CLI2#2] -- register_copy 
    // [169] phi __stdio_filecount#109 = __stdio_filecount#39 [phi:main::@135->main::CLI2#3] -- register_copy 
    // [169] phi __errno#113 = __errno#123 [phi:main::@135->main::CLI2#4] -- register_copy 
    jmp CLI2
    // [169] phi from main::@69 to main::CLI2 [phi:main::@69->main::CLI2]
  __b7:
    // [169] phi smc_file_minor#301 = 0 [phi:main::@69->main::CLI2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [169] phi smc_file_major#301 = 0 [phi:main::@69->main::CLI2#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [169] phi smc_file_release#301 = 0 [phi:main::@69->main::CLI2#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [169] phi __stdio_filecount#109 = 0 [phi:main::@69->main::CLI2#3] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [169] phi __errno#113 = 0 [phi:main::@69->main::CLI2#4] -- vwsm1=vwsc1 
    sta __errno
    sta __errno+1
    // main::CLI2
  CLI2:
    // asm
    // asm { cli  }
    cli
    // main::bank_set_brom3
    // BROM = bank
    // [171] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // [173] phi from main::CLI3 to main::@71 [phi:main::CLI3->main::@71]
    // main::@71
    // display_progress_clear()
    // [174] call display_progress_clear
    // [917] phi from main::@71 to display_progress_clear [phi:main::@71->display_progress_clear]
    jsr display_progress_clear
    // [175] phi from main::@71 to main::@129 [phi:main::@71->main::@129]
    // main::@129
    // main_vera_check()
    // [176] call main_vera_check
    // [1243] phi from main::@129 to main_vera_check [phi:main::@129->main_vera_check]
    jsr main_vera_check
    // main::bank_set_brom4
    // BROM = bank
    // [177] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::SEI3
    // asm { sei  }
    sei
    // [180] phi from main::SEI3 to main::@29 [phi:main::SEI3->main::@29]
    // [180] phi __stdio_filecount#111 = __stdio_filecount#36 [phi:main::SEI3->main::@29#0] -- register_copy 
    // [180] phi __errno#115 = __errno#123 [phi:main::SEI3->main::@29#1] -- register_copy 
    // [180] phi main::rom_chip2#10 = 0 [phi:main::SEI3->main::@29#2] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip2
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@29
  __b29:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [181] if(main::rom_chip2#10<8) goto main::bank_set_brom5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip2
    cmp #8
    bcs !bank_set_brom5+
    jmp bank_set_brom5
  !bank_set_brom5:
    // main::bank_set_brom6
    // BROM = bank
    // [182] BROM = main::bank_set_brom6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom6_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc2
    // status_smc == status
    // [184] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [185] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0 -- vbum1=vbum2 
    sta check_status_smc2_return
    // [186] phi from main::check_status_smc2 to main::check_status_cx16_rom1 [phi:main::check_status_smc2->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [187] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [188] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom1_check_status_rom1_return
    // main::@73
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [189] if(0!=main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc2_return
    bne check_status_smc3
    // main::@246
    // [190] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@36 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom1_check_status_rom1_return
    beq !__b36+
    jmp __b36
  !__b36:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [191] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [192] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0 -- vbum1=vbum2 
    sta check_status_smc3_return
    // [193] phi from main::check_status_smc3 to main::check_status_cx16_rom2 [phi:main::check_status_smc3->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [194] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_NONE -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [195] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom2_check_status_rom1_return
    // main::@76
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [196] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbum1_then_la1 
    // VA3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
    lda check_status_smc3_return
    beq check_status_smc4
    // main::@247
    // [197] if(0!=main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@3 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom2_check_status_rom1_return
    beq !__b3+
    jmp __b3
  !__b3:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [198] main::check_status_smc4_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [199] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0 -- vbum1=vbum2 
    sta check_status_smc4_return
    // [200] phi from main::check_status_smc4 to main::check_status_cx16_rom3 [phi:main::check_status_smc4->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [201] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [202] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom3_check_status_rom1_return
    // main::@77
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [203] if(0==main::check_status_smc4_return#0) goto main::check_status_smc5 -- 0_eq_vbum1_then_la1 
    lda check_status_smc4_return
    beq check_status_smc5
    // main::@248
    // [204] if(0==main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@5 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom3_check_status_rom1_return
    bne !__b5+
    jmp __b5
  !__b5:
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [205] main::check_status_smc5_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [206] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0 -- vbum1=vbum2 
    sta check_status_smc5_return
    // [207] phi from main::check_status_smc5 to main::check_status_cx16_rom4 [phi:main::check_status_smc5->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [208] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [209] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom4_check_status_rom1_return
    // main::@78
    // smc_supported_rom(rom_release[0])
    // [210] smc_supported_rom::rom_release#0 = *rom_release -- vbum1=_deref_pbuc1 
    lda rom_release
    sta smc_supported_rom.rom_release
    // [211] call smc_supported_rom
    // [1270] phi from main::@78 to smc_supported_rom [phi:main::@78->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_release[0])
    // [212] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@170
    // [213] main::$45 = smc_supported_rom::return#3 -- vbum1=vbum2 
    lda smc_supported_rom.return
    sta main__45
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_release[0]))
    // [214] if(0==main::check_status_smc5_return#0) goto main::check_status_smc6 -- 0_eq_vbum1_then_la1 
    lda check_status_smc5_return
    beq check_status_smc6
    // main::@250
    // [215] if(0==main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::check_status_smc6 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom4_check_status_rom1_return
    beq check_status_smc6
    // main::@249
    // [216] if(0==main::$45) goto main::@6 -- 0_eq_vbum1_then_la1 
    lda main__45
    bne !__b6+
    jmp __b6
  !__b6:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [217] main::check_status_smc6_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [218] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0 -- vbum1=vbum2 
    sta check_status_smc6_return
    // main::@79
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [219] if(0==main::check_status_smc6_return#0) goto main::check_status_smc7 -- 0_eq_vbum1_then_la1 
    beq check_status_smc7
    // main::@253
    // [220] if(smc_release#405==smc_file_release#301) goto main::@252 -- vbum1_eq_vbum2_then_la1 
    lda smc_release
    cmp smc_file_release
    bne !__b252+
    jmp __b252
  !__b252:
    // main::check_status_smc7
  check_status_smc7:
    // status_smc == status
    // [221] main::check_status_smc7_$0 = status_smc#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [222] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0 -- vbum1=vbum2 
    sta check_status_smc7_return
    // main::check_status_vera1
    // status_vera == status
    // [223] main::check_status_vera1_$0 = status_vera#127 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [224] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0 -- vbum1=vbum2 
    sta check_status_vera1_return
    // [225] phi from main::check_status_vera1 to main::@80 [phi:main::check_status_vera1->main::@80]
    // main::@80
    // check_status_roms(STATUS_ISSUE)
    // [226] call check_status_roms
    // [1277] phi from main::@80 to check_status_roms [phi:main::@80->check_status_roms]
    // [1277] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@80->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [227] check_status_roms::return#3 = check_status_roms::return#2
    // main::@175
    // [228] main::$62 = check_status_roms::return#3 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__62
    // main::check_status_smc8
    // status_smc == status
    // [229] main::check_status_smc8_$0 = status_smc#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [230] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0 -- vbum1=vbum2 
    sta check_status_smc8_return
    // main::check_status_vera2
    // status_vera == status
    // [231] main::check_status_vera2_$0 = status_vera#127 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [232] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0 -- vbum1=vbum2 
    sta check_status_vera2_return
    // [233] phi from main::check_status_vera2 to main::@81 [phi:main::check_status_vera2->main::@81]
    // main::@81
    // check_status_roms(STATUS_ERROR)
    // [234] call check_status_roms
    // [1277] phi from main::@81 to check_status_roms [phi:main::@81->check_status_roms]
    // [1277] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@81->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [235] check_status_roms::return#4 = check_status_roms::return#2
    // main::@176
    // [236] main::$71 = check_status_roms::return#4 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__71
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [237] if(0!=main::check_status_smc7_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc7_return
    bne check_status_vera3
    // main::@258
    // [238] if(0==main::check_status_vera1_return#0) goto main::@257 -- 0_eq_vbum1_then_la1 
    lda check_status_vera1_return
    bne !__b257+
    jmp __b257
  !__b257:
    // main::check_status_vera3
  check_status_vera3:
    // status_vera == status
    // [239] main::check_status_vera3_$0 = status_vera#127 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [240] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0 -- vbum1=vbum2 
    sta check_status_vera3_return
    // main::@82
    // if(check_status_vera(STATUS_ERROR))
    // [241] if(0==main::check_status_vera3_return#0) goto main::check_status_smc13 -- 0_eq_vbum1_then_la1 
    bne !check_status_smc13+
    jmp check_status_smc13
  !check_status_smc13:
    // main::bank_set_brom10
    // BROM = bank
    // [242] BROM = main::bank_set_brom10_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom10_bank
    sta.z BROM
    // main::CLI6
    // asm
    // asm { cli  }
    cli
    // main::vera_display_set_border_color1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [244] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [245] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [246] phi from main::vera_display_set_border_color1 to main::@91 [phi:main::vera_display_set_border_color1->main::@91]
    // main::@91
    // textcolor(WHITE)
    // [247] call textcolor
    // [783] phi from main::@91 to textcolor [phi:main::@91->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:main::@91->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [248] phi from main::@91 to main::@213 [phi:main::@91->main::@213]
    // main::@213
    // bgcolor(BLUE)
    // [249] call bgcolor
    // [788] phi from main::@213 to bgcolor [phi:main::@213->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:main::@213->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [250] phi from main::@213 to main::@214 [phi:main::@213->main::@214]
    // main::@214
    // clrscr()
    // [251] call clrscr
    jsr clrscr
    // [252] phi from main::@214 to main::@215 [phi:main::@214->main::@215]
    // main::@215
    // printf("There was a severe error updating your VERA!")
    // [253] call printf_str
    // [1209] phi from main::@215 to printf_str [phi:main::@215->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:main::@215->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s15 [phi:main::@215->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // [254] phi from main::@215 to main::@216 [phi:main::@215->main::@216]
    // main::@216
    // printf("You are back at the READY prompt without resetting your CX16.\n\n")
    // [255] call printf_str
    // [1209] phi from main::@216 to printf_str [phi:main::@216->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:main::@216->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s16 [phi:main::@216->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // [256] phi from main::@216 to main::@217 [phi:main::@216->main::@217]
    // main::@217
    // printf("Please don't reset or shut down your VERA until you've\n")
    // [257] call printf_str
    // [1209] phi from main::@217 to printf_str [phi:main::@217->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:main::@217->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s17 [phi:main::@217->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // [258] phi from main::@217 to main::@218 [phi:main::@217->main::@218]
    // main::@218
    // printf("managed to either reflash your VERA with the previous firmware ")
    // [259] call printf_str
    // [1209] phi from main::@218 to printf_str [phi:main::@218->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:main::@218->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s18 [phi:main::@218->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // [260] phi from main::@218 to main::@219 [phi:main::@218->main::@219]
    // main::@219
    // printf("or have update successs retrying!\n\n")
    // [261] call printf_str
    // [1209] phi from main::@219 to printf_str [phi:main::@219->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:main::@219->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s19 [phi:main::@219->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // [262] phi from main::@219 to main::@220 [phi:main::@219->main::@220]
    // main::@220
    // printf("PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n")
    // [263] call printf_str
    // [1209] phi from main::@220 to printf_str [phi:main::@220->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:main::@220->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s20 [phi:main::@220->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // [264] phi from main::@220 to main::@221 [phi:main::@220->main::@221]
    // main::@221
    // wait_moment(32)
    // [265] call wait_moment
    // [1309] phi from main::@221 to wait_moment [phi:main::@221->wait_moment]
    // [1309] phi wait_moment::w#13 = $20 [phi:main::@221->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [266] phi from main::@221 to main::@222 [phi:main::@221->main::@222]
    // main::@222
    // system_reset()
    // [267] call system_reset
    // [1317] phi from main::@222 to system_reset [phi:main::@222->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [268] return 
    rts
    // main::check_status_smc13
  check_status_smc13:
    // status_smc == status
    // [269] main::check_status_smc13_$0 = status_smc#0 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc13_main__0
    // return (unsigned char)(status_smc == status);
    // [270] main::check_status_smc13_return#0 = (char)main::check_status_smc13_$0 -- vbum1=vbum2 
    sta check_status_smc13_return
    // main::check_status_smc14
    // status_smc == status
    // [271] main::check_status_smc14_$0 = status_smc#0 == STATUS_NONE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc14_main__0
    // return (unsigned char)(status_smc == status);
    // [272] main::check_status_smc14_return#0 = (char)main::check_status_smc14_$0 -- vbum1=vbum2 
    sta check_status_smc14_return
    // main::check_status_vera6
    // status_vera == status
    // [273] main::check_status_vera6_$0 = status_vera#127 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera6_main__0
    // return (unsigned char)(status_vera == status);
    // [274] main::check_status_vera6_return#0 = (char)main::check_status_vera6_$0 -- vbum1=vbum2 
    sta check_status_vera6_return
    // main::check_status_vera7
    // status_vera == status
    // [275] main::check_status_vera7_$0 = status_vera#127 == STATUS_NONE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera7_main__0
    // return (unsigned char)(status_vera == status);
    // [276] main::check_status_vera7_return#0 = (char)main::check_status_vera7_$0 -- vbum1=vbum2 
    sta check_status_vera7_return
    // [277] phi from main::check_status_vera7 to main::@90 [phi:main::check_status_vera7->main::@90]
    // main::@90
    // check_status_roms_less(STATUS_SKIP)
    // [278] call check_status_roms_less
    // [1322] phi from main::@90 to check_status_roms_less [phi:main::@90->check_status_roms_less]
    jsr check_status_roms_less
    // check_status_roms_less(STATUS_SKIP)
    // [279] check_status_roms_less::return#3 = check_status_roms_less::return#2
    // main::@212
    // [280] main::$84 = check_status_roms_less::return#3 -- vbum1=vbum2 
    lda check_status_roms_less.return
    sta main__84
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        check_status_roms_less(STATUS_SKIP))
    // [281] if(0!=main::check_status_smc13_return#0) goto main::@266 -- 0_neq_vbum1_then_la1 
    lda check_status_smc13_return
    beq !__b266+
    jmp __b266
  !__b266:
    // main::@267
    // [282] if(0!=main::check_status_smc14_return#0) goto main::@266 -- 0_neq_vbum1_then_la1 
    lda check_status_smc14_return
    beq !__b266+
    jmp __b266
  !__b266:
    // main::check_status_smc15
  check_status_smc15:
    // status_smc == status
    // [283] main::check_status_smc15_$0 = status_smc#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc15_main__0
    // return (unsigned char)(status_smc == status);
    // [284] main::check_status_smc15_return#0 = (char)main::check_status_smc15_$0 -- vbum1=vbum2 
    sta check_status_smc15_return
    // main::check_status_vera8
    // status_vera == status
    // [285] main::check_status_vera8_$0 = status_vera#127 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera8_main__0
    // return (unsigned char)(status_vera == status);
    // [286] main::check_status_vera8_return#0 = (char)main::check_status_vera8_$0 -- vbum1=vbum2 
    sta check_status_vera8_return
    // [287] phi from main::check_status_vera8 to main::@93 [phi:main::check_status_vera8->main::@93]
    // main::@93
    // check_status_roms(STATUS_ERROR)
    // [288] call check_status_roms
    // [1277] phi from main::@93 to check_status_roms [phi:main::@93->check_status_roms]
    // [1277] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@93->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [289] check_status_roms::return#10 = check_status_roms::return#2
    // main::@223
    // [290] main::$275 = check_status_roms::return#10 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__275
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [291] if(0!=main::check_status_smc15_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc15_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@269
    // [292] if(0!=main::check_status_vera8_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera8_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@268
    // [293] if(0!=main::$275) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda main__275
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::check_status_smc16
    // status_smc == status
    // [294] main::check_status_smc16_$0 = status_smc#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc16_main__0
    // return (unsigned char)(status_smc == status);
    // [295] main::check_status_smc16_return#0 = (char)main::check_status_smc16_$0 -- vbum1=vbum2 
    sta check_status_smc16_return
    // main::check_status_vera9
    // status_vera == status
    // [296] main::check_status_vera9_$0 = status_vera#127 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera9_main__0
    // return (unsigned char)(status_vera == status);
    // [297] main::check_status_vera9_return#0 = (char)main::check_status_vera9_$0 -- vbum1=vbum2 
    sta check_status_vera9_return
    // [298] phi from main::check_status_vera9 to main::@95 [phi:main::check_status_vera9->main::@95]
    // main::@95
    // check_status_roms(STATUS_ISSUE)
    // [299] call check_status_roms
    // [1277] phi from main::@95 to check_status_roms [phi:main::@95->check_status_roms]
    // [1277] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@95->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [300] check_status_roms::return#11 = check_status_roms::return#2
    // main::@225
    // [301] main::$280 = check_status_roms::return#11 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__280
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [302] if(0!=main::check_status_smc16_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_smc16_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@271
    // [303] if(0!=main::check_status_vera9_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_vera9_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@270
    // [304] if(0!=main::$280) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda main__280
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::vera_display_set_border_color5
    // *VERA_CTRL &= ~VERA_DCSEL
    // [305] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [306] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [307] phi from main::vera_display_set_border_color5 to main::@97 [phi:main::vera_display_set_border_color5->main::@97]
    // main::@97
    // display_action_progress("Your CX16 update is a success!")
    // [308] call display_action_progress
    // [903] phi from main::@97 to display_action_progress [phi:main::@97->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text37 [phi:main::@97->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text37
    sta.z display_action_progress.info_text
    lda #>info_text37
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc17
    // status_smc == status
    // [309] main::check_status_smc17_$0 = status_smc#0 == STATUS_FLASHED -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc17_main__0
    // return (unsigned char)(status_smc == status);
    // [310] main::check_status_smc17_return#0 = (char)main::check_status_smc17_$0 -- vbum1=vbum2 
    sta check_status_smc17_return
    // main::@98
    // if(check_status_smc(STATUS_FLASHED))
    // [311] if(0!=main::check_status_smc17_return#0) goto main::@56 -- 0_neq_vbum1_then_la1 
    beq !__b56+
    jmp __b56
  !__b56:
    // [312] phi from main::@98 to main::@11 [phi:main::@98->main::@11]
    // main::@11
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [313] call display_progress_text
    // [1331] phi from main::@11 to display_progress_text [phi:main::@11->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_debriefing_text_rom [phi:main::@11->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_debriefing_count_rom [phi:main::@11->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_rom
    sta display_progress_text.lines
    jsr display_progress_text
    // [314] phi from main::@11 main::@92 main::@96 to main::@4 [phi:main::@11/main::@92/main::@96->main::@4]
    // main::@4
  __b4:
    // textcolor(PINK)
    // [315] call textcolor
  // DE6 | Wait until reset
    // [783] phi from main::@4 to textcolor [phi:main::@4->textcolor]
    // [783] phi textcolor::color#23 = PINK [phi:main::@4->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [316] phi from main::@4 to main::@238 [phi:main::@4->main::@238]
    // main::@238
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [317] call display_progress_line
    // [1341] phi from main::@238 to display_progress_line [phi:main::@238->display_progress_line]
    // [1341] phi display_progress_line::text#3 = main::text [phi:main::@238->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1341] phi display_progress_line::line#3 = 2 [phi:main::@238->display_progress_line#1] -- vbum1=vbuc1 
    lda #2
    sta display_progress_line.line
    jsr display_progress_line
    // [318] phi from main::@238 to main::@239 [phi:main::@238->main::@239]
    // main::@239
    // textcolor(WHITE)
    // [319] call textcolor
    // [783] phi from main::@239 to textcolor [phi:main::@239->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:main::@239->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [320] phi from main::@239 to main::@64 [phi:main::@239->main::@64]
    // [320] phi main::w1#2 = $78 [phi:main::@239->main::@64#0] -- vbuz1=vbuc1 
    lda #$78
    sta.z w1
    // main::@64
  __b64:
    // for (unsigned char w=120; w>0; w--)
    // [321] if(main::w1#2>0) goto main::@65 -- vbuz1_gt_0_then_la1 
    lda.z w1
    bne __b65
    // [322] phi from main::@64 to main::@66 [phi:main::@64->main::@66]
    // main::@66
    // system_reset()
    // [323] call system_reset
    // [1317] phi from main::@66 to system_reset [phi:main::@66->system_reset]
    jsr system_reset
    rts
    // [324] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
  __b65:
    // wait_moment(1)
    // [325] call wait_moment
    // [1309] phi from main::@65 to wait_moment [phi:main::@65->wait_moment]
    // [1309] phi wait_moment::w#13 = 1 [phi:main::@65->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [326] phi from main::@65 to main::@240 [phi:main::@65->main::@240]
    // main::@240
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [327] call snprintf_init
    // [1204] phi from main::@240 to snprintf_init [phi:main::@240->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@240->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [328] phi from main::@240 to main::@241 [phi:main::@240->main::@241]
    // main::@241
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [329] call printf_str
    // [1209] phi from main::@241 to printf_str [phi:main::@241->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@241->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s24 [phi:main::@241->printf_str#1] -- pbuz1=pbuc1 
    lda #<s24
    sta.z printf_str.s
    lda #>s24
    sta.z printf_str.s+1
    jsr printf_str
    // main::@242
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [330] printf_uchar::uvalue#17 = main::w1#2 -- vbum1=vbuz2 
    lda.z w1
    sta printf_uchar.uvalue
    // [331] call printf_uchar
    // [1346] phi from main::@242 to printf_uchar [phi:main::@242->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 0 [phi:main::@242->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:main::@242->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:main::@242->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:main::@242->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#17 [phi:main::@242->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [332] phi from main::@242 to main::@243 [phi:main::@242->main::@243]
    // main::@243
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [333] call printf_str
    // [1209] phi from main::@243 to printf_str [phi:main::@243->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@243->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s25 [phi:main::@243->printf_str#1] -- pbuz1=pbuc1 
    lda #<s25
    sta.z printf_str.s
    lda #>s25
    sta.z printf_str.s+1
    jsr printf_str
    // main::@244
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [334] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [335] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [337] call display_action_text
    // [1357] phi from main::@244 to display_action_text [phi:main::@244->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:main::@244->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@245
    // for (unsigned char w=120; w>0; w--)
    // [338] main::w1#1 = -- main::w1#2 -- vbuz1=_dec_vbuz1 
    dec.z w1
    // [320] phi from main::@245 to main::@64 [phi:main::@245->main::@64]
    // [320] phi main::w1#2 = main::w1#1 [phi:main::@245->main::@64#0] -- register_copy 
    jmp __b64
    // main::@56
  __b56:
    // if(smc_bootloader == 1)
    // [339] if(smc_bootloader#0!=1) goto main::@57 -- vwum1_neq_vbuc1_then_la1 
    lda smc_bootloader+1
    bne __b57
    lda smc_bootloader
    cmp #1
    bne __b57
    // [340] phi from main::@56 to main::@62 [phi:main::@56->main::@62]
    // main::@62
    // smc_reset()
    // [341] call smc_reset
    // [1371] phi from main::@62 to smc_reset [phi:main::@62->smc_reset]
    jsr smc_reset
    // [342] phi from main::@56 main::@62 to main::@57 [phi:main::@56/main::@62->main::@57]
    // main::@57
  __b57:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [343] call display_progress_text
    // [1331] phi from main::@57 to display_progress_text [phi:main::@57->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_debriefing_text_smc [phi:main::@57->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_debriefing_count_smc [phi:main::@57->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_smc
    sta display_progress_text.lines
    jsr display_progress_text
    // [344] phi from main::@57 to main::@226 [phi:main::@57->main::@226]
    // main::@226
    // textcolor(PINK)
    // [345] call textcolor
    // [783] phi from main::@226 to textcolor [phi:main::@226->textcolor]
    // [783] phi textcolor::color#23 = PINK [phi:main::@226->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [346] phi from main::@226 to main::@227 [phi:main::@226->main::@227]
    // main::@227
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [347] call display_progress_line
    // [1341] phi from main::@227 to display_progress_line [phi:main::@227->display_progress_line]
    // [1341] phi display_progress_line::text#3 = main::text [phi:main::@227->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1341] phi display_progress_line::line#3 = 2 [phi:main::@227->display_progress_line#1] -- vbum1=vbuc1 
    lda #2
    sta display_progress_line.line
    jsr display_progress_line
    // [348] phi from main::@227 to main::@228 [phi:main::@227->main::@228]
    // main::@228
    // textcolor(WHITE)
    // [349] call textcolor
    // [783] phi from main::@228 to textcolor [phi:main::@228->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:main::@228->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [350] phi from main::@228 to main::@58 [phi:main::@228->main::@58]
    // [350] phi main::w#2 = $78 [phi:main::@228->main::@58#0] -- vbuz1=vbuc1 
    lda #$78
    sta.z w
    // main::@58
  __b58:
    // for (unsigned char w=120; w>0; w--)
    // [351] if(main::w#2>0) goto main::@59 -- vbuz1_gt_0_then_la1 
    lda.z w
    bne __b59
    // [352] phi from main::@58 to main::@60 [phi:main::@58->main::@60]
    // main::@60
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [353] call snprintf_init
    // [1204] phi from main::@60 to snprintf_init [phi:main::@60->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@60->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [354] phi from main::@60 to main::@235 [phi:main::@60->main::@235]
    // main::@235
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [355] call printf_str
    // [1209] phi from main::@235 to printf_str [phi:main::@235->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@235->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s23 [phi:main::@235->printf_str#1] -- pbuz1=pbuc1 
    lda #<s23
    sta.z printf_str.s
    lda #>s23
    sta.z printf_str.s+1
    jsr printf_str
    // main::@236
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [356] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [357] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [359] call display_action_text
    // [1357] phi from main::@236 to display_action_text [phi:main::@236->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:main::@236->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [360] phi from main::@236 to main::@237 [phi:main::@236->main::@237]
    // main::@237
    // smc_reset()
    // [361] call smc_reset
  // DE5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [1371] phi from main::@237 to smc_reset [phi:main::@237->smc_reset]
    jsr smc_reset
    // [362] phi from main::@237 main::@61 to main::@61 [phi:main::@237/main::@61->main::@61]
  __b10:
  // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
    // main::@61
    jmp __b10
    // [363] phi from main::@58 to main::@59 [phi:main::@58->main::@59]
    // main::@59
  __b59:
    // wait_moment(1)
    // [364] call wait_moment
    // [1309] phi from main::@59 to wait_moment [phi:main::@59->wait_moment]
    // [1309] phi wait_moment::w#13 = 1 [phi:main::@59->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [365] phi from main::@59 to main::@229 [phi:main::@59->main::@229]
    // main::@229
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [366] call snprintf_init
    // [1204] phi from main::@229 to snprintf_init [phi:main::@229->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@229->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [367] phi from main::@229 to main::@230 [phi:main::@229->main::@230]
    // main::@230
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [368] call printf_str
    // [1209] phi from main::@230 to printf_str [phi:main::@230->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@230->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s21 [phi:main::@230->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@231
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [369] printf_uchar::uvalue#16 = main::w#2 -- vbum1=vbuz2 
    lda.z w
    sta printf_uchar.uvalue
    // [370] call printf_uchar
    // [1346] phi from main::@231 to printf_uchar [phi:main::@231->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:main::@231->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 3 [phi:main::@231->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:main::@231->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:main::@231->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#16 [phi:main::@231->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [371] phi from main::@231 to main::@232 [phi:main::@231->main::@232]
    // main::@232
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [372] call printf_str
    // [1209] phi from main::@232 to printf_str [phi:main::@232->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@232->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s22 [phi:main::@232->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@233
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [373] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [374] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [376] call display_action_text
    // [1357] phi from main::@233 to display_action_text [phi:main::@233->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:main::@233->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@234
    // for (unsigned char w=120; w>0; w--)
    // [377] main::w#1 = -- main::w#2 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [350] phi from main::@234 to main::@58 [phi:main::@234->main::@58]
    // [350] phi main::w#2 = main::w#1 [phi:main::@234->main::@58#0] -- register_copy 
    jmp __b58
    // main::vera_display_set_border_color4
  vera_display_set_border_color4:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [378] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [379] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [380] phi from main::vera_display_set_border_color4 to main::@96 [phi:main::vera_display_set_border_color4->main::@96]
    // main::@96
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [381] call display_action_progress
    // [903] phi from main::@96 to display_action_progress [phi:main::@96->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text36 [phi:main::@96->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text36
    sta.z display_action_progress.info_text
    lda #>info_text36
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b4
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [382] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [383] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [384] phi from main::vera_display_set_border_color3 to main::@94 [phi:main::vera_display_set_border_color3->main::@94]
    // main::@94
    // display_action_progress("Update Failure! Your CX16 may no longer boot!")
    // [385] call display_action_progress
    // [903] phi from main::@94 to display_action_progress [phi:main::@94->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text34 [phi:main::@94->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text34
    sta.z display_action_progress.info_text
    lda #>info_text34
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [386] phi from main::@94 to main::@224 [phi:main::@94->main::@224]
    // main::@224
    // display_action_text("Take a photo of this screen, shut down power and retry!")
    // [387] call display_action_text
    // [1357] phi from main::@224 to display_action_text [phi:main::@224->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main::info_text35 [phi:main::@224->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text35
    sta.z display_action_text.info_text
    lda #>info_text35
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [388] phi from main::@224 main::@63 to main::@63 [phi:main::@224/main::@63->main::@63]
    // main::@63
  __b63:
    jmp __b63
    // main::@266
  __b266:
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        check_status_roms_less(STATUS_SKIP))
    // [389] if(0!=main::check_status_vera6_return#0) goto main::@265 -- 0_neq_vbum1_then_la1 
    lda check_status_vera6_return
    bne __b265
    // main::@273
    // [390] if(0==main::check_status_vera7_return#0) goto main::check_status_smc15 -- 0_eq_vbum1_then_la1 
    lda check_status_vera7_return
    bne !check_status_smc15+
    jmp check_status_smc15
  !check_status_smc15:
    // main::@265
  __b265:
    // [391] if(0!=main::$84) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda main__84
    bne vera_display_set_border_color2
    jmp check_status_smc15
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [392] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [393] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [394] phi from main::vera_display_set_border_color2 to main::@92 [phi:main::vera_display_set_border_color2->main::@92]
    // main::@92
    // display_action_progress("No CX16 component has been updated with new firmware!")
    // [395] call display_action_progress
    // [903] phi from main::@92 to display_action_progress [phi:main::@92->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text33 [phi:main::@92->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text33
    sta.z display_action_progress.info_text
    lda #>info_text33
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b4
    // main::@257
  __b257:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [396] if(0!=main::$62) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda main__62
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@256
    // [397] if(0==main::check_status_smc8_return#0) goto main::@255 -- 0_eq_vbum1_then_la1 
    lda check_status_smc8_return
    beq __b255
    jmp check_status_vera3
    // main::@255
  __b255:
    // [398] if(0!=main::check_status_vera2_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera2_return
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@254
    // [399] if(0==main::$71) goto main::check_status_vera4 -- 0_eq_vbum1_then_la1 
    lda main__71
    beq check_status_vera4
    jmp check_status_vera3
    // main::check_status_vera4
  check_status_vera4:
    // status_vera == status
    // [400] main::check_status_vera4_$0 = status_vera#127 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera4_main__0
    // return (unsigned char)(status_vera == status);
    // [401] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0 -- vbum1=vbum2 
    sta check_status_vera4_return
    // main::check_status_smc9
    // status_smc == status
    // [402] main::check_status_smc9_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [403] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0 -- vbum1=vbum2 
    sta check_status_smc9_return
    // [404] phi from main::check_status_smc9 to main::check_status_cx16_rom5 [phi:main::check_status_smc9->main::check_status_cx16_rom5]
    // main::check_status_cx16_rom5
    // main::check_status_cx16_rom5_check_status_rom1
    // status_rom[rom_chip] == status
    // [405] main::check_status_cx16_rom5_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom5_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [406] main::check_status_cx16_rom5_check_status_rom1_return#0 = (char)main::check_status_cx16_rom5_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom5_check_status_rom1_return
    // [407] phi from main::check_status_cx16_rom5_check_status_rom1 to main::@83 [phi:main::check_status_cx16_rom5_check_status_rom1->main::@83]
    // main::@83
    // check_status_card_roms(STATUS_FLASH)
    // [408] call check_status_card_roms
    // [1380] phi from main::@83 to check_status_card_roms [phi:main::@83->check_status_card_roms]
    jsr check_status_card_roms
    // check_status_card_roms(STATUS_FLASH)
    // [409] check_status_card_roms::return#3 = check_status_card_roms::return#2
    // main::@179
    // [410] main::$187 = check_status_card_roms::return#3 -- vbum1=vbum2 
    lda check_status_card_roms.return
    sta main__187
    // if(check_status_vera(STATUS_FLASH) || check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [411] if(0!=main::check_status_vera4_return#0) goto main::@9 -- 0_neq_vbum1_then_la1 
    lda check_status_vera4_return
    beq !__b9+
    jmp __b9
  !__b9:
    // main::@261
    // [412] if(0!=main::check_status_smc9_return#0) goto main::@9 -- 0_neq_vbum1_then_la1 
    lda check_status_smc9_return
    beq !__b9+
    jmp __b9
  !__b9:
    // main::@260
    // [413] if(0!=main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::@9 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom5_check_status_rom1_return
    beq !__b9+
    jmp __b9
  !__b9:
    // main::@259
    // [414] if(0!=main::$187) goto main::@9 -- 0_neq_vbum1_then_la1 
    lda main__187
    beq !__b9+
    jmp __b9
  !__b9:
    // main::bank_set_bram1
  bank_set_bram1:
    // BRAM = bank
    // [415] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::SEI4
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom7
    // BROM = bank
    // [417] BROM = main::bank_set_brom7_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom7_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // main::check_status_vera5
    // status_vera == status
    // [419] main::check_status_vera5_$0 = status_vera#127 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera5_main__0
    // return (unsigned char)(status_vera == status);
    // [420] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0 -- vbum1=vbum2 
    sta check_status_vera5_return
    // main::@84
    // if(check_status_vera(STATUS_FLASH))
    // [421] if(0==main::check_status_vera5_return#0) goto main::SEI5 -- 0_eq_vbum1_then_la1 
    beq SEI5
    // [422] phi from main::@84 to main::@51 [phi:main::@84->main::@51]
    // main::@51
    // display_progress_text(display_jp1_spi_vera_text, display_jp1_spi_vera_count)
    // [423] call display_progress_text
    // [1331] phi from main::@51 to display_progress_text [phi:main::@51->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_jp1_spi_vera_text [phi:main::@51->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_jp1_spi_vera_text
    sta.z display_progress_text.text
    lda #>display_jp1_spi_vera_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_jp1_spi_vera_count [phi:main::@51->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_jp1_spi_vera_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [424] phi from main::@51 to main::@185 [phi:main::@51->main::@185]
    // main::@185
    // util_wait_space()
    // [425] call util_wait_space
    // [1389] phi from main::@185 to util_wait_space [phi:main::@185->util_wait_space]
    jsr util_wait_space
    // [426] phi from main::@185 to main::@186 [phi:main::@185->main::@186]
    // main::@186
    // main_vera_flash()
    // [427] call main_vera_flash
    // [1392] phi from main::@186 to main_vera_flash [phi:main::@186->main_vera_flash]
    jsr main_vera_flash
    // [428] phi from main::@186 main::@84 to main::SEI5 [phi:main::@186/main::@84->main::SEI5]
    // [428] phi __stdio_filecount#113 = __stdio_filecount#36 [phi:main::@186/main::@84->main::SEI5#0] -- register_copy 
    // [428] phi __errno#117 = __errno#123 [phi:main::@186/main::@84->main::SEI5#1] -- register_copy 
    // main::SEI5
  SEI5:
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom8
    // BROM = bank
    // [430] BROM = main::bank_set_brom8_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom8_bank
    sta.z BROM
    // [431] phi from main::bank_set_brom8 to main::@85 [phi:main::bank_set_brom8->main::@85]
    // main::@85
    // display_progress_clear()
    // [432] call display_progress_clear
    // [917] phi from main::@85 to display_progress_clear [phi:main::@85->display_progress_clear]
    jsr display_progress_clear
    // main::check_status_smc10
    // status_smc == status
    // [433] main::check_status_smc10_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [434] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0 -- vbum1=vbum2 
    sta check_status_smc10_return
    // [435] phi from main::check_status_smc10 to main::check_status_cx16_rom6 [phi:main::check_status_smc10->main::check_status_cx16_rom6]
    // main::check_status_cx16_rom6
    // main::check_status_cx16_rom6_check_status_rom1
    // status_rom[rom_chip] == status
    // [436] main::check_status_cx16_rom6_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom6_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [437] main::check_status_cx16_rom6_check_status_rom1_return#0 = (char)main::check_status_cx16_rom6_check_status_rom1_$0 -- vbum1=vbum2 
    sta check_status_cx16_rom6_check_status_rom1_return
    // main::@86
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [438] if(0==main::check_status_smc10_return#0) goto main::SEI6 -- 0_eq_vbum1_then_la1 
    lda check_status_smc10_return
    beq SEI6
    // main::@262
    // [439] if(0!=main::check_status_cx16_rom6_check_status_rom1_return#0) goto main::@52 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom6_check_status_rom1_return
    beq !__b52+
    jmp __b52
  !__b52:
    // [440] phi from main::@262 to main::SEI6 [phi:main::@262->main::SEI6]
    // [440] phi from main::@189 main::@40 main::@41 main::@55 main::@86 to main::SEI6 [phi:main::@189/main::@40/main::@41/main::@55/main::@86->main::SEI6]
    // [440] phi __stdio_filecount#577 = __stdio_filecount#39 [phi:main::@189/main::@40/main::@41/main::@55/main::@86->main::SEI6#0] -- register_copy 
    // [440] phi __errno#584 = __errno#123 [phi:main::@189/main::@40/main::@41/main::@55/main::@86->main::SEI6#1] -- register_copy 
    // main::SEI6
  SEI6:
    // asm
    // asm { sei  }
    sei
    // [442] phi from main::SEI6 to main::@42 [phi:main::SEI6->main::@42]
    // [442] phi __stdio_filecount#114 = __stdio_filecount#577 [phi:main::SEI6->main::@42#0] -- register_copy 
    // [442] phi __errno#118 = __errno#584 [phi:main::SEI6->main::@42#1] -- register_copy 
    // [442] phi main::rom_chip4#10 = 7 [phi:main::SEI6->main::@42#2] -- vbuz1=vbuc1 
    lda #7
    sta.z rom_chip4
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@42
  __b42:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [443] if(main::rom_chip4#10!=$ff) goto main::check_status_rom1 -- vbuz1_neq_vbuc1_then_la1 
    lda #$ff
    cmp.z rom_chip4
    bne check_status_rom1
    // [444] phi from main::@42 to main::@43 [phi:main::@42->main::@43]
    // main::@43
    // display_progress_clear()
    // [445] call display_progress_clear
    // [917] phi from main::@43 to display_progress_clear [phi:main::@43->display_progress_clear]
    jsr display_progress_clear
    jmp check_status_vera3
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [446] main::check_status_rom1_$0 = status_rom[main::rom_chip4#10] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy.z rom_chip4
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [447] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // main::@87
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [448] if(0==main::check_status_rom1_return#0) goto main::@44 -- 0_eq_vbum1_then_la1 
    beq __b44
    // main::check_status_smc11
    // status_smc == status
    // [449] main::check_status_smc11_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc11_main__0
    // return (unsigned char)(status_smc == status);
    // [450] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0 -- vbum1=vbuz2 
    sta check_status_smc11_return
    // main::check_status_smc12
    // status_smc == status
    // [451] main::check_status_smc12_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc12_main__0
    // return (unsigned char)(status_smc == status);
    // [452] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0 -- vbum1=vbuz2 
    sta check_status_smc12_return
    // main::@88
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [453] if(main::rom_chip4#10==0) goto main::@264 -- vbuz1_eq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda.z rom_chip4
    bne !__b264+
    jmp __b264
  !__b264:
    // main::@263
  __b263:
    // [454] if(main::rom_chip4#10!=0) goto main::bank_set_brom9 -- vbuz1_neq_0_then_la1 
    lda.z rom_chip4
    bne bank_set_brom9
    // main::@50
    // display_info_rom(rom_chip, STATUS_ISSUE, "SMC Update failed!")
    // [455] display_info_rom::rom_chip#11 = main::rom_chip4#10 -- vbum1=vbuz2 
    sta display_info_rom.rom_chip
    // [456] call display_info_rom
    // [1565] phi from main::@50 to display_info_rom [phi:main::@50->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = main::info_text29 [phi:main::@50->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_info_rom.info_text
    lda #>info_text29
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#11 [phi:main::@50->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:main::@50->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    // [457] phi from main::@200 main::@211 main::@45 main::@49 main::@50 main::@87 to main::@44 [phi:main::@200/main::@211/main::@45/main::@49/main::@50/main::@87->main::@44]
    // [457] phi __stdio_filecount#578 = __stdio_filecount#12 [phi:main::@200/main::@211/main::@45/main::@49/main::@50/main::@87->main::@44#0] -- register_copy 
    // [457] phi __errno#585 = __errno#123 [phi:main::@200/main::@211/main::@45/main::@49/main::@50/main::@87->main::@44#1] -- register_copy 
    // main::@44
  __b44:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [458] main::rom_chip4#1 = -- main::rom_chip4#10 -- vbuz1=_dec_vbuz1 
    dec.z rom_chip4
    // [442] phi from main::@44 to main::@42 [phi:main::@44->main::@42]
    // [442] phi __stdio_filecount#114 = __stdio_filecount#578 [phi:main::@44->main::@42#0] -- register_copy 
    // [442] phi __errno#118 = __errno#585 [phi:main::@44->main::@42#1] -- register_copy 
    // [442] phi main::rom_chip4#10 = main::rom_chip4#1 [phi:main::@44->main::@42#2] -- register_copy 
    jmp __b42
    // main::bank_set_brom9
  bank_set_brom9:
    // BROM = bank
    // [459] BROM = main::bank_set_brom9_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom9_bank
    sta.z BROM
    // [460] phi from main::bank_set_brom9 to main::@89 [phi:main::bank_set_brom9->main::@89]
    // main::@89
    // display_progress_clear()
    // [461] call display_progress_clear
    // [917] phi from main::@89 to display_progress_clear [phi:main::@89->display_progress_clear]
    jsr display_progress_clear
    // main::@193
    // unsigned char rom_bank = rom_chip * 32
    // [462] main::rom_bank1#0 = main::rom_chip4#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z rom_chip4
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [463] rom_file::rom_chip#1 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_file.rom_chip
    // [464] call rom_file
    // [1610] phi from main::@193 to rom_file [phi:main::@193->rom_file]
    // [1610] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@193->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [465] rom_file::return#5 = rom_file::return#2
    // main::@194
    // [466] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [467] call snprintf_init
    // [1204] phi from main::@194 to snprintf_init [phi:main::@194->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@194->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [468] phi from main::@194 to main::@195 [phi:main::@194->main::@195]
    // main::@195
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [469] call printf_str
    // [1209] phi from main::@195 to printf_str [phi:main::@195->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@195->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s11 [phi:main::@195->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@196
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [470] printf_string::str#25 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z printf_string.str
    lda.z file1+1
    sta.z printf_string.str+1
    // [471] call printf_string
    // [1218] phi from main::@196 to printf_string [phi:main::@196->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:main::@196->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#25 [phi:main::@196->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:main::@196->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:main::@196->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [472] phi from main::@196 to main::@197 [phi:main::@196->main::@197]
    // main::@197
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [473] call printf_str
    // [1209] phi from main::@197 to printf_str [phi:main::@197->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@197->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s12 [phi:main::@197->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@198
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [474] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [475] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [477] call display_action_progress
    // [903] phi from main::@198 to display_action_progress [phi:main::@198->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = info_text [phi:main::@198->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@199
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [478] main::$318 = main::rom_chip4#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip4
    asl
    asl
    sta main__318
    // [479] rom_read::file#1 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z rom_read.file
    lda.z file1+1
    sta.z rom_read.file+1
    // [480] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_read.brom_bank_start
    // [481] rom_read::rom_size#1 = rom_sizes[main::$318] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__318
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [482] call rom_read
    // [1616] phi from main::@199 to rom_read [phi:main::@199->rom_read]
    // [1616] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@199->rom_read#0] -- register_copy 
    // [1616] phi __errno#105 = __errno#118 [phi:main::@199->rom_read#1] -- register_copy 
    // [1616] phi __stdio_filecount#100 = __stdio_filecount#114 [phi:main::@199->rom_read#2] -- register_copy 
    // [1616] phi rom_read::file#10 = rom_read::file#1 [phi:main::@199->rom_read#3] -- register_copy 
    // [1616] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#2 [phi:main::@199->rom_read#4] -- register_copy 
    // [1616] phi rom_read::info_status#12 = STATUS_READING [phi:main::@199->rom_read#5] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [483] rom_read::return#3 = rom_read::return#0
    // main::@200
    // [484] main::rom_bytes_read1#0 = rom_read::return#3 -- vduz1=vdum2 
    lda rom_read.return
    sta.z rom_bytes_read1
    lda rom_read.return+1
    sta.z rom_bytes_read1+1
    lda rom_read.return+2
    sta.z rom_bytes_read1+2
    lda rom_read.return+3
    sta.z rom_bytes_read1+3
    // if(rom_bytes_read)
    // [485] if(0==main::rom_bytes_read1#0) goto main::@44 -- 0_eq_vduz1_then_la1 
    lda.z rom_bytes_read1
    ora.z rom_bytes_read1+1
    ora.z rom_bytes_read1+2
    ora.z rom_bytes_read1+3
    bne !__b44+
    jmp __b44
  !__b44:
    // [486] phi from main::@200 to main::@47 [phi:main::@200->main::@47]
    // main::@47
    // display_action_progress("Comparing ... (.) data, (=) same, (*) different.")
    // [487] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [903] phi from main::@47 to display_action_progress [phi:main::@47->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text30 [phi:main::@47->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z display_action_progress.info_text
    lda #>info_text30
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@201
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [488] display_info_rom::rom_chip#12 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [489] call display_info_rom
    // [1565] phi from main::@201 to display_info_rom [phi:main::@201->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = str [phi:main::@201->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_rom.info_text
    lda #>str
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#12 [phi:main::@201->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:main::@201->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@202
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [490] rom_verify::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_verify.rom_chip
    // [491] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_verify.rom_bank_start
    // [492] rom_verify::file_size#0 = file_sizes[main::$318] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__318
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [493] call rom_verify
  // Verify the ROM...
    // [1689] phi from main::@202 to rom_verify [phi:main::@202->rom_verify]
    jsr rom_verify
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [494] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@203
    // [495] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vdum2 
    lda rom_verify.return
    sta.z rom_differences
    lda rom_verify.return+1
    sta.z rom_differences+1
    lda rom_verify.return+2
    sta.z rom_differences+2
    lda rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [496] if(0==main::rom_differences#0) goto main::@45 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b45+
    jmp __b45
  !__b45:
    // [497] phi from main::@203 to main::@48 [phi:main::@203->main::@48]
    // main::@48
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [498] call snprintf_init
    // [1204] phi from main::@48 to snprintf_init [phi:main::@48->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@48->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@204
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [499] printf_ulong::uvalue#13 = main::rom_differences#0 -- vdum1=vduz2 
    lda.z rom_differences
    sta printf_ulong.uvalue
    lda.z rom_differences+1
    sta printf_ulong.uvalue+1
    lda.z rom_differences+2
    sta printf_ulong.uvalue+2
    lda.z rom_differences+3
    sta printf_ulong.uvalue+3
    // [500] call printf_ulong
    // [1753] phi from main::@204 to printf_ulong [phi:main::@204->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:main::@204->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:main::@204->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main::@204->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#13 [phi:main::@204->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [501] phi from main::@204 to main::@205 [phi:main::@204->main::@205]
    // main::@205
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [502] call printf_str
    // [1209] phi from main::@205 to printf_str [phi:main::@205->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@205->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s13 [phi:main::@205->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@206
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [503] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [504] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [506] display_info_rom::rom_chip#14 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [507] call display_info_rom
    // [1565] phi from main::@206 to display_info_rom [phi:main::@206->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = info_text [phi:main::@206->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#14 [phi:main::@206->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@206->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@207
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [508] rom_flash::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_flash.rom_chip
    // [509] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [510] rom_flash::file_size#0 = file_sizes[main::$318] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__318
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [511] call rom_flash
    // [1763] phi from main::@207 to rom_flash [phi:main::@207->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [512] rom_flash::return#2 = rom_flash::flash_errors#12
    // main::@208
    // [513] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [514] if(0!=main::rom_flash_errors#0) goto main::@46 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b46
    // main::@49
    // display_info_rom(rom_chip, STATUS_FLASHED, NULL)
    // [515] display_info_rom::rom_chip#16 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [516] call display_info_rom
  // RFL3 | Flash ROM and all ok
    // [1565] phi from main::@49 to display_info_rom [phi:main::@49->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = 0 [phi:main::@49->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#16 [phi:main::@49->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_FLASHED [phi:main::@49->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // [517] phi from main::@208 to main::@46 [phi:main::@208->main::@46]
    // main::@46
  __b46:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [518] call snprintf_init
    // [1204] phi from main::@46 to snprintf_init [phi:main::@46->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@46->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@209
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [519] printf_ulong::uvalue#14 = main::rom_flash_errors#0 -- vdum1=vdum2 
    lda rom_flash_errors
    sta printf_ulong.uvalue
    lda rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [520] call printf_ulong
    // [1753] phi from main::@209 to printf_ulong [phi:main::@209->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 0 [phi:main::@209->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 0 [phi:main::@209->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = DECIMAL [phi:main::@209->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#14 [phi:main::@209->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [521] phi from main::@209 to main::@210 [phi:main::@209->main::@210]
    // main::@210
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [522] call printf_str
    // [1209] phi from main::@210 to printf_str [phi:main::@210->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@210->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s14 [phi:main::@210->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@211
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [523] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [524] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [526] display_info_rom::rom_chip#15 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [527] call display_info_rom
    // [1565] phi from main::@211 to display_info_rom [phi:main::@211->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = info_text [phi:main::@211->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#15 [phi:main::@211->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:main::@211->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // main::@45
  __b45:
    // display_info_rom(rom_chip, STATUS_SKIP, "No update required")
    // [528] display_info_rom::rom_chip#13 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [529] call display_info_rom
  // RFL1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Flashed. | None
    // [1565] phi from main::@45 to display_info_rom [phi:main::@45->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = info_text6 [phi:main::@45->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text6
    sta.z display_info_rom.info_text
    lda #>@info_text6
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#13 [phi:main::@45->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@45->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // main::@264
  __b264:
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [530] if(0!=main::check_status_smc11_return#0) goto main::bank_set_brom9 -- 0_neq_vbum1_then_la1 
    lda check_status_smc11_return
    beq !bank_set_brom9+
    jmp bank_set_brom9
  !bank_set_brom9:
    // main::@272
    // [531] if(0!=main::check_status_smc12_return#0) goto main::bank_set_brom9 -- 0_neq_vbum1_then_la1 
    lda check_status_smc12_return
    beq !bank_set_brom9+
    jmp bank_set_brom9
  !bank_set_brom9:
    jmp __b263
    // [532] phi from main::@262 to main::@52 [phi:main::@262->main::@52]
    // main::@52
  __b52:
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [533] call display_action_progress
    // [903] phi from main::@52 to display_action_progress [phi:main::@52->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text23 [phi:main::@52->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_action_progress.info_text
    lda #>info_text23
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [534] phi from main::@52 to main::@187 [phi:main::@52->main::@187]
    // main::@187
    // display_progress_clear()
    // [535] call display_progress_clear
    // [917] phi from main::@187 to display_progress_clear [phi:main::@187->display_progress_clear]
    jsr display_progress_clear
    // [536] phi from main::@187 to main::@188 [phi:main::@187->main::@188]
    // main::@188
    // smc_read(STATUS_READING)
    // [537] call smc_read
    // [1154] phi from main::@188 to smc_read [phi:main::@188->smc_read]
    // [1154] phi __errno#102 = __errno#117 [phi:main::@188->smc_read#0] -- register_copy 
    // [1154] phi __stdio_filecount#128 = __stdio_filecount#113 [phi:main::@188->smc_read#1] -- register_copy 
    // [1154] phi smc_read::info_status#10 = STATUS_READING [phi:main::@188->smc_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_READING)
    // [538] smc_read::return#3 = smc_read::return#0
    // main::@189
    // smc_file_size = smc_read(STATUS_READING)
    // [539] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [540] if(0==smc_file_size#1) goto main::SEI6 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !SEI6+
    jmp SEI6
  !SEI6:
    // [541] phi from main::@189 to main::@53 [phi:main::@189->main::@53]
    // main::@53
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [542] call display_action_text
  // Flash the SMC chip.
    // [1357] phi from main::@53 to display_action_text [phi:main::@53->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main::info_text24 [phi:main::@53->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_action_text.info_text
    lda #>info_text24
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@190
    // [543] smc_bootloader#515 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [544] call display_info_smc
    // [961] phi from main::@190 to display_info_smc [phi:main::@190->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text25 [phi:main::@190->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z display_info_smc.info_text
    lda #>info_text25
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#515 [phi:main::@190->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_FLASHING [phi:main::@190->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_smc.info_status
    jsr display_info_smc
    // main::@191
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [545] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta smc_flash.smc_bytes_total+1
    // [546] call smc_flash
    // [1862] phi from main::@191 to smc_flash [phi:main::@191->smc_flash]
    jsr smc_flash
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [547] smc_flash::return#5 = smc_flash::return#1
    // main::@192
    // [548] main::flashed_bytes#0 = smc_flash::return#5 -- vwuz1=vwum2 
    lda smc_flash.return
    sta.z flashed_bytes
    lda smc_flash.return+1
    sta.z flashed_bytes+1
    // if(flashed_bytes)
    // [549] if(0!=main::flashed_bytes#0) goto main::@40 -- 0_neq_vwuz1_then_la1 
    lda.z flashed_bytes
    ora.z flashed_bytes+1
    bne __b40
    // main::@54
    // if(flashed_bytes == (unsigned int)0xFFFF)
    // [550] if(main::flashed_bytes#0==$ffff) goto main::@41 -- vwuz1_eq_vwuc1_then_la1 
    lda.z flashed_bytes
    cmp #<$ffff
    bne !+
    lda.z flashed_bytes+1
    cmp #>$ffff
    beq __b41
  !:
    // main::@55
    // [551] smc_bootloader#521 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "POWER/RESET not pressed!")
    // [552] call display_info_smc
  // SFL2 | no action on POWER/RESET press request
    // [961] phi from main::@55 to display_info_smc [phi:main::@55->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text28 [phi:main::@55->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_info_smc.info_text
    lda #>info_text28
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#521 [phi:main::@55->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@55->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // main::@41
  __b41:
    // [553] smc_bootloader#520 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC has errors!")
    // [554] call display_info_smc
  // SFL3 | errors during flash
    // [961] phi from main::@41 to display_info_smc [phi:main::@41->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text27 [phi:main::@41->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_info_smc.info_text
    lda #>info_text27
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#520 [phi:main::@41->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main::@41->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // main::@40
  __b40:
    // [555] smc_bootloader#519 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHED, "")
    // [556] call display_info_smc
  // SFL1 | and POWER/RESET pressed
    // [961] phi from main::@40 to display_info_smc [phi:main::@40->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = str [phi:main::@40->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_smc.info_text
    lda #>str
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#519 [phi:main::@40->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_FLASHED [phi:main::@40->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // [557] phi from main::@179 main::@259 main::@260 main::@261 to main::@9 [phi:main::@179/main::@259/main::@260/main::@261->main::@9]
    // main::@9
  __b9:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [558] call display_action_progress
    // [903] phi from main::@9 to display_action_progress [phi:main::@9->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text17 [phi:main::@9->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_action_progress.info_text
    lda #>info_text17
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [559] phi from main::@9 to main::@180 [phi:main::@9->main::@180]
    // main::@180
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [560] call util_wait_key
    // [2011] phi from main::@180 to util_wait_key [phi:main::@180->util_wait_key]
    // [2011] phi util_wait_key::filter#13 = main::filter1 [phi:main::@180->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z util_wait_key.filter
    lda #>filter1
    sta.z util_wait_key.filter+1
    // [2011] phi util_wait_key::info_text#3 = main::info_text18 [phi:main::@180->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z util_wait_key.info_text
    lda #>info_text18
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [561] util_wait_key::return#4 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return_1
    // main::@181
    // [562] main::ch1#0 = util_wait_key::return#4 -- vbum1=vbum2 
    sta ch1
    // strchr("nN", ch)
    // [563] strchr::c#1 = main::ch1#0 -- vbum1=vbum2 
    sta strchr.c
    // [564] call strchr
    // [2035] phi from main::@181 to strchr [phi:main::@181->strchr]
    // [2035] phi strchr::c#4 = strchr::c#1 [phi:main::@181->strchr#0] -- register_copy 
    // [2035] phi strchr::str#2 = (const void *)main::$345 [phi:main::@181->strchr#1] -- pvoz1=pvoc1 
    lda #<main__345
    sta.z strchr.str
    lda #>main__345
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [565] strchr::return#4 = strchr::return#2
    // main::@182
    // [566] main::$192 = strchr::return#4
    // if(strchr("nN", ch))
    // [567] if((void *)0==main::$192) goto main::bank_set_bram1 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__192
    cmp #<0
    bne !+
    lda.z main__192+1
    cmp #>0
    bne !bank_set_bram1+
    jmp bank_set_bram1
  !bank_set_bram1:
  !:
    // main::@10
    // [568] smc_bootloader#509 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [569] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [961] phi from main::@10 to display_info_smc [phi:main::@10->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text19 [phi:main::@10->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#509 [phi:main::@10->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@10->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // main::@183
    // [570] spi_manufacturer#586 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [571] spi_memory_type#587 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [572] spi_memory_capacity#588 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [573] call display_info_vera
    // [997] phi from main::@183 to display_info_vera [phi:main::@183->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = main::info_text19 [phi:main::@183->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_vera.info_text
    lda #>info_text19
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#588 [phi:main::@183->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#587 [phi:main::@183->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#586 [phi:main::@183->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main::@183->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [574] phi from main::@183 to main::@37 [phi:main::@183->main::@37]
    // [574] phi main::rom_chip3#2 = 0 [phi:main::@183->main::@37#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip3
    // main::@37
  __b37:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [575] if(main::rom_chip3#2<8) goto main::@38 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip3
    cmp #8
    bcc __b38
    // [576] phi from main::@37 to main::@39 [phi:main::@37->main::@39]
    // main::@39
    // display_action_text("You have selected not to cancel the update ... ")
    // [577] call display_action_text
    // [1357] phi from main::@39 to display_action_text [phi:main::@39->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main::info_text22 [phi:main::@39->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_text.info_text
    lda #>info_text22
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_bram1
    // main::@38
  __b38:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [578] display_info_rom::rom_chip#10 = main::rom_chip3#2 -- vbum1=vbuz2 
    lda.z rom_chip3
    sta display_info_rom.rom_chip
    // [579] call display_info_rom
    // [1565] phi from main::@38 to display_info_rom [phi:main::@38->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = main::info_text19 [phi:main::@38->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_rom.info_text
    lda #>info_text19
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#10 [phi:main::@38->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@38->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@184
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [580] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip3
    // [574] phi from main::@184 to main::@37 [phi:main::@184->main::@37]
    // [574] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@184->main::@37#0] -- register_copy 
    jmp __b37
    // main::@252
  __b252:
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [581] if(smc_major#404!=smc_file_major#301) goto main::check_status_smc7 -- vbum1_neq_vbum2_then_la1 
    lda smc_major
    cmp smc_file_major
    beq !check_status_smc7+
    jmp check_status_smc7
  !check_status_smc7:
    // main::@251
    // [582] if(smc_minor#403==smc_file_minor#301) goto main::@8 -- vbum1_eq_vbum2_then_la1 
    lda smc_minor
    cmp smc_file_minor
    beq __b8
    jmp check_status_smc7
    // [583] phi from main::@251 to main::@8 [phi:main::@251->main::@8]
    // main::@8
  __b8:
    // display_action_progress("The SMC chip and SMC.BIN versions are equal, no flash required!")
    // [584] call display_action_progress
    // [903] phi from main::@8 to display_action_progress [phi:main::@8->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text15 [phi:main::@8->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_progress.info_text
    lda #>info_text15
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [585] phi from main::@8 to main::@177 [phi:main::@8->main::@177]
    // main::@177
    // util_wait_space()
    // [586] call util_wait_space
    // [1389] phi from main::@177 to util_wait_space [phi:main::@177->util_wait_space]
    jsr util_wait_space
    // main::@178
    // [587] smc_bootloader#514 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "SMC.BIN and SMC equal.")
    // [588] call display_info_smc
    // [961] phi from main::@178 to display_info_smc [phi:main::@178->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text16 [phi:main::@178->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_info_smc.info_text
    lda #>info_text16
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#514 [phi:main::@178->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@178->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_smc7
    // [589] phi from main::@249 to main::@6 [phi:main::@249->main::@6]
    // main::@6
  __b6:
    // display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!")
    // [590] call display_action_progress
    // [903] phi from main::@6 to display_action_progress [phi:main::@6->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text13 [phi:main::@6->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [591] phi from main::@6 to main::@171 [phi:main::@6->main::@171]
    // main::@171
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [592] call display_progress_text
    // [1331] phi from main::@171 to display_progress_text [phi:main::@171->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_smc_unsupported_rom_text [phi:main::@171->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_smc_unsupported_rom_count [phi:main::@171->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [593] phi from main::@171 to main::@172 [phi:main::@171->main::@172]
    // main::@172
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [594] call util_wait_key
    // [2011] phi from main::@172 to util_wait_key [phi:main::@172->util_wait_key]
    // [2011] phi util_wait_key::filter#13 = main::filter [phi:main::@172->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [2011] phi util_wait_key::info_text#3 = main::info_text14 [phi:main::@172->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z util_wait_key.info_text
    lda #>info_text14
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [595] util_wait_key::return#3 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return
    // main::@173
    // [596] main::ch#0 = util_wait_key::return#3 -- vbum1=vbum2 
    sta ch
    // if(ch == 'N')
    // [597] if(main::ch#0!='N') goto main::check_status_smc6 -- vbum1_neq_vbuc1_then_la1 
    lda #'N'
    cmp ch
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@7
    // [598] smc_bootloader#506 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [599] call display_info_smc
  // Cancel flash
    // [961] phi from main::@7 to display_info_smc [phi:main::@7->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = 0 [phi:main::@7->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#506 [phi:main::@7->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@7->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [600] phi from main::@7 to main::@174 [phi:main::@7->main::@174]
    // main::@174
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [601] call display_info_cx16_rom
    // [2044] phi from main::@174 to display_info_cx16_rom [phi:main::@174->display_info_cx16_rom]
    // [2044] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@174->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [2044] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@174->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc6
    // [602] phi from main::@248 to main::@5 [phi:main::@248->main::@5]
    // main::@5
  __b5:
    // display_action_progress("CX16 ROM update issue!")
    // [603] call display_action_progress
    // [903] phi from main::@5 to display_action_progress [phi:main::@5->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text11 [phi:main::@5->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_action_progress.info_text
    lda #>info_text11
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [604] phi from main::@5 to main::@166 [phi:main::@5->main::@166]
    // main::@166
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [605] call display_progress_text
    // [1331] phi from main::@166 to display_progress_text [phi:main::@166->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@166->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@166->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // main::@167
    // [606] smc_bootloader#513 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [607] call display_info_smc
    // [961] phi from main::@167 to display_info_smc [phi:main::@167->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text9 [phi:main::@167->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#513 [phi:main::@167->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@167->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [608] phi from main::@167 to main::@168 [phi:main::@167->main::@168]
    // main::@168
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [609] call display_info_cx16_rom
    // [2044] phi from main::@168 to display_info_cx16_rom [phi:main::@168->display_info_cx16_rom]
    // [2044] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@168->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [2044] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@168->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [610] phi from main::@168 to main::@169 [phi:main::@168->main::@169]
    // main::@169
    // util_wait_space()
    // [611] call util_wait_space
    // [1389] phi from main::@169 to util_wait_space [phi:main::@169->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc5
    // [612] phi from main::@247 to main::@3 [phi:main::@247->main::@3]
    // main::@3
  __b3:
    // display_action_progress("CX16 ROM update issue, ROM not detected!")
    // [613] call display_action_progress
    // [903] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text8 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [614] phi from main::@3 to main::@162 [phi:main::@3->main::@162]
    // main::@162
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [615] call display_progress_text
    // [1331] phi from main::@162 to display_progress_text [phi:main::@162->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@162->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@162->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // main::@163
    // [616] smc_bootloader#512 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [617] call display_info_smc
    // [961] phi from main::@163 to display_info_smc [phi:main::@163->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text9 [phi:main::@163->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#512 [phi:main::@163->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@163->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [618] phi from main::@163 to main::@164 [phi:main::@163->main::@164]
    // main::@164
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [619] call display_info_cx16_rom
    // [2044] phi from main::@164 to display_info_cx16_rom [phi:main::@164->display_info_cx16_rom]
    // [2044] phi display_info_cx16_rom::info_text#4 = main::info_text10 [phi:main::@164->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_cx16_rom.info_text
    lda #>info_text10
    sta.z display_info_cx16_rom.info_text+1
    // [2044] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@164->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [620] phi from main::@164 to main::@165 [phi:main::@164->main::@165]
    // main::@165
    // util_wait_space()
    // [621] call util_wait_space
    // [1389] phi from main::@165 to util_wait_space [phi:main::@165->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc5
    // [622] phi from main::@246 to main::@36 [phi:main::@246->main::@36]
    // main::@36
  __b36:
    // display_action_progress("SMC update issue!")
    // [623] call display_action_progress
    // [903] phi from main::@36 to display_action_progress [phi:main::@36->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main::info_text6 [phi:main::@36->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_action_progress.info_text
    lda #>info_text6
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [624] phi from main::@36 to main::@158 [phi:main::@36->main::@158]
    // main::@158
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [625] call display_progress_text
    // [1331] phi from main::@158 to display_progress_text [phi:main::@158->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@158->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@158->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [626] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [627] call display_info_cx16_rom
    // [2044] phi from main::@159 to display_info_cx16_rom [phi:main::@159->display_info_cx16_rom]
    // [2044] phi display_info_cx16_rom::info_text#4 = main::info_text7 [phi:main::@159->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_info_cx16_rom.info_text
    lda #>info_text7
    sta.z display_info_cx16_rom.info_text+1
    // [2044] phi display_info_cx16_rom::info_status#4 = STATUS_SKIP [phi:main::@159->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // main::@160
    // [628] smc_bootloader#511 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [629] call display_info_smc
    // [961] phi from main::@160 to display_info_smc [phi:main::@160->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = 0 [phi:main::@160->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#511 [phi:main::@160->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@160->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [630] phi from main::@160 to main::@161 [phi:main::@160->main::@161]
    // main::@161
    // util_wait_space()
    // [631] call util_wait_space
    // [1389] phi from main::@161 to util_wait_space [phi:main::@161->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [632] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::@72
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [633] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@30 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b30+
    jmp __b30
  !__b30:
    // [634] phi from main::@72 to main::@33 [phi:main::@72->main::@33]
    // main::@33
    // display_progress_clear()
    // [635] call display_progress_clear
    // [917] phi from main::@33 to display_progress_clear [phi:main::@33->display_progress_clear]
    jsr display_progress_clear
    // main::@136
    // unsigned char rom_bank = rom_chip * 32
    // [636] main::rom_bank#0 = main::rom_chip2#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [637] rom_file::rom_chip#0 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta rom_file.rom_chip
    // [638] call rom_file
    // [1610] phi from main::@136 to rom_file [phi:main::@136->rom_file]
    // [1610] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@136->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [639] rom_file::return#4 = rom_file::return#2
    // main::@137
    // [640] main::file#0 = rom_file::return#4 -- pbum1=pbuz2 
    lda.z rom_file.return
    sta file
    lda.z rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ...", file)
    // [641] call snprintf_init
    // [1204] phi from main::@137 to snprintf_init [phi:main::@137->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@137->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [642] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(info_text, "Checking %s ...", file)
    // [643] call printf_str
    // [1209] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s5 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(info_text, "Checking %s ...", file)
    // [644] printf_string::str#20 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [645] call printf_string
    // [1218] phi from main::@139 to printf_string [phi:main::@139->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:main::@139->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#20 [phi:main::@139->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:main::@139->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:main::@139->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [646] phi from main::@139 to main::@140 [phi:main::@139->main::@140]
    // main::@140
    // sprintf(info_text, "Checking %s ...", file)
    // [647] call printf_str
    // [1209] phi from main::@140 to printf_str [phi:main::@140->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@140->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s6 [phi:main::@140->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@141
    // sprintf(info_text, "Checking %s ...", file)
    // [648] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [649] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [651] call display_action_progress
    // [903] phi from main::@141 to display_action_progress [phi:main::@141->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = info_text [phi:main::@141->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@142
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [652] main::$316 = main::rom_chip2#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip2
    asl
    asl
    sta main__316
    // [653] rom_read::file#0 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z rom_read.file
    lda file+1
    sta.z rom_read.file+1
    // [654] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbum1=vbum2 
    lda rom_bank
    sta rom_read.brom_bank_start
    // [655] rom_read::rom_size#0 = rom_sizes[main::$316] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__316
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [656] call rom_read
  // Read the ROM(n).BIN file.
    // [1616] phi from main::@142 to rom_read [phi:main::@142->rom_read]
    // [1616] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@142->rom_read#0] -- register_copy 
    // [1616] phi __errno#105 = __errno#115 [phi:main::@142->rom_read#1] -- register_copy 
    // [1616] phi __stdio_filecount#100 = __stdio_filecount#111 [phi:main::@142->rom_read#2] -- register_copy 
    // [1616] phi rom_read::file#10 = rom_read::file#0 [phi:main::@142->rom_read#3] -- register_copy 
    // [1616] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#1 [phi:main::@142->rom_read#4] -- register_copy 
    // [1616] phi rom_read::info_status#12 = STATUS_CHECKING [phi:main::@142->rom_read#5] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [657] rom_read::return#2 = rom_read::return#0
    // main::@143
    // [658] main::rom_bytes_read#0 = rom_read::return#2 -- vduz1=vdum2 
    lda rom_read.return
    sta.z rom_bytes_read
    lda rom_read.return+1
    sta.z rom_bytes_read+1
    lda rom_read.return+2
    sta.z rom_bytes_read+2
    lda rom_read.return+3
    sta.z rom_bytes_read+3
    // if (!rom_bytes_read)
    // [659] if(0==main::rom_bytes_read#0) goto main::@31 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z rom_bytes_read
    ora.z rom_bytes_read+1
    ora.z rom_bytes_read+2
    ora.z rom_bytes_read+3
    bne !__b31+
    jmp __b31
  !__b31:
    // main::@34
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [660] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [661] if(0!=main::rom_file_modulo#0) goto main::@32 -- 0_neq_vduz1_then_la1 
    lda.z rom_file_modulo
    ora.z rom_file_modulo+1
    ora.z rom_file_modulo+2
    ora.z rom_file_modulo+3
    beq !__b32+
    jmp __b32
  !__b32:
    // main::@35
    // file_sizes[rom_chip] = rom_bytes_read
    // [662] file_sizes[main::$316] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vduz2 
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
    // [663] call rom_get_github_commit_id
    // [2049] phi from main::@35 to rom_get_github_commit_id [phi:main::@35->rom_get_github_commit_id]
    // [2049] phi rom_get_github_commit_id::commit_id#6 = main::rom_file_github [phi:main::@35->rom_get_github_commit_id#0] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_file_github
    sta.z rom_get_github_commit_id.commit_id+1
    // [2049] phi rom_get_github_commit_id::from#6 = (char *)$7800 [phi:main::@35->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
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
    // [665] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@74
    // unsigned char rom_file_release = rom_get_release(*((char*)0xBF80))
    // [666] rom_get_release::release#2 = *((char *) 49024) -- vbum1=_deref_pbuc1 
    lda $bf80
    sta rom_get_release.release
    // [667] call rom_get_release
    // [2066] phi from main::@74 to rom_get_release [phi:main::@74->rom_get_release]
    // [2066] phi rom_get_release::release#3 = rom_get_release::release#2 [phi:main::@74->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char rom_file_release = rom_get_release(*((char*)0xBF80))
    // [668] rom_get_release::return#3 = rom_get_release::return#0
    // main::@151
    // [669] main::rom_file_release#0 = rom_get_release::return#3 -- vbum1=vbum2 
    lda rom_get_release.return
    sta rom_file_release
    // unsigned char rom_file_prefix = rom_get_prefix(*((char*)0xBF80))
    // [670] rom_get_prefix::release#1 = *((char *) 49024) -- vbum1=_deref_pbuc1 
    lda $bf80
    sta rom_get_prefix.release
    // [671] call rom_get_prefix
    // [2073] phi from main::@151 to rom_get_prefix [phi:main::@151->rom_get_prefix]
    // [2073] phi rom_get_prefix::release#2 = rom_get_prefix::release#1 [phi:main::@151->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char rom_file_prefix = rom_get_prefix(*((char*)0xBF80))
    // [672] rom_get_prefix::return#3 = rom_get_prefix::return#0
    // main::@152
    // [673] main::rom_file_prefix#0 = rom_get_prefix::return#3 -- vbuz1=vbum2 
    lda rom_get_prefix.return
    sta.z rom_file_prefix
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // main::@75
    // rom_get_version_text(rom_file_release_text, rom_file_prefix, rom_file_release, rom_file_github)
    // [675] rom_get_version_text::prefix#1 = main::rom_file_prefix#0 -- vbum1=vbuz2 
    lda.z rom_file_prefix
    sta rom_get_version_text.prefix
    // [676] rom_get_version_text::release#1 = main::rom_file_release#0 -- vbum1=vbum2 
    lda rom_file_release
    sta rom_get_version_text.release
    // [677] call rom_get_version_text
    // [2082] phi from main::@75 to rom_get_version_text [phi:main::@75->rom_get_version_text]
    // [2082] phi rom_get_version_text::github#2 = main::rom_file_github [phi:main::@75->rom_get_version_text#0] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z rom_get_version_text.github
    lda #>rom_file_github
    sta.z rom_get_version_text.github+1
    // [2082] phi rom_get_version_text::release#2 = rom_get_version_text::release#1 [phi:main::@75->rom_get_version_text#1] -- register_copy 
    // [2082] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#1 [phi:main::@75->rom_get_version_text#2] -- register_copy 
    // [2082] phi rom_get_version_text::release_info#2 = main::rom_file_release_text [phi:main::@75->rom_get_version_text#3] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_file_release_text
    sta.z rom_get_version_text.release_info+1
    jsr rom_get_version_text
    // [678] phi from main::@75 to main::@153 [phi:main::@75->main::@153]
    // main::@153
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [679] call snprintf_init
    // [1204] phi from main::@153 to snprintf_init [phi:main::@153->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@153->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@154
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [680] printf_string::str#23 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [681] call printf_string
    // [1218] phi from main::@154 to printf_string [phi:main::@154->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:main::@154->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#23 [phi:main::@154->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:main::@154->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:main::@154->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [682] phi from main::@154 to main::@155 [phi:main::@154->main::@155]
    // main::@155
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [683] call printf_str
    // [1209] phi from main::@155 to printf_str [phi:main::@155->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@155->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s2 [phi:main::@155->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // [684] phi from main::@155 to main::@156 [phi:main::@155->main::@156]
    // main::@156
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [685] call printf_string
    // [1218] phi from main::@156 to printf_string [phi:main::@156->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:main::@156->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = main::rom_file_release_text [phi:main::@156->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z printf_string.str
    lda #>rom_file_release_text
    sta.z printf_string.str+1
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:main::@156->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:main::@156->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@157
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [686] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [687] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [689] display_info_rom::rom_chip#9 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [690] call display_info_rom
    // [1565] phi from main::@157 to display_info_rom [phi:main::@157->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = info_text [phi:main::@157->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#9 [phi:main::@157->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@157->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // [691] phi from main::@146 main::@150 main::@157 main::@72 to main::@30 [phi:main::@146/main::@150/main::@157/main::@72->main::@30]
    // [691] phi __stdio_filecount#398 = __stdio_filecount#12 [phi:main::@146/main::@150/main::@157/main::@72->main::@30#0] -- register_copy 
    // [691] phi __errno#383 = __errno#123 [phi:main::@146/main::@150/main::@157/main::@72->main::@30#1] -- register_copy 
    // main::@30
  __b30:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [692] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip2
    // [180] phi from main::@30 to main::@29 [phi:main::@30->main::@29]
    // [180] phi __stdio_filecount#111 = __stdio_filecount#398 [phi:main::@30->main::@29#0] -- register_copy 
    // [180] phi __errno#115 = __errno#383 [phi:main::@30->main::@29#1] -- register_copy 
    // [180] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@30->main::@29#2] -- register_copy 
    jmp __b29
    // [693] phi from main::@34 to main::@32 [phi:main::@34->main::@32]
    // main::@32
  __b32:
    // sprintf(info_text, "File %s size error!", file)
    // [694] call snprintf_init
    // [1204] phi from main::@32 to snprintf_init [phi:main::@32->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@32->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [695] phi from main::@32 to main::@147 [phi:main::@32->main::@147]
    // main::@147
    // sprintf(info_text, "File %s size error!", file)
    // [696] call printf_str
    // [1209] phi from main::@147 to printf_str [phi:main::@147->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@147->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s8 [phi:main::@147->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@148
    // sprintf(info_text, "File %s size error!", file)
    // [697] printf_string::str#22 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [698] call printf_string
    // [1218] phi from main::@148 to printf_string [phi:main::@148->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:main::@148->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#22 [phi:main::@148->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:main::@148->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:main::@148->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [699] phi from main::@148 to main::@149 [phi:main::@148->main::@149]
    // main::@149
    // sprintf(info_text, "File %s size error!", file)
    // [700] call printf_str
    // [1209] phi from main::@149 to printf_str [phi:main::@149->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@149->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s9 [phi:main::@149->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@150
    // sprintf(info_text, "File %s size error!", file)
    // [701] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [702] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ISSUE, info_text)
    // [704] display_info_rom::rom_chip#8 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [705] call display_info_rom
    // [1565] phi from main::@150 to display_info_rom [phi:main::@150->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = info_text [phi:main::@150->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#8 [phi:main::@150->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:main::@150->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b30
    // [706] phi from main::@143 to main::@31 [phi:main::@143->main::@31]
    // main::@31
  __b31:
    // sprintf(info_text, "No %s", file)
    // [707] call snprintf_init
    // [1204] phi from main::@31 to snprintf_init [phi:main::@31->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@31->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [708] phi from main::@31 to main::@144 [phi:main::@31->main::@144]
    // main::@144
    // sprintf(info_text, "No %s", file)
    // [709] call printf_str
    // [1209] phi from main::@144 to printf_str [phi:main::@144->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@144->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s7 [phi:main::@144->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@145
    // sprintf(info_text, "No %s", file)
    // [710] printf_string::str#21 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [711] call printf_string
    // [1218] phi from main::@145 to printf_string [phi:main::@145->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:main::@145->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#21 [phi:main::@145->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:main::@145->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:main::@145->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@146
    // sprintf(info_text, "No %s", file)
    // [712] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [713] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_SKIP, info_text)
    // [715] display_info_rom::rom_chip#7 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [716] call display_info_rom
    // [1565] phi from main::@146 to display_info_rom [phi:main::@146->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = info_text [phi:main::@146->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#7 [phi:main::@146->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@146->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b30
    // main::@28
  __b28:
    // [717] smc_bootloader#518 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [718] call display_info_smc
  // SF3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
    // [961] phi from main::@28 to display_info_smc [phi:main::@28->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text5 [phi:main::@28->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_smc.info_text
    lda #>info_text5
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#518 [phi:main::@28->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@28->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [169] phi from main::@27 main::@28 to main::CLI2 [phi:main::@27/main::@28->main::CLI2]
  __b11:
    // [169] phi smc_file_minor#301 = 0 [phi:main::@27/main::@28->main::CLI2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [169] phi smc_file_major#301 = 0 [phi:main::@27/main::@28->main::CLI2#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [169] phi smc_file_release#301 = 0 [phi:main::@27/main::@28->main::CLI2#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [169] phi __stdio_filecount#109 = __stdio_filecount#39 [phi:main::@27/main::@28->main::CLI2#3] -- register_copy 
    // [169] phi __errno#113 = __errno#123 [phi:main::@27/main::@28->main::CLI2#4] -- register_copy 
    jmp CLI2
    // main::@27
  __b27:
    // [719] smc_bootloader#517 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "No SMC.BIN!")
    // [720] call display_info_smc
  // SF1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
  // SF2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
    // [961] phi from main::@27 to display_info_smc [phi:main::@27->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text4 [phi:main::@27->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#517 [phi:main::@27->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@27->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b11
    // main::@21
  __b21:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [721] if(rom_device_ids[main::rom_chip1#10]!=$55) goto main::@22 -- pbuc1_derefidx_vbuz1_neq_vbuc2_then_la1 
    lda #$55
    ldy.z rom_chip1
    cmp rom_device_ids,y
    bne __b22
    // main::@23
  __b23:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [722] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip1
    // [136] phi from main::@23 to main::@20 [phi:main::@23->main::@20]
    // [136] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@23->main::@20#0] -- register_copy 
    jmp __b20
    // main::@22
  __b22:
    // bank_set_brom(rom_chip*32)
    // [723] main::bank_set_brom2_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta bank_set_brom2_bank
    // main::bank_set_brom2
    // BROM = bank
    // [724] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbum2 
    sta.z BROM
    // main::@70
    // rom_chip*8
    // [725] main::$115 = main::rom_chip1#10 << 3 -- vbum1=vbuz2_rol_3 
    lda.z rom_chip1
    asl
    asl
    asl
    sta main__115
    // rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000)
    // [726] rom_get_github_commit_id::commit_id#0 = rom_github + main::$115 -- pbuz1=pbuc1_plus_vbum2 
    clc
    adc #<rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [727] call rom_get_github_commit_id
    // [2049] phi from main::@70 to rom_get_github_commit_id [phi:main::@70->rom_get_github_commit_id]
    // [2049] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#0 [phi:main::@70->rom_get_github_commit_id#0] -- register_copy 
    // [2049] phi rom_get_github_commit_id::from#6 = (char *) 49152 [phi:main::@70->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z rom_get_github_commit_id.from
    lda #>$c000
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::@125
    // rom_get_release(*((char*)0xFF80))
    // [728] rom_get_release::release#1 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_release.release
    // [729] call rom_get_release
    // [2066] phi from main::@125 to rom_get_release [phi:main::@125->rom_get_release]
    // [2066] phi rom_get_release::release#3 = rom_get_release::release#1 [phi:main::@125->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)0xFF80))
    // [730] rom_get_release::return#2 = rom_get_release::return#0
    // main::@126
    // [731] main::$111 = rom_get_release::return#2 -- vbuz1=vbum2 
    lda rom_get_release.return
    sta.z main__111
    // rom_release[rom_chip] = rom_get_release(*((char*)0xFF80))
    // [732] rom_release[main::rom_chip1#10] = main::$111 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z rom_chip1
    sta rom_release,y
    // rom_get_prefix(*((char*)0xFF80))
    // [733] rom_get_prefix::release#0 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_prefix.release
    // [734] call rom_get_prefix
    // [2073] phi from main::@126 to rom_get_prefix [phi:main::@126->rom_get_prefix]
    // [2073] phi rom_get_prefix::release#2 = rom_get_prefix::release#0 [phi:main::@126->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)0xFF80))
    // [735] rom_get_prefix::return#2 = rom_get_prefix::return#0
    // main::@127
    // [736] main::$112 = rom_get_prefix::return#2 -- vbuz1=vbum2 
    lda rom_get_prefix.return
    sta.z main__112
    // rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80))
    // [737] rom_prefix[main::rom_chip1#10] = main::$112 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z rom_chip1
    sta rom_prefix,y
    // rom_chip*13
    // [738] main::$376 = main::rom_chip1#10 << 1 -- vbuz1=vbuz2_rol_1 
    tya
    asl
    sta.z main__376
    // [739] main::$377 = main::$376 + main::rom_chip1#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__377
    clc
    adc.z rom_chip1
    sta.z main__377
    // [740] main::$378 = main::$377 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__378
    asl
    asl
    sta.z main__378
    // [741] main::$113 = main::$378 + main::rom_chip1#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__113
    clc
    adc.z rom_chip1
    sta.z main__113
    // rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8])
    // [742] rom_get_version_text::release_info#0 = rom_release_text + main::$113 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_release_text
    adc #0
    sta.z rom_get_version_text.release_info+1
    // [743] rom_get_version_text::github#0 = rom_github + main::$115 -- pbuz1=pbuc1_plus_vbum2 
    lda main__115
    clc
    adc #<rom_github
    sta.z rom_get_version_text.github
    lda #>rom_github
    adc #0
    sta.z rom_get_version_text.github+1
    // [744] rom_get_version_text::prefix#0 = rom_prefix[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbuz2 
    lda rom_prefix,y
    sta rom_get_version_text.prefix
    // [745] rom_get_version_text::release#0 = rom_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbuz2 
    lda rom_release,y
    sta rom_get_version_text.release
    // [746] call rom_get_version_text
    // [2082] phi from main::@127 to rom_get_version_text [phi:main::@127->rom_get_version_text]
    // [2082] phi rom_get_version_text::github#2 = rom_get_version_text::github#0 [phi:main::@127->rom_get_version_text#0] -- register_copy 
    // [2082] phi rom_get_version_text::release#2 = rom_get_version_text::release#0 [phi:main::@127->rom_get_version_text#1] -- register_copy 
    // [2082] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#0 [phi:main::@127->rom_get_version_text#2] -- register_copy 
    // [2082] phi rom_get_version_text::release_info#2 = rom_get_version_text::release_info#0 [phi:main::@127->rom_get_version_text#3] -- register_copy 
    jsr rom_get_version_text
    // main::@128
    // display_info_rom(rom_chip, STATUS_DETECTED, NULL)
    // [747] display_info_rom::rom_chip#6 = main::rom_chip1#10 -- vbum1=vbuz2 
    lda.z rom_chip1
    sta display_info_rom.rom_chip
    // [748] call display_info_rom
    // [1565] phi from main::@128 to display_info_rom [phi:main::@128->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = 0 [phi:main::@128->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#6 [phi:main::@128->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_DETECTED [phi:main::@128->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b23
    // [749] phi from main::@16 to main::@19 [phi:main::@16->main::@19]
    // main::@19
  __b19:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [750] call snprintf_init
    // [1204] phi from main::@19 to snprintf_init [phi:main::@19->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [751] phi from main::@19 to main::@115 [phi:main::@19->main::@115]
    // main::@115
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [752] call printf_str
    // [1209] phi from main::@115 to printf_str [phi:main::@115->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@115->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s2 [phi:main::@115->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@116
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [753] printf_uint::uvalue#7 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [754] call printf_uint
    // [2098] phi from main::@116 to printf_uint [phi:main::@116->printf_uint]
    // [2098] phi printf_uint::format_zero_padding#10 = 1 [phi:main::@116->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2098] phi printf_uint::format_min_length#10 = 2 [phi:main::@116->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [2098] phi printf_uint::putc#10 = &snputc [phi:main::@116->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2098] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:main::@116->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2098] phi printf_uint::uvalue#10 = printf_uint::uvalue#7 [phi:main::@116->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [755] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [756] call printf_str
    // [1209] phi from main::@117 to printf_str [phi:main::@117->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main::@117->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main::s3 [phi:main::@117->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@118
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [757] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [758] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [760] smc_bootloader#507 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, info_text)
    // [761] call display_info_smc
    // [961] phi from main::@118 to display_info_smc [phi:main::@118->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = info_text [phi:main::@118->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#507 [phi:main::@118->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@118->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [762] phi from main::@118 to main::@119 [phi:main::@118->main::@119]
    // main::@119
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [763] call display_progress_text
  // Bootloader is not supported by this utility, but is not error.
    // [1331] phi from main::@119 to display_progress_text [phi:main::@119->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_no_valid_smc_bootloader_text [phi:main::@119->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_no_valid_smc_bootloader_count [phi:main::@119->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [129] phi from main::@114 main::@119 main::@18 to main::@2 [phi:main::@114/main::@119/main::@18->main::@2]
  __b14:
    // [129] phi smc_minor#403 = 0 [phi:main::@114/main::@119/main::@18->main::@2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_minor
    // [129] phi smc_major#404 = 0 [phi:main::@114/main::@119/main::@18->main::@2#1] -- vbum1=vbuc1 
    sta smc_major
    // [129] phi smc_release#405 = 0 [phi:main::@114/main::@119/main::@18->main::@2#2] -- vbum1=vbuc1 
    sta smc_release
    jmp __b2
    // main::@18
  __b18:
    // [764] smc_bootloader#516 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC Unreachable!")
    // [765] call display_info_smc
  // SD2 | SMC chip not detected | Display that the SMC chip is not detected and set SMC to Error. | Error
    // [961] phi from main::@18 to display_info_smc [phi:main::@18->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text2 [phi:main::@18->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_smc.info_text
    lda #>info_text2
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#516 [phi:main::@18->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main::@18->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b14
    // main::@1
  __b1:
    // [766] smc_bootloader#505 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "No Bootloader!")
    // [767] call display_info_smc
  // SD1 | No Bootloader | Display that there is no bootloader and set SMC to Issue. | Issue
    // [961] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = main::info_text1 [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#505 [phi:main::@1->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@1->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [768] phi from main::@1 to main::@114 [phi:main::@1->main::@114]
    // main::@114
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [769] call display_progress_text
  // If the CX16 board does not have a bootloader, display info how to flash bootloader.
    // [1331] phi from main::@114 to display_progress_text [phi:main::@114->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_no_valid_smc_bootloader_text [phi:main::@114->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_no_valid_smc_bootloader_count [phi:main::@114->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta display_progress_text.lines
    jsr display_progress_text
    jmp __b14
    // main::@13
  __b13:
    // rom_chip*13
    // [770] main::$372 = main::rom_chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z main__372
    // [771] main::$373 = main::$372 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__373
    clc
    adc.z rom_chip
    sta.z main__373
    // [772] main::$374 = main::$373 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__374
    asl
    asl
    sta.z main__374
    // [773] main::$87 = main::$374 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__87
    clc
    adc.z rom_chip
    sta.z main__87
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [774] strcpy::destination#1 = rom_release_text + main::$87 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [775] call strcpy
    // [1065] phi from main::@13 to strcpy [phi:main::@13->strcpy]
    // [1065] phi strcpy::dst#0 = strcpy::destination#1 [phi:main::@13->strcpy#0] -- register_copy 
    // [1065] phi strcpy::src#0 = main::source [phi:main::@13->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@108
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [776] display_info_rom::rom_chip#5 = main::rom_chip#2 -- vbum1=vbuz2 
    lda.z rom_chip
    sta display_info_rom.rom_chip
    // [777] call display_info_rom
    // [1565] phi from main::@108 to display_info_rom [phi:main::@108->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = 0 [phi:main::@108->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#5 [phi:main::@108->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@108->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@109
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [778] main::rom_chip#1 = ++ main::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [94] phi from main::@109 to main::@12 [phi:main::@109->main::@12]
    // [94] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@109->main::@12#0] -- register_copy 
    jmp __b12
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
    info_text1: .text "No Bootloader!"
    .byte 0
    info_text2: .text "SMC Unreachable!"
    .byte 0
    s2: .text "Bootloader v"
    .byte 0
    s3: .text " invalid! !"
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
    rom_flash_errors: .dword 0
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
    // [779] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [780] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [781] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [782] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $61
    .label textcolor__1 = $61
    // __conio.color & 0xF0
    // [784] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [785] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [786] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [787] return 
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
    .label bgcolor__0 = $61
    .label bgcolor__1 = $62
    .label bgcolor__2 = $61
    // __conio.color & 0x0F
    // [789] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [790] bgcolor::$1 = bgcolor::color#15 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [791] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [792] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [793] return 
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
    // [794] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [795] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [796] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [797] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [799] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [800] return 
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
    .label gotoxy__2 = $30
    .label gotoxy__3 = $30
    .label gotoxy__6 = $2f
    .label gotoxy__7 = $2f
    .label gotoxy__8 = $37
    .label gotoxy__9 = $34
    .label gotoxy__10 = $33
    .label gotoxy__14 = $2f
    // (x>=__conio.width)?__conio.width:x
    // [802] if(gotoxy::x#37>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [804] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [804] phi gotoxy::$3 = gotoxy::x#37 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [803] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [804] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [804] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [805] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [806] if(gotoxy::y#37>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [807] gotoxy::$14 = gotoxy::y#37 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [808] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [808] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [809] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [810] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [811] gotoxy::$10 = gotoxy::y#37 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [812] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [813] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [814] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [815] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    .label cputln__2 = $4d
    // __conio.cursor_x = 0
    // [816] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [817] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [818] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [819] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [820] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [821] return 
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
    .label cx16_k_screen_set_charset1_offset = $f2
    // cx16_k_screen_set_mode(0)
    // [822] cx16_k_screen_set_mode::mode = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_screen_set_mode.mode
    // [823] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [824] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // screenlayer1()
    // [825] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // display_frame_init_64::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [826] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [827] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // [829] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [830] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [831] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [832] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [833] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [834] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [835] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [836] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [837] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [838] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [839] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [840] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [841] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [842] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [843] phi from display_frame_init_64::vera_layer1_show1 to display_frame_init_64::@1 [phi:display_frame_init_64::vera_layer1_show1->display_frame_init_64::@1]
    // display_frame_init_64::@1
    // textcolor(WHITE)
    // [844] call textcolor
  // Layer 1 is the current text canvas.
    // [783] phi from display_frame_init_64::@1 to textcolor [phi:display_frame_init_64::@1->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:display_frame_init_64::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [845] phi from display_frame_init_64::@1 to display_frame_init_64::@4 [phi:display_frame_init_64::@1->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // bgcolor(BLUE)
    // [846] call bgcolor
  // Default text color is white.
    // [788] phi from display_frame_init_64::@4 to bgcolor [phi:display_frame_init_64::@4->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_frame_init_64::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [847] phi from display_frame_init_64::@4 to display_frame_init_64::@5 [phi:display_frame_init_64::@4->display_frame_init_64::@5]
    // display_frame_init_64::@5
    // clrscr()
    // [848] call clrscr
    // With a blue background.
    // cx16-conio.c won't compile scrolling code for this program with the underlying define, resulting in less code overhead!
    jsr clrscr
    // display_frame_init_64::@return
    // }
    // [849] return 
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
    // [851] call textcolor
    // [783] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [783] phi textcolor::color#23 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [852] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [853] call bgcolor
    // [788] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [854] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [855] call clrscr
    jsr clrscr
    // [856] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [857] call display_frame
    // [2158] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [2158] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [858] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [859] call display_frame
    // [2158] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [2158] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [860] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [861] call display_frame
    // [2158] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [862] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [863] call display_frame
  // Chipset areas
    // [2158] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x1
    jsr display_frame
    // [864] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [865] call display_frame
    // [2158] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x1
    jsr display_frame
    // [866] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [867] call display_frame
    // [2158] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x1
    jsr display_frame
    // [868] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [869] call display_frame
    // [2158] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x1
    jsr display_frame
    // [870] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [871] call display_frame
    // [2158] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x1
    jsr display_frame
    // [872] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [873] call display_frame
    // [2158] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x1
    jsr display_frame
    // [874] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [875] call display_frame
    // [2158] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x1
    jsr display_frame
    // [876] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [877] call display_frame
    // [2158] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x1
    jsr display_frame
    // [878] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [879] call display_frame
    // [2158] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x1
    jsr display_frame
    // [880] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [881] call display_frame
    // [2158] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [2158] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [882] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [883] call display_frame
  // Progress area
    // [2158] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [2158] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [884] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [885] call display_frame
    // [2158] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [2158] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [886] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [887] call display_frame
    // [2158] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [2158] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [2158] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [2158] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2158] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [888] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [889] call textcolor
    // [783] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [890] return 
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
    // [892] call gotoxy
    // [801] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [801] phi gotoxy::y#37 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [893] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [894] call printf_string
    // [1218] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [895] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($5d) const char *s)
cputsxy: {
    .label s = $5d
    // gotoxy(x, y)
    // [897] gotoxy::x#1 = cputsxy::x#4 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [898] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [899] call gotoxy
    // [801] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [900] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [901] call cputs
    // [2292] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [902] return 
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
// void display_action_progress(__zp($50) char *info_text)
display_action_progress: {
    .label info_text = $50
    // unsigned char x = wherex()
    // [904] call wherex
    jsr wherex
    // [905] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [906] display_action_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [907] call wherey
    jsr wherey
    // [908] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [909] display_action_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [910] call gotoxy
    // [801] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [801] phi gotoxy::y#37 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [911] printf_string::str#1 = display_action_progress::info_text#27
    // [912] call printf_string
    // [1218] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [913] gotoxy::x#14 = display_action_progress::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [914] gotoxy::y#14 = display_action_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [915] call gotoxy
    // [801] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#14 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#14 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [916] return 
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
    // [918] call textcolor
    // [783] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [919] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [920] call bgcolor
    // [788] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [921] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [921] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [922] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [923] return 
    rts
    // [924] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [924] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x
    // [924] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [925] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [926] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [921] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [921] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [927] cputcxy::x#14 = display_progress_clear::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [928] cputcxy::y#14 = display_progress_clear::y#2 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [929] call cputcxy
    // [2305] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [2305] phi cputcxy::c#17 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [2305] phi cputcxy::y#17 = cputcxy::y#14 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#14 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [930] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbum1=_inc_vbum1 
    inc x
    // for(unsigned char i = 0; i < w; i++)
    // [931] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [924] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [924] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [924] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
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
    // [933] call display_smc_led
    // [2313] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [2313] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_smc_led.c
    jsr display_smc_led
    // [934] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [935] call display_print_chip
    // [2319] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [2319] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2319] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta display_print_chip.w
    // [2319] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #1
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [936] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [938] call display_vera_led
    // [2363] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [2363] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_vera_led.c
    jsr display_vera_led
    // [939] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [940] call display_print_chip
    // [2319] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [2319] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2319] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta display_print_chip.w
    // [2319] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #9
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [941] return 
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
    .label display_chip_rom__4 = $42
    .label display_chip_rom__6 = $29
    .label display_chip_rom__11 = $29
    .label display_chip_rom__12 = $29
    // [943] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [943] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [944] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [945] return 
    rts
    // [946] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [947] call strcpy
    // [1065] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [1065] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [1065] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [948] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbum2_rol_1 
    lda r
    asl
    sta.z display_chip_rom__11
    // [949] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [950] call strcat
    // [2369] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [951] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [952] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [953] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [954] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbum1=vbum2 
    lda r
    sta display_rom_led.chip
    // [955] call display_rom_led
    // [2381] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [2381] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_rom_led.c
    // [2381] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [956] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbum2 
    lda r
    clc
    adc.z display_chip_rom__12
    sta.z display_chip_rom__12
    // [957] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [958] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbum1=vbuc1_plus_vbuz2 
    lda #$14
    clc
    adc.z display_chip_rom__6
    sta display_print_chip.x
    // [959] call display_print_chip
    // [2319] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [2319] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [2319] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta display_print_chip.w
    // [2319] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [960] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [943] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [943] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
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
// void display_info_smc(__mem() char info_status, __zp($47) char *info_text)
display_info_smc: {
    .label display_info_smc__9 = $29
    .label info_text = $47
    // unsigned char x = wherex()
    // [962] call wherex
    jsr wherex
    // [963] wherex::return#10 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_2
    // display_info_smc::@3
    // [964] display_info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [965] call wherey
    jsr wherey
    // [966] wherey::return#10 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_2
    // display_info_smc::@4
    // [967] display_info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [968] status_smc#0 = display_info_smc::info_status#20 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [969] display_smc_led::c#1 = status_color[display_info_smc::info_status#20] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_smc_led.c
    // [970] call display_smc_led
    // [2313] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [2313] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [971] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [972] call gotoxy
    // [801] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [801] phi gotoxy::y#37 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [973] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [974] call printf_str
    // [1209] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [975] display_info_smc::$9 = display_info_smc::info_status#20 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_smc__9
    // [976] printf_string::str#3 = status_text[display_info_smc::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [977] call printf_string
    // [1218] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [978] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [979] call printf_str
    // [1209] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [980] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [981] call printf_string
    // [1218] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = smc_version_text [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 8 [phi:display_info_smc::@9->printf_string#3] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [982] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [983] call printf_str
    // [1209] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [984] printf_uint::uvalue#1 = smc_bootloader#14 -- vwum1=vwum2 
    lda smc_bootloader_1
    sta printf_uint.uvalue
    lda smc_bootloader_1+1
    sta printf_uint.uvalue+1
    // [985] call printf_uint
    // [2098] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    // [2098] phi printf_uint::format_zero_padding#10 = 0 [phi:display_info_smc::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2098] phi printf_uint::format_min_length#10 = 0 [phi:display_info_smc::@11->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2098] phi printf_uint::putc#10 = &cputc [phi:display_info_smc::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [2098] phi printf_uint::format_radix#10 = DECIMAL [phi:display_info_smc::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [2098] phi printf_uint::uvalue#10 = printf_uint::uvalue#1 [phi:display_info_smc::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [986] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [987] call printf_str
    // [1209] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [988] if((char *)0==display_info_smc::info_text#20) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [989] phi from display_info_smc::@13 to display_info_smc::@2 [phi:display_info_smc::@13->display_info_smc::@2]
    // display_info_smc::@2
    // gotoxy(INFO_X+64-28, INFO_Y)
    // [990] call gotoxy
    // [801] phi from display_info_smc::@2 to gotoxy [phi:display_info_smc::@2->gotoxy]
    // [801] phi gotoxy::y#37 = $11 [phi:display_info_smc::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_smc::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_smc::@14
    // printf("%-25s", info_text)
    // [991] printf_string::str#5 = display_info_smc::info_text#20 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [992] call printf_string
    // [1218] phi from display_info_smc::@14 to printf_string [phi:display_info_smc::@14->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@14->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#5 [phi:display_info_smc::@14->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@14->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = $19 [phi:display_info_smc::@14->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [993] gotoxy::x#18 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [994] gotoxy::y#18 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [995] call gotoxy
    // [801] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#18 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#18 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [996] return 
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
// void display_info_vera(__mem() char info_status, __zp($63) char *info_text)
display_info_vera: {
    .label display_info_vera__9 = $42
    .label info_text = $63
    // unsigned char x = wherex()
    // [998] call wherex
    jsr wherex
    // [999] wherex::return#11 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_3
    // display_info_vera::@3
    // [1000] display_info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [1001] call wherey
    jsr wherey
    // [1002] wherey::return#11 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_3
    // display_info_vera::@4
    // [1003] display_info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [1004] status_vera#127 = display_info_vera::info_status#19 -- vbum1=vbum2 
    lda info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [1005] display_vera_led::c#1 = status_color[display_info_vera::info_status#19] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_vera_led.c
    // [1006] call display_vera_led
    // [2363] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [2363] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [1007] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [1008] call gotoxy
    // [801] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [801] phi gotoxy::y#37 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [1009] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1010] call printf_str
    // [1209] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1011] display_info_vera::$9 = display_info_vera::info_status#19 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_vera__9
    // [1012] printf_string::str#6 = status_text[display_info_vera::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1013] call printf_string
    // [1218] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1014] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1015] call printf_str
    // [1209] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1016] printf_uchar::uvalue#1 = spi_manufacturer#108 -- vbum1=vbum2 
    lda spi_manufacturer
    sta printf_uchar.uvalue
    // [1017] call printf_uchar
    // [1346] phi from display_info_vera::@9 to printf_uchar [phi:display_info_vera::@9->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_info_vera::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:display_info_vera::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &cputc [phi:display_info_vera::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_info_vera::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#1 [phi:display_info_vera::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1018] phi from display_info_vera::@9 to display_info_vera::@10 [phi:display_info_vera::@9->display_info_vera::@10]
    // display_info_vera::@10
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1019] call printf_str
    // [1209] phi from display_info_vera::@10 to printf_str [phi:display_info_vera::@10->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:display_info_vera::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s4
    sta.z printf_str.s
    lda #>@s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@11
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1020] printf_uchar::uvalue#2 = spi_memory_type#107 -- vbum1=vbum2 
    lda spi_memory_type
    sta printf_uchar.uvalue
    // [1021] call printf_uchar
    // [1346] phi from display_info_vera::@11 to printf_uchar [phi:display_info_vera::@11->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_info_vera::@11->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:display_info_vera::@11->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &cputc [phi:display_info_vera::@11->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_info_vera::@11->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#2 [phi:display_info_vera::@11->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1022] phi from display_info_vera::@11 to display_info_vera::@12 [phi:display_info_vera::@11->display_info_vera::@12]
    // display_info_vera::@12
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1023] call printf_str
    // [1209] phi from display_info_vera::@12 to printf_str [phi:display_info_vera::@12->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:display_info_vera::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s4
    sta.z printf_str.s
    lda #>@s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@13
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1024] printf_uchar::uvalue#3 = spi_memory_capacity#106 -- vbum1=vbum2 
    lda spi_memory_capacity
    sta printf_uchar.uvalue
    // [1025] call printf_uchar
    // [1346] phi from display_info_vera::@13 to printf_uchar [phi:display_info_vera::@13->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_info_vera::@13->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:display_info_vera::@13->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &cputc [phi:display_info_vera::@13->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_info_vera::@13->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#3 [phi:display_info_vera::@13->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1026] phi from display_info_vera::@13 to display_info_vera::@14 [phi:display_info_vera::@13->display_info_vera::@14]
    // display_info_vera::@14
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1027] call printf_str
    // [1209] phi from display_info_vera::@14 to printf_str [phi:display_info_vera::@14->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_info_vera::s4 [phi:display_info_vera::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@15
    // if(info_text)
    // [1028] if((char *)0==display_info_vera::info_text#19) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [1029] phi from display_info_vera::@15 to display_info_vera::@2 [phi:display_info_vera::@15->display_info_vera::@2]
    // display_info_vera::@2
    // gotoxy(INFO_X+64-28, INFO_Y+1)
    // [1030] call gotoxy
    // [801] phi from display_info_vera::@2 to gotoxy [phi:display_info_vera::@2->gotoxy]
    // [801] phi gotoxy::y#37 = $11+1 [phi:display_info_vera::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_vera::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_vera::@16
    // printf("%-25s", info_text)
    // [1031] printf_string::str#7 = display_info_vera::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1032] call printf_string
    // [1218] phi from display_info_vera::@16 to printf_string [phi:display_info_vera::@16->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_vera::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#7 [phi:display_info_vera::@16->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_vera::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = $19 [phi:display_info_vera::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [1033] gotoxy::x#21 = display_info_vera::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1034] gotoxy::y#21 = display_info_vera::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1035] call gotoxy
    // [801] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#21 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#21 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [1036] return 
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
    .label intro_status = $cb
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [1038] call display_progress_text
    // [1331] phi from main_intro to display_progress_text [phi:main_intro->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_into_briefing_text [phi:main_intro->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_intro_briefing_count [phi:main_intro->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_briefing_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [1039] phi from main_intro to main_intro::@4 [phi:main_intro->main_intro::@4]
    // main_intro::@4
    // util_wait_space()
    // [1040] call util_wait_space
    // [1389] phi from main_intro::@4 to util_wait_space [phi:main_intro::@4->util_wait_space]
    jsr util_wait_space
    // [1041] phi from main_intro::@4 to main_intro::@5 [phi:main_intro::@4->main_intro::@5]
    // main_intro::@5
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [1042] call display_progress_text
    // [1331] phi from main_intro::@5 to display_progress_text [phi:main_intro::@5->display_progress_text]
    // [1331] phi display_progress_text::text#13 = display_into_colors_text [phi:main_intro::@5->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [1331] phi display_progress_text::lines#12 = display_intro_colors_count [phi:main_intro::@5->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_colors_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [1043] phi from main_intro::@5 to main_intro::@1 [phi:main_intro::@5->main_intro::@1]
    // [1043] phi main_intro::intro_status#2 = 0 [phi:main_intro::@5->main_intro::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_status
    // main_intro::@1
  __b1:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [1044] if(main_intro::intro_status#2<$b) goto main_intro::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_status
    cmp #$b
    bcc __b2
    // [1045] phi from main_intro::@1 to main_intro::@3 [phi:main_intro::@1->main_intro::@3]
    // main_intro::@3
    // util_wait_space()
    // [1046] call util_wait_space
    // [1389] phi from main_intro::@3 to util_wait_space [phi:main_intro::@3->util_wait_space]
    jsr util_wait_space
    // [1047] phi from main_intro::@3 to main_intro::@7 [phi:main_intro::@3->main_intro::@7]
    // main_intro::@7
    // display_progress_clear()
    // [1048] call display_progress_clear
    // [917] phi from main_intro::@7 to display_progress_clear [phi:main_intro::@7->display_progress_clear]
    jsr display_progress_clear
    // main_intro::@return
    // }
    // [1049] return 
    rts
    // main_intro::@2
  __b2:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [1050] display_info_led::y#3 = PROGRESS_Y+3 + main_intro::intro_status#2 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y+3
    clc
    adc.z intro_status
    sta display_info_led.y
    // [1051] display_info_led::tc#3 = status_color[main_intro::intro_status#2] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z intro_status
    lda status_color,y
    sta display_info_led.tc
    // [1052] call display_info_led
    // [2392] phi from main_intro::@2 to display_info_led [phi:main_intro::@2->display_info_led]
    // [2392] phi display_info_led::y#4 = display_info_led::y#3 [phi:main_intro::@2->display_info_led#0] -- register_copy 
    // [2392] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main_intro::@2->display_info_led#1] -- vbum1=vbuc1 
    lda #PROGRESS_X+3
    sta display_info_led.x
    // [2392] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main_intro::@2->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main_intro::@6
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [1053] main_intro::intro_status#1 = ++ main_intro::intro_status#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_status
    // [1043] phi from main_intro::@6 to main_intro::@1 [phi:main_intro::@6->main_intro::@1]
    // [1043] phi main_intro::intro_status#2 = main_intro::intro_status#1 [phi:main_intro::@6->main_intro::@1#0] -- register_copy 
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
    .label smc_detect__1 = $29
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1054] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1055] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1056] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1057] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1058] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [1059] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwum2 
    lda smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [1060] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [1063] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [1063] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwum1=vwuc1 
    lda #<$200
    sta return
    lda #>$200
    sta return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [1061] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwum1_neq_vbuc1_then_la1 
    lda smc_bootloader_version+1
    bne __b2
    lda smc_bootloader_version
    cmp #$ff
    bne __b2
    // [1063] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [1063] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwum1=vwuc1 
    lda #<$100
    sta return
    lda #>$100
    sta return+1
    rts
    // [1062] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [1063] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [1063] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [1064] return 
    rts
  .segment Data
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = return
    return: .word 0
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($50) char *destination, char *source)
strcpy: {
    .label src = $5d
    .label dst = $50
    .label destination = $50
    // [1066] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [1066] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1066] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [1067] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1068] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1069] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1070] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1071] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1072] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
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
    // [1073] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1075] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1076] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1077] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    .label return = smc_detect.return
}
.segment Code
  // smc_get_version_text
/**
 * @brief Detect and write the SMC version number into the info_text.
 * 
 * @param version_string The string containing the SMC version filled upon return.
 */
// unsigned long smc_get_version_text(__zp($47) char *version_string, __mem() char release, __mem() char major, __mem() char minor)
smc_get_version_text: {
    .label version_string = $47
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1079] snprintf_init::s#4 = smc_get_version_text::version_string#2
    // [1080] call snprintf_init
    // [1204] phi from smc_get_version_text to snprintf_init [phi:smc_get_version_text->snprintf_init]
    // [1204] phi snprintf_init::s#31 = snprintf_init::s#4 [phi:smc_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // smc_get_version_text::@1
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1081] printf_uchar::uvalue#7 = smc_get_version_text::release#2
    // [1082] call printf_uchar
    // [1346] phi from smc_get_version_text::@1 to printf_uchar [phi:smc_get_version_text::@1->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:smc_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:smc_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_get_version_text::@1->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#7 [phi:smc_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1083] phi from smc_get_version_text::@1 to smc_get_version_text::@2 [phi:smc_get_version_text::@1->smc_get_version_text::@2]
    // smc_get_version_text::@2
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1084] call printf_str
    // [1209] phi from smc_get_version_text::@2 to printf_str [phi:smc_get_version_text::@2->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = smc_get_version_text::s [phi:smc_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@3
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1085] printf_uchar::uvalue#8 = smc_get_version_text::major#2 -- vbum1=vbum2 
    lda major
    sta printf_uchar.uvalue
    // [1086] call printf_uchar
    // [1346] phi from smc_get_version_text::@3 to printf_uchar [phi:smc_get_version_text::@3->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_get_version_text::@3->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:smc_get_version_text::@3->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:smc_get_version_text::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_get_version_text::@3->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#8 [phi:smc_get_version_text::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1087] phi from smc_get_version_text::@3 to smc_get_version_text::@4 [phi:smc_get_version_text::@3->smc_get_version_text::@4]
    // smc_get_version_text::@4
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1088] call printf_str
    // [1209] phi from smc_get_version_text::@4 to printf_str [phi:smc_get_version_text::@4->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_get_version_text::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = smc_get_version_text::s [phi:smc_get_version_text::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@5
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1089] printf_uchar::uvalue#9 = smc_get_version_text::minor#2 -- vbum1=vbum2 
    lda minor
    sta printf_uchar.uvalue
    // [1090] call printf_uchar
    // [1346] phi from smc_get_version_text::@5 to printf_uchar [phi:smc_get_version_text::@5->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_get_version_text::@5->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:smc_get_version_text::@5->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:smc_get_version_text::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_get_version_text::@5->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#9 [phi:smc_get_version_text::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_get_version_text::@6
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1091] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1092] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_get_version_text::@return
    // }
    // [1094] return 
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
    // vera_detect()
    // [1096] call vera_detect
    // [2403] phi from main_vera_detect to vera_detect [phi:main_vera_detect->vera_detect]
    jsr vera_detect
    // [1097] phi from main_vera_detect to main_vera_detect::@1 [phi:main_vera_detect->main_vera_detect::@1]
    // main_vera_detect::@1
    // display_chip_vera()
    // [1098] call display_chip_vera
    // [937] phi from main_vera_detect::@1 to display_chip_vera [phi:main_vera_detect::@1->display_chip_vera]
    jsr display_chip_vera
    // main_vera_detect::@2
    // [1099] spi_manufacturer#589 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1100] spi_memory_type#590 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1101] spi_memory_capacity#591 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, NULL)
    // [1102] call display_info_vera
    // [997] phi from main_vera_detect::@2 to display_info_vera [phi:main_vera_detect::@2->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = 0 [phi:main_vera_detect::@2->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#591 [phi:main_vera_detect::@2->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#590 [phi:main_vera_detect::@2->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#589 [phi:main_vera_detect::@2->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_detect::@2->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_detect::@return
    // }
    // [1103] return 
    rts
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__3 = $29
    .label rom_detect__5 = $42
    .label rom_detect__9 = $41
    .label rom_detect__14 = $70
    .label rom_detect__15 = $5a
    .label rom_detect__18 = $65
    .label rom_detect__21 = $c6
    .label rom_detect__24 = $7f
    // [1105] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [1105] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [1105] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vdum1=vduc1 
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
    // [1106] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [1107] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [1108] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [1109] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [1110] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda rom_detect_address
    adc #<$5555
    sta rom_unlock.address
    lda rom_detect_address+1
    adc #>$5555
    sta rom_unlock.address+1
    lda rom_detect_address+2
    adc #0
    sta rom_unlock.address+2
    lda rom_detect_address+3
    adc #0
    sta rom_unlock.address+3
    // [1111] call rom_unlock
    // [2406] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [2406] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$90
    sta rom_unlock.unlock_code
    // [2406] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [1112] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vdum1=vdum2 
    lda rom_detect_address
    sta rom_read_byte.address
    lda rom_detect_address+1
    sta rom_read_byte.address+1
    lda rom_detect_address+2
    sta rom_read_byte.address+2
    lda rom_detect_address+3
    sta rom_read_byte.address+3
    // [1113] call rom_read_byte
    // [2416] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [2416] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [1114] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [1115] rom_detect::$3 = rom_read_byte::return#2 -- vbuz1=vbum2 
    lda rom_read_byte.return
    sta.z rom_detect__3
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [1116] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [1117] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vdum1=vdum2_plus_1 
    lda rom_detect_address
    clc
    adc #1
    sta rom_read_byte.address
    lda rom_detect_address+1
    adc #0
    sta rom_read_byte.address+1
    lda rom_detect_address+2
    adc #0
    sta rom_read_byte.address+2
    lda rom_detect_address+3
    adc #0
    sta rom_read_byte.address+3
    // [1118] call rom_read_byte
    // [2416] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [2416] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [1119] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [1120] rom_detect::$5 = rom_read_byte::return#3 -- vbuz1=vbum2 
    lda rom_read_byte.return
    sta.z rom_detect__5
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [1121] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [1122] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vdum1=vdum2_plus_vwuc1 
    clc
    lda rom_detect_address
    adc #<$5555
    sta rom_unlock.address
    lda rom_detect_address+1
    adc #>$5555
    sta rom_unlock.address+1
    lda rom_detect_address+2
    adc #0
    sta rom_unlock.address+2
    lda rom_detect_address+3
    adc #0
    sta rom_unlock.address+3
    // [1123] call rom_unlock
    // [2406] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [2406] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbum1=vbuc1 
    lda #$f0
    sta rom_unlock.unlock_code
    // [2406] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [1124] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [1125] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z rom_detect__14
    // [1126] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z rom_detect__14
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [1127] gotoxy::x#30 = rom_detect::$9 + $28 -- vbum1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta gotoxy.x
    // [1128] call gotoxy
    // [801] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [801] phi gotoxy::y#37 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = gotoxy::x#30 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [1129] printf_uchar::uvalue#14 = rom_device_ids[rom_detect::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta printf_uchar.uvalue
    // [1130] call printf_uchar
    // [1346] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#14 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [1131] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip
    lda rom_device_ids,y
    cmp #$b5
    bne !__b3+
    jmp __b3
  !__b3:
    // rom_detect::@9
    // case SST39SF020A:
    //             rom_device_names[rom_chip] = "f020a";
    //             rom_size_strings[rom_chip] = "256";
    //             rom_sizes[rom_chip] = 256 * 1024;
    //             break;
    // [1132] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b6
    bne !__b4+
    jmp __b4
  !__b4:
    // rom_detect::@10
    // case SST39SF040:
    //             rom_device_names[rom_chip] = "f040";
    //             rom_size_strings[rom_chip] = "512";
    //             rom_sizes[rom_chip] = 512 * 1024;
    //             break;
    // [1133] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [1134] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [1135] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [1136] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [1137] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [1138] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [1139] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [1140] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [1141] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [1105] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [1105] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [1105] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [1142] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [1143] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [1144] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [1145] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$200*$400
    sta rom_sizes,y
    lda #>$200*$400
    sta rom_sizes+1,y
    lda #<$200*$400>>$10
    sta rom_sizes+2,y
    lda #>$200*$400>>$10
    sta rom_sizes+3,y
    jmp __b7
    // rom_detect::@4
  __b4:
    // rom_device_names[rom_chip] = "f020a"
    // [1146] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [1147] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [1148] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [1149] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$100*$400
    sta rom_sizes,y
    lda #>$100*$400
    sta rom_sizes+1,y
    lda #<$100*$400>>$10
    sta rom_sizes+2,y
    lda #>$100*$400>>$10
    sta rom_sizes+3,y
    jmp __b7
    // rom_detect::@3
  __b3:
    // rom_device_names[rom_chip] = "f010a"
    // [1150] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [1151] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [1152] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [1153] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
    tay
    lda #<$80*$400
    sta rom_sizes,y
    lda #>$80*$400
    sta rom_sizes+1,y
    lda #<$80*$400>>$10
    sta rom_sizes+2,y
    lda #>$80*$400>>$10
    sta rom_sizes+3,y
    jmp __b7
  .segment Data
    rom_detect__25: .text "f010a"
    .byte 0
    rom_detect__26: .text "128"
    .byte 0
    rom_detect__27: .text "f020a"
    .byte 0
    rom_detect__28: .text "256"
    .byte 0
    rom_detect__29: .text "f040"
    .byte 0
    rom_detect__30: .text "512"
    .byte 0
    rom_detect__31: .text "----"
    .byte 0
    rom_detect__32: .text "000"
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
    .label fp = $c7
    .label smc_bram_ptr = $4e
    .label smc_action_text = $4b
    // if(info_status == STATUS_READING)
    // [1155] if(smc_read::info_status#10==STATUS_READING) goto smc_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [1157] phi from smc_read to smc_read::@2 [phi:smc_read->smc_read::@2]
    // [1157] phi smc_read::smc_action_text#12 = smc_action_text#2 [phi:smc_read->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z smc_action_text
    lda #>smc_action_text_1
    sta.z smc_action_text+1
    jmp __b2
    // [1156] phi from smc_read to smc_read::@1 [phi:smc_read->smc_read::@1]
    // smc_read::@1
  __b1:
    // [1157] phi from smc_read::@1 to smc_read::@2 [phi:smc_read::@1->smc_read::@2]
    // [1157] phi smc_read::smc_action_text#12 = smc_action_text#1 [phi:smc_read::@1->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z smc_action_text
    lda #>smc_action_text
    sta.z smc_action_text+1
    // smc_read::@2
  __b2:
    // smc_read::bank_set_bram1
    // BRAM = bank
    // [1158] BRAM = smc_read::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1159] phi from smc_read::bank_set_bram1 to smc_read::@16 [phi:smc_read::bank_set_bram1->smc_read::@16]
    // smc_read::@16
    // textcolor(WHITE)
    // [1160] call textcolor
    // [783] phi from smc_read::@16 to textcolor [phi:smc_read::@16->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:smc_read::@16->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1161] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // gotoxy(x, y)
    // [1162] call gotoxy
    // [801] phi from smc_read::@17 to gotoxy [phi:smc_read::@17->gotoxy]
    // [801] phi gotoxy::y#37 = PROGRESS_Y [phi:smc_read::@17->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:smc_read::@17->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1163] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1164] call fopen
    // [2428] phi from smc_read::@18 to fopen [phi:smc_read::@18->fopen]
    // [2428] phi __errno#467 = __errno#102 [phi:smc_read::@18->fopen#0] -- register_copy 
    // [2428] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@18->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2428] phi __stdio_filecount#27 = __stdio_filecount#128 [phi:smc_read::@18->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1165] fopen::return#4 = fopen::return#2
    // smc_read::@19
    // [1166] smc_read::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1167] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@3 -- pssc1_eq_pssz1_then_la1 
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
    // [1168] fgets::stream#1 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1169] call fgets
    // [2509] phi from smc_read::@4 to fgets [phi:smc_read::@4->fgets]
    // [2509] phi fgets::ptr#14 = smc_file_header [phi:smc_read::@4->fgets#0] -- pbuz1=pbuc1 
    lda #<smc_file_header
    sta.z fgets.ptr
    lda #>smc_file_header
    sta.z fgets.ptr+1
    // [2509] phi fgets::size#10 = $20 [phi:smc_read::@4->fgets#1] -- vwum1=vbuc1 
    lda #<$20
    sta fgets.size
    lda #>$20
    sta fgets.size+1
    // [2509] phi fgets::stream#4 = fgets::stream#1 [phi:smc_read::@4->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_file_header, 32, fp)
    // [1170] fgets::return#11 = fgets::return#1
    // smc_read::@20
    // smc_file_read = fgets(smc_file_header, 32, fp)
    // [1171] smc_read::smc_file_read#1 = fgets::return#11
    // if(smc_file_read)
    // [1172] if(0==smc_read::smc_file_read#1) goto smc_read::@3 -- 0_eq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    beq __b5
    // smc_read::@5
    // if(info_status == STATUS_CHECKING)
    // [1173] if(smc_read::info_status#10!=STATUS_CHECKING) goto smc_read::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b4
    // [1174] phi from smc_read::@5 to smc_read::@6 [phi:smc_read::@5->smc_read::@6]
    // smc_read::@6
    // [1175] phi from smc_read::@6 to smc_read::@7 [phi:smc_read::@6->smc_read::@7]
    // [1175] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@6->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1175] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@6->smc_read::@7#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1175] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@6->smc_read::@7#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [1175] phi smc_read::smc_bram_ptr#10 = (char *) 1024 [phi:smc_read::@6->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    jmp __b7
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // [1175] phi from smc_read::@5 to smc_read::@7 [phi:smc_read::@5->smc_read::@7]
  __b4:
    // [1175] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@5->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1175] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@5->smc_read::@7#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1175] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@5->smc_read::@7#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [1175] phi smc_read::smc_bram_ptr#10 = (char *)$a000 [phi:smc_read::@5->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // smc_read::@7
  __b7:
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1176] fgets::ptr#4 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z fgets.ptr
    lda.z smc_bram_ptr+1
    sta.z fgets.ptr+1
    // [1177] fgets::stream#2 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1178] call fgets
    // [2509] phi from smc_read::@7 to fgets [phi:smc_read::@7->fgets]
    // [2509] phi fgets::ptr#14 = fgets::ptr#4 [phi:smc_read::@7->fgets#0] -- register_copy 
    // [2509] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@7->fgets#1] -- vwum1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta fgets.size
    lda #>SMC_PROGRESS_CELL
    sta fgets.size+1
    // [2509] phi fgets::stream#4 = fgets::stream#2 [phi:smc_read::@7->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1179] fgets::return#12 = fgets::return#1
    // smc_read::@21
    // smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1180] smc_read::smc_file_read#10 = fgets::return#12
    // while (smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp))
    // [1181] if(0!=smc_read::smc_file_read#10) goto smc_read::@8 -- 0_neq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    bne __b8
    // smc_read::@9
    // fclose(fp)
    // [1182] fclose::stream#1 = smc_read::fp#0
    // [1183] call fclose
    // [2563] phi from smc_read::@9 to fclose [phi:smc_read::@9->fclose]
    // [2563] phi fclose::stream#3 = fclose::stream#1 [phi:smc_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [1184] phi from smc_read::@9 to smc_read::@3 [phi:smc_read::@9->smc_read::@3]
    // [1184] phi __stdio_filecount#39 = __stdio_filecount#2 [phi:smc_read::@9->smc_read::@3#0] -- register_copy 
    // [1184] phi smc_read::return#0 = smc_read::smc_file_size#10 [phi:smc_read::@9->smc_read::@3#1] -- register_copy 
    rts
    // [1184] phi from smc_read::@19 smc_read::@20 to smc_read::@3 [phi:smc_read::@19/smc_read::@20->smc_read::@3]
  __b5:
    // [1184] phi __stdio_filecount#39 = __stdio_filecount#1 [phi:smc_read::@19/smc_read::@20->smc_read::@3#0] -- register_copy 
    // [1184] phi smc_read::return#0 = 0 [phi:smc_read::@19/smc_read::@20->smc_read::@3#1] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@3
    // smc_read::@return
    // }
    // [1185] return 
    rts
    // smc_read::@8
  __b8:
    // display_action_text_reading(smc_action_text, "SMC.BIN", smc_file_size, SMC_CHIP_SIZE, smc_bram_bank, smc_bram_ptr)
    // [1186] display_action_text_reading::action#1 = smc_read::smc_action_text#12 -- pbuz1=pbuz2 
    lda.z smc_action_text
    sta.z display_action_text_reading.action
    lda.z smc_action_text+1
    sta.z display_action_text_reading.action+1
    // [1187] display_action_text_reading::bytes#1 = smc_read::smc_file_size#10 -- vdum1=vwum2 
    lda smc_file_size
    sta display_action_text_reading.bytes
    lda smc_file_size+1
    sta display_action_text_reading.bytes+1
    lda #0
    sta display_action_text_reading.bytes+2
    sta display_action_text_reading.bytes+3
    // [1188] display_action_text_reading::bram_ptr#1 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1189] call display_action_text_reading
    // [2592] phi from smc_read::@8 to display_action_text_reading [phi:smc_read::@8->display_action_text_reading]
    // [2592] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#1 [phi:smc_read::@8->display_action_text_reading#0] -- register_copy 
    // [2592] phi display_action_text_reading::bram_bank#10 = smc_read::smc_bram_bank [phi:smc_read::@8->display_action_text_reading#1] -- vbum1=vbuc1 
    lda #smc_bram_bank
    sta display_action_text_reading.bram_bank
    // [2592] phi display_action_text_reading::size#10 = SMC_CHIP_SIZE [phi:smc_read::@8->display_action_text_reading#2] -- vdum1=vduc1 
    lda #<SMC_CHIP_SIZE
    sta display_action_text_reading.size
    lda #>SMC_CHIP_SIZE
    sta display_action_text_reading.size+1
    lda #<SMC_CHIP_SIZE>>$10
    sta display_action_text_reading.size+2
    lda #>SMC_CHIP_SIZE>>$10
    sta display_action_text_reading.size+3
    // [2592] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#1 [phi:smc_read::@8->display_action_text_reading#3] -- register_copy 
    // [2592] phi display_action_text_reading::file#3 = smc_read::path [phi:smc_read::@8->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2592] phi display_action_text_reading::action#3 = display_action_text_reading::action#1 [phi:smc_read::@8->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // smc_read::@22
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1190] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b10
    lda progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b10
    // smc_read::@13
    // gotoxy(x, ++y);
    // [1191] smc_read::y#1 = ++ smc_read::y#12 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1192] gotoxy::y#27 = smc_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1193] call gotoxy
    // [801] phi from smc_read::@13 to gotoxy [phi:smc_read::@13->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#27 [phi:smc_read::@13->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:smc_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1194] phi from smc_read::@13 to smc_read::@10 [phi:smc_read::@13->smc_read::@10]
    // [1194] phi smc_read::y#13 = smc_read::y#1 [phi:smc_read::@13->smc_read::@10#0] -- register_copy 
    // [1194] phi smc_read::progress_row_bytes#11 = 0 [phi:smc_read::@13->smc_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1194] phi from smc_read::@22 to smc_read::@10 [phi:smc_read::@22->smc_read::@10]
    // [1194] phi smc_read::y#13 = smc_read::y#12 [phi:smc_read::@22->smc_read::@10#0] -- register_copy 
    // [1194] phi smc_read::progress_row_bytes#11 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@10#1] -- register_copy 
    // smc_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [1195] if(smc_read::info_status#10!=STATUS_READING) goto smc_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // smc_read::@14
    // cputc('.')
    // [1196] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1197] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_read::@11
  __b11:
    // if(info_status == STATUS_CHECKING)
    // [1199] if(smc_read::info_status#10==STATUS_CHECKING) goto smc_read::@12 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    beq __b6
    // smc_read::@15
    // smc_bram_ptr += smc_file_read
    // [1200] smc_read::smc_bram_ptr#3 = smc_read::smc_bram_ptr#10 + smc_read::smc_file_read#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z smc_bram_ptr
    adc smc_file_read
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    adc smc_file_read+1
    sta.z smc_bram_ptr+1
    // [1201] phi from smc_read::@15 to smc_read::@12 [phi:smc_read::@15->smc_read::@12]
    // [1201] phi smc_read::smc_bram_ptr#7 = smc_read::smc_bram_ptr#3 [phi:smc_read::@15->smc_read::@12#0] -- register_copy 
    jmp __b12
    // [1201] phi from smc_read::@11 to smc_read::@12 [phi:smc_read::@11->smc_read::@12]
  __b6:
    // [1201] phi smc_read::smc_bram_ptr#7 = (char *) 1024 [phi:smc_read::@11->smc_read::@12#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    // smc_read::@12
  __b12:
    // smc_file_size += smc_file_read
    // [1202] smc_read::smc_file_size#1 = smc_read::smc_file_size#10 + smc_read::smc_file_read#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda smc_file_size
    adc smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1203] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#11 + smc_read::smc_file_read#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_bytes
    adc smc_file_read
    sta progress_row_bytes
    lda progress_row_bytes+1
    adc smc_file_read+1
    sta progress_row_bytes+1
    // [1175] phi from smc_read::@12 to smc_read::@7 [phi:smc_read::@12->smc_read::@7]
    // [1175] phi smc_read::y#12 = smc_read::y#13 [phi:smc_read::@12->smc_read::@7#0] -- register_copy 
    // [1175] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@12->smc_read::@7#1] -- register_copy 
    // [1175] phi smc_read::smc_file_size#10 = smc_read::smc_file_size#1 [phi:smc_read::@12->smc_read::@7#2] -- register_copy 
    // [1175] phi smc_read::smc_bram_ptr#10 = smc_read::smc_bram_ptr#7 [phi:smc_read::@12->smc_read::@7#3] -- register_copy 
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
// void snprintf_init(__zp($47) char *s, unsigned int n)
snprintf_init: {
    .label s = $47
    // __snprintf_capacity = n
    // [1205] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [1206] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [1207] __snprintf_buffer = snprintf_init::s#31 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [1208] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($43) void (*putc)(char), __zp($50) const char *s)
printf_str: {
    .label s = $50
    .label putc = $43
    // [1210] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [1210] phi printf_str::s#83 = printf_str::s#84 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [1211] printf_str::c#1 = *printf_str::s#83 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1212] printf_str::s#0 = ++ printf_str::s#83 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1213] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [1214] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [1215] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1216] callexecute *printf_str::putc#84  -- call__deref_pprz1 
    jsr icall15
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall15:
    jmp (putc)
  .segment Data
    c: .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($3a) void (*putc)(char), __zp($50) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $31
    .label str = $50
    .label str_1 = $b6
    .label putc = $3a
    // if(format.min_length)
    // [1219] if(0==printf_string::format_min_length#26) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1220] strlen::str#3 = printf_string::str#26 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1221] call strlen
    // [2623] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2623] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1222] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1223] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1224] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1225] printf_string::padding#1 = (signed char)printf_string::format_min_length#26 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1226] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1228] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1228] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1227] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1228] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1228] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1229] if(0!=printf_string::format_justify_left#26) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1230] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1231] printf_padding::putc#3 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1232] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1233] call printf_padding
    // [2629] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2629] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2629] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2629] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1234] printf_str::putc#1 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1235] printf_str::s#2 = printf_string::str#26
    // [1236] call printf_str
    // [1209] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [1209] phi printf_str::putc#84 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [1209] phi printf_str::s#84 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1237] if(0==printf_string::format_justify_left#26) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1238] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1239] printf_padding::putc#4 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1240] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1241] call printf_padding
    // [2629] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2629] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2629] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2629] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1242] return 
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
    .label vera_bytes_read = $d5
    // display_action_progress("Checking VERA.BIN ...")
    // [1244] call display_action_progress
    // [903] phi from main_vera_check to display_action_progress [phi:main_vera_check->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main_vera_check::info_text [phi:main_vera_check->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1245] phi from main_vera_check to main_vera_check::@4 [phi:main_vera_check->main_vera_check::@4]
    // main_vera_check::@4
    // unsigned long vera_bytes_read = vera_read(STATUS_CHECKING)
    // [1246] call vera_read
  // Read the VERA.BIN file.
    // [2637] phi from main_vera_check::@4 to vera_read [phi:main_vera_check::@4->vera_read]
    // [2637] phi __errno#100 = __errno#113 [phi:main_vera_check::@4->vera_read#0] -- register_copy 
    // [2637] phi __stdio_filecount#123 = __stdio_filecount#109 [phi:main_vera_check::@4->vera_read#1] -- register_copy 
    // [2637] phi vera_read::info_status#12 = STATUS_CHECKING [phi:main_vera_check::@4->vera_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta vera_read.info_status
    jsr vera_read
    // unsigned long vera_bytes_read = vera_read(STATUS_CHECKING)
    // [1247] vera_read::return#2 = vera_read::return#0
    // main_vera_check::@5
    // [1248] main_vera_check::vera_bytes_read#0 = vera_read::return#2 -- vduz1=vdum2 
    lda vera_read.return
    sta.z vera_bytes_read
    lda vera_read.return+1
    sta.z vera_bytes_read+1
    lda vera_read.return+2
    sta.z vera_bytes_read+2
    lda vera_read.return+3
    sta.z vera_bytes_read+3
    // wait_moment(10)
    // [1249] call wait_moment
    // [1309] phi from main_vera_check::@5 to wait_moment [phi:main_vera_check::@5->wait_moment]
    // [1309] phi wait_moment::w#13 = $a [phi:main_vera_check::@5->wait_moment#0] -- vbum1=vbuc1 
    lda #$a
    sta wait_moment.w
    jsr wait_moment
    // main_vera_check::@6
    // if (!vera_bytes_read)
    // [1250] if(0==main_vera_check::vera_bytes_read#0) goto main_vera_check::@1 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    beq __b1
    // main_vera_check::@3
    // vera_file_size = vera_bytes_read
    // [1251] vera_file_size#0 = main_vera_check::vera_bytes_read#0 -- vdum1=vduz2 
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
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1252] call snprintf_init
    // [1204] phi from main_vera_check::@3 to snprintf_init [phi:main_vera_check::@3->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main_vera_check::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1253] phi from main_vera_check::@3 to main_vera_check::@7 [phi:main_vera_check::@3->main_vera_check::@7]
    // main_vera_check::@7
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1254] call printf_str
    // [1209] phi from main_vera_check::@7 to printf_str [phi:main_vera_check::@7->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main_vera_check::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main_vera_check::s [phi:main_vera_check::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [1255] phi from main_vera_check::@7 to main_vera_check::@8 [phi:main_vera_check::@7->main_vera_check::@8]
    // main_vera_check::@8
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1256] call printf_string
    // [1218] phi from main_vera_check::@8 to printf_string [phi:main_vera_check::@8->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:main_vera_check::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = str [phi:main_vera_check::@8->printf_string#1] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:main_vera_check::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:main_vera_check::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main_vera_check::@9
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1257] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1258] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1260] spi_manufacturer#588 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1261] spi_memory_type#589 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1262] spi_memory_capacity#590 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASH, info_text)
    // [1263] call display_info_vera
    // [997] phi from main_vera_check::@9 to display_info_vera [phi:main_vera_check::@9->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = info_text [phi:main_vera_check::@9->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#590 [phi:main_vera_check::@9->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#589 [phi:main_vera_check::@9->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#588 [phi:main_vera_check::@9->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_FLASH [phi:main_vera_check::@9->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1264] phi from main_vera_check::@9 to main_vera_check::@2 [phi:main_vera_check::@9->main_vera_check::@2]
    // [1264] phi vera_file_size#1 = vera_file_size#0 [phi:main_vera_check::@9->main_vera_check::@2#0] -- register_copy 
    // main_vera_check::@2
    // main_vera_check::@return
    // }
    // [1265] return 
    rts
    // main_vera_check::@1
  __b1:
    // [1266] spi_manufacturer#587 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1267] spi_memory_type#588 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1268] spi_memory_capacity#589 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "No VERA.BIN")
    // [1269] call display_info_vera
  // VF1 | no VERA.BIN  | Ask the user to place the VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // VF2 | VERA.BIN size 0 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // TODO: VF4 | ROM.BIN size over 0x20000 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
    // [997] phi from main_vera_check::@1 to display_info_vera [phi:main_vera_check::@1->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = main_vera_check::info_text1 [phi:main_vera_check::@1->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#589 [phi:main_vera_check::@1->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#588 [phi:main_vera_check::@1->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#587 [phi:main_vera_check::@1->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main_vera_check::@1->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1264] phi from main_vera_check::@1 to main_vera_check::@2 [phi:main_vera_check::@1->main_vera_check::@2]
    // [1264] phi vera_file_size#1 = 0 [phi:main_vera_check::@1->main_vera_check::@2#0] -- vdum1=vduc1 
    lda #<0
    sta vera_file_size
    sta vera_file_size+1
    lda #<0>>$10
    sta vera_file_size+2
    lda #>0>>$10
    sta vera_file_size+3
    rts
  .segment DataVera
    info_text: .text "Checking VERA.BIN ..."
    .byte 0
    info_text1: .text "No VERA.BIN"
    .byte 0
    s: .text "VERA.BIN:"
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
    // [1271] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [1271] phi smc_supported_rom::i#2 = $1f [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbum1=vbuc1 
    lda #$1f
    sta i
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=31; i>3; i--)
    // [1272] if(smc_supported_rom::i#2>=3+1) goto smc_supported_rom::@2 -- vbum1_ge_vbuc1_then_la1 
    lda i
    cmp #3+1
    bcs __b2
    // [1274] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [1274] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_file_header[i] == rom_release)
    // [1273] if(smc_file_header[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbum1_neq_vbum2_then_la1 
    lda rom_release
    ldy i
    cmp smc_file_header,y
    bne __b3
    // [1274] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [1274] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // smc_supported_rom::@return
    // }
    // [1275] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=31; i>3; i--)
    // [1276] smc_supported_rom::i#1 = -- smc_supported_rom::i#2 -- vbum1=_dec_vbum1 
    dec i
    // [1271] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [1271] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
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
    .label check_status_rom1_check_status_roms__0 = $42
    // [1278] phi from check_status_roms to check_status_roms::@1 [phi:check_status_roms->check_status_roms::@1]
    // [1278] phi check_status_roms::rom_chip#2 = 0 [phi:check_status_roms->check_status_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1279] if(check_status_roms::rom_chip#2<8) goto check_status_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1280] phi from check_status_roms::@1 to check_status_roms::@return [phi:check_status_roms::@1->check_status_roms::@return]
    // [1280] phi check_status_roms::return#2 = 0 [phi:check_status_roms::@1->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_roms::@return
    // }
    // [1281] return 
    rts
    // check_status_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1282] check_status_roms::check_status_rom1_$0 = status_rom[check_status_roms::rom_chip#2] == check_status_roms::status#6 -- vboz1=pbuc1_derefidx_vbum2_eq_vbum3 
    lda status
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1283] check_status_roms::check_status_rom1_return#0 = (char)check_status_roms::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1284] if(0==check_status_roms::check_status_rom1_return#0) goto check_status_roms::@2 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [1280] phi from check_status_roms::@3 to check_status_roms::@return [phi:check_status_roms::@3->check_status_roms::@return]
    // [1280] phi check_status_roms::return#2 = 1 [phi:check_status_roms::@3->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_roms::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1285] check_status_roms::rom_chip#1 = ++ check_status_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1278] phi from check_status_roms::@2 to check_status_roms::@1 [phi:check_status_roms::@2->check_status_roms::@1]
    // [1278] phi check_status_roms::rom_chip#2 = check_status_roms::rom_chip#1 [phi:check_status_roms::@2->check_status_roms::@1#0] -- register_copy 
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
    .label clrscr__0 = $70
    .label clrscr__1 = $41
    .label clrscr__2 = $7f
    // unsigned int line_text = __conio.mapbase_offset
    // [1286] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1287] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1288] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1289] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1290] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1291] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1291] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1291] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1292] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1293] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1294] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1295] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1296] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1297] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1297] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1298] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1299] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1300] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1301] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1302] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1303] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1304] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1305] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1306] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1307] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1308] return 
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
    // [1310] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1310] phi wait_moment::j#2 = 0 [phi:wait_moment->wait_moment::@1#0] -- vbum1=vbuc1 
    lda #0
    sta j
    // wait_moment::@1
  __b1:
    // for(unsigned char j=0; j<w; j++)
    // [1311] if(wait_moment::j#2<wait_moment::w#13) goto wait_moment::@2 -- vbum1_lt_vbum2_then_la1 
    lda j
    cmp w
    bcc __b4
    // wait_moment::@return
    // }
    // [1312] return 
    rts
    // [1313] phi from wait_moment::@1 to wait_moment::@2 [phi:wait_moment::@1->wait_moment::@2]
  __b4:
    // [1313] phi wait_moment::i#2 = $ffff [phi:wait_moment::@1->wait_moment::@2#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta i
    lda #>$ffff
    sta i+1
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1314] if(wait_moment::i#2>0) goto wait_moment::@3 -- vwum1_gt_0_then_la1 
    lda i+1
    bne __b3
    lda i
    bne __b3
  !:
    // wait_moment::@4
    // for(unsigned char j=0; j<w; j++)
    // [1315] wait_moment::j#1 = ++ wait_moment::j#2 -- vbum1=_inc_vbum1 
    inc j
    // [1310] phi from wait_moment::@4 to wait_moment::@1 [phi:wait_moment::@4->wait_moment::@1]
    // [1310] phi wait_moment::j#2 = wait_moment::j#1 [phi:wait_moment::@4->wait_moment::@1#0] -- register_copy 
    jmp __b1
    // wait_moment::@3
  __b3:
    // for(unsigned int i=65535; i>0; i--)
    // [1316] wait_moment::i#1 = -- wait_moment::i#2 -- vwum1=_dec_vwum1 
    lda i
    bne !+
    dec i+1
  !:
    dec i
    // [1313] phi from wait_moment::@3 to wait_moment::@2 [phi:wait_moment::@3->wait_moment::@2]
    // [1313] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@3->wait_moment::@2#0] -- register_copy 
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
    // [1318] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1319] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1321] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    .label check_status_rom1_check_status_roms_less__0 = $c6
    // [1323] phi from check_status_roms_less to check_status_roms_less::@1 [phi:check_status_roms_less->check_status_roms_less::@1]
    // [1323] phi check_status_roms_less::rom_chip#2 = 0 [phi:check_status_roms_less->check_status_roms_less::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms_less::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1324] if(check_status_roms_less::rom_chip#2<8) goto check_status_roms_less::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1325] phi from check_status_roms_less::@1 to check_status_roms_less::@return [phi:check_status_roms_less::@1->check_status_roms_less::@return]
    // [1325] phi check_status_roms_less::return#2 = 1 [phi:check_status_roms_less::@1->check_status_roms_less::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // check_status_roms_less::@return
    // }
    // [1326] return 
    rts
    // check_status_roms_less::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1327] check_status_roms_less::check_status_rom1_$0 = status_rom[check_status_roms_less::rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms_less__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1328] check_status_roms_less::check_status_rom1_return#0 = (char)check_status_roms_less::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_roms_less::@3
    // if(check_status_rom(rom_chip, status) > status)
    // [1329] if(check_status_roms_less::check_status_rom1_return#0<STATUS_SKIP+1) goto check_status_roms_less::@2 -- vbum1_lt_vbuc1_then_la1 
    cmp #STATUS_SKIP+1
    bcc __b2
    // [1325] phi from check_status_roms_less::@3 to check_status_roms_less::@return [phi:check_status_roms_less::@3->check_status_roms_less::@return]
    // [1325] phi check_status_roms_less::return#2 = 0 [phi:check_status_roms_less::@3->check_status_roms_less::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // check_status_roms_less::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1330] check_status_roms_less::rom_chip#1 = ++ check_status_roms_less::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1323] phi from check_status_roms_less::@2 to check_status_roms_less::@1 [phi:check_status_roms_less::@2->check_status_roms_less::@1]
    // [1323] phi check_status_roms_less::rom_chip#2 = check_status_roms_less::rom_chip#1 [phi:check_status_roms_less::@2->check_status_roms_less::@1#0] -- register_copy 
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
// void display_progress_text(__zp($43) char **text, __mem() char lines)
display_progress_text: {
    .label display_progress_text__3 = $65
    .label text = $43
    // display_progress_clear()
    // [1332] call display_progress_clear
    // [917] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [1333] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [1333] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [1334] if(display_progress_text::l#2<display_progress_text::lines#12) goto display_progress_text::@2 -- vbum1_lt_vbum2_then_la1 
    lda l
    cmp lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [1335] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [1336] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbum2_rol_1 
    lda l
    asl
    sta.z display_progress_text__3
    // [1337] display_progress_line::line#0 = display_progress_text::l#2 -- vbum1=vbum2 
    lda l
    sta display_progress_line.line
    // [1338] display_progress_line::text#0 = display_progress_text::text#13[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [1339] call display_progress_line
    // [1341] phi from display_progress_text::@2 to display_progress_line [phi:display_progress_text::@2->display_progress_line]
    // [1341] phi display_progress_line::text#3 = display_progress_line::text#0 [phi:display_progress_text::@2->display_progress_line#0] -- register_copy 
    // [1341] phi display_progress_line::line#3 = display_progress_line::line#0 [phi:display_progress_text::@2->display_progress_line#1] -- register_copy 
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [1340] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [1333] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [1333] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
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
// void display_progress_line(__mem() char line, __zp($5d) char *text)
display_progress_line: {
    .label text = $5d
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1342] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#3 -- vbum1=vbuc1_plus_vbum1 
    lda #PROGRESS_Y
    clc
    adc cputsxy.y
    sta cputsxy.y
    // [1343] cputsxy::s#0 = display_progress_line::text#3
    // [1344] call cputsxy
    // [896] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [896] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [896] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [896] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1345] return 
    rts
  .segment Data
    .label line = cputsxy.y
}
.segment Code
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($43) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $43
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1347] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1348] uctoa::value#1 = printf_uchar::uvalue#18
    // [1349] uctoa::radix#0 = printf_uchar::format_radix#18
    // [1350] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1351] printf_number_buffer::putc#2 = printf_uchar::putc#18
    // [1352] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1353] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#18
    // [1354] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#18
    // [1355] call printf_number_buffer
  // Print using format
    // [2718] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [2718] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [2718] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [2718] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [2718] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1356] return 
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
// void display_action_text(__zp($3a) char *info_text)
display_action_text: {
    .label info_text = $3a
    // unsigned char x = wherex()
    // [1358] call wherex
    jsr wherex
    // [1359] wherex::return#3 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_1
    // display_action_text::@1
    // [1360] display_action_text::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [1361] call wherey
    jsr wherey
    // [1362] wherey::return#3 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_1
    // display_action_text::@2
    // [1363] display_action_text::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [1364] call gotoxy
    // [801] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [801] phi gotoxy::y#37 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1365] printf_string::str#2 = display_action_text::info_text#25 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1366] call printf_string
    // [1218] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1367] gotoxy::x#16 = display_action_text::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1368] gotoxy::y#16 = display_action_text::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1369] call gotoxy
    // [801] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#16 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#16 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1370] return 
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
    // [1372] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1373] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@1
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1374] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1375] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1376] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1377] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1379] return 
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
    .label check_status_rom1_check_status_card_roms__0 = $5a
    // [1381] phi from check_status_card_roms to check_status_card_roms::@1 [phi:check_status_card_roms->check_status_card_roms::@1]
    // [1381] phi check_status_card_roms::rom_chip#2 = 1 [phi:check_status_card_roms->check_status_card_roms::@1#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip
    // check_status_card_roms::@1
  __b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1382] if(check_status_card_roms::rom_chip#2<8) goto check_status_card_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1383] phi from check_status_card_roms::@1 to check_status_card_roms::@return [phi:check_status_card_roms::@1->check_status_card_roms::@return]
    // [1383] phi check_status_card_roms::return#2 = 0 [phi:check_status_card_roms::@1->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_card_roms::@return
    // }
    // [1384] return 
    rts
    // check_status_card_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1385] check_status_card_roms::check_status_rom1_$0 = status_rom[check_status_card_roms::rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_card_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1386] check_status_card_roms::check_status_rom1_return#0 = (char)check_status_card_roms::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_card_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1387] if(0==check_status_card_roms::check_status_rom1_return#0) goto check_status_card_roms::@2 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [1383] phi from check_status_card_roms::@3 to check_status_card_roms::@return [phi:check_status_card_roms::@3->check_status_card_roms::@return]
    // [1383] phi check_status_card_roms::return#2 = 1 [phi:check_status_card_roms::@3->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_card_roms::@2
  __b2:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1388] check_status_card_roms::rom_chip#1 = ++ check_status_card_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1381] phi from check_status_card_roms::@2 to check_status_card_roms::@1 [phi:check_status_card_roms::@2->check_status_card_roms::@1]
    // [1381] phi check_status_card_roms::rom_chip#2 = check_status_card_roms::rom_chip#1 [phi:check_status_card_roms::@2->check_status_card_roms::@1#0] -- register_copy 
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
    // [1390] call util_wait_key
    // [2011] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [2011] phi util_wait_key::filter#13 = s4 [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s4
    sta.z util_wait_key.filter
    lda #>s4
    sta.z util_wait_key.filter+1
    // [2011] phi util_wait_key::info_text#3 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [1391] return 
    rts
  .segment Data
    info_text: .text "Press [SPACE] to continue ..."
    .byte 0
}
.segment CodeVera
  // main_vera_flash
main_vera_flash: {
    .label vera_bytes_read = $d5
    .label spi_ensure_detect = $ce
    .label vera_erase_error = $e9
    .label vera_differences1 = $f4
    .label spi_ensure_detect_1 = $cf
    // display_progress_clear()
    // [1393] call display_progress_clear
    // [917] phi from main_vera_flash to display_progress_clear [phi:main_vera_flash->display_progress_clear]
    jsr display_progress_clear
    // [1394] phi from main_vera_flash to main_vera_flash::@20 [phi:main_vera_flash->main_vera_flash::@20]
    // main_vera_flash::@20
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1395] call snprintf_init
    // [1204] phi from main_vera_flash::@20 to snprintf_init [phi:main_vera_flash::@20->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main_vera_flash::@20->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1396] phi from main_vera_flash::@20 to main_vera_flash::@21 [phi:main_vera_flash::@20->main_vera_flash::@21]
    // main_vera_flash::@21
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1397] call printf_str
    // [1209] phi from main_vera_flash::@21 to printf_str [phi:main_vera_flash::@21->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main_vera_flash::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main_vera_flash::s [phi:main_vera_flash::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@22
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1398] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1399] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [1401] call display_action_progress
    // [903] phi from main_vera_flash::@22 to display_action_progress [phi:main_vera_flash::@22->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = info_text [phi:main_vera_flash::@22->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1402] phi from main_vera_flash::@22 to main_vera_flash::@23 [phi:main_vera_flash::@22->main_vera_flash::@23]
    // main_vera_flash::@23
    // unsigned long vera_bytes_read = vera_read(STATUS_READING)
    // [1403] call vera_read
    // [2637] phi from main_vera_flash::@23 to vera_read [phi:main_vera_flash::@23->vera_read]
    // [2637] phi __errno#100 = __errno#115 [phi:main_vera_flash::@23->vera_read#0] -- register_copy 
    // [2637] phi __stdio_filecount#123 = __stdio_filecount#111 [phi:main_vera_flash::@23->vera_read#1] -- register_copy 
    // [2637] phi vera_read::info_status#12 = STATUS_READING [phi:main_vera_flash::@23->vera_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta vera_read.info_status
    jsr vera_read
    // unsigned long vera_bytes_read = vera_read(STATUS_READING)
    // [1404] vera_read::return#3 = vera_read::return#0
    // main_vera_flash::@24
    // [1405] main_vera_flash::vera_bytes_read#0 = vera_read::return#3 -- vduz1=vdum2 
    lda vera_read.return
    sta.z vera_bytes_read
    lda vera_read.return+1
    sta.z vera_bytes_read+1
    lda vera_read.return+2
    sta.z vera_bytes_read+2
    lda vera_read.return+3
    sta.z vera_bytes_read+3
    // if(vera_bytes_read)
    // [1406] if(0==main_vera_flash::vera_bytes_read#0) goto main_vera_flash::@1 -- 0_eq_vduz1_then_la1 
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    bne !__b1+
    jmp __b1
  !__b1:
    // [1407] phi from main_vera_flash::@24 to main_vera_flash::@2 [phi:main_vera_flash::@24->main_vera_flash::@2]
    // main_vera_flash::@2
    // display_action_progress("VERA SPI activation ...")
    // [1408] call display_action_progress
  // Now we loop until jumper JP1 has been placed!
    // [903] phi from main_vera_flash::@2 to display_action_progress [phi:main_vera_flash::@2->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main_vera_flash::info_text [phi:main_vera_flash::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1409] phi from main_vera_flash::@2 to main_vera_flash::@25 [phi:main_vera_flash::@2->main_vera_flash::@25]
    // main_vera_flash::@25
    // display_action_text("Please close the jumper JP1 on the VERA board!")
    // [1410] call display_action_text
    // [1357] phi from main_vera_flash::@25 to display_action_text [phi:main_vera_flash::@25->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main_vera_flash::info_text1 [phi:main_vera_flash::@25->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_text.info_text
    lda #>info_text1
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1411] phi from main_vera_flash::@25 to main_vera_flash::@26 [phi:main_vera_flash::@25->main_vera_flash::@26]
    // main_vera_flash::@26
    // vera_detect()
    // [1412] call vera_detect
    // [2403] phi from main_vera_flash::@26 to vera_detect [phi:main_vera_flash::@26->vera_detect]
    jsr vera_detect
    // [1413] phi from main_vera_flash::@26 main_vera_flash::@7 to main_vera_flash::@3 [phi:main_vera_flash::@26/main_vera_flash::@7->main_vera_flash::@3]
  __b2:
    // [1413] phi main_vera_flash::spi_ensure_detect#11 = 0 [phi:main_vera_flash::@26/main_vera_flash::@7->main_vera_flash::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z spi_ensure_detect
    // main_vera_flash::@3
  __b3:
    // while(spi_ensure_detect < 16)
    // [1414] if(main_vera_flash::spi_ensure_detect#11<$10) goto main_vera_flash::@4 -- vbuz1_lt_vbuc1_then_la1 
    lda.z spi_ensure_detect
    cmp #$10
    bcs !__b4+
    jmp __b4
  !__b4:
    // [1415] phi from main_vera_flash::@3 to main_vera_flash::@5 [phi:main_vera_flash::@3->main_vera_flash::@5]
    // main_vera_flash::@5
    // display_action_text("The jumper JP1 has been closed on the VERA!")
    // [1416] call display_action_text
    // [1357] phi from main_vera_flash::@5 to display_action_text [phi:main_vera_flash::@5->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main_vera_flash::info_text2 [phi:main_vera_flash::@5->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1417] phi from main_vera_flash::@5 to main_vera_flash::@29 [phi:main_vera_flash::@5->main_vera_flash::@29]
    // main_vera_flash::@29
    // display_action_progress("Comparing VERA ... (.) data, (=) same, (*) different.")
    // [1418] call display_action_progress
  // Now we compare the RAM with the actual VERA contents.
    // [903] phi from main_vera_flash::@29 to display_action_progress [phi:main_vera_flash::@29->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main_vera_flash::info_text3 [phi:main_vera_flash::@29->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main_vera_flash::@30
    // [1419] spi_manufacturer#594 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1420] spi_memory_type#595 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1421] spi_memory_capacity#596 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_COMPARING, NULL)
    // [1422] call display_info_vera
    // [997] phi from main_vera_flash::@30 to display_info_vera [phi:main_vera_flash::@30->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@30->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#596 [phi:main_vera_flash::@30->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#595 [phi:main_vera_flash::@30->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#594 [phi:main_vera_flash::@30->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_COMPARING [phi:main_vera_flash::@30->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1423] phi from main_vera_flash::@30 to main_vera_flash::@31 [phi:main_vera_flash::@30->main_vera_flash::@31]
    // main_vera_flash::@31
    // unsigned long vera_differences = vera_verify()
    // [1424] call vera_verify
  // Verify VERA ...
    // [2749] phi from main_vera_flash::@31 to vera_verify [phi:main_vera_flash::@31->vera_verify]
    jsr vera_verify
    // unsigned long vera_differences = vera_verify()
    // [1425] vera_verify::return#2 = vera_verify::vera_different_bytes#11
    // main_vera_flash::@32
    // [1426] main_vera_flash::vera_differences#0 = vera_verify::return#2 -- vdum1=vdum2 
    lda vera_verify.return
    sta vera_differences
    lda vera_verify.return+1
    sta vera_differences+1
    lda vera_verify.return+2
    sta vera_differences+2
    lda vera_verify.return+3
    sta vera_differences+3
    // if (!vera_differences)
    // [1427] if(0==main_vera_flash::vera_differences#0) goto main_vera_flash::@10 -- 0_eq_vdum1_then_la1 
    lda vera_differences
    ora vera_differences+1
    ora vera_differences+2
    ora vera_differences+3
    bne !__b10+
    jmp __b10
  !__b10:
    // [1428] phi from main_vera_flash::@32 to main_vera_flash::@8 [phi:main_vera_flash::@32->main_vera_flash::@8]
    // main_vera_flash::@8
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1429] call snprintf_init
    // [1204] phi from main_vera_flash::@8 to snprintf_init [phi:main_vera_flash::@8->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main_vera_flash::@8->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@34
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1430] printf_ulong::uvalue#10 = main_vera_flash::vera_differences#0 -- vdum1=vdum2 
    lda vera_differences
    sta printf_ulong.uvalue
    lda vera_differences+1
    sta printf_ulong.uvalue+1
    lda vera_differences+2
    sta printf_ulong.uvalue+2
    lda vera_differences+3
    sta printf_ulong.uvalue+3
    // [1431] call printf_ulong
    // [1753] phi from main_vera_flash::@34 to printf_ulong [phi:main_vera_flash::@34->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:main_vera_flash::@34->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:main_vera_flash::@34->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@34->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#10 [phi:main_vera_flash::@34->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1432] phi from main_vera_flash::@34 to main_vera_flash::@35 [phi:main_vera_flash::@34->main_vera_flash::@35]
    // main_vera_flash::@35
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1433] call printf_str
    // [1209] phi from main_vera_flash::@35 to printf_str [phi:main_vera_flash::@35->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main_vera_flash::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s13 [phi:main_vera_flash::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@36
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1434] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1435] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1437] spi_manufacturer#595 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1438] spi_memory_type#596 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1439] spi_memory_capacity#597 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASH, info_text)
    // [1440] call display_info_vera
    // [997] phi from main_vera_flash::@36 to display_info_vera [phi:main_vera_flash::@36->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@36->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#597 [phi:main_vera_flash::@36->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#596 [phi:main_vera_flash::@36->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#595 [phi:main_vera_flash::@36->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_FLASH [phi:main_vera_flash::@36->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1441] phi from main_vera_flash::@36 to main_vera_flash::@37 [phi:main_vera_flash::@36->main_vera_flash::@37]
    // main_vera_flash::@37
    // unsigned char vera_erase_error = vera_erase()
    // [1442] call vera_erase
    jsr vera_erase
    // [1443] vera_erase::return#3 = vera_erase::return#2
    // main_vera_flash::@38
    // [1444] main_vera_flash::vera_erase_error#0 = vera_erase::return#3 -- vbuz1=vbum2 
    lda vera_erase.return
    sta.z vera_erase_error
    // if(vera_erase_error)
    // [1445] if(0==main_vera_flash::vera_erase_error#0) goto main_vera_flash::@11 -- 0_eq_vbuz1_then_la1 
    beq __b11
    // [1446] phi from main_vera_flash::@38 to main_vera_flash::@9 [phi:main_vera_flash::@38->main_vera_flash::@9]
    // main_vera_flash::@9
    // display_action_progress("There was an error cleaning your VERA flash memory!")
    // [1447] call display_action_progress
    // [903] phi from main_vera_flash::@9 to display_action_progress [phi:main_vera_flash::@9->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main_vera_flash::info_text7 [phi:main_vera_flash::@9->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_action_progress.info_text
    lda #>info_text7
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1448] phi from main_vera_flash::@9 to main_vera_flash::@40 [phi:main_vera_flash::@9->main_vera_flash::@40]
    // main_vera_flash::@40
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [1449] call display_action_text
    // [1357] phi from main_vera_flash::@40 to display_action_text [phi:main_vera_flash::@40->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main_vera_flash::info_text8 [phi:main_vera_flash::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_text.info_text
    lda #>info_text8
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main_vera_flash::@41
    // [1450] spi_manufacturer#596 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1451] spi_memory_type#597 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1452] spi_memory_capacity#598 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_ERROR, "ERASE ERROR!")
    // [1453] call display_info_vera
    // [997] phi from main_vera_flash::@41 to display_info_vera [phi:main_vera_flash::@41->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = main_vera_flash::info_text9 [phi:main_vera_flash::@41->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_vera.info_text
    lda #>info_text9
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#598 [phi:main_vera_flash::@41->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#597 [phi:main_vera_flash::@41->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#596 [phi:main_vera_flash::@41->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_ERROR [phi:main_vera_flash::@41->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@42
    // [1454] smc_bootloader#522 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, NULL)
    // [1455] call display_info_smc
    // [961] phi from main_vera_flash::@42 to display_info_smc [phi:main_vera_flash::@42->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = 0 [phi:main_vera_flash::@42->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#522 [phi:main_vera_flash::@42->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main_vera_flash::@42->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    // [1456] phi from main_vera_flash::@42 to main_vera_flash::@43 [phi:main_vera_flash::@42->main_vera_flash::@43]
    // main_vera_flash::@43
    // display_info_roms(STATUS_ERROR, NULL)
    // [1457] call display_info_roms
    // [2827] phi from main_vera_flash::@43 to display_info_roms [phi:main_vera_flash::@43->display_info_roms]
    jsr display_info_roms
    // [1458] phi from main_vera_flash::@43 to main_vera_flash::@44 [phi:main_vera_flash::@43->main_vera_flash::@44]
    // main_vera_flash::@44
    // wait_moment(32)
    // [1459] call wait_moment
    // [1309] phi from main_vera_flash::@44 to wait_moment [phi:main_vera_flash::@44->wait_moment]
    // [1309] phi wait_moment::w#13 = $20 [phi:main_vera_flash::@44->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [1460] phi from main_vera_flash::@44 to main_vera_flash::@45 [phi:main_vera_flash::@44->main_vera_flash::@45]
    // main_vera_flash::@45
    // spi_deselect()
    // [1461] call spi_deselect
    jsr spi_deselect
    // main_vera_flash::@return
    // }
    // [1462] return 
    rts
    // [1463] phi from main_vera_flash::@38 to main_vera_flash::@11 [phi:main_vera_flash::@38->main_vera_flash::@11]
    // main_vera_flash::@11
  __b11:
    // unsigned long vera_flashed = vera_flash()
    // [1464] call vera_flash
    // [2837] phi from main_vera_flash::@11 to vera_flash [phi:main_vera_flash::@11->vera_flash]
    jsr vera_flash
    // unsigned long vera_flashed = vera_flash()
    // [1465] vera_flash::return#3 = vera_flash::return#2
    // main_vera_flash::@39
    // [1466] main_vera_flash::vera_flashed#0 = vera_flash::return#3 -- vdum1=vdum2 
    lda vera_flash.return
    sta vera_flashed
    lda vera_flash.return+1
    sta vera_flashed+1
    lda vera_flash.return+2
    sta vera_flashed+2
    lda vera_flash.return+3
    sta vera_flashed+3
    // if(vera_flashed)
    // [1467] if(0!=main_vera_flash::vera_flashed#0) goto main_vera_flash::@12 -- 0_neq_vdum1_then_la1 
    lda vera_flashed
    ora vera_flashed+1
    ora vera_flashed+2
    ora vera_flashed+3
    beq !__b12+
    jmp __b12
  !__b12:
    // main_vera_flash::@13
    // [1468] spi_manufacturer#591 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1469] spi_memory_type#592 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1470] spi_memory_capacity#593 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_ERROR, info_text)
    // [1471] call display_info_vera
  // VFL2 | Flash VERA resulting in errors
    // [997] phi from main_vera_flash::@13 to display_info_vera [phi:main_vera_flash::@13->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@13->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#593 [phi:main_vera_flash::@13->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#592 [phi:main_vera_flash::@13->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#591 [phi:main_vera_flash::@13->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_ERROR [phi:main_vera_flash::@13->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1472] phi from main_vera_flash::@13 to main_vera_flash::@54 [phi:main_vera_flash::@13->main_vera_flash::@54]
    // main_vera_flash::@54
    // display_action_progress("There was an error updating your VERA flash memory!")
    // [1473] call display_action_progress
    // [903] phi from main_vera_flash::@54 to display_action_progress [phi:main_vera_flash::@54->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main_vera_flash::info_text10 [phi:main_vera_flash::@54->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1474] phi from main_vera_flash::@54 to main_vera_flash::@55 [phi:main_vera_flash::@54->main_vera_flash::@55]
    // main_vera_flash::@55
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [1475] call display_action_text
    // [1357] phi from main_vera_flash::@55 to display_action_text [phi:main_vera_flash::@55->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main_vera_flash::info_text8 [phi:main_vera_flash::@55->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_text.info_text
    lda #>info_text8
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main_vera_flash::@56
    // [1476] spi_manufacturer#600 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1477] spi_memory_type#601 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1478] spi_memory_capacity#602 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_ERROR, "FLASH ERROR!")
    // [1479] call display_info_vera
    // [997] phi from main_vera_flash::@56 to display_info_vera [phi:main_vera_flash::@56->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = main_vera_flash::info_text12 [phi:main_vera_flash::@56->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_vera.info_text
    lda #>info_text12
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#602 [phi:main_vera_flash::@56->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#601 [phi:main_vera_flash::@56->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#600 [phi:main_vera_flash::@56->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_ERROR [phi:main_vera_flash::@56->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@57
    // [1480] smc_bootloader#523 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, NULL)
    // [1481] call display_info_smc
    // [961] phi from main_vera_flash::@57 to display_info_smc [phi:main_vera_flash::@57->display_info_smc]
    // [961] phi display_info_smc::info_text#20 = 0 [phi:main_vera_flash::@57->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [961] phi smc_bootloader#14 = smc_bootloader#523 [phi:main_vera_flash::@57->display_info_smc#1] -- register_copy 
    // [961] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main_vera_flash::@57->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    // [1482] phi from main_vera_flash::@57 to main_vera_flash::@58 [phi:main_vera_flash::@57->main_vera_flash::@58]
    // main_vera_flash::@58
    // display_info_roms(STATUS_ERROR, NULL)
    // [1483] call display_info_roms
    // [2827] phi from main_vera_flash::@58 to display_info_roms [phi:main_vera_flash::@58->display_info_roms]
    jsr display_info_roms
    // [1484] phi from main_vera_flash::@58 to main_vera_flash::@59 [phi:main_vera_flash::@58->main_vera_flash::@59]
    // main_vera_flash::@59
    // wait_moment(32)
    // [1485] call wait_moment
    // [1309] phi from main_vera_flash::@59 to wait_moment [phi:main_vera_flash::@59->wait_moment]
    // [1309] phi wait_moment::w#13 = $20 [phi:main_vera_flash::@59->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [1486] phi from main_vera_flash::@59 to main_vera_flash::@60 [phi:main_vera_flash::@59->main_vera_flash::@60]
    // main_vera_flash::@60
    // spi_deselect()
    // [1487] call spi_deselect
    jsr spi_deselect
    rts
    // [1488] phi from main_vera_flash::@39 to main_vera_flash::@12 [phi:main_vera_flash::@39->main_vera_flash::@12]
    // main_vera_flash::@12
  __b12:
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1489] call snprintf_init
    // [1204] phi from main_vera_flash::@12 to snprintf_init [phi:main_vera_flash::@12->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main_vera_flash::@12->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@46
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1490] printf_ulong::uvalue#11 = main_vera_flash::vera_flashed#0 -- vdum1=vdum2 
    lda vera_flashed
    sta printf_ulong.uvalue
    lda vera_flashed+1
    sta printf_ulong.uvalue+1
    lda vera_flashed+2
    sta printf_ulong.uvalue+2
    lda vera_flashed+3
    sta printf_ulong.uvalue+3
    // [1491] call printf_ulong
    // [1753] phi from main_vera_flash::@46 to printf_ulong [phi:main_vera_flash::@46->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 0 [phi:main_vera_flash::@46->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 0 [phi:main_vera_flash::@46->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@46->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#11 [phi:main_vera_flash::@46->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1492] phi from main_vera_flash::@46 to main_vera_flash::@47 [phi:main_vera_flash::@46->main_vera_flash::@47]
    // main_vera_flash::@47
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1493] call printf_str
    // [1209] phi from main_vera_flash::@47 to printf_str [phi:main_vera_flash::@47->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main_vera_flash::@47->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = main_vera_flash::s2 [phi:main_vera_flash::@47->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@48
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1494] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1495] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1497] spi_manufacturer#597 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1498] spi_memory_type#598 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1499] spi_memory_capacity#599 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHED, info_text)
    // [1500] call display_info_vera
    // [997] phi from main_vera_flash::@48 to display_info_vera [phi:main_vera_flash::@48->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@48->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#599 [phi:main_vera_flash::@48->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#598 [phi:main_vera_flash::@48->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#597 [phi:main_vera_flash::@48->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_FLASHED [phi:main_vera_flash::@48->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1501] phi from main_vera_flash::@48 to main_vera_flash::@49 [phi:main_vera_flash::@48->main_vera_flash::@49]
    // main_vera_flash::@49
    // unsigned long vera_differences = vera_verify()
    // [1502] call vera_verify
    // [2749] phi from main_vera_flash::@49 to vera_verify [phi:main_vera_flash::@49->vera_verify]
    jsr vera_verify
    // unsigned long vera_differences = vera_verify()
    // [1503] vera_verify::return#3 = vera_verify::vera_different_bytes#11
    // main_vera_flash::@50
    // [1504] main_vera_flash::vera_differences1#0 = vera_verify::return#3 -- vduz1=vdum2 
    lda vera_verify.return
    sta.z vera_differences1
    lda vera_verify.return+1
    sta.z vera_differences1+1
    lda vera_verify.return+2
    sta.z vera_differences1+2
    lda vera_verify.return+3
    sta.z vera_differences1+3
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1505] call snprintf_init
    // [1204] phi from main_vera_flash::@50 to snprintf_init [phi:main_vera_flash::@50->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:main_vera_flash::@50->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@51
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1506] printf_ulong::uvalue#12 = main_vera_flash::vera_differences1#0 -- vdum1=vduz2 
    lda.z vera_differences1
    sta printf_ulong.uvalue
    lda.z vera_differences1+1
    sta printf_ulong.uvalue+1
    lda.z vera_differences1+2
    sta printf_ulong.uvalue+2
    lda.z vera_differences1+3
    sta printf_ulong.uvalue+3
    // [1507] call printf_ulong
    // [1753] phi from main_vera_flash::@51 to printf_ulong [phi:main_vera_flash::@51->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:main_vera_flash::@51->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:main_vera_flash::@51->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@51->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#12 [phi:main_vera_flash::@51->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1508] phi from main_vera_flash::@51 to main_vera_flash::@52 [phi:main_vera_flash::@51->main_vera_flash::@52]
    // main_vera_flash::@52
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1509] call printf_str
    // [1209] phi from main_vera_flash::@52 to printf_str [phi:main_vera_flash::@52->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:main_vera_flash::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s13 [phi:main_vera_flash::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@53
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1510] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1511] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1513] spi_manufacturer#598 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1514] spi_memory_type#599 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1515] spi_memory_capacity#600 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHED, info_text)
    // [1516] call display_info_vera
    // [997] phi from main_vera_flash::@53 to display_info_vera [phi:main_vera_flash::@53->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@53->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#600 [phi:main_vera_flash::@53->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#599 [phi:main_vera_flash::@53->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#598 [phi:main_vera_flash::@53->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_FLASHED [phi:main_vera_flash::@53->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1517] phi from main_vera_flash::@10 main_vera_flash::@53 to main_vera_flash::@14 [phi:main_vera_flash::@10/main_vera_flash::@53->main_vera_flash::@14]
    // main_vera_flash::@14
  __b14:
    // display_action_progress("VERA SPI de-activation ...")
    // [1518] call display_action_progress
  // Now we loop until jumper JP1 is open again!
    // [903] phi from main_vera_flash::@14 to display_action_progress [phi:main_vera_flash::@14->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = main_vera_flash::info_text13 [phi:main_vera_flash::@14->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1519] phi from main_vera_flash::@14 to main_vera_flash::@61 [phi:main_vera_flash::@14->main_vera_flash::@61]
    // main_vera_flash::@61
    // display_action_text("Please OPEN the jumper JP1 on the VERA board!")
    // [1520] call display_action_text
    // [1357] phi from main_vera_flash::@61 to display_action_text [phi:main_vera_flash::@61->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main_vera_flash::info_text14 [phi:main_vera_flash::@61->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_action_text.info_text
    lda #>info_text14
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1521] phi from main_vera_flash::@61 to main_vera_flash::@62 [phi:main_vera_flash::@61->main_vera_flash::@62]
    // main_vera_flash::@62
    // vera_detect()
    // [1522] call vera_detect
    // [2403] phi from main_vera_flash::@62 to vera_detect [phi:main_vera_flash::@62->vera_detect]
    jsr vera_detect
    // [1523] phi from main_vera_flash::@19 main_vera_flash::@62 to main_vera_flash::@15 [phi:main_vera_flash::@19/main_vera_flash::@62->main_vera_flash::@15]
  __b5:
    // [1523] phi main_vera_flash::spi_ensure_detect#12 = 0 [phi:main_vera_flash::@19/main_vera_flash::@62->main_vera_flash::@15#0] -- vbuz1=vbuc1 
    lda #0
    sta.z spi_ensure_detect_1
    // main_vera_flash::@15
  __b15:
    // while(spi_ensure_detect < 16)
    // [1524] if(main_vera_flash::spi_ensure_detect#12<$10) goto main_vera_flash::@16 -- vbuz1_lt_vbuc1_then_la1 
    lda.z spi_ensure_detect_1
    cmp #$10
    bcc __b16
    // [1525] phi from main_vera_flash::@15 to main_vera_flash::@17 [phi:main_vera_flash::@15->main_vera_flash::@17]
    // main_vera_flash::@17
    // display_action_text("The jumper JP1 has been opened on the VERA!")
    // [1526] call display_action_text
    // [1357] phi from main_vera_flash::@17 to display_action_text [phi:main_vera_flash::@17->display_action_text]
    // [1357] phi display_action_text::info_text#25 = main_vera_flash::info_text15 [phi:main_vera_flash::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_text.info_text
    lda #>info_text15
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1527] phi from main_vera_flash::@17 main_vera_flash::@24 to main_vera_flash::@1 [phi:main_vera_flash::@17/main_vera_flash::@24->main_vera_flash::@1]
    // main_vera_flash::@1
  __b1:
    // spi_deselect()
    // [1528] call spi_deselect
    jsr spi_deselect
    rts
    // [1529] phi from main_vera_flash::@15 to main_vera_flash::@16 [phi:main_vera_flash::@15->main_vera_flash::@16]
    // main_vera_flash::@16
  __b16:
    // vera_detect()
    // [1530] call vera_detect
    // [2403] phi from main_vera_flash::@16 to vera_detect [phi:main_vera_flash::@16->vera_detect]
    jsr vera_detect
    // [1531] phi from main_vera_flash::@16 to main_vera_flash::@63 [phi:main_vera_flash::@16->main_vera_flash::@63]
    // main_vera_flash::@63
    // wait_moment(1)
    // [1532] call wait_moment
    // [1309] phi from main_vera_flash::@63 to wait_moment [phi:main_vera_flash::@63->wait_moment]
    // [1309] phi wait_moment::w#13 = 1 [phi:main_vera_flash::@63->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // main_vera_flash::@64
    // if(spi_manufacturer != 0xEF && spi_memory_type != 0x40 && spi_memory_capacity != 0x15)
    // [1533] if(spi_read::return#0==$ef) goto main_vera_flash::@19 -- vbum1_eq_vbuc1_then_la1 
    lda #$ef
    cmp spi_read.return
    beq __b19
    // main_vera_flash::@69
    // [1534] if(spi_read::return#1==$40) goto main_vera_flash::@19 -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp spi_read.return_1
    beq __b19
    // main_vera_flash::@68
    // [1535] if(spi_read::return#10!=$15) goto main_vera_flash::@18 -- vbum1_neq_vbuc1_then_la1 
    lda #$15
    cmp spi_read.return_3
    bne __b18
    // main_vera_flash::@19
  __b19:
    // [1536] spi_manufacturer#593 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1537] spi_memory_type#594 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1538] spi_memory_capacity#595 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_WAITING, NULL)
    // [1539] call display_info_vera
    // [997] phi from main_vera_flash::@19 to display_info_vera [phi:main_vera_flash::@19->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@19->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#595 [phi:main_vera_flash::@19->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#594 [phi:main_vera_flash::@19->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#593 [phi:main_vera_flash::@19->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_WAITING [phi:main_vera_flash::@19->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_WAITING
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b5
    // main_vera_flash::@18
  __b18:
    // [1540] spi_manufacturer#592 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1541] spi_memory_type#593 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1542] spi_memory_capacity#594 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, NULL)
    // [1543] call display_info_vera
    // [997] phi from main_vera_flash::@18 to display_info_vera [phi:main_vera_flash::@18->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@18->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#594 [phi:main_vera_flash::@18->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#593 [phi:main_vera_flash::@18->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#592 [phi:main_vera_flash::@18->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_flash::@18->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@65
    // spi_ensure_detect++;
    // [1544] main_vera_flash::spi_ensure_detect#4 = ++ main_vera_flash::spi_ensure_detect#12 -- vbuz1=_inc_vbuz1 
    inc.z spi_ensure_detect_1
    // [1523] phi from main_vera_flash::@65 to main_vera_flash::@15 [phi:main_vera_flash::@65->main_vera_flash::@15]
    // [1523] phi main_vera_flash::spi_ensure_detect#12 = main_vera_flash::spi_ensure_detect#4 [phi:main_vera_flash::@65->main_vera_flash::@15#0] -- register_copy 
    jmp __b15
    // main_vera_flash::@10
  __b10:
    // [1545] spi_manufacturer#590 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1546] spi_memory_type#591 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1547] spi_memory_capacity#592 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "No update required")
    // [1548] call display_info_vera
  // VFL1 | VERA and VERA.BIN equal | Display that there are no differences between the VERA and VERA.BIN. Set VERA to Flashed. | None
    // [997] phi from main_vera_flash::@10 to display_info_vera [phi:main_vera_flash::@10->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = info_text6 [phi:main_vera_flash::@10->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_vera.info_text
    lda #>info_text6
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#592 [phi:main_vera_flash::@10->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#591 [phi:main_vera_flash::@10->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#590 [phi:main_vera_flash::@10->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main_vera_flash::@10->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b14
    // [1549] phi from main_vera_flash::@3 to main_vera_flash::@4 [phi:main_vera_flash::@3->main_vera_flash::@4]
    // main_vera_flash::@4
  __b4:
    // vera_detect()
    // [1550] call vera_detect
    // [2403] phi from main_vera_flash::@4 to vera_detect [phi:main_vera_flash::@4->vera_detect]
    jsr vera_detect
    // [1551] phi from main_vera_flash::@4 to main_vera_flash::@27 [phi:main_vera_flash::@4->main_vera_flash::@27]
    // main_vera_flash::@27
    // wait_moment(1)
    // [1552] call wait_moment
    // [1309] phi from main_vera_flash::@27 to wait_moment [phi:main_vera_flash::@27->wait_moment]
    // [1309] phi wait_moment::w#13 = 1 [phi:main_vera_flash::@27->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // main_vera_flash::@28
    // if(spi_manufacturer == 0xEF && spi_memory_type == 0x40 && spi_memory_capacity == 0x15)
    // [1553] if(spi_read::return#0!=$ef) goto main_vera_flash::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #$ef
    cmp spi_read.return
    bne __b7
    // main_vera_flash::@67
    // [1554] if(spi_read::return#1!=$40) goto main_vera_flash::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #$40
    cmp spi_read.return_1
    bne __b7
    // main_vera_flash::@66
    // [1555] if(spi_read::return#10==$15) goto main_vera_flash::@6 -- vbum1_eq_vbuc1_then_la1 
    lda #$15
    cmp spi_read.return_3
    beq __b6
    // main_vera_flash::@7
  __b7:
    // [1556] spi_manufacturer#601 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1557] spi_memory_type#602 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1558] spi_memory_capacity#603 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_WAITING, "Close JP1 jumper pins!")
    // [1559] call display_info_vera
    // [997] phi from main_vera_flash::@7 to display_info_vera [phi:main_vera_flash::@7->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = main_vera_flash::info_text5 [phi:main_vera_flash::@7->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_vera.info_text
    lda #>info_text5
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#603 [phi:main_vera_flash::@7->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#602 [phi:main_vera_flash::@7->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#601 [phi:main_vera_flash::@7->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_WAITING [phi:main_vera_flash::@7->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_WAITING
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b2
    // main_vera_flash::@6
  __b6:
    // [1560] spi_manufacturer#599 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1561] spi_memory_type#600 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1562] spi_memory_capacity#601 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, "JP1 jumper pins closed!")
    // [1563] call display_info_vera
    // [997] phi from main_vera_flash::@6 to display_info_vera [phi:main_vera_flash::@6->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = main_vera_flash::info_text4 [phi:main_vera_flash::@6->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_vera.info_text
    lda #>info_text4
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#601 [phi:main_vera_flash::@6->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#600 [phi:main_vera_flash::@6->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#599 [phi:main_vera_flash::@6->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_flash::@6->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@33
    // spi_ensure_detect++;
    // [1564] main_vera_flash::spi_ensure_detect#1 = ++ main_vera_flash::spi_ensure_detect#11 -- vbuz1=_inc_vbuz1 
    inc.z spi_ensure_detect
    // [1413] phi from main_vera_flash::@33 to main_vera_flash::@3 [phi:main_vera_flash::@33->main_vera_flash::@3]
    // [1413] phi main_vera_flash::spi_ensure_detect#11 = main_vera_flash::spi_ensure_detect#1 [phi:main_vera_flash::@33->main_vera_flash::@3#0] -- register_copy 
    jmp __b3
  .segment DataVera
    s: .text "Reading VERA.BIN ... (.) data ( ) empty"
    .byte 0
    info_text: .text "VERA SPI activation ..."
    .byte 0
    info_text1: .text "Please close the jumper JP1 on the VERA board!"
    .byte 0
    info_text2: .text "The jumper JP1 has been closed on the VERA!"
    .byte 0
    info_text3: .text "Comparing VERA ... (.) data, (=) same, (*) different."
    .byte 0
    info_text4: .text "JP1 jumper pins closed!"
    .byte 0
    info_text5: .text "Close JP1 jumper pins!"
    .byte 0
    info_text7: .text "There was an error cleaning your VERA flash memory!"
    .byte 0
    info_text8: .text "DO NOT RESET or REBOOT YOUR CX16 AND WAIT!"
    .byte 0
    info_text9: .text "ERASE ERROR!"
    .byte 0
    s2: .text " bytes flashed!"
    .byte 0
    info_text10: .text "There was an error updating your VERA flash memory!"
    .byte 0
    info_text12: .text "FLASH ERROR!"
    .byte 0
    info_text13: .text "VERA SPI de-activation ..."
    .byte 0
    info_text14: .text "Please OPEN the jumper JP1 on the VERA board!"
    .byte 0
    info_text15: .text "The jumper JP1 has been opened on the VERA!"
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
// void display_info_rom(__mem() char rom_chip, __mem() char info_status, __zp($3c) char *info_text)
display_info_rom: {
    .label display_info_rom__6 = $70
    .label display_info_rom__15 = $7f
    .label display_info_rom__16 = $41
    .label info_text = $3c
    .label display_info_rom__19 = $70
    .label display_info_rom__20 = $70
    // unsigned char x = wherex()
    // [1566] call wherex
    jsr wherex
    // [1567] wherex::return#12 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_4
    // display_info_rom::@3
    // [1568] display_info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1569] call wherey
    jsr wherey
    // [1570] wherey::return#12 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_4
    // display_info_rom::@4
    // [1571] display_info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1572] status_rom[display_info_rom::rom_chip#17] = display_info_rom::info_status#17 -- pbuc1_derefidx_vbum1=vbum2 
    lda info_status
    ldy rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1573] display_rom_led::chip#1 = display_info_rom::rom_chip#17 -- vbum1=vbum2 
    tya
    sta display_rom_led.chip
    // [1574] display_rom_led::c#1 = status_color[display_info_rom::info_status#17] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_rom_led.c
    // [1575] call display_rom_led
    // [2381] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [2381] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [2381] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1576] gotoxy::y#23 = display_info_rom::rom_chip#17 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1577] call gotoxy
    // [801] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#23 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1578] display_info_rom::$16 = display_info_rom::rom_chip#17 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z display_info_rom__16
    // rom_chip*13
    // [1579] display_info_rom::$19 = display_info_rom::$16 + display_info_rom::rom_chip#17 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z display_info_rom__16
    sta.z display_info_rom__19
    // [1580] display_info_rom::$20 = display_info_rom::$19 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z display_info_rom__20
    asl
    asl
    sta.z display_info_rom__20
    // [1581] display_info_rom::$6 = display_info_rom::$20 + display_info_rom::rom_chip#17 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z display_info_rom__6
    sta.z display_info_rom__6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1582] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta.z printf_string.str_1+1
    // [1583] call printf_str
    // [1209] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = chip [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z printf_str.s
    lda #>chip
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1584] printf_uchar::uvalue#4 = display_info_rom::rom_chip#17 -- vbum1=vbum2 
    lda rom_chip
    sta printf_uchar.uvalue
    // [1585] call printf_uchar
    // [1346] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#4 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1586] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1587] call printf_str
    // [1209] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1588] display_info_rom::$15 = display_info_rom::info_status#17 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_rom__15
    // [1589] printf_string::str#8 = status_text[display_info_rom::$15] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1590] call printf_string
    // [1218] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1591] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1592] call printf_str
    // [1209] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1593] printf_string::str#9 = rom_device_names[display_info_rom::$16] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__16
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1594] call printf_string
    // [1218] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1595] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1596] call printf_str
    // [1209] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1597] printf_string::str#41 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z printf_string.str_1
    sta.z printf_string.str
    lda.z printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1598] call printf_string
    // [1218] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#41 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = $d [phi:display_info_rom::@13->printf_string#3] -- vbum1=vbuc1 
    lda #$d
    sta printf_string.format_min_length
    jsr printf_string
    // [1599] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1600] call printf_str
    // [1209] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1601] if((char *)0==display_info_rom::info_text#17) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // gotoxy(INFO_X+64-28, INFO_Y+rom_chip+2)
    // [1602] gotoxy::y#25 = display_info_rom::rom_chip#17 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1603] call gotoxy
    // [801] phi from display_info_rom::@2 to gotoxy [phi:display_info_rom::@2->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#25 [phi:display_info_rom::@2->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_rom::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@16
    // printf("%-25s", info_text)
    // [1604] printf_string::str#11 = display_info_rom::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1605] call printf_string
    // [1218] phi from display_info_rom::@16 to printf_string [phi:display_info_rom::@16->printf_string]
    // [1218] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#11 [phi:display_info_rom::@16->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = $19 [phi:display_info_rom::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1606] gotoxy::x#24 = display_info_rom::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1607] gotoxy::y#24 = display_info_rom::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1608] call gotoxy
    // [801] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#24 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#24 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1609] return 
    rts
  .segment Data
    .label x = wherex.return_4
    .label y = wherey.return_4
    info_status: .byte 0
    rom_chip: .byte 0
}
.segment Code
  // rom_file
// __zp($d2) char * rom_file(__mem() char rom_chip)
rom_file: {
    .label rom_file__0 = $41
    .label return = $d2
    // if(rom_chip)
    // [1611] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbum1_then_la1 
    lda rom_chip
    bne __b1
    // [1614] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1614] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_cx16
    sta.z return
    lda #>file_rom_cx16
    sta.z return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1612] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #'0'
    clc
    adc rom_chip
    sta.z rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1613] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuz1 
    sta file_rom_card+3
    // [1614] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1614] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_card
    sta.z return
    lda #>file_rom_card
    sta.z return+1
    // rom_file::@return
    // }
    // [1615] return 
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
// __mem() unsigned long rom_read(char rom_chip, __zp($56) char *file, __mem() char info_status, __mem() char brom_bank_start, __mem() unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__13 = $79
    .label fp = $bb
    .label rom_bram_ptr = $2d
    .label file = $56
    .label rom_action_text = $54
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1617] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1618] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_read::@18
    // if(info_status == STATUS_READING)
    // [1619] if(rom_read::info_status#12==STATUS_READING) goto rom_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [1621] phi from rom_read::@18 to rom_read::@2 [phi:rom_read::@18->rom_read::@2]
    // [1621] phi rom_read::rom_action_text#10 = smc_action_text#2 [phi:rom_read::@18->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z rom_action_text
    lda #>smc_action_text_1
    sta.z rom_action_text+1
    jmp __b2
    // [1620] phi from rom_read::@18 to rom_read::@1 [phi:rom_read::@18->rom_read::@1]
    // rom_read::@1
  __b1:
    // [1621] phi from rom_read::@1 to rom_read::@2 [phi:rom_read::@1->rom_read::@2]
    // [1621] phi rom_read::rom_action_text#10 = smc_action_text#1 [phi:rom_read::@1->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z rom_action_text
    lda #>smc_action_text
    sta.z rom_action_text+1
    // rom_read::@2
  __b2:
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1622] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#10 -- vbum1=vbum2 
    lda brom_bank_start
    sta rom_address_from_bank.rom_bank
    // [1623] call rom_address_from_bank
    // [2897] phi from rom_read::@2 to rom_address_from_bank [phi:rom_read::@2->rom_address_from_bank]
    // [2897] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read::@2->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1624] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@20
    // [1625] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1626] call snprintf_init
    // [1204] phi from rom_read::@20 to snprintf_init [phi:rom_read::@20->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:rom_read::@20->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1627] phi from rom_read::@20 to rom_read::@21 [phi:rom_read::@20->rom_read::@21]
    // rom_read::@21
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1628] call printf_str
    // [1209] phi from rom_read::@21 to printf_str [phi:rom_read::@21->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:rom_read::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = rom_read::s [phi:rom_read::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@22
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1629] printf_string::str#17 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1630] call printf_string
    // [1218] phi from rom_read::@22 to printf_string [phi:rom_read::@22->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:rom_read::@22->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#17 [phi:rom_read::@22->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:rom_read::@22->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:rom_read::@22->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1631] phi from rom_read::@22 to rom_read::@23 [phi:rom_read::@22->rom_read::@23]
    // rom_read::@23
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1632] call printf_str
    // [1209] phi from rom_read::@23 to printf_str [phi:rom_read::@23->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:rom_read::@23->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = rom_read::s1 [phi:rom_read::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@24
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1633] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1634] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1636] call display_action_text
    // [1357] phi from rom_read::@24 to display_action_text [phi:rom_read::@24->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:rom_read::@24->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@25
    // FILE *fp = fopen(file, "r")
    // [1637] fopen::path#4 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1638] call fopen
    // [2428] phi from rom_read::@25 to fopen [phi:rom_read::@25->fopen]
    // [2428] phi __errno#467 = __errno#105 [phi:rom_read::@25->fopen#0] -- register_copy 
    // [2428] phi fopen::pathtoken#0 = fopen::path#4 [phi:rom_read::@25->fopen#1] -- register_copy 
    // [2428] phi __stdio_filecount#27 = __stdio_filecount#100 [phi:rom_read::@25->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1639] fopen::return#5 = fopen::return#2
    // rom_read::@26
    // [1640] rom_read::fp#0 = fopen::return#5 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1641] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [1642] phi from rom_read::@26 to rom_read::@4 [phi:rom_read::@26->rom_read::@4]
    // rom_read::@4
    // gotoxy(x, y)
    // [1643] call gotoxy
    // [801] phi from rom_read::@4 to gotoxy [phi:rom_read::@4->gotoxy]
    // [801] phi gotoxy::y#37 = PROGRESS_Y [phi:rom_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:rom_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1644] phi from rom_read::@4 to rom_read::@5 [phi:rom_read::@4->rom_read::@5]
    // [1644] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@4->rom_read::@5#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1644] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@4->rom_read::@5#1] -- vwum1=vwuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1644] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#10 [phi:rom_read::@4->rom_read::@5#2] -- register_copy 
    // [1644] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@4->rom_read::@5#3] -- register_copy 
    // [1644] phi rom_read::rom_bram_ptr#13 = (char *)$7800 [phi:rom_read::@4->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1644] phi rom_read::rom_bram_bank#10 = 0 [phi:rom_read::@4->rom_read::@5#5] -- vbum1=vbuc1 
    lda #0
    sta rom_bram_bank
    // [1644] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@4->rom_read::@5#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@5
  __b5:
    // while (rom_file_size < rom_size)
    // [1645] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@6 -- vdum1_lt_vdum2_then_la1 
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
    // [1646] fclose::stream#2 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [1647] call fclose
    // [2563] phi from rom_read::@10 to fclose [phi:rom_read::@10->fclose]
    // [2563] phi fclose::stream#3 = fclose::stream#2 [phi:rom_read::@10->fclose#0] -- register_copy 
    jsr fclose
    // [1648] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1648] phi __stdio_filecount#12 = __stdio_filecount#2 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1648] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    rts
    // [1648] phi from rom_read::@26 to rom_read::@3 [phi:rom_read::@26->rom_read::@3]
  __b4:
    // [1648] phi __stdio_filecount#12 = __stdio_filecount#1 [phi:rom_read::@26->rom_read::@3#0] -- register_copy 
    // [1648] phi rom_read::return#0 = 0 [phi:rom_read::@26->rom_read::@3#1] -- vdum1=vduc1 
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
    // [1649] return 
    rts
    // rom_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [1650] if(rom_read::info_status#12!=STATUS_CHECKING) goto rom_read::@30 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b7
    // [1652] phi from rom_read::@6 to rom_read::@7 [phi:rom_read::@6->rom_read::@7]
    // [1652] phi rom_read::rom_bram_ptr#10 = (char *) 1024 [phi:rom_read::@6->rom_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z rom_bram_ptr
    lda #>$400
    sta.z rom_bram_ptr+1
    // [1651] phi from rom_read::@6 to rom_read::@30 [phi:rom_read::@6->rom_read::@30]
    // rom_read::@30
    // [1652] phi from rom_read::@30 to rom_read::@7 [phi:rom_read::@30->rom_read::@7]
    // [1652] phi rom_read::rom_bram_ptr#10 = rom_read::rom_bram_ptr#13 [phi:rom_read::@30->rom_read::@7#0] -- register_copy 
    // rom_read::@7
  __b7:
    // display_action_text_reading(rom_action_text, file, rom_file_size, rom_size, rom_bram_bank, rom_bram_ptr)
    // [1653] display_action_text_reading::action#2 = rom_read::rom_action_text#10 -- pbuz1=pbuz2 
    lda.z rom_action_text
    sta.z display_action_text_reading.action
    lda.z rom_action_text+1
    sta.z display_action_text_reading.action+1
    // [1654] display_action_text_reading::file#2 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z display_action_text_reading.file
    lda.z file+1
    sta.z display_action_text_reading.file+1
    // [1655] display_action_text_reading::bytes#2 = rom_read::rom_file_size#11 -- vdum1=vdum2 
    lda rom_file_size
    sta display_action_text_reading.bytes
    lda rom_file_size+1
    sta display_action_text_reading.bytes+1
    lda rom_file_size+2
    sta display_action_text_reading.bytes+2
    lda rom_file_size+3
    sta display_action_text_reading.bytes+3
    // [1656] display_action_text_reading::size#2 = rom_read::rom_size#12 -- vdum1=vdum2 
    lda rom_size
    sta display_action_text_reading.size
    lda rom_size+1
    sta display_action_text_reading.size+1
    lda rom_size+2
    sta display_action_text_reading.size+2
    lda rom_size+3
    sta display_action_text_reading.size+3
    // [1657] display_action_text_reading::bram_bank#2 = rom_read::rom_bram_bank#10 -- vbum1=vbum2 
    lda rom_bram_bank
    sta display_action_text_reading.bram_bank
    // [1658] display_action_text_reading::bram_ptr#2 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z rom_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1659] call display_action_text_reading
    // [2592] phi from rom_read::@7 to display_action_text_reading [phi:rom_read::@7->display_action_text_reading]
    // [2592] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#2 [phi:rom_read::@7->display_action_text_reading#0] -- register_copy 
    // [2592] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#2 [phi:rom_read::@7->display_action_text_reading#1] -- register_copy 
    // [2592] phi display_action_text_reading::size#10 = display_action_text_reading::size#2 [phi:rom_read::@7->display_action_text_reading#2] -- register_copy 
    // [2592] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#2 [phi:rom_read::@7->display_action_text_reading#3] -- register_copy 
    // [2592] phi display_action_text_reading::file#3 = display_action_text_reading::file#2 [phi:rom_read::@7->display_action_text_reading#4] -- register_copy 
    // [2592] phi display_action_text_reading::action#3 = display_action_text_reading::action#2 [phi:rom_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // rom_read::@27
    // rom_address % 0x04000
    // [1660] rom_read::$13 = rom_read::rom_address#10 & $4000-1 -- vduz1=vdum2_band_vduc1 
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
    // [1661] if(0!=rom_read::$13) goto rom_read::@8 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__13
    ora.z rom_read__13+1
    ora.z rom_read__13+2
    ora.z rom_read__13+3
    bne __b8
    // rom_read::@14
    // brom_bank_start++;
    // [1662] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#11 -- vbum1=_inc_vbum1 
    inc brom_bank_start
    // [1663] phi from rom_read::@14 rom_read::@27 to rom_read::@8 [phi:rom_read::@14/rom_read::@27->rom_read::@8]
    // [1663] phi rom_read::brom_bank_start#16 = rom_read::brom_bank_start#0 [phi:rom_read::@14/rom_read::@27->rom_read::@8#0] -- register_copy 
    // rom_read::@8
  __b8:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1664] BRAM = rom_read::rom_bram_bank#10 -- vbuz1=vbum2 
    lda rom_bram_bank
    sta.z BRAM
    // rom_read::@19
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1665] fgets::ptr#5 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z fgets.ptr
    lda.z rom_bram_ptr+1
    sta.z fgets.ptr+1
    // [1666] fgets::stream#3 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1667] call fgets
    // [2509] phi from rom_read::@19 to fgets [phi:rom_read::@19->fgets]
    // [2509] phi fgets::ptr#14 = fgets::ptr#5 [phi:rom_read::@19->fgets#0] -- register_copy 
    // [2509] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@19->fgets#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta fgets.size
    lda #>ROM_PROGRESS_CELL
    sta fgets.size+1
    // [2509] phi fgets::stream#4 = fgets::stream#3 [phi:rom_read::@19->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1668] fgets::return#13 = fgets::return#1
    // rom_read::@28
    // [1669] rom_read::rom_package_read#0 = fgets::return#13 -- vwum1=vwum2 
    lda fgets.return
    sta rom_package_read
    lda fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1670] if(0!=rom_read::rom_package_read#0) goto rom_read::@9 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b9
    jmp __b10
    // rom_read::@9
  __b9:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1671] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@11 -- vwum1_neq_vwuc1_then_la1 
    lda rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b11
    lda rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b11
    // rom_read::@15
    // gotoxy(x, ++y);
    // [1672] rom_read::y#1 = ++ rom_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1673] gotoxy::y#32 = rom_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1674] call gotoxy
    // [801] phi from rom_read::@15 to gotoxy [phi:rom_read::@15->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#32 [phi:rom_read::@15->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:rom_read::@15->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1675] phi from rom_read::@15 to rom_read::@11 [phi:rom_read::@15->rom_read::@11]
    // [1675] phi rom_read::y#26 = rom_read::y#1 [phi:rom_read::@15->rom_read::@11#0] -- register_copy 
    // [1675] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@15->rom_read::@11#1] -- vwum1=vbuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1675] phi from rom_read::@9 to rom_read::@11 [phi:rom_read::@9->rom_read::@11]
    // [1675] phi rom_read::y#26 = rom_read::y#11 [phi:rom_read::@9->rom_read::@11#0] -- register_copy 
    // [1675] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@9->rom_read::@11#1] -- register_copy 
    // rom_read::@11
  __b11:
    // if(info_status == STATUS_READING)
    // [1676] if(rom_read::info_status#12!=STATUS_READING) goto rom_read::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b12
    // rom_read::@16
    // cputc('.')
    // [1677] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1678] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_read::@12
  __b12:
    // rom_bram_ptr += rom_package_read
    // [1680] rom_read::rom_bram_ptr#2 = rom_read::rom_bram_ptr#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z rom_bram_ptr
    adc rom_package_read
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc rom_package_read+1
    sta.z rom_bram_ptr+1
    // rom_address += rom_package_read
    // [1681] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1682] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1683] rom_read::rom_row_current#17 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda rom_row_current
    adc rom_package_read
    sta rom_row_current
    lda rom_row_current+1
    adc rom_package_read+1
    sta rom_row_current+1
    // if (rom_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [1684] if(rom_read::rom_bram_ptr#2!=(char *)$c000) goto rom_read::@13 -- pbuz1_neq_pbuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b13
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b13
    // rom_read::@17
    // rom_bram_bank++;
    // [1685] rom_read::rom_bram_bank#1 = ++ rom_read::rom_bram_bank#10 -- vbum1=_inc_vbum1 
    inc rom_bram_bank
    // [1686] phi from rom_read::@17 to rom_read::@13 [phi:rom_read::@17->rom_read::@13]
    // [1686] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#1 [phi:rom_read::@17->rom_read::@13#0] -- register_copy 
    // [1686] phi rom_read::rom_bram_ptr#8 = (char *)$a000 [phi:rom_read::@17->rom_read::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1686] phi from rom_read::@12 to rom_read::@13 [phi:rom_read::@12->rom_read::@13]
    // [1686] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#10 [phi:rom_read::@12->rom_read::@13#0] -- register_copy 
    // [1686] phi rom_read::rom_bram_ptr#8 = rom_read::rom_bram_ptr#2 [phi:rom_read::@12->rom_read::@13#1] -- register_copy 
    // rom_read::@13
  __b13:
    // if (rom_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [1687] if(rom_read::rom_bram_ptr#8!=(char *)$9800) goto rom_read::@29 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1644] phi from rom_read::@13 to rom_read::@5 [phi:rom_read::@13->rom_read::@5]
    // [1644] phi rom_read::y#11 = rom_read::y#26 [phi:rom_read::@13->rom_read::@5#0] -- register_copy 
    // [1644] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#17 [phi:rom_read::@13->rom_read::@5#1] -- register_copy 
    // [1644] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@13->rom_read::@5#2] -- register_copy 
    // [1644] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@13->rom_read::@5#3] -- register_copy 
    // [1644] phi rom_read::rom_bram_ptr#13 = (char *)$a000 [phi:rom_read::@13->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1644] phi rom_read::rom_bram_bank#10 = 1 [phi:rom_read::@13->rom_read::@5#5] -- vbum1=vbuc1 
    lda #1
    sta rom_bram_bank
    // [1644] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@13->rom_read::@5#6] -- register_copy 
    jmp __b5
    // [1688] phi from rom_read::@13 to rom_read::@29 [phi:rom_read::@13->rom_read::@29]
    // rom_read::@29
    // [1644] phi from rom_read::@29 to rom_read::@5 [phi:rom_read::@29->rom_read::@5]
    // [1644] phi rom_read::y#11 = rom_read::y#26 [phi:rom_read::@29->rom_read::@5#0] -- register_copy 
    // [1644] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#17 [phi:rom_read::@29->rom_read::@5#1] -- register_copy 
    // [1644] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@29->rom_read::@5#2] -- register_copy 
    // [1644] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@29->rom_read::@5#3] -- register_copy 
    // [1644] phi rom_read::rom_bram_ptr#13 = rom_read::rom_bram_ptr#8 [phi:rom_read::@29->rom_read::@5#4] -- register_copy 
    // [1644] phi rom_read::rom_bram_bank#10 = rom_read::rom_bram_bank#14 [phi:rom_read::@29->rom_read::@5#5] -- register_copy 
    // [1644] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@29->rom_read::@5#6] -- register_copy 
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
    .label rom_verify__17 = $74
    .label rom_bram_ptr = $38
    // rom_verify::bank_set_bram1
    // BRAM = bank
    // [1690] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_verify::@11
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1691] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1692] call rom_address_from_bank
    // [2897] phi from rom_verify::@11 to rom_address_from_bank [phi:rom_verify::@11->rom_address_from_bank]
    // [2897] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify::@11->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1693] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_1
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_1+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_1+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_1+3
    // rom_verify::@12
    // [1694] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1695] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vdum2_plus_vdum1 
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
    // [1696] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1697] call display_info_rom
    // [1565] phi from rom_verify::@12 to display_info_rom [phi:rom_verify::@12->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = rom_verify::info_text [phi:rom_verify::@12->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#1 [phi:rom_verify::@12->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:rom_verify::@12->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1698] phi from rom_verify::@12 to rom_verify::@13 [phi:rom_verify::@12->rom_verify::@13]
    // rom_verify::@13
    // gotoxy(x, y)
    // [1699] call gotoxy
    // [801] phi from rom_verify::@13 to gotoxy [phi:rom_verify::@13->gotoxy]
    // [801] phi gotoxy::y#37 = PROGRESS_Y [phi:rom_verify::@13->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:rom_verify::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1700] phi from rom_verify::@13 to rom_verify::@1 [phi:rom_verify::@13->rom_verify::@1]
    // [1700] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@13->rom_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1700] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@13->rom_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1700] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@13->rom_verify::@1#2] -- vdum1=vduc1 
    sta rom_different_bytes
    sta rom_different_bytes+1
    lda #<0>>$10
    sta rom_different_bytes+2
    lda #>0>>$10
    sta rom_different_bytes+3
    // [1700] phi rom_verify::rom_bram_ptr#10 = (char *)$7800 [phi:rom_verify::@13->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1700] phi rom_verify::rom_bram_bank#11 = 0 [phi:rom_verify::@13->rom_verify::@1#4] -- vbum1=vbuc1 
    lda #0
    sta rom_bram_bank
    // [1700] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@13->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1701] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1702] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1703] rom_compare::bank_ram#0 = rom_verify::rom_bram_bank#11 -- vbum1=vbum2 
    lda rom_bram_bank
    sta rom_compare.bank_ram
    // [1704] rom_compare::ptr_ram#1 = rom_verify::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z rom_compare.ptr_ram
    lda.z rom_bram_ptr+1
    sta.z rom_compare.ptr_ram+1
    // [1705] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vdum1=vdum2 
    lda rom_address
    sta rom_compare.rom_compare_address
    lda rom_address+1
    sta rom_compare.rom_compare_address+1
    lda rom_address+2
    sta rom_compare.rom_compare_address+2
    lda rom_address+3
    sta rom_compare.rom_compare_address+3
    // [1706] call rom_compare
  // {asm{.byte $db}}
    // [2901] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2901] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2901] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size+1
    // [2901] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2901] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1707] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@14
    // [1708] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1709] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1710] rom_verify::y#1 = ++ rom_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1711] gotoxy::y#34 = rom_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1712] call gotoxy
    // [801] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#34 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1713] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1713] phi rom_verify::y#11 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1713] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1713] phi from rom_verify::@14 to rom_verify::@3 [phi:rom_verify::@14->rom_verify::@3]
    // [1713] phi rom_verify::y#11 = rom_verify::y#3 [phi:rom_verify::@14->rom_verify::@3#0] -- register_copy 
    // [1713] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@14->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1714] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwum1_neq_vwuc1_then_la1 
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
    // [1715] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1716] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // rom_bram_ptr += ROM_PROGRESS_CELL
    // [1718] rom_verify::rom_bram_ptr#1 = rom_verify::rom_bram_ptr#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z rom_bram_ptr
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc #>ROM_PROGRESS_CELL
    sta.z rom_bram_ptr+1
    // rom_address += ROM_PROGRESS_CELL
    // [1719] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
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
    // [1720] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwum1=vwum1_plus_vwuc1 
    lda progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta progress_row_current
    lda progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta progress_row_current+1
    // if (rom_bram_ptr == BRAM_HIGH)
    // [1721] if(rom_verify::rom_bram_ptr#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // rom_bram_bank++;
    // [1722] rom_verify::rom_bram_bank#1 = ++ rom_verify::rom_bram_bank#11 -- vbum1=_inc_vbum1 
    inc rom_bram_bank
    // [1723] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1723] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1723] phi rom_verify::rom_bram_ptr#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1723] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1723] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1723] phi rom_verify::rom_bram_ptr#6 = rom_verify::rom_bram_ptr#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (rom_bram_ptr == RAM_HIGH)
    // [1724] if(rom_verify::rom_bram_ptr#6!=$9800) goto rom_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$9800
    bne __b7
    lda.z rom_bram_ptr
    cmp #<$9800
    bne __b7
    // [1726] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1726] phi rom_verify::rom_bram_ptr#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1726] phi rom_verify::rom_bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta rom_bram_bank
    // [1725] phi from rom_verify::@6 to rom_verify::@24 [phi:rom_verify::@6->rom_verify::@24]
    // rom_verify::@24
    // [1726] phi from rom_verify::@24 to rom_verify::@7 [phi:rom_verify::@24->rom_verify::@7]
    // [1726] phi rom_verify::rom_bram_ptr#11 = rom_verify::rom_bram_ptr#6 [phi:rom_verify::@24->rom_verify::@7#0] -- register_copy 
    // [1726] phi rom_verify::rom_bram_bank#10 = rom_verify::rom_bram_bank#25 [phi:rom_verify::@24->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1727] rom_verify::$17 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<ROM_PROGRESS_CELL
    sbc equal_bytes
    sta.z rom_verify__17
    lda #>ROM_PROGRESS_CELL
    sbc equal_bytes+1
    sta.z rom_verify__17+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1728] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$17 -- vdum1=vdum1_plus_vwuz2 
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
    // [1729] call snprintf_init
    // [1204] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1730] phi from rom_verify::@7 to rom_verify::@15 [phi:rom_verify::@7->rom_verify::@15]
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1731] call printf_str
    // [1209] phi from rom_verify::@15 to printf_str [phi:rom_verify::@15->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:rom_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s [phi:rom_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1732] printf_ulong::uvalue#7 = rom_verify::rom_different_bytes#1 -- vdum1=vdum2 
    lda rom_different_bytes
    sta printf_ulong.uvalue
    lda rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1733] call printf_ulong
    // [1753] phi from rom_verify::@16 to printf_ulong [phi:rom_verify::@16->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:rom_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:rom_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:rom_verify::@16->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#7 [phi:rom_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1734] phi from rom_verify::@16 to rom_verify::@17 [phi:rom_verify::@16->rom_verify::@17]
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1735] call printf_str
    // [1209] phi from rom_verify::@17 to printf_str [phi:rom_verify::@17->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:rom_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s1 [phi:rom_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1736] printf_uchar::uvalue#15 = rom_verify::rom_bram_bank#10 -- vbum1=vbum2 
    lda rom_bram_bank
    sta printf_uchar.uvalue
    // [1737] call printf_uchar
    // [1346] phi from rom_verify::@18 to printf_uchar [phi:rom_verify::@18->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:rom_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 2 [phi:rom_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:rom_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:rom_verify::@18->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#15 [phi:rom_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1738] phi from rom_verify::@18 to rom_verify::@19 [phi:rom_verify::@18->rom_verify::@19]
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1739] call printf_str
    // [1209] phi from rom_verify::@19 to printf_str [phi:rom_verify::@19->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:rom_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s2 [phi:rom_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1740] printf_uint::uvalue#6 = (unsigned int)rom_verify::rom_bram_ptr#11 -- vwum1=vwuz2 
    lda.z rom_bram_ptr
    sta printf_uint.uvalue
    lda.z rom_bram_ptr+1
    sta printf_uint.uvalue+1
    // [1741] call printf_uint
    // [2098] phi from rom_verify::@20 to printf_uint [phi:rom_verify::@20->printf_uint]
    // [2098] phi printf_uint::format_zero_padding#10 = 1 [phi:rom_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2098] phi printf_uint::format_min_length#10 = 4 [phi:rom_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2098] phi printf_uint::putc#10 = &snputc [phi:rom_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2098] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:rom_verify::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2098] phi printf_uint::uvalue#10 = printf_uint::uvalue#6 [phi:rom_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1742] phi from rom_verify::@20 to rom_verify::@21 [phi:rom_verify::@20->rom_verify::@21]
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1743] call printf_str
    // [1209] phi from rom_verify::@21 to printf_str [phi:rom_verify::@21->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:rom_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s3 [phi:rom_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1744] printf_ulong::uvalue#8 = rom_verify::rom_address#1 -- vdum1=vdum2 
    lda rom_address
    sta printf_ulong.uvalue
    lda rom_address+1
    sta printf_ulong.uvalue+1
    lda rom_address+2
    sta printf_ulong.uvalue+2
    lda rom_address+3
    sta printf_ulong.uvalue+3
    // [1745] call printf_ulong
    // [1753] phi from rom_verify::@22 to printf_ulong [phi:rom_verify::@22->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:rom_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:rom_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:rom_verify::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#8 [phi:rom_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // rom_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1746] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1747] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1749] call display_action_text
    // [1357] phi from rom_verify::@23 to display_action_text [phi:rom_verify::@23->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:rom_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1700] phi from rom_verify::@23 to rom_verify::@1 [phi:rom_verify::@23->rom_verify::@1]
    // [1700] phi rom_verify::y#3 = rom_verify::y#11 [phi:rom_verify::@23->rom_verify::@1#0] -- register_copy 
    // [1700] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@23->rom_verify::@1#1] -- register_copy 
    // [1700] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@23->rom_verify::@1#2] -- register_copy 
    // [1700] phi rom_verify::rom_bram_ptr#10 = rom_verify::rom_bram_ptr#11 [phi:rom_verify::@23->rom_verify::@1#3] -- register_copy 
    // [1700] phi rom_verify::rom_bram_bank#11 = rom_verify::rom_bram_bank#10 [phi:rom_verify::@23->rom_verify::@1#4] -- register_copy 
    // [1700] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@23->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1750] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1751] callexecute cputc  -- call_vprc1 
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
    // [1754] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1755] ultoa::value#1 = printf_ulong::uvalue#15
    // [1756] ultoa::radix#0 = printf_ulong::format_radix#15
    // [1757] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1758] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1759] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#15
    // [1760] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#15
    // [1761] call printf_number_buffer
  // Print using format
    // [2718] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [2718] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [2718] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [2718] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [2718] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1762] return 
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
    .label rom_flash__29 = $79
    .label ram_address_sector = $a9
    .label ram_address = $5f
    // rom_flash::bank_set_bram1
    // BRAM = bank
    // [1764] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // [1765] phi from rom_flash::bank_set_bram1 to rom_flash::@19 [phi:rom_flash::bank_set_bram1->rom_flash::@19]
    // rom_flash::@19
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1766] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [903] phi from rom_flash::@19 to display_action_progress [phi:rom_flash::@19->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = string_0 [phi:rom_flash::@19->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<string_0
    sta.z display_action_progress.info_text
    lda #>string_0
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@20
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1767] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1768] call rom_address_from_bank
    // [2897] phi from rom_flash::@20 to rom_address_from_bank [phi:rom_flash::@20->rom_address_from_bank]
    // [2897] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@20->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1769] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@21
    // [1770] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1771] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1772] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1773] call display_info_rom
    // [1565] phi from rom_flash::@21 to display_info_rom [phi:rom_flash::@21->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = info_text1 [phi:rom_flash::@21->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#2 [phi:rom_flash::@21->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@21->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1774] phi from rom_flash::@21 to rom_flash::@1 [phi:rom_flash::@21->rom_flash::@1]
    // [1774] phi rom_flash::flash_errors#12 = 0 [phi:rom_flash::@21->rom_flash::@1#0] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1774] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@21->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1774] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@21->rom_flash::@1#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1774] phi rom_flash::ram_address_sector#11 = (char *)$7800 [phi:rom_flash::@21->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address_sector
    lda #>$7800
    sta.z ram_address_sector+1
    // [1774] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@21->rom_flash::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank_sector
    // [1774] phi rom_flash::rom_address_sector#13 = rom_flash::rom_address_sector#0 [phi:rom_flash::@21->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1775] if(rom_flash::rom_address_sector#13<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1776] display_action_text_flashed::bytes#2 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta display_action_text_flashed.bytes
    lda rom_address_sector+1
    sta display_action_text_flashed.bytes+1
    lda rom_address_sector+2
    sta display_action_text_flashed.bytes+2
    lda rom_address_sector+3
    sta display_action_text_flashed.bytes+3
    // [1777] call display_action_text_flashed
    // [2957] phi from rom_flash::@3 to display_action_text_flashed [phi:rom_flash::@3->display_action_text_flashed]
    // [2957] phi display_action_text_flashed::chip#3 = chip [phi:rom_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2957] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#2 [phi:rom_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1778] phi from rom_flash::@3 to rom_flash::@23 [phi:rom_flash::@3->rom_flash::@23]
    // rom_flash::@23
    // wait_moment(32)
    // [1779] call wait_moment
    // [1309] phi from rom_flash::@23 to wait_moment [phi:rom_flash::@23->wait_moment]
    // [1309] phi wait_moment::w#13 = $20 [phi:rom_flash::@23->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // rom_flash::@return
    // }
    // [1780] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1781] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_compare.bank_ram
    // [1782] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1783] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta rom_compare.rom_compare_address+3
    // [1784] call rom_compare
  // {asm{.byte $db}}
    // [2901] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2901] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2901] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwum1=vwuc1 
    lda #<$1000
    sta rom_compare.rom_compare_size
    lda #>$1000
    sta rom_compare.rom_compare_size+1
    // [2901] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2901] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1785] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@22
    // [1786] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1787] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwum1_neq_vwuc1_then_la1 
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
    // [1788] cputsxy::x#1 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta cputsxy.x
    // [1789] cputsxy::y#1 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputsxy.y
    // [1790] call cputsxy
    // [896] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [896] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [896] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [896] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1791] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1791] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1792] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1793] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#13 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1794] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1795] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbum1=_inc_vbum1 
    inc bram_bank_sector
    // [1796] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1796] phi rom_flash::bram_bank_sector#40 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1796] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1796] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1796] phi rom_flash::bram_bank_sector#40 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1796] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1797] if(rom_flash::ram_address_sector#8!=$9800) goto rom_flash::@36 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$9800
    bne __b14
    lda.z ram_address_sector
    cmp #<$9800
    bne __b14
    // [1799] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1799] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1799] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank_sector
    // [1798] phi from rom_flash::@13 to rom_flash::@36 [phi:rom_flash::@13->rom_flash::@36]
    // rom_flash::@36
    // [1799] phi from rom_flash::@36 to rom_flash::@14 [phi:rom_flash::@36->rom_flash::@14]
    // [1799] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@36->rom_flash::@14#0] -- register_copy 
    // [1799] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#40 [phi:rom_flash::@36->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1800] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1801] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
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
    // [1802] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1803] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1804] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1804] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1804] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1804] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1804] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1804] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1805] call snprintf_init
    // [1204] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@32
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1806] printf_ulong::uvalue#9 = rom_flash::flash_errors#10 -- vdum1=vdum2 
    lda flash_errors
    sta printf_ulong.uvalue
    lda flash_errors+1
    sta printf_ulong.uvalue+1
    lda flash_errors+2
    sta printf_ulong.uvalue+2
    lda flash_errors+3
    sta printf_ulong.uvalue+3
    // [1807] call printf_ulong
    // [1753] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = DECIMAL [phi:rom_flash::@32->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#9 [phi:rom_flash::@32->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1808] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1809] call printf_str
    // [1209] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = rom_flash::s2 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1810] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1811] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1813] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1814] call display_info_rom
    // [1565] phi from rom_flash::@34 to display_info_rom [phi:rom_flash::@34->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = info_text [phi:rom_flash::@34->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#3 [phi:rom_flash::@34->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@34->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1774] phi from rom_flash::@34 to rom_flash::@1 [phi:rom_flash::@34->rom_flash::@1]
    // [1774] phi rom_flash::flash_errors#12 = rom_flash::flash_errors#10 [phi:rom_flash::@34->rom_flash::@1#0] -- register_copy 
    // [1774] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@34->rom_flash::@1#1] -- register_copy 
    // [1774] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@34->rom_flash::@1#2] -- register_copy 
    // [1774] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@34->rom_flash::@1#3] -- register_copy 
    // [1774] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@34->rom_flash::@1#4] -- register_copy 
    // [1774] phi rom_flash::rom_address_sector#13 = rom_flash::rom_address_sector#1 [phi:rom_flash::@34->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1815] phi from rom_flash::@22 to rom_flash::@5 [phi:rom_flash::@22->rom_flash::@5]
  __b3:
    // [1815] phi rom_flash::flash_errors_sector#10 = 0 [phi:rom_flash::@22->rom_flash::@5#0] -- vwum1=vwuc1 
    lda #<0
    sta flash_errors_sector
    sta flash_errors_sector+1
    // [1815] phi rom_flash::retries#12 = 0 [phi:rom_flash::@22->rom_flash::@5#1] -- vbum1=vbuc1 
    sta retries
    // [1815] phi from rom_flash::@35 to rom_flash::@5 [phi:rom_flash::@35->rom_flash::@5]
    // [1815] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@35->rom_flash::@5#0] -- register_copy 
    // [1815] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@35->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1816] rom_sector_erase::address#0 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_sector_erase.address
    lda rom_address_sector+1
    sta rom_sector_erase.address+1
    lda rom_address_sector+2
    sta rom_sector_erase.address+2
    lda rom_address_sector+3
    sta rom_sector_erase.address+3
    // [1817] call rom_sector_erase
    // [2974] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@24
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1818] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#13 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1819] gotoxy::x#35 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [1820] gotoxy::y#35 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1821] call gotoxy
    // [801] phi from rom_flash::@24 to gotoxy [phi:rom_flash::@24->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#35 [phi:rom_flash::@24->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#35 [phi:rom_flash::@24->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1822] phi from rom_flash::@24 to rom_flash::@25 [phi:rom_flash::@24->rom_flash::@25]
    // rom_flash::@25
    // printf("........")
    // [1823] call printf_str
    // [1209] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [1209] phi printf_str::putc#84 = &cputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = rom_flash::s1 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // [1824] rom_flash::rom_address#16 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_address
    lda rom_address_sector+1
    sta rom_address+1
    lda rom_address_sector+2
    sta rom_address+2
    lda rom_address_sector+3
    sta rom_address+3
    // [1825] rom_flash::ram_address#16 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1826] rom_flash::x#16 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta x
    // [1827] phi from rom_flash::@10 rom_flash::@26 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6]
    // [1827] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#0] -- register_copy 
    // [1827] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#1] -- register_copy 
    // [1827] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#7 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#2] -- register_copy 
    // [1827] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1828] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vdum1_lt_vdum2_then_la1 
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
    // [1829] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors_sector && retries <= 3)
    // [1830] if(0==rom_flash::flash_errors_sector#11) goto rom_flash::@12 -- 0_eq_vwum1_then_la1 
    lda flash_errors_sector
    ora flash_errors_sector+1
    beq __b12
    // rom_flash::@35
    // [1831] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1832] rom_flash::flash_errors#1 = rom_flash::flash_errors#12 + rom_flash::flash_errors_sector#11 -- vdum1=vdum1_plus_vwum2 
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
    // [1833] display_action_text_flashing::bram_bank#2 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta display_action_text_flashing.bram_bank
    // [1834] display_action_text_flashing::bram_ptr#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z display_action_text_flashing.bram_ptr
    lda.z ram_address_sector+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1835] display_action_text_flashing::address#2 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta display_action_text_flashing.address
    lda rom_address_sector+1
    sta display_action_text_flashing.address+1
    lda rom_address_sector+2
    sta display_action_text_flashing.address+2
    lda rom_address_sector+3
    sta display_action_text_flashing.address+3
    // [1836] call display_action_text_flashing
    // [2986] phi from rom_flash::@7 to display_action_text_flashing [phi:rom_flash::@7->display_action_text_flashing]
    // [2986] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#2 [phi:rom_flash::@7->display_action_text_flashing#0] -- register_copy 
    // [2986] phi display_action_text_flashing::chip#10 = chip [phi:rom_flash::@7->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2986] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#2 [phi:rom_flash::@7->display_action_text_flashing#2] -- register_copy 
    // [2986] phi display_action_text_flashing::bram_bank#3 = display_action_text_flashing::bram_bank#2 [phi:rom_flash::@7->display_action_text_flashing#3] -- register_copy 
    // [2986] phi display_action_text_flashing::bytes#3 = $1000 [phi:rom_flash::@7->display_action_text_flashing#4] -- vdum1=vduc1 
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
    // [1837] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_write.flash_ram_bank
    // [1838] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1839] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vdum1=vdum2 
    lda rom_address
    sta rom_write.flash_rom_address
    lda rom_address+1
    sta rom_write.flash_rom_address+1
    lda rom_address+2
    sta rom_write.flash_rom_address+2
    lda rom_address+3
    sta rom_write.flash_rom_address+3
    // [1840] call rom_write
    jsr rom_write
    // rom_flash::@28
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1841] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_compare.bank_ram
    // [1842] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1843] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vdum1=vdum2 
    lda rom_address
    sta rom_compare.rom_compare_address
    lda rom_address+1
    sta rom_compare.rom_compare_address+1
    lda rom_address+2
    sta rom_compare.rom_compare_address+2
    lda rom_address+3
    sta rom_compare.rom_compare_address+3
    // [1844] call rom_compare
    // [2901] phi from rom_flash::@28 to rom_compare [phi:rom_flash::@28->rom_compare]
    // [2901] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@28->rom_compare#0] -- register_copy 
    // [2901] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@28->rom_compare#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size+1
    // [2901] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@28->rom_compare#2] -- register_copy 
    // [2901] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@28->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1845] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@29
    // equal_bytes = rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1846] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwum1=vwum2 
    lda rom_compare.return
    sta equal_bytes_1
    lda rom_compare.return+1
    sta equal_bytes_1+1
    // gotoxy(x, y)
    // [1847] gotoxy::x#36 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1848] gotoxy::y#36 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1849] call gotoxy
    // [801] phi from rom_flash::@29 to gotoxy [phi:rom_flash::@29->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#36 [phi:rom_flash::@29->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#36 [phi:rom_flash::@29->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@30
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1850] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1851] cputcxy::x#16 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1852] cputcxy::y#16 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1853] call cputcxy
    // [2305] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [2305] phi cputcxy::c#17 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [2305] phi cputcxy::y#17 = cputcxy::y#16 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#16 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1854] phi from rom_flash::@11 rom_flash::@31 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10]
    // [1854] phi rom_flash::flash_errors_sector#7 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1855] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1856] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
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
    // [1857] rom_flash::x#1 = ++ rom_flash::x#10 -- vbum1=_inc_vbum1 
    inc x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1858] cputcxy::x#15 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1859] cputcxy::y#15 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1860] call cputcxy
    // [2305] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [2305] phi cputcxy::c#17 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'!'
    sta cputcxy.c
    // [2305] phi cputcxy::y#17 = cputcxy::y#15 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#15 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@31
    // flash_errors_sector++;
    // [1861] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#11 -- vwum1=_inc_vwum1 
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
    .label smc_flash__29 = $70
    .label smc_flash__30 = $70
    .label smc_bram_ptr = $72
    // smc_flash::bank_set_bram1
    // BRAM = bank
    // [1863] BRAM = smc_flash::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1864] phi from smc_flash::bank_set_bram1 to smc_flash::@24 [phi:smc_flash::bank_set_bram1->smc_flash::@24]
    // smc_flash::@24
    // display_action_progress("To start the SMC update, do the following ...")
    // [1865] call display_action_progress
    // [903] phi from smc_flash::@24 to display_action_progress [phi:smc_flash::@24->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = smc_flash::info_text [phi:smc_flash::@24->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@28
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1866] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1867] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1868] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1869] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1871] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbum1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta cx16_k_i2c_write_byte1_return
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1872] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1873] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [1874] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbum1_then_la1 
    lda smc_bootloader_start
    beq __b6
    // [1875] phi from smc_flash::@25 to smc_flash::@2 [phi:smc_flash::@25->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1876] call snprintf_init
    // [1204] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1877] phi from smc_flash::@2 to smc_flash::@29 [phi:smc_flash::@2->smc_flash::@29]
    // smc_flash::@29
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1878] call printf_str
    // [1209] phi from smc_flash::@29 to printf_str [phi:smc_flash::@29->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = smc_flash::s [phi:smc_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1879] printf_uchar::uvalue#10 = smc_flash::smc_bootloader_start#0 -- vbum1=vbum2 
    lda smc_bootloader_start
    sta printf_uchar.uvalue
    // [1880] call printf_uchar
    // [1346] phi from smc_flash::@30 to printf_uchar [phi:smc_flash::@30->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_flash::@30->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:smc_flash::@30->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:smc_flash::@30->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:smc_flash::@30->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#10 [phi:smc_flash::@30->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1881] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1882] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1884] call display_action_text
    // [1357] phi from smc_flash::@31 to display_action_text [phi:smc_flash::@31->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@31->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@32
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1885] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1886] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1887] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1888] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1890] phi from smc_flash::@50 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@50/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1890] phi smc_flash::return#1 = 0 [phi:smc_flash::@50/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // smc_flash::@return
    // }
    // [1891] return 
    rts
    // [1892] phi from smc_flash::@25 to smc_flash::@3 [phi:smc_flash::@25->smc_flash::@3]
  __b6:
    // [1892] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@25->smc_flash::@3#0] -- vbum1=vbuc1 
    lda #$80
    sta smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1893] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1894] phi from smc_flash::@3 smc_flash::@33 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@33->smc_flash::@7]
  __b9:
    // [1894] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@33->smc_flash::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1895] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1896] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1897] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1898] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1899] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@45
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1900] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#12
    // if(smc_bootloader_not_activated)
    // [1901] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwum1_then_la1 
    lda smc_bootloader_not_activated
    ora smc_bootloader_not_activated+1
    beq __b1
    // [1902] phi from smc_flash::@45 to smc_flash::@10 [phi:smc_flash::@45->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1903] call snprintf_init
    // [1204] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1904] phi from smc_flash::@10 to smc_flash::@48 [phi:smc_flash::@10->smc_flash::@48]
    // smc_flash::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1905] call printf_str
    // [1209] phi from smc_flash::@48 to printf_str [phi:smc_flash::@48->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_flash::@48->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = smc_flash::s5 [phi:smc_flash::@48->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@49
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1906] printf_uint::uvalue#4 = smc_flash::smc_bootloader_not_activated#1
    // [1907] call printf_uint
    // [2098] phi from smc_flash::@49 to printf_uint [phi:smc_flash::@49->printf_uint]
    // [2098] phi printf_uint::format_zero_padding#10 = 0 [phi:smc_flash::@49->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2098] phi printf_uint::format_min_length#10 = 0 [phi:smc_flash::@49->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2098] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@49->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2098] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@49->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2098] phi printf_uint::uvalue#10 = printf_uint::uvalue#4 [phi:smc_flash::@49->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@50
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1908] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1909] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1911] call display_action_text
    // [1357] phi from smc_flash::@50 to display_action_text [phi:smc_flash::@50->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@50->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1912] phi from smc_flash::@45 to smc_flash::@1 [phi:smc_flash::@45->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1913] call display_action_progress
    // [903] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1914] phi from smc_flash::@1 to smc_flash::@46 [phi:smc_flash::@1->smc_flash::@46]
    // smc_flash::@46
    // textcolor(WHITE)
    // [1915] call textcolor
    // [783] phi from smc_flash::@46 to textcolor [phi:smc_flash::@46->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:smc_flash::@46->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1916] phi from smc_flash::@46 to smc_flash::@47 [phi:smc_flash::@46->smc_flash::@47]
    // smc_flash::@47
    // gotoxy(x, y)
    // [1917] call gotoxy
    // [801] phi from smc_flash::@47 to gotoxy [phi:smc_flash::@47->gotoxy]
    // [801] phi gotoxy::y#37 = PROGRESS_Y [phi:smc_flash::@47->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:smc_flash::@47->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1918] phi from smc_flash::@47 to smc_flash::@11 [phi:smc_flash::@47->smc_flash::@11]
    // [1918] phi smc_flash::y#36 = PROGRESS_Y [phi:smc_flash::@47->smc_flash::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1918] phi smc_flash::smc_row_bytes#16 = 0 [phi:smc_flash::@47->smc_flash::@11#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1918] phi smc_flash::smc_bram_ptr#14 = (char *)$a000 [phi:smc_flash::@47->smc_flash::@11#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // [1918] phi smc_flash::smc_bytes_flashed#13 = 0 [phi:smc_flash::@47->smc_flash::@11#3] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [1918] phi from smc_flash::@15 to smc_flash::@11 [phi:smc_flash::@15->smc_flash::@11]
    // [1918] phi smc_flash::y#36 = smc_flash::y#21 [phi:smc_flash::@15->smc_flash::@11#0] -- register_copy 
    // [1918] phi smc_flash::smc_row_bytes#16 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@15->smc_flash::@11#1] -- register_copy 
    // [1918] phi smc_flash::smc_bram_ptr#14 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@15->smc_flash::@11#2] -- register_copy 
    // [1918] phi smc_flash::smc_bytes_flashed#13 = smc_flash::smc_bytes_flashed#12 [phi:smc_flash::@15->smc_flash::@11#3] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1919] if(smc_flash::smc_bytes_flashed#13<smc_flash::smc_bytes_total#0) goto smc_flash::@13 -- vwum1_lt_vwum2_then_la1 
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
    // [1920] display_action_text_flashed::bytes#1 = smc_flash::smc_bytes_flashed#13 -- vdum1=vwum2 
    lda smc_bytes_flashed
    sta display_action_text_flashed.bytes
    lda smc_bytes_flashed+1
    sta display_action_text_flashed.bytes+1
    lda #0
    sta display_action_text_flashed.bytes+2
    sta display_action_text_flashed.bytes+3
    // [1921] call display_action_text_flashed
    // [2957] phi from smc_flash::@12 to display_action_text_flashed [phi:smc_flash::@12->display_action_text_flashed]
    // [2957] phi display_action_text_flashed::chip#3 = smc_flash::chip [phi:smc_flash::@12->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2957] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#1 [phi:smc_flash::@12->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1890] phi from smc_flash::@12 to smc_flash::@return [phi:smc_flash::@12->smc_flash::@return]
    // [1890] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#13 [phi:smc_flash::@12->smc_flash::@return#0] -- register_copy 
    rts
    // [1922] phi from smc_flash::@11 to smc_flash::@13 [phi:smc_flash::@11->smc_flash::@13]
  __b10:
    // [1922] phi smc_flash::y#21 = smc_flash::y#36 [phi:smc_flash::@11->smc_flash::@13#0] -- register_copy 
    // [1922] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#16 [phi:smc_flash::@11->smc_flash::@13#1] -- register_copy 
    // [1922] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#13 [phi:smc_flash::@11->smc_flash::@13#2] -- register_copy 
    // [1922] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#14 [phi:smc_flash::@11->smc_flash::@13#3] -- register_copy 
    // [1922] phi smc_flash::smc_attempts_flashed#15 = 0 [phi:smc_flash::@11->smc_flash::@13#4] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1922] phi smc_flash::smc_package_committed#10 = 0 [phi:smc_flash::@11->smc_flash::@13#5] -- vbum1=vbuc1 
    sta smc_package_committed
    // smc_flash::@13
  __b13:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1923] if(0!=smc_flash::smc_package_committed#10) goto smc_flash::@15 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b15
    // smc_flash::@55
    // [1924] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b14
    // smc_flash::@15
  __b15:
    // if(smc_attempts_flashed >= 10)
    // [1925] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1926] phi from smc_flash::@15 to smc_flash::@23 [phi:smc_flash::@15->smc_flash::@23]
    // smc_flash::@23
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1927] call snprintf_init
    // [1204] phi from smc_flash::@23 to snprintf_init [phi:smc_flash::@23->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:smc_flash::@23->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1928] phi from smc_flash::@23 to smc_flash::@52 [phi:smc_flash::@23->smc_flash::@52]
    // smc_flash::@52
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1929] call printf_str
    // [1209] phi from smc_flash::@52 to printf_str [phi:smc_flash::@52->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_flash::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = smc_flash::s6 [phi:smc_flash::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@53
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1930] printf_uint::uvalue#5 = smc_flash::smc_bytes_flashed#12 -- vwum1=vwum2 
    lda smc_bytes_flashed
    sta printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1931] call printf_uint
    // [2098] phi from smc_flash::@53 to printf_uint [phi:smc_flash::@53->printf_uint]
    // [2098] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_flash::@53->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2098] phi printf_uint::format_min_length#10 = 4 [phi:smc_flash::@53->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2098] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2098] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@53->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2098] phi printf_uint::uvalue#10 = printf_uint::uvalue#5 [phi:smc_flash::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@54
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1932] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1933] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1935] call display_action_text
    // [1357] phi from smc_flash::@54 to display_action_text [phi:smc_flash::@54->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@54->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1890] phi from smc_flash::@54 to smc_flash::@return [phi:smc_flash::@54->smc_flash::@return]
    // [1890] phi smc_flash::return#1 = $ffff [phi:smc_flash::@54->smc_flash::@return#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta return
    lda #>$ffff
    sta return+1
    rts
    // smc_flash::@14
  __b14:
    // display_action_text_flashing(8, "SMC", smc_bram_bank, smc_bram_ptr, smc_bytes_flashed)
    // [1936] display_action_text_flashing::bram_ptr#1 = smc_flash::smc_bram_ptr#12 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1937] display_action_text_flashing::address#1 = smc_flash::smc_bytes_flashed#12 -- vdum1=vwum2 
    lda smc_bytes_flashed
    sta display_action_text_flashing.address
    lda smc_bytes_flashed+1
    sta display_action_text_flashing.address+1
    lda #0
    sta display_action_text_flashing.address+2
    sta display_action_text_flashing.address+3
    // [1938] call display_action_text_flashing
    // [2986] phi from smc_flash::@14 to display_action_text_flashing [phi:smc_flash::@14->display_action_text_flashing]
    // [2986] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#1 [phi:smc_flash::@14->display_action_text_flashing#0] -- register_copy 
    // [2986] phi display_action_text_flashing::chip#10 = smc_flash::chip [phi:smc_flash::@14->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2986] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#1 [phi:smc_flash::@14->display_action_text_flashing#2] -- register_copy 
    // [2986] phi display_action_text_flashing::bram_bank#3 = smc_flash::smc_bram_bank [phi:smc_flash::@14->display_action_text_flashing#3] -- vbum1=vbuc1 
    lda #smc_bram_bank
    sta display_action_text_flashing.bram_bank
    // [2986] phi display_action_text_flashing::bytes#3 = 8 [phi:smc_flash::@14->display_action_text_flashing#4] -- vdum1=vbuc1 
    lda #8
    sta display_action_text_flashing.bytes
    lda #0
    sta display_action_text_flashing.bytes+1
    sta display_action_text_flashing.bytes+2
    sta display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [1939] phi from smc_flash::@14 to smc_flash::@16 [phi:smc_flash::@14->smc_flash::@16]
    // [1939] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@14->smc_flash::@16#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [1939] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@14->smc_flash::@16#1] -- register_copy 
    // [1939] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@14->smc_flash::@16#2] -- vwum1=vwuc1 
    sta smc_package_flashed
    sta smc_package_flashed+1
    // smc_flash::@16
  __b16:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1940] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@17 -- vwum1_lt_vbuc1_then_la1 
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
    // [1941] smc_flash::$29 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbum2_bxor_vbuc1 
    lda #$ff
    eor smc_bytes_checksum
    sta.z smc_flash__29
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1942] smc_flash::$30 = smc_flash::$29 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z smc_flash__30
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1943] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1944] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1945] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$30 -- vbum1=vbuz2 
    lda.z smc_flash__30
    sta cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1946] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [1948] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1949] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1950] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1951] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@51
    // [1952] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#13
    // if(smc_commit_result == 1)
    // [1953] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@20 -- vwum1_eq_vbuc1_then_la1 
    lda smc_commit_result+1
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b20
  !:
    // smc_flash::@19
    // smc_bram_ptr -= SMC_PROGRESS_CELL
    // [1954] smc_flash::smc_bram_ptr#2 = smc_flash::smc_bram_ptr#10 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_bram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    sbc #0
    sta.z smc_bram_ptr+1
    // smc_attempts_flashed++;
    // [1955] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#15 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1922] phi from smc_flash::@19 to smc_flash::@13 [phi:smc_flash::@19->smc_flash::@13]
    // [1922] phi smc_flash::y#21 = smc_flash::y#21 [phi:smc_flash::@19->smc_flash::@13#0] -- register_copy 
    // [1922] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@19->smc_flash::@13#1] -- register_copy 
    // [1922] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#12 [phi:smc_flash::@19->smc_flash::@13#2] -- register_copy 
    // [1922] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#2 [phi:smc_flash::@19->smc_flash::@13#3] -- register_copy 
    // [1922] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@19->smc_flash::@13#4] -- register_copy 
    // [1922] phi smc_flash::smc_package_committed#10 = smc_flash::smc_package_committed#10 [phi:smc_flash::@19->smc_flash::@13#5] -- register_copy 
    jmp __b13
    // smc_flash::@20
  __b20:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1956] if(smc_flash::smc_row_bytes#11!=SMC_PROGRESS_ROW) goto smc_flash::@21 -- vwum1_neq_vwuc1_then_la1 
    lda smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b21
    lda smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b21
    // smc_flash::@22
    // gotoxy(x, ++y);
    // [1957] smc_flash::y#1 = ++ smc_flash::y#21 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1958] gotoxy::y#29 = smc_flash::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1959] call gotoxy
    // [801] phi from smc_flash::@22 to gotoxy [phi:smc_flash::@22->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#29 [phi:smc_flash::@22->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:smc_flash::@22->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1960] phi from smc_flash::@22 to smc_flash::@21 [phi:smc_flash::@22->smc_flash::@21]
    // [1960] phi smc_flash::y#38 = smc_flash::y#1 [phi:smc_flash::@22->smc_flash::@21#0] -- register_copy 
    // [1960] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@22->smc_flash::@21#1] -- vwum1=vbuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1960] phi from smc_flash::@20 to smc_flash::@21 [phi:smc_flash::@20->smc_flash::@21]
    // [1960] phi smc_flash::y#38 = smc_flash::y#21 [phi:smc_flash::@20->smc_flash::@21#0] -- register_copy 
    // [1960] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@20->smc_flash::@21#1] -- register_copy 
    // smc_flash::@21
  __b21:
    // cputc('+')
    // [1961] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1962] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1964] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#12 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1965] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_row_bytes
    sta smc_row_bytes
    bcc !+
    inc smc_row_bytes+1
  !:
    // [1922] phi from smc_flash::@21 to smc_flash::@13 [phi:smc_flash::@21->smc_flash::@13]
    // [1922] phi smc_flash::y#21 = smc_flash::y#38 [phi:smc_flash::@21->smc_flash::@13#0] -- register_copy 
    // [1922] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@21->smc_flash::@13#1] -- register_copy 
    // [1922] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@21->smc_flash::@13#2] -- register_copy 
    // [1922] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#10 [phi:smc_flash::@21->smc_flash::@13#3] -- register_copy 
    // [1922] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#15 [phi:smc_flash::@21->smc_flash::@13#4] -- register_copy 
    // [1922] phi smc_flash::smc_package_committed#10 = 1 [phi:smc_flash::@21->smc_flash::@13#5] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b13
    // smc_flash::@17
  __b17:
    // unsigned char smc_byte_upload = *smc_bram_ptr
    // [1966] smc_flash::smc_byte_upload#0 = *smc_flash::smc_bram_ptr#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_bram_ptr),y
    sta smc_byte_upload
    // smc_bram_ptr++;
    // [1967] smc_flash::smc_bram_ptr#1 = ++ smc_flash::smc_bram_ptr#10 -- pbuz1=_inc_pbuz1 
    inc.z smc_bram_ptr
    bne !+
    inc.z smc_bram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1968] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbum1=vbum1_plus_vbum2 
    lda smc_bytes_checksum
    clc
    adc smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1969] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1970] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1971] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1972] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [1974] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwum1=_inc_vwum1 
    inc smc_package_flashed
    bne !+
    inc smc_package_flashed+1
  !:
    // [1939] phi from smc_flash::@26 to smc_flash::@16 [phi:smc_flash::@26->smc_flash::@16]
    // [1939] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@26->smc_flash::@16#0] -- register_copy 
    // [1939] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#1 [phi:smc_flash::@26->smc_flash::@16#1] -- register_copy 
    // [1939] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@26->smc_flash::@16#2] -- register_copy 
    jmp __b16
    // [1975] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment(1)
    // [1976] call wait_moment
    // [1309] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    // [1309] phi wait_moment::w#13 = 1 [phi:smc_flash::@8->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [1977] phi from smc_flash::@8 to smc_flash::@39 [phi:smc_flash::@8->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1978] call snprintf_init
    // [1204] phi from smc_flash::@39 to snprintf_init [phi:smc_flash::@39->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:smc_flash::@39->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1979] phi from smc_flash::@39 to smc_flash::@40 [phi:smc_flash::@39->smc_flash::@40]
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1980] call printf_str
    // [1209] phi from smc_flash::@40 to printf_str [phi:smc_flash::@40->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_flash::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = smc_flash::s3 [phi:smc_flash::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@41
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1981] printf_uchar::uvalue#12 = smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta printf_uchar.uvalue
    // [1982] call printf_uchar
    // [1346] phi from smc_flash::@41 to printf_uchar [phi:smc_flash::@41->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_flash::@41->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:smc_flash::@41->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:smc_flash::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_flash::@41->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#12 [phi:smc_flash::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1983] phi from smc_flash::@41 to smc_flash::@42 [phi:smc_flash::@41->smc_flash::@42]
    // smc_flash::@42
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1984] call printf_str
    // [1209] phi from smc_flash::@42 to printf_str [phi:smc_flash::@42->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_flash::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s6 [phi:smc_flash::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s6
    sta.z printf_str.s
    lda #>@s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@43
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1985] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1986] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1988] call display_action_text
    // [1357] phi from smc_flash::@43 to display_action_text [phi:smc_flash::@43->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@43->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@44
    // smc_bootloader_activation_countdown--;
    // [1989] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1894] phi from smc_flash::@44 to smc_flash::@7 [phi:smc_flash::@44->smc_flash::@7]
    // [1894] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@44->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1990] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1991] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1992] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1993] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@33
    // [1994] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#11
    // if(smc_bootloader_not_activated)
    // [1995] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1996] phi from smc_flash::@33 to smc_flash::@5 [phi:smc_flash::@33->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment(1)
    // [1997] call wait_moment
    // [1309] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    // [1309] phi wait_moment::w#13 = 1 [phi:smc_flash::@5->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [1998] phi from smc_flash::@5 to smc_flash::@34 [phi:smc_flash::@5->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1999] call snprintf_init
    // [1204] phi from smc_flash::@34 to snprintf_init [phi:smc_flash::@34->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:smc_flash::@34->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2000] phi from smc_flash::@34 to smc_flash::@35 [phi:smc_flash::@34->smc_flash::@35]
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2001] call printf_str
    // [1209] phi from smc_flash::@35 to printf_str [phi:smc_flash::@35->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_flash::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s21 [phi:smc_flash::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@36
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2002] printf_uchar::uvalue#11 = smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown
    sta printf_uchar.uvalue
    // [2003] call printf_uchar
    // [1346] phi from smc_flash::@36 to printf_uchar [phi:smc_flash::@36->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:smc_flash::@36->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 3 [phi:smc_flash::@36->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:smc_flash::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_flash::@36->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#11 [phi:smc_flash::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2004] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2005] call printf_str
    // [1209] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = smc_flash::s2 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2006] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2007] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2009] call display_action_text
    // [1357] phi from smc_flash::@38 to display_action_text [phi:smc_flash::@38->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@38->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [2010] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1892] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1892] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
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
    .label smc_bootloader_not_activated1 = smc_detect.return
    // Waiting a bit to ensure the bootloader is activated.
    smc_bootloader_activation_countdown: .byte 0
    // Waiting a bit to ensure the bootloader is activated.
    smc_bootloader_activation_countdown_1: .byte 0
    .label smc_bootloader_not_activated = smc_detect.return
    smc_byte_upload: .byte 0
    smc_bytes_checksum: .byte 0
    smc_package_flashed: .word 0
    .label smc_commit_result = smc_detect.return
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
// __mem() char util_wait_key(__zp($3a) char *info_text, __zp($58) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__9 = $63
    .label info_text = $3a
    .label filter = $58
    // display_action_text(info_text)
    // [2012] display_action_text::info_text#10 = util_wait_key::info_text#3
    // [2013] call display_action_text
    // [1357] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1357] phi display_action_text::info_text#25 = display_action_text::info_text#10 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [2014] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [2015] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [2016] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [2017] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [2018] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [2020] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [2021] call cbm_k_getin
    jsr cbm_k_getin
    // [2022] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [2023] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbum2 
    lda cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [2024] if((char *)0!=util_wait_key::filter#13) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [2025] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [2026] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [2027] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [2028] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [2029] strchr::str#0 = (const void *)util_wait_key::filter#13 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [2030] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [2031] call strchr
    // [2035] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [2035] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [2035] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [2032] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [2033] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [2034] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
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
// __zp($63) void * strchr(__zp($63) const void *str, __mem() char c)
strchr: {
    .label ptr = $63
    .label return = $63
    .label str = $63
    // [2036] strchr::ptr#6 = (char *)strchr::str#2
    // [2037] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [2037] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [2038] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [2039] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [2039] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [2040] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [2041] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [2042] strchr::return#8 = (void *)strchr::ptr#2
    // [2039] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [2039] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [2043] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
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
// void display_info_cx16_rom(__mem() char info_status, __zp($3c) char *info_text)
display_info_cx16_rom: {
    .label info_text = $3c
    // display_info_rom(0, info_status, info_text)
    // [2045] display_info_rom::info_status#0 = display_info_cx16_rom::info_status#4
    // [2046] display_info_rom::info_text#0 = display_info_cx16_rom::info_text#4
    // [2047] call display_info_rom
    // [1565] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = display_info_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1565] phi display_info_rom::rom_chip#17 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbum1=vbuc1 
    lda #0
    sta display_info_rom.rom_chip
    // [1565] phi display_info_rom::info_status#17 = display_info_rom::info_status#0 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [2048] return 
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
// void rom_get_github_commit_id(__zp($38) char *commit_id, __zp($3c) char *from)
rom_get_github_commit_id: {
    .label commit_id = $38
    .label from = $3c
    // [2050] phi from rom_get_github_commit_id to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2]
    // [2050] phi rom_get_github_commit_id::commit_id_ok#2 = true [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#0] -- vbom1=vboc1 
    lda #1
    sta commit_id_ok
    // [2050] phi rom_get_github_commit_id::c#2 = 0 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#1] -- vbum1=vbuc1 
    lda #0
    sta c
    // rom_get_github_commit_id::@2
  __b2:
    // for(unsigned char c=0; c<7; c++)
    // [2051] if(rom_get_github_commit_id::c#2<7) goto rom_get_github_commit_id::@3 -- vbum1_lt_vbuc1_then_la1 
    lda c
    cmp #7
    bcc __b3
    // rom_get_github_commit_id::@4
    // if(commit_id_ok)
    // [2052] if(rom_get_github_commit_id::commit_id_ok#2) goto rom_get_github_commit_id::@1 -- vbom1_then_la1 
    lda commit_id_ok
    cmp #0
    bne __b1
    // rom_get_github_commit_id::@6
    // *commit_id = '\0'
    // [2053] *rom_get_github_commit_id::commit_id#6 = '@' -- _deref_pbuz1=vbuc1 
    lda #'@'
    ldy #0
    sta (commit_id),y
    // rom_get_github_commit_id::@return
    // }
    // [2054] return 
    rts
    // rom_get_github_commit_id::@1
  __b1:
    // strncpy(commit_id, from, 7)
    // [2055] strncpy::dst#2 = rom_get_github_commit_id::commit_id#6
    // [2056] strncpy::src#2 = rom_get_github_commit_id::from#6
    // [2057] call strncpy
    // [3033] phi from rom_get_github_commit_id::@1 to strncpy [phi:rom_get_github_commit_id::@1->strncpy]
    // [3033] phi strncpy::dst#8 = strncpy::dst#2 [phi:rom_get_github_commit_id::@1->strncpy#0] -- register_copy 
    // [3033] phi strncpy::src#6 = strncpy::src#2 [phi:rom_get_github_commit_id::@1->strncpy#1] -- register_copy 
    // [3033] phi strncpy::n#3 = 7 [phi:rom_get_github_commit_id::@1->strncpy#2] -- vwum1=vbuc1 
    lda #<7
    sta strncpy.n
    lda #>7
    sta strncpy.n+1
    jsr strncpy
    rts
    // rom_get_github_commit_id::@3
  __b3:
    // unsigned char ch = from[c]
    // [2058] rom_get_github_commit_id::ch#0 = rom_get_github_commit_id::from#6[rom_get_github_commit_id::c#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy c
    lda (from),y
    sta ch
    // if(!(ch >= 48 && ch <= 48+9 || ch >= 65 && ch <= 65+26))
    // [2059] if(rom_get_github_commit_id::ch#0<$30) goto rom_get_github_commit_id::@7 -- vbum1_lt_vbuc1_then_la1 
    cmp #$30
    bcc __b7
    // rom_get_github_commit_id::@8
    // [2060] if(rom_get_github_commit_id::ch#0<$30+9+1) goto rom_get_github_commit_id::@5 -- vbum1_lt_vbuc1_then_la1 
    cmp #$30+9+1
    bcc __b5
    // rom_get_github_commit_id::@7
  __b7:
    // [2061] if(rom_get_github_commit_id::ch#0<$41) goto rom_get_github_commit_id::@5 -- vbum1_lt_vbuc1_then_la1 
    lda ch
    cmp #$41
    bcc __b4
    // rom_get_github_commit_id::@9
    // [2062] if(rom_get_github_commit_id::ch#0<$41+$1a+1) goto rom_get_github_commit_id::@10 -- vbum1_lt_vbuc1_then_la1 
    cmp #$41+$1a+1
    bcc __b5
    // [2064] phi from rom_get_github_commit_id::@7 rom_get_github_commit_id::@9 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5]
  __b4:
    // [2064] phi rom_get_github_commit_id::commit_id_ok#4 = false [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5#0] -- vbom1=vboc1 
    lda #0
    sta commit_id_ok
    // [2063] phi from rom_get_github_commit_id::@9 to rom_get_github_commit_id::@10 [phi:rom_get_github_commit_id::@9->rom_get_github_commit_id::@10]
    // rom_get_github_commit_id::@10
    // [2064] phi from rom_get_github_commit_id::@10 rom_get_github_commit_id::@8 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5]
    // [2064] phi rom_get_github_commit_id::commit_id_ok#4 = rom_get_github_commit_id::commit_id_ok#2 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5#0] -- register_copy 
    // rom_get_github_commit_id::@5
  __b5:
    // for(unsigned char c=0; c<7; c++)
    // [2065] rom_get_github_commit_id::c#1 = ++ rom_get_github_commit_id::c#2 -- vbum1=_inc_vbum1 
    inc c
    // [2050] phi from rom_get_github_commit_id::@5 to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2]
    // [2050] phi rom_get_github_commit_id::commit_id_ok#2 = rom_get_github_commit_id::commit_id_ok#4 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#0] -- register_copy 
    // [2050] phi rom_get_github_commit_id::c#2 = rom_get_github_commit_id::c#1 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#1] -- register_copy 
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
    .label rom_get_release__0 = $7f
    .label rom_get_release__2 = $c6
    // release & 0x80
    // [2067] rom_get_release::$0 = rom_get_release::release#3 & $80 -- vbuz1=vbum2_band_vbuc1 
    lda #$80
    and release
    sta.z rom_get_release__0
    // if(release & 0x80)
    // [2068] if(0==rom_get_release::$0) goto rom_get_release::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // rom_get_release::@2
    // ~release
    // [2069] rom_get_release::$2 = ~ rom_get_release::release#3 -- vbuz1=_bnot_vbum2 
    lda release
    eor #$ff
    sta.z rom_get_release__2
    // release = ~release + 1
    // [2070] rom_get_release::release#0 = rom_get_release::$2 + 1 -- vbum1=vbuz2_plus_1 
    inc
    sta release
    // [2071] phi from rom_get_release rom_get_release::@2 to rom_get_release::@1 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1]
    // [2071] phi rom_get_release::return#0 = rom_get_release::release#3 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1#0] -- register_copy 
    // rom_get_release::@1
  __b1:
    // rom_get_release::@return
    // }
    // [2072] return 
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
    .label rom_get_prefix__2 = $c6
    // if(release == 0xFF)
    // [2074] if(rom_get_prefix::release#2!=$ff) goto rom_get_prefix::@1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp release
    bne __b3
    // [2075] phi from rom_get_prefix to rom_get_prefix::@3 [phi:rom_get_prefix->rom_get_prefix::@3]
    // rom_get_prefix::@3
    // [2076] phi from rom_get_prefix::@3 to rom_get_prefix::@1 [phi:rom_get_prefix::@3->rom_get_prefix::@1]
    // [2076] phi rom_get_prefix::prefix#4 = 'p' [phi:rom_get_prefix::@3->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'p'
    sta prefix
    jmp __b1
    // [2076] phi from rom_get_prefix to rom_get_prefix::@1 [phi:rom_get_prefix->rom_get_prefix::@1]
  __b3:
    // [2076] phi rom_get_prefix::prefix#4 = 'r' [phi:rom_get_prefix->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'r'
    sta prefix
    // rom_get_prefix::@1
  __b1:
    // release & 0x80
    // [2077] rom_get_prefix::$2 = rom_get_prefix::release#2 & $80 -- vbuz1=vbum2_band_vbuc1 
    lda #$80
    and release
    sta.z rom_get_prefix__2
    // if(release & 0x80)
    // [2078] if(0==rom_get_prefix::$2) goto rom_get_prefix::@4 -- 0_eq_vbuz1_then_la1 
    beq __b2
    // [2080] phi from rom_get_prefix::@1 to rom_get_prefix::@2 [phi:rom_get_prefix::@1->rom_get_prefix::@2]
    // [2080] phi rom_get_prefix::return#0 = 'p' [phi:rom_get_prefix::@1->rom_get_prefix::@2#0] -- vbum1=vbuc1 
    lda #'p'
    sta return
    rts
    // [2079] phi from rom_get_prefix::@1 to rom_get_prefix::@4 [phi:rom_get_prefix::@1->rom_get_prefix::@4]
    // rom_get_prefix::@4
    // [2080] phi from rom_get_prefix::@4 to rom_get_prefix::@2 [phi:rom_get_prefix::@4->rom_get_prefix::@2]
    // [2080] phi rom_get_prefix::return#0 = rom_get_prefix::prefix#4 [phi:rom_get_prefix::@4->rom_get_prefix::@2#0] -- register_copy 
    // rom_get_prefix::@2
  __b2:
    // rom_get_prefix::@return
    // }
    // [2081] return 
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
// void rom_get_version_text(__zp($47) char *release_info, __mem() char prefix, __mem() char release, __zp($45) char *github)
rom_get_version_text: {
    .label release_info = $47
    .label github = $45
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2083] snprintf_init::s#10 = rom_get_version_text::release_info#2
    // [2084] call snprintf_init
    // [1204] phi from rom_get_version_text to snprintf_init [phi:rom_get_version_text->snprintf_init]
    // [1204] phi snprintf_init::s#31 = snprintf_init::s#10 [phi:rom_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // rom_get_version_text::@1
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2085] stackpush(char) = rom_get_version_text::prefix#2 -- _stackpushbyte_=vbum1 
    lda prefix
    pha
    // [2086] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [2088] printf_uchar::uvalue#13 = rom_get_version_text::release#2 -- vbum1=vbum2 
    lda release
    sta printf_uchar.uvalue
    // [2089] call printf_uchar
    // [1346] phi from rom_get_version_text::@1 to printf_uchar [phi:rom_get_version_text::@1->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 0 [phi:rom_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 0 [phi:rom_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:rom_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = DECIMAL [phi:rom_get_version_text::@1->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#13 [phi:rom_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2090] phi from rom_get_version_text::@1 to rom_get_version_text::@2 [phi:rom_get_version_text::@1->rom_get_version_text::@2]
    // rom_get_version_text::@2
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2091] call printf_str
    // [1209] phi from rom_get_version_text::@2 to printf_str [phi:rom_get_version_text::@2->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:rom_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:rom_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@3
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2092] printf_string::str#16 = rom_get_version_text::github#2 -- pbuz1=pbuz2 
    lda.z github
    sta.z printf_string.str
    lda.z github+1
    sta.z printf_string.str+1
    // [2093] call printf_string
    // [1218] phi from rom_get_version_text::@3 to printf_string [phi:rom_get_version_text::@3->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:rom_get_version_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#16 [phi:rom_get_version_text::@3->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:rom_get_version_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:rom_get_version_text::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // rom_get_version_text::@4
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2094] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2095] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_get_version_text::@return
    // }
    // [2097] return 
    rts
  .segment Data
    prefix: .byte 0
    release: .byte 0
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($43) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $43
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [2099] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [2100] utoa::value#1 = printf_uint::uvalue#10
    // [2101] utoa::radix#0 = printf_uint::format_radix#10
    // [2102] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [2103] printf_number_buffer::putc#1 = printf_uint::putc#10
    // [2104] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [2105] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#10
    // [2106] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#10
    // [2107] call printf_number_buffer
  // Print using format
    // [2718] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [2718] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [2718] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [2718] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [2718] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [2108] return 
    rts
  .segment Data
    .label uvalue = smc_detect.return
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $62
    .label screenlayer__1 = $61
    .label screenlayer__2 = $c0
    .label screenlayer__5 = $bd
    .label screenlayer__6 = $bd
    .label screenlayer__7 = $ba
    .label screenlayer__8 = $ba
    .label screenlayer__9 = $b8
    .label screenlayer__10 = $b8
    .label screenlayer__11 = $b8
    .label screenlayer__12 = $b9
    .label screenlayer__13 = $b9
    .label screenlayer__14 = $b9
    .label screenlayer__16 = $ba
    .label screenlayer__17 = $b1
    .label screenlayer__18 = $b8
    .label screenlayer__19 = $b9
    .label y = $ad
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [2109] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [2110] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [2111] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [2112] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [2113] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [2114] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [2115] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [2116] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [2117] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [2118] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [2119] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [2120] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [2121] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [2122] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [2123] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [2124] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [2125] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [2126] screenlayer::$18 = (char)screenlayer::$9
    // [2127] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [2128] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [2129] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [2130] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [2131] screenlayer::$19 = (char)screenlayer::$12
    // [2132] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [2133] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [2134] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [2135] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [2136] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [2136] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [2136] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [2137] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [2138] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [2139] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [2140] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [2141] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [2142] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [2136] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [2136] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [2136] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [2143] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [2144] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [2145] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [2146] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [2147] call gotoxy
    // [801] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [801] phi gotoxy::y#37 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [2148] return 
    rts
    // [2149] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [2150] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [2151] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [2152] call gotoxy
    // [801] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [2153] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [2154] call clearline
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
    // [2155] cx16_k_screen_set_mode::error = 0 -- vbum1=vbuc1 
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
    // [2157] return 
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
    // [2159] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbum2_minus_vbum3 
    lda x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [2160] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2161] display_frame_maskxy::x#0 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2162] display_frame_maskxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2163] call display_frame_maskxy
    // [3107] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [3107] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [3107] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2164] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [2165] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [2166] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = display_frame_char(mask)
    // [2167] display_frame_char::mask#0 = display_frame::mask#1
    // [2168] call display_frame_char
  // Add a corner.
    // [3133] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [3133] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [2169] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [2170] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [2171] cputcxy::x#2 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2172] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2173] cputcxy::c#2 = display_frame::c#0
    // [2174] call cputcxy
    // [2305] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#2 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#2 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#2 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [2175] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [2176] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [2177] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [2177] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [2178] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [2179] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [2179] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [2180] display_frame_maskxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta display_frame_maskxy.x
    // [2181] display_frame_maskxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2182] call display_frame_maskxy
    // [3107] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [3107] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [3107] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2183] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [2184] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [2185] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2186] display_frame_char::mask#1 = display_frame::mask#3
    // [2187] call display_frame_char
    // [3133] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [3133] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2188] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [2189] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [2190] cputcxy::x#3 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [2191] cputcxy::y#3 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2192] cputcxy::c#3 = display_frame::c#1
    // [2193] call cputcxy
    // [2305] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#3 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#3 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#3 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [2194] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [2195] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [2196] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [2196] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [2197] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbum2_then_la1 
    lda y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [2198] display_frame_maskxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2199] display_frame_maskxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2200] call display_frame_maskxy
    // [3107] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [3107] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [3107] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2201] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [2202] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [2203] display_frame::mask#11 = display_frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2204] display_frame_char::mask#5 = display_frame::mask#11
    // [2205] call display_frame_char
    // [3133] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [3133] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2206] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [2207] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [2208] cputcxy::x#7 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2209] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2210] cputcxy::c#7 = display_frame::c#5
    // [2211] call cputcxy
    // [2305] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#7 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#7 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#7 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [2212] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [2213] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [2214] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [2214] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [2215] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbum2_then_la1 
    lda x
    cmp x1
    bcc __b12
    // [2216] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [2216] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [2217] display_frame_maskxy::x#6 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2218] display_frame_maskxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2219] call display_frame_maskxy
    // [3107] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [3107] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [3107] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2220] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [2221] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [2222] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2223] display_frame_char::mask#6 = display_frame::mask#13
    // [2224] call display_frame_char
    // [3133] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [3133] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2225] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [2226] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [2227] cputcxy::x#8 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2228] cputcxy::y#8 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2229] cputcxy::c#8 = display_frame::c#6
    // [2230] call cputcxy
    // [2305] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#8 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#8 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#8 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [2231] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [2232] display_frame_maskxy::x#7 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2233] display_frame_maskxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2234] call display_frame_maskxy
    // [3107] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [3107] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [3107] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2235] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [2236] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [2237] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2238] display_frame_char::mask#7 = display_frame::mask#15
    // [2239] call display_frame_char
    // [3133] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [3133] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2240] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [2241] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [2242] cputcxy::x#9 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2243] cputcxy::y#9 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2244] cputcxy::c#9 = display_frame::c#7
    // [2245] call cputcxy
    // [2305] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#9 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#9 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#9 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [2246] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [2247] display_frame_maskxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2248] display_frame_maskxy::y#3 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2249] call display_frame_maskxy
    // [3107] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [3107] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [3107] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [2250] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [2251] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [2252] display_frame::mask#7 = display_frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2253] display_frame_char::mask#3 = display_frame::mask#7
    // [2254] call display_frame_char
    // [3133] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [3133] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2255] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [2256] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [2257] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2258] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2259] cputcxy::c#5 = display_frame::c#3
    // [2260] call cputcxy
    // [2305] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#5 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#5 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#5 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [2261] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta display_frame_maskxy.x
    // [2262] display_frame_maskxy::y#4 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2263] call display_frame_maskxy
    // [3107] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [3107] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [3107] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [2264] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [2265] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [2266] display_frame::mask#9 = display_frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2267] display_frame_char::mask#4 = display_frame::mask#9
    // [2268] call display_frame_char
    // [3133] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [3133] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2269] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [2270] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [2271] cputcxy::x#6 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [2272] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2273] cputcxy::c#6 = display_frame::c#4
    // [2274] call cputcxy
    // [2305] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#6 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#6 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#6 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [2275] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [2276] display_frame_maskxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta display_frame_maskxy.x
    // [2277] display_frame_maskxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2278] call display_frame_maskxy
    // [3107] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [3107] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [3107] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2279] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [2280] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [2281] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2282] display_frame_char::mask#2 = display_frame::mask#5
    // [2283] call display_frame_char
    // [3133] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [3133] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2284] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [2285] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [2286] cputcxy::x#4 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [2287] cputcxy::y#4 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2288] cputcxy::c#4 = display_frame::c#2
    // [2289] call cputcxy
    // [2305] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#4 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#4 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#4 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [2290] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [2291] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
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
// void cputs(__zp($45) const char *s)
cputs: {
    .label s = $45
    // [2293] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [2293] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [2294] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [2295] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [2296] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [2297] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [2298] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [2299] callexecute cputc  -- call_vprc1 
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
    // [2301] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [2302] return 
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
    // [2303] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [2304] return 
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
    // [2306] gotoxy::x#0 = cputcxy::x#17 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [2307] gotoxy::y#0 = cputcxy::y#17 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2308] call gotoxy
    // [801] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [2309] stackpush(char) = cputcxy::c#17 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [2310] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [2312] return 
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
    // [2314] display_chip_led::tc#0 = display_smc_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2315] call display_chip_led
    // [3148] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [3148] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #5
    sta display_chip_led.w
    // [3148] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbum1=vbuc1 
    lda #1+1
    sta display_chip_led.x
    // [3148] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [2316] display_info_led::tc#0 = display_smc_led::c#2
    // [2317] call display_info_led
    // [2392] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [2392] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbum1=vbuc1 
    lda #$11
    sta display_info_led.y
    // [2392] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2392] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [2318] return 
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
// void display_print_chip(__mem() char x, char y, __mem() char w, __zp($76) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $76
    .label text_1 = $6c
    .label text_2 = $49
    .label text_3 = $6e
    .label text_4 = $31
    .label text_5 = $b6
    .label text_6 = $3e
    // display_chip_line(x, y++, w, *text++)
    // [2320] display_chip_line::x#0 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2321] display_chip_line::w#0 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2322] display_chip_line::c#0 = *display_print_chip::text#11 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta display_chip_line.c
    // [2323] call display_chip_line
    // [3166] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [3166] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [3166] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [3166] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [3166] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [2324] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [2325] display_chip_line::x#1 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2326] display_chip_line::w#1 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2327] display_chip_line::c#1 = *display_print_chip::text#0 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta display_chip_line.c
    // [2328] call display_chip_line
    // [3166] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [3166] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [3166] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [3166] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [3166] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [2329] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [2330] display_chip_line::x#2 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2331] display_chip_line::w#2 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2332] display_chip_line::c#2 = *display_print_chip::text#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta display_chip_line.c
    // [2333] call display_chip_line
    // [3166] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [3166] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [3166] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [3166] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [3166] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [2334] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [2335] display_chip_line::x#3 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2336] display_chip_line::w#3 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2337] display_chip_line::c#3 = *display_print_chip::text#15 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta display_chip_line.c
    // [2338] call display_chip_line
    // [3166] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [3166] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [3166] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [3166] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [3166] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [2339] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [2340] display_chip_line::x#4 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2341] display_chip_line::w#4 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2342] display_chip_line::c#4 = *display_print_chip::text#16 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta display_chip_line.c
    // [2343] call display_chip_line
    // [3166] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [3166] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [3166] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [3166] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [3166] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [2344] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [2345] display_chip_line::x#5 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2346] display_chip_line::w#5 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2347] display_chip_line::c#5 = *display_print_chip::text#17 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta display_chip_line.c
    // [2348] call display_chip_line
    // [3166] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [3166] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [3166] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [3166] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [3166] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [2349] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [2350] display_chip_line::x#6 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2351] display_chip_line::w#6 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2352] display_chip_line::c#6 = *display_print_chip::text#18 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [2353] call display_chip_line
    // [3166] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [3166] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [3166] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [3166] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [3166] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [2354] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [2355] display_chip_line::x#7 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2356] display_chip_line::w#7 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2357] display_chip_line::c#7 = *display_print_chip::text#19 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [2358] call display_chip_line
    // [3166] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [3166] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [3166] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [3166] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [3166] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [2359] display_chip_end::x#0 = display_print_chip::x#10
    // [2360] display_chip_end::w#0 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_end.w
    // [2361] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [2362] return 
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
    // [2364] display_chip_led::tc#1 = display_vera_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2365] call display_chip_led
    // [3148] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [3148] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #8
    sta display_chip_led.w
    // [3148] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbum1=vbuc1 
    lda #9+1
    sta display_chip_led.x
    // [3148] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [2366] display_info_led::tc#1 = display_vera_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_info_led.tc
    // [2367] call display_info_led
    // [2392] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [2392] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbum1=vbuc1 
    lda #$11+1
    sta display_info_led.y
    // [2392] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2392] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [2368] return 
    rts
  .segment Data
    c: .byte 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($49) char *source)
strcat: {
    .label strcat__0 = $4b
    .label dst = $4b
    .label src = $49
    .label source = $49
    // strlen(destination)
    // [2370] call strlen
    // [2623] phi from strcat to strlen [phi:strcat->strlen]
    // [2623] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [2371] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [2372] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [2373] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [2374] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [2374] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [2374] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [2375] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [2376] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [2377] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [2378] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [2379] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [2380] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
    .label display_rom_led__0 = $40
    .label display_rom_led__7 = $40
    .label display_rom_led__8 = $40
    // chip*6
    // [2382] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbum2_rol_1 
    lda chip
    asl
    sta.z display_rom_led__7
    // [2383] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbum2 
    lda chip
    clc
    adc.z display_rom_led__8
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [2384] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [2385] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbum1=vbuz2_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_rom_led__0
    sta display_chip_led.x
    // [2386] display_chip_led::tc#2 = display_rom_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2387] call display_chip_led
    // [3148] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [3148] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #3
    sta display_chip_led.w
    // [3148] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [3148] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [2388] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc chip
    sta display_info_led.y
    // [2389] display_info_led::tc#2 = display_rom_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_info_led.tc
    // [2390] call display_info_led
    // [2392] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [2392] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [2392] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2392] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [2391] return 
    rts
  .segment Data
    chip: .byte 0
    c: .byte 0
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
    // [2393] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [2394] call textcolor
    // [783] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [783] phi textcolor::color#23 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2395] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [2396] call bgcolor
    // [788] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [2397] cputcxy::x#13 = display_info_led::x#4
    // [2398] cputcxy::y#13 = display_info_led::y#4
    // [2399] call cputcxy
    // [2305] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [2305] phi cputcxy::c#17 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [2305] phi cputcxy::y#17 = cputcxy::y#13 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#13 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [2400] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [2401] call textcolor
    // [783] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [2402] return 
    rts
  .segment Data
    .label tc = display_smc_led.c
    .label y = cputcxy.y
    .label x = cputcxy.x
}
.segment CodeVera
  // vera_detect
vera_detect: {
    // spi_get_jedec()
    // [2404] call spi_get_jedec
  // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    // [3227] phi from vera_detect to spi_get_jedec [phi:vera_detect->spi_get_jedec]
    jsr spi_get_jedec
    // vera_detect::@return
    // }
    // [2405] return 
    rts
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
    // [2407] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // [2408] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
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
    // [2409] call rom_write_byte
  // This is a very important operation...
    // [3243] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [3243] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbum1=vbuc1 
    lda #$aa
    sta rom_write_byte.value
    // [3243] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2410] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vdum1=vdum2_plus_vwuc1 
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
    // [2411] call rom_write_byte
    // [3243] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [3243] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbum1=vbuc1 
    lda #$55
    sta rom_write_byte.value
    // [3243] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2412] rom_write_byte::address#2 = rom_unlock::address#5 -- vdum1=vdum2 
    lda address
    sta rom_write_byte.address
    lda address+1
    sta rom_write_byte.address+1
    lda address+2
    sta rom_write_byte.address+2
    lda address+3
    sta rom_write_byte.address+3
    // [2413] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbum1=vbum2 
    lda unlock_code
    sta rom_write_byte.value
    // [2414] call rom_write_byte
    // [3243] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [3243] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [3243] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2415] return 
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
    .label rom_bank1_rom_read_byte__0 = $40
    .label rom_bank1_rom_read_byte__1 = $42
    .label rom_bank1_rom_read_byte__2 = $bb
    .label rom_ptr1_rom_read_byte__0 = $3e
    .label rom_ptr1_rom_read_byte__2 = $3e
    .label rom_ptr1_return = $3e
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [2417] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vdum2 
    lda address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [2418] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vdum2 
    lda address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2419] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta.z rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta.z rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2420] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_read_byte__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2421] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2422] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_read_byte__2
    lda address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [2423] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2424] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [2425] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [2426] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbum1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta return
    // rom_read_byte::@return
    // }
    // [2427] return 
    rts
  .segment Data
    rom_bank1_bank_unshifted: .word 0
    rom_bank1_return: .byte 0
    return: .byte 0
    address: .dword 0
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
// __zp($5d) struct $2 * fopen(__zp($5f) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $42
    .label fopen__9 = $65
    .label fopen__11 = $58
    .label fopen__15 = $5a
    .label fopen__16 = $47
    .label fopen__26 = $45
    .label fopen__28 = $49
    .label fopen__30 = $5d
    .label cbm_k_setnam1_filename = $c9
    .label cbm_k_setnam1_fopen__0 = $50
    .label stream = $5d
    .label pathtoken = $5f
    .label pathtoken_1 = $a9
    .label path = $5f
    .label return = $5d
    // unsigned char sp = __stdio_filecount
    // [2429] fopen::sp#0 = __stdio_filecount#27 -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [2430] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2431] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2432] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [2433] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2434] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2435] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [2436] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [2437] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [2438] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2438] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [2438] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2438] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2438] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [2438] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2438] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2438] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2438] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2438] phi fopen::path#10 = fopen::path#12 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2438] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2438] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2439] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2440] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2441] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2442] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2443] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [2444] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2444] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2444] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2444] phi fopen::path#12 = fopen::path#14 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2444] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2445] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2446] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [2447] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [2448] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2449] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2450] fopen::$4 = __stdio_filecount#27 + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [2451] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2452] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2453] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2454] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2455] fopen::$9 = __stdio_filecount#27 + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [2456] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2457] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [2458] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2459] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2460] call strlen
    // [2623] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2623] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2461] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2462] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [2463] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2465] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2466] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2467] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2468] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2470] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2472] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2473] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2474] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [2475] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2476] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2477] call ferror
    jsr ferror
    // [2478] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2479] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [2480] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2481] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2483] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2483] phi __stdio_filecount#1 = __stdio_filecount#27 [phi:fopen::cbm_k_close1->fopen::@return#0] -- register_copy 
    // [2483] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#1] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2484] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2485] __stdio_filecount#0 = ++ __stdio_filecount#27 -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2486] fopen::return#10 = (struct $2 *)fopen::stream#0
    // [2483] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2483] phi __stdio_filecount#1 = __stdio_filecount#0 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    // [2483] phi fopen::return#2 = fopen::return#10 [phi:fopen::@4->fopen::@return#1] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2487] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2488] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2489] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2490] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2490] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2490] phi fopen::path#14 = fopen::path#17 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2491] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2492] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2493] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2494] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2495] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2496] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2496] phi fopen::path#17 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2496] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2497] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2498] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2499] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2500] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2501] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2502] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2503] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2504] call atoi
    // [3309] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [3309] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2505] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2506] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2507] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2508] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
// __mem() unsigned int fgets(__zp($58) char *ptr, __mem() unsigned int size, __zp($72) struct $2 *stream)
fgets: {
    .label fgets__1 = $65
    .label fgets__8 = $5a
    .label fgets__9 = $40
    .label fgets__13 = $42
    .label ptr = $58
    .label stream = $72
    // unsigned char sp = (unsigned char)stream
    // [2510] fgets::sp#0 = (char)fgets::stream#4 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2511] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2512] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2514] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2516] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2517] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2518] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2519] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2520] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2521] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2521] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2522] return 
    rts
    // fgets::@1
  __b1:
    // [2523] fgets::remaining#22 = fgets::size#10 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2524] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2524] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2524] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2524] phi fgets::ptr#11 = fgets::ptr#14 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2524] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2524] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2524] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2524] phi fgets::ptr#11 = fgets::ptr#15 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2525] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2526] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
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
    // [2527] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2528] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2529] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2530] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2531] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2532] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2532] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2533] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2535] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2536] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2537] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2538] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2539] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2540] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2541] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
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
    // [2542] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2543] fgets::ptr#0 = fgets::ptr#11 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2544] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2545] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2546] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2547] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2547] phi fgets::ptr#15 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2548] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2549] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2521] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2521] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2550] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2551] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2552] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2553] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2554] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2555] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2556] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2557] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2558] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2559] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2560] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2561] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2562] fgets::bytes#1 = cx16_k_macptr::return#2
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
// int fclose(__zp($c7) struct $2 *stream)
fclose: {
    .label fclose__1 = $40
    .label fclose__4 = $42
    .label fclose__6 = $2b
    .label stream = $c7
    // unsigned char sp = (unsigned char)stream
    // [2564] fclose::sp#0 = (char)fclose::stream#3 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2565] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2566] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2568] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2570] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2571] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2572] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [2573] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2574] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2575] phi from fclose::@2 fclose::@3 fclose::@4 to fclose::@return [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return]
    // [2575] phi __stdio_filecount#2 = __stdio_filecount#3 [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return#0] -- register_copy 
    // fclose::@return
    // }
    // [2576] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2577] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2579] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2581] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2582] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2583] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2584] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2585] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2586] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2587] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2588] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2589] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2590] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2591] __stdio_filecount#3 = -- __stdio_filecount#1 -- vbum1=_dec_vbum1 
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
// void display_action_text_reading(__zp($50) char *action, __zp($74) char *file, __mem() unsigned long bytes, __mem() unsigned long size, __mem() char bram_bank, __zp($76) char *bram_ptr)
display_action_text_reading: {
    .label action = $50
    .label bram_ptr = $76
    .label file = $74
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2593] call snprintf_init
    // [1204] phi from display_action_text_reading to snprintf_init [phi:display_action_text_reading->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:display_action_text_reading->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // display_action_text_reading::@1
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2594] printf_string::str#14 = display_action_text_reading::action#3
    // [2595] call printf_string
    // [1218] phi from display_action_text_reading::@1 to printf_string [phi:display_action_text_reading::@1->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:display_action_text_reading::@1->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#14 [phi:display_action_text_reading::@1->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_reading::@1->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_reading::@1->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2596] phi from display_action_text_reading::@1 to display_action_text_reading::@2 [phi:display_action_text_reading::@1->display_action_text_reading::@2]
    // display_action_text_reading::@2
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2597] call printf_str
    // [1209] phi from display_action_text_reading::@2 to printf_str [phi:display_action_text_reading::@2->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s4 [phi:display_action_text_reading::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@3
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2598] printf_string::str#15 = display_action_text_reading::file#3 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [2599] call printf_string
    // [1218] phi from display_action_text_reading::@3 to printf_string [phi:display_action_text_reading::@3->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:display_action_text_reading::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#15 [phi:display_action_text_reading::@3->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_reading::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_reading::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2600] phi from display_action_text_reading::@3 to display_action_text_reading::@4 [phi:display_action_text_reading::@3->display_action_text_reading::@4]
    // display_action_text_reading::@4
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2601] call printf_str
    // [1209] phi from display_action_text_reading::@4 to printf_str [phi:display_action_text_reading::@4->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s2 [phi:display_action_text_reading::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@5
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2602] printf_ulong::uvalue#5 = display_action_text_reading::bytes#3
    // [2603] call printf_ulong
    // [1753] phi from display_action_text_reading::@5 to printf_ulong [phi:display_action_text_reading::@5->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_reading::@5->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_reading::@5->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_reading::@5->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#5 [phi:display_action_text_reading::@5->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2604] phi from display_action_text_reading::@5 to display_action_text_reading::@6 [phi:display_action_text_reading::@5->display_action_text_reading::@6]
    // display_action_text_reading::@6
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2605] call printf_str
    // [1209] phi from display_action_text_reading::@6 to printf_str [phi:display_action_text_reading::@6->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_action_text_reading::s2 [phi:display_action_text_reading::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@7
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2606] printf_ulong::uvalue#6 = display_action_text_reading::size#10 -- vdum1=vdum2 
    lda size
    sta printf_ulong.uvalue
    lda size+1
    sta printf_ulong.uvalue+1
    lda size+2
    sta printf_ulong.uvalue+2
    lda size+3
    sta printf_ulong.uvalue+3
    // [2607] call printf_ulong
    // [1753] phi from display_action_text_reading::@7 to printf_ulong [phi:display_action_text_reading::@7->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_reading::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_reading::@7->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_reading::@7->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#6 [phi:display_action_text_reading::@7->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2608] phi from display_action_text_reading::@7 to display_action_text_reading::@8 [phi:display_action_text_reading::@7->display_action_text_reading::@8]
    // display_action_text_reading::@8
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2609] call printf_str
    // [1209] phi from display_action_text_reading::@8 to printf_str [phi:display_action_text_reading::@8->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@8->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_action_text_reading::s3 [phi:display_action_text_reading::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@9
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2610] printf_uchar::uvalue#6 = display_action_text_reading::bram_bank#10 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [2611] call printf_uchar
    // [1346] phi from display_action_text_reading::@9 to printf_uchar [phi:display_action_text_reading::@9->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_action_text_reading::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 2 [phi:display_action_text_reading::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:display_action_text_reading::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_action_text_reading::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#6 [phi:display_action_text_reading::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2612] phi from display_action_text_reading::@9 to display_action_text_reading::@10 [phi:display_action_text_reading::@9->display_action_text_reading::@10]
    // display_action_text_reading::@10
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2613] call printf_str
    // [1209] phi from display_action_text_reading::@10 to printf_str [phi:display_action_text_reading::@10->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s2 [phi:display_action_text_reading::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@11
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2614] printf_uint::uvalue#3 = (unsigned int)display_action_text_reading::bram_ptr#10 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2615] call printf_uint
    // [2098] phi from display_action_text_reading::@11 to printf_uint [phi:display_action_text_reading::@11->printf_uint]
    // [2098] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_reading::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2098] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_reading::@11->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2098] phi printf_uint::putc#10 = &snputc [phi:display_action_text_reading::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2098] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2098] phi printf_uint::uvalue#10 = printf_uint::uvalue#3 [phi:display_action_text_reading::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2616] phi from display_action_text_reading::@11 to display_action_text_reading::@12 [phi:display_action_text_reading::@11->display_action_text_reading::@12]
    // display_action_text_reading::@12
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2617] call printf_str
    // [1209] phi from display_action_text_reading::@12 to printf_str [phi:display_action_text_reading::@12->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s6 [phi:display_action_text_reading::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@13
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2618] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2619] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2621] call display_action_text
    // [1357] phi from display_action_text_reading::@13 to display_action_text [phi:display_action_text_reading::@13->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:display_action_text_reading::@13->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_reading::@return
    // }
    // [2622] return 
    rts
  .segment Data
    s2: .text "/"
    .byte 0
    s3: .text " -> RAM:"
    .byte 0
    .label bytes = printf_ulong.uvalue
    bram_bank: .byte 0
    size: .dword 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($31) char *str)
strlen: {
    .label str = $31
    // [2624] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2624] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [2624] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2625] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2626] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2627] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [2628] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2624] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2624] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2624] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($5d) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $5d
    // [2630] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2630] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2631] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [2632] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2633] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [2634] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall38
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2636] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2630] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2630] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall38:
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
    .label fp = $cc
    // We start for VERA from 0x1:0xA000.
    .label vera_bram_ptr = $ae
    .label vera_action_text = $6a
    // vera_read::bank_set_bram1
    // BRAM = bank
    // [2638] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // vera_read::@16
    // if(info_status == STATUS_READING)
    // [2639] if(vera_read::info_status#12==STATUS_READING) goto vera_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [2641] phi from vera_read::@16 to vera_read::@2 [phi:vera_read::@16->vera_read::@2]
    // [2641] phi vera_read::vera_bram_bank#14 = 0 [phi:vera_read::@16->vera_read::@2#0] -- vbum1=vbuc1 
    lda #0
    sta vera_bram_bank
    // [2641] phi vera_read::vera_action_text#10 = smc_action_text#2 [phi:vera_read::@16->vera_read::@2#1] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z vera_action_text
    lda #>smc_action_text_1
    sta.z vera_action_text+1
    jmp __b2
    // [2640] phi from vera_read::@16 to vera_read::@1 [phi:vera_read::@16->vera_read::@1]
    // vera_read::@1
  __b1:
    // [2641] phi from vera_read::@1 to vera_read::@2 [phi:vera_read::@1->vera_read::@2]
    // [2641] phi vera_read::vera_bram_bank#14 = 1 [phi:vera_read::@1->vera_read::@2#0] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2641] phi vera_read::vera_action_text#10 = smc_action_text#1 [phi:vera_read::@1->vera_read::@2#1] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z vera_action_text
    lda #>smc_action_text
    sta.z vera_action_text+1
    // vera_read::@2
  __b2:
    // vera_read::bank_set_brom1
    // BROM = bank
    // [2642] BROM = vera_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [2643] phi from vera_read::bank_set_brom1 to vera_read::@17 [phi:vera_read::bank_set_brom1->vera_read::@17]
    // vera_read::@17
    // display_action_text("Opening VERA.BIN from SD card ...")
    // [2644] call display_action_text
    // [1357] phi from vera_read::@17 to display_action_text [phi:vera_read::@17->display_action_text]
    // [1357] phi display_action_text::info_text#25 = vera_read::info_text [phi:vera_read::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2645] phi from vera_read::@17 to vera_read::@19 [phi:vera_read::@17->vera_read::@19]
    // vera_read::@19
    // FILE *fp = fopen("VERA.BIN", "r")
    // [2646] call fopen
    // [2428] phi from vera_read::@19 to fopen [phi:vera_read::@19->fopen]
    // [2428] phi __errno#467 = __errno#100 [phi:vera_read::@19->fopen#0] -- register_copy 
    // [2428] phi fopen::pathtoken#0 = vera_read::path [phi:vera_read::@19->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2428] phi __stdio_filecount#27 = __stdio_filecount#123 [phi:vera_read::@19->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("VERA.BIN", "r")
    // [2647] fopen::return#3 = fopen::return#2
    // vera_read::@20
    // [2648] vera_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [2649] if((struct $2 *)0==vera_read::fp#0) goto vera_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [2650] phi from vera_read::@20 to vera_read::@4 [phi:vera_read::@20->vera_read::@4]
    // vera_read::@4
    // gotoxy(x, y)
    // [2651] call gotoxy
    // [801] phi from vera_read::@4 to gotoxy [phi:vera_read::@4->gotoxy]
    // [801] phi gotoxy::y#37 = PROGRESS_Y [phi:vera_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:vera_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2652] phi from vera_read::@4 to vera_read::@5 [phi:vera_read::@4->vera_read::@5]
    // [2652] phi vera_read::y#11 = PROGRESS_Y [phi:vera_read::@4->vera_read::@5#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2652] phi vera_read::progress_row_current#10 = 0 [phi:vera_read::@4->vera_read::@5#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2652] phi vera_read::vera_bram_ptr#13 = (char *)$a000 [phi:vera_read::@4->vera_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2652] phi vera_read::vera_bram_bank#10 = vera_read::vera_bram_bank#14 [phi:vera_read::@4->vera_read::@5#3] -- register_copy 
    // [2652] phi vera_read::vera_file_size#11 = 0 [phi:vera_read::@4->vera_read::@5#4] -- vdum1=vduc1 
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
    // [2653] if(vera_read::vera_file_size#11<vera_size) goto vera_read::@6 -- vdum1_lt_vduc1_then_la1 
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
    // [2654] fclose::stream#0 = vera_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [2655] call fclose
    // [2563] phi from vera_read::@9 to fclose [phi:vera_read::@9->fclose]
    // [2563] phi fclose::stream#3 = fclose::stream#0 [phi:vera_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [2656] phi from vera_read::@9 to vera_read::@3 [phi:vera_read::@9->vera_read::@3]
    // [2656] phi __stdio_filecount#36 = __stdio_filecount#2 [phi:vera_read::@9->vera_read::@3#0] -- register_copy 
    // [2656] phi vera_read::return#0 = vera_read::vera_file_size#11 [phi:vera_read::@9->vera_read::@3#1] -- register_copy 
    rts
    // [2656] phi from vera_read::@20 to vera_read::@3 [phi:vera_read::@20->vera_read::@3]
  __b4:
    // [2656] phi __stdio_filecount#36 = __stdio_filecount#1 [phi:vera_read::@20->vera_read::@3#0] -- register_copy 
    // [2656] phi vera_read::return#0 = 0 [phi:vera_read::@20->vera_read::@3#1] -- vdum1=vduc1 
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
    // [2657] return 
    rts
    // vera_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [2658] if(vera_read::info_status#12!=STATUS_CHECKING) goto vera_read::@23 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b7
    // [2660] phi from vera_read::@6 to vera_read::@7 [phi:vera_read::@6->vera_read::@7]
    // [2660] phi vera_read::vera_bram_ptr#10 = (char *) 1024 [phi:vera_read::@6->vera_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z vera_bram_ptr
    lda #>$400
    sta.z vera_bram_ptr+1
    // [2659] phi from vera_read::@6 to vera_read::@23 [phi:vera_read::@6->vera_read::@23]
    // vera_read::@23
    // [2660] phi from vera_read::@23 to vera_read::@7 [phi:vera_read::@23->vera_read::@7]
    // [2660] phi vera_read::vera_bram_ptr#10 = vera_read::vera_bram_ptr#13 [phi:vera_read::@23->vera_read::@7#0] -- register_copy 
    // vera_read::@7
  __b7:
    // display_action_text_reading(vera_action_text, "VERA.BIN", vera_file_size, vera_size, vera_bram_bank, vera_bram_ptr)
    // [2661] display_action_text_reading::action#0 = vera_read::vera_action_text#10 -- pbuz1=pbuz2 
    lda.z vera_action_text
    sta.z display_action_text_reading.action
    lda.z vera_action_text+1
    sta.z display_action_text_reading.action+1
    // [2662] display_action_text_reading::bytes#0 = vera_read::vera_file_size#11 -- vdum1=vdum2 
    lda vera_file_size
    sta display_action_text_reading.bytes
    lda vera_file_size+1
    sta display_action_text_reading.bytes+1
    lda vera_file_size+2
    sta display_action_text_reading.bytes+2
    lda vera_file_size+3
    sta display_action_text_reading.bytes+3
    // [2663] display_action_text_reading::bram_bank#0 = vera_read::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta display_action_text_reading.bram_bank
    // [2664] display_action_text_reading::bram_ptr#0 = vera_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [2665] call display_action_text_reading
    // [2592] phi from vera_read::@7 to display_action_text_reading [phi:vera_read::@7->display_action_text_reading]
    // [2592] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#0 [phi:vera_read::@7->display_action_text_reading#0] -- register_copy 
    // [2592] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#0 [phi:vera_read::@7->display_action_text_reading#1] -- register_copy 
    // [2592] phi display_action_text_reading::size#10 = vera_size [phi:vera_read::@7->display_action_text_reading#2] -- vdum1=vduc1 
    lda #<vera_size
    sta display_action_text_reading.size
    lda #>vera_size
    sta display_action_text_reading.size+1
    lda #<vera_size>>$10
    sta display_action_text_reading.size+2
    lda #>vera_size>>$10
    sta display_action_text_reading.size+3
    // [2592] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#0 [phi:vera_read::@7->display_action_text_reading#3] -- register_copy 
    // [2592] phi display_action_text_reading::file#3 = vera_read::path [phi:vera_read::@7->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2592] phi display_action_text_reading::action#3 = display_action_text_reading::action#0 [phi:vera_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // vera_read::bank_set_bram2
    // BRAM = bank
    // [2666] BRAM = vera_read::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // vera_read::@18
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [2667] fgets::ptr#2 = vera_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z fgets.ptr
    lda.z vera_bram_ptr+1
    sta.z fgets.ptr+1
    // [2668] fgets::stream#0 = vera_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [2669] call fgets
    // [2509] phi from vera_read::@18 to fgets [phi:vera_read::@18->fgets]
    // [2509] phi fgets::ptr#14 = fgets::ptr#2 [phi:vera_read::@18->fgets#0] -- register_copy 
    // [2509] phi fgets::size#10 = VERA_PROGRESS_CELL [phi:vera_read::@18->fgets#1] -- vwum1=vbuc1 
    lda #<VERA_PROGRESS_CELL
    sta fgets.size
    lda #>VERA_PROGRESS_CELL
    sta fgets.size+1
    // [2509] phi fgets::stream#4 = fgets::stream#0 [phi:vera_read::@18->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [2670] fgets::return#10 = fgets::return#1
    // vera_read::@21
    // [2671] vera_read::vera_package_read#0 = fgets::return#10 -- vwum1=vwum2 
    lda fgets.return
    sta vera_package_read
    lda fgets.return+1
    sta vera_package_read+1
    // if (!vera_package_read)
    // [2672] if(0!=vera_read::vera_package_read#0) goto vera_read::@8 -- 0_neq_vwum1_then_la1 
    lda vera_package_read
    ora vera_package_read+1
    bne __b8
    jmp __b9
    // vera_read::@8
  __b8:
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [2673] if(vera_read::progress_row_current#10!=VERA_PROGRESS_ROW) goto vera_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b10
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b10
    // vera_read::@13
    // gotoxy(x, ++y);
    // [2674] vera_read::y#1 = ++ vera_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [2675] gotoxy::y#6 = vera_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2676] call gotoxy
    // [801] phi from vera_read::@13 to gotoxy [phi:vera_read::@13->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#6 [phi:vera_read::@13->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:vera_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2677] phi from vera_read::@13 to vera_read::@10 [phi:vera_read::@13->vera_read::@10]
    // [2677] phi vera_read::y#22 = vera_read::y#1 [phi:vera_read::@13->vera_read::@10#0] -- register_copy 
    // [2677] phi vera_read::progress_row_current#4 = 0 [phi:vera_read::@13->vera_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2677] phi from vera_read::@8 to vera_read::@10 [phi:vera_read::@8->vera_read::@10]
    // [2677] phi vera_read::y#22 = vera_read::y#11 [phi:vera_read::@8->vera_read::@10#0] -- register_copy 
    // [2677] phi vera_read::progress_row_current#4 = vera_read::progress_row_current#10 [phi:vera_read::@8->vera_read::@10#1] -- register_copy 
    // vera_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [2678] if(vera_read::info_status#12!=STATUS_READING) goto vera_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // vera_read::@14
    // cputc('.')
    // [2679] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [2680] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_read::@11
  __b11:
    // vera_bram_ptr += vera_package_read
    // [2682] vera_read::vera_bram_ptr#2 = vera_read::vera_bram_ptr#10 + vera_read::vera_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z vera_bram_ptr
    adc vera_package_read
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc vera_package_read+1
    sta.z vera_bram_ptr+1
    // vera_file_size += vera_package_read
    // [2683] vera_read::vera_file_size#1 = vera_read::vera_file_size#11 + vera_read::vera_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [2684] vera_read::progress_row_current#15 = vera_read::progress_row_current#4 + vera_read::vera_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_current
    adc vera_package_read
    sta progress_row_current
    lda progress_row_current+1
    adc vera_package_read+1
    sta progress_row_current+1
    // if (vera_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [2685] if(vera_read::vera_bram_ptr#2!=(char *)$c000) goto vera_read::@12 -- pbuz1_neq_pbuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b12
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b12
    // vera_read::@15
    // vera_bram_bank++;
    // [2686] vera_read::vera_bram_bank#2 = ++ vera_read::vera_bram_bank#10 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2687] phi from vera_read::@15 to vera_read::@12 [phi:vera_read::@15->vera_read::@12]
    // [2687] phi vera_read::vera_bram_bank#13 = vera_read::vera_bram_bank#2 [phi:vera_read::@15->vera_read::@12#0] -- register_copy 
    // [2687] phi vera_read::vera_bram_ptr#8 = (char *)$a000 [phi:vera_read::@15->vera_read::@12#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2687] phi from vera_read::@11 to vera_read::@12 [phi:vera_read::@11->vera_read::@12]
    // [2687] phi vera_read::vera_bram_bank#13 = vera_read::vera_bram_bank#10 [phi:vera_read::@11->vera_read::@12#0] -- register_copy 
    // [2687] phi vera_read::vera_bram_ptr#8 = vera_read::vera_bram_ptr#2 [phi:vera_read::@11->vera_read::@12#1] -- register_copy 
    // vera_read::@12
  __b12:
    // if (vera_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [2688] if(vera_read::vera_bram_ptr#8!=(char *)$9800) goto vera_read::@22 -- pbuz1_neq_pbuc1_then_la1 
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
    // [2652] phi from vera_read::@12 to vera_read::@5 [phi:vera_read::@12->vera_read::@5]
    // [2652] phi vera_read::y#11 = vera_read::y#22 [phi:vera_read::@12->vera_read::@5#0] -- register_copy 
    // [2652] phi vera_read::progress_row_current#10 = vera_read::progress_row_current#15 [phi:vera_read::@12->vera_read::@5#1] -- register_copy 
    // [2652] phi vera_read::vera_bram_ptr#13 = (char *)$a000 [phi:vera_read::@12->vera_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2652] phi vera_read::vera_bram_bank#10 = 1 [phi:vera_read::@12->vera_read::@5#3] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2652] phi vera_read::vera_file_size#11 = vera_read::vera_file_size#1 [phi:vera_read::@12->vera_read::@5#4] -- register_copy 
    jmp __b5
    // [2689] phi from vera_read::@12 to vera_read::@22 [phi:vera_read::@12->vera_read::@22]
    // vera_read::@22
    // [2652] phi from vera_read::@22 to vera_read::@5 [phi:vera_read::@22->vera_read::@5]
    // [2652] phi vera_read::y#11 = vera_read::y#22 [phi:vera_read::@22->vera_read::@5#0] -- register_copy 
    // [2652] phi vera_read::progress_row_current#10 = vera_read::progress_row_current#15 [phi:vera_read::@22->vera_read::@5#1] -- register_copy 
    // [2652] phi vera_read::vera_bram_ptr#13 = vera_read::vera_bram_ptr#8 [phi:vera_read::@22->vera_read::@5#2] -- register_copy 
    // [2652] phi vera_read::vera_bram_bank#10 = vera_read::vera_bram_bank#13 [phi:vera_read::@22->vera_read::@5#3] -- register_copy 
    // [2652] phi vera_read::vera_file_size#11 = vera_read::vera_file_size#1 [phi:vera_read::@22->vera_read::@5#4] -- register_copy 
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
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__mem() char value, __zp($3a) char *buffer, __mem() char radix)
uctoa: {
    .label uctoa__4 = $2b
    .label buffer = $3a
    .label digit_values = $31
    // if(radix==DECIMAL)
    // [2690] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2691] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2692] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2693] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2694] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2695] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2696] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2697] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2698] return 
    rts
    // [2699] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2699] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2699] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2699] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2699] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2699] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2699] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2699] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2699] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2699] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2699] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2699] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2700] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2700] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2700] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2700] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2700] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2701] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2702] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2703] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2704] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2705] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2706] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [2707] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2708] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [2709] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2709] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2709] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2709] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2710] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2700] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2700] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2700] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2700] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2700] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2711] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2712] uctoa_append::value#0 = uctoa::value#2
    // [2713] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2714] call uctoa_append
    // [3330] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2715] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2716] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2717] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2709] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2709] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2709] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2709] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
// void printf_number_buffer(__zp($43) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $58
    .label putc = $43
    // if(format.min_length)
    // [2719] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [2720] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [2721] call strlen
    // [2623] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2623] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [2722] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [2723] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [2724] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [2725] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [2726] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [2727] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [2727] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [2728] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [2729] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [2731] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [2731] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [2730] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [2731] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [2731] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [2732] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [2733] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [2734] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2735] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2736] call printf_padding
    // [2629] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2629] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2629] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2629] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2737] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2738] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [2739] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall40
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2741] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2742] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2743] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2744] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2745] call printf_padding
    // [2629] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2629] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2629] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [2629] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2746] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2747] call printf_str
    // [1209] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [1209] phi printf_str::putc#84 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [1209] phi printf_str::s#84 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2748] return 
    rts
    // Outside Flow
  icall40:
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
    .label vera_verify__16 = $ae
    .label vera_bram_ptr = $66
    // vera_verify::bank_set_bram1
    // BRAM = bank
    // [2750] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // vera_verify::@11
    // unsigned long vera_boundary = vera_file_size
    // [2751] vera_verify::vera_boundary#0 = vera_file_size#1 -- vdum1=vdum2 
    lda vera_file_size
    sta vera_boundary
    lda vera_file_size+1
    sta vera_boundary+1
    lda vera_file_size+2
    sta vera_boundary+2
    lda vera_file_size+3
    sta vera_boundary+3
    // [2752] spi_manufacturer#603 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [2753] spi_memory_type#604 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [2754] spi_memory_capacity#605 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_COMPARING, "Comparing VERA ...")
    // [2755] call display_info_vera
    // [997] phi from vera_verify::@11 to display_info_vera [phi:vera_verify::@11->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = vera_verify::info_text [phi:vera_verify::@11->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_vera.info_text
    lda #>info_text
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#605 [phi:vera_verify::@11->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#604 [phi:vera_verify::@11->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#603 [phi:vera_verify::@11->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_COMPARING [phi:vera_verify::@11->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [2756] phi from vera_verify::@11 to vera_verify::@12 [phi:vera_verify::@11->vera_verify::@12]
    // vera_verify::@12
    // gotoxy(x, y)
    // [2757] call gotoxy
    // [801] phi from vera_verify::@12 to gotoxy [phi:vera_verify::@12->gotoxy]
    // [801] phi gotoxy::y#37 = PROGRESS_Y [phi:vera_verify::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:vera_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2758] phi from vera_verify::@12 to vera_verify::@13 [phi:vera_verify::@12->vera_verify::@13]
    // vera_verify::@13
    // spi_read_flash(0UL)
    // [2759] call spi_read_flash
    // [3337] phi from vera_verify::@13 to spi_read_flash [phi:vera_verify::@13->spi_read_flash]
    jsr spi_read_flash
    // [2760] phi from vera_verify::@13 to vera_verify::@1 [phi:vera_verify::@13->vera_verify::@1]
    // [2760] phi vera_verify::y#3 = PROGRESS_Y [phi:vera_verify::@13->vera_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2760] phi vera_verify::progress_row_current#3 = 0 [phi:vera_verify::@13->vera_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2760] phi vera_verify::vera_different_bytes#11 = 0 [phi:vera_verify::@13->vera_verify::@1#2] -- vdum1=vduc1 
    sta vera_different_bytes
    sta vera_different_bytes+1
    lda #<0>>$10
    sta vera_different_bytes+2
    lda #>0>>$10
    sta vera_different_bytes+3
    // [2760] phi vera_verify::vera_bram_ptr#10 = (char *)$a000 [phi:vera_verify::@13->vera_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2760] phi vera_verify::vera_bram_bank#11 = 1 [phi:vera_verify::@13->vera_verify::@1#4] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2760] phi vera_verify::vera_address#11 = 0 [phi:vera_verify::@13->vera_verify::@1#5] -- vdum1=vduc1 
    lda #<0
    sta vera_address
    sta vera_address+1
    lda #<0>>$10
    sta vera_address+2
    lda #>0>>$10
    sta vera_address+3
    // vera_verify::@1
  __b1:
    // while (vera_address < vera_boundary)
    // [2761] if(vera_verify::vera_address#11<vera_verify::vera_boundary#0) goto vera_verify::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [2762] return 
    rts
    // vera_verify::@2
  __b2:
    // unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_ptr, VERA_PROGRESS_CELL)
    // [2763] vera_compare::bank_ram#0 = vera_verify::vera_bram_bank#11 -- vbum1=vbum2 
    lda vera_bram_bank
    sta vera_compare.bank_ram
    // [2764] vera_compare::bram_ptr#0 = vera_verify::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z vera_compare.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z vera_compare.bram_ptr+1
    // [2765] call vera_compare
  // {asm{.byte $db}}
    // [3348] phi from vera_verify::@2 to vera_compare [phi:vera_verify::@2->vera_compare]
    jsr vera_compare
    // unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_ptr, VERA_PROGRESS_CELL)
    // [2766] vera_compare::return#0 = vera_compare::equal_bytes#2
    // vera_verify::@14
    // [2767] vera_verify::equal_bytes#0 = vera_compare::return#0
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [2768] if(vera_verify::progress_row_current#3!=VERA_PROGRESS_ROW) goto vera_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b3
    // vera_verify::@8
    // gotoxy(x, ++y);
    // [2769] vera_verify::y#1 = ++ vera_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [2770] gotoxy::y#8 = vera_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2771] call gotoxy
    // [801] phi from vera_verify::@8 to gotoxy [phi:vera_verify::@8->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#8 [phi:vera_verify::@8->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = PROGRESS_X [phi:vera_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2772] phi from vera_verify::@8 to vera_verify::@3 [phi:vera_verify::@8->vera_verify::@3]
    // [2772] phi vera_verify::y#10 = vera_verify::y#1 [phi:vera_verify::@8->vera_verify::@3#0] -- register_copy 
    // [2772] phi vera_verify::progress_row_current#4 = 0 [phi:vera_verify::@8->vera_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2772] phi from vera_verify::@14 to vera_verify::@3 [phi:vera_verify::@14->vera_verify::@3]
    // [2772] phi vera_verify::y#10 = vera_verify::y#3 [phi:vera_verify::@14->vera_verify::@3#0] -- register_copy 
    // [2772] phi vera_verify::progress_row_current#4 = vera_verify::progress_row_current#3 [phi:vera_verify::@14->vera_verify::@3#1] -- register_copy 
    // vera_verify::@3
  __b3:
    // if (equal_bytes != VERA_PROGRESS_CELL)
    // [2773] if(vera_verify::equal_bytes#0!=VERA_PROGRESS_CELL) goto vera_verify::@4 -- vwum1_neq_vbuc1_then_la1 
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
    // [2774] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [2775] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_verify::@5
  __b5:
    // vera_bram_ptr += VERA_PROGRESS_CELL
    // [2777] vera_verify::vera_bram_ptr#1 = vera_verify::vera_bram_ptr#10 + VERA_PROGRESS_CELL -- pbuz1=pbuz1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc.z vera_bram_ptr
    sta.z vera_bram_ptr
    bcc !+
    inc.z vera_bram_ptr+1
  !:
    // vera_address += VERA_PROGRESS_CELL
    // [2778] vera_verify::vera_address#1 = vera_verify::vera_address#11 + VERA_PROGRESS_CELL -- vdum1=vdum1_plus_vbuc1 
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
    // [2779] vera_verify::progress_row_current#11 = vera_verify::progress_row_current#4 + VERA_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc progress_row_current
    sta progress_row_current
    bcc !+
    inc progress_row_current+1
  !:
    // if (vera_bram_ptr == BRAM_HIGH)
    // [2780] if(vera_verify::vera_bram_ptr#1!=$c000) goto vera_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b6
    // vera_verify::@10
    // vera_bram_bank++;
    // [2781] vera_verify::vera_bram_bank#1 = ++ vera_verify::vera_bram_bank#11 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2782] phi from vera_verify::@10 to vera_verify::@6 [phi:vera_verify::@10->vera_verify::@6]
    // [2782] phi vera_verify::vera_bram_bank#25 = vera_verify::vera_bram_bank#1 [phi:vera_verify::@10->vera_verify::@6#0] -- register_copy 
    // [2782] phi vera_verify::vera_bram_ptr#6 = (char *)$a000 [phi:vera_verify::@10->vera_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2782] phi from vera_verify::@5 to vera_verify::@6 [phi:vera_verify::@5->vera_verify::@6]
    // [2782] phi vera_verify::vera_bram_bank#25 = vera_verify::vera_bram_bank#11 [phi:vera_verify::@5->vera_verify::@6#0] -- register_copy 
    // [2782] phi vera_verify::vera_bram_ptr#6 = vera_verify::vera_bram_ptr#1 [phi:vera_verify::@5->vera_verify::@6#1] -- register_copy 
    // vera_verify::@6
  __b6:
    // if (vera_bram_ptr == RAM_HIGH)
    // [2783] if(vera_verify::vera_bram_ptr#6!=$9800) goto vera_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b7
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b7
    // [2785] phi from vera_verify::@6 to vera_verify::@7 [phi:vera_verify::@6->vera_verify::@7]
    // [2785] phi vera_verify::vera_bram_ptr#11 = (char *)$a000 [phi:vera_verify::@6->vera_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2785] phi vera_verify::vera_bram_bank#10 = 1 [phi:vera_verify::@6->vera_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2784] phi from vera_verify::@6 to vera_verify::@24 [phi:vera_verify::@6->vera_verify::@24]
    // vera_verify::@24
    // [2785] phi from vera_verify::@24 to vera_verify::@7 [phi:vera_verify::@24->vera_verify::@7]
    // [2785] phi vera_verify::vera_bram_ptr#11 = vera_verify::vera_bram_ptr#6 [phi:vera_verify::@24->vera_verify::@7#0] -- register_copy 
    // [2785] phi vera_verify::vera_bram_bank#10 = vera_verify::vera_bram_bank#25 [phi:vera_verify::@24->vera_verify::@7#1] -- register_copy 
    // vera_verify::@7
  __b7:
    // VERA_PROGRESS_CELL - equal_bytes
    // [2786] vera_verify::$16 = VERA_PROGRESS_CELL - vera_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<VERA_PROGRESS_CELL
    sbc equal_bytes
    sta.z vera_verify__16
    lda #>VERA_PROGRESS_CELL
    sbc equal_bytes+1
    sta.z vera_verify__16+1
    // vera_different_bytes += (VERA_PROGRESS_CELL - equal_bytes)
    // [2787] vera_verify::vera_different_bytes#1 = vera_verify::vera_different_bytes#11 + vera_verify::$16 -- vdum1=vdum1_plus_vwuz2 
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
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2788] call snprintf_init
    // [1204] phi from vera_verify::@7 to snprintf_init [phi:vera_verify::@7->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:vera_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2789] phi from vera_verify::@7 to vera_verify::@15 [phi:vera_verify::@7->vera_verify::@15]
    // vera_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2790] call printf_str
    // [1209] phi from vera_verify::@15 to printf_str [phi:vera_verify::@15->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:vera_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s [phi:vera_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2791] printf_ulong::uvalue#0 = vera_verify::vera_different_bytes#1 -- vdum1=vdum2 
    lda vera_different_bytes
    sta printf_ulong.uvalue
    lda vera_different_bytes+1
    sta printf_ulong.uvalue+1
    lda vera_different_bytes+2
    sta printf_ulong.uvalue+2
    lda vera_different_bytes+3
    sta printf_ulong.uvalue+3
    // [2792] call printf_ulong
    // [1753] phi from vera_verify::@16 to printf_ulong [phi:vera_verify::@16->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:vera_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:vera_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:vera_verify::@16->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#0 [phi:vera_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2793] phi from vera_verify::@16 to vera_verify::@17 [phi:vera_verify::@16->vera_verify::@17]
    // vera_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2794] call printf_str
    // [1209] phi from vera_verify::@17 to printf_str [phi:vera_verify::@17->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:vera_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s1 [phi:vera_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2795] printf_uchar::uvalue#0 = vera_verify::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta printf_uchar.uvalue
    // [2796] call printf_uchar
    // [1346] phi from vera_verify::@18 to printf_uchar [phi:vera_verify::@18->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:vera_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 2 [phi:vera_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:vera_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:vera_verify::@18->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#0 [phi:vera_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2797] phi from vera_verify::@18 to vera_verify::@19 [phi:vera_verify::@18->vera_verify::@19]
    // vera_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2798] call printf_str
    // [1209] phi from vera_verify::@19 to printf_str [phi:vera_verify::@19->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:vera_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s2 [phi:vera_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2799] printf_uint::uvalue#0 = (unsigned int)vera_verify::vera_bram_ptr#11 -- vwum1=vwuz2 
    lda.z vera_bram_ptr
    sta printf_uint.uvalue
    lda.z vera_bram_ptr+1
    sta printf_uint.uvalue+1
    // [2800] call printf_uint
    // [2098] phi from vera_verify::@20 to printf_uint [phi:vera_verify::@20->printf_uint]
    // [2098] phi printf_uint::format_zero_padding#10 = 1 [phi:vera_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2098] phi printf_uint::format_min_length#10 = 4 [phi:vera_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2098] phi printf_uint::putc#10 = &snputc [phi:vera_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2098] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:vera_verify::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2098] phi printf_uint::uvalue#10 = printf_uint::uvalue#0 [phi:vera_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2801] phi from vera_verify::@20 to vera_verify::@21 [phi:vera_verify::@20->vera_verify::@21]
    // vera_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2802] call printf_str
    // [1209] phi from vera_verify::@21 to printf_str [phi:vera_verify::@21->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:vera_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s3 [phi:vera_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2803] printf_ulong::uvalue#1 = vera_verify::vera_address#1 -- vdum1=vdum2 
    lda vera_address
    sta printf_ulong.uvalue
    lda vera_address+1
    sta printf_ulong.uvalue+1
    lda vera_address+2
    sta printf_ulong.uvalue+2
    lda vera_address+3
    sta printf_ulong.uvalue+3
    // [2804] call printf_ulong
    // [1753] phi from vera_verify::@22 to printf_ulong [phi:vera_verify::@22->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:vera_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:vera_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:vera_verify::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#1 [phi:vera_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // vera_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2805] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2806] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2808] call display_action_text
    // [1357] phi from vera_verify::@23 to display_action_text [phi:vera_verify::@23->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:vera_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2760] phi from vera_verify::@23 to vera_verify::@1 [phi:vera_verify::@23->vera_verify::@1]
    // [2760] phi vera_verify::y#3 = vera_verify::y#10 [phi:vera_verify::@23->vera_verify::@1#0] -- register_copy 
    // [2760] phi vera_verify::progress_row_current#3 = vera_verify::progress_row_current#11 [phi:vera_verify::@23->vera_verify::@1#1] -- register_copy 
    // [2760] phi vera_verify::vera_different_bytes#11 = vera_verify::vera_different_bytes#1 [phi:vera_verify::@23->vera_verify::@1#2] -- register_copy 
    // [2760] phi vera_verify::vera_bram_ptr#10 = vera_verify::vera_bram_ptr#11 [phi:vera_verify::@23->vera_verify::@1#3] -- register_copy 
    // [2760] phi vera_verify::vera_bram_bank#11 = vera_verify::vera_bram_bank#10 [phi:vera_verify::@23->vera_verify::@1#4] -- register_copy 
    // [2760] phi vera_verify::vera_address#11 = vera_verify::vera_address#1 [phi:vera_verify::@23->vera_verify::@1#5] -- register_copy 
    jmp __b1
    // vera_verify::@4
  __b4:
    // cputc('*')
    // [2809] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [2810] callexecute cputc  -- call_vprc1 
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
    .label vera_erase__0 = $b0
    .label vera_erase__3 = $78
    // BYTE2(vera_file_size)
    // [2812] vera_erase::$0 = byte2  vera_file_size#1 -- vbuz1=_byte2_vdum2 
    lda vera_file_size+2
    sta.z vera_erase__0
    // unsigned char vera_total_64k_blocks = BYTE2(vera_file_size)+1
    // [2813] vera_erase::vera_total_64k_blocks#0 = vera_erase::$0 + 1 -- vbum1=vbuz2_plus_1 
    inc
    sta vera_total_64k_blocks
    // [2814] phi from vera_erase to vera_erase::@1 [phi:vera_erase->vera_erase::@1]
    // [2814] phi vera_erase::vera_address#2 = 0 [phi:vera_erase->vera_erase::@1#0] -- vdum1=vduc1 
    lda #<0
    sta vera_address
    sta vera_address+1
    lda #<0>>$10
    sta vera_address+2
    lda #>0>>$10
    sta vera_address+3
    // [2814] phi vera_erase::vera_current_64k_block#2 = 0 [phi:vera_erase->vera_erase::@1#1] -- vbum1=vbuc1 
    lda #0
    sta vera_current_64k_block
    // vera_erase::@1
  __b1:
    // while(vera_current_64k_block < vera_total_64k_blocks)
    // [2815] if(vera_erase::vera_current_64k_block#2<vera_erase::vera_total_64k_blocks#0) goto vera_erase::@2 -- vbum1_lt_vbum2_then_la1 
    lda vera_current_64k_block
    cmp vera_total_64k_blocks
    bcc __b2
    // [2816] phi from vera_erase::@1 to vera_erase::@return [phi:vera_erase::@1->vera_erase::@return]
    // [2816] phi vera_erase::return#2 = 0 [phi:vera_erase::@1->vera_erase::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // vera_erase::@return
    // }
    // [2817] return 
    rts
    // [2818] phi from vera_erase::@1 to vera_erase::@2 [phi:vera_erase::@1->vera_erase::@2]
    // vera_erase::@2
  __b2:
    // spi_wait_non_busy()
    // [2819] call spi_wait_non_busy
    // [3362] phi from vera_erase::@2 to spi_wait_non_busy [phi:vera_erase::@2->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // spi_wait_non_busy()
    // [2820] spi_wait_non_busy::return#4 = spi_wait_non_busy::return#3
    // vera_erase::@4
    // [2821] vera_erase::$3 = spi_wait_non_busy::return#4 -- vbuz1=vbum2 
    lda spi_wait_non_busy.return
    sta.z vera_erase__3
    // if(!spi_wait_non_busy())
    // [2822] if(0==vera_erase::$3) goto vera_erase::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // [2816] phi from vera_erase::@4 to vera_erase::@return [phi:vera_erase::@4->vera_erase::@return]
    // [2816] phi vera_erase::return#2 = 1 [phi:vera_erase::@4->vera_erase::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // vera_erase::@3
  __b3:
    // spi_block_erase(vera_address)
    // [2823] spi_block_erase::data#0 = vera_erase::vera_address#2 -- vdum1=vdum2 
    lda vera_address
    sta spi_block_erase.data
    lda vera_address+1
    sta spi_block_erase.data+1
    lda vera_address+2
    sta spi_block_erase.data+2
    lda vera_address+3
    sta spi_block_erase.data+3
    // [2824] call spi_block_erase
    // [3379] phi from vera_erase::@3 to spi_block_erase [phi:vera_erase::@3->spi_block_erase]
    jsr spi_block_erase
    // vera_erase::@5
    // vera_address += 0x10000
    // [2825] vera_erase::vera_address#1 = vera_erase::vera_address#2 + $10000 -- vdum1=vdum1_plus_vduc1 
    clc
    lda vera_address
    adc #<$10000
    sta vera_address
    lda vera_address+1
    adc #>$10000
    sta vera_address+1
    lda vera_address+2
    adc #<$10000>>$10
    sta vera_address+2
    lda vera_address+3
    adc #>$10000>>$10
    sta vera_address+3
    // vera_current_64k_block++;
    // [2826] vera_erase::vera_current_64k_block#1 = ++ vera_erase::vera_current_64k_block#2 -- vbum1=_inc_vbum1 
    inc vera_current_64k_block
    // [2814] phi from vera_erase::@5 to vera_erase::@1 [phi:vera_erase::@5->vera_erase::@1]
    // [2814] phi vera_erase::vera_address#2 = vera_erase::vera_address#1 [phi:vera_erase::@5->vera_erase::@1#0] -- register_copy 
    // [2814] phi vera_erase::vera_current_64k_block#2 = vera_erase::vera_current_64k_block#1 [phi:vera_erase::@5->vera_erase::@1#1] -- register_copy 
    jmp __b1
  .segment DataVera
    vera_total_64k_blocks: .byte 0
    vera_address: .dword 0
    vera_current_64k_block: .byte 0
    // There is an error. We must exit properly back to a prompt, no CX16 reset may happen!
    return: .byte 0
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
    // [2828] phi from display_info_roms to display_info_roms::@1 [phi:display_info_roms->display_info_roms::@1]
    // [2828] phi display_info_roms::rom_chip#2 = 0 [phi:display_info_roms->display_info_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // display_info_roms::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [2829] if(display_info_roms::rom_chip#2<8) goto display_info_roms::@2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b2
    // display_info_roms::@return
    // }
    // [2830] return 
    rts
    // display_info_roms::@2
  __b2:
    // display_info_rom(rom_chip, info_status, info_text)
    // [2831] display_info_rom::rom_chip#4 = display_info_roms::rom_chip#2 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [2832] call display_info_rom
    // [1565] phi from display_info_roms::@2 to display_info_rom [phi:display_info_roms::@2->display_info_rom]
    // [1565] phi display_info_rom::info_text#17 = 0 [phi:display_info_roms::@2->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1565] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#4 [phi:display_info_roms::@2->display_info_rom#1] -- register_copy 
    // [1565] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:display_info_roms::@2->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    // display_info_roms::@3
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [2833] display_info_roms::rom_chip#1 = ++ display_info_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [2828] phi from display_info_roms::@3 to display_info_roms::@1 [phi:display_info_roms::@3->display_info_roms::@1]
    // [2828] phi display_info_roms::rom_chip#2 = display_info_roms::rom_chip#1 [phi:display_info_roms::@3->display_info_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip: .byte 0
}
.segment CodeVera
  // spi_deselect
spi_deselect: {
    // *vera_reg_SPICtrl &= 0xfe
    // [2834] *vera_reg_SPICtrl = *vera_reg_SPICtrl & $fe -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
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
    // [2835] call spi_read
    jsr spi_read
    // spi_deselect::@return
    // }
    // [2836] return 
    rts
}
  // vera_flash
vera_flash: {
    .label vera_flash__8 = $b0
    .label vera_flash__22 = $b2
    .label vera_bram_ptr = $ab
    .label vera_flash__27 = $66
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [2838] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [903] phi from vera_flash to display_action_progress [phi:vera_flash->display_action_progress]
    // [903] phi display_action_progress::info_text#27 = string_0 [phi:vera_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<string_0
    sta.z display_action_progress.info_text
    lda #>string_0
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // vera_flash::@15
    // [2839] spi_manufacturer#602 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [2840] spi_memory_type#603 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [2841] spi_memory_capacity#604 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHING, "Flashing ...")
    // [2842] call display_info_vera
    // [997] phi from vera_flash::@15 to display_info_vera [phi:vera_flash::@15->display_info_vera]
    // [997] phi display_info_vera::info_text#19 = info_text1 [phi:vera_flash::@15->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [997] phi spi_memory_capacity#106 = spi_memory_capacity#604 [phi:vera_flash::@15->display_info_vera#1] -- register_copy 
    // [997] phi spi_memory_type#107 = spi_memory_type#603 [phi:vera_flash::@15->display_info_vera#2] -- register_copy 
    // [997] phi spi_manufacturer#108 = spi_manufacturer#602 [phi:vera_flash::@15->display_info_vera#3] -- register_copy 
    // [997] phi display_info_vera::info_status#19 = STATUS_FLASHING [phi:vera_flash::@15->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [2843] phi from vera_flash::@15 to vera_flash::@1 [phi:vera_flash::@15->vera_flash::@1]
    // [2843] phi vera_flash::vera_bram_ptr#12 = (char *)$a000 [phi:vera_flash::@15->vera_flash::@1#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2843] phi vera_flash::vera_bram_bank#10 = 1 [phi:vera_flash::@15->vera_flash::@1#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2843] phi vera_flash::y_sector#13 = PROGRESS_Y [phi:vera_flash::@15->vera_flash::@1#2] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [2843] phi vera_flash::x_sector#13 = PROGRESS_X [phi:vera_flash::@15->vera_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [2843] phi vera_flash::vera_address_page#11 = 0 [phi:vera_flash::@15->vera_flash::@1#4] -- vdum1=vduc1 
    lda #<0
    sta vera_address_page
    sta vera_address_page+1
    lda #<0>>$10
    sta vera_address_page+2
    lda #>0>>$10
    sta vera_address_page+3
    // [2843] phi from vera_flash::@11 to vera_flash::@1 [phi:vera_flash::@11->vera_flash::@1]
    // [2843] phi vera_flash::vera_bram_ptr#12 = vera_flash::vera_bram_ptr#22 [phi:vera_flash::@11->vera_flash::@1#0] -- register_copy 
    // [2843] phi vera_flash::vera_bram_bank#10 = vera_flash::vera_bram_bank#18 [phi:vera_flash::@11->vera_flash::@1#1] -- register_copy 
    // [2843] phi vera_flash::y_sector#13 = vera_flash::y_sector#13 [phi:vera_flash::@11->vera_flash::@1#2] -- register_copy 
    // [2843] phi vera_flash::x_sector#13 = vera_flash::x_sector#1 [phi:vera_flash::@11->vera_flash::@1#3] -- register_copy 
    // [2843] phi vera_flash::vera_address_page#11 = vera_flash::vera_address_page#14 [phi:vera_flash::@11->vera_flash::@1#4] -- register_copy 
    // vera_flash::@1
  __b1:
    // while (vera_address_page < vera_file_size)
    // [2844] if(vera_flash::vera_address_page#11<vera_file_size#1) goto vera_flash::@2 -- vdum1_lt_vdum2_then_la1 
    lda vera_address_page+3
    cmp vera_file_size+3
    bcc __b2
    bne !+
    lda vera_address_page+2
    cmp vera_file_size+2
    bcc __b2
    bne !+
    lda vera_address_page+1
    cmp vera_file_size+1
    bcc __b2
    bne !+
    lda vera_address_page
    cmp vera_file_size
    bcc __b2
  !:
    // vera_flash::@3
    // display_action_text_flashed(vera_address_page, "VERA")
    // [2845] display_action_text_flashed::bytes#0 = vera_flash::vera_address_page#11 -- vdum1=vdum2 
    lda vera_address_page
    sta display_action_text_flashed.bytes
    lda vera_address_page+1
    sta display_action_text_flashed.bytes+1
    lda vera_address_page+2
    sta display_action_text_flashed.bytes+2
    lda vera_address_page+3
    sta display_action_text_flashed.bytes+3
    // [2846] call display_action_text_flashed
    // [2957] phi from vera_flash::@3 to display_action_text_flashed [phi:vera_flash::@3->display_action_text_flashed]
    // [2957] phi display_action_text_flashed::chip#3 = vera_flash::chip [phi:vera_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2957] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#0 [phi:vera_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [2847] phi from vera_flash::@3 to vera_flash::@18 [phi:vera_flash::@3->vera_flash::@18]
    // vera_flash::@18
    // wait_moment(32)
    // [2848] call wait_moment
    // [1309] phi from vera_flash::@18 to wait_moment [phi:vera_flash::@18->wait_moment]
    // [1309] phi wait_moment::w#13 = $20 [phi:vera_flash::@18->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [2849] phi from vera_flash::@18 to vera_flash::@return [phi:vera_flash::@18->vera_flash::@return]
    // [2849] phi vera_flash::return#2 = vera_flash::vera_address_page#11 [phi:vera_flash::@18->vera_flash::@return#0] -- register_copy 
    // vera_flash::@return
    // }
    // [2850] return 
    rts
    // vera_flash::@2
  __b2:
    // unsigned long vera_page_boundary = vera_address_page + VERA_PROGRESS_PAGE
    // [2851] vera_flash::vera_page_boundary#0 = vera_flash::vera_address_page#11 + VERA_PROGRESS_PAGE -- vdum1=vdum2_plus_vwuc1 
    // {asm{.byte $db}}
    clc
    lda vera_address_page
    adc #<VERA_PROGRESS_PAGE
    sta vera_page_boundary
    lda vera_address_page+1
    adc #>VERA_PROGRESS_PAGE
    sta vera_page_boundary+1
    lda vera_address_page+2
    adc #0
    sta vera_page_boundary+2
    lda vera_address_page+3
    adc #0
    sta vera_page_boundary+3
    // cputcxy(x,y,'.')
    // [2852] cputcxy::x#0 = vera_flash::x_sector#13 -- vbum1=vbum2 
    lda x_sector
    sta cputcxy.x
    // [2853] cputcxy::y#0 = vera_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [2854] call cputcxy
    // [2305] phi from vera_flash::@2 to cputcxy [phi:vera_flash::@2->cputcxy]
    // [2305] phi cputcxy::c#17 = '.' [phi:vera_flash::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #'.'
    sta cputcxy.c
    // [2305] phi cputcxy::y#17 = cputcxy::y#0 [phi:vera_flash::@2->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#0 [phi:vera_flash::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_flash::@16
    // cputc('.')
    // [2855] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [2856] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // spi_wait_non_busy()
    // [2858] call spi_wait_non_busy
    // [3362] phi from vera_flash::@16 to spi_wait_non_busy [phi:vera_flash::@16->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // spi_wait_non_busy()
    // [2859] spi_wait_non_busy::return#5 = spi_wait_non_busy::return#3
    // vera_flash::@17
    // [2860] vera_flash::$8 = spi_wait_non_busy::return#5 -- vbuz1=vbum2 
    lda spi_wait_non_busy.return
    sta.z vera_flash__8
    // if(!spi_wait_non_busy())
    // [2861] if(0==vera_flash::$8) goto vera_flash::bank_set_bram1 -- 0_eq_vbuz1_then_la1 
    beq bank_set_bram1
    // [2849] phi from vera_flash::@17 to vera_flash::@return [phi:vera_flash::@17->vera_flash::@return]
    // [2849] phi vera_flash::return#2 = 0 [phi:vera_flash::@17->vera_flash::@return#0] -- vdum1=vbuc1 
    lda #0
    sta return
    sta return+1
    sta return+2
    sta return+3
    rts
    // vera_flash::bank_set_bram1
  bank_set_bram1:
    // BRAM = bank
    // [2862] BRAM = vera_flash::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // vera_flash::@14
    // spi_write_page_begin(vera_address_page)
    // [2863] spi_write_page_begin::data#0 = vera_flash::vera_address_page#11 -- vdum1=vdum2 
    lda vera_address_page
    sta spi_write_page_begin.data
    lda vera_address_page+1
    sta spi_write_page_begin.data+1
    lda vera_address_page+2
    sta spi_write_page_begin.data+2
    lda vera_address_page+3
    sta spi_write_page_begin.data+3
    // [2864] call spi_write_page_begin
    // [3404] phi from vera_flash::@14 to spi_write_page_begin [phi:vera_flash::@14->spi_write_page_begin]
    jsr spi_write_page_begin
    // vera_flash::@19
    // [2865] vera_flash::vera_address#16 = vera_flash::vera_address_page#11 -- vdum1=vdum2 
    lda vera_address_page
    sta vera_address
    lda vera_address_page+1
    sta vera_address+1
    lda vera_address_page+2
    sta vera_address+2
    lda vera_address_page+3
    sta vera_address+3
    // [2866] phi from vera_flash::@19 vera_flash::@21 to vera_flash::@5 [phi:vera_flash::@19/vera_flash::@21->vera_flash::@5]
    // [2866] phi vera_flash::vera_address_page#14 = vera_flash::vera_address_page#11 [phi:vera_flash::@19/vera_flash::@21->vera_flash::@5#0] -- register_copy 
    // [2866] phi vera_flash::vera_bram_ptr#13 = vera_flash::vera_bram_ptr#12 [phi:vera_flash::@19/vera_flash::@21->vera_flash::@5#1] -- register_copy 
    // [2866] phi vera_flash::vera_address#10 = vera_flash::vera_address#16 [phi:vera_flash::@19/vera_flash::@21->vera_flash::@5#2] -- register_copy 
    // vera_flash::@5
  __b5:
    // while (vera_address < vera_page_boundary)
    // [2867] if(vera_flash::vera_address#10<vera_flash::vera_page_boundary#0) goto vera_flash::@6 -- vdum1_lt_vdum2_then_la1 
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
    // [2868] if(vera_flash::vera_bram_ptr#13!=$c000) goto vera_flash::@10 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b10
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b10
    // vera_flash::@12
    // vera_bram_bank++;
    // [2869] vera_flash::vera_bram_bank#1 = ++ vera_flash::vera_bram_bank#10 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2870] phi from vera_flash::@12 to vera_flash::@10 [phi:vera_flash::@12->vera_flash::@10]
    // [2870] phi vera_flash::vera_bram_bank#25 = vera_flash::vera_bram_bank#1 [phi:vera_flash::@12->vera_flash::@10#0] -- register_copy 
    // [2870] phi vera_flash::vera_bram_ptr#8 = (char *)$a000 [phi:vera_flash::@12->vera_flash::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2870] phi from vera_flash::@4 to vera_flash::@10 [phi:vera_flash::@4->vera_flash::@10]
    // [2870] phi vera_flash::vera_bram_bank#25 = vera_flash::vera_bram_bank#10 [phi:vera_flash::@4->vera_flash::@10#0] -- register_copy 
    // [2870] phi vera_flash::vera_bram_ptr#8 = vera_flash::vera_bram_ptr#13 [phi:vera_flash::@4->vera_flash::@10#1] -- register_copy 
    // vera_flash::@10
  __b10:
    // if (vera_bram_ptr == RAM_HIGH)
    // [2871] if(vera_flash::vera_bram_ptr#8!=$9800) goto vera_flash::@22 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b11
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b11
    // [2873] phi from vera_flash::@10 to vera_flash::@11 [phi:vera_flash::@10->vera_flash::@11]
    // [2873] phi vera_flash::vera_bram_ptr#22 = (char *)$a000 [phi:vera_flash::@10->vera_flash::@11#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2873] phi vera_flash::vera_bram_bank#18 = 1 [phi:vera_flash::@10->vera_flash::@11#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2872] phi from vera_flash::@10 to vera_flash::@22 [phi:vera_flash::@10->vera_flash::@22]
    // vera_flash::@22
    // [2873] phi from vera_flash::@22 to vera_flash::@11 [phi:vera_flash::@22->vera_flash::@11]
    // [2873] phi vera_flash::vera_bram_ptr#22 = vera_flash::vera_bram_ptr#8 [phi:vera_flash::@22->vera_flash::@11#0] -- register_copy 
    // [2873] phi vera_flash::vera_bram_bank#18 = vera_flash::vera_bram_bank#25 [phi:vera_flash::@22->vera_flash::@11#1] -- register_copy 
    // vera_flash::@11
  __b11:
    // x_sector += 2
    // [2874] vera_flash::x_sector#1 = vera_flash::x_sector#13 + 2 -- vbum1=vbum1_plus_2 
    lda x_sector
    clc
    adc #2
    sta x_sector
    // vera_address_page % VERA_PROGRESS_ROW
    // [2875] vera_flash::$22 = vera_flash::vera_address_page#14 & VERA_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
    lda vera_address_page
    and #<VERA_PROGRESS_ROW-1
    sta.z vera_flash__22
    lda vera_address_page+1
    and #>VERA_PROGRESS_ROW-1
    sta.z vera_flash__22+1
    lda vera_address_page+2
    and #<VERA_PROGRESS_ROW-1>>$10
    sta.z vera_flash__22+2
    lda vera_address_page+3
    and #>VERA_PROGRESS_ROW-1>>$10
    sta.z vera_flash__22+3
    // if (!(vera_address_page % VERA_PROGRESS_ROW))
    // [2876] if(0!=vera_flash::$22) goto vera_flash::@1 -- 0_neq_vduz1_then_la1 
    lda.z vera_flash__22
    ora.z vera_flash__22+1
    ora.z vera_flash__22+2
    ora.z vera_flash__22+3
    beq !__b1+
    jmp __b1
  !__b1:
    // vera_flash::@13
    // y_sector++;
    // [2877] vera_flash::y_sector#1 = ++ vera_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [2843] phi from vera_flash::@13 to vera_flash::@1 [phi:vera_flash::@13->vera_flash::@1]
    // [2843] phi vera_flash::vera_bram_ptr#12 = vera_flash::vera_bram_ptr#22 [phi:vera_flash::@13->vera_flash::@1#0] -- register_copy 
    // [2843] phi vera_flash::vera_bram_bank#10 = vera_flash::vera_bram_bank#18 [phi:vera_flash::@13->vera_flash::@1#1] -- register_copy 
    // [2843] phi vera_flash::y_sector#13 = vera_flash::y_sector#1 [phi:vera_flash::@13->vera_flash::@1#2] -- register_copy 
    // [2843] phi vera_flash::x_sector#13 = PROGRESS_X [phi:vera_flash::@13->vera_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [2843] phi vera_flash::vera_address_page#11 = vera_flash::vera_address_page#14 [phi:vera_flash::@13->vera_flash::@1#4] -- register_copy 
    jmp __b1
    // vera_flash::@6
  __b6:
    // display_action_text_flashing(VERA_PROGRESS_PAGE, "VERA", vera_bram_bank, vera_bram_ptr, vera_address)
    // [2878] display_action_text_flashing::bram_bank#0 = vera_flash::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta display_action_text_flashing.bram_bank
    // [2879] display_action_text_flashing::bram_ptr#0 = vera_flash::vera_bram_ptr#13 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [2880] display_action_text_flashing::address#0 = vera_flash::vera_address#10 -- vdum1=vdum2 
    lda vera_address
    sta display_action_text_flashing.address
    lda vera_address+1
    sta display_action_text_flashing.address+1
    lda vera_address+2
    sta display_action_text_flashing.address+2
    lda vera_address+3
    sta display_action_text_flashing.address+3
    // [2881] call display_action_text_flashing
    // [2986] phi from vera_flash::@6 to display_action_text_flashing [phi:vera_flash::@6->display_action_text_flashing]
    // [2986] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#0 [phi:vera_flash::@6->display_action_text_flashing#0] -- register_copy 
    // [2986] phi display_action_text_flashing::chip#10 = vera_flash::chip [phi:vera_flash::@6->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2986] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#0 [phi:vera_flash::@6->display_action_text_flashing#2] -- register_copy 
    // [2986] phi display_action_text_flashing::bram_bank#3 = display_action_text_flashing::bram_bank#0 [phi:vera_flash::@6->display_action_text_flashing#3] -- register_copy 
    // [2986] phi display_action_text_flashing::bytes#3 = VERA_PROGRESS_PAGE [phi:vera_flash::@6->display_action_text_flashing#4] -- vdum1=vduc1 
    lda #<VERA_PROGRESS_PAGE
    sta display_action_text_flashing.bytes
    lda #>VERA_PROGRESS_PAGE
    sta display_action_text_flashing.bytes+1
    lda #<VERA_PROGRESS_PAGE>>$10
    sta display_action_text_flashing.bytes+2
    lda #>VERA_PROGRESS_PAGE>>$10
    sta display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [2882] phi from vera_flash::@6 to vera_flash::@7 [phi:vera_flash::@6->vera_flash::@7]
    // [2882] phi vera_flash::i#2 = 0 [phi:vera_flash::@6->vera_flash::@7#0] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // vera_flash::@7
  __b7:
    // for(unsigned int i=0; i<=255; i++)
    // [2883] if(vera_flash::i#2<=$ff) goto vera_flash::@8 -- vwum1_le_vbuc1_then_la1 
    lda #$ff
    cmp i
    bcc !+
    lda i+1
    beq __b8
  !:
    // vera_flash::@9
    // cputcxy(x,y,'+')
    // [2884] cputcxy::x#1 = vera_flash::x_sector#13 -- vbum1=vbum2 
    lda x_sector
    sta cputcxy.x
    // [2885] cputcxy::y#1 = vera_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [2886] call cputcxy
    // [2305] phi from vera_flash::@9 to cputcxy [phi:vera_flash::@9->cputcxy]
    // [2305] phi cputcxy::c#17 = '+' [phi:vera_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [2305] phi cputcxy::y#17 = cputcxy::y#1 [phi:vera_flash::@9->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#1 [phi:vera_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_flash::@21
    // cputc('+')
    // [2887] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [2888] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_bram_ptr += VERA_PROGRESS_PAGE
    // [2890] vera_flash::vera_bram_ptr#1 = vera_flash::vera_bram_ptr#13 + VERA_PROGRESS_PAGE -- pbuz1=pbuz1_plus_vwuc1 
    lda.z vera_bram_ptr
    clc
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr+1
    // vera_address += VERA_PROGRESS_PAGE
    // [2891] vera_flash::vera_address#1 = vera_flash::vera_address#10 + VERA_PROGRESS_PAGE -- vdum1=vdum1_plus_vwuc1 
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
    // [2892] vera_flash::vera_address_page#1 = vera_flash::vera_address_page#14 + VERA_PROGRESS_PAGE -- vdum1=vdum1_plus_vwuc1 
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
    // spi_write(vera_bram_ptr[i])
    // [2893] vera_flash::$27 = vera_flash::vera_bram_ptr#13 + vera_flash::i#2 -- pbuz1=pbuz2_plus_vwum3 
    lda.z vera_bram_ptr
    clc
    adc i
    sta.z vera_flash__27
    lda.z vera_bram_ptr+1
    adc i+1
    sta.z vera_flash__27+1
    // [2894] spi_write::data = *vera_flash::$27 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (vera_flash__27),y
    sta spi_write.data
    // [2895] call spi_write
    jsr spi_write
    // vera_flash::@20
    // for(unsigned int i=0; i<=255; i++)
    // [2896] vera_flash::i#1 = ++ vera_flash::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [2882] phi from vera_flash::@20 to vera_flash::@7 [phi:vera_flash::@20->vera_flash::@7]
    // [2882] phi vera_flash::i#2 = vera_flash::i#1 [phi:vera_flash::@20->vera_flash::@7#0] -- register_copy 
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
    .label rom_address_from_bank__1 = $c2
    // ((unsigned long)(rom_bank)) << 14
    // [2898] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbum2 
    lda rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2899] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vdum1=vduz2_rol_vbuc1 
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
    // [2900] return 
    rts
  .segment Data
    .label return = rom_read.rom_address
    rom_bank: .byte 0
    .label return_1 = rom_verify.rom_address
    .label return_2 = rom_flash.rom_address_sector
}
.segment Code
  // rom_compare
// __mem() unsigned int rom_compare(__mem() char bank_ram, __zp($56) char *ptr_ram, __mem() unsigned long rom_compare_address, __mem() unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $41
    .label rom_bank1_rom_compare__0 = $2b
    .label rom_bank1_rom_compare__1 = $42
    .label rom_bank1_rom_compare__2 = $50
    .label rom_ptr1_rom_compare__0 = $4e
    .label rom_ptr1_rom_compare__2 = $4e
    .label rom_ptr1_return = $4e
    .label ptr_rom = $4e
    .label ptr_ram = $56
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2902] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2903] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vdum2 
    lda rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2904] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vdum2 
    lda rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2905] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2906] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_compare__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2907] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2908] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vdum2 
    lda rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2909] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2910] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2911] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // [2912] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2913] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2913] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [2913] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2913] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2913] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2914] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [2915] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2916] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2917] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta rom_byte_compare.value
    // [2918] call rom_byte_compare
    jsr rom_byte_compare
    // [2919] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2920] rom_compare::$5 = rom_byte_compare::return#2 -- vbuz1=vbum2 
    lda rom_byte_compare.return
    sta.z rom_compare__5
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2921] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2922] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [2923] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2923] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2924] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2925] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2926] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [2913] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2913] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2913] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2913] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2913] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
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
// void ultoa(__mem() unsigned long value, __zp($3c) char *buffer, __mem() char radix)
ultoa: {
    .label ultoa__4 = $2b
    .label ultoa__10 = $41
    .label ultoa__11 = $42
    .label buffer = $3c
    .label digit_values = $3a
    // if(radix==DECIMAL)
    // [2927] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2928] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2929] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2930] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2931] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2932] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2933] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2934] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2935] return 
    rts
    // [2936] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2936] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2936] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2936] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2936] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2936] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2936] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2936] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2936] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2936] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2936] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2936] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2937] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2937] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2937] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2937] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2937] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2938] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2939] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2940] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2941] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2942] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2943] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2944] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2945] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2946] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2947] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2948] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2948] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2948] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2948] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2949] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2937] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2937] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2937] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2937] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2937] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2950] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2951] ultoa_append::value#0 = ultoa::value#2
    // [2952] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2953] call ultoa_append
    // [3428] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2954] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2955] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2956] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2948] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2948] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2948] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2948] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
// void display_action_text_flashed(__mem() unsigned long bytes, __zp($3e) char *chip)
display_action_text_flashed: {
    .label chip = $3e
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2958] call snprintf_init
    // [1204] phi from display_action_text_flashed to snprintf_init [phi:display_action_text_flashed->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:display_action_text_flashed->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2959] phi from display_action_text_flashed to display_action_text_flashed::@1 [phi:display_action_text_flashed->display_action_text_flashed::@1]
    // display_action_text_flashed::@1
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2960] call printf_str
    // [1209] phi from display_action_text_flashed::@1 to printf_str [phi:display_action_text_flashed::@1->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashed::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_action_text_flashed::s [phi:display_action_text_flashed::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@2
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2961] printf_ulong::uvalue#4 = display_action_text_flashed::bytes#3 -- vdum1=vdum2 
    lda bytes
    sta printf_ulong.uvalue
    lda bytes+1
    sta printf_ulong.uvalue+1
    lda bytes+2
    sta printf_ulong.uvalue+2
    lda bytes+3
    sta printf_ulong.uvalue+3
    // [2962] call printf_ulong
    // [1753] phi from display_action_text_flashed::@2 to printf_ulong [phi:display_action_text_flashed::@2->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 0 [phi:display_action_text_flashed::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 0 [phi:display_action_text_flashed::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = DECIMAL [phi:display_action_text_flashed::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#4 [phi:display_action_text_flashed::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2963] phi from display_action_text_flashed::@2 to display_action_text_flashed::@3 [phi:display_action_text_flashed::@2->display_action_text_flashed::@3]
    // display_action_text_flashed::@3
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2964] call printf_str
    // [1209] phi from display_action_text_flashed::@3 to printf_str [phi:display_action_text_flashed::@3->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashed::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_action_text_flashed::s1 [phi:display_action_text_flashed::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@4
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2965] printf_string::str#13 = display_action_text_flashed::chip#3 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [2966] call printf_string
    // [1218] phi from display_action_text_flashed::@4 to printf_string [phi:display_action_text_flashed::@4->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:display_action_text_flashed::@4->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#13 [phi:display_action_text_flashed::@4->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_flashed::@4->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_flashed::@4->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2967] phi from display_action_text_flashed::@4 to display_action_text_flashed::@5 [phi:display_action_text_flashed::@4->display_action_text_flashed::@5]
    // display_action_text_flashed::@5
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2968] call printf_str
    // [1209] phi from display_action_text_flashed::@5 to printf_str [phi:display_action_text_flashed::@5->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashed::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s5 [phi:display_action_text_flashed::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@6
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2969] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2970] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2972] call display_action_text
    // [1357] phi from display_action_text_flashed::@6 to display_action_text [phi:display_action_text_flashed::@6->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:display_action_text_flashed::@6->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashed::@return
    // }
    // [2973] return 
    rts
  .segment Data
    s: .text "Flashed "
    .byte 0
    s1: .text " bytes from RAM -> "
    .byte 0
    bytes: .dword 0
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
    .label rom_ptr1_rom_sector_erase__0 = $2d
    .label rom_ptr1_rom_sector_erase__2 = $2d
    .label rom_ptr1_return = $2d
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2975] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_sector_erase__2
    lda address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2976] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2977] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2978] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // [2979] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vdum1=vdum1_plus_vwuc1 
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
    // [2980] call rom_unlock
    // [2406] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2406] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbum1=vbuc1 
    lda #$80
    sta rom_unlock.unlock_code
    // [2406] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2981] rom_unlock::address#1 = rom_sector_erase::address#0 -- vdum1=vdum2 
    lda address
    sta rom_unlock.address
    lda address+1
    sta rom_unlock.address+1
    lda address+2
    sta rom_unlock.address+2
    lda address+3
    sta rom_unlock.address+3
    // [2982] call rom_unlock
    // [2406] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2406] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$30
    sta rom_unlock.unlock_code
    // [2406] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2983] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2984] call rom_wait
    // [3435] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [3435] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2985] return 
    rts
  .segment Data
    .label rom_chip_address = rom_unlock.address
    address: .dword 0
}
.segment Code
  // display_action_text_flashing
// void display_action_text_flashing(__mem() unsigned long bytes, __zp($6e) char *chip, __mem() char bram_bank, __zp($6c) char *bram_ptr, __mem() unsigned long address)
display_action_text_flashing: {
    .label bram_ptr = $6c
    .label chip = $6e
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2987] call snprintf_init
    // [1204] phi from display_action_text_flashing to snprintf_init [phi:display_action_text_flashing->snprintf_init]
    // [1204] phi snprintf_init::s#31 = info_text [phi:display_action_text_flashing->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2988] phi from display_action_text_flashing to display_action_text_flashing::@1 [phi:display_action_text_flashing->display_action_text_flashing::@1]
    // display_action_text_flashing::@1
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2989] call printf_str
    // [1209] phi from display_action_text_flashing::@1 to printf_str [phi:display_action_text_flashing::@1->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_action_text_flashing::s [phi:display_action_text_flashing::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@2
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2990] printf_ulong::uvalue#2 = display_action_text_flashing::bytes#3 -- vdum1=vdum2 
    lda bytes
    sta printf_ulong.uvalue
    lda bytes+1
    sta printf_ulong.uvalue+1
    lda bytes+2
    sta printf_ulong.uvalue+2
    lda bytes+3
    sta printf_ulong.uvalue+3
    // [2991] call printf_ulong
    // [1753] phi from display_action_text_flashing::@2 to printf_ulong [phi:display_action_text_flashing::@2->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 0 [phi:display_action_text_flashing::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 0 [phi:display_action_text_flashing::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = DECIMAL [phi:display_action_text_flashing::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#2 [phi:display_action_text_flashing::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2992] phi from display_action_text_flashing::@2 to display_action_text_flashing::@3 [phi:display_action_text_flashing::@2->display_action_text_flashing::@3]
    // display_action_text_flashing::@3
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2993] call printf_str
    // [1209] phi from display_action_text_flashing::@3 to printf_str [phi:display_action_text_flashing::@3->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_action_text_flashing::s1 [phi:display_action_text_flashing::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@4
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2994] printf_uchar::uvalue#5 = display_action_text_flashing::bram_bank#3 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [2995] call printf_uchar
    // [1346] phi from display_action_text_flashing::@4 to printf_uchar [phi:display_action_text_flashing::@4->printf_uchar]
    // [1346] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_action_text_flashing::@4->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1346] phi printf_uchar::format_min_length#18 = 2 [phi:display_action_text_flashing::@4->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1346] phi printf_uchar::putc#18 = &snputc [phi:display_action_text_flashing::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1346] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_action_text_flashing::@4->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1346] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#5 [phi:display_action_text_flashing::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2996] phi from display_action_text_flashing::@4 to display_action_text_flashing::@5 [phi:display_action_text_flashing::@4->display_action_text_flashing::@5]
    // display_action_text_flashing::@5
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2997] call printf_str
    // [1209] phi from display_action_text_flashing::@5 to printf_str [phi:display_action_text_flashing::@5->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s2 [phi:display_action_text_flashing::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@6
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2998] printf_uint::uvalue#2 = (unsigned int)display_action_text_flashing::bram_ptr#3 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2999] call printf_uint
    // [2098] phi from display_action_text_flashing::@6 to printf_uint [phi:display_action_text_flashing::@6->printf_uint]
    // [2098] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2098] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_flashing::@6->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2098] phi printf_uint::putc#10 = &snputc [phi:display_action_text_flashing::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2098] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@6->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2098] phi printf_uint::uvalue#10 = printf_uint::uvalue#2 [phi:display_action_text_flashing::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [3000] phi from display_action_text_flashing::@6 to display_action_text_flashing::@7 [phi:display_action_text_flashing::@6->display_action_text_flashing::@7]
    // display_action_text_flashing::@7
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3001] call printf_str
    // [1209] phi from display_action_text_flashing::@7 to printf_str [phi:display_action_text_flashing::@7->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = display_action_text_flashing::s3 [phi:display_action_text_flashing::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@8
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3002] printf_string::str#12 = display_action_text_flashing::chip#10 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [3003] call printf_string
    // [1218] phi from display_action_text_flashing::@8 to printf_string [phi:display_action_text_flashing::@8->printf_string]
    // [1218] phi printf_string::putc#26 = &snputc [phi:display_action_text_flashing::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1218] phi printf_string::str#26 = printf_string::str#12 [phi:display_action_text_flashing::@8->printf_string#1] -- register_copy 
    // [1218] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_flashing::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1218] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_flashing::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [3004] phi from display_action_text_flashing::@8 to display_action_text_flashing::@9 [phi:display_action_text_flashing::@8->display_action_text_flashing::@9]
    // display_action_text_flashing::@9
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3005] call printf_str
    // [1209] phi from display_action_text_flashing::@9 to printf_str [phi:display_action_text_flashing::@9->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@9->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s2 [phi:display_action_text_flashing::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@10
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3006] printf_ulong::uvalue#3 = display_action_text_flashing::address#10 -- vdum1=vdum2 
    lda address
    sta printf_ulong.uvalue
    lda address+1
    sta printf_ulong.uvalue+1
    lda address+2
    sta printf_ulong.uvalue+2
    lda address+3
    sta printf_ulong.uvalue+3
    // [3007] call printf_ulong
    // [1753] phi from display_action_text_flashing::@10 to printf_ulong [phi:display_action_text_flashing::@10->printf_ulong]
    // [1753] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_flashing::@10->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1753] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_flashing::@10->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1753] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_flashing::@10->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1753] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#3 [phi:display_action_text_flashing::@10->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [3008] phi from display_action_text_flashing::@10 to display_action_text_flashing::@11 [phi:display_action_text_flashing::@10->display_action_text_flashing::@11]
    // display_action_text_flashing::@11
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3009] call printf_str
    // [1209] phi from display_action_text_flashing::@11 to printf_str [phi:display_action_text_flashing::@11->printf_str]
    // [1209] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@11->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1209] phi printf_str::s#84 = s5 [phi:display_action_text_flashing::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@12
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3010] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [3011] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [3013] call display_action_text
    // [1357] phi from display_action_text_flashing::@12 to display_action_text [phi:display_action_text_flashing::@12->display_action_text]
    // [1357] phi display_action_text::info_text#25 = info_text [phi:display_action_text_flashing::@12->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashing::@return
    // }
    // [3014] return 
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
// unsigned long rom_write(__mem() char flash_ram_bank, __zp($54) char *flash_ram_address, __mem() unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label flash_ram_address = $54
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [3015] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // rom_write::bank_set_bram1
    // BRAM = bank
    // [3016] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbum2 
    lda flash_ram_bank
    sta.z BRAM
    // [3017] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [3017] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [3017] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [3017] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vdum1=vduc1 
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
    // [3018] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [3019] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [3020] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
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
    // [3021] call rom_unlock
    // [2406] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2406] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$a0
    sta rom_unlock.unlock_code
    // [2406] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [3022] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vdum1=vdum2 
    lda flash_rom_address
    sta rom_byte_program.address
    lda flash_rom_address+1
    sta rom_byte_program.address+1
    lda flash_rom_address+2
    sta rom_byte_program.address+2
    lda flash_rom_address+3
    sta rom_byte_program.address+3
    // [3023] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta rom_byte_program.value
    // [3024] call rom_byte_program
    // [3442] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [3025] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vdum1=_inc_vdum1 
    inc flash_rom_address
    bne !+
    inc flash_rom_address+1
    bne !+
    inc flash_rom_address+2
    bne !+
    inc flash_rom_address+3
  !:
    // flash_ram_address++;
    // [3026] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [3027] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vdum1=_inc_vdum1 
    inc flashed_bytes
    bne !+
    inc flashed_bytes+1
    bne !+
    inc flashed_bytes+2
    bne !+
    inc flashed_bytes+3
  !:
    // [3017] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [3017] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [3017] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [3017] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip_address: .dword 0
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
    // [3028] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [3030] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [3031] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [3032] return 
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
// char * strncpy(__zp($38) char *dst, __zp($3c) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $38
    .label src = $3c
    // [3034] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [3034] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [3034] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [3034] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [3035] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [3036] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [3037] strncpy::c#0 = *strncpy::src#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [3038] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [3039] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [3040] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [3040] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [3041] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [3042] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [3043] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [3034] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [3034] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [3034] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [3034] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
    i: .word 0
    n: .word 0
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($3e) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $42
    .label utoa__10 = $40
    .label utoa__11 = $41
    .label buffer = $3e
    .label digit_values = $3c
    // if(radix==DECIMAL)
    // [3044] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [3045] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [3046] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [3047] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [3048] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [3049] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [3050] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [3051] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [3052] return 
    rts
    // [3053] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [3053] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [3053] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [3053] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [3053] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [3053] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [3053] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [3053] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [3053] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [3053] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [3053] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [3053] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [3054] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [3054] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [3054] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [3054] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [3054] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [3055] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [3056] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [3057] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [3058] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [3059] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [3060] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [3061] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [3062] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [3063] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [3064] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [3065] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [3065] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [3065] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [3065] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [3066] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [3054] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [3054] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [3054] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [3054] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [3054] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [3067] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [3068] utoa_append::value#0 = utoa::value#2
    // [3069] utoa_append::sub#0 = utoa::digit_value#0
    // [3070] call utoa_append
    // [3452] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [3071] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [3072] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [3073] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [3065] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [3065] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [3065] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [3065] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .word 0
    digit: .byte 0
    .label value = smc_detect.return
    .label radix = printf_uint.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $36
    .label insertup__4 = $2a
    .label insertup__6 = $2c
    .label insertup__7 = $2a
    // __conio.width+1
    // [3074] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [3075] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [3076] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [3076] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [3077] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [3078] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [3079] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [3080] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [3081] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [3082] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [3083] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [3084] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [3085] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [3086] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [3087] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [3088] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [3089] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [3090] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [3076] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [3076] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [3091] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [3092] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [3093] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [3094] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [3095] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [3096] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [3097] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [3098] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [3099] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [3100] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [3101] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [3101] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [3102] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [3103] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [3104] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [3105] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [3106] return 
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
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $42
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $41
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $40
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [3108] gotoxy::x#9 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [3109] gotoxy::y#9 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [3110] call gotoxy
    // [801] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#9 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#9 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [3111] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [3112] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [3113] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [3114] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [3115] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [3116] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [3117] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [3118] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbum1=_deref_pbuc1 
    lda VERA_DATA0
    sta c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [3119] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$70
    cmp c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [3120] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6e
    cmp c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [3121] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6d
    cmp c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [3122] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$7d
    cmp c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [3123] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [3124] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$5d
    cmp c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [3125] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6b
    cmp c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [3126] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$73
    cmp c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [3127] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$72
    cmp c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [3128] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$71
    cmp c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [3129] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbum1_eq_vbuc1_then_la1 
    lda #$5b
    cmp c
    beq __b11
    // [3131] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [3131] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [3130] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [3131] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [3131] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [3131] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [3131] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [3131] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [3131] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [3131] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [3131] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [3131] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [3131] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [3131] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [3131] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [3131] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // display_frame_maskxy::@return
    // }
    // [3132] return 
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
    // [3134] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [3135] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [3136] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [3137] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [3138] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [3139] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [3140] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [3141] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [3142] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [3143] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [3144] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [3146] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [3146] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$20
    sta return
    rts
    // [3145] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [3146] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [3146] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5b
    sta return
    rts
    // [3146] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [3146] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$70
    sta return
    rts
    // [3146] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [3146] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6e
    sta return
    rts
    // [3146] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [3146] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6d
    sta return
    rts
    // [3146] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [3146] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$7d
    sta return
    rts
    // [3146] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [3146] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$40
    sta return
    rts
    // [3146] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [3146] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5d
    sta return
    rts
    // [3146] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [3146] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6b
    sta return
    rts
    // [3146] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [3146] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$73
    sta return
    rts
    // [3146] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [3146] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$72
    sta return
    rts
    // [3146] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [3146] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$71
    sta return
    // display_frame_char::@return
    // }
    // [3147] return 
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
    // [3149] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [3150] call textcolor
    // [783] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [783] phi textcolor::color#23 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [3151] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [3152] call bgcolor
    // [788] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [3153] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [3153] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [3153] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [3154] cputcxy::x#11 = display_chip_led::x#4 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [3155] call cputcxy
    // [2305] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [2305] phi cputcxy::c#17 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [2305] phi cputcxy::y#17 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [2305] phi cputcxy::x#17 = cputcxy::x#11 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [3156] cputcxy::x#12 = display_chip_led::x#4 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [3157] call cputcxy
    // [2305] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [2305] phi cputcxy::c#17 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [2305] phi cputcxy::y#17 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [2305] phi cputcxy::x#17 = cputcxy::x#12 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [3158] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbum1=_inc_vbum1 
    inc x
    // while(--w)
    // [3159] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbum1=_dec_vbum1 
    dec w
    // [3160] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbum1_then_la1 
    lda w
    bne __b1
    // [3161] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [3162] call textcolor
    // [783] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [3163] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [3164] call bgcolor
    // [788] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [3165] return 
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
    // [3167] gotoxy::x#11 = display_chip_line::x#16 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [3168] gotoxy::y#11 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [3169] call gotoxy
    // [801] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [801] phi gotoxy::y#37 = gotoxy::y#11 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [801] phi gotoxy::x#37 = gotoxy::x#11 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [3170] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [3171] call textcolor
    // [783] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [783] phi textcolor::color#23 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3172] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [3173] call bgcolor
    // [788] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [3174] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [3175] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [3177] call textcolor
    // [783] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [3178] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [3179] call bgcolor
    // [788] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [788] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [3180] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [3180] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [3181] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [3182] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [3183] call textcolor
    // [783] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [783] phi textcolor::color#23 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3184] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [3185] call bgcolor
    // [788] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [3186] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [3187] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [3189] call textcolor
    // [783] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [783] phi textcolor::color#23 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [3190] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [3191] call bgcolor
    // [788] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [788] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [3192] cputcxy::x#10 = display_chip_line::x#16 + 2 -- vbum1=vbum2_plus_2 
    lda x
    clc
    adc #2
    sta cputcxy.x
    // [3193] cputcxy::y#10 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [3194] cputcxy::c#10 = display_chip_line::c#15 -- vbum1=vbum2 
    lda c
    sta cputcxy.c
    // [3195] call cputcxy
    // [2305] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [2305] phi cputcxy::c#17 = cputcxy::c#10 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [2305] phi cputcxy::y#17 = cputcxy::y#10 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [2305] phi cputcxy::x#17 = cputcxy::x#10 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [3196] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [3197] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [3198] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [3200] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [3180] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [3180] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
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
    // [3201] gotoxy::x#12 = display_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [3202] call gotoxy
    // [801] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [801] phi gotoxy::y#37 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [801] phi gotoxy::x#37 = gotoxy::x#12 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [3203] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [3204] call textcolor
    // [783] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [783] phi textcolor::color#23 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3205] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [3206] call bgcolor
    // [788] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [3207] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [3208] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [3210] call textcolor
    // [783] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [783] phi textcolor::color#23 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [3211] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [3212] call bgcolor
    // [788] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [788] phi bgcolor::color#15 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [3213] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [3213] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [3214] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [3215] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [3216] call textcolor
    // [783] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [783] phi textcolor::color#23 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3217] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [3218] call bgcolor
    // [788] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [788] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [3219] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [3220] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [3222] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [3223] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [3224] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [3226] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [3213] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [3213] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    .label x = display_print_chip.x
    w: .byte 0
}
.segment CodeVera
  // spi_get_jedec
spi_get_jedec: {
    // spi_fast()
    // [3228] call spi_fast
    /* 
; Returns
; .X = Vendor ID
; .Y = Memory Type
; .A = Memory Capacity
.proc spi_get_jedec
    jsr spi_fast

    jsr spi_select
    lda #$9F
    jsr spi_write
    jsr spi_read
    tax
    jsr spi_read
    tay
    jsr spi_read
    rts
.endproc
 */
    jsr spi_fast
    // [3229] phi from spi_get_jedec to spi_get_jedec::@1 [phi:spi_get_jedec->spi_get_jedec::@1]
    // spi_get_jedec::@1
    // spi_select()
    // [3230] call spi_select
    // [3481] phi from spi_get_jedec::@1 to spi_select [phi:spi_get_jedec::@1->spi_select]
    jsr spi_select
    // spi_get_jedec::@2
    // spi_write(0x9F)
    // [3231] spi_write::data = $9f -- vbum1=vbuc1 
    lda #$9f
    sta spi_write.data
    // [3232] call spi_write
    jsr spi_write
    // [3233] phi from spi_get_jedec::@2 to spi_get_jedec::@3 [phi:spi_get_jedec::@2->spi_get_jedec::@3]
    // spi_get_jedec::@3
    // spi_read()
    // [3234] call spi_read
    jsr spi_read
    // [3235] spi_read::return#0 = spi_read::return#5 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_read.return
    // [3236] phi from spi_get_jedec::@3 to spi_get_jedec::@4 [phi:spi_get_jedec::@3->spi_get_jedec::@4]
    // spi_get_jedec::@4
    // spi_read()
    // [3237] call spi_read
    jsr spi_read
    // [3238] spi_read::return#1 = spi_read::return#5 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_read.return_1
    // [3239] phi from spi_get_jedec::@4 to spi_get_jedec::@5 [phi:spi_get_jedec::@4->spi_get_jedec::@5]
    // spi_get_jedec::@5
    // spi_read()
    // [3240] call spi_read
    jsr spi_read
    // [3241] spi_read::return#10 = spi_read::return#5 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_read.return_3
    // spi_get_jedec::@return
    // }
    // [3242] return 
    rts
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
    .label rom_bank1_rom_write_byte__0 = $40
    .label rom_bank1_rom_write_byte__1 = $2b
    .label rom_bank1_rom_write_byte__2 = $43
    .label rom_ptr1_rom_write_byte__0 = $38
    .label rom_ptr1_rom_write_byte__2 = $38
    .label rom_ptr1_return = $38
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [3244] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vdum2 
    lda address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [3245] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vdum2 
    lda address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [3246] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [3247] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_write_byte__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [3248] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [3249] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_write_byte__2
    lda address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [3250] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [3251] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [3252] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [3253] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbum2 
    lda value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [3254] return 
    rts
  .segment Data
    rom_bank1_bank_unshifted: .word 0
    rom_bank1_return: .byte 0
    address: .dword 0
    value: .byte 0
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
    // [3256] return 
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
// __mem() int ferror(__zp($5d) struct $2 *stream)
ferror: {
    .label ferror__6 = $40
    .label ferror__15 = $2b
    .label cbm_k_setnam1_filename = $be
    .label cbm_k_setnam1_ferror__0 = $43
    .label stream = $5d
    .label errno_len = $71
    // unsigned char sp = (unsigned char)stream
    // [3257] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [3258] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [3259] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [3260] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [3261] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [3262] ferror::cbm_k_setnam1_filename = str -- pbuz1=pbuc1 
    lda #<str
    sta.z cbm_k_setnam1_filename
    lda #>str
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [3263] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [3264] call strlen
    // [2623] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2623] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [3265] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [3266] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [3267] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [3270] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [3271] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [3273] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [3275] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [3276] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [3277] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [3278] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [3278] phi __errno#123 = __errno#467 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [3278] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [3278] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [3278] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [3279] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [3281] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [3282] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [3283] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [3284] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [3285] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [3286] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [3287] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [3289] ferror::return#1 = __errno#123 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [3290] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [3291] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [3292] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [3293] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [3294] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [3295] call strncpy
    // [3033] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [3033] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [3033] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [3033] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [3296] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [3297] call atoi
    // [3309] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [3309] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [3298] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [3299] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [3300] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [3300] phi __errno#178 = __errno#123 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [3300] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [3301] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [3302] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [3303] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [3305] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [3306] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [3307] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [3308] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [3278] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [3278] phi __errno#123 = __errno#178 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [3278] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [3278] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [3278] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
// __mem() int atoi(__zp($5f) const char *str)
atoi: {
    .label atoi__6 = $38
    .label atoi__7 = $38
    .label str = $5f
    .label atoi__10 = $38
    .label atoi__11 = $38
    // if (str[i] == '-')
    // [3310] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [3311] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [3312] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [3312] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [3312] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [3312] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [3312] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [3312] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [3312] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [3312] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [3313] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [3314] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [3315] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [3317] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [3317] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [3316] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [3318] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [3319] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [3320] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [3321] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [3322] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [3323] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [3324] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [3312] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [3312] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [3312] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [3312] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($5b) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $5b
    // unsigned int bytes_read
    // [3325] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [3327] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [3328] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [3329] return 
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
// __mem() char uctoa_append(__zp($49) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $49
    // [3331] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [3331] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3331] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [3332] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [3333] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [3334] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [3335] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3336] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [3331] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [3331] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [3331] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
    // [3338] call spi_select
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
    // [3481] phi from spi_read_flash to spi_select [phi:spi_read_flash->spi_select]
    jsr spi_select
    // spi_read_flash::@1
    // spi_write(0x03)
    // [3339] spi_write::data = 3 -- vbum1=vbuc1 
    lda #3
    sta spi_write.data
    // [3340] call spi_write
    jsr spi_write
    // spi_read_flash::@2
    // spi_write(BYTE2(spi_data))
    // [3341] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3342] call spi_write
    jsr spi_write
    // spi_read_flash::@3
    // spi_write(BYTE1(spi_data))
    // [3343] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3344] call spi_write
    jsr spi_write
    // spi_read_flash::@4
    // spi_write(BYTE0(spi_data))
    // [3345] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3346] call spi_write
    jsr spi_write
    // spi_read_flash::@return
    // }
    // [3347] return 
    rts
}
  // vera_compare
// __mem() unsigned int vera_compare(__mem() char bank_ram, __zp($6a) char *bram_ptr, unsigned int vera_compare_size)
vera_compare: {
    .label bram_ptr = $6a
    // vera_compare::bank_set_bram1
    // BRAM = bank
    // [3349] BRAM = vera_compare::bank_ram#0 -- vbuz1=vbum2 
    lda bank_ram
    sta.z BRAM
    // [3350] phi from vera_compare::bank_set_bram1 to vera_compare::@1 [phi:vera_compare::bank_set_bram1->vera_compare::@1]
    // [3350] phi vera_compare::bram_ptr#2 = vera_compare::bram_ptr#0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#0] -- register_copy 
    // [3350] phi vera_compare::equal_bytes#2 = 0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [3350] phi vera_compare::compared_bytes#2 = 0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#2] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // vera_compare::@1
  __b1:
    // while (compared_bytes < vera_compare_size)
    // [3351] if(vera_compare::compared_bytes#2<VERA_PROGRESS_CELL) goto vera_compare::@2 -- vwum1_lt_vbuc1_then_la1 
    lda compared_bytes+1
    bne !+
    lda compared_bytes
    cmp #VERA_PROGRESS_CELL
    bcc __b2
  !:
    // vera_compare::@return
    // }
    // [3352] return 
    rts
    // [3353] phi from vera_compare::@1 to vera_compare::@2 [phi:vera_compare::@1->vera_compare::@2]
    // vera_compare::@2
  __b2:
    // unsigned char vera_byte = spi_read()
    // [3354] call spi_read
    jsr spi_read
    // [3355] spi_read::return#14 = spi_read::return#5
    // vera_compare::@5
    // [3356] vera_compare::vera_byte#0 = spi_read::return#14
    // if (vera_byte == *bram_ptr)
    // [3357] if(vera_compare::vera_byte#0!=*vera_compare::bram_ptr#2) goto vera_compare::@3 -- vbum1_neq__deref_pbuz2_then_la1 
    ldy #0
    lda (bram_ptr),y
    cmp vera_byte
    bne __b3
    // vera_compare::@4
    // equal_bytes++;
    // [3358] vera_compare::equal_bytes#1 = ++ vera_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [3359] phi from vera_compare::@4 vera_compare::@5 to vera_compare::@3 [phi:vera_compare::@4/vera_compare::@5->vera_compare::@3]
    // [3359] phi vera_compare::equal_bytes#6 = vera_compare::equal_bytes#1 [phi:vera_compare::@4/vera_compare::@5->vera_compare::@3#0] -- register_copy 
    // vera_compare::@3
  __b3:
    // bram_ptr++;
    // [3360] vera_compare::bram_ptr#1 = ++ vera_compare::bram_ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z bram_ptr
    bne !+
    inc.z bram_ptr+1
  !:
    // compared_bytes++;
    // [3361] vera_compare::compared_bytes#1 = ++ vera_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [3350] phi from vera_compare::@3 to vera_compare::@1 [phi:vera_compare::@3->vera_compare::@1]
    // [3350] phi vera_compare::bram_ptr#2 = vera_compare::bram_ptr#1 [phi:vera_compare::@3->vera_compare::@1#0] -- register_copy 
    // [3350] phi vera_compare::equal_bytes#2 = vera_compare::equal_bytes#6 [phi:vera_compare::@3->vera_compare::@1#1] -- register_copy 
    // [3350] phi vera_compare::compared_bytes#2 = vera_compare::compared_bytes#1 [phi:vera_compare::@3->vera_compare::@1#2] -- register_copy 
    jmp __b1
  .segment DataVera
    bank_ram: .byte 0
    .label return = equal_bytes
    .label vera_byte = spi_read.return_2
    compared_bytes: .word 0
    /// Holds the amount of bytes actually verified between the VERA and the RAM.
    equal_bytes: .word 0
}
.segment CodeVera
  // spi_wait_non_busy
spi_wait_non_busy: {
    // [3363] phi from spi_wait_non_busy to spi_wait_non_busy::@1 [phi:spi_wait_non_busy->spi_wait_non_busy::@1]
    // [3363] phi spi_wait_non_busy::y#2 = 0 [phi:spi_wait_non_busy->spi_wait_non_busy::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // spi_wait_non_busy::@1
    // [3364] phi from spi_wait_non_busy::@1 to spi_wait_non_busy::@2 [phi:spi_wait_non_busy::@1->spi_wait_non_busy::@2]
    // spi_wait_non_busy::@2
  __b2:
    // spi_select()
    // [3365] call spi_select
    // [3481] phi from spi_wait_non_busy::@2 to spi_select [phi:spi_wait_non_busy::@2->spi_select]
    jsr spi_select
    // spi_wait_non_busy::@5
    // spi_write(0x05)
    // [3366] spi_write::data = 5 -- vbum1=vbuc1 
    lda #5
    sta spi_write.data
    // [3367] call spi_write
    jsr spi_write
    // [3368] phi from spi_wait_non_busy::@5 to spi_wait_non_busy::@6 [phi:spi_wait_non_busy::@5->spi_wait_non_busy::@6]
    // spi_wait_non_busy::@6
    // unsigned char w = spi_read()
    // [3369] call spi_read
    jsr spi_read
    // [3370] spi_read::return#11 = spi_read::return#5
    // spi_wait_non_busy::@7
    // [3371] spi_wait_non_busy::w#0 = spi_read::return#11
    // w &= 1
    // [3372] spi_wait_non_busy::w#1 = spi_wait_non_busy::w#0 & 1 -- vbum1=vbum1_band_vbuc1 
    lda #1
    and w
    sta w
    // if(w == 0)
    // [3373] if(spi_wait_non_busy::w#1==0) goto spi_wait_non_busy::@return -- vbum1_eq_0_then_la1 
    beq __b1
    // spi_wait_non_busy::@4
    // y++;
    // [3374] spi_wait_non_busy::y#1 = ++ spi_wait_non_busy::y#2 -- vbum1=_inc_vbum1 
    inc y
    // if(y == 0)
    // [3375] if(spi_wait_non_busy::y#1!=0) goto spi_wait_non_busy::@3 -- vbum1_neq_0_then_la1 
    lda y
    bne __b3
    // [3376] phi from spi_wait_non_busy::@4 to spi_wait_non_busy::@return [phi:spi_wait_non_busy::@4->spi_wait_non_busy::@return]
    // [3376] phi spi_wait_non_busy::return#3 = 1 [phi:spi_wait_non_busy::@4->spi_wait_non_busy::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // [3376] phi from spi_wait_non_busy::@7 to spi_wait_non_busy::@return [phi:spi_wait_non_busy::@7->spi_wait_non_busy::@return]
  __b1:
    // [3376] phi spi_wait_non_busy::return#3 = 0 [phi:spi_wait_non_busy::@7->spi_wait_non_busy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // spi_wait_non_busy::@return
    // }
    // [3377] return 
    rts
    // spi_wait_non_busy::@3
  __b3:
    // asm
    // asm { .byte$CB  }
    // WAI
    .byte $cb
    // [3363] phi from spi_wait_non_busy::@3 to spi_wait_non_busy::@1 [phi:spi_wait_non_busy::@3->spi_wait_non_busy::@1]
    // [3363] phi spi_wait_non_busy::y#2 = spi_wait_non_busy::y#1 [phi:spi_wait_non_busy::@3->spi_wait_non_busy::@1#0] -- register_copy 
    jmp __b2
  .segment DataVera
    .label w = spi_read.return_2
    /** 
.proc spi_wait_non_busy
    ldy #0
top:
    jsr spi_select
    lda #$05
    jsr spi_write

    jsr spi_read
    and #1
    bne wait_restart
    clc
    rts
fail:
    sec
    rts
wait_restart:
    iny
    beq fail
    wai    
    bra top
.endproc
 */
    y: .byte 0
    return: .byte 0
}
.segment CodeVera
  // spi_block_erase
// void spi_block_erase(__mem() unsigned long data)
spi_block_erase: {
    .label spi_block_erase__4 = $7d
    .label spi_block_erase__6 = $7e
    .label spi_block_erase__8 = $78
    // spi_select()
    // [3380] call spi_select
  /** 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_block_erase ; 64k
    pha

    ; write enable
    jsr spi_select
    lda #$06
    jsr spi_write

    jsr spi_select
    lda #$d8
    jsr spi_write

    pla
    jsr spi_write
    tya
    jsr spi_write
    txa
    jsr spi_write

    jsr spi_deselect

    rts
.endproc
 */
    // [3481] phi from spi_block_erase to spi_select [phi:spi_block_erase->spi_select]
    jsr spi_select
    // spi_block_erase::@1
    // spi_write(0x06)
    // [3381] spi_write::data = 6 -- vbum1=vbuc1 
    lda #6
    sta spi_write.data
    // [3382] call spi_write
    jsr spi_write
    // [3383] phi from spi_block_erase::@1 to spi_block_erase::@2 [phi:spi_block_erase::@1->spi_block_erase::@2]
    // spi_block_erase::@2
    // spi_select()
    // [3384] call spi_select
    // [3481] phi from spi_block_erase::@2 to spi_select [phi:spi_block_erase::@2->spi_select]
    jsr spi_select
    // spi_block_erase::@3
    // spi_write(0xD8)
    // [3385] spi_write::data = $d8 -- vbum1=vbuc1 
    lda #$d8
    sta spi_write.data
    // [3386] call spi_write
    jsr spi_write
    // spi_block_erase::@4
    // BYTE2(data)
    // [3387] spi_block_erase::$4 = byte2  spi_block_erase::data#0 -- vbuz1=_byte2_vdum2 
    lda data+2
    sta.z spi_block_erase__4
    // spi_write(BYTE2(data))
    // [3388] spi_write::data = spi_block_erase::$4 -- vbum1=vbuz2 
    sta spi_write.data
    // [3389] call spi_write
    jsr spi_write
    // spi_block_erase::@5
    // BYTE1(data)
    // [3390] spi_block_erase::$6 = byte1  spi_block_erase::data#0 -- vbuz1=_byte1_vdum2 
    lda data+1
    sta.z spi_block_erase__6
    // spi_write(BYTE1(data))
    // [3391] spi_write::data = spi_block_erase::$6 -- vbum1=vbuz2 
    sta spi_write.data
    // [3392] call spi_write
    jsr spi_write
    // spi_block_erase::@6
    // BYTE0(data)
    // [3393] spi_block_erase::$8 = byte0  spi_block_erase::data#0 -- vbuz1=_byte0_vdum2 
    lda data
    sta.z spi_block_erase__8
    // spi_write(BYTE0(data))
    // [3394] spi_write::data = spi_block_erase::$8 -- vbum1=vbuz2 
    sta spi_write.data
    // [3395] call spi_write
    jsr spi_write
    // [3396] phi from spi_block_erase::@6 to spi_block_erase::@7 [phi:spi_block_erase::@6->spi_block_erase::@7]
    // spi_block_erase::@7
    // spi_deselect()
    // [3397] call spi_deselect
    jsr spi_deselect
    // spi_block_erase::@return
    // }
    // [3398] return 
    rts
  .segment DataVera
    data: .dword 0
}
.segment CodeVera
  // spi_read
spi_read: {
    // unsigned char SPIData
    // [3399] spi_read::SPIData = 0 -- vbum1=vbuc1 
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
    // [3401] spi_read::return#4 = spi_read::SPIData -- vbum1=vbum2 
    sta return_2
    // spi_read::@return
    // }
    // [3402] spi_read::return#5 = spi_read::return#4
    // [3403] return 
    rts
  .segment DataVera
    SPIData: .byte 0
    return: .byte 0
    return_1: .byte 0
    return_2: .byte 0
    return_3: .byte 0
}
.segment CodeVera
  // spi_write_page_begin
// void spi_write_page_begin(__mem() unsigned long data)
spi_write_page_begin: {
    .label spi_write_page_begin__4 = $78
    .label spi_write_page_begin__6 = $7d
    .label spi_write_page_begin__8 = $7e
    // spi_select()
    // [3405] call spi_select
  /** 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_write_page_begin
    pha

    ; write enable
    jsr spi_select
    lda #$06
    jsr spi_write

    jsr spi_select
    lda #$02
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
    // [3481] phi from spi_write_page_begin to spi_select [phi:spi_write_page_begin->spi_select]
    jsr spi_select
    // spi_write_page_begin::@1
    // spi_write(0x06)
    // [3406] spi_write::data = 6 -- vbum1=vbuc1 
    lda #6
    sta spi_write.data
    // [3407] call spi_write
    jsr spi_write
    // [3408] phi from spi_write_page_begin::@1 to spi_write_page_begin::@2 [phi:spi_write_page_begin::@1->spi_write_page_begin::@2]
    // spi_write_page_begin::@2
    // spi_select()
    // [3409] call spi_select
    // [3481] phi from spi_write_page_begin::@2 to spi_select [phi:spi_write_page_begin::@2->spi_select]
    jsr spi_select
    // spi_write_page_begin::@3
    // spi_write(0x02)
    // [3410] spi_write::data = 2 -- vbum1=vbuc1 
    lda #2
    sta spi_write.data
    // [3411] call spi_write
    jsr spi_write
    // spi_write_page_begin::@4
    // BYTE2(data)
    // [3412] spi_write_page_begin::$4 = byte2  spi_write_page_begin::data#0 -- vbuz1=_byte2_vdum2 
    lda data+2
    sta.z spi_write_page_begin__4
    // spi_write(BYTE2(data))
    // [3413] spi_write::data = spi_write_page_begin::$4 -- vbum1=vbuz2 
    sta spi_write.data
    // [3414] call spi_write
    jsr spi_write
    // spi_write_page_begin::@5
    // BYTE1(data)
    // [3415] spi_write_page_begin::$6 = byte1  spi_write_page_begin::data#0 -- vbuz1=_byte1_vdum2 
    lda data+1
    sta.z spi_write_page_begin__6
    // spi_write(BYTE1(data))
    // [3416] spi_write::data = spi_write_page_begin::$6 -- vbum1=vbuz2 
    sta spi_write.data
    // [3417] call spi_write
    jsr spi_write
    // spi_write_page_begin::@6
    // BYTE0(data)
    // [3418] spi_write_page_begin::$8 = byte0  spi_write_page_begin::data#0 -- vbuz1=_byte0_vdum2 
    lda data
    sta.z spi_write_page_begin__8
    // spi_write(BYTE0(data))
    // [3419] spi_write::data = spi_write_page_begin::$8 -- vbum1=vbuz2 
    sta spi_write.data
    // [3420] call spi_write
    jsr spi_write
    // spi_write_page_begin::@return
    // }
    // [3421] return 
    rts
  .segment DataVera
    data: .dword 0
}
.segment CodeVera
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
    // [3423] return 
    rts
  .segment DataVera
    data: .byte 0
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
// __mem() char rom_byte_compare(__zp($4e) char *ptr_rom, __mem() char value)
rom_byte_compare: {
    .label ptr_rom = $4e
    // if (*ptr_rom != value)
    // [3424] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbum2_then_la1 
    lda value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [3425] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [3426] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [3426] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    tya
    sta return
    rts
    // [3426] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [3426] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [3427] return 
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
// __mem() unsigned long ultoa_append(__zp($47) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $47
    // [3429] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [3429] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3429] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [3430] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [3431] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [3432] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [3433] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3434] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [3429] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [3429] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [3429] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_ulong.uvalue
    .label sub = ultoa.digit_value
    .label return = printf_ulong.uvalue
    digit: .byte 0
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
// void rom_wait(__zp($2d) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $2b
    .label rom_wait__1 = $29
    .label ptr_rom = $2d
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [3436] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [3437] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    lda (ptr_rom),y
    sta test2
    // test1 & 0x40
    // [3438] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbum2_band_vbuc1 
    lda #$40
    and test1
    sta.z rom_wait__0
    // test2 & 0x40
    // [3439] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbum2_band_vbuc1 
    lda #$40
    and test2
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [3440] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [3441] return 
    rts
  .segment Data
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
    .label rom_ptr1_rom_byte_program__0 = $4b
    .label rom_ptr1_rom_byte_program__2 = $4b
    .label rom_ptr1_return = $4b
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [3443] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_byte_program__2
    lda address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [3444] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [3445] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [3446] rom_write_byte::address#3 = rom_byte_program::address#0
    // [3447] rom_write_byte::value#3 = rom_byte_program::value#0
    // [3448] call rom_write_byte
    // [3243] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [3243] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [3243] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [3449] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [3450] call rom_wait
    // [3435] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [3435] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [3451] return 
    rts
  .segment Data
    .label address = rom_write_byte.address
    .label value = rom_write_byte.value
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
// __mem() unsigned int utoa_append(__zp($45) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $45
    // [3453] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [3453] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3453] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [3454] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [3455] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [3456] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [3457] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3458] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [3453] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [3453] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [3453] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = smc_detect.return
    .label sub = utoa.digit_value
    .label return = smc_detect.return
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
    // [3459] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [3460] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [3461] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [3462] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [3463] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [3464] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [3465] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [3466] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [3467] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [3468] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [3469] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [3470] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [3471] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [3472] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [3473] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [3473] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [3474] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [3475] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [3476] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [3477] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [3478] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
.segment CodeVera
  // spi_fast
spi_fast: {
    // asm
    // asm { ldavera_reg_SPICtrl and#%11111101 stavera_reg_SPICtrl  }
    /*
.proc spi_fast
    lda Vera::Reg::SPICtrl
    and #%11111101
    sta Vera::Reg::SPICtrl
	rts
.endproc
*/
    lda vera_reg_SPICtrl
    and #$fd
    sta vera_reg_SPICtrl
    // spi_fast::@return
    // }
    // [3480] return 
    rts
}
  // spi_select
spi_select: {
    // spi_deselect()
    // [3482] call spi_deselect
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
    // [3483] *vera_reg_SPICtrl = *vera_reg_SPICtrl | 1 -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #1
    ora vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // spi_select::@return
    // }
    // [3484] return 
    rts
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
  display_into_briefing_text: .word __3, __4, str, __6, __7, __8, __9, __10, __11, str, __13, __14, str, __16, __17
  display_into_colors_text: .word __18, __19, str, __21, __22, __23, __24, __25, __26, __27, __28, __29, __30, __31, str, __33
.segment DataVera
  display_jp1_spi_vera_text: .word __34, str, __36, __37, __38, __39, __40, str, __42, __43, str, __45, __46, __47, str, __49
.segment Data
  display_no_valid_smc_bootloader_text: .word __50, str, __52, __53, str, __55, __56, __57, __58
  display_smc_rom_issue_text: .word __59, str, __69, __62, str, __64, __65, __66
  display_smc_unsupported_rom_text: .word __67, str, __69, __70, str, __72, __73
  display_debriefing_text_smc: .word __88, str, main.text, str, __78, __79, __80, str, __82, str, __84, __85, __86, __87
  display_debriefing_text_rom: .word __88, str, __90, __91
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
  __42: .text "2. Once the VERA has been updated, you will be asked to open"
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
  __50: .text "The SMC chip in your CX16 doesn't have a valid bootloader."
  .byte 0
  __52: .text "A valid bootloader is needed to update the SMC chip."
  .byte 0
  __53: .text "Unfortunately, your SMC chip cannot be updated using this tool!"
  .byte 0
  __55: .text "A bootloader can be installed onto the SMC chip using an"
  .byte 0
  __56: .text "an Arduino or an AVR ISP device."
  .byte 0
  __57: .text "Alternatively a new SMC chip with a valid bootloader can be"
  .byte 0
  __58: .text "ordered from TexElec."
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
  s4: .text " "
  .byte 0
  chip: .text "ROM"
  .byte 0
  s5: .text " ... "
  .byte 0
  s6: .text " ..."
  .byte 0
  s21: .text "["
  .byte 0
  info_text6: .text "No update required"
  .byte 0
  s13: .text " differences!"
  .byte 0
  smc_action_text: .text "Reading"
  .byte 0
  smc_action_text_1: .text "Checking"
  .byte 0
  str: .text ""
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
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader: .word 0
  smc_release: .byte 0
  smc_major: .byte 0
  smc_minor: .byte 0
  smc_file_size: .word 0
  smc_file_release: .byte 0
  smc_file_major: .byte 0
  smc_file_minor: .byte 0
  smc_file_size_1: .word 0
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader_1: .word 0
  status_vera: .byte 0
.segment DataVera
  spi_manufacturer: .byte 0
  spi_memory_type: .byte 0
  spi_memory_capacity: .byte 0
