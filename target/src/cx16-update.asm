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
  // #define __VERA_FLASH
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
  // A progress frame row represents about 512 bytes for a SMC update.
  .const VERA_PROGRESS_CELL = $80
  // A progress frame cell represents about 128 bytes for a VERA compare.
  .const VERA_PROGRESS_PAGE = $100
  // A progress frame cell represents about 256 bytes for a VERA flash.
  .const VERA_PROGRESS_ROW = $2000
  .const OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS = 1
  // Globals (to save zeropage and code overhead with parameter passing.)
  .const smc_bootloader = 0
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
  .label __snprintf_buffer = $5d
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
    .label conio_x16_init__4 = $c0
    .label conio_x16_init__5 = $64
    .label conio_x16_init__6 = $c2
    .label conio_x16_init__7 = $c4
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [437] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [442] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [29] conio_x16_init::$4 = cbm_k_plot_get::return#2 -- vwuz1=vwum2 
    lda cbm_k_plot_get.return
    sta.z conio_x16_init__4
    lda cbm_k_plot_get.return+1
    sta.z conio_x16_init__4+1
    // BYTE1(cbm_k_plot_get())
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwuz2 
    sta.z conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
    sta __conio
    // cbm_k_plot_get()
    // [32] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [33] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [34] conio_x16_init::$6 = cbm_k_plot_get::return#3 -- vwuz1=vwum2 
    lda cbm_k_plot_get.return
    sta.z conio_x16_init__6
    lda cbm_k_plot_get.return+1
    sta.z conio_x16_init__6+1
    // BYTE0(cbm_k_plot_get())
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuz1=_byte0_vwuz2 
    lda.z conio_x16_init__6
    sta.z conio_x16_init__7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbuz1 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#2 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta gotoxy.x
    // [38] gotoxy::y#2 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta gotoxy.y
    // [39] call gotoxy
    // [455] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
