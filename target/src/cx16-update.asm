  // File Comments
/**
 * @file cx16-update.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Main ROM update logic & overall support and test assistance.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Main SPI and VERA update logic, VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL MAIN LOGIC FLOW
 *
 * @version 3.0
 * @date 2023-10-15
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
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Main ROM update logic & overall support and test assistance.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Main SPI and VERA update logic, VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL SMC FIRMWARE UPDATE ROUTINES
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
  .label __snprintf_buffer = $64
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
    // [784] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [789] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [802] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .const bank_set_bram1_bank = 0
    .const bank_set_brom7_bank = 4
    .const bank_set_brom8_bank = 0
    .const bank_set_brom9_bank = 0
    .const bank_set_brom10_bank = 4
    .label main__87 = $d1
    .label main__111 = $e9
    .label main__112 = $ea
    .label main__113 = $d0
    .label main__140 = $e7
    .label main__191 = $5e
    .label check_status_smc1_main__0 = $6d
    .label check_status_rom1_main__0 = $ec
    .label check_status_smc11_main__0 = $ed
    .label check_status_smc12_main__0 = $ee
    .label rom_chip = $d9
    .label rom_chip1 = $da
    .label rom_chip2 = $de
    .label rom_bytes_read = $ef
    .label rom_file_modulo = $e3
    .label rom_file_github_id = $6e
    .label rom_file_prefix_id = $e8
    .label rom_chip3 = $d4
    .label flashed_bytes = $c7
    .label rom_chip4 = $dd
    .label file1 = $d2
    .label rom_bytes_read1 = $df
    .label w = $dc
    .label w1 = $db
    .label main__371 = $d1
    .label main__372 = $d1
    .label main__373 = $d1
    .label main__375 = $d0
    .label main__376 = $d0
    .label main__377 = $d0
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
    // [72] phi from main to main::@97 [phi:main->main::@97]
    // main::@97
    // display_frame_draw()
    // [73] call display_frame_draw
  // ST1 | Reset canvas to 64 columns
    // [851] phi from main::@97 to display_frame_draw [phi:main::@97->display_frame_draw]
    jsr display_frame_draw
    // [74] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // display_frame_title("Commander X16 Update Utility (v2.2.0).")
    // [75] call display_frame_title
    // [892] phi from main::@98 to display_frame_title [phi:main::@98->display_frame_title]
    jsr display_frame_title
    // [76] phi from main::@98 to main::display_info_title1 [phi:main::@98->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [77] call cputsxy
    // [897] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [897] phi cputsxy::s#4 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [897] phi cputsxy::y#4 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [897] phi cputsxy::x#4 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [78] phi from main::display_info_title1 to main::@99 [phi:main::display_info_title1->main::@99]
    // main::@99
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [79] call cputsxy
    // [897] phi from main::@99 to cputsxy [phi:main::@99->cputsxy]
    // [897] phi cputsxy::s#4 = main::s1 [phi:main::@99->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [897] phi cputsxy::y#4 = $11-1 [phi:main::@99->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [897] phi cputsxy::x#4 = 4-2 [phi:main::@99->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [80] phi from main::@99 to main::@67 [phi:main::@99->main::@67]
    // main::@67
    // display_action_progress("Introduction, please read carefully the below!")
    // [81] call display_action_progress
    // [904] phi from main::@67 to display_action_progress [phi:main::@67->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text [phi:main::@67->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [82] phi from main::@67 to main::@100 [phi:main::@67->main::@100]
    // main::@100
    // display_progress_clear()
    // [83] call display_progress_clear
    // [918] phi from main::@100 to display_progress_clear [phi:main::@100->display_progress_clear]
    jsr display_progress_clear
    // [84] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // display_chip_smc()
    // [85] call display_chip_smc
    // [933] phi from main::@101 to display_chip_smc [phi:main::@101->display_chip_smc]
    jsr display_chip_smc
    // [86] phi from main::@101 to main::@102 [phi:main::@101->main::@102]
    // main::@102
    // display_chip_vera()
    // [87] call display_chip_vera
    // [938] phi from main::@102 to display_chip_vera [phi:main::@102->display_chip_vera]
    jsr display_chip_vera
    // [88] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // display_chip_rom()
    // [89] call display_chip_rom
    // [943] phi from main::@103 to display_chip_rom [phi:main::@103->display_chip_rom]
    jsr display_chip_rom
    // [90] phi from main::@103 to main::@104 [phi:main::@103->main::@104]
    // main::@104
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [91] call display_info_smc
    // [962] phi from main::@104 to display_info_smc [phi:main::@104->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = 0 [phi:main::@104->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = 0 [phi:main::@104->display_info_smc#1] -- vwum1=vwuc1 
    sta smc_bootloader_1
    sta smc_bootloader_1+1
    // [962] phi display_info_smc::info_status#20 = BLACK [phi:main::@104->display_info_smc#2] -- vbum1=vbuc1 
    lda #BLACK
    sta display_info_smc.info_status
    jsr display_info_smc
    // [92] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // display_info_vera(STATUS_NONE, NULL)
    // [93] call display_info_vera
    // [998] phi from main::@105 to display_info_vera [phi:main::@105->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = 0 [phi:main::@105->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = 0 [phi:main::@105->display_info_vera#1] -- vbum1=vbuc1 
    sta spi_memory_capacity
    // [998] phi spi_memory_type#107 = 0 [phi:main::@105->display_info_vera#2] -- vbum1=vbuc1 
    sta spi_memory_type
    // [998] phi spi_manufacturer#108 = 0 [phi:main::@105->display_info_vera#3] -- vbum1=vbuc1 
    sta spi_manufacturer
    // [998] phi display_info_vera::info_status#19 = STATUS_NONE [phi:main::@105->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_vera.info_status
    jsr display_info_vera
    // [94] phi from main::@105 to main::@12 [phi:main::@105->main::@12]
    // [94] phi main::rom_chip#2 = 0 [phi:main::@105->main::@12#0] -- vbuz1=vbuc1 
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
    // [1038] phi from main::@14 to main_intro [phi:main::@14->main_intro]
    jsr main_intro
    // [98] phi from main::@14 to main::@108 [phi:main::@14->main::@108]
    // main::@108
    // smc_detect()
    // [99] call smc_detect
    jsr smc_detect
    // [100] smc_detect::return#2 = smc_detect::return#0
    // main::@109
    // smc_bootloader = smc_detect()
    // [101] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwum2 
    lda smc_detect.return
    sta smc_bootloader
    lda smc_detect.return+1
    sta smc_bootloader+1
    // strcpy(smc_version_text, "0.0.0")
    // [102] call strcpy
    // [1066] phi from main::@109 to strcpy [phi:main::@109->strcpy]
    // [1066] phi strcpy::dst#0 = smc_version_text [phi:main::@109->strcpy#0] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z strcpy.dst
    lda #>smc_version_text
    sta.z strcpy.dst+1
    // [1066] phi strcpy::src#0 = main::source1 [phi:main::@109->strcpy#1] -- pbuz1=pbuc1 
    lda #<source1
    sta.z strcpy.src
    lda #>source1
    sta.z strcpy.src+1
    jsr strcpy
    // [103] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // display_chip_smc()
    // [104] call display_chip_smc
    // [933] phi from main::@110 to display_chip_smc [phi:main::@110->display_chip_smc]
    jsr display_chip_smc
    // main::@111
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
    // main::@118
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
    // main::@119
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
    // main::@120
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
    // [1079] phi from main::@120 to smc_get_version_text [phi:main::@120->smc_get_version_text]
    // [1079] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#0 [phi:main::@120->smc_get_version_text#0] -- register_copy 
    // [1079] phi smc_get_version_text::major#2 = smc_get_version_text::major#0 [phi:main::@120->smc_get_version_text#1] -- register_copy 
    // [1079] phi smc_get_version_text::release#2 = smc_get_version_text::release#0 [phi:main::@120->smc_get_version_text#2] -- register_copy 
    // [1079] phi smc_get_version_text::version_string#2 = smc_version_text [phi:main::@120->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // main::@121
    // [127] smc_bootloader#503 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_DETECTED, NULL)
    // [128] call display_info_smc
    // [962] phi from main::@121 to display_info_smc [phi:main::@121->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = 0 [phi:main::@121->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#503 [phi:main::@121->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_DETECTED [phi:main::@121->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_smc.info_status
    jsr display_info_smc
    // [129] phi from main::@121 to main::@2 [phi:main::@121->main::@2]
    // [129] phi smc_minor#398 = smc_minor#0 [phi:main::@121->main::@2#0] -- register_copy 
    // [129] phi smc_major#399 = smc_major#0 [phi:main::@121->main::@2#1] -- register_copy 
    // [129] phi smc_release#400 = smc_release#0 [phi:main::@121->main::@2#2] -- register_copy 
    // main::@2
  __b2:
    // main_vera_detect()
    // [130] call main_vera_detect
    // [1096] phi from main::@2 to main_vera_detect [phi:main::@2->main_vera_detect]
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
    // [1105] phi from main::@68 to rom_detect [phi:main::@68->rom_detect]
    jsr rom_detect
    // [134] phi from main::@68 to main::@122 [phi:main::@68->main::@122]
    // main::@122
    // display_chip_rom()
    // [135] call display_chip_rom
    // [943] phi from main::@122 to display_chip_rom [phi:main::@122->display_chip_rom]
    jsr display_chip_rom
    // [136] phi from main::@122 to main::@20 [phi:main::@122->main::@20]
    // [136] phi main::rom_chip1#10 = 0 [phi:main::@122->main::@20#0] -- vbuz1=vbuc1 
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
    // [904] phi from main::@24 to display_action_progress [phi:main::@24->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text3 [phi:main::@24->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [145] phi from main::@24 to main::@128 [phi:main::@24->main::@128]
    // main::@128
    // smc_read(STATUS_CHECKING)
    // [146] call smc_read
    // [1155] phi from main::@128 to smc_read [phi:main::@128->smc_read]
    // [1155] phi __errno#102 = 0 [phi:main::@128->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [1155] phi __stdio_filecount#128 = 0 [phi:main::@128->smc_read#1] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [1155] phi smc_read::info_status#10 = STATUS_CHECKING [phi:main::@128->smc_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_CHECKING)
    // [147] smc_read::return#2 = smc_read::return#0
    // main::@129
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
    // [1079] phi from main::@26 to smc_get_version_text [phi:main::@26->smc_get_version_text]
    // [1079] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#1 [phi:main::@26->smc_get_version_text#0] -- register_copy 
    // [1079] phi smc_get_version_text::major#2 = smc_get_version_text::major#1 [phi:main::@26->smc_get_version_text#1] -- register_copy 
    // [1079] phi smc_get_version_text::release#2 = smc_get_version_text::release#1 [phi:main::@26->smc_get_version_text#2] -- register_copy 
    // [1079] phi smc_get_version_text::version_string#2 = main::smc_file_version_text [phi:main::@26->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_file_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [158] phi from main::@26 to main::@130 [phi:main::@26->main::@130]
    // main::@130
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [159] call snprintf_init
    // [1205] phi from main::@130 to snprintf_init [phi:main::@130->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@130->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [160] phi from main::@130 to main::@131 [phi:main::@130->main::@131]
    // main::@131
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [161] call printf_str
    // [1210] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s4 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [162] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [163] call printf_string
    // [1219] phi from main::@132 to printf_string [phi:main::@132->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:main::@132->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = main::smc_file_version_text [phi:main::@132->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z printf_string.str
    lda #>smc_file_version_text
    sta.z printf_string.str+1
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:main::@132->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:main::@132->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@133
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [164] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [165] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [167] smc_bootloader#505 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, info_text)
    // [168] call display_info_smc
  // All ok, display file version.
    // [962] phi from main::@133 to display_info_smc [phi:main::@133->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = info_text [phi:main::@133->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#505 [phi:main::@133->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_FLASH [phi:main::@133->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [169] phi from main::@133 to main::CLI2 [phi:main::@133->main::CLI2]
    // [169] phi smc_file_minor#301 = smc_file_minor#0 [phi:main::@133->main::CLI2#0] -- register_copy 
    // [169] phi smc_file_major#301 = smc_file_major#0 [phi:main::@133->main::CLI2#1] -- register_copy 
    // [169] phi smc_file_release#301 = smc_file_release#0 [phi:main::@133->main::CLI2#2] -- register_copy 
    // [169] phi __stdio_filecount#109 = __stdio_filecount#39 [phi:main::@133->main::CLI2#3] -- register_copy 
    // [169] phi __errno#113 = __errno#123 [phi:main::@133->main::CLI2#4] -- register_copy 
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
    // [918] phi from main::@71 to display_progress_clear [phi:main::@71->display_progress_clear]
    jsr display_progress_clear
    // [175] phi from main::@71 to main::@127 [phi:main::@71->main::@127]
    // main::@127
    // main_vera_check()
    // [176] call main_vera_check
    // [1244] phi from main::@127 to main_vera_check [phi:main::@127->main_vera_check]
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
    // main::@244
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
    // main::@74
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [196] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbum1_then_la1 
    // VA3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
    lda check_status_smc3_return
    beq check_status_smc4
    // main::@245
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
    // main::@75
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [203] if(0==main::check_status_smc4_return#0) goto main::check_status_smc5 -- 0_eq_vbum1_then_la1 
    lda check_status_smc4_return
    beq check_status_smc5
    // main::@246
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
    // main::@76
    // smc_supported_rom(rom_release[0])
    // [210] smc_supported_rom::rom_release#0 = *rom_release -- vbum1=_deref_pbuc1 
    lda rom_release
    sta smc_supported_rom.rom_release
    // [211] call smc_supported_rom
    // [1271] phi from main::@76 to smc_supported_rom [phi:main::@76->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_release[0])
    // [212] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@168
    // [213] main::$45 = smc_supported_rom::return#3 -- vbum1=vbum2 
    lda smc_supported_rom.return
    sta main__45
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_release[0]))
    // [214] if(0==main::check_status_smc5_return#0) goto main::check_status_smc6 -- 0_eq_vbum1_then_la1 
    lda check_status_smc5_return
    beq check_status_smc6
    // main::@248
    // [215] if(0==main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::check_status_smc6 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom4_check_status_rom1_return
    beq check_status_smc6
    // main::@247
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
    // main::@77
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [219] if(0==main::check_status_smc6_return#0) goto main::check_status_smc7 -- 0_eq_vbum1_then_la1 
    beq check_status_smc7
    // main::@251
    // [220] if(smc_release#400==smc_file_release#301) goto main::@250 -- vbum1_eq_vbum2_then_la1 
    lda smc_release
    cmp smc_file_release
    bne !__b250+
    jmp __b250
  !__b250:
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
    // [225] phi from main::check_status_vera1 to main::@78 [phi:main::check_status_vera1->main::@78]
    // main::@78
    // check_status_roms(STATUS_ISSUE)
    // [226] call check_status_roms
    // [1278] phi from main::@78 to check_status_roms [phi:main::@78->check_status_roms]
    // [1278] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@78->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [227] check_status_roms::return#3 = check_status_roms::return#2
    // main::@173
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
    // [233] phi from main::check_status_vera2 to main::@79 [phi:main::check_status_vera2->main::@79]
    // main::@79
    // check_status_roms(STATUS_ERROR)
    // [234] call check_status_roms
    // [1278] phi from main::@79 to check_status_roms [phi:main::@79->check_status_roms]
    // [1278] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@79->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [235] check_status_roms::return#4 = check_status_roms::return#2
    // main::@174
    // [236] main::$71 = check_status_roms::return#4 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__71
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [237] if(0!=main::check_status_smc7_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc7_return
    bne check_status_vera3
    // main::@256
    // [238] if(0==main::check_status_vera1_return#0) goto main::@255 -- 0_eq_vbum1_then_la1 
    lda check_status_vera1_return
    bne !__b255+
    jmp __b255
  !__b255:
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
    // main::@80
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
    // [246] phi from main::vera_display_set_border_color1 to main::@89 [phi:main::vera_display_set_border_color1->main::@89]
    // main::@89
    // textcolor(WHITE)
    // [247] call textcolor
    // [784] phi from main::@89 to textcolor [phi:main::@89->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:main::@89->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [248] phi from main::@89 to main::@211 [phi:main::@89->main::@211]
    // main::@211
    // bgcolor(BLUE)
    // [249] call bgcolor
    // [789] phi from main::@211 to bgcolor [phi:main::@211->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:main::@211->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [250] phi from main::@211 to main::@212 [phi:main::@211->main::@212]
    // main::@212
    // clrscr()
    // [251] call clrscr
    jsr clrscr
    // [252] phi from main::@212 to main::@213 [phi:main::@212->main::@213]
    // main::@213
    // printf("There was a severe error updating your VERA!")
    // [253] call printf_str
    // [1210] phi from main::@213 to printf_str [phi:main::@213->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:main::@213->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s15 [phi:main::@213->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // [254] phi from main::@213 to main::@214 [phi:main::@213->main::@214]
    // main::@214
    // printf("You are back at the READY prompt without resetting your CX16.\n\n")
    // [255] call printf_str
    // [1210] phi from main::@214 to printf_str [phi:main::@214->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:main::@214->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s16 [phi:main::@214->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // [256] phi from main::@214 to main::@215 [phi:main::@214->main::@215]
    // main::@215
    // printf("Please don't reset or shut down your VERA until you've\n")
    // [257] call printf_str
    // [1210] phi from main::@215 to printf_str [phi:main::@215->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:main::@215->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s17 [phi:main::@215->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // [258] phi from main::@215 to main::@216 [phi:main::@215->main::@216]
    // main::@216
    // printf("managed to either reflash your VERA with the previous firmware ")
    // [259] call printf_str
    // [1210] phi from main::@216 to printf_str [phi:main::@216->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:main::@216->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s18 [phi:main::@216->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // [260] phi from main::@216 to main::@217 [phi:main::@216->main::@217]
    // main::@217
    // printf("or have update successs retrying!\n\n")
    // [261] call printf_str
    // [1210] phi from main::@217 to printf_str [phi:main::@217->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:main::@217->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s19 [phi:main::@217->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // [262] phi from main::@217 to main::@218 [phi:main::@217->main::@218]
    // main::@218
    // printf("PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n")
    // [263] call printf_str
    // [1210] phi from main::@218 to printf_str [phi:main::@218->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:main::@218->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s20 [phi:main::@218->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // [264] phi from main::@218 to main::@219 [phi:main::@218->main::@219]
    // main::@219
    // wait_moment(32)
    // [265] call wait_moment
    // [1310] phi from main::@219 to wait_moment [phi:main::@219->wait_moment]
    // [1310] phi wait_moment::w#13 = $20 [phi:main::@219->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [266] phi from main::@219 to main::@220 [phi:main::@219->main::@220]
    // main::@220
    // system_reset()
    // [267] call system_reset
    // [1318] phi from main::@220 to system_reset [phi:main::@220->system_reset]
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
    // [277] phi from main::check_status_vera7 to main::@88 [phi:main::check_status_vera7->main::@88]
    // main::@88
    // check_status_roms_less(STATUS_SKIP)
    // [278] call check_status_roms_less
    // [1323] phi from main::@88 to check_status_roms_less [phi:main::@88->check_status_roms_less]
    jsr check_status_roms_less
    // check_status_roms_less(STATUS_SKIP)
    // [279] check_status_roms_less::return#3 = check_status_roms_less::return#2
    // main::@210
    // [280] main::$84 = check_status_roms_less::return#3 -- vbum1=vbum2 
    lda check_status_roms_less.return
    sta main__84
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        check_status_roms_less(STATUS_SKIP))
    // [281] if(0!=main::check_status_smc13_return#0) goto main::@264 -- 0_neq_vbum1_then_la1 
    lda check_status_smc13_return
    beq !__b264+
    jmp __b264
  !__b264:
    // main::@265
    // [282] if(0!=main::check_status_smc14_return#0) goto main::@264 -- 0_neq_vbum1_then_la1 
    lda check_status_smc14_return
    beq !__b264+
    jmp __b264
  !__b264:
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
    // [287] phi from main::check_status_vera8 to main::@91 [phi:main::check_status_vera8->main::@91]
    // main::@91
    // check_status_roms(STATUS_ERROR)
    // [288] call check_status_roms
    // [1278] phi from main::@91 to check_status_roms [phi:main::@91->check_status_roms]
    // [1278] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@91->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [289] check_status_roms::return#10 = check_status_roms::return#2
    // main::@221
    // [290] main::$274 = check_status_roms::return#10 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__274
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [291] if(0!=main::check_status_smc15_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc15_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@267
    // [292] if(0!=main::check_status_vera8_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera8_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@266
    // [293] if(0!=main::$274) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda main__274
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
    // [298] phi from main::check_status_vera9 to main::@93 [phi:main::check_status_vera9->main::@93]
    // main::@93
    // check_status_roms(STATUS_ISSUE)
    // [299] call check_status_roms
    // [1278] phi from main::@93 to check_status_roms [phi:main::@93->check_status_roms]
    // [1278] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@93->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [300] check_status_roms::return#11 = check_status_roms::return#2
    // main::@223
    // [301] main::$279 = check_status_roms::return#11 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__279
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [302] if(0!=main::check_status_smc16_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_smc16_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@269
    // [303] if(0!=main::check_status_vera9_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_vera9_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@268
    // [304] if(0!=main::$279) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda main__279
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
    // [307] phi from main::vera_display_set_border_color5 to main::@95 [phi:main::vera_display_set_border_color5->main::@95]
    // main::@95
    // display_action_progress("Your CX16 update is a success!")
    // [308] call display_action_progress
    // [904] phi from main::@95 to display_action_progress [phi:main::@95->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text37 [phi:main::@95->display_action_progress#0] -- pbuz1=pbuc1 
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
    // main::@96
    // if(check_status_smc(STATUS_FLASHED))
    // [311] if(0!=main::check_status_smc17_return#0) goto main::@56 -- 0_neq_vbum1_then_la1 
    beq !__b56+
    jmp __b56
  !__b56:
    // [312] phi from main::@96 to main::@11 [phi:main::@96->main::@11]
    // main::@11
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [313] call display_progress_text
    // [1332] phi from main::@11 to display_progress_text [phi:main::@11->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_debriefing_text_rom [phi:main::@11->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_debriefing_count_rom [phi:main::@11->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_rom
    sta display_progress_text.lines
    jsr display_progress_text
    // [314] phi from main::@11 main::@90 main::@94 to main::@4 [phi:main::@11/main::@90/main::@94->main::@4]
    // main::@4
  __b4:
    // textcolor(PINK)
    // [315] call textcolor
  // DE6 | Wait until reset
    // [784] phi from main::@4 to textcolor [phi:main::@4->textcolor]
    // [784] phi textcolor::color#23 = PINK [phi:main::@4->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [316] phi from main::@4 to main::@236 [phi:main::@4->main::@236]
    // main::@236
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [317] call display_progress_line
    // [1342] phi from main::@236 to display_progress_line [phi:main::@236->display_progress_line]
    // [1342] phi display_progress_line::text#3 = main::text [phi:main::@236->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1342] phi display_progress_line::line#3 = 2 [phi:main::@236->display_progress_line#1] -- vbum1=vbuc1 
    lda #2
    sta display_progress_line.line
    jsr display_progress_line
    // [318] phi from main::@236 to main::@237 [phi:main::@236->main::@237]
    // main::@237
    // textcolor(WHITE)
    // [319] call textcolor
    // [784] phi from main::@237 to textcolor [phi:main::@237->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:main::@237->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [320] phi from main::@237 to main::@64 [phi:main::@237->main::@64]
    // [320] phi main::w1#2 = $78 [phi:main::@237->main::@64#0] -- vbuz1=vbuc1 
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
    // [1318] phi from main::@66 to system_reset [phi:main::@66->system_reset]
    jsr system_reset
    rts
    // [324] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
  __b65:
    // wait_moment(1)
    // [325] call wait_moment
    // [1310] phi from main::@65 to wait_moment [phi:main::@65->wait_moment]
    // [1310] phi wait_moment::w#13 = 1 [phi:main::@65->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [326] phi from main::@65 to main::@238 [phi:main::@65->main::@238]
    // main::@238
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [327] call snprintf_init
    // [1205] phi from main::@238 to snprintf_init [phi:main::@238->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@238->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [328] phi from main::@238 to main::@239 [phi:main::@238->main::@239]
    // main::@239
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [329] call printf_str
    // [1210] phi from main::@239 to printf_str [phi:main::@239->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@239->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s24 [phi:main::@239->printf_str#1] -- pbuz1=pbuc1 
    lda #<s24
    sta.z printf_str.s
    lda #>s24
    sta.z printf_str.s+1
    jsr printf_str
    // main::@240
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [330] printf_uchar::uvalue#17 = main::w1#2 -- vbum1=vbuz2 
    lda.z w1
    sta printf_uchar.uvalue
    // [331] call printf_uchar
    // [1347] phi from main::@240 to printf_uchar [phi:main::@240->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 0 [phi:main::@240->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:main::@240->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:main::@240->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:main::@240->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#17 [phi:main::@240->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [332] phi from main::@240 to main::@241 [phi:main::@240->main::@241]
    // main::@241
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [333] call printf_str
    // [1210] phi from main::@241 to printf_str [phi:main::@241->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@241->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s25 [phi:main::@241->printf_str#1] -- pbuz1=pbuc1 
    lda #<s25
    sta.z printf_str.s
    lda #>s25
    sta.z printf_str.s+1
    jsr printf_str
    // main::@242
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
    // [1358] phi from main::@242 to display_action_text [phi:main::@242->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:main::@242->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@243
    // for (unsigned char w=120; w>0; w--)
    // [338] main::w1#1 = -- main::w1#2 -- vbuz1=_dec_vbuz1 
    dec.z w1
    // [320] phi from main::@243 to main::@64 [phi:main::@243->main::@64]
    // [320] phi main::w1#2 = main::w1#1 [phi:main::@243->main::@64#0] -- register_copy 
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
    // [1372] phi from main::@62 to smc_reset [phi:main::@62->smc_reset]
    jsr smc_reset
    // [342] phi from main::@56 main::@62 to main::@57 [phi:main::@56/main::@62->main::@57]
    // main::@57
  __b57:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [343] call display_progress_text
    // [1332] phi from main::@57 to display_progress_text [phi:main::@57->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_debriefing_text_smc [phi:main::@57->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_debriefing_count_smc [phi:main::@57->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_smc
    sta display_progress_text.lines
    jsr display_progress_text
    // [344] phi from main::@57 to main::@224 [phi:main::@57->main::@224]
    // main::@224
    // textcolor(PINK)
    // [345] call textcolor
    // [784] phi from main::@224 to textcolor [phi:main::@224->textcolor]
    // [784] phi textcolor::color#23 = PINK [phi:main::@224->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [346] phi from main::@224 to main::@225 [phi:main::@224->main::@225]
    // main::@225
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [347] call display_progress_line
    // [1342] phi from main::@225 to display_progress_line [phi:main::@225->display_progress_line]
    // [1342] phi display_progress_line::text#3 = main::text [phi:main::@225->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1342] phi display_progress_line::line#3 = 2 [phi:main::@225->display_progress_line#1] -- vbum1=vbuc1 
    lda #2
    sta display_progress_line.line
    jsr display_progress_line
    // [348] phi from main::@225 to main::@226 [phi:main::@225->main::@226]
    // main::@226
    // textcolor(WHITE)
    // [349] call textcolor
    // [784] phi from main::@226 to textcolor [phi:main::@226->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:main::@226->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [350] phi from main::@226 to main::@58 [phi:main::@226->main::@58]
    // [350] phi main::w#2 = $78 [phi:main::@226->main::@58#0] -- vbuz1=vbuc1 
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
    // [1205] phi from main::@60 to snprintf_init [phi:main::@60->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@60->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [354] phi from main::@60 to main::@233 [phi:main::@60->main::@233]
    // main::@233
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [355] call printf_str
    // [1210] phi from main::@233 to printf_str [phi:main::@233->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@233->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s23 [phi:main::@233->printf_str#1] -- pbuz1=pbuc1 
    lda #<s23
    sta.z printf_str.s
    lda #>s23
    sta.z printf_str.s+1
    jsr printf_str
    // main::@234
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
    // [1358] phi from main::@234 to display_action_text [phi:main::@234->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:main::@234->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [360] phi from main::@234 to main::@235 [phi:main::@234->main::@235]
    // main::@235
    // smc_reset()
    // [361] call smc_reset
  // DE5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [1372] phi from main::@235 to smc_reset [phi:main::@235->smc_reset]
    jsr smc_reset
    // [362] phi from main::@235 main::@61 to main::@61 [phi:main::@235/main::@61->main::@61]
  __b10:
  // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
    // main::@61
    jmp __b10
    // [363] phi from main::@58 to main::@59 [phi:main::@58->main::@59]
    // main::@59
  __b59:
    // wait_moment(1)
    // [364] call wait_moment
    // [1310] phi from main::@59 to wait_moment [phi:main::@59->wait_moment]
    // [1310] phi wait_moment::w#13 = 1 [phi:main::@59->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [365] phi from main::@59 to main::@227 [phi:main::@59->main::@227]
    // main::@227
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [366] call snprintf_init
    // [1205] phi from main::@227 to snprintf_init [phi:main::@227->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@227->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [367] phi from main::@227 to main::@228 [phi:main::@227->main::@228]
    // main::@228
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [368] call printf_str
    // [1210] phi from main::@228 to printf_str [phi:main::@228->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@228->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s21 [phi:main::@228->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@229
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [369] printf_uchar::uvalue#16 = main::w#2 -- vbum1=vbuz2 
    lda.z w
    sta printf_uchar.uvalue
    // [370] call printf_uchar
    // [1347] phi from main::@229 to printf_uchar [phi:main::@229->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:main::@229->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 3 [phi:main::@229->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:main::@229->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:main::@229->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#16 [phi:main::@229->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [371] phi from main::@229 to main::@230 [phi:main::@229->main::@230]
    // main::@230
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [372] call printf_str
    // [1210] phi from main::@230 to printf_str [phi:main::@230->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@230->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s22 [phi:main::@230->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@231
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
    // [1358] phi from main::@231 to display_action_text [phi:main::@231->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:main::@231->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@232
    // for (unsigned char w=120; w>0; w--)
    // [377] main::w#1 = -- main::w#2 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [350] phi from main::@232 to main::@58 [phi:main::@232->main::@58]
    // [350] phi main::w#2 = main::w#1 [phi:main::@232->main::@58#0] -- register_copy 
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
    // [380] phi from main::vera_display_set_border_color4 to main::@94 [phi:main::vera_display_set_border_color4->main::@94]
    // main::@94
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [381] call display_action_progress
    // [904] phi from main::@94 to display_action_progress [phi:main::@94->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text36 [phi:main::@94->display_action_progress#0] -- pbuz1=pbuc1 
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
    // [384] phi from main::vera_display_set_border_color3 to main::@92 [phi:main::vera_display_set_border_color3->main::@92]
    // main::@92
    // display_action_progress("Update Failure! Your CX16 may no longer boot!")
    // [385] call display_action_progress
    // [904] phi from main::@92 to display_action_progress [phi:main::@92->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text34 [phi:main::@92->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text34
    sta.z display_action_progress.info_text
    lda #>info_text34
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [386] phi from main::@92 to main::@222 [phi:main::@92->main::@222]
    // main::@222
    // display_action_text("Take a photo of this screen, shut down power and retry!")
    // [387] call display_action_text
    // [1358] phi from main::@222 to display_action_text [phi:main::@222->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main::info_text35 [phi:main::@222->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text35
    sta.z display_action_text.info_text
    lda #>info_text35
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [388] phi from main::@222 main::@63 to main::@63 [phi:main::@222/main::@63->main::@63]
    // main::@63
  __b63:
    jmp __b63
    // main::@264
  __b264:
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        check_status_roms_less(STATUS_SKIP))
    // [389] if(0!=main::check_status_vera6_return#0) goto main::@263 -- 0_neq_vbum1_then_la1 
    lda check_status_vera6_return
    bne __b263
    // main::@271
    // [390] if(0==main::check_status_vera7_return#0) goto main::check_status_smc15 -- 0_eq_vbum1_then_la1 
    lda check_status_vera7_return
    bne !check_status_smc15+
    jmp check_status_smc15
  !check_status_smc15:
    // main::@263
  __b263:
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
    // [394] phi from main::vera_display_set_border_color2 to main::@90 [phi:main::vera_display_set_border_color2->main::@90]
    // main::@90
    // display_action_progress("No CX16 component has been updated with new firmware!")
    // [395] call display_action_progress
    // [904] phi from main::@90 to display_action_progress [phi:main::@90->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text33 [phi:main::@90->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text33
    sta.z display_action_progress.info_text
    lda #>info_text33
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b4
    // main::@255
  __b255:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [396] if(0!=main::$62) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda main__62
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@254
    // [397] if(0==main::check_status_smc8_return#0) goto main::@253 -- 0_eq_vbum1_then_la1 
    lda check_status_smc8_return
    beq __b253
    jmp check_status_vera3
    // main::@253
  __b253:
    // [398] if(0!=main::check_status_vera2_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera2_return
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@252
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
    // [407] phi from main::check_status_cx16_rom5_check_status_rom1 to main::@81 [phi:main::check_status_cx16_rom5_check_status_rom1->main::@81]
    // main::@81
    // check_status_card_roms(STATUS_FLASH)
    // [408] call check_status_card_roms
    // [1381] phi from main::@81 to check_status_card_roms [phi:main::@81->check_status_card_roms]
    jsr check_status_card_roms
    // check_status_card_roms(STATUS_FLASH)
    // [409] check_status_card_roms::return#3 = check_status_card_roms::return#2
    // main::@177
    // [410] main::$186 = check_status_card_roms::return#3 -- vbum1=vbum2 
    lda check_status_card_roms.return
    sta main__186
    // if(check_status_vera(STATUS_FLASH) || check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [411] if(0!=main::check_status_vera4_return#0) goto main::@9 -- 0_neq_vbum1_then_la1 
    lda check_status_vera4_return
    beq !__b9+
    jmp __b9
  !__b9:
    // main::@259
    // [412] if(0!=main::check_status_smc9_return#0) goto main::@9 -- 0_neq_vbum1_then_la1 
    lda check_status_smc9_return
    beq !__b9+
    jmp __b9
  !__b9:
    // main::@258
    // [413] if(0!=main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::@9 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom5_check_status_rom1_return
    beq !__b9+
    jmp __b9
  !__b9:
    // main::@257
    // [414] if(0!=main::$186) goto main::@9 -- 0_neq_vbum1_then_la1 
    lda main__186
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
    // main::@82
    // if(check_status_vera(STATUS_FLASH))
    // [421] if(0==main::check_status_vera5_return#0) goto main::SEI5 -- 0_eq_vbum1_then_la1 
    beq SEI5
    // [422] phi from main::@82 to main::@51 [phi:main::@82->main::@51]
    // main::@51
    // display_progress_text(display_jp1_spi_vera_text, display_jp1_spi_vera_count)
    // [423] call display_progress_text
    // [1332] phi from main::@51 to display_progress_text [phi:main::@51->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_jp1_spi_vera_text [phi:main::@51->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_jp1_spi_vera_text
    sta.z display_progress_text.text
    lda #>display_jp1_spi_vera_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_jp1_spi_vera_count [phi:main::@51->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_jp1_spi_vera_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [424] phi from main::@51 to main::@183 [phi:main::@51->main::@183]
    // main::@183
    // util_wait_space()
    // [425] call util_wait_space
    // [1390] phi from main::@183 to util_wait_space [phi:main::@183->util_wait_space]
    jsr util_wait_space
    // [426] phi from main::@183 to main::@184 [phi:main::@183->main::@184]
    // main::@184
    // main_vera_flash()
    // [427] call main_vera_flash
    // [1393] phi from main::@184 to main_vera_flash [phi:main::@184->main_vera_flash]
    jsr main_vera_flash
    // [428] phi from main::@184 main::@82 to main::SEI5 [phi:main::@184/main::@82->main::SEI5]
    // [428] phi __stdio_filecount#113 = __stdio_filecount#36 [phi:main::@184/main::@82->main::SEI5#0] -- register_copy 
    // [428] phi __errno#117 = __errno#123 [phi:main::@184/main::@82->main::SEI5#1] -- register_copy 
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
    // [431] phi from main::bank_set_brom8 to main::@83 [phi:main::bank_set_brom8->main::@83]
    // main::@83
    // display_progress_clear()
    // [432] call display_progress_clear
    // [918] phi from main::@83 to display_progress_clear [phi:main::@83->display_progress_clear]
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
    // main::@84
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [438] if(0==main::check_status_smc10_return#0) goto main::SEI6 -- 0_eq_vbum1_then_la1 
    lda check_status_smc10_return
    beq SEI6
    // main::@260
    // [439] if(0!=main::check_status_cx16_rom6_check_status_rom1_return#0) goto main::@52 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom6_check_status_rom1_return
    beq !__b52+
    jmp __b52
  !__b52:
    // [440] phi from main::@260 to main::SEI6 [phi:main::@260->main::SEI6]
    // [440] phi from main::@187 main::@40 main::@41 main::@55 main::@84 to main::SEI6 [phi:main::@187/main::@40/main::@41/main::@55/main::@84->main::SEI6]
    // [440] phi __stdio_filecount#582 = __stdio_filecount#39 [phi:main::@187/main::@40/main::@41/main::@55/main::@84->main::SEI6#0] -- register_copy 
    // [440] phi __errno#589 = __errno#123 [phi:main::@187/main::@40/main::@41/main::@55/main::@84->main::SEI6#1] -- register_copy 
    // main::SEI6
  SEI6:
    // asm
    // asm { sei  }
    sei
    // [442] phi from main::SEI6 to main::@42 [phi:main::SEI6->main::@42]
    // [442] phi __stdio_filecount#114 = __stdio_filecount#582 [phi:main::SEI6->main::@42#0] -- register_copy 
    // [442] phi __errno#118 = __errno#589 [phi:main::SEI6->main::@42#1] -- register_copy 
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
    // [918] phi from main::@43 to display_progress_clear [phi:main::@43->display_progress_clear]
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
    // main::@85
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
    // main::@86
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [453] if(main::rom_chip4#10==0) goto main::@262 -- vbuz1_eq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda.z rom_chip4
    bne !__b262+
    jmp __b262
  !__b262:
    // main::@261
  __b261:
    // [454] if(main::rom_chip4#10!=0) goto main::bank_set_brom9 -- vbuz1_neq_0_then_la1 
    lda.z rom_chip4
    bne bank_set_brom9
    // main::@50
    // display_info_rom(rom_chip, STATUS_ISSUE, "SMC Update failed!")
    // [455] display_info_rom::rom_chip#11 = main::rom_chip4#10 -- vbum1=vbuz2 
    sta display_info_rom.rom_chip
    // [456] call display_info_rom
    // [1566] phi from main::@50 to display_info_rom [phi:main::@50->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = main::info_text29 [phi:main::@50->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_info_rom.info_text
    lda #>info_text29
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#11 [phi:main::@50->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:main::@50->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    // [457] phi from main::@198 main::@209 main::@45 main::@49 main::@50 main::@85 to main::@44 [phi:main::@198/main::@209/main::@45/main::@49/main::@50/main::@85->main::@44]
    // [457] phi __stdio_filecount#583 = __stdio_filecount#12 [phi:main::@198/main::@209/main::@45/main::@49/main::@50/main::@85->main::@44#0] -- register_copy 
    // [457] phi __errno#590 = __errno#123 [phi:main::@198/main::@209/main::@45/main::@49/main::@50/main::@85->main::@44#1] -- register_copy 
    // main::@44
  __b44:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [458] main::rom_chip4#1 = -- main::rom_chip4#10 -- vbuz1=_dec_vbuz1 
    dec.z rom_chip4
    // [442] phi from main::@44 to main::@42 [phi:main::@44->main::@42]
    // [442] phi __stdio_filecount#114 = __stdio_filecount#583 [phi:main::@44->main::@42#0] -- register_copy 
    // [442] phi __errno#118 = __errno#590 [phi:main::@44->main::@42#1] -- register_copy 
    // [442] phi main::rom_chip4#10 = main::rom_chip4#1 [phi:main::@44->main::@42#2] -- register_copy 
    jmp __b42
    // main::bank_set_brom9
  bank_set_brom9:
    // BROM = bank
    // [459] BROM = main::bank_set_brom9_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom9_bank
    sta.z BROM
    // [460] phi from main::bank_set_brom9 to main::@87 [phi:main::bank_set_brom9->main::@87]
    // main::@87
    // display_progress_clear()
    // [461] call display_progress_clear
    // [918] phi from main::@87 to display_progress_clear [phi:main::@87->display_progress_clear]
    jsr display_progress_clear
    // main::@191
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
    // [1611] phi from main::@191 to rom_file [phi:main::@191->rom_file]
    // [1611] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@191->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [465] rom_file::return#5 = rom_file::return#2
    // main::@192
    // [466] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [467] call snprintf_init
    // [1205] phi from main::@192 to snprintf_init [phi:main::@192->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@192->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [468] phi from main::@192 to main::@193 [phi:main::@192->main::@193]
    // main::@193
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [469] call printf_str
    // [1210] phi from main::@193 to printf_str [phi:main::@193->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@193->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s11 [phi:main::@193->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@194
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [470] printf_string::str#25 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z printf_string.str
    lda.z file1+1
    sta.z printf_string.str+1
    // [471] call printf_string
    // [1219] phi from main::@194 to printf_string [phi:main::@194->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:main::@194->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#25 [phi:main::@194->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:main::@194->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:main::@194->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [472] phi from main::@194 to main::@195 [phi:main::@194->main::@195]
    // main::@195
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [473] call printf_str
    // [1210] phi from main::@195 to printf_str [phi:main::@195->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@195->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s12 [phi:main::@195->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@196
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
    // [904] phi from main::@196 to display_action_progress [phi:main::@196->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = info_text [phi:main::@196->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@197
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [478] main::$317 = main::rom_chip4#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip4
    asl
    asl
    sta main__317
    // [479] rom_read::rom_chip#1 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_read.rom_chip
    // [480] rom_read::file#1 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z rom_read.file
    lda.z file1+1
    sta.z rom_read.file+1
    // [481] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_read.brom_bank_start
    // [482] rom_read::rom_size#1 = rom_sizes[main::$317] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__317
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [483] call rom_read
    // [1617] phi from main::@197 to rom_read [phi:main::@197->rom_read]
    // [1617] phi rom_read::rom_chip#20 = rom_read::rom_chip#1 [phi:main::@197->rom_read#0] -- register_copy 
    // [1617] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@197->rom_read#1] -- register_copy 
    // [1617] phi __errno#105 = __errno#118 [phi:main::@197->rom_read#2] -- register_copy 
    // [1617] phi __stdio_filecount#100 = __stdio_filecount#114 [phi:main::@197->rom_read#3] -- register_copy 
    // [1617] phi rom_read::file#10 = rom_read::file#1 [phi:main::@197->rom_read#4] -- register_copy 
    // [1617] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#2 [phi:main::@197->rom_read#5] -- register_copy 
    // [1617] phi rom_read::info_status#11 = STATUS_READING [phi:main::@197->rom_read#6] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [484] rom_read::return#3 = rom_read::return#0
    // main::@198
    // [485] main::rom_bytes_read1#0 = rom_read::return#3 -- vduz1=vdum2 
    lda rom_read.return
    sta.z rom_bytes_read1
    lda rom_read.return+1
    sta.z rom_bytes_read1+1
    lda rom_read.return+2
    sta.z rom_bytes_read1+2
    lda rom_read.return+3
    sta.z rom_bytes_read1+3
    // if(rom_bytes_read)
    // [486] if(0==main::rom_bytes_read1#0) goto main::@44 -- 0_eq_vduz1_then_la1 
    lda.z rom_bytes_read1
    ora.z rom_bytes_read1+1
    ora.z rom_bytes_read1+2
    ora.z rom_bytes_read1+3
    bne !__b44+
    jmp __b44
  !__b44:
    // [487] phi from main::@198 to main::@47 [phi:main::@198->main::@47]
    // main::@47
    // display_action_progress("Comparing ... (.) data, (=) same, (*) different.")
    // [488] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [904] phi from main::@47 to display_action_progress [phi:main::@47->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text30 [phi:main::@47->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z display_action_progress.info_text
    lda #>info_text30
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@199
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [489] display_info_rom::rom_chip#12 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [490] call display_info_rom
    // [1566] phi from main::@199 to display_info_rom [phi:main::@199->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = str [phi:main::@199->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_rom.info_text
    lda #>str
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#12 [phi:main::@199->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:main::@199->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@200
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [491] rom_verify::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_verify.rom_chip
    // [492] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_verify.rom_bank_start
    // [493] rom_verify::file_size#0 = file_sizes[main::$317] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__317
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [494] call rom_verify
  // Verify the ROM...
    // [1697] phi from main::@200 to rom_verify [phi:main::@200->rom_verify]
    jsr rom_verify
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [495] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@201
    // [496] main::rom_differences#0 = rom_verify::return#2 -- vdum1=vdum2 
    lda rom_verify.return
    sta rom_differences
    lda rom_verify.return+1
    sta rom_differences+1
    lda rom_verify.return+2
    sta rom_differences+2
    lda rom_verify.return+3
    sta rom_differences+3
    // if (!rom_differences)
    // [497] if(0==main::rom_differences#0) goto main::@45 -- 0_eq_vdum1_then_la1 
    lda rom_differences
    ora rom_differences+1
    ora rom_differences+2
    ora rom_differences+3
    bne !__b45+
    jmp __b45
  !__b45:
    // [498] phi from main::@201 to main::@48 [phi:main::@201->main::@48]
    // main::@48
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [499] call snprintf_init
    // [1205] phi from main::@48 to snprintf_init [phi:main::@48->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@48->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@202
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [500] printf_ulong::uvalue#13 = main::rom_differences#0 -- vdum1=vdum2 
    lda rom_differences
    sta printf_ulong.uvalue
    lda rom_differences+1
    sta printf_ulong.uvalue+1
    lda rom_differences+2
    sta printf_ulong.uvalue+2
    lda rom_differences+3
    sta printf_ulong.uvalue+3
    // [501] call printf_ulong
    // [1761] phi from main::@202 to printf_ulong [phi:main::@202->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:main::@202->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:main::@202->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main::@202->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#13 [phi:main::@202->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [502] phi from main::@202 to main::@203 [phi:main::@202->main::@203]
    // main::@203
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [503] call printf_str
    // [1210] phi from main::@203 to printf_str [phi:main::@203->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@203->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s13 [phi:main::@203->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@204
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [504] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [505] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [507] display_info_rom::rom_chip#14 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [508] call display_info_rom
    // [1566] phi from main::@204 to display_info_rom [phi:main::@204->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = info_text [phi:main::@204->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#14 [phi:main::@204->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@204->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@205
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [509] rom_flash::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta rom_flash.rom_chip
    // [510] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [511] rom_flash::file_size#0 = file_sizes[main::$317] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__317
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [512] call rom_flash
    // [1771] phi from main::@205 to rom_flash [phi:main::@205->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [513] rom_flash::return#2 = rom_flash::flash_errors#12
    // main::@206
    // [514] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [515] if(0!=main::rom_flash_errors#0) goto main::@46 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b46
    // main::@49
    // display_info_rom(rom_chip, STATUS_FLASHED, NULL)
    // [516] display_info_rom::rom_chip#16 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [517] call display_info_rom
  // RFL3 | Flash ROM and all ok
    // [1566] phi from main::@49 to display_info_rom [phi:main::@49->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = 0 [phi:main::@49->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#16 [phi:main::@49->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_FLASHED [phi:main::@49->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // [518] phi from main::@206 to main::@46 [phi:main::@206->main::@46]
    // main::@46
  __b46:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [519] call snprintf_init
    // [1205] phi from main::@46 to snprintf_init [phi:main::@46->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@46->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@207
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [520] printf_ulong::uvalue#14 = main::rom_flash_errors#0 -- vdum1=vdum2 
    lda rom_flash_errors
    sta printf_ulong.uvalue
    lda rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [521] call printf_ulong
    // [1761] phi from main::@207 to printf_ulong [phi:main::@207->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 0 [phi:main::@207->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 0 [phi:main::@207->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = DECIMAL [phi:main::@207->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#14 [phi:main::@207->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [522] phi from main::@207 to main::@208 [phi:main::@207->main::@208]
    // main::@208
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [523] call printf_str
    // [1210] phi from main::@208 to printf_str [phi:main::@208->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@208->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s14 [phi:main::@208->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@209
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [524] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [525] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [527] display_info_rom::rom_chip#15 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [528] call display_info_rom
    // [1566] phi from main::@209 to display_info_rom [phi:main::@209->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = info_text [phi:main::@209->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#15 [phi:main::@209->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:main::@209->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // main::@45
  __b45:
    // display_info_rom(rom_chip, STATUS_SKIP, "No update required")
    // [529] display_info_rom::rom_chip#13 = main::rom_chip4#10 -- vbum1=vbuz2 
    lda.z rom_chip4
    sta display_info_rom.rom_chip
    // [530] call display_info_rom
  // RFL1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Flashed. | None
    // [1566] phi from main::@45 to display_info_rom [phi:main::@45->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = info_text6 [phi:main::@45->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text6
    sta.z display_info_rom.info_text
    lda #>@info_text6
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#13 [phi:main::@45->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@45->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // main::@262
  __b262:
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [531] if(0!=main::check_status_smc11_return#0) goto main::bank_set_brom9 -- 0_neq_vbum1_then_la1 
    lda check_status_smc11_return
    beq !bank_set_brom9+
    jmp bank_set_brom9
  !bank_set_brom9:
    // main::@270
    // [532] if(0!=main::check_status_smc12_return#0) goto main::bank_set_brom9 -- 0_neq_vbum1_then_la1 
    lda check_status_smc12_return
    beq !bank_set_brom9+
    jmp bank_set_brom9
  !bank_set_brom9:
    jmp __b261
    // [533] phi from main::@260 to main::@52 [phi:main::@260->main::@52]
    // main::@52
  __b52:
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [534] call display_action_progress
    // [904] phi from main::@52 to display_action_progress [phi:main::@52->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text23 [phi:main::@52->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_action_progress.info_text
    lda #>info_text23
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [535] phi from main::@52 to main::@185 [phi:main::@52->main::@185]
    // main::@185
    // display_progress_clear()
    // [536] call display_progress_clear
    // [918] phi from main::@185 to display_progress_clear [phi:main::@185->display_progress_clear]
    jsr display_progress_clear
    // [537] phi from main::@185 to main::@186 [phi:main::@185->main::@186]
    // main::@186
    // smc_read(STATUS_READING)
    // [538] call smc_read
    // [1155] phi from main::@186 to smc_read [phi:main::@186->smc_read]
    // [1155] phi __errno#102 = __errno#117 [phi:main::@186->smc_read#0] -- register_copy 
    // [1155] phi __stdio_filecount#128 = __stdio_filecount#113 [phi:main::@186->smc_read#1] -- register_copy 
    // [1155] phi smc_read::info_status#10 = STATUS_READING [phi:main::@186->smc_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_READING)
    // [539] smc_read::return#3 = smc_read::return#0
    // main::@187
    // smc_file_size = smc_read(STATUS_READING)
    // [540] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [541] if(0==smc_file_size#1) goto main::SEI6 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !SEI6+
    jmp SEI6
  !SEI6:
    // [542] phi from main::@187 to main::@53 [phi:main::@187->main::@53]
    // main::@53
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [543] call display_action_text
  // Flash the SMC chip.
    // [1358] phi from main::@53 to display_action_text [phi:main::@53->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main::info_text24 [phi:main::@53->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_action_text.info_text
    lda #>info_text24
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@188
    // [544] smc_bootloader#510 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [545] call display_info_smc
    // [962] phi from main::@188 to display_info_smc [phi:main::@188->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text25 [phi:main::@188->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z display_info_smc.info_text
    lda #>info_text25
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#510 [phi:main::@188->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_FLASHING [phi:main::@188->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_smc.info_status
    jsr display_info_smc
    // main::@189
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [546] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta smc_flash.smc_bytes_total+1
    // [547] call smc_flash
    // [1870] phi from main::@189 to smc_flash [phi:main::@189->smc_flash]
    jsr smc_flash
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [548] smc_flash::return#5 = smc_flash::return#1
    // main::@190
    // [549] main::flashed_bytes#0 = smc_flash::return#5 -- vwuz1=vwum2 
    lda smc_flash.return
    sta.z flashed_bytes
    lda smc_flash.return+1
    sta.z flashed_bytes+1
    // if(flashed_bytes)
    // [550] if(0!=main::flashed_bytes#0) goto main::@40 -- 0_neq_vwuz1_then_la1 
    lda.z flashed_bytes
    ora.z flashed_bytes+1
    bne __b40
    // main::@54
    // if(flashed_bytes == (unsigned int)0xFFFF)
    // [551] if(main::flashed_bytes#0==$ffff) goto main::@41 -- vwuz1_eq_vwuc1_then_la1 
    lda.z flashed_bytes
    cmp #<$ffff
    bne !+
    lda.z flashed_bytes+1
    cmp #>$ffff
    beq __b41
  !:
    // main::@55
    // [552] smc_bootloader#516 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "POWER/RESET not pressed!")
    // [553] call display_info_smc
  // SFL2 | no action on POWER/RESET press request
    // [962] phi from main::@55 to display_info_smc [phi:main::@55->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text28 [phi:main::@55->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_info_smc.info_text
    lda #>info_text28
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#516 [phi:main::@55->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@55->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // main::@41
  __b41:
    // [554] smc_bootloader#515 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC has errors!")
    // [555] call display_info_smc
  // SFL3 | errors during flash
    // [962] phi from main::@41 to display_info_smc [phi:main::@41->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text27 [phi:main::@41->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_info_smc.info_text
    lda #>info_text27
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#515 [phi:main::@41->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main::@41->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // main::@40
  __b40:
    // [556] smc_bootloader#514 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHED, "")
    // [557] call display_info_smc
  // SFL1 | and POWER/RESET pressed
    // [962] phi from main::@40 to display_info_smc [phi:main::@40->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = str [phi:main::@40->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_smc.info_text
    lda #>str
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#514 [phi:main::@40->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_FLASHED [phi:main::@40->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI6
    // [558] phi from main::@177 main::@257 main::@258 main::@259 to main::@9 [phi:main::@177/main::@257/main::@258/main::@259->main::@9]
    // main::@9
  __b9:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [559] call display_action_progress
    // [904] phi from main::@9 to display_action_progress [phi:main::@9->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text17 [phi:main::@9->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_action_progress.info_text
    lda #>info_text17
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [560] phi from main::@9 to main::@178 [phi:main::@9->main::@178]
    // main::@178
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [561] call util_wait_key
    // [2019] phi from main::@178 to util_wait_key [phi:main::@178->util_wait_key]
    // [2019] phi util_wait_key::filter#13 = main::filter1 [phi:main::@178->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z util_wait_key.filter
    lda #>filter1
    sta.z util_wait_key.filter+1
    // [2019] phi util_wait_key::info_text#3 = main::info_text18 [phi:main::@178->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z util_wait_key.info_text
    lda #>info_text18
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [562] util_wait_key::return#4 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return_1
    // main::@179
    // [563] main::ch1#0 = util_wait_key::return#4 -- vbum1=vbum2 
    sta ch1
    // strchr("nN", ch)
    // [564] strchr::c#1 = main::ch1#0 -- vbum1=vbum2 
    sta strchr.c
    // [565] call strchr
    // [2043] phi from main::@179 to strchr [phi:main::@179->strchr]
    // [2043] phi strchr::c#4 = strchr::c#1 [phi:main::@179->strchr#0] -- register_copy 
    // [2043] phi strchr::str#2 = (const void *)main::$344 [phi:main::@179->strchr#1] -- pvoz1=pvoc1 
    lda #<main__344
    sta.z strchr.str
    lda #>main__344
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [566] strchr::return#4 = strchr::return#2
    // main::@180
    // [567] main::$191 = strchr::return#4
    // if(strchr("nN", ch))
    // [568] if((void *)0==main::$191) goto main::bank_set_bram1 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__191
    cmp #<0
    bne !+
    lda.z main__191+1
    cmp #>0
    bne !bank_set_bram1+
    jmp bank_set_bram1
  !bank_set_bram1:
  !:
    // main::@10
    // [569] smc_bootloader#504 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [570] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [962] phi from main::@10 to display_info_smc [phi:main::@10->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text19 [phi:main::@10->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#504 [phi:main::@10->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@10->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // main::@181
    // [571] spi_manufacturer#581 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [572] spi_memory_type#582 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [573] spi_memory_capacity#583 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [574] call display_info_vera
    // [998] phi from main::@181 to display_info_vera [phi:main::@181->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = main::info_text19 [phi:main::@181->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_vera.info_text
    lda #>info_text19
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#583 [phi:main::@181->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#582 [phi:main::@181->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#581 [phi:main::@181->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main::@181->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [575] phi from main::@181 to main::@37 [phi:main::@181->main::@37]
    // [575] phi main::rom_chip3#2 = 0 [phi:main::@181->main::@37#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip3
    // main::@37
  __b37:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [576] if(main::rom_chip3#2<8) goto main::@38 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip3
    cmp #8
    bcc __b38
    // [577] phi from main::@37 to main::@39 [phi:main::@37->main::@39]
    // main::@39
    // display_action_text("You have selected not to cancel the update ... ")
    // [578] call display_action_text
    // [1358] phi from main::@39 to display_action_text [phi:main::@39->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main::info_text22 [phi:main::@39->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_text.info_text
    lda #>info_text22
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_bram1
    // main::@38
  __b38:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [579] display_info_rom::rom_chip#10 = main::rom_chip3#2 -- vbum1=vbuz2 
    lda.z rom_chip3
    sta display_info_rom.rom_chip
    // [580] call display_info_rom
    // [1566] phi from main::@38 to display_info_rom [phi:main::@38->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = main::info_text19 [phi:main::@38->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_rom.info_text
    lda #>info_text19
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#10 [phi:main::@38->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@38->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@182
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [581] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip3
    // [575] phi from main::@182 to main::@37 [phi:main::@182->main::@37]
    // [575] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@182->main::@37#0] -- register_copy 
    jmp __b37
    // main::@250
  __b250:
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [582] if(smc_major#399!=smc_file_major#301) goto main::check_status_smc7 -- vbum1_neq_vbum2_then_la1 
    lda smc_major
    cmp smc_file_major
    beq !check_status_smc7+
    jmp check_status_smc7
  !check_status_smc7:
    // main::@249
    // [583] if(smc_minor#398==smc_file_minor#301) goto main::@8 -- vbum1_eq_vbum2_then_la1 
    lda smc_minor
    cmp smc_file_minor
    beq __b8
    jmp check_status_smc7
    // [584] phi from main::@249 to main::@8 [phi:main::@249->main::@8]
    // main::@8
  __b8:
    // display_action_progress("The SMC chip and SMC.BIN versions are equal, no flash required!")
    // [585] call display_action_progress
    // [904] phi from main::@8 to display_action_progress [phi:main::@8->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text15 [phi:main::@8->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_progress.info_text
    lda #>info_text15
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [586] phi from main::@8 to main::@175 [phi:main::@8->main::@175]
    // main::@175
    // util_wait_space()
    // [587] call util_wait_space
    // [1390] phi from main::@175 to util_wait_space [phi:main::@175->util_wait_space]
    jsr util_wait_space
    // main::@176
    // [588] smc_bootloader#509 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "SMC.BIN and SMC equal.")
    // [589] call display_info_smc
    // [962] phi from main::@176 to display_info_smc [phi:main::@176->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text16 [phi:main::@176->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_info_smc.info_text
    lda #>info_text16
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#509 [phi:main::@176->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@176->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_smc7
    // [590] phi from main::@247 to main::@6 [phi:main::@247->main::@6]
    // main::@6
  __b6:
    // display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!")
    // [591] call display_action_progress
    // [904] phi from main::@6 to display_action_progress [phi:main::@6->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text13 [phi:main::@6->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [592] phi from main::@6 to main::@169 [phi:main::@6->main::@169]
    // main::@169
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [593] call display_progress_text
    // [1332] phi from main::@169 to display_progress_text [phi:main::@169->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_smc_unsupported_rom_text [phi:main::@169->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_smc_unsupported_rom_count [phi:main::@169->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [594] phi from main::@169 to main::@170 [phi:main::@169->main::@170]
    // main::@170
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [595] call util_wait_key
    // [2019] phi from main::@170 to util_wait_key [phi:main::@170->util_wait_key]
    // [2019] phi util_wait_key::filter#13 = main::filter [phi:main::@170->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [2019] phi util_wait_key::info_text#3 = main::info_text14 [phi:main::@170->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z util_wait_key.info_text
    lda #>info_text14
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [596] util_wait_key::return#3 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return
    // main::@171
    // [597] main::ch#0 = util_wait_key::return#3 -- vbum1=vbum2 
    sta ch
    // if(ch == 'N')
    // [598] if(main::ch#0!='N') goto main::check_status_smc6 -- vbum1_neq_vbuc1_then_la1 
    lda #'N'
    cmp ch
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@7
    // [599] smc_bootloader#501 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [600] call display_info_smc
  // Cancel flash
    // [962] phi from main::@7 to display_info_smc [phi:main::@7->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = 0 [phi:main::@7->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#501 [phi:main::@7->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@7->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [601] phi from main::@7 to main::@172 [phi:main::@7->main::@172]
    // main::@172
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [602] call display_info_cx16_rom
    // [2052] phi from main::@172 to display_info_cx16_rom [phi:main::@172->display_info_cx16_rom]
    // [2052] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@172->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [2052] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@172->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc6
    // [603] phi from main::@246 to main::@5 [phi:main::@246->main::@5]
    // main::@5
  __b5:
    // display_action_progress("CX16 ROM update issue!")
    // [604] call display_action_progress
    // [904] phi from main::@5 to display_action_progress [phi:main::@5->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text11 [phi:main::@5->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_action_progress.info_text
    lda #>info_text11
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [605] phi from main::@5 to main::@164 [phi:main::@5->main::@164]
    // main::@164
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [606] call display_progress_text
    // [1332] phi from main::@164 to display_progress_text [phi:main::@164->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@164->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@164->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // main::@165
    // [607] smc_bootloader#508 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [608] call display_info_smc
    // [962] phi from main::@165 to display_info_smc [phi:main::@165->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text9 [phi:main::@165->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#508 [phi:main::@165->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@165->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [609] phi from main::@165 to main::@166 [phi:main::@165->main::@166]
    // main::@166
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [610] call display_info_cx16_rom
    // [2052] phi from main::@166 to display_info_cx16_rom [phi:main::@166->display_info_cx16_rom]
    // [2052] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@166->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [2052] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@166->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [611] phi from main::@166 to main::@167 [phi:main::@166->main::@167]
    // main::@167
    // util_wait_space()
    // [612] call util_wait_space
    // [1390] phi from main::@167 to util_wait_space [phi:main::@167->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc5
    // [613] phi from main::@245 to main::@3 [phi:main::@245->main::@3]
    // main::@3
  __b3:
    // display_action_progress("CX16 ROM update issue, ROM not detected!")
    // [614] call display_action_progress
    // [904] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text8 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [615] phi from main::@3 to main::@160 [phi:main::@3->main::@160]
    // main::@160
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [616] call display_progress_text
    // [1332] phi from main::@160 to display_progress_text [phi:main::@160->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@160->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@160->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // main::@161
    // [617] smc_bootloader#507 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [618] call display_info_smc
    // [962] phi from main::@161 to display_info_smc [phi:main::@161->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text9 [phi:main::@161->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#507 [phi:main::@161->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@161->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [619] phi from main::@161 to main::@162 [phi:main::@161->main::@162]
    // main::@162
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [620] call display_info_cx16_rom
    // [2052] phi from main::@162 to display_info_cx16_rom [phi:main::@162->display_info_cx16_rom]
    // [2052] phi display_info_cx16_rom::info_text#4 = main::info_text10 [phi:main::@162->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_cx16_rom.info_text
    lda #>info_text10
    sta.z display_info_cx16_rom.info_text+1
    // [2052] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@162->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [621] phi from main::@162 to main::@163 [phi:main::@162->main::@163]
    // main::@163
    // util_wait_space()
    // [622] call util_wait_space
    // [1390] phi from main::@163 to util_wait_space [phi:main::@163->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc5
    // [623] phi from main::@244 to main::@36 [phi:main::@244->main::@36]
    // main::@36
  __b36:
    // display_action_progress("SMC update issue!")
    // [624] call display_action_progress
    // [904] phi from main::@36 to display_action_progress [phi:main::@36->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main::info_text6 [phi:main::@36->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_action_progress.info_text
    lda #>info_text6
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [625] phi from main::@36 to main::@156 [phi:main::@36->main::@156]
    // main::@156
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [626] call display_progress_text
    // [1332] phi from main::@156 to display_progress_text [phi:main::@156->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@156->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@156->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [627] phi from main::@156 to main::@157 [phi:main::@156->main::@157]
    // main::@157
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [628] call display_info_cx16_rom
    // [2052] phi from main::@157 to display_info_cx16_rom [phi:main::@157->display_info_cx16_rom]
    // [2052] phi display_info_cx16_rom::info_text#4 = main::info_text7 [phi:main::@157->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_info_cx16_rom.info_text
    lda #>info_text7
    sta.z display_info_cx16_rom.info_text+1
    // [2052] phi display_info_cx16_rom::info_status#4 = STATUS_SKIP [phi:main::@157->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // main::@158
    // [629] smc_bootloader#506 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [630] call display_info_smc
    // [962] phi from main::@158 to display_info_smc [phi:main::@158->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = 0 [phi:main::@158->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#506 [phi:main::@158->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@158->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [631] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // util_wait_space()
    // [632] call util_wait_space
    // [1390] phi from main::@159 to util_wait_space [phi:main::@159->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [633] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::@72
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [634] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@30 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b30+
    jmp __b30
  !__b30:
    // [635] phi from main::@72 to main::@33 [phi:main::@72->main::@33]
    // main::@33
    // display_progress_clear()
    // [636] call display_progress_clear
    // [918] phi from main::@33 to display_progress_clear [phi:main::@33->display_progress_clear]
    jsr display_progress_clear
    // main::@134
    // unsigned char rom_bank = rom_chip * 32
    // [637] main::rom_bank#0 = main::rom_chip2#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [638] rom_file::rom_chip#0 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta rom_file.rom_chip
    // [639] call rom_file
    // [1611] phi from main::@134 to rom_file [phi:main::@134->rom_file]
    // [1611] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@134->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [640] rom_file::return#4 = rom_file::return#2
    // main::@135
    // [641] main::file#0 = rom_file::return#4 -- pbum1=pbuz2 
    lda.z rom_file.return
    sta file
    lda.z rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ...", file)
    // [642] call snprintf_init
    // [1205] phi from main::@135 to snprintf_init [phi:main::@135->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@135->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [643] phi from main::@135 to main::@136 [phi:main::@135->main::@136]
    // main::@136
    // sprintf(info_text, "Checking %s ...", file)
    // [644] call printf_str
    // [1210] phi from main::@136 to printf_str [phi:main::@136->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@136->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s5 [phi:main::@136->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@137
    // sprintf(info_text, "Checking %s ...", file)
    // [645] printf_string::str#20 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [646] call printf_string
    // [1219] phi from main::@137 to printf_string [phi:main::@137->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:main::@137->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#20 [phi:main::@137->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:main::@137->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:main::@137->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [647] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(info_text, "Checking %s ...", file)
    // [648] call printf_str
    // [1210] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s6 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(info_text, "Checking %s ...", file)
    // [649] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [650] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [652] call display_action_progress
    // [904] phi from main::@139 to display_action_progress [phi:main::@139->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = info_text [phi:main::@139->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@140
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [653] main::$315 = main::rom_chip2#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip2
    asl
    asl
    sta main__315
    // [654] rom_read::rom_chip#0 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta rom_read.rom_chip
    // [655] rom_read::file#0 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z rom_read.file
    lda file+1
    sta.z rom_read.file+1
    // [656] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbum1=vbum2 
    lda rom_bank
    sta rom_read.brom_bank_start
    // [657] rom_read::rom_size#0 = rom_sizes[main::$315] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__315
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [658] call rom_read
  // Read the ROM(n).BIN file.
    // [1617] phi from main::@140 to rom_read [phi:main::@140->rom_read]
    // [1617] phi rom_read::rom_chip#20 = rom_read::rom_chip#0 [phi:main::@140->rom_read#0] -- register_copy 
    // [1617] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@140->rom_read#1] -- register_copy 
    // [1617] phi __errno#105 = __errno#115 [phi:main::@140->rom_read#2] -- register_copy 
    // [1617] phi __stdio_filecount#100 = __stdio_filecount#111 [phi:main::@140->rom_read#3] -- register_copy 
    // [1617] phi rom_read::file#10 = rom_read::file#0 [phi:main::@140->rom_read#4] -- register_copy 
    // [1617] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#1 [phi:main::@140->rom_read#5] -- register_copy 
    // [1617] phi rom_read::info_status#11 = STATUS_CHECKING [phi:main::@140->rom_read#6] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [659] rom_read::return#2 = rom_read::return#0
    // main::@141
    // [660] main::rom_bytes_read#0 = rom_read::return#2 -- vduz1=vdum2 
    lda rom_read.return
    sta.z rom_bytes_read
    lda rom_read.return+1
    sta.z rom_bytes_read+1
    lda rom_read.return+2
    sta.z rom_bytes_read+2
    lda rom_read.return+3
    sta.z rom_bytes_read+3
    // if (!rom_bytes_read)
    // [661] if(0==main::rom_bytes_read#0) goto main::@31 -- 0_eq_vduz1_then_la1 
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
    // [662] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [663] if(0!=main::rom_file_modulo#0) goto main::@32 -- 0_neq_vduz1_then_la1 
    lda.z rom_file_modulo
    ora.z rom_file_modulo+1
    ora.z rom_file_modulo+2
    ora.z rom_file_modulo+3
    beq !__b32+
    jmp __b32
  !__b32:
    // main::@35
    // file_sizes[rom_chip] = rom_bytes_read
    // [664] file_sizes[main::$315] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vduz2 
    // RF5 | ROM.BIN all ok | Display the ROM.BIN release version and github commit id (if any) and set ROM to Flash | Flash
    // We know the file size, so we indicate it in the status panel.
    ldy main__315
    lda.z rom_bytes_read
    sta file_sizes,y
    lda.z rom_bytes_read+1
    sta file_sizes+1,y
    lda.z rom_bytes_read+2
    sta file_sizes+2,y
    lda.z rom_bytes_read+3
    sta file_sizes+3,y
    // 8*rom_chip
    // [665] main::$140 = main::rom_chip2#10 << 3 -- vbuz1=vbuz2_rol_3 
    lda.z rom_chip2
    asl
    asl
    asl
    sta.z main__140
    // unsigned char* rom_file_github_id = &rom_file_github[8*rom_chip]
    // [666] main::rom_file_github_id#0 = rom_file_github + main::$140 -- pbuz1=pbuc1_plus_vbuz2 
    // Fill the version data ...
    clc
    adc #<rom_file_github
    sta.z rom_file_github_id
    lda #>rom_file_github
    adc #0
    sta.z rom_file_github_id+1
    // unsigned char rom_file_release_id = rom_get_release(rom_file_release[rom_chip])
    // [667] rom_get_release::release#2 = rom_file_release[main::rom_chip2#10] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip2
    lda rom_file_release,y
    sta rom_get_release.release
    // [668] call rom_get_release
    // [2057] phi from main::@35 to rom_get_release [phi:main::@35->rom_get_release]
    // [2057] phi rom_get_release::release#3 = rom_get_release::release#2 [phi:main::@35->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char rom_file_release_id = rom_get_release(rom_file_release[rom_chip])
    // [669] rom_get_release::return#3 = rom_get_release::return#0
    // main::@149
    // [670] main::rom_file_release_id#0 = rom_get_release::return#3 -- vbum1=vbum2 
    lda rom_get_release.return
    sta rom_file_release_id
    // unsigned char rom_file_prefix_id = rom_get_prefix(rom_file_release[rom_chip])
    // [671] rom_get_prefix::release#1 = rom_file_release[main::rom_chip2#10] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip2
    lda rom_file_release,y
    sta rom_get_prefix.release
    // [672] call rom_get_prefix
    // [2064] phi from main::@149 to rom_get_prefix [phi:main::@149->rom_get_prefix]
    // [2064] phi rom_get_prefix::release#2 = rom_get_prefix::release#1 [phi:main::@149->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char rom_file_prefix_id = rom_get_prefix(rom_file_release[rom_chip])
    // [673] rom_get_prefix::return#3 = rom_get_prefix::return#0
    // main::@150
    // [674] main::rom_file_prefix_id#0 = rom_get_prefix::return#3 -- vbuz1=vbum2 
    lda rom_get_prefix.return
    sta.z rom_file_prefix_id
    // rom_get_version_text(rom_file_release_text, rom_file_prefix_id, rom_file_release_id, rom_file_github_id)
    // [675] rom_get_version_text::prefix#1 = main::rom_file_prefix_id#0 -- vbum1=vbuz2 
    sta rom_get_version_text.prefix
    // [676] rom_get_version_text::release#1 = main::rom_file_release_id#0 -- vbum1=vbum2 
    lda rom_file_release_id
    sta rom_get_version_text.release
    // [677] rom_get_version_text::github#1 = main::rom_file_github_id#0
    // [678] call rom_get_version_text
    // [2073] phi from main::@150 to rom_get_version_text [phi:main::@150->rom_get_version_text]
    // [2073] phi rom_get_version_text::github#2 = rom_get_version_text::github#1 [phi:main::@150->rom_get_version_text#0] -- register_copy 
    // [2073] phi rom_get_version_text::release#2 = rom_get_version_text::release#1 [phi:main::@150->rom_get_version_text#1] -- register_copy 
    // [2073] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#1 [phi:main::@150->rom_get_version_text#2] -- register_copy 
    // [2073] phi rom_get_version_text::release_info#2 = main::rom_file_release_text [phi:main::@150->rom_get_version_text#3] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_file_release_text
    sta.z rom_get_version_text.release_info+1
    jsr rom_get_version_text
    // [679] phi from main::@150 to main::@151 [phi:main::@150->main::@151]
    // main::@151
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [680] call snprintf_init
    // [1205] phi from main::@151 to snprintf_init [phi:main::@151->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@151->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@152
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [681] printf_string::str#23 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [682] call printf_string
    // [1219] phi from main::@152 to printf_string [phi:main::@152->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:main::@152->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#23 [phi:main::@152->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:main::@152->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:main::@152->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [683] phi from main::@152 to main::@153 [phi:main::@152->main::@153]
    // main::@153
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [684] call printf_str
    // [1210] phi from main::@153 to printf_str [phi:main::@153->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@153->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s2 [phi:main::@153->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // [685] phi from main::@153 to main::@154 [phi:main::@153->main::@154]
    // main::@154
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [686] call printf_string
    // [1219] phi from main::@154 to printf_string [phi:main::@154->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:main::@154->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = main::rom_file_release_text [phi:main::@154->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z printf_string.str
    lda #>rom_file_release_text
    sta.z printf_string.str+1
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:main::@154->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:main::@154->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@155
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [687] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [688] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [690] display_info_rom::rom_chip#9 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [691] call display_info_rom
    // [1566] phi from main::@155 to display_info_rom [phi:main::@155->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = info_text [phi:main::@155->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#9 [phi:main::@155->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@155->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // [692] phi from main::@144 main::@148 main::@155 main::@72 to main::@30 [phi:main::@144/main::@148/main::@155/main::@72->main::@30]
    // [692] phi __stdio_filecount#404 = __stdio_filecount#12 [phi:main::@144/main::@148/main::@155/main::@72->main::@30#0] -- register_copy 
    // [692] phi __errno#389 = __errno#123 [phi:main::@144/main::@148/main::@155/main::@72->main::@30#1] -- register_copy 
    // main::@30
  __b30:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [693] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip2
    // [180] phi from main::@30 to main::@29 [phi:main::@30->main::@29]
    // [180] phi __stdio_filecount#111 = __stdio_filecount#404 [phi:main::@30->main::@29#0] -- register_copy 
    // [180] phi __errno#115 = __errno#389 [phi:main::@30->main::@29#1] -- register_copy 
    // [180] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@30->main::@29#2] -- register_copy 
    jmp __b29
    // [694] phi from main::@34 to main::@32 [phi:main::@34->main::@32]
    // main::@32
  __b32:
    // sprintf(info_text, "File %s size error!", file)
    // [695] call snprintf_init
    // [1205] phi from main::@32 to snprintf_init [phi:main::@32->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@32->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [696] phi from main::@32 to main::@145 [phi:main::@32->main::@145]
    // main::@145
    // sprintf(info_text, "File %s size error!", file)
    // [697] call printf_str
    // [1210] phi from main::@145 to printf_str [phi:main::@145->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@145->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s8 [phi:main::@145->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@146
    // sprintf(info_text, "File %s size error!", file)
    // [698] printf_string::str#22 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [699] call printf_string
    // [1219] phi from main::@146 to printf_string [phi:main::@146->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:main::@146->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#22 [phi:main::@146->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:main::@146->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:main::@146->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [700] phi from main::@146 to main::@147 [phi:main::@146->main::@147]
    // main::@147
    // sprintf(info_text, "File %s size error!", file)
    // [701] call printf_str
    // [1210] phi from main::@147 to printf_str [phi:main::@147->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@147->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s9 [phi:main::@147->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@148
    // sprintf(info_text, "File %s size error!", file)
    // [702] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [703] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ISSUE, info_text)
    // [705] display_info_rom::rom_chip#8 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [706] call display_info_rom
    // [1566] phi from main::@148 to display_info_rom [phi:main::@148->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = info_text [phi:main::@148->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#8 [phi:main::@148->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:main::@148->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b30
    // [707] phi from main::@141 to main::@31 [phi:main::@141->main::@31]
    // main::@31
  __b31:
    // sprintf(info_text, "No %s", file)
    // [708] call snprintf_init
    // [1205] phi from main::@31 to snprintf_init [phi:main::@31->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@31->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [709] phi from main::@31 to main::@142 [phi:main::@31->main::@142]
    // main::@142
    // sprintf(info_text, "No %s", file)
    // [710] call printf_str
    // [1210] phi from main::@142 to printf_str [phi:main::@142->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@142->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s7 [phi:main::@142->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@143
    // sprintf(info_text, "No %s", file)
    // [711] printf_string::str#21 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [712] call printf_string
    // [1219] phi from main::@143 to printf_string [phi:main::@143->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:main::@143->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#21 [phi:main::@143->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:main::@143->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:main::@143->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@144
    // sprintf(info_text, "No %s", file)
    // [713] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [714] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_SKIP, info_text)
    // [716] display_info_rom::rom_chip#7 = main::rom_chip2#10 -- vbum1=vbuz2 
    lda.z rom_chip2
    sta display_info_rom.rom_chip
    // [717] call display_info_rom
    // [1566] phi from main::@144 to display_info_rom [phi:main::@144->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = info_text [phi:main::@144->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#7 [phi:main::@144->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@144->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b30
    // main::@28
  __b28:
    // [718] smc_bootloader#513 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [719] call display_info_smc
  // SF3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
    // [962] phi from main::@28 to display_info_smc [phi:main::@28->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text5 [phi:main::@28->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_smc.info_text
    lda #>info_text5
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#513 [phi:main::@28->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@28->display_info_smc#2] -- vbum1=vbuc1 
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
    // [720] smc_bootloader#512 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "No SMC.BIN!")
    // [721] call display_info_smc
  // SF1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
  // SF2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
    // [962] phi from main::@27 to display_info_smc [phi:main::@27->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text4 [phi:main::@27->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#512 [phi:main::@27->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_SKIP [phi:main::@27->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b11
    // main::@21
  __b21:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [722] if(rom_device_ids[main::rom_chip1#10]!=$55) goto main::@22 -- pbuc1_derefidx_vbuz1_neq_vbuc2_then_la1 
    lda #$55
    ldy.z rom_chip1
    cmp rom_device_ids,y
    bne __b22
    // main::@23
  __b23:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [723] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip1
    // [136] phi from main::@23 to main::@20 [phi:main::@23->main::@20]
    // [136] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@23->main::@20#0] -- register_copy 
    jmp __b20
    // main::@22
  __b22:
    // bank_set_brom(rom_chip*32)
    // [724] main::bank_set_brom2_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbuz2_rol_5 
    lda.z rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta bank_set_brom2_bank
    // main::bank_set_brom2
    // BROM = bank
    // [725] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbum2 
    sta.z BROM
    // main::@70
    // rom_chip*8
    // [726] main::$115 = main::rom_chip1#10 << 3 -- vbum1=vbuz2_rol_3 
    lda.z rom_chip1
    asl
    asl
    asl
    sta main__115
    // rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000)
    // [727] rom_get_github_commit_id::commit_id#1 = rom_github + main::$115 -- pbuz1=pbuc1_plus_vbum2 
    clc
    adc #<rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [728] call rom_get_github_commit_id
    // [2089] phi from main::@70 to rom_get_github_commit_id [phi:main::@70->rom_get_github_commit_id]
    // [2089] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#1 [phi:main::@70->rom_get_github_commit_id#0] -- register_copy 
    // [2089] phi rom_get_github_commit_id::from#6 = (char *) 49152 [phi:main::@70->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z rom_get_github_commit_id.from
    lda #>$c000
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::@123
    // rom_get_release(*((char*)0xFF80))
    // [729] rom_get_release::release#1 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_release.release
    // [730] call rom_get_release
    // [2057] phi from main::@123 to rom_get_release [phi:main::@123->rom_get_release]
    // [2057] phi rom_get_release::release#3 = rom_get_release::release#1 [phi:main::@123->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)0xFF80))
    // [731] rom_get_release::return#2 = rom_get_release::return#0
    // main::@124
    // [732] main::$111 = rom_get_release::return#2 -- vbuz1=vbum2 
    lda rom_get_release.return
    sta.z main__111
    // rom_release[rom_chip] = rom_get_release(*((char*)0xFF80))
    // [733] rom_release[main::rom_chip1#10] = main::$111 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z rom_chip1
    sta rom_release,y
    // rom_get_prefix(*((char*)0xFF80))
    // [734] rom_get_prefix::release#0 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_prefix.release
    // [735] call rom_get_prefix
    // [2064] phi from main::@124 to rom_get_prefix [phi:main::@124->rom_get_prefix]
    // [2064] phi rom_get_prefix::release#2 = rom_get_prefix::release#0 [phi:main::@124->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)0xFF80))
    // [736] rom_get_prefix::return#2 = rom_get_prefix::return#0
    // main::@125
    // [737] main::$112 = rom_get_prefix::return#2 -- vbuz1=vbum2 
    lda rom_get_prefix.return
    sta.z main__112
    // rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80))
    // [738] rom_prefix[main::rom_chip1#10] = main::$112 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z rom_chip1
    sta rom_prefix,y
    // rom_chip*13
    // [739] main::$375 = main::rom_chip1#10 << 1 -- vbuz1=vbuz2_rol_1 
    tya
    asl
    sta.z main__375
    // [740] main::$376 = main::$375 + main::rom_chip1#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__376
    clc
    adc.z rom_chip1
    sta.z main__376
    // [741] main::$377 = main::$376 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__377
    asl
    asl
    sta.z main__377
    // [742] main::$113 = main::$377 + main::rom_chip1#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__113
    clc
    adc.z rom_chip1
    sta.z main__113
    // rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8])
    // [743] rom_get_version_text::release_info#0 = rom_release_text + main::$113 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_release_text
    adc #0
    sta.z rom_get_version_text.release_info+1
    // [744] rom_get_version_text::github#0 = rom_github + main::$115 -- pbuz1=pbuc1_plus_vbum2 
    lda main__115
    clc
    adc #<rom_github
    sta.z rom_get_version_text.github
    lda #>rom_github
    adc #0
    sta.z rom_get_version_text.github+1
    // [745] rom_get_version_text::prefix#0 = rom_prefix[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbuz2 
    lda rom_prefix,y
    sta rom_get_version_text.prefix
    // [746] rom_get_version_text::release#0 = rom_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbuz2 
    lda rom_release,y
    sta rom_get_version_text.release
    // [747] call rom_get_version_text
    // [2073] phi from main::@125 to rom_get_version_text [phi:main::@125->rom_get_version_text]
    // [2073] phi rom_get_version_text::github#2 = rom_get_version_text::github#0 [phi:main::@125->rom_get_version_text#0] -- register_copy 
    // [2073] phi rom_get_version_text::release#2 = rom_get_version_text::release#0 [phi:main::@125->rom_get_version_text#1] -- register_copy 
    // [2073] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#0 [phi:main::@125->rom_get_version_text#2] -- register_copy 
    // [2073] phi rom_get_version_text::release_info#2 = rom_get_version_text::release_info#0 [phi:main::@125->rom_get_version_text#3] -- register_copy 
    jsr rom_get_version_text
    // main::@126
    // display_info_rom(rom_chip, STATUS_DETECTED, NULL)
    // [748] display_info_rom::rom_chip#6 = main::rom_chip1#10 -- vbum1=vbuz2 
    lda.z rom_chip1
    sta display_info_rom.rom_chip
    // [749] call display_info_rom
    // [1566] phi from main::@126 to display_info_rom [phi:main::@126->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = 0 [phi:main::@126->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#6 [phi:main::@126->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_DETECTED [phi:main::@126->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b23
    // [750] phi from main::@16 to main::@19 [phi:main::@16->main::@19]
    // main::@19
  __b19:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [751] call snprintf_init
    // [1205] phi from main::@19 to snprintf_init [phi:main::@19->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [752] phi from main::@19 to main::@113 [phi:main::@19->main::@113]
    // main::@113
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [753] call printf_str
    // [1210] phi from main::@113 to printf_str [phi:main::@113->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@113->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s2 [phi:main::@113->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@114
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [754] printf_uint::uvalue#7 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [755] call printf_uint
    // [2106] phi from main::@114 to printf_uint [phi:main::@114->printf_uint]
    // [2106] phi printf_uint::format_zero_padding#10 = 1 [phi:main::@114->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2106] phi printf_uint::format_min_length#10 = 2 [phi:main::@114->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [2106] phi printf_uint::putc#10 = &snputc [phi:main::@114->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2106] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:main::@114->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2106] phi printf_uint::uvalue#10 = printf_uint::uvalue#7 [phi:main::@114->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [756] phi from main::@114 to main::@115 [phi:main::@114->main::@115]
    // main::@115
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [757] call printf_str
    // [1210] phi from main::@115 to printf_str [phi:main::@115->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main::@115->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main::s3 [phi:main::@115->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@116
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [758] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [759] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [761] smc_bootloader#502 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, info_text)
    // [762] call display_info_smc
    // [962] phi from main::@116 to display_info_smc [phi:main::@116->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = info_text [phi:main::@116->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#502 [phi:main::@116->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@116->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [763] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [764] call display_progress_text
  // Bootloader is not supported by this utility, but is not error.
    // [1332] phi from main::@117 to display_progress_text [phi:main::@117->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_no_valid_smc_bootloader_text [phi:main::@117->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_no_valid_smc_bootloader_count [phi:main::@117->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [129] phi from main::@112 main::@117 main::@18 to main::@2 [phi:main::@112/main::@117/main::@18->main::@2]
  __b14:
    // [129] phi smc_minor#398 = 0 [phi:main::@112/main::@117/main::@18->main::@2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_minor
    // [129] phi smc_major#399 = 0 [phi:main::@112/main::@117/main::@18->main::@2#1] -- vbum1=vbuc1 
    sta smc_major
    // [129] phi smc_release#400 = 0 [phi:main::@112/main::@117/main::@18->main::@2#2] -- vbum1=vbuc1 
    sta smc_release
    jmp __b2
    // main::@18
  __b18:
    // [765] smc_bootloader#511 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC Unreachable!")
    // [766] call display_info_smc
  // SD2 | SMC chip not detected | Display that the SMC chip is not detected and set SMC to Error. | Error
    // [962] phi from main::@18 to display_info_smc [phi:main::@18->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text2 [phi:main::@18->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_smc.info_text
    lda #>info_text2
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#511 [phi:main::@18->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main::@18->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b14
    // main::@1
  __b1:
    // [767] smc_bootloader#500 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "No Bootloader!")
    // [768] call display_info_smc
  // SD1 | No Bootloader | Display that there is no bootloader and set SMC to Issue. | Issue
    // [962] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = main::info_text1 [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#500 [phi:main::@1->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ISSUE [phi:main::@1->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [769] phi from main::@1 to main::@112 [phi:main::@1->main::@112]
    // main::@112
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [770] call display_progress_text
  // If the CX16 board does not have a bootloader, display info how to flash bootloader.
    // [1332] phi from main::@112 to display_progress_text [phi:main::@112->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_no_valid_smc_bootloader_text [phi:main::@112->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_no_valid_smc_bootloader_count [phi:main::@112->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta display_progress_text.lines
    jsr display_progress_text
    jmp __b14
    // main::@13
  __b13:
    // rom_chip*13
    // [771] main::$371 = main::rom_chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z main__371
    // [772] main::$372 = main::$371 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__372
    clc
    adc.z rom_chip
    sta.z main__372
    // [773] main::$373 = main::$372 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__373
    asl
    asl
    sta.z main__373
    // [774] main::$87 = main::$373 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__87
    clc
    adc.z rom_chip
    sta.z main__87
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [775] strcpy::destination#1 = rom_release_text + main::$87 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [776] call strcpy
    // [1066] phi from main::@13 to strcpy [phi:main::@13->strcpy]
    // [1066] phi strcpy::dst#0 = strcpy::destination#1 [phi:main::@13->strcpy#0] -- register_copy 
    // [1066] phi strcpy::src#0 = main::source [phi:main::@13->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@106
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [777] display_info_rom::rom_chip#5 = main::rom_chip#2 -- vbum1=vbuz2 
    lda.z rom_chip
    sta display_info_rom.rom_chip
    // [778] call display_info_rom
    // [1566] phi from main::@106 to display_info_rom [phi:main::@106->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = 0 [phi:main::@106->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#5 [phi:main::@106->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@106->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@107
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [779] main::rom_chip#1 = ++ main::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [94] phi from main::@107 to main::@12 [phi:main::@107->main::@12]
    // [94] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@107->main::@12#0] -- register_copy 
    jmp __b12
  .segment Data
    smc_file_version_text: .fill $d, 0
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
    main__344: .text "nN"
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
    main__186: .byte 0
    main__274: .byte 0
    main__279: .byte 0
    main__315: .byte 0
    main__317: .byte 0
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
    rom_file_release_id: .byte 0
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
    rom_differences: .dword 0
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
    // [780] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [781] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [782] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [783] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $5c
    .label textcolor__1 = $5c
    // __conio.color & 0xF0
    // [785] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [786] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [787] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [788] return 
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
    .label bgcolor__0 = $5c
    .label bgcolor__1 = $5d
    .label bgcolor__2 = $5c
    // __conio.color & 0x0F
    // [790] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [791] bgcolor::$1 = bgcolor::color#15 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [792] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [793] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [794] return 
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
    // [795] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [796] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [797] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [798] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [800] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [801] return 
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
    // [803] if(gotoxy::x#37>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [805] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [805] phi gotoxy::$3 = gotoxy::x#37 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [804] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [805] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [805] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [806] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [807] if(gotoxy::y#37>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [808] gotoxy::$14 = gotoxy::y#37 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [809] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [809] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [810] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [811] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [812] gotoxy::$10 = gotoxy::y#37 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [813] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [814] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [815] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [816] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    .label cputln__2 = $49
    // __conio.cursor_x = 0
    // [817] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [818] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [819] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [820] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [821] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [822] return 
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
    .label cx16_k_screen_set_charset1_offset = $f3
    // cx16_k_screen_set_mode(0)
    // [823] cx16_k_screen_set_mode::mode = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_screen_set_mode.mode
    // [824] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [825] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // screenlayer1()
    // [826] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // display_frame_init_64::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [827] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [828] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // [830] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [831] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [832] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [833] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [834] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [835] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [836] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [837] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [838] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [839] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [840] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [841] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [842] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [843] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [844] phi from display_frame_init_64::vera_layer1_show1 to display_frame_init_64::@1 [phi:display_frame_init_64::vera_layer1_show1->display_frame_init_64::@1]
    // display_frame_init_64::@1
    // textcolor(WHITE)
    // [845] call textcolor
  // Layer 1 is the current text canvas.
    // [784] phi from display_frame_init_64::@1 to textcolor [phi:display_frame_init_64::@1->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:display_frame_init_64::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [846] phi from display_frame_init_64::@1 to display_frame_init_64::@4 [phi:display_frame_init_64::@1->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // bgcolor(BLUE)
    // [847] call bgcolor
  // Default text color is white.
    // [789] phi from display_frame_init_64::@4 to bgcolor [phi:display_frame_init_64::@4->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_frame_init_64::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [848] phi from display_frame_init_64::@4 to display_frame_init_64::@5 [phi:display_frame_init_64::@4->display_frame_init_64::@5]
    // display_frame_init_64::@5
    // clrscr()
    // [849] call clrscr
    // With a blue background.
    // cx16-conio.c won't compile scrolling code for this program with the underlying define, resulting in less code overhead!
    jsr clrscr
    // display_frame_init_64::@return
    // }
    // [850] return 
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
    // [852] call textcolor
    // [784] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [784] phi textcolor::color#23 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [853] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [854] call bgcolor
    // [789] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [855] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [856] call clrscr
    jsr clrscr
    // [857] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [858] call display_frame
    // [2166] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [2166] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [859] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [860] call display_frame
    // [2166] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [2166] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [861] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [862] call display_frame
    // [2166] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [863] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [864] call display_frame
  // Chipset areas
    // [2166] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x1
    jsr display_frame
    // [865] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [866] call display_frame
    // [2166] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x1
    jsr display_frame
    // [867] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [868] call display_frame
    // [2166] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x1
    jsr display_frame
    // [869] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [870] call display_frame
    // [2166] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x1
    jsr display_frame
    // [871] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [872] call display_frame
    // [2166] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x1
    jsr display_frame
    // [873] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [874] call display_frame
    // [2166] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x1
    jsr display_frame
    // [875] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [876] call display_frame
    // [2166] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x1
    jsr display_frame
    // [877] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [878] call display_frame
    // [2166] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x1
    jsr display_frame
    // [879] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [880] call display_frame
    // [2166] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x1
    jsr display_frame
    // [881] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [882] call display_frame
    // [2166] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [2166] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [883] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [884] call display_frame
  // Progress area
    // [2166] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [2166] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [885] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [886] call display_frame
    // [2166] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [2166] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [887] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [888] call display_frame
    // [2166] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [2166] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [2166] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [2166] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2166] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [889] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [890] call textcolor
    // [784] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [891] return 
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
    // [893] call gotoxy
    // [802] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [802] phi gotoxy::y#37 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [894] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [895] call printf_string
    // [1219] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [896] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($6e) const char *s)
cputsxy: {
    .label s = $6e
    // gotoxy(x, y)
    // [898] gotoxy::x#1 = cputsxy::x#4 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [899] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [900] call gotoxy
    // [802] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [901] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [902] call cputs
    // [2300] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [903] return 
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
    // [905] call wherex
    jsr wherex
    // [906] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [907] display_action_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [908] call wherey
    jsr wherey
    // [909] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [910] display_action_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [911] call gotoxy
    // [802] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [802] phi gotoxy::y#37 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [912] printf_string::str#1 = display_action_progress::info_text#27
    // [913] call printf_string
    // [1219] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [914] gotoxy::x#14 = display_action_progress::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [915] gotoxy::y#14 = display_action_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [916] call gotoxy
    // [802] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#14 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#14 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [917] return 
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
    // [919] call textcolor
    // [784] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [920] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [921] call bgcolor
    // [789] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [922] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [922] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [923] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [924] return 
    rts
    // [925] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [925] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x
    // [925] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [926] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [927] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [922] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [922] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [928] cputcxy::x#14 = display_progress_clear::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [929] cputcxy::y#14 = display_progress_clear::y#2 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [930] call cputcxy
    // [2313] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [2313] phi cputcxy::c#17 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [2313] phi cputcxy::y#17 = cputcxy::y#14 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#14 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [931] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbum1=_inc_vbum1 
    inc x
    // for(unsigned char i = 0; i < w; i++)
    // [932] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [925] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [925] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [925] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
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
    // [934] call display_smc_led
    // [2321] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [2321] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_smc_led.c
    jsr display_smc_led
    // [935] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [936] call display_print_chip
    // [2327] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [2327] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2327] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta display_print_chip.w
    // [2327] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #1
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [937] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [939] call display_vera_led
    // [2371] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [2371] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_vera_led.c
    jsr display_vera_led
    // [940] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [941] call display_print_chip
    // [2327] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [2327] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2327] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta display_print_chip.w
    // [2327] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #9
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [942] return 
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
    .label display_chip_rom__6 = $2b
    .label display_chip_rom__11 = $2b
    .label display_chip_rom__12 = $2b
    // [944] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [944] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [945] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [946] return 
    rts
    // [947] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [948] call strcpy
    // [1066] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [1066] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [1066] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [949] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbum2_rol_1 
    lda r
    asl
    sta.z display_chip_rom__11
    // [950] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [951] call strcat
    // [2377] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [952] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [953] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [954] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [955] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbum1=vbum2 
    lda r
    sta display_rom_led.chip
    // [956] call display_rom_led
    // [2389] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [2389] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_rom_led.c
    // [2389] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [957] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbum2 
    lda r
    clc
    adc.z display_chip_rom__12
    sta.z display_chip_rom__12
    // [958] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [959] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbum1=vbuc1_plus_vbuz2 
    lda #$14
    clc
    adc.z display_chip_rom__6
    sta display_print_chip.x
    // [960] call display_print_chip
    // [2327] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [2327] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [2327] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta display_print_chip.w
    // [2327] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [961] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [944] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [944] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
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
// void display_info_smc(__mem() char info_status, __zp($45) char *info_text)
display_info_smc: {
    .label display_info_smc__9 = $2b
    .label info_text = $45
    // unsigned char x = wherex()
    // [963] call wherex
    jsr wherex
    // [964] wherex::return#10 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_2
    // display_info_smc::@3
    // [965] display_info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [966] call wherey
    jsr wherey
    // [967] wherey::return#10 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_2
    // display_info_smc::@4
    // [968] display_info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [969] status_smc#0 = display_info_smc::info_status#20 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [970] display_smc_led::c#1 = status_color[display_info_smc::info_status#20] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_smc_led.c
    // [971] call display_smc_led
    // [2321] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [2321] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [972] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [973] call gotoxy
    // [802] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [802] phi gotoxy::y#37 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [974] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [975] call printf_str
    // [1210] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [976] display_info_smc::$9 = display_info_smc::info_status#20 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_smc__9
    // [977] printf_string::str#3 = status_text[display_info_smc::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [978] call printf_string
    // [1219] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [979] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [980] call printf_str
    // [1210] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [981] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [982] call printf_string
    // [1219] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = smc_version_text [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 8 [phi:display_info_smc::@9->printf_string#3] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [983] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [984] call printf_str
    // [1210] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [985] printf_uint::uvalue#1 = smc_bootloader#14 -- vwum1=vwum2 
    lda smc_bootloader_1
    sta printf_uint.uvalue
    lda smc_bootloader_1+1
    sta printf_uint.uvalue+1
    // [986] call printf_uint
    // [2106] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    // [2106] phi printf_uint::format_zero_padding#10 = 0 [phi:display_info_smc::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2106] phi printf_uint::format_min_length#10 = 0 [phi:display_info_smc::@11->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2106] phi printf_uint::putc#10 = &cputc [phi:display_info_smc::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [2106] phi printf_uint::format_radix#10 = DECIMAL [phi:display_info_smc::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [2106] phi printf_uint::uvalue#10 = printf_uint::uvalue#1 [phi:display_info_smc::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [987] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [988] call printf_str
    // [1210] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [989] if((char *)0==display_info_smc::info_text#20) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [990] phi from display_info_smc::@13 to display_info_smc::@2 [phi:display_info_smc::@13->display_info_smc::@2]
    // display_info_smc::@2
    // gotoxy(INFO_X+64-28, INFO_Y)
    // [991] call gotoxy
    // [802] phi from display_info_smc::@2 to gotoxy [phi:display_info_smc::@2->gotoxy]
    // [802] phi gotoxy::y#37 = $11 [phi:display_info_smc::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_smc::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_smc::@14
    // printf("%-25s", info_text)
    // [992] printf_string::str#5 = display_info_smc::info_text#20 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [993] call printf_string
    // [1219] phi from display_info_smc::@14 to printf_string [phi:display_info_smc::@14->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@14->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#5 [phi:display_info_smc::@14->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@14->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = $19 [phi:display_info_smc::@14->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [994] gotoxy::x#18 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [995] gotoxy::y#18 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [996] call gotoxy
    // [802] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#18 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#18 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [997] return 
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
// void display_info_vera(__mem() char info_status, __zp($5e) char *info_text)
display_info_vera: {
    .label display_info_vera__9 = $42
    .label info_text = $5e
    // unsigned char x = wherex()
    // [999] call wherex
    jsr wherex
    // [1000] wherex::return#11 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_3
    // display_info_vera::@3
    // [1001] display_info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [1002] call wherey
    jsr wherey
    // [1003] wherey::return#11 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_3
    // display_info_vera::@4
    // [1004] display_info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [1005] status_vera#127 = display_info_vera::info_status#19 -- vbum1=vbum2 
    lda info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [1006] display_vera_led::c#1 = status_color[display_info_vera::info_status#19] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_vera_led.c
    // [1007] call display_vera_led
    // [2371] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [2371] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [1008] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [1009] call gotoxy
    // [802] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [802] phi gotoxy::y#37 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [1010] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1011] call printf_str
    // [1210] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1012] display_info_vera::$9 = display_info_vera::info_status#19 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_vera__9
    // [1013] printf_string::str#6 = status_text[display_info_vera::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1014] call printf_string
    // [1219] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1015] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1016] call printf_str
    // [1210] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1017] printf_uchar::uvalue#1 = spi_manufacturer#108 -- vbum1=vbum2 
    lda spi_manufacturer
    sta printf_uchar.uvalue
    // [1018] call printf_uchar
    // [1347] phi from display_info_vera::@9 to printf_uchar [phi:display_info_vera::@9->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_info_vera::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:display_info_vera::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &cputc [phi:display_info_vera::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_info_vera::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#1 [phi:display_info_vera::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1019] phi from display_info_vera::@9 to display_info_vera::@10 [phi:display_info_vera::@9->display_info_vera::@10]
    // display_info_vera::@10
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1020] call printf_str
    // [1210] phi from display_info_vera::@10 to printf_str [phi:display_info_vera::@10->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:display_info_vera::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s4
    sta.z printf_str.s
    lda #>@s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@11
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1021] printf_uchar::uvalue#2 = spi_memory_type#107 -- vbum1=vbum2 
    lda spi_memory_type
    sta printf_uchar.uvalue
    // [1022] call printf_uchar
    // [1347] phi from display_info_vera::@11 to printf_uchar [phi:display_info_vera::@11->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_info_vera::@11->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:display_info_vera::@11->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &cputc [phi:display_info_vera::@11->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_info_vera::@11->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#2 [phi:display_info_vera::@11->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1023] phi from display_info_vera::@11 to display_info_vera::@12 [phi:display_info_vera::@11->display_info_vera::@12]
    // display_info_vera::@12
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1024] call printf_str
    // [1210] phi from display_info_vera::@12 to printf_str [phi:display_info_vera::@12->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:display_info_vera::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s4
    sta.z printf_str.s
    lda #>@s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@13
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1025] printf_uchar::uvalue#3 = spi_memory_capacity#106 -- vbum1=vbum2 
    lda spi_memory_capacity
    sta printf_uchar.uvalue
    // [1026] call printf_uchar
    // [1347] phi from display_info_vera::@13 to printf_uchar [phi:display_info_vera::@13->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_info_vera::@13->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:display_info_vera::@13->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &cputc [phi:display_info_vera::@13->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_info_vera::@13->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#3 [phi:display_info_vera::@13->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1027] phi from display_info_vera::@13 to display_info_vera::@14 [phi:display_info_vera::@13->display_info_vera::@14]
    // display_info_vera::@14
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1028] call printf_str
    // [1210] phi from display_info_vera::@14 to printf_str [phi:display_info_vera::@14->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_vera::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_info_vera::s4 [phi:display_info_vera::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@15
    // if(info_text)
    // [1029] if((char *)0==display_info_vera::info_text#19) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [1030] phi from display_info_vera::@15 to display_info_vera::@2 [phi:display_info_vera::@15->display_info_vera::@2]
    // display_info_vera::@2
    // gotoxy(INFO_X+64-28, INFO_Y+1)
    // [1031] call gotoxy
    // [802] phi from display_info_vera::@2 to gotoxy [phi:display_info_vera::@2->gotoxy]
    // [802] phi gotoxy::y#37 = $11+1 [phi:display_info_vera::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_vera::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_vera::@16
    // printf("%-25s", info_text)
    // [1032] printf_string::str#7 = display_info_vera::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1033] call printf_string
    // [1219] phi from display_info_vera::@16 to printf_string [phi:display_info_vera::@16->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_vera::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#7 [phi:display_info_vera::@16->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_vera::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = $19 [phi:display_info_vera::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [1034] gotoxy::x#21 = display_info_vera::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1035] gotoxy::y#21 = display_info_vera::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1036] call gotoxy
    // [802] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#21 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#21 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [1037] return 
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
    // [1039] call display_progress_text
    // [1332] phi from main_intro to display_progress_text [phi:main_intro->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_into_briefing_text [phi:main_intro->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_intro_briefing_count [phi:main_intro->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_briefing_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [1040] phi from main_intro to main_intro::@4 [phi:main_intro->main_intro::@4]
    // main_intro::@4
    // util_wait_space()
    // [1041] call util_wait_space
    // [1390] phi from main_intro::@4 to util_wait_space [phi:main_intro::@4->util_wait_space]
    jsr util_wait_space
    // [1042] phi from main_intro::@4 to main_intro::@5 [phi:main_intro::@4->main_intro::@5]
    // main_intro::@5
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [1043] call display_progress_text
    // [1332] phi from main_intro::@5 to display_progress_text [phi:main_intro::@5->display_progress_text]
    // [1332] phi display_progress_text::text#13 = display_into_colors_text [phi:main_intro::@5->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [1332] phi display_progress_text::lines#12 = display_intro_colors_count [phi:main_intro::@5->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_colors_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [1044] phi from main_intro::@5 to main_intro::@1 [phi:main_intro::@5->main_intro::@1]
    // [1044] phi main_intro::intro_status#2 = 0 [phi:main_intro::@5->main_intro::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_status
    // main_intro::@1
  __b1:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [1045] if(main_intro::intro_status#2<$b) goto main_intro::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_status
    cmp #$b
    bcc __b2
    // [1046] phi from main_intro::@1 to main_intro::@3 [phi:main_intro::@1->main_intro::@3]
    // main_intro::@3
    // util_wait_space()
    // [1047] call util_wait_space
    // [1390] phi from main_intro::@3 to util_wait_space [phi:main_intro::@3->util_wait_space]
    jsr util_wait_space
    // [1048] phi from main_intro::@3 to main_intro::@7 [phi:main_intro::@3->main_intro::@7]
    // main_intro::@7
    // display_progress_clear()
    // [1049] call display_progress_clear
    // [918] phi from main_intro::@7 to display_progress_clear [phi:main_intro::@7->display_progress_clear]
    jsr display_progress_clear
    // main_intro::@return
    // }
    // [1050] return 
    rts
    // main_intro::@2
  __b2:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [1051] display_info_led::y#3 = PROGRESS_Y+3 + main_intro::intro_status#2 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y+3
    clc
    adc.z intro_status
    sta display_info_led.y
    // [1052] display_info_led::tc#3 = status_color[main_intro::intro_status#2] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z intro_status
    lda status_color,y
    sta display_info_led.tc
    // [1053] call display_info_led
    // [2400] phi from main_intro::@2 to display_info_led [phi:main_intro::@2->display_info_led]
    // [2400] phi display_info_led::y#4 = display_info_led::y#3 [phi:main_intro::@2->display_info_led#0] -- register_copy 
    // [2400] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main_intro::@2->display_info_led#1] -- vbum1=vbuc1 
    lda #PROGRESS_X+3
    sta display_info_led.x
    // [2400] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main_intro::@2->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main_intro::@6
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [1054] main_intro::intro_status#1 = ++ main_intro::intro_status#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_status
    // [1044] phi from main_intro::@6 to main_intro::@1 [phi:main_intro::@6->main_intro::@1]
    // [1044] phi main_intro::intro_status#2 = main_intro::intro_status#1 [phi:main_intro::@6->main_intro::@1#0] -- register_copy 
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
    .label smc_detect__1 = $2b
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1055] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1056] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1057] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1058] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1059] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [1060] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwum2 
    lda smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [1061] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [1064] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [1064] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwum1=vwuc1 
    lda #<$200
    sta return
    lda #>$200
    sta return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [1062] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwum1_neq_vbuc1_then_la1 
    lda smc_bootloader_version+1
    bne __b2
    lda smc_bootloader_version
    cmp #$ff
    bne __b2
    // [1064] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [1064] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwum1=vwuc1 
    lda #<$100
    sta return
    lda #>$100
    sta return+1
    rts
    // [1063] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [1064] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [1064] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [1065] return 
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
    .label src = $6e
    .label dst = $50
    .label destination = $50
    // [1067] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [1067] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1067] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [1068] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1069] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1070] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1071] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1072] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1073] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
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
    // [1074] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1076] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1077] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1078] return 
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
// unsigned long smc_get_version_text(__zp($45) char *version_string, __mem() char release, __mem() char major, __mem() char minor)
smc_get_version_text: {
    .label version_string = $45
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1080] snprintf_init::s#4 = smc_get_version_text::version_string#2
    // [1081] call snprintf_init
    // [1205] phi from smc_get_version_text to snprintf_init [phi:smc_get_version_text->snprintf_init]
    // [1205] phi snprintf_init::s#31 = snprintf_init::s#4 [phi:smc_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // smc_get_version_text::@1
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1082] printf_uchar::uvalue#7 = smc_get_version_text::release#2
    // [1083] call printf_uchar
    // [1347] phi from smc_get_version_text::@1 to printf_uchar [phi:smc_get_version_text::@1->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:smc_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:smc_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_get_version_text::@1->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#7 [phi:smc_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1084] phi from smc_get_version_text::@1 to smc_get_version_text::@2 [phi:smc_get_version_text::@1->smc_get_version_text::@2]
    // smc_get_version_text::@2
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1085] call printf_str
    // [1210] phi from smc_get_version_text::@2 to printf_str [phi:smc_get_version_text::@2->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = smc_get_version_text::s [phi:smc_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@3
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1086] printf_uchar::uvalue#8 = smc_get_version_text::major#2 -- vbum1=vbum2 
    lda major
    sta printf_uchar.uvalue
    // [1087] call printf_uchar
    // [1347] phi from smc_get_version_text::@3 to printf_uchar [phi:smc_get_version_text::@3->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_get_version_text::@3->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:smc_get_version_text::@3->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:smc_get_version_text::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_get_version_text::@3->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#8 [phi:smc_get_version_text::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1088] phi from smc_get_version_text::@3 to smc_get_version_text::@4 [phi:smc_get_version_text::@3->smc_get_version_text::@4]
    // smc_get_version_text::@4
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1089] call printf_str
    // [1210] phi from smc_get_version_text::@4 to printf_str [phi:smc_get_version_text::@4->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_get_version_text::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = smc_get_version_text::s [phi:smc_get_version_text::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@5
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1090] printf_uchar::uvalue#9 = smc_get_version_text::minor#2 -- vbum1=vbum2 
    lda minor
    sta printf_uchar.uvalue
    // [1091] call printf_uchar
    // [1347] phi from smc_get_version_text::@5 to printf_uchar [phi:smc_get_version_text::@5->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_get_version_text::@5->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:smc_get_version_text::@5->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:smc_get_version_text::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_get_version_text::@5->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#9 [phi:smc_get_version_text::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_get_version_text::@6
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1092] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1093] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_get_version_text::@return
    // }
    // [1095] return 
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
    // [1097] call vera_detect
    // [2411] phi from main_vera_detect to vera_detect [phi:main_vera_detect->vera_detect]
    jsr vera_detect
    // [1098] phi from main_vera_detect to main_vera_detect::@1 [phi:main_vera_detect->main_vera_detect::@1]
    // main_vera_detect::@1
    // display_chip_vera()
    // [1099] call display_chip_vera
    // [938] phi from main_vera_detect::@1 to display_chip_vera [phi:main_vera_detect::@1->display_chip_vera]
    jsr display_chip_vera
    // main_vera_detect::@2
    // [1100] spi_manufacturer#584 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1101] spi_memory_type#585 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1102] spi_memory_capacity#586 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, NULL)
    // [1103] call display_info_vera
    // [998] phi from main_vera_detect::@2 to display_info_vera [phi:main_vera_detect::@2->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = 0 [phi:main_vera_detect::@2->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#586 [phi:main_vera_detect::@2->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#585 [phi:main_vera_detect::@2->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#584 [phi:main_vera_detect::@2->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_detect::@2->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_detect::@return
    // }
    // [1104] return 
    rts
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__3 = $2b
    .label rom_detect__5 = $42
    .label rom_detect__9 = $41
    .label rom_detect__14 = $6a
    .label rom_detect__15 = $61
    .label rom_detect__18 = $60
    .label rom_detect__21 = $c6
    .label rom_detect__24 = $7d
    // [1106] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [1106] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [1106] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vdum1=vduc1 
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
    // [1107] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [1108] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [1109] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [1110] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [1111] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vdum1=vdum2_plus_vwuc1 
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
    // [1112] call rom_unlock
    // [2414] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [2414] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$90
    sta rom_unlock.unlock_code
    // [2414] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [1113] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vdum1=vdum2 
    lda rom_detect_address
    sta rom_read_byte.address
    lda rom_detect_address+1
    sta rom_read_byte.address+1
    lda rom_detect_address+2
    sta rom_read_byte.address+2
    lda rom_detect_address+3
    sta rom_read_byte.address+3
    // [1114] call rom_read_byte
    // [2424] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [2424] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [1115] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [1116] rom_detect::$3 = rom_read_byte::return#2 -- vbuz1=vbum2 
    lda rom_read_byte.return
    sta.z rom_detect__3
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [1117] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [1118] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vdum1=vdum2_plus_1 
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
    // [1119] call rom_read_byte
    // [2424] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [2424] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [1120] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [1121] rom_detect::$5 = rom_read_byte::return#3 -- vbuz1=vbum2 
    lda rom_read_byte.return
    sta.z rom_detect__5
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [1122] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [1123] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vdum1=vdum2_plus_vwuc1 
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
    // [1124] call rom_unlock
    // [2414] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [2414] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbum1=vbuc1 
    lda #$f0
    sta rom_unlock.unlock_code
    // [2414] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [1125] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [1126] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z rom_detect__14
    // [1127] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z rom_detect__14
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [1128] gotoxy::x#30 = rom_detect::$9 + $28 -- vbum1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta gotoxy.x
    // [1129] call gotoxy
    // [802] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [802] phi gotoxy::y#37 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = gotoxy::x#30 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [1130] printf_uchar::uvalue#14 = rom_device_ids[rom_detect::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta printf_uchar.uvalue
    // [1131] call printf_uchar
    // [1347] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#14 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [1132] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [1133] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [1134] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [1135] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [1136] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [1137] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [1138] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [1139] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [1140] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [1141] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [1142] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [1106] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [1106] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [1106] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [1143] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [1144] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [1145] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [1146] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [1147] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [1148] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [1149] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [1150] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [1151] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [1152] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [1153] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [1154] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    .label smc_bram_ptr = $4c
    .label smc_action_text = $7e
    // if(info_status == STATUS_READING)
    // [1156] if(smc_read::info_status#10==STATUS_READING) goto smc_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [1158] phi from smc_read to smc_read::@2 [phi:smc_read->smc_read::@2]
    // [1158] phi smc_read::smc_action_text#12 = smc_action_text#2 [phi:smc_read->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z smc_action_text
    lda #>smc_action_text_1
    sta.z smc_action_text+1
    jmp __b2
    // [1157] phi from smc_read to smc_read::@1 [phi:smc_read->smc_read::@1]
    // smc_read::@1
  __b1:
    // [1158] phi from smc_read::@1 to smc_read::@2 [phi:smc_read::@1->smc_read::@2]
    // [1158] phi smc_read::smc_action_text#12 = smc_action_text#1 [phi:smc_read::@1->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z smc_action_text
    lda #>smc_action_text
    sta.z smc_action_text+1
    // smc_read::@2
  __b2:
    // smc_read::bank_set_bram1
    // BRAM = bank
    // [1159] BRAM = smc_read::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1160] phi from smc_read::bank_set_bram1 to smc_read::@16 [phi:smc_read::bank_set_bram1->smc_read::@16]
    // smc_read::@16
    // textcolor(WHITE)
    // [1161] call textcolor
    // [784] phi from smc_read::@16 to textcolor [phi:smc_read::@16->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:smc_read::@16->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1162] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // gotoxy(x, y)
    // [1163] call gotoxy
    // [802] phi from smc_read::@17 to gotoxy [phi:smc_read::@17->gotoxy]
    // [802] phi gotoxy::y#37 = PROGRESS_Y [phi:smc_read::@17->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:smc_read::@17->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1164] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1165] call fopen
    // [2436] phi from smc_read::@18 to fopen [phi:smc_read::@18->fopen]
    // [2436] phi __errno#473 = __errno#102 [phi:smc_read::@18->fopen#0] -- register_copy 
    // [2436] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@18->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2436] phi __stdio_filecount#27 = __stdio_filecount#128 [phi:smc_read::@18->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1166] fopen::return#4 = fopen::return#2
    // smc_read::@19
    // [1167] smc_read::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1168] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@3 -- pssc1_eq_pssz1_then_la1 
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
    // [1169] fgets::stream#1 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1170] call fgets
    // [2517] phi from smc_read::@4 to fgets [phi:smc_read::@4->fgets]
    // [2517] phi fgets::ptr#14 = smc_file_header [phi:smc_read::@4->fgets#0] -- pbuz1=pbuc1 
    lda #<smc_file_header
    sta.z fgets.ptr
    lda #>smc_file_header
    sta.z fgets.ptr+1
    // [2517] phi fgets::size#10 = $20 [phi:smc_read::@4->fgets#1] -- vwum1=vbuc1 
    lda #<$20
    sta fgets.size
    lda #>$20
    sta fgets.size+1
    // [2517] phi fgets::stream#4 = fgets::stream#1 [phi:smc_read::@4->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_file_header, 32, fp)
    // [1171] fgets::return#11 = fgets::return#1
    // smc_read::@20
    // smc_file_read = fgets(smc_file_header, 32, fp)
    // [1172] smc_read::smc_file_read#1 = fgets::return#11
    // if(smc_file_read)
    // [1173] if(0==smc_read::smc_file_read#1) goto smc_read::@3 -- 0_eq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    beq __b5
    // smc_read::@5
    // if(info_status == STATUS_CHECKING)
    // [1174] if(smc_read::info_status#10!=STATUS_CHECKING) goto smc_read::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b4
    // [1175] phi from smc_read::@5 to smc_read::@6 [phi:smc_read::@5->smc_read::@6]
    // smc_read::@6
    // [1176] phi from smc_read::@6 to smc_read::@7 [phi:smc_read::@6->smc_read::@7]
    // [1176] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@6->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1176] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@6->smc_read::@7#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1176] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@6->smc_read::@7#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [1176] phi smc_read::smc_bram_ptr#10 = (char *) 1024 [phi:smc_read::@6->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    jmp __b7
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // [1176] phi from smc_read::@5 to smc_read::@7 [phi:smc_read::@5->smc_read::@7]
  __b4:
    // [1176] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@5->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1176] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@5->smc_read::@7#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1176] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@5->smc_read::@7#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [1176] phi smc_read::smc_bram_ptr#10 = (char *)$a000 [phi:smc_read::@5->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // smc_read::@7
  __b7:
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1177] fgets::ptr#4 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z fgets.ptr
    lda.z smc_bram_ptr+1
    sta.z fgets.ptr+1
    // [1178] fgets::stream#2 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1179] call fgets
    // [2517] phi from smc_read::@7 to fgets [phi:smc_read::@7->fgets]
    // [2517] phi fgets::ptr#14 = fgets::ptr#4 [phi:smc_read::@7->fgets#0] -- register_copy 
    // [2517] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@7->fgets#1] -- vwum1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta fgets.size
    lda #>SMC_PROGRESS_CELL
    sta fgets.size+1
    // [2517] phi fgets::stream#4 = fgets::stream#2 [phi:smc_read::@7->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1180] fgets::return#12 = fgets::return#1
    // smc_read::@21
    // smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1181] smc_read::smc_file_read#10 = fgets::return#12
    // while (smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp))
    // [1182] if(0!=smc_read::smc_file_read#10) goto smc_read::@8 -- 0_neq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    bne __b8
    // smc_read::@9
    // fclose(fp)
    // [1183] fclose::stream#1 = smc_read::fp#0
    // [1184] call fclose
    // [2571] phi from smc_read::@9 to fclose [phi:smc_read::@9->fclose]
    // [2571] phi fclose::stream#3 = fclose::stream#1 [phi:smc_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [1185] phi from smc_read::@9 to smc_read::@3 [phi:smc_read::@9->smc_read::@3]
    // [1185] phi __stdio_filecount#39 = __stdio_filecount#2 [phi:smc_read::@9->smc_read::@3#0] -- register_copy 
    // [1185] phi smc_read::return#0 = smc_read::smc_file_size#10 [phi:smc_read::@9->smc_read::@3#1] -- register_copy 
    rts
    // [1185] phi from smc_read::@19 smc_read::@20 to smc_read::@3 [phi:smc_read::@19/smc_read::@20->smc_read::@3]
  __b5:
    // [1185] phi __stdio_filecount#39 = __stdio_filecount#1 [phi:smc_read::@19/smc_read::@20->smc_read::@3#0] -- register_copy 
    // [1185] phi smc_read::return#0 = 0 [phi:smc_read::@19/smc_read::@20->smc_read::@3#1] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@3
    // smc_read::@return
    // }
    // [1186] return 
    rts
    // smc_read::@8
  __b8:
    // display_action_text_reading(smc_action_text, "SMC.BIN", smc_file_size, SMC_CHIP_SIZE, smc_bram_bank, smc_bram_ptr)
    // [1187] display_action_text_reading::action#1 = smc_read::smc_action_text#12 -- pbuz1=pbuz2 
    lda.z smc_action_text
    sta.z display_action_text_reading.action
    lda.z smc_action_text+1
    sta.z display_action_text_reading.action+1
    // [1188] display_action_text_reading::bytes#1 = smc_read::smc_file_size#10 -- vdum1=vwum2 
    lda smc_file_size
    sta display_action_text_reading.bytes
    lda smc_file_size+1
    sta display_action_text_reading.bytes+1
    lda #0
    sta display_action_text_reading.bytes+2
    sta display_action_text_reading.bytes+3
    // [1189] display_action_text_reading::bram_ptr#1 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1190] call display_action_text_reading
    // [2600] phi from smc_read::@8 to display_action_text_reading [phi:smc_read::@8->display_action_text_reading]
    // [2600] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#1 [phi:smc_read::@8->display_action_text_reading#0] -- register_copy 
    // [2600] phi display_action_text_reading::bram_bank#10 = smc_read::smc_bram_bank [phi:smc_read::@8->display_action_text_reading#1] -- vbum1=vbuc1 
    lda #smc_bram_bank
    sta display_action_text_reading.bram_bank
    // [2600] phi display_action_text_reading::size#10 = SMC_CHIP_SIZE [phi:smc_read::@8->display_action_text_reading#2] -- vdum1=vduc1 
    lda #<SMC_CHIP_SIZE
    sta display_action_text_reading.size
    lda #>SMC_CHIP_SIZE
    sta display_action_text_reading.size+1
    lda #<SMC_CHIP_SIZE>>$10
    sta display_action_text_reading.size+2
    lda #>SMC_CHIP_SIZE>>$10
    sta display_action_text_reading.size+3
    // [2600] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#1 [phi:smc_read::@8->display_action_text_reading#3] -- register_copy 
    // [2600] phi display_action_text_reading::file#3 = smc_read::path [phi:smc_read::@8->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2600] phi display_action_text_reading::action#3 = display_action_text_reading::action#1 [phi:smc_read::@8->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // smc_read::@22
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1191] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b10
    lda progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b10
    // smc_read::@13
    // gotoxy(x, ++y);
    // [1192] smc_read::y#1 = ++ smc_read::y#12 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1193] gotoxy::y#27 = smc_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1194] call gotoxy
    // [802] phi from smc_read::@13 to gotoxy [phi:smc_read::@13->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#27 [phi:smc_read::@13->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:smc_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1195] phi from smc_read::@13 to smc_read::@10 [phi:smc_read::@13->smc_read::@10]
    // [1195] phi smc_read::y#13 = smc_read::y#1 [phi:smc_read::@13->smc_read::@10#0] -- register_copy 
    // [1195] phi smc_read::progress_row_bytes#11 = 0 [phi:smc_read::@13->smc_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1195] phi from smc_read::@22 to smc_read::@10 [phi:smc_read::@22->smc_read::@10]
    // [1195] phi smc_read::y#13 = smc_read::y#12 [phi:smc_read::@22->smc_read::@10#0] -- register_copy 
    // [1195] phi smc_read::progress_row_bytes#11 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@10#1] -- register_copy 
    // smc_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [1196] if(smc_read::info_status#10!=STATUS_READING) goto smc_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // smc_read::@14
    // cputc('.')
    // [1197] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1198] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_read::@11
  __b11:
    // if(info_status == STATUS_CHECKING)
    // [1200] if(smc_read::info_status#10==STATUS_CHECKING) goto smc_read::@12 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    beq __b6
    // smc_read::@15
    // smc_bram_ptr += smc_file_read
    // [1201] smc_read::smc_bram_ptr#3 = smc_read::smc_bram_ptr#10 + smc_read::smc_file_read#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z smc_bram_ptr
    adc smc_file_read
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    adc smc_file_read+1
    sta.z smc_bram_ptr+1
    // [1202] phi from smc_read::@15 to smc_read::@12 [phi:smc_read::@15->smc_read::@12]
    // [1202] phi smc_read::smc_bram_ptr#7 = smc_read::smc_bram_ptr#3 [phi:smc_read::@15->smc_read::@12#0] -- register_copy 
    jmp __b12
    // [1202] phi from smc_read::@11 to smc_read::@12 [phi:smc_read::@11->smc_read::@12]
  __b6:
    // [1202] phi smc_read::smc_bram_ptr#7 = (char *) 1024 [phi:smc_read::@11->smc_read::@12#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    // smc_read::@12
  __b12:
    // smc_file_size += smc_file_read
    // [1203] smc_read::smc_file_size#1 = smc_read::smc_file_size#10 + smc_read::smc_file_read#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda smc_file_size
    adc smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1204] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#11 + smc_read::smc_file_read#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_bytes
    adc smc_file_read
    sta progress_row_bytes
    lda progress_row_bytes+1
    adc smc_file_read+1
    sta progress_row_bytes+1
    // [1176] phi from smc_read::@12 to smc_read::@7 [phi:smc_read::@12->smc_read::@7]
    // [1176] phi smc_read::y#12 = smc_read::y#13 [phi:smc_read::@12->smc_read::@7#0] -- register_copy 
    // [1176] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@12->smc_read::@7#1] -- register_copy 
    // [1176] phi smc_read::smc_file_size#10 = smc_read::smc_file_size#1 [phi:smc_read::@12->smc_read::@7#2] -- register_copy 
    // [1176] phi smc_read::smc_bram_ptr#10 = smc_read::smc_bram_ptr#7 [phi:smc_read::@12->smc_read::@7#3] -- register_copy 
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
// void snprintf_init(__zp($45) char *s, unsigned int n)
snprintf_init: {
    .label s = $45
    // __snprintf_capacity = n
    // [1206] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [1207] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [1208] __snprintf_buffer = snprintf_init::s#31 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [1209] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($3b) void (*putc)(char), __zp($50) const char *s)
printf_str: {
    .label s = $50
    .label putc = $3b
    // [1211] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [1211] phi printf_str::s#83 = printf_str::s#84 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [1212] printf_str::c#1 = *printf_str::s#83 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1213] printf_str::s#0 = ++ printf_str::s#83 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1214] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [1215] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [1216] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1217] callexecute *printf_str::putc#84  -- call__deref_pprz1 
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
// void printf_string(__zp($4a) void (*putc)(char), __zp($50) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $3d
    .label str = $50
    .label str_1 = $b6
    .label putc = $4a
    // if(format.min_length)
    // [1220] if(0==printf_string::format_min_length#26) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1221] strlen::str#3 = printf_string::str#26 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1222] call strlen
    // [2631] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2631] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1223] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1224] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1225] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1226] printf_string::padding#1 = (signed char)printf_string::format_min_length#26 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1227] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1229] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1229] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1228] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1229] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1229] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1230] if(0!=printf_string::format_justify_left#26) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1231] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1232] printf_padding::putc#3 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1233] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1234] call printf_padding
    // [2637] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2637] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2637] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2637] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1235] printf_str::putc#1 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1236] printf_str::s#2 = printf_string::str#26
    // [1237] call printf_str
    // [1210] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [1210] phi printf_str::putc#84 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [1210] phi printf_str::s#84 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1238] if(0==printf_string::format_justify_left#26) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1239] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1240] printf_padding::putc#4 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1241] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1242] call printf_padding
    // [2637] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2637] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2637] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2637] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1243] return 
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
    // [1245] call display_action_progress
    // [904] phi from main_vera_check to display_action_progress [phi:main_vera_check->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main_vera_check::info_text [phi:main_vera_check->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1246] phi from main_vera_check to main_vera_check::@4 [phi:main_vera_check->main_vera_check::@4]
    // main_vera_check::@4
    // unsigned long vera_bytes_read = vera_read(STATUS_CHECKING)
    // [1247] call vera_read
  // Read the VERA.BIN file.
    // [2645] phi from main_vera_check::@4 to vera_read [phi:main_vera_check::@4->vera_read]
    // [2645] phi __errno#100 = __errno#113 [phi:main_vera_check::@4->vera_read#0] -- register_copy 
    // [2645] phi __stdio_filecount#123 = __stdio_filecount#109 [phi:main_vera_check::@4->vera_read#1] -- register_copy 
    // [2645] phi vera_read::info_status#12 = STATUS_CHECKING [phi:main_vera_check::@4->vera_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta vera_read.info_status
    jsr vera_read
    // unsigned long vera_bytes_read = vera_read(STATUS_CHECKING)
    // [1248] vera_read::return#2 = vera_read::return#0
    // main_vera_check::@5
    // [1249] main_vera_check::vera_bytes_read#0 = vera_read::return#2 -- vduz1=vdum2 
    lda vera_read.return
    sta.z vera_bytes_read
    lda vera_read.return+1
    sta.z vera_bytes_read+1
    lda vera_read.return+2
    sta.z vera_bytes_read+2
    lda vera_read.return+3
    sta.z vera_bytes_read+3
    // wait_moment(10)
    // [1250] call wait_moment
    // [1310] phi from main_vera_check::@5 to wait_moment [phi:main_vera_check::@5->wait_moment]
    // [1310] phi wait_moment::w#13 = $a [phi:main_vera_check::@5->wait_moment#0] -- vbum1=vbuc1 
    lda #$a
    sta wait_moment.w
    jsr wait_moment
    // main_vera_check::@6
    // if (!vera_bytes_read)
    // [1251] if(0==main_vera_check::vera_bytes_read#0) goto main_vera_check::@1 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    beq __b1
    // main_vera_check::@3
    // vera_file_size = vera_bytes_read
    // [1252] vera_file_size#0 = main_vera_check::vera_bytes_read#0 -- vdum1=vduz2 
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
    // [1253] call snprintf_init
    // [1205] phi from main_vera_check::@3 to snprintf_init [phi:main_vera_check::@3->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main_vera_check::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1254] phi from main_vera_check::@3 to main_vera_check::@7 [phi:main_vera_check::@3->main_vera_check::@7]
    // main_vera_check::@7
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1255] call printf_str
    // [1210] phi from main_vera_check::@7 to printf_str [phi:main_vera_check::@7->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main_vera_check::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main_vera_check::s [phi:main_vera_check::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [1256] phi from main_vera_check::@7 to main_vera_check::@8 [phi:main_vera_check::@7->main_vera_check::@8]
    // main_vera_check::@8
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1257] call printf_string
    // [1219] phi from main_vera_check::@8 to printf_string [phi:main_vera_check::@8->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:main_vera_check::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = str [phi:main_vera_check::@8->printf_string#1] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:main_vera_check::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:main_vera_check::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main_vera_check::@9
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1258] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1259] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1261] spi_manufacturer#583 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1262] spi_memory_type#584 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1263] spi_memory_capacity#585 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASH, info_text)
    // [1264] call display_info_vera
    // [998] phi from main_vera_check::@9 to display_info_vera [phi:main_vera_check::@9->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = info_text [phi:main_vera_check::@9->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#585 [phi:main_vera_check::@9->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#584 [phi:main_vera_check::@9->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#583 [phi:main_vera_check::@9->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_FLASH [phi:main_vera_check::@9->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1265] phi from main_vera_check::@9 to main_vera_check::@2 [phi:main_vera_check::@9->main_vera_check::@2]
    // [1265] phi vera_file_size#1 = vera_file_size#0 [phi:main_vera_check::@9->main_vera_check::@2#0] -- register_copy 
    // main_vera_check::@2
    // main_vera_check::@return
    // }
    // [1266] return 
    rts
    // main_vera_check::@1
  __b1:
    // [1267] spi_manufacturer#582 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1268] spi_memory_type#583 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1269] spi_memory_capacity#584 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "No VERA.BIN")
    // [1270] call display_info_vera
  // VF1 | no VERA.BIN  | Ask the user to place the VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // VF2 | VERA.BIN size 0 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // TODO: VF4 | ROM.BIN size over 0x20000 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
    // [998] phi from main_vera_check::@1 to display_info_vera [phi:main_vera_check::@1->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = main_vera_check::info_text1 [phi:main_vera_check::@1->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#584 [phi:main_vera_check::@1->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#583 [phi:main_vera_check::@1->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#582 [phi:main_vera_check::@1->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main_vera_check::@1->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1265] phi from main_vera_check::@1 to main_vera_check::@2 [phi:main_vera_check::@1->main_vera_check::@2]
    // [1265] phi vera_file_size#1 = 0 [phi:main_vera_check::@1->main_vera_check::@2#0] -- vdum1=vduc1 
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
    // [1272] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [1272] phi smc_supported_rom::i#2 = $1f [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbum1=vbuc1 
    lda #$1f
    sta i
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=31; i>3; i--)
    // [1273] if(smc_supported_rom::i#2>=3+1) goto smc_supported_rom::@2 -- vbum1_ge_vbuc1_then_la1 
    lda i
    cmp #3+1
    bcs __b2
    // [1275] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [1275] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_file_header[i] == rom_release)
    // [1274] if(smc_file_header[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbum1_neq_vbum2_then_la1 
    lda rom_release
    ldy i
    cmp smc_file_header,y
    bne __b3
    // [1275] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [1275] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // smc_supported_rom::@return
    // }
    // [1276] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=31; i>3; i--)
    // [1277] smc_supported_rom::i#1 = -- smc_supported_rom::i#2 -- vbum1=_dec_vbum1 
    dec i
    // [1272] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [1272] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
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
    // [1279] phi from check_status_roms to check_status_roms::@1 [phi:check_status_roms->check_status_roms::@1]
    // [1279] phi check_status_roms::rom_chip#2 = 0 [phi:check_status_roms->check_status_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1280] if(check_status_roms::rom_chip#2<8) goto check_status_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1281] phi from check_status_roms::@1 to check_status_roms::@return [phi:check_status_roms::@1->check_status_roms::@return]
    // [1281] phi check_status_roms::return#2 = 0 [phi:check_status_roms::@1->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_roms::@return
    // }
    // [1282] return 
    rts
    // check_status_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1283] check_status_roms::check_status_rom1_$0 = status_rom[check_status_roms::rom_chip#2] == check_status_roms::status#6 -- vboz1=pbuc1_derefidx_vbum2_eq_vbum3 
    lda status
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1284] check_status_roms::check_status_rom1_return#0 = (char)check_status_roms::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1285] if(0==check_status_roms::check_status_rom1_return#0) goto check_status_roms::@2 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [1281] phi from check_status_roms::@3 to check_status_roms::@return [phi:check_status_roms::@3->check_status_roms::@return]
    // [1281] phi check_status_roms::return#2 = 1 [phi:check_status_roms::@3->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_roms::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1286] check_status_roms::rom_chip#1 = ++ check_status_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1279] phi from check_status_roms::@2 to check_status_roms::@1 [phi:check_status_roms::@2->check_status_roms::@1]
    // [1279] phi check_status_roms::rom_chip#2 = check_status_roms::rom_chip#1 [phi:check_status_roms::@2->check_status_roms::@1#0] -- register_copy 
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
    .label clrscr__0 = $6a
    .label clrscr__1 = $41
    .label clrscr__2 = $7d
    // unsigned int line_text = __conio.mapbase_offset
    // [1287] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1288] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1289] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1290] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1291] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1292] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1292] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1292] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1293] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1294] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1295] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1296] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1297] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1298] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1298] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1299] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1300] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1301] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1302] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1303] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1304] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1305] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1306] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1307] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1308] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1309] return 
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
    // [1311] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1311] phi wait_moment::j#2 = 0 [phi:wait_moment->wait_moment::@1#0] -- vbum1=vbuc1 
    lda #0
    sta j
    // wait_moment::@1
  __b1:
    // for(unsigned char j=0; j<w; j++)
    // [1312] if(wait_moment::j#2<wait_moment::w#13) goto wait_moment::@2 -- vbum1_lt_vbum2_then_la1 
    lda j
    cmp w
    bcc __b4
    // wait_moment::@return
    // }
    // [1313] return 
    rts
    // [1314] phi from wait_moment::@1 to wait_moment::@2 [phi:wait_moment::@1->wait_moment::@2]
  __b4:
    // [1314] phi wait_moment::i#2 = $ffff [phi:wait_moment::@1->wait_moment::@2#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta i
    lda #>$ffff
    sta i+1
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1315] if(wait_moment::i#2>0) goto wait_moment::@3 -- vwum1_gt_0_then_la1 
    lda i+1
    bne __b3
    lda i
    bne __b3
  !:
    // wait_moment::@4
    // for(unsigned char j=0; j<w; j++)
    // [1316] wait_moment::j#1 = ++ wait_moment::j#2 -- vbum1=_inc_vbum1 
    inc j
    // [1311] phi from wait_moment::@4 to wait_moment::@1 [phi:wait_moment::@4->wait_moment::@1]
    // [1311] phi wait_moment::j#2 = wait_moment::j#1 [phi:wait_moment::@4->wait_moment::@1#0] -- register_copy 
    jmp __b1
    // wait_moment::@3
  __b3:
    // for(unsigned int i=65535; i>0; i--)
    // [1317] wait_moment::i#1 = -- wait_moment::i#2 -- vwum1=_dec_vwum1 
    lda i
    bne !+
    dec i+1
  !:
    dec i
    // [1314] phi from wait_moment::@3 to wait_moment::@2 [phi:wait_moment::@3->wait_moment::@2]
    // [1314] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@3->wait_moment::@2#0] -- register_copy 
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
    // [1319] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1320] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1322] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    // [1324] phi from check_status_roms_less to check_status_roms_less::@1 [phi:check_status_roms_less->check_status_roms_less::@1]
    // [1324] phi check_status_roms_less::rom_chip#2 = 0 [phi:check_status_roms_less->check_status_roms_less::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms_less::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1325] if(check_status_roms_less::rom_chip#2<8) goto check_status_roms_less::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1326] phi from check_status_roms_less::@1 to check_status_roms_less::@return [phi:check_status_roms_less::@1->check_status_roms_less::@return]
    // [1326] phi check_status_roms_less::return#2 = 1 [phi:check_status_roms_less::@1->check_status_roms_less::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // check_status_roms_less::@return
    // }
    // [1327] return 
    rts
    // check_status_roms_less::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1328] check_status_roms_less::check_status_rom1_$0 = status_rom[check_status_roms_less::rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms_less__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1329] check_status_roms_less::check_status_rom1_return#0 = (char)check_status_roms_less::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_roms_less::@3
    // if(check_status_rom(rom_chip, status) > status)
    // [1330] if(check_status_roms_less::check_status_rom1_return#0<STATUS_SKIP+1) goto check_status_roms_less::@2 -- vbum1_lt_vbuc1_then_la1 
    cmp #STATUS_SKIP+1
    bcc __b2
    // [1326] phi from check_status_roms_less::@3 to check_status_roms_less::@return [phi:check_status_roms_less::@3->check_status_roms_less::@return]
    // [1326] phi check_status_roms_less::return#2 = 0 [phi:check_status_roms_less::@3->check_status_roms_less::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // check_status_roms_less::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1331] check_status_roms_less::rom_chip#1 = ++ check_status_roms_less::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1324] phi from check_status_roms_less::@2 to check_status_roms_less::@1 [phi:check_status_roms_less::@2->check_status_roms_less::@1]
    // [1324] phi check_status_roms_less::rom_chip#2 = check_status_roms_less::rom_chip#1 [phi:check_status_roms_less::@2->check_status_roms_less::@1#0] -- register_copy 
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
// void display_progress_text(__zp($3b) char **text, __mem() char lines)
display_progress_text: {
    .label display_progress_text__3 = $60
    .label text = $3b
    // display_progress_clear()
    // [1333] call display_progress_clear
    // [918] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [1334] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [1334] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [1335] if(display_progress_text::l#2<display_progress_text::lines#12) goto display_progress_text::@2 -- vbum1_lt_vbum2_then_la1 
    lda l
    cmp lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [1336] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [1337] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbum2_rol_1 
    lda l
    asl
    sta.z display_progress_text__3
    // [1338] display_progress_line::line#0 = display_progress_text::l#2 -- vbum1=vbum2 
    lda l
    sta display_progress_line.line
    // [1339] display_progress_line::text#0 = display_progress_text::text#13[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [1340] call display_progress_line
    // [1342] phi from display_progress_text::@2 to display_progress_line [phi:display_progress_text::@2->display_progress_line]
    // [1342] phi display_progress_line::text#3 = display_progress_line::text#0 [phi:display_progress_text::@2->display_progress_line#0] -- register_copy 
    // [1342] phi display_progress_line::line#3 = display_progress_line::line#0 [phi:display_progress_text::@2->display_progress_line#1] -- register_copy 
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [1341] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [1334] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [1334] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
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
// void display_progress_line(__mem() char line, __zp($6e) char *text)
display_progress_line: {
    .label text = $6e
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1343] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#3 -- vbum1=vbuc1_plus_vbum1 
    lda #PROGRESS_Y
    clc
    adc cputsxy.y
    sta cputsxy.y
    // [1344] cputsxy::s#0 = display_progress_line::text#3
    // [1345] call cputsxy
    // [897] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [897] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [897] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [897] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1346] return 
    rts
  .segment Data
    .label line = cputsxy.y
}
.segment Code
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($3b) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $3b
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1348] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1349] uctoa::value#1 = printf_uchar::uvalue#18
    // [1350] uctoa::radix#0 = printf_uchar::format_radix#18
    // [1351] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1352] printf_number_buffer::putc#2 = printf_uchar::putc#18
    // [1353] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1354] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#18
    // [1355] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#18
    // [1356] call printf_number_buffer
  // Print using format
    // [2726] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [2726] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [2726] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [2726] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [2726] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1357] return 
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
// void display_action_text(__zp($4a) char *info_text)
display_action_text: {
    .label info_text = $4a
    // unsigned char x = wherex()
    // [1359] call wherex
    jsr wherex
    // [1360] wherex::return#3 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_1
    // display_action_text::@1
    // [1361] display_action_text::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [1362] call wherey
    jsr wherey
    // [1363] wherey::return#3 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_1
    // display_action_text::@2
    // [1364] display_action_text::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [1365] call gotoxy
    // [802] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [802] phi gotoxy::y#37 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1366] printf_string::str#2 = display_action_text::info_text#25 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1367] call printf_string
    // [1219] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1368] gotoxy::x#16 = display_action_text::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1369] gotoxy::y#16 = display_action_text::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1370] call gotoxy
    // [802] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#16 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#16 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1371] return 
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
    // [1373] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1374] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@1
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1375] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1376] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1377] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1378] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1380] return 
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
    .label check_status_rom1_check_status_card_roms__0 = $61
    // [1382] phi from check_status_card_roms to check_status_card_roms::@1 [phi:check_status_card_roms->check_status_card_roms::@1]
    // [1382] phi check_status_card_roms::rom_chip#2 = 1 [phi:check_status_card_roms->check_status_card_roms::@1#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip
    // check_status_card_roms::@1
  __b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1383] if(check_status_card_roms::rom_chip#2<8) goto check_status_card_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1384] phi from check_status_card_roms::@1 to check_status_card_roms::@return [phi:check_status_card_roms::@1->check_status_card_roms::@return]
    // [1384] phi check_status_card_roms::return#2 = 0 [phi:check_status_card_roms::@1->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_card_roms::@return
    // }
    // [1385] return 
    rts
    // check_status_card_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1386] check_status_card_roms::check_status_rom1_$0 = status_rom[check_status_card_roms::rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_card_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1387] check_status_card_roms::check_status_rom1_return#0 = (char)check_status_card_roms::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_card_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1388] if(0==check_status_card_roms::check_status_rom1_return#0) goto check_status_card_roms::@2 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [1384] phi from check_status_card_roms::@3 to check_status_card_roms::@return [phi:check_status_card_roms::@3->check_status_card_roms::@return]
    // [1384] phi check_status_card_roms::return#2 = 1 [phi:check_status_card_roms::@3->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_card_roms::@2
  __b2:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1389] check_status_card_roms::rom_chip#1 = ++ check_status_card_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1382] phi from check_status_card_roms::@2 to check_status_card_roms::@1 [phi:check_status_card_roms::@2->check_status_card_roms::@1]
    // [1382] phi check_status_card_roms::rom_chip#2 = check_status_card_roms::rom_chip#1 [phi:check_status_card_roms::@2->check_status_card_roms::@1#0] -- register_copy 
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
    // [1391] call util_wait_key
    // [2019] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [2019] phi util_wait_key::filter#13 = s4 [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s4
    sta.z util_wait_key.filter
    lda #>s4
    sta.z util_wait_key.filter+1
    // [2019] phi util_wait_key::info_text#3 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [1392] return 
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
    .label vera_erase_error = $eb
    .label vera_differences1 = $f5
    .label spi_ensure_detect_1 = $cf
    // display_progress_clear()
    // [1394] call display_progress_clear
    // [918] phi from main_vera_flash to display_progress_clear [phi:main_vera_flash->display_progress_clear]
    jsr display_progress_clear
    // [1395] phi from main_vera_flash to main_vera_flash::@20 [phi:main_vera_flash->main_vera_flash::@20]
    // main_vera_flash::@20
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1396] call snprintf_init
    // [1205] phi from main_vera_flash::@20 to snprintf_init [phi:main_vera_flash::@20->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main_vera_flash::@20->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1397] phi from main_vera_flash::@20 to main_vera_flash::@21 [phi:main_vera_flash::@20->main_vera_flash::@21]
    // main_vera_flash::@21
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1398] call printf_str
    // [1210] phi from main_vera_flash::@21 to printf_str [phi:main_vera_flash::@21->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main_vera_flash::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main_vera_flash::s [phi:main_vera_flash::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@22
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1399] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1400] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [1402] call display_action_progress
    // [904] phi from main_vera_flash::@22 to display_action_progress [phi:main_vera_flash::@22->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = info_text [phi:main_vera_flash::@22->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1403] phi from main_vera_flash::@22 to main_vera_flash::@23 [phi:main_vera_flash::@22->main_vera_flash::@23]
    // main_vera_flash::@23
    // unsigned long vera_bytes_read = vera_read(STATUS_READING)
    // [1404] call vera_read
    // [2645] phi from main_vera_flash::@23 to vera_read [phi:main_vera_flash::@23->vera_read]
    // [2645] phi __errno#100 = __errno#115 [phi:main_vera_flash::@23->vera_read#0] -- register_copy 
    // [2645] phi __stdio_filecount#123 = __stdio_filecount#111 [phi:main_vera_flash::@23->vera_read#1] -- register_copy 
    // [2645] phi vera_read::info_status#12 = STATUS_READING [phi:main_vera_flash::@23->vera_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta vera_read.info_status
    jsr vera_read
    // unsigned long vera_bytes_read = vera_read(STATUS_READING)
    // [1405] vera_read::return#3 = vera_read::return#0
    // main_vera_flash::@24
    // [1406] main_vera_flash::vera_bytes_read#0 = vera_read::return#3 -- vduz1=vdum2 
    lda vera_read.return
    sta.z vera_bytes_read
    lda vera_read.return+1
    sta.z vera_bytes_read+1
    lda vera_read.return+2
    sta.z vera_bytes_read+2
    lda vera_read.return+3
    sta.z vera_bytes_read+3
    // if(vera_bytes_read)
    // [1407] if(0==main_vera_flash::vera_bytes_read#0) goto main_vera_flash::@1 -- 0_eq_vduz1_then_la1 
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    bne !__b1+
    jmp __b1
  !__b1:
    // [1408] phi from main_vera_flash::@24 to main_vera_flash::@2 [phi:main_vera_flash::@24->main_vera_flash::@2]
    // main_vera_flash::@2
    // display_action_progress("VERA SPI activation ...")
    // [1409] call display_action_progress
  // Now we loop until jumper JP1 has been placed!
    // [904] phi from main_vera_flash::@2 to display_action_progress [phi:main_vera_flash::@2->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main_vera_flash::info_text [phi:main_vera_flash::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1410] phi from main_vera_flash::@2 to main_vera_flash::@25 [phi:main_vera_flash::@2->main_vera_flash::@25]
    // main_vera_flash::@25
    // display_action_text("Please close the jumper JP1 on the VERA board!")
    // [1411] call display_action_text
    // [1358] phi from main_vera_flash::@25 to display_action_text [phi:main_vera_flash::@25->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main_vera_flash::info_text1 [phi:main_vera_flash::@25->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_text.info_text
    lda #>info_text1
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1412] phi from main_vera_flash::@25 to main_vera_flash::@26 [phi:main_vera_flash::@25->main_vera_flash::@26]
    // main_vera_flash::@26
    // vera_detect()
    // [1413] call vera_detect
    // [2411] phi from main_vera_flash::@26 to vera_detect [phi:main_vera_flash::@26->vera_detect]
    jsr vera_detect
    // [1414] phi from main_vera_flash::@26 main_vera_flash::@7 to main_vera_flash::@3 [phi:main_vera_flash::@26/main_vera_flash::@7->main_vera_flash::@3]
  __b2:
    // [1414] phi main_vera_flash::spi_ensure_detect#11 = 0 [phi:main_vera_flash::@26/main_vera_flash::@7->main_vera_flash::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z spi_ensure_detect
    // main_vera_flash::@3
  __b3:
    // while(spi_ensure_detect < 16)
    // [1415] if(main_vera_flash::spi_ensure_detect#11<$10) goto main_vera_flash::@4 -- vbuz1_lt_vbuc1_then_la1 
    lda.z spi_ensure_detect
    cmp #$10
    bcs !__b4+
    jmp __b4
  !__b4:
    // [1416] phi from main_vera_flash::@3 to main_vera_flash::@5 [phi:main_vera_flash::@3->main_vera_flash::@5]
    // main_vera_flash::@5
    // display_action_text("The jumper JP1 has been closed on the VERA!")
    // [1417] call display_action_text
    // [1358] phi from main_vera_flash::@5 to display_action_text [phi:main_vera_flash::@5->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main_vera_flash::info_text2 [phi:main_vera_flash::@5->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1418] phi from main_vera_flash::@5 to main_vera_flash::@29 [phi:main_vera_flash::@5->main_vera_flash::@29]
    // main_vera_flash::@29
    // display_action_progress("Comparing VERA ... (.) data, (=) same, (*) different.")
    // [1419] call display_action_progress
  // Now we compare the RAM with the actual VERA contents.
    // [904] phi from main_vera_flash::@29 to display_action_progress [phi:main_vera_flash::@29->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main_vera_flash::info_text3 [phi:main_vera_flash::@29->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main_vera_flash::@30
    // [1420] spi_manufacturer#589 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1421] spi_memory_type#590 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1422] spi_memory_capacity#591 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_COMPARING, NULL)
    // [1423] call display_info_vera
    // [998] phi from main_vera_flash::@30 to display_info_vera [phi:main_vera_flash::@30->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@30->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#591 [phi:main_vera_flash::@30->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#590 [phi:main_vera_flash::@30->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#589 [phi:main_vera_flash::@30->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_COMPARING [phi:main_vera_flash::@30->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1424] phi from main_vera_flash::@30 to main_vera_flash::@31 [phi:main_vera_flash::@30->main_vera_flash::@31]
    // main_vera_flash::@31
    // unsigned long vera_differences = vera_verify()
    // [1425] call vera_verify
  // Verify VERA ...
    // [2757] phi from main_vera_flash::@31 to vera_verify [phi:main_vera_flash::@31->vera_verify]
    jsr vera_verify
    // unsigned long vera_differences = vera_verify()
    // [1426] vera_verify::return#2 = vera_verify::vera_different_bytes#11
    // main_vera_flash::@32
    // [1427] main_vera_flash::vera_differences#0 = vera_verify::return#2 -- vdum1=vdum2 
    lda vera_verify.return
    sta vera_differences
    lda vera_verify.return+1
    sta vera_differences+1
    lda vera_verify.return+2
    sta vera_differences+2
    lda vera_verify.return+3
    sta vera_differences+3
    // if (!vera_differences)
    // [1428] if(0==main_vera_flash::vera_differences#0) goto main_vera_flash::@10 -- 0_eq_vdum1_then_la1 
    lda vera_differences
    ora vera_differences+1
    ora vera_differences+2
    ora vera_differences+3
    bne !__b10+
    jmp __b10
  !__b10:
    // [1429] phi from main_vera_flash::@32 to main_vera_flash::@8 [phi:main_vera_flash::@32->main_vera_flash::@8]
    // main_vera_flash::@8
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1430] call snprintf_init
    // [1205] phi from main_vera_flash::@8 to snprintf_init [phi:main_vera_flash::@8->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main_vera_flash::@8->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@34
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1431] printf_ulong::uvalue#10 = main_vera_flash::vera_differences#0 -- vdum1=vdum2 
    lda vera_differences
    sta printf_ulong.uvalue
    lda vera_differences+1
    sta printf_ulong.uvalue+1
    lda vera_differences+2
    sta printf_ulong.uvalue+2
    lda vera_differences+3
    sta printf_ulong.uvalue+3
    // [1432] call printf_ulong
    // [1761] phi from main_vera_flash::@34 to printf_ulong [phi:main_vera_flash::@34->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:main_vera_flash::@34->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:main_vera_flash::@34->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@34->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#10 [phi:main_vera_flash::@34->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1433] phi from main_vera_flash::@34 to main_vera_flash::@35 [phi:main_vera_flash::@34->main_vera_flash::@35]
    // main_vera_flash::@35
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1434] call printf_str
    // [1210] phi from main_vera_flash::@35 to printf_str [phi:main_vera_flash::@35->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main_vera_flash::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s13 [phi:main_vera_flash::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@36
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1435] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1436] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1438] spi_manufacturer#590 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1439] spi_memory_type#591 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1440] spi_memory_capacity#592 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASH, info_text)
    // [1441] call display_info_vera
    // [998] phi from main_vera_flash::@36 to display_info_vera [phi:main_vera_flash::@36->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@36->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#592 [phi:main_vera_flash::@36->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#591 [phi:main_vera_flash::@36->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#590 [phi:main_vera_flash::@36->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_FLASH [phi:main_vera_flash::@36->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1442] phi from main_vera_flash::@36 to main_vera_flash::@37 [phi:main_vera_flash::@36->main_vera_flash::@37]
    // main_vera_flash::@37
    // unsigned char vera_erase_error = vera_erase()
    // [1443] call vera_erase
    jsr vera_erase
    // [1444] vera_erase::return#3 = vera_erase::return#2
    // main_vera_flash::@38
    // [1445] main_vera_flash::vera_erase_error#0 = vera_erase::return#3 -- vbuz1=vbum2 
    lda vera_erase.return
    sta.z vera_erase_error
    // if(vera_erase_error)
    // [1446] if(0==main_vera_flash::vera_erase_error#0) goto main_vera_flash::@11 -- 0_eq_vbuz1_then_la1 
    beq __b11
    // [1447] phi from main_vera_flash::@38 to main_vera_flash::@9 [phi:main_vera_flash::@38->main_vera_flash::@9]
    // main_vera_flash::@9
    // display_action_progress("There was an error cleaning your VERA flash memory!")
    // [1448] call display_action_progress
    // [904] phi from main_vera_flash::@9 to display_action_progress [phi:main_vera_flash::@9->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main_vera_flash::info_text7 [phi:main_vera_flash::@9->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_action_progress.info_text
    lda #>info_text7
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1449] phi from main_vera_flash::@9 to main_vera_flash::@40 [phi:main_vera_flash::@9->main_vera_flash::@40]
    // main_vera_flash::@40
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [1450] call display_action_text
    // [1358] phi from main_vera_flash::@40 to display_action_text [phi:main_vera_flash::@40->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main_vera_flash::info_text8 [phi:main_vera_flash::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_text.info_text
    lda #>info_text8
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main_vera_flash::@41
    // [1451] spi_manufacturer#591 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1452] spi_memory_type#592 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1453] spi_memory_capacity#593 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_ERROR, "ERASE ERROR!")
    // [1454] call display_info_vera
    // [998] phi from main_vera_flash::@41 to display_info_vera [phi:main_vera_flash::@41->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = main_vera_flash::info_text9 [phi:main_vera_flash::@41->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_vera.info_text
    lda #>info_text9
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#593 [phi:main_vera_flash::@41->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#592 [phi:main_vera_flash::@41->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#591 [phi:main_vera_flash::@41->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_ERROR [phi:main_vera_flash::@41->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@42
    // [1455] smc_bootloader#517 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, NULL)
    // [1456] call display_info_smc
    // [962] phi from main_vera_flash::@42 to display_info_smc [phi:main_vera_flash::@42->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = 0 [phi:main_vera_flash::@42->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#517 [phi:main_vera_flash::@42->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main_vera_flash::@42->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    // [1457] phi from main_vera_flash::@42 to main_vera_flash::@43 [phi:main_vera_flash::@42->main_vera_flash::@43]
    // main_vera_flash::@43
    // display_info_roms(STATUS_ERROR, NULL)
    // [1458] call display_info_roms
    // [2835] phi from main_vera_flash::@43 to display_info_roms [phi:main_vera_flash::@43->display_info_roms]
    jsr display_info_roms
    // [1459] phi from main_vera_flash::@43 to main_vera_flash::@44 [phi:main_vera_flash::@43->main_vera_flash::@44]
    // main_vera_flash::@44
    // wait_moment(32)
    // [1460] call wait_moment
    // [1310] phi from main_vera_flash::@44 to wait_moment [phi:main_vera_flash::@44->wait_moment]
    // [1310] phi wait_moment::w#13 = $20 [phi:main_vera_flash::@44->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [1461] phi from main_vera_flash::@44 to main_vera_flash::@45 [phi:main_vera_flash::@44->main_vera_flash::@45]
    // main_vera_flash::@45
    // spi_deselect()
    // [1462] call spi_deselect
    jsr spi_deselect
    // main_vera_flash::@return
    // }
    // [1463] return 
    rts
    // [1464] phi from main_vera_flash::@38 to main_vera_flash::@11 [phi:main_vera_flash::@38->main_vera_flash::@11]
    // main_vera_flash::@11
  __b11:
    // unsigned long vera_flashed = vera_flash()
    // [1465] call vera_flash
    // [2845] phi from main_vera_flash::@11 to vera_flash [phi:main_vera_flash::@11->vera_flash]
    jsr vera_flash
    // unsigned long vera_flashed = vera_flash()
    // [1466] vera_flash::return#3 = vera_flash::return#2
    // main_vera_flash::@39
    // [1467] main_vera_flash::vera_flashed#0 = vera_flash::return#3 -- vdum1=vdum2 
    lda vera_flash.return
    sta vera_flashed
    lda vera_flash.return+1
    sta vera_flashed+1
    lda vera_flash.return+2
    sta vera_flashed+2
    lda vera_flash.return+3
    sta vera_flashed+3
    // if(vera_flashed)
    // [1468] if(0!=main_vera_flash::vera_flashed#0) goto main_vera_flash::@12 -- 0_neq_vdum1_then_la1 
    lda vera_flashed
    ora vera_flashed+1
    ora vera_flashed+2
    ora vera_flashed+3
    beq !__b12+
    jmp __b12
  !__b12:
    // main_vera_flash::@13
    // [1469] spi_manufacturer#586 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1470] spi_memory_type#587 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1471] spi_memory_capacity#588 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_ERROR, info_text)
    // [1472] call display_info_vera
  // VFL2 | Flash VERA resulting in errors
    // [998] phi from main_vera_flash::@13 to display_info_vera [phi:main_vera_flash::@13->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@13->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#588 [phi:main_vera_flash::@13->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#587 [phi:main_vera_flash::@13->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#586 [phi:main_vera_flash::@13->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_ERROR [phi:main_vera_flash::@13->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1473] phi from main_vera_flash::@13 to main_vera_flash::@54 [phi:main_vera_flash::@13->main_vera_flash::@54]
    // main_vera_flash::@54
    // display_action_progress("There was an error updating your VERA flash memory!")
    // [1474] call display_action_progress
    // [904] phi from main_vera_flash::@54 to display_action_progress [phi:main_vera_flash::@54->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main_vera_flash::info_text10 [phi:main_vera_flash::@54->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1475] phi from main_vera_flash::@54 to main_vera_flash::@55 [phi:main_vera_flash::@54->main_vera_flash::@55]
    // main_vera_flash::@55
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [1476] call display_action_text
    // [1358] phi from main_vera_flash::@55 to display_action_text [phi:main_vera_flash::@55->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main_vera_flash::info_text8 [phi:main_vera_flash::@55->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_text.info_text
    lda #>info_text8
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main_vera_flash::@56
    // [1477] spi_manufacturer#595 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1478] spi_memory_type#596 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1479] spi_memory_capacity#597 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_ERROR, "FLASH ERROR!")
    // [1480] call display_info_vera
    // [998] phi from main_vera_flash::@56 to display_info_vera [phi:main_vera_flash::@56->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = main_vera_flash::info_text12 [phi:main_vera_flash::@56->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_vera.info_text
    lda #>info_text12
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#597 [phi:main_vera_flash::@56->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#596 [phi:main_vera_flash::@56->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#595 [phi:main_vera_flash::@56->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_ERROR [phi:main_vera_flash::@56->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@57
    // [1481] smc_bootloader#518 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, NULL)
    // [1482] call display_info_smc
    // [962] phi from main_vera_flash::@57 to display_info_smc [phi:main_vera_flash::@57->display_info_smc]
    // [962] phi display_info_smc::info_text#20 = 0 [phi:main_vera_flash::@57->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [962] phi smc_bootloader#14 = smc_bootloader#518 [phi:main_vera_flash::@57->display_info_smc#1] -- register_copy 
    // [962] phi display_info_smc::info_status#20 = STATUS_ERROR [phi:main_vera_flash::@57->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    // [1483] phi from main_vera_flash::@57 to main_vera_flash::@58 [phi:main_vera_flash::@57->main_vera_flash::@58]
    // main_vera_flash::@58
    // display_info_roms(STATUS_ERROR, NULL)
    // [1484] call display_info_roms
    // [2835] phi from main_vera_flash::@58 to display_info_roms [phi:main_vera_flash::@58->display_info_roms]
    jsr display_info_roms
    // [1485] phi from main_vera_flash::@58 to main_vera_flash::@59 [phi:main_vera_flash::@58->main_vera_flash::@59]
    // main_vera_flash::@59
    // wait_moment(32)
    // [1486] call wait_moment
    // [1310] phi from main_vera_flash::@59 to wait_moment [phi:main_vera_flash::@59->wait_moment]
    // [1310] phi wait_moment::w#13 = $20 [phi:main_vera_flash::@59->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [1487] phi from main_vera_flash::@59 to main_vera_flash::@60 [phi:main_vera_flash::@59->main_vera_flash::@60]
    // main_vera_flash::@60
    // spi_deselect()
    // [1488] call spi_deselect
    jsr spi_deselect
    rts
    // [1489] phi from main_vera_flash::@39 to main_vera_flash::@12 [phi:main_vera_flash::@39->main_vera_flash::@12]
    // main_vera_flash::@12
  __b12:
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1490] call snprintf_init
    // [1205] phi from main_vera_flash::@12 to snprintf_init [phi:main_vera_flash::@12->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main_vera_flash::@12->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@46
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1491] printf_ulong::uvalue#11 = main_vera_flash::vera_flashed#0 -- vdum1=vdum2 
    lda vera_flashed
    sta printf_ulong.uvalue
    lda vera_flashed+1
    sta printf_ulong.uvalue+1
    lda vera_flashed+2
    sta printf_ulong.uvalue+2
    lda vera_flashed+3
    sta printf_ulong.uvalue+3
    // [1492] call printf_ulong
    // [1761] phi from main_vera_flash::@46 to printf_ulong [phi:main_vera_flash::@46->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 0 [phi:main_vera_flash::@46->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 0 [phi:main_vera_flash::@46->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@46->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#11 [phi:main_vera_flash::@46->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1493] phi from main_vera_flash::@46 to main_vera_flash::@47 [phi:main_vera_flash::@46->main_vera_flash::@47]
    // main_vera_flash::@47
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1494] call printf_str
    // [1210] phi from main_vera_flash::@47 to printf_str [phi:main_vera_flash::@47->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main_vera_flash::@47->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = main_vera_flash::s2 [phi:main_vera_flash::@47->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@48
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [1495] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1496] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1498] spi_manufacturer#592 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1499] spi_memory_type#593 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1500] spi_memory_capacity#594 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHED, info_text)
    // [1501] call display_info_vera
    // [998] phi from main_vera_flash::@48 to display_info_vera [phi:main_vera_flash::@48->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@48->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#594 [phi:main_vera_flash::@48->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#593 [phi:main_vera_flash::@48->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#592 [phi:main_vera_flash::@48->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_FLASHED [phi:main_vera_flash::@48->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1502] phi from main_vera_flash::@48 to main_vera_flash::@49 [phi:main_vera_flash::@48->main_vera_flash::@49]
    // main_vera_flash::@49
    // unsigned long vera_differences = vera_verify()
    // [1503] call vera_verify
    // [2757] phi from main_vera_flash::@49 to vera_verify [phi:main_vera_flash::@49->vera_verify]
    jsr vera_verify
    // unsigned long vera_differences = vera_verify()
    // [1504] vera_verify::return#3 = vera_verify::vera_different_bytes#11
    // main_vera_flash::@50
    // [1505] main_vera_flash::vera_differences1#0 = vera_verify::return#3 -- vduz1=vdum2 
    lda vera_verify.return
    sta.z vera_differences1
    lda vera_verify.return+1
    sta.z vera_differences1+1
    lda vera_verify.return+2
    sta.z vera_differences1+2
    lda vera_verify.return+3
    sta.z vera_differences1+3
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1506] call snprintf_init
    // [1205] phi from main_vera_flash::@50 to snprintf_init [phi:main_vera_flash::@50->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:main_vera_flash::@50->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@51
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1507] printf_ulong::uvalue#12 = main_vera_flash::vera_differences1#0 -- vdum1=vduz2 
    lda.z vera_differences1
    sta printf_ulong.uvalue
    lda.z vera_differences1+1
    sta printf_ulong.uvalue+1
    lda.z vera_differences1+2
    sta printf_ulong.uvalue+2
    lda.z vera_differences1+3
    sta printf_ulong.uvalue+3
    // [1508] call printf_ulong
    // [1761] phi from main_vera_flash::@51 to printf_ulong [phi:main_vera_flash::@51->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:main_vera_flash::@51->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:main_vera_flash::@51->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:main_vera_flash::@51->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#12 [phi:main_vera_flash::@51->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1509] phi from main_vera_flash::@51 to main_vera_flash::@52 [phi:main_vera_flash::@51->main_vera_flash::@52]
    // main_vera_flash::@52
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1510] call printf_str
    // [1210] phi from main_vera_flash::@52 to printf_str [phi:main_vera_flash::@52->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:main_vera_flash::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s13 [phi:main_vera_flash::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@53
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [1511] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1512] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1514] spi_manufacturer#593 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1515] spi_memory_type#594 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1516] spi_memory_capacity#595 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHED, info_text)
    // [1517] call display_info_vera
    // [998] phi from main_vera_flash::@53 to display_info_vera [phi:main_vera_flash::@53->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@53->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#595 [phi:main_vera_flash::@53->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#594 [phi:main_vera_flash::@53->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#593 [phi:main_vera_flash::@53->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_FLASHED [phi:main_vera_flash::@53->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1518] phi from main_vera_flash::@10 main_vera_flash::@53 to main_vera_flash::@14 [phi:main_vera_flash::@10/main_vera_flash::@53->main_vera_flash::@14]
    // main_vera_flash::@14
  __b14:
    // display_action_progress("VERA SPI de-activation ...")
    // [1519] call display_action_progress
  // Now we loop until jumper JP1 is open again!
    // [904] phi from main_vera_flash::@14 to display_action_progress [phi:main_vera_flash::@14->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = main_vera_flash::info_text13 [phi:main_vera_flash::@14->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1520] phi from main_vera_flash::@14 to main_vera_flash::@61 [phi:main_vera_flash::@14->main_vera_flash::@61]
    // main_vera_flash::@61
    // display_action_text("Please OPEN the jumper JP1 on the VERA board!")
    // [1521] call display_action_text
    // [1358] phi from main_vera_flash::@61 to display_action_text [phi:main_vera_flash::@61->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main_vera_flash::info_text14 [phi:main_vera_flash::@61->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_action_text.info_text
    lda #>info_text14
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1522] phi from main_vera_flash::@61 to main_vera_flash::@62 [phi:main_vera_flash::@61->main_vera_flash::@62]
    // main_vera_flash::@62
    // vera_detect()
    // [1523] call vera_detect
    // [2411] phi from main_vera_flash::@62 to vera_detect [phi:main_vera_flash::@62->vera_detect]
    jsr vera_detect
    // [1524] phi from main_vera_flash::@19 main_vera_flash::@62 to main_vera_flash::@15 [phi:main_vera_flash::@19/main_vera_flash::@62->main_vera_flash::@15]
  __b5:
    // [1524] phi main_vera_flash::spi_ensure_detect#12 = 0 [phi:main_vera_flash::@19/main_vera_flash::@62->main_vera_flash::@15#0] -- vbuz1=vbuc1 
    lda #0
    sta.z spi_ensure_detect_1
    // main_vera_flash::@15
  __b15:
    // while(spi_ensure_detect < 16)
    // [1525] if(main_vera_flash::spi_ensure_detect#12<$10) goto main_vera_flash::@16 -- vbuz1_lt_vbuc1_then_la1 
    lda.z spi_ensure_detect_1
    cmp #$10
    bcc __b16
    // [1526] phi from main_vera_flash::@15 to main_vera_flash::@17 [phi:main_vera_flash::@15->main_vera_flash::@17]
    // main_vera_flash::@17
    // display_action_text("The jumper JP1 has been opened on the VERA!")
    // [1527] call display_action_text
    // [1358] phi from main_vera_flash::@17 to display_action_text [phi:main_vera_flash::@17->display_action_text]
    // [1358] phi display_action_text::info_text#25 = main_vera_flash::info_text15 [phi:main_vera_flash::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_text.info_text
    lda #>info_text15
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1528] phi from main_vera_flash::@17 main_vera_flash::@24 to main_vera_flash::@1 [phi:main_vera_flash::@17/main_vera_flash::@24->main_vera_flash::@1]
    // main_vera_flash::@1
  __b1:
    // spi_deselect()
    // [1529] call spi_deselect
    jsr spi_deselect
    rts
    // [1530] phi from main_vera_flash::@15 to main_vera_flash::@16 [phi:main_vera_flash::@15->main_vera_flash::@16]
    // main_vera_flash::@16
  __b16:
    // vera_detect()
    // [1531] call vera_detect
    // [2411] phi from main_vera_flash::@16 to vera_detect [phi:main_vera_flash::@16->vera_detect]
    jsr vera_detect
    // [1532] phi from main_vera_flash::@16 to main_vera_flash::@63 [phi:main_vera_flash::@16->main_vera_flash::@63]
    // main_vera_flash::@63
    // wait_moment(1)
    // [1533] call wait_moment
    // [1310] phi from main_vera_flash::@63 to wait_moment [phi:main_vera_flash::@63->wait_moment]
    // [1310] phi wait_moment::w#13 = 1 [phi:main_vera_flash::@63->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // main_vera_flash::@64
    // if(spi_manufacturer != 0xEF && spi_memory_type != 0x40 && spi_memory_capacity != 0x15)
    // [1534] if(spi_read::return#0==$ef) goto main_vera_flash::@19 -- vbum1_eq_vbuc1_then_la1 
    lda #$ef
    cmp spi_read.return
    beq __b19
    // main_vera_flash::@69
    // [1535] if(spi_read::return#1==$40) goto main_vera_flash::@19 -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp spi_read.return_1
    beq __b19
    // main_vera_flash::@68
    // [1536] if(spi_read::return#10!=$15) goto main_vera_flash::@18 -- vbum1_neq_vbuc1_then_la1 
    lda #$15
    cmp spi_read.return_3
    bne __b18
    // main_vera_flash::@19
  __b19:
    // [1537] spi_manufacturer#588 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1538] spi_memory_type#589 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1539] spi_memory_capacity#590 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_WAITING, NULL)
    // [1540] call display_info_vera
    // [998] phi from main_vera_flash::@19 to display_info_vera [phi:main_vera_flash::@19->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@19->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#590 [phi:main_vera_flash::@19->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#589 [phi:main_vera_flash::@19->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#588 [phi:main_vera_flash::@19->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_WAITING [phi:main_vera_flash::@19->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_WAITING
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b5
    // main_vera_flash::@18
  __b18:
    // [1541] spi_manufacturer#587 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1542] spi_memory_type#588 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1543] spi_memory_capacity#589 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, NULL)
    // [1544] call display_info_vera
    // [998] phi from main_vera_flash::@18 to display_info_vera [phi:main_vera_flash::@18->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@18->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#589 [phi:main_vera_flash::@18->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#588 [phi:main_vera_flash::@18->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#587 [phi:main_vera_flash::@18->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_flash::@18->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@65
    // spi_ensure_detect++;
    // [1545] main_vera_flash::spi_ensure_detect#4 = ++ main_vera_flash::spi_ensure_detect#12 -- vbuz1=_inc_vbuz1 
    inc.z spi_ensure_detect_1
    // [1524] phi from main_vera_flash::@65 to main_vera_flash::@15 [phi:main_vera_flash::@65->main_vera_flash::@15]
    // [1524] phi main_vera_flash::spi_ensure_detect#12 = main_vera_flash::spi_ensure_detect#4 [phi:main_vera_flash::@65->main_vera_flash::@15#0] -- register_copy 
    jmp __b15
    // main_vera_flash::@10
  __b10:
    // [1546] spi_manufacturer#585 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1547] spi_memory_type#586 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1548] spi_memory_capacity#587 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "No update required")
    // [1549] call display_info_vera
  // VFL1 | VERA and VERA.BIN equal | Display that there are no differences between the VERA and VERA.BIN. Set VERA to Flashed. | None
    // [998] phi from main_vera_flash::@10 to display_info_vera [phi:main_vera_flash::@10->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = info_text6 [phi:main_vera_flash::@10->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_vera.info_text
    lda #>info_text6
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#587 [phi:main_vera_flash::@10->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#586 [phi:main_vera_flash::@10->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#585 [phi:main_vera_flash::@10->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main_vera_flash::@10->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b14
    // [1550] phi from main_vera_flash::@3 to main_vera_flash::@4 [phi:main_vera_flash::@3->main_vera_flash::@4]
    // main_vera_flash::@4
  __b4:
    // vera_detect()
    // [1551] call vera_detect
    // [2411] phi from main_vera_flash::@4 to vera_detect [phi:main_vera_flash::@4->vera_detect]
    jsr vera_detect
    // [1552] phi from main_vera_flash::@4 to main_vera_flash::@27 [phi:main_vera_flash::@4->main_vera_flash::@27]
    // main_vera_flash::@27
    // wait_moment(1)
    // [1553] call wait_moment
    // [1310] phi from main_vera_flash::@27 to wait_moment [phi:main_vera_flash::@27->wait_moment]
    // [1310] phi wait_moment::w#13 = 1 [phi:main_vera_flash::@27->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // main_vera_flash::@28
    // if(spi_manufacturer == 0xEF && spi_memory_type == 0x40 && spi_memory_capacity == 0x15)
    // [1554] if(spi_read::return#0!=$ef) goto main_vera_flash::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #$ef
    cmp spi_read.return
    bne __b7
    // main_vera_flash::@67
    // [1555] if(spi_read::return#1!=$40) goto main_vera_flash::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #$40
    cmp spi_read.return_1
    bne __b7
    // main_vera_flash::@66
    // [1556] if(spi_read::return#10==$15) goto main_vera_flash::@6 -- vbum1_eq_vbuc1_then_la1 
    lda #$15
    cmp spi_read.return_3
    beq __b6
    // main_vera_flash::@7
  __b7:
    // [1557] spi_manufacturer#596 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1558] spi_memory_type#597 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1559] spi_memory_capacity#598 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_WAITING, "Close JP1 jumper pins!")
    // [1560] call display_info_vera
    // [998] phi from main_vera_flash::@7 to display_info_vera [phi:main_vera_flash::@7->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = main_vera_flash::info_text5 [phi:main_vera_flash::@7->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_vera.info_text
    lda #>info_text5
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#598 [phi:main_vera_flash::@7->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#597 [phi:main_vera_flash::@7->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#596 [phi:main_vera_flash::@7->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_WAITING [phi:main_vera_flash::@7->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_WAITING
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b2
    // main_vera_flash::@6
  __b6:
    // [1561] spi_manufacturer#594 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1562] spi_memory_type#595 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1563] spi_memory_capacity#596 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, "JP1 jumper pins closed!")
    // [1564] call display_info_vera
    // [998] phi from main_vera_flash::@6 to display_info_vera [phi:main_vera_flash::@6->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = main_vera_flash::info_text4 [phi:main_vera_flash::@6->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_vera.info_text
    lda #>info_text4
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#596 [phi:main_vera_flash::@6->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#595 [phi:main_vera_flash::@6->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#594 [phi:main_vera_flash::@6->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_flash::@6->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@33
    // spi_ensure_detect++;
    // [1565] main_vera_flash::spi_ensure_detect#1 = ++ main_vera_flash::spi_ensure_detect#11 -- vbuz1=_inc_vbuz1 
    inc.z spi_ensure_detect
    // [1414] phi from main_vera_flash::@33 to main_vera_flash::@3 [phi:main_vera_flash::@33->main_vera_flash::@3]
    // [1414] phi main_vera_flash::spi_ensure_detect#11 = main_vera_flash::spi_ensure_detect#1 [phi:main_vera_flash::@33->main_vera_flash::@3#0] -- register_copy 
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
// void display_info_rom(__mem() char rom_chip, __mem() char info_status, __zp($3f) char *info_text)
display_info_rom: {
    .label display_info_rom__6 = $6a
    .label display_info_rom__15 = $7d
    .label display_info_rom__16 = $41
    .label info_text = $3f
    .label display_info_rom__19 = $6a
    .label display_info_rom__20 = $6a
    // unsigned char x = wherex()
    // [1567] call wherex
    jsr wherex
    // [1568] wherex::return#12 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_4
    // display_info_rom::@3
    // [1569] display_info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1570] call wherey
    jsr wherey
    // [1571] wherey::return#12 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_4
    // display_info_rom::@4
    // [1572] display_info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1573] status_rom[display_info_rom::rom_chip#17] = display_info_rom::info_status#17 -- pbuc1_derefidx_vbum1=vbum2 
    lda info_status
    ldy rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1574] display_rom_led::chip#1 = display_info_rom::rom_chip#17 -- vbum1=vbum2 
    tya
    sta display_rom_led.chip
    // [1575] display_rom_led::c#1 = status_color[display_info_rom::info_status#17] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_rom_led.c
    // [1576] call display_rom_led
    // [2389] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [2389] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [2389] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1577] gotoxy::y#23 = display_info_rom::rom_chip#17 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1578] call gotoxy
    // [802] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#23 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1579] display_info_rom::$16 = display_info_rom::rom_chip#17 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z display_info_rom__16
    // rom_chip*13
    // [1580] display_info_rom::$19 = display_info_rom::$16 + display_info_rom::rom_chip#17 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z display_info_rom__16
    sta.z display_info_rom__19
    // [1581] display_info_rom::$20 = display_info_rom::$19 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z display_info_rom__20
    asl
    asl
    sta.z display_info_rom__20
    // [1582] display_info_rom::$6 = display_info_rom::$20 + display_info_rom::rom_chip#17 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z display_info_rom__6
    sta.z display_info_rom__6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1583] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta.z printf_string.str_1+1
    // [1584] call printf_str
    // [1210] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = chip [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z printf_str.s
    lda #>chip
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1585] printf_uchar::uvalue#4 = display_info_rom::rom_chip#17 -- vbum1=vbum2 
    lda rom_chip
    sta printf_uchar.uvalue
    // [1586] call printf_uchar
    // [1347] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#4 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1587] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1588] call printf_str
    // [1210] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1589] display_info_rom::$15 = display_info_rom::info_status#17 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_rom__15
    // [1590] printf_string::str#8 = status_text[display_info_rom::$15] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1591] call printf_string
    // [1219] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1592] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1593] call printf_str
    // [1210] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1594] printf_string::str#9 = rom_device_names[display_info_rom::$16] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__16
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1595] call printf_string
    // [1219] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1596] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1597] call printf_str
    // [1210] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1598] printf_string::str#41 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z printf_string.str_1
    sta.z printf_string.str
    lda.z printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1599] call printf_string
    // [1219] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#41 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = $d [phi:display_info_rom::@13->printf_string#3] -- vbum1=vbuc1 
    lda #$d
    sta printf_string.format_min_length
    jsr printf_string
    // [1600] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1601] call printf_str
    // [1210] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1602] if((char *)0==display_info_rom::info_text#17) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // gotoxy(INFO_X+64-28, INFO_Y+rom_chip+2)
    // [1603] gotoxy::y#25 = display_info_rom::rom_chip#17 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1604] call gotoxy
    // [802] phi from display_info_rom::@2 to gotoxy [phi:display_info_rom::@2->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#25 [phi:display_info_rom::@2->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_rom::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@16
    // printf("%-25s", info_text)
    // [1605] printf_string::str#11 = display_info_rom::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1606] call printf_string
    // [1219] phi from display_info_rom::@16 to printf_string [phi:display_info_rom::@16->printf_string]
    // [1219] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#11 [phi:display_info_rom::@16->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = $19 [phi:display_info_rom::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1607] gotoxy::x#24 = display_info_rom::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1608] gotoxy::y#24 = display_info_rom::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1609] call gotoxy
    // [802] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#24 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#24 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1610] return 
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
    // [1612] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbum1_then_la1 
    lda rom_chip
    bne __b1
    // [1615] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1615] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_cx16
    sta.z return
    lda #>file_rom_cx16
    sta.z return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1613] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #'0'
    clc
    adc rom_chip
    sta.z rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1614] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuz1 
    sta file_rom_card+3
    // [1615] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1615] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_card
    sta.z return
    lda #>file_rom_card
    sta.z return+1
    // rom_file::@return
    // }
    // [1616] return 
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
// __mem() unsigned long rom_read(__mem() char rom_chip, __zp($56) char *file, __mem() char info_status, __mem() char brom_bank_start, __mem() unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__13 = $77
    .label rom_read__24 = $6a
    .label fp = $bc
    .label rom_bram_ptr = $2d
    .label file = $56
    .label rom_action_text = $54
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1618] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1619] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_read::@23
    // if(info_status == STATUS_READING)
    // [1620] if(rom_read::info_status#11==STATUS_READING) goto rom_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [1622] phi from rom_read::@23 to rom_read::@2 [phi:rom_read::@23->rom_read::@2]
    // [1622] phi rom_read::rom_action_text#10 = smc_action_text#2 [phi:rom_read::@23->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z rom_action_text
    lda #>smc_action_text_1
    sta.z rom_action_text+1
    jmp __b2
    // [1621] phi from rom_read::@23 to rom_read::@1 [phi:rom_read::@23->rom_read::@1]
    // rom_read::@1
  __b1:
    // [1622] phi from rom_read::@1 to rom_read::@2 [phi:rom_read::@1->rom_read::@2]
    // [1622] phi rom_read::rom_action_text#10 = smc_action_text#1 [phi:rom_read::@1->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z rom_action_text
    lda #>smc_action_text
    sta.z rom_action_text+1
    // rom_read::@2
  __b2:
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1623] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#10 -- vbum1=vbum2 
    lda brom_bank_start
    sta rom_address_from_bank.rom_bank
    // [1624] call rom_address_from_bank
    // [2905] phi from rom_read::@2 to rom_address_from_bank [phi:rom_read::@2->rom_address_from_bank]
    // [2905] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read::@2->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1625] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@25
    // [1626] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1627] call snprintf_init
    // [1205] phi from rom_read::@25 to snprintf_init [phi:rom_read::@25->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:rom_read::@25->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1628] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1629] call printf_str
    // [1210] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = rom_read::s [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1630] printf_string::str#17 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1631] call printf_string
    // [1219] phi from rom_read::@27 to printf_string [phi:rom_read::@27->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:rom_read::@27->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#17 [phi:rom_read::@27->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:rom_read::@27->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:rom_read::@27->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1632] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1633] call printf_str
    // [1210] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = rom_read::s1 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1634] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1635] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1637] call display_action_text
    // [1358] phi from rom_read::@29 to display_action_text [phi:rom_read::@29->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:rom_read::@29->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@30
    // FILE *fp = fopen(file, "r")
    // [1638] fopen::path#4 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1639] call fopen
    // [2436] phi from rom_read::@30 to fopen [phi:rom_read::@30->fopen]
    // [2436] phi __errno#473 = __errno#105 [phi:rom_read::@30->fopen#0] -- register_copy 
    // [2436] phi fopen::pathtoken#0 = fopen::path#4 [phi:rom_read::@30->fopen#1] -- register_copy 
    // [2436] phi __stdio_filecount#27 = __stdio_filecount#100 [phi:rom_read::@30->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1640] fopen::return#5 = fopen::return#2
    // rom_read::@31
    // [1641] rom_read::fp#0 = fopen::return#5 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1642] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [1643] phi from rom_read::@31 to rom_read::@4 [phi:rom_read::@31->rom_read::@4]
    // rom_read::@4
    // gotoxy(x, y)
    // [1644] call gotoxy
    // [802] phi from rom_read::@4 to gotoxy [phi:rom_read::@4->gotoxy]
    // [802] phi gotoxy::y#37 = PROGRESS_Y [phi:rom_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:rom_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1645] phi from rom_read::@4 to rom_read::@5 [phi:rom_read::@4->rom_read::@5]
    // [1645] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@4->rom_read::@5#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1645] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@4->rom_read::@5#1] -- vwum1=vwuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1645] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#10 [phi:rom_read::@4->rom_read::@5#2] -- register_copy 
    // [1645] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@4->rom_read::@5#3] -- register_copy 
    // [1645] phi rom_read::rom_bram_ptr#13 = (char *)$7800 [phi:rom_read::@4->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1645] phi rom_read::rom_bram_bank#10 = 0 [phi:rom_read::@4->rom_read::@5#5] -- vbum1=vbuc1 
    lda #0
    sta rom_bram_bank
    // [1645] phi rom_read::rom_file_size#13 = 0 [phi:rom_read::@4->rom_read::@5#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@5
  __b5:
    // while (rom_file_size < rom_size)
    // [1646] if(rom_read::rom_file_size#13<rom_read::rom_size#12) goto rom_read::@6 -- vdum1_lt_vdum2_then_la1 
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
    // [1647] fclose::stream#2 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [1648] call fclose
    // [2571] phi from rom_read::@10 to fclose [phi:rom_read::@10->fclose]
    // [2571] phi fclose::stream#3 = fclose::stream#2 [phi:rom_read::@10->fclose#0] -- register_copy 
    jsr fclose
    // [1649] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1649] phi __stdio_filecount#12 = __stdio_filecount#2 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1649] phi rom_read::return#0 = rom_read::rom_file_size#13 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    rts
    // [1649] phi from rom_read::@31 to rom_read::@3 [phi:rom_read::@31->rom_read::@3]
  __b4:
    // [1649] phi __stdio_filecount#12 = __stdio_filecount#1 [phi:rom_read::@31->rom_read::@3#0] -- register_copy 
    // [1649] phi rom_read::return#0 = 0 [phi:rom_read::@31->rom_read::@3#1] -- vdum1=vduc1 
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
    // [1650] return 
    rts
    // rom_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [1651] if(rom_read::info_status#11!=STATUS_CHECKING) goto rom_read::@35 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b7
    // [1653] phi from rom_read::@6 to rom_read::@7 [phi:rom_read::@6->rom_read::@7]
    // [1653] phi rom_read::rom_bram_ptr#10 = (char *) 1024 [phi:rom_read::@6->rom_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z rom_bram_ptr
    lda #>$400
    sta.z rom_bram_ptr+1
    // [1652] phi from rom_read::@6 to rom_read::@35 [phi:rom_read::@6->rom_read::@35]
    // rom_read::@35
    // [1653] phi from rom_read::@35 to rom_read::@7 [phi:rom_read::@35->rom_read::@7]
    // [1653] phi rom_read::rom_bram_ptr#10 = rom_read::rom_bram_ptr#13 [phi:rom_read::@35->rom_read::@7#0] -- register_copy 
    // rom_read::@7
  __b7:
    // display_action_text_reading(rom_action_text, file, rom_file_size, rom_size, rom_bram_bank, rom_bram_ptr)
    // [1654] display_action_text_reading::action#2 = rom_read::rom_action_text#10 -- pbuz1=pbuz2 
    lda.z rom_action_text
    sta.z display_action_text_reading.action
    lda.z rom_action_text+1
    sta.z display_action_text_reading.action+1
    // [1655] display_action_text_reading::file#2 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z display_action_text_reading.file
    lda.z file+1
    sta.z display_action_text_reading.file+1
    // [1656] display_action_text_reading::bytes#2 = rom_read::rom_file_size#13 -- vdum1=vdum2 
    lda rom_file_size
    sta display_action_text_reading.bytes
    lda rom_file_size+1
    sta display_action_text_reading.bytes+1
    lda rom_file_size+2
    sta display_action_text_reading.bytes+2
    lda rom_file_size+3
    sta display_action_text_reading.bytes+3
    // [1657] display_action_text_reading::size#2 = rom_read::rom_size#12 -- vdum1=vdum2 
    lda rom_size
    sta display_action_text_reading.size
    lda rom_size+1
    sta display_action_text_reading.size+1
    lda rom_size+2
    sta display_action_text_reading.size+2
    lda rom_size+3
    sta display_action_text_reading.size+3
    // [1658] display_action_text_reading::bram_bank#2 = rom_read::rom_bram_bank#10 -- vbum1=vbum2 
    lda rom_bram_bank
    sta display_action_text_reading.bram_bank
    // [1659] display_action_text_reading::bram_ptr#2 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z rom_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1660] call display_action_text_reading
    // [2600] phi from rom_read::@7 to display_action_text_reading [phi:rom_read::@7->display_action_text_reading]
    // [2600] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#2 [phi:rom_read::@7->display_action_text_reading#0] -- register_copy 
    // [2600] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#2 [phi:rom_read::@7->display_action_text_reading#1] -- register_copy 
    // [2600] phi display_action_text_reading::size#10 = display_action_text_reading::size#2 [phi:rom_read::@7->display_action_text_reading#2] -- register_copy 
    // [2600] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#2 [phi:rom_read::@7->display_action_text_reading#3] -- register_copy 
    // [2600] phi display_action_text_reading::file#3 = display_action_text_reading::file#2 [phi:rom_read::@7->display_action_text_reading#4] -- register_copy 
    // [2600] phi display_action_text_reading::action#3 = display_action_text_reading::action#2 [phi:rom_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // rom_read::@32
    // rom_address % 0x04000
    // [1661] rom_read::$13 = rom_read::rom_address#10 & $4000-1 -- vduz1=vdum2_band_vduc1 
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
    // [1662] if(0!=rom_read::$13) goto rom_read::@8 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__13
    ora.z rom_read__13+1
    ora.z rom_read__13+2
    ora.z rom_read__13+3
    bne __b8
    // rom_read::@17
    // brom_bank_start++;
    // [1663] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#11 -- vbum1=_inc_vbum1 
    inc brom_bank_start
    // [1664] phi from rom_read::@17 rom_read::@32 to rom_read::@8 [phi:rom_read::@17/rom_read::@32->rom_read::@8]
    // [1664] phi rom_read::brom_bank_start#16 = rom_read::brom_bank_start#0 [phi:rom_read::@17/rom_read::@32->rom_read::@8#0] -- register_copy 
    // rom_read::@8
  __b8:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1665] BRAM = rom_read::rom_bram_bank#10 -- vbuz1=vbum2 
    lda rom_bram_bank
    sta.z BRAM
    // rom_read::@24
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1666] fgets::ptr#5 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z fgets.ptr
    lda.z rom_bram_ptr+1
    sta.z fgets.ptr+1
    // [1667] fgets::stream#3 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1668] call fgets
    // [2517] phi from rom_read::@24 to fgets [phi:rom_read::@24->fgets]
    // [2517] phi fgets::ptr#14 = fgets::ptr#5 [phi:rom_read::@24->fgets#0] -- register_copy 
    // [2517] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@24->fgets#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta fgets.size
    lda #>ROM_PROGRESS_CELL
    sta fgets.size+1
    // [2517] phi fgets::stream#4 = fgets::stream#3 [phi:rom_read::@24->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1669] fgets::return#13 = fgets::return#1
    // rom_read::@33
    // [1670] rom_read::rom_package_read#0 = fgets::return#13 -- vwum1=vwum2 
    lda fgets.return
    sta rom_package_read
    lda fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1671] if(0!=rom_read::rom_package_read#0) goto rom_read::@9 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b9
    jmp __b10
    // rom_read::@9
  __b9:
    // if(info_status == STATUS_CHECKING)
    // [1672] if(rom_read::info_status#11!=STATUS_CHECKING) goto rom_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b11
    // rom_read::@18
    // if(rom_file_size == 0x0)
    // [1673] if(rom_read::rom_file_size#13!=0) goto rom_read::@12 -- vdum1_neq_0_then_la1 
    lda rom_file_size
    ora rom_file_size+1
    ora rom_file_size+2
    ora rom_file_size+3
    bne __b12
    // rom_read::@19
    // rom_chip*8
    // [1674] rom_read::$24 = rom_read::rom_chip#20 << 3 -- vbuz1=vbum2_rol_3 
    lda rom_chip
    asl
    asl
    asl
    sta.z rom_read__24
    // rom_get_github_commit_id(&rom_file_github[rom_chip*8], (char*)0x0400)
    // [1675] rom_get_github_commit_id::commit_id#0 = rom_file_github + rom_read::$24 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_file_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_file_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [1676] call rom_get_github_commit_id
    // [2089] phi from rom_read::@19 to rom_get_github_commit_id [phi:rom_read::@19->rom_get_github_commit_id]
    // [2089] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#0 [phi:rom_read::@19->rom_get_github_commit_id#0] -- register_copy 
    // [2089] phi rom_get_github_commit_id::from#6 = (char *) 1024 [phi:rom_read::@19->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$400
    sta.z rom_get_github_commit_id.from
    lda #>$400
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // rom_read::@12
  __b12:
    // if(rom_file_size == 0xFE00)
    // [1677] if(rom_read::rom_file_size#13!=$fe00) goto rom_read::@11 -- vdum1_neq_vduc1_then_la1 
    lda rom_file_size+3
    cmp #>$fe00>>$10
    bne __b11
    lda rom_file_size+2
    cmp #<$fe00>>$10
    bne __b11
    lda rom_file_size+1
    cmp #>$fe00
    bne __b11
    lda rom_file_size
    cmp #<$fe00
    bne __b11
    // rom_read::@13
    // rom_file_release[rom_chip] = *((char*)(0x0400+0x0180))
    // [1678] rom_file_release[rom_read::rom_chip#20] = *((char *)$400+$180) -- pbuc1_derefidx_vbum1=_deref_pbuc2 
    lda $400+$180
    ldy rom_chip
    sta rom_file_release,y
    // rom_read::@11
  __b11:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1679] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@14 -- vwum1_neq_vwuc1_then_la1 
    lda rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b14
    lda rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b14
    // rom_read::@20
    // gotoxy(x, ++y);
    // [1680] rom_read::y#1 = ++ rom_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1681] gotoxy::y#32 = rom_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1682] call gotoxy
    // [802] phi from rom_read::@20 to gotoxy [phi:rom_read::@20->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#32 [phi:rom_read::@20->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:rom_read::@20->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1683] phi from rom_read::@20 to rom_read::@14 [phi:rom_read::@20->rom_read::@14]
    // [1683] phi rom_read::y#33 = rom_read::y#1 [phi:rom_read::@20->rom_read::@14#0] -- register_copy 
    // [1683] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@20->rom_read::@14#1] -- vwum1=vbuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1683] phi from rom_read::@11 to rom_read::@14 [phi:rom_read::@11->rom_read::@14]
    // [1683] phi rom_read::y#33 = rom_read::y#11 [phi:rom_read::@11->rom_read::@14#0] -- register_copy 
    // [1683] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@11->rom_read::@14#1] -- register_copy 
    // rom_read::@14
  __b14:
    // if(info_status == STATUS_READING)
    // [1684] if(rom_read::info_status#11!=STATUS_READING) goto rom_read::@15 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b15
    // rom_read::@21
    // cputc('.')
    // [1685] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1686] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_read::@15
  __b15:
    // rom_bram_ptr += rom_package_read
    // [1688] rom_read::rom_bram_ptr#2 = rom_read::rom_bram_ptr#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z rom_bram_ptr
    adc rom_package_read
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc rom_package_read+1
    sta.z rom_bram_ptr+1
    // rom_address += rom_package_read
    // [1689] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1690] rom_read::rom_file_size#1 = rom_read::rom_file_size#13 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1691] rom_read::rom_row_current#2 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda rom_row_current
    adc rom_package_read
    sta rom_row_current
    lda rom_row_current+1
    adc rom_package_read+1
    sta rom_row_current+1
    // if (rom_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [1692] if(rom_read::rom_bram_ptr#2!=(char *)$c000) goto rom_read::@16 -- pbuz1_neq_pbuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b16
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b16
    // rom_read::@22
    // rom_bram_bank++;
    // [1693] rom_read::rom_bram_bank#1 = ++ rom_read::rom_bram_bank#10 -- vbum1=_inc_vbum1 
    inc rom_bram_bank
    // [1694] phi from rom_read::@22 to rom_read::@16 [phi:rom_read::@22->rom_read::@16]
    // [1694] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#1 [phi:rom_read::@22->rom_read::@16#0] -- register_copy 
    // [1694] phi rom_read::rom_bram_ptr#8 = (char *)$a000 [phi:rom_read::@22->rom_read::@16#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1694] phi from rom_read::@15 to rom_read::@16 [phi:rom_read::@15->rom_read::@16]
    // [1694] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#10 [phi:rom_read::@15->rom_read::@16#0] -- register_copy 
    // [1694] phi rom_read::rom_bram_ptr#8 = rom_read::rom_bram_ptr#2 [phi:rom_read::@15->rom_read::@16#1] -- register_copy 
    // rom_read::@16
  __b16:
    // if (rom_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [1695] if(rom_read::rom_bram_ptr#8!=(char *)$9800) goto rom_read::@34 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1645] phi from rom_read::@16 to rom_read::@5 [phi:rom_read::@16->rom_read::@5]
    // [1645] phi rom_read::y#11 = rom_read::y#33 [phi:rom_read::@16->rom_read::@5#0] -- register_copy 
    // [1645] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@16->rom_read::@5#1] -- register_copy 
    // [1645] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@16->rom_read::@5#2] -- register_copy 
    // [1645] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@16->rom_read::@5#3] -- register_copy 
    // [1645] phi rom_read::rom_bram_ptr#13 = (char *)$a000 [phi:rom_read::@16->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1645] phi rom_read::rom_bram_bank#10 = 1 [phi:rom_read::@16->rom_read::@5#5] -- vbum1=vbuc1 
    lda #1
    sta rom_bram_bank
    // [1645] phi rom_read::rom_file_size#13 = rom_read::rom_file_size#1 [phi:rom_read::@16->rom_read::@5#6] -- register_copy 
    jmp __b5
    // [1696] phi from rom_read::@16 to rom_read::@34 [phi:rom_read::@16->rom_read::@34]
    // rom_read::@34
    // [1645] phi from rom_read::@34 to rom_read::@5 [phi:rom_read::@34->rom_read::@5]
    // [1645] phi rom_read::y#11 = rom_read::y#33 [phi:rom_read::@34->rom_read::@5#0] -- register_copy 
    // [1645] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@34->rom_read::@5#1] -- register_copy 
    // [1645] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@34->rom_read::@5#2] -- register_copy 
    // [1645] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@34->rom_read::@5#3] -- register_copy 
    // [1645] phi rom_read::rom_bram_ptr#13 = rom_read::rom_bram_ptr#8 [phi:rom_read::@34->rom_read::@5#4] -- register_copy 
    // [1645] phi rom_read::rom_bram_bank#10 = rom_read::rom_bram_bank#14 [phi:rom_read::@34->rom_read::@5#5] -- register_copy 
    // [1645] phi rom_read::rom_file_size#13 = rom_read::rom_file_size#1 [phi:rom_read::@34->rom_read::@5#6] -- register_copy 
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
    /// Holds the amount of bytes actually read in the memory to be flashed.
    rom_row_current: .word 0
    // We start for ROM from 0x0:0x7800 !!!!
    rom_bram_bank: .byte 0
    rom_chip: .byte 0
    rom_size: .dword 0
    info_status: .byte 0
}
.segment Code
  // rom_verify
// __mem() unsigned long rom_verify(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__17 = $72
    .label rom_bram_ptr = $47
    // rom_verify::bank_set_bram1
    // BRAM = bank
    // [1698] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_verify::@11
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1699] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1700] call rom_address_from_bank
    // [2905] phi from rom_verify::@11 to rom_address_from_bank [phi:rom_verify::@11->rom_address_from_bank]
    // [2905] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify::@11->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1701] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_1
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_1+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_1+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_1+3
    // rom_verify::@12
    // [1702] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1703] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vdum2_plus_vdum1 
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
    // [1704] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1705] call display_info_rom
    // [1566] phi from rom_verify::@12 to display_info_rom [phi:rom_verify::@12->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = rom_verify::info_text [phi:rom_verify::@12->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#1 [phi:rom_verify::@12->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:rom_verify::@12->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1706] phi from rom_verify::@12 to rom_verify::@13 [phi:rom_verify::@12->rom_verify::@13]
    // rom_verify::@13
    // gotoxy(x, y)
    // [1707] call gotoxy
    // [802] phi from rom_verify::@13 to gotoxy [phi:rom_verify::@13->gotoxy]
    // [802] phi gotoxy::y#37 = PROGRESS_Y [phi:rom_verify::@13->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:rom_verify::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1708] phi from rom_verify::@13 to rom_verify::@1 [phi:rom_verify::@13->rom_verify::@1]
    // [1708] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@13->rom_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1708] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@13->rom_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1708] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@13->rom_verify::@1#2] -- vdum1=vduc1 
    sta rom_different_bytes
    sta rom_different_bytes+1
    lda #<0>>$10
    sta rom_different_bytes+2
    lda #>0>>$10
    sta rom_different_bytes+3
    // [1708] phi rom_verify::rom_bram_ptr#10 = (char *)$7800 [phi:rom_verify::@13->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1708] phi rom_verify::rom_bram_bank#11 = 0 [phi:rom_verify::@13->rom_verify::@1#4] -- vbum1=vbuc1 
    lda #0
    sta rom_bram_bank
    // [1708] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@13->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1709] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1710] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1711] rom_compare::bank_ram#0 = rom_verify::rom_bram_bank#11 -- vbum1=vbum2 
    lda rom_bram_bank
    sta rom_compare.bank_ram
    // [1712] rom_compare::ptr_ram#1 = rom_verify::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z rom_compare.ptr_ram
    lda.z rom_bram_ptr+1
    sta.z rom_compare.ptr_ram+1
    // [1713] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vdum1=vdum2 
    lda rom_address
    sta rom_compare.rom_compare_address
    lda rom_address+1
    sta rom_compare.rom_compare_address+1
    lda rom_address+2
    sta rom_compare.rom_compare_address+2
    lda rom_address+3
    sta rom_compare.rom_compare_address+3
    // [1714] call rom_compare
  // {asm{.byte $db}}
    // [2909] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2909] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2909] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size+1
    // [2909] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2909] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1715] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@14
    // [1716] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1717] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1718] rom_verify::y#1 = ++ rom_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1719] gotoxy::y#34 = rom_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1720] call gotoxy
    // [802] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#34 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1721] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1721] phi rom_verify::y#11 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1721] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1721] phi from rom_verify::@14 to rom_verify::@3 [phi:rom_verify::@14->rom_verify::@3]
    // [1721] phi rom_verify::y#11 = rom_verify::y#3 [phi:rom_verify::@14->rom_verify::@3#0] -- register_copy 
    // [1721] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@14->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1722] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwum1_neq_vwuc1_then_la1 
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
    // [1723] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1724] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // rom_bram_ptr += ROM_PROGRESS_CELL
    // [1726] rom_verify::rom_bram_ptr#1 = rom_verify::rom_bram_ptr#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z rom_bram_ptr
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc #>ROM_PROGRESS_CELL
    sta.z rom_bram_ptr+1
    // rom_address += ROM_PROGRESS_CELL
    // [1727] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
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
    // [1728] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwum1=vwum1_plus_vwuc1 
    lda progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta progress_row_current
    lda progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta progress_row_current+1
    // if (rom_bram_ptr == BRAM_HIGH)
    // [1729] if(rom_verify::rom_bram_ptr#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // rom_bram_bank++;
    // [1730] rom_verify::rom_bram_bank#1 = ++ rom_verify::rom_bram_bank#11 -- vbum1=_inc_vbum1 
    inc rom_bram_bank
    // [1731] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1731] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1731] phi rom_verify::rom_bram_ptr#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1731] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1731] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1731] phi rom_verify::rom_bram_ptr#6 = rom_verify::rom_bram_ptr#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (rom_bram_ptr == RAM_HIGH)
    // [1732] if(rom_verify::rom_bram_ptr#6!=$9800) goto rom_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$9800
    bne __b7
    lda.z rom_bram_ptr
    cmp #<$9800
    bne __b7
    // [1734] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1734] phi rom_verify::rom_bram_ptr#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1734] phi rom_verify::rom_bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta rom_bram_bank
    // [1733] phi from rom_verify::@6 to rom_verify::@24 [phi:rom_verify::@6->rom_verify::@24]
    // rom_verify::@24
    // [1734] phi from rom_verify::@24 to rom_verify::@7 [phi:rom_verify::@24->rom_verify::@7]
    // [1734] phi rom_verify::rom_bram_ptr#11 = rom_verify::rom_bram_ptr#6 [phi:rom_verify::@24->rom_verify::@7#0] -- register_copy 
    // [1734] phi rom_verify::rom_bram_bank#10 = rom_verify::rom_bram_bank#25 [phi:rom_verify::@24->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1735] rom_verify::$17 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<ROM_PROGRESS_CELL
    sbc equal_bytes
    sta.z rom_verify__17
    lda #>ROM_PROGRESS_CELL
    sbc equal_bytes+1
    sta.z rom_verify__17+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1736] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$17 -- vdum1=vdum1_plus_vwuz2 
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
    // [1737] call snprintf_init
    // [1205] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1738] phi from rom_verify::@7 to rom_verify::@15 [phi:rom_verify::@7->rom_verify::@15]
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1739] call printf_str
    // [1210] phi from rom_verify::@15 to printf_str [phi:rom_verify::@15->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:rom_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s [phi:rom_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1740] printf_ulong::uvalue#7 = rom_verify::rom_different_bytes#1 -- vdum1=vdum2 
    lda rom_different_bytes
    sta printf_ulong.uvalue
    lda rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1741] call printf_ulong
    // [1761] phi from rom_verify::@16 to printf_ulong [phi:rom_verify::@16->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:rom_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:rom_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:rom_verify::@16->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#7 [phi:rom_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1742] phi from rom_verify::@16 to rom_verify::@17 [phi:rom_verify::@16->rom_verify::@17]
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1743] call printf_str
    // [1210] phi from rom_verify::@17 to printf_str [phi:rom_verify::@17->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:rom_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s1 [phi:rom_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1744] printf_uchar::uvalue#15 = rom_verify::rom_bram_bank#10 -- vbum1=vbum2 
    lda rom_bram_bank
    sta printf_uchar.uvalue
    // [1745] call printf_uchar
    // [1347] phi from rom_verify::@18 to printf_uchar [phi:rom_verify::@18->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:rom_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 2 [phi:rom_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:rom_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:rom_verify::@18->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#15 [phi:rom_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1746] phi from rom_verify::@18 to rom_verify::@19 [phi:rom_verify::@18->rom_verify::@19]
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1747] call printf_str
    // [1210] phi from rom_verify::@19 to printf_str [phi:rom_verify::@19->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:rom_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s2 [phi:rom_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1748] printf_uint::uvalue#6 = (unsigned int)rom_verify::rom_bram_ptr#11 -- vwum1=vwuz2 
    lda.z rom_bram_ptr
    sta printf_uint.uvalue
    lda.z rom_bram_ptr+1
    sta printf_uint.uvalue+1
    // [1749] call printf_uint
    // [2106] phi from rom_verify::@20 to printf_uint [phi:rom_verify::@20->printf_uint]
    // [2106] phi printf_uint::format_zero_padding#10 = 1 [phi:rom_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2106] phi printf_uint::format_min_length#10 = 4 [phi:rom_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2106] phi printf_uint::putc#10 = &snputc [phi:rom_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2106] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:rom_verify::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2106] phi printf_uint::uvalue#10 = printf_uint::uvalue#6 [phi:rom_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1750] phi from rom_verify::@20 to rom_verify::@21 [phi:rom_verify::@20->rom_verify::@21]
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1751] call printf_str
    // [1210] phi from rom_verify::@21 to printf_str [phi:rom_verify::@21->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:rom_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s3 [phi:rom_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1752] printf_ulong::uvalue#8 = rom_verify::rom_address#1 -- vdum1=vdum2 
    lda rom_address
    sta printf_ulong.uvalue
    lda rom_address+1
    sta printf_ulong.uvalue+1
    lda rom_address+2
    sta printf_ulong.uvalue+2
    lda rom_address+3
    sta printf_ulong.uvalue+3
    // [1753] call printf_ulong
    // [1761] phi from rom_verify::@22 to printf_ulong [phi:rom_verify::@22->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:rom_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:rom_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:rom_verify::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#8 [phi:rom_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // rom_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1754] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1755] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1757] call display_action_text
    // [1358] phi from rom_verify::@23 to display_action_text [phi:rom_verify::@23->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:rom_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1708] phi from rom_verify::@23 to rom_verify::@1 [phi:rom_verify::@23->rom_verify::@1]
    // [1708] phi rom_verify::y#3 = rom_verify::y#11 [phi:rom_verify::@23->rom_verify::@1#0] -- register_copy 
    // [1708] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@23->rom_verify::@1#1] -- register_copy 
    // [1708] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@23->rom_verify::@1#2] -- register_copy 
    // [1708] phi rom_verify::rom_bram_ptr#10 = rom_verify::rom_bram_ptr#11 [phi:rom_verify::@23->rom_verify::@1#3] -- register_copy 
    // [1708] phi rom_verify::rom_bram_bank#11 = rom_verify::rom_bram_bank#10 [phi:rom_verify::@23->rom_verify::@1#4] -- register_copy 
    // [1708] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@23->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1758] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1759] callexecute cputc  -- call_vprc1 
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
    // [1762] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1763] ultoa::value#1 = printf_ulong::uvalue#15
    // [1764] ultoa::radix#0 = printf_ulong::format_radix#15
    // [1765] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1766] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1767] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#15
    // [1768] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#15
    // [1769] call printf_number_buffer
  // Print using format
    // [2726] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [2726] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [2726] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [2726] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [2726] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1770] return 
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
    .label rom_flash__29 = $77
    .label ram_address_sector = $a9
    .label ram_address = $5a
    // rom_flash::bank_set_bram1
    // BRAM = bank
    // [1772] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // [1773] phi from rom_flash::bank_set_bram1 to rom_flash::@19 [phi:rom_flash::bank_set_bram1->rom_flash::@19]
    // rom_flash::@19
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1774] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [904] phi from rom_flash::@19 to display_action_progress [phi:rom_flash::@19->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = string_0 [phi:rom_flash::@19->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<string_0
    sta.z display_action_progress.info_text
    lda #>string_0
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@20
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1775] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1776] call rom_address_from_bank
    // [2905] phi from rom_flash::@20 to rom_address_from_bank [phi:rom_flash::@20->rom_address_from_bank]
    // [2905] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@20->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1777] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@21
    // [1778] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1779] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1780] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1781] call display_info_rom
    // [1566] phi from rom_flash::@21 to display_info_rom [phi:rom_flash::@21->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = info_text1 [phi:rom_flash::@21->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#2 [phi:rom_flash::@21->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@21->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1782] phi from rom_flash::@21 to rom_flash::@1 [phi:rom_flash::@21->rom_flash::@1]
    // [1782] phi rom_flash::flash_errors#12 = 0 [phi:rom_flash::@21->rom_flash::@1#0] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1782] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@21->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1782] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@21->rom_flash::@1#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1782] phi rom_flash::ram_address_sector#11 = (char *)$7800 [phi:rom_flash::@21->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address_sector
    lda #>$7800
    sta.z ram_address_sector+1
    // [1782] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@21->rom_flash::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank_sector
    // [1782] phi rom_flash::rom_address_sector#13 = rom_flash::rom_address_sector#0 [phi:rom_flash::@21->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1783] if(rom_flash::rom_address_sector#13<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1784] display_action_text_flashed::bytes#2 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta display_action_text_flashed.bytes
    lda rom_address_sector+1
    sta display_action_text_flashed.bytes+1
    lda rom_address_sector+2
    sta display_action_text_flashed.bytes+2
    lda rom_address_sector+3
    sta display_action_text_flashed.bytes+3
    // [1785] call display_action_text_flashed
    // [2965] phi from rom_flash::@3 to display_action_text_flashed [phi:rom_flash::@3->display_action_text_flashed]
    // [2965] phi display_action_text_flashed::chip#3 = chip [phi:rom_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2965] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#2 [phi:rom_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1786] phi from rom_flash::@3 to rom_flash::@23 [phi:rom_flash::@3->rom_flash::@23]
    // rom_flash::@23
    // wait_moment(32)
    // [1787] call wait_moment
    // [1310] phi from rom_flash::@23 to wait_moment [phi:rom_flash::@23->wait_moment]
    // [1310] phi wait_moment::w#13 = $20 [phi:rom_flash::@23->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // rom_flash::@return
    // }
    // [1788] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1789] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_compare.bank_ram
    // [1790] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1791] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta rom_compare.rom_compare_address+3
    // [1792] call rom_compare
  // {asm{.byte $db}}
    // [2909] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2909] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2909] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwum1=vwuc1 
    lda #<$1000
    sta rom_compare.rom_compare_size
    lda #>$1000
    sta rom_compare.rom_compare_size+1
    // [2909] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2909] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1793] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@22
    // [1794] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1795] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwum1_neq_vwuc1_then_la1 
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
    // [1796] cputsxy::x#1 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta cputsxy.x
    // [1797] cputsxy::y#1 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputsxy.y
    // [1798] call cputsxy
    // [897] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [897] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [897] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [897] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1799] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1799] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1800] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1801] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#13 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1802] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1803] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbum1=_inc_vbum1 
    inc bram_bank_sector
    // [1804] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1804] phi rom_flash::bram_bank_sector#40 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1804] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1804] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1804] phi rom_flash::bram_bank_sector#40 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1804] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1805] if(rom_flash::ram_address_sector#8!=$9800) goto rom_flash::@36 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$9800
    bne __b14
    lda.z ram_address_sector
    cmp #<$9800
    bne __b14
    // [1807] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1807] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1807] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank_sector
    // [1806] phi from rom_flash::@13 to rom_flash::@36 [phi:rom_flash::@13->rom_flash::@36]
    // rom_flash::@36
    // [1807] phi from rom_flash::@36 to rom_flash::@14 [phi:rom_flash::@36->rom_flash::@14]
    // [1807] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@36->rom_flash::@14#0] -- register_copy 
    // [1807] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#40 [phi:rom_flash::@36->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1808] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1809] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
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
    // [1810] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1811] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1812] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1812] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1812] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1812] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1812] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1812] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1813] call snprintf_init
    // [1205] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@32
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1814] printf_ulong::uvalue#9 = rom_flash::flash_errors#10 -- vdum1=vdum2 
    lda flash_errors
    sta printf_ulong.uvalue
    lda flash_errors+1
    sta printf_ulong.uvalue+1
    lda flash_errors+2
    sta printf_ulong.uvalue+2
    lda flash_errors+3
    sta printf_ulong.uvalue+3
    // [1815] call printf_ulong
    // [1761] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = DECIMAL [phi:rom_flash::@32->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#9 [phi:rom_flash::@32->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1816] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1817] call printf_str
    // [1210] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = rom_flash::s2 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1818] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1819] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1821] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1822] call display_info_rom
    // [1566] phi from rom_flash::@34 to display_info_rom [phi:rom_flash::@34->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = info_text [phi:rom_flash::@34->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#3 [phi:rom_flash::@34->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@34->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1782] phi from rom_flash::@34 to rom_flash::@1 [phi:rom_flash::@34->rom_flash::@1]
    // [1782] phi rom_flash::flash_errors#12 = rom_flash::flash_errors#10 [phi:rom_flash::@34->rom_flash::@1#0] -- register_copy 
    // [1782] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@34->rom_flash::@1#1] -- register_copy 
    // [1782] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@34->rom_flash::@1#2] -- register_copy 
    // [1782] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@34->rom_flash::@1#3] -- register_copy 
    // [1782] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@34->rom_flash::@1#4] -- register_copy 
    // [1782] phi rom_flash::rom_address_sector#13 = rom_flash::rom_address_sector#1 [phi:rom_flash::@34->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1823] phi from rom_flash::@22 to rom_flash::@5 [phi:rom_flash::@22->rom_flash::@5]
  __b3:
    // [1823] phi rom_flash::flash_errors_sector#10 = 0 [phi:rom_flash::@22->rom_flash::@5#0] -- vwum1=vwuc1 
    lda #<0
    sta flash_errors_sector
    sta flash_errors_sector+1
    // [1823] phi rom_flash::retries#12 = 0 [phi:rom_flash::@22->rom_flash::@5#1] -- vbum1=vbuc1 
    sta retries
    // [1823] phi from rom_flash::@35 to rom_flash::@5 [phi:rom_flash::@35->rom_flash::@5]
    // [1823] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@35->rom_flash::@5#0] -- register_copy 
    // [1823] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@35->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1824] rom_sector_erase::address#0 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_sector_erase.address
    lda rom_address_sector+1
    sta rom_sector_erase.address+1
    lda rom_address_sector+2
    sta rom_sector_erase.address+2
    lda rom_address_sector+3
    sta rom_sector_erase.address+3
    // [1825] call rom_sector_erase
    // [2982] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@24
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1826] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#13 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1827] gotoxy::x#35 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [1828] gotoxy::y#35 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1829] call gotoxy
    // [802] phi from rom_flash::@24 to gotoxy [phi:rom_flash::@24->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#35 [phi:rom_flash::@24->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#35 [phi:rom_flash::@24->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1830] phi from rom_flash::@24 to rom_flash::@25 [phi:rom_flash::@24->rom_flash::@25]
    // rom_flash::@25
    // printf("........")
    // [1831] call printf_str
    // [1210] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [1210] phi printf_str::putc#84 = &cputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = rom_flash::s1 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // [1832] rom_flash::rom_address#16 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_address
    lda rom_address_sector+1
    sta rom_address+1
    lda rom_address_sector+2
    sta rom_address+2
    lda rom_address_sector+3
    sta rom_address+3
    // [1833] rom_flash::ram_address#16 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1834] rom_flash::x#16 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta x
    // [1835] phi from rom_flash::@10 rom_flash::@26 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6]
    // [1835] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#0] -- register_copy 
    // [1835] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#1] -- register_copy 
    // [1835] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#7 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#2] -- register_copy 
    // [1835] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1836] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vdum1_lt_vdum2_then_la1 
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
    // [1837] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors_sector && retries <= 3)
    // [1838] if(0==rom_flash::flash_errors_sector#11) goto rom_flash::@12 -- 0_eq_vwum1_then_la1 
    lda flash_errors_sector
    ora flash_errors_sector+1
    beq __b12
    // rom_flash::@35
    // [1839] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1840] rom_flash::flash_errors#1 = rom_flash::flash_errors#12 + rom_flash::flash_errors_sector#11 -- vdum1=vdum1_plus_vwum2 
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
    // [1841] display_action_text_flashing::bram_bank#2 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta display_action_text_flashing.bram_bank
    // [1842] display_action_text_flashing::bram_ptr#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z display_action_text_flashing.bram_ptr
    lda.z ram_address_sector+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1843] display_action_text_flashing::address#2 = rom_flash::rom_address_sector#13 -- vdum1=vdum2 
    lda rom_address_sector
    sta display_action_text_flashing.address
    lda rom_address_sector+1
    sta display_action_text_flashing.address+1
    lda rom_address_sector+2
    sta display_action_text_flashing.address+2
    lda rom_address_sector+3
    sta display_action_text_flashing.address+3
    // [1844] call display_action_text_flashing
    // [2994] phi from rom_flash::@7 to display_action_text_flashing [phi:rom_flash::@7->display_action_text_flashing]
    // [2994] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#2 [phi:rom_flash::@7->display_action_text_flashing#0] -- register_copy 
    // [2994] phi display_action_text_flashing::chip#10 = chip [phi:rom_flash::@7->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2994] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#2 [phi:rom_flash::@7->display_action_text_flashing#2] -- register_copy 
    // [2994] phi display_action_text_flashing::bram_bank#3 = display_action_text_flashing::bram_bank#2 [phi:rom_flash::@7->display_action_text_flashing#3] -- register_copy 
    // [2994] phi display_action_text_flashing::bytes#3 = $1000 [phi:rom_flash::@7->display_action_text_flashing#4] -- vdum1=vduc1 
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
    // [1845] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_write.flash_ram_bank
    // [1846] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1847] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vdum1=vdum2 
    lda rom_address
    sta rom_write.flash_rom_address
    lda rom_address+1
    sta rom_write.flash_rom_address+1
    lda rom_address+2
    sta rom_write.flash_rom_address+2
    lda rom_address+3
    sta rom_write.flash_rom_address+3
    // [1848] call rom_write
    jsr rom_write
    // rom_flash::@28
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1849] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta rom_compare.bank_ram
    // [1850] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1851] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vdum1=vdum2 
    lda rom_address
    sta rom_compare.rom_compare_address
    lda rom_address+1
    sta rom_compare.rom_compare_address+1
    lda rom_address+2
    sta rom_compare.rom_compare_address+2
    lda rom_address+3
    sta rom_compare.rom_compare_address+3
    // [1852] call rom_compare
    // [2909] phi from rom_flash::@28 to rom_compare [phi:rom_flash::@28->rom_compare]
    // [2909] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@28->rom_compare#0] -- register_copy 
    // [2909] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@28->rom_compare#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta rom_compare.rom_compare_size+1
    // [2909] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@28->rom_compare#2] -- register_copy 
    // [2909] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@28->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1853] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@29
    // equal_bytes = rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1854] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwum1=vwum2 
    lda rom_compare.return
    sta equal_bytes_1
    lda rom_compare.return+1
    sta equal_bytes_1+1
    // gotoxy(x, y)
    // [1855] gotoxy::x#36 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1856] gotoxy::y#36 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1857] call gotoxy
    // [802] phi from rom_flash::@29 to gotoxy [phi:rom_flash::@29->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#36 [phi:rom_flash::@29->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#36 [phi:rom_flash::@29->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@30
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1858] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1859] cputcxy::x#16 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1860] cputcxy::y#16 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1861] call cputcxy
    // [2313] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [2313] phi cputcxy::c#17 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [2313] phi cputcxy::y#17 = cputcxy::y#16 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#16 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1862] phi from rom_flash::@11 rom_flash::@31 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10]
    // [1862] phi rom_flash::flash_errors_sector#7 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1863] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1864] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
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
    // [1865] rom_flash::x#1 = ++ rom_flash::x#10 -- vbum1=_inc_vbum1 
    inc x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1866] cputcxy::x#15 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1867] cputcxy::y#15 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1868] call cputcxy
    // [2313] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [2313] phi cputcxy::c#17 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'!'
    sta cputcxy.c
    // [2313] phi cputcxy::y#17 = cputcxy::y#15 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#15 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@31
    // flash_errors_sector++;
    // [1869] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#11 -- vwum1=_inc_vwum1 
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
    .label smc_flash__29 = $7d
    .label smc_flash__30 = $7d
    .label smc_bram_ptr = $70
    // smc_flash::bank_set_bram1
    // BRAM = bank
    // [1871] BRAM = smc_flash::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1872] phi from smc_flash::bank_set_bram1 to smc_flash::@24 [phi:smc_flash::bank_set_bram1->smc_flash::@24]
    // smc_flash::@24
    // display_action_progress("To start the SMC update, do the following ...")
    // [1873] call display_action_progress
    // [904] phi from smc_flash::@24 to display_action_progress [phi:smc_flash::@24->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = smc_flash::info_text [phi:smc_flash::@24->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@28
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1874] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1875] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1876] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1877] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1879] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbum1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta cx16_k_i2c_write_byte1_return
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1880] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1881] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [1882] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbum1_then_la1 
    lda smc_bootloader_start
    beq __b6
    // [1883] phi from smc_flash::@25 to smc_flash::@2 [phi:smc_flash::@25->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1884] call snprintf_init
    // [1205] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1885] phi from smc_flash::@2 to smc_flash::@29 [phi:smc_flash::@2->smc_flash::@29]
    // smc_flash::@29
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1886] call printf_str
    // [1210] phi from smc_flash::@29 to printf_str [phi:smc_flash::@29->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = smc_flash::s [phi:smc_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1887] printf_uchar::uvalue#10 = smc_flash::smc_bootloader_start#0 -- vbum1=vbum2 
    lda smc_bootloader_start
    sta printf_uchar.uvalue
    // [1888] call printf_uchar
    // [1347] phi from smc_flash::@30 to printf_uchar [phi:smc_flash::@30->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_flash::@30->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:smc_flash::@30->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:smc_flash::@30->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:smc_flash::@30->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#10 [phi:smc_flash::@30->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1889] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1890] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1892] call display_action_text
    // [1358] phi from smc_flash::@31 to display_action_text [phi:smc_flash::@31->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@31->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@32
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1893] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1894] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1895] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1896] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1898] phi from smc_flash::@50 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@50/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1898] phi smc_flash::return#1 = 0 [phi:smc_flash::@50/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // smc_flash::@return
    // }
    // [1899] return 
    rts
    // [1900] phi from smc_flash::@25 to smc_flash::@3 [phi:smc_flash::@25->smc_flash::@3]
  __b6:
    // [1900] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@25->smc_flash::@3#0] -- vbum1=vbuc1 
    lda #$80
    sta smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1901] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1902] phi from smc_flash::@3 smc_flash::@33 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@33->smc_flash::@7]
  __b9:
    // [1902] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@33->smc_flash::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1903] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1904] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1905] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1906] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1907] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@45
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1908] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#12
    // if(smc_bootloader_not_activated)
    // [1909] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwum1_then_la1 
    lda smc_bootloader_not_activated
    ora smc_bootloader_not_activated+1
    beq __b1
    // [1910] phi from smc_flash::@45 to smc_flash::@10 [phi:smc_flash::@45->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1911] call snprintf_init
    // [1205] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1912] phi from smc_flash::@10 to smc_flash::@48 [phi:smc_flash::@10->smc_flash::@48]
    // smc_flash::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1913] call printf_str
    // [1210] phi from smc_flash::@48 to printf_str [phi:smc_flash::@48->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_flash::@48->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = smc_flash::s5 [phi:smc_flash::@48->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@49
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1914] printf_uint::uvalue#4 = smc_flash::smc_bootloader_not_activated#1
    // [1915] call printf_uint
    // [2106] phi from smc_flash::@49 to printf_uint [phi:smc_flash::@49->printf_uint]
    // [2106] phi printf_uint::format_zero_padding#10 = 0 [phi:smc_flash::@49->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2106] phi printf_uint::format_min_length#10 = 0 [phi:smc_flash::@49->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2106] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@49->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2106] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@49->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2106] phi printf_uint::uvalue#10 = printf_uint::uvalue#4 [phi:smc_flash::@49->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@50
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1916] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1917] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1919] call display_action_text
    // [1358] phi from smc_flash::@50 to display_action_text [phi:smc_flash::@50->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@50->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1920] phi from smc_flash::@45 to smc_flash::@1 [phi:smc_flash::@45->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1921] call display_action_progress
    // [904] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1922] phi from smc_flash::@1 to smc_flash::@46 [phi:smc_flash::@1->smc_flash::@46]
    // smc_flash::@46
    // textcolor(WHITE)
    // [1923] call textcolor
    // [784] phi from smc_flash::@46 to textcolor [phi:smc_flash::@46->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:smc_flash::@46->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1924] phi from smc_flash::@46 to smc_flash::@47 [phi:smc_flash::@46->smc_flash::@47]
    // smc_flash::@47
    // gotoxy(x, y)
    // [1925] call gotoxy
    // [802] phi from smc_flash::@47 to gotoxy [phi:smc_flash::@47->gotoxy]
    // [802] phi gotoxy::y#37 = PROGRESS_Y [phi:smc_flash::@47->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:smc_flash::@47->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1926] phi from smc_flash::@47 to smc_flash::@11 [phi:smc_flash::@47->smc_flash::@11]
    // [1926] phi smc_flash::y#36 = PROGRESS_Y [phi:smc_flash::@47->smc_flash::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1926] phi smc_flash::smc_row_bytes#16 = 0 [phi:smc_flash::@47->smc_flash::@11#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1926] phi smc_flash::smc_bram_ptr#14 = (char *)$a000 [phi:smc_flash::@47->smc_flash::@11#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // [1926] phi smc_flash::smc_bytes_flashed#13 = 0 [phi:smc_flash::@47->smc_flash::@11#3] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [1926] phi from smc_flash::@15 to smc_flash::@11 [phi:smc_flash::@15->smc_flash::@11]
    // [1926] phi smc_flash::y#36 = smc_flash::y#21 [phi:smc_flash::@15->smc_flash::@11#0] -- register_copy 
    // [1926] phi smc_flash::smc_row_bytes#16 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@15->smc_flash::@11#1] -- register_copy 
    // [1926] phi smc_flash::smc_bram_ptr#14 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@15->smc_flash::@11#2] -- register_copy 
    // [1926] phi smc_flash::smc_bytes_flashed#13 = smc_flash::smc_bytes_flashed#12 [phi:smc_flash::@15->smc_flash::@11#3] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1927] if(smc_flash::smc_bytes_flashed#13<smc_flash::smc_bytes_total#0) goto smc_flash::@13 -- vwum1_lt_vwum2_then_la1 
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
    // [1928] display_action_text_flashed::bytes#1 = smc_flash::smc_bytes_flashed#13 -- vdum1=vwum2 
    lda smc_bytes_flashed
    sta display_action_text_flashed.bytes
    lda smc_bytes_flashed+1
    sta display_action_text_flashed.bytes+1
    lda #0
    sta display_action_text_flashed.bytes+2
    sta display_action_text_flashed.bytes+3
    // [1929] call display_action_text_flashed
    // [2965] phi from smc_flash::@12 to display_action_text_flashed [phi:smc_flash::@12->display_action_text_flashed]
    // [2965] phi display_action_text_flashed::chip#3 = smc_flash::chip [phi:smc_flash::@12->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2965] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#1 [phi:smc_flash::@12->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1898] phi from smc_flash::@12 to smc_flash::@return [phi:smc_flash::@12->smc_flash::@return]
    // [1898] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#13 [phi:smc_flash::@12->smc_flash::@return#0] -- register_copy 
    rts
    // [1930] phi from smc_flash::@11 to smc_flash::@13 [phi:smc_flash::@11->smc_flash::@13]
  __b10:
    // [1930] phi smc_flash::y#21 = smc_flash::y#36 [phi:smc_flash::@11->smc_flash::@13#0] -- register_copy 
    // [1930] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#16 [phi:smc_flash::@11->smc_flash::@13#1] -- register_copy 
    // [1930] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#13 [phi:smc_flash::@11->smc_flash::@13#2] -- register_copy 
    // [1930] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#14 [phi:smc_flash::@11->smc_flash::@13#3] -- register_copy 
    // [1930] phi smc_flash::smc_attempts_flashed#15 = 0 [phi:smc_flash::@11->smc_flash::@13#4] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1930] phi smc_flash::smc_package_committed#10 = 0 [phi:smc_flash::@11->smc_flash::@13#5] -- vbum1=vbuc1 
    sta smc_package_committed
    // smc_flash::@13
  __b13:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1931] if(0!=smc_flash::smc_package_committed#10) goto smc_flash::@15 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b15
    // smc_flash::@55
    // [1932] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b14
    // smc_flash::@15
  __b15:
    // if(smc_attempts_flashed >= 10)
    // [1933] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1934] phi from smc_flash::@15 to smc_flash::@23 [phi:smc_flash::@15->smc_flash::@23]
    // smc_flash::@23
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1935] call snprintf_init
    // [1205] phi from smc_flash::@23 to snprintf_init [phi:smc_flash::@23->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:smc_flash::@23->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1936] phi from smc_flash::@23 to smc_flash::@52 [phi:smc_flash::@23->smc_flash::@52]
    // smc_flash::@52
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1937] call printf_str
    // [1210] phi from smc_flash::@52 to printf_str [phi:smc_flash::@52->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_flash::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = smc_flash::s6 [phi:smc_flash::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@53
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1938] printf_uint::uvalue#5 = smc_flash::smc_bytes_flashed#12 -- vwum1=vwum2 
    lda smc_bytes_flashed
    sta printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1939] call printf_uint
    // [2106] phi from smc_flash::@53 to printf_uint [phi:smc_flash::@53->printf_uint]
    // [2106] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_flash::@53->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2106] phi printf_uint::format_min_length#10 = 4 [phi:smc_flash::@53->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2106] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2106] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@53->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2106] phi printf_uint::uvalue#10 = printf_uint::uvalue#5 [phi:smc_flash::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@54
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1940] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1941] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1943] call display_action_text
    // [1358] phi from smc_flash::@54 to display_action_text [phi:smc_flash::@54->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@54->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1898] phi from smc_flash::@54 to smc_flash::@return [phi:smc_flash::@54->smc_flash::@return]
    // [1898] phi smc_flash::return#1 = $ffff [phi:smc_flash::@54->smc_flash::@return#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta return
    lda #>$ffff
    sta return+1
    rts
    // smc_flash::@14
  __b14:
    // display_action_text_flashing(8, "SMC", smc_bram_bank, smc_bram_ptr, smc_bytes_flashed)
    // [1944] display_action_text_flashing::bram_ptr#1 = smc_flash::smc_bram_ptr#12 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1945] display_action_text_flashing::address#1 = smc_flash::smc_bytes_flashed#12 -- vdum1=vwum2 
    lda smc_bytes_flashed
    sta display_action_text_flashing.address
    lda smc_bytes_flashed+1
    sta display_action_text_flashing.address+1
    lda #0
    sta display_action_text_flashing.address+2
    sta display_action_text_flashing.address+3
    // [1946] call display_action_text_flashing
    // [2994] phi from smc_flash::@14 to display_action_text_flashing [phi:smc_flash::@14->display_action_text_flashing]
    // [2994] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#1 [phi:smc_flash::@14->display_action_text_flashing#0] -- register_copy 
    // [2994] phi display_action_text_flashing::chip#10 = smc_flash::chip [phi:smc_flash::@14->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2994] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#1 [phi:smc_flash::@14->display_action_text_flashing#2] -- register_copy 
    // [2994] phi display_action_text_flashing::bram_bank#3 = smc_flash::smc_bram_bank [phi:smc_flash::@14->display_action_text_flashing#3] -- vbum1=vbuc1 
    lda #smc_bram_bank
    sta display_action_text_flashing.bram_bank
    // [2994] phi display_action_text_flashing::bytes#3 = 8 [phi:smc_flash::@14->display_action_text_flashing#4] -- vdum1=vbuc1 
    lda #8
    sta display_action_text_flashing.bytes
    lda #0
    sta display_action_text_flashing.bytes+1
    sta display_action_text_flashing.bytes+2
    sta display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [1947] phi from smc_flash::@14 to smc_flash::@16 [phi:smc_flash::@14->smc_flash::@16]
    // [1947] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@14->smc_flash::@16#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [1947] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@14->smc_flash::@16#1] -- register_copy 
    // [1947] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@14->smc_flash::@16#2] -- vwum1=vwuc1 
    sta smc_package_flashed
    sta smc_package_flashed+1
    // smc_flash::@16
  __b16:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1948] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@17 -- vwum1_lt_vbuc1_then_la1 
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
    // [1949] smc_flash::$29 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbum2_bxor_vbuc1 
    lda #$ff
    eor smc_bytes_checksum
    sta.z smc_flash__29
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1950] smc_flash::$30 = smc_flash::$29 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z smc_flash__30
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1951] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1952] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1953] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$30 -- vbum1=vbuz2 
    lda.z smc_flash__30
    sta cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1954] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [1956] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1957] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1958] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1959] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@51
    // [1960] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#13
    // if(smc_commit_result == 1)
    // [1961] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@20 -- vwum1_eq_vbuc1_then_la1 
    lda smc_commit_result+1
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b20
  !:
    // smc_flash::@19
    // smc_bram_ptr -= SMC_PROGRESS_CELL
    // [1962] smc_flash::smc_bram_ptr#2 = smc_flash::smc_bram_ptr#10 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_bram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    sbc #0
    sta.z smc_bram_ptr+1
    // smc_attempts_flashed++;
    // [1963] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#15 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1930] phi from smc_flash::@19 to smc_flash::@13 [phi:smc_flash::@19->smc_flash::@13]
    // [1930] phi smc_flash::y#21 = smc_flash::y#21 [phi:smc_flash::@19->smc_flash::@13#0] -- register_copy 
    // [1930] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@19->smc_flash::@13#1] -- register_copy 
    // [1930] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#12 [phi:smc_flash::@19->smc_flash::@13#2] -- register_copy 
    // [1930] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#2 [phi:smc_flash::@19->smc_flash::@13#3] -- register_copy 
    // [1930] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@19->smc_flash::@13#4] -- register_copy 
    // [1930] phi smc_flash::smc_package_committed#10 = smc_flash::smc_package_committed#10 [phi:smc_flash::@19->smc_flash::@13#5] -- register_copy 
    jmp __b13
    // smc_flash::@20
  __b20:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1964] if(smc_flash::smc_row_bytes#11!=SMC_PROGRESS_ROW) goto smc_flash::@21 -- vwum1_neq_vwuc1_then_la1 
    lda smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b21
    lda smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b21
    // smc_flash::@22
    // gotoxy(x, ++y);
    // [1965] smc_flash::y#1 = ++ smc_flash::y#21 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1966] gotoxy::y#29 = smc_flash::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1967] call gotoxy
    // [802] phi from smc_flash::@22 to gotoxy [phi:smc_flash::@22->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#29 [phi:smc_flash::@22->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:smc_flash::@22->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1968] phi from smc_flash::@22 to smc_flash::@21 [phi:smc_flash::@22->smc_flash::@21]
    // [1968] phi smc_flash::y#38 = smc_flash::y#1 [phi:smc_flash::@22->smc_flash::@21#0] -- register_copy 
    // [1968] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@22->smc_flash::@21#1] -- vwum1=vbuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1968] phi from smc_flash::@20 to smc_flash::@21 [phi:smc_flash::@20->smc_flash::@21]
    // [1968] phi smc_flash::y#38 = smc_flash::y#21 [phi:smc_flash::@20->smc_flash::@21#0] -- register_copy 
    // [1968] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@20->smc_flash::@21#1] -- register_copy 
    // smc_flash::@21
  __b21:
    // cputc('+')
    // [1969] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1970] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1972] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#12 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1973] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_row_bytes
    sta smc_row_bytes
    bcc !+
    inc smc_row_bytes+1
  !:
    // [1930] phi from smc_flash::@21 to smc_flash::@13 [phi:smc_flash::@21->smc_flash::@13]
    // [1930] phi smc_flash::y#21 = smc_flash::y#38 [phi:smc_flash::@21->smc_flash::@13#0] -- register_copy 
    // [1930] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@21->smc_flash::@13#1] -- register_copy 
    // [1930] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@21->smc_flash::@13#2] -- register_copy 
    // [1930] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#10 [phi:smc_flash::@21->smc_flash::@13#3] -- register_copy 
    // [1930] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#15 [phi:smc_flash::@21->smc_flash::@13#4] -- register_copy 
    // [1930] phi smc_flash::smc_package_committed#10 = 1 [phi:smc_flash::@21->smc_flash::@13#5] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b13
    // smc_flash::@17
  __b17:
    // unsigned char smc_byte_upload = *smc_bram_ptr
    // [1974] smc_flash::smc_byte_upload#0 = *smc_flash::smc_bram_ptr#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_bram_ptr),y
    sta smc_byte_upload
    // smc_bram_ptr++;
    // [1975] smc_flash::smc_bram_ptr#1 = ++ smc_flash::smc_bram_ptr#10 -- pbuz1=_inc_pbuz1 
    inc.z smc_bram_ptr
    bne !+
    inc.z smc_bram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1976] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbum1=vbum1_plus_vbum2 
    lda smc_bytes_checksum
    clc
    adc smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1977] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1978] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1979] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1980] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [1982] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwum1=_inc_vwum1 
    inc smc_package_flashed
    bne !+
    inc smc_package_flashed+1
  !:
    // [1947] phi from smc_flash::@26 to smc_flash::@16 [phi:smc_flash::@26->smc_flash::@16]
    // [1947] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@26->smc_flash::@16#0] -- register_copy 
    // [1947] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#1 [phi:smc_flash::@26->smc_flash::@16#1] -- register_copy 
    // [1947] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@26->smc_flash::@16#2] -- register_copy 
    jmp __b16
    // [1983] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment(1)
    // [1984] call wait_moment
    // [1310] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    // [1310] phi wait_moment::w#13 = 1 [phi:smc_flash::@8->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [1985] phi from smc_flash::@8 to smc_flash::@39 [phi:smc_flash::@8->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1986] call snprintf_init
    // [1205] phi from smc_flash::@39 to snprintf_init [phi:smc_flash::@39->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:smc_flash::@39->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1987] phi from smc_flash::@39 to smc_flash::@40 [phi:smc_flash::@39->smc_flash::@40]
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1988] call printf_str
    // [1210] phi from smc_flash::@40 to printf_str [phi:smc_flash::@40->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_flash::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = smc_flash::s3 [phi:smc_flash::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@41
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1989] printf_uchar::uvalue#12 = smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta printf_uchar.uvalue
    // [1990] call printf_uchar
    // [1347] phi from smc_flash::@41 to printf_uchar [phi:smc_flash::@41->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 0 [phi:smc_flash::@41->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:smc_flash::@41->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:smc_flash::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_flash::@41->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#12 [phi:smc_flash::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1991] phi from smc_flash::@41 to smc_flash::@42 [phi:smc_flash::@41->smc_flash::@42]
    // smc_flash::@42
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1992] call printf_str
    // [1210] phi from smc_flash::@42 to printf_str [phi:smc_flash::@42->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_flash::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s6 [phi:smc_flash::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s6
    sta.z printf_str.s
    lda #>@s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@43
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1993] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1994] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1996] call display_action_text
    // [1358] phi from smc_flash::@43 to display_action_text [phi:smc_flash::@43->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@43->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@44
    // smc_bootloader_activation_countdown--;
    // [1997] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1902] phi from smc_flash::@44 to smc_flash::@7 [phi:smc_flash::@44->smc_flash::@7]
    // [1902] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@44->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1998] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1999] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [2000] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [2001] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@33
    // [2002] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#11
    // if(smc_bootloader_not_activated)
    // [2003] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [2004] phi from smc_flash::@33 to smc_flash::@5 [phi:smc_flash::@33->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment(1)
    // [2005] call wait_moment
    // [1310] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    // [1310] phi wait_moment::w#13 = 1 [phi:smc_flash::@5->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [2006] phi from smc_flash::@5 to smc_flash::@34 [phi:smc_flash::@5->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2007] call snprintf_init
    // [1205] phi from smc_flash::@34 to snprintf_init [phi:smc_flash::@34->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:smc_flash::@34->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2008] phi from smc_flash::@34 to smc_flash::@35 [phi:smc_flash::@34->smc_flash::@35]
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2009] call printf_str
    // [1210] phi from smc_flash::@35 to printf_str [phi:smc_flash::@35->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_flash::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s21 [phi:smc_flash::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@36
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2010] printf_uchar::uvalue#11 = smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown
    sta printf_uchar.uvalue
    // [2011] call printf_uchar
    // [1347] phi from smc_flash::@36 to printf_uchar [phi:smc_flash::@36->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:smc_flash::@36->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 3 [phi:smc_flash::@36->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:smc_flash::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:smc_flash::@36->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#11 [phi:smc_flash::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2012] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2013] call printf_str
    // [1210] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = smc_flash::s2 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [2014] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2015] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2017] call display_action_text
    // [1358] phi from smc_flash::@38 to display_action_text [phi:smc_flash::@38->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@38->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [2018] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1900] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1900] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
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
// __mem() char util_wait_key(__zp($4a) char *info_text, __zp($43) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__9 = $5e
    .label info_text = $4a
    .label filter = $43
    // display_action_text(info_text)
    // [2020] display_action_text::info_text#10 = util_wait_key::info_text#3
    // [2021] call display_action_text
    // [1358] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1358] phi display_action_text::info_text#25 = display_action_text::info_text#10 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [2022] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [2023] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [2024] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [2025] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [2026] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [2028] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [2029] call cbm_k_getin
    jsr cbm_k_getin
    // [2030] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [2031] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbum2 
    lda cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [2032] if((char *)0!=util_wait_key::filter#13) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [2033] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [2034] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [2035] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [2036] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [2037] strchr::str#0 = (const void *)util_wait_key::filter#13 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [2038] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [2039] call strchr
    // [2043] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [2043] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [2043] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [2040] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [2041] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [2042] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
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
// __zp($5e) void * strchr(__zp($5e) const void *str, __mem() char c)
strchr: {
    .label ptr = $5e
    .label return = $5e
    .label str = $5e
    // [2044] strchr::ptr#6 = (char *)strchr::str#2
    // [2045] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [2045] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [2046] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [2047] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [2047] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [2048] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [2049] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [2050] strchr::return#8 = (void *)strchr::ptr#2
    // [2047] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [2047] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [2051] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
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
// void display_info_cx16_rom(__mem() char info_status, __zp($3f) char *info_text)
display_info_cx16_rom: {
    .label info_text = $3f
    // display_info_rom(0, info_status, info_text)
    // [2053] display_info_rom::info_status#0 = display_info_cx16_rom::info_status#4
    // [2054] display_info_rom::info_text#0 = display_info_cx16_rom::info_text#4
    // [2055] call display_info_rom
    // [1566] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = display_info_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1566] phi display_info_rom::rom_chip#17 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbum1=vbuc1 
    lda #0
    sta display_info_rom.rom_chip
    // [1566] phi display_info_rom::info_status#17 = display_info_rom::info_status#0 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [2056] return 
    rts
  .segment Data
    .label info_status = display_info_rom.info_status
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
    .label rom_get_release__0 = $c6
    .label rom_get_release__2 = $60
    // release & 0x80
    // [2058] rom_get_release::$0 = rom_get_release::release#3 & $80 -- vbuz1=vbum2_band_vbuc1 
    lda #$80
    and release
    sta.z rom_get_release__0
    // if(release & 0x80)
    // [2059] if(0==rom_get_release::$0) goto rom_get_release::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // rom_get_release::@2
    // ~release
    // [2060] rom_get_release::$2 = ~ rom_get_release::release#3 -- vbuz1=_bnot_vbum2 
    lda release
    eor #$ff
    sta.z rom_get_release__2
    // release = ~release + 1
    // [2061] rom_get_release::release#0 = rom_get_release::$2 + 1 -- vbum1=vbuz2_plus_1 
    inc
    sta release
    // [2062] phi from rom_get_release rom_get_release::@2 to rom_get_release::@1 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1]
    // [2062] phi rom_get_release::return#0 = rom_get_release::release#3 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1#0] -- register_copy 
    // rom_get_release::@1
  __b1:
    // rom_get_release::@return
    // }
    // [2063] return 
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
    // [2065] if(rom_get_prefix::release#2!=$ff) goto rom_get_prefix::@1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp release
    bne __b3
    // [2066] phi from rom_get_prefix to rom_get_prefix::@3 [phi:rom_get_prefix->rom_get_prefix::@3]
    // rom_get_prefix::@3
    // [2067] phi from rom_get_prefix::@3 to rom_get_prefix::@1 [phi:rom_get_prefix::@3->rom_get_prefix::@1]
    // [2067] phi rom_get_prefix::prefix#4 = 'p' [phi:rom_get_prefix::@3->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'p'
    sta prefix
    jmp __b1
    // [2067] phi from rom_get_prefix to rom_get_prefix::@1 [phi:rom_get_prefix->rom_get_prefix::@1]
  __b3:
    // [2067] phi rom_get_prefix::prefix#4 = 'r' [phi:rom_get_prefix->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'r'
    sta prefix
    // rom_get_prefix::@1
  __b1:
    // release & 0x80
    // [2068] rom_get_prefix::$2 = rom_get_prefix::release#2 & $80 -- vbuz1=vbum2_band_vbuc1 
    lda #$80
    and release
    sta.z rom_get_prefix__2
    // if(release & 0x80)
    // [2069] if(0==rom_get_prefix::$2) goto rom_get_prefix::@4 -- 0_eq_vbuz1_then_la1 
    beq __b2
    // [2071] phi from rom_get_prefix::@1 to rom_get_prefix::@2 [phi:rom_get_prefix::@1->rom_get_prefix::@2]
    // [2071] phi rom_get_prefix::return#0 = 'p' [phi:rom_get_prefix::@1->rom_get_prefix::@2#0] -- vbum1=vbuc1 
    lda #'p'
    sta return
    rts
    // [2070] phi from rom_get_prefix::@1 to rom_get_prefix::@4 [phi:rom_get_prefix::@1->rom_get_prefix::@4]
    // rom_get_prefix::@4
    // [2071] phi from rom_get_prefix::@4 to rom_get_prefix::@2 [phi:rom_get_prefix::@4->rom_get_prefix::@2]
    // [2071] phi rom_get_prefix::return#0 = rom_get_prefix::prefix#4 [phi:rom_get_prefix::@4->rom_get_prefix::@2#0] -- register_copy 
    // rom_get_prefix::@2
  __b2:
    // rom_get_prefix::@return
    // }
    // [2072] return 
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
// void rom_get_version_text(__zp($45) char *release_info, __mem() char prefix, __mem() char release, __zp($6e) char *github)
rom_get_version_text: {
    .label release_info = $45
    .label github = $6e
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2074] snprintf_init::s#10 = rom_get_version_text::release_info#2
    // [2075] call snprintf_init
    // [1205] phi from rom_get_version_text to snprintf_init [phi:rom_get_version_text->snprintf_init]
    // [1205] phi snprintf_init::s#31 = snprintf_init::s#10 [phi:rom_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // rom_get_version_text::@1
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2076] stackpush(char) = rom_get_version_text::prefix#2 -- _stackpushbyte_=vbum1 
    lda prefix
    pha
    // [2077] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [2079] printf_uchar::uvalue#13 = rom_get_version_text::release#2 -- vbum1=vbum2 
    lda release
    sta printf_uchar.uvalue
    // [2080] call printf_uchar
    // [1347] phi from rom_get_version_text::@1 to printf_uchar [phi:rom_get_version_text::@1->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 0 [phi:rom_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 0 [phi:rom_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:rom_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = DECIMAL [phi:rom_get_version_text::@1->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#13 [phi:rom_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2081] phi from rom_get_version_text::@1 to rom_get_version_text::@2 [phi:rom_get_version_text::@1->rom_get_version_text::@2]
    // rom_get_version_text::@2
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2082] call printf_str
    // [1210] phi from rom_get_version_text::@2 to printf_str [phi:rom_get_version_text::@2->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:rom_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:rom_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@3
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2083] printf_string::str#16 = rom_get_version_text::github#2 -- pbuz1=pbuz2 
    lda.z github
    sta.z printf_string.str
    lda.z github+1
    sta.z printf_string.str+1
    // [2084] call printf_string
    // [1219] phi from rom_get_version_text::@3 to printf_string [phi:rom_get_version_text::@3->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:rom_get_version_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#16 [phi:rom_get_version_text::@3->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:rom_get_version_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:rom_get_version_text::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // rom_get_version_text::@4
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [2085] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2086] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_get_version_text::@return
    // }
    // [2088] return 
    rts
  .segment Data
    prefix: .byte 0
    release: .byte 0
}
.segment Code
  // rom_get_github_commit_id
/**
 * @brief Copy the github commit_id only if the commit_id contains hexadecimal characters. 
 * 
 * @param commit_id The target commit_id.
 * @param from The source ptr in ROM or RAM.
 */
// void rom_get_github_commit_id(__zp($47) char *commit_id, __zp($3f) char *from)
rom_get_github_commit_id: {
    .label commit_id = $47
    .label from = $3f
    // [2090] phi from rom_get_github_commit_id to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2]
    // [2090] phi rom_get_github_commit_id::commit_id_ok#2 = true [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#0] -- vbom1=vboc1 
    lda #1
    sta commit_id_ok
    // [2090] phi rom_get_github_commit_id::c#2 = 0 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#1] -- vbum1=vbuc1 
    lda #0
    sta c
    // rom_get_github_commit_id::@2
  __b2:
    // for(unsigned char c=0; c<7; c++)
    // [2091] if(rom_get_github_commit_id::c#2<7) goto rom_get_github_commit_id::@3 -- vbum1_lt_vbuc1_then_la1 
    lda c
    cmp #7
    bcc __b3
    // rom_get_github_commit_id::@4
    // if(commit_id_ok)
    // [2092] if(rom_get_github_commit_id::commit_id_ok#2) goto rom_get_github_commit_id::@1 -- vbom1_then_la1 
    lda commit_id_ok
    cmp #0
    bne __b1
    // rom_get_github_commit_id::@6
    // *commit_id = '\0'
    // [2093] *rom_get_github_commit_id::commit_id#6 = '@' -- _deref_pbuz1=vbuc1 
    lda #'@'
    ldy #0
    sta (commit_id),y
    // rom_get_github_commit_id::@return
    // }
    // [2094] return 
    rts
    // rom_get_github_commit_id::@1
  __b1:
    // strncpy(commit_id, from, 7)
    // [2095] strncpy::dst#2 = rom_get_github_commit_id::commit_id#6
    // [2096] strncpy::src#2 = rom_get_github_commit_id::from#6
    // [2097] call strncpy
    // [3041] phi from rom_get_github_commit_id::@1 to strncpy [phi:rom_get_github_commit_id::@1->strncpy]
    // [3041] phi strncpy::dst#8 = strncpy::dst#2 [phi:rom_get_github_commit_id::@1->strncpy#0] -- register_copy 
    // [3041] phi strncpy::src#6 = strncpy::src#2 [phi:rom_get_github_commit_id::@1->strncpy#1] -- register_copy 
    // [3041] phi strncpy::n#3 = 7 [phi:rom_get_github_commit_id::@1->strncpy#2] -- vwum1=vbuc1 
    lda #<7
    sta strncpy.n
    lda #>7
    sta strncpy.n+1
    jsr strncpy
    rts
    // rom_get_github_commit_id::@3
  __b3:
    // unsigned char ch = from[c]
    // [2098] rom_get_github_commit_id::ch#0 = rom_get_github_commit_id::from#6[rom_get_github_commit_id::c#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy c
    lda (from),y
    sta ch
    // if(!(ch >= 48 && ch <= 48+9 || ch >= 65 && ch <= 65+26))
    // [2099] if(rom_get_github_commit_id::ch#0<$30) goto rom_get_github_commit_id::@7 -- vbum1_lt_vbuc1_then_la1 
    cmp #$30
    bcc __b7
    // rom_get_github_commit_id::@8
    // [2100] if(rom_get_github_commit_id::ch#0<$30+9+1) goto rom_get_github_commit_id::@5 -- vbum1_lt_vbuc1_then_la1 
    cmp #$30+9+1
    bcc __b5
    // rom_get_github_commit_id::@7
  __b7:
    // [2101] if(rom_get_github_commit_id::ch#0<$41) goto rom_get_github_commit_id::@5 -- vbum1_lt_vbuc1_then_la1 
    lda ch
    cmp #$41
    bcc __b4
    // rom_get_github_commit_id::@9
    // [2102] if(rom_get_github_commit_id::ch#0<$41+$1a+1) goto rom_get_github_commit_id::@10 -- vbum1_lt_vbuc1_then_la1 
    cmp #$41+$1a+1
    bcc __b5
    // [2104] phi from rom_get_github_commit_id::@7 rom_get_github_commit_id::@9 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5]
  __b4:
    // [2104] phi rom_get_github_commit_id::commit_id_ok#4 = false [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5#0] -- vbom1=vboc1 
    lda #0
    sta commit_id_ok
    // [2103] phi from rom_get_github_commit_id::@9 to rom_get_github_commit_id::@10 [phi:rom_get_github_commit_id::@9->rom_get_github_commit_id::@10]
    // rom_get_github_commit_id::@10
    // [2104] phi from rom_get_github_commit_id::@10 rom_get_github_commit_id::@8 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5]
    // [2104] phi rom_get_github_commit_id::commit_id_ok#4 = rom_get_github_commit_id::commit_id_ok#2 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5#0] -- register_copy 
    // rom_get_github_commit_id::@5
  __b5:
    // for(unsigned char c=0; c<7; c++)
    // [2105] rom_get_github_commit_id::c#1 = ++ rom_get_github_commit_id::c#2 -- vbum1=_inc_vbum1 
    inc c
    // [2090] phi from rom_get_github_commit_id::@5 to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2]
    // [2090] phi rom_get_github_commit_id::commit_id_ok#2 = rom_get_github_commit_id::commit_id_ok#4 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#0] -- register_copy 
    // [2090] phi rom_get_github_commit_id::c#2 = rom_get_github_commit_id::c#1 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#1] -- register_copy 
    jmp __b2
  .segment Data
    ch: .byte 0
    c: .byte 0
    commit_id_ok: .byte 0
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($3b) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $3b
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [2107] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [2108] utoa::value#1 = printf_uint::uvalue#10
    // [2109] utoa::radix#0 = printf_uint::format_radix#10
    // [2110] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [2111] printf_number_buffer::putc#1 = printf_uint::putc#10
    // [2112] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [2113] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#10
    // [2114] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#10
    // [2115] call printf_number_buffer
  // Print using format
    // [2726] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [2726] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [2726] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [2726] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [2726] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [2116] return 
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
    .label screenlayer__0 = $5d
    .label screenlayer__1 = $5c
    .label screenlayer__2 = $c0
    .label screenlayer__5 = $bb
    .label screenlayer__6 = $bb
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
    // [2117] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [2118] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [2119] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [2120] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [2121] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [2122] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [2123] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [2124] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [2125] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [2126] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [2127] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [2128] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [2129] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [2130] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [2131] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [2132] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [2133] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [2134] screenlayer::$18 = (char)screenlayer::$9
    // [2135] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [2136] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [2137] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [2138] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [2139] screenlayer::$19 = (char)screenlayer::$12
    // [2140] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [2141] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [2142] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [2143] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [2144] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [2144] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [2144] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [2145] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [2146] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [2147] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [2148] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [2149] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [2150] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [2144] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [2144] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [2144] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [2151] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [2152] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [2153] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [2154] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [2155] call gotoxy
    // [802] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [802] phi gotoxy::y#37 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [2156] return 
    rts
    // [2157] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [2158] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [2159] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [2160] call gotoxy
    // [802] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [2161] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [2162] call clearline
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
    // [2163] cx16_k_screen_set_mode::error = 0 -- vbum1=vbuc1 
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
    // [2165] return 
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
    // [2167] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbum2_minus_vbum3 
    lda x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [2168] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2169] display_frame_maskxy::x#0 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2170] display_frame_maskxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2171] call display_frame_maskxy
    // [3115] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [3115] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [3115] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2172] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [2173] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [2174] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = display_frame_char(mask)
    // [2175] display_frame_char::mask#0 = display_frame::mask#1
    // [2176] call display_frame_char
  // Add a corner.
    // [3141] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [3141] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [2177] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [2178] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [2179] cputcxy::x#2 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2180] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2181] cputcxy::c#2 = display_frame::c#0
    // [2182] call cputcxy
    // [2313] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#2 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#2 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#2 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [2183] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [2184] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [2185] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [2185] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [2186] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [2187] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [2187] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [2188] display_frame_maskxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta display_frame_maskxy.x
    // [2189] display_frame_maskxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2190] call display_frame_maskxy
    // [3115] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [3115] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [3115] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2191] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [2192] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [2193] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2194] display_frame_char::mask#1 = display_frame::mask#3
    // [2195] call display_frame_char
    // [3141] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [3141] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2196] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [2197] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [2198] cputcxy::x#3 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [2199] cputcxy::y#3 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2200] cputcxy::c#3 = display_frame::c#1
    // [2201] call cputcxy
    // [2313] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#3 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#3 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#3 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [2202] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [2203] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [2204] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [2204] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [2205] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbum2_then_la1 
    lda y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [2206] display_frame_maskxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2207] display_frame_maskxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2208] call display_frame_maskxy
    // [3115] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [3115] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [3115] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2209] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [2210] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [2211] display_frame::mask#11 = display_frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2212] display_frame_char::mask#5 = display_frame::mask#11
    // [2213] call display_frame_char
    // [3141] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [3141] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2214] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [2215] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [2216] cputcxy::x#7 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2217] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2218] cputcxy::c#7 = display_frame::c#5
    // [2219] call cputcxy
    // [2313] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#7 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#7 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#7 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [2220] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [2221] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [2222] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [2222] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [2223] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbum2_then_la1 
    lda x
    cmp x1
    bcc __b12
    // [2224] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [2224] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [2225] display_frame_maskxy::x#6 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2226] display_frame_maskxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2227] call display_frame_maskxy
    // [3115] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [3115] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [3115] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2228] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [2229] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [2230] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2231] display_frame_char::mask#6 = display_frame::mask#13
    // [2232] call display_frame_char
    // [3141] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [3141] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2233] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [2234] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [2235] cputcxy::x#8 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2236] cputcxy::y#8 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2237] cputcxy::c#8 = display_frame::c#6
    // [2238] call cputcxy
    // [2313] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#8 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#8 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#8 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [2239] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [2240] display_frame_maskxy::x#7 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2241] display_frame_maskxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2242] call display_frame_maskxy
    // [3115] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [3115] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [3115] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2243] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [2244] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [2245] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2246] display_frame_char::mask#7 = display_frame::mask#15
    // [2247] call display_frame_char
    // [3141] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [3141] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2248] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [2249] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [2250] cputcxy::x#9 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2251] cputcxy::y#9 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2252] cputcxy::c#9 = display_frame::c#7
    // [2253] call cputcxy
    // [2313] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#9 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#9 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#9 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [2254] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [2255] display_frame_maskxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [2256] display_frame_maskxy::y#3 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2257] call display_frame_maskxy
    // [3115] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [3115] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [3115] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [2258] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [2259] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [2260] display_frame::mask#7 = display_frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2261] display_frame_char::mask#3 = display_frame::mask#7
    // [2262] call display_frame_char
    // [3141] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [3141] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2263] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [2264] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [2265] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [2266] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2267] cputcxy::c#5 = display_frame::c#3
    // [2268] call cputcxy
    // [2313] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#5 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#5 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#5 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [2269] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta display_frame_maskxy.x
    // [2270] display_frame_maskxy::y#4 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [2271] call display_frame_maskxy
    // [3115] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [3115] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [3115] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [2272] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [2273] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [2274] display_frame::mask#9 = display_frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2275] display_frame_char::mask#4 = display_frame::mask#9
    // [2276] call display_frame_char
    // [3141] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [3141] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2277] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [2278] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [2279] cputcxy::x#6 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [2280] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [2281] cputcxy::c#6 = display_frame::c#4
    // [2282] call cputcxy
    // [2313] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#6 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#6 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#6 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [2283] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [2284] display_frame_maskxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta display_frame_maskxy.x
    // [2285] display_frame_maskxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [2286] call display_frame_maskxy
    // [3115] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [3115] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [3115] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2287] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [2288] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [2289] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2290] display_frame_char::mask#2 = display_frame::mask#5
    // [2291] call display_frame_char
    // [3141] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [3141] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2292] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [2293] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [2294] cputcxy::x#4 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [2295] cputcxy::y#4 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2296] cputcxy::c#4 = display_frame::c#2
    // [2297] call cputcxy
    // [2313] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#4 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#4 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#4 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [2298] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [2299] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
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
// void cputs(__zp($38) const char *s)
cputs: {
    .label s = $38
    // [2301] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [2301] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [2302] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [2303] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [2304] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [2305] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [2306] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [2307] callexecute cputc  -- call_vprc1 
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
    // [2309] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [2310] return 
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
    // [2311] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [2312] return 
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
    // [2314] gotoxy::x#0 = cputcxy::x#17 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [2315] gotoxy::y#0 = cputcxy::y#17 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2316] call gotoxy
    // [802] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [2317] stackpush(char) = cputcxy::c#17 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [2318] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [2320] return 
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
    // [2322] display_chip_led::tc#0 = display_smc_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2323] call display_chip_led
    // [3156] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [3156] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #5
    sta display_chip_led.w
    // [3156] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbum1=vbuc1 
    lda #1+1
    sta display_chip_led.x
    // [3156] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [2324] display_info_led::tc#0 = display_smc_led::c#2
    // [2325] call display_info_led
    // [2400] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [2400] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbum1=vbuc1 
    lda #$11
    sta display_info_led.y
    // [2400] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2400] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [2326] return 
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
// void display_print_chip(__mem() char x, char y, __mem() char w, __zp($74) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $74
    .label text_1 = $68
    .label text_2 = $3d
    .label text_3 = $6b
    .label text_4 = $b6
    .label text_5 = $31
    .label text_6 = $4e
    // display_chip_line(x, y++, w, *text++)
    // [2328] display_chip_line::x#0 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2329] display_chip_line::w#0 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2330] display_chip_line::c#0 = *display_print_chip::text#11 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta display_chip_line.c
    // [2331] call display_chip_line
    // [3174] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [3174] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [3174] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [3174] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [3174] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [2332] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [2333] display_chip_line::x#1 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2334] display_chip_line::w#1 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2335] display_chip_line::c#1 = *display_print_chip::text#0 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta display_chip_line.c
    // [2336] call display_chip_line
    // [3174] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [3174] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [3174] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [3174] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [3174] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [2337] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [2338] display_chip_line::x#2 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2339] display_chip_line::w#2 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2340] display_chip_line::c#2 = *display_print_chip::text#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta display_chip_line.c
    // [2341] call display_chip_line
    // [3174] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [3174] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [3174] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [3174] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [3174] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [2342] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [2343] display_chip_line::x#3 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2344] display_chip_line::w#3 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2345] display_chip_line::c#3 = *display_print_chip::text#15 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta display_chip_line.c
    // [2346] call display_chip_line
    // [3174] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [3174] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [3174] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [3174] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [3174] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [2347] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [2348] display_chip_line::x#4 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2349] display_chip_line::w#4 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2350] display_chip_line::c#4 = *display_print_chip::text#16 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta display_chip_line.c
    // [2351] call display_chip_line
    // [3174] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [3174] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [3174] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [3174] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [3174] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [2352] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [2353] display_chip_line::x#5 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2354] display_chip_line::w#5 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2355] display_chip_line::c#5 = *display_print_chip::text#17 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta display_chip_line.c
    // [2356] call display_chip_line
    // [3174] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [3174] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [3174] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [3174] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [3174] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [2357] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [2358] display_chip_line::x#6 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2359] display_chip_line::w#6 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2360] display_chip_line::c#6 = *display_print_chip::text#18 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [2361] call display_chip_line
    // [3174] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [3174] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [3174] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [3174] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [3174] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [2362] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [2363] display_chip_line::x#7 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [2364] display_chip_line::w#7 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [2365] display_chip_line::c#7 = *display_print_chip::text#19 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [2366] call display_chip_line
    // [3174] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [3174] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [3174] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [3174] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [3174] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [2367] display_chip_end::x#0 = display_print_chip::x#10
    // [2368] display_chip_end::w#0 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_end.w
    // [2369] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [2370] return 
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
    // [2372] display_chip_led::tc#1 = display_vera_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2373] call display_chip_led
    // [3156] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [3156] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #8
    sta display_chip_led.w
    // [3156] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbum1=vbuc1 
    lda #9+1
    sta display_chip_led.x
    // [3156] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [2374] display_info_led::tc#1 = display_vera_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_info_led.tc
    // [2375] call display_info_led
    // [2400] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [2400] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbum1=vbuc1 
    lda #$11+1
    sta display_info_led.y
    // [2400] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2400] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [2376] return 
    rts
  .segment Data
    c: .byte 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($38) char *source)
strcat: {
    .label strcat__0 = $7e
    .label dst = $7e
    .label src = $38
    .label source = $38
    // strlen(destination)
    // [2378] call strlen
    // [2631] phi from strcat to strlen [phi:strcat->strlen]
    // [2631] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [2379] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [2380] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [2381] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [2382] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [2382] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [2382] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [2383] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [2384] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [2385] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [2386] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [2387] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [2388] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
    .label display_rom_led__0 = $60
    .label display_rom_led__7 = $60
    .label display_rom_led__8 = $60
    // chip*6
    // [2390] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbum2_rol_1 
    lda chip
    asl
    sta.z display_rom_led__7
    // [2391] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbum2 
    lda chip
    clc
    adc.z display_rom_led__8
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [2392] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [2393] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbum1=vbuz2_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_rom_led__0
    sta display_chip_led.x
    // [2394] display_chip_led::tc#2 = display_rom_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [2395] call display_chip_led
    // [3156] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [3156] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #3
    sta display_chip_led.w
    // [3156] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [3156] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [2396] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc chip
    sta display_info_led.y
    // [2397] display_info_led::tc#2 = display_rom_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_info_led.tc
    // [2398] call display_info_led
    // [2400] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [2400] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [2400] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [2400] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [2399] return 
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
    // [2401] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [2402] call textcolor
    // [784] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [784] phi textcolor::color#23 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2403] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [2404] call bgcolor
    // [789] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [2405] cputcxy::x#13 = display_info_led::x#4
    // [2406] cputcxy::y#13 = display_info_led::y#4
    // [2407] call cputcxy
    // [2313] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [2313] phi cputcxy::c#17 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [2313] phi cputcxy::y#17 = cputcxy::y#13 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#13 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [2408] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [2409] call textcolor
    // [784] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [2410] return 
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
    // [2412] call spi_get_jedec
  // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    // [3235] phi from vera_detect to spi_get_jedec [phi:vera_detect->spi_get_jedec]
    jsr spi_get_jedec
    // vera_detect::@return
    // }
    // [2413] return 
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
    // [2415] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // [2416] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
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
    // [2417] call rom_write_byte
  // This is a very important operation...
    // [3251] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [3251] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbum1=vbuc1 
    lda #$aa
    sta rom_write_byte.value
    // [3251] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2418] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vdum1=vdum2_plus_vwuc1 
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
    // [2419] call rom_write_byte
    // [3251] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [3251] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbum1=vbuc1 
    lda #$55
    sta rom_write_byte.value
    // [3251] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2420] rom_write_byte::address#2 = rom_unlock::address#5 -- vdum1=vdum2 
    lda address
    sta rom_write_byte.address
    lda address+1
    sta rom_write_byte.address+1
    lda address+2
    sta rom_write_byte.address+2
    lda address+3
    sta rom_write_byte.address+3
    // [2421] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbum1=vbum2 
    lda unlock_code
    sta rom_write_byte.value
    // [2422] call rom_write_byte
    // [3251] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [3251] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [3251] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2423] return 
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
    .label rom_bank1_rom_read_byte__0 = $3a
    .label rom_bank1_rom_read_byte__1 = $42
    .label rom_bank1_rom_read_byte__2 = $bc
    .label rom_ptr1_rom_read_byte__0 = $31
    .label rom_ptr1_rom_read_byte__2 = $31
    .label rom_ptr1_return = $31
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [2425] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vdum2 
    lda address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [2426] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vdum2 
    lda address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2427] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta.z rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta.z rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2428] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_read_byte__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2429] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2430] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_read_byte__2
    lda address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [2431] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2432] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [2433] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [2434] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbum1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta return
    // rom_read_byte::@return
    // }
    // [2435] return 
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
// __zp($3d) struct $2 * fopen(__zp($5a) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $3a
    .label fopen__9 = $42
    .label fopen__11 = $43
    .label fopen__15 = $61
    .label fopen__16 = $50
    .label fopen__26 = $45
    .label fopen__28 = $4e
    .label fopen__30 = $3d
    .label cbm_k_setnam1_filename = $c9
    .label cbm_k_setnam1_fopen__0 = $4a
    .label stream = $3d
    .label pathtoken = $5a
    .label pathtoken_1 = $a9
    .label path = $5a
    .label return = $3d
    // unsigned char sp = __stdio_filecount
    // [2437] fopen::sp#0 = __stdio_filecount#27 -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [2438] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2439] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2440] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [2441] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2442] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2443] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [2444] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [2445] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [2446] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2446] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [2446] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2446] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2446] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [2446] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2446] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2446] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2446] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2446] phi fopen::path#10 = fopen::path#12 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2446] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2446] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2447] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2448] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2449] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2450] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2451] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [2452] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2452] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2452] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2452] phi fopen::path#12 = fopen::path#14 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2452] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2453] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2454] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [2455] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [2456] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2457] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2458] fopen::$4 = __stdio_filecount#27 + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [2459] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2460] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2461] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2462] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2463] fopen::$9 = __stdio_filecount#27 + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [2464] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2465] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [2466] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2467] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2468] call strlen
    // [2631] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2631] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2469] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2470] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [2471] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2473] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2474] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2475] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2476] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2478] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2480] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2481] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2482] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [2483] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2484] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2485] call ferror
    jsr ferror
    // [2486] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2487] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [2488] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2489] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2491] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2491] phi __stdio_filecount#1 = __stdio_filecount#27 [phi:fopen::cbm_k_close1->fopen::@return#0] -- register_copy 
    // [2491] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#1] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2492] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2493] __stdio_filecount#0 = ++ __stdio_filecount#27 -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2494] fopen::return#10 = (struct $2 *)fopen::stream#0
    // [2491] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2491] phi __stdio_filecount#1 = __stdio_filecount#0 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    // [2491] phi fopen::return#2 = fopen::return#10 [phi:fopen::@4->fopen::@return#1] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2495] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2496] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2497] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2498] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2498] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2498] phi fopen::path#14 = fopen::path#17 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2499] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2500] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2501] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2502] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2503] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2504] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2504] phi fopen::path#17 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2504] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2505] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2506] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2507] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2508] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2509] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2510] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2511] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2512] call atoi
    // [3317] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [3317] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2513] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2514] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2515] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2516] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
// __mem() unsigned int fgets(__zp($43) char *ptr, __mem() unsigned int size, __zp($70) struct $2 *stream)
fgets: {
    .label fgets__1 = $61
    .label fgets__8 = $3a
    .label fgets__9 = $42
    .label fgets__13 = $29
    .label ptr = $43
    .label stream = $70
    // unsigned char sp = (unsigned char)stream
    // [2518] fgets::sp#0 = (char)fgets::stream#4 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2519] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2520] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2522] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2524] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2525] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2526] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2527] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2528] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2529] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2529] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2530] return 
    rts
    // fgets::@1
  __b1:
    // [2531] fgets::remaining#22 = fgets::size#10 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2532] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2532] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2532] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2532] phi fgets::ptr#11 = fgets::ptr#14 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2532] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2532] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2532] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2532] phi fgets::ptr#11 = fgets::ptr#15 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2533] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2534] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
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
    // [2535] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2536] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2537] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2538] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2539] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2540] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2540] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2541] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2543] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2544] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2545] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2546] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2547] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2548] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2549] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
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
    // [2550] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2551] fgets::ptr#0 = fgets::ptr#11 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2552] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2553] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2554] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2555] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2555] phi fgets::ptr#15 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2556] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2557] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2529] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2529] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2558] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2559] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2560] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2561] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2562] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2563] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2564] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2565] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2566] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2567] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2568] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2569] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2570] fgets::bytes#1 = cx16_k_macptr::return#2
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
    .label fclose__1 = $3a
    .label fclose__4 = $42
    .label fclose__6 = $29
    .label stream = $c7
    // unsigned char sp = (unsigned char)stream
    // [2572] fclose::sp#0 = (char)fclose::stream#3 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2573] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2574] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2576] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2578] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2579] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2580] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [2581] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2582] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2583] phi from fclose::@2 fclose::@3 fclose::@4 to fclose::@return [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return]
    // [2583] phi __stdio_filecount#2 = __stdio_filecount#3 [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return#0] -- register_copy 
    // fclose::@return
    // }
    // [2584] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2585] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2587] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2589] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2590] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2591] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2592] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2593] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2594] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2595] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2596] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2597] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2598] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2599] __stdio_filecount#3 = -- __stdio_filecount#1 -- vbum1=_dec_vbum1 
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
// void display_action_text_reading(__zp($50) char *action, __zp($72) char *file, __mem() unsigned long bytes, __mem() unsigned long size, __mem() char bram_bank, __zp($74) char *bram_ptr)
display_action_text_reading: {
    .label action = $50
    .label bram_ptr = $74
    .label file = $72
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2601] call snprintf_init
    // [1205] phi from display_action_text_reading to snprintf_init [phi:display_action_text_reading->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:display_action_text_reading->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // display_action_text_reading::@1
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2602] printf_string::str#14 = display_action_text_reading::action#3
    // [2603] call printf_string
    // [1219] phi from display_action_text_reading::@1 to printf_string [phi:display_action_text_reading::@1->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:display_action_text_reading::@1->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#14 [phi:display_action_text_reading::@1->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_reading::@1->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_reading::@1->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2604] phi from display_action_text_reading::@1 to display_action_text_reading::@2 [phi:display_action_text_reading::@1->display_action_text_reading::@2]
    // display_action_text_reading::@2
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2605] call printf_str
    // [1210] phi from display_action_text_reading::@2 to printf_str [phi:display_action_text_reading::@2->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s4 [phi:display_action_text_reading::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@3
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2606] printf_string::str#15 = display_action_text_reading::file#3 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [2607] call printf_string
    // [1219] phi from display_action_text_reading::@3 to printf_string [phi:display_action_text_reading::@3->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:display_action_text_reading::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#15 [phi:display_action_text_reading::@3->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_reading::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_reading::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2608] phi from display_action_text_reading::@3 to display_action_text_reading::@4 [phi:display_action_text_reading::@3->display_action_text_reading::@4]
    // display_action_text_reading::@4
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2609] call printf_str
    // [1210] phi from display_action_text_reading::@4 to printf_str [phi:display_action_text_reading::@4->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s2 [phi:display_action_text_reading::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@5
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2610] printf_ulong::uvalue#5 = display_action_text_reading::bytes#3
    // [2611] call printf_ulong
    // [1761] phi from display_action_text_reading::@5 to printf_ulong [phi:display_action_text_reading::@5->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_reading::@5->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_reading::@5->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_reading::@5->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#5 [phi:display_action_text_reading::@5->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2612] phi from display_action_text_reading::@5 to display_action_text_reading::@6 [phi:display_action_text_reading::@5->display_action_text_reading::@6]
    // display_action_text_reading::@6
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2613] call printf_str
    // [1210] phi from display_action_text_reading::@6 to printf_str [phi:display_action_text_reading::@6->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_action_text_reading::s2 [phi:display_action_text_reading::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@7
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2614] printf_ulong::uvalue#6 = display_action_text_reading::size#10 -- vdum1=vdum2 
    lda size
    sta printf_ulong.uvalue
    lda size+1
    sta printf_ulong.uvalue+1
    lda size+2
    sta printf_ulong.uvalue+2
    lda size+3
    sta printf_ulong.uvalue+3
    // [2615] call printf_ulong
    // [1761] phi from display_action_text_reading::@7 to printf_ulong [phi:display_action_text_reading::@7->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_reading::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_reading::@7->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_reading::@7->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#6 [phi:display_action_text_reading::@7->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2616] phi from display_action_text_reading::@7 to display_action_text_reading::@8 [phi:display_action_text_reading::@7->display_action_text_reading::@8]
    // display_action_text_reading::@8
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2617] call printf_str
    // [1210] phi from display_action_text_reading::@8 to printf_str [phi:display_action_text_reading::@8->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@8->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_action_text_reading::s3 [phi:display_action_text_reading::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@9
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2618] printf_uchar::uvalue#6 = display_action_text_reading::bram_bank#10 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [2619] call printf_uchar
    // [1347] phi from display_action_text_reading::@9 to printf_uchar [phi:display_action_text_reading::@9->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_action_text_reading::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 2 [phi:display_action_text_reading::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:display_action_text_reading::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_action_text_reading::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#6 [phi:display_action_text_reading::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2620] phi from display_action_text_reading::@9 to display_action_text_reading::@10 [phi:display_action_text_reading::@9->display_action_text_reading::@10]
    // display_action_text_reading::@10
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2621] call printf_str
    // [1210] phi from display_action_text_reading::@10 to printf_str [phi:display_action_text_reading::@10->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s2 [phi:display_action_text_reading::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@11
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2622] printf_uint::uvalue#3 = (unsigned int)display_action_text_reading::bram_ptr#10 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2623] call printf_uint
    // [2106] phi from display_action_text_reading::@11 to printf_uint [phi:display_action_text_reading::@11->printf_uint]
    // [2106] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_reading::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2106] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_reading::@11->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2106] phi printf_uint::putc#10 = &snputc [phi:display_action_text_reading::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2106] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2106] phi printf_uint::uvalue#10 = printf_uint::uvalue#3 [phi:display_action_text_reading::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2624] phi from display_action_text_reading::@11 to display_action_text_reading::@12 [phi:display_action_text_reading::@11->display_action_text_reading::@12]
    // display_action_text_reading::@12
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2625] call printf_str
    // [1210] phi from display_action_text_reading::@12 to printf_str [phi:display_action_text_reading::@12->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_reading::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s6 [phi:display_action_text_reading::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@13
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2626] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2627] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2629] call display_action_text
    // [1358] phi from display_action_text_reading::@13 to display_action_text [phi:display_action_text_reading::@13->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:display_action_text_reading::@13->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_reading::@return
    // }
    // [2630] return 
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
    // [2632] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2632] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [2632] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2633] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2634] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2635] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [2636] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2632] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2632] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2632] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($31) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $31
    // [2638] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2638] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2639] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [2640] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2641] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [2642] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall38
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2644] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2638] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2638] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
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
    .label vera_action_text = $66
    // vera_read::bank_set_bram1
    // BRAM = bank
    // [2646] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // vera_read::@16
    // if(info_status == STATUS_READING)
    // [2647] if(vera_read::info_status#12==STATUS_READING) goto vera_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [2649] phi from vera_read::@16 to vera_read::@2 [phi:vera_read::@16->vera_read::@2]
    // [2649] phi vera_read::vera_bram_bank#14 = 0 [phi:vera_read::@16->vera_read::@2#0] -- vbum1=vbuc1 
    lda #0
    sta vera_bram_bank
    // [2649] phi vera_read::vera_action_text#10 = smc_action_text#2 [phi:vera_read::@16->vera_read::@2#1] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z vera_action_text
    lda #>smc_action_text_1
    sta.z vera_action_text+1
    jmp __b2
    // [2648] phi from vera_read::@16 to vera_read::@1 [phi:vera_read::@16->vera_read::@1]
    // vera_read::@1
  __b1:
    // [2649] phi from vera_read::@1 to vera_read::@2 [phi:vera_read::@1->vera_read::@2]
    // [2649] phi vera_read::vera_bram_bank#14 = 1 [phi:vera_read::@1->vera_read::@2#0] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2649] phi vera_read::vera_action_text#10 = smc_action_text#1 [phi:vera_read::@1->vera_read::@2#1] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z vera_action_text
    lda #>smc_action_text
    sta.z vera_action_text+1
    // vera_read::@2
  __b2:
    // vera_read::bank_set_brom1
    // BROM = bank
    // [2650] BROM = vera_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [2651] phi from vera_read::bank_set_brom1 to vera_read::@17 [phi:vera_read::bank_set_brom1->vera_read::@17]
    // vera_read::@17
    // display_action_text("Opening VERA.BIN from SD card ...")
    // [2652] call display_action_text
    // [1358] phi from vera_read::@17 to display_action_text [phi:vera_read::@17->display_action_text]
    // [1358] phi display_action_text::info_text#25 = vera_read::info_text [phi:vera_read::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2653] phi from vera_read::@17 to vera_read::@19 [phi:vera_read::@17->vera_read::@19]
    // vera_read::@19
    // FILE *fp = fopen("VERA.BIN", "r")
    // [2654] call fopen
    // [2436] phi from vera_read::@19 to fopen [phi:vera_read::@19->fopen]
    // [2436] phi __errno#473 = __errno#100 [phi:vera_read::@19->fopen#0] -- register_copy 
    // [2436] phi fopen::pathtoken#0 = vera_read::path [phi:vera_read::@19->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2436] phi __stdio_filecount#27 = __stdio_filecount#123 [phi:vera_read::@19->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("VERA.BIN", "r")
    // [2655] fopen::return#3 = fopen::return#2
    // vera_read::@20
    // [2656] vera_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [2657] if((struct $2 *)0==vera_read::fp#0) goto vera_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [2658] phi from vera_read::@20 to vera_read::@4 [phi:vera_read::@20->vera_read::@4]
    // vera_read::@4
    // gotoxy(x, y)
    // [2659] call gotoxy
    // [802] phi from vera_read::@4 to gotoxy [phi:vera_read::@4->gotoxy]
    // [802] phi gotoxy::y#37 = PROGRESS_Y [phi:vera_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:vera_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2660] phi from vera_read::@4 to vera_read::@5 [phi:vera_read::@4->vera_read::@5]
    // [2660] phi vera_read::y#11 = PROGRESS_Y [phi:vera_read::@4->vera_read::@5#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2660] phi vera_read::progress_row_current#10 = 0 [phi:vera_read::@4->vera_read::@5#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2660] phi vera_read::vera_bram_ptr#13 = (char *)$a000 [phi:vera_read::@4->vera_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2660] phi vera_read::vera_bram_bank#10 = vera_read::vera_bram_bank#14 [phi:vera_read::@4->vera_read::@5#3] -- register_copy 
    // [2660] phi vera_read::vera_file_size#11 = 0 [phi:vera_read::@4->vera_read::@5#4] -- vdum1=vduc1 
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
    // [2661] if(vera_read::vera_file_size#11<vera_size) goto vera_read::@6 -- vdum1_lt_vduc1_then_la1 
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
    // [2662] fclose::stream#0 = vera_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [2663] call fclose
    // [2571] phi from vera_read::@9 to fclose [phi:vera_read::@9->fclose]
    // [2571] phi fclose::stream#3 = fclose::stream#0 [phi:vera_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [2664] phi from vera_read::@9 to vera_read::@3 [phi:vera_read::@9->vera_read::@3]
    // [2664] phi __stdio_filecount#36 = __stdio_filecount#2 [phi:vera_read::@9->vera_read::@3#0] -- register_copy 
    // [2664] phi vera_read::return#0 = vera_read::vera_file_size#11 [phi:vera_read::@9->vera_read::@3#1] -- register_copy 
    rts
    // [2664] phi from vera_read::@20 to vera_read::@3 [phi:vera_read::@20->vera_read::@3]
  __b4:
    // [2664] phi __stdio_filecount#36 = __stdio_filecount#1 [phi:vera_read::@20->vera_read::@3#0] -- register_copy 
    // [2664] phi vera_read::return#0 = 0 [phi:vera_read::@20->vera_read::@3#1] -- vdum1=vduc1 
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
    // [2665] return 
    rts
    // vera_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [2666] if(vera_read::info_status#12!=STATUS_CHECKING) goto vera_read::@23 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b7
    // [2668] phi from vera_read::@6 to vera_read::@7 [phi:vera_read::@6->vera_read::@7]
    // [2668] phi vera_read::vera_bram_ptr#10 = (char *) 1024 [phi:vera_read::@6->vera_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z vera_bram_ptr
    lda #>$400
    sta.z vera_bram_ptr+1
    // [2667] phi from vera_read::@6 to vera_read::@23 [phi:vera_read::@6->vera_read::@23]
    // vera_read::@23
    // [2668] phi from vera_read::@23 to vera_read::@7 [phi:vera_read::@23->vera_read::@7]
    // [2668] phi vera_read::vera_bram_ptr#10 = vera_read::vera_bram_ptr#13 [phi:vera_read::@23->vera_read::@7#0] -- register_copy 
    // vera_read::@7
  __b7:
    // display_action_text_reading(vera_action_text, "VERA.BIN", vera_file_size, vera_size, vera_bram_bank, vera_bram_ptr)
    // [2669] display_action_text_reading::action#0 = vera_read::vera_action_text#10 -- pbuz1=pbuz2 
    lda.z vera_action_text
    sta.z display_action_text_reading.action
    lda.z vera_action_text+1
    sta.z display_action_text_reading.action+1
    // [2670] display_action_text_reading::bytes#0 = vera_read::vera_file_size#11 -- vdum1=vdum2 
    lda vera_file_size
    sta display_action_text_reading.bytes
    lda vera_file_size+1
    sta display_action_text_reading.bytes+1
    lda vera_file_size+2
    sta display_action_text_reading.bytes+2
    lda vera_file_size+3
    sta display_action_text_reading.bytes+3
    // [2671] display_action_text_reading::bram_bank#0 = vera_read::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta display_action_text_reading.bram_bank
    // [2672] display_action_text_reading::bram_ptr#0 = vera_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [2673] call display_action_text_reading
    // [2600] phi from vera_read::@7 to display_action_text_reading [phi:vera_read::@7->display_action_text_reading]
    // [2600] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#0 [phi:vera_read::@7->display_action_text_reading#0] -- register_copy 
    // [2600] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#0 [phi:vera_read::@7->display_action_text_reading#1] -- register_copy 
    // [2600] phi display_action_text_reading::size#10 = vera_size [phi:vera_read::@7->display_action_text_reading#2] -- vdum1=vduc1 
    lda #<vera_size
    sta display_action_text_reading.size
    lda #>vera_size
    sta display_action_text_reading.size+1
    lda #<vera_size>>$10
    sta display_action_text_reading.size+2
    lda #>vera_size>>$10
    sta display_action_text_reading.size+3
    // [2600] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#0 [phi:vera_read::@7->display_action_text_reading#3] -- register_copy 
    // [2600] phi display_action_text_reading::file#3 = vera_read::path [phi:vera_read::@7->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2600] phi display_action_text_reading::action#3 = display_action_text_reading::action#0 [phi:vera_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // vera_read::bank_set_bram2
    // BRAM = bank
    // [2674] BRAM = vera_read::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // vera_read::@18
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [2675] fgets::ptr#2 = vera_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z fgets.ptr
    lda.z vera_bram_ptr+1
    sta.z fgets.ptr+1
    // [2676] fgets::stream#0 = vera_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [2677] call fgets
    // [2517] phi from vera_read::@18 to fgets [phi:vera_read::@18->fgets]
    // [2517] phi fgets::ptr#14 = fgets::ptr#2 [phi:vera_read::@18->fgets#0] -- register_copy 
    // [2517] phi fgets::size#10 = VERA_PROGRESS_CELL [phi:vera_read::@18->fgets#1] -- vwum1=vbuc1 
    lda #<VERA_PROGRESS_CELL
    sta fgets.size
    lda #>VERA_PROGRESS_CELL
    sta fgets.size+1
    // [2517] phi fgets::stream#4 = fgets::stream#0 [phi:vera_read::@18->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [2678] fgets::return#10 = fgets::return#1
    // vera_read::@21
    // [2679] vera_read::vera_package_read#0 = fgets::return#10 -- vwum1=vwum2 
    lda fgets.return
    sta vera_package_read
    lda fgets.return+1
    sta vera_package_read+1
    // if (!vera_package_read)
    // [2680] if(0!=vera_read::vera_package_read#0) goto vera_read::@8 -- 0_neq_vwum1_then_la1 
    lda vera_package_read
    ora vera_package_read+1
    bne __b8
    jmp __b9
    // vera_read::@8
  __b8:
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [2681] if(vera_read::progress_row_current#10!=VERA_PROGRESS_ROW) goto vera_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b10
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b10
    // vera_read::@13
    // gotoxy(x, ++y);
    // [2682] vera_read::y#1 = ++ vera_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [2683] gotoxy::y#6 = vera_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2684] call gotoxy
    // [802] phi from vera_read::@13 to gotoxy [phi:vera_read::@13->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#6 [phi:vera_read::@13->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:vera_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2685] phi from vera_read::@13 to vera_read::@10 [phi:vera_read::@13->vera_read::@10]
    // [2685] phi vera_read::y#22 = vera_read::y#1 [phi:vera_read::@13->vera_read::@10#0] -- register_copy 
    // [2685] phi vera_read::progress_row_current#4 = 0 [phi:vera_read::@13->vera_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2685] phi from vera_read::@8 to vera_read::@10 [phi:vera_read::@8->vera_read::@10]
    // [2685] phi vera_read::y#22 = vera_read::y#11 [phi:vera_read::@8->vera_read::@10#0] -- register_copy 
    // [2685] phi vera_read::progress_row_current#4 = vera_read::progress_row_current#10 [phi:vera_read::@8->vera_read::@10#1] -- register_copy 
    // vera_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [2686] if(vera_read::info_status#12!=STATUS_READING) goto vera_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // vera_read::@14
    // cputc('.')
    // [2687] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [2688] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_read::@11
  __b11:
    // vera_bram_ptr += vera_package_read
    // [2690] vera_read::vera_bram_ptr#2 = vera_read::vera_bram_ptr#10 + vera_read::vera_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z vera_bram_ptr
    adc vera_package_read
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc vera_package_read+1
    sta.z vera_bram_ptr+1
    // vera_file_size += vera_package_read
    // [2691] vera_read::vera_file_size#1 = vera_read::vera_file_size#11 + vera_read::vera_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [2692] vera_read::progress_row_current#15 = vera_read::progress_row_current#4 + vera_read::vera_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_current
    adc vera_package_read
    sta progress_row_current
    lda progress_row_current+1
    adc vera_package_read+1
    sta progress_row_current+1
    // if (vera_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [2693] if(vera_read::vera_bram_ptr#2!=(char *)$c000) goto vera_read::@12 -- pbuz1_neq_pbuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b12
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b12
    // vera_read::@15
    // vera_bram_bank++;
    // [2694] vera_read::vera_bram_bank#2 = ++ vera_read::vera_bram_bank#10 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2695] phi from vera_read::@15 to vera_read::@12 [phi:vera_read::@15->vera_read::@12]
    // [2695] phi vera_read::vera_bram_bank#13 = vera_read::vera_bram_bank#2 [phi:vera_read::@15->vera_read::@12#0] -- register_copy 
    // [2695] phi vera_read::vera_bram_ptr#8 = (char *)$a000 [phi:vera_read::@15->vera_read::@12#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2695] phi from vera_read::@11 to vera_read::@12 [phi:vera_read::@11->vera_read::@12]
    // [2695] phi vera_read::vera_bram_bank#13 = vera_read::vera_bram_bank#10 [phi:vera_read::@11->vera_read::@12#0] -- register_copy 
    // [2695] phi vera_read::vera_bram_ptr#8 = vera_read::vera_bram_ptr#2 [phi:vera_read::@11->vera_read::@12#1] -- register_copy 
    // vera_read::@12
  __b12:
    // if (vera_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [2696] if(vera_read::vera_bram_ptr#8!=(char *)$9800) goto vera_read::@22 -- pbuz1_neq_pbuc1_then_la1 
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
    // [2660] phi from vera_read::@12 to vera_read::@5 [phi:vera_read::@12->vera_read::@5]
    // [2660] phi vera_read::y#11 = vera_read::y#22 [phi:vera_read::@12->vera_read::@5#0] -- register_copy 
    // [2660] phi vera_read::progress_row_current#10 = vera_read::progress_row_current#15 [phi:vera_read::@12->vera_read::@5#1] -- register_copy 
    // [2660] phi vera_read::vera_bram_ptr#13 = (char *)$a000 [phi:vera_read::@12->vera_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2660] phi vera_read::vera_bram_bank#10 = 1 [phi:vera_read::@12->vera_read::@5#3] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2660] phi vera_read::vera_file_size#11 = vera_read::vera_file_size#1 [phi:vera_read::@12->vera_read::@5#4] -- register_copy 
    jmp __b5
    // [2697] phi from vera_read::@12 to vera_read::@22 [phi:vera_read::@12->vera_read::@22]
    // vera_read::@22
    // [2660] phi from vera_read::@22 to vera_read::@5 [phi:vera_read::@22->vera_read::@5]
    // [2660] phi vera_read::y#11 = vera_read::y#22 [phi:vera_read::@22->vera_read::@5#0] -- register_copy 
    // [2660] phi vera_read::progress_row_current#10 = vera_read::progress_row_current#15 [phi:vera_read::@22->vera_read::@5#1] -- register_copy 
    // [2660] phi vera_read::vera_bram_ptr#13 = vera_read::vera_bram_ptr#8 [phi:vera_read::@22->vera_read::@5#2] -- register_copy 
    // [2660] phi vera_read::vera_bram_bank#10 = vera_read::vera_bram_bank#13 [phi:vera_read::@22->vera_read::@5#3] -- register_copy 
    // [2660] phi vera_read::vera_file_size#11 = vera_read::vera_file_size#1 [phi:vera_read::@22->vera_read::@5#4] -- register_copy 
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
// void uctoa(__mem() char value, __zp($38) char *buffer, __mem() char radix)
uctoa: {
    .label uctoa__4 = $29
    .label buffer = $38
    .label digit_values = $4a
    // if(radix==DECIMAL)
    // [2698] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2699] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2700] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2701] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2702] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2703] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2704] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2705] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2706] return 
    rts
    // [2707] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2707] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2707] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2707] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2707] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2707] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2707] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2707] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2707] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2707] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2707] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2707] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2708] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2708] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2708] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2708] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2708] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2709] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2710] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2711] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2712] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2713] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2714] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [2715] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2716] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [2717] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2717] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2717] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2717] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2718] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2708] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2708] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2708] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2708] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2708] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2719] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2720] uctoa_append::value#0 = uctoa::value#2
    // [2721] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2722] call uctoa_append
    // [3338] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2723] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2724] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2725] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2717] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2717] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2717] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2717] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
// void printf_number_buffer(__zp($3b) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $4a
    .label putc = $3b
    // if(format.min_length)
    // [2727] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [2728] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [2729] call strlen
    // [2631] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2631] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [2730] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [2731] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [2732] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [2733] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [2734] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [2735] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [2735] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [2736] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [2737] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [2739] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [2739] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [2738] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [2739] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [2739] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [2740] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [2741] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [2742] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2743] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2744] call printf_padding
    // [2637] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2637] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2637] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2637] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2745] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2746] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [2747] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall40
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2749] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2750] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2751] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2752] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2753] call printf_padding
    // [2637] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2637] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2637] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [2637] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2754] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2755] call printf_str
    // [1210] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [1210] phi printf_str::putc#84 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [1210] phi printf_str::s#84 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2756] return 
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
    .label vera_bram_ptr = $62
    // vera_verify::bank_set_bram1
    // BRAM = bank
    // [2758] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // vera_verify::@11
    // unsigned long vera_boundary = vera_file_size
    // [2759] vera_verify::vera_boundary#0 = vera_file_size#1 -- vdum1=vdum2 
    lda vera_file_size
    sta vera_boundary
    lda vera_file_size+1
    sta vera_boundary+1
    lda vera_file_size+2
    sta vera_boundary+2
    lda vera_file_size+3
    sta vera_boundary+3
    // [2760] spi_manufacturer#598 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [2761] spi_memory_type#599 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [2762] spi_memory_capacity#600 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_COMPARING, "Comparing VERA ...")
    // [2763] call display_info_vera
    // [998] phi from vera_verify::@11 to display_info_vera [phi:vera_verify::@11->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = vera_verify::info_text [phi:vera_verify::@11->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_vera.info_text
    lda #>info_text
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#600 [phi:vera_verify::@11->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#599 [phi:vera_verify::@11->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#598 [phi:vera_verify::@11->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_COMPARING [phi:vera_verify::@11->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [2764] phi from vera_verify::@11 to vera_verify::@12 [phi:vera_verify::@11->vera_verify::@12]
    // vera_verify::@12
    // gotoxy(x, y)
    // [2765] call gotoxy
    // [802] phi from vera_verify::@12 to gotoxy [phi:vera_verify::@12->gotoxy]
    // [802] phi gotoxy::y#37 = PROGRESS_Y [phi:vera_verify::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:vera_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2766] phi from vera_verify::@12 to vera_verify::@13 [phi:vera_verify::@12->vera_verify::@13]
    // vera_verify::@13
    // spi_read_flash(0UL)
    // [2767] call spi_read_flash
    // [3345] phi from vera_verify::@13 to spi_read_flash [phi:vera_verify::@13->spi_read_flash]
    jsr spi_read_flash
    // [2768] phi from vera_verify::@13 to vera_verify::@1 [phi:vera_verify::@13->vera_verify::@1]
    // [2768] phi vera_verify::y#3 = PROGRESS_Y [phi:vera_verify::@13->vera_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2768] phi vera_verify::progress_row_current#3 = 0 [phi:vera_verify::@13->vera_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2768] phi vera_verify::vera_different_bytes#11 = 0 [phi:vera_verify::@13->vera_verify::@1#2] -- vdum1=vduc1 
    sta vera_different_bytes
    sta vera_different_bytes+1
    lda #<0>>$10
    sta vera_different_bytes+2
    lda #>0>>$10
    sta vera_different_bytes+3
    // [2768] phi vera_verify::vera_bram_ptr#10 = (char *)$a000 [phi:vera_verify::@13->vera_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2768] phi vera_verify::vera_bram_bank#11 = 1 [phi:vera_verify::@13->vera_verify::@1#4] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2768] phi vera_verify::vera_address#11 = 0 [phi:vera_verify::@13->vera_verify::@1#5] -- vdum1=vduc1 
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
    // [2769] if(vera_verify::vera_address#11<vera_verify::vera_boundary#0) goto vera_verify::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [2770] return 
    rts
    // vera_verify::@2
  __b2:
    // unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_ptr, VERA_PROGRESS_CELL)
    // [2771] vera_compare::bank_ram#0 = vera_verify::vera_bram_bank#11 -- vbum1=vbum2 
    lda vera_bram_bank
    sta vera_compare.bank_ram
    // [2772] vera_compare::bram_ptr#0 = vera_verify::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z vera_compare.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z vera_compare.bram_ptr+1
    // [2773] call vera_compare
  // {asm{.byte $db}}
    // [3356] phi from vera_verify::@2 to vera_compare [phi:vera_verify::@2->vera_compare]
    jsr vera_compare
    // unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_ptr, VERA_PROGRESS_CELL)
    // [2774] vera_compare::return#0 = vera_compare::equal_bytes#2
    // vera_verify::@14
    // [2775] vera_verify::equal_bytes#0 = vera_compare::return#0
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [2776] if(vera_verify::progress_row_current#3!=VERA_PROGRESS_ROW) goto vera_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b3
    // vera_verify::@8
    // gotoxy(x, ++y);
    // [2777] vera_verify::y#1 = ++ vera_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [2778] gotoxy::y#8 = vera_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2779] call gotoxy
    // [802] phi from vera_verify::@8 to gotoxy [phi:vera_verify::@8->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#8 [phi:vera_verify::@8->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = PROGRESS_X [phi:vera_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [2780] phi from vera_verify::@8 to vera_verify::@3 [phi:vera_verify::@8->vera_verify::@3]
    // [2780] phi vera_verify::y#10 = vera_verify::y#1 [phi:vera_verify::@8->vera_verify::@3#0] -- register_copy 
    // [2780] phi vera_verify::progress_row_current#4 = 0 [phi:vera_verify::@8->vera_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2780] phi from vera_verify::@14 to vera_verify::@3 [phi:vera_verify::@14->vera_verify::@3]
    // [2780] phi vera_verify::y#10 = vera_verify::y#3 [phi:vera_verify::@14->vera_verify::@3#0] -- register_copy 
    // [2780] phi vera_verify::progress_row_current#4 = vera_verify::progress_row_current#3 [phi:vera_verify::@14->vera_verify::@3#1] -- register_copy 
    // vera_verify::@3
  __b3:
    // if (equal_bytes != VERA_PROGRESS_CELL)
    // [2781] if(vera_verify::equal_bytes#0!=VERA_PROGRESS_CELL) goto vera_verify::@4 -- vwum1_neq_vbuc1_then_la1 
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
    // [2782] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [2783] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_verify::@5
  __b5:
    // vera_bram_ptr += VERA_PROGRESS_CELL
    // [2785] vera_verify::vera_bram_ptr#1 = vera_verify::vera_bram_ptr#10 + VERA_PROGRESS_CELL -- pbuz1=pbuz1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc.z vera_bram_ptr
    sta.z vera_bram_ptr
    bcc !+
    inc.z vera_bram_ptr+1
  !:
    // vera_address += VERA_PROGRESS_CELL
    // [2786] vera_verify::vera_address#1 = vera_verify::vera_address#11 + VERA_PROGRESS_CELL -- vdum1=vdum1_plus_vbuc1 
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
    // [2787] vera_verify::progress_row_current#11 = vera_verify::progress_row_current#4 + VERA_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc progress_row_current
    sta progress_row_current
    bcc !+
    inc progress_row_current+1
  !:
    // if (vera_bram_ptr == BRAM_HIGH)
    // [2788] if(vera_verify::vera_bram_ptr#1!=$c000) goto vera_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b6
    // vera_verify::@10
    // vera_bram_bank++;
    // [2789] vera_verify::vera_bram_bank#1 = ++ vera_verify::vera_bram_bank#11 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2790] phi from vera_verify::@10 to vera_verify::@6 [phi:vera_verify::@10->vera_verify::@6]
    // [2790] phi vera_verify::vera_bram_bank#25 = vera_verify::vera_bram_bank#1 [phi:vera_verify::@10->vera_verify::@6#0] -- register_copy 
    // [2790] phi vera_verify::vera_bram_ptr#6 = (char *)$a000 [phi:vera_verify::@10->vera_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2790] phi from vera_verify::@5 to vera_verify::@6 [phi:vera_verify::@5->vera_verify::@6]
    // [2790] phi vera_verify::vera_bram_bank#25 = vera_verify::vera_bram_bank#11 [phi:vera_verify::@5->vera_verify::@6#0] -- register_copy 
    // [2790] phi vera_verify::vera_bram_ptr#6 = vera_verify::vera_bram_ptr#1 [phi:vera_verify::@5->vera_verify::@6#1] -- register_copy 
    // vera_verify::@6
  __b6:
    // if (vera_bram_ptr == RAM_HIGH)
    // [2791] if(vera_verify::vera_bram_ptr#6!=$9800) goto vera_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b7
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b7
    // [2793] phi from vera_verify::@6 to vera_verify::@7 [phi:vera_verify::@6->vera_verify::@7]
    // [2793] phi vera_verify::vera_bram_ptr#11 = (char *)$a000 [phi:vera_verify::@6->vera_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2793] phi vera_verify::vera_bram_bank#10 = 1 [phi:vera_verify::@6->vera_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2792] phi from vera_verify::@6 to vera_verify::@24 [phi:vera_verify::@6->vera_verify::@24]
    // vera_verify::@24
    // [2793] phi from vera_verify::@24 to vera_verify::@7 [phi:vera_verify::@24->vera_verify::@7]
    // [2793] phi vera_verify::vera_bram_ptr#11 = vera_verify::vera_bram_ptr#6 [phi:vera_verify::@24->vera_verify::@7#0] -- register_copy 
    // [2793] phi vera_verify::vera_bram_bank#10 = vera_verify::vera_bram_bank#25 [phi:vera_verify::@24->vera_verify::@7#1] -- register_copy 
    // vera_verify::@7
  __b7:
    // VERA_PROGRESS_CELL - equal_bytes
    // [2794] vera_verify::$16 = VERA_PROGRESS_CELL - vera_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<VERA_PROGRESS_CELL
    sbc equal_bytes
    sta.z vera_verify__16
    lda #>VERA_PROGRESS_CELL
    sbc equal_bytes+1
    sta.z vera_verify__16+1
    // vera_different_bytes += (VERA_PROGRESS_CELL - equal_bytes)
    // [2795] vera_verify::vera_different_bytes#1 = vera_verify::vera_different_bytes#11 + vera_verify::$16 -- vdum1=vdum1_plus_vwuz2 
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
    // [2796] call snprintf_init
    // [1205] phi from vera_verify::@7 to snprintf_init [phi:vera_verify::@7->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:vera_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2797] phi from vera_verify::@7 to vera_verify::@15 [phi:vera_verify::@7->vera_verify::@15]
    // vera_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2798] call printf_str
    // [1210] phi from vera_verify::@15 to printf_str [phi:vera_verify::@15->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:vera_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s [phi:vera_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2799] printf_ulong::uvalue#0 = vera_verify::vera_different_bytes#1 -- vdum1=vdum2 
    lda vera_different_bytes
    sta printf_ulong.uvalue
    lda vera_different_bytes+1
    sta printf_ulong.uvalue+1
    lda vera_different_bytes+2
    sta printf_ulong.uvalue+2
    lda vera_different_bytes+3
    sta printf_ulong.uvalue+3
    // [2800] call printf_ulong
    // [1761] phi from vera_verify::@16 to printf_ulong [phi:vera_verify::@16->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:vera_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:vera_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:vera_verify::@16->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#0 [phi:vera_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2801] phi from vera_verify::@16 to vera_verify::@17 [phi:vera_verify::@16->vera_verify::@17]
    // vera_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2802] call printf_str
    // [1210] phi from vera_verify::@17 to printf_str [phi:vera_verify::@17->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:vera_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s1 [phi:vera_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2803] printf_uchar::uvalue#0 = vera_verify::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta printf_uchar.uvalue
    // [2804] call printf_uchar
    // [1347] phi from vera_verify::@18 to printf_uchar [phi:vera_verify::@18->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:vera_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 2 [phi:vera_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:vera_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:vera_verify::@18->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#0 [phi:vera_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2805] phi from vera_verify::@18 to vera_verify::@19 [phi:vera_verify::@18->vera_verify::@19]
    // vera_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2806] call printf_str
    // [1210] phi from vera_verify::@19 to printf_str [phi:vera_verify::@19->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:vera_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s2 [phi:vera_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2807] printf_uint::uvalue#0 = (unsigned int)vera_verify::vera_bram_ptr#11 -- vwum1=vwuz2 
    lda.z vera_bram_ptr
    sta printf_uint.uvalue
    lda.z vera_bram_ptr+1
    sta printf_uint.uvalue+1
    // [2808] call printf_uint
    // [2106] phi from vera_verify::@20 to printf_uint [phi:vera_verify::@20->printf_uint]
    // [2106] phi printf_uint::format_zero_padding#10 = 1 [phi:vera_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2106] phi printf_uint::format_min_length#10 = 4 [phi:vera_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2106] phi printf_uint::putc#10 = &snputc [phi:vera_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2106] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:vera_verify::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2106] phi printf_uint::uvalue#10 = printf_uint::uvalue#0 [phi:vera_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2809] phi from vera_verify::@20 to vera_verify::@21 [phi:vera_verify::@20->vera_verify::@21]
    // vera_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2810] call printf_str
    // [1210] phi from vera_verify::@21 to printf_str [phi:vera_verify::@21->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:vera_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s3 [phi:vera_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2811] printf_ulong::uvalue#1 = vera_verify::vera_address#1 -- vdum1=vdum2 
    lda vera_address
    sta printf_ulong.uvalue
    lda vera_address+1
    sta printf_ulong.uvalue+1
    lda vera_address+2
    sta printf_ulong.uvalue+2
    lda vera_address+3
    sta printf_ulong.uvalue+3
    // [2812] call printf_ulong
    // [1761] phi from vera_verify::@22 to printf_ulong [phi:vera_verify::@22->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:vera_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:vera_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:vera_verify::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#1 [phi:vera_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // vera_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [2813] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2814] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2816] call display_action_text
    // [1358] phi from vera_verify::@23 to display_action_text [phi:vera_verify::@23->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:vera_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2768] phi from vera_verify::@23 to vera_verify::@1 [phi:vera_verify::@23->vera_verify::@1]
    // [2768] phi vera_verify::y#3 = vera_verify::y#10 [phi:vera_verify::@23->vera_verify::@1#0] -- register_copy 
    // [2768] phi vera_verify::progress_row_current#3 = vera_verify::progress_row_current#11 [phi:vera_verify::@23->vera_verify::@1#1] -- register_copy 
    // [2768] phi vera_verify::vera_different_bytes#11 = vera_verify::vera_different_bytes#1 [phi:vera_verify::@23->vera_verify::@1#2] -- register_copy 
    // [2768] phi vera_verify::vera_bram_ptr#10 = vera_verify::vera_bram_ptr#11 [phi:vera_verify::@23->vera_verify::@1#3] -- register_copy 
    // [2768] phi vera_verify::vera_bram_bank#11 = vera_verify::vera_bram_bank#10 [phi:vera_verify::@23->vera_verify::@1#4] -- register_copy 
    // [2768] phi vera_verify::vera_address#11 = vera_verify::vera_address#1 [phi:vera_verify::@23->vera_verify::@1#5] -- register_copy 
    jmp __b1
    // vera_verify::@4
  __b4:
    // cputc('*')
    // [2817] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [2818] callexecute cputc  -- call_vprc1 
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
    .label vera_erase__3 = $76
    // BYTE2(vera_file_size)
    // [2820] vera_erase::$0 = byte2  vera_file_size#1 -- vbuz1=_byte2_vdum2 
    lda vera_file_size+2
    sta.z vera_erase__0
    // unsigned char vera_total_64k_blocks = BYTE2(vera_file_size)+1
    // [2821] vera_erase::vera_total_64k_blocks#0 = vera_erase::$0 + 1 -- vbum1=vbuz2_plus_1 
    inc
    sta vera_total_64k_blocks
    // [2822] phi from vera_erase to vera_erase::@1 [phi:vera_erase->vera_erase::@1]
    // [2822] phi vera_erase::vera_address#2 = 0 [phi:vera_erase->vera_erase::@1#0] -- vdum1=vduc1 
    lda #<0
    sta vera_address
    sta vera_address+1
    lda #<0>>$10
    sta vera_address+2
    lda #>0>>$10
    sta vera_address+3
    // [2822] phi vera_erase::vera_current_64k_block#2 = 0 [phi:vera_erase->vera_erase::@1#1] -- vbum1=vbuc1 
    lda #0
    sta vera_current_64k_block
    // vera_erase::@1
  __b1:
    // while(vera_current_64k_block < vera_total_64k_blocks)
    // [2823] if(vera_erase::vera_current_64k_block#2<vera_erase::vera_total_64k_blocks#0) goto vera_erase::@2 -- vbum1_lt_vbum2_then_la1 
    lda vera_current_64k_block
    cmp vera_total_64k_blocks
    bcc __b2
    // [2824] phi from vera_erase::@1 to vera_erase::@return [phi:vera_erase::@1->vera_erase::@return]
    // [2824] phi vera_erase::return#2 = 0 [phi:vera_erase::@1->vera_erase::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // vera_erase::@return
    // }
    // [2825] return 
    rts
    // [2826] phi from vera_erase::@1 to vera_erase::@2 [phi:vera_erase::@1->vera_erase::@2]
    // vera_erase::@2
  __b2:
    // spi_wait_non_busy()
    // [2827] call spi_wait_non_busy
    // [3370] phi from vera_erase::@2 to spi_wait_non_busy [phi:vera_erase::@2->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // spi_wait_non_busy()
    // [2828] spi_wait_non_busy::return#4 = spi_wait_non_busy::return#3
    // vera_erase::@4
    // [2829] vera_erase::$3 = spi_wait_non_busy::return#4 -- vbuz1=vbum2 
    lda spi_wait_non_busy.return
    sta.z vera_erase__3
    // if(!spi_wait_non_busy())
    // [2830] if(0==vera_erase::$3) goto vera_erase::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // [2824] phi from vera_erase::@4 to vera_erase::@return [phi:vera_erase::@4->vera_erase::@return]
    // [2824] phi vera_erase::return#2 = 1 [phi:vera_erase::@4->vera_erase::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // vera_erase::@3
  __b3:
    // spi_block_erase(vera_address)
    // [2831] spi_block_erase::data#0 = vera_erase::vera_address#2 -- vdum1=vdum2 
    lda vera_address
    sta spi_block_erase.data
    lda vera_address+1
    sta spi_block_erase.data+1
    lda vera_address+2
    sta spi_block_erase.data+2
    lda vera_address+3
    sta spi_block_erase.data+3
    // [2832] call spi_block_erase
    // [3387] phi from vera_erase::@3 to spi_block_erase [phi:vera_erase::@3->spi_block_erase]
    jsr spi_block_erase
    // vera_erase::@5
    // vera_address += 0x10000
    // [2833] vera_erase::vera_address#1 = vera_erase::vera_address#2 + $10000 -- vdum1=vdum1_plus_vduc1 
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
    // [2834] vera_erase::vera_current_64k_block#1 = ++ vera_erase::vera_current_64k_block#2 -- vbum1=_inc_vbum1 
    inc vera_current_64k_block
    // [2822] phi from vera_erase::@5 to vera_erase::@1 [phi:vera_erase::@5->vera_erase::@1]
    // [2822] phi vera_erase::vera_address#2 = vera_erase::vera_address#1 [phi:vera_erase::@5->vera_erase::@1#0] -- register_copy 
    // [2822] phi vera_erase::vera_current_64k_block#2 = vera_erase::vera_current_64k_block#1 [phi:vera_erase::@5->vera_erase::@1#1] -- register_copy 
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
    // [2836] phi from display_info_roms to display_info_roms::@1 [phi:display_info_roms->display_info_roms::@1]
    // [2836] phi display_info_roms::rom_chip#2 = 0 [phi:display_info_roms->display_info_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // display_info_roms::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [2837] if(display_info_roms::rom_chip#2<8) goto display_info_roms::@2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b2
    // display_info_roms::@return
    // }
    // [2838] return 
    rts
    // display_info_roms::@2
  __b2:
    // display_info_rom(rom_chip, info_status, info_text)
    // [2839] display_info_rom::rom_chip#4 = display_info_roms::rom_chip#2 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [2840] call display_info_rom
    // [1566] phi from display_info_roms::@2 to display_info_rom [phi:display_info_roms::@2->display_info_rom]
    // [1566] phi display_info_rom::info_text#17 = 0 [phi:display_info_roms::@2->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1566] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#4 [phi:display_info_roms::@2->display_info_rom#1] -- register_copy 
    // [1566] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:display_info_roms::@2->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    // display_info_roms::@3
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [2841] display_info_roms::rom_chip#1 = ++ display_info_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [2836] phi from display_info_roms::@3 to display_info_roms::@1 [phi:display_info_roms::@3->display_info_roms::@1]
    // [2836] phi display_info_roms::rom_chip#2 = display_info_roms::rom_chip#1 [phi:display_info_roms::@3->display_info_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip: .byte 0
}
.segment CodeVera
  // spi_deselect
spi_deselect: {
    // *vera_reg_SPICtrl &= 0xfe
    // [2842] *vera_reg_SPICtrl = *vera_reg_SPICtrl & $fe -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
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
    // [2843] call spi_read
    jsr spi_read
    // spi_deselect::@return
    // }
    // [2844] return 
    rts
}
  // vera_flash
vera_flash: {
    .label vera_flash__8 = $b0
    .label vera_flash__22 = $b2
    .label vera_bram_ptr = $ab
    .label vera_flash__27 = $62
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [2846] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [904] phi from vera_flash to display_action_progress [phi:vera_flash->display_action_progress]
    // [904] phi display_action_progress::info_text#27 = string_0 [phi:vera_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<string_0
    sta.z display_action_progress.info_text
    lda #>string_0
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // vera_flash::@15
    // [2847] spi_manufacturer#597 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [2848] spi_memory_type#598 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [2849] spi_memory_capacity#599 = spi_read::return#10 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHING, "Flashing ...")
    // [2850] call display_info_vera
    // [998] phi from vera_flash::@15 to display_info_vera [phi:vera_flash::@15->display_info_vera]
    // [998] phi display_info_vera::info_text#19 = info_text1 [phi:vera_flash::@15->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [998] phi spi_memory_capacity#106 = spi_memory_capacity#599 [phi:vera_flash::@15->display_info_vera#1] -- register_copy 
    // [998] phi spi_memory_type#107 = spi_memory_type#598 [phi:vera_flash::@15->display_info_vera#2] -- register_copy 
    // [998] phi spi_manufacturer#108 = spi_manufacturer#597 [phi:vera_flash::@15->display_info_vera#3] -- register_copy 
    // [998] phi display_info_vera::info_status#19 = STATUS_FLASHING [phi:vera_flash::@15->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [2851] phi from vera_flash::@15 to vera_flash::@1 [phi:vera_flash::@15->vera_flash::@1]
    // [2851] phi vera_flash::vera_bram_ptr#12 = (char *)$a000 [phi:vera_flash::@15->vera_flash::@1#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2851] phi vera_flash::vera_bram_bank#10 = 1 [phi:vera_flash::@15->vera_flash::@1#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2851] phi vera_flash::y_sector#13 = PROGRESS_Y [phi:vera_flash::@15->vera_flash::@1#2] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [2851] phi vera_flash::x_sector#13 = PROGRESS_X [phi:vera_flash::@15->vera_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [2851] phi vera_flash::vera_address_page#11 = 0 [phi:vera_flash::@15->vera_flash::@1#4] -- vdum1=vduc1 
    lda #<0
    sta vera_address_page
    sta vera_address_page+1
    lda #<0>>$10
    sta vera_address_page+2
    lda #>0>>$10
    sta vera_address_page+3
    // [2851] phi from vera_flash::@11 to vera_flash::@1 [phi:vera_flash::@11->vera_flash::@1]
    // [2851] phi vera_flash::vera_bram_ptr#12 = vera_flash::vera_bram_ptr#22 [phi:vera_flash::@11->vera_flash::@1#0] -- register_copy 
    // [2851] phi vera_flash::vera_bram_bank#10 = vera_flash::vera_bram_bank#18 [phi:vera_flash::@11->vera_flash::@1#1] -- register_copy 
    // [2851] phi vera_flash::y_sector#13 = vera_flash::y_sector#13 [phi:vera_flash::@11->vera_flash::@1#2] -- register_copy 
    // [2851] phi vera_flash::x_sector#13 = vera_flash::x_sector#1 [phi:vera_flash::@11->vera_flash::@1#3] -- register_copy 
    // [2851] phi vera_flash::vera_address_page#11 = vera_flash::vera_address_page#14 [phi:vera_flash::@11->vera_flash::@1#4] -- register_copy 
    // vera_flash::@1
  __b1:
    // while (vera_address_page < vera_file_size)
    // [2852] if(vera_flash::vera_address_page#11<vera_file_size#1) goto vera_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [2853] display_action_text_flashed::bytes#0 = vera_flash::vera_address_page#11 -- vdum1=vdum2 
    lda vera_address_page
    sta display_action_text_flashed.bytes
    lda vera_address_page+1
    sta display_action_text_flashed.bytes+1
    lda vera_address_page+2
    sta display_action_text_flashed.bytes+2
    lda vera_address_page+3
    sta display_action_text_flashed.bytes+3
    // [2854] call display_action_text_flashed
    // [2965] phi from vera_flash::@3 to display_action_text_flashed [phi:vera_flash::@3->display_action_text_flashed]
    // [2965] phi display_action_text_flashed::chip#3 = vera_flash::chip [phi:vera_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2965] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#0 [phi:vera_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [2855] phi from vera_flash::@3 to vera_flash::@18 [phi:vera_flash::@3->vera_flash::@18]
    // vera_flash::@18
    // wait_moment(32)
    // [2856] call wait_moment
    // [1310] phi from vera_flash::@18 to wait_moment [phi:vera_flash::@18->wait_moment]
    // [1310] phi wait_moment::w#13 = $20 [phi:vera_flash::@18->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [2857] phi from vera_flash::@18 to vera_flash::@return [phi:vera_flash::@18->vera_flash::@return]
    // [2857] phi vera_flash::return#2 = vera_flash::vera_address_page#11 [phi:vera_flash::@18->vera_flash::@return#0] -- register_copy 
    // vera_flash::@return
    // }
    // [2858] return 
    rts
    // vera_flash::@2
  __b2:
    // unsigned long vera_page_boundary = vera_address_page + VERA_PROGRESS_PAGE
    // [2859] vera_flash::vera_page_boundary#0 = vera_flash::vera_address_page#11 + VERA_PROGRESS_PAGE -- vdum1=vdum2_plus_vwuc1 
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
    // [2860] cputcxy::x#0 = vera_flash::x_sector#13 -- vbum1=vbum2 
    lda x_sector
    sta cputcxy.x
    // [2861] cputcxy::y#0 = vera_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [2862] call cputcxy
    // [2313] phi from vera_flash::@2 to cputcxy [phi:vera_flash::@2->cputcxy]
    // [2313] phi cputcxy::c#17 = '.' [phi:vera_flash::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #'.'
    sta cputcxy.c
    // [2313] phi cputcxy::y#17 = cputcxy::y#0 [phi:vera_flash::@2->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#0 [phi:vera_flash::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_flash::@16
    // cputc('.')
    // [2863] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [2864] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // spi_wait_non_busy()
    // [2866] call spi_wait_non_busy
    // [3370] phi from vera_flash::@16 to spi_wait_non_busy [phi:vera_flash::@16->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // spi_wait_non_busy()
    // [2867] spi_wait_non_busy::return#5 = spi_wait_non_busy::return#3
    // vera_flash::@17
    // [2868] vera_flash::$8 = spi_wait_non_busy::return#5 -- vbuz1=vbum2 
    lda spi_wait_non_busy.return
    sta.z vera_flash__8
    // if(!spi_wait_non_busy())
    // [2869] if(0==vera_flash::$8) goto vera_flash::bank_set_bram1 -- 0_eq_vbuz1_then_la1 
    beq bank_set_bram1
    // [2857] phi from vera_flash::@17 to vera_flash::@return [phi:vera_flash::@17->vera_flash::@return]
    // [2857] phi vera_flash::return#2 = 0 [phi:vera_flash::@17->vera_flash::@return#0] -- vdum1=vbuc1 
    lda #0
    sta return
    sta return+1
    sta return+2
    sta return+3
    rts
    // vera_flash::bank_set_bram1
  bank_set_bram1:
    // BRAM = bank
    // [2870] BRAM = vera_flash::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // vera_flash::@14
    // spi_write_page_begin(vera_address_page)
    // [2871] spi_write_page_begin::data#0 = vera_flash::vera_address_page#11 -- vdum1=vdum2 
    lda vera_address_page
    sta spi_write_page_begin.data
    lda vera_address_page+1
    sta spi_write_page_begin.data+1
    lda vera_address_page+2
    sta spi_write_page_begin.data+2
    lda vera_address_page+3
    sta spi_write_page_begin.data+3
    // [2872] call spi_write_page_begin
    // [3412] phi from vera_flash::@14 to spi_write_page_begin [phi:vera_flash::@14->spi_write_page_begin]
    jsr spi_write_page_begin
    // vera_flash::@19
    // [2873] vera_flash::vera_address#16 = vera_flash::vera_address_page#11 -- vdum1=vdum2 
    lda vera_address_page
    sta vera_address
    lda vera_address_page+1
    sta vera_address+1
    lda vera_address_page+2
    sta vera_address+2
    lda vera_address_page+3
    sta vera_address+3
    // [2874] phi from vera_flash::@19 vera_flash::@21 to vera_flash::@5 [phi:vera_flash::@19/vera_flash::@21->vera_flash::@5]
    // [2874] phi vera_flash::vera_address_page#14 = vera_flash::vera_address_page#11 [phi:vera_flash::@19/vera_flash::@21->vera_flash::@5#0] -- register_copy 
    // [2874] phi vera_flash::vera_bram_ptr#13 = vera_flash::vera_bram_ptr#12 [phi:vera_flash::@19/vera_flash::@21->vera_flash::@5#1] -- register_copy 
    // [2874] phi vera_flash::vera_address#10 = vera_flash::vera_address#16 [phi:vera_flash::@19/vera_flash::@21->vera_flash::@5#2] -- register_copy 
    // vera_flash::@5
  __b5:
    // while (vera_address < vera_page_boundary)
    // [2875] if(vera_flash::vera_address#10<vera_flash::vera_page_boundary#0) goto vera_flash::@6 -- vdum1_lt_vdum2_then_la1 
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
    // [2876] if(vera_flash::vera_bram_ptr#13!=$c000) goto vera_flash::@10 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b10
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b10
    // vera_flash::@12
    // vera_bram_bank++;
    // [2877] vera_flash::vera_bram_bank#1 = ++ vera_flash::vera_bram_bank#10 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2878] phi from vera_flash::@12 to vera_flash::@10 [phi:vera_flash::@12->vera_flash::@10]
    // [2878] phi vera_flash::vera_bram_bank#25 = vera_flash::vera_bram_bank#1 [phi:vera_flash::@12->vera_flash::@10#0] -- register_copy 
    // [2878] phi vera_flash::vera_bram_ptr#8 = (char *)$a000 [phi:vera_flash::@12->vera_flash::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2878] phi from vera_flash::@4 to vera_flash::@10 [phi:vera_flash::@4->vera_flash::@10]
    // [2878] phi vera_flash::vera_bram_bank#25 = vera_flash::vera_bram_bank#10 [phi:vera_flash::@4->vera_flash::@10#0] -- register_copy 
    // [2878] phi vera_flash::vera_bram_ptr#8 = vera_flash::vera_bram_ptr#13 [phi:vera_flash::@4->vera_flash::@10#1] -- register_copy 
    // vera_flash::@10
  __b10:
    // if (vera_bram_ptr == RAM_HIGH)
    // [2879] if(vera_flash::vera_bram_ptr#8!=$9800) goto vera_flash::@22 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b11
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b11
    // [2881] phi from vera_flash::@10 to vera_flash::@11 [phi:vera_flash::@10->vera_flash::@11]
    // [2881] phi vera_flash::vera_bram_ptr#22 = (char *)$a000 [phi:vera_flash::@10->vera_flash::@11#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2881] phi vera_flash::vera_bram_bank#18 = 1 [phi:vera_flash::@10->vera_flash::@11#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2880] phi from vera_flash::@10 to vera_flash::@22 [phi:vera_flash::@10->vera_flash::@22]
    // vera_flash::@22
    // [2881] phi from vera_flash::@22 to vera_flash::@11 [phi:vera_flash::@22->vera_flash::@11]
    // [2881] phi vera_flash::vera_bram_ptr#22 = vera_flash::vera_bram_ptr#8 [phi:vera_flash::@22->vera_flash::@11#0] -- register_copy 
    // [2881] phi vera_flash::vera_bram_bank#18 = vera_flash::vera_bram_bank#25 [phi:vera_flash::@22->vera_flash::@11#1] -- register_copy 
    // vera_flash::@11
  __b11:
    // x_sector += 2
    // [2882] vera_flash::x_sector#1 = vera_flash::x_sector#13 + 2 -- vbum1=vbum1_plus_2 
    lda x_sector
    clc
    adc #2
    sta x_sector
    // vera_address_page % VERA_PROGRESS_ROW
    // [2883] vera_flash::$22 = vera_flash::vera_address_page#14 & VERA_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
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
    // [2884] if(0!=vera_flash::$22) goto vera_flash::@1 -- 0_neq_vduz1_then_la1 
    lda.z vera_flash__22
    ora.z vera_flash__22+1
    ora.z vera_flash__22+2
    ora.z vera_flash__22+3
    beq !__b1+
    jmp __b1
  !__b1:
    // vera_flash::@13
    // y_sector++;
    // [2885] vera_flash::y_sector#1 = ++ vera_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [2851] phi from vera_flash::@13 to vera_flash::@1 [phi:vera_flash::@13->vera_flash::@1]
    // [2851] phi vera_flash::vera_bram_ptr#12 = vera_flash::vera_bram_ptr#22 [phi:vera_flash::@13->vera_flash::@1#0] -- register_copy 
    // [2851] phi vera_flash::vera_bram_bank#10 = vera_flash::vera_bram_bank#18 [phi:vera_flash::@13->vera_flash::@1#1] -- register_copy 
    // [2851] phi vera_flash::y_sector#13 = vera_flash::y_sector#1 [phi:vera_flash::@13->vera_flash::@1#2] -- register_copy 
    // [2851] phi vera_flash::x_sector#13 = PROGRESS_X [phi:vera_flash::@13->vera_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [2851] phi vera_flash::vera_address_page#11 = vera_flash::vera_address_page#14 [phi:vera_flash::@13->vera_flash::@1#4] -- register_copy 
    jmp __b1
    // vera_flash::@6
  __b6:
    // display_action_text_flashing(VERA_PROGRESS_PAGE, "VERA", vera_bram_bank, vera_bram_ptr, vera_address)
    // [2886] display_action_text_flashing::bram_bank#0 = vera_flash::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta display_action_text_flashing.bram_bank
    // [2887] display_action_text_flashing::bram_ptr#0 = vera_flash::vera_bram_ptr#13 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [2888] display_action_text_flashing::address#0 = vera_flash::vera_address#10 -- vdum1=vdum2 
    lda vera_address
    sta display_action_text_flashing.address
    lda vera_address+1
    sta display_action_text_flashing.address+1
    lda vera_address+2
    sta display_action_text_flashing.address+2
    lda vera_address+3
    sta display_action_text_flashing.address+3
    // [2889] call display_action_text_flashing
    // [2994] phi from vera_flash::@6 to display_action_text_flashing [phi:vera_flash::@6->display_action_text_flashing]
    // [2994] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#0 [phi:vera_flash::@6->display_action_text_flashing#0] -- register_copy 
    // [2994] phi display_action_text_flashing::chip#10 = vera_flash::chip [phi:vera_flash::@6->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2994] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#0 [phi:vera_flash::@6->display_action_text_flashing#2] -- register_copy 
    // [2994] phi display_action_text_flashing::bram_bank#3 = display_action_text_flashing::bram_bank#0 [phi:vera_flash::@6->display_action_text_flashing#3] -- register_copy 
    // [2994] phi display_action_text_flashing::bytes#3 = VERA_PROGRESS_PAGE [phi:vera_flash::@6->display_action_text_flashing#4] -- vdum1=vduc1 
    lda #<VERA_PROGRESS_PAGE
    sta display_action_text_flashing.bytes
    lda #>VERA_PROGRESS_PAGE
    sta display_action_text_flashing.bytes+1
    lda #<VERA_PROGRESS_PAGE>>$10
    sta display_action_text_flashing.bytes+2
    lda #>VERA_PROGRESS_PAGE>>$10
    sta display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [2890] phi from vera_flash::@6 to vera_flash::@7 [phi:vera_flash::@6->vera_flash::@7]
    // [2890] phi vera_flash::i#2 = 0 [phi:vera_flash::@6->vera_flash::@7#0] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // vera_flash::@7
  __b7:
    // for(unsigned int i=0; i<=255; i++)
    // [2891] if(vera_flash::i#2<=$ff) goto vera_flash::@8 -- vwum1_le_vbuc1_then_la1 
    lda #$ff
    cmp i
    bcc !+
    lda i+1
    beq __b8
  !:
    // vera_flash::@9
    // cputcxy(x,y,'+')
    // [2892] cputcxy::x#1 = vera_flash::x_sector#13 -- vbum1=vbum2 
    lda x_sector
    sta cputcxy.x
    // [2893] cputcxy::y#1 = vera_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [2894] call cputcxy
    // [2313] phi from vera_flash::@9 to cputcxy [phi:vera_flash::@9->cputcxy]
    // [2313] phi cputcxy::c#17 = '+' [phi:vera_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [2313] phi cputcxy::y#17 = cputcxy::y#1 [phi:vera_flash::@9->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#1 [phi:vera_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_flash::@21
    // cputc('+')
    // [2895] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [2896] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_bram_ptr += VERA_PROGRESS_PAGE
    // [2898] vera_flash::vera_bram_ptr#1 = vera_flash::vera_bram_ptr#13 + VERA_PROGRESS_PAGE -- pbuz1=pbuz1_plus_vwuc1 
    lda.z vera_bram_ptr
    clc
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr+1
    // vera_address += VERA_PROGRESS_PAGE
    // [2899] vera_flash::vera_address#1 = vera_flash::vera_address#10 + VERA_PROGRESS_PAGE -- vdum1=vdum1_plus_vwuc1 
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
    // [2900] vera_flash::vera_address_page#1 = vera_flash::vera_address_page#14 + VERA_PROGRESS_PAGE -- vdum1=vdum1_plus_vwuc1 
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
    // [2901] vera_flash::$27 = vera_flash::vera_bram_ptr#13 + vera_flash::i#2 -- pbuz1=pbuz2_plus_vwum3 
    lda.z vera_bram_ptr
    clc
    adc i
    sta.z vera_flash__27
    lda.z vera_bram_ptr+1
    adc i+1
    sta.z vera_flash__27+1
    // [2902] spi_write::data = *vera_flash::$27 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (vera_flash__27),y
    sta spi_write.data
    // [2903] call spi_write
    jsr spi_write
    // vera_flash::@20
    // for(unsigned int i=0; i<=255; i++)
    // [2904] vera_flash::i#1 = ++ vera_flash::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [2890] phi from vera_flash::@20 to vera_flash::@7 [phi:vera_flash::@20->vera_flash::@7]
    // [2890] phi vera_flash::i#2 = vera_flash::i#1 [phi:vera_flash::@20->vera_flash::@7#0] -- register_copy 
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
    // [2906] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbum2 
    lda rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2907] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vdum1=vduz2_rol_vbuc1 
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
    // [2908] return 
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
    .label rom_bank1_rom_compare__0 = $29
    .label rom_bank1_rom_compare__1 = $42
    .label rom_bank1_rom_compare__2 = $50
    .label rom_ptr1_rom_compare__0 = $4c
    .label rom_ptr1_rom_compare__2 = $4c
    .label rom_ptr1_return = $4c
    .label ptr_rom = $4c
    .label ptr_ram = $56
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2910] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2911] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vdum2 
    lda rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2912] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vdum2 
    lda rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2913] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2914] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_compare__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2915] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2916] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vdum2 
    lda rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2917] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2918] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2919] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // [2920] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2921] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2921] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [2921] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2921] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2921] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2922] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [2923] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2924] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2925] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta rom_byte_compare.value
    // [2926] call rom_byte_compare
    jsr rom_byte_compare
    // [2927] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2928] rom_compare::$5 = rom_byte_compare::return#2 -- vbuz1=vbum2 
    lda rom_byte_compare.return
    sta.z rom_compare__5
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2929] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2930] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [2931] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2931] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2932] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2933] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2934] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [2921] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2921] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2921] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2921] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2921] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
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
// void ultoa(__mem() unsigned long value, __zp($38) char *buffer, __mem() char radix)
ultoa: {
    .label ultoa__4 = $42
    .label ultoa__10 = $3a
    .label ultoa__11 = $41
    .label buffer = $38
    .label digit_values = $4a
    // if(radix==DECIMAL)
    // [2935] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2936] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2937] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2938] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2939] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2940] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2941] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2942] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2943] return 
    rts
    // [2944] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2944] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2944] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2944] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2944] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2944] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2944] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2944] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2944] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2944] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2944] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2944] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2945] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2945] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2945] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2945] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2945] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2946] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2947] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2948] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2949] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2950] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2951] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2952] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2953] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2954] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2955] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2956] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2956] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2956] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2956] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2957] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2945] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2945] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2945] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2945] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2945] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2958] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2959] ultoa_append::value#0 = ultoa::value#2
    // [2960] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2961] call ultoa_append
    // [3436] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2962] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2963] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2964] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2956] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2956] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2956] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2956] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
// void display_action_text_flashed(__mem() unsigned long bytes, __zp($4e) char *chip)
display_action_text_flashed: {
    .label chip = $4e
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2966] call snprintf_init
    // [1205] phi from display_action_text_flashed to snprintf_init [phi:display_action_text_flashed->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:display_action_text_flashed->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2967] phi from display_action_text_flashed to display_action_text_flashed::@1 [phi:display_action_text_flashed->display_action_text_flashed::@1]
    // display_action_text_flashed::@1
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2968] call printf_str
    // [1210] phi from display_action_text_flashed::@1 to printf_str [phi:display_action_text_flashed::@1->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashed::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_action_text_flashed::s [phi:display_action_text_flashed::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@2
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2969] printf_ulong::uvalue#4 = display_action_text_flashed::bytes#3 -- vdum1=vdum2 
    lda bytes
    sta printf_ulong.uvalue
    lda bytes+1
    sta printf_ulong.uvalue+1
    lda bytes+2
    sta printf_ulong.uvalue+2
    lda bytes+3
    sta printf_ulong.uvalue+3
    // [2970] call printf_ulong
    // [1761] phi from display_action_text_flashed::@2 to printf_ulong [phi:display_action_text_flashed::@2->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 0 [phi:display_action_text_flashed::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 0 [phi:display_action_text_flashed::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = DECIMAL [phi:display_action_text_flashed::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#4 [phi:display_action_text_flashed::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2971] phi from display_action_text_flashed::@2 to display_action_text_flashed::@3 [phi:display_action_text_flashed::@2->display_action_text_flashed::@3]
    // display_action_text_flashed::@3
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2972] call printf_str
    // [1210] phi from display_action_text_flashed::@3 to printf_str [phi:display_action_text_flashed::@3->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashed::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_action_text_flashed::s1 [phi:display_action_text_flashed::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@4
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2973] printf_string::str#13 = display_action_text_flashed::chip#3 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [2974] call printf_string
    // [1219] phi from display_action_text_flashed::@4 to printf_string [phi:display_action_text_flashed::@4->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:display_action_text_flashed::@4->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#13 [phi:display_action_text_flashed::@4->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_flashed::@4->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_flashed::@4->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2975] phi from display_action_text_flashed::@4 to display_action_text_flashed::@5 [phi:display_action_text_flashed::@4->display_action_text_flashed::@5]
    // display_action_text_flashed::@5
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2976] call printf_str
    // [1210] phi from display_action_text_flashed::@5 to printf_str [phi:display_action_text_flashed::@5->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashed::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s5 [phi:display_action_text_flashed::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@6
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2977] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2978] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2980] call display_action_text
    // [1358] phi from display_action_text_flashed::@6 to display_action_text [phi:display_action_text_flashed::@6->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:display_action_text_flashed::@6->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashed::@return
    // }
    // [2981] return 
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
    // [2983] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_sector_erase__2
    lda address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2984] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2985] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2986] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // [2987] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vdum1=vdum1_plus_vwuc1 
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
    // [2988] call rom_unlock
    // [2414] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2414] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbum1=vbuc1 
    lda #$80
    sta rom_unlock.unlock_code
    // [2414] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2989] rom_unlock::address#1 = rom_sector_erase::address#0 -- vdum1=vdum2 
    lda address
    sta rom_unlock.address
    lda address+1
    sta rom_unlock.address+1
    lda address+2
    sta rom_unlock.address+2
    lda address+3
    sta rom_unlock.address+3
    // [2990] call rom_unlock
    // [2414] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2414] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$30
    sta rom_unlock.unlock_code
    // [2414] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2991] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2992] call rom_wait
    // [3443] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [3443] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2993] return 
    rts
  .segment Data
    .label rom_chip_address = rom_unlock.address
    address: .dword 0
}
.segment Code
  // display_action_text_flashing
// void display_action_text_flashing(__mem() unsigned long bytes, __zp($6b) char *chip, __mem() char bram_bank, __zp($68) char *bram_ptr, __mem() unsigned long address)
display_action_text_flashing: {
    .label bram_ptr = $68
    .label chip = $6b
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2995] call snprintf_init
    // [1205] phi from display_action_text_flashing to snprintf_init [phi:display_action_text_flashing->snprintf_init]
    // [1205] phi snprintf_init::s#31 = info_text [phi:display_action_text_flashing->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2996] phi from display_action_text_flashing to display_action_text_flashing::@1 [phi:display_action_text_flashing->display_action_text_flashing::@1]
    // display_action_text_flashing::@1
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2997] call printf_str
    // [1210] phi from display_action_text_flashing::@1 to printf_str [phi:display_action_text_flashing::@1->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_action_text_flashing::s [phi:display_action_text_flashing::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@2
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2998] printf_ulong::uvalue#2 = display_action_text_flashing::bytes#3 -- vdum1=vdum2 
    lda bytes
    sta printf_ulong.uvalue
    lda bytes+1
    sta printf_ulong.uvalue+1
    lda bytes+2
    sta printf_ulong.uvalue+2
    lda bytes+3
    sta printf_ulong.uvalue+3
    // [2999] call printf_ulong
    // [1761] phi from display_action_text_flashing::@2 to printf_ulong [phi:display_action_text_flashing::@2->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 0 [phi:display_action_text_flashing::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 0 [phi:display_action_text_flashing::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = DECIMAL [phi:display_action_text_flashing::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#2 [phi:display_action_text_flashing::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [3000] phi from display_action_text_flashing::@2 to display_action_text_flashing::@3 [phi:display_action_text_flashing::@2->display_action_text_flashing::@3]
    // display_action_text_flashing::@3
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3001] call printf_str
    // [1210] phi from display_action_text_flashing::@3 to printf_str [phi:display_action_text_flashing::@3->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_action_text_flashing::s1 [phi:display_action_text_flashing::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@4
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3002] printf_uchar::uvalue#5 = display_action_text_flashing::bram_bank#3 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [3003] call printf_uchar
    // [1347] phi from display_action_text_flashing::@4 to printf_uchar [phi:display_action_text_flashing::@4->printf_uchar]
    // [1347] phi printf_uchar::format_zero_padding#18 = 1 [phi:display_action_text_flashing::@4->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1347] phi printf_uchar::format_min_length#18 = 2 [phi:display_action_text_flashing::@4->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1347] phi printf_uchar::putc#18 = &snputc [phi:display_action_text_flashing::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1347] phi printf_uchar::format_radix#18 = HEXADECIMAL [phi:display_action_text_flashing::@4->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1347] phi printf_uchar::uvalue#18 = printf_uchar::uvalue#5 [phi:display_action_text_flashing::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [3004] phi from display_action_text_flashing::@4 to display_action_text_flashing::@5 [phi:display_action_text_flashing::@4->display_action_text_flashing::@5]
    // display_action_text_flashing::@5
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3005] call printf_str
    // [1210] phi from display_action_text_flashing::@5 to printf_str [phi:display_action_text_flashing::@5->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s2 [phi:display_action_text_flashing::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@6
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3006] printf_uint::uvalue#2 = (unsigned int)display_action_text_flashing::bram_ptr#3 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [3007] call printf_uint
    // [2106] phi from display_action_text_flashing::@6 to printf_uint [phi:display_action_text_flashing::@6->printf_uint]
    // [2106] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2106] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_flashing::@6->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2106] phi printf_uint::putc#10 = &snputc [phi:display_action_text_flashing::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2106] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@6->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [2106] phi printf_uint::uvalue#10 = printf_uint::uvalue#2 [phi:display_action_text_flashing::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [3008] phi from display_action_text_flashing::@6 to display_action_text_flashing::@7 [phi:display_action_text_flashing::@6->display_action_text_flashing::@7]
    // display_action_text_flashing::@7
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3009] call printf_str
    // [1210] phi from display_action_text_flashing::@7 to printf_str [phi:display_action_text_flashing::@7->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = display_action_text_flashing::s3 [phi:display_action_text_flashing::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@8
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3010] printf_string::str#12 = display_action_text_flashing::chip#10 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [3011] call printf_string
    // [1219] phi from display_action_text_flashing::@8 to printf_string [phi:display_action_text_flashing::@8->printf_string]
    // [1219] phi printf_string::putc#26 = &snputc [phi:display_action_text_flashing::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1219] phi printf_string::str#26 = printf_string::str#12 [phi:display_action_text_flashing::@8->printf_string#1] -- register_copy 
    // [1219] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_flashing::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1219] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_flashing::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [3012] phi from display_action_text_flashing::@8 to display_action_text_flashing::@9 [phi:display_action_text_flashing::@8->display_action_text_flashing::@9]
    // display_action_text_flashing::@9
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3013] call printf_str
    // [1210] phi from display_action_text_flashing::@9 to printf_str [phi:display_action_text_flashing::@9->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@9->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s2 [phi:display_action_text_flashing::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@10
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3014] printf_ulong::uvalue#3 = display_action_text_flashing::address#10 -- vdum1=vdum2 
    lda address
    sta printf_ulong.uvalue
    lda address+1
    sta printf_ulong.uvalue+1
    lda address+2
    sta printf_ulong.uvalue+2
    lda address+3
    sta printf_ulong.uvalue+3
    // [3015] call printf_ulong
    // [1761] phi from display_action_text_flashing::@10 to printf_ulong [phi:display_action_text_flashing::@10->printf_ulong]
    // [1761] phi printf_ulong::format_zero_padding#15 = 1 [phi:display_action_text_flashing::@10->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1761] phi printf_ulong::format_min_length#15 = 5 [phi:display_action_text_flashing::@10->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1761] phi printf_ulong::format_radix#15 = HEXADECIMAL [phi:display_action_text_flashing::@10->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1761] phi printf_ulong::uvalue#15 = printf_ulong::uvalue#3 [phi:display_action_text_flashing::@10->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [3016] phi from display_action_text_flashing::@10 to display_action_text_flashing::@11 [phi:display_action_text_flashing::@10->display_action_text_flashing::@11]
    // display_action_text_flashing::@11
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3017] call printf_str
    // [1210] phi from display_action_text_flashing::@11 to printf_str [phi:display_action_text_flashing::@11->printf_str]
    // [1210] phi printf_str::putc#84 = &snputc [phi:display_action_text_flashing::@11->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1210] phi printf_str::s#84 = s5 [phi:display_action_text_flashing::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@12
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [3018] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [3019] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [3021] call display_action_text
    // [1358] phi from display_action_text_flashing::@12 to display_action_text [phi:display_action_text_flashing::@12->display_action_text]
    // [1358] phi display_action_text::info_text#25 = info_text [phi:display_action_text_flashing::@12->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashing::@return
    // }
    // [3022] return 
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
    // [3023] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vdum1=vdum2_band_vduc1 
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
    // [3024] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbum2 
    lda flash_ram_bank
    sta.z BRAM
    // [3025] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [3025] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [3025] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [3025] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vdum1=vduc1 
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
    // [3026] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [3027] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [3028] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vdum1=vdum2_plus_vwuc1 
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
    // [3029] call rom_unlock
    // [2414] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2414] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbum1=vbuc1 
    lda #$a0
    sta rom_unlock.unlock_code
    // [2414] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [3030] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vdum1=vdum2 
    lda flash_rom_address
    sta rom_byte_program.address
    lda flash_rom_address+1
    sta rom_byte_program.address+1
    lda flash_rom_address+2
    sta rom_byte_program.address+2
    lda flash_rom_address+3
    sta rom_byte_program.address+3
    // [3031] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta rom_byte_program.value
    // [3032] call rom_byte_program
    // [3450] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [3033] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vdum1=_inc_vdum1 
    inc flash_rom_address
    bne !+
    inc flash_rom_address+1
    bne !+
    inc flash_rom_address+2
    bne !+
    inc flash_rom_address+3
  !:
    // flash_ram_address++;
    // [3034] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [3035] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vdum1=_inc_vdum1 
    inc flashed_bytes
    bne !+
    inc flashed_bytes+1
    bne !+
    inc flashed_bytes+2
    bne !+
    inc flashed_bytes+3
  !:
    // [3025] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [3025] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [3025] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [3025] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
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
    // [3036] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [3038] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [3039] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [3040] return 
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
// char * strncpy(__zp($47) char *dst, __zp($3f) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $47
    .label src = $3f
    // [3042] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [3042] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [3042] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [3042] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [3043] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [3044] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [3045] strncpy::c#0 = *strncpy::src#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [3046] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [3047] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [3048] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [3048] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [3049] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [3050] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [3051] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [3042] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [3042] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [3042] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [3042] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
// void utoa(__mem() unsigned int value, __zp($3d) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $3a
    .label utoa__10 = $41
    .label utoa__11 = $42
    .label buffer = $3d
    .label digit_values = $4e
    // if(radix==DECIMAL)
    // [3052] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [3053] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [3054] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [3055] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [3056] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [3057] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [3058] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [3059] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [3060] return 
    rts
    // [3061] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [3061] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [3061] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [3061] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [3061] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [3061] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [3061] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [3061] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [3061] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [3061] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [3061] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [3061] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [3062] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [3062] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [3062] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [3062] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [3062] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [3063] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [3064] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [3065] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [3066] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [3067] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [3068] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [3069] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [3070] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [3071] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [3072] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [3073] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [3073] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [3073] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [3073] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [3074] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [3062] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [3062] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [3062] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [3062] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [3062] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [3075] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [3076] utoa_append::value#0 = utoa::value#2
    // [3077] utoa_append::sub#0 = utoa::digit_value#0
    // [3078] call utoa_append
    // [3460] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [3079] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [3080] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [3081] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [3073] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [3073] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [3073] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [3073] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
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
    // [3082] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [3083] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [3084] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [3084] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [3085] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [3086] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [3087] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [3088] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [3089] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [3090] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [3091] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [3092] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [3093] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [3094] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [3095] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [3096] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [3097] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [3098] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [3084] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [3084] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [3099] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [3100] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [3101] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [3102] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [3103] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [3104] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [3105] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [3106] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [3107] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [3108] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [3109] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [3109] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [3110] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [3111] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [3112] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [3113] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [3114] return 
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
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $3a
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [3116] gotoxy::x#9 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [3117] gotoxy::y#9 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [3118] call gotoxy
    // [802] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#9 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#9 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [3119] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [3120] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [3121] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [3122] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [3123] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [3124] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [3125] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [3126] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbum1=_deref_pbuc1 
    lda VERA_DATA0
    sta c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [3127] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$70
    cmp c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [3128] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6e
    cmp c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [3129] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6d
    cmp c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [3130] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$7d
    cmp c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [3131] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [3132] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$5d
    cmp c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [3133] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6b
    cmp c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [3134] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$73
    cmp c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [3135] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$72
    cmp c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [3136] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$71
    cmp c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [3137] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbum1_eq_vbuc1_then_la1 
    lda #$5b
    cmp c
    beq __b11
    // [3139] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [3139] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [3138] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [3139] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [3139] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [3139] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [3139] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [3139] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [3139] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [3139] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [3139] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [3139] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [3139] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [3139] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [3139] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [3139] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // display_frame_maskxy::@return
    // }
    // [3140] return 
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
    // [3142] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [3143] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [3144] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [3145] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [3146] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [3147] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [3148] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [3149] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [3150] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [3151] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [3152] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [3154] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [3154] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$20
    sta return
    rts
    // [3153] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [3154] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [3154] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5b
    sta return
    rts
    // [3154] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [3154] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$70
    sta return
    rts
    // [3154] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [3154] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6e
    sta return
    rts
    // [3154] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [3154] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6d
    sta return
    rts
    // [3154] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [3154] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$7d
    sta return
    rts
    // [3154] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [3154] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$40
    sta return
    rts
    // [3154] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [3154] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5d
    sta return
    rts
    // [3154] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [3154] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6b
    sta return
    rts
    // [3154] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [3154] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$73
    sta return
    rts
    // [3154] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [3154] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$72
    sta return
    rts
    // [3154] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [3154] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$71
    sta return
    // display_frame_char::@return
    // }
    // [3155] return 
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
    // [3157] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [3158] call textcolor
    // [784] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [784] phi textcolor::color#23 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [3159] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [3160] call bgcolor
    // [789] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [3161] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [3161] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [3161] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [3162] cputcxy::x#11 = display_chip_led::x#4 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [3163] call cputcxy
    // [2313] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [2313] phi cputcxy::c#17 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [2313] phi cputcxy::y#17 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [2313] phi cputcxy::x#17 = cputcxy::x#11 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [3164] cputcxy::x#12 = display_chip_led::x#4 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [3165] call cputcxy
    // [2313] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [2313] phi cputcxy::c#17 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [2313] phi cputcxy::y#17 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [2313] phi cputcxy::x#17 = cputcxy::x#12 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [3166] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbum1=_inc_vbum1 
    inc x
    // while(--w)
    // [3167] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbum1=_dec_vbum1 
    dec w
    // [3168] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbum1_then_la1 
    lda w
    bne __b1
    // [3169] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [3170] call textcolor
    // [784] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [3171] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [3172] call bgcolor
    // [789] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [3173] return 
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
    // [3175] gotoxy::x#11 = display_chip_line::x#16 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [3176] gotoxy::y#11 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [3177] call gotoxy
    // [802] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [802] phi gotoxy::y#37 = gotoxy::y#11 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [802] phi gotoxy::x#37 = gotoxy::x#11 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [3178] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [3179] call textcolor
    // [784] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [784] phi textcolor::color#23 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3180] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [3181] call bgcolor
    // [789] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [3182] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [3183] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [3185] call textcolor
    // [784] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [3186] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [3187] call bgcolor
    // [789] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [789] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [3188] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [3188] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [3189] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [3190] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [3191] call textcolor
    // [784] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [784] phi textcolor::color#23 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3192] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [3193] call bgcolor
    // [789] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [3194] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [3195] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [3197] call textcolor
    // [784] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [784] phi textcolor::color#23 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [3198] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [3199] call bgcolor
    // [789] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [789] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [3200] cputcxy::x#10 = display_chip_line::x#16 + 2 -- vbum1=vbum2_plus_2 
    lda x
    clc
    adc #2
    sta cputcxy.x
    // [3201] cputcxy::y#10 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [3202] cputcxy::c#10 = display_chip_line::c#15 -- vbum1=vbum2 
    lda c
    sta cputcxy.c
    // [3203] call cputcxy
    // [2313] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [2313] phi cputcxy::c#17 = cputcxy::c#10 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [2313] phi cputcxy::y#17 = cputcxy::y#10 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [2313] phi cputcxy::x#17 = cputcxy::x#10 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [3204] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [3205] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [3206] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [3208] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [3188] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [3188] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
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
    // [3209] gotoxy::x#12 = display_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [3210] call gotoxy
    // [802] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [802] phi gotoxy::y#37 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [802] phi gotoxy::x#37 = gotoxy::x#12 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [3211] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [3212] call textcolor
    // [784] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [784] phi textcolor::color#23 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3213] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [3214] call bgcolor
    // [789] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [3215] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [3216] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [3218] call textcolor
    // [784] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [784] phi textcolor::color#23 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [3219] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [3220] call bgcolor
    // [789] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [789] phi bgcolor::color#15 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [3221] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [3221] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [3222] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [3223] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [3224] call textcolor
    // [784] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [784] phi textcolor::color#23 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [3225] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [3226] call bgcolor
    // [789] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [789] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [3227] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [3228] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [3230] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [3231] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [3232] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [3234] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [3221] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [3221] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
    // [3236] call spi_fast
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
    // [3237] phi from spi_get_jedec to spi_get_jedec::@1 [phi:spi_get_jedec->spi_get_jedec::@1]
    // spi_get_jedec::@1
    // spi_select()
    // [3238] call spi_select
    // [3489] phi from spi_get_jedec::@1 to spi_select [phi:spi_get_jedec::@1->spi_select]
    jsr spi_select
    // spi_get_jedec::@2
    // spi_write(0x9F)
    // [3239] spi_write::data = $9f -- vbum1=vbuc1 
    lda #$9f
    sta spi_write.data
    // [3240] call spi_write
    jsr spi_write
    // [3241] phi from spi_get_jedec::@2 to spi_get_jedec::@3 [phi:spi_get_jedec::@2->spi_get_jedec::@3]
    // spi_get_jedec::@3
    // spi_read()
    // [3242] call spi_read
    jsr spi_read
    // [3243] spi_read::return#0 = spi_read::return#5 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_read.return
    // [3244] phi from spi_get_jedec::@3 to spi_get_jedec::@4 [phi:spi_get_jedec::@3->spi_get_jedec::@4]
    // spi_get_jedec::@4
    // spi_read()
    // [3245] call spi_read
    jsr spi_read
    // [3246] spi_read::return#1 = spi_read::return#5 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_read.return_1
    // [3247] phi from spi_get_jedec::@4 to spi_get_jedec::@5 [phi:spi_get_jedec::@4->spi_get_jedec::@5]
    // spi_get_jedec::@5
    // spi_read()
    // [3248] call spi_read
    jsr spi_read
    // [3249] spi_read::return#10 = spi_read::return#5 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_read.return_3
    // spi_get_jedec::@return
    // }
    // [3250] return 
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
    .label rom_bank1_rom_write_byte__0 = $3a
    .label rom_bank1_rom_write_byte__1 = $29
    .label rom_bank1_rom_write_byte__2 = $3f
    .label rom_ptr1_rom_write_byte__0 = $3b
    .label rom_ptr1_rom_write_byte__2 = $3b
    .label rom_ptr1_return = $3b
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [3252] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vdum2 
    lda address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [3253] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vdum2 
    lda address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [3254] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [3255] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_write_byte__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [3256] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [3257] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_write_byte__2
    lda address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [3258] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [3259] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [3260] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [3261] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbum2 
    lda value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [3262] return 
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
    // [3264] return 
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
// __mem() int ferror(__zp($3d) struct $2 *stream)
ferror: {
    .label ferror__6 = $29
    .label ferror__15 = $2b
    .label cbm_k_setnam1_filename = $be
    .label cbm_k_setnam1_ferror__0 = $3b
    .label stream = $3d
    .label errno_len = $6d
    // unsigned char sp = (unsigned char)stream
    // [3265] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [3266] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [3267] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [3268] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [3269] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [3270] ferror::cbm_k_setnam1_filename = str -- pbuz1=pbuc1 
    lda #<str
    sta.z cbm_k_setnam1_filename
    lda #>str
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [3271] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [3272] call strlen
    // [2631] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2631] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [3273] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [3274] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [3275] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [3278] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [3279] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [3281] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [3283] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [3284] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [3285] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [3286] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [3286] phi __errno#123 = __errno#473 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [3286] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [3286] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [3286] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [3287] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [3289] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [3290] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [3291] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [3292] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [3293] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [3294] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [3295] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [3297] ferror::return#1 = __errno#123 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [3298] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [3299] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [3300] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [3301] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [3302] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [3303] call strncpy
    // [3041] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [3041] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [3041] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [3041] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [3304] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [3305] call atoi
    // [3317] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [3317] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [3306] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [3307] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [3308] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [3308] phi __errno#178 = __errno#123 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [3308] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [3309] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [3310] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [3311] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [3313] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [3314] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [3315] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [3316] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [3286] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [3286] phi __errno#123 = __errno#178 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [3286] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [3286] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [3286] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
    .label atoi__6 = $47
    .label atoi__7 = $47
    .label str = $5a
    .label atoi__10 = $47
    .label atoi__11 = $47
    // if (str[i] == '-')
    // [3318] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [3319] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [3320] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [3320] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [3320] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [3320] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [3320] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [3320] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [3320] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [3320] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [3321] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [3322] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [3323] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [3325] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [3325] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [3324] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [3326] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [3327] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [3328] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [3329] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [3330] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [3331] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [3332] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [3320] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [3320] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [3320] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [3320] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($58) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $58
    // unsigned int bytes_read
    // [3333] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [3335] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [3336] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [3337] return 
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
// __mem() char uctoa_append(__zp($43) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $43
    // [3339] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [3339] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3339] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [3340] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [3341] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [3342] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [3343] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3344] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [3339] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [3339] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [3339] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
    // [3346] call spi_select
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
    // [3489] phi from spi_read_flash to spi_select [phi:spi_read_flash->spi_select]
    jsr spi_select
    // spi_read_flash::@1
    // spi_write(0x03)
    // [3347] spi_write::data = 3 -- vbum1=vbuc1 
    lda #3
    sta spi_write.data
    // [3348] call spi_write
    jsr spi_write
    // spi_read_flash::@2
    // spi_write(BYTE2(spi_data))
    // [3349] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3350] call spi_write
    jsr spi_write
    // spi_read_flash::@3
    // spi_write(BYTE1(spi_data))
    // [3351] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3352] call spi_write
    jsr spi_write
    // spi_read_flash::@4
    // spi_write(BYTE0(spi_data))
    // [3353] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [3354] call spi_write
    jsr spi_write
    // spi_read_flash::@return
    // }
    // [3355] return 
    rts
}
  // vera_compare
// __mem() unsigned int vera_compare(__mem() char bank_ram, __zp($66) char *bram_ptr, unsigned int vera_compare_size)
vera_compare: {
    .label bram_ptr = $66
    // vera_compare::bank_set_bram1
    // BRAM = bank
    // [3357] BRAM = vera_compare::bank_ram#0 -- vbuz1=vbum2 
    lda bank_ram
    sta.z BRAM
    // [3358] phi from vera_compare::bank_set_bram1 to vera_compare::@1 [phi:vera_compare::bank_set_bram1->vera_compare::@1]
    // [3358] phi vera_compare::bram_ptr#2 = vera_compare::bram_ptr#0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#0] -- register_copy 
    // [3358] phi vera_compare::equal_bytes#2 = 0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [3358] phi vera_compare::compared_bytes#2 = 0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#2] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // vera_compare::@1
  __b1:
    // while (compared_bytes < vera_compare_size)
    // [3359] if(vera_compare::compared_bytes#2<VERA_PROGRESS_CELL) goto vera_compare::@2 -- vwum1_lt_vbuc1_then_la1 
    lda compared_bytes+1
    bne !+
    lda compared_bytes
    cmp #VERA_PROGRESS_CELL
    bcc __b2
  !:
    // vera_compare::@return
    // }
    // [3360] return 
    rts
    // [3361] phi from vera_compare::@1 to vera_compare::@2 [phi:vera_compare::@1->vera_compare::@2]
    // vera_compare::@2
  __b2:
    // unsigned char vera_byte = spi_read()
    // [3362] call spi_read
    jsr spi_read
    // [3363] spi_read::return#14 = spi_read::return#5
    // vera_compare::@5
    // [3364] vera_compare::vera_byte#0 = spi_read::return#14
    // if (vera_byte == *bram_ptr)
    // [3365] if(vera_compare::vera_byte#0!=*vera_compare::bram_ptr#2) goto vera_compare::@3 -- vbum1_neq__deref_pbuz2_then_la1 
    ldy #0
    lda (bram_ptr),y
    cmp vera_byte
    bne __b3
    // vera_compare::@4
    // equal_bytes++;
    // [3366] vera_compare::equal_bytes#1 = ++ vera_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [3367] phi from vera_compare::@4 vera_compare::@5 to vera_compare::@3 [phi:vera_compare::@4/vera_compare::@5->vera_compare::@3]
    // [3367] phi vera_compare::equal_bytes#6 = vera_compare::equal_bytes#1 [phi:vera_compare::@4/vera_compare::@5->vera_compare::@3#0] -- register_copy 
    // vera_compare::@3
  __b3:
    // bram_ptr++;
    // [3368] vera_compare::bram_ptr#1 = ++ vera_compare::bram_ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z bram_ptr
    bne !+
    inc.z bram_ptr+1
  !:
    // compared_bytes++;
    // [3369] vera_compare::compared_bytes#1 = ++ vera_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [3358] phi from vera_compare::@3 to vera_compare::@1 [phi:vera_compare::@3->vera_compare::@1]
    // [3358] phi vera_compare::bram_ptr#2 = vera_compare::bram_ptr#1 [phi:vera_compare::@3->vera_compare::@1#0] -- register_copy 
    // [3358] phi vera_compare::equal_bytes#2 = vera_compare::equal_bytes#6 [phi:vera_compare::@3->vera_compare::@1#1] -- register_copy 
    // [3358] phi vera_compare::compared_bytes#2 = vera_compare::compared_bytes#1 [phi:vera_compare::@3->vera_compare::@1#2] -- register_copy 
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
    // [3371] phi from spi_wait_non_busy to spi_wait_non_busy::@1 [phi:spi_wait_non_busy->spi_wait_non_busy::@1]
    // [3371] phi spi_wait_non_busy::y#2 = 0 [phi:spi_wait_non_busy->spi_wait_non_busy::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // spi_wait_non_busy::@1
    // [3372] phi from spi_wait_non_busy::@1 to spi_wait_non_busy::@2 [phi:spi_wait_non_busy::@1->spi_wait_non_busy::@2]
    // spi_wait_non_busy::@2
  __b2:
    // spi_select()
    // [3373] call spi_select
    // [3489] phi from spi_wait_non_busy::@2 to spi_select [phi:spi_wait_non_busy::@2->spi_select]
    jsr spi_select
    // spi_wait_non_busy::@5
    // spi_write(0x05)
    // [3374] spi_write::data = 5 -- vbum1=vbuc1 
    lda #5
    sta spi_write.data
    // [3375] call spi_write
    jsr spi_write
    // [3376] phi from spi_wait_non_busy::@5 to spi_wait_non_busy::@6 [phi:spi_wait_non_busy::@5->spi_wait_non_busy::@6]
    // spi_wait_non_busy::@6
    // unsigned char w = spi_read()
    // [3377] call spi_read
    jsr spi_read
    // [3378] spi_read::return#11 = spi_read::return#5
    // spi_wait_non_busy::@7
    // [3379] spi_wait_non_busy::w#0 = spi_read::return#11
    // w &= 1
    // [3380] spi_wait_non_busy::w#1 = spi_wait_non_busy::w#0 & 1 -- vbum1=vbum1_band_vbuc1 
    lda #1
    and w
    sta w
    // if(w == 0)
    // [3381] if(spi_wait_non_busy::w#1==0) goto spi_wait_non_busy::@return -- vbum1_eq_0_then_la1 
    beq __b1
    // spi_wait_non_busy::@4
    // y++;
    // [3382] spi_wait_non_busy::y#1 = ++ spi_wait_non_busy::y#2 -- vbum1=_inc_vbum1 
    inc y
    // if(y == 0)
    // [3383] if(spi_wait_non_busy::y#1!=0) goto spi_wait_non_busy::@3 -- vbum1_neq_0_then_la1 
    lda y
    bne __b3
    // [3384] phi from spi_wait_non_busy::@4 to spi_wait_non_busy::@return [phi:spi_wait_non_busy::@4->spi_wait_non_busy::@return]
    // [3384] phi spi_wait_non_busy::return#3 = 1 [phi:spi_wait_non_busy::@4->spi_wait_non_busy::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // [3384] phi from spi_wait_non_busy::@7 to spi_wait_non_busy::@return [phi:spi_wait_non_busy::@7->spi_wait_non_busy::@return]
  __b1:
    // [3384] phi spi_wait_non_busy::return#3 = 0 [phi:spi_wait_non_busy::@7->spi_wait_non_busy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // spi_wait_non_busy::@return
    // }
    // [3385] return 
    rts
    // spi_wait_non_busy::@3
  __b3:
    // asm
    // asm { .byte$CB  }
    // WAI
    .byte $cb
    // [3371] phi from spi_wait_non_busy::@3 to spi_wait_non_busy::@1 [phi:spi_wait_non_busy::@3->spi_wait_non_busy::@1]
    // [3371] phi spi_wait_non_busy::y#2 = spi_wait_non_busy::y#1 [phi:spi_wait_non_busy::@3->spi_wait_non_busy::@1#0] -- register_copy 
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
    .label spi_block_erase__4 = $7b
    .label spi_block_erase__6 = $7c
    .label spi_block_erase__8 = $76
    // spi_select()
    // [3388] call spi_select
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
    // [3489] phi from spi_block_erase to spi_select [phi:spi_block_erase->spi_select]
    jsr spi_select
    // spi_block_erase::@1
    // spi_write(0x06)
    // [3389] spi_write::data = 6 -- vbum1=vbuc1 
    lda #6
    sta spi_write.data
    // [3390] call spi_write
    jsr spi_write
    // [3391] phi from spi_block_erase::@1 to spi_block_erase::@2 [phi:spi_block_erase::@1->spi_block_erase::@2]
    // spi_block_erase::@2
    // spi_select()
    // [3392] call spi_select
    // [3489] phi from spi_block_erase::@2 to spi_select [phi:spi_block_erase::@2->spi_select]
    jsr spi_select
    // spi_block_erase::@3
    // spi_write(0xD8)
    // [3393] spi_write::data = $d8 -- vbum1=vbuc1 
    lda #$d8
    sta spi_write.data
    // [3394] call spi_write
    jsr spi_write
    // spi_block_erase::@4
    // BYTE2(data)
    // [3395] spi_block_erase::$4 = byte2  spi_block_erase::data#0 -- vbuz1=_byte2_vdum2 
    lda data+2
    sta.z spi_block_erase__4
    // spi_write(BYTE2(data))
    // [3396] spi_write::data = spi_block_erase::$4 -- vbum1=vbuz2 
    sta spi_write.data
    // [3397] call spi_write
    jsr spi_write
    // spi_block_erase::@5
    // BYTE1(data)
    // [3398] spi_block_erase::$6 = byte1  spi_block_erase::data#0 -- vbuz1=_byte1_vdum2 
    lda data+1
    sta.z spi_block_erase__6
    // spi_write(BYTE1(data))
    // [3399] spi_write::data = spi_block_erase::$6 -- vbum1=vbuz2 
    sta spi_write.data
    // [3400] call spi_write
    jsr spi_write
    // spi_block_erase::@6
    // BYTE0(data)
    // [3401] spi_block_erase::$8 = byte0  spi_block_erase::data#0 -- vbuz1=_byte0_vdum2 
    lda data
    sta.z spi_block_erase__8
    // spi_write(BYTE0(data))
    // [3402] spi_write::data = spi_block_erase::$8 -- vbum1=vbuz2 
    sta spi_write.data
    // [3403] call spi_write
    jsr spi_write
    // [3404] phi from spi_block_erase::@6 to spi_block_erase::@7 [phi:spi_block_erase::@6->spi_block_erase::@7]
    // spi_block_erase::@7
    // spi_deselect()
    // [3405] call spi_deselect
    jsr spi_deselect
    // spi_block_erase::@return
    // }
    // [3406] return 
    rts
  .segment DataVera
    data: .dword 0
}
.segment CodeVera
  // spi_read
spi_read: {
    // unsigned char SPIData
    // [3407] spi_read::SPIData = 0 -- vbum1=vbuc1 
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
    // [3409] spi_read::return#4 = spi_read::SPIData -- vbum1=vbum2 
    sta return_2
    // spi_read::@return
    // }
    // [3410] spi_read::return#5 = spi_read::return#4
    // [3411] return 
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
    .label spi_write_page_begin__4 = $76
    .label spi_write_page_begin__6 = $7b
    .label spi_write_page_begin__8 = $7c
    // spi_select()
    // [3413] call spi_select
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
    // [3489] phi from spi_write_page_begin to spi_select [phi:spi_write_page_begin->spi_select]
    jsr spi_select
    // spi_write_page_begin::@1
    // spi_write(0x06)
    // [3414] spi_write::data = 6 -- vbum1=vbuc1 
    lda #6
    sta spi_write.data
    // [3415] call spi_write
    jsr spi_write
    // [3416] phi from spi_write_page_begin::@1 to spi_write_page_begin::@2 [phi:spi_write_page_begin::@1->spi_write_page_begin::@2]
    // spi_write_page_begin::@2
    // spi_select()
    // [3417] call spi_select
    // [3489] phi from spi_write_page_begin::@2 to spi_select [phi:spi_write_page_begin::@2->spi_select]
    jsr spi_select
    // spi_write_page_begin::@3
    // spi_write(0x02)
    // [3418] spi_write::data = 2 -- vbum1=vbuc1 
    lda #2
    sta spi_write.data
    // [3419] call spi_write
    jsr spi_write
    // spi_write_page_begin::@4
    // BYTE2(data)
    // [3420] spi_write_page_begin::$4 = byte2  spi_write_page_begin::data#0 -- vbuz1=_byte2_vdum2 
    lda data+2
    sta.z spi_write_page_begin__4
    // spi_write(BYTE2(data))
    // [3421] spi_write::data = spi_write_page_begin::$4 -- vbum1=vbuz2 
    sta spi_write.data
    // [3422] call spi_write
    jsr spi_write
    // spi_write_page_begin::@5
    // BYTE1(data)
    // [3423] spi_write_page_begin::$6 = byte1  spi_write_page_begin::data#0 -- vbuz1=_byte1_vdum2 
    lda data+1
    sta.z spi_write_page_begin__6
    // spi_write(BYTE1(data))
    // [3424] spi_write::data = spi_write_page_begin::$6 -- vbum1=vbuz2 
    sta spi_write.data
    // [3425] call spi_write
    jsr spi_write
    // spi_write_page_begin::@6
    // BYTE0(data)
    // [3426] spi_write_page_begin::$8 = byte0  spi_write_page_begin::data#0 -- vbuz1=_byte0_vdum2 
    lda data
    sta.z spi_write_page_begin__8
    // spi_write(BYTE0(data))
    // [3427] spi_write::data = spi_write_page_begin::$8 -- vbum1=vbuz2 
    sta spi_write.data
    // [3428] call spi_write
    jsr spi_write
    // spi_write_page_begin::@return
    // }
    // [3429] return 
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
    // [3431] return 
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
// __mem() char rom_byte_compare(__zp($4c) char *ptr_rom, __mem() char value)
rom_byte_compare: {
    .label ptr_rom = $4c
    // if (*ptr_rom != value)
    // [3432] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbum2_then_la1 
    lda value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [3433] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [3434] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [3434] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    tya
    sta return
    rts
    // [3434] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [3434] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [3435] return 
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
// __mem() unsigned long ultoa_append(__zp($45) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $45
    // [3437] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [3437] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3437] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [3438] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [3439] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [3440] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [3441] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3442] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [3437] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [3437] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [3437] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
    // [3444] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [3445] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    lda (ptr_rom),y
    sta test2
    // test1 & 0x40
    // [3446] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbum2_band_vbuc1 
    lda #$40
    and test1
    sta.z rom_wait__0
    // test2 & 0x40
    // [3447] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbum2_band_vbuc1 
    lda #$40
    and test2
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [3448] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [3449] return 
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
    .label rom_ptr1_rom_byte_program__0 = $47
    .label rom_ptr1_rom_byte_program__2 = $47
    .label rom_ptr1_return = $47
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [3451] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_byte_program__2
    lda address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [3452] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [3453] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [3454] rom_write_byte::address#3 = rom_byte_program::address#0
    // [3455] rom_write_byte::value#3 = rom_byte_program::value#0
    // [3456] call rom_write_byte
    // [3251] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [3251] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [3251] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [3457] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [3458] call rom_wait
    // [3443] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [3443] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [3459] return 
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
// __mem() unsigned int utoa_append(__zp($3f) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $3f
    // [3461] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [3461] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [3461] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [3462] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [3463] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [3464] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [3465] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [3466] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [3461] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [3461] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [3461] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
    // [3467] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [3468] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [3469] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [3470] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [3471] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [3472] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [3473] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [3474] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [3475] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [3476] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [3477] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [3478] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [3479] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [3480] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [3481] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [3481] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [3482] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [3483] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [3484] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [3485] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [3486] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
    // [3488] return 
    rts
}
  // spi_select
spi_select: {
    // spi_deselect()
    // [3490] call spi_deselect
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
    // [3491] *vera_reg_SPICtrl = *vera_reg_SPICtrl | 1 -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #1
    ora vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // spi_select::@return
    // }
    // [3492] return 
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
  rom_file_github: .fill 8*8, 0
  rom_file_release: .fill 8, 0
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