// void cputc(__mem() char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $47
    .label cputc__3 = $48
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
    .const bank_set_brom2_bank = 0
    .const bank_set_brom3_bank = 4
    .const bank_set_brom4_bank = 0
    .const bank_set_brom5_bank = 4
    .label main__30 = $e1
    .label main__47 = $e7
    .label main__56 = $e6
    .label main__69 = $e5
    .label main__72 = $a9
    .label main__111 = $e4
    .label main__116 = $42
    .label main__151 = $e2
    .label main__156 = $e3
    .label check_status_smc1_main__0 = $63
    .label check_status_cx16_rom1_check_status_rom1_main__0 = $c7
    .label check_status_smc2_main__0 = $c8
    .label check_status_cx16_rom2_check_status_rom1_main__0 = $c9
    .label check_status_smc3_main__0 = $ca
    .label check_status_cx16_rom3_check_status_rom1_main__0 = $cb
    .label check_status_smc4_main__0 = $cc
    .label check_status_cx16_rom4_check_status_rom1_main__0 = $cd
    .label check_status_smc5_main__0 = $ce
    .label check_status_smc6_main__0 = $cf
    .label check_status_vera1_main__0 = $d0
    .label check_status_smc7_main__0 = $d1
    .label check_status_vera2_main__0 = $d2
    .label check_status_vera3_main__0 = $d3
    .label check_status_vera4_main__0 = $dd
    .label check_status_smc8_main__0 = $de
    .label check_status_cx16_rom5_check_status_rom1_main__0 = $df
    .label check_status_vera5_main__0 = $e0
    .label check_status_smc9_main__0 = $d4
    .label check_status_smc10_main__0 = $d5
    .label check_status_vera6_main__0 = $d6
    .label check_status_vera7_main__0 = $d7
    .label check_status_smc11_main__0 = $d8
    .label check_status_vera8_main__0 = $d9
    .label check_status_smc12_main__0 = $da
    .label check_status_vera9_main__0 = $db
    .label check_status_smc13_main__0 = $dc
    .label rom_chip = $af
    .label ch = $c6
    .label ch1 = $c5
    .label rom_chip1 = $aa
    .label w = $b1
    .label w1 = $b0
    .label main__229 = $a9
    .label main__230 = $a9
    .label main__231 = $a9
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
    // [72] phi from main to main::@49 [phi:main->main::@49]
    // main::@49
    // display_frame_draw()
    // [73] call display_frame_draw
  // ST1 | Reset canvas to 64 columns
    // [504] phi from main::@49 to display_frame_draw [phi:main::@49->display_frame_draw]
    jsr display_frame_draw
    // [74] phi from main::@49 to main::@50 [phi:main::@49->main::@50]
    // main::@50
    // display_frame_title("Commander X16 Update Utility (v3.0.0) ")
    // [75] call display_frame_title
    // [545] phi from main::@50 to display_frame_title [phi:main::@50->display_frame_title]
    jsr display_frame_title
    // [76] phi from main::@50 to main::display_info_title1 [phi:main::@50->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [77] call cputsxy
    // [550] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [550] phi cputsxy::s#3 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [550] phi cputsxy::y#3 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [550] phi cputsxy::x#3 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [78] phi from main::display_info_title1 to main::@51 [phi:main::display_info_title1->main::@51]
    // main::@51
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [79] call cputsxy
    // [550] phi from main::@51 to cputsxy [phi:main::@51->cputsxy]
    // [550] phi cputsxy::s#3 = main::s1 [phi:main::@51->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [550] phi cputsxy::y#3 = $11-1 [phi:main::@51->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [550] phi cputsxy::x#3 = 4-2 [phi:main::@51->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [80] phi from main::@51 to main::@27 [phi:main::@51->main::@27]
    // main::@27
    // display_action_progress("Introduction, please read carefully the below!")
    // [81] call display_action_progress
    // [557] phi from main::@27 to display_action_progress [phi:main::@27->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text [phi:main::@27->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [82] phi from main::@27 to main::@52 [phi:main::@27->main::@52]
    // main::@52
    // display_progress_clear()
    // [83] call display_progress_clear
    // [571] phi from main::@52 to display_progress_clear [phi:main::@52->display_progress_clear]
    jsr display_progress_clear
    // [84] phi from main::@52 to main::@53 [phi:main::@52->main::@53]
    // main::@53
    // display_chip_smc()
    // [85] call display_chip_smc
    // [586] phi from main::@53 to display_chip_smc [phi:main::@53->display_chip_smc]
    jsr display_chip_smc
    // [86] phi from main::@53 to main::@54 [phi:main::@53->main::@54]
    // main::@54
    // display_chip_vera()
    // [87] call display_chip_vera
    // [591] phi from main::@54 to display_chip_vera [phi:main::@54->display_chip_vera]
    jsr display_chip_vera
    // [88] phi from main::@54 to main::@55 [phi:main::@54->main::@55]
    // main::@55
    // display_chip_rom()
    // [89] call display_chip_rom
    // [596] phi from main::@55 to display_chip_rom [phi:main::@55->display_chip_rom]
    jsr display_chip_rom
    // [90] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [91] call display_info_smc
    // [615] phi from main::@56 to display_info_smc [phi:main::@56->display_info_smc]
    // [615] phi display_info_smc::info_text#10 = 0 [phi:main::@56->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [615] phi display_info_smc::info_status#10 = BLACK [phi:main::@56->display_info_smc#1] -- vbum1=vbuc1 
    lda #BLACK
    sta display_info_smc.info_status
    jsr display_info_smc
    // [92] phi from main::@56 to main::@57 [phi:main::@56->main::@57]
    // main::@57
    // display_info_vera(STATUS_NONE, NULL)
    // [93] call display_info_vera
    // [651] phi from main::@57 to display_info_vera [phi:main::@57->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = 0 [phi:main::@57->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = 0 [phi:main::@57->display_info_vera#1] -- vbum1=vbuc1 
    sta spi_memory_capacity
    // [651] phi spi_memory_type#111 = 0 [phi:main::@57->display_info_vera#2] -- vbum1=vbuc1 
    sta spi_memory_type
    // [651] phi spi_manufacturer#100 = 0 [phi:main::@57->display_info_vera#3] -- vbum1=vbuc1 
    sta spi_manufacturer
    // [651] phi display_info_vera::info_status#19 = STATUS_NONE [phi:main::@57->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_vera.info_status
    jsr display_info_vera
    // [94] phi from main::@57 to main::@10 [phi:main::@57->main::@10]
    // [94] phi main::rom_chip#2 = 0 [phi:main::@57->main::@10#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // main::@10
  __b10:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [95] if(main::rom_chip#2<8) goto main::@11 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcs !__b11+
    jmp __b11
  !__b11:
    // [96] phi from main::@10 to main::@12 [phi:main::@10->main::@12]
    // main::@12
    // main_intro()
    // [97] call main_intro
    // [691] phi from main::@12 to main_intro [phi:main::@12->main_intro]
    jsr main_intro
    // [98] phi from main::@12 to main::@60 [phi:main::@12->main::@60]
    // main::@60
    // main_vera_detect()
    // [99] call main_vera_detect
    // [708] phi from main::@60 to main_vera_detect [phi:main::@60->main_vera_detect]
    jsr main_vera_detect
    // main::bank_set_brom1
    // BROM = bank
    // [100] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [102] phi from main::CLI1 to main::@28 [phi:main::CLI1->main::@28]
    // main::@28
    // display_progress_clear()
    // [103] call display_progress_clear
    // [571] phi from main::@28 to display_progress_clear [phi:main::@28->display_progress_clear]
    jsr display_progress_clear
    // [104] phi from main::@28 to main::@61 [phi:main::@28->main::@61]
    // main::@61
    // main_vera_check()
    // [105] call main_vera_check
    // [717] phi from main::@61 to main_vera_check [phi:main::@61->main_vera_check]
    jsr main_vera_check
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom2
    // BROM = bank
    // [107] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::check_status_smc1
    // status_smc == status
    // [108] main::check_status_smc1_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [109] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0 -- vbum1=vbuz2 
    sta check_status_smc1_return
    // [110] phi from main::check_status_smc1 to main::check_status_cx16_rom1 [phi:main::check_status_smc1->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [111] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [112] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_cx16_rom1_check_status_rom1_return
    // main::@29
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [113] if(0!=main::check_status_smc1_return#0) goto main::check_status_smc2 -- 0_neq_vbum1_then_la1 
    lda check_status_smc1_return
    bne check_status_smc2
    // main::@125
    // [114] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@13 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom1_check_status_rom1_return
    beq !__b13+
    jmp __b13
  !__b13:
    // main::check_status_smc2
  check_status_smc2:
    // status_smc == status
    // [115] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [116] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0 -- vbum1=vbuz2 
    sta check_status_smc2_return
    // [117] phi from main::check_status_smc2 to main::check_status_cx16_rom2 [phi:main::check_status_smc2->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [118] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_NONE -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [119] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_cx16_rom2_check_status_rom1_return
    // main::@30
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [120] if(0==main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_eq_vbum1_then_la1 
    // VA3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
    lda check_status_smc2_return
    beq check_status_smc3
    // main::@126
    // [121] if(0!=main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@1 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom2_check_status_rom1_return
    beq !__b1+
    jmp __b1
  !__b1:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [122] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [123] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0 -- vbum1=vbuz2 
    sta check_status_smc3_return
    // [124] phi from main::check_status_smc3 to main::check_status_cx16_rom3 [phi:main::check_status_smc3->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [125] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [126] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_cx16_rom3_check_status_rom1_return
    // main::@31
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [127] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbum1_then_la1 
    lda check_status_smc3_return
    beq check_status_smc4
    // main::@127
    // [128] if(0==main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@3 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom3_check_status_rom1_return
    bne !__b3+
    jmp __b3
  !__b3:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [129] main::check_status_smc4_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [130] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0 -- vbum1=vbuz2 
    sta check_status_smc4_return
    // [131] phi from main::check_status_smc4 to main::check_status_cx16_rom4 [phi:main::check_status_smc4->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [132] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [133] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_cx16_rom4_check_status_rom1_return
    // main::@32
    // smc_supported_rom(rom_release[0])
    // [134] smc_supported_rom::rom_release#0 = *rom_release -- vbum1=_deref_pbuc1 
    lda rom_release
    sta smc_supported_rom.rom_release
    // [135] call smc_supported_rom
    // [744] phi from main::@32 to smc_supported_rom [phi:main::@32->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_release[0])
    // [136] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@74
    // [137] main::$30 = smc_supported_rom::return#3 -- vbuz1=vbum2 
    lda smc_supported_rom.return
    sta.z main__30
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_release[0]))
    // [138] if(0==main::check_status_smc4_return#0) goto main::check_status_smc5 -- 0_eq_vbum1_then_la1 
    lda check_status_smc4_return
    beq check_status_smc5
    // main::@129
    // [139] if(0==main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::check_status_smc5 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom4_check_status_rom1_return
    beq check_status_smc5
    // main::@128
    // [140] if(0==main::$30) goto main::@4 -- 0_eq_vbuz1_then_la1 
    lda.z main__30
    bne !__b4+
    jmp __b4
  !__b4:
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [141] main::check_status_smc5_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [142] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0 -- vbum1=vbuz2 
    sta check_status_smc5_return
    // main::@33
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [143] if(0!=main::check_status_smc5_return#0) goto main::@6 -- 0_neq_vbum1_then_la1 
    beq !__b6+
    jmp __b6
  !__b6:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [144] main::check_status_smc6_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [145] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0 -- vbum1=vbuz2 
    sta check_status_smc6_return
    // main::check_status_vera1
    // status_vera == status
    // [146] main::check_status_vera1_$0 = status_vera#127 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [147] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0 -- vbum1=vbuz2 
    sta check_status_vera1_return
    // [148] phi from main::check_status_vera1 to main::@34 [phi:main::check_status_vera1->main::@34]
    // main::@34
    // check_status_roms(STATUS_ISSUE)
    // [149] call check_status_roms
    // [751] phi from main::@34 to check_status_roms [phi:main::@34->check_status_roms]
    // [751] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@34->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [150] check_status_roms::return#3 = check_status_roms::return#2
    // main::@79
    // [151] main::$47 = check_status_roms::return#3 -- vbuz1=vbum2 
    lda check_status_roms.return
    sta.z main__47
    // main::check_status_smc7
    // status_smc == status
    // [152] main::check_status_smc7_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [153] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0 -- vbum1=vbuz2 
    sta check_status_smc7_return
    // main::check_status_vera2
    // status_vera == status
    // [154] main::check_status_vera2_$0 = status_vera#127 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [155] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0 -- vbum1=vbuz2 
    sta check_status_vera2_return
    // [156] phi from main::check_status_vera2 to main::@35 [phi:main::check_status_vera2->main::@35]
    // main::@35
    // check_status_roms(STATUS_ERROR)
    // [157] call check_status_roms
    // [751] phi from main::@35 to check_status_roms [phi:main::@35->check_status_roms]
    // [751] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@35->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [158] check_status_roms::return#4 = check_status_roms::return#2
    // main::@80
    // [159] main::$56 = check_status_roms::return#4 -- vbuz1=vbum2 
    lda check_status_roms.return
    sta.z main__56
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [160] if(0!=main::check_status_smc6_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc6_return
    bne check_status_vera3
    // main::@134
    // [161] if(0==main::check_status_vera1_return#0) goto main::@133 -- 0_eq_vbum1_then_la1 
    lda check_status_vera1_return
    bne !__b133+
    jmp __b133
  !__b133:
    // main::check_status_vera3
  check_status_vera3:
    // status_vera == status
    // [162] main::check_status_vera3_$0 = status_vera#127 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [163] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0 -- vbum1=vbuz2 
    sta check_status_vera3_return
    // main::@36
    // if(check_status_vera(STATUS_ERROR))
    // [164] if(0==main::check_status_vera3_return#0) goto main::check_status_smc9 -- 0_eq_vbum1_then_la1 
    bne !check_status_smc9+
    jmp check_status_smc9
  !check_status_smc9:
    // main::bank_set_brom5
    // BROM = bank
    // [165] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // main::vera_display_set_border_color1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [167] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [168] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [169] phi from main::vera_display_set_border_color1 to main::@41 [phi:main::vera_display_set_border_color1->main::@41]
    // main::@41
    // textcolor(WHITE)
    // [170] call textcolor
    // [437] phi from main::@41 to textcolor [phi:main::@41->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:main::@41->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [171] phi from main::@41 to main::@92 [phi:main::@41->main::@92]
    // main::@92
    // bgcolor(BLUE)
    // [172] call bgcolor
    // [442] phi from main::@92 to bgcolor [phi:main::@92->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:main::@92->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [173] phi from main::@92 to main::@93 [phi:main::@92->main::@93]
    // main::@93
    // clrscr()
    // [174] call clrscr
    jsr clrscr
    // [175] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // printf("There was a severe error updating your VERA!")
    // [176] call printf_str
    // [783] phi from main::@94 to printf_str [phi:main::@94->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:main::@94->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s2 [phi:main::@94->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [177] phi from main::@94 to main::@95 [phi:main::@94->main::@95]
    // main::@95
    // printf("You are back at the READY prompt without resetting your CX16.\n\n")
    // [178] call printf_str
    // [783] phi from main::@95 to printf_str [phi:main::@95->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:main::@95->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s3 [phi:main::@95->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // [179] phi from main::@95 to main::@96 [phi:main::@95->main::@96]
    // main::@96
    // printf("Please don't reset or shut down your VERA until you've\n")
    // [180] call printf_str
    // [783] phi from main::@96 to printf_str [phi:main::@96->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:main::@96->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s4 [phi:main::@96->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [181] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // printf("managed to either reflash your VERA with the previous firmware ")
    // [182] call printf_str
    // [783] phi from main::@97 to printf_str [phi:main::@97->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:main::@97->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s5 [phi:main::@97->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [183] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // printf("or have update successs retrying!\n\n")
    // [184] call printf_str
    // [783] phi from main::@98 to printf_str [phi:main::@98->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:main::@98->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s6 [phi:main::@98->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // [185] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // printf("PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n")
    // [186] call printf_str
    // [783] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s7 [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // [187] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // wait_moment(32)
    // [188] call wait_moment
    // [792] phi from main::@100 to wait_moment [phi:main::@100->wait_moment]
    // [792] phi wait_moment::w#10 = $20 [phi:main::@100->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [189] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // system_reset()
    // [190] call system_reset
    // [800] phi from main::@101 to system_reset [phi:main::@101->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [191] return 
    rts
    // main::check_status_smc9
  check_status_smc9:
    // status_smc == status
    // [192] main::check_status_smc9_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [193] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0 -- vbum1=vbuz2 
    sta check_status_smc9_return
    // main::check_status_smc10
    // status_smc == status
    // [194] main::check_status_smc10_$0 = status_smc#0 == STATUS_NONE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [195] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0 -- vbum1=vbuz2 
    sta check_status_smc10_return
    // main::check_status_vera6
    // status_vera == status
    // [196] main::check_status_vera6_$0 = status_vera#127 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera6_main__0
    // return (unsigned char)(status_vera == status);
    // [197] main::check_status_vera6_return#0 = (char)main::check_status_vera6_$0 -- vbum1=vbuz2 
    sta check_status_vera6_return
    // main::check_status_vera7
    // status_vera == status
    // [198] main::check_status_vera7_$0 = status_vera#127 == STATUS_NONE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera7_main__0
    // return (unsigned char)(status_vera == status);
    // [199] main::check_status_vera7_return#0 = (char)main::check_status_vera7_$0 -- vbum1=vbuz2 
    sta check_status_vera7_return
    // [200] phi from main::check_status_vera7 to main::@40 [phi:main::check_status_vera7->main::@40]
    // main::@40
    // check_status_roms_less(STATUS_SKIP)
    // [201] call check_status_roms_less
    // [805] phi from main::@40 to check_status_roms_less [phi:main::@40->check_status_roms_less]
    jsr check_status_roms_less
    // check_status_roms_less(STATUS_SKIP)
    // [202] check_status_roms_less::return#3 = check_status_roms_less::return#2
    // main::@91
    // [203] main::$69 = check_status_roms_less::return#3 -- vbuz1=vbum2 
    lda check_status_roms_less.return
    sta.z main__69
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        (check_status_roms_less(STATUS_SKIP)) )
    // [204] if(0!=main::check_status_smc9_return#0) goto main::@139 -- 0_neq_vbum1_then_la1 
    lda check_status_smc9_return
    beq !__b139+
    jmp __b139
  !__b139:
    // main::@140
    // [205] if(0!=main::check_status_smc10_return#0) goto main::@139 -- 0_neq_vbum1_then_la1 
    lda check_status_smc10_return
    beq !__b139+
    jmp __b139
  !__b139:
    // main::check_status_smc11
  check_status_smc11:
    // status_smc == status
    // [206] main::check_status_smc11_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc11_main__0
    // return (unsigned char)(status_smc == status);
    // [207] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0 -- vbum1=vbuz2 
    sta check_status_smc11_return
    // main::check_status_vera8
    // status_vera == status
    // [208] main::check_status_vera8_$0 = status_vera#127 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera8_main__0
    // return (unsigned char)(status_vera == status);
    // [209] main::check_status_vera8_return#0 = (char)main::check_status_vera8_$0 -- vbum1=vbuz2 
    sta check_status_vera8_return
    // [210] phi from main::check_status_vera8 to main::@43 [phi:main::check_status_vera8->main::@43]
    // main::@43
    // check_status_roms(STATUS_ERROR)
    // [211] call check_status_roms
    // [751] phi from main::@43 to check_status_roms [phi:main::@43->check_status_roms]
    // [751] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@43->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [212] check_status_roms::return#10 = check_status_roms::return#2
    // main::@102
    // [213] main::$151 = check_status_roms::return#10 -- vbuz1=vbum2 
    lda check_status_roms.return
    sta.z main__151
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [214] if(0!=main::check_status_smc11_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc11_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@142
    // [215] if(0!=main::check_status_vera8_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera8_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@141
    // [216] if(0!=main::$151) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z main__151
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::check_status_smc12
    // status_smc == status
    // [217] main::check_status_smc12_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc12_main__0
    // return (unsigned char)(status_smc == status);
    // [218] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0 -- vbum1=vbuz2 
    sta check_status_smc12_return
    // main::check_status_vera9
    // status_vera == status
    // [219] main::check_status_vera9_$0 = status_vera#127 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera9_main__0
    // return (unsigned char)(status_vera == status);
    // [220] main::check_status_vera9_return#0 = (char)main::check_status_vera9_$0 -- vbum1=vbuz2 
    sta check_status_vera9_return
    // [221] phi from main::check_status_vera9 to main::@45 [phi:main::check_status_vera9->main::@45]
    // main::@45
    // check_status_roms(STATUS_ISSUE)
    // [222] call check_status_roms
    // [751] phi from main::@45 to check_status_roms [phi:main::@45->check_status_roms]
    // [751] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@45->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [223] check_status_roms::return#11 = check_status_roms::return#2
    // main::@104
    // [224] main::$156 = check_status_roms::return#11 -- vbuz1=vbum2 
    lda check_status_roms.return
    sta.z main__156
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [225] if(0!=main::check_status_smc12_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_smc12_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@144
    // [226] if(0!=main::check_status_vera9_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_vera9_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@143
    // [227] if(0!=main::$156) goto main::vera_display_set_border_color4 -- 0_neq_vbuz1_then_la1 
    lda.z main__156
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::vera_display_set_border_color5
    // *VERA_CTRL &= ~VERA_DCSEL
    // [228] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [229] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [230] phi from main::vera_display_set_border_color5 to main::@47 [phi:main::vera_display_set_border_color5->main::@47]
    // main::@47
    // display_action_progress("Your CX16 update is a success!")
    // [231] call display_action_progress
    // [557] phi from main::@47 to display_action_progress [phi:main::@47->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text22 [phi:main::@47->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_progress.info_text
    lda #>info_text22
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc13
    // status_smc == status
    // [232] main::check_status_smc13_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc13_main__0
    // return (unsigned char)(status_smc == status);
    // [233] main::check_status_smc13_return#0 = (char)main::check_status_smc13_$0 -- vbum1=vbuz2 
    sta check_status_smc13_return
    // main::@48
    // if(check_status_smc(STATUS_FLASHED))
    // [234] if(0!=main::check_status_smc13_return#0) goto main::@18 -- 0_neq_vbum1_then_la1 
    beq !__b18+
    jmp __b18
  !__b18:
    // [235] phi from main::@48 to main::@9 [phi:main::@48->main::@9]
    // main::@9
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [236] call display_progress_text
    // [813] phi from main::@9 to display_progress_text [phi:main::@9->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_debriefing_text_rom [phi:main::@9->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_debriefing_count_rom [phi:main::@9->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_rom
    sta display_progress_text.lines
    jsr display_progress_text
    // [237] phi from main::@42 main::@46 main::@9 to main::@2 [phi:main::@42/main::@46/main::@9->main::@2]
    // main::@2
  __b2:
    // textcolor(PINK)
    // [238] call textcolor
  // DE6 | Wait until reset
    // [437] phi from main::@2 to textcolor [phi:main::@2->textcolor]
    // [437] phi textcolor::color#21 = PINK [phi:main::@2->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [239] phi from main::@2 to main::@117 [phi:main::@2->main::@117]
    // main::@117
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [240] call display_progress_line
    // [823] phi from main::@117 to display_progress_line [phi:main::@117->display_progress_line]
    // [823] phi display_progress_line::text#3 = main::text [phi:main::@117->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [823] phi display_progress_line::line#3 = 2 [phi:main::@117->display_progress_line#1] -- vbum1=vbuc1 
    lda #2
    sta display_progress_line.line
    jsr display_progress_line
    // [241] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // textcolor(WHITE)
    // [242] call textcolor
    // [437] phi from main::@118 to textcolor [phi:main::@118->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:main::@118->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [243] phi from main::@118 to main::@24 [phi:main::@118->main::@24]
    // [243] phi main::w1#2 = $78 [phi:main::@118->main::@24#0] -- vbuz1=vbuc1 
    lda #$78
    sta.z w1
    // main::@24
  __b24:
    // for (unsigned char w=120; w>0; w--)
    // [244] if(main::w1#2>0) goto main::@25 -- vbuz1_gt_0_then_la1 
    lda.z w1
    bne __b25
    // [245] phi from main::@24 to main::@26 [phi:main::@24->main::@26]
    // main::@26
    // system_reset()
    // [246] call system_reset
    // [800] phi from main::@26 to system_reset [phi:main::@26->system_reset]
    jsr system_reset
    rts
    // [247] phi from main::@24 to main::@25 [phi:main::@24->main::@25]
    // main::@25
  __b25:
    // wait_moment(1)
    // [248] call wait_moment
    // [792] phi from main::@25 to wait_moment [phi:main::@25->wait_moment]
    // [792] phi wait_moment::w#10 = 1 [phi:main::@25->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [249] phi from main::@25 to main::@119 [phi:main::@25->main::@119]
    // main::@119
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [250] call snprintf_init
    jsr snprintf_init
    // [251] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [252] call printf_str
    // [783] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s11 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@121
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [253] printf_uchar::uvalue#8 = main::w1#2 -- vbum1=vbuz2 
    lda.z w1
    sta printf_uchar.uvalue
    // [254] call printf_uchar
    // [832] phi from main::@121 to printf_uchar [phi:main::@121->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@121->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 0 [phi:main::@121->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &snputc [phi:main::@121->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@121->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#8 [phi:main::@121->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [255] phi from main::@121 to main::@122 [phi:main::@121->main::@122]
    // main::@122
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [256] call printf_str
    // [783] phi from main::@122 to printf_str [phi:main::@122->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main::@122->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s12 [phi:main::@122->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@123
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [257] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [258] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [260] call display_action_text
    // [843] phi from main::@123 to display_action_text [phi:main::@123->display_action_text]
    // [843] phi display_action_text::info_text#17 = info_text [phi:main::@123->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@124
    // for (unsigned char w=120; w>0; w--)
    // [261] main::w1#1 = -- main::w1#2 -- vbuz1=_dec_vbuz1 
    dec.z w1
    // [243] phi from main::@124 to main::@24 [phi:main::@124->main::@24]
    // [243] phi main::w1#2 = main::w1#1 [phi:main::@124->main::@24#0] -- register_copy 
    jmp __b24
    // [262] phi from main::@48 to main::@18 [phi:main::@48->main::@18]
    // main::@18
  __b18:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [263] call display_progress_text
    // [813] phi from main::@18 to display_progress_text [phi:main::@18->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_debriefing_text_smc [phi:main::@18->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_debriefing_count_smc [phi:main::@18->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_smc
    sta display_progress_text.lines
    jsr display_progress_text
    // [264] phi from main::@18 to main::@105 [phi:main::@18->main::@105]
    // main::@105
    // textcolor(PINK)
    // [265] call textcolor
    // [437] phi from main::@105 to textcolor [phi:main::@105->textcolor]
    // [437] phi textcolor::color#21 = PINK [phi:main::@105->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [266] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [267] call display_progress_line
    // [823] phi from main::@106 to display_progress_line [phi:main::@106->display_progress_line]
    // [823] phi display_progress_line::text#3 = main::text [phi:main::@106->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [823] phi display_progress_line::line#3 = 2 [phi:main::@106->display_progress_line#1] -- vbum1=vbuc1 
    lda #2
    sta display_progress_line.line
    jsr display_progress_line
    // [268] phi from main::@106 to main::@107 [phi:main::@106->main::@107]
    // main::@107
    // textcolor(WHITE)
    // [269] call textcolor
    // [437] phi from main::@107 to textcolor [phi:main::@107->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:main::@107->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [270] phi from main::@107 to main::@19 [phi:main::@107->main::@19]
    // [270] phi main::w#2 = $78 [phi:main::@107->main::@19#0] -- vbuz1=vbuc1 
    lda #$78
    sta.z w
    // main::@19
  __b19:
    // for (unsigned char w=120; w>0; w--)
    // [271] if(main::w#2>0) goto main::@20 -- vbuz1_gt_0_then_la1 
    lda.z w
    bne __b20
    // [272] phi from main::@19 to main::@21 [phi:main::@19->main::@21]
    // main::@21
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [273] call snprintf_init
    jsr snprintf_init
    // [274] phi from main::@21 to main::@114 [phi:main::@21->main::@114]
    // main::@114
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [275] call printf_str
    // [783] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s10 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [276] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [277] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [279] call display_action_text
    // [843] phi from main::@115 to display_action_text [phi:main::@115->display_action_text]
    // [843] phi display_action_text::info_text#17 = info_text [phi:main::@115->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [280] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // smc_reset()
    // [281] call smc_reset
  // DE5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [857] phi from main::@116 to smc_reset [phi:main::@116->smc_reset]
    jsr smc_reset
    // [282] phi from main::@116 main::@22 to main::@22 [phi:main::@116/main::@22->main::@22]
  __b5:
  // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
    // main::@22
    jmp __b5
    // [283] phi from main::@19 to main::@20 [phi:main::@19->main::@20]
    // main::@20
  __b20:
    // wait_moment(1)
    // [284] call wait_moment
    // [792] phi from main::@20 to wait_moment [phi:main::@20->wait_moment]
    // [792] phi wait_moment::w#10 = 1 [phi:main::@20->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [285] phi from main::@20 to main::@108 [phi:main::@20->main::@108]
    // main::@108
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [286] call snprintf_init
    jsr snprintf_init
    // [287] phi from main::@108 to main::@109 [phi:main::@108->main::@109]
    // main::@109
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [288] call printf_str
    // [783] phi from main::@109 to printf_str [phi:main::@109->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main::@109->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s8 [phi:main::@109->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@110
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [289] printf_uchar::uvalue#7 = main::w#2 -- vbum1=vbuz2 
    lda.z w
    sta printf_uchar.uvalue
    // [290] call printf_uchar
    // [832] phi from main::@110 to printf_uchar [phi:main::@110->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 1 [phi:main::@110->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 3 [phi:main::@110->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &snputc [phi:main::@110->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@110->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#7 [phi:main::@110->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [291] phi from main::@110 to main::@111 [phi:main::@110->main::@111]
    // main::@111
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [292] call printf_str
    // [783] phi from main::@111 to printf_str [phi:main::@111->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main::@111->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main::s9 [phi:main::@111->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@112
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [293] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [294] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [296] call display_action_text
    // [843] phi from main::@112 to display_action_text [phi:main::@112->display_action_text]
    // [843] phi display_action_text::info_text#17 = info_text [phi:main::@112->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@113
    // for (unsigned char w=120; w>0; w--)
    // [297] main::w#1 = -- main::w#2 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [270] phi from main::@113 to main::@19 [phi:main::@113->main::@19]
    // [270] phi main::w#2 = main::w#1 [phi:main::@113->main::@19#0] -- register_copy 
    jmp __b19
    // main::vera_display_set_border_color4
  vera_display_set_border_color4:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [298] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [299] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [300] phi from main::vera_display_set_border_color4 to main::@46 [phi:main::vera_display_set_border_color4->main::@46]
    // main::@46
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [301] call display_action_progress
    // [557] phi from main::@46 to display_action_progress [phi:main::@46->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text21 [phi:main::@46->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_action_progress.info_text
    lda #>info_text21
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b2
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [302] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [303] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [304] phi from main::vera_display_set_border_color3 to main::@44 [phi:main::vera_display_set_border_color3->main::@44]
    // main::@44
    // display_action_progress("Update Failure! Your CX16 may no longer boot!")
    // [305] call display_action_progress
    // [557] phi from main::@44 to display_action_progress [phi:main::@44->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text19 [phi:main::@44->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_action_progress.info_text
    lda #>info_text19
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [306] phi from main::@44 to main::@103 [phi:main::@44->main::@103]
    // main::@103
    // display_action_text("Take a photo of this screen, shut down power and retry!")
    // [307] call display_action_text
    // [843] phi from main::@103 to display_action_text [phi:main::@103->display_action_text]
    // [843] phi display_action_text::info_text#17 = main::info_text20 [phi:main::@103->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_action_text.info_text
    lda #>info_text20
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [308] phi from main::@103 main::@23 to main::@23 [phi:main::@103/main::@23->main::@23]
    // main::@23
  __b23:
    jmp __b23
    // main::@139
  __b139:
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        (check_status_roms_less(STATUS_SKIP)) )
    // [309] if(0!=main::check_status_vera6_return#0) goto main::@138 -- 0_neq_vbum1_then_la1 
    lda check_status_vera6_return
    bne __b138
    // main::@145
    // [310] if(0==main::check_status_vera7_return#0) goto main::check_status_smc11 -- 0_eq_vbum1_then_la1 
    lda check_status_vera7_return
    bne !check_status_smc11+
    jmp check_status_smc11
  !check_status_smc11:
    // main::@138
  __b138:
    // [311] if(0!=main::$69) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z main__69
    bne vera_display_set_border_color2
    jmp check_status_smc11
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [312] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [313] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [314] phi from main::vera_display_set_border_color2 to main::@42 [phi:main::vera_display_set_border_color2->main::@42]
    // main::@42
    // display_action_progress("No CX16 component has been updated with new firmware!")
    // [315] call display_action_progress
    // [557] phi from main::@42 to display_action_progress [phi:main::@42->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text18 [phi:main::@42->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z display_action_progress.info_text
    lda #>info_text18
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b2
    // main::@133
  __b133:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [316] if(0!=main::$47) goto main::check_status_vera3 -- 0_neq_vbuz1_then_la1 
    lda.z main__47
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@132
    // [317] if(0==main::check_status_smc7_return#0) goto main::@131 -- 0_eq_vbum1_then_la1 
    lda check_status_smc7_return
    beq __b131
    jmp check_status_vera3
    // main::@131
  __b131:
    // [318] if(0!=main::check_status_vera2_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera2_return
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@130
    // [319] if(0==main::$56) goto main::check_status_vera4 -- 0_eq_vbuz1_then_la1 
    lda.z main__56
    beq check_status_vera4
    jmp check_status_vera3
    // main::check_status_vera4
  check_status_vera4:
    // status_vera == status
    // [320] main::check_status_vera4_$0 = status_vera#127 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera4_main__0
    // return (unsigned char)(status_vera == status);
    // [321] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0 -- vbum1=vbuz2 
    sta check_status_vera4_return
    // main::check_status_smc8
    // status_smc == status
    // [322] main::check_status_smc8_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [323] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0 -- vbum1=vbuz2 
    sta check_status_smc8_return
    // [324] phi from main::check_status_smc8 to main::check_status_cx16_rom5 [phi:main::check_status_smc8->main::check_status_cx16_rom5]
    // main::check_status_cx16_rom5
    // main::check_status_cx16_rom5_check_status_rom1
    // status_rom[rom_chip] == status
    // [325] main::check_status_cx16_rom5_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom5_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [326] main::check_status_cx16_rom5_check_status_rom1_return#0 = (char)main::check_status_cx16_rom5_check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_cx16_rom5_check_status_rom1_return
    // [327] phi from main::check_status_cx16_rom5_check_status_rom1 to main::@37 [phi:main::check_status_cx16_rom5_check_status_rom1->main::@37]
    // main::@37
    // check_status_card_roms(STATUS_FLASH)
    // [328] call check_status_card_roms
    // [866] phi from main::@37 to check_status_card_roms [phi:main::@37->check_status_card_roms]
    jsr check_status_card_roms
    // check_status_card_roms(STATUS_FLASH)
    // [329] check_status_card_roms::return#3 = check_status_card_roms::return#2
    // main::@83
    // [330] main::$111 = check_status_card_roms::return#3 -- vbuz1=vbum2 
    lda check_status_card_roms.return
    sta.z main__111
    // if(check_status_vera(STATUS_FLASH) || check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [331] if(0!=main::check_status_vera4_return#0) goto main::@7 -- 0_neq_vbum1_then_la1 
    lda check_status_vera4_return
    bne __b7
    // main::@137
    // [332] if(0!=main::check_status_smc8_return#0) goto main::@7 -- 0_neq_vbum1_then_la1 
    lda check_status_smc8_return
    bne __b7
    // main::@136
    // [333] if(0!=main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::@7 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom5_check_status_rom1_return
    bne __b7
    // main::@135
    // [334] if(0!=main::$111) goto main::@7 -- 0_neq_vbuz1_then_la1 
    lda.z main__111
    bne __b7
    // main::bank_set_brom3
  bank_set_brom3:
    // BROM = bank
    // [335] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::check_status_vera5
    // status_vera == status
    // [337] main::check_status_vera5_$0 = status_vera#127 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera5_main__0
    // return (unsigned char)(status_vera == status);
    // [338] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0 -- vbum1=vbuz2 
    sta check_status_vera5_return
    // main::@38
    // if(check_status_vera(STATUS_FLASH))
    // [339] if(0==main::check_status_vera5_return#0) goto main::SEI2 -- 0_eq_vbum1_then_la1 
    beq SEI2
    // [340] phi from main::@38 to main::@17 [phi:main::@38->main::@17]
    // main::@17
    // display_progress_text(display_jp1_spi_vera_text, display_jp1_spi_vera_count)
    // [341] call display_progress_text
    // [813] phi from main::@17 to display_progress_text [phi:main::@17->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_jp1_spi_vera_text [phi:main::@17->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_jp1_spi_vera_text
    sta.z display_progress_text.text
    lda #>display_jp1_spi_vera_text
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_jp1_spi_vera_count [phi:main::@17->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_jp1_spi_vera_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [342] phi from main::@17 to main::@89 [phi:main::@17->main::@89]
    // main::@89
    // util_wait_space()
    // [343] call util_wait_space
    // [875] phi from main::@89 to util_wait_space [phi:main::@89->util_wait_space]
    jsr util_wait_space
    // [344] phi from main::@89 to main::@90 [phi:main::@89->main::@90]
    // main::@90
    // main_vera_flash()
    // [345] call main_vera_flash
    // [878] phi from main::@90 to main_vera_flash [phi:main::@90->main_vera_flash]
    jsr main_vera_flash
    // main::SEI2
  SEI2:
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom4
    // BROM = bank
    // [347] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // [348] phi from main::bank_set_brom4 to main::@39 [phi:main::bank_set_brom4->main::@39]
    // main::@39
    // display_progress_clear()
    // [349] call display_progress_clear
    // [571] phi from main::@39 to display_progress_clear [phi:main::@39->display_progress_clear]
    jsr display_progress_clear
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    jmp check_status_vera3
    // [351] phi from main::@135 main::@136 main::@137 main::@83 to main::@7 [phi:main::@135/main::@136/main::@137/main::@83->main::@7]
    // main::@7
  __b7:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [352] call display_action_progress
    // [557] phi from main::@7 to display_action_progress [phi:main::@7->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text12 [phi:main::@7->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_action_progress.info_text
    lda #>info_text12
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [353] phi from main::@7 to main::@84 [phi:main::@7->main::@84]
    // main::@84
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [354] call util_wait_key
    // [1032] phi from main::@84 to util_wait_key [phi:main::@84->util_wait_key]
    // [1032] phi util_wait_key::filter#13 = main::filter1 [phi:main::@84->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z util_wait_key.filter
    lda #>filter1
    sta.z util_wait_key.filter+1
    // [1032] phi util_wait_key::info_text#3 = main::info_text13 [phi:main::@84->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z util_wait_key.info_text
    lda #>info_text13
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [355] util_wait_key::return#4 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return_1
    // main::@85
    // [356] main::ch1#0 = util_wait_key::return#4 -- vbuz1=vbum2 
    sta.z ch1
    // strchr("nN", ch)
    // [357] strchr::c#1 = main::ch1#0 -- vbum1=vbuz2 
    sta strchr.c
    // [358] call strchr
    // [1057] phi from main::@85 to strchr [phi:main::@85->strchr]
    // [1057] phi strchr::c#4 = strchr::c#1 [phi:main::@85->strchr#0] -- register_copy 
    // [1057] phi strchr::str#2 = (const void *)main::$206 [phi:main::@85->strchr#1] -- pvoz1=pvoc1 
    lda #<main__206
    sta.z strchr.str
    lda #>main__206
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [359] strchr::return#4 = strchr::return#2
    // main::@86
    // [360] main::$116 = strchr::return#4
    // if(strchr("nN", ch))
    // [361] if((void *)0==main::$116) goto main::bank_set_brom3 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__116
    cmp #<0
    bne !+
    lda.z main__116+1
    cmp #>0
    beq bank_set_brom3
  !:
    // [362] phi from main::@86 to main::@8 [phi:main::@86->main::@8]
    // main::@8
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [363] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [615] phi from main::@8 to display_info_smc [phi:main::@8->display_info_smc]
    // [615] phi display_info_smc::info_text#10 = main::info_text14 [phi:main::@8->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_smc.info_text
    lda #>info_text14
    sta.z display_info_smc.info_text+1
    // [615] phi display_info_smc::info_status#10 = STATUS_SKIP [phi:main::@8->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // main::@87
    // [364] spi_manufacturer#405 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [365] spi_memory_type#406 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [366] spi_memory_capacity#407 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [367] call display_info_vera
    // [651] phi from main::@87 to display_info_vera [phi:main::@87->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = main::info_text14 [phi:main::@87->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_vera.info_text
    lda #>info_text14
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#407 [phi:main::@87->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#406 [phi:main::@87->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#405 [phi:main::@87->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main::@87->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [368] phi from main::@87 to main::@14 [phi:main::@87->main::@14]
    // [368] phi main::rom_chip1#2 = 0 [phi:main::@87->main::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip1
    // main::@14
  __b14:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [369] if(main::rom_chip1#2<8) goto main::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip1
    cmp #8
    bcc __b15
    // [370] phi from main::@14 to main::@16 [phi:main::@14->main::@16]
    // main::@16
    // display_action_text("You have selected not to cancel the update ... ")
    // [371] call display_action_text
    // [843] phi from main::@16 to display_action_text [phi:main::@16->display_action_text]
    // [843] phi display_action_text::info_text#17 = main::info_text17 [phi:main::@16->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_action_text.info_text
    lda #>info_text17
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_brom3
    // main::@15
  __b15:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [372] display_info_rom::rom_chip#3 = main::rom_chip1#2 -- vbum1=vbuz2 
    lda.z rom_chip1
    sta display_info_rom.rom_chip
    // [373] call display_info_rom
    // [1066] phi from main::@15 to display_info_rom [phi:main::@15->display_info_rom]
    // [1066] phi display_info_rom::info_text#10 = main::info_text14 [phi:main::@15->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_rom.info_text
    lda #>info_text14
    sta.z display_info_rom.info_text+1
    // [1066] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#3 [phi:main::@15->display_info_rom#1] -- register_copy 
    // [1066] phi display_info_rom::info_status#10 = STATUS_SKIP [phi:main::@15->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@88
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [374] main::rom_chip1#1 = ++ main::rom_chip1#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip1
    // [368] phi from main::@88 to main::@14 [phi:main::@88->main::@14]
    // [368] phi main::rom_chip1#2 = main::rom_chip1#1 [phi:main::@88->main::@14#0] -- register_copy 
    jmp __b14
    // [375] phi from main::@33 to main::@6 [phi:main::@33->main::@6]
    // main::@6
  __b6:
    // display_action_progress("The SMC chip and SMC.BIN versions are equal, no flash required!")
    // [376] call display_action_progress
    // [557] phi from main::@6 to display_action_progress [phi:main::@6->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text10 [phi:main::@6->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [377] phi from main::@6 to main::@81 [phi:main::@6->main::@81]
    // main::@81
    // util_wait_space()
    // [378] call util_wait_space
    // [875] phi from main::@81 to util_wait_space [phi:main::@81->util_wait_space]
    jsr util_wait_space
    // [379] phi from main::@81 to main::@82 [phi:main::@81->main::@82]
    // main::@82
    // display_info_smc(STATUS_SKIP, "SMC.BIN and SMC equal.")
    // [380] call display_info_smc
    // [615] phi from main::@82 to display_info_smc [phi:main::@82->display_info_smc]
    // [615] phi display_info_smc::info_text#10 = main::info_text11 [phi:main::@82->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_info_smc.info_text
    lda #>info_text11
    sta.z display_info_smc.info_text+1
    // [615] phi display_info_smc::info_status#10 = STATUS_SKIP [phi:main::@82->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_smc6
    // [381] phi from main::@128 to main::@4 [phi:main::@128->main::@4]
    // main::@4
  __b4:
    // display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!")
    // [382] call display_action_progress
    // [557] phi from main::@4 to display_action_progress [phi:main::@4->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text8 [phi:main::@4->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [383] phi from main::@4 to main::@75 [phi:main::@4->main::@75]
    // main::@75
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [384] call display_progress_text
    // [813] phi from main::@75 to display_progress_text [phi:main::@75->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_smc_unsupported_rom_text [phi:main::@75->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_smc_unsupported_rom_count [phi:main::@75->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [385] phi from main::@75 to main::@76 [phi:main::@75->main::@76]
    // main::@76
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [386] call util_wait_key
    // [1032] phi from main::@76 to util_wait_key [phi:main::@76->util_wait_key]
    // [1032] phi util_wait_key::filter#13 = main::filter [phi:main::@76->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1032] phi util_wait_key::info_text#3 = main::info_text9 [phi:main::@76->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z util_wait_key.info_text
    lda #>info_text9
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [387] util_wait_key::return#3 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return
    // main::@77
    // [388] main::ch#0 = util_wait_key::return#3 -- vbuz1=vbum2 
    sta.z ch
    // if(ch == 'N')
    // [389] if(main::ch#0!='N') goto main::check_status_smc5 -- vbuz1_neq_vbuc1_then_la1 
    lda #'N'
    cmp.z ch
    beq !check_status_smc5+
    jmp check_status_smc5
  !check_status_smc5:
    // [390] phi from main::@77 to main::@5 [phi:main::@77->main::@5]
    // main::@5
    // display_info_smc(STATUS_ISSUE, NULL)
    // [391] call display_info_smc
  // Cancel flash
    // [615] phi from main::@5 to display_info_smc [phi:main::@5->display_info_smc]
    // [615] phi display_info_smc::info_text#10 = 0 [phi:main::@5->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [615] phi display_info_smc::info_status#10 = STATUS_ISSUE [phi:main::@5->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [392] phi from main::@5 to main::@78 [phi:main::@5->main::@78]
    // main::@78
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [393] call display_info_cx16_rom
    // [1111] phi from main::@78 to display_info_cx16_rom [phi:main::@78->display_info_cx16_rom]
    // [1111] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@78->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1111] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@78->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc5
    // [394] phi from main::@127 to main::@3 [phi:main::@127->main::@3]
    // main::@3
  __b3:
    // display_action_progress("CX16 ROM update issue!")
    // [395] call display_action_progress
    // [557] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text6 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_action_progress.info_text
    lda #>info_text6
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [396] phi from main::@3 to main::@70 [phi:main::@3->main::@70]
    // main::@70
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [397] call display_progress_text
    // [813] phi from main::@70 to display_progress_text [phi:main::@70->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_smc_rom_issue_text [phi:main::@70->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_smc_rom_issue_count [phi:main::@70->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [398] phi from main::@70 to main::@71 [phi:main::@70->main::@71]
    // main::@71
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [399] call display_info_smc
    // [615] phi from main::@71 to display_info_smc [phi:main::@71->display_info_smc]
    // [615] phi display_info_smc::info_text#10 = main::info_text4 [phi:main::@71->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [615] phi display_info_smc::info_status#10 = STATUS_SKIP [phi:main::@71->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [400] phi from main::@71 to main::@72 [phi:main::@71->main::@72]
    // main::@72
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [401] call display_info_cx16_rom
    // [1111] phi from main::@72 to display_info_cx16_rom [phi:main::@72->display_info_cx16_rom]
    // [1111] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@72->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1111] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@72->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [402] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // util_wait_space()
    // [403] call util_wait_space
    // [875] phi from main::@73 to util_wait_space [phi:main::@73->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [404] phi from main::@126 to main::@1 [phi:main::@126->main::@1]
    // main::@1
  __b1:
    // display_action_progress("CX16 ROM update issue, ROM not detected!")
    // [405] call display_action_progress
    // [557] phi from main::@1 to display_action_progress [phi:main::@1->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text3 [phi:main::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [406] phi from main::@1 to main::@66 [phi:main::@1->main::@66]
    // main::@66
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [407] call display_progress_text
    // [813] phi from main::@66 to display_progress_text [phi:main::@66->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_smc_rom_issue_text [phi:main::@66->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_smc_rom_issue_count [phi:main::@66->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [408] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [409] call display_info_smc
    // [615] phi from main::@67 to display_info_smc [phi:main::@67->display_info_smc]
    // [615] phi display_info_smc::info_text#10 = main::info_text4 [phi:main::@67->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [615] phi display_info_smc::info_status#10 = STATUS_SKIP [phi:main::@67->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [410] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [411] call display_info_cx16_rom
    // [1111] phi from main::@68 to display_info_cx16_rom [phi:main::@68->display_info_cx16_rom]
    // [1111] phi display_info_cx16_rom::info_text#4 = main::info_text5 [phi:main::@68->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_cx16_rom.info_text
    lda #>info_text5
    sta.z display_info_cx16_rom.info_text+1
    // [1111] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@68->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [412] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // util_wait_space()
    // [413] call util_wait_space
    // [875] phi from main::@69 to util_wait_space [phi:main::@69->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [414] phi from main::@125 to main::@13 [phi:main::@125->main::@13]
    // main::@13
  __b13:
    // display_action_progress("SMC update issue!")
    // [415] call display_action_progress
    // [557] phi from main::@13 to display_action_progress [phi:main::@13->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main::info_text1 [phi:main::@13->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [416] phi from main::@13 to main::@62 [phi:main::@13->main::@62]
    // main::@62
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [417] call display_progress_text
    // [813] phi from main::@62 to display_progress_text [phi:main::@62->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_smc_rom_issue_text [phi:main::@62->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_smc_rom_issue_count [phi:main::@62->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [418] phi from main::@62 to main::@63 [phi:main::@62->main::@63]
    // main::@63
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [419] call display_info_cx16_rom
    // [1111] phi from main::@63 to display_info_cx16_rom [phi:main::@63->display_info_cx16_rom]
    // [1111] phi display_info_cx16_rom::info_text#4 = main::info_text2 [phi:main::@63->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_cx16_rom.info_text
    lda #>info_text2
    sta.z display_info_cx16_rom.info_text+1
    // [1111] phi display_info_cx16_rom::info_status#4 = STATUS_SKIP [phi:main::@63->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [420] phi from main::@63 to main::@64 [phi:main::@63->main::@64]
    // main::@64
    // display_info_smc(STATUS_ISSUE, NULL)
    // [421] call display_info_smc
    // [615] phi from main::@64 to display_info_smc [phi:main::@64->display_info_smc]
    // [615] phi display_info_smc::info_text#10 = 0 [phi:main::@64->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [615] phi display_info_smc::info_status#10 = STATUS_ISSUE [phi:main::@64->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [422] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
    // util_wait_space()
    // [423] call util_wait_space
    // [875] phi from main::@65 to util_wait_space [phi:main::@65->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc2
    // main::@11
  __b11:
    // rom_chip*13
    // [424] main::$229 = main::rom_chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z main__229
    // [425] main::$230 = main::$229 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__230
    clc
    adc.z rom_chip
    sta.z main__230
    // [426] main::$231 = main::$230 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__231
    asl
    asl
    sta.z main__231
    // [427] main::$72 = main::$231 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__72
    clc
    adc.z rom_chip
    sta.z main__72
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [428] strcpy::destination#1 = rom_release_text + main::$72 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [429] call strcpy
    // [1116] phi from main::@11 to strcpy [phi:main::@11->strcpy]
    // [1116] phi strcpy::dst#0 = strcpy::destination#1 [phi:main::@11->strcpy#0] -- register_copy 
    // [1116] phi strcpy::src#0 = main::source [phi:main::@11->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@58
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [430] display_info_rom::rom_chip#2 = main::rom_chip#2 -- vbum1=vbuz2 
    lda.z rom_chip
    sta display_info_rom.rom_chip
    // [431] call display_info_rom
    // [1066] phi from main::@58 to display_info_rom [phi:main::@58->display_info_rom]
    // [1066] phi display_info_rom::info_text#10 = 0 [phi:main::@58->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1066] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#2 [phi:main::@58->display_info_rom#1] -- register_copy 
    // [1066] phi display_info_rom::info_status#10 = STATUS_NONE [phi:main::@58->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@59
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [432] main::rom_chip#1 = ++ main::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [94] phi from main::@59 to main::@10 [phi:main::@59->main::@10]
    // [94] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@59->main::@10#0] -- register_copy 
    jmp __b10
  .segment Data
    title_text: .text "Commander X16 Update Utility (v3.0.0) "
    .byte 0
    s: .text "# Chip Status    Type   Curr. Release Update Info"
    .byte 0
    s1: .text "- ---- --------- ------ ------------- --------------------------"
    .byte 0
    info_text: .text "Introduction, please read carefully the below!"
    .byte 0
    source: .text "          "
    .byte 0
    info_text1: .text "SMC update issue!"
    .byte 0
    info_text2: .text "Issue with SMC!"
    .byte 0
    info_text3: .text "CX16 ROM update issue, ROM not detected!"
    .byte 0
    info_text4: .text "Issue with main CX16 ROM!"
    .byte 0
    info_text5: .text "Are J1 jumper pins closed?"
    .byte 0
    info_text6: .text "CX16 ROM update issue!"
    .byte 0
    info_text8: .text "Compatibility between ROM.BIN and SMC.BIN can't be assured!"
    .byte 0
    info_text9: .text "Continue with flashing anyway? [Y/N]"
    .byte 0
    filter: .text "YN"
    .byte 0
    info_text10: .text "The SMC chip and SMC.BIN versions are equal, no flash required!"
    .byte 0
    info_text11: .text "SMC.BIN and SMC equal."
    .byte 0
    info_text12: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text13: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter1: .text "nyNY"
    .byte 0
    main__206: .text "nN"
    .byte 0
    info_text14: .text "Cancelled"
    .byte 0
    info_text17: .text "You have selected not to cancel the update ... "
    .byte 0
    s2: .text "There was a severe error updating your VERA!"
    .byte 0
    s3: .text @"You are back at the READY prompt without resetting your CX16.\n\n"
    .byte 0
    s4: .text @"Please don't reset or shut down your VERA until you've\n"
    .byte 0
    s5: .text "managed to either reflash your VERA with the previous firmware "
    .byte 0
    s6: .text @"or have update successs retrying!\n\n"
    .byte 0
    s7: .text @"PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n"
    .byte 0
    info_text18: .text "No CX16 component has been updated with new firmware!"
    .byte 0
    info_text19: .text "Update Failure! Your CX16 may no longer boot!"
    .byte 0
    info_text20: .text "Take a photo of this screen, shut down power and retry!"
    .byte 0
    info_text21: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text22: .text "Your CX16 update is a success!"
    .byte 0
    text: .text "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!"
    .byte 0
    s8: .text "["
    .byte 0
    s9: .text "] Please read carefully the below ..."
    .byte 0
    s10: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s11: .text "("
    .byte 0
    s12: .text ") Your CX16 will reset after countdown ..."
    .byte 0
    check_status_smc1_return: .byte 0
    check_status_cx16_rom1_check_status_rom1_return: .byte 0
    check_status_smc2_return: .byte 0
    check_status_cx16_rom2_check_status_rom1_return: .byte 0
    check_status_smc3_return: .byte 0
    check_status_cx16_rom3_check_status_rom1_return: .byte 0
    check_status_smc4_return: .byte 0
    check_status_cx16_rom4_check_status_rom1_return: .byte 0
    check_status_smc5_return: .byte 0
    check_status_smc6_return: .byte 0
    check_status_vera1_return: .byte 0
    check_status_smc7_return: .byte 0
    check_status_vera2_return: .byte 0
    check_status_vera3_return: .byte 0
    check_status_vera4_return: .byte 0
    check_status_smc8_return: .byte 0
    check_status_cx16_rom5_check_status_rom1_return: .byte 0
    check_status_vera5_return: .byte 0
    check_status_smc9_return: .byte 0
    check_status_smc10_return: .byte 0
    check_status_vera6_return: .byte 0
    check_status_vera7_return: .byte 0
    check_status_smc11_return: .byte 0
    check_status_vera8_return: .byte 0
    check_status_smc12_return: .byte 0
    check_status_vera9_return: .byte 0
    check_status_smc13_return: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [433] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [434] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [435] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [436] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $55
    .label textcolor__1 = $55
    // __conio.color & 0xF0
    // [438] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [439] textcolor::$1 = textcolor::$0 | textcolor::color#21 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [440] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [441] return 
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
    .label bgcolor__0 = $55
    .label bgcolor__1 = $58
    .label bgcolor__2 = $55
    // __conio.color & 0x0F
    // [443] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [444] bgcolor::$1 = bgcolor::color#15 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [445] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [446] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [447] return 
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
    // [448] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [449] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [450] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [451] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [453] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [454] return 
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
    // [456] if(gotoxy::x#26>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [458] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [458] phi gotoxy::$3 = gotoxy::x#26 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [457] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [458] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [458] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [459] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [460] if(gotoxy::y#26>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [461] gotoxy::$14 = gotoxy::y#26 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [462] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [462] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [463] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [464] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [465] gotoxy::$10 = gotoxy::y#26 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [466] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [467] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [468] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [469] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    // [470] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [471] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [472] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [473] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [474] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [475] return 
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
    .label cx16_k_screen_set_charset1_offset = $b2
    // cx16_k_screen_set_mode(0)
    // [476] cx16_k_screen_set_mode::mode = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_screen_set_mode.mode
    // [477] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [478] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // screenlayer1()
    // [479] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // display_frame_init_64::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [480] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [481] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // [483] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [484] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [485] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [486] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [487] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [488] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [489] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [490] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [491] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [492] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [493] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [494] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [495] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [496] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [497] phi from display_frame_init_64::vera_layer1_show1 to display_frame_init_64::@1 [phi:display_frame_init_64::vera_layer1_show1->display_frame_init_64::@1]
    // display_frame_init_64::@1
    // textcolor(WHITE)
    // [498] call textcolor
  // Layer 1 is the current text canvas.
    // [437] phi from display_frame_init_64::@1 to textcolor [phi:display_frame_init_64::@1->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:display_frame_init_64::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [499] phi from display_frame_init_64::@1 to display_frame_init_64::@4 [phi:display_frame_init_64::@1->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // bgcolor(BLUE)
    // [500] call bgcolor
  // Default text color is white.
    // [442] phi from display_frame_init_64::@4 to bgcolor [phi:display_frame_init_64::@4->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_frame_init_64::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [501] phi from display_frame_init_64::@4 to display_frame_init_64::@5 [phi:display_frame_init_64::@4->display_frame_init_64::@5]
    // display_frame_init_64::@5
    // clrscr()
    // [502] call clrscr
    // With a blue background.
    // cx16-conio.c won't compile scrolling code for this program with the underlying define, resulting in less code overhead!
    jsr clrscr
    // display_frame_init_64::@return
    // }
    // [503] return 
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
    // [505] call textcolor
    // [437] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [437] phi textcolor::color#21 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [506] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [507] call bgcolor
    // [442] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [508] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [509] call clrscr
    jsr clrscr
    // [510] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [511] call display_frame
    // [1173] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1173] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [512] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [513] call display_frame
    // [1173] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1173] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [514] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [515] call display_frame
    // [1173] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [516] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [517] call display_frame
  // Chipset areas
    // [1173] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x1
    jsr display_frame
    // [518] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [519] call display_frame
    // [1173] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x1
    jsr display_frame
    // [520] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [521] call display_frame
    // [1173] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x1
    jsr display_frame
    // [522] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [523] call display_frame
    // [1173] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x1
    jsr display_frame
    // [524] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [525] call display_frame
    // [1173] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x1
    jsr display_frame
    // [526] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [527] call display_frame
    // [1173] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x1
    jsr display_frame
    // [528] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [529] call display_frame
    // [1173] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x1
    jsr display_frame
    // [530] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [531] call display_frame
    // [1173] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x1
    jsr display_frame
    // [532] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [533] call display_frame
    // [1173] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x1
    jsr display_frame
    // [534] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [535] call display_frame
    // [1173] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1173] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [536] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [537] call display_frame
  // Progress area
    // [1173] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1173] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [538] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [539] call display_frame
    // [1173] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1173] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [540] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [541] call display_frame
    // [1173] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1173] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [1173] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [1173] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1173] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [542] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [543] call textcolor
    // [437] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [544] return 
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
    // [546] call gotoxy
    // [455] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [455] phi gotoxy::y#26 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [547] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [548] call printf_string
    // [1307] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [549] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($49) const char *s)
cputsxy: {
    .label s = $49
    // gotoxy(x, y)
    // [551] gotoxy::x#1 = cputsxy::x#3 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [552] gotoxy::y#1 = cputsxy::y#3 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [553] call gotoxy
    // [455] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [554] cputs::s#1 = cputsxy::s#3 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [555] call cputs
    // [1332] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [556] return 
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
// void display_action_progress(__zp($42) char *info_text)
display_action_progress: {
    .label info_text = $42
    // unsigned char x = wherex()
    // [558] call wherex
    jsr wherex
    // [559] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [560] display_action_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [561] call wherey
    jsr wherey
    // [562] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [563] display_action_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [564] call gotoxy
    // [455] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [455] phi gotoxy::y#26 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [565] printf_string::str#1 = display_action_progress::info_text#19
    // [566] call printf_string
    // [1307] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [567] gotoxy::x#14 = display_action_progress::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [568] gotoxy::y#14 = display_action_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [569] call gotoxy
    // [455] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#14 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#14 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [570] return 
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
    // [572] call textcolor
    // [437] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [573] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [574] call bgcolor
    // [442] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [575] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [575] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [576] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [577] return 
    rts
    // [578] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [578] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x
    // [578] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [579] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [580] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [575] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [575] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [581] cputcxy::x#14 = display_progress_clear::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [582] cputcxy::y#14 = display_progress_clear::y#2 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [583] call cputcxy
    // [1345] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1345] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [1345] phi cputcxy::y#15 = cputcxy::y#14 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#14 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [584] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbum1=_inc_vbum1 
    inc x
    // for(unsigned char i = 0; i < w; i++)
    // [585] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [578] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [578] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [578] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
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
    // [587] call display_smc_led
    // [1353] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1353] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_smc_led.c
    jsr display_smc_led
    // [588] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [589] call display_print_chip
    // [1359] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1359] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1359] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta display_print_chip.w
    // [1359] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #1
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [590] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [592] call display_vera_led
    // [1403] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [1403] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_vera_led.c
    jsr display_vera_led
    // [593] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [594] call display_print_chip
    // [1359] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1359] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1359] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta display_print_chip.w
    // [1359] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #9
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [595] return 
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
    .label display_chip_rom__4 = $4e
    .label display_chip_rom__6 = $4d
    .label display_chip_rom__11 = $4d
    .label display_chip_rom__12 = $4d
    // [597] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [597] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [598] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [599] return 
    rts
    // [600] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [601] call strcpy
    // [1116] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [1116] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [1116] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [602] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbum2_rol_1 
    lda r
    asl
    sta.z display_chip_rom__11
    // [603] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [604] call strcat
    // [1409] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [605] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [606] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [607] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [608] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbum1=vbum2 
    lda r
    sta display_rom_led.chip
    // [609] call display_rom_led
    // [1421] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [1421] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_rom_led.c
    // [1421] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [610] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbum2 
    lda r
    clc
    adc.z display_chip_rom__12
    sta.z display_chip_rom__12
    // [611] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [612] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbum1=vbuc1_plus_vbuz2 
    lda #$14
    clc
    adc.z display_chip_rom__6
    sta display_print_chip.x
    // [613] call display_print_chip
    // [1359] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1359] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1359] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta display_print_chip.w
    // [1359] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [614] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [597] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [597] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
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
// void display_info_smc(__mem() char info_status, __zp($34) char *info_text)
display_info_smc: {
    .label display_info_smc__9 = $4d
    .label info_text = $34
    // unsigned char x = wherex()
    // [616] call wherex
    jsr wherex
    // [617] wherex::return#10 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_2
    // display_info_smc::@3
    // [618] display_info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [619] call wherey
    jsr wherey
    // [620] wherey::return#10 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_2
    // display_info_smc::@4
    // [621] display_info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [622] status_smc#0 = display_info_smc::info_status#10 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [623] display_smc_led::c#1 = status_color[display_info_smc::info_status#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_smc_led.c
    // [624] call display_smc_led
    // [1353] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1353] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [625] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [626] call gotoxy
    // [455] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [455] phi gotoxy::y#26 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [627] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [628] call printf_str
    // [783] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [629] display_info_smc::$9 = display_info_smc::info_status#10 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_smc__9
    // [630] printf_string::str#3 = status_text[display_info_smc::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [631] call printf_string
    // [1307] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [632] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [633] call printf_str
    // [783] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [634] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [635] call printf_string
    // [1307] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = smc_version_text [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_smc::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 8 [phi:display_info_smc::@9->printf_string#3] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [636] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [637] call printf_str
    // [783] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [638] phi from display_info_smc::@10 to display_info_smc::@11 [phi:display_info_smc::@10->display_info_smc::@11]
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [639] call printf_uint
    // [1432] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    // [1432] phi printf_uint::format_zero_padding#4 = 0 [phi:display_info_smc::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [1432] phi printf_uint::format_min_length#4 = 0 [phi:display_info_smc::@11->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [1432] phi printf_uint::putc#4 = &cputc [phi:display_info_smc::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1432] phi printf_uint::format_radix#4 = DECIMAL [phi:display_info_smc::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [1432] phi printf_uint::uvalue#4 = smc_bootloader [phi:display_info_smc::@11->printf_uint#4] -- vwum1=vwuc1 
    lda #<smc_bootloader
    sta printf_uint.uvalue
    lda #>smc_bootloader
    sta printf_uint.uvalue+1
    jsr printf_uint
    // [640] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [641] call printf_str
    // [783] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [642] if((char *)0==display_info_smc::info_text#10) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [643] phi from display_info_smc::@13 to display_info_smc::@2 [phi:display_info_smc::@13->display_info_smc::@2]
    // display_info_smc::@2
    // gotoxy(INFO_X+64-28, INFO_Y)
    // [644] call gotoxy
    // [455] phi from display_info_smc::@2 to gotoxy [phi:display_info_smc::@2->gotoxy]
    // [455] phi gotoxy::y#26 = $11 [phi:display_info_smc::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = 4+$40-$1c [phi:display_info_smc::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_smc::@14
    // printf("%-25s", info_text)
    // [645] printf_string::str#5 = display_info_smc::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [646] call printf_string
    // [1307] phi from display_info_smc::@14 to printf_string [phi:display_info_smc::@14->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_smc::@14->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#5 [phi:display_info_smc::@14->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_smc::@14->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = $19 [phi:display_info_smc::@14->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [647] gotoxy::x#18 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [648] gotoxy::y#18 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [649] call gotoxy
    // [455] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#18 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#18 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [650] return 
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
// void display_info_vera(__mem() char info_status, __zp($36) char *info_text)
display_info_vera: {
    .label display_info_vera__9 = $4e
    .label info_text = $36
    // unsigned char x = wherex()
    // [652] call wherex
    jsr wherex
    // [653] wherex::return#11 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_3
    // display_info_vera::@3
    // [654] display_info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [655] call wherey
    jsr wherey
    // [656] wherey::return#11 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_3
    // display_info_vera::@4
    // [657] display_info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [658] status_vera#127 = display_info_vera::info_status#19 -- vbum1=vbum2 
    lda info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [659] display_vera_led::c#1 = status_color[display_info_vera::info_status#19] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_vera_led.c
    // [660] call display_vera_led
    // [1403] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [1403] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [661] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [662] call gotoxy
    // [455] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [455] phi gotoxy::y#26 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [663] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [664] call printf_str
    // [783] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [665] display_info_vera::$9 = display_info_vera::info_status#19 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_vera__9
    // [666] printf_string::str#6 = status_text[display_info_vera::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [667] call printf_string
    // [1307] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [668] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [669] call printf_str
    // [783] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [670] printf_uchar::uvalue#1 = spi_manufacturer#100 -- vbum1=vbum2 
    lda spi_manufacturer
    sta printf_uchar.uvalue
    // [671] call printf_uchar
    // [832] phi from display_info_vera::@9 to printf_uchar [phi:display_info_vera::@9->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 1 [phi:display_info_vera::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_vera::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &cputc [phi:display_info_vera::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_info_vera::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:display_info_vera::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [672] phi from display_info_vera::@9 to display_info_vera::@10 [phi:display_info_vera::@9->display_info_vera::@10]
    // display_info_vera::@10
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [673] call printf_str
    // [783] phi from display_info_vera::@10 to printf_str [phi:display_info_vera::@10->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_vera::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s [phi:display_info_vera::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@11
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [674] printf_uchar::uvalue#2 = spi_memory_type#111 -- vbum1=vbum2 
    lda spi_memory_type
    sta printf_uchar.uvalue
    // [675] call printf_uchar
    // [832] phi from display_info_vera::@11 to printf_uchar [phi:display_info_vera::@11->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 1 [phi:display_info_vera::@11->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_vera::@11->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &cputc [phi:display_info_vera::@11->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_info_vera::@11->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:display_info_vera::@11->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [676] phi from display_info_vera::@11 to display_info_vera::@12 [phi:display_info_vera::@11->display_info_vera::@12]
    // display_info_vera::@12
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [677] call printf_str
    // [783] phi from display_info_vera::@12 to printf_str [phi:display_info_vera::@12->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_vera::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s [phi:display_info_vera::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@13
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [678] printf_uchar::uvalue#3 = spi_memory_capacity#110 -- vbum1=vbum2 
    lda spi_memory_capacity
    sta printf_uchar.uvalue
    // [679] call printf_uchar
    // [832] phi from display_info_vera::@13 to printf_uchar [phi:display_info_vera::@13->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 1 [phi:display_info_vera::@13->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_vera::@13->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &cputc [phi:display_info_vera::@13->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_info_vera::@13->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:display_info_vera::@13->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [680] phi from display_info_vera::@13 to display_info_vera::@14 [phi:display_info_vera::@13->display_info_vera::@14]
    // display_info_vera::@14
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [681] call printf_str
    // [783] phi from display_info_vera::@14 to printf_str [phi:display_info_vera::@14->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_vera::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_info_vera::s4 [phi:display_info_vera::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@15
    // if(info_text)
    // [682] if((char *)0==display_info_vera::info_text#19) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [683] phi from display_info_vera::@15 to display_info_vera::@2 [phi:display_info_vera::@15->display_info_vera::@2]
    // display_info_vera::@2
    // gotoxy(INFO_X+64-28, INFO_Y+1)
    // [684] call gotoxy
    // [455] phi from display_info_vera::@2 to gotoxy [phi:display_info_vera::@2->gotoxy]
    // [455] phi gotoxy::y#26 = $11+1 [phi:display_info_vera::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = 4+$40-$1c [phi:display_info_vera::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_vera::@16
    // printf("%-25s", info_text)
    // [685] printf_string::str#7 = display_info_vera::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [686] call printf_string
    // [1307] phi from display_info_vera::@16 to printf_string [phi:display_info_vera::@16->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_vera::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#7 [phi:display_info_vera::@16->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_vera::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = $19 [phi:display_info_vera::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [687] gotoxy::x#21 = display_info_vera::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [688] gotoxy::y#21 = display_info_vera::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [689] call gotoxy
    // [455] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#21 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#21 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [690] return 
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
    .label intro_status = $7a
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [692] call display_progress_text
    // [813] phi from main_intro to display_progress_text [phi:main_intro->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_into_briefing_text [phi:main_intro->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_intro_briefing_count [phi:main_intro->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_briefing_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [693] phi from main_intro to main_intro::@4 [phi:main_intro->main_intro::@4]
    // main_intro::@4
    // util_wait_space()
    // [694] call util_wait_space
    // [875] phi from main_intro::@4 to util_wait_space [phi:main_intro::@4->util_wait_space]
    jsr util_wait_space
    // [695] phi from main_intro::@4 to main_intro::@5 [phi:main_intro::@4->main_intro::@5]
    // main_intro::@5
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [696] call display_progress_text
    // [813] phi from main_intro::@5 to display_progress_text [phi:main_intro::@5->display_progress_text]
    // [813] phi display_progress_text::text#11 = display_into_colors_text [phi:main_intro::@5->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [813] phi display_progress_text::lines#10 = display_intro_colors_count [phi:main_intro::@5->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_colors_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [697] phi from main_intro::@5 to main_intro::@1 [phi:main_intro::@5->main_intro::@1]
    // [697] phi main_intro::intro_status#2 = 0 [phi:main_intro::@5->main_intro::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_status
    // main_intro::@1
  __b1:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [698] if(main_intro::intro_status#2<$b) goto main_intro::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_status
    cmp #$b
    bcc __b2
    // [699] phi from main_intro::@1 to main_intro::@3 [phi:main_intro::@1->main_intro::@3]
    // main_intro::@3
    // util_wait_space()
    // [700] call util_wait_space
    // [875] phi from main_intro::@3 to util_wait_space [phi:main_intro::@3->util_wait_space]
    jsr util_wait_space
    // [701] phi from main_intro::@3 to main_intro::@7 [phi:main_intro::@3->main_intro::@7]
    // main_intro::@7
    // display_progress_clear()
    // [702] call display_progress_clear
    // [571] phi from main_intro::@7 to display_progress_clear [phi:main_intro::@7->display_progress_clear]
    jsr display_progress_clear
    // main_intro::@return
    // }
    // [703] return 
    rts
    // main_intro::@2
  __b2:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [704] display_info_led::y#3 = PROGRESS_Y+3 + main_intro::intro_status#2 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y+3
    clc
    adc.z intro_status
    sta display_info_led.y
    // [705] display_info_led::tc#3 = status_color[main_intro::intro_status#2] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z intro_status
    lda status_color,y
    sta display_info_led.tc
    // [706] call display_info_led
    // [1443] phi from main_intro::@2 to display_info_led [phi:main_intro::@2->display_info_led]
    // [1443] phi display_info_led::y#4 = display_info_led::y#3 [phi:main_intro::@2->display_info_led#0] -- register_copy 
    // [1443] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main_intro::@2->display_info_led#1] -- vbum1=vbuc1 
    lda #PROGRESS_X+3
    sta display_info_led.x
    // [1443] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main_intro::@2->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main_intro::@6
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [707] main_intro::intro_status#1 = ++ main_intro::intro_status#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_status
    // [697] phi from main_intro::@6 to main_intro::@1 [phi:main_intro::@6->main_intro::@1]
    // [697] phi main_intro::intro_status#2 = main_intro::intro_status#1 [phi:main_intro::@6->main_intro::@1#0] -- register_copy 
    jmp __b1
}
.segment CodeVera
  // main_vera_detect
main_vera_detect: {
    // vera_detect()
    // [709] call vera_detect
    // [1454] phi from main_vera_detect to vera_detect [phi:main_vera_detect->vera_detect]
    jsr vera_detect
    // [710] phi from main_vera_detect to main_vera_detect::@1 [phi:main_vera_detect->main_vera_detect::@1]
    // main_vera_detect::@1
    // display_chip_vera()
    // [711] call display_chip_vera
    // [591] phi from main_vera_detect::@1 to display_chip_vera [phi:main_vera_detect::@1->display_chip_vera]
    jsr display_chip_vera
    // main_vera_detect::@2
    // [712] spi_manufacturer#408 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [713] spi_memory_type#409 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [714] spi_memory_capacity#410 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, NULL)
    // [715] call display_info_vera
    // [651] phi from main_vera_detect::@2 to display_info_vera [phi:main_vera_detect::@2->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = 0 [phi:main_vera_detect::@2->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#410 [phi:main_vera_detect::@2->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#409 [phi:main_vera_detect::@2->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#408 [phi:main_vera_detect::@2->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_detect::@2->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_detect::@return
    // }
    // [716] return 
    rts
}
  // main_vera_check
main_vera_check: {
    .label vera_bytes_read = $ab
    // display_action_progress("Checking VERA.BIN ...")
    // [718] call display_action_progress
    // [557] phi from main_vera_check to display_action_progress [phi:main_vera_check->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main_vera_check::info_text [phi:main_vera_check->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [719] phi from main_vera_check to main_vera_check::@4 [phi:main_vera_check->main_vera_check::@4]
    // main_vera_check::@4
    // unsigned long vera_bytes_read = vera_read(STATUS_CHECKING)
    // [720] call vera_read
  // Read the VERA.BIN file.
    // [1457] phi from main_vera_check::@4 to vera_read [phi:main_vera_check::@4->vera_read]
    // [1457] phi __errno#118 = 0 [phi:main_vera_check::@4->vera_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [1457] phi __stdio_filecount#105 = 0 [phi:main_vera_check::@4->vera_read#1] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [1457] phi vera_read::info_status#12 = STATUS_CHECKING [phi:main_vera_check::@4->vera_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta vera_read.info_status
    jsr vera_read
    // unsigned long vera_bytes_read = vera_read(STATUS_CHECKING)
    // [721] vera_read::return#2 = vera_read::return#0
    // main_vera_check::@5
    // [722] main_vera_check::vera_bytes_read#0 = vera_read::return#2 -- vduz1=vdum2 
    lda vera_read.return
    sta.z vera_bytes_read
    lda vera_read.return+1
    sta.z vera_bytes_read+1
    lda vera_read.return+2
    sta.z vera_bytes_read+2
    lda vera_read.return+3
    sta.z vera_bytes_read+3
    // wait_moment(10)
    // [723] call wait_moment
    // [792] phi from main_vera_check::@5 to wait_moment [phi:main_vera_check::@5->wait_moment]
    // [792] phi wait_moment::w#10 = $a [phi:main_vera_check::@5->wait_moment#0] -- vbum1=vbuc1 
    lda #$a
    sta wait_moment.w
    jsr wait_moment
    // main_vera_check::@6
    // if (!vera_bytes_read)
    // [724] if(0==main_vera_check::vera_bytes_read#0) goto main_vera_check::@1 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    beq __b1
    // main_vera_check::@3
    // vera_file_size = vera_bytes_read
    // [725] vera_file_size#0 = main_vera_check::vera_bytes_read#0 -- vdum1=vduz2 
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
    // [726] call snprintf_init
    jsr snprintf_init
    // [727] phi from main_vera_check::@3 to main_vera_check::@7 [phi:main_vera_check::@3->main_vera_check::@7]
    // main_vera_check::@7
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [728] call printf_str
    // [783] phi from main_vera_check::@7 to printf_str [phi:main_vera_check::@7->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main_vera_check::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main_vera_check::s [phi:main_vera_check::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [729] phi from main_vera_check::@7 to main_vera_check::@8 [phi:main_vera_check::@7->main_vera_check::@8]
    // main_vera_check::@8
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [730] call printf_string
    // [1307] phi from main_vera_check::@8 to printf_string [phi:main_vera_check::@8->printf_string]
    // [1307] phi printf_string::putc#17 = &snputc [phi:main_vera_check::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = str [phi:main_vera_check::@8->printf_string#1] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [1307] phi printf_string::format_justify_left#17 = 0 [phi:main_vera_check::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 0 [phi:main_vera_check::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main_vera_check::@9
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [731] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [732] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [734] spi_manufacturer#407 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [735] spi_memory_type#408 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [736] spi_memory_capacity#409 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASH, info_text)
    // [737] call display_info_vera
    // [651] phi from main_vera_check::@9 to display_info_vera [phi:main_vera_check::@9->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = info_text [phi:main_vera_check::@9->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#409 [phi:main_vera_check::@9->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#408 [phi:main_vera_check::@9->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#407 [phi:main_vera_check::@9->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_FLASH [phi:main_vera_check::@9->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [738] phi from main_vera_check::@9 to main_vera_check::@2 [phi:main_vera_check::@9->main_vera_check::@2]
    // [738] phi vera_file_size#1 = vera_file_size#0 [phi:main_vera_check::@9->main_vera_check::@2#0] -- register_copy 
    // main_vera_check::@2
    // main_vera_check::@return
    // }
    // [739] return 
    rts
    // main_vera_check::@1
  __b1:
    // [740] spi_manufacturer#406 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [741] spi_memory_type#407 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [742] spi_memory_capacity#408 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "No VERA.BIN")
    // [743] call display_info_vera
  // VF1 | no VERA.BIN  | Ask the user to place the VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // VF2 | VERA.BIN size 0 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // TODO: VF4 | ROM.BIN size over 0x20000 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
    // [651] phi from main_vera_check::@1 to display_info_vera [phi:main_vera_check::@1->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = main_vera_check::info_text1 [phi:main_vera_check::@1->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#408 [phi:main_vera_check::@1->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#407 [phi:main_vera_check::@1->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#406 [phi:main_vera_check::@1->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main_vera_check::@1->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [738] phi from main_vera_check::@1 to main_vera_check::@2 [phi:main_vera_check::@1->main_vera_check::@2]
    // [738] phi vera_file_size#1 = 0 [phi:main_vera_check::@1->main_vera_check::@2#0] -- vdum1=vduc1 
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
    // [745] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [745] phi smc_supported_rom::i#2 = $1f [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbum1=vbuc1 
    lda #$1f
    sta i
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=31; i>3; i--)
    // [746] if(smc_supported_rom::i#2>=3+1) goto smc_supported_rom::@2 -- vbum1_ge_vbuc1_then_la1 
    lda i
    cmp #3+1
    bcs __b2
    // [748] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [748] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_file_header[i] == rom_release)
    // [747] if(smc_file_header[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbum1_neq_vbum2_then_la1 
    lda rom_release
    ldy i
    cmp smc_file_header,y
    bne __b3
    // [748] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [748] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // smc_supported_rom::@return
    // }
    // [749] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=31; i>3; i--)
    // [750] smc_supported_rom::i#1 = -- smc_supported_rom::i#2 -- vbum1=_dec_vbum1 
    dec i
    // [745] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [745] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    return: .byte 0
    rom_release: .byte 0
}
.segment Code
  // check_status_roms
/**
 * @brief Check the status of any of the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
// __mem() char check_status_roms(__mem() char status)
check_status_roms: {
    .label check_status_rom1_check_status_roms__0 = $4d
    // [752] phi from check_status_roms to check_status_roms::@1 [phi:check_status_roms->check_status_roms::@1]
    // [752] phi check_status_roms::rom_chip#2 = 0 [phi:check_status_roms->check_status_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [753] if(check_status_roms::rom_chip#2<8) goto check_status_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [754] phi from check_status_roms::@1 to check_status_roms::@return [phi:check_status_roms::@1->check_status_roms::@return]
    // [754] phi check_status_roms::return#2 = 0 [phi:check_status_roms::@1->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_roms::@return
    // }
    // [755] return 
    rts
    // check_status_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [756] check_status_roms::check_status_rom1_$0 = status_rom[check_status_roms::rom_chip#2] == check_status_roms::status#6 -- vboz1=pbuc1_derefidx_vbum2_eq_vbum3 
    lda status
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [757] check_status_roms::check_status_rom1_return#0 = (char)check_status_roms::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [758] if(0==check_status_roms::check_status_rom1_return#0) goto check_status_roms::@2 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [754] phi from check_status_roms::@3 to check_status_roms::@return [phi:check_status_roms::@3->check_status_roms::@return]
    // [754] phi check_status_roms::return#2 = 1 [phi:check_status_roms::@3->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_roms::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [759] check_status_roms::rom_chip#1 = ++ check_status_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [752] phi from check_status_roms::@2 to check_status_roms::@1 [phi:check_status_roms::@2->check_status_roms::@1]
    // [752] phi check_status_roms::rom_chip#2 = check_status_roms::rom_chip#1 [phi:check_status_roms::@2->check_status_roms::@1#0] -- register_copy 
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
    .label clrscr__0 = $4d
    .label clrscr__1 = $4e
    .label clrscr__2 = $3b
    // unsigned int line_text = __conio.mapbase_offset
    // [760] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [761] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [762] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [763] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [764] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [765] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [765] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [765] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [766] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [767] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [768] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [769] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [770] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [771] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [771] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [772] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [773] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [774] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [775] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [776] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [777] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [778] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [779] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [780] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [781] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [782] return 
    rts
  .segment Data
    .label line_text = ch
    l: .byte 0
    ch: .word 0
    c: .byte 0
}
.segment Code
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($49) void (*putc)(char), __zp($42) const char *s)
printf_str: {
    .label s = $42
    .label putc = $49
    // [784] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [784] phi printf_str::s#52 = printf_str::s#53 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [785] printf_str::c#1 = *printf_str::s#52 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [786] printf_str::s#0 = ++ printf_str::s#52 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [787] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [788] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [789] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [790] callexecute *printf_str::putc#53  -- call__deref_pprz1 
    jsr icall5
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall5:
    jmp (putc)
  .segment Data
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
    // [793] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [793] phi wait_moment::j#2 = 0 [phi:wait_moment->wait_moment::@1#0] -- vbum1=vbuc1 
    lda #0
    sta j
    // wait_moment::@1
  __b1:
    // for(unsigned char j=0; j<w; j++)
    // [794] if(wait_moment::j#2<wait_moment::w#10) goto wait_moment::@2 -- vbum1_lt_vbum2_then_la1 
    lda j
    cmp w
    bcc __b4
    // wait_moment::@return
    // }
    // [795] return 
    rts
    // [796] phi from wait_moment::@1 to wait_moment::@2 [phi:wait_moment::@1->wait_moment::@2]
  __b4:
    // [796] phi wait_moment::i#2 = $ffff [phi:wait_moment::@1->wait_moment::@2#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta i
    lda #>$ffff
    sta i+1
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [797] if(wait_moment::i#2>0) goto wait_moment::@3 -- vwum1_gt_0_then_la1 
    lda i+1
    bne __b3
    lda i
    bne __b3
  !:
    // wait_moment::@4
    // for(unsigned char j=0; j<w; j++)
    // [798] wait_moment::j#1 = ++ wait_moment::j#2 -- vbum1=_inc_vbum1 
    inc j
    // [793] phi from wait_moment::@4 to wait_moment::@1 [phi:wait_moment::@4->wait_moment::@1]
    // [793] phi wait_moment::j#2 = wait_moment::j#1 [phi:wait_moment::@4->wait_moment::@1#0] -- register_copy 
    jmp __b1
    // wait_moment::@3
  __b3:
    // for(unsigned int i=65535; i>0; i--)
    // [799] wait_moment::i#1 = -- wait_moment::i#2 -- vwum1=_dec_vwum1 
    lda i
    bne !+
    dec i+1
  !:
    dec i
    // [796] phi from wait_moment::@3 to wait_moment::@2 [phi:wait_moment::@3->wait_moment::@2]
    // [796] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@3->wait_moment::@2#0] -- register_copy 
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
    // [801] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [802] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [804] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
    // system_reset::@1
  __b1:
    jmp __b1
}
  // check_status_roms_less
/**
 * @brief Check the status of all the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if all chips are equal to the status.
 */
// __mem() char check_status_roms_less(char status)
check_status_roms_less: {
    .label check_status_roms_less__1 = $4e
    // [806] phi from check_status_roms_less to check_status_roms_less::@1 [phi:check_status_roms_less->check_status_roms_less::@1]
    // [806] phi check_status_roms_less::rom_chip#2 = 0 [phi:check_status_roms_less->check_status_roms_less::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms_less::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [807] if(check_status_roms_less::rom_chip#2<8) goto check_status_roms_less::@2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b2
    // [810] phi from check_status_roms_less::@1 to check_status_roms_less::@return [phi:check_status_roms_less::@1->check_status_roms_less::@return]
    // [810] phi check_status_roms_less::return#2 = 1 [phi:check_status_roms_less::@1->check_status_roms_less::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_roms_less::@2
  __b2:
    // status_rom[rom_chip] > status
    // [808] check_status_roms_less::$1 = status_rom[check_status_roms_less::rom_chip#2] > STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_gt_vbuc2 
    ldy rom_chip
    lda status_rom,y
    cmp #STATUS_SKIP
    lda #0
    rol
    sta.z check_status_roms_less__1
    // if((unsigned char)(status_rom[rom_chip] > status))
    // [809] if(0==(char)check_status_roms_less::$1) goto check_status_roms_less::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // [810] phi from check_status_roms_less::@2 to check_status_roms_less::@return [phi:check_status_roms_less::@2->check_status_roms_less::@return]
    // [810] phi check_status_roms_less::return#2 = 0 [phi:check_status_roms_less::@2->check_status_roms_less::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_roms_less::@return
    // }
    // [811] return 
    rts
    // check_status_roms_less::@3
  __b3:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [812] check_status_roms_less::rom_chip#1 = ++ check_status_roms_less::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [806] phi from check_status_roms_less::@3 to check_status_roms_less::@1 [phi:check_status_roms_less::@3->check_status_roms_less::@1]
    // [806] phi check_status_roms_less::rom_chip#2 = check_status_roms_less::rom_chip#1 [phi:check_status_roms_less::@3->check_status_roms_less::@1#0] -- register_copy 
    jmp __b1
  .segment Data
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
// void display_progress_text(__zp($3e) char **text, __mem() char lines)
display_progress_text: {
    .label display_progress_text__3 = $3b
    .label text = $3e
    // display_progress_clear()
    // [814] call display_progress_clear
    // [571] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [815] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [815] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [816] if(display_progress_text::l#2<display_progress_text::lines#10) goto display_progress_text::@2 -- vbum1_lt_vbum2_then_la1 
    lda l
    cmp lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [817] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [818] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbum2_rol_1 
    lda l
    asl
    sta.z display_progress_text__3
    // [819] display_progress_line::line#0 = display_progress_text::l#2 -- vbum1=vbum2 
    lda l
    sta display_progress_line.line
    // [820] display_progress_line::text#0 = display_progress_text::text#11[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [821] call display_progress_line
    // [823] phi from display_progress_text::@2 to display_progress_line [phi:display_progress_text::@2->display_progress_line]
    // [823] phi display_progress_line::text#3 = display_progress_line::text#0 [phi:display_progress_text::@2->display_progress_line#0] -- register_copy 
    // [823] phi display_progress_line::line#3 = display_progress_line::line#0 [phi:display_progress_text::@2->display_progress_line#1] -- register_copy 
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [822] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [815] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [815] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
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
// void display_progress_line(__mem() char line, __zp($49) char *text)
display_progress_line: {
    .label text = $49
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [824] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#3 -- vbum1=vbuc1_plus_vbum1 
    lda #PROGRESS_Y
    clc
    adc cputsxy.y
    sta cputsxy.y
    // [825] cputsxy::s#0 = display_progress_line::text#3
    // [826] call cputsxy
    // [550] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [550] phi cputsxy::s#3 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [550] phi cputsxy::y#3 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [550] phi cputsxy::x#3 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [827] return 
    rts
  .segment Data
    .label line = cputsxy.y
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [828] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [829] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [830] __snprintf_buffer = info_text -- pbuz1=pbuc1 
    lda #<info_text
    sta.z __snprintf_buffer
    lda #>info_text
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [831] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($49) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $49
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [833] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [834] uctoa::value#1 = printf_uchar::uvalue#10
    // [835] uctoa::radix#0 = printf_uchar::format_radix#10
    // [836] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [837] printf_number_buffer::putc#2 = printf_uchar::putc#10
    // [838] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [839] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10
    // [840] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [841] call printf_number_buffer
  // Print using format
    // [1538] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1538] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1538] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1538] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1538] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [842] return 
    rts
  .segment Data
    uvalue: .byte 0
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
// void display_action_text(__zp($59) char *info_text)
display_action_text: {
    .label info_text = $59
    // unsigned char x = wherex()
    // [844] call wherex
    jsr wherex
    // [845] wherex::return#3 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_1
    // display_action_text::@1
    // [846] display_action_text::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [847] call wherey
    jsr wherey
    // [848] wherey::return#3 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_1
    // display_action_text::@2
    // [849] display_action_text::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [850] call gotoxy
    // [455] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [455] phi gotoxy::y#26 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [851] printf_string::str#2 = display_action_text::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [852] call printf_string
    // [1307] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [853] gotoxy::x#16 = display_action_text::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [854] gotoxy::y#16 = display_action_text::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [855] call gotoxy
    // [455] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#16 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#16 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [856] return 
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
    // [858] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [859] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@1
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [860] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [861] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [862] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [863] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [865] return 
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
    // [867] phi from check_status_card_roms to check_status_card_roms::@1 [phi:check_status_card_roms->check_status_card_roms::@1]
    // [867] phi check_status_card_roms::rom_chip#2 = 1 [phi:check_status_card_roms->check_status_card_roms::@1#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip
    // check_status_card_roms::@1
  __b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [868] if(check_status_card_roms::rom_chip#2<8) goto check_status_card_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [869] phi from check_status_card_roms::@1 to check_status_card_roms::@return [phi:check_status_card_roms::@1->check_status_card_roms::@return]
    // [869] phi check_status_card_roms::return#2 = 0 [phi:check_status_card_roms::@1->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_card_roms::@return
    // }
    // [870] return 
    rts
    // check_status_card_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [871] check_status_card_roms::check_status_rom1_$0 = status_rom[check_status_card_roms::rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_card_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [872] check_status_card_roms::check_status_rom1_return#0 = (char)check_status_card_roms::check_status_rom1_$0 -- vbum1=vbuz2 
    sta check_status_rom1_return
    // check_status_card_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [873] if(0==check_status_card_roms::check_status_rom1_return#0) goto check_status_card_roms::@2 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [869] phi from check_status_card_roms::@3 to check_status_card_roms::@return [phi:check_status_card_roms::@3->check_status_card_roms::@return]
    // [869] phi check_status_card_roms::return#2 = 1 [phi:check_status_card_roms::@3->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_card_roms::@2
  __b2:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [874] check_status_card_roms::rom_chip#1 = ++ check_status_card_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [867] phi from check_status_card_roms::@2 to check_status_card_roms::@1 [phi:check_status_card_roms::@2->check_status_card_roms::@1]
    // [867] phi check_status_card_roms::rom_chip#2 = check_status_card_roms::rom_chip#1 [phi:check_status_card_roms::@2->check_status_card_roms::@1#0] -- register_copy 
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
    // [876] call util_wait_key
    // [1032] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1032] phi util_wait_key::filter#13 = s [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z util_wait_key.filter
    lda #>s
    sta.z util_wait_key.filter+1
    // [1032] phi util_wait_key::info_text#3 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [877] return 
    rts
  .segment Data
    info_text: .text "Press [SPACE] to continue ..."
    .byte 0
}
.segment CodeVera
  // main_vera_flash
main_vera_flash: {
    .label vera_bytes_read = $ab
    .label vera_differences = $b8
    .label spi_ensure_detect = $7d
    .label vera_flashed = $bc
    .label vera_differences1 = $b4
    .label spi_ensure_detect_1 = $7e
    // display_progress_clear()
    // [879] call display_progress_clear
    // [571] phi from main_vera_flash to display_progress_clear [phi:main_vera_flash->display_progress_clear]
    jsr display_progress_clear
    // [880] phi from main_vera_flash to main_vera_flash::@19 [phi:main_vera_flash->main_vera_flash::@19]
    // main_vera_flash::@19
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [881] call snprintf_init
    jsr snprintf_init
    // [882] phi from main_vera_flash::@19 to main_vera_flash::@20 [phi:main_vera_flash::@19->main_vera_flash::@20]
    // main_vera_flash::@20
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [883] call printf_str
    // [783] phi from main_vera_flash::@20 to printf_str [phi:main_vera_flash::@20->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main_vera_flash::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main_vera_flash::s [phi:main_vera_flash::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@21
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [884] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [885] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [887] call display_action_progress
    // [557] phi from main_vera_flash::@21 to display_action_progress [phi:main_vera_flash::@21->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = info_text [phi:main_vera_flash::@21->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [888] phi from main_vera_flash::@21 to main_vera_flash::@22 [phi:main_vera_flash::@21->main_vera_flash::@22]
    // main_vera_flash::@22
    // unsigned long vera_bytes_read = vera_read(STATUS_READING)
    // [889] call vera_read
    // [1457] phi from main_vera_flash::@22 to vera_read [phi:main_vera_flash::@22->vera_read]
    // [1457] phi __errno#118 = __errno#18 [phi:main_vera_flash::@22->vera_read#0] -- register_copy 
    // [1457] phi __stdio_filecount#105 = __stdio_filecount#26 [phi:main_vera_flash::@22->vera_read#1] -- register_copy 
    // [1457] phi vera_read::info_status#12 = STATUS_READING [phi:main_vera_flash::@22->vera_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta vera_read.info_status
    jsr vera_read
    // unsigned long vera_bytes_read = vera_read(STATUS_READING)
    // [890] vera_read::return#3 = vera_read::return#0
    // main_vera_flash::@23
    // [891] main_vera_flash::vera_bytes_read#0 = vera_read::return#3 -- vduz1=vdum2 
    lda vera_read.return
    sta.z vera_bytes_read
    lda vera_read.return+1
    sta.z vera_bytes_read+1
    lda vera_read.return+2
    sta.z vera_bytes_read+2
    lda vera_read.return+3
    sta.z vera_bytes_read+3
    // if(vera_bytes_read)
    // [892] if(0==main_vera_flash::vera_bytes_read#0) goto main_vera_flash::@1 -- 0_eq_vduz1_then_la1 
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    bne !__b1+
    jmp __b1
  !__b1:
    // [893] phi from main_vera_flash::@23 to main_vera_flash::@2 [phi:main_vera_flash::@23->main_vera_flash::@2]
    // main_vera_flash::@2
    // display_action_progress("VERA SPI activation ...")
    // [894] call display_action_progress
  // Now we loop until jumper JP1 has been placed!
    // [557] phi from main_vera_flash::@2 to display_action_progress [phi:main_vera_flash::@2->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main_vera_flash::info_text [phi:main_vera_flash::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [895] phi from main_vera_flash::@2 to main_vera_flash::@24 [phi:main_vera_flash::@2->main_vera_flash::@24]
    // main_vera_flash::@24
    // display_action_text("Please close the jumper JP1 on the VERA board!")
    // [896] call display_action_text
    // [843] phi from main_vera_flash::@24 to display_action_text [phi:main_vera_flash::@24->display_action_text]
    // [843] phi display_action_text::info_text#17 = main_vera_flash::info_text1 [phi:main_vera_flash::@24->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_text.info_text
    lda #>info_text1
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [897] phi from main_vera_flash::@24 to main_vera_flash::@25 [phi:main_vera_flash::@24->main_vera_flash::@25]
    // main_vera_flash::@25
    // vera_detect()
    // [898] call vera_detect
    // [1454] phi from main_vera_flash::@25 to vera_detect [phi:main_vera_flash::@25->vera_detect]
    jsr vera_detect
    // [899] phi from main_vera_flash::@25 main_vera_flash::@7 to main_vera_flash::@3 [phi:main_vera_flash::@25/main_vera_flash::@7->main_vera_flash::@3]
  __b2:
    // [899] phi main_vera_flash::spi_ensure_detect#11 = 0 [phi:main_vera_flash::@25/main_vera_flash::@7->main_vera_flash::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z spi_ensure_detect
    // main_vera_flash::@3
  __b3:
    // while(spi_ensure_detect < 16)
    // [900] if(main_vera_flash::spi_ensure_detect#11<$10) goto main_vera_flash::@4 -- vbuz1_lt_vbuc1_then_la1 
    lda.z spi_ensure_detect
    cmp #$10
    bcs !__b4+
    jmp __b4
  !__b4:
    // [901] phi from main_vera_flash::@3 to main_vera_flash::@5 [phi:main_vera_flash::@3->main_vera_flash::@5]
    // main_vera_flash::@5
    // display_action_text("The jumper JP1 has been closed on the VERA!")
    // [902] call display_action_text
    // [843] phi from main_vera_flash::@5 to display_action_text [phi:main_vera_flash::@5->display_action_text]
    // [843] phi display_action_text::info_text#17 = main_vera_flash::info_text2 [phi:main_vera_flash::@5->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [903] phi from main_vera_flash::@5 to main_vera_flash::@28 [phi:main_vera_flash::@5->main_vera_flash::@28]
    // main_vera_flash::@28
    // display_action_progress("Comparing VERA ... (.) data, (=) same, (*) different.")
    // [904] call display_action_progress
  // Now we compare the RAM with the actual VERA contents.
    // [557] phi from main_vera_flash::@28 to display_action_progress [phi:main_vera_flash::@28->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main_vera_flash::info_text3 [phi:main_vera_flash::@28->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main_vera_flash::@29
    // [905] spi_manufacturer#413 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [906] spi_memory_type#414 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [907] spi_memory_capacity#415 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_COMPARING, NULL)
    // [908] call display_info_vera
    // [651] phi from main_vera_flash::@29 to display_info_vera [phi:main_vera_flash::@29->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@29->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#415 [phi:main_vera_flash::@29->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#414 [phi:main_vera_flash::@29->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#413 [phi:main_vera_flash::@29->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_COMPARING [phi:main_vera_flash::@29->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [909] phi from main_vera_flash::@29 to main_vera_flash::@30 [phi:main_vera_flash::@29->main_vera_flash::@30]
    // main_vera_flash::@30
    // unsigned long vera_differences = vera_verify()
    // [910] call vera_verify
  // Verify VERA ...
    // [1569] phi from main_vera_flash::@30 to vera_verify [phi:main_vera_flash::@30->vera_verify]
    jsr vera_verify
    // unsigned long vera_differences = vera_verify()
    // [911] vera_verify::return#2 = vera_verify::vera_different_bytes#11
    // main_vera_flash::@31
    // [912] main_vera_flash::vera_differences#0 = vera_verify::return#2 -- vduz1=vdum2 
    lda vera_verify.return
    sta.z vera_differences
    lda vera_verify.return+1
    sta.z vera_differences+1
    lda vera_verify.return+2
    sta.z vera_differences+2
    lda vera_verify.return+3
    sta.z vera_differences+3
    // if (!vera_differences)
    // [913] if(0==main_vera_flash::vera_differences#0) goto main_vera_flash::@9 -- 0_eq_vduz1_then_la1 
    lda.z vera_differences
    ora.z vera_differences+1
    ora.z vera_differences+2
    ora.z vera_differences+3
    bne !__b9+
    jmp __b9
  !__b9:
    // [914] phi from main_vera_flash::@31 to main_vera_flash::@8 [phi:main_vera_flash::@31->main_vera_flash::@8]
    // main_vera_flash::@8
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [915] call snprintf_init
    jsr snprintf_init
    // main_vera_flash::@33
    // [916] printf_ulong::uvalue#7 = main_vera_flash::vera_differences#0 -- vdum1=vduz2 
    lda.z vera_differences
    sta printf_ulong.uvalue
    lda.z vera_differences+1
    sta printf_ulong.uvalue+1
    lda.z vera_differences+2
    sta printf_ulong.uvalue+2
    lda.z vera_differences+3
    sta printf_ulong.uvalue+3
    // [917] call printf_ulong
    // [1632] phi from main_vera_flash::@33 to printf_ulong [phi:main_vera_flash::@33->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 1 [phi:main_vera_flash::@33->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 5 [phi:main_vera_flash::@33->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:main_vera_flash::@33->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#7 [phi:main_vera_flash::@33->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [918] phi from main_vera_flash::@33 to main_vera_flash::@34 [phi:main_vera_flash::@33->main_vera_flash::@34]
    // main_vera_flash::@34
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [919] call printf_str
    // [783] phi from main_vera_flash::@34 to printf_str [phi:main_vera_flash::@34->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main_vera_flash::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main_vera_flash::s1 [phi:main_vera_flash::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@35
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [920] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [921] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [923] spi_manufacturer#414 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [924] spi_memory_type#415 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [925] spi_memory_capacity#416 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASH, info_text)
    // [926] call display_info_vera
    // [651] phi from main_vera_flash::@35 to display_info_vera [phi:main_vera_flash::@35->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@35->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#416 [phi:main_vera_flash::@35->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#415 [phi:main_vera_flash::@35->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#414 [phi:main_vera_flash::@35->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_FLASH [phi:main_vera_flash::@35->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [927] phi from main_vera_flash::@35 to main_vera_flash::@36 [phi:main_vera_flash::@35->main_vera_flash::@36]
    // main_vera_flash::@36
    // unsigned char vera_erase_error = vera_erase()
    // [928] call vera_erase
    jsr vera_erase
    // [929] phi from main_vera_flash::@36 to main_vera_flash::@10 [phi:main_vera_flash::@36->main_vera_flash::@10]
    // main_vera_flash::@10
    // unsigned long vera_flashed = vera_flash()
    // [930] call vera_flash
    // [1648] phi from main_vera_flash::@10 to vera_flash [phi:main_vera_flash::@10->vera_flash]
    jsr vera_flash
    // unsigned long vera_flashed = vera_flash()
    // [931] vera_flash::return#3 = vera_flash::return#2
    // main_vera_flash::@37
    // [932] main_vera_flash::vera_flashed#0 = vera_flash::return#3 -- vduz1=vdum2 
    lda vera_flash.return
    sta.z vera_flashed
    lda vera_flash.return+1
    sta.z vera_flashed+1
    lda vera_flash.return+2
    sta.z vera_flashed+2
    lda vera_flash.return+3
    sta.z vera_flashed+3
    // if(vera_flashed)
    // [933] if(0!=main_vera_flash::vera_flashed#0) goto main_vera_flash::@11 -- 0_neq_vduz1_then_la1 
    lda.z vera_flashed
    ora.z vera_flashed+1
    ora.z vera_flashed+2
    ora.z vera_flashed+3
    bne __b11
    // main_vera_flash::@12
    // [934] spi_manufacturer#410 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [935] spi_memory_type#411 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [936] spi_memory_capacity#412 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_ERROR, info_text)
    // [937] call display_info_vera
  // VFL2 | Flash VERA resulting in errors
    // [651] phi from main_vera_flash::@12 to display_info_vera [phi:main_vera_flash::@12->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@12->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#412 [phi:main_vera_flash::@12->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#411 [phi:main_vera_flash::@12->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#410 [phi:main_vera_flash::@12->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_ERROR [phi:main_vera_flash::@12->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // [938] phi from main_vera_flash::@12 to main_vera_flash::@46 [phi:main_vera_flash::@12->main_vera_flash::@46]
    // main_vera_flash::@46
    // display_action_progress("There was an error updating your VERA flash memory!")
    // [939] call display_action_progress
    // [557] phi from main_vera_flash::@46 to display_action_progress [phi:main_vera_flash::@46->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main_vera_flash::info_text10 [phi:main_vera_flash::@46->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [940] phi from main_vera_flash::@46 to main_vera_flash::@47 [phi:main_vera_flash::@46->main_vera_flash::@47]
    // main_vera_flash::@47
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [941] call display_action_text
    // [843] phi from main_vera_flash::@47 to display_action_text [phi:main_vera_flash::@47->display_action_text]
    // [843] phi display_action_text::info_text#17 = main_vera_flash::info_text8 [phi:main_vera_flash::@47->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_text.info_text
    lda #>info_text8
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main_vera_flash::@48
    // [942] spi_manufacturer#418 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [943] spi_memory_type#419 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [944] spi_memory_capacity#420 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_ERROR, "FLASH ERROR!")
    // [945] call display_info_vera
    // [651] phi from main_vera_flash::@48 to display_info_vera [phi:main_vera_flash::@48->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = main_vera_flash::info_text12 [phi:main_vera_flash::@48->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_vera.info_text
    lda #>info_text12
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#420 [phi:main_vera_flash::@48->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#419 [phi:main_vera_flash::@48->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#418 [phi:main_vera_flash::@48->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_ERROR [phi:main_vera_flash::@48->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // [946] phi from main_vera_flash::@48 to main_vera_flash::@49 [phi:main_vera_flash::@48->main_vera_flash::@49]
    // main_vera_flash::@49
    // display_info_smc(STATUS_ERROR, NULL)
    // [947] call display_info_smc
    // [615] phi from main_vera_flash::@49 to display_info_smc [phi:main_vera_flash::@49->display_info_smc]
    // [615] phi display_info_smc::info_text#10 = 0 [phi:main_vera_flash::@49->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [615] phi display_info_smc::info_status#10 = STATUS_ERROR [phi:main_vera_flash::@49->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    // [948] phi from main_vera_flash::@49 to main_vera_flash::@50 [phi:main_vera_flash::@49->main_vera_flash::@50]
    // main_vera_flash::@50
    // display_info_roms(STATUS_ERROR, NULL)
    // [949] call display_info_roms
    // [1698] phi from main_vera_flash::@50 to display_info_roms [phi:main_vera_flash::@50->display_info_roms]
    jsr display_info_roms
    // [950] phi from main_vera_flash::@50 to main_vera_flash::@51 [phi:main_vera_flash::@50->main_vera_flash::@51]
    // main_vera_flash::@51
    // wait_moment(32)
    // [951] call wait_moment
    // [792] phi from main_vera_flash::@51 to wait_moment [phi:main_vera_flash::@51->wait_moment]
    // [792] phi wait_moment::w#10 = $20 [phi:main_vera_flash::@51->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [952] phi from main_vera_flash::@51 to main_vera_flash::@52 [phi:main_vera_flash::@51->main_vera_flash::@52]
    // main_vera_flash::@52
    // spi_deselect()
    // [953] call spi_deselect
    jsr spi_deselect
    // main_vera_flash::@return
    // }
    // [954] return 
    rts
    // [955] phi from main_vera_flash::@37 to main_vera_flash::@11 [phi:main_vera_flash::@37->main_vera_flash::@11]
    // main_vera_flash::@11
  __b11:
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [956] call snprintf_init
    jsr snprintf_init
    // main_vera_flash::@38
    // [957] printf_ulong::uvalue#8 = main_vera_flash::vera_flashed#0 -- vdum1=vduz2 
    lda.z vera_flashed
    sta printf_ulong.uvalue
    lda.z vera_flashed+1
    sta printf_ulong.uvalue+1
    lda.z vera_flashed+2
    sta printf_ulong.uvalue+2
    lda.z vera_flashed+3
    sta printf_ulong.uvalue+3
    // [958] call printf_ulong
    // [1632] phi from main_vera_flash::@38 to printf_ulong [phi:main_vera_flash::@38->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 0 [phi:main_vera_flash::@38->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 0 [phi:main_vera_flash::@38->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:main_vera_flash::@38->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#8 [phi:main_vera_flash::@38->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [959] phi from main_vera_flash::@38 to main_vera_flash::@39 [phi:main_vera_flash::@38->main_vera_flash::@39]
    // main_vera_flash::@39
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [960] call printf_str
    // [783] phi from main_vera_flash::@39 to printf_str [phi:main_vera_flash::@39->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main_vera_flash::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main_vera_flash::s2 [phi:main_vera_flash::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@40
    // sprintf(info_text, "%x bytes flashed!", vera_flashed)
    // [961] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [962] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [964] spi_manufacturer#415 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [965] spi_memory_type#416 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [966] spi_memory_capacity#417 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHED, info_text)
    // [967] call display_info_vera
    // [651] phi from main_vera_flash::@40 to display_info_vera [phi:main_vera_flash::@40->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@40->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#417 [phi:main_vera_flash::@40->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#416 [phi:main_vera_flash::@40->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#415 [phi:main_vera_flash::@40->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_FLASHED [phi:main_vera_flash::@40->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [968] phi from main_vera_flash::@40 to main_vera_flash::@41 [phi:main_vera_flash::@40->main_vera_flash::@41]
    // main_vera_flash::@41
    // unsigned long vera_differences = vera_verify()
    // [969] call vera_verify
    // [1569] phi from main_vera_flash::@41 to vera_verify [phi:main_vera_flash::@41->vera_verify]
    jsr vera_verify
    // unsigned long vera_differences = vera_verify()
    // [970] vera_verify::return#3 = vera_verify::vera_different_bytes#11
    // main_vera_flash::@42
    // [971] main_vera_flash::vera_differences1#0 = vera_verify::return#3 -- vduz1=vdum2 
    lda vera_verify.return
    sta.z vera_differences1
    lda vera_verify.return+1
    sta.z vera_differences1+1
    lda vera_verify.return+2
    sta.z vera_differences1+2
    lda vera_verify.return+3
    sta.z vera_differences1+3
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [972] call snprintf_init
    jsr snprintf_init
    // main_vera_flash::@43
    // [973] printf_ulong::uvalue#9 = main_vera_flash::vera_differences1#0 -- vdum1=vduz2 
    lda.z vera_differences1
    sta printf_ulong.uvalue
    lda.z vera_differences1+1
    sta printf_ulong.uvalue+1
    lda.z vera_differences1+2
    sta printf_ulong.uvalue+2
    lda.z vera_differences1+3
    sta printf_ulong.uvalue+3
    // [974] call printf_ulong
    // [1632] phi from main_vera_flash::@43 to printf_ulong [phi:main_vera_flash::@43->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 1 [phi:main_vera_flash::@43->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 5 [phi:main_vera_flash::@43->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:main_vera_flash::@43->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#9 [phi:main_vera_flash::@43->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [975] phi from main_vera_flash::@43 to main_vera_flash::@44 [phi:main_vera_flash::@43->main_vera_flash::@44]
    // main_vera_flash::@44
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [976] call printf_str
    // [783] phi from main_vera_flash::@44 to printf_str [phi:main_vera_flash::@44->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:main_vera_flash::@44->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = main_vera_flash::s1 [phi:main_vera_flash::@44->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@45
    // sprintf(info_text, "%05x differences!", vera_differences)
    // [977] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [978] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [980] spi_manufacturer#416 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [981] spi_memory_type#417 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [982] spi_memory_capacity#418 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHED, info_text)
    // [983] call display_info_vera
    // [651] phi from main_vera_flash::@45 to display_info_vera [phi:main_vera_flash::@45->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = info_text [phi:main_vera_flash::@45->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#418 [phi:main_vera_flash::@45->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#417 [phi:main_vera_flash::@45->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#416 [phi:main_vera_flash::@45->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_FLASHED [phi:main_vera_flash::@45->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [984] phi from main_vera_flash::@45 main_vera_flash::@9 to main_vera_flash::@13 [phi:main_vera_flash::@45/main_vera_flash::@9->main_vera_flash::@13]
    // main_vera_flash::@13
  __b13:
    // display_action_progress("VERA SPI de-activation ...")
    // [985] call display_action_progress
  // Now we loop until jumper JP1 is open again!
    // [557] phi from main_vera_flash::@13 to display_action_progress [phi:main_vera_flash::@13->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = main_vera_flash::info_text13 [phi:main_vera_flash::@13->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [986] phi from main_vera_flash::@13 to main_vera_flash::@53 [phi:main_vera_flash::@13->main_vera_flash::@53]
    // main_vera_flash::@53
    // display_action_text("Please OPEN the jumper JP1 on the VERA board!")
    // [987] call display_action_text
    // [843] phi from main_vera_flash::@53 to display_action_text [phi:main_vera_flash::@53->display_action_text]
    // [843] phi display_action_text::info_text#17 = main_vera_flash::info_text14 [phi:main_vera_flash::@53->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_action_text.info_text
    lda #>info_text14
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [988] phi from main_vera_flash::@53 to main_vera_flash::@54 [phi:main_vera_flash::@53->main_vera_flash::@54]
    // main_vera_flash::@54
    // vera_detect()
    // [989] call vera_detect
    // [1454] phi from main_vera_flash::@54 to vera_detect [phi:main_vera_flash::@54->vera_detect]
    jsr vera_detect
    // [990] phi from main_vera_flash::@18 main_vera_flash::@54 to main_vera_flash::@14 [phi:main_vera_flash::@18/main_vera_flash::@54->main_vera_flash::@14]
  __b5:
    // [990] phi main_vera_flash::spi_ensure_detect#12 = 0 [phi:main_vera_flash::@18/main_vera_flash::@54->main_vera_flash::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z spi_ensure_detect_1
    // main_vera_flash::@14
  __b14:
    // while(spi_ensure_detect < 16)
    // [991] if(main_vera_flash::spi_ensure_detect#12<$10) goto main_vera_flash::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z spi_ensure_detect_1
    cmp #$10
    bcc __b15
    // [992] phi from main_vera_flash::@14 to main_vera_flash::@16 [phi:main_vera_flash::@14->main_vera_flash::@16]
    // main_vera_flash::@16
    // display_action_text("The jumper JP1 has been opened on the VERA!")
    // [993] call display_action_text
    // [843] phi from main_vera_flash::@16 to display_action_text [phi:main_vera_flash::@16->display_action_text]
    // [843] phi display_action_text::info_text#17 = main_vera_flash::info_text15 [phi:main_vera_flash::@16->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_text.info_text
    lda #>info_text15
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [994] phi from main_vera_flash::@16 main_vera_flash::@23 to main_vera_flash::@1 [phi:main_vera_flash::@16/main_vera_flash::@23->main_vera_flash::@1]
    // main_vera_flash::@1
  __b1:
    // spi_deselect()
    // [995] call spi_deselect
    jsr spi_deselect
    rts
    // [996] phi from main_vera_flash::@14 to main_vera_flash::@15 [phi:main_vera_flash::@14->main_vera_flash::@15]
    // main_vera_flash::@15
  __b15:
    // vera_detect()
    // [997] call vera_detect
    // [1454] phi from main_vera_flash::@15 to vera_detect [phi:main_vera_flash::@15->vera_detect]
    jsr vera_detect
    // [998] phi from main_vera_flash::@15 to main_vera_flash::@55 [phi:main_vera_flash::@15->main_vera_flash::@55]
    // main_vera_flash::@55
    // wait_moment(1)
    // [999] call wait_moment
    // [792] phi from main_vera_flash::@55 to wait_moment [phi:main_vera_flash::@55->wait_moment]
    // [792] phi wait_moment::w#10 = 1 [phi:main_vera_flash::@55->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // main_vera_flash::@56
    // if(spi_manufacturer != 0xEF && spi_memory_type != 0x40 && spi_memory_capacity != 0x15)
    // [1000] if(spi_read::return#0==$ef) goto main_vera_flash::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #$ef
    cmp spi_read.return
    beq __b18
    // main_vera_flash::@61
    // [1001] if(spi_read::return#1==$40) goto main_vera_flash::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp spi_read.return_1
    beq __b18
    // main_vera_flash::@60
    // [1002] if(spi_read::return#2!=$15) goto main_vera_flash::@17 -- vbum1_neq_vbuc1_then_la1 
    lda #$15
    cmp spi_read.return_2
    bne __b17
    // main_vera_flash::@18
  __b18:
    // [1003] spi_manufacturer#412 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1004] spi_memory_type#413 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1005] spi_memory_capacity#414 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_WAITING, NULL)
    // [1006] call display_info_vera
    // [651] phi from main_vera_flash::@18 to display_info_vera [phi:main_vera_flash::@18->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@18->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#414 [phi:main_vera_flash::@18->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#413 [phi:main_vera_flash::@18->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#412 [phi:main_vera_flash::@18->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_WAITING [phi:main_vera_flash::@18->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_WAITING
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b5
    // main_vera_flash::@17
  __b17:
    // [1007] spi_manufacturer#411 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1008] spi_memory_type#412 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1009] spi_memory_capacity#413 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, NULL)
    // [1010] call display_info_vera
    // [651] phi from main_vera_flash::@17 to display_info_vera [phi:main_vera_flash::@17->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = 0 [phi:main_vera_flash::@17->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#413 [phi:main_vera_flash::@17->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#412 [phi:main_vera_flash::@17->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#411 [phi:main_vera_flash::@17->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_flash::@17->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@57
    // spi_ensure_detect++;
    // [1011] main_vera_flash::spi_ensure_detect#4 = ++ main_vera_flash::spi_ensure_detect#12 -- vbuz1=_inc_vbuz1 
    inc.z spi_ensure_detect_1
    // [990] phi from main_vera_flash::@57 to main_vera_flash::@14 [phi:main_vera_flash::@57->main_vera_flash::@14]
    // [990] phi main_vera_flash::spi_ensure_detect#12 = main_vera_flash::spi_ensure_detect#4 [phi:main_vera_flash::@57->main_vera_flash::@14#0] -- register_copy 
    jmp __b14
    // main_vera_flash::@9
  __b9:
    // [1012] spi_manufacturer#409 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1013] spi_memory_type#410 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1014] spi_memory_capacity#411 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "No update required")
    // [1015] call display_info_vera
  // VFL1 | VERA and VERA.BIN equal | Display that there are no differences between the VERA and VERA.BIN. Set VERA to Flashed. | None
    // [651] phi from main_vera_flash::@9 to display_info_vera [phi:main_vera_flash::@9->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = main_vera_flash::info_text6 [phi:main_vera_flash::@9->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_vera.info_text
    lda #>info_text6
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#411 [phi:main_vera_flash::@9->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#410 [phi:main_vera_flash::@9->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#409 [phi:main_vera_flash::@9->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_SKIP [phi:main_vera_flash::@9->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b13
    // [1016] phi from main_vera_flash::@3 to main_vera_flash::@4 [phi:main_vera_flash::@3->main_vera_flash::@4]
    // main_vera_flash::@4
  __b4:
    // vera_detect()
    // [1017] call vera_detect
    // [1454] phi from main_vera_flash::@4 to vera_detect [phi:main_vera_flash::@4->vera_detect]
    jsr vera_detect
    // [1018] phi from main_vera_flash::@4 to main_vera_flash::@26 [phi:main_vera_flash::@4->main_vera_flash::@26]
    // main_vera_flash::@26
    // wait_moment(1)
    // [1019] call wait_moment
    // [792] phi from main_vera_flash::@26 to wait_moment [phi:main_vera_flash::@26->wait_moment]
    // [792] phi wait_moment::w#10 = 1 [phi:main_vera_flash::@26->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // main_vera_flash::@27
    // if(spi_manufacturer == 0xEF && spi_memory_type == 0x40 && spi_memory_capacity == 0x15)
    // [1020] if(spi_read::return#0!=$ef) goto main_vera_flash::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #$ef
    cmp spi_read.return
    bne __b7
    // main_vera_flash::@59
    // [1021] if(spi_read::return#1!=$40) goto main_vera_flash::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #$40
    cmp spi_read.return_1
    bne __b7
    // main_vera_flash::@58
    // [1022] if(spi_read::return#2==$15) goto main_vera_flash::@6 -- vbum1_eq_vbuc1_then_la1 
    lda #$15
    cmp spi_read.return_2
    beq __b6
    // main_vera_flash::@7
  __b7:
    // [1023] spi_manufacturer#419 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1024] spi_memory_type#420 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1025] spi_memory_capacity#421 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_WAITING, "Close JP1 jumper pins!")
    // [1026] call display_info_vera
    // [651] phi from main_vera_flash::@7 to display_info_vera [phi:main_vera_flash::@7->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = main_vera_flash::info_text5 [phi:main_vera_flash::@7->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_vera.info_text
    lda #>info_text5
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#421 [phi:main_vera_flash::@7->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#420 [phi:main_vera_flash::@7->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#419 [phi:main_vera_flash::@7->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_WAITING [phi:main_vera_flash::@7->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_WAITING
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b2
    // main_vera_flash::@6
  __b6:
    // [1027] spi_manufacturer#417 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1028] spi_memory_type#418 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1029] spi_memory_capacity#419 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, "JP1 jumper pins closed!")
    // [1030] call display_info_vera
    // [651] phi from main_vera_flash::@6 to display_info_vera [phi:main_vera_flash::@6->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = main_vera_flash::info_text4 [phi:main_vera_flash::@6->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_vera.info_text
    lda #>info_text4
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#419 [phi:main_vera_flash::@6->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#418 [phi:main_vera_flash::@6->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#417 [phi:main_vera_flash::@6->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_DETECTED [phi:main_vera_flash::@6->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@32
    // spi_ensure_detect++;
    // [1031] main_vera_flash::spi_ensure_detect#1 = ++ main_vera_flash::spi_ensure_detect#11 -- vbuz1=_inc_vbuz1 
    inc.z spi_ensure_detect
    // [899] phi from main_vera_flash::@32 to main_vera_flash::@3 [phi:main_vera_flash::@32->main_vera_flash::@3]
    // [899] phi main_vera_flash::spi_ensure_detect#11 = main_vera_flash::spi_ensure_detect#1 [phi:main_vera_flash::@32->main_vera_flash::@3#0] -- register_copy 
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
    info_text6: .text "No update required"
    .byte 0
    s1: .text " differences!"
    .byte 0
    info_text8: .text "DO NOT RESET or REBOOT YOUR CX16 AND WAIT!"
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
// __mem() char util_wait_key(__zp($59) char *info_text, __zp($5f) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__10 = $42
    .label info_text = $59
    .label filter = $5f
    // display_action_text(info_text)
    // [1033] display_action_text::info_text#5 = util_wait_key::info_text#3
    // [1034] call display_action_text
    // [843] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [843] phi display_action_text::info_text#17 = display_action_text::info_text#5 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1035] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1036] util_wait_key::brom#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta brom
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1037] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1038] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // util_wait_key::CLI1
    // asm
    // asm { cli  }
    cli
    // [1040] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::CLI1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::CLI1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1042] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1043] call cbm_k_getin
    jsr cbm_k_getin
    // [1044] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1045] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbum2 
    lda cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [1046] if((char *)0!=util_wait_key::filter#13) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1047] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1048] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1049] BROM = util_wait_key::brom#0 -- vbuz1=vbum2 
    lda brom
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1050] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1051] strchr::str#0 = (const void *)util_wait_key::filter#13 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1052] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [1053] call strchr
    // [1057] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1057] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1057] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1054] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1055] util_wait_key::$10 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1056] if(util_wait_key::$10!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__10
    ora.z util_wait_key__10+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    bram: .byte 0
    brom: .byte 0
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
// __zp($42) void * strchr(__zp($42) const void *str, __mem() char c)
strchr: {
    .label ptr = $42
    .label return = $42
    .label str = $42
    // [1058] strchr::ptr#6 = (char *)strchr::str#2
    // [1059] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1059] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1060] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1061] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1061] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1062] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1063] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1064] strchr::return#8 = (void *)strchr::ptr#2
    // [1061] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1061] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1065] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
  .segment Data
    c: .byte 0
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
    .label display_info_rom__6 = $38
    .label display_info_rom__15 = $4e
    .label display_info_rom__16 = $3b
    .label info_text = $3c
    .label display_info_rom__19 = $38
    .label display_info_rom__20 = $38
    // unsigned char x = wherex()
    // [1067] call wherex
    jsr wherex
    // [1068] wherex::return#12 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_4
    // display_info_rom::@3
    // [1069] display_info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1070] call wherey
    jsr wherey
    // [1071] wherey::return#12 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_4
    // display_info_rom::@4
    // [1072] display_info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1073] status_rom[display_info_rom::rom_chip#10] = display_info_rom::info_status#10 -- pbuc1_derefidx_vbum1=vbum2 
    lda info_status
    ldy rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1074] display_rom_led::chip#1 = display_info_rom::rom_chip#10 -- vbum1=vbum2 
    tya
    sta display_rom_led.chip
    // [1075] display_rom_led::c#1 = status_color[display_info_rom::info_status#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_rom_led.c
    // [1076] call display_rom_led
    // [1421] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [1421] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [1421] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1077] gotoxy::y#23 = display_info_rom::rom_chip#10 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1078] call gotoxy
    // [455] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#23 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1079] display_info_rom::$16 = display_info_rom::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z display_info_rom__16
    // rom_chip*13
    // [1080] display_info_rom::$19 = display_info_rom::$16 + display_info_rom::rom_chip#10 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z display_info_rom__16
    sta.z display_info_rom__19
    // [1081] display_info_rom::$20 = display_info_rom::$19 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z display_info_rom__20
    asl
    asl
    sta.z display_info_rom__20
    // [1082] display_info_rom::$6 = display_info_rom::$20 + display_info_rom::rom_chip#10 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z display_info_rom__6
    sta.z display_info_rom__6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1083] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta.z printf_string.str_1+1
    // [1084] call printf_str
    // [783] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1085] printf_uchar::uvalue#4 = display_info_rom::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta printf_uchar.uvalue
    // [1086] call printf_uchar
    // [832] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1087] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1088] call printf_str
    // [783] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1089] display_info_rom::$15 = display_info_rom::info_status#10 << 1 -- vbuz1=vbum2_rol_1 
    lda info_status
    asl
    sta.z display_info_rom__15
    // [1090] printf_string::str#8 = status_text[display_info_rom::$15] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1091] call printf_string
    // [1307] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1092] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1093] call printf_str
    // [783] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1094] printf_string::str#9 = rom_device_names[display_info_rom::$16] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__16
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1095] call printf_string
    // [1307] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1096] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1097] call printf_str
    // [783] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1098] printf_string::str#29 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z printf_string.str_1
    sta.z printf_string.str
    lda.z printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1099] call printf_string
    // [1307] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#29 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = $d [phi:display_info_rom::@13->printf_string#3] -- vbum1=vbuc1 
    lda #$d
    sta printf_string.format_min_length
    jsr printf_string
    // [1100] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1101] call printf_str
    // [783] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [783] phi printf_str::putc#53 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1102] if((char *)0==display_info_rom::info_text#10) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // gotoxy(INFO_X+64-28, INFO_Y+rom_chip+2)
    // [1103] gotoxy::y#25 = display_info_rom::rom_chip#10 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1104] call gotoxy
    // [455] phi from display_info_rom::@2 to gotoxy [phi:display_info_rom::@2->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#25 [phi:display_info_rom::@2->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = 4+$40-$1c [phi:display_info_rom::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@16
    // printf("%-25s", info_text)
    // [1105] printf_string::str#11 = display_info_rom::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1106] call printf_string
    // [1307] phi from display_info_rom::@16 to printf_string [phi:display_info_rom::@16->printf_string]
    // [1307] phi printf_string::putc#17 = &cputc [phi:display_info_rom::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#11 [phi:display_info_rom::@16->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 1 [phi:display_info_rom::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = $19 [phi:display_info_rom::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1107] gotoxy::x#24 = display_info_rom::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1108] gotoxy::y#24 = display_info_rom::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1109] call gotoxy
    // [455] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#24 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#24 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1110] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    .label x = wherex.return_4
    .label y = wherey.return_4
    info_status: .byte 0
    rom_chip: .byte 0
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
    // [1112] display_info_rom::info_status#0 = display_info_cx16_rom::info_status#4
    // [1113] display_info_rom::info_text#0 = display_info_cx16_rom::info_text#4
    // [1114] call display_info_rom
    // [1066] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1066] phi display_info_rom::info_text#10 = display_info_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1066] phi display_info_rom::rom_chip#10 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbum1=vbuc1 
    lda #0
    sta display_info_rom.rom_chip
    // [1066] phi display_info_rom::info_status#10 = display_info_rom::info_status#0 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1115] return 
    rts
  .segment Data
    .label info_status = display_info_rom.info_status
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($36) char *destination, char *source)
strcpy: {
    .label src = $34
    .label dst = $36
    .label destination = $36
    // [1117] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [1117] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1117] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [1118] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1119] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1120] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1121] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1122] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1123] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $58
    .label screenlayer__1 = $55
    .label screenlayer__2 = $74
    .label screenlayer__5 = $71
    .label screenlayer__6 = $71
    .label screenlayer__7 = $70
    .label screenlayer__8 = $70
    .label screenlayer__9 = $6e
    .label screenlayer__10 = $6e
    .label screenlayer__11 = $6e
    .label screenlayer__12 = $6f
    .label screenlayer__13 = $6f
    .label screenlayer__14 = $6f
    .label screenlayer__16 = $70
    .label screenlayer__17 = $67
    .label screenlayer__18 = $6e
    .label screenlayer__19 = $6f
    .label y = $64
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1124] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1125] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1126] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1127] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1128] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1129] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1130] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1131] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1132] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1133] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1134] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1135] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1136] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1137] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1138] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [1139] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1140] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1141] screenlayer::$18 = (char)screenlayer::$9
    // [1142] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1143] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1144] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1145] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1146] screenlayer::$19 = (char)screenlayer::$12
    // [1147] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1148] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1149] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1150] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1151] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1151] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1151] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1152] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1153] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1154] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [1155] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1156] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1157] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1151] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1151] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1151] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1158] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1159] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1160] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1161] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1162] call gotoxy
    // [455] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [455] phi gotoxy::y#26 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1163] return 
    rts
    // [1164] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1165] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1166] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1167] call gotoxy
    // [455] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1168] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1169] call clearline
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
    // [1170] cx16_k_screen_set_mode::error = 0 -- vbum1=vbuc1 
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
    // [1172] return 
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
    // [1174] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbum2_minus_vbum3 
    lda x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [1175] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1176] display_frame_maskxy::x#0 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [1177] display_frame_maskxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [1178] call display_frame_maskxy
    // [1746] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [1746] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [1746] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1179] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1180] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1181] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = display_frame_char(mask)
    // [1182] display_frame_char::mask#0 = display_frame::mask#1
    // [1183] call display_frame_char
  // Add a corner.
    // [1772] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [1772] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1184] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1185] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1186] cputcxy::x#2 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1187] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1188] cputcxy::c#2 = display_frame::c#0
    // [1189] call cputcxy
    // [1345] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1190] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1191] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [1192] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1192] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1193] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1194] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1194] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1195] display_frame_maskxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta display_frame_maskxy.x
    // [1196] display_frame_maskxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [1197] call display_frame_maskxy
    // [1746] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [1746] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [1746] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1198] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1199] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1200] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1201] display_frame_char::mask#1 = display_frame::mask#3
    // [1202] call display_frame_char
    // [1772] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [1772] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1203] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1204] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1205] cputcxy::x#3 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1206] cputcxy::y#3 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1207] cputcxy::c#3 = display_frame::c#1
    // [1208] call cputcxy
    // [1345] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1209] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [1210] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [1211] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1211] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1212] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbum2_then_la1 
    lda y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1213] display_frame_maskxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [1214] display_frame_maskxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [1215] call display_frame_maskxy
    // [1746] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [1746] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [1746] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1216] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1217] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1218] display_frame::mask#11 = display_frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1219] display_frame_char::mask#5 = display_frame::mask#11
    // [1220] call display_frame_char
    // [1772] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [1772] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1221] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1222] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1223] cputcxy::x#7 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1224] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1225] cputcxy::c#7 = display_frame::c#5
    // [1226] call cputcxy
    // [1345] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1227] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1228] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [1229] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1229] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1230] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbum2_then_la1 
    lda x
    cmp x1
    bcc __b12
    // [1231] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1231] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1232] display_frame_maskxy::x#6 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [1233] display_frame_maskxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [1234] call display_frame_maskxy
    // [1746] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [1746] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [1746] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1235] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1236] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1237] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1238] display_frame_char::mask#6 = display_frame::mask#13
    // [1239] call display_frame_char
    // [1772] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [1772] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1240] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1241] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1242] cputcxy::x#8 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1243] cputcxy::y#8 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1244] cputcxy::c#8 = display_frame::c#6
    // [1245] call cputcxy
    // [1345] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1246] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1247] display_frame_maskxy::x#7 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [1248] display_frame_maskxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [1249] call display_frame_maskxy
    // [1746] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [1746] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [1746] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1250] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1251] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1252] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1253] display_frame_char::mask#7 = display_frame::mask#15
    // [1254] call display_frame_char
    // [1772] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [1772] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1255] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1256] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1257] cputcxy::x#9 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1258] cputcxy::y#9 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1259] cputcxy::c#9 = display_frame::c#7
    // [1260] call cputcxy
    // [1345] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#9 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#9 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1261] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1262] display_frame_maskxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta display_frame_maskxy.x
    // [1263] display_frame_maskxy::y#3 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [1264] call display_frame_maskxy
    // [1746] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [1746] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [1746] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1265] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1266] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1267] display_frame::mask#7 = display_frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1268] display_frame_char::mask#3 = display_frame::mask#7
    // [1269] call display_frame_char
    // [1772] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [1772] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1270] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1271] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1272] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1273] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1274] cputcxy::c#5 = display_frame::c#3
    // [1275] call cputcxy
    // [1345] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1276] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta display_frame_maskxy.x
    // [1277] display_frame_maskxy::y#4 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta display_frame_maskxy.y
    // [1278] call display_frame_maskxy
    // [1746] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [1746] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [1746] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1279] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1280] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1281] display_frame::mask#9 = display_frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1282] display_frame_char::mask#4 = display_frame::mask#9
    // [1283] call display_frame_char
    // [1772] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [1772] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1284] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1285] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1286] cputcxy::x#6 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [1287] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1288] cputcxy::c#6 = display_frame::c#4
    // [1289] call cputcxy
    // [1345] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1290] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1291] display_frame_maskxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta display_frame_maskxy.x
    // [1292] display_frame_maskxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta display_frame_maskxy.y
    // [1293] call display_frame_maskxy
    // [1746] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [1746] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [1746] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1294] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1295] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1296] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1297] display_frame_char::mask#2 = display_frame::mask#5
    // [1298] call display_frame_char
    // [1772] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [1772] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1299] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1300] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1301] cputcxy::x#4 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1302] cputcxy::y#4 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1303] cputcxy::c#4 = display_frame::c#2
    // [1304] call cputcxy
    // [1345] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1305] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1306] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
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
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($3e) void (*putc)(char), __zp($42) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $51
    .label str = $42
    .label str_1 = $4f
    .label putc = $3e
    // if(format.min_length)
    // [1308] if(0==printf_string::format_min_length#17) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1309] strlen::str#3 = printf_string::str#17 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1310] call strlen
    // [1787] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1787] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1311] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1312] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1313] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1314] printf_string::padding#1 = (signed char)printf_string::format_min_length#17 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1315] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1317] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1317] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1316] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1317] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1317] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1318] if(0!=printf_string::format_justify_left#17) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1319] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1320] printf_padding::putc#3 = printf_string::putc#17 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1321] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1322] call printf_padding
    // [1793] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1793] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1793] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1793] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1323] printf_str::putc#1 = printf_string::putc#17 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1324] printf_str::s#2 = printf_string::str#17
    // [1325] call printf_str
    // [783] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [783] phi printf_str::putc#53 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [783] phi printf_str::s#53 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1326] if(0==printf_string::format_justify_left#17) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1327] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1328] printf_padding::putc#4 = printf_string::putc#17 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1329] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1330] call printf_padding
    // [1793] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1793] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1793] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1793] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1331] return 
    rts
  .segment Data
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
    format_justify_left: .byte 0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($2d) const char *s)
cputs: {
    .label s = $2d
    // [1333] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1333] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1334] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1335] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1336] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [1337] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1338] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1339] callexecute cputc  -- call_vprc1 
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
    // [1341] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [1342] return 
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
    // [1343] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [1344] return 
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
    // [1346] gotoxy::x#0 = cputcxy::x#15 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1347] gotoxy::y#0 = cputcxy::y#15 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1348] call gotoxy
    // [455] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1349] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1350] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1352] return 
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
    // [1354] display_chip_led::tc#0 = display_smc_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [1355] call display_chip_led
    // [1801] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [1801] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #5
    sta display_chip_led.w
    // [1801] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbum1=vbuc1 
    lda #1+1
    sta display_chip_led.x
    // [1801] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1356] display_info_led::tc#0 = display_smc_led::c#2
    // [1357] call display_info_led
    // [1443] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1443] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbum1=vbuc1 
    lda #$11
    sta display_info_led.y
    // [1443] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [1443] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1358] return 
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
// void display_print_chip(__mem() char x, char y, __mem() char w, __zp($51) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $51
    .label text_1 = $4f
    .label text_2 = $40
    .label text_3 = $6c
    .label text_4 = $4b
    .label text_5 = $45
    .label text_6 = $53
    // display_chip_line(x, y++, w, *text++)
    // [1360] display_chip_line::x#0 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1361] display_chip_line::w#0 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [1362] display_chip_line::c#0 = *display_print_chip::text#11 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta display_chip_line.c
    // [1363] call display_chip_line
    // [1819] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [1819] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [1819] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [1819] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [1819] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [1364] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [1365] display_chip_line::x#1 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1366] display_chip_line::w#1 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [1367] display_chip_line::c#1 = *display_print_chip::text#0 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta display_chip_line.c
    // [1368] call display_chip_line
    // [1819] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [1819] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [1819] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [1819] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [1819] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [1369] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [1370] display_chip_line::x#2 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1371] display_chip_line::w#2 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [1372] display_chip_line::c#2 = *display_print_chip::text#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta display_chip_line.c
    // [1373] call display_chip_line
    // [1819] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [1819] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [1819] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [1819] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [1819] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [1374] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [1375] display_chip_line::x#3 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1376] display_chip_line::w#3 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [1377] display_chip_line::c#3 = *display_print_chip::text#15 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta display_chip_line.c
    // [1378] call display_chip_line
    // [1819] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [1819] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [1819] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [1819] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [1819] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [1379] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [1380] display_chip_line::x#4 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1381] display_chip_line::w#4 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [1382] display_chip_line::c#4 = *display_print_chip::text#16 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta display_chip_line.c
    // [1383] call display_chip_line
    // [1819] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [1819] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [1819] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [1819] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [1819] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [1384] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [1385] display_chip_line::x#5 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1386] display_chip_line::w#5 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [1387] display_chip_line::c#5 = *display_print_chip::text#17 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta display_chip_line.c
    // [1388] call display_chip_line
    // [1819] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [1819] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [1819] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [1819] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [1819] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [1389] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [1390] display_chip_line::x#6 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1391] display_chip_line::w#6 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [1392] display_chip_line::c#6 = *display_print_chip::text#18 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [1393] call display_chip_line
    // [1819] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [1819] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [1819] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [1819] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [1819] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [1394] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [1395] display_chip_line::x#7 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1396] display_chip_line::w#7 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_line.w
    // [1397] display_chip_line::c#7 = *display_print_chip::text#19 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [1398] call display_chip_line
    // [1819] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [1819] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [1819] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [1819] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [1819] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [1399] display_chip_end::x#0 = display_print_chip::x#10
    // [1400] display_chip_end::w#0 = display_print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta display_chip_end.w
    // [1401] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [1402] return 
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
    // [1404] display_chip_led::tc#1 = display_vera_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [1405] call display_chip_led
    // [1801] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [1801] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #8
    sta display_chip_led.w
    // [1801] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbum1=vbuc1 
    lda #9+1
    sta display_chip_led.x
    // [1801] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1406] display_info_led::tc#1 = display_vera_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_info_led.tc
    // [1407] call display_info_led
    // [1443] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1443] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbum1=vbuc1 
    lda #$11+1
    sta display_info_led.y
    // [1443] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [1443] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [1408] return 
    rts
  .segment Data
    c: .byte 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($59) char *source)
strcat: {
    .label strcat__0 = $5f
    .label dst = $5f
    .label src = $59
    .label source = $59
    // strlen(destination)
    // [1410] call strlen
    // [1787] phi from strcat to strlen [phi:strcat->strlen]
    // [1787] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1411] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1412] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [1413] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1414] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1414] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1414] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1415] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1416] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1417] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1418] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1419] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1420] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
    .label display_rom_led__0 = $38
    .label display_rom_led__7 = $38
    .label display_rom_led__8 = $38
    // chip*6
    // [1422] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbum2_rol_1 
    lda chip
    asl
    sta.z display_rom_led__7
    // [1423] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbum2 
    lda chip
    clc
    adc.z display_rom_led__8
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1424] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1425] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbum1=vbuz2_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_rom_led__0
    sta display_chip_led.x
    // [1426] display_chip_led::tc#2 = display_rom_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_chip_led.tc
    // [1427] call display_chip_led
    // [1801] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [1801] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbum1=vbuc1 
    lda #3
    sta display_chip_led.w
    // [1801] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [1801] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1428] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc chip
    sta display_info_led.y
    // [1429] display_info_led::tc#2 = display_rom_led::c#2 -- vbum1=vbum2 
    lda c
    sta display_info_led.tc
    // [1430] call display_info_led
    // [1443] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1443] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1443] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbum1=vbuc1 
    lda #4-2
    sta display_info_led.x
    // [1443] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [1431] return 
    rts
  .segment Data
    chip: .byte 0
    c: .byte 0
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($49) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $49
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1433] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1434] utoa::value#1 = printf_uint::uvalue#4
    // [1435] utoa::radix#0 = printf_uint::format_radix#4
    // [1436] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1437] printf_number_buffer::putc#1 = printf_uint::putc#4
    // [1438] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1439] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#4
    // [1440] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#4
    // [1441] call printf_number_buffer
  // Print using format
    // [1538] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1538] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1538] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1538] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1538] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1442] return 
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
    // [1444] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [1445] call textcolor
    // [437] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [437] phi textcolor::color#21 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1446] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1447] call bgcolor
    // [442] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1448] cputcxy::x#13 = display_info_led::x#4
    // [1449] cputcxy::y#13 = display_info_led::y#4
    // [1450] call cputcxy
    // [1345] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1345] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [1345] phi cputcxy::y#15 = cputcxy::y#13 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#13 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1451] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1452] call textcolor
    // [437] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [1453] return 
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
    // [1455] call spi_get_jedec
  // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    // [1910] phi from vera_detect to spi_get_jedec [phi:vera_detect->spi_get_jedec]
    jsr spi_get_jedec
    // vera_detect::@return
    // }
    // [1456] return 
    rts
}
  // vera_read
// __mem() unsigned long vera_read(__mem() char info_status)
vera_read: {
    .const bank_set_brom1_bank = 0
    .label fp = $7b
    // We start for VERA from 0x1:0xA000.
    .label vera_bram_ptr = $65
    .label vera_action_text = $5b
    // vera_read::bank_set_bram1
    // BRAM = bank
    // [1458] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // vera_read::@16
    // if(info_status == STATUS_READING)
    // [1459] if(vera_read::info_status#12==STATUS_READING) goto vera_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [1461] phi from vera_read::@16 to vera_read::@2 [phi:vera_read::@16->vera_read::@2]
    // [1461] phi vera_read::vera_bram_bank#14 = 0 [phi:vera_read::@16->vera_read::@2#0] -- vbum1=vbuc1 
    lda #0
    sta vera_bram_bank
    // [1461] phi vera_read::vera_action_text#10 = vera_read::vera_action_text#2 [phi:vera_read::@16->vera_read::@2#1] -- pbuz1=pbuc1 
    lda #<vera_action_text_2
    sta.z vera_action_text
    lda #>vera_action_text_2
    sta.z vera_action_text+1
    jmp __b2
    // [1460] phi from vera_read::@16 to vera_read::@1 [phi:vera_read::@16->vera_read::@1]
    // vera_read::@1
  __b1:
    // [1461] phi from vera_read::@1 to vera_read::@2 [phi:vera_read::@1->vera_read::@2]
    // [1461] phi vera_read::vera_bram_bank#14 = 1 [phi:vera_read::@1->vera_read::@2#0] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [1461] phi vera_read::vera_action_text#10 = vera_read::vera_action_text#1 [phi:vera_read::@1->vera_read::@2#1] -- pbuz1=pbuc1 
    lda #<vera_action_text_1
    sta.z vera_action_text
    lda #>vera_action_text_1
    sta.z vera_action_text+1
    // vera_read::@2
  __b2:
    // vera_read::bank_set_brom1
    // BROM = bank
    // [1462] BROM = vera_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1463] phi from vera_read::bank_set_brom1 to vera_read::@17 [phi:vera_read::bank_set_brom1->vera_read::@17]
    // vera_read::@17
    // display_action_text("Opening VERA.BIN from SD card ...")
    // [1464] call display_action_text
    // [843] phi from vera_read::@17 to display_action_text [phi:vera_read::@17->display_action_text]
    // [843] phi display_action_text::info_text#17 = vera_read::info_text [phi:vera_read::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1465] phi from vera_read::@17 to vera_read::@19 [phi:vera_read::@17->vera_read::@19]
    // vera_read::@19
    // FILE *fp = fopen("VERA.BIN", "r")
    // [1466] call fopen
    jsr fopen
    // [1467] fopen::return#3 = fopen::return#2
    // vera_read::@20
    // [1468] vera_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1469] if((struct $2 *)0==vera_read::fp#0) goto vera_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [1470] phi from vera_read::@20 to vera_read::@4 [phi:vera_read::@20->vera_read::@4]
    // vera_read::@4
    // gotoxy(x, y)
    // [1471] call gotoxy
    // [455] phi from vera_read::@4 to gotoxy [phi:vera_read::@4->gotoxy]
    // [455] phi gotoxy::y#26 = PROGRESS_Y [phi:vera_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = PROGRESS_X [phi:vera_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1472] phi from vera_read::@4 to vera_read::@5 [phi:vera_read::@4->vera_read::@5]
    // [1472] phi vera_read::y#11 = PROGRESS_Y [phi:vera_read::@4->vera_read::@5#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1472] phi vera_read::progress_row_current#10 = 0 [phi:vera_read::@4->vera_read::@5#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1472] phi vera_read::vera_bram_ptr#13 = (char *)$a000 [phi:vera_read::@4->vera_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1472] phi vera_read::vera_bram_bank#10 = vera_read::vera_bram_bank#14 [phi:vera_read::@4->vera_read::@5#3] -- register_copy 
    // [1472] phi vera_read::vera_file_size#11 = 0 [phi:vera_read::@4->vera_read::@5#4] -- vdum1=vduc1 
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
    // [1473] if(vera_read::vera_file_size#11<vera_size) goto vera_read::@6 -- vdum1_lt_vduc1_then_la1 
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
    // [1474] fclose::stream#0 = vera_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [1475] call fclose
    jsr fclose
    // [1476] phi from vera_read::@9 to vera_read::@3 [phi:vera_read::@9->vera_read::@3]
    // [1476] phi __stdio_filecount#26 = __stdio_filecount#2 [phi:vera_read::@9->vera_read::@3#0] -- register_copy 
    // [1476] phi vera_read::return#0 = vera_read::vera_file_size#11 [phi:vera_read::@9->vera_read::@3#1] -- register_copy 
    rts
    // [1476] phi from vera_read::@20 to vera_read::@3 [phi:vera_read::@20->vera_read::@3]
  __b4:
    // [1476] phi __stdio_filecount#26 = __stdio_filecount#1 [phi:vera_read::@20->vera_read::@3#0] -- register_copy 
    // [1476] phi vera_read::return#0 = 0 [phi:vera_read::@20->vera_read::@3#1] -- vdum1=vduc1 
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
    // [1477] return 
    rts
    // vera_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [1478] if(vera_read::info_status#12!=STATUS_CHECKING) goto vera_read::@23 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b7
    // [1480] phi from vera_read::@6 to vera_read::@7 [phi:vera_read::@6->vera_read::@7]
    // [1480] phi vera_read::vera_bram_ptr#10 = (char *) 1024 [phi:vera_read::@6->vera_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z vera_bram_ptr
    lda #>$400
    sta.z vera_bram_ptr+1
    // [1479] phi from vera_read::@6 to vera_read::@23 [phi:vera_read::@6->vera_read::@23]
    // vera_read::@23
    // [1480] phi from vera_read::@23 to vera_read::@7 [phi:vera_read::@23->vera_read::@7]
    // [1480] phi vera_read::vera_bram_ptr#10 = vera_read::vera_bram_ptr#13 [phi:vera_read::@23->vera_read::@7#0] -- register_copy 
    // vera_read::@7
  __b7:
    // display_action_text_reading(vera_action_text, "VERA.BIN", vera_file_size, vera_size, vera_bram_bank, vera_bram_ptr)
    // [1481] display_action_text_reading::action#0 = vera_read::vera_action_text#10 -- pbuz1=pbuz2 
    lda.z vera_action_text
    sta.z display_action_text_reading.action
    lda.z vera_action_text+1
    sta.z display_action_text_reading.action+1
    // [1482] display_action_text_reading::bytes#0 = vera_read::vera_file_size#11 -- vdum1=vdum2 
    lda vera_file_size
    sta display_action_text_reading.bytes
    lda vera_file_size+1
    sta display_action_text_reading.bytes+1
    lda vera_file_size+2
    sta display_action_text_reading.bytes+2
    lda vera_file_size+3
    sta display_action_text_reading.bytes+3
    // [1483] display_action_text_reading::bram_bank#0 = vera_read::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta display_action_text_reading.bram_bank
    // [1484] display_action_text_reading::bram_ptr#0 = vera_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1485] call display_action_text_reading
    // [2033] phi from vera_read::@7 to display_action_text_reading [phi:vera_read::@7->display_action_text_reading]
    jsr display_action_text_reading
    // vera_read::bank_set_bram2
    // BRAM = bank
    // [1486] BRAM = vera_read::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // vera_read::@18
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [1487] fgets::ptr#2 = vera_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z fgets.ptr
    lda.z vera_bram_ptr+1
    sta.z fgets.ptr+1
    // [1488] fgets::stream#0 = vera_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1489] call fgets
    jsr fgets
    // [1490] fgets::return#5 = fgets::return#1
    // vera_read::@21
    // [1491] vera_read::vera_package_read#0 = fgets::return#5 -- vwum1=vwum2 
    lda fgets.return
    sta vera_package_read
    lda fgets.return+1
    sta vera_package_read+1
    // if (!vera_package_read)
    // [1492] if(0!=vera_read::vera_package_read#0) goto vera_read::@8 -- 0_neq_vwum1_then_la1 
    lda vera_package_read
    ora vera_package_read+1
    bne __b8
    jmp __b9
    // vera_read::@8
  __b8:
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [1493] if(vera_read::progress_row_current#10!=VERA_PROGRESS_ROW) goto vera_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b10
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b10
    // vera_read::@13
    // gotoxy(x, ++y);
    // [1494] vera_read::y#1 = ++ vera_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1495] gotoxy::y#6 = vera_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1496] call gotoxy
    // [455] phi from vera_read::@13 to gotoxy [phi:vera_read::@13->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#6 [phi:vera_read::@13->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = PROGRESS_X [phi:vera_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1497] phi from vera_read::@13 to vera_read::@10 [phi:vera_read::@13->vera_read::@10]
    // [1497] phi vera_read::y#22 = vera_read::y#1 [phi:vera_read::@13->vera_read::@10#0] -- register_copy 
    // [1497] phi vera_read::progress_row_current#4 = 0 [phi:vera_read::@13->vera_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1497] phi from vera_read::@8 to vera_read::@10 [phi:vera_read::@8->vera_read::@10]
    // [1497] phi vera_read::y#22 = vera_read::y#11 [phi:vera_read::@8->vera_read::@10#0] -- register_copy 
    // [1497] phi vera_read::progress_row_current#4 = vera_read::progress_row_current#10 [phi:vera_read::@8->vera_read::@10#1] -- register_copy 
    // vera_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [1498] if(vera_read::info_status#12!=STATUS_READING) goto vera_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // vera_read::@14
    // cputc('.')
    // [1499] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1500] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_read::@11
  __b11:
    // vera_bram_ptr += vera_package_read
    // [1502] vera_read::vera_bram_ptr#2 = vera_read::vera_bram_ptr#10 + vera_read::vera_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z vera_bram_ptr
    adc vera_package_read
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc vera_package_read+1
    sta.z vera_bram_ptr+1
    // vera_file_size += vera_package_read
    // [1503] vera_read::vera_file_size#1 = vera_read::vera_file_size#11 + vera_read::vera_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1504] vera_read::progress_row_current#15 = vera_read::progress_row_current#4 + vera_read::vera_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_current
    adc vera_package_read
    sta progress_row_current
    lda progress_row_current+1
    adc vera_package_read+1
    sta progress_row_current+1
    // if (vera_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [1505] if(vera_read::vera_bram_ptr#2!=(char *)$c000) goto vera_read::@12 -- pbuz1_neq_pbuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b12
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b12
    // vera_read::@15
    // vera_bram_bank++;
    // [1506] vera_read::vera_bram_bank#2 = ++ vera_read::vera_bram_bank#10 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [1507] phi from vera_read::@15 to vera_read::@12 [phi:vera_read::@15->vera_read::@12]
    // [1507] phi vera_read::vera_bram_bank#13 = vera_read::vera_bram_bank#2 [phi:vera_read::@15->vera_read::@12#0] -- register_copy 
    // [1507] phi vera_read::vera_bram_ptr#8 = (char *)$a000 [phi:vera_read::@15->vera_read::@12#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1507] phi from vera_read::@11 to vera_read::@12 [phi:vera_read::@11->vera_read::@12]
    // [1507] phi vera_read::vera_bram_bank#13 = vera_read::vera_bram_bank#10 [phi:vera_read::@11->vera_read::@12#0] -- register_copy 
    // [1507] phi vera_read::vera_bram_ptr#8 = vera_read::vera_bram_ptr#2 [phi:vera_read::@11->vera_read::@12#1] -- register_copy 
    // vera_read::@12
  __b12:
    // if (vera_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [1508] if(vera_read::vera_bram_ptr#8!=(char *)$9800) goto vera_read::@22 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1472] phi from vera_read::@12 to vera_read::@5 [phi:vera_read::@12->vera_read::@5]
    // [1472] phi vera_read::y#11 = vera_read::y#22 [phi:vera_read::@12->vera_read::@5#0] -- register_copy 
    // [1472] phi vera_read::progress_row_current#10 = vera_read::progress_row_current#15 [phi:vera_read::@12->vera_read::@5#1] -- register_copy 
    // [1472] phi vera_read::vera_bram_ptr#13 = (char *)$a000 [phi:vera_read::@12->vera_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1472] phi vera_read::vera_bram_bank#10 = 1 [phi:vera_read::@12->vera_read::@5#3] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [1472] phi vera_read::vera_file_size#11 = vera_read::vera_file_size#1 [phi:vera_read::@12->vera_read::@5#4] -- register_copy 
    jmp __b5
    // [1509] phi from vera_read::@12 to vera_read::@22 [phi:vera_read::@12->vera_read::@22]
    // vera_read::@22
    // [1472] phi from vera_read::@22 to vera_read::@5 [phi:vera_read::@22->vera_read::@5]
    // [1472] phi vera_read::y#11 = vera_read::y#22 [phi:vera_read::@22->vera_read::@5#0] -- register_copy 
    // [1472] phi vera_read::progress_row_current#10 = vera_read::progress_row_current#15 [phi:vera_read::@22->vera_read::@5#1] -- register_copy 
    // [1472] phi vera_read::vera_bram_ptr#13 = vera_read::vera_bram_ptr#8 [phi:vera_read::@22->vera_read::@5#2] -- register_copy 
    // [1472] phi vera_read::vera_bram_bank#10 = vera_read::vera_bram_bank#13 [phi:vera_read::@22->vera_read::@5#3] -- register_copy 
    // [1472] phi vera_read::vera_file_size#11 = vera_read::vera_file_size#1 [phi:vera_read::@22->vera_read::@5#4] -- register_copy 
  .segment DataVera
    info_text: .text "Opening VERA.BIN from SD card ..."
    .byte 0
    path: .text "VERA.BIN"
    .byte 0
    vera_action_text_1: .text "Reading"
    .byte 0
    vera_action_text_2: .text "Checking"
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
// void uctoa(__mem() char value, __zp($40) char *buffer, __mem() char radix)
uctoa: {
    .label uctoa__4 = $38
    .label buffer = $40
    .label digit_values = $2d
    // if(radix==DECIMAL)
    // [1510] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1511] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1512] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1513] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1514] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1515] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1516] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1517] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1518] return 
    rts
    // [1519] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1519] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1519] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1519] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1519] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1519] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [1519] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1519] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1519] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1519] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1519] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1519] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [1520] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1520] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1520] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1520] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1520] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1521] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1522] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1523] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1524] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1525] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1526] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [1527] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [1528] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [1529] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1529] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1529] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1529] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1530] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1520] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1520] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1520] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1520] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1520] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1531] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1532] uctoa_append::value#0 = uctoa::value#2
    // [1533] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1534] call uctoa_append
    // [2108] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1535] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1536] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1537] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1529] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1529] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1529] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1529] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .byte 0
    digit: .byte 0
    .label value = printf_uchar.uvalue
    .label radix = printf_uchar.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($49) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $53
    .label putc = $49
    // if(format.min_length)
    // [1539] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [1540] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1541] call strlen
    // [1787] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1787] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1542] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1543] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [1544] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [1545] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1546] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1547] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1547] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1548] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1549] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1551] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1551] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1550] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1551] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1551] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1552] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1553] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1554] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1555] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1556] call printf_padding
    // [1793] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1793] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1793] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1793] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1557] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1558] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1559] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall13
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1561] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1562] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1563] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1564] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1565] call printf_padding
    // [1793] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1793] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1793] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [1793] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1566] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1567] call printf_str
    // [783] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [783] phi printf_str::putc#53 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [783] phi printf_str::s#53 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1568] return 
    rts
    // Outside Flow
  icall13:
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
    .label vera_verify__16 = $65
    .label vera_bram_ptr = $76
    // vera_verify::bank_set_bram1
    // BRAM = bank
    // [1570] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // vera_verify::@11
    // unsigned long vera_boundary = vera_file_size
    // [1571] vera_verify::vera_boundary#0 = vera_file_size#1 -- vdum1=vdum2 
    lda vera_file_size
    sta vera_boundary
    lda vera_file_size+1
    sta vera_boundary+1
    lda vera_file_size+2
    sta vera_boundary+2
    lda vera_file_size+3
    sta vera_boundary+3
    // [1572] spi_manufacturer#421 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1573] spi_memory_type#422 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1574] spi_memory_capacity#423 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_COMPARING, "Comparing VERA ...")
    // [1575] call display_info_vera
    // [651] phi from vera_verify::@11 to display_info_vera [phi:vera_verify::@11->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = vera_verify::info_text [phi:vera_verify::@11->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_vera.info_text
    lda #>info_text
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#423 [phi:vera_verify::@11->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#422 [phi:vera_verify::@11->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#421 [phi:vera_verify::@11->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_COMPARING [phi:vera_verify::@11->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1576] phi from vera_verify::@11 to vera_verify::@12 [phi:vera_verify::@11->vera_verify::@12]
    // vera_verify::@12
    // gotoxy(x, y)
    // [1577] call gotoxy
    // [455] phi from vera_verify::@12 to gotoxy [phi:vera_verify::@12->gotoxy]
    // [455] phi gotoxy::y#26 = PROGRESS_Y [phi:vera_verify::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = PROGRESS_X [phi:vera_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1578] phi from vera_verify::@12 to vera_verify::@13 [phi:vera_verify::@12->vera_verify::@13]
    // vera_verify::@13
    // spi_read_flash(0UL)
    // [1579] call spi_read_flash
    // [2115] phi from vera_verify::@13 to spi_read_flash [phi:vera_verify::@13->spi_read_flash]
    jsr spi_read_flash
    // [1580] phi from vera_verify::@13 to vera_verify::@1 [phi:vera_verify::@13->vera_verify::@1]
    // [1580] phi vera_verify::y#3 = PROGRESS_Y [phi:vera_verify::@13->vera_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1580] phi vera_verify::progress_row_current#3 = 0 [phi:vera_verify::@13->vera_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1580] phi vera_verify::vera_different_bytes#11 = 0 [phi:vera_verify::@13->vera_verify::@1#2] -- vdum1=vduc1 
    sta vera_different_bytes
    sta vera_different_bytes+1
    lda #<0>>$10
    sta vera_different_bytes+2
    lda #>0>>$10
    sta vera_different_bytes+3
    // [1580] phi vera_verify::vera_bram_ptr#10 = (char *)$a000 [phi:vera_verify::@13->vera_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1580] phi vera_verify::vera_bram_bank#11 = 1 [phi:vera_verify::@13->vera_verify::@1#4] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [1580] phi vera_verify::vera_address#11 = 0 [phi:vera_verify::@13->vera_verify::@1#5] -- vdum1=vduc1 
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
    // [1581] if(vera_verify::vera_address#11<vera_verify::vera_boundary#0) goto vera_verify::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1582] return 
    rts
    // vera_verify::@2
  __b2:
    // unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_ptr, VERA_PROGRESS_CELL)
    // [1583] vera_compare::bank_ram#0 = vera_verify::vera_bram_bank#11 -- vbum1=vbum2 
    lda vera_bram_bank
    sta vera_compare.bank_ram
    // [1584] vera_compare::bram_ptr#0 = vera_verify::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z vera_compare.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z vera_compare.bram_ptr+1
    // [1585] call vera_compare
  // {asm{.byte $db}}
    // [2126] phi from vera_verify::@2 to vera_compare [phi:vera_verify::@2->vera_compare]
    jsr vera_compare
    // unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_ptr, VERA_PROGRESS_CELL)
    // [1586] vera_compare::return#0 = vera_compare::equal_bytes#2
    // vera_verify::@14
    // [1587] vera_verify::equal_bytes#0 = vera_compare::return#0
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [1588] if(vera_verify::progress_row_current#3!=VERA_PROGRESS_ROW) goto vera_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b3
    // vera_verify::@8
    // gotoxy(x, ++y);
    // [1589] vera_verify::y#1 = ++ vera_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1590] gotoxy::y#8 = vera_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1591] call gotoxy
    // [455] phi from vera_verify::@8 to gotoxy [phi:vera_verify::@8->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#8 [phi:vera_verify::@8->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = PROGRESS_X [phi:vera_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1592] phi from vera_verify::@8 to vera_verify::@3 [phi:vera_verify::@8->vera_verify::@3]
    // [1592] phi vera_verify::y#10 = vera_verify::y#1 [phi:vera_verify::@8->vera_verify::@3#0] -- register_copy 
    // [1592] phi vera_verify::progress_row_current#4 = 0 [phi:vera_verify::@8->vera_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1592] phi from vera_verify::@14 to vera_verify::@3 [phi:vera_verify::@14->vera_verify::@3]
    // [1592] phi vera_verify::y#10 = vera_verify::y#3 [phi:vera_verify::@14->vera_verify::@3#0] -- register_copy 
    // [1592] phi vera_verify::progress_row_current#4 = vera_verify::progress_row_current#3 [phi:vera_verify::@14->vera_verify::@3#1] -- register_copy 
    // vera_verify::@3
  __b3:
    // if (equal_bytes != VERA_PROGRESS_CELL)
    // [1593] if(vera_verify::equal_bytes#0!=VERA_PROGRESS_CELL) goto vera_verify::@4 -- vwum1_neq_vbuc1_then_la1 
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
    // [1594] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1595] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_verify::@5
  __b5:
    // vera_bram_ptr += VERA_PROGRESS_CELL
    // [1597] vera_verify::vera_bram_ptr#1 = vera_verify::vera_bram_ptr#10 + VERA_PROGRESS_CELL -- pbuz1=pbuz1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc.z vera_bram_ptr
    sta.z vera_bram_ptr
    bcc !+
    inc.z vera_bram_ptr+1
  !:
    // vera_address += VERA_PROGRESS_CELL
    // [1598] vera_verify::vera_address#1 = vera_verify::vera_address#11 + VERA_PROGRESS_CELL -- vdum1=vdum1_plus_vbuc1 
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
    // [1599] vera_verify::progress_row_current#11 = vera_verify::progress_row_current#4 + VERA_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc progress_row_current
    sta progress_row_current
    bcc !+
    inc progress_row_current+1
  !:
    // if (vera_bram_ptr == BRAM_HIGH)
    // [1600] if(vera_verify::vera_bram_ptr#1!=$c000) goto vera_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b6
    // vera_verify::@10
    // vera_bram_bank++;
    // [1601] vera_verify::vera_bram_bank#1 = ++ vera_verify::vera_bram_bank#11 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [1602] phi from vera_verify::@10 to vera_verify::@6 [phi:vera_verify::@10->vera_verify::@6]
    // [1602] phi vera_verify::vera_bram_bank#25 = vera_verify::vera_bram_bank#1 [phi:vera_verify::@10->vera_verify::@6#0] -- register_copy 
    // [1602] phi vera_verify::vera_bram_ptr#6 = (char *)$a000 [phi:vera_verify::@10->vera_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1602] phi from vera_verify::@5 to vera_verify::@6 [phi:vera_verify::@5->vera_verify::@6]
    // [1602] phi vera_verify::vera_bram_bank#25 = vera_verify::vera_bram_bank#11 [phi:vera_verify::@5->vera_verify::@6#0] -- register_copy 
    // [1602] phi vera_verify::vera_bram_ptr#6 = vera_verify::vera_bram_ptr#1 [phi:vera_verify::@5->vera_verify::@6#1] -- register_copy 
    // vera_verify::@6
  __b6:
    // if (vera_bram_ptr == RAM_HIGH)
    // [1603] if(vera_verify::vera_bram_ptr#6!=$9800) goto vera_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b7
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b7
    // [1605] phi from vera_verify::@6 to vera_verify::@7 [phi:vera_verify::@6->vera_verify::@7]
    // [1605] phi vera_verify::vera_bram_ptr#11 = (char *)$a000 [phi:vera_verify::@6->vera_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1605] phi vera_verify::vera_bram_bank#10 = 1 [phi:vera_verify::@6->vera_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [1604] phi from vera_verify::@6 to vera_verify::@24 [phi:vera_verify::@6->vera_verify::@24]
    // vera_verify::@24
    // [1605] phi from vera_verify::@24 to vera_verify::@7 [phi:vera_verify::@24->vera_verify::@7]
    // [1605] phi vera_verify::vera_bram_ptr#11 = vera_verify::vera_bram_ptr#6 [phi:vera_verify::@24->vera_verify::@7#0] -- register_copy 
    // [1605] phi vera_verify::vera_bram_bank#10 = vera_verify::vera_bram_bank#25 [phi:vera_verify::@24->vera_verify::@7#1] -- register_copy 
    // vera_verify::@7
  __b7:
    // VERA_PROGRESS_CELL - equal_bytes
    // [1606] vera_verify::$16 = VERA_PROGRESS_CELL - vera_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<VERA_PROGRESS_CELL
    sbc equal_bytes
    sta.z vera_verify__16
    lda #>VERA_PROGRESS_CELL
    sbc equal_bytes+1
    sta.z vera_verify__16+1
    // vera_different_bytes += (VERA_PROGRESS_CELL - equal_bytes)
    // [1607] vera_verify::vera_different_bytes#1 = vera_verify::vera_different_bytes#11 + vera_verify::$16 -- vdum1=vdum1_plus_vwuz2 
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
    // [1608] call snprintf_init
    jsr snprintf_init
    // [1609] phi from vera_verify::@7 to vera_verify::@15 [phi:vera_verify::@7->vera_verify::@15]
    // vera_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1610] call printf_str
    // [783] phi from vera_verify::@15 to printf_str [phi:vera_verify::@15->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:vera_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = vera_verify::s [phi:vera_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1611] printf_ulong::uvalue#0 = vera_verify::vera_different_bytes#1 -- vdum1=vdum2 
    lda vera_different_bytes
    sta printf_ulong.uvalue
    lda vera_different_bytes+1
    sta printf_ulong.uvalue+1
    lda vera_different_bytes+2
    sta printf_ulong.uvalue+2
    lda vera_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1612] call printf_ulong
    // [1632] phi from vera_verify::@16 to printf_ulong [phi:vera_verify::@16->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 1 [phi:vera_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 5 [phi:vera_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:vera_verify::@16->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#0 [phi:vera_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1613] phi from vera_verify::@16 to vera_verify::@17 [phi:vera_verify::@16->vera_verify::@17]
    // vera_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1614] call printf_str
    // [783] phi from vera_verify::@17 to printf_str [phi:vera_verify::@17->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:vera_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = vera_verify::s1 [phi:vera_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1615] printf_uchar::uvalue#0 = vera_verify::vera_bram_bank#10 -- vbum1=vbum2 
    lda vera_bram_bank
    sta printf_uchar.uvalue
    // [1616] call printf_uchar
    // [832] phi from vera_verify::@18 to printf_uchar [phi:vera_verify::@18->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 1 [phi:vera_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 2 [phi:vera_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &snputc [phi:vera_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:vera_verify::@18->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:vera_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1617] phi from vera_verify::@18 to vera_verify::@19 [phi:vera_verify::@18->vera_verify::@19]
    // vera_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1618] call printf_str
    // [783] phi from vera_verify::@19 to printf_str [phi:vera_verify::@19->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:vera_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s2 [phi:vera_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1619] printf_uint::uvalue#0 = (unsigned int)vera_verify::vera_bram_ptr#11 -- vwum1=vwuz2 
    lda.z vera_bram_ptr
    sta printf_uint.uvalue
    lda.z vera_bram_ptr+1
    sta printf_uint.uvalue+1
    // [1620] call printf_uint
    // [1432] phi from vera_verify::@20 to printf_uint [phi:vera_verify::@20->printf_uint]
    // [1432] phi printf_uint::format_zero_padding#4 = 1 [phi:vera_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1432] phi printf_uint::format_min_length#4 = 4 [phi:vera_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1432] phi printf_uint::putc#4 = &snputc [phi:vera_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1432] phi printf_uint::format_radix#4 = HEXADECIMAL [phi:vera_verify::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1432] phi printf_uint::uvalue#4 = printf_uint::uvalue#0 [phi:vera_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1621] phi from vera_verify::@20 to vera_verify::@21 [phi:vera_verify::@20->vera_verify::@21]
    // vera_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1622] call printf_str
    // [783] phi from vera_verify::@21 to printf_str [phi:vera_verify::@21->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:vera_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = vera_verify::s3 [phi:vera_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // vera_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1623] printf_ulong::uvalue#1 = vera_verify::vera_address#1 -- vdum1=vdum2 
    lda vera_address
    sta printf_ulong.uvalue
    lda vera_address+1
    sta printf_ulong.uvalue+1
    lda vera_address+2
    sta printf_ulong.uvalue+2
    lda vera_address+3
    sta printf_ulong.uvalue+3
    // [1624] call printf_ulong
    // [1632] phi from vera_verify::@22 to printf_ulong [phi:vera_verify::@22->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 1 [phi:vera_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 5 [phi:vera_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:vera_verify::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#1 [phi:vera_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // vera_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_ptr, vera_address)
    // [1625] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1626] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1628] call display_action_text
    // [843] phi from vera_verify::@23 to display_action_text [phi:vera_verify::@23->display_action_text]
    // [843] phi display_action_text::info_text#17 = info_text [phi:vera_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1580] phi from vera_verify::@23 to vera_verify::@1 [phi:vera_verify::@23->vera_verify::@1]
    // [1580] phi vera_verify::y#3 = vera_verify::y#10 [phi:vera_verify::@23->vera_verify::@1#0] -- register_copy 
    // [1580] phi vera_verify::progress_row_current#3 = vera_verify::progress_row_current#11 [phi:vera_verify::@23->vera_verify::@1#1] -- register_copy 
    // [1580] phi vera_verify::vera_different_bytes#11 = vera_verify::vera_different_bytes#1 [phi:vera_verify::@23->vera_verify::@1#2] -- register_copy 
    // [1580] phi vera_verify::vera_bram_ptr#10 = vera_verify::vera_bram_ptr#11 [phi:vera_verify::@23->vera_verify::@1#3] -- register_copy 
    // [1580] phi vera_verify::vera_bram_bank#11 = vera_verify::vera_bram_bank#10 [phi:vera_verify::@23->vera_verify::@1#4] -- register_copy 
    // [1580] phi vera_verify::vera_address#11 = vera_verify::vera_address#1 [phi:vera_verify::@23->vera_verify::@1#5] -- register_copy 
    jmp __b1
    // vera_verify::@4
  __b4:
    // cputc('*')
    // [1629] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1630] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b5
  .segment DataVera
    info_text: .text "Comparing VERA ..."
    .byte 0
    s: .text "Comparing: "
    .byte 0
    s1: .text " differences between RAM:"
    .byte 0
    s3: .text " <-> ROM:"
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
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_ulong: {
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1633] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1634] ultoa::value#1 = printf_ulong::uvalue#10
    // [1635] ultoa::radix#0 = printf_ulong::format_radix#10
    // [1636] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1637] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1638] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#10
    // [1639] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#10
    // [1640] call printf_number_buffer
  // Print using format
    // [1538] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1538] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [1538] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1538] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1538] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1641] return 
    rts
  .segment Data
    uvalue: .dword 0
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment CodeVera
  // vera_erase
vera_erase: {
    .label vera_erase__0 = $7f
    // BYTE2(vera_file_size)
    // [1642] vera_erase::$0 = byte2  vera_file_size#1 -- vbuz1=_byte2_vdum2 
    lda vera_file_size+2
    sta.z vera_erase__0
    // unsigned char vera_total_64k_blocks = BYTE2(vera_file_size)+1
    // [1643] vera_erase::vera_total_64k_blocks#0 = vera_erase::$0 + 1 -- vbum1=vbuz2_plus_1 
    inc
    sta vera_total_64k_blocks
    // [1644] phi from vera_erase to vera_erase::@1 [phi:vera_erase->vera_erase::@1]
    // [1644] phi vera_erase::vera_current_64k_block#2 = 0 [phi:vera_erase->vera_erase::@1#0] -- vbum1=vbuc1 
    lda #0
    sta vera_current_64k_block
    // vera_erase::@1
  __b1:
    // while(vera_current_64k_block < vera_total_64k_blocks)
    // [1645] if(vera_erase::vera_current_64k_block#2<vera_erase::vera_total_64k_blocks#0) goto vera_erase::@2 -- vbum1_lt_vbum2_then_la1 
    lda vera_current_64k_block
    cmp vera_total_64k_blocks
    bcc __b2
    // vera_erase::@return
    // }
    // [1646] return 
    rts
    // vera_erase::@2
  __b2:
    // vera_current_64k_block++;
    // [1647] vera_erase::vera_current_64k_block#1 = ++ vera_erase::vera_current_64k_block#2 -- vbum1=_inc_vbum1 
    inc vera_current_64k_block
    // [1644] phi from vera_erase::@2 to vera_erase::@1 [phi:vera_erase::@2->vera_erase::@1]
    // [1644] phi vera_erase::vera_current_64k_block#2 = vera_erase::vera_current_64k_block#1 [phi:vera_erase::@2->vera_erase::@1#0] -- register_copy 
    jmp __b1
  .segment DataVera
    vera_total_64k_blocks: .byte 0
    vera_current_64k_block: .byte 0
}
.segment CodeVera
  // vera_flash
vera_flash: {
    .label vera_flash__18 = $68
    .label vera_bram_ptr = $61
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1649] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [557] phi from vera_flash to display_action_progress [phi:vera_flash->display_action_progress]
    // [557] phi display_action_progress::info_text#19 = vera_flash::info_text [phi:vera_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // vera_flash::@14
    // [1650] spi_manufacturer#420 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [1651] spi_memory_type#421 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [1652] spi_memory_capacity#422 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_FLASHING, "Flashing ...")
    // [1653] call display_info_vera
    // [651] phi from vera_flash::@14 to display_info_vera [phi:vera_flash::@14->display_info_vera]
    // [651] phi display_info_vera::info_text#19 = vera_flash::info_text1 [phi:vera_flash::@14->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [651] phi spi_memory_capacity#110 = spi_memory_capacity#422 [phi:vera_flash::@14->display_info_vera#1] -- register_copy 
    // [651] phi spi_memory_type#111 = spi_memory_type#421 [phi:vera_flash::@14->display_info_vera#2] -- register_copy 
    // [651] phi spi_manufacturer#100 = spi_manufacturer#420 [phi:vera_flash::@14->display_info_vera#3] -- register_copy 
    // [651] phi display_info_vera::info_status#19 = STATUS_FLASHING [phi:vera_flash::@14->display_info_vera#4] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1654] phi from vera_flash::@14 to vera_flash::@1 [phi:vera_flash::@14->vera_flash::@1]
    // [1654] phi vera_flash::vera_bram_ptr#10 = (char *)$a000 [phi:vera_flash::@14->vera_flash::@1#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1654] phi vera_flash::vera_bram_bank#11 = 1 [phi:vera_flash::@14->vera_flash::@1#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [1654] phi vera_flash::y_sector#14 = PROGRESS_Y [phi:vera_flash::@14->vera_flash::@1#2] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1654] phi vera_flash::x_sector#14 = PROGRESS_X [phi:vera_flash::@14->vera_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1654] phi vera_flash::return#2 = 0 [phi:vera_flash::@14->vera_flash::@1#4] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
    // [1654] phi from vera_flash::@11 to vera_flash::@1 [phi:vera_flash::@11->vera_flash::@1]
    // [1654] phi vera_flash::vera_bram_ptr#10 = vera_flash::vera_bram_ptr#18 [phi:vera_flash::@11->vera_flash::@1#0] -- register_copy 
    // [1654] phi vera_flash::vera_bram_bank#11 = vera_flash::vera_bram_bank#14 [phi:vera_flash::@11->vera_flash::@1#1] -- register_copy 
    // [1654] phi vera_flash::y_sector#14 = vera_flash::y_sector#14 [phi:vera_flash::@11->vera_flash::@1#2] -- register_copy 
    // [1654] phi vera_flash::x_sector#14 = vera_flash::x_sector#1 [phi:vera_flash::@11->vera_flash::@1#3] -- register_copy 
    // [1654] phi vera_flash::return#2 = vera_flash::vera_address_page#12 [phi:vera_flash::@11->vera_flash::@1#4] -- register_copy 
    // vera_flash::@1
  __b1:
    // while (vera_address_page < vera_file_size)
    // [1655] if(vera_flash::return#2<vera_file_size#1) goto vera_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1656] display_action_text_flashed::bytes#0 = vera_flash::return#2 -- vdum1=vdum2 
    lda return
    sta display_action_text_flashed.bytes
    lda return+1
    sta display_action_text_flashed.bytes+1
    lda return+2
    sta display_action_text_flashed.bytes+2
    lda return+3
    sta display_action_text_flashed.bytes+3
    // [1657] call display_action_text_flashed
    // [2170] phi from vera_flash::@3 to display_action_text_flashed [phi:vera_flash::@3->display_action_text_flashed]
    jsr display_action_text_flashed
    // [1658] phi from vera_flash::@3 to vera_flash::@16 [phi:vera_flash::@3->vera_flash::@16]
    // vera_flash::@16
    // wait_moment(32)
    // [1659] call wait_moment
    // [792] phi from vera_flash::@16 to wait_moment [phi:vera_flash::@16->wait_moment]
    // [792] phi wait_moment::w#10 = $20 [phi:vera_flash::@16->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // vera_flash::@return
    // }
    // [1660] return 
    rts
    // vera_flash::@2
  __b2:
    // unsigned long vera_page_boundary = vera_address_page + VERA_PROGRESS_PAGE
    // [1661] vera_flash::vera_page_boundary#0 = vera_flash::return#2 + VERA_PROGRESS_PAGE -- vdum1=vdum2_plus_vwuc1 
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
    // [1662] cputcxy::x#0 = vera_flash::x_sector#14 -- vbum1=vbum2 
    lda x_sector
    sta cputcxy.x
    // [1663] cputcxy::y#0 = vera_flash::y_sector#14 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1664] call cputcxy
    // [1345] phi from vera_flash::@2 to cputcxy [phi:vera_flash::@2->cputcxy]
    // [1345] phi cputcxy::c#15 = '.' [phi:vera_flash::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #'.'
    sta cputcxy.c
    // [1345] phi cputcxy::y#15 = cputcxy::y#0 [phi:vera_flash::@2->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#0 [phi:vera_flash::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_flash::@15
    // cputc('.')
    // [1665] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1666] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_flash::bank_set_bram1
    // BRAM = bank
    // [1668] BRAM = vera_flash::vera_bram_bank#11 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // [1669] vera_flash::vera_address#13 = vera_flash::return#2 -- vdum1=vdum2 
    lda return
    sta vera_address
    lda return+1
    sta vera_address+1
    lda return+2
    sta vera_address+2
    lda return+3
    sta vera_address+3
    // [1670] phi from vera_flash::@17 vera_flash::bank_set_bram1 to vera_flash::@5 [phi:vera_flash::@17/vera_flash::bank_set_bram1->vera_flash::@5]
    // [1670] phi vera_flash::vera_address_page#12 = vera_flash::vera_address_page#1 [phi:vera_flash::@17/vera_flash::bank_set_bram1->vera_flash::@5#0] -- register_copy 
    // [1670] phi vera_flash::vera_bram_ptr#13 = vera_flash::vera_bram_ptr#1 [phi:vera_flash::@17/vera_flash::bank_set_bram1->vera_flash::@5#1] -- register_copy 
    // [1670] phi vera_flash::vera_address#10 = vera_flash::vera_address#1 [phi:vera_flash::@17/vera_flash::bank_set_bram1->vera_flash::@5#2] -- register_copy 
    // vera_flash::@5
  __b5:
    // while (vera_address < vera_page_boundary)
    // [1671] if(vera_flash::vera_address#10<vera_flash::vera_page_boundary#0) goto vera_flash::@6 -- vdum1_lt_vdum2_then_la1 
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
    // [1672] if(vera_flash::vera_bram_ptr#13!=$c000) goto vera_flash::@10 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b10
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b10
    // vera_flash::@12
    // vera_bram_bank++;
    // [1673] vera_flash::vera_bram_bank#1 = ++ vera_flash::vera_bram_bank#11 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [1674] phi from vera_flash::@12 to vera_flash::@10 [phi:vera_flash::@12->vera_flash::@10]
    // [1674] phi vera_flash::vera_bram_bank#21 = vera_flash::vera_bram_bank#1 [phi:vera_flash::@12->vera_flash::@10#0] -- register_copy 
    // [1674] phi vera_flash::vera_bram_ptr#7 = (char *)$a000 [phi:vera_flash::@12->vera_flash::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1674] phi from vera_flash::@4 to vera_flash::@10 [phi:vera_flash::@4->vera_flash::@10]
    // [1674] phi vera_flash::vera_bram_bank#21 = vera_flash::vera_bram_bank#11 [phi:vera_flash::@4->vera_flash::@10#0] -- register_copy 
    // [1674] phi vera_flash::vera_bram_ptr#7 = vera_flash::vera_bram_ptr#13 [phi:vera_flash::@4->vera_flash::@10#1] -- register_copy 
    // vera_flash::@10
  __b10:
    // if (vera_bram_ptr == RAM_HIGH)
    // [1675] if(vera_flash::vera_bram_ptr#7!=$9800) goto vera_flash::@18 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b11
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b11
    // [1677] phi from vera_flash::@10 to vera_flash::@11 [phi:vera_flash::@10->vera_flash::@11]
    // [1677] phi vera_flash::vera_bram_ptr#18 = (char *)$a000 [phi:vera_flash::@10->vera_flash::@11#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1677] phi vera_flash::vera_bram_bank#14 = 1 [phi:vera_flash::@10->vera_flash::@11#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [1676] phi from vera_flash::@10 to vera_flash::@18 [phi:vera_flash::@10->vera_flash::@18]
    // vera_flash::@18
    // [1677] phi from vera_flash::@18 to vera_flash::@11 [phi:vera_flash::@18->vera_flash::@11]
    // [1677] phi vera_flash::vera_bram_ptr#18 = vera_flash::vera_bram_ptr#7 [phi:vera_flash::@18->vera_flash::@11#0] -- register_copy 
    // [1677] phi vera_flash::vera_bram_bank#14 = vera_flash::vera_bram_bank#21 [phi:vera_flash::@18->vera_flash::@11#1] -- register_copy 
    // vera_flash::@11
  __b11:
    // x_sector += 2
    // [1678] vera_flash::x_sector#1 = vera_flash::x_sector#14 + 2 -- vbum1=vbum1_plus_2 
    lda x_sector
    clc
    adc #2
    sta x_sector
    // vera_address_page % VERA_PROGRESS_ROW
    // [1679] vera_flash::$18 = vera_flash::vera_address_page#12 & VERA_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
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
    // [1680] if(0!=vera_flash::$18) goto vera_flash::@1 -- 0_neq_vduz1_then_la1 
    lda.z vera_flash__18
    ora.z vera_flash__18+1
    ora.z vera_flash__18+2
    ora.z vera_flash__18+3
    beq !__b1+
    jmp __b1
  !__b1:
    // vera_flash::@13
    // y_sector++;
    // [1681] vera_flash::y_sector#1 = ++ vera_flash::y_sector#14 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1654] phi from vera_flash::@13 to vera_flash::@1 [phi:vera_flash::@13->vera_flash::@1]
    // [1654] phi vera_flash::vera_bram_ptr#10 = vera_flash::vera_bram_ptr#18 [phi:vera_flash::@13->vera_flash::@1#0] -- register_copy 
    // [1654] phi vera_flash::vera_bram_bank#11 = vera_flash::vera_bram_bank#14 [phi:vera_flash::@13->vera_flash::@1#1] -- register_copy 
    // [1654] phi vera_flash::y_sector#14 = vera_flash::y_sector#1 [phi:vera_flash::@13->vera_flash::@1#2] -- register_copy 
    // [1654] phi vera_flash::x_sector#14 = PROGRESS_X [phi:vera_flash::@13->vera_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1654] phi vera_flash::return#2 = vera_flash::vera_address_page#12 [phi:vera_flash::@13->vera_flash::@1#4] -- register_copy 
    jmp __b1
    // vera_flash::@6
  __b6:
    // display_action_text_flashing(VERA_PROGRESS_PAGE, "VERA", vera_bram_bank, vera_bram_ptr, vera_address)
    // [1682] display_action_text_flashing::bram_bank#0 = vera_flash::vera_bram_bank#11 -- vbum1=vbum2 
    lda vera_bram_bank
    sta display_action_text_flashing.bram_bank
    // [1683] display_action_text_flashing::bram_ptr#0 = vera_flash::vera_bram_ptr#13 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1684] display_action_text_flashing::address#0 = vera_flash::vera_address#10 -- vdum1=vdum2 
    lda vera_address
    sta display_action_text_flashing.address
    lda vera_address+1
    sta display_action_text_flashing.address+1
    lda vera_address+2
    sta display_action_text_flashing.address+2
    lda vera_address+3
    sta display_action_text_flashing.address+3
    // [1685] call display_action_text_flashing
    // [2187] phi from vera_flash::@6 to display_action_text_flashing [phi:vera_flash::@6->display_action_text_flashing]
    jsr display_action_text_flashing
    // [1686] phi from vera_flash::@6 to vera_flash::@7 [phi:vera_flash::@6->vera_flash::@7]
    // [1686] phi vera_flash::i#2 = 0 [phi:vera_flash::@6->vera_flash::@7#0] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // vera_flash::@7
  __b7:
    // for(unsigned int i=0; i<=255; i++)
    // [1687] if(vera_flash::i#2<=$ff) goto vera_flash::@8 -- vwum1_le_vbuc1_then_la1 
    lda #$ff
    cmp i
    bcc !+
    lda i+1
    beq __b8
  !:
    // vera_flash::@9
    // cputcxy(x,y,'+')
    // [1688] cputcxy::x#1 = vera_flash::x_sector#14 -- vbum1=vbum2 
    lda x_sector
    sta cputcxy.x
    // [1689] cputcxy::y#1 = vera_flash::y_sector#14 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1690] call cputcxy
    // [1345] phi from vera_flash::@9 to cputcxy [phi:vera_flash::@9->cputcxy]
    // [1345] phi cputcxy::c#15 = '+' [phi:vera_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [1345] phi cputcxy::y#15 = cputcxy::y#1 [phi:vera_flash::@9->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#1 [phi:vera_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // vera_flash::@17
    // cputc('+')
    // [1691] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1692] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_bram_ptr += VERA_PROGRESS_PAGE
    // [1694] vera_flash::vera_bram_ptr#1 = vera_flash::vera_bram_ptr#13 + VERA_PROGRESS_PAGE -- pbuz1=pbuz1_plus_vwuc1 
    lda.z vera_bram_ptr
    clc
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr+1
    // vera_address += VERA_PROGRESS_PAGE
    // [1695] vera_flash::vera_address#1 = vera_flash::vera_address#10 + VERA_PROGRESS_PAGE -- vdum1=vdum1_plus_vwuc1 
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
    // [1696] vera_flash::vera_address_page#1 = vera_flash::vera_address_page#12 + VERA_PROGRESS_PAGE -- vdum1=vdum1_plus_vwuc1 
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
    // [1697] vera_flash::i#1 = ++ vera_flash::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [1686] phi from vera_flash::@8 to vera_flash::@7 [phi:vera_flash::@8->vera_flash::@7]
    // [1686] phi vera_flash::i#2 = vera_flash::i#1 [phi:vera_flash::@8->vera_flash::@7#0] -- register_copy 
    jmp __b7
  .segment DataVera
    info_text: .text "Flashing ... (-) equal, (+) flashed, (!) error."
    .byte 0
    info_text1: .text "Flashing ..."
    .byte 0
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
    // [1699] phi from display_info_roms to display_info_roms::@1 [phi:display_info_roms->display_info_roms::@1]
    // [1699] phi display_info_roms::rom_chip#2 = 0 [phi:display_info_roms->display_info_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // display_info_roms::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [1700] if(display_info_roms::rom_chip#2<8) goto display_info_roms::@2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b2
    // display_info_roms::@return
    // }
    // [1701] return 
    rts
    // display_info_roms::@2
  __b2:
    // display_info_rom(rom_chip, info_status, info_text)
    // [1702] display_info_rom::rom_chip#1 = display_info_roms::rom_chip#2 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1703] call display_info_rom
    // [1066] phi from display_info_roms::@2 to display_info_rom [phi:display_info_roms::@2->display_info_rom]
    // [1066] phi display_info_rom::info_text#10 = display_info_roms::info_text#1 [phi:display_info_roms::@2->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1066] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#1 [phi:display_info_roms::@2->display_info_rom#1] -- register_copy 
    // [1066] phi display_info_rom::info_status#10 = STATUS_ERROR [phi:display_info_roms::@2->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    // display_info_roms::@3
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [1704] display_info_roms::rom_chip#1 = ++ display_info_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1699] phi from display_info_roms::@3 to display_info_roms::@1 [phi:display_info_roms::@3->display_info_roms::@1]
    // [1699] phi display_info_roms::rom_chip#2 = display_info_roms::rom_chip#1 [phi:display_info_roms::@3->display_info_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip: .byte 0
}
.segment CodeVera
  // spi_deselect
spi_deselect: {
    // *vera_reg_SPICtrl &= 0xfe
    // [1705] *vera_reg_SPICtrl = *vera_reg_SPICtrl & $fe -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
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
    // [1706] call spi_read
    jsr spi_read
    // spi_deselect::@return
    // }
    // [1707] return 
    rts
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
    // [1708] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1710] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [1711] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1712] return 
    rts
  .segment Data
    ch: .byte 0
    return: .byte 0
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
    // [1713] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [1714] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [1715] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1715] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1716] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [1717] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1718] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1719] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1720] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1721] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [1722] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [1723] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [1724] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [1725] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [1726] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [1727] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [1728] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1729] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [1715] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1715] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [1730] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [1731] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1732] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1733] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1734] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1735] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1736] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1737] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1738] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1739] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1740] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1740] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1741] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1742] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1743] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1744] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1745] return 
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
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $38
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $4e
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $3b
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [1747] gotoxy::x#9 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [1748] gotoxy::y#9 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [1749] call gotoxy
    // [455] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#9 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#9 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1750] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [1751] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [1752] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [1753] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1754] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1755] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1756] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1757] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbum1=_deref_pbuc1 
    lda VERA_DATA0
    sta c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1758] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$70
    cmp c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1759] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6e
    cmp c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1760] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6d
    cmp c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1761] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$7d
    cmp c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1762] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1763] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$5d
    cmp c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1764] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6b
    cmp c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1765] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$73
    cmp c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1766] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$72
    cmp c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1767] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$71
    cmp c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1768] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbum1_eq_vbuc1_then_la1 
    lda #$5b
    cmp c
    beq __b11
    // [1770] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [1770] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [1769] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [1770] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [1770] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [1770] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [1770] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [1770] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [1770] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [1770] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [1770] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [1770] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [1770] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [1770] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [1770] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [1770] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // display_frame_maskxy::@return
    // }
    // [1771] return 
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
    // [1773] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1774] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1775] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1776] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1777] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1778] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1779] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1780] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1781] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1782] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1783] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [1785] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [1785] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$20
    sta return
    rts
    // [1784] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [1785] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [1785] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5b
    sta return
    rts
    // [1785] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [1785] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$70
    sta return
    rts
    // [1785] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [1785] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6e
    sta return
    rts
    // [1785] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [1785] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6d
    sta return
    rts
    // [1785] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [1785] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$7d
    sta return
    rts
    // [1785] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [1785] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$40
    sta return
    rts
    // [1785] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [1785] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5d
    sta return
    rts
    // [1785] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [1785] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6b
    sta return
    rts
    // [1785] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [1785] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$73
    sta return
    rts
    // [1785] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [1785] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$72
    sta return
    rts
    // [1785] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [1785] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$71
    sta return
    // display_frame_char::@return
    // }
    // [1786] return 
    rts
  .segment Data
    .label return = cputcxy.c
    .label mask = display_frame_maskxy.return
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($2d) char *str)
strlen: {
    .label str = $2d
    // [1788] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1788] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [1788] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1789] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1790] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1791] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [1792] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1788] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1788] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1788] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($2d) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $2d
    // [1794] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1794] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1795] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [1796] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1797] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [1798] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall19
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1800] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1794] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1794] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall19:
    jmp (putc)
  .segment Data
    i: .byte 0
    length: .byte 0
    pad: .byte 0
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
    // [1802] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [1803] call textcolor
    // [437] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [437] phi textcolor::color#21 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1804] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [1805] call bgcolor
    // [442] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [1806] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [1806] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [1806] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [1807] cputcxy::x#11 = display_chip_led::x#4 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1808] call cputcxy
    // [1345] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1345] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [1345] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [1345] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [1809] cputcxy::x#12 = display_chip_led::x#4 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1810] call cputcxy
    // [1345] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1345] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [1345] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [1345] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [1811] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbum1=_inc_vbum1 
    inc x
    // while(--w)
    // [1812] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbum1=_dec_vbum1 
    dec w
    // [1813] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbum1_then_la1 
    lda w
    bne __b1
    // [1814] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [1815] call textcolor
    // [437] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1816] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [1817] call bgcolor
    // [442] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [1818] return 
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
    // [1820] gotoxy::x#11 = display_chip_line::x#16 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1821] gotoxy::y#11 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1822] call gotoxy
    // [455] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [455] phi gotoxy::y#26 = gotoxy::y#11 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [455] phi gotoxy::x#26 = gotoxy::x#11 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1823] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [1824] call textcolor
    // [437] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [437] phi textcolor::color#21 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1825] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [1826] call bgcolor
    // [442] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1827] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1828] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1830] call textcolor
    // [437] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1831] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [1832] call bgcolor
    // [442] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [442] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [1833] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [1833] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1834] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [1835] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [1836] call textcolor
    // [437] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [437] phi textcolor::color#21 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1837] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [1838] call bgcolor
    // [442] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [1839] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1840] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1842] call textcolor
    // [437] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [437] phi textcolor::color#21 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1843] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [1844] call bgcolor
    // [442] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [442] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [1845] cputcxy::x#10 = display_chip_line::x#16 + 2 -- vbum1=vbum2_plus_2 
    lda x
    clc
    adc #2
    sta cputcxy.x
    // [1846] cputcxy::y#10 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1847] cputcxy::c#10 = display_chip_line::c#15 -- vbum1=vbum2 
    lda c
    sta cputcxy.c
    // [1848] call cputcxy
    // [1345] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1345] phi cputcxy::c#15 = cputcxy::c#10 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1345] phi cputcxy::y#15 = cputcxy::y#10 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1345] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [1849] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [1850] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1851] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1853] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1833] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [1833] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
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
    // [1854] gotoxy::x#12 = display_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1855] call gotoxy
    // [455] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [455] phi gotoxy::y#26 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [455] phi gotoxy::x#26 = gotoxy::x#12 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1856] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [1857] call textcolor
    // [437] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [437] phi textcolor::color#21 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1858] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [1859] call bgcolor
    // [442] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [1860] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1861] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1863] call textcolor
    // [437] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [437] phi textcolor::color#21 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [1864] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [1865] call bgcolor
    // [442] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [442] phi bgcolor::color#15 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [1866] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [1866] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1867] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [1868] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [1869] call textcolor
    // [437] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [437] phi textcolor::color#21 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1870] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [1871] call bgcolor
    // [442] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [442] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [1872] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1873] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [1875] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [1876] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1877] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1879] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1866] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [1866] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
// void utoa(__mem() unsigned int value, __zp($36) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $3b
    .label utoa__10 = $38
    .label utoa__11 = $4e
    .label buffer = $36
    .label digit_values = $3c
    // if(radix==DECIMAL)
    // [1880] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1881] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1882] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1883] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1884] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1885] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1886] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1887] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1888] return 
    rts
    // [1889] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1889] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1889] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [1889] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1889] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1889] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [1889] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1889] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1889] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [1889] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1889] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1889] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [1890] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1890] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1890] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1890] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1890] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1891] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1892] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1893] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [1894] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1895] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1896] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1897] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [1898] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1899] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [1900] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [1901] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1901] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1901] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1901] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1902] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1890] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1890] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1890] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1890] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1890] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1903] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1904] utoa_append::value#0 = utoa::value#2
    // [1905] utoa_append::sub#0 = utoa::digit_value#0
    // [1906] call utoa_append
    // [2241] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1907] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1908] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1909] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1901] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1901] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1901] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1901] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .word 0
    digit: .byte 0
    .label value = printf_uint.uvalue
    .label radix = printf_uint.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment CodeVera
  // spi_get_jedec
spi_get_jedec: {
    // spi_fast()
    // [1911] call spi_fast
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
    // [1912] phi from spi_get_jedec to spi_get_jedec::@1 [phi:spi_get_jedec->spi_get_jedec::@1]
    // spi_get_jedec::@1
    // spi_select()
    // [1913] call spi_select
    // [2250] phi from spi_get_jedec::@1 to spi_select [phi:spi_get_jedec::@1->spi_select]
    jsr spi_select
    // spi_get_jedec::@2
    // spi_write(0x9F)
    // [1914] spi_write::data = $9f -- vbum1=vbuc1 
    lda #$9f
    sta spi_write.data
    // [1915] call spi_write
    jsr spi_write
    // [1916] phi from spi_get_jedec::@2 to spi_get_jedec::@3 [phi:spi_get_jedec::@2->spi_get_jedec::@3]
    // spi_get_jedec::@3
    // spi_read()
    // [1917] call spi_read
    jsr spi_read
    // [1918] spi_read::return#0 = spi_read::return#4 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_read.return
    // [1919] phi from spi_get_jedec::@3 to spi_get_jedec::@4 [phi:spi_get_jedec::@3->spi_get_jedec::@4]
    // spi_get_jedec::@4
    // spi_read()
    // [1920] call spi_read
    jsr spi_read
    // [1921] spi_read::return#1 = spi_read::return#4 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_read.return_1
    // [1922] phi from spi_get_jedec::@4 to spi_get_jedec::@5 [phi:spi_get_jedec::@4->spi_get_jedec::@5]
    // spi_get_jedec::@5
    // spi_read()
    // [1923] call spi_read
    jsr spi_read
    // [1924] spi_read::return#2 = spi_read::return#4 -- vbum1=vbum2 
    lda spi_read.return_3
    sta spi_read.return_2
    // spi_get_jedec::@return
    // }
    // [1925] return 
    rts
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
// __zp($40) struct $2 * fopen(__zp($49) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $4e
    .label fopen__9 = $38
    .label fopen__11 = $3e
    .label fopen__15 = $3b
    .label fopen__16 = $59
    .label fopen__26 = $5f
    .label fopen__28 = $51
    .label fopen__30 = $40
    .label cbm_k_setnam1_filename = $78
    .label cbm_k_setnam1_fopen__0 = $3c
    .label stream = $40
    .label pathtoken = $36
    .label path = $49
    .label return = $40
    // unsigned char sp = __stdio_filecount
    // [1926] fopen::sp#0 = __stdio_filecount#105 -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [1927] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1928] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1929] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [1930] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [1931] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [1932] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [1933] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [1934] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1934] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [1934] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1934] phi fopen::path#13 = vera_read::path [phi:fopen->fopen::@8#2] -- pbuz1=pbuc1 
    lda #<vera_read.path
    sta.z path
    lda #>vera_read.path
    sta.z path+1
    // [1934] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    lda #0
    sta pathstep
    // [1934] phi fopen::pathtoken#10 = vera_read::path [phi:fopen->fopen::@8#4] -- pbuz1=pbuc1 
    lda #<vera_read.path
    sta.z pathtoken
    lda #>vera_read.path
    sta.z pathtoken+1
  // Iterate while path is not \0.
    // [1934] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1934] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1934] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1934] phi fopen::path#13 = fopen::path#10 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1934] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1934] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1935] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [1936] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [1937] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1938] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1939] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [1940] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1940] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1940] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1940] phi fopen::path#10 = fopen::path#12 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1940] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1941] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken
    bne !+
    inc.z pathtoken+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1942] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [1943] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [1944] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [1945] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1946] fopen::$4 = __stdio_filecount#105 + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [1947] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1948] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1949] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1950] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1951] fopen::$9 = __stdio_filecount#105 + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1952] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [1953] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [1954] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1955] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1956] call strlen
    // [1787] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1787] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1957] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1958] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [1959] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1961] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [1962] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [1963] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [1964] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [1966] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1968] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [1969] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [1970] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [1971] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [1972] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [1973] call ferror
    jsr ferror
    // [1974] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [1975] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [1976] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [1977] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [1979] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [1979] phi __stdio_filecount#1 = __stdio_filecount#105 [phi:fopen::cbm_k_close1->fopen::@return#0] -- register_copy 
    // [1979] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#1] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [1980] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [1981] __stdio_filecount#0 = ++ __stdio_filecount#105 -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [1982] fopen::return#6 = (struct $2 *)fopen::stream#0
    // [1979] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [1979] phi __stdio_filecount#1 = __stdio_filecount#0 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    // [1979] phi fopen::return#2 = fopen::return#6 [phi:fopen::@4->fopen::@return#1] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [1983] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [1984] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [1985] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    // [1986] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [1986] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [1986] phi fopen::path#12 = fopen::path#15 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [1987] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [1988] fopen::pathcmp#0 = *fopen::path#13 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [1989] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [1990] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [1991] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [1992] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [1992] phi fopen::path#15 = fopen::path#13 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [1992] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [1993] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [1994] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [1995] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [1996] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [1997] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [1998] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [1999] atoi::str#0 = fopen::path#13 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2000] call atoi
    // [2310] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2310] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2001] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2002] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2003] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2004] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
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
  // fclose
/**
 * @brief Close a file.
 *
 * @param fp The FILE pointer.
 * @return
 *  - 0x0000: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - other: OK! The last pointer between 0xA000 and 0xBFFF is returned. Note that the last pointer is indicating the first free byte.
 */
// int fclose(__zp($4f) struct $2 *stream)
fclose: {
    .label fclose__1 = $3b
    .label fclose__4 = $38
    .label fclose__6 = $39
    .label stream = $4f
    // unsigned char sp = (unsigned char)stream
    // [2005] fclose::sp#0 = (char)fclose::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2006] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2007] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2009] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2011] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2012] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2013] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [2014] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2015] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2016] phi from fclose::@2 fclose::@3 fclose::@4 to fclose::@return [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return]
    // [2016] phi __stdio_filecount#2 = __stdio_filecount#3 [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return#0] -- register_copy 
    // fclose::@return
    // }
    // [2017] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2018] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2020] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2022] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2023] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2024] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2025] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2026] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2027] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2028] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2029] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2030] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2031] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2032] __stdio_filecount#3 = -- __stdio_filecount#1 -- vbum1=_dec_vbum1 
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
// void display_action_text_reading(__zp($42) char *action, char *file, __mem() unsigned long bytes, unsigned long size, __mem() char bram_bank, __zp($6c) char *bram_ptr)
display_action_text_reading: {
    .label action = $42
    .label bram_ptr = $6c
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2034] call snprintf_init
    jsr snprintf_init
    // display_action_text_reading::@1
    // [2035] printf_string::str#14 = display_action_text_reading::action#0
    // [2036] call printf_string
    // [1307] phi from display_action_text_reading::@1 to printf_string [phi:display_action_text_reading::@1->printf_string]
    // [1307] phi printf_string::putc#17 = &snputc [phi:display_action_text_reading::@1->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = printf_string::str#14 [phi:display_action_text_reading::@1->printf_string#1] -- register_copy 
    // [1307] phi printf_string::format_justify_left#17 = 0 [phi:display_action_text_reading::@1->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 0 [phi:display_action_text_reading::@1->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2037] phi from display_action_text_reading::@1 to display_action_text_reading::@2 [phi:display_action_text_reading::@1->display_action_text_reading::@2]
    // display_action_text_reading::@2
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2038] call printf_str
    // [783] phi from display_action_text_reading::@2 to printf_str [phi:display_action_text_reading::@2->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_reading::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s [phi:display_action_text_reading::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [2039] phi from display_action_text_reading::@2 to display_action_text_reading::@3 [phi:display_action_text_reading::@2->display_action_text_reading::@3]
    // display_action_text_reading::@3
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2040] call printf_string
    // [1307] phi from display_action_text_reading::@3 to printf_string [phi:display_action_text_reading::@3->printf_string]
    // [1307] phi printf_string::putc#17 = &snputc [phi:display_action_text_reading::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = vera_read::path [phi:display_action_text_reading::@3->printf_string#1] -- pbuz1=pbuc1 
    lda #<vera_read.path
    sta.z printf_string.str
    lda #>vera_read.path
    sta.z printf_string.str+1
    // [1307] phi printf_string::format_justify_left#17 = 0 [phi:display_action_text_reading::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 0 [phi:display_action_text_reading::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2041] phi from display_action_text_reading::@3 to display_action_text_reading::@4 [phi:display_action_text_reading::@3->display_action_text_reading::@4]
    // display_action_text_reading::@4
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2042] call printf_str
    // [783] phi from display_action_text_reading::@4 to printf_str [phi:display_action_text_reading::@4->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_reading::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s2 [phi:display_action_text_reading::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@5
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2043] printf_ulong::uvalue#5 = display_action_text_reading::bytes#0
    // [2044] call printf_ulong
    // [1632] phi from display_action_text_reading::@5 to printf_ulong [phi:display_action_text_reading::@5->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_reading::@5->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_reading::@5->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@5->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#5 [phi:display_action_text_reading::@5->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2045] phi from display_action_text_reading::@5 to display_action_text_reading::@6 [phi:display_action_text_reading::@5->display_action_text_reading::@6]
    // display_action_text_reading::@6
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2046] call printf_str
    // [783] phi from display_action_text_reading::@6 to printf_str [phi:display_action_text_reading::@6->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_reading::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_action_text_reading::s2 [phi:display_action_text_reading::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [2047] phi from display_action_text_reading::@6 to display_action_text_reading::@7 [phi:display_action_text_reading::@6->display_action_text_reading::@7]
    // display_action_text_reading::@7
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2048] call printf_ulong
    // [1632] phi from display_action_text_reading::@7 to printf_ulong [phi:display_action_text_reading::@7->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_reading::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_reading::@7->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@7->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = vera_size [phi:display_action_text_reading::@7->printf_ulong#3] -- vdum1=vduc1 
    lda #<vera_size
    sta printf_ulong.uvalue
    lda #>vera_size
    sta printf_ulong.uvalue+1
    lda #<vera_size>>$10
    sta printf_ulong.uvalue+2
    lda #>vera_size>>$10
    sta printf_ulong.uvalue+3
    jsr printf_ulong
    // [2049] phi from display_action_text_reading::@7 to display_action_text_reading::@8 [phi:display_action_text_reading::@7->display_action_text_reading::@8]
    // display_action_text_reading::@8
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2050] call printf_str
    // [783] phi from display_action_text_reading::@8 to printf_str [phi:display_action_text_reading::@8->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_reading::@8->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_action_text_reading::s3 [phi:display_action_text_reading::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@9
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2051] printf_uchar::uvalue#6 = display_action_text_reading::bram_bank#0
    // [2052] call printf_uchar
    // [832] phi from display_action_text_reading::@9 to printf_uchar [phi:display_action_text_reading::@9->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 1 [phi:display_action_text_reading::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 2 [phi:display_action_text_reading::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &snputc [phi:display_action_text_reading::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:display_action_text_reading::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2053] phi from display_action_text_reading::@9 to display_action_text_reading::@10 [phi:display_action_text_reading::@9->display_action_text_reading::@10]
    // display_action_text_reading::@10
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2054] call printf_str
    // [783] phi from display_action_text_reading::@10 to printf_str [phi:display_action_text_reading::@10->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_reading::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s2 [phi:display_action_text_reading::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@11
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2055] printf_uint::uvalue#3 = (unsigned int)display_action_text_reading::bram_ptr#0 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2056] call printf_uint
    // [1432] phi from display_action_text_reading::@11 to printf_uint [phi:display_action_text_reading::@11->printf_uint]
    // [1432] phi printf_uint::format_zero_padding#4 = 1 [phi:display_action_text_reading::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1432] phi printf_uint::format_min_length#4 = 4 [phi:display_action_text_reading::@11->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1432] phi printf_uint::putc#4 = &snputc [phi:display_action_text_reading::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1432] phi printf_uint::format_radix#4 = HEXADECIMAL [phi:display_action_text_reading::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1432] phi printf_uint::uvalue#4 = printf_uint::uvalue#3 [phi:display_action_text_reading::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2057] phi from display_action_text_reading::@11 to display_action_text_reading::@12 [phi:display_action_text_reading::@11->display_action_text_reading::@12]
    // display_action_text_reading::@12
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2058] call printf_str
    // [783] phi from display_action_text_reading::@12 to printf_str [phi:display_action_text_reading::@12->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_reading::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_action_text_reading::s5 [phi:display_action_text_reading::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@13
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2059] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2060] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2062] call display_action_text
    // [843] phi from display_action_text_reading::@13 to display_action_text [phi:display_action_text_reading::@13->display_action_text]
    // [843] phi display_action_text::info_text#17 = info_text [phi:display_action_text_reading::@13->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_reading::@return
    // }
    // [2063] return 
    rts
  .segment Data
    s2: .text "/"
    .byte 0
    s3: .text " -> RAM:"
    .byte 0
    s5: .text " ..."
    .byte 0
    .label bytes = printf_ulong.uvalue
    .label bram_bank = printf_uchar.uvalue
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
// __mem() unsigned int fgets(__zp($49) char *ptr, unsigned int size, __zp($4b) struct $2 *stream)
fgets: {
    .label fgets__1 = $38
    .label fgets__8 = $39
    .label fgets__9 = $3a
    .label fgets__13 = $4d
    .label ptr = $49
    .label stream = $4b
    // unsigned char sp = (unsigned char)stream
    // [2064] fgets::sp#0 = (char)fgets::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2065] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2066] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2068] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2070] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2071] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@9
    // cbm_k_readst()
    // [2072] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2073] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2074] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b8
    // [2075] phi from fgets::@10 fgets::@3 fgets::@9 to fgets::@return [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return]
  __b1:
    // [2075] phi fgets::return#1 = 0 [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2076] return 
    rts
    // [2077] phi from fgets::@13 to fgets::@1 [phi:fgets::@13->fgets::@1]
    // [2077] phi fgets::read#10 = fgets::read#1 [phi:fgets::@13->fgets::@1#0] -- register_copy 
    // [2077] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@13->fgets::@1#1] -- register_copy 
    // [2077] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@13->fgets::@1#2] -- register_copy 
    // [2077] phi from fgets::@9 to fgets::@1 [phi:fgets::@9->fgets::@1]
  __b8:
    // [2077] phi fgets::read#10 = 0 [phi:fgets::@9->fgets::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2077] phi fgets::remaining#11 = VERA_PROGRESS_CELL [phi:fgets::@9->fgets::@1#1] -- vwum1=vbuc1 
    lda #<VERA_PROGRESS_CELL
    sta remaining
    lda #>VERA_PROGRESS_CELL
    sta remaining+1
    // [2077] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@9->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@6
  __b6:
    // if (remaining >= 512)
    // [2078] if(fgets::remaining#11>=$200) goto fgets::@2 -- vwum1_ge_vwuc1_then_la1 
    lda remaining+1
    cmp #>$200
    bcc !+
    beq !__b2+
    jmp __b2
  !__b2:
    lda remaining
    cmp #<$200
    bcc !__b2+
    jmp __b2
  !__b2:
  !:
    // fgets::@7
    // cx16_k_macptr(remaining, ptr)
    // [2079] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2080] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2081] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2082] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@12
  __b12:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2083] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2084] phi from fgets::@11 fgets::@12 to fgets::cbm_k_readst2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2]
    // [2084] phi fgets::bytes#10 = fgets::bytes#2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2085] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2087] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2088] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@10
    // cbm_k_readst()
    // [2089] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2090] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2091] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2092] if(0==fgets::$9) goto fgets::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    jmp __b1
    // fgets::@3
  __b3:
    // if (bytes == 0xFFFF)
    // [2093] if(fgets::bytes#10!=$ffff) goto fgets::@4 -- vwum1_neq_vwuc1_then_la1 
    lda bytes+1
    cmp #>$ffff
    bne __b4
    lda bytes
    cmp #<$ffff
    bne __b4
    jmp __b1
    // fgets::@4
  __b4:
    // read += bytes
    // [2094] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2095] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2096] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2097] if(fgets::$13!=$c0) goto fgets::@5 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b5
    // fgets::@8
    // ptr -= 0x2000
    // [2098] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2099] phi from fgets::@4 fgets::@8 to fgets::@5 [phi:fgets::@4/fgets::@8->fgets::@5]
    // [2099] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@4/fgets::@8->fgets::@5#0] -- register_copy 
    // fgets::@5
  __b5:
    // remaining -= bytes
    // [2100] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2101] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@13 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b13
    // [2075] phi from fgets::@13 fgets::@5 to fgets::@return [phi:fgets::@13/fgets::@5->fgets::@return]
    // [2075] phi fgets::return#1 = fgets::read#1 [phi:fgets::@13/fgets::@5->fgets::@return#0] -- register_copy 
    rts
    // fgets::@13
  __b13:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2102] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b6+
    jmp __b6
  !__b6:
    rts
    // fgets::@2
  __b2:
    // cx16_k_macptr(512, ptr)
    // [2103] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2104] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2105] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2106] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@11
    // bytes = cx16_k_macptr(512, ptr)
    // [2107] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b12
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
// __mem() char uctoa_append(__zp($45) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $45
    // [2109] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2109] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2109] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2110] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2111] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2112] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2113] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2114] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [2109] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2109] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2109] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uchar.uvalue
    .label sub = uctoa.digit_value
    .label return = printf_uchar.uvalue
    digit: .byte 0
}
.segment CodeVera
  // spi_read_flash
// void spi_read_flash(unsigned long spi_data)
spi_read_flash: {
    // spi_select()
    // [2116] call spi_select
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
    // [2250] phi from spi_read_flash to spi_select [phi:spi_read_flash->spi_select]
    jsr spi_select
    // spi_read_flash::@1
    // spi_write(0x03)
    // [2117] spi_write::data = 3 -- vbum1=vbuc1 
    lda #3
    sta spi_write.data
    // [2118] call spi_write
    jsr spi_write
    // spi_read_flash::@2
    // spi_write(BYTE2(spi_data))
    // [2119] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [2120] call spi_write
    jsr spi_write
    // spi_read_flash::@3
    // spi_write(BYTE1(spi_data))
    // [2121] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [2122] call spi_write
    jsr spi_write
    // spi_read_flash::@4
    // spi_write(BYTE0(spi_data))
    // [2123] spi_write::data = 0 -- vbum1=vbuc1 
    lda #0
    sta spi_write.data
    // [2124] call spi_write
    jsr spi_write
    // spi_read_flash::@return
    // }
    // [2125] return 
    rts
}
  // vera_compare
// __mem() unsigned int vera_compare(__mem() char bank_ram, __zp($5b) char *bram_ptr, unsigned int vera_compare_size)
vera_compare: {
    .label bram_ptr = $5b
    // vera_compare::bank_set_bram1
    // BRAM = bank
    // [2127] BRAM = vera_compare::bank_ram#0 -- vbuz1=vbum2 
    lda bank_ram
    sta.z BRAM
    // [2128] phi from vera_compare::bank_set_bram1 to vera_compare::@1 [phi:vera_compare::bank_set_bram1->vera_compare::@1]
    // [2128] phi vera_compare::bram_ptr#2 = vera_compare::bram_ptr#0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#0] -- register_copy 
    // [2128] phi vera_compare::equal_bytes#2 = 0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [2128] phi vera_compare::compared_bytes#2 = 0 [phi:vera_compare::bank_set_bram1->vera_compare::@1#2] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // vera_compare::@1
  __b1:
    // while (compared_bytes < vera_compare_size)
    // [2129] if(vera_compare::compared_bytes#2<VERA_PROGRESS_CELL) goto vera_compare::@2 -- vwum1_lt_vbuc1_then_la1 
    lda compared_bytes+1
    bne !+
    lda compared_bytes
    cmp #VERA_PROGRESS_CELL
    bcc __b2
  !:
    // vera_compare::@return
    // }
    // [2130] return 
    rts
    // [2131] phi from vera_compare::@1 to vera_compare::@2 [phi:vera_compare::@1->vera_compare::@2]
    // vera_compare::@2
  __b2:
    // unsigned char vera_byte = spi_read()
    // [2132] call spi_read
    jsr spi_read
    // [2133] spi_read::return#12 = spi_read::return#4
    // vera_compare::@5
    // [2134] vera_compare::vera_byte#0 = spi_read::return#12
    // if (vera_byte == *bram_ptr)
    // [2135] if(vera_compare::vera_byte#0!=*vera_compare::bram_ptr#2) goto vera_compare::@3 -- vbum1_neq__deref_pbuz2_then_la1 
    ldy #0
    lda (bram_ptr),y
    cmp vera_byte
    bne __b3
    // vera_compare::@4
    // equal_bytes++;
    // [2136] vera_compare::equal_bytes#1 = ++ vera_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [2137] phi from vera_compare::@4 vera_compare::@5 to vera_compare::@3 [phi:vera_compare::@4/vera_compare::@5->vera_compare::@3]
    // [2137] phi vera_compare::equal_bytes#6 = vera_compare::equal_bytes#1 [phi:vera_compare::@4/vera_compare::@5->vera_compare::@3#0] -- register_copy 
    // vera_compare::@3
  __b3:
    // bram_ptr++;
    // [2138] vera_compare::bram_ptr#1 = ++ vera_compare::bram_ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z bram_ptr
    bne !+
    inc.z bram_ptr+1
  !:
    // compared_bytes++;
    // [2139] vera_compare::compared_bytes#1 = ++ vera_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [2128] phi from vera_compare::@3 to vera_compare::@1 [phi:vera_compare::@3->vera_compare::@1]
    // [2128] phi vera_compare::bram_ptr#2 = vera_compare::bram_ptr#1 [phi:vera_compare::@3->vera_compare::@1#0] -- register_copy 
    // [2128] phi vera_compare::equal_bytes#2 = vera_compare::equal_bytes#6 [phi:vera_compare::@3->vera_compare::@1#1] -- register_copy 
    // [2128] phi vera_compare::compared_bytes#2 = vera_compare::compared_bytes#1 [phi:vera_compare::@3->vera_compare::@1#2] -- register_copy 
    jmp __b1
  .segment DataVera
    bank_ram: .byte 0
    .label return = equal_bytes
    .label vera_byte = spi_read.return_3
    compared_bytes: .word 0
    /// Holds the amount of bytes actually verified between the VERA and the RAM.
    equal_bytes: .word 0
}
.segment Code
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__mem() unsigned long value, __zp($34) char *buffer, __mem() char radix)
ultoa: {
    .label ultoa__4 = $3a
    .label ultoa__10 = $39
    .label ultoa__11 = $4d
    .label buffer = $34
    .label digit_values = $40
    // if(radix==DECIMAL)
    // [2140] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2141] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2142] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2143] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2144] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2145] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2146] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2147] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2148] return 
    rts
    // [2149] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2149] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2149] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2149] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2149] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2149] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2149] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2149] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2149] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2149] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2149] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2149] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2150] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2150] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2150] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2150] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2150] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2151] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2152] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2153] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2154] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2155] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2156] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2157] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2158] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2159] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2160] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2161] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2161] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2161] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2161] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2162] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2150] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2150] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2150] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2150] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2150] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2163] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2164] ultoa_append::value#0 = ultoa::value#2
    // [2165] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2166] call ultoa_append
    // [2331] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2167] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2168] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2169] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2161] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2161] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2161] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2161] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
// void display_action_text_flashed(__mem() unsigned long bytes, char *chip)
display_action_text_flashed: {
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2171] call snprintf_init
    jsr snprintf_init
    // [2172] phi from display_action_text_flashed to display_action_text_flashed::@1 [phi:display_action_text_flashed->display_action_text_flashed::@1]
    // display_action_text_flashed::@1
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2173] call printf_str
    // [783] phi from display_action_text_flashed::@1 to printf_str [phi:display_action_text_flashed::@1->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashed::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_action_text_flashed::s [phi:display_action_text_flashed::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@2
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2174] printf_ulong::uvalue#4 = display_action_text_flashed::bytes#0 -- vdum1=vdum2 
    lda bytes
    sta printf_ulong.uvalue
    lda bytes+1
    sta printf_ulong.uvalue+1
    lda bytes+2
    sta printf_ulong.uvalue+2
    lda bytes+3
    sta printf_ulong.uvalue+3
    // [2175] call printf_ulong
    // [1632] phi from display_action_text_flashed::@2 to printf_ulong [phi:display_action_text_flashed::@2->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 0 [phi:display_action_text_flashed::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 0 [phi:display_action_text_flashed::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = DECIMAL [phi:display_action_text_flashed::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#4 [phi:display_action_text_flashed::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2176] phi from display_action_text_flashed::@2 to display_action_text_flashed::@3 [phi:display_action_text_flashed::@2->display_action_text_flashed::@3]
    // display_action_text_flashed::@3
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2177] call printf_str
    // [783] phi from display_action_text_flashed::@3 to printf_str [phi:display_action_text_flashed::@3->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashed::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_action_text_flashed::s1 [phi:display_action_text_flashed::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [2178] phi from display_action_text_flashed::@3 to display_action_text_flashed::@4 [phi:display_action_text_flashed::@3->display_action_text_flashed::@4]
    // display_action_text_flashed::@4
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2179] call printf_string
    // [1307] phi from display_action_text_flashed::@4 to printf_string [phi:display_action_text_flashed::@4->printf_string]
    // [1307] phi printf_string::putc#17 = &snputc [phi:display_action_text_flashed::@4->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = vera_flash::chip [phi:display_action_text_flashed::@4->printf_string#1] -- pbuz1=pbuc1 
    lda #<vera_flash.chip
    sta.z printf_string.str
    lda #>vera_flash.chip
    sta.z printf_string.str+1
    // [1307] phi printf_string::format_justify_left#17 = 0 [phi:display_action_text_flashed::@4->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 0 [phi:display_action_text_flashed::@4->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2180] phi from display_action_text_flashed::@4 to display_action_text_flashed::@5 [phi:display_action_text_flashed::@4->display_action_text_flashed::@5]
    // display_action_text_flashed::@5
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2181] call printf_str
    // [783] phi from display_action_text_flashed::@5 to printf_str [phi:display_action_text_flashed::@5->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashed::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s5 [phi:display_action_text_flashed::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@6
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2182] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2183] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2185] call display_action_text
    // [843] phi from display_action_text_flashed::@6 to display_action_text [phi:display_action_text_flashed::@6->display_action_text]
    // [843] phi display_action_text::info_text#17 = info_text [phi:display_action_text_flashed::@6->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashed::@return
    // }
    // [2186] return 
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
// void display_action_text_flashing(unsigned long bytes, char *chip, __mem() char bram_bank, __zp($51) char *bram_ptr, __mem() unsigned long address)
display_action_text_flashing: {
    .label bram_ptr = $51
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2188] call snprintf_init
    jsr snprintf_init
    // [2189] phi from display_action_text_flashing to display_action_text_flashing::@1 [phi:display_action_text_flashing->display_action_text_flashing::@1]
    // display_action_text_flashing::@1
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2190] call printf_str
    // [783] phi from display_action_text_flashing::@1 to printf_str [phi:display_action_text_flashing::@1->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashing::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_action_text_flashing::s [phi:display_action_text_flashing::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [2191] phi from display_action_text_flashing::@1 to display_action_text_flashing::@2 [phi:display_action_text_flashing::@1->display_action_text_flashing::@2]
    // display_action_text_flashing::@2
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2192] call printf_ulong
    // [1632] phi from display_action_text_flashing::@2 to printf_ulong [phi:display_action_text_flashing::@2->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 0 [phi:display_action_text_flashing::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 0 [phi:display_action_text_flashing::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = DECIMAL [phi:display_action_text_flashing::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = VERA_PROGRESS_PAGE [phi:display_action_text_flashing::@2->printf_ulong#3] -- vdum1=vduc1 
    lda #<VERA_PROGRESS_PAGE
    sta printf_ulong.uvalue
    lda #>VERA_PROGRESS_PAGE
    sta printf_ulong.uvalue+1
    lda #<VERA_PROGRESS_PAGE>>$10
    sta printf_ulong.uvalue+2
    lda #>VERA_PROGRESS_PAGE>>$10
    sta printf_ulong.uvalue+3
    jsr printf_ulong
    // [2193] phi from display_action_text_flashing::@2 to display_action_text_flashing::@3 [phi:display_action_text_flashing::@2->display_action_text_flashing::@3]
    // display_action_text_flashing::@3
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2194] call printf_str
    // [783] phi from display_action_text_flashing::@3 to printf_str [phi:display_action_text_flashing::@3->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashing::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_action_text_flashing::s1 [phi:display_action_text_flashing::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@4
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2195] printf_uchar::uvalue#5 = display_action_text_flashing::bram_bank#0 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [2196] call printf_uchar
    // [832] phi from display_action_text_flashing::@4 to printf_uchar [phi:display_action_text_flashing::@4->printf_uchar]
    // [832] phi printf_uchar::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@4->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [832] phi printf_uchar::format_min_length#10 = 2 [phi:display_action_text_flashing::@4->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [832] phi printf_uchar::putc#10 = &snputc [phi:display_action_text_flashing::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [832] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@4->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [832] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:display_action_text_flashing::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2197] phi from display_action_text_flashing::@4 to display_action_text_flashing::@5 [phi:display_action_text_flashing::@4->display_action_text_flashing::@5]
    // display_action_text_flashing::@5
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2198] call printf_str
    // [783] phi from display_action_text_flashing::@5 to printf_str [phi:display_action_text_flashing::@5->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashing::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s2 [phi:display_action_text_flashing::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@6
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2199] printf_uint::uvalue#2 = (unsigned int)display_action_text_flashing::bram_ptr#0 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2200] call printf_uint
    // [1432] phi from display_action_text_flashing::@6 to printf_uint [phi:display_action_text_flashing::@6->printf_uint]
    // [1432] phi printf_uint::format_zero_padding#4 = 1 [phi:display_action_text_flashing::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1432] phi printf_uint::format_min_length#4 = 4 [phi:display_action_text_flashing::@6->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1432] phi printf_uint::putc#4 = &snputc [phi:display_action_text_flashing::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1432] phi printf_uint::format_radix#4 = HEXADECIMAL [phi:display_action_text_flashing::@6->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1432] phi printf_uint::uvalue#4 = printf_uint::uvalue#2 [phi:display_action_text_flashing::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2201] phi from display_action_text_flashing::@6 to display_action_text_flashing::@7 [phi:display_action_text_flashing::@6->display_action_text_flashing::@7]
    // display_action_text_flashing::@7
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2202] call printf_str
    // [783] phi from display_action_text_flashing::@7 to printf_str [phi:display_action_text_flashing::@7->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashing::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = display_action_text_flashing::s3 [phi:display_action_text_flashing::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // [2203] phi from display_action_text_flashing::@7 to display_action_text_flashing::@8 [phi:display_action_text_flashing::@7->display_action_text_flashing::@8]
    // display_action_text_flashing::@8
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2204] call printf_string
    // [1307] phi from display_action_text_flashing::@8 to printf_string [phi:display_action_text_flashing::@8->printf_string]
    // [1307] phi printf_string::putc#17 = &snputc [phi:display_action_text_flashing::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1307] phi printf_string::str#17 = vera_flash::chip [phi:display_action_text_flashing::@8->printf_string#1] -- pbuz1=pbuc1 
    lda #<vera_flash.chip
    sta.z printf_string.str
    lda #>vera_flash.chip
    sta.z printf_string.str+1
    // [1307] phi printf_string::format_justify_left#17 = 0 [phi:display_action_text_flashing::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1307] phi printf_string::format_min_length#17 = 0 [phi:display_action_text_flashing::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2205] phi from display_action_text_flashing::@8 to display_action_text_flashing::@9 [phi:display_action_text_flashing::@8->display_action_text_flashing::@9]
    // display_action_text_flashing::@9
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2206] call printf_str
    // [783] phi from display_action_text_flashing::@9 to printf_str [phi:display_action_text_flashing::@9->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashing::@9->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s2 [phi:display_action_text_flashing::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@10
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2207] printf_ulong::uvalue#3 = display_action_text_flashing::address#0 -- vdum1=vdum2 
    lda address
    sta printf_ulong.uvalue
    lda address+1
    sta printf_ulong.uvalue+1
    lda address+2
    sta printf_ulong.uvalue+2
    lda address+3
    sta printf_ulong.uvalue+3
    // [2208] call printf_ulong
    // [1632] phi from display_action_text_flashing::@10 to printf_ulong [phi:display_action_text_flashing::@10->printf_ulong]
    // [1632] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@10->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1632] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_flashing::@10->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1632] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@10->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1632] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#3 [phi:display_action_text_flashing::@10->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2209] phi from display_action_text_flashing::@10 to display_action_text_flashing::@11 [phi:display_action_text_flashing::@10->display_action_text_flashing::@11]
    // display_action_text_flashing::@11
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2210] call printf_str
    // [783] phi from display_action_text_flashing::@11 to printf_str [phi:display_action_text_flashing::@11->printf_str]
    // [783] phi printf_str::putc#53 = &snputc [phi:display_action_text_flashing::@11->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [783] phi printf_str::s#53 = s5 [phi:display_action_text_flashing::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@12
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2211] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2212] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2214] call display_action_text
    // [843] phi from display_action_text_flashing::@12 to display_action_text [phi:display_action_text_flashing::@12->display_action_text]
    // [843] phi display_action_text::info_text#17 = info_text [phi:display_action_text_flashing::@12->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashing::@return
    // }
    // [2215] return 
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
}
.segment CodeVera
  // spi_read
spi_read: {
    // unsigned char SPIData
    // [2216] spi_read::SPIData = 0 -- vbum1=vbuc1 
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
    // [2218] spi_read::return#3 = spi_read::SPIData -- vbum1=vbum2 
    sta return_3
    // spi_read::@return
    // }
    // [2219] spi_read::return#4 = spi_read::return#3
    // [2220] return 
    rts
  .segment DataVera
    SPIData: .byte 0
    return: .byte 0
    return_1: .byte 0
    return_2: .byte 0
    return_3: .byte 0
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
    // [2221] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2222] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2223] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2224] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2225] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2226] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2227] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2228] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2229] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2230] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2231] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2232] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2233] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2234] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2235] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2235] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2236] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [2237] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2238] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2239] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2240] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
    // [2242] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2242] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2242] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2243] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [2244] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2245] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2246] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2247] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [2242] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2242] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2242] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uint.uvalue
    .label sub = utoa.digit_value
    .label return = printf_uint.uvalue
    digit: .byte 0
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
    // [2249] return 
    rts
}
  // spi_select
spi_select: {
    // spi_deselect()
    // [2251] call spi_deselect
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
    // [2252] *vera_reg_SPICtrl = *vera_reg_SPICtrl | 1 -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #1
    ora vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // spi_select::@return
    // }
    // [2253] return 
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
    // [2255] return 
    rts
  .segment DataVera
    data: .byte 0
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
    // [2257] return 
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
// __mem() int ferror(__zp($40) struct $2 *stream)
ferror: {
    .label ferror__6 = $39
    .label ferror__15 = $3a
    .label cbm_k_setnam1_filename = $72
    .label cbm_k_setnam1_ferror__0 = $6c
    .label stream = $40
    .label errno_len = $63
    // unsigned char sp = (unsigned char)stream
    // [2258] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [2259] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2260] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2261] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2262] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2263] ferror::cbm_k_setnam1_filename = str -- pbuz1=pbuc1 
    lda #<str
    sta.z cbm_k_setnam1_filename
    lda #>str
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2264] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2265] call strlen
    // [1787] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1787] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2266] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2267] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [2268] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2271] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2272] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2274] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2276] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2277] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2278] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2279] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2279] phi __errno#18 = __errno#118 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2279] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2279] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2279] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2280] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2282] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2283] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2284] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [2285] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [2286] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [2287] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2288] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2290] ferror::return#1 = __errno#18 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2291] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2292] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2293] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2294] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2295] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [2296] call strncpy
    // [2338] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [2297] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2298] call atoi
    // [2310] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2310] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2299] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2300] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [2301] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2301] phi __errno#116 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2301] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2302] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2303] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2304] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2306] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2307] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2308] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [2309] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [2279] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2279] phi __errno#18 = __errno#116 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2279] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2279] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2279] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
// __mem() int atoi(__zp($49) const char *str)
atoi: {
    .label atoi__6 = $4b
    .label atoi__7 = $4b
    .label str = $49
    .label atoi__10 = $4b
    .label atoi__11 = $4b
    // if (str[i] == '-')
    // [2311] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2312] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2313] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2313] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [2313] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [2313] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [2313] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2313] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [2313] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [2313] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2314] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2315] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2316] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [2318] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2318] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2317] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [2319] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2320] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2321] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [2322] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2323] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2324] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2325] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [2313] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2313] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2313] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2313] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($56) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $56
    // unsigned int bytes_read
    // [2326] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [2328] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [2329] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2330] return 
    rts
  .segment Data
    bytes: .byte 0
    bytes_read: .word 0
    .label return = fgets.bytes
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
// __mem() unsigned long ultoa_append(__zp($3c) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $3c
    // [2332] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2332] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2332] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2333] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [2334] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2335] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2336] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2337] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [2332] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2332] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2332] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_ulong.uvalue
    .label sub = ultoa.digit_value
    .label return = printf_ulong.uvalue
    digit: .byte 0
}
.segment Code
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($4f) char *dst, __zp($34) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $4f
    .label src = $34
    // [2339] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2339] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [2339] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [2339] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2340] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [2341] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2342] strncpy::c#0 = *strncpy::src#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [2343] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [2344] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2345] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2345] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2346] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2347] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2348] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [2339] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2339] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2339] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2339] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
    i: .word 0
    n: .word 0
}
  // File Data
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
  display_smc_rom_issue_text: .word __50, str, __60, __53, str, __55, __56, __57
  display_smc_unsupported_rom_text: .word __58, str, __60, __61, str, __63, __64
  display_debriefing_text_smc: .word __79, str, main.text, str, __69, __70, __71, str, __73, str, __75, __76, __77, __78
  display_debriefing_text_rom: .word __79, str, __81, __82
  smc_file_header: .fill $20, 0
  smc_version_text: .fill $10, 0
  rom_device_names: .word 0
  .fill 2*7, 0
  rom_size_strings: .word 0
  .fill 2*7, 0
  rom_release_text: .fill 8*$d, 0
  rom_release: .fill 8, 0
  status_rom: .byte 0
  .fill 7, 0
  info_text: .fill $50, 0
  status_text: .word __83, __84, __85, vera_read.vera_action_text_2, vera_read.vera_action_text_1, __88, __89, __90, __91, __92, __93, __94
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
  __50: .text "There is an issue with the CX16 SMC or ROM flash readiness."
  .byte 0
  __53: .text "to avoid possible conflicts of firmware, bricking your CX16."
  .byte 0
  __55: .text "Therefore, ensure you have the correct SMC.BIN and ROM.BIN"
  .byte 0
  __56: .text "files placed on your SDcard. Also ensure that the"
  .byte 0
  __57: .text "J1 jumper pins on the CX16 board are closed."
  .byte 0
  __58: .text "There is an issue with the CX16 SMC or ROM flash versions."
  .byte 0
  __60: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __61: .text "to avoid possible conflicts, risking bricking your CX16."
  .byte 0
  __63: .text "The SMC.BIN and ROM.BIN found on your SDCard may not be"
  .byte 0
  __64: .text "mutually compatible. Update the CX16 at your own risk!"
  .byte 0
  __69: .text "Because your SMC chipset has been updated,"
  .byte 0
  __70: .text "the restart process differs, depending on the"
  .byte 0
  __71: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __73: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __75: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __76: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __77: .text "  The power-off button won't work!"
  .byte 0
  __78: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __79: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __81: .text "Since your CX16 system SMC chip has not been updated"
  .byte 0
  __82: .text "your CX16 will just reset automatically after count down."
  .byte 0
  __83: .text "None"
  .byte 0
  __84: .text "Skip"
  .byte 0
  __85: .text "Detected"
  .byte 0
  __88: .text "Comparing"
  .byte 0
  __89: .text "Update"
  .byte 0
  __90: .text "Updating"
  .byte 0
  __91: .text "Updated"
  .byte 0
  __92: .text "Issue"
  .byte 0
  __93: .text "Error"
  .byte 0
  __94: .text "Waiting"
  .byte 0
  s2: .text ":"
  .byte 0
  s: .text " "
  .byte 0
  s5: .text " ... "
  .byte 0
.segment DataVera
  str: .text ""
  .byte 0
.segment Data
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
  status_vera: .byte 0
.segment DataVera
  spi_manufacturer: .byte 0
  spi_memory_type: .byte 0
  spi_memory_capacity: .byte 0
