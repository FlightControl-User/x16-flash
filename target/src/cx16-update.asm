  // File Comments
/**
 * @file cx16-w25q16.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
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
.segmentdef Data                    [startAfter="Code",max=$7800]
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
  .const display_intro_briefing_count = $f
  .const display_intro_colors_count = $10
  .const display_jp1_spi_vera_count = $10
  .const display_smc_rom_issue_count = 8
  .const display_smc_unsupported_rom_count = 7
  .const display_debriefing_smc_count = $e
  .const display_debriefing_count_rom = 6
  .const vera_size = $20000
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
  .label __snprintf_buffer = $b1
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
    .label conio_x16_init__5 = $6f
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [439] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [444] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [457] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label cputc__2 = $42
    .label cputc__3 = $43
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
    .label main__35 = $be
    .label main__44 = $aa
    .label main__53 = $77
    .label main__66 = $4f
    .label main__118 = $ee
    .label main__123 = $5a
    .label main__156 = $77
    .label main__161 = $77
    .label check_status_smc1_main__0 = $b3
    .label check_status_cx16_rom1_check_status_rom1_main__0 = $ec
    .label check_status_smc2_main__0 = $f8
    .label check_status_cx16_rom2_check_status_rom1_main__0 = $ed
    .label check_status_smc3_main__0 = $e9
    .label check_status_cx16_rom3_check_status_rom1_main__0 = $79
    .label check_status_smc4_main__0 = $a9
    .label check_status_cx16_rom4_check_status_rom1_main__0 = $ab
    .label check_status_cx16_rom5_check_status_rom1_main__0 = $b4
    .label check_status_smc6_main__0 = $b0
    .label check_status_vera1_main__0 = $7a
    .label check_status_smc7_main__0 = $7f
    .label check_status_vera2_main__0 = $f7
    .label check_status_vera3_main__0 = $54
    .label check_status_vera4_main__0 = $74
    .label check_status_smc8_main__0 = $6c
    .label check_status_vera5_main__0 = $ad
    .label check_status_smc9_main__0 = $53
    .label check_status_smc10_main__0 = $7e
    .label check_status_vera6_main__0 = $d8
    .label check_status_vera7_main__0 = $68
    .label check_status_smc11_main__0 = $76
    .label check_status_vera8_main__0 = $5c
    .label check_status_smc12_main__0 = $5d
    .label check_status_smc13_main__0 = $c2
    .label check_status_smc1_return = $b3
    .label check_status_cx16_rom1_check_status_rom1_return = $ec
    .label check_status_smc2_return = $f8
    .label check_status_cx16_rom2_check_status_rom1_return = $ed
    .label ch = $6a
    .label ch2 = $66
    .label check_status_smc3_return = $e9
    .label check_status_cx16_rom3_check_status_rom1_return = $79
    .label ch1 = $ba
    .label check_status_smc4_return = $a9
    .label check_status_cx16_rom4_check_status_rom1_return = $ab
    .label ch3 = $63
    .label check_status_cx16_rom5_check_status_rom1_return = $b4
    .label check_status_smc6_return = $b0
    .label check_status_vera1_return = $7a
    .label check_status_smc7_return = $7f
    .label check_status_vera2_return = $f7
    .label check_status_vera3_return = $54
    .label check_status_vera4_return = $74
    .label check_status_smc8_return = $6c
    .label check_status_vera5_return = $ad
    .label ch4 = $b5
    .label check_status_smc9_return = $53
    .label check_status_smc10_return = $7e
    .label check_status_vera6_return = $d8
    .label check_status_vera7_return = $68
    .label check_status_smc11_return = $76
    .label check_status_vera8_return = $5c
    .label check_status_smc12_return = $5d
    .label check_status_smc13_return = $c2
    // init()
    // [71] call init
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
    // [478] phi from main to init [phi:main->init]
    jsr init
    // [72] phi from main to main::@50 [phi:main->main::@50]
    // main::@50
    // main_intro()
    // [73] call main_intro
    // [514] phi from main::@50 to main_intro [phi:main::@50->main_intro]
    jsr main_intro
    // [74] phi from main::@50 to main::@51 [phi:main::@50->main::@51]
    // main::@51
    // main_vera_detect()
    // [75] call main_vera_detect
    // [531] phi from main::@51 to main_vera_detect [phi:main::@51->main_vera_detect]
    jsr main_vera_detect
    // main::bank_set_brom1
    // BROM = bank
    // [76] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [78] phi from main::CLI1 to main::@28 [phi:main::CLI1->main::@28]
    // main::@28
    // display_progress_clear()
    // [79] call display_progress_clear
    // [538] phi from main::@28 to display_progress_clear [phi:main::@28->display_progress_clear]
    jsr display_progress_clear
    // [80] phi from main::@28 to main::@52 [phi:main::@28->main::@52]
    // main::@52
    // main_vera_check()
    // [81] call main_vera_check
    // [553] phi from main::@52 to main_vera_check [phi:main::@52->main_vera_check]
    jsr main_vera_check
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom2
    // BROM = bank
    // [83] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::check_status_smc1
    // status_smc == status
    // [84] main::check_status_smc1_$0 = status_smc#132 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [85] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // [86] phi from main::check_status_smc1 to main::check_status_cx16_rom1 [phi:main::check_status_smc1->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [87] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [88] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0
    // main::@29
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [89] if(0!=main::check_status_smc1_return#0) goto main::check_status_smc2 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc1_return
    bne check_status_smc2
    // main::@125
    // [90] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom1_check_status_rom1_return
    beq !__b3+
    jmp __b3
  !__b3:
    // main::check_status_smc2
  check_status_smc2:
    // status_smc == status
    // [91] main::check_status_smc2_$0 = status_smc#132 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [92] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0
    // [93] phi from main::check_status_smc2 to main::check_status_cx16_rom2 [phi:main::check_status_smc2->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [94] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_NONE -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [95] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0
    // main::@30
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [96] if(0==main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_eq_vbuz1_then_la1 
    // VA3 | SMC.BIN and CX16 ROM not Detected
    lda.z check_status_smc2_return
    beq check_status_smc3
    // main::@126
    // [97] if(0!=main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@1 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom2_check_status_rom1_return
    beq !__b1+
    jmp __b1
  !__b1:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [98] main::check_status_smc3_$0 = status_smc#132 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [99] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0
    // [100] phi from main::check_status_smc3 to main::check_status_cx16_rom3 [phi:main::check_status_smc3->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [101] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [102] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0
    // main::@31
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [103] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc3_return
    beq check_status_smc4
    // main::@127
    // [104] if(0==main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@5 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom3_check_status_rom1_return
    bne !__b5+
    jmp __b5
  !__b5:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [105] main::check_status_smc4_$0 = status_smc#132 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [106] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0
    // [107] phi from main::check_status_smc4 to main::check_status_cx16_rom4 [phi:main::check_status_smc4->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [108] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [109] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0
    // main::@32
    // smc_supported_rom(rom_file_release[0])
    // [110] smc_supported_rom::rom_release#0 = *rom_file_release -- vbuz1=_deref_pbuc1 
    lda rom_file_release
    sta.z smc_supported_rom.rom_release
    // [111] call smc_supported_rom
    // [575] phi from main::@32 to smc_supported_rom [phi:main::@32->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_file_release[0])
    // [112] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@70
    // [113] main::$20 = smc_supported_rom::return#3
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_file_release[0]))
    // [114] if(0==main::check_status_smc4_return#0) goto main::check_status_smc5 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc4_return
    beq check_status_smc5
    // main::@129
    // [115] if(0==main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::check_status_smc5 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom4_check_status_rom1_return
    beq check_status_smc5
    // main::@128
    // [116] if(0==main::$20) goto main::@8 -- 0_eq_vbum1_then_la1 
    lda main__20
    bne !__b8+
    jmp __b8
  !__b8:
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [117] main::check_status_smc5_$0 = status_smc#132 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [118] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0
    // main::@33
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [119] if(0!=main::check_status_smc5_return#0) goto main::@10 -- 0_neq_vbum1_then_la1 
    lda check_status_smc5_return
    beq !__b10+
    jmp __b10
  !__b10:
    // [120] phi from main::@33 main::@78 to main::check_status_cx16_rom5 [phi:main::@33/main::@78->main::check_status_cx16_rom5]
    // main::check_status_cx16_rom5
  check_status_cx16_rom5:
    // main::check_status_cx16_rom5_check_status_rom1
    // status_rom[rom_chip] == status
    // [121] main::check_status_cx16_rom5_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom5_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [122] main::check_status_cx16_rom5_check_status_rom1_return#0 = (char)main::check_status_cx16_rom5_check_status_rom1_$0
    // [123] phi from main::check_status_cx16_rom5_check_status_rom1 to main::@34 [phi:main::check_status_cx16_rom5_check_status_rom1->main::@34]
    // main::@34
    // strncmp(&rom_github[0], &rom_file_github[0], 7)
    // [124] call strncmp
    // [582] phi from main::@34 to strncmp [phi:main::@34->strncmp]
    jsr strncmp
    // strncmp(&rom_github[0], &rom_file_github[0], 7)
    // [125] strncmp::return#3 = strncmp::return#2
    // main::@76
    // [126] main::$35 = strncmp::return#3 -- vwsz1=vwsm2 
    lda strncmp.return
    sta.z main__35
    lda strncmp.return+1
    sta.z main__35+1
    // if(check_status_cx16_rom(STATUS_FLASH) && rom_release[0] == rom_file_release[0] && strncmp(&rom_github[0], &rom_file_github[0], 7) == 0)
    // [127] if(0==main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::check_status_smc6 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom5_check_status_rom1_return
    beq check_status_smc6
    // main::@131
    // [128] if(*rom_release!=*rom_file_release) goto main::check_status_smc6 -- _deref_pbuc1_neq__deref_pbuc2_then_la1 
    lda rom_release
    cmp rom_file_release
    bne check_status_smc6
    // main::@130
    // [129] if(main::$35==0) goto main::@11 -- vwsz1_eq_0_then_la1 
    lda.z main__35
    ora.z main__35+1
    bne !__b11+
    jmp __b11
  !__b11:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [130] main::check_status_smc6_$0 = status_smc#132 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [131] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0
    // main::check_status_vera1
    // status_vera == status
    // [132] main::check_status_vera1_$0 = status_vera#111 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [133] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0
    // [134] phi from main::check_status_vera1 to main::@35 [phi:main::check_status_vera1->main::@35]
    // main::@35
    // check_status_roms(STATUS_ISSUE)
    // [135] call check_status_roms
    // [594] phi from main::@35 to check_status_roms [phi:main::@35->check_status_roms]
    // [594] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@35->check_status_roms#0] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [136] check_status_roms::return#3 = check_status_roms::return#2
    // main::@79
    // [137] main::$44 = check_status_roms::return#3 -- vbuz1=vbuz2 
    lda.z check_status_roms.return
    sta.z main__44
    // main::check_status_smc7
    // status_smc == status
    // [138] main::check_status_smc7_$0 = status_smc#132 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [139] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0
    // main::check_status_vera2
    // status_vera == status
    // [140] main::check_status_vera2_$0 = status_vera#111 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [141] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0
    // [142] phi from main::check_status_vera2 to main::@36 [phi:main::check_status_vera2->main::@36]
    // main::@36
    // check_status_roms(STATUS_ERROR)
    // [143] call check_status_roms
    // [594] phi from main::@36 to check_status_roms [phi:main::@36->check_status_roms]
    // [594] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@36->check_status_roms#0] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [144] check_status_roms::return#4 = check_status_roms::return#2
    // main::@80
    // [145] main::$53 = check_status_roms::return#4
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [146] if(0!=main::check_status_smc6_return#0) goto main::check_status_vera3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc6_return
    bne check_status_vera3
    // main::@136
    // [147] if(0==main::check_status_vera1_return#0) goto main::@135 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera1_return
    bne !__b135+
    jmp __b135
  !__b135:
    // main::check_status_vera3
  check_status_vera3:
    // status_vera == status
    // [148] main::check_status_vera3_$0 = status_vera#111 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [149] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0
    // main::@37
    // if(check_status_vera(STATUS_ERROR))
    // [150] if(0==main::check_status_vera3_return#0) goto main::check_status_smc9 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera3_return
    bne !check_status_smc9+
    jmp check_status_smc9
  !check_status_smc9:
    // main::bank_set_brom5
    // BROM = bank
    // [151] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // main::vera_display_set_border_color1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [153] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [154] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [155] phi from main::vera_display_set_border_color1 to main::@42 [phi:main::vera_display_set_border_color1->main::@42]
    // main::@42
    // textcolor(WHITE)
    // [156] call textcolor
    // [439] phi from main::@42 to textcolor [phi:main::@42->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:main::@42->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [157] phi from main::@42 to main::@90 [phi:main::@42->main::@90]
    // main::@90
    // bgcolor(BLUE)
    // [158] call bgcolor
    // [444] phi from main::@90 to bgcolor [phi:main::@90->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:main::@90->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [159] phi from main::@90 to main::@91 [phi:main::@90->main::@91]
    // main::@91
    // clrscr()
    // [160] call clrscr
    jsr clrscr
    // [161] phi from main::@91 to main::@92 [phi:main::@91->main::@92]
    // main::@92
    // printf("There was a severe error updating your VERA!")
    // [162] call printf_str
    // [626] phi from main::@92 to printf_str [phi:main::@92->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:main::@92->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s [phi:main::@92->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [163] phi from main::@92 to main::@93 [phi:main::@92->main::@93]
    // main::@93
    // printf("You are back at the READY prompt without resetting your CX16.\n\n")
    // [164] call printf_str
    // [626] phi from main::@93 to printf_str [phi:main::@93->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:main::@93->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s1 [phi:main::@93->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [165] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // printf("Please don't reset or shut down your VERA until you've\n")
    // [166] call printf_str
    // [626] phi from main::@94 to printf_str [phi:main::@94->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:main::@94->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s2 [phi:main::@94->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [167] phi from main::@94 to main::@95 [phi:main::@94->main::@95]
    // main::@95
    // printf("managed to either reflash your VERA with the previous firmware ")
    // [168] call printf_str
    // [626] phi from main::@95 to printf_str [phi:main::@95->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:main::@95->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s3 [phi:main::@95->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // [169] phi from main::@95 to main::@96 [phi:main::@95->main::@96]
    // main::@96
    // printf("or have update successs retrying!\n\n")
    // [170] call printf_str
    // [626] phi from main::@96 to printf_str [phi:main::@96->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:main::@96->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s4 [phi:main::@96->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [171] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // printf("PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n")
    // [172] call printf_str
    // [626] phi from main::@97 to printf_str [phi:main::@97->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:main::@97->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s5 [phi:main::@97->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [173] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // wait_moment(32)
    // [174] call wait_moment
    // [635] phi from main::@98 to wait_moment [phi:main::@98->wait_moment]
    // [635] phi wait_moment::w#14 = $20 [phi:main::@98->wait_moment#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z wait_moment.w
    jsr wait_moment
    // [175] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // system_reset()
    // [176] call system_reset
    // [643] phi from main::@99 to system_reset [phi:main::@99->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [177] return 
    rts
    // main::check_status_smc9
  check_status_smc9:
    // status_smc == status
    // [178] main::check_status_smc9_$0 = status_smc#132 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [179] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0
    // main::check_status_smc10
    // status_smc == status
    // [180] main::check_status_smc10_$0 = status_smc#132 == STATUS_NONE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [181] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0
    // main::check_status_vera6
    // status_vera == status
    // [182] main::check_status_vera6_$0 = status_vera#111 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera6_main__0
    // return (unsigned char)(status_vera == status);
    // [183] main::check_status_vera6_return#0 = (char)main::check_status_vera6_$0
    // main::check_status_vera7
    // status_vera == status
    // [184] main::check_status_vera7_$0 = status_vera#111 == STATUS_NONE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera7_main__0
    // return (unsigned char)(status_vera == status);
    // [185] main::check_status_vera7_return#0 = (char)main::check_status_vera7_$0
    // [186] phi from main::check_status_vera7 to main::@41 [phi:main::check_status_vera7->main::@41]
    // main::@41
    // check_status_roms_less(STATUS_SKIP)
    // [187] call check_status_roms_less
    // [649] phi from main::@41 to check_status_roms_less [phi:main::@41->check_status_roms_less]
    jsr check_status_roms_less
    // check_status_roms_less(STATUS_SKIP)
    // [188] check_status_roms_less::return#3 = check_status_roms_less::return#2
    // main::@89
    // [189] main::$66 = check_status_roms_less::return#3
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        (check_status_roms_less(STATUS_SKIP)) )
    // [190] if(0!=main::check_status_smc9_return#0) goto main::@141 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc9_return
    beq !__b141+
    jmp __b141
  !__b141:
    // main::@142
    // [191] if(0!=main::check_status_smc10_return#0) goto main::@141 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc10_return
    beq !__b141+
    jmp __b141
  !__b141:
    // main::check_status_smc11
  check_status_smc11:
    // status_smc == status
    // [192] main::check_status_smc11_$0 = status_smc#132 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc11_main__0
    // return (unsigned char)(status_smc == status);
    // [193] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0
    // main::check_status_vera8
    // status_vera == status
    // [194] main::check_status_vera8_$0 = status_vera#111 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera8_main__0
    // return (unsigned char)(status_vera == status);
    // [195] main::check_status_vera8_return#0 = (char)main::check_status_vera8_$0
    // [196] phi from main::check_status_vera8 to main::@44 [phi:main::check_status_vera8->main::@44]
    // main::@44
    // check_status_roms(STATUS_ERROR)
    // [197] call check_status_roms
    // [594] phi from main::@44 to check_status_roms [phi:main::@44->check_status_roms]
    // [594] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@44->check_status_roms#0] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [198] check_status_roms::return#10 = check_status_roms::return#2
    // main::@100
    // [199] main::$156 = check_status_roms::return#10
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [200] if(0!=main::check_status_smc11_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc11_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@144
    // [201] if(0!=main::check_status_vera8_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera8_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@143
    // [202] if(0!=main::$156) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z main__156
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::check_status_smc12
    // status_smc == status
    // [203] main::check_status_smc12_$0 = status_smc#132 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc12_main__0
    // return (unsigned char)(status_smc == status);
    // [204] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0
    // main::check_status_vera9
    // status_vera == status
    // [205] main::check_status_vera9_$0 = status_vera#111 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera9_main__0
    // return (unsigned char)(status_vera == status);
    // [206] main::check_status_vera9_return#0 = (char)main::check_status_vera9_$0
    // [207] phi from main::check_status_vera9 to main::@46 [phi:main::check_status_vera9->main::@46]
    // main::@46
    // check_status_roms(STATUS_ISSUE)
    // [208] call check_status_roms
    // [594] phi from main::@46 to check_status_roms [phi:main::@46->check_status_roms]
    // [594] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@46->check_status_roms#0] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [209] check_status_roms::return#11 = check_status_roms::return#2
    // main::@104
    // [210] main::$161 = check_status_roms::return#11
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [211] if(0!=main::check_status_smc12_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc12_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@146
    // [212] if(0!=main::check_status_vera9_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_vera9_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@145
    // [213] if(0!=main::$161) goto main::vera_display_set_border_color4 -- 0_neq_vbuz1_then_la1 
    lda.z main__161
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::vera_display_set_border_color5
    // *VERA_CTRL &= ~VERA_DCSEL
    // [214] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [215] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [216] phi from main::vera_display_set_border_color5 to main::@48 [phi:main::vera_display_set_border_color5->main::@48]
    // main::@48
    // display_action_progress("Your CX16 update is a success!")
    // [217] call display_action_progress
    // [657] phi from main::@48 to display_action_progress [phi:main::@48->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text29 [phi:main::@48->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_action_progress.info_text
    lda #>info_text29
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc13
    // status_smc == status
    // [218] main::check_status_smc13_$0 = status_smc#132 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc13_main__0
    // return (unsigned char)(status_smc == status);
    // [219] main::check_status_smc13_return#0 = (char)main::check_status_smc13_$0
    // main::@49
    // if(check_status_smc(STATUS_FLASHED))
    // [220] if(0!=main::check_status_smc13_return#0) goto main::@19 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc13_return
    beq !__b19+
    jmp __b19
  !__b19:
    // [221] phi from main::@49 to main::@14 [phi:main::@49->main::@14]
    // main::@14
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [222] call display_progress_text
    // [671] phi from main::@14 to display_progress_text [phi:main::@14->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_debriefing_text_rom [phi:main::@14->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_debriefing_count_rom [phi:main::@14->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_rom
    sta display_progress_text.lines
    jsr display_progress_text
    // [223] phi from main::@14 main::@43 main::@47 to main::@2 [phi:main::@14/main::@43/main::@47->main::@2]
    // main::@2
  __b2:
    // textcolor(PINK)
    // [224] call textcolor
  // DE6 | Wait until reset
    // [439] phi from main::@2 to textcolor [phi:main::@2->textcolor]
    // [439] phi textcolor::color#21 = PINK [phi:main::@2->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [225] phi from main::@2 to main::@117 [phi:main::@2->main::@117]
    // main::@117
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [226] call display_progress_line
    // [681] phi from main::@117 to display_progress_line [phi:main::@117->display_progress_line]
    // [681] phi display_progress_line::text#3 = main::text1 [phi:main::@117->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text1
    sta.z display_progress_line.text
    lda #>text1
    sta.z display_progress_line.text+1
    // [681] phi display_progress_line::line#3 = 2 [phi:main::@117->display_progress_line#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_progress_line.line
    jsr display_progress_line
    // [227] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // textcolor(WHITE)
    // [228] call textcolor
    // [439] phi from main::@118 to textcolor [phi:main::@118->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:main::@118->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [229] phi from main::@118 to main::@25 [phi:main::@118->main::@25]
    // [229] phi main::w1#2 = $78 [phi:main::@118->main::@25#0] -- vbum1=vbuc1 
    lda #$78
    sta w1
    // main::@25
  __b25:
    // for (unsigned char w=120; w>0; w--)
    // [230] if(main::w1#2>0) goto main::@26 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b26
    // [231] phi from main::@25 to main::@27 [phi:main::@25->main::@27]
    // main::@27
    // system_reset()
    // [232] call system_reset
    // [643] phi from main::@27 to system_reset [phi:main::@27->system_reset]
    jsr system_reset
    rts
    // [233] phi from main::@25 to main::@26 [phi:main::@25->main::@26]
    // main::@26
  __b26:
    // wait_moment(1)
    // [234] call wait_moment
    // [635] phi from main::@26 to wait_moment [phi:main::@26->wait_moment]
    // [635] phi wait_moment::w#14 = 1 [phi:main::@26->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // [235] phi from main::@26 to main::@119 [phi:main::@26->main::@119]
    // main::@119
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [236] call snprintf_init
    jsr snprintf_init
    // [237] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [238] call printf_str
    // [626] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s9 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@121
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [239] printf_uchar::uvalue#5 = main::w1#2 -- vbum1=vbum2 
    lda w1
    sta printf_uchar.uvalue
    // [240] call printf_uchar
    // [690] phi from main::@121 to printf_uchar [phi:main::@121->printf_uchar]
    // [690] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@121->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [690] phi printf_uchar::format_min_length#10 = 0 [phi:main::@121->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [690] phi printf_uchar::putc#10 = &snputc [phi:main::@121->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [690] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@121->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [690] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#5 [phi:main::@121->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [241] phi from main::@121 to main::@122 [phi:main::@121->main::@122]
    // main::@122
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [242] call printf_str
    // [626] phi from main::@122 to printf_str [phi:main::@122->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main::@122->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s10 [phi:main::@122->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@123
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [243] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [244] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [246] call display_action_text
    // [701] phi from main::@123 to display_action_text [phi:main::@123->display_action_text]
    // [701] phi display_action_text::info_text#17 = info_text [phi:main::@123->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@124
    // for (unsigned char w=120; w>0; w--)
    // [247] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [229] phi from main::@124 to main::@25 [phi:main::@124->main::@25]
    // [229] phi main::w1#2 = main::w1#1 [phi:main::@124->main::@25#0] -- register_copy 
    jmp __b25
    // [248] phi from main::@49 to main::@19 [phi:main::@49->main::@19]
    // main::@19
  __b19:
    // display_progress_text(display_debriefing_smc_text, display_debriefing_smc_count)
    // [249] call display_progress_text
    // [671] phi from main::@19 to display_progress_text [phi:main::@19->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_debriefing_smc_text [phi:main::@19->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_smc_text
    sta.z display_progress_text.text
    lda #>display_debriefing_smc_text
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_debriefing_smc_count [phi:main::@19->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_smc_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [250] phi from main::@19 to main::@105 [phi:main::@19->main::@105]
    // main::@105
    // textcolor(PINK)
    // [251] call textcolor
    // [439] phi from main::@105 to textcolor [phi:main::@105->textcolor]
    // [439] phi textcolor::color#21 = PINK [phi:main::@105->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [252] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [253] call display_progress_line
    // [681] phi from main::@106 to display_progress_line [phi:main::@106->display_progress_line]
    // [681] phi display_progress_line::text#3 = main::text [phi:main::@106->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [681] phi display_progress_line::line#3 = 2 [phi:main::@106->display_progress_line#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_progress_line.line
    jsr display_progress_line
    // [254] phi from main::@106 to main::@107 [phi:main::@106->main::@107]
    // main::@107
    // textcolor(WHITE)
    // [255] call textcolor
    // [439] phi from main::@107 to textcolor [phi:main::@107->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:main::@107->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [256] phi from main::@107 to main::@20 [phi:main::@107->main::@20]
    // [256] phi main::w#2 = $78 [phi:main::@107->main::@20#0] -- vbum1=vbuc1 
    lda #$78
    sta w
    // main::@20
  __b20:
    // for (unsigned char w=120; w>0; w--)
    // [257] if(main::w#2>0) goto main::@21 -- vbum1_gt_0_then_la1 
    lda w
    bne __b21
    // [258] phi from main::@20 to main::@22 [phi:main::@20->main::@22]
    // main::@22
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [259] call snprintf_init
    jsr snprintf_init
    // [260] phi from main::@22 to main::@114 [phi:main::@22->main::@114]
    // main::@114
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [261] call printf_str
    // [626] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s8 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [262] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [263] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [265] call display_action_text
    // [701] phi from main::@115 to display_action_text [phi:main::@115->display_action_text]
    // [701] phi display_action_text::info_text#17 = info_text [phi:main::@115->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [266] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // smc_reset()
    // [267] call smc_reset
  // DE5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [715] phi from main::@116 to smc_reset [phi:main::@116->smc_reset]
    jsr smc_reset
    // [268] phi from main::@116 main::@23 to main::@23 [phi:main::@116/main::@23->main::@23]
  __b4:
  // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
    // main::@23
    jmp __b4
    // [269] phi from main::@20 to main::@21 [phi:main::@20->main::@21]
    // main::@21
  __b21:
    // wait_moment(1)
    // [270] call wait_moment
    // [635] phi from main::@21 to wait_moment [phi:main::@21->wait_moment]
    // [635] phi wait_moment::w#14 = 1 [phi:main::@21->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // [271] phi from main::@21 to main::@108 [phi:main::@21->main::@108]
    // main::@108
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [272] call snprintf_init
    jsr snprintf_init
    // [273] phi from main::@108 to main::@109 [phi:main::@108->main::@109]
    // main::@109
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [274] call printf_str
    // [626] phi from main::@109 to printf_str [phi:main::@109->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main::@109->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s6 [phi:main::@109->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@110
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [275] printf_uchar::uvalue#4 = main::w#2 -- vbum1=vbum2 
    lda w
    sta printf_uchar.uvalue
    // [276] call printf_uchar
    // [690] phi from main::@110 to printf_uchar [phi:main::@110->printf_uchar]
    // [690] phi printf_uchar::format_zero_padding#10 = 1 [phi:main::@110->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [690] phi printf_uchar::format_min_length#10 = 3 [phi:main::@110->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [690] phi printf_uchar::putc#10 = &snputc [phi:main::@110->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [690] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@110->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [690] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#4 [phi:main::@110->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [277] phi from main::@110 to main::@111 [phi:main::@110->main::@111]
    // main::@111
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [278] call printf_str
    // [626] phi from main::@111 to printf_str [phi:main::@111->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main::@111->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main::s7 [phi:main::@111->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@112
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [279] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [280] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [282] call display_action_text
    // [701] phi from main::@112 to display_action_text [phi:main::@112->display_action_text]
    // [701] phi display_action_text::info_text#17 = info_text [phi:main::@112->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@113
    // for (unsigned char w=120; w>0; w--)
    // [283] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [256] phi from main::@113 to main::@20 [phi:main::@113->main::@20]
    // [256] phi main::w#2 = main::w#1 [phi:main::@113->main::@20#0] -- register_copy 
    jmp __b20
    // main::vera_display_set_border_color4
  vera_display_set_border_color4:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [284] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [285] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [286] phi from main::vera_display_set_border_color4 to main::@47 [phi:main::vera_display_set_border_color4->main::@47]
    // main::@47
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [287] call display_action_progress
    // [657] phi from main::@47 to display_action_progress [phi:main::@47->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text28 [phi:main::@47->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_action_progress.info_text
    lda #>info_text28
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b2
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [288] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [289] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [290] phi from main::vera_display_set_border_color3 to main::@45 [phi:main::vera_display_set_border_color3->main::@45]
    // main::@45
    // display_action_progress("Update Failure! Your CX16 may no longer boot!")
    // [291] call display_action_progress
    // [657] phi from main::@45 to display_action_progress [phi:main::@45->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text26 [phi:main::@45->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_action_progress.info_text
    lda #>info_text26
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [292] phi from main::@45 to main::@101 [phi:main::@45->main::@101]
    // main::@101
    // display_action_text("Take a photo of this screen and wait at leaast 60 seconds.")
    // [293] call display_action_text
    // [701] phi from main::@101 to display_action_text [phi:main::@101->display_action_text]
    // [701] phi display_action_text::info_text#17 = main::info_text27 [phi:main::@101->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_action_text.info_text
    lda #>info_text27
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [294] phi from main::@101 to main::@102 [phi:main::@101->main::@102]
    // main::@102
    // wait_moment(250)
    // [295] call wait_moment
    // [635] phi from main::@102 to wait_moment [phi:main::@102->wait_moment]
    // [635] phi wait_moment::w#14 = $fa [phi:main::@102->wait_moment#0] -- vbuz1=vbuc1 
    lda #$fa
    sta.z wait_moment.w
    jsr wait_moment
    // [296] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // smc_reset()
    // [297] call smc_reset
    // [715] phi from main::@103 to smc_reset [phi:main::@103->smc_reset]
    jsr smc_reset
    // [298] phi from main::@103 main::@24 to main::@24 [phi:main::@103/main::@24->main::@24]
    // main::@24
  __b24:
    jmp __b24
    // main::@141
  __b141:
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        (check_status_roms_less(STATUS_SKIP)) )
    // [299] if(0!=main::check_status_vera6_return#0) goto main::@140 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera6_return
    bne __b140
    // main::@147
    // [300] if(0==main::check_status_vera7_return#0) goto main::check_status_smc11 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera7_return
    bne !check_status_smc11+
    jmp check_status_smc11
  !check_status_smc11:
    // main::@140
  __b140:
    // [301] if(0!=main::$66) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z main__66
    bne vera_display_set_border_color2
    jmp check_status_smc11
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [302] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [303] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [304] phi from main::vera_display_set_border_color2 to main::@43 [phi:main::vera_display_set_border_color2->main::@43]
    // main::@43
    // display_action_progress("No CX16 component has been updated with new firmware!")
    // [305] call display_action_progress
    // [657] phi from main::@43 to display_action_progress [phi:main::@43->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text25 [phi:main::@43->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z display_action_progress.info_text
    lda #>info_text25
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b2
    // main::@135
  __b135:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [306] if(0!=main::$44) goto main::check_status_vera3 -- 0_neq_vbuz1_then_la1 
    lda.z main__44
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@134
    // [307] if(0==main::check_status_smc7_return#0) goto main::@133 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc7_return
    beq __b133
    jmp check_status_vera3
    // main::@133
  __b133:
    // [308] if(0!=main::check_status_vera2_return#0) goto main::check_status_vera3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera2_return
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@132
    // [309] if(0==main::$53) goto main::check_status_vera4 -- 0_eq_vbuz1_then_la1 
    lda.z main__53
    beq check_status_vera4
    jmp check_status_vera3
    // main::check_status_vera4
  check_status_vera4:
    // status_vera == status
    // [310] main::check_status_vera4_$0 = status_vera#111 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera4_main__0
    // return (unsigned char)(status_vera == status);
    // [311] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0
    // main::check_status_smc8
    // status_smc == status
    // [312] main::check_status_smc8_$0 = status_smc#132 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [313] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0
    // [314] phi from main::check_status_smc8 to main::check_status_cx16_rom6 [phi:main::check_status_smc8->main::check_status_cx16_rom6]
    // main::check_status_cx16_rom6
    // main::check_status_cx16_rom6_check_status_rom1
    // status_rom[rom_chip] == status
    // [315] main::check_status_cx16_rom6_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom6_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [316] main::check_status_cx16_rom6_check_status_rom1_return#0 = (char)main::check_status_cx16_rom6_check_status_rom1_$0
    // [317] phi from main::check_status_cx16_rom6_check_status_rom1 to main::@38 [phi:main::check_status_cx16_rom6_check_status_rom1->main::@38]
    // main::@38
    // check_status_card_roms(STATUS_FLASH)
    // [318] call check_status_card_roms
    // [724] phi from main::@38 to check_status_card_roms [phi:main::@38->check_status_card_roms]
    jsr check_status_card_roms
    // check_status_card_roms(STATUS_FLASH)
    // [319] check_status_card_roms::return#3 = check_status_card_roms::return#2
    // main::@83
    // [320] main::$118 = check_status_card_roms::return#3
    // if(check_status_vera(STATUS_FLASH) || check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [321] if(0!=main::check_status_vera4_return#0) goto main::@12 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera4_return
    bne __b12
    // main::@139
    // [322] if(0!=main::check_status_smc8_return#0) goto main::@12 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc8_return
    bne __b12
    // main::@138
    // [323] if(0!=main::check_status_cx16_rom6_check_status_rom1_return#0) goto main::@12 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom6_check_status_rom1_return
    bne __b12
    // main::@137
    // [324] if(0!=main::$118) goto main::@12 -- 0_neq_vbuz1_then_la1 
    lda.z main__118
    bne __b12
    // main::bank_set_brom3
  bank_set_brom3:
    // BROM = bank
    // [325] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::check_status_vera5
    // status_vera == status
    // [327] main::check_status_vera5_$0 = status_vera#111 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera5_main__0
    // return (unsigned char)(status_vera == status);
    // [328] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0
    // main::@39
    // if(check_status_vera(STATUS_FLASH))
    // [329] if(0==main::check_status_vera5_return#0) goto main::SEI2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera5_return
    beq SEI2
    // [330] phi from main::@39 to main::@18 [phi:main::@39->main::@18]
    // main::@18
    // main_vera_flash()
    // [331] call main_vera_flash
    // [733] phi from main::@18 to main_vera_flash [phi:main::@18->main_vera_flash]
    jsr main_vera_flash
    // main::SEI2
  SEI2:
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom4
    // BROM = bank
    // [333] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // [334] phi from main::bank_set_brom4 to main::@40 [phi:main::bank_set_brom4->main::@40]
    // main::@40
    // display_progress_clear()
    // [335] call display_progress_clear
    // [538] phi from main::@40 to display_progress_clear [phi:main::@40->display_progress_clear]
    jsr display_progress_clear
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    jmp check_status_vera3
    // [337] phi from main::@137 main::@138 main::@139 main::@83 to main::@12 [phi:main::@137/main::@138/main::@139/main::@83->main::@12]
    // main::@12
  __b12:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [338] call display_action_progress
    // [657] phi from main::@12 to display_action_progress [phi:main::@12->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text19 [phi:main::@12->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_action_progress.info_text
    lda #>info_text19
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [339] phi from main::@12 to main::@84 [phi:main::@12->main::@84]
    // main::@84
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [340] call util_wait_key
    // [869] phi from main::@84 to util_wait_key [phi:main::@84->util_wait_key]
    // [869] phi util_wait_key::filter#16 = main::filter4 [phi:main::@84->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter4
    sta.z util_wait_key.filter
    lda #>filter4
    sta.z util_wait_key.filter+1
    // [869] phi util_wait_key::info_text#6 = main::info_text20 [phi:main::@84->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z util_wait_key.info_text
    lda #>info_text20
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [341] util_wait_key::return#13 = util_wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z util_wait_key.ch
    sta.z util_wait_key.return_4
    // main::@85
    // [342] main::ch4#0 = util_wait_key::return#13
    // strchr("nN", ch)
    // [343] strchr::c#1 = main::ch4#0 -- vbum1=vbuz2 
    lda.z ch4
    sta strchr.c
    // [344] call strchr
    // [894] phi from main::@85 to strchr [phi:main::@85->strchr]
    // [894] phi strchr::c#4 = strchr::c#1 [phi:main::@85->strchr#0] -- register_copy 
    // [894] phi strchr::str#2 = (const void *)main::$213 [phi:main::@85->strchr#1] -- pvoz1=pvoc1 
    lda #<main__213
    sta.z strchr.str
    lda #>main__213
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [345] strchr::return#4 = strchr::return#2
    // main::@86
    // [346] main::$123 = strchr::return#4
    // if(strchr("nN", ch))
    // [347] if((void *)0==main::$123) goto main::bank_set_brom3 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__123
    cmp #<0
    bne !+
    lda.z main__123+1
    cmp #>0
    beq bank_set_brom3
  !:
    // [348] phi from main::@86 to main::@13 [phi:main::@86->main::@13]
    // main::@13
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [349] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [903] phi from main::@13 to display_info_smc [phi:main::@13->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = main::info_text21 [phi:main::@13->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_info_smc.info_text
    lda #>info_text21
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_SKIP [phi:main::@13->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [350] phi from main::@13 to main::@87 [phi:main::@13->main::@87]
    // main::@87
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [351] call display_info_vera
    // [939] phi from main::@87 to display_info_vera [phi:main::@87->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = main::info_text22 [phi:main::@87->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_info_vera.info_text
    lda #>info_text22
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main::@87->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [352] phi from main::@87 to main::@15 [phi:main::@87->main::@15]
    // [352] phi main::rom_chip#2 = 0 [phi:main::@87->main::@15#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@15
  __b15:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [353] if(main::rom_chip#2<8) goto main::@16 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b16
    // [354] phi from main::@15 to main::@17 [phi:main::@15->main::@17]
    // main::@17
    // display_action_text("You have selected not to cancel the update ... ")
    // [355] call display_action_text
    // [701] phi from main::@17 to display_action_text [phi:main::@17->display_action_text]
    // [701] phi display_action_text::info_text#17 = main::info_text24 [phi:main::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_action_text.info_text
    lda #>info_text24
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_brom3
    // main::@16
  __b16:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [356] display_info_rom::rom_chip#3 = main::rom_chip#2 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [357] call display_info_rom
    // [967] phi from main::@16 to display_info_rom [phi:main::@16->display_info_rom]
    // [967] phi display_info_rom::info_text#10 = main::info_text23 [phi:main::@16->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_info_rom.info_text
    lda #>info_text23
    sta.z display_info_rom.info_text+1
    // [967] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#3 [phi:main::@16->display_info_rom#1] -- register_copy 
    // [967] phi display_info_rom::info_status#10 = STATUS_SKIP [phi:main::@16->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@88
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [358] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [352] phi from main::@88 to main::@15 [phi:main::@88->main::@15]
    // [352] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@88->main::@15#0] -- register_copy 
    jmp __b15
    // [359] phi from main::@130 to main::@11 [phi:main::@130->main::@11]
    // main::@11
  __b11:
    // display_action_progress("The CX16 ROM and ROM.BIN versions are equal, no flash required!")
    // [360] call display_action_progress
    // [657] phi from main::@11 to display_action_progress [phi:main::@11->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text18 [phi:main::@11->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z display_action_progress.info_text
    lda #>info_text18
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [361] phi from main::@11 to main::@81 [phi:main::@11->main::@81]
    // main::@81
    // util_wait_space()
    // [362] call util_wait_space
    // [1012] phi from main::@81 to util_wait_space [phi:main::@81->util_wait_space]
    jsr util_wait_space
    // [363] phi from main::@81 to main::@82 [phi:main::@81->main::@82]
    // main::@82
    // display_info_cx16_rom(STATUS_SKIP, NULL)
    // [364] call display_info_cx16_rom
    // [1015] phi from main::@82 to display_info_cx16_rom [phi:main::@82->display_info_cx16_rom]
    // [1015] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@82->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1015] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@82->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc6
    // [365] phi from main::@33 to main::@10 [phi:main::@33->main::@10]
    // main::@10
  __b10:
    // display_action_progress("The CX16 SMC and SMC.BIN versions are equal, no flash required!")
    // [366] call display_action_progress
    // [657] phi from main::@10 to display_action_progress [phi:main::@10->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text17 [phi:main::@10->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_action_progress.info_text
    lda #>info_text17
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [367] phi from main::@10 to main::@77 [phi:main::@10->main::@77]
    // main::@77
    // util_wait_space()
    // [368] call util_wait_space
    // [1012] phi from main::@77 to util_wait_space [phi:main::@77->util_wait_space]
    jsr util_wait_space
    // [369] phi from main::@77 to main::@78 [phi:main::@77->main::@78]
    // main::@78
    // display_info_smc(STATUS_SKIP, NULL)
    // [370] call display_info_smc
    // [903] phi from main::@78 to display_info_smc [phi:main::@78->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = 0 [phi:main::@78->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_SKIP [phi:main::@78->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_cx16_rom5
    // [371] phi from main::@128 to main::@8 [phi:main::@128->main::@8]
    // main::@8
  __b8:
    // display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!")
    // [372] call display_action_progress
    // [657] phi from main::@8 to display_action_progress [phi:main::@8->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text15 [phi:main::@8->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_progress.info_text
    lda #>info_text15
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [373] phi from main::@8 to main::@72 [phi:main::@8->main::@72]
    // main::@72
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [374] call display_progress_text
    // [671] phi from main::@72 to display_progress_text [phi:main::@72->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_smc_unsupported_rom_text [phi:main::@72->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_smc_unsupported_rom_count [phi:main::@72->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [375] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [376] call util_wait_key
    // [869] phi from main::@73 to util_wait_key [phi:main::@73->util_wait_key]
    // [869] phi util_wait_key::filter#16 = main::filter3 [phi:main::@73->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter3
    sta.z util_wait_key.filter
    lda #>filter3
    sta.z util_wait_key.filter+1
    // [869] phi util_wait_key::info_text#6 = main::info_text16 [phi:main::@73->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z util_wait_key.info_text
    lda #>info_text16
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [377] util_wait_key::return#12 = util_wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z util_wait_key.ch
    sta.z util_wait_key.return_3
    // main::@74
    // [378] main::ch3#0 = util_wait_key::return#12
    // if(ch == 'N')
    // [379] if(main::ch3#0!='N') goto main::check_status_smc5 -- vbuz1_neq_vbuc1_then_la1 
    lda #'N'
    cmp.z ch3
    beq !check_status_smc5+
    jmp check_status_smc5
  !check_status_smc5:
    // [380] phi from main::@74 to main::@9 [phi:main::@74->main::@9]
    // main::@9
    // display_info_smc(STATUS_ISSUE, NULL)
    // [381] call display_info_smc
  // Cancel flash
    // [903] phi from main::@9 to display_info_smc [phi:main::@9->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = 0 [phi:main::@9->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_ISSUE [phi:main::@9->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [382] phi from main::@9 to main::@75 [phi:main::@9->main::@75]
    // main::@75
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [383] call display_info_cx16_rom
    // [1015] phi from main::@75 to display_info_cx16_rom [phi:main::@75->display_info_cx16_rom]
    // [1015] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@75->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1015] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@75->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc5
    // [384] phi from main::@127 to main::@5 [phi:main::@127->main::@5]
    // main::@5
  __b5:
    // display_action_progress("Issue with the CX16 ROM, check the issue ...")
    // [385] call display_action_progress
    // [657] phi from main::@5 to display_action_progress [phi:main::@5->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text8 [phi:main::@5->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [386] phi from main::@5 to main::@64 [phi:main::@5->main::@64]
    // main::@64
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [387] call display_progress_text
    // [671] phi from main::@64 to display_progress_text [phi:main::@64->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_smc_rom_issue_text [phi:main::@64->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_smc_rom_issue_count [phi:main::@64->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [388] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [389] call display_info_smc
    // [903] phi from main::@65 to display_info_smc [phi:main::@65->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = main::info_text9 [phi:main::@65->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_SKIP [phi:main::@65->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [390] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [391] call display_info_cx16_rom
    // [1015] phi from main::@66 to display_info_cx16_rom [phi:main::@66->display_info_cx16_rom]
    // [1015] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@66->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1015] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@66->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [392] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [393] call util_wait_key
    // [869] phi from main::@67 to util_wait_key [phi:main::@67->util_wait_key]
    // [869] phi util_wait_key::filter#16 = main::filter2 [phi:main::@67->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter2
    sta.z util_wait_key.filter
    lda #>filter2
    sta.z util_wait_key.filter+1
    // [869] phi util_wait_key::info_text#6 = main::info_text10 [phi:main::@67->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z util_wait_key.info_text
    lda #>info_text10
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [394] util_wait_key::return#11 = util_wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z util_wait_key.ch
    sta.z util_wait_key.return_2
    // main::@68
    // [395] main::ch1#0 = util_wait_key::return#11
    // if(ch == 'Y')
    // [396] if(main::ch1#0!='Y') goto main::check_status_smc4 -- vbuz1_neq_vbuc1_then_la1 
    lda #'Y'
    cmp.z ch1
    beq !check_status_smc4+
    jmp check_status_smc4
  !check_status_smc4:
    // [397] phi from main::@68 to main::@6 [phi:main::@68->main::@6]
    // main::@6
    // display_info_smc(STATUS_FLASH, "")
    // [398] call display_info_smc
    // [903] phi from main::@6 to display_info_smc [phi:main::@6->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = main::info_text11 [phi:main::@6->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_info_smc.info_text
    lda #>info_text11
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_FLASH [phi:main::@6->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [399] phi from main::@6 to main::@69 [phi:main::@6->main::@69]
    // main::@69
    // display_info_cx16_rom(STATUS_SKIP, "")
    // [400] call display_info_cx16_rom
    // [1015] phi from main::@69 to display_info_cx16_rom [phi:main::@69->display_info_cx16_rom]
    // [1015] phi display_info_cx16_rom::info_text#8 = main::info_text12 [phi:main::@69->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_cx16_rom.info_text
    lda #>info_text12
    sta.z display_info_cx16_rom.info_text+1
    // [1015] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@69->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc4
    // [401] phi from main::@126 to main::@1 [phi:main::@126->main::@1]
    // main::@1
  __b1:
    // display_action_progress("Issue with the CX16 ROM: not detected! ...")
    // [402] call display_action_progress
    // [657] phi from main::@1 to display_action_progress [phi:main::@1->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text4 [phi:main::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_action_progress.info_text
    lda #>info_text4
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [403] phi from main::@1 to main::@59 [phi:main::@1->main::@59]
    // main::@59
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [404] call display_progress_text
    // [671] phi from main::@59 to display_progress_text [phi:main::@59->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_smc_rom_issue_text [phi:main::@59->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_smc_rom_issue_count [phi:main::@59->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [405] phi from main::@59 to main::@60 [phi:main::@59->main::@60]
    // main::@60
    // display_info_smc(STATUS_SKIP, "Issue with CX16 ROM!")
    // [406] call display_info_smc
    // [903] phi from main::@60 to display_info_smc [phi:main::@60->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = main::info_text5 [phi:main::@60->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_smc.info_text
    lda #>info_text5
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_SKIP [phi:main::@60->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [407] phi from main::@60 to main::@61 [phi:main::@60->main::@61]
    // main::@61
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [408] call display_info_cx16_rom
    // [1015] phi from main::@61 to display_info_cx16_rom [phi:main::@61->display_info_cx16_rom]
    // [1015] phi display_info_cx16_rom::info_text#8 = main::info_text6 [phi:main::@61->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_cx16_rom.info_text
    lda #>info_text6
    sta.z display_info_cx16_rom.info_text+1
    // [1015] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@61->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [409] phi from main::@61 to main::@62 [phi:main::@61->main::@62]
    // main::@62
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [410] call util_wait_key
    // [869] phi from main::@62 to util_wait_key [phi:main::@62->util_wait_key]
    // [869] phi util_wait_key::filter#16 = main::filter1 [phi:main::@62->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z util_wait_key.filter
    lda #>filter1
    sta.z util_wait_key.filter+1
    // [869] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@62->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [411] util_wait_key::return#10 = util_wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z util_wait_key.ch
    sta.z util_wait_key.return_1
    // main::@63
    // [412] main::ch2#0 = util_wait_key::return#10
    // if(ch == 'Y')
    // [413] if(main::ch2#0!='Y') goto main::check_status_smc4 -- vbuz1_neq_vbuc1_then_la1 
    lda #'Y'
    cmp.z ch2
    beq !check_status_smc4+
    jmp check_status_smc4
  !check_status_smc4:
    // [414] phi from main::@63 to main::@7 [phi:main::@63->main::@7]
    // main::@7
    // display_info_smc(STATUS_FLASH, "")
    // [415] call display_info_smc
    // [903] phi from main::@7 to display_info_smc [phi:main::@7->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = main::info_text13 [phi:main::@7->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_info_smc.info_text
    lda #>info_text13
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_FLASH [phi:main::@7->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [416] phi from main::@7 to main::@71 [phi:main::@7->main::@71]
    // main::@71
    // display_info_cx16_rom(STATUS_SKIP, "")
    // [417] call display_info_cx16_rom
    // [1015] phi from main::@71 to display_info_cx16_rom [phi:main::@71->display_info_cx16_rom]
    // [1015] phi display_info_cx16_rom::info_text#8 = main::info_text14 [phi:main::@71->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_cx16_rom.info_text
    lda #>info_text14
    sta.z display_info_cx16_rom.info_text+1
    // [1015] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@71->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc4
    // [418] phi from main::@125 to main::@3 [phi:main::@125->main::@3]
    // main::@3
  __b3:
    // display_action_progress("Issue with the CX16 SMC, check the issue ...")
    // [419] call display_action_progress
    // [657] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main::info_text [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [420] phi from main::@3 to main::@53 [phi:main::@3->main::@53]
    // main::@53
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [421] call display_progress_text
    // [671] phi from main::@53 to display_progress_text [phi:main::@53->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_smc_rom_issue_text [phi:main::@53->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_smc_rom_issue_count [phi:main::@53->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [422] phi from main::@53 to main::@54 [phi:main::@53->main::@54]
    // main::@54
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [423] call display_info_cx16_rom
    // [1015] phi from main::@54 to display_info_cx16_rom [phi:main::@54->display_info_cx16_rom]
    // [1015] phi display_info_cx16_rom::info_text#8 = main::info_text1 [phi:main::@54->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_cx16_rom.info_text
    lda #>info_text1
    sta.z display_info_cx16_rom.info_text+1
    // [1015] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@54->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [424] phi from main::@54 to main::@55 [phi:main::@54->main::@55]
    // main::@55
    // display_info_smc(STATUS_ISSUE, NULL)
    // [425] call display_info_smc
    // [903] phi from main::@55 to display_info_smc [phi:main::@55->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = 0 [phi:main::@55->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_ISSUE [phi:main::@55->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [426] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [427] call util_wait_key
    // [869] phi from main::@56 to util_wait_key [phi:main::@56->util_wait_key]
    // [869] phi util_wait_key::filter#16 = main::filter [phi:main::@56->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [869] phi util_wait_key::info_text#6 = main::info_text2 [phi:main::@56->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z util_wait_key.info_text
    lda #>info_text2
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [428] util_wait_key::return#3 = util_wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z util_wait_key.ch
    sta.z util_wait_key.return
    // main::@57
    // [429] main::ch#0 = util_wait_key::return#3
    // if(ch == 'Y')
    // [430] if(main::ch#0!='Y') goto main::check_status_smc2 -- vbuz1_neq_vbuc1_then_la1 
    lda #'Y'
    cmp.z ch
    beq !check_status_smc2+
    jmp check_status_smc2
  !check_status_smc2:
    // [431] phi from main::@57 to main::@4 [phi:main::@57->main::@4]
    // main::@4
    // display_info_cx16_rom(STATUS_FLASH, "")
    // [432] call display_info_cx16_rom
    // [1015] phi from main::@4 to display_info_cx16_rom [phi:main::@4->display_info_cx16_rom]
    // [1015] phi display_info_cx16_rom::info_text#8 = main::info_text3 [phi:main::@4->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_cx16_rom.info_text
    lda #>info_text3
    sta.z display_info_cx16_rom.info_text+1
    // [1015] phi display_info_cx16_rom::info_status#8 = STATUS_FLASH [phi:main::@4->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [433] phi from main::@4 to main::@58 [phi:main::@4->main::@58]
    // main::@58
    // display_info_smc(STATUS_SKIP, NULL)
    // [434] call display_info_smc
    // [903] phi from main::@58 to display_info_smc [phi:main::@58->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = 0 [phi:main::@58->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_SKIP [phi:main::@58->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_smc2
  .segment Data
    info_text: .text "Issue with the CX16 SMC, check the issue ..."
    .byte 0
    info_text1: .text "Issue with SMC!"
    .byte 0
    info_text2: .text "Proceed with the update? [Y/N]"
    .byte 0
    filter: .text "YN"
    .byte 0
    info_text3: .text ""
    .byte 0
    info_text4: .text "Issue with the CX16 ROM: not detected! ..."
    .byte 0
    info_text5: .text "Issue with CX16 ROM!"
    .byte 0
    info_text6: .text "Are J1 jumper pins closed?"
    .byte 0
    info_text7: .text "Proceed with the update? [Y/N]"
    .byte 0
    filter1: .text "YN"
    .byte 0
    info_text8: .text "Issue with the CX16 ROM, check the issue ..."
    .byte 0
    info_text9: .text "Issue with main CX16 ROM!"
    .byte 0
    info_text10: .text "Proceed with the update? [Y/N]"
    .byte 0
    filter2: .text "YN"
    .byte 0
    info_text11: .text ""
    .byte 0
    info_text12: .text ""
    .byte 0
    info_text13: .text ""
    .byte 0
    info_text14: .text ""
    .byte 0
    info_text15: .text "Compatibility between ROM.BIN and SMC.BIN can't be assured!"
    .byte 0
    info_text16: .text "Proceed with the update? [Y/N]"
    .byte 0
    filter3: .text "YN"
    .byte 0
    info_text17: .text "The CX16 SMC and SMC.BIN versions are equal, no flash required!"
    .byte 0
    info_text18: .text "The CX16 ROM and ROM.BIN versions are equal, no flash required!"
    .byte 0
    info_text19: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text20: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter4: .text "nyNY"
    .byte 0
    main__213: .text "nN"
    .byte 0
    info_text21: .text "Cancelled"
    .byte 0
    info_text22: .text "Cancelled"
    .byte 0
    info_text23: .text "Cancelled"
    .byte 0
    info_text24: .text "You have selected not to cancel the update ... "
    .byte 0
    s: .text "There was a severe error updating your VERA!"
    .byte 0
    s1: .text @"You are back at the READY prompt without resetting your CX16.\n\n"
    .byte 0
    s2: .text @"Please don't reset or shut down your VERA until you've\n"
    .byte 0
    s3: .text "managed to either reflash your VERA with the previous firmware "
    .byte 0
    s4: .text @"or have update successs retrying!\n\n"
    .byte 0
    s5: .text @"PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n"
    .byte 0
    info_text25: .text "No CX16 component has been updated with new firmware!"
    .byte 0
    info_text26: .text "Update Failure! Your CX16 may no longer boot!"
    .byte 0
    info_text27: .text "Take a photo of this screen and wait at leaast 60 seconds."
    .byte 0
    info_text28: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text29: .text "Your CX16 update is a success!"
    .byte 0
    text: .text "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!"
    .byte 0
    s6: .text "["
    .byte 0
    s7: .text "] Please read carefully the below ..."
    .byte 0
    s8: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    text1: .text "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!"
    .byte 0
    s9: .text "("
    .byte 0
    s10: .text ") Your CX16 will reset after countdown ..."
    .byte 0
    .label main__20 = smc_supported_rom.return
    check_status_smc5_main__0: .byte 0
    check_status_cx16_rom6_check_status_rom1_main__0: .byte 0
    check_status_vera9_main__0: .byte 0
    .label check_status_smc5_return = check_status_smc5_main__0
    .label check_status_cx16_rom6_check_status_rom1_return = check_status_cx16_rom6_check_status_rom1_main__0
    rom_chip: .byte 0
    .label check_status_vera9_return = check_status_vera9_main__0
    w: .byte 0
    w1: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [435] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [436] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [437] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [438] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $57
    .label textcolor__1 = $57
    // __conio.color & 0xF0
    // [440] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [441] textcolor::$1 = textcolor::$0 | textcolor::color#21 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [442] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [443] return 
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
    .label bgcolor__0 = $57
    .label bgcolor__1 = $61
    .label bgcolor__2 = $57
    // __conio.color & 0x0F
    // [445] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [446] bgcolor::$1 = bgcolor::color#15 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [447] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [448] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [449] return 
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
    // [450] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [451] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [452] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [453] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [455] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [456] return 
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
    .label gotoxy__8 = $31
    .label gotoxy__9 = $2e
    .label gotoxy__10 = $2d
    .label gotoxy__14 = $2b
    // (x>=__conio.width)?__conio.width:x
    // [458] if(gotoxy::x#26>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [460] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [460] phi gotoxy::$3 = gotoxy::x#26 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [459] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [460] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [460] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [461] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [462] if(gotoxy::y#26>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [463] gotoxy::$14 = gotoxy::y#26 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [464] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [464] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [465] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [466] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [467] gotoxy::$10 = gotoxy::y#26 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [468] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [469] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [470] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [471] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    .label cputln__2 = $34
    // __conio.cursor_x = 0
    // [472] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [473] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [474] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [475] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [476] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [477] return 
    rts
}
.segment CodeIntro
  // init
init: {
    .label init__12 = $da
    .label rom_chip = $62
    .label init__16 = $da
    .label init__17 = $da
    .label init__18 = $da
    // display_frame_init_64()
    // [479] call display_frame_init_64
    jsr display_frame_init_64
    // [480] phi from init to init::@4 [phi:init->init::@4]
    // init::@4
    // display_frame_draw()
    // [481] call display_frame_draw
  // ST1 | Reset canvas to 64 columns
    // [1094] phi from init::@4 to display_frame_draw [phi:init::@4->display_frame_draw]
    jsr display_frame_draw
    // [482] phi from init::@4 to init::@5 [phi:init::@4->init::@5]
    // init::@5
    // display_frame_title("Commander X16 Update Utility (v2.2.1) ")
    // [483] call display_frame_title
    // [1135] phi from init::@5 to display_frame_title [phi:init::@5->display_frame_title]
    jsr display_frame_title
    // [484] phi from init::@5 to init::display_info_title1 [phi:init::@5->init::display_info_title1]
    // init::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [485] call cputsxy
    // [1140] phi from init::display_info_title1 to cputsxy [phi:init::display_info_title1->cputsxy]
    // [1140] phi cputsxy::s#3 = init::s [phi:init::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [1140] phi cputsxy::y#3 = $11-2 [phi:init::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [1140] phi cputsxy::x#3 = 4-2 [phi:init::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [486] phi from init::display_info_title1 to init::@6 [phi:init::display_info_title1->init::@6]
    // init::@6
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [487] call cputsxy
    // [1140] phi from init::@6 to cputsxy [phi:init::@6->cputsxy]
    // [1140] phi cputsxy::s#3 = init::s1 [phi:init::@6->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [1140] phi cputsxy::y#3 = $11-1 [phi:init::@6->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [1140] phi cputsxy::x#3 = 4-2 [phi:init::@6->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [488] phi from init::@6 to init::@3 [phi:init::@6->init::@3]
    // init::@3
    // display_action_progress("Introduction, please read carefully the below!")
    // [489] call display_action_progress
    // [657] phi from init::@3 to display_action_progress [phi:init::@3->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = init::info_text [phi:init::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [490] phi from init::@3 to init::@7 [phi:init::@3->init::@7]
    // init::@7
    // display_progress_clear()
    // [491] call display_progress_clear
    // [538] phi from init::@7 to display_progress_clear [phi:init::@7->display_progress_clear]
    jsr display_progress_clear
    // [492] phi from init::@7 to init::@8 [phi:init::@7->init::@8]
    // init::@8
    // display_chip_smc()
    // [493] call display_chip_smc
    // [1147] phi from init::@8 to display_chip_smc [phi:init::@8->display_chip_smc]
    jsr display_chip_smc
    // [494] phi from init::@8 to init::@9 [phi:init::@8->init::@9]
    // init::@9
    // display_chip_vera()
    // [495] call display_chip_vera
    // [1152] phi from init::@9 to display_chip_vera [phi:init::@9->display_chip_vera]
    jsr display_chip_vera
    // [496] phi from init::@9 to init::@10 [phi:init::@9->init::@10]
    // init::@10
    // display_chip_rom()
    // [497] call display_chip_rom
    // [1157] phi from init::@10 to display_chip_rom [phi:init::@10->display_chip_rom]
    jsr display_chip_rom
    // [498] phi from init::@10 to init::@11 [phi:init::@10->init::@11]
    // init::@11
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [499] call display_info_smc
    // [903] phi from init::@11 to display_info_smc [phi:init::@11->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = 0 [phi:init::@11->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = BLACK [phi:init::@11->display_info_smc#1] -- vbum1=vbuc1 
    lda #BLACK
    sta display_info_smc.info_status
    jsr display_info_smc
    // [500] phi from init::@11 to init::@12 [phi:init::@11->init::@12]
    // init::@12
    // display_info_vera(STATUS_NONE, NULL)
    // [501] call display_info_vera
    // [939] phi from init::@12 to display_info_vera [phi:init::@12->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = 0 [phi:init::@12->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_NONE [phi:init::@12->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [502] phi from init::@12 to init::@1 [phi:init::@12->init::@1]
    // [502] phi init::rom_chip#2 = 0 [phi:init::@12->init::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // init::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [503] if(init::rom_chip#2<8) goto init::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc __b2
    // init::@return
    // }
    // [504] return 
    rts
    // init::@2
  __b2:
    // rom_chip*13
    // [505] init::$16 = init::rom_chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z init__16
    // [506] init::$17 = init::$16 + init::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z init__17
    clc
    adc.z rom_chip
    sta.z init__17
    // [507] init::$18 = init::$17 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z init__18
    asl
    asl
    sta.z init__18
    // [508] init::$12 = init::$18 + init::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z init__12
    clc
    adc.z rom_chip
    sta.z init__12
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [509] strcpy::destination#0 = rom_release_text + init::$12 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [510] call strcpy
    // [1176] phi from init::@2 to strcpy [phi:init::@2->strcpy]
    // [1176] phi strcpy::dst#0 = strcpy::destination#0 [phi:init::@2->strcpy#0] -- register_copy 
    // [1176] phi strcpy::src#0 = init::source [phi:init::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // init::@13
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [511] display_info_rom::rom_chip#0 = init::rom_chip#2 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z display_info_rom.rom_chip
    // [512] call display_info_rom
    // [967] phi from init::@13 to display_info_rom [phi:init::@13->display_info_rom]
    // [967] phi display_info_rom::info_text#10 = 0 [phi:init::@13->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [967] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#0 [phi:init::@13->display_info_rom#1] -- register_copy 
    // [967] phi display_info_rom::info_status#10 = STATUS_NONE [phi:init::@13->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // init::@14
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [513] init::rom_chip#1 = ++ init::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [502] phi from init::@14 to init::@1 [phi:init::@14->init::@1]
    // [502] phi init::rom_chip#2 = init::rom_chip#1 [phi:init::@14->init::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    title_text: .text "Commander X16 Update Utility (v2.2.1) "
    .byte 0
    s: .text "# Chip Status    Type   Curr. Release Update Info"
    .byte 0
    s1: .text "- ---- --------- ------ ------------- --------------------------"
    .byte 0
    info_text: .text "Introduction, please read carefully the below!"
    .byte 0
    source: .text "          "
    .byte 0
}
.segment CodeIntro
  // main_intro
main_intro: {
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [515] call display_progress_text
    // [671] phi from main_intro to display_progress_text [phi:main_intro->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_into_briefing_text [phi:main_intro->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_intro_briefing_count [phi:main_intro->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_briefing_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [516] phi from main_intro to main_intro::@4 [phi:main_intro->main_intro::@4]
    // main_intro::@4
    // util_wait_space()
    // [517] call util_wait_space
    // [1012] phi from main_intro::@4 to util_wait_space [phi:main_intro::@4->util_wait_space]
    jsr util_wait_space
    // [518] phi from main_intro::@4 to main_intro::@5 [phi:main_intro::@4->main_intro::@5]
    // main_intro::@5
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [519] call display_progress_text
    // [671] phi from main_intro::@5 to display_progress_text [phi:main_intro::@5->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_into_colors_text [phi:main_intro::@5->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_intro_colors_count [phi:main_intro::@5->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_colors_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [520] phi from main_intro::@5 to main_intro::@1 [phi:main_intro::@5->main_intro::@1]
    // [520] phi main_intro::intro_status#2 = 0 [phi:main_intro::@5->main_intro::@1#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main_intro::@1
  __b1:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [521] if(main_intro::intro_status#2<$b) goto main_intro::@2 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcc __b2
    // [522] phi from main_intro::@1 to main_intro::@3 [phi:main_intro::@1->main_intro::@3]
    // main_intro::@3
    // util_wait_space()
    // [523] call util_wait_space
    // [1012] phi from main_intro::@3 to util_wait_space [phi:main_intro::@3->util_wait_space]
    jsr util_wait_space
    // [524] phi from main_intro::@3 to main_intro::@7 [phi:main_intro::@3->main_intro::@7]
    // main_intro::@7
    // display_progress_clear()
    // [525] call display_progress_clear
    // [538] phi from main_intro::@7 to display_progress_clear [phi:main_intro::@7->display_progress_clear]
    jsr display_progress_clear
    // main_intro::@return
    // }
    // [526] return 
    rts
    // main_intro::@2
  __b2:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [527] display_info_led::y#3 = PROGRESS_Y+3 + main_intro::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [528] display_info_led::tc#3 = status_color[main_intro::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z display_info_led.tc
    // [529] call display_info_led
    // [1184] phi from main_intro::@2 to display_info_led [phi:main_intro::@2->display_info_led]
    // [1184] phi display_info_led::y#4 = display_info_led::y#3 [phi:main_intro::@2->display_info_led#0] -- register_copy 
    // [1184] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main_intro::@2->display_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z display_info_led.x
    // [1184] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main_intro::@2->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main_intro::@6
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [530] main_intro::intro_status#1 = ++ main_intro::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [520] phi from main_intro::@6 to main_intro::@1 [phi:main_intro::@6->main_intro::@1]
    // [520] phi main_intro::intro_status#2 = main_intro::intro_status#1 [phi:main_intro::@6->main_intro::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label intro_status = smc_supported_rom.return
}
.segment CodeVera
  // main_vera_detect
//#pragma data_seg(DataVera)
main_vera_detect: {
    // w25q16_detect()
    // [532] call w25q16_detect
    // [1195] phi from main_vera_detect to w25q16_detect [phi:main_vera_detect->w25q16_detect]
    jsr w25q16_detect
    // [533] phi from main_vera_detect to main_vera_detect::@1 [phi:main_vera_detect->main_vera_detect::@1]
    // main_vera_detect::@1
    // display_chip_vera()
    // [534] call display_chip_vera
    // [1152] phi from main_vera_detect::@1 to display_chip_vera [phi:main_vera_detect::@1->display_chip_vera]
    jsr display_chip_vera
    // [535] phi from main_vera_detect::@1 to main_vera_detect::@2 [phi:main_vera_detect::@1->main_vera_detect::@2]
    // main_vera_detect::@2
    // display_info_vera(STATUS_DETECTED, NULL)
    // [536] call display_info_vera
    // [939] phi from main_vera_detect::@2 to display_info_vera [phi:main_vera_detect::@2->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = 0 [phi:main_vera_detect::@2->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_DETECTED [phi:main_vera_detect::@2->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // main_vera_detect::@return
    // }
    // [537] return 
    rts
}
.segment Code
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $77
    .label i = $70
    .label y = $4f
    // textcolor(WHITE)
    // [539] call textcolor
    // [439] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [540] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [541] call bgcolor
    // [444] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [542] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [542] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [543] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [544] return 
    rts
    // [545] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [545] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [545] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [546] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [547] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [542] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [542] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [548] cputcxy::x#12 = display_progress_clear::x#2 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [549] cputcxy::y#12 = display_progress_clear::y#2 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [550] call cputcxy
    // [1200] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1200] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [1200] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [551] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [552] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [545] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [545] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [545] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
.segment CodeVera
  // main_vera_check
main_vera_check: {
    .label vera_bytes_read = $df
    // display_action_progress("Checking VERA.BIN ...")
    // [554] call display_action_progress
    // [657] phi from main_vera_check to display_action_progress [phi:main_vera_check->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main_vera_check::info_text [phi:main_vera_check->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [555] phi from main_vera_check to main_vera_check::@4 [phi:main_vera_check->main_vera_check::@4]
    // main_vera_check::@4
    // unsigned long vera_bytes_read = w25q16_read(STATUS_CHECKING)
    // [556] call w25q16_read
  // Read the VERA.BIN file.
    // [1208] phi from main_vera_check::@4 to w25q16_read [phi:main_vera_check::@4->w25q16_read]
    // [1208] phi __errno#118 = 0 [phi:main_vera_check::@4->w25q16_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [1208] phi w25q16_read::info_status#12 = STATUS_CHECKING [phi:main_vera_check::@4->w25q16_read#1] -- vbuz1=vbuc1 
    lda #STATUS_CHECKING
    sta.z w25q16_read.info_status
    jsr w25q16_read
    // unsigned long vera_bytes_read = w25q16_read(STATUS_CHECKING)
    // [557] w25q16_read::return#2 = w25q16_read::return#0
    // main_vera_check::@5
    // [558] main_vera_check::vera_bytes_read#0 = w25q16_read::return#2
    // wait_moment(10)
    // [559] call wait_moment
    // [635] phi from main_vera_check::@5 to wait_moment [phi:main_vera_check::@5->wait_moment]
    // [635] phi wait_moment::w#14 = $a [phi:main_vera_check::@5->wait_moment#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z wait_moment.w
    jsr wait_moment
    // main_vera_check::@6
    // if (!vera_bytes_read)
    // [560] if(0==main_vera_check::vera_bytes_read#0) goto main_vera_check::@1 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    beq __b1
    // main_vera_check::@3
    // vera_file_size = vera_bytes_read
    // [561] vera_file_size#0 = main_vera_check::vera_bytes_read#0 -- vdum1=vduz2 
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
    // [562] call snprintf_init
    jsr snprintf_init
    // [563] phi from main_vera_check::@3 to main_vera_check::@7 [phi:main_vera_check::@3->main_vera_check::@7]
    // main_vera_check::@7
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [564] call printf_str
    // [626] phi from main_vera_check::@7 to printf_str [phi:main_vera_check::@7->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main_vera_check::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main_vera_check::s [phi:main_vera_check::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [565] phi from main_vera_check::@7 to main_vera_check::@8 [phi:main_vera_check::@7->main_vera_check::@8]
    // main_vera_check::@8
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [566] call printf_string
    // [1261] phi from main_vera_check::@8 to printf_string [phi:main_vera_check::@8->printf_string]
    // [1261] phi printf_string::putc#17 = &snputc [phi:main_vera_check::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = main_vera_check::str [phi:main_vera_check::@8->printf_string#1] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [1261] phi printf_string::format_justify_left#17 = 0 [phi:main_vera_check::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 0 [phi:main_vera_check::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main_vera_check::@9
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [567] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [568] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_FLASH, info_text)
    // [570] call display_info_vera
    // [939] phi from main_vera_check::@9 to display_info_vera [phi:main_vera_check::@9->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = info_text [phi:main_vera_check::@9->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_FLASH [phi:main_vera_check::@9->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [571] phi from main_vera_check::@9 to main_vera_check::@2 [phi:main_vera_check::@9->main_vera_check::@2]
    // [571] phi vera_file_size#1 = vera_file_size#0 [phi:main_vera_check::@9->main_vera_check::@2#0] -- register_copy 
    // main_vera_check::@2
    // main_vera_check::@return
    // }
    // [572] return 
    rts
    // [573] phi from main_vera_check::@6 to main_vera_check::@1 [phi:main_vera_check::@6->main_vera_check::@1]
    // main_vera_check::@1
  __b1:
    // display_info_vera(STATUS_SKIP, "No VERA.BIN")
    // [574] call display_info_vera
  // VF1 | no VERA.BIN  | Ask the user to place the VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // VF2 | VERA.BIN size 0 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // TODO: VF4 | ROM.BIN size over 0x20000 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
    // [939] phi from main_vera_check::@1 to display_info_vera [phi:main_vera_check::@1->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = main_vera_check::info_text1 [phi:main_vera_check::@1->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main_vera_check::@1->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [571] phi from main_vera_check::@1 to main_vera_check::@2 [phi:main_vera_check::@1->main_vera_check::@2]
    // [571] phi vera_file_size#1 = 0 [phi:main_vera_check::@1->main_vera_check::@2#0] -- vdum1=vduc1 
    lda #<0
    sta vera_file_size
    sta vera_file_size+1
    lda #<0>>$10
    sta vera_file_size+2
    lda #>0>>$10
    sta vera_file_size+3
    rts
  .segment Data
    info_text: .text "Checking VERA.BIN ..."
    .byte 0
    info_text1: .text "No VERA.BIN"
    .byte 0
    s: .text "VERA.BIN:"
    .byte 0
    str: .text ""
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
// __mem() char smc_supported_rom(__zp($bb) char rom_release)
smc_supported_rom: {
    .label i = $62
    .label rom_release = $bb
    // [576] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [576] phi smc_supported_rom::i#2 = $1f [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z i
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=31; i>3; i--)
    // [577] if(smc_supported_rom::i#2>=3+1) goto smc_supported_rom::@2 -- vbuz1_ge_vbuc1_then_la1 
    lda.z i
    cmp #3+1
    bcs __b2
    // [579] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [579] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_file_header[i] == rom_release)
    // [578] if(smc_file_header[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbuz1_neq_vbuz2_then_la1 
    lda.z rom_release
    ldy.z i
    cmp smc_file_header,y
    bne __b3
    // [579] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [579] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // smc_supported_rom::@return
    // }
    // [580] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=31; i>3; i--)
    // [581] smc_supported_rom::i#1 = -- smc_supported_rom::i#2 -- vbuz1=_dec_vbuz1 
    dec.z i
    // [576] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [576] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    return: .byte 0
}
.segment Code
  // strncmp
/// Compares at most the first n bytes of str1 and str2.
/// @param str1 This is the first string to be compared.
/// @param str2 This is the second string to be compared.
/// @param The maximum number of characters to be compared.
/// @return if Return value < 0 then it indicates str1 is less than str2.
///         if Return value > 0 then it indicates str2 is less than str1.
///         if Return value = 0 then it indicates str1 is equal to str2.
// __mem() int strncmp(const char *str1, const char *str2, __mem() unsigned int n)
strncmp: {
    .label strncmp__0 = $da
    .label s1 = $48
    .label s2 = $3b
    // [583] phi from strncmp to strncmp::@1 [phi:strncmp->strncmp::@1]
    // [583] phi strncmp::n#2 = 7 [phi:strncmp->strncmp::@1#0] -- vwum1=vbuc1 
    lda #<7
    sta n
    lda #>7
    sta n+1
    // [583] phi strncmp::s2#2 = rom_file_github [phi:strncmp->strncmp::@1#1] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z s2
    lda #>rom_file_github
    sta.z s2+1
    // [583] phi strncmp::s1#2 = rom_github [phi:strncmp->strncmp::@1#2] -- pbuz1=pbuc1 
    lda #<rom_github
    sta.z s1
    lda #>rom_github
    sta.z s1+1
    // strncmp::@1
  __b1:
    // while(*s1==*s2)
    // [584] if(*strncmp::s1#2==*strncmp::s2#2) goto strncmp::@2 -- _deref_pbuz1_eq__deref_pbuz2_then_la1 
    ldy #0
    lda (s1),y
    cmp (s2),y
    beq __b2
    // strncmp::@3
    // *s1-*s2
    // [585] strncmp::$0 = *strncmp::s1#2 - *strncmp::s2#2 -- vbuz1=_deref_pbuz2_minus__deref_pbuz3 
    lda (s1),y
    sec
    sbc (s2),y
    sta.z strncmp__0
    // return (int)(signed char)(*s1-*s2);
    // [586] strncmp::return#0 = (int)(signed char)strncmp::$0 -- vwsm1=_sword_vbsz2 
    sta return
    ora #$7f
    bmi !+
    tya
  !:
    sta return+1
    // [587] phi from strncmp::@3 to strncmp::@return [phi:strncmp::@3->strncmp::@return]
    // [587] phi strncmp::return#2 = strncmp::return#0 [phi:strncmp::@3->strncmp::@return#0] -- register_copy 
    rts
    // [587] phi from strncmp::@2 strncmp::@5 to strncmp::@return [phi:strncmp::@2/strncmp::@5->strncmp::@return]
  __b3:
    // [587] phi strncmp::return#2 = 0 [phi:strncmp::@2/strncmp::@5->strncmp::@return#0] -- vwsm1=vbsc1 
    lda #<0
    sta return
    sta return+1
    // strncmp::@return
    // }
    // [588] return 
    rts
    // strncmp::@2
  __b2:
    // n--;
    // [589] strncmp::n#0 = -- strncmp::n#2 -- vwum1=_dec_vwum1 
    lda n
    bne !+
    dec n+1
  !:
    dec n
    // if(*s1==0 || n==0)
    // [590] if(*strncmp::s1#2==0) goto strncmp::@return -- _deref_pbuz1_eq_0_then_la1 
    ldy #0
    lda (s1),y
    cmp #0
    beq __b3
    // strncmp::@5
    // [591] if(strncmp::n#0==0) goto strncmp::@return -- vwum1_eq_0_then_la1 
    lda n
    ora n+1
    beq __b3
    // strncmp::@4
    // s1++;
    // [592] strncmp::s1#1 = ++ strncmp::s1#2 -- pbuz1=_inc_pbuz1 
    inc.z s1
    bne !+
    inc.z s1+1
  !:
    // s2++;
    // [593] strncmp::s2#1 = ++ strncmp::s2#2 -- pbuz1=_inc_pbuz1 
    inc.z s2
    bne !+
    inc.z s2+1
  !:
    // [583] phi from strncmp::@4 to strncmp::@1 [phi:strncmp::@4->strncmp::@1]
    // [583] phi strncmp::n#2 = strncmp::n#0 [phi:strncmp::@4->strncmp::@1#0] -- register_copy 
    // [583] phi strncmp::s2#2 = strncmp::s2#1 [phi:strncmp::@4->strncmp::@1#1] -- register_copy 
    // [583] phi strncmp::s1#2 = strncmp::s1#1 [phi:strncmp::@4->strncmp::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    n: .word 0
    return: .word 0
}
.segment Code
  // check_status_roms
/**
 * @brief Check the status of any of the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
// __zp($77) char check_status_roms(__zp($4f) char status)
check_status_roms: {
    .label check_status_rom1_check_status_roms__0 = $78
    .label check_status_rom1_return = $78
    .label rom_chip = $70
    .label return = $77
    .label status = $4f
    // [595] phi from check_status_roms to check_status_roms::@1 [phi:check_status_roms->check_status_roms::@1]
    // [595] phi check_status_roms::rom_chip#2 = 0 [phi:check_status_roms->check_status_roms::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // check_status_roms::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [596] if(check_status_roms::rom_chip#2<8) goto check_status_roms::check_status_rom1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc check_status_rom1
    // [597] phi from check_status_roms::@1 to check_status_roms::@return [phi:check_status_roms::@1->check_status_roms::@return]
    // [597] phi check_status_roms::return#2 = 0 [phi:check_status_roms::@1->check_status_roms::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    // check_status_roms::@return
    // }
    // [598] return 
    rts
    // check_status_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [599] check_status_roms::check_status_rom1_$0 = status_rom[check_status_roms::rom_chip#2] == check_status_roms::status#6 -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuz3 
    lda.z status
    ldy.z rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [600] check_status_roms::check_status_rom1_return#0 = (char)check_status_roms::check_status_rom1_$0
    // check_status_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [601] if(0==check_status_roms::check_status_rom1_return#0) goto check_status_roms::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_rom1_return
    beq __b2
    // [597] phi from check_status_roms::@3 to check_status_roms::@return [phi:check_status_roms::@3->check_status_roms::@return]
    // [597] phi check_status_roms::return#2 = 1 [phi:check_status_roms::@3->check_status_roms::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    rts
    // check_status_roms::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [602] check_status_roms::rom_chip#1 = ++ check_status_roms::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [595] phi from check_status_roms::@2 to check_status_roms::@1 [phi:check_status_roms::@2->check_status_roms::@1]
    // [595] phi check_status_roms::rom_chip#2 = check_status_roms::rom_chip#1 [phi:check_status_roms::@2->check_status_roms::@1#0] -- register_copy 
    jmp __b1
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $78
    .label clrscr__1 = $7b
    .label clrscr__2 = $3f
    // unsigned int line_text = __conio.mapbase_offset
    // [603] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [604] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [605] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [606] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [607] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [608] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [608] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [608] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [609] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [610] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [611] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [612] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [613] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [614] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [614] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [615] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [616] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [617] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [618] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [619] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [620] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [621] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [622] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [623] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [624] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [625] return 
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
// void printf_str(__zp($48) void (*putc)(char), __zp($3b) const char *s)
printf_str: {
    .label s = $3b
    .label putc = $48
    // [627] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [627] phi printf_str::s#48 = printf_str::s#49 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [628] printf_str::c#1 = *printf_str::s#48 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [629] printf_str::s#0 = ++ printf_str::s#48 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [630] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [631] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [632] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [633] callexecute *printf_str::putc#49  -- call__deref_pprz1 
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
// void wait_moment(__zp($62) char w)
wait_moment: {
    .label i = $48
    .label j = $4f
    .label w = $62
    // [636] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [636] phi wait_moment::j#2 = 0 [phi:wait_moment->wait_moment::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z j
    // wait_moment::@1
  __b1:
    // for(unsigned char j=0; j<w; j++)
    // [637] if(wait_moment::j#2<wait_moment::w#14) goto wait_moment::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z j
    cmp.z w
    bcc __b4
    // wait_moment::@return
    // }
    // [638] return 
    rts
    // [639] phi from wait_moment::@1 to wait_moment::@2 [phi:wait_moment::@1->wait_moment::@2]
  __b4:
    // [639] phi wait_moment::i#2 = $ffff [phi:wait_moment::@1->wait_moment::@2#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [640] if(wait_moment::i#2>0) goto wait_moment::@3 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b3
    lda.z i
    bne __b3
  !:
    // wait_moment::@4
    // for(unsigned char j=0; j<w; j++)
    // [641] wait_moment::j#1 = ++ wait_moment::j#2 -- vbuz1=_inc_vbuz1 
    inc.z j
    // [636] phi from wait_moment::@4 to wait_moment::@1 [phi:wait_moment::@4->wait_moment::@1]
    // [636] phi wait_moment::j#2 = wait_moment::j#1 [phi:wait_moment::@4->wait_moment::@1#0] -- register_copy 
    jmp __b1
    // wait_moment::@3
  __b3:
    // for(unsigned int i=65535; i>0; i--)
    // [642] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [639] phi from wait_moment::@3 to wait_moment::@2 [phi:wait_moment::@3->wait_moment::@2]
    // [639] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@3->wait_moment::@2#0] -- register_copy 
    jmp __b2
}
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
    // [644] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [645] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // *((char*)0x9F25) = 0x80
    // [646] *((char *) 40741) = $80 -- _deref_pbuc1=vbuc2 
    lda #$80
    sta $9f25
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [648] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
// __zp($4f) char check_status_roms_less(char status)
check_status_roms_less: {
    .label check_status_roms_less__1 = $7b
    .label rom_chip = $62
    .label return = $4f
    // [650] phi from check_status_roms_less to check_status_roms_less::@1 [phi:check_status_roms_less->check_status_roms_less::@1]
    // [650] phi check_status_roms_less::rom_chip#2 = 0 [phi:check_status_roms_less->check_status_roms_less::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // check_status_roms_less::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [651] if(check_status_roms_less::rom_chip#2<8) goto check_status_roms_less::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc __b2
    // [654] phi from check_status_roms_less::@1 to check_status_roms_less::@return [phi:check_status_roms_less::@1->check_status_roms_less::@return]
    // [654] phi check_status_roms_less::return#2 = 1 [phi:check_status_roms_less::@1->check_status_roms_less::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    rts
    // check_status_roms_less::@2
  __b2:
    // status_rom[rom_chip] > status
    // [652] check_status_roms_less::$1 = status_rom[check_status_roms_less::rom_chip#2] > STATUS_SKIP -- vboz1=pbuc1_derefidx_vbuz2_gt_vbuc2 
    ldy.z rom_chip
    lda status_rom,y
    cmp #STATUS_SKIP
    lda #0
    rol
    sta.z check_status_roms_less__1
    // if((unsigned char)(status_rom[rom_chip] > status))
    // [653] if(0==(char)check_status_roms_less::$1) goto check_status_roms_less::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // [654] phi from check_status_roms_less::@2 to check_status_roms_less::@return [phi:check_status_roms_less::@2->check_status_roms_less::@return]
    // [654] phi check_status_roms_less::return#2 = 0 [phi:check_status_roms_less::@2->check_status_roms_less::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    // check_status_roms_less::@return
    // }
    // [655] return 
    rts
    // check_status_roms_less::@3
  __b3:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [656] check_status_roms_less::rom_chip#1 = ++ check_status_roms_less::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [650] phi from check_status_roms_less::@3 to check_status_roms_less::@1 [phi:check_status_roms_less::@3->check_status_roms_less::@1]
    // [650] phi check_status_roms_less::rom_chip#2 = check_status_roms_less::rom_chip#1 [phi:check_status_roms_less::@3->check_status_roms_less::@1#0] -- register_copy 
    jmp __b1
}
  // display_action_progress
/**
 * @brief Print the progress at the action frame, which is the first line.
 * 
 * @param info_text The progress text to be displayed.
 */
// void display_action_progress(__zp($3b) char *info_text)
display_action_progress: {
    .label x = $3f
    .label y = $d9
    .label info_text = $3b
    // unsigned char x = wherex()
    // [658] call wherex
    jsr wherex
    // [659] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [660] display_action_progress::x#0 = wherex::return#2 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [661] call wherey
    jsr wherey
    // [662] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [663] display_action_progress::y#0 = wherey::return#2 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // gotoxy(2, PROGRESS_Y-4)
    // [664] call gotoxy
    // [457] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [457] phi gotoxy::y#26 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [665] printf_string::str#1 = display_action_progress::info_text#22
    // [666] call printf_string
    // [1261] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [667] gotoxy::x#10 = display_action_progress::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [668] gotoxy::y#10 = display_action_progress::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [669] call gotoxy
    // [457] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [670] return 
    rts
}
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($48) char **text, __mem() char lines)
display_progress_text: {
    .label display_progress_text__3 = $d9
    .label l = $ee
    .label text = $48
    // display_progress_clear()
    // [672] call display_progress_clear
    // [538] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [673] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [673] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [674] if(display_progress_text::l#2<display_progress_text::lines#10) goto display_progress_text::@2 -- vbuz1_lt_vbum2_then_la1 
    lda.z l
    cmp lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [675] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [676] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z l
    asl
    sta.z display_progress_text__3
    // [677] display_progress_line::line#0 = display_progress_text::l#2 -- vbuz1=vbuz2 
    lda.z l
    sta.z display_progress_line.line
    // [678] display_progress_line::text#0 = display_progress_text::text#11[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [679] call display_progress_line
    // [681] phi from display_progress_text::@2 to display_progress_line [phi:display_progress_text::@2->display_progress_line]
    // [681] phi display_progress_line::text#3 = display_progress_line::text#0 [phi:display_progress_text::@2->display_progress_line#0] -- register_copy 
    // [681] phi display_progress_line::line#3 = display_progress_line::line#0 [phi:display_progress_text::@2->display_progress_line#1] -- register_copy 
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [680] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [673] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [673] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label lines = main.check_status_vera9_main__0
}
.segment Code
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__zp($70) char line, __zp($5a) char *text)
display_progress_line: {
    .label line = $70
    .label text = $5a
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [682] cputsxy::y#2 = PROGRESS_Y + display_progress_line::line#3 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y
    clc
    adc.z line
    sta cputsxy.y
    // [683] cputsxy::s#2 = display_progress_line::text#3
    // [684] call cputsxy
    // [1140] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [1140] phi cputsxy::s#3 = cputsxy::s#2 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [1140] phi cputsxy::y#3 = cputsxy::y#2 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [1140] phi cputsxy::x#3 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [685] return 
    rts
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [686] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [687] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [688] __snprintf_buffer = info_text -- pbuz1=pbuc1 
    lda #<info_text
    sta.z __snprintf_buffer
    lda #>info_text
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [689] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($48) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $48
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [691] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [692] uctoa::value#1 = printf_uchar::uvalue#6
    // [693] uctoa::radix#0 = printf_uchar::format_radix#10
    // [694] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [695] printf_number_buffer::putc#2 = printf_uchar::putc#10
    // [696] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [697] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10
    // [698] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [699] call printf_number_buffer
  // Print using format
    // [1318] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1318] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1318] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1318] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1318] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [700] return 
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
// void display_action_text(__zp($37) char *info_text)
display_action_text: {
    .label info_text = $37
    .label x = $69
    .label y = $3d
    // unsigned char x = wherex()
    // [702] call wherex
    jsr wherex
    // [703] wherex::return#3 = wherex::return#0
    // display_action_text::@1
    // [704] display_action_text::x#0 = wherex::return#3 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [705] call wherey
    jsr wherey
    // [706] wherey::return#3 = wherey::return#0
    // display_action_text::@2
    // [707] display_action_text::y#0 = wherey::return#3 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // gotoxy(2, PROGRESS_Y-3)
    // [708] call gotoxy
    // [457] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [457] phi gotoxy::y#26 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [709] printf_string::str#2 = display_action_text::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [710] call printf_string
    // [1261] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [711] gotoxy::x#12 = display_action_text::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [712] gotoxy::y#12 = display_action_text::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [713] call gotoxy
    // [457] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [714] return 
    rts
}
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
    // [716] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [717] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@1
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [718] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [719] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [720] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [721] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [723] return 
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
// __zp($ee) char check_status_card_roms(char status)
check_status_card_roms: {
    .label check_status_rom1_check_status_card_roms__0 = $69
    .label check_status_rom1_return = $69
    .label return = $ee
    // [725] phi from check_status_card_roms to check_status_card_roms::@1 [phi:check_status_card_roms->check_status_card_roms::@1]
    // [725] phi check_status_card_roms::rom_chip#2 = 1 [phi:check_status_card_roms->check_status_card_roms::@1#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip
    // check_status_card_roms::@1
  __b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [726] if(check_status_card_roms::rom_chip#2<8) goto check_status_card_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [727] phi from check_status_card_roms::@1 to check_status_card_roms::@return [phi:check_status_card_roms::@1->check_status_card_roms::@return]
    // [727] phi check_status_card_roms::return#2 = 0 [phi:check_status_card_roms::@1->check_status_card_roms::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    // check_status_card_roms::@return
    // }
    // [728] return 
    rts
    // check_status_card_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [729] check_status_card_roms::check_status_rom1_$0 = status_rom[check_status_card_roms::rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_card_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [730] check_status_card_roms::check_status_rom1_return#0 = (char)check_status_card_roms::check_status_rom1_$0
    // check_status_card_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [731] if(0==check_status_card_roms::check_status_rom1_return#0) goto check_status_card_roms::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_rom1_return
    beq __b2
    // [727] phi from check_status_card_roms::@3 to check_status_card_roms::@return [phi:check_status_card_roms::@3->check_status_card_roms::@return]
    // [727] phi check_status_card_roms::return#2 = 1 [phi:check_status_card_roms::@3->check_status_card_roms::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    rts
    // check_status_card_roms::@2
  __b2:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [732] check_status_card_roms::rom_chip#1 = ++ check_status_card_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [725] phi from check_status_card_roms::@2 to check_status_card_roms::@1 [phi:check_status_card_roms::@2->check_status_card_roms::@1]
    // [725] phi check_status_card_roms::rom_chip#2 = check_status_card_roms::rom_chip#1 [phi:check_status_card_roms::@2->check_status_card_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label rom_chip = main.check_status_vera9_main__0
}
.segment CodeVera
  // main_vera_flash
main_vera_flash: {
    .label vera_bytes_read = $df
    .label spi_ensure_detect = $70
    .label vera_erase_error = $da
    .label spi_ensure_detect_1 = $c2
    // display_progress_text(display_jp1_spi_vera_text, display_jp1_spi_vera_count)
    // [734] call display_progress_text
    // [671] phi from main_vera_flash to display_progress_text [phi:main_vera_flash->display_progress_text]
    // [671] phi display_progress_text::text#11 = display_jp1_spi_vera_text [phi:main_vera_flash->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_jp1_spi_vera_text
    sta.z display_progress_text.text
    lda #>display_jp1_spi_vera_text
    sta.z display_progress_text.text+1
    // [671] phi display_progress_text::lines#10 = display_jp1_spi_vera_count [phi:main_vera_flash->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_jp1_spi_vera_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [735] phi from main_vera_flash to main_vera_flash::@20 [phi:main_vera_flash->main_vera_flash::@20]
    // main_vera_flash::@20
    // util_wait_space()
    // [736] call util_wait_space
    // [1012] phi from main_vera_flash::@20 to util_wait_space [phi:main_vera_flash::@20->util_wait_space]
    jsr util_wait_space
    // [737] phi from main_vera_flash::@20 to main_vera_flash::@21 [phi:main_vera_flash::@20->main_vera_flash::@21]
    // main_vera_flash::@21
    // display_progress_clear()
    // [738] call display_progress_clear
    // [538] phi from main_vera_flash::@21 to display_progress_clear [phi:main_vera_flash::@21->display_progress_clear]
    jsr display_progress_clear
    // [739] phi from main_vera_flash::@21 to main_vera_flash::@22 [phi:main_vera_flash::@21->main_vera_flash::@22]
    // main_vera_flash::@22
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [740] call snprintf_init
    jsr snprintf_init
    // [741] phi from main_vera_flash::@22 to main_vera_flash::@23 [phi:main_vera_flash::@22->main_vera_flash::@23]
    // main_vera_flash::@23
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [742] call printf_str
    // [626] phi from main_vera_flash::@23 to printf_str [phi:main_vera_flash::@23->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main_vera_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main_vera_flash::s [phi:main_vera_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@24
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [743] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [744] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [746] call display_action_progress
    // [657] phi from main_vera_flash::@24 to display_action_progress [phi:main_vera_flash::@24->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = info_text [phi:main_vera_flash::@24->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [747] phi from main_vera_flash::@24 to main_vera_flash::@25 [phi:main_vera_flash::@24->main_vera_flash::@25]
    // main_vera_flash::@25
    // unsigned long vera_bytes_read = w25q16_read(STATUS_READING)
    // [748] call w25q16_read
    // [1208] phi from main_vera_flash::@25 to w25q16_read [phi:main_vera_flash::@25->w25q16_read]
    // [1208] phi __errno#118 = __errno#18 [phi:main_vera_flash::@25->w25q16_read#0] -- register_copy 
    // [1208] phi w25q16_read::info_status#12 = STATUS_READING [phi:main_vera_flash::@25->w25q16_read#1] -- vbuz1=vbuc1 
    lda #STATUS_READING
    sta.z w25q16_read.info_status
    jsr w25q16_read
    // unsigned long vera_bytes_read = w25q16_read(STATUS_READING)
    // [749] w25q16_read::return#3 = w25q16_read::return#0
    // main_vera_flash::@26
    // [750] main_vera_flash::vera_bytes_read#0 = w25q16_read::return#3
    // if(vera_bytes_read)
    // [751] if(0==main_vera_flash::vera_bytes_read#0) goto main_vera_flash::@1 -- 0_eq_vduz1_then_la1 
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    bne !__b1+
    jmp __b1
  !__b1:
    // [752] phi from main_vera_flash::@26 to main_vera_flash::@2 [phi:main_vera_flash::@26->main_vera_flash::@2]
    // main_vera_flash::@2
    // display_action_progress("VERA SPI activation ...")
    // [753] call display_action_progress
  // Now we loop until jumper JP1 has been placed!
    // [657] phi from main_vera_flash::@2 to display_action_progress [phi:main_vera_flash::@2->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main_vera_flash::info_text [phi:main_vera_flash::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [754] phi from main_vera_flash::@2 to main_vera_flash::@28 [phi:main_vera_flash::@2->main_vera_flash::@28]
    // main_vera_flash::@28
    // display_action_text("Please close the jumper JP1 on the VERA board!")
    // [755] call display_action_text
    // [701] phi from main_vera_flash::@28 to display_action_text [phi:main_vera_flash::@28->display_action_text]
    // [701] phi display_action_text::info_text#17 = main_vera_flash::info_text1 [phi:main_vera_flash::@28->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_text.info_text
    lda #>info_text1
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [756] phi from main_vera_flash::@28 main_vera_flash::@7 to main_vera_flash::@3 [phi:main_vera_flash::@28/main_vera_flash::@7->main_vera_flash::@3]
  __b2:
    // [756] phi main_vera_flash::spi_ensure_detect#11 = 0 [phi:main_vera_flash::@28/main_vera_flash::@7->main_vera_flash::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z spi_ensure_detect
    // main_vera_flash::@3
  __b3:
    // while(spi_ensure_detect < 16)
    // [757] if(main_vera_flash::spi_ensure_detect#11<$10) goto main_vera_flash::@4 -- vbuz1_lt_vbuc1_then_la1 
    lda.z spi_ensure_detect
    cmp #$10
    bcs !__b4+
    jmp __b4
  !__b4:
    // [758] phi from main_vera_flash::@3 to main_vera_flash::@5 [phi:main_vera_flash::@3->main_vera_flash::@5]
    // main_vera_flash::@5
    // display_action_text("The jumper JP1 has been closed on the VERA!")
    // [759] call display_action_text
    // [701] phi from main_vera_flash::@5 to display_action_text [phi:main_vera_flash::@5->display_action_text]
    // [701] phi display_action_text::info_text#17 = main_vera_flash::info_text2 [phi:main_vera_flash::@5->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [760] phi from main_vera_flash::@5 to main_vera_flash::@31 [phi:main_vera_flash::@5->main_vera_flash::@31]
    // main_vera_flash::@31
    // display_action_progress("Comparing VERA ... (.) data, (=) same, (*) different.")
    // [761] call display_action_progress
  // Now we compare the RAM with the actual VERA contents.
    // [657] phi from main_vera_flash::@31 to display_action_progress [phi:main_vera_flash::@31->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main_vera_flash::info_text3 [phi:main_vera_flash::@31->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [762] phi from main_vera_flash::@31 to main_vera_flash::@32 [phi:main_vera_flash::@31->main_vera_flash::@32]
    // main_vera_flash::@32
    // display_info_vera(STATUS_COMPARING, "")
    // [763] call display_info_vera
    // [939] phi from main_vera_flash::@32 to display_info_vera [phi:main_vera_flash::@32->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = main_vera_flash::info_text4 [phi:main_vera_flash::@32->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_vera.info_text
    lda #>info_text4
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_COMPARING [phi:main_vera_flash::@32->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [764] phi from main_vera_flash::@32 to main_vera_flash::@33 [phi:main_vera_flash::@32->main_vera_flash::@33]
    // main_vera_flash::@33
    // unsigned long vera_differences = w25q16_verify(0)
    // [765] call w25q16_verify
  // Verify VERA ...
    // [1349] phi from main_vera_flash::@33 to w25q16_verify [phi:main_vera_flash::@33->w25q16_verify]
    // [1349] phi w25q16_verify::verify#2 = 0 [phi:main_vera_flash::@33->w25q16_verify#0] -- vbum1=vbuc1 
    lda #0
    sta w25q16_verify.verify
    jsr w25q16_verify
    // unsigned long vera_differences = w25q16_verify(0)
    // [766] w25q16_verify::return#2 = w25q16_verify::w25q16_different_bytes#2
    // main_vera_flash::@34
    // [767] main_vera_flash::vera_differences#0 = w25q16_verify::return#2 -- vdum1=vdum2 
    lda w25q16_verify.return
    sta vera_differences
    lda w25q16_verify.return+1
    sta vera_differences+1
    lda w25q16_verify.return+2
    sta vera_differences+2
    lda w25q16_verify.return+3
    sta vera_differences+3
    // if (!vera_differences)
    // [768] if(0==main_vera_flash::vera_differences#0) goto main_vera_flash::@10 -- 0_eq_vdum1_then_la1 
    lda vera_differences
    ora vera_differences+1
    ora vera_differences+2
    ora vera_differences+3
    bne !__b10+
    jmp __b10
  !__b10:
    // [769] phi from main_vera_flash::@34 to main_vera_flash::@8 [phi:main_vera_flash::@34->main_vera_flash::@8]
    // main_vera_flash::@8
    // sprintf(info_text, "%u differences!", vera_differences)
    // [770] call snprintf_init
    jsr snprintf_init
    // main_vera_flash::@35
    // [771] printf_ulong::uvalue#8 = main_vera_flash::vera_differences#0 -- vdum1=vdum2 
    lda vera_differences
    sta printf_ulong.uvalue
    lda vera_differences+1
    sta printf_ulong.uvalue+1
    lda vera_differences+2
    sta printf_ulong.uvalue+2
    lda vera_differences+3
    sta printf_ulong.uvalue+3
    // [772] call printf_ulong
    // [1428] phi from main_vera_flash::@35 to printf_ulong [phi:main_vera_flash::@35->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 0 [phi:main_vera_flash::@35->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 0 [phi:main_vera_flash::@35->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = DECIMAL [phi:main_vera_flash::@35->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#8 [phi:main_vera_flash::@35->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [773] phi from main_vera_flash::@35 to main_vera_flash::@36 [phi:main_vera_flash::@35->main_vera_flash::@36]
    // main_vera_flash::@36
    // sprintf(info_text, "%u differences!", vera_differences)
    // [774] call printf_str
    // [626] phi from main_vera_flash::@36 to printf_str [phi:main_vera_flash::@36->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main_vera_flash::@36->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main_vera_flash::s1 [phi:main_vera_flash::@36->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@37
    // sprintf(info_text, "%u differences!", vera_differences)
    // [775] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [776] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_FLASH, info_text)
    // [778] call display_info_vera
    // [939] phi from main_vera_flash::@37 to display_info_vera [phi:main_vera_flash::@37->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@37->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_FLASH [phi:main_vera_flash::@37->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [779] phi from main_vera_flash::@37 to main_vera_flash::@38 [phi:main_vera_flash::@37->main_vera_flash::@38]
    // main_vera_flash::@38
    // unsigned char vera_erase_error = w25q16_erase()
    // [780] call w25q16_erase
    jsr w25q16_erase
    // [781] w25q16_erase::return#3 = w25q16_erase::return#2
    // main_vera_flash::@39
    // [782] main_vera_flash::vera_erase_error#0 = w25q16_erase::return#3
    // if(vera_erase_error)
    // [783] if(0==main_vera_flash::vera_erase_error#0) goto main_vera_flash::@11 -- 0_eq_vbuz1_then_la1 
    lda.z vera_erase_error
    beq __b11
    // [784] phi from main_vera_flash::@39 to main_vera_flash::@9 [phi:main_vera_flash::@39->main_vera_flash::@9]
    // main_vera_flash::@9
    // display_action_progress("There was an error cleaning your VERA flash memory!")
    // [785] call display_action_progress
    // [657] phi from main_vera_flash::@9 to display_action_progress [phi:main_vera_flash::@9->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main_vera_flash::info_text7 [phi:main_vera_flash::@9->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_action_progress.info_text
    lda #>info_text7
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [786] phi from main_vera_flash::@9 to main_vera_flash::@41 [phi:main_vera_flash::@9->main_vera_flash::@41]
    // main_vera_flash::@41
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [787] call display_action_text
    // [701] phi from main_vera_flash::@41 to display_action_text [phi:main_vera_flash::@41->display_action_text]
    // [701] phi display_action_text::info_text#17 = main_vera_flash::info_text8 [phi:main_vera_flash::@41->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_text.info_text
    lda #>info_text8
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [788] phi from main_vera_flash::@41 to main_vera_flash::@42 [phi:main_vera_flash::@41->main_vera_flash::@42]
    // main_vera_flash::@42
    // display_info_vera(STATUS_ERROR, "ERASE ERROR!")
    // [789] call display_info_vera
    // [939] phi from main_vera_flash::@42 to display_info_vera [phi:main_vera_flash::@42->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = main_vera_flash::info_text9 [phi:main_vera_flash::@42->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_vera.info_text
    lda #>info_text9
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@42->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [790] phi from main_vera_flash::@42 to main_vera_flash::@43 [phi:main_vera_flash::@42->main_vera_flash::@43]
    // main_vera_flash::@43
    // display_info_smc(STATUS_ERROR, NULL)
    // [791] call display_info_smc
    // [903] phi from main_vera_flash::@43 to display_info_smc [phi:main_vera_flash::@43->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = 0 [phi:main_vera_flash::@43->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main_vera_flash::@43->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    // [792] phi from main_vera_flash::@43 to main_vera_flash::@44 [phi:main_vera_flash::@43->main_vera_flash::@44]
    // main_vera_flash::@44
    // display_info_roms(STATUS_ERROR, NULL)
    // [793] call display_info_roms
    // [1454] phi from main_vera_flash::@44 to display_info_roms [phi:main_vera_flash::@44->display_info_roms]
    jsr display_info_roms
    // [794] phi from main_vera_flash::@44 to main_vera_flash::@45 [phi:main_vera_flash::@44->main_vera_flash::@45]
    // main_vera_flash::@45
    // wait_moment(32)
    // [795] call wait_moment
    // [635] phi from main_vera_flash::@45 to wait_moment [phi:main_vera_flash::@45->wait_moment]
    // [635] phi wait_moment::w#14 = $20 [phi:main_vera_flash::@45->wait_moment#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z wait_moment.w
    jsr wait_moment
    // [796] phi from main_vera_flash::@45 to main_vera_flash::@46 [phi:main_vera_flash::@45->main_vera_flash::@46]
    // main_vera_flash::@46
    // spi_deselect()
    // [797] call spi_deselect
    jsr spi_deselect
    // main_vera_flash::@return
    // }
    // [798] return 
    rts
    // [799] phi from main_vera_flash::@39 to main_vera_flash::@11 [phi:main_vera_flash::@39->main_vera_flash::@11]
    // main_vera_flash::@11
  __b11:
    // __mem unsigned long vera_flashed = w25q16_flash()
    // [800] call w25q16_flash
    // [1464] phi from main_vera_flash::@11 to w25q16_flash [phi:main_vera_flash::@11->w25q16_flash]
    jsr w25q16_flash
    // __mem unsigned long vera_flashed = w25q16_flash()
    // [801] w25q16_flash::return#3 = w25q16_flash::return#2
    // main_vera_flash::@40
    // [802] main_vera_flash::vera_flashed#0 = w25q16_flash::return#3 -- vdum1=vduz2 
    lda.z w25q16_flash.return
    sta vera_flashed
    lda.z w25q16_flash.return+1
    sta vera_flashed+1
    lda.z w25q16_flash.return+2
    sta vera_flashed+2
    lda.z w25q16_flash.return+3
    sta vera_flashed+3
    // if (vera_flashed)
    // [803] if(0!=main_vera_flash::vera_flashed#0) goto main_vera_flash::@12 -- 0_neq_vdum1_then_la1 
    lda vera_flashed
    ora vera_flashed+1
    ora vera_flashed+2
    ora vera_flashed+3
    bne __b12
    // [804] phi from main_vera_flash::@40 to main_vera_flash::@13 [phi:main_vera_flash::@40->main_vera_flash::@13]
    // main_vera_flash::@13
    // display_info_vera(STATUS_ERROR, info_text)
    // [805] call display_info_vera
  // VFL2 | Flash VERA resulting in errors
    // [939] phi from main_vera_flash::@13 to display_info_vera [phi:main_vera_flash::@13->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@13->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@13->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [806] phi from main_vera_flash::@13 to main_vera_flash::@49 [phi:main_vera_flash::@13->main_vera_flash::@49]
    // main_vera_flash::@49
    // display_action_progress("There was an error updating your VERA flash memory!")
    // [807] call display_action_progress
    // [657] phi from main_vera_flash::@49 to display_action_progress [phi:main_vera_flash::@49->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main_vera_flash::info_text10 [phi:main_vera_flash::@49->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [808] phi from main_vera_flash::@49 to main_vera_flash::@50 [phi:main_vera_flash::@49->main_vera_flash::@50]
    // main_vera_flash::@50
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [809] call display_action_text
    // [701] phi from main_vera_flash::@50 to display_action_text [phi:main_vera_flash::@50->display_action_text]
    // [701] phi display_action_text::info_text#17 = main_vera_flash::info_text11 [phi:main_vera_flash::@50->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_action_text.info_text
    lda #>info_text11
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [810] phi from main_vera_flash::@50 to main_vera_flash::@51 [phi:main_vera_flash::@50->main_vera_flash::@51]
    // main_vera_flash::@51
    // display_info_vera(STATUS_ERROR, "FLASH ERROR!")
    // [811] call display_info_vera
    // [939] phi from main_vera_flash::@51 to display_info_vera [phi:main_vera_flash::@51->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = main_vera_flash::info_text12 [phi:main_vera_flash::@51->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_vera.info_text
    lda #>info_text12
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@51->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [812] phi from main_vera_flash::@51 to main_vera_flash::@52 [phi:main_vera_flash::@51->main_vera_flash::@52]
    // main_vera_flash::@52
    // display_info_smc(STATUS_ERROR, NULL)
    // [813] call display_info_smc
    // [903] phi from main_vera_flash::@52 to display_info_smc [phi:main_vera_flash::@52->display_info_smc]
    // [903] phi display_info_smc::info_text#12 = 0 [phi:main_vera_flash::@52->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [903] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main_vera_flash::@52->display_info_smc#1] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    // [814] phi from main_vera_flash::@52 to main_vera_flash::@53 [phi:main_vera_flash::@52->main_vera_flash::@53]
    // main_vera_flash::@53
    // display_info_roms(STATUS_ERROR, NULL)
    // [815] call display_info_roms
    // [1454] phi from main_vera_flash::@53 to display_info_roms [phi:main_vera_flash::@53->display_info_roms]
    jsr display_info_roms
    // [816] phi from main_vera_flash::@53 to main_vera_flash::@54 [phi:main_vera_flash::@53->main_vera_flash::@54]
    // main_vera_flash::@54
    // wait_moment(32)
    // [817] call wait_moment
    // [635] phi from main_vera_flash::@54 to wait_moment [phi:main_vera_flash::@54->wait_moment]
    // [635] phi wait_moment::w#14 = $20 [phi:main_vera_flash::@54->wait_moment#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z wait_moment.w
    jsr wait_moment
    // [818] phi from main_vera_flash::@54 to main_vera_flash::@55 [phi:main_vera_flash::@54->main_vera_flash::@55]
    // main_vera_flash::@55
    // spi_deselect()
    // [819] call spi_deselect
    jsr spi_deselect
    rts
    // [820] phi from main_vera_flash::@40 to main_vera_flash::@12 [phi:main_vera_flash::@40->main_vera_flash::@12]
    // main_vera_flash::@12
  __b12:
    // display_info_vera(STATUS_FLASHED, NULL)
    // [821] call display_info_vera
  // VFL3 | Flash VERA and all ok
    // [939] phi from main_vera_flash::@12 to display_info_vera [phi:main_vera_flash::@12->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = 0 [phi:main_vera_flash::@12->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_FLASHED [phi:main_vera_flash::@12->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [822] phi from main_vera_flash::@12 to main_vera_flash::@47 [phi:main_vera_flash::@12->main_vera_flash::@47]
    // main_vera_flash::@47
    // __mem unsigned long vera_differences = w25q16_verify(1)
    // [823] call w25q16_verify
    // [1349] phi from main_vera_flash::@47 to w25q16_verify [phi:main_vera_flash::@47->w25q16_verify]
    // [1349] phi w25q16_verify::verify#2 = 1 [phi:main_vera_flash::@47->w25q16_verify#0] -- vbum1=vbuc1 
    lda #1
    sta w25q16_verify.verify
    jsr w25q16_verify
    // __mem unsigned long vera_differences = w25q16_verify(1)
    // [824] w25q16_verify::return#3 = w25q16_verify::w25q16_different_bytes#2
    // main_vera_flash::@48
    // [825] main_vera_flash::vera_differences1#0 = w25q16_verify::return#3 -- vdum1=vdum2 
    lda w25q16_verify.return
    sta vera_differences1
    lda w25q16_verify.return+1
    sta vera_differences1+1
    lda w25q16_verify.return+2
    sta vera_differences1+2
    lda w25q16_verify.return+3
    sta vera_differences1+3
    // if (vera_differences)
    // [826] if(0==main_vera_flash::vera_differences1#0) goto main_vera_flash::@15 -- 0_eq_vdum1_then_la1 
    lda vera_differences1
    ora vera_differences1+1
    ora vera_differences1+2
    ora vera_differences1+3
    beq __b15
    // [827] phi from main_vera_flash::@48 to main_vera_flash::@14 [phi:main_vera_flash::@48->main_vera_flash::@14]
    // main_vera_flash::@14
    // sprintf(info_text, "%u differences!", vera_differences)
    // [828] call snprintf_init
    jsr snprintf_init
    // main_vera_flash::@56
    // [829] printf_ulong::uvalue#9 = main_vera_flash::vera_differences1#0
    // [830] call printf_ulong
    // [1428] phi from main_vera_flash::@56 to printf_ulong [phi:main_vera_flash::@56->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 0 [phi:main_vera_flash::@56->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 0 [phi:main_vera_flash::@56->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = DECIMAL [phi:main_vera_flash::@56->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#9 [phi:main_vera_flash::@56->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [831] phi from main_vera_flash::@56 to main_vera_flash::@57 [phi:main_vera_flash::@56->main_vera_flash::@57]
    // main_vera_flash::@57
    // sprintf(info_text, "%u differences!", vera_differences)
    // [832] call printf_str
    // [626] phi from main_vera_flash::@57 to printf_str [phi:main_vera_flash::@57->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:main_vera_flash::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = main_vera_flash::s2 [phi:main_vera_flash::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@58
    // sprintf(info_text, "%u differences!", vera_differences)
    // [833] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [834] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_ERROR, info_text)
    // [836] call display_info_vera
    // [939] phi from main_vera_flash::@58 to display_info_vera [phi:main_vera_flash::@58->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@58->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@58->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [837] phi from main_vera_flash::@10 main_vera_flash::@48 main_vera_flash::@58 to main_vera_flash::@15 [phi:main_vera_flash::@10/main_vera_flash::@48/main_vera_flash::@58->main_vera_flash::@15]
    // main_vera_flash::@15
  __b15:
    // display_action_progress("VERA SPI de-activation ...")
    // [838] call display_action_progress
  // Now we loop until jumper JP1 is open again!
    // [657] phi from main_vera_flash::@15 to display_action_progress [phi:main_vera_flash::@15->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = main_vera_flash::info_text13 [phi:main_vera_flash::@15->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [839] phi from main_vera_flash::@15 to main_vera_flash::@59 [phi:main_vera_flash::@15->main_vera_flash::@59]
    // main_vera_flash::@59
    // display_action_text("Please OPEN the jumper JP1 on the VERA board!")
    // [840] call display_action_text
    // [701] phi from main_vera_flash::@59 to display_action_text [phi:main_vera_flash::@59->display_action_text]
    // [701] phi display_action_text::info_text#17 = main_vera_flash::info_text14 [phi:main_vera_flash::@59->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_action_text.info_text
    lda #>info_text14
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [841] phi from main_vera_flash::@59 main_vera_flash::@61 main_vera_flash::@64 main_vera_flash::@65 to main_vera_flash::@16 [phi:main_vera_flash::@59/main_vera_flash::@61/main_vera_flash::@64/main_vera_flash::@65->main_vera_flash::@16]
  __b5:
    // [841] phi main_vera_flash::spi_ensure_detect#12 = 0 [phi:main_vera_flash::@59/main_vera_flash::@61/main_vera_flash::@64/main_vera_flash::@65->main_vera_flash::@16#0] -- vbuz1=vbuc1 
    lda #0
    sta.z spi_ensure_detect_1
    // main_vera_flash::@16
  __b16:
    // while(spi_ensure_detect < 16)
    // [842] if(main_vera_flash::spi_ensure_detect#12<$10) goto main_vera_flash::@17 -- vbuz1_lt_vbuc1_then_la1 
    lda.z spi_ensure_detect_1
    cmp #$10
    bcc __b17
    // [843] phi from main_vera_flash::@16 to main_vera_flash::@18 [phi:main_vera_flash::@16->main_vera_flash::@18]
    // main_vera_flash::@18
    // display_action_text("The jumper JP1 has been opened on the VERA!")
    // [844] call display_action_text
    // [701] phi from main_vera_flash::@18 to display_action_text [phi:main_vera_flash::@18->display_action_text]
    // [701] phi display_action_text::info_text#17 = main_vera_flash::info_text15 [phi:main_vera_flash::@18->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_text.info_text
    lda #>info_text15
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [845] phi from main_vera_flash::@18 main_vera_flash::@26 to main_vera_flash::@1 [phi:main_vera_flash::@18/main_vera_flash::@26->main_vera_flash::@1]
    // main_vera_flash::@1
  __b1:
    // spi_deselect()
    // [846] call spi_deselect
    jsr spi_deselect
    // [847] phi from main_vera_flash::@1 to main_vera_flash::@27 [phi:main_vera_flash::@1->main_vera_flash::@27]
    // main_vera_flash::@27
    // wait_moment(16)
    // [848] call wait_moment
    // [635] phi from main_vera_flash::@27 to wait_moment [phi:main_vera_flash::@27->wait_moment]
    // [635] phi wait_moment::w#14 = $10 [phi:main_vera_flash::@27->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    rts
    // [849] phi from main_vera_flash::@16 to main_vera_flash::@17 [phi:main_vera_flash::@16->main_vera_flash::@17]
    // main_vera_flash::@17
  __b17:
    // w25q16_detect()
    // [850] call w25q16_detect
    // [1195] phi from main_vera_flash::@17 to w25q16_detect [phi:main_vera_flash::@17->w25q16_detect]
    jsr w25q16_detect
    // [851] phi from main_vera_flash::@17 to main_vera_flash::@60 [phi:main_vera_flash::@17->main_vera_flash::@60]
    // main_vera_flash::@60
    // wait_moment(1)
    // [852] call wait_moment
    // [635] phi from main_vera_flash::@60 to wait_moment [phi:main_vera_flash::@60->wait_moment]
    // [635] phi wait_moment::w#14 = 1 [phi:main_vera_flash::@60->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // main_vera_flash::@61
    // if(spi_manufacturer != 0xEF && spi_memory_type != 0x40 && spi_memory_capacity != 0x15)
    // [853] if(spi_manufacturer#0==$ef) goto main_vera_flash::@16 -- vbum1_eq_vbuc1_then_la1 
    lda #$ef
    cmp spi_manufacturer
    beq __b5
    // main_vera_flash::@65
    // [854] if(spi_memory_type#0==$40) goto main_vera_flash::@16 -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp spi_memory_type
    beq __b5
    // main_vera_flash::@64
    // [855] if(spi_memory_capacity#0!=$15) goto main_vera_flash::@19 -- vbum1_neq_vbuc1_then_la1 
    lda #$15
    cmp spi_memory_capacity
    bne __b19
    jmp __b5
    // main_vera_flash::@19
  __b19:
    // spi_ensure_detect++;
    // [856] main_vera_flash::spi_ensure_detect#4 = ++ main_vera_flash::spi_ensure_detect#12 -- vbuz1=_inc_vbuz1 
    inc.z spi_ensure_detect_1
    // [841] phi from main_vera_flash::@19 to main_vera_flash::@16 [phi:main_vera_flash::@19->main_vera_flash::@16]
    // [841] phi main_vera_flash::spi_ensure_detect#12 = main_vera_flash::spi_ensure_detect#4 [phi:main_vera_flash::@19->main_vera_flash::@16#0] -- register_copy 
    jmp __b16
    // [857] phi from main_vera_flash::@34 to main_vera_flash::@10 [phi:main_vera_flash::@34->main_vera_flash::@10]
    // main_vera_flash::@10
  __b10:
    // display_info_vera(STATUS_SKIP, "No update required")
    // [858] call display_info_vera
  // VFL1 | VERA and VERA.BIN equal | Display that there are no differences between the VERA and VERA.BIN. Set VERA to Flashed. | None
    // [939] phi from main_vera_flash::@10 to display_info_vera [phi:main_vera_flash::@10->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = main_vera_flash::info_text6 [phi:main_vera_flash::@10->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_vera.info_text
    lda #>info_text6
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main_vera_flash::@10->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    jmp __b15
    // [859] phi from main_vera_flash::@3 to main_vera_flash::@4 [phi:main_vera_flash::@3->main_vera_flash::@4]
    // main_vera_flash::@4
  __b4:
    // w25q16_detect()
    // [860] call w25q16_detect
    // [1195] phi from main_vera_flash::@4 to w25q16_detect [phi:main_vera_flash::@4->w25q16_detect]
    jsr w25q16_detect
    // [861] phi from main_vera_flash::@4 to main_vera_flash::@29 [phi:main_vera_flash::@4->main_vera_flash::@29]
    // main_vera_flash::@29
    // wait_moment(1)
    // [862] call wait_moment
    // [635] phi from main_vera_flash::@29 to wait_moment [phi:main_vera_flash::@29->wait_moment]
    // [635] phi wait_moment::w#14 = 1 [phi:main_vera_flash::@29->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // main_vera_flash::@30
    // if(spi_manufacturer == 0xEF && spi_memory_type == 0x40 && spi_memory_capacity == 0x15)
    // [863] if(spi_manufacturer#0!=$ef) goto main_vera_flash::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #$ef
    cmp spi_manufacturer
    bne __b7
    // main_vera_flash::@63
    // [864] if(spi_memory_type#0!=$40) goto main_vera_flash::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #$40
    cmp spi_memory_type
    bne __b7
    // main_vera_flash::@62
    // [865] if(spi_memory_capacity#0==$15) goto main_vera_flash::@6 -- vbum1_eq_vbuc1_then_la1 
    lda #$15
    cmp spi_memory_capacity
    beq __b6
    // [866] phi from main_vera_flash::@30 main_vera_flash::@62 main_vera_flash::@63 to main_vera_flash::@7 [phi:main_vera_flash::@30/main_vera_flash::@62/main_vera_flash::@63->main_vera_flash::@7]
    // main_vera_flash::@7
  __b7:
    // display_info_vera(STATUS_WAITING, "Close JP1 jumper pins!")
    // [867] call display_info_vera
    // [939] phi from main_vera_flash::@7 to display_info_vera [phi:main_vera_flash::@7->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = main_vera_flash::info_text5 [phi:main_vera_flash::@7->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_vera.info_text
    lda #>info_text5
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_WAITING [phi:main_vera_flash::@7->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_WAITING
    sta.z display_info_vera.info_status
    jsr display_info_vera
    jmp __b2
    // main_vera_flash::@6
  __b6:
    // spi_ensure_detect++;
    // [868] main_vera_flash::spi_ensure_detect#1 = ++ main_vera_flash::spi_ensure_detect#11 -- vbuz1=_inc_vbuz1 
    inc.z spi_ensure_detect
    // [756] phi from main_vera_flash::@6 to main_vera_flash::@3 [phi:main_vera_flash::@6->main_vera_flash::@3]
    // [756] phi main_vera_flash::spi_ensure_detect#11 = main_vera_flash::spi_ensure_detect#1 [phi:main_vera_flash::@6->main_vera_flash::@3#0] -- register_copy 
    jmp __b3
  .segment Data
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
    info_text4: .text ""
    .byte 0
    info_text5: .text "Close JP1 jumper pins!"
    .byte 0
    info_text6: .text "No update required"
    .byte 0
    s1: .text " differences!"
    .byte 0
    info_text7: .text "There was an error cleaning your VERA flash memory!"
    .byte 0
    info_text8: .text "DO NOT RESET or REBOOT YOUR CX16 AND WAIT!"
    .byte 0
    info_text9: .text "ERASE ERROR!"
    .byte 0
    info_text10: .text "There was an error updating your VERA flash memory!"
    .byte 0
    info_text11: .text "DO NOT RESET or REBOOT YOUR CX16 AND WAIT!"
    .byte 0
    info_text12: .text "FLASH ERROR!"
    .byte 0
    s2: .text " differences!"
    .byte 0
    info_text13: .text "VERA SPI de-activation ..."
    .byte 0
    info_text14: .text "Please OPEN the jumper JP1 on the VERA board!"
    .byte 0
    info_text15: .text "The jumper JP1 has been opened on the VERA!"
    .byte 0
    vera_differences: .dword 0
    vera_flashed: .dword 0
    .label vera_differences1 = printf_ulong.uvalue
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
// __zp($b5) char util_wait_key(__zp($37) char *info_text, __zp($39) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__10 = $5a
    .label bram = $3d
    .label brom = $50
    .label return = $6a
    .label info_text = $37
    .label ch = $d2
    .label return_1 = $66
    .label return_2 = $ba
    .label return_3 = $63
    .label return_4 = $b5
    .label filter = $39
    // display_action_text(info_text)
    // [870] display_action_text::info_text#0 = util_wait_key::info_text#6
    // [871] call display_action_text
    // [701] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [701] phi display_action_text::info_text#17 = display_action_text::info_text#0 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [872] util_wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [873] util_wait_key::brom#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z brom
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [874] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [875] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // util_wait_key::CLI1
    // asm
    // asm { cli  }
    cli
    // [877] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::CLI1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::CLI1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [879] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [880] call cbm_k_getin
    jsr cbm_k_getin
    // [881] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [882] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwuz1=vbum2 
    lda cbm_k_getin.return
    sta.z ch
    lda #0
    sta.z ch+1
    // util_wait_key::@3
    // if (filter)
    // [883] if((char *)0!=util_wait_key::filter#16) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [884] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwuz1_then_la1 
    lda.z ch
    ora.z ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [885] BRAM = util_wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [886] BROM = util_wait_key::brom#0 -- vbuz1=vbuz2 
    lda.z brom
    sta.z BROM
    // util_wait_key::@return
    // }
    // [887] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [888] strchr::str#0 = (const void *)util_wait_key::filter#16 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [889] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwuz2 
    lda.z ch
    sta strchr.c
    // [890] call strchr
    // [894] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [894] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [894] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [891] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [892] util_wait_key::$10 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [893] if(util_wait_key::$10!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__10
    ora.z util_wait_key__10+1
    bne bank_set_bram2
    jmp kbhit1
}
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($5a) void * strchr(__zp($5a) const void *str, __mem() char c)
strchr: {
    .label ptr = $5a
    .label return = $5a
    .label str = $5a
    // [895] strchr::ptr#6 = (char *)strchr::str#2
    // [896] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [896] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [897] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [898] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [898] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [899] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [900] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [901] strchr::return#8 = (void *)strchr::ptr#2
    // [898] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [898] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [902] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
  .segment Data
    c: .byte 0
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
// void display_info_smc(__mem() char info_status, __zp($44) char *info_text)
display_info_smc: {
    .label x = $50
    .label y = $3e
    .label info_text = $44
    // unsigned char x = wherex()
    // [904] call wherex
    jsr wherex
    // [905] wherex::return#10 = wherex::return#0
    // display_info_smc::@3
    // [906] display_info_smc::x#0 = wherex::return#10 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [907] call wherey
    jsr wherey
    // [908] wherey::return#10 = wherey::return#0
    // display_info_smc::@4
    // [909] display_info_smc::y#0 = wherey::return#10 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_smc = info_status
    // [910] status_smc#132 = display_info_smc::info_status#12 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [911] display_smc_led::c#1 = status_color[display_info_smc::info_status#12] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [912] call display_smc_led
    // [1531] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1531] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [913] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [914] call gotoxy
    // [457] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [457] phi gotoxy::y#26 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [915] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [916] call printf_str
    // [626] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [917] display_info_smc::$9 = display_info_smc::info_status#12 << 1 -- vbum1=vbum1_rol_1 
    asl display_info_smc__9
    // [918] printf_string::str#3 = status_text[display_info_smc::$9] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy display_info_smc__9
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [919] call printf_string
    // [1261] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [920] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [921] call printf_str
    // [626] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [922] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [923] call printf_string
    // [1261] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = smc_version_text [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_smc::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 8 [phi:display_info_smc::@9->printf_string#3] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [924] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [925] call printf_str
    // [626] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [926] phi from display_info_smc::@10 to display_info_smc::@11 [phi:display_info_smc::@10->display_info_smc::@11]
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [927] call printf_uint
    // [1537] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    // [1537] phi printf_uint::format_zero_padding#4 = 0 [phi:display_info_smc::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [1537] phi printf_uint::format_min_length#4 = 0 [phi:display_info_smc::@11->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [1537] phi printf_uint::putc#4 = &cputc [phi:display_info_smc::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1537] phi printf_uint::format_radix#4 = DECIMAL [phi:display_info_smc::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [1537] phi printf_uint::uvalue#4 = smc_bootloader [phi:display_info_smc::@11->printf_uint#4] -- vwum1=vwuc1 
    lda #<smc_bootloader
    sta printf_uint.uvalue
    lda #>smc_bootloader
    sta printf_uint.uvalue+1
    jsr printf_uint
    // [928] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [929] call printf_str
    // [626] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_smc::s3 [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [930] if((char *)0==display_info_smc::info_text#12) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [931] phi from display_info_smc::@13 to display_info_smc::@2 [phi:display_info_smc::@13->display_info_smc::@2]
    // display_info_smc::@2
    // gotoxy(INFO_X+64-28, INFO_Y)
    // [932] call gotoxy
    // [457] phi from display_info_smc::@2 to gotoxy [phi:display_info_smc::@2->gotoxy]
    // [457] phi gotoxy::y#26 = $11 [phi:display_info_smc::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = 4+$40-$1c [phi:display_info_smc::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_smc::@14
    // printf("%-25s", info_text)
    // [933] printf_string::str#5 = display_info_smc::info_text#12 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [934] call printf_string
    // [1261] phi from display_info_smc::@14 to printf_string [phi:display_info_smc::@14->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_smc::@14->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#5 [phi:display_info_smc::@14->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_smc::@14->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = $19 [phi:display_info_smc::@14->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [935] gotoxy::x#14 = display_info_smc::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [936] gotoxy::y#14 = display_info_smc::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [937] call gotoxy
    // [457] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [938] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " BL:"
    .byte 0
    s3: .text " "
    .byte 0
    .label display_info_smc__9 = main.check_status_cx16_rom6_check_status_rom1_main__0
    .label info_status = main.check_status_cx16_rom6_check_status_rom1_main__0
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__zp($ad) char info_status, __zp($35) char *info_text)
display_info_vera: {
    .label display_info_vera__9 = $ad
    .label x = $ae
    .label y = $41
    .label info_status = $ad
    .label info_text = $35
    // unsigned char x = wherex()
    // [940] call wherex
    jsr wherex
    // [941] wherex::return#11 = wherex::return#0
    // display_info_vera::@3
    // [942] display_info_vera::x#0 = wherex::return#11 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [943] call wherey
    jsr wherey
    // [944] wherey::return#11 = wherey::return#0
    // display_info_vera::@4
    // [945] display_info_vera::y#0 = wherey::return#11 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_vera = info_status
    // [946] status_vera#111 = display_info_vera::info_status#15 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [947] display_vera_led::c#1 = status_color[display_info_vera::info_status#15] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_vera_led.c
    // [948] call display_vera_led
    // [1548] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [1548] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [949] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [950] call gotoxy
    // [457] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [457] phi gotoxy::y#26 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [951] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s W25Q16", status_text[info_status])
    // [952] call printf_str
    // [626] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s W25Q16", status_text[info_status])
    // [953] display_info_vera::$9 = display_info_vera::info_status#15 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_vera__9
    // [954] printf_string::str#6 = status_text[display_info_vera::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_vera__9
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [955] call printf_string
    // [1261] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [956] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s W25Q16", status_text[info_status])
    // [957] call printf_str
    // [626] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [958] if((char *)0==display_info_vera::info_text#15) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [959] phi from display_info_vera::@9 to display_info_vera::@2 [phi:display_info_vera::@9->display_info_vera::@2]
    // display_info_vera::@2
    // gotoxy(INFO_X+64-28, INFO_Y+1)
    // [960] call gotoxy
    // [457] phi from display_info_vera::@2 to gotoxy [phi:display_info_vera::@2->gotoxy]
    // [457] phi gotoxy::y#26 = $11+1 [phi:display_info_vera::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = 4+$40-$1c [phi:display_info_vera::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_vera::@10
    // printf("%-25s", info_text)
    // [961] printf_string::str#7 = display_info_vera::info_text#15 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [962] call printf_string
    // [1261] phi from display_info_vera::@10 to printf_string [phi:display_info_vera::@10->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_vera::@10->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#7 [phi:display_info_vera::@10->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_vera::@10->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = $19 [phi:display_info_vera::@10->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [963] gotoxy::x#17 = display_info_vera::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [964] gotoxy::y#17 = display_info_vera::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [965] call gotoxy
    // [457] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#17 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#17 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [966] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " W25Q16"
    .byte 0
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
// void display_info_rom(__zp($da) char rom_chip, __zp($b5) char info_status, __zp($6d) char *info_text)
display_info_rom: {
    .label display_info_rom__6 = $3e
    .label display_info_rom__15 = $b5
    .label display_info_rom__16 = $bb
    .label rom_chip = $da
    .label x = $4a
    .label y = $6b
    .label info_status = $b5
    .label info_text = $6d
    .label display_info_rom__19 = $3e
    .label display_info_rom__20 = $3e
    // unsigned char x = wherex()
    // [968] call wherex
    jsr wherex
    // [969] wherex::return#12 = wherex::return#0
    // display_info_rom::@3
    // [970] display_info_rom::x#0 = wherex::return#12 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [971] call wherey
    jsr wherey
    // [972] wherey::return#12 = wherey::return#0
    // display_info_rom::@4
    // [973] display_info_rom::y#0 = wherey::return#12 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_rom[rom_chip] = info_status
    // [974] status_rom[display_info_rom::rom_chip#10] = display_info_rom::info_status#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [975] display_rom_led::chip#1 = display_info_rom::rom_chip#10 -- vbuz1=vbuz2 
    tya
    sta.z display_rom_led.chip
    // [976] display_rom_led::c#1 = status_color[display_info_rom::info_status#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [977] call display_rom_led
    // [1554] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [1554] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [1554] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [978] gotoxy::y#19 = display_info_rom::rom_chip#10 + $11+2 -- vbum1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta gotoxy.y
    // [979] call gotoxy
    // [457] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#19 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [980] display_info_rom::$16 = display_info_rom::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z display_info_rom__16
    // rom_chip*13
    // [981] display_info_rom::$19 = display_info_rom::$16 + display_info_rom::rom_chip#10 -- vbuz1=vbuz2_plus_vbuz3 
    clc
    adc.z rom_chip
    sta.z display_info_rom__19
    // [982] display_info_rom::$20 = display_info_rom::$19 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z display_info_rom__20
    asl
    asl
    sta.z display_info_rom__20
    // [983] display_info_rom::$6 = display_info_rom::$20 + display_info_rom::rom_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_info_rom__6
    clc
    adc.z rom_chip
    sta.z display_info_rom__6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [984] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta.z printf_string.str_1+1
    // [985] call printf_str
    // [626] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [986] printf_uchar::uvalue#0 = display_info_rom::rom_chip#10 -- vbum1=vbuz2 
    lda.z rom_chip
    sta printf_uchar.uvalue
    // [987] call printf_uchar
    // [690] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [690] phi printf_uchar::format_zero_padding#10 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [690] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [690] phi printf_uchar::putc#10 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [690] phi printf_uchar::format_radix#10 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [690] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [988] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [989] call printf_str
    // [626] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_rom::s1 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [990] display_info_rom::$15 = display_info_rom::info_status#10 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_rom__15
    // [991] printf_string::str#8 = status_text[display_info_rom::$15] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__15
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [992] call printf_string
    // [1261] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [993] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [994] call printf_str
    // [626] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_rom::s2 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [995] printf_string::str#9 = rom_device_names[display_info_rom::$16] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__16
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [996] call printf_string
    // [1261] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [997] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [998] call printf_str
    // [626] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_rom::s3 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [999] printf_string::str#29 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z printf_string.str_1
    sta.z printf_string.str
    lda.z printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1000] call printf_string
    // [1261] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#29 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = $d [phi:display_info_rom::@13->printf_string#3] -- vbum1=vbuc1 
    lda #$d
    sta printf_string.format_min_length
    jsr printf_string
    // [1001] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1002] call printf_str
    // [626] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [626] phi printf_str::putc#49 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_info_rom::s4 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1003] if((char *)0==display_info_rom::info_text#10) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // gotoxy(INFO_X+64-28, INFO_Y+rom_chip+2)
    // [1004] gotoxy::y#21 = display_info_rom::rom_chip#10 + $11+2 -- vbum1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta gotoxy.y
    // [1005] call gotoxy
    // [457] phi from display_info_rom::@2 to gotoxy [phi:display_info_rom::@2->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#21 [phi:display_info_rom::@2->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = 4+$40-$1c [phi:display_info_rom::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@16
    // printf("%-25s", info_text)
    // [1006] printf_string::str#11 = display_info_rom::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1007] call printf_string
    // [1261] phi from display_info_rom::@16 to printf_string [phi:display_info_rom::@16->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_info_rom::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#11 [phi:display_info_rom::@16->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_info_rom::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = $19 [phi:display_info_rom::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1008] gotoxy::x#20 = display_info_rom::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1009] gotoxy::y#20 = display_info_rom::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1010] call gotoxy
    // [457] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#20 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#20 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1011] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    s1: .text " "
    .byte 0
    s2: .text " "
    .byte 0
    s3: .text " "
    .byte 0
    s4: .text " "
    .byte 0
}
.segment Code
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [1013] call util_wait_key
    // [869] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [869] phi util_wait_key::filter#16 = util_wait_space::filter [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [869] phi util_wait_key::info_text#6 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [1014] return 
    rts
  .segment Data
    info_text: .text "Press [SPACE] to continue ..."
    .byte 0
    filter: .text " "
    .byte 0
}
.segment Code
  // display_info_cx16_rom
/**
 * @brief Display the ROM status of the main CX16 ROM chip.
 * 
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_cx16_rom(__zp($b5) char info_status, __zp($6d) char *info_text)
display_info_cx16_rom: {
    .label info_status = $b5
    .label info_text = $6d
    // display_info_rom(0, info_status, info_text)
    // [1016] display_info_rom::info_status#1 = display_info_cx16_rom::info_status#8
    // [1017] display_info_rom::info_text#1 = display_info_cx16_rom::info_text#8
    // [1018] call display_info_rom
    // [967] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [967] phi display_info_rom::info_text#10 = display_info_rom::info_text#1 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [967] phi display_info_rom::rom_chip#10 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z display_info_rom.rom_chip
    // [967] phi display_info_rom::info_status#10 = display_info_rom::info_status#1 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1019] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $61
    .label screenlayer__1 = $57
    .label screenlayer__2 = $bc
    .label screenlayer__5 = $af
    .label screenlayer__6 = $af
    .label screenlayer__7 = $ac
    .label screenlayer__8 = $ac
    .label screenlayer__9 = $7c
    .label screenlayer__10 = $7c
    .label screenlayer__11 = $7c
    .label screenlayer__12 = $7d
    .label screenlayer__13 = $7d
    .label screenlayer__14 = $7d
    .label screenlayer__16 = $ac
    .label screenlayer__17 = $75
    .label screenlayer__18 = $7c
    .label screenlayer__19 = $7d
    .label y = $6f
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1020] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1021] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1022] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1023] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1024] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1025] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1026] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1027] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1028] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1029] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1030] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1031] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1032] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1033] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1034] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [1035] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1036] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1037] screenlayer::$18 = (char)screenlayer::$9
    // [1038] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1039] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1040] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1041] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1042] screenlayer::$19 = (char)screenlayer::$12
    // [1043] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1044] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1045] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1046] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1047] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1047] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1047] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1048] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1049] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1050] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [1051] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1052] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1053] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1047] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1047] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1047] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1054] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1055] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1056] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1057] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1058] call gotoxy
    // [457] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [457] phi gotoxy::y#26 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1059] return 
    rts
    // [1060] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1061] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1062] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1063] call gotoxy
    // [457] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1064] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1065] call clearline
    jsr clearline
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
    // cx16_k_screen_set_mode(0)
    // [1066] cx16_k_screen_set_mode::mode = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_screen_set_mode.mode
    // [1067] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [1068] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // screenlayer1()
    // [1069] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // display_frame_init_64::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [1070] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [1071] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
    lda #<0
    sta cx16_k_screen_set_charset1_offset
    sta cx16_k_screen_set_charset1_offset+1
    // display_frame_init_64::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [1073] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [1074] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [1075] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [1076] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [1077] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [1078] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [1079] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [1080] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [1081] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [1082] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [1083] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [1084] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [1085] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [1086] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [1087] phi from display_frame_init_64::vera_layer1_show1 to display_frame_init_64::@1 [phi:display_frame_init_64::vera_layer1_show1->display_frame_init_64::@1]
    // display_frame_init_64::@1
    // textcolor(WHITE)
    // [1088] call textcolor
  // Layer 1 is the current text canvas.
    // [439] phi from display_frame_init_64::@1 to textcolor [phi:display_frame_init_64::@1->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:display_frame_init_64::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1089] phi from display_frame_init_64::@1 to display_frame_init_64::@4 [phi:display_frame_init_64::@1->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // bgcolor(BLUE)
    // [1090] call bgcolor
  // Default text color is white.
    // [444] phi from display_frame_init_64::@4 to bgcolor [phi:display_frame_init_64::@4->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_frame_init_64::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [1091] phi from display_frame_init_64::@4 to display_frame_init_64::@5 [phi:display_frame_init_64::@4->display_frame_init_64::@5]
    // display_frame_init_64::@5
    // clrscr()
    // [1092] call clrscr
    // With a blue background.
    // cx16-conio.c won't compile scrolling code for this program with the underlying define, resulting in less code overhead!
    jsr clrscr
    // display_frame_init_64::@return
    // }
    // [1093] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
}
.segment Code
  // display_frame_draw
/**
 * @brief Create the CX16 update frame for X = 64, Y = 40 positions.
 */
display_frame_draw: {
    // textcolor(LIGHT_BLUE)
    // [1095] call textcolor
    // [439] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [439] phi textcolor::color#21 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [1096] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [1097] call bgcolor
    // [444] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [1098] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [1099] call clrscr
    jsr clrscr
    // [1100] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [1101] call display_frame
    // [1601] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1601] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [1102] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [1103] call display_frame
    // [1601] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1601] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [1104] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [1105] call display_frame
    // [1601] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [1106] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [1107] call display_frame
  // Chipset areas
    // [1601] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x1
    jsr display_frame
    // [1108] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [1109] call display_frame
    // [1601] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x1
    jsr display_frame
    // [1110] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [1111] call display_frame
    // [1601] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x1
    jsr display_frame
    // [1112] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [1113] call display_frame
    // [1601] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x1
    jsr display_frame
    // [1114] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [1115] call display_frame
    // [1601] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x1
    jsr display_frame
    // [1116] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [1117] call display_frame
    // [1601] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x1
    jsr display_frame
    // [1118] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [1119] call display_frame
    // [1601] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x1
    jsr display_frame
    // [1120] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [1121] call display_frame
    // [1601] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x1
    jsr display_frame
    // [1122] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [1123] call display_frame
    // [1601] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x1
    jsr display_frame
    // [1124] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [1125] call display_frame
    // [1601] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1601] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [1126] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [1127] call display_frame
  // Progress area
    // [1601] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1601] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [1128] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [1129] call display_frame
    // [1601] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1601] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [1130] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [1131] call display_frame
    // [1601] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1601] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y
    // [1601] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [1601] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1601] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [1132] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [1133] call textcolor
    // [439] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [1134] return 
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
    // [1136] call gotoxy
    // [457] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [457] phi gotoxy::y#26 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [1137] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [1138] call printf_string
    // [1261] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1261] phi printf_string::putc#17 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = init::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<init.title_text
    sta.z printf_string.str
    lda #>init.title_text
    sta.z printf_string.str+1
    // [1261] phi printf_string::format_justify_left#17 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [1139] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($5a) const char *s)
cputsxy: {
    .label s = $5a
    // gotoxy(x, y)
    // [1141] gotoxy::x#1 = cputsxy::x#3 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1142] gotoxy::y#1 = cputsxy::y#3 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1143] call gotoxy
    // [457] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [1144] cputs::s#1 = cputsxy::s#3 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [1145] call cputs
    // [1735] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [1146] return 
    rts
  .segment Data
    y: .byte 0
    x: .byte 0
}
.segment Code
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [1148] call display_smc_led
    // [1531] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1531] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [1149] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [1150] call display_print_chip
    // [1744] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1744] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1744] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z display_print_chip.w
    // [1744] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [1151] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [1153] call display_vera_led
    // [1548] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [1548] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_vera_led.c
    jsr display_vera_led
    // [1154] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [1155] call display_print_chip
    // [1744] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1744] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1744] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z display_print_chip.w
    // [1744] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [1156] return 
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
    .label display_chip_rom__4 = $ae
    .label display_chip_rom__6 = $7f
    .label r = $c2
    .label display_chip_rom__11 = $40
    .label display_chip_rom__12 = $40
    // [1158] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [1158] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [1159] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [1160] return 
    rts
    // [1161] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [1162] call strcpy
    // [1176] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [1176] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [1176] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [1163] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z r
    asl
    sta.z display_chip_rom__11
    // [1164] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [1165] call strcat
    // [1788] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [1166] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbuz1_then_la1 
    lda.z r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [1167] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [1168] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [1169] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z display_rom_led.chip
    // [1170] call display_rom_led
    // [1554] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [1554] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [1554] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [1171] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_chip_rom__12
    clc
    adc.z r
    sta.z display_chip_rom__12
    // [1172] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz2_rol_1 
    asl
    sta.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [1173] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z display_print_chip.x
    sta.z display_print_chip.x
    // [1174] call display_print_chip
    // [1744] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1744] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1744] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z display_print_chip.w
    // [1744] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [1175] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [1158] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [1158] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($39) char *destination, char *source)
strcpy: {
    .label src = $37
    .label dst = $39
    .label destination = $39
    // [1177] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [1177] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1177] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [1178] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1179] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1180] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1181] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1182] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1183] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // display_info_led
/**
 * @brief Print the colored led of an info line in the info frame.
 * 
 * @param x Start X
 * @param y Start Y
 * @param tc Fore color
 * @param bc Back color
 */
// void display_info_led(__zp($74) char x, __zp($6c) char y, __zp($63) char tc, char bc)
display_info_led: {
    .label tc = $63
    .label y = $6c
    .label x = $74
    // textcolor(tc)
    // [1185] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [1186] call textcolor
    // [439] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [439] phi textcolor::color#21 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1187] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1188] call bgcolor
    // [444] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1189] cputcxy::x#11 = display_info_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1190] cputcxy::y#11 = display_info_led::y#4 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1191] call cputcxy
    // [1200] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1200] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [1200] phi cputcxy::y#15 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1192] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1193] call textcolor
    // [439] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [1194] return 
    rts
}
.segment CodeVera
  // w25q16_detect
w25q16_detect: {
    // spi_get_jedec()
    // [1196] call spi_get_jedec
  // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    // [1800] phi from w25q16_detect to spi_get_jedec [phi:w25q16_detect->spi_get_jedec]
    jsr spi_get_jedec
    // [1197] phi from w25q16_detect to w25q16_detect::@1 [phi:w25q16_detect->w25q16_detect::@1]
    // w25q16_detect::@1
    // spi_deselect()
    // [1198] call spi_deselect
    jsr spi_deselect
    // w25q16_detect::@return
    // }
    // [1199] return 
    rts
}
.segment Code
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__mem() char x, __mem() char y, __mem() char c)
cputcxy: {
    // gotoxy(x, y)
    // [1201] gotoxy::x#0 = cputcxy::x#15 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1202] gotoxy::y#0 = cputcxy::y#15 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1203] call gotoxy
    // [457] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1204] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1205] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1207] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    c: .byte 0
}
.segment CodeVera
  // w25q16_read
// __zp($df) unsigned long w25q16_read(__zp($74) char info_status)
w25q16_read: {
    .const bank_set_brom1_bank = 0
    .label fp = $71
    .label return = $df
    .label vera_package_read = $e3
    .label y = $ba
    // We start for VERA from 0x1:0xA000.
    .label vera_bram_ptr = $be
    .label vera_file_size = $df
    .label vera_bram_bank = $6c
    .label progress_row_current = $d2
    .label info_status = $74
    .label vera_action_text = $64
    // w25q16_read::bank_set_bram1
    // BRAM = bank
    // [1209] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // w25q16_read::@16
    // if(info_status == STATUS_READING)
    // [1210] if(w25q16_read::info_status#12==STATUS_READING) goto w25q16_read::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp.z info_status
    beq __b1
    // [1212] phi from w25q16_read::@16 to w25q16_read::@2 [phi:w25q16_read::@16->w25q16_read::@2]
    // [1212] phi w25q16_read::vera_bram_bank#14 = 0 [phi:w25q16_read::@16->w25q16_read::@2#0] -- vbuz1=vbuc1 
    lda #0
    sta.z vera_bram_bank
    // [1212] phi w25q16_read::vera_action_text#10 = w25q16_read::vera_action_text#2 [phi:w25q16_read::@16->w25q16_read::@2#1] -- pbuz1=pbuc1 
    lda #<vera_action_text_2
    sta.z vera_action_text
    lda #>vera_action_text_2
    sta.z vera_action_text+1
    jmp __b2
    // [1211] phi from w25q16_read::@16 to w25q16_read::@1 [phi:w25q16_read::@16->w25q16_read::@1]
    // w25q16_read::@1
  __b1:
    // [1212] phi from w25q16_read::@1 to w25q16_read::@2 [phi:w25q16_read::@1->w25q16_read::@2]
    // [1212] phi w25q16_read::vera_bram_bank#14 = 1 [phi:w25q16_read::@1->w25q16_read::@2#0] -- vbuz1=vbuc1 
    lda #1
    sta.z vera_bram_bank
    // [1212] phi w25q16_read::vera_action_text#10 = w25q16_read::vera_action_text#1 [phi:w25q16_read::@1->w25q16_read::@2#1] -- pbuz1=pbuc1 
    lda #<vera_action_text_1
    sta.z vera_action_text
    lda #>vera_action_text_1
    sta.z vera_action_text+1
    // w25q16_read::@2
  __b2:
    // w25q16_read::bank_set_brom1
    // BROM = bank
    // [1213] BROM = w25q16_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1214] phi from w25q16_read::bank_set_brom1 to w25q16_read::@17 [phi:w25q16_read::bank_set_brom1->w25q16_read::@17]
    // w25q16_read::@17
    // display_action_text("Opening VERA.BIN from SD card ...")
    // [1215] call display_action_text
    // [701] phi from w25q16_read::@17 to display_action_text [phi:w25q16_read::@17->display_action_text]
    // [701] phi display_action_text::info_text#17 = w25q16_read::info_text [phi:w25q16_read::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1216] phi from w25q16_read::@17 to w25q16_read::@19 [phi:w25q16_read::@17->w25q16_read::@19]
    // w25q16_read::@19
    // FILE *fp = fopen("VERA.BIN", "r")
    // [1217] call fopen
    jsr fopen
    // [1218] fopen::return#3 = fopen::return#2
    // w25q16_read::@20
    // [1219] w25q16_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1220] if((struct $2 *)0==w25q16_read::fp#0) goto w25q16_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [1221] phi from w25q16_read::@20 to w25q16_read::@4 [phi:w25q16_read::@20->w25q16_read::@4]
    // w25q16_read::@4
    // gotoxy(x, y)
    // [1222] call gotoxy
    // [457] phi from w25q16_read::@4 to gotoxy [phi:w25q16_read::@4->gotoxy]
    // [457] phi gotoxy::y#26 = PROGRESS_Y [phi:w25q16_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = PROGRESS_X [phi:w25q16_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1223] phi from w25q16_read::@4 to w25q16_read::@5 [phi:w25q16_read::@4->w25q16_read::@5]
    // [1223] phi w25q16_read::y#11 = PROGRESS_Y [phi:w25q16_read::@4->w25q16_read::@5#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1223] phi w25q16_read::progress_row_current#10 = 0 [phi:w25q16_read::@4->w25q16_read::@5#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1223] phi w25q16_read::vera_bram_ptr#13 = (char *)$a000 [phi:w25q16_read::@4->w25q16_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1223] phi w25q16_read::vera_bram_bank#10 = w25q16_read::vera_bram_bank#14 [phi:w25q16_read::@4->w25q16_read::@5#3] -- register_copy 
    // [1223] phi w25q16_read::vera_file_size#11 = 0 [phi:w25q16_read::@4->w25q16_read::@5#4] -- vduz1=vduc1 
    lda #<0
    sta.z vera_file_size
    sta.z vera_file_size+1
    lda #<0>>$10
    sta.z vera_file_size+2
    lda #>0>>$10
    sta.z vera_file_size+3
    // w25q16_read::@5
  __b5:
    // while (vera_file_size < vera_size)
    // [1224] if(w25q16_read::vera_file_size#11<vera_size) goto w25q16_read::@6 -- vduz1_lt_vduc1_then_la1 
    lda.z vera_file_size+3
    cmp #>vera_size>>$10
    bcc __b6
    bne !+
    lda.z vera_file_size+2
    cmp #<vera_size>>$10
    bcc __b6
    bne !+
    lda.z vera_file_size+1
    cmp #>vera_size
    bcc __b6
    bne !+
    lda.z vera_file_size
    cmp #<vera_size
    bcc __b6
  !:
    // w25q16_read::@9
  __b9:
    // fclose(fp)
    // [1225] fclose::stream#0 = w25q16_read::fp#0
    // [1226] call fclose
    jsr fclose
    // [1227] phi from w25q16_read::@9 to w25q16_read::@3 [phi:w25q16_read::@9->w25q16_read::@3]
    // [1227] phi w25q16_read::return#0 = w25q16_read::vera_file_size#11 [phi:w25q16_read::@9->w25q16_read::@3#0] -- register_copy 
    rts
    // [1227] phi from w25q16_read::@20 to w25q16_read::@3 [phi:w25q16_read::@20->w25q16_read::@3]
  __b4:
    // [1227] phi w25q16_read::return#0 = 0 [phi:w25q16_read::@20->w25q16_read::@3#0] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // w25q16_read::@3
    // w25q16_read::@return
    // }
    // [1228] return 
    rts
    // w25q16_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [1229] if(w25q16_read::info_status#12!=STATUS_CHECKING) goto w25q16_read::@23 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp.z info_status
    bne __b7
    // [1231] phi from w25q16_read::@6 to w25q16_read::@7 [phi:w25q16_read::@6->w25q16_read::@7]
    // [1231] phi w25q16_read::vera_bram_ptr#10 = (char *) 1024 [phi:w25q16_read::@6->w25q16_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z vera_bram_ptr
    lda #>$400
    sta.z vera_bram_ptr+1
    // [1230] phi from w25q16_read::@6 to w25q16_read::@23 [phi:w25q16_read::@6->w25q16_read::@23]
    // w25q16_read::@23
    // [1231] phi from w25q16_read::@23 to w25q16_read::@7 [phi:w25q16_read::@23->w25q16_read::@7]
    // [1231] phi w25q16_read::vera_bram_ptr#10 = w25q16_read::vera_bram_ptr#13 [phi:w25q16_read::@23->w25q16_read::@7#0] -- register_copy 
    // w25q16_read::@7
  __b7:
    // display_action_text_reading(vera_action_text, "VERA.BIN", vera_file_size, vera_size, vera_bram_bank, vera_bram_ptr)
    // [1232] display_action_text_reading::action#0 = w25q16_read::vera_action_text#10 -- pbuz1=pbuz2 
    lda.z vera_action_text
    sta.z display_action_text_reading.action
    lda.z vera_action_text+1
    sta.z display_action_text_reading.action+1
    // [1233] display_action_text_reading::bytes#0 = w25q16_read::vera_file_size#11 -- vduz1=vduz2 
    lda.z vera_file_size
    sta.z display_action_text_reading.bytes
    lda.z vera_file_size+1
    sta.z display_action_text_reading.bytes+1
    lda.z vera_file_size+2
    sta.z display_action_text_reading.bytes+2
    lda.z vera_file_size+3
    sta.z display_action_text_reading.bytes+3
    // [1234] display_action_text_reading::bram_bank#0 = w25q16_read::vera_bram_bank#10 -- vbuz1=vbuz2 
    lda.z vera_bram_bank
    sta.z display_action_text_reading.bram_bank
    // [1235] display_action_text_reading::bram_ptr#0 = w25q16_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1236] call display_action_text_reading
    // [1923] phi from w25q16_read::@7 to display_action_text_reading [phi:w25q16_read::@7->display_action_text_reading]
    jsr display_action_text_reading
    // w25q16_read::bank_set_bram2
    // BRAM = bank
    // [1237] BRAM = w25q16_read::vera_bram_bank#10 -- vbuz1=vbuz2 
    lda.z vera_bram_bank
    sta.z BRAM
    // w25q16_read::@18
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [1238] fgets::ptr#2 = w25q16_read::vera_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z fgets.ptr
    lda.z vera_bram_ptr+1
    sta.z fgets.ptr+1
    // [1239] fgets::stream#0 = w25q16_read::fp#0
    // [1240] call fgets
    jsr fgets
    // [1241] fgets::return#5 = fgets::return#1
    // w25q16_read::@21
    // [1242] w25q16_read::vera_package_read#0 = fgets::return#5 -- vwuz1=vwum2 
    lda fgets.return
    sta.z vera_package_read
    lda fgets.return+1
    sta.z vera_package_read+1
    // if (!vera_package_read)
    // [1243] if(0!=w25q16_read::vera_package_read#0) goto w25q16_read::@8 -- 0_neq_vwuz1_then_la1 
    lda.z vera_package_read
    ora.z vera_package_read+1
    bne __b8
    jmp __b9
    // w25q16_read::@8
  __b8:
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [1244] if(w25q16_read::progress_row_current#10!=VERA_PROGRESS_ROW) goto w25q16_read::@10 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b10
    lda.z progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b10
    // w25q16_read::@13
    // gotoxy(x, ++y);
    // [1245] w25q16_read::y#1 = ++ w25q16_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1246] gotoxy::y#23 = w25q16_read::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1247] call gotoxy
    // [457] phi from w25q16_read::@13 to gotoxy [phi:w25q16_read::@13->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#23 [phi:w25q16_read::@13->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = PROGRESS_X [phi:w25q16_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1248] phi from w25q16_read::@13 to w25q16_read::@10 [phi:w25q16_read::@13->w25q16_read::@10]
    // [1248] phi w25q16_read::y#22 = w25q16_read::y#1 [phi:w25q16_read::@13->w25q16_read::@10#0] -- register_copy 
    // [1248] phi w25q16_read::progress_row_current#4 = 0 [phi:w25q16_read::@13->w25q16_read::@10#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1248] phi from w25q16_read::@8 to w25q16_read::@10 [phi:w25q16_read::@8->w25q16_read::@10]
    // [1248] phi w25q16_read::y#22 = w25q16_read::y#11 [phi:w25q16_read::@8->w25q16_read::@10#0] -- register_copy 
    // [1248] phi w25q16_read::progress_row_current#4 = w25q16_read::progress_row_current#10 [phi:w25q16_read::@8->w25q16_read::@10#1] -- register_copy 
    // w25q16_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [1249] if(w25q16_read::info_status#12!=STATUS_READING) goto w25q16_read::@11 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp.z info_status
    bne __b11
    // w25q16_read::@14
    // cputc('.')
    // [1250] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1251] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // w25q16_read::@11
  __b11:
    // vera_bram_ptr += vera_package_read
    // [1253] w25q16_read::vera_bram_ptr#2 = w25q16_read::vera_bram_ptr#10 + w25q16_read::vera_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z vera_bram_ptr
    adc.z vera_package_read
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc.z vera_package_read+1
    sta.z vera_bram_ptr+1
    // vera_file_size += vera_package_read
    // [1254] w25q16_read::vera_file_size#1 = w25q16_read::vera_file_size#11 + w25q16_read::vera_package_read#0 -- vduz1=vduz1_plus_vwuz2 
    lda.z vera_file_size
    clc
    adc.z vera_package_read
    sta.z vera_file_size
    lda.z vera_file_size+1
    adc.z vera_package_read+1
    sta.z vera_file_size+1
    lda.z vera_file_size+2
    adc #0
    sta.z vera_file_size+2
    lda.z vera_file_size+3
    adc #0
    sta.z vera_file_size+3
    // progress_row_current += vera_package_read
    // [1255] w25q16_read::progress_row_current#15 = w25q16_read::progress_row_current#4 + w25q16_read::vera_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_current
    adc.z vera_package_read
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc.z vera_package_read+1
    sta.z progress_row_current+1
    // if (vera_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [1256] if(w25q16_read::vera_bram_ptr#2!=(char *)$c000) goto w25q16_read::@12 -- pbuz1_neq_pbuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b12
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b12
    // w25q16_read::@15
    // vera_bram_bank++;
    // [1257] w25q16_read::vera_bram_bank#2 = ++ w25q16_read::vera_bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z vera_bram_bank
    // [1258] phi from w25q16_read::@15 to w25q16_read::@12 [phi:w25q16_read::@15->w25q16_read::@12]
    // [1258] phi w25q16_read::vera_bram_bank#13 = w25q16_read::vera_bram_bank#2 [phi:w25q16_read::@15->w25q16_read::@12#0] -- register_copy 
    // [1258] phi w25q16_read::vera_bram_ptr#8 = (char *)$a000 [phi:w25q16_read::@15->w25q16_read::@12#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1258] phi from w25q16_read::@11 to w25q16_read::@12 [phi:w25q16_read::@11->w25q16_read::@12]
    // [1258] phi w25q16_read::vera_bram_bank#13 = w25q16_read::vera_bram_bank#10 [phi:w25q16_read::@11->w25q16_read::@12#0] -- register_copy 
    // [1258] phi w25q16_read::vera_bram_ptr#8 = w25q16_read::vera_bram_ptr#2 [phi:w25q16_read::@11->w25q16_read::@12#1] -- register_copy 
    // w25q16_read::@12
  __b12:
    // if (vera_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [1259] if(w25q16_read::vera_bram_ptr#8!=(char *)$9800) goto w25q16_read::@22 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1223] phi from w25q16_read::@12 to w25q16_read::@5 [phi:w25q16_read::@12->w25q16_read::@5]
    // [1223] phi w25q16_read::y#11 = w25q16_read::y#22 [phi:w25q16_read::@12->w25q16_read::@5#0] -- register_copy 
    // [1223] phi w25q16_read::progress_row_current#10 = w25q16_read::progress_row_current#15 [phi:w25q16_read::@12->w25q16_read::@5#1] -- register_copy 
    // [1223] phi w25q16_read::vera_bram_ptr#13 = (char *)$a000 [phi:w25q16_read::@12->w25q16_read::@5#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1223] phi w25q16_read::vera_bram_bank#10 = 1 [phi:w25q16_read::@12->w25q16_read::@5#3] -- vbuz1=vbuc1 
    lda #1
    sta.z vera_bram_bank
    // [1223] phi w25q16_read::vera_file_size#11 = w25q16_read::vera_file_size#1 [phi:w25q16_read::@12->w25q16_read::@5#4] -- register_copy 
    jmp __b5
    // [1260] phi from w25q16_read::@12 to w25q16_read::@22 [phi:w25q16_read::@12->w25q16_read::@22]
    // w25q16_read::@22
    // [1223] phi from w25q16_read::@22 to w25q16_read::@5 [phi:w25q16_read::@22->w25q16_read::@5]
    // [1223] phi w25q16_read::y#11 = w25q16_read::y#22 [phi:w25q16_read::@22->w25q16_read::@5#0] -- register_copy 
    // [1223] phi w25q16_read::progress_row_current#10 = w25q16_read::progress_row_current#15 [phi:w25q16_read::@22->w25q16_read::@5#1] -- register_copy 
    // [1223] phi w25q16_read::vera_bram_ptr#13 = w25q16_read::vera_bram_ptr#8 [phi:w25q16_read::@22->w25q16_read::@5#2] -- register_copy 
    // [1223] phi w25q16_read::vera_bram_bank#10 = w25q16_read::vera_bram_bank#13 [phi:w25q16_read::@22->w25q16_read::@5#3] -- register_copy 
    // [1223] phi w25q16_read::vera_file_size#11 = w25q16_read::vera_file_size#1 [phi:w25q16_read::@22->w25q16_read::@5#4] -- register_copy 
  .segment Data
    info_text: .text "Opening VERA.BIN from SD card ..."
    .byte 0
    path: .text "VERA.BIN"
    .byte 0
    file: .text "VERA.BIN"
    .byte 0
    vera_action_text_1: .text "Reading"
    .byte 0
    vera_action_text_2: .text "Checking"
    .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($51) void (*putc)(char), __zp($3b) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $46
    .label str = $3b
    .label str_1 = $55
    .label putc = $51
    // if(format.min_length)
    // [1262] if(0==printf_string::format_min_length#17) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1263] strlen::str#3 = printf_string::str#17 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1264] call strlen
    // [1998] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1998] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1265] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1266] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1267] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1268] printf_string::padding#1 = (signed char)printf_string::format_min_length#17 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1269] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1271] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1271] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1270] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1271] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1271] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1272] if(0!=printf_string::format_justify_left#17) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1273] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1274] printf_padding::putc#3 = printf_string::putc#17 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1275] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1276] call printf_padding
    // [2004] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2004] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2004] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2004] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1277] printf_str::putc#1 = printf_string::putc#17 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1278] printf_str::s#2 = printf_string::str#17
    // [1279] call printf_str
    // [626] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [626] phi printf_str::putc#49 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [626] phi printf_str::s#49 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1280] if(0==printf_string::format_justify_left#17) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1281] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1282] printf_padding::putc#4 = printf_string::putc#17 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1283] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1284] call printf_padding
    // [2004] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2004] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2004] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2004] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1285] return 
    rts
  .segment Data
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
    format_justify_left: .byte 0
}
.segment Code
  // wherex
// Return the x position of the cursor
wherex: {
    // return __conio.cursor_x;
    // [1286] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [1287] return 
    rts
  .segment Data
    return: .byte 0
}
.segment Code
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [1288] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [1289] return 
    rts
  .segment Data
    return: .byte 0
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
    .label uctoa__4 = $41
    .label buffer = $35
    .label digit_values = $44
    // if(radix==DECIMAL)
    // [1290] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1291] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1292] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1293] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1294] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1295] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1296] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1297] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1298] return 
    rts
    // [1299] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1299] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1299] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1299] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1299] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1299] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [1299] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1299] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1299] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1299] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1299] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1299] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [1300] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1300] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1300] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1300] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1300] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1301] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1302] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1303] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1304] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1305] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1306] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [1307] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [1308] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [1309] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1309] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1309] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1309] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1310] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1300] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1300] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1300] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1300] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1300] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1311] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1312] uctoa_append::value#0 = uctoa::value#2
    // [1313] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1314] call uctoa_append
    // [2012] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1315] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1316] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1317] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1309] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1309] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1309] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1309] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
// void printf_number_buffer(__zp($48) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $4b
    .label putc = $48
    // if(format.min_length)
    // [1319] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [1320] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1321] call strlen
    // [1998] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1998] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1322] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1323] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [1324] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [1325] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1326] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1327] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1327] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1328] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1329] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1331] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1331] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1330] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1331] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1331] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1332] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1333] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1334] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1335] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1336] call printf_padding
    // [2004] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2004] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2004] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2004] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1337] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1338] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1339] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall11
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1341] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1342] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1343] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1344] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1345] call printf_padding
    // [2004] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2004] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2004] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [2004] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1346] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1347] call printf_str
    // [626] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [626] phi printf_str::putc#49 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [626] phi printf_str::s#49 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1348] return 
    rts
    // Outside Flow
  icall11:
    jmp (putc)
  .segment Data
    buffer_sign: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
    len: .byte 0
    .label padding = len
}
.segment CodeVera
  // w25q16_verify
/**
 * @brief Verify the w25q16 flash memory contents with the VERA.BIN file contents loaded from RAM $01:A000.
 * 
 * @return unsigned long The total different bytes identified.
 */
// __mem() unsigned long w25q16_verify(__mem() char verify)
w25q16_verify: {
    .label w25q16_verify__9 = $b6
    .label w25q16_verify__12 = $c3
    .label w25q16_verify__18 = $6b
    .label w25q16_verify__30 = $7b
    /// Holds the amount of bytes actually verified between the VERA and the RAM.
    .label w25q16_compare_size = $7b
    .label w25q16_byte = $4a
    .label bram_ptr = $5e
    /// Holds the amount of correct and verified bytes flashed in the VERA.
    .label w25q16_compared_bytes = $bb
    // WARNING: if VERA_PROGRESS_CELL every needs to be a value larger than 128 then the char scalar widtg needs to be extended to an int.
    .label w25q16_equal_bytes = $b3
    .label y = $78
    .label w25q16_address = $f3
    .label bram_bank = $6a
    /// Holds the amount of correct and verified bytes flashed in the VERA.
    .label w25q16_compared_bytes_1 = $ad
    .label progress_row_current = $c7
    .label different_char = $66
    // w25q16_verify::bank_set_bram1
    // BRAM = bank
    // [1350] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // w25q16_verify::@21
    // if(verify)
    // [1351] if(0!=w25q16_verify::verify#2) goto w25q16_verify::@1 -- 0_neq_vbum1_then_la1 
    lda verify
    beq !__b1+
    jmp __b1
  !__b1:
    // [1352] phi from w25q16_verify::@21 to w25q16_verify::@3 [phi:w25q16_verify::@21->w25q16_verify::@3]
    // w25q16_verify::@3
    // display_action_progress("Comparing VERA with VERA.BIN ... (.) data, (=) same, (*) different.")
    // [1353] call display_action_progress
    // [657] phi from w25q16_verify::@3 to display_action_progress [phi:w25q16_verify::@3->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = w25q16_verify::info_text1 [phi:w25q16_verify::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1354] phi from w25q16_verify::@3 to w25q16_verify::@2 [phi:w25q16_verify::@3->w25q16_verify::@2]
    // [1354] phi w25q16_verify::different_char#16 = '*' [phi:w25q16_verify::@3->w25q16_verify::@2#0] -- vbuz1=vbuc1 
    lda #'*'
    sta.z different_char
    // w25q16_verify::@2
  __b2:
    // gotoxy(x, y)
    // [1355] call gotoxy
    // [457] phi from w25q16_verify::@2 to gotoxy [phi:w25q16_verify::@2->gotoxy]
    // [457] phi gotoxy::y#26 = PROGRESS_Y [phi:w25q16_verify::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = PROGRESS_X [phi:w25q16_verify::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1356] phi from w25q16_verify::@2 to w25q16_verify::@22 [phi:w25q16_verify::@2->w25q16_verify::@22]
    // w25q16_verify::@22
    // wait_moment(16)
    // [1357] call wait_moment
    // [635] phi from w25q16_verify::@22 to wait_moment [phi:w25q16_verify::@22->wait_moment]
    // [635] phi wait_moment::w#14 = $10 [phi:w25q16_verify::@22->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    // [1358] phi from w25q16_verify::@22 to w25q16_verify::@23 [phi:w25q16_verify::@22->w25q16_verify::@23]
    // w25q16_verify::@23
    // spi_wait_non_busy()
    // [1359] call spi_wait_non_busy
    // [2019] phi from w25q16_verify::@23 to spi_wait_non_busy [phi:w25q16_verify::@23->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // [1360] phi from w25q16_verify::@23 to w25q16_verify::@24 [phi:w25q16_verify::@23->w25q16_verify::@24]
    // w25q16_verify::@24
    // spi_read_flash(0UL)
    // [1361] call spi_read_flash
    // [2036] phi from w25q16_verify::@24 to spi_read_flash [phi:w25q16_verify::@24->spi_read_flash]
    jsr spi_read_flash
    // [1362] phi from w25q16_verify::@24 to w25q16_verify::@4 [phi:w25q16_verify::@24->w25q16_verify::@4]
    // [1362] phi w25q16_verify::y#15 = PROGRESS_Y [phi:w25q16_verify::@24->w25q16_verify::@4#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1362] phi w25q16_verify::progress_row_current#12 = 0 [phi:w25q16_verify::@24->w25q16_verify::@4#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1362] phi w25q16_verify::bram_ptr#14 = (char *)$a000 [phi:w25q16_verify::@24->w25q16_verify::@4#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z bram_ptr
    lda #>$a000
    sta.z bram_ptr+1
    // [1362] phi w25q16_verify::w25q16_different_bytes#2 = 0 [phi:w25q16_verify::@24->w25q16_verify::@4#3] -- vdum1=vduc1 
    lda #<0
    sta w25q16_different_bytes
    sta w25q16_different_bytes+1
    lda #<0>>$10
    sta w25q16_different_bytes+2
    lda #>0>>$10
    sta w25q16_different_bytes+3
    // [1362] phi w25q16_verify::bank_set_bram2_bank#0 = 1 [phi:w25q16_verify::@24->w25q16_verify::@4#4] -- vbum1=vbuc1 
    lda #1
    sta bank_set_bram2_bank
    // [1362] phi w25q16_verify::w25q16_address#2 = 0 [phi:w25q16_verify::@24->w25q16_verify::@4#5] -- vduz1=vduc1 
    lda #<0
    sta.z w25q16_address
    sta.z w25q16_address+1
    lda #<0>>$10
    sta.z w25q16_address+2
    lda #>0>>$10
    sta.z w25q16_address+3
  // Start the w26q16 flash memory read cycle from 0x0 using the spi interface
    // w25q16_verify::@4
  __b4:
    // while (w25q16_address < vera_file_size)
    // [1363] if(w25q16_verify::w25q16_address#2<vera_file_size#1) goto w25q16_verify::@5 -- vduz1_lt_vdum2_then_la1 
    lda.z w25q16_address+3
    cmp vera_file_size+3
    bcc __b5
    bne !+
    lda.z w25q16_address+2
    cmp vera_file_size+2
    bcc __b5
    bne !+
    lda.z w25q16_address+1
    cmp vera_file_size+1
    bcc __b5
    bne !+
    lda.z w25q16_address
    cmp vera_file_size
    bcc __b5
  !:
    // [1364] phi from w25q16_verify::@4 to w25q16_verify::@6 [phi:w25q16_verify::@4->w25q16_verify::@6]
    // w25q16_verify::@6
    // wait_moment(16)
    // [1365] call wait_moment
    // [635] phi from w25q16_verify::@6 to wait_moment [phi:w25q16_verify::@6->wait_moment]
    // [635] phi wait_moment::w#14 = $10 [phi:w25q16_verify::@6->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    // w25q16_verify::@return
    // }
    // [1366] return 
    rts
    // w25q16_verify::@5
  __b5:
    // w25q16_address + VERA_PROGRESS_CELL
    // [1367] w25q16_verify::$9 = w25q16_verify::w25q16_address#2 + VERA_PROGRESS_CELL -- vduz1=vduz2_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc.z w25q16_address
    sta.z w25q16_verify__9
    lda.z w25q16_address+1
    adc #0
    sta.z w25q16_verify__9+1
    lda.z w25q16_address+2
    adc #0
    sta.z w25q16_verify__9+2
    lda.z w25q16_address+3
    adc #0
    sta.z w25q16_verify__9+3
    // if(w25q16_address + VERA_PROGRESS_CELL > vera_file_size)
    // [1368] if(w25q16_verify::$9<=vera_file_size#1) goto w25q16_verify::@7 -- vduz1_le_vdum2_then_la1 
    lda vera_file_size+3
    cmp.z w25q16_verify__9+3
    bcc !+
    bne __b3
    lda vera_file_size+2
    cmp.z w25q16_verify__9+2
    bcc !+
    bne __b3
    lda vera_file_size+1
    cmp.z w25q16_verify__9+1
    bcc !+
    bne __b3
    lda vera_file_size
    cmp.z w25q16_verify__9
    bcs __b3
  !:
    // w25q16_verify::@18
    // vera_file_size - w25q16_address
    // [1369] w25q16_verify::$12 = vera_file_size#1 - w25q16_verify::w25q16_address#2 -- vduz1=vdum2_minus_vduz3 
    lda vera_file_size
    sec
    sbc.z w25q16_address
    sta.z w25q16_verify__12
    lda vera_file_size+1
    sbc.z w25q16_address+1
    sta.z w25q16_verify__12+1
    lda vera_file_size+2
    sbc.z w25q16_address+2
    sta.z w25q16_verify__12+2
    lda vera_file_size+3
    sbc.z w25q16_address+3
    sta.z w25q16_verify__12+3
    // w25q16_compare_size = BYTE0(vera_file_size - w25q16_address)
    // [1370] w25q16_verify::w25q16_compare_size#1 = byte0  w25q16_verify::$12 -- vbuz1=_byte0_vduz2 
    lda.z w25q16_verify__12
    sta.z w25q16_compare_size
    // [1371] phi from w25q16_verify::@18 to w25q16_verify::@7 [phi:w25q16_verify::@18->w25q16_verify::@7]
    // [1371] phi w25q16_verify::w25q16_compare_size#15 = w25q16_verify::w25q16_compare_size#1 [phi:w25q16_verify::@18->w25q16_verify::@7#0] -- register_copy 
    jmp __b7
    // [1371] phi from w25q16_verify::@5 to w25q16_verify::@7 [phi:w25q16_verify::@5->w25q16_verify::@7]
  __b3:
    // [1371] phi w25q16_verify::w25q16_compare_size#15 = VERA_PROGRESS_CELL [phi:w25q16_verify::@5->w25q16_verify::@7#0] -- vbuz1=vbuc1 
    lda #VERA_PROGRESS_CELL
    sta.z w25q16_compare_size
    // w25q16_verify::@7
  __b7:
    // w25q16_verify::bank_set_bram2
    // BRAM = bank
    // [1372] BRAM = w25q16_verify::bank_set_bram2_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram2_bank
    sta.z BRAM
    // [1373] phi from w25q16_verify::bank_set_bram2 to w25q16_verify::@8 [phi:w25q16_verify::bank_set_bram2->w25q16_verify::@8]
    // [1373] phi w25q16_verify::w25q16_equal_bytes#10 = 0 [phi:w25q16_verify::bank_set_bram2->w25q16_verify::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z w25q16_equal_bytes
    // [1373] phi w25q16_verify::w25q16_compared_bytes#2 = 0 [phi:w25q16_verify::bank_set_bram2->w25q16_verify::@8#1] -- vbuz1=vbuc1 
    sta.z w25q16_compared_bytes_1
    // [1373] phi w25q16_verify::bram_ptr#10 = w25q16_verify::bram_ptr#14 [phi:w25q16_verify::bank_set_bram2->w25q16_verify::@8#2] -- register_copy 
    // w25q16_verify::@8
  __b8:
    // unsigned char w25q16_byte = spi_read()
    // [1374] call spi_read
    jsr spi_read
    // [1375] spi_read::return#14 = spi_read::return#12
    // w25q16_verify::@25
    // [1376] w25q16_verify::w25q16_byte#0 = spi_read::return#14
    // if (w25q16_byte == *bram_ptr)
    // [1377] if(w25q16_verify::w25q16_byte#0!=*w25q16_verify::bram_ptr#10) goto w25q16_verify::@9 -- vbuz1_neq__deref_pbuz2_then_la1 
    ldy #0
    lda (bram_ptr),y
    cmp.z w25q16_byte
    bne __b9
    // w25q16_verify::@10
    // w25q16_equal_bytes++;
    // [1378] w25q16_verify::w25q16_equal_bytes#1 = ++ w25q16_verify::w25q16_equal_bytes#10 -- vbuz1=_inc_vbuz1 
    inc.z w25q16_equal_bytes
    // [1379] phi from w25q16_verify::@10 w25q16_verify::@25 to w25q16_verify::@9 [phi:w25q16_verify::@10/w25q16_verify::@25->w25q16_verify::@9]
    // [1379] phi w25q16_verify::w25q16_equal_bytes#11 = w25q16_verify::w25q16_equal_bytes#1 [phi:w25q16_verify::@10/w25q16_verify::@25->w25q16_verify::@9#0] -- register_copy 
    // w25q16_verify::@9
  __b9:
    // bram_ptr++;
    // [1380] w25q16_verify::bram_ptr#1 = ++ w25q16_verify::bram_ptr#10 -- pbuz1=_inc_pbuz1 
    inc.z bram_ptr
    bne !+
    inc.z bram_ptr+1
  !:
    // w25q16_compare_size-1
    // [1381] w25q16_verify::$18 = w25q16_verify::w25q16_compare_size#15 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z w25q16_compare_size
    dex
    stx.z w25q16_verify__18
    // while(w25q16_compared_bytes++ != w25q16_compare_size-1)
    // [1382] w25q16_verify::w25q16_compared_bytes#1 = ++ w25q16_verify::w25q16_compared_bytes#2 -- vbuz1=_inc_vbuz2 
    lda.z w25q16_compared_bytes_1
    inc
    sta.z w25q16_compared_bytes
    // [1383] if(w25q16_verify::w25q16_compared_bytes#2!=w25q16_verify::$18) goto w25q16_verify::@34 -- vbuz1_neq_vbuz2_then_la1 
    lda.z w25q16_compared_bytes_1
    cmp.z w25q16_verify__18
    beq !__b34+
    jmp __b34
  !__b34:
    // w25q16_verify::@11
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [1384] if(w25q16_verify::progress_row_current#12!=VERA_PROGRESS_ROW) goto w25q16_verify::@13 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b13
    lda.z progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b13
    // w25q16_verify::@12
    // gotoxy(x, ++y);
    // [1385] w25q16_verify::y#1 = ++ w25q16_verify::y#15 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1386] gotoxy::y#25 = w25q16_verify::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1387] call gotoxy
    // [457] phi from w25q16_verify::@12 to gotoxy [phi:w25q16_verify::@12->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#25 [phi:w25q16_verify::@12->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = PROGRESS_X [phi:w25q16_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1388] phi from w25q16_verify::@12 to w25q16_verify::@13 [phi:w25q16_verify::@12->w25q16_verify::@13]
    // [1388] phi w25q16_verify::y#21 = w25q16_verify::y#1 [phi:w25q16_verify::@12->w25q16_verify::@13#0] -- register_copy 
    // [1388] phi w25q16_verify::progress_row_current#10 = 0 [phi:w25q16_verify::@12->w25q16_verify::@13#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1388] phi from w25q16_verify::@11 to w25q16_verify::@13 [phi:w25q16_verify::@11->w25q16_verify::@13]
    // [1388] phi w25q16_verify::y#21 = w25q16_verify::y#15 [phi:w25q16_verify::@11->w25q16_verify::@13#0] -- register_copy 
    // [1388] phi w25q16_verify::progress_row_current#10 = w25q16_verify::progress_row_current#12 [phi:w25q16_verify::@11->w25q16_verify::@13#1] -- register_copy 
    // w25q16_verify::@13
  __b13:
    // if (w25q16_equal_bytes != w25q16_compare_size)
    // [1389] if(w25q16_verify::w25q16_equal_bytes#11!=w25q16_verify::w25q16_compare_size#15) goto w25q16_verify::@14 -- vbuz1_neq_vbuz2_then_la1 
    lda.z w25q16_equal_bytes
    cmp.z w25q16_compare_size
    beq !__b14+
    jmp __b14
  !__b14:
    // w25q16_verify::@19
    // cputc('=')
    // [1390] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1391] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // w25q16_verify::@15
  __b15:
    // w25q16_address += VERA_PROGRESS_CELL
    // [1393] w25q16_verify::w25q16_address#1 = w25q16_verify::w25q16_address#2 + VERA_PROGRESS_CELL -- vduz1=vduz1_plus_vbuc1 
    // vera_bram_ptr += VERA_PROGRESS_CELL;
    lda.z w25q16_address
    clc
    adc #VERA_PROGRESS_CELL
    sta.z w25q16_address
    bcc !+
    inc.z w25q16_address+1
    bne !+
    inc.z w25q16_address+2
    bne !+
    inc.z w25q16_address+3
  !:
    // progress_row_current += VERA_PROGRESS_CELL
    // [1394] w25q16_verify::progress_row_current#18 = w25q16_verify::progress_row_current#10 + VERA_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc.z progress_row_current
    sta.z progress_row_current
    bcc !+
    inc.z progress_row_current+1
  !:
    // if (bram_ptr == BRAM_HIGH)
    // [1395] if(w25q16_verify::bram_ptr#1!=$c000) goto w25q16_verify::@16 -- pbuz1_neq_vwuc1_then_la1 
    lda.z bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z bram_ptr
    cmp #<$c000
    bne __b6
    // w25q16_verify::@20
    // bram_bank++;
    // [1396] w25q16_verify::bram_bank#1 = ++ w25q16_verify::bank_set_bram2_bank#0 -- vbuz1=_inc_vbum2 
    lda bank_set_bram2_bank
    inc
    sta.z bram_bank
    // [1397] phi from w25q16_verify::@20 to w25q16_verify::@16 [phi:w25q16_verify::@20->w25q16_verify::@16]
    // [1397] phi w25q16_verify::bram_bank#21 = w25q16_verify::bram_bank#1 [phi:w25q16_verify::@20->w25q16_verify::@16#0] -- register_copy 
    // [1397] phi w25q16_verify::bram_ptr#7 = (char *)$a000 [phi:w25q16_verify::@20->w25q16_verify::@16#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z bram_ptr
    lda #>$a000
    sta.z bram_ptr+1
    jmp __b16
    // [1397] phi from w25q16_verify::@15 to w25q16_verify::@16 [phi:w25q16_verify::@15->w25q16_verify::@16]
  __b6:
    // [1397] phi w25q16_verify::bram_bank#21 = w25q16_verify::bank_set_bram2_bank#0 [phi:w25q16_verify::@15->w25q16_verify::@16#0] -- vbuz1=vbum2 
    lda bank_set_bram2_bank
    sta.z bram_bank
    // [1397] phi w25q16_verify::bram_ptr#7 = w25q16_verify::bram_ptr#1 [phi:w25q16_verify::@15->w25q16_verify::@16#1] -- register_copy 
    // w25q16_verify::@16
  __b16:
    // if (bram_ptr == RAM_HIGH)
    // [1398] if(w25q16_verify::bram_ptr#7!=$9800) goto w25q16_verify::@35 -- pbuz1_neq_vwuc1_then_la1 
    lda.z bram_ptr+1
    cmp #>$9800
    bne __b17
    lda.z bram_ptr
    cmp #<$9800
    bne __b17
    // [1400] phi from w25q16_verify::@16 to w25q16_verify::@17 [phi:w25q16_verify::@16->w25q16_verify::@17]
    // [1400] phi w25q16_verify::bram_ptr#13 = (char *)$a000 [phi:w25q16_verify::@16->w25q16_verify::@17#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z bram_ptr
    lda #>$a000
    sta.z bram_ptr+1
    // [1400] phi w25q16_verify::bram_bank#13 = 1 [phi:w25q16_verify::@16->w25q16_verify::@17#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1399] phi from w25q16_verify::@16 to w25q16_verify::@35 [phi:w25q16_verify::@16->w25q16_verify::@35]
    // w25q16_verify::@35
    // [1400] phi from w25q16_verify::@35 to w25q16_verify::@17 [phi:w25q16_verify::@35->w25q16_verify::@17]
    // [1400] phi w25q16_verify::bram_ptr#13 = w25q16_verify::bram_ptr#7 [phi:w25q16_verify::@35->w25q16_verify::@17#0] -- register_copy 
    // [1400] phi w25q16_verify::bram_bank#13 = w25q16_verify::bram_bank#21 [phi:w25q16_verify::@35->w25q16_verify::@17#1] -- register_copy 
    // w25q16_verify::@17
  __b17:
    // w25q16_compare_size - w25q16_equal_bytes
    // [1401] w25q16_verify::$30 = w25q16_verify::w25q16_compare_size#15 - w25q16_verify::w25q16_equal_bytes#11 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z w25q16_verify__30
    sec
    sbc.z w25q16_equal_bytes
    sta.z w25q16_verify__30
    // w25q16_different_bytes += (w25q16_compare_size - w25q16_equal_bytes)
    // [1402] w25q16_verify::w25q16_different_bytes#1 = w25q16_verify::w25q16_different_bytes#2 + w25q16_verify::$30 -- vdum1=vdum1_plus_vbuz2 
    clc
    adc w25q16_different_bytes
    sta w25q16_different_bytes
    lda w25q16_different_bytes+1
    adc #0
    sta w25q16_different_bytes+1
    lda w25q16_different_bytes+2
    adc #0
    sta w25q16_different_bytes+2
    lda w25q16_different_bytes+3
    adc #0
    sta w25q16_different_bytes+3
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [1403] call snprintf_init
    jsr snprintf_init
    // w25q16_verify::@26
    // [1404] printf_ulong::uvalue#6 = w25q16_verify::w25q16_different_bytes#1 -- vdum1=vdum2 
    lda w25q16_different_bytes
    sta printf_ulong.uvalue
    lda w25q16_different_bytes+1
    sta printf_ulong.uvalue+1
    lda w25q16_different_bytes+2
    sta printf_ulong.uvalue+2
    lda w25q16_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1405] call printf_ulong
    // [1428] phi from w25q16_verify::@26 to printf_ulong [phi:w25q16_verify::@26->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 1 [phi:w25q16_verify::@26->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 5 [phi:w25q16_verify::@26->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:w25q16_verify::@26->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#6 [phi:w25q16_verify::@26->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1406] phi from w25q16_verify::@26 to w25q16_verify::@27 [phi:w25q16_verify::@26->w25q16_verify::@27]
    // w25q16_verify::@27
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [1407] call printf_str
    // [626] phi from w25q16_verify::@27 to printf_str [phi:w25q16_verify::@27->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:w25q16_verify::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = w25q16_verify::s [phi:w25q16_verify::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // w25q16_verify::@28
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [1408] printf_uchar::uvalue#3 = w25q16_verify::bram_bank#13 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [1409] call printf_uchar
    // [690] phi from w25q16_verify::@28 to printf_uchar [phi:w25q16_verify::@28->printf_uchar]
    // [690] phi printf_uchar::format_zero_padding#10 = 1 [phi:w25q16_verify::@28->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [690] phi printf_uchar::format_min_length#10 = 2 [phi:w25q16_verify::@28->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [690] phi printf_uchar::putc#10 = &snputc [phi:w25q16_verify::@28->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [690] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:w25q16_verify::@28->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [690] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#3 [phi:w25q16_verify::@28->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1410] phi from w25q16_verify::@28 to w25q16_verify::@29 [phi:w25q16_verify::@28->w25q16_verify::@29]
    // w25q16_verify::@29
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [1411] call printf_str
    // [626] phi from w25q16_verify::@29 to printf_str [phi:w25q16_verify::@29->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:w25q16_verify::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = w25q16_verify::s1 [phi:w25q16_verify::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // w25q16_verify::@30
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [1412] printf_uint::uvalue#3 = (unsigned int)w25q16_verify::bram_ptr#13 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [1413] call printf_uint
    // [1537] phi from w25q16_verify::@30 to printf_uint [phi:w25q16_verify::@30->printf_uint]
    // [1537] phi printf_uint::format_zero_padding#4 = 1 [phi:w25q16_verify::@30->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1537] phi printf_uint::format_min_length#4 = 4 [phi:w25q16_verify::@30->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1537] phi printf_uint::putc#4 = &snputc [phi:w25q16_verify::@30->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1537] phi printf_uint::format_radix#4 = HEXADECIMAL [phi:w25q16_verify::@30->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1537] phi printf_uint::uvalue#4 = printf_uint::uvalue#3 [phi:w25q16_verify::@30->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1414] phi from w25q16_verify::@30 to w25q16_verify::@31 [phi:w25q16_verify::@30->w25q16_verify::@31]
    // w25q16_verify::@31
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [1415] call printf_str
    // [626] phi from w25q16_verify::@31 to printf_str [phi:w25q16_verify::@31->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:w25q16_verify::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = w25q16_verify::s2 [phi:w25q16_verify::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // w25q16_verify::@32
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [1416] printf_ulong::uvalue#7 = w25q16_verify::w25q16_address#1 -- vdum1=vduz2 
    lda.z w25q16_address
    sta printf_ulong.uvalue
    lda.z w25q16_address+1
    sta printf_ulong.uvalue+1
    lda.z w25q16_address+2
    sta printf_ulong.uvalue+2
    lda.z w25q16_address+3
    sta printf_ulong.uvalue+3
    // [1417] call printf_ulong
    // [1428] phi from w25q16_verify::@32 to printf_ulong [phi:w25q16_verify::@32->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 1 [phi:w25q16_verify::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 5 [phi:w25q16_verify::@32->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:w25q16_verify::@32->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#7 [phi:w25q16_verify::@32->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // w25q16_verify::@33
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [1418] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1419] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1421] call display_action_text
    // [701] phi from w25q16_verify::@33 to display_action_text [phi:w25q16_verify::@33->display_action_text]
    // [701] phi display_action_text::info_text#17 = info_text [phi:w25q16_verify::@33->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1362] phi from w25q16_verify::@33 to w25q16_verify::@4 [phi:w25q16_verify::@33->w25q16_verify::@4]
    // [1362] phi w25q16_verify::y#15 = w25q16_verify::y#21 [phi:w25q16_verify::@33->w25q16_verify::@4#0] -- register_copy 
    // [1362] phi w25q16_verify::progress_row_current#12 = w25q16_verify::progress_row_current#18 [phi:w25q16_verify::@33->w25q16_verify::@4#1] -- register_copy 
    // [1362] phi w25q16_verify::bram_ptr#14 = w25q16_verify::bram_ptr#13 [phi:w25q16_verify::@33->w25q16_verify::@4#2] -- register_copy 
    // [1362] phi w25q16_verify::w25q16_different_bytes#2 = w25q16_verify::w25q16_different_bytes#1 [phi:w25q16_verify::@33->w25q16_verify::@4#3] -- register_copy 
    // [1362] phi w25q16_verify::bank_set_bram2_bank#0 = w25q16_verify::bram_bank#13 [phi:w25q16_verify::@33->w25q16_verify::@4#4] -- vbum1=vbuz2 
    lda.z bram_bank
    sta bank_set_bram2_bank
    // [1362] phi w25q16_verify::w25q16_address#2 = w25q16_verify::w25q16_address#1 [phi:w25q16_verify::@33->w25q16_verify::@4#5] -- register_copy 
    jmp __b4
    // w25q16_verify::@14
  __b14:
    // cputc(different_char)
    // [1422] stackpush(char) = w25q16_verify::different_char#16 -- _stackpushbyte_=vbuz1 
    lda.z different_char
    pha
    // [1423] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b15
    // w25q16_verify::@34
  __b34:
    // [1425] w25q16_verify::w25q16_compared_bytes#9 = w25q16_verify::w25q16_compared_bytes#1 -- vbuz1=vbuz2 
    lda.z w25q16_compared_bytes
    sta.z w25q16_compared_bytes_1
    // [1373] phi from w25q16_verify::@34 to w25q16_verify::@8 [phi:w25q16_verify::@34->w25q16_verify::@8]
    // [1373] phi w25q16_verify::w25q16_equal_bytes#10 = w25q16_verify::w25q16_equal_bytes#11 [phi:w25q16_verify::@34->w25q16_verify::@8#0] -- register_copy 
    // [1373] phi w25q16_verify::w25q16_compared_bytes#2 = w25q16_verify::w25q16_compared_bytes#9 [phi:w25q16_verify::@34->w25q16_verify::@8#1] -- register_copy 
    // [1373] phi w25q16_verify::bram_ptr#10 = w25q16_verify::bram_ptr#1 [phi:w25q16_verify::@34->w25q16_verify::@8#2] -- register_copy 
    jmp __b8
    // [1426] phi from w25q16_verify::@21 to w25q16_verify::@1 [phi:w25q16_verify::@21->w25q16_verify::@1]
    // w25q16_verify::@1
  __b1:
    // display_action_progress("Verifying VERA after VERA.BIN update ... (=) same, (!) error.")
    // [1427] call display_action_progress
    // [657] phi from w25q16_verify::@1 to display_action_progress [phi:w25q16_verify::@1->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = w25q16_verify::info_text [phi:w25q16_verify::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1354] phi from w25q16_verify::@1 to w25q16_verify::@2 [phi:w25q16_verify::@1->w25q16_verify::@2]
    // [1354] phi w25q16_verify::different_char#16 = '!' [phi:w25q16_verify::@1->w25q16_verify::@2#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z different_char
    jmp __b2
  .segment Data
    info_text: .text "Verifying VERA after VERA.BIN update ... (=) same, (!) error."
    .byte 0
    info_text1: .text "Comparing VERA with VERA.BIN ... (.) data, (=) same, (*) different."
    .byte 0
    s: .text " different RAM:"
    .byte 0
    s1: .text ":"
    .byte 0
    s2: .text " <-> VERA:"
    .byte 0
    bank_set_bram2_bank: .byte 0
    w25q16_different_bytes: .dword 0
    .label return = w25q16_different_bytes
    .label verify = main.check_status_cx16_rom6_check_status_rom1_main__0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_ulong: {
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1429] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1430] ultoa::value#1 = printf_ulong::uvalue#10
    // [1431] ultoa::radix#0 = printf_ulong::format_radix#10
    // [1432] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1433] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1434] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#10
    // [1435] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#10
    // [1436] call printf_number_buffer
  // Print using format
    // [1318] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1318] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [1318] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1318] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1318] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1437] return 
    rts
  .segment Data
    uvalue: .dword 0
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment CodeVera
  // w25q16_erase
w25q16_erase: {
    .label w25q16_erase__0 = $40
    .label w25q16_erase__4 = $ba
    .label vera_total_64k_blocks = $40
    .label vera_current_64k_block = $b5
    // There is an error. We must exit properly back to a prompt, no CX16 reset may happen!
    .label return = $da
    // BYTE2(vera_file_size)
    // [1438] w25q16_erase::$0 = byte2  vera_file_size#1 -- vbuz1=_byte2_vdum2 
    lda vera_file_size+2
    sta.z w25q16_erase__0
    // unsigned char vera_total_64k_blocks = BYTE2(vera_file_size)+1
    // [1439] w25q16_erase::vera_total_64k_blocks#0 = w25q16_erase::$0 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z vera_total_64k_blocks
    // spi_select()
    // [1440] call spi_select
    // [2080] phi from w25q16_erase to spi_select [phi:w25q16_erase->spi_select]
    jsr spi_select
    // [1441] phi from w25q16_erase to w25q16_erase::@1 [phi:w25q16_erase->w25q16_erase::@1]
    // [1441] phi w25q16_erase::vera_address#2 = 0 [phi:w25q16_erase->w25q16_erase::@1#0] -- vdum1=vduc1 
    lda #<0
    sta vera_address
    sta vera_address+1
    lda #<0>>$10
    sta vera_address+2
    lda #>0>>$10
    sta vera_address+3
    // [1441] phi w25q16_erase::vera_current_64k_block#2 = 0 [phi:w25q16_erase->w25q16_erase::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z vera_current_64k_block
    // w25q16_erase::@1
  __b1:
    // while(vera_current_64k_block < vera_total_64k_blocks)
    // [1442] if(w25q16_erase::vera_current_64k_block#2<w25q16_erase::vera_total_64k_blocks#0) goto w25q16_erase::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z vera_current_64k_block
    cmp.z vera_total_64k_blocks
    bcc __b2
    // [1443] phi from w25q16_erase::@1 to w25q16_erase::@return [phi:w25q16_erase::@1->w25q16_erase::@return]
    // [1443] phi w25q16_erase::return#2 = 0 [phi:w25q16_erase::@1->w25q16_erase::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    // w25q16_erase::@return
    // }
    // [1444] return 
    rts
    // [1445] phi from w25q16_erase::@1 to w25q16_erase::@2 [phi:w25q16_erase::@1->w25q16_erase::@2]
    // w25q16_erase::@2
  __b2:
    // spi_wait_non_busy()
    // [1446] call spi_wait_non_busy
    // [2019] phi from w25q16_erase::@2 to spi_wait_non_busy [phi:w25q16_erase::@2->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // spi_wait_non_busy()
    // [1447] spi_wait_non_busy::return#5 = spi_wait_non_busy::return#3
    // w25q16_erase::@4
    // [1448] w25q16_erase::$4 = spi_wait_non_busy::return#5
    // if(!spi_wait_non_busy())
    // [1449] if(0==w25q16_erase::$4) goto w25q16_erase::@3 -- 0_eq_vbuz1_then_la1 
    lda.z w25q16_erase__4
    beq __b3
    // [1443] phi from w25q16_erase::@4 to w25q16_erase::@return [phi:w25q16_erase::@4->w25q16_erase::@return]
    // [1443] phi w25q16_erase::return#2 = 1 [phi:w25q16_erase::@4->w25q16_erase::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    rts
    // w25q16_erase::@3
  __b3:
    // spi_block_erase(vera_address)
    // [1450] spi_block_erase::data#0 = w25q16_erase::vera_address#2 -- vduz1=vdum2 
    lda vera_address
    sta.z spi_block_erase.data
    lda vera_address+1
    sta.z spi_block_erase.data+1
    lda vera_address+2
    sta.z spi_block_erase.data+2
    lda vera_address+3
    sta.z spi_block_erase.data+3
    // [1451] call spi_block_erase
    // [2084] phi from w25q16_erase::@3 to spi_block_erase [phi:w25q16_erase::@3->spi_block_erase]
    jsr spi_block_erase
    // w25q16_erase::@5
    // vera_address += 0x10000
    // [1452] w25q16_erase::vera_address#1 = w25q16_erase::vera_address#2 + $10000 -- vdum1=vdum1_plus_vduc1 
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
    // [1453] w25q16_erase::vera_current_64k_block#1 = ++ w25q16_erase::vera_current_64k_block#2 -- vbuz1=_inc_vbuz1 
    inc.z vera_current_64k_block
    // [1441] phi from w25q16_erase::@5 to w25q16_erase::@1 [phi:w25q16_erase::@5->w25q16_erase::@1]
    // [1441] phi w25q16_erase::vera_address#2 = w25q16_erase::vera_address#1 [phi:w25q16_erase::@5->w25q16_erase::@1#0] -- register_copy 
    // [1441] phi w25q16_erase::vera_current_64k_block#2 = w25q16_erase::vera_current_64k_block#1 [phi:w25q16_erase::@5->w25q16_erase::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label vera_address = main_vera_flash.vera_differences
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
    .label rom_chip = $ec
    // [1455] phi from display_info_roms to display_info_roms::@1 [phi:display_info_roms->display_info_roms::@1]
    // [1455] phi display_info_roms::rom_chip#2 = 0 [phi:display_info_roms->display_info_roms::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // display_info_roms::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [1456] if(display_info_roms::rom_chip#2<8) goto display_info_roms::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc __b2
    // display_info_roms::@return
    // }
    // [1457] return 
    rts
    // display_info_roms::@2
  __b2:
    // display_info_rom(rom_chip, info_status, info_text)
    // [1458] display_info_rom::rom_chip#2 = display_info_roms::rom_chip#2 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z display_info_rom.rom_chip
    // [1459] call display_info_rom
    // [967] phi from display_info_roms::@2 to display_info_rom [phi:display_info_roms::@2->display_info_rom]
    // [967] phi display_info_rom::info_text#10 = 0 [phi:display_info_roms::@2->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [967] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#2 [phi:display_info_roms::@2->display_info_rom#1] -- register_copy 
    // [967] phi display_info_rom::info_status#10 = STATUS_ERROR [phi:display_info_roms::@2->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // display_info_roms::@3
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [1460] display_info_roms::rom_chip#1 = ++ display_info_roms::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [1455] phi from display_info_roms::@3 to display_info_roms::@1 [phi:display_info_roms::@3->display_info_roms::@1]
    // [1455] phi display_info_roms::rom_chip#2 = display_info_roms::rom_chip#1 [phi:display_info_roms::@3->display_info_roms::@1#0] -- register_copy 
    jmp __b1
}
.segment CodeVera
  // spi_deselect
spi_deselect: {
    // *vera_reg_SPICtrl &= 0xfe
    // [1461] *vera_reg_SPICtrl = *vera_reg_SPICtrl & $fe -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
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
    // [1462] call spi_read
    jsr spi_read
    // spi_deselect::@return
    // }
    // [1463] return 
    rts
}
  // w25q16_flash
w25q16_flash: {
    .label w25q16_flash__7 = $ba
    .label w25q16_flash__21 = $f3
    // TODO: ERROR!!!
    .label return = $c3
    .label i = $6d
    .label vera_bram_ptr = $4d
    .label vera_address = $c9
    .label vera_address_page = $c3
    .label vera_flashed_bytes = $b6
    .label vera_bram_bank = $e9
    .label x_sector = $f8
    .label y_sector = $ed
    .label w25q16_flash__28 = $71
    // display_action_progress(TEXT_PROGRESS_FLASHING)
    // [1465] call display_action_progress
    // [657] phi from w25q16_flash to display_action_progress [phi:w25q16_flash->display_action_progress]
    // [657] phi display_action_progress::info_text#22 = TEXT_PROGRESS_FLASHING [phi:w25q16_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<TEXT_PROGRESS_FLASHING
    sta.z display_action_progress.info_text
    lda #>TEXT_PROGRESS_FLASHING
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1466] phi from w25q16_flash to w25q16_flash::@1 [phi:w25q16_flash->w25q16_flash::@1]
    // [1466] phi w25q16_flash::vera_flashed_bytes#17 = 0 [phi:w25q16_flash->w25q16_flash::@1#0] -- vduz1=vduc1 
    lda #<0
    sta.z vera_flashed_bytes
    sta.z vera_flashed_bytes+1
    lda #<0>>$10
    sta.z vera_flashed_bytes+2
    lda #>0>>$10
    sta.z vera_flashed_bytes+3
    // [1466] phi w25q16_flash::vera_bram_ptr#12 = (char *)$a000 [phi:w25q16_flash->w25q16_flash::@1#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1466] phi w25q16_flash::vera_bram_bank#10 = 1 [phi:w25q16_flash->w25q16_flash::@1#2] -- vbuz1=vbuc1 
    lda #1
    sta.z vera_bram_bank
    // [1466] phi w25q16_flash::y_sector#15 = PROGRESS_Y [phi:w25q16_flash->w25q16_flash::@1#3] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y_sector
    // [1466] phi w25q16_flash::x_sector#14 = PROGRESS_X [phi:w25q16_flash->w25q16_flash::@1#4] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x_sector
    // [1466] phi w25q16_flash::vera_address_page#11 = 0 [phi:w25q16_flash->w25q16_flash::@1#5] -- vduz1=vduc1 
    lda #<0
    sta.z vera_address_page
    sta.z vera_address_page+1
    lda #<0>>$10
    sta.z vera_address_page+2
    lda #>0>>$10
    sta.z vera_address_page+3
    // w25q16_flash::@1
  __b1:
    // while (vera_address_page < vera_file_size)
    // [1467] if(w25q16_flash::vera_address_page#11<vera_file_size#1) goto w25q16_flash::@2 -- vduz1_lt_vdum2_then_la1 
    lda.z vera_address_page+3
    cmp vera_file_size+3
    bcc __b2
    bne !+
    lda.z vera_address_page+2
    cmp vera_file_size+2
    bcc __b2
    bne !+
    lda.z vera_address_page+1
    cmp vera_file_size+1
    bcc __b2
    bne !+
    lda.z vera_address_page
    cmp vera_file_size
    bcc __b2
  !:
    // w25q16_flash::@3
    // display_action_text_flashed(vera_address_page, "VERA")
    // [1468] display_action_text_flashed::bytes#0 = w25q16_flash::vera_address_page#11 -- vduz1=vduz2 
    lda.z vera_address_page
    sta.z display_action_text_flashed.bytes
    lda.z vera_address_page+1
    sta.z display_action_text_flashed.bytes+1
    lda.z vera_address_page+2
    sta.z display_action_text_flashed.bytes+2
    lda.z vera_address_page+3
    sta.z display_action_text_flashed.bytes+3
    // [1469] call display_action_text_flashed
    // [2104] phi from w25q16_flash::@3 to display_action_text_flashed [phi:w25q16_flash::@3->display_action_text_flashed]
    jsr display_action_text_flashed
    // [1470] phi from w25q16_flash::@3 to w25q16_flash::@18 [phi:w25q16_flash::@3->w25q16_flash::@18]
    // w25q16_flash::@18
    // wait_moment(16)
    // [1471] call wait_moment
    // [635] phi from w25q16_flash::@18 to wait_moment [phi:w25q16_flash::@18->wait_moment]
    // [635] phi wait_moment::w#14 = $10 [phi:w25q16_flash::@18->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    // [1472] phi from w25q16_flash::@18 to w25q16_flash::@return [phi:w25q16_flash::@18->w25q16_flash::@return]
    // [1472] phi w25q16_flash::return#2 = w25q16_flash::vera_address_page#11 [phi:w25q16_flash::@18->w25q16_flash::@return#0] -- register_copy 
    // w25q16_flash::@return
    // }
    // [1473] return 
    rts
    // w25q16_flash::@2
  __b2:
    // unsigned long vera_page_boundary = vera_address_page + VERA_PROGRESS_PAGE
    // [1474] w25q16_flash::vera_page_boundary#0 = w25q16_flash::vera_address_page#11 + VERA_PROGRESS_PAGE -- vdum1=vduz2_plus_vwuc1 
    // {asm{.byte $db}}
    clc
    lda.z vera_address_page
    adc #<VERA_PROGRESS_PAGE
    sta vera_page_boundary
    lda.z vera_address_page+1
    adc #>VERA_PROGRESS_PAGE
    sta vera_page_boundary+1
    lda.z vera_address_page+2
    adc #0
    sta vera_page_boundary+2
    lda.z vera_address_page+3
    adc #0
    sta vera_page_boundary+3
    // cputcxy(x,y,'.')
    // [1475] cputcxy::x#13 = w25q16_flash::x_sector#14 -- vbum1=vbuz2 
    lda.z x_sector
    sta cputcxy.x
    // [1476] cputcxy::y#13 = w25q16_flash::y_sector#15 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputcxy.y
    // [1477] call cputcxy
    // [1200] phi from w25q16_flash::@2 to cputcxy [phi:w25q16_flash::@2->cputcxy]
    // [1200] phi cputcxy::c#15 = '.' [phi:w25q16_flash::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #'.'
    sta cputcxy.c
    // [1200] phi cputcxy::y#15 = cputcxy::y#13 [phi:w25q16_flash::@2->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#13 [phi:w25q16_flash::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // w25q16_flash::@16
    // cputc('.')
    // [1478] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1479] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // spi_wait_non_busy()
    // [1481] call spi_wait_non_busy
    // [2019] phi from w25q16_flash::@16 to spi_wait_non_busy [phi:w25q16_flash::@16->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // spi_wait_non_busy()
    // [1482] spi_wait_non_busy::return#6 = spi_wait_non_busy::return#3
    // w25q16_flash::@17
    // [1483] w25q16_flash::$7 = spi_wait_non_busy::return#6
    // if(!spi_wait_non_busy())
    // [1484] if(0==w25q16_flash::$7) goto w25q16_flash::bank_set_bram1 -- 0_eq_vbuz1_then_la1 
    lda.z w25q16_flash__7
    beq bank_set_bram1
    // [1472] phi from w25q16_flash::@17 to w25q16_flash::@return [phi:w25q16_flash::@17->w25q16_flash::@return]
    // [1472] phi w25q16_flash::return#2 = 0 [phi:w25q16_flash::@17->w25q16_flash::@return#0] -- vduz1=vbuc1 
    lda #0
    sta.z return
    sta.z return+1
    sta.z return+2
    sta.z return+3
    rts
    // w25q16_flash::bank_set_bram1
  bank_set_bram1:
    // BRAM = bank
    // [1485] BRAM = w25q16_flash::vera_bram_bank#10 -- vbuz1=vbuz2 
    lda.z vera_bram_bank
    sta.z BRAM
    // w25q16_flash::@15
    // spi_write_page_begin(vera_address_page)
    // [1486] spi_write_page_begin::data#0 = w25q16_flash::vera_address_page#11 -- vduz1=vduz2 
    lda.z vera_address_page
    sta.z spi_write_page_begin.data
    lda.z vera_address_page+1
    sta.z spi_write_page_begin.data+1
    lda.z vera_address_page+2
    sta.z spi_write_page_begin.data+2
    lda.z vera_address_page+3
    sta.z spi_write_page_begin.data+3
    // [1487] call spi_write_page_begin
    // [2121] phi from w25q16_flash::@15 to spi_write_page_begin [phi:w25q16_flash::@15->spi_write_page_begin]
    jsr spi_write_page_begin
    // w25q16_flash::@19
    // [1488] w25q16_flash::vera_address#16 = w25q16_flash::vera_address_page#11 -- vduz1=vduz2 
    lda.z vera_address_page
    sta.z vera_address
    lda.z vera_address_page+1
    sta.z vera_address+1
    lda.z vera_address_page+2
    sta.z vera_address+2
    lda.z vera_address_page+3
    sta.z vera_address+3
    // [1489] phi from w25q16_flash::@19 w25q16_flash::@21 to w25q16_flash::@5 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5]
    // [1489] phi w25q16_flash::vera_flashed_bytes#10 = w25q16_flash::vera_flashed_bytes#17 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5#0] -- register_copy 
    // [1489] phi w25q16_flash::vera_address_page#10 = w25q16_flash::vera_address_page#11 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5#1] -- register_copy 
    // [1489] phi w25q16_flash::vera_bram_ptr#13 = w25q16_flash::vera_bram_ptr#12 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5#2] -- register_copy 
    // [1489] phi w25q16_flash::vera_address#10 = w25q16_flash::vera_address#16 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5#3] -- register_copy 
    // w25q16_flash::@5
  __b5:
    // while (vera_address < vera_page_boundary)
    // [1490] if(w25q16_flash::vera_address#10<w25q16_flash::vera_page_boundary#0) goto w25q16_flash::@6 -- vduz1_lt_vdum2_then_la1 
    lda.z vera_address+3
    cmp vera_page_boundary+3
    bcs !__b6+
    jmp __b6
  !__b6:
    bne !+
    lda.z vera_address+2
    cmp vera_page_boundary+2
    bcs !__b6+
    jmp __b6
  !__b6:
    bne !+
    lda.z vera_address+1
    cmp vera_page_boundary+1
    bcs !__b6+
    jmp __b6
  !__b6:
    bne !+
    lda.z vera_address
    cmp vera_page_boundary
    bcs !__b6+
    jmp __b6
  !__b6:
  !:
    // w25q16_flash::@4
    // if (vera_bram_ptr == BRAM_HIGH)
    // [1491] if(w25q16_flash::vera_bram_ptr#13!=$c000) goto w25q16_flash::@10 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b10
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b10
    // w25q16_flash::@13
    // vera_bram_bank++;
    // [1492] w25q16_flash::vera_bram_bank#1 = ++ w25q16_flash::vera_bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z vera_bram_bank
    // [1493] phi from w25q16_flash::@13 to w25q16_flash::@10 [phi:w25q16_flash::@13->w25q16_flash::@10]
    // [1493] phi w25q16_flash::vera_bram_bank#27 = w25q16_flash::vera_bram_bank#1 [phi:w25q16_flash::@13->w25q16_flash::@10#0] -- register_copy 
    // [1493] phi w25q16_flash::vera_bram_ptr#8 = (char *)$a000 [phi:w25q16_flash::@13->w25q16_flash::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1493] phi from w25q16_flash::@4 to w25q16_flash::@10 [phi:w25q16_flash::@4->w25q16_flash::@10]
    // [1493] phi w25q16_flash::vera_bram_bank#27 = w25q16_flash::vera_bram_bank#10 [phi:w25q16_flash::@4->w25q16_flash::@10#0] -- register_copy 
    // [1493] phi w25q16_flash::vera_bram_ptr#8 = w25q16_flash::vera_bram_ptr#13 [phi:w25q16_flash::@4->w25q16_flash::@10#1] -- register_copy 
    // w25q16_flash::@10
  __b10:
    // if (vera_bram_ptr == RAM_HIGH)
    // [1494] if(w25q16_flash::vera_bram_ptr#8!=$9800) goto w25q16_flash::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b11
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b11
    // [1496] phi from w25q16_flash::@10 to w25q16_flash::@11 [phi:w25q16_flash::@10->w25q16_flash::@11]
    // [1496] phi w25q16_flash::vera_bram_ptr#23 = (char *)$a000 [phi:w25q16_flash::@10->w25q16_flash::@11#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [1496] phi w25q16_flash::vera_bram_bank#19 = 1 [phi:w25q16_flash::@10->w25q16_flash::@11#1] -- vbuz1=vbuc1 
    lda #1
    sta.z vera_bram_bank
    // [1495] phi from w25q16_flash::@10 to w25q16_flash::@23 [phi:w25q16_flash::@10->w25q16_flash::@23]
    // w25q16_flash::@23
    // [1496] phi from w25q16_flash::@23 to w25q16_flash::@11 [phi:w25q16_flash::@23->w25q16_flash::@11]
    // [1496] phi w25q16_flash::vera_bram_ptr#23 = w25q16_flash::vera_bram_ptr#8 [phi:w25q16_flash::@23->w25q16_flash::@11#0] -- register_copy 
    // [1496] phi w25q16_flash::vera_bram_bank#19 = w25q16_flash::vera_bram_bank#27 [phi:w25q16_flash::@23->w25q16_flash::@11#1] -- register_copy 
    // w25q16_flash::@11
  __b11:
    // x_sector += 2
    // [1497] w25q16_flash::x_sector#1 = w25q16_flash::x_sector#14 + 2 -- vbuz1=vbuz1_plus_2 
    lda.z x_sector
    clc
    adc #2
    sta.z x_sector
    // vera_address_page % VERA_PROGRESS_ROW
    // [1498] w25q16_flash::$21 = w25q16_flash::vera_address_page#10 & VERA_PROGRESS_ROW-1 -- vduz1=vduz2_band_vduc1 
    lda.z vera_address_page
    and #<VERA_PROGRESS_ROW-1
    sta.z w25q16_flash__21
    lda.z vera_address_page+1
    and #>VERA_PROGRESS_ROW-1
    sta.z w25q16_flash__21+1
    lda.z vera_address_page+2
    and #<VERA_PROGRESS_ROW-1>>$10
    sta.z w25q16_flash__21+2
    lda.z vera_address_page+3
    and #>VERA_PROGRESS_ROW-1>>$10
    sta.z w25q16_flash__21+3
    // if (!(vera_address_page % VERA_PROGRESS_ROW))
    // [1499] if(0!=w25q16_flash::$21) goto w25q16_flash::@12 -- 0_neq_vduz1_then_la1 
    lda.z w25q16_flash__21
    ora.z w25q16_flash__21+1
    ora.z w25q16_flash__21+2
    ora.z w25q16_flash__21+3
    bne __b12
    // w25q16_flash::@14
    // y_sector++;
    // [1500] w25q16_flash::y_sector#1 = ++ w25q16_flash::y_sector#15 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [1501] phi from w25q16_flash::@14 to w25q16_flash::@12 [phi:w25q16_flash::@14->w25q16_flash::@12]
    // [1501] phi w25q16_flash::y_sector#12 = w25q16_flash::y_sector#1 [phi:w25q16_flash::@14->w25q16_flash::@12#0] -- register_copy 
    // [1501] phi w25q16_flash::x_sector#13 = PROGRESS_X [phi:w25q16_flash::@14->w25q16_flash::@12#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x_sector
    // [1501] phi from w25q16_flash::@11 to w25q16_flash::@12 [phi:w25q16_flash::@11->w25q16_flash::@12]
    // [1501] phi w25q16_flash::y_sector#12 = w25q16_flash::y_sector#15 [phi:w25q16_flash::@11->w25q16_flash::@12#0] -- register_copy 
    // [1501] phi w25q16_flash::x_sector#13 = w25q16_flash::x_sector#1 [phi:w25q16_flash::@11->w25q16_flash::@12#1] -- register_copy 
    // w25q16_flash::@12
  __b12:
    // get_info_text_flashing(vera_flashed_bytes)
    // [1502] get_info_text_flashing::flash_bytes#0 = w25q16_flash::vera_flashed_bytes#10 -- vduz1=vduz2 
    lda.z vera_flashed_bytes
    sta.z get_info_text_flashing.flash_bytes
    lda.z vera_flashed_bytes+1
    sta.z get_info_text_flashing.flash_bytes+1
    lda.z vera_flashed_bytes+2
    sta.z get_info_text_flashing.flash_bytes+2
    lda.z vera_flashed_bytes+3
    sta.z get_info_text_flashing.flash_bytes+3
    // [1503] call get_info_text_flashing
    // [2139] phi from w25q16_flash::@12 to get_info_text_flashing [phi:w25q16_flash::@12->get_info_text_flashing]
    jsr get_info_text_flashing
    // [1504] phi from w25q16_flash::@12 to w25q16_flash::@22 [phi:w25q16_flash::@12->w25q16_flash::@22]
    // w25q16_flash::@22
    // display_info_vera(STATUS_FLASHING, get_info_text_flashing(vera_flashed_bytes))
    // [1505] call display_info_vera
    // [939] phi from w25q16_flash::@22 to display_info_vera [phi:w25q16_flash::@22->display_info_vera]
    // [939] phi display_info_vera::info_text#15 = info_text [phi:w25q16_flash::@22->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_vera.info_text
    lda #>info_text
    sta.z display_info_vera.info_text+1
    // [939] phi display_info_vera::info_status#15 = STATUS_FLASHING [phi:w25q16_flash::@22->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [1466] phi from w25q16_flash::@22 to w25q16_flash::@1 [phi:w25q16_flash::@22->w25q16_flash::@1]
    // [1466] phi w25q16_flash::vera_flashed_bytes#17 = w25q16_flash::vera_flashed_bytes#10 [phi:w25q16_flash::@22->w25q16_flash::@1#0] -- register_copy 
    // [1466] phi w25q16_flash::vera_bram_ptr#12 = w25q16_flash::vera_bram_ptr#23 [phi:w25q16_flash::@22->w25q16_flash::@1#1] -- register_copy 
    // [1466] phi w25q16_flash::vera_bram_bank#10 = w25q16_flash::vera_bram_bank#19 [phi:w25q16_flash::@22->w25q16_flash::@1#2] -- register_copy 
    // [1466] phi w25q16_flash::y_sector#15 = w25q16_flash::y_sector#12 [phi:w25q16_flash::@22->w25q16_flash::@1#3] -- register_copy 
    // [1466] phi w25q16_flash::x_sector#14 = w25q16_flash::x_sector#13 [phi:w25q16_flash::@22->w25q16_flash::@1#4] -- register_copy 
    // [1466] phi w25q16_flash::vera_address_page#11 = w25q16_flash::vera_address_page#10 [phi:w25q16_flash::@22->w25q16_flash::@1#5] -- register_copy 
    jmp __b1
    // w25q16_flash::@6
  __b6:
    // display_action_text_flashing(VERA_PROGRESS_PAGE, "VERA", vera_bram_bank, vera_bram_ptr, vera_address)
    // [1506] display_action_text_flashing::bram_bank#0 = w25q16_flash::vera_bram_bank#10 -- vbuz1=vbuz2 
    lda.z vera_bram_bank
    sta.z display_action_text_flashing.bram_bank
    // [1507] display_action_text_flashing::bram_ptr#0 = w25q16_flash::vera_bram_ptr#13 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1508] display_action_text_flashing::address#0 = w25q16_flash::vera_address#10 -- vduz1=vduz2 
    lda.z vera_address
    sta.z display_action_text_flashing.address
    lda.z vera_address+1
    sta.z display_action_text_flashing.address+1
    lda.z vera_address+2
    sta.z display_action_text_flashing.address+2
    lda.z vera_address+3
    sta.z display_action_text_flashing.address+3
    // [1509] call display_action_text_flashing
    // [2149] phi from w25q16_flash::@6 to display_action_text_flashing [phi:w25q16_flash::@6->display_action_text_flashing]
    jsr display_action_text_flashing
    // [1510] phi from w25q16_flash::@6 to w25q16_flash::@7 [phi:w25q16_flash::@6->w25q16_flash::@7]
    // [1510] phi w25q16_flash::i#2 = 0 [phi:w25q16_flash::@6->w25q16_flash::@7#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // w25q16_flash::@7
  __b7:
    // for(unsigned int i=0; i<=255; i++)
    // [1511] if(w25q16_flash::i#2<=$ff) goto w25q16_flash::@8 -- vwuz1_le_vbuc1_then_la1 
    lda #$ff
    cmp.z i
    bcc !+
    lda.z i+1
    beq __b8
  !:
    // w25q16_flash::@9
    // cputcxy(x,y,'+')
    // [1512] cputcxy::x#14 = w25q16_flash::x_sector#14 -- vbum1=vbuz2 
    lda.z x_sector
    sta cputcxy.x
    // [1513] cputcxy::y#14 = w25q16_flash::y_sector#15 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputcxy.y
    // [1514] call cputcxy
    // [1200] phi from w25q16_flash::@9 to cputcxy [phi:w25q16_flash::@9->cputcxy]
    // [1200] phi cputcxy::c#15 = '+' [phi:w25q16_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [1200] phi cputcxy::y#15 = cputcxy::y#14 [phi:w25q16_flash::@9->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#14 [phi:w25q16_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // w25q16_flash::@21
    // cputc('+')
    // [1515] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1516] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_bram_ptr += VERA_PROGRESS_PAGE
    // [1518] w25q16_flash::vera_bram_ptr#1 = w25q16_flash::vera_bram_ptr#13 + VERA_PROGRESS_PAGE -- pbuz1=pbuz1_plus_vwuc1 
    lda.z vera_bram_ptr
    clc
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr+1
    // vera_address += VERA_PROGRESS_PAGE
    // [1519] w25q16_flash::vera_address#1 = w25q16_flash::vera_address#10 + VERA_PROGRESS_PAGE -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z vera_address
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_address
    lda.z vera_address+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_address+1
    lda.z vera_address+2
    adc #0
    sta.z vera_address+2
    lda.z vera_address+3
    adc #0
    sta.z vera_address+3
    // vera_address_page += VERA_PROGRESS_PAGE
    // [1520] w25q16_flash::vera_address_page#1 = w25q16_flash::vera_address_page#10 + VERA_PROGRESS_PAGE -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z vera_address_page
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_address_page
    lda.z vera_address_page+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_address_page+1
    lda.z vera_address_page+2
    adc #0
    sta.z vera_address_page+2
    lda.z vera_address_page+3
    adc #0
    sta.z vera_address_page+3
    // vera_flashed_bytes += VERA_PROGRESS_PAGE
    // [1521] w25q16_flash::vera_flashed_bytes#1 = w25q16_flash::vera_flashed_bytes#10 + VERA_PROGRESS_PAGE -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z vera_flashed_bytes
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_flashed_bytes
    lda.z vera_flashed_bytes+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_flashed_bytes+1
    lda.z vera_flashed_bytes+2
    adc #0
    sta.z vera_flashed_bytes+2
    lda.z vera_flashed_bytes+3
    adc #0
    sta.z vera_flashed_bytes+3
    jmp __b5
    // w25q16_flash::@8
  __b8:
    // spi_write(vera_bram_ptr[i])
    // [1522] w25q16_flash::$28 = w25q16_flash::vera_bram_ptr#13 + w25q16_flash::i#2 -- pbuz1=pbuz2_plus_vwuz3 
    lda.z vera_bram_ptr
    clc
    adc.z i
    sta.z w25q16_flash__28
    lda.z vera_bram_ptr+1
    adc.z i+1
    sta.z w25q16_flash__28+1
    // [1523] spi_write::data = *w25q16_flash::$28 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (w25q16_flash__28),y
    sta.z spi_write.data
    // [1524] call spi_write
    jsr spi_write
    // w25q16_flash::@20
    // for(unsigned int i=0; i<=255; i++)
    // [1525] w25q16_flash::i#1 = ++ w25q16_flash::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1510] phi from w25q16_flash::@20 to w25q16_flash::@7 [phi:w25q16_flash::@20->w25q16_flash::@7]
    // [1510] phi w25q16_flash::i#2 = w25q16_flash::i#1 [phi:w25q16_flash::@20->w25q16_flash::@7#0] -- register_copy 
    jmp __b7
  .segment Data
    chip: .text "VERA"
    .byte 0
    chip1: .text "VERA"
    .byte 0
    vera_page_boundary: .dword 0
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
    // [1526] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1528] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [1529] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1530] return 
    rts
  .segment Data
    ch: .byte 0
    return: .byte 0
}
.segment Code
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__zp($63) char c)
display_smc_led: {
    .label c = $63
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1532] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1533] call display_chip_led
    // [2180] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2180] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [2180] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [2180] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1534] display_info_led::tc#0 = display_smc_led::c#2
    // [1535] call display_info_led
    // [1184] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1184] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1184] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1184] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1536] return 
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($48) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $48
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1538] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1539] utoa::value#1 = printf_uint::uvalue#4
    // [1540] utoa::radix#0 = printf_uint::format_radix#4
    // [1541] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1542] printf_number_buffer::putc#1 = printf_uint::putc#4
    // [1543] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1544] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#4
    // [1545] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#4
    // [1546] call printf_number_buffer
  // Print using format
    // [1318] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1318] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1318] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1318] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1318] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1547] return 
    rts
  .segment Data
    uvalue: .word 0
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__zp($79) char c)
display_vera_led: {
    .label c = $79
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1549] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1550] call display_chip_led
    // [2180] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2180] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [2180] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [2180] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1551] display_info_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1552] call display_info_led
    // [1184] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1184] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1184] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1184] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [1553] return 
    rts
}
  // display_rom_led
/**
 * @brief Print ROM led above the ROM chip.
 * 
 * @param chip ROM chip number (0 is main rom chip of CX16)
 * @param c Led color
 */
// void display_rom_led(__zp($a9) char chip, __zp($ab) char c)
display_rom_led: {
    .label display_rom_led__0 = $54
    .label chip = $a9
    .label c = $ab
    .label display_rom_led__7 = $54
    .label display_rom_led__8 = $54
    // chip*6
    // [1555] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z display_rom_led__7
    // [1556] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_rom_led__8
    clc
    adc.z chip
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1557] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1558] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_chip_led.x
    sta.z display_chip_led.x
    // [1559] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1560] call display_chip_led
    // [2180] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2180] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [2180] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2180] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1561] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [1562] display_info_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1563] call display_info_led
    // [1184] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1184] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1184] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1184] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [1564] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $30
    .label insertup__4 = $29
    .label insertup__6 = $2a
    .label insertup__7 = $29
    // __conio.width+1
    // [1565] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [1566] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [1567] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1567] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1568] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [1569] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1570] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1571] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1572] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1573] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [1574] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [1575] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [1576] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [1577] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [1578] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [1579] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [1580] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1581] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [1567] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1567] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [1582] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [1583] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1584] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1585] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1586] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1587] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1588] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1589] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1590] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1591] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1592] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1592] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1593] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1594] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1595] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1596] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1597] return 
    rts
  .segment Data
    addr: .word 0
}
.segment Code
  // cx16_k_screen_set_mode
/**
 * @brief Sets the screen mode.
 *
 * @return cx16_k_screen_mode_error_t Contains 1 if there is an error.
 */
// char cx16_k_screen_set_mode(__mem() volatile char mode)
cx16_k_screen_set_mode: {
    // cx16_k_screen_mode_error_t error = 0
    // [1598] cx16_k_screen_set_mode::error = 0 -- vbum1=vbuc1 
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
    // [1600] return 
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
// void display_frame(char x0, char y0, __zp($bb) char x1, __mem() char y1)
display_frame: {
    .label w = $73
    .label h = $d1
    .label x = $aa
    .label y = $b4
    .label mask = $6a
    .label c = $78
    .label x_1 = $b0
    .label y_1 = $7a
    .label x1 = $bb
    // unsigned char w = x1 - x0
    // [1602] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [1603] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbuz1=vbum2_minus_vbuz3 
    lda y1
    sec
    sbc.z y
    sta.z h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1604] display_frame_maskxy::x#0 = display_frame::x#0
    // [1605] display_frame_maskxy::y#0 = display_frame::y#0
    // [1606] call display_frame_maskxy
    // [2248] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2248] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2248] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1607] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1608] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1609] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = display_frame_char(mask)
    // [1610] display_frame_char::mask#0 = display_frame::mask#1
    // [1611] call display_frame_char
  // Add a corner.
    // [2274] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2274] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1612] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1613] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1614] cputcxy::x#0 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1615] cputcxy::y#0 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1616] cputcxy::c#0 = display_frame::c#0 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1617] call cputcxy
    // [1200] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1618] if(display_frame::w#0<2) goto display_frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1619] display_frame::x#1 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1620] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1620] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1621] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1622] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1622] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1623] display_frame_maskxy::x#1 = display_frame::x#24
    // [1624] display_frame_maskxy::y#1 = display_frame::y#0
    // [1625] call display_frame_maskxy
    // [2248] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2248] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2248] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1626] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1627] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1628] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1629] display_frame_char::mask#1 = display_frame::mask#3
    // [1630] call display_frame_char
    // [2274] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2274] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1631] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1632] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1633] cputcxy::x#1 = display_frame::x#24 -- vbum1=vbuz2 
    lda.z x_1
    sta cputcxy.x
    // [1634] cputcxy::y#1 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1635] cputcxy::c#1 = display_frame::c#1 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1636] call cputcxy
    // [1200] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1637] if(display_frame::h#0<2) goto display_frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [1638] display_frame::y#1 = ++ display_frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1639] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1639] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1640] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbuz1_lt_vbum2_then_la1 
    lda.z y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1641] display_frame_maskxy::x#5 = display_frame::x#0
    // [1642] display_frame_maskxy::y#5 = display_frame::y#10
    // [1643] call display_frame_maskxy
    // [2248] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2248] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2248] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1644] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1645] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1646] display_frame::mask#11 = display_frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1647] display_frame_char::mask#5 = display_frame::mask#11
    // [1648] call display_frame_char
    // [2274] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2274] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1649] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1650] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1651] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1652] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1653] cputcxy::c#5 = display_frame::c#5 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1654] call cputcxy
    // [1200] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1655] if(display_frame::w#0<2) goto display_frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1656] display_frame::x#4 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1657] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1657] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1658] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1659] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1659] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1660] display_frame_maskxy::x#6 = display_frame::x#15
    // [1661] display_frame_maskxy::y#6 = display_frame::y#10
    // [1662] call display_frame_maskxy
    // [2248] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2248] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2248] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1663] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1664] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1665] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1666] display_frame_char::mask#6 = display_frame::mask#13
    // [1667] call display_frame_char
    // [2274] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2274] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1668] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1669] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1670] cputcxy::x#6 = display_frame::x#15 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1671] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1672] cputcxy::c#6 = display_frame::c#6 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1673] call cputcxy
    // [1200] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1674] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1675] display_frame_maskxy::x#7 = display_frame::x#18
    // [1676] display_frame_maskxy::y#7 = display_frame::y#10
    // [1677] call display_frame_maskxy
    // [2248] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2248] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2248] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1678] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1679] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1680] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1681] display_frame_char::mask#7 = display_frame::mask#15
    // [1682] call display_frame_char
    // [2274] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2274] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1683] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1684] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1685] cputcxy::x#7 = display_frame::x#18 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1686] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1687] cputcxy::c#7 = display_frame::c#7 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1688] call cputcxy
    // [1200] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1689] display_frame::x#5 = ++ display_frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1690] display_frame_maskxy::x#3 = display_frame::x#0
    // [1691] display_frame_maskxy::y#3 = display_frame::y#10
    // [1692] call display_frame_maskxy
    // [2248] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2248] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2248] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1693] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1694] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1695] display_frame::mask#7 = display_frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1696] display_frame_char::mask#3 = display_frame::mask#7
    // [1697] call display_frame_char
    // [2274] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2274] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1698] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1699] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1700] cputcxy::x#3 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1701] cputcxy::y#3 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1702] cputcxy::c#3 = display_frame::c#3 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1703] call cputcxy
    // [1200] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1704] display_frame_maskxy::x#4 = display_frame::x1#16
    // [1705] display_frame_maskxy::y#4 = display_frame::y#10
    // [1706] call display_frame_maskxy
    // [2248] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2248] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2248] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_2
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1707] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1708] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1709] display_frame::mask#9 = display_frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1710] display_frame_char::mask#4 = display_frame::mask#9
    // [1711] call display_frame_char
    // [2274] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2274] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1712] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1713] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1714] cputcxy::x#4 = display_frame::x1#16 -- vbum1=vbuz2 
    lda.z x1
    sta cputcxy.x
    // [1715] cputcxy::y#4 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1716] cputcxy::c#4 = display_frame::c#4 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1717] call cputcxy
    // [1200] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1718] display_frame::y#2 = ++ display_frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1719] display_frame_maskxy::x#2 = display_frame::x#10
    // [1720] display_frame_maskxy::y#2 = display_frame::y#0
    // [1721] call display_frame_maskxy
    // [2248] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2248] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2248] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1722] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1723] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1724] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1725] display_frame_char::mask#2 = display_frame::mask#5
    // [1726] call display_frame_char
    // [2274] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2274] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1727] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1728] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1729] cputcxy::x#2 = display_frame::x#10 -- vbum1=vbuz2 
    lda.z x_1
    sta cputcxy.x
    // [1730] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1731] cputcxy::c#2 = display_frame::c#2 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1732] call cputcxy
    // [1200] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1733] display_frame::x#2 = ++ display_frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1734] display_frame::x#30 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
  .segment Data
    .label y1 = main.check_status_smc5_main__0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($51) const char *s)
cputs: {
    .label s = $51
    // [1736] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1736] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1737] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1738] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1739] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [1740] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1741] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1742] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
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
// void display_print_chip(__zp($7f) char x, char y, __zp($f7) char w, __zp($4b) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $4b
    .label text_1 = $d6
    .label x = $7f
    .label text_2 = $46
    .label text_3 = $32
    .label text_4 = $55
    .label text_5 = $d4
    .label text_6 = $c0
    .label w = $f7
    // display_chip_line(x, y++, w, *text++)
    // [1745] display_chip_line::x#0 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1746] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1747] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_chip_line.c
    // [1748] call display_chip_line
    // [2289] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2289] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2289] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2289] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2
    sta.z display_chip_line.y
    // [2289] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [1749] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [1750] display_chip_line::x#1 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1751] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1752] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_chip_line.c
    // [1753] call display_chip_line
    // [2289] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2289] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2289] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2289] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z display_chip_line.y
    // [2289] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [1754] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [1755] display_chip_line::x#2 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1756] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1757] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_chip_line.c
    // [1758] call display_chip_line
    // [2289] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2289] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2289] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2289] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z display_chip_line.y
    // [2289] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [1759] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [1760] display_chip_line::x#3 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1761] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1762] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z display_chip_line.c
    // [1763] call display_chip_line
    // [2289] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2289] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2289] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2289] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z display_chip_line.y
    // [2289] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [1764] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [1765] display_chip_line::x#4 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1766] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1767] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z display_chip_line.c
    // [1768] call display_chip_line
    // [2289] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2289] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2289] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2289] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z display_chip_line.y
    // [2289] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [1769] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [1770] display_chip_line::x#5 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1771] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1772] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z display_chip_line.c
    // [1773] call display_chip_line
    // [2289] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2289] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2289] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2289] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z display_chip_line.y
    // [2289] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [1774] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [1775] display_chip_line::x#6 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1776] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1777] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [1778] call display_chip_line
    // [2289] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2289] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2289] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2289] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [2289] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [1779] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [1780] display_chip_line::x#7 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1781] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1782] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [1783] call display_chip_line
    // [2289] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2289] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2289] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2289] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [2289] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [1784] display_chip_end::x#0 = display_print_chip::x#10
    // [1785] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_end.w
    // [1786] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [1787] return 
    rts
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($46) char *source)
strcat: {
    .label strcat__0 = $64
    .label dst = $64
    .label src = $46
    .label source = $46
    // strlen(destination)
    // [1789] call strlen
    // [1998] phi from strcat to strlen [phi:strcat->strlen]
    // [1998] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1790] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1791] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [1792] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1793] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1793] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1793] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1794] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1795] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1796] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1797] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1798] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1799] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
.segment CodeVera
  // spi_get_jedec
spi_get_jedec: {
    // spi_fast()
    // [1801] call spi_fast
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
    // [1802] phi from spi_get_jedec to spi_get_jedec::@1 [phi:spi_get_jedec->spi_get_jedec::@1]
    // spi_get_jedec::@1
    // spi_select()
    // [1803] call spi_select
    // [2080] phi from spi_get_jedec::@1 to spi_select [phi:spi_get_jedec::@1->spi_select]
    jsr spi_select
    // spi_get_jedec::@2
    // spi_write(0x9F)
    // [1804] spi_write::data = $9f -- vbuz1=vbuc1 
    lda #$9f
    sta.z spi_write.data
    // [1805] call spi_write
    jsr spi_write
    // [1806] phi from spi_get_jedec::@2 to spi_get_jedec::@3 [phi:spi_get_jedec::@2->spi_get_jedec::@3]
    // spi_get_jedec::@3
    // spi_read()
    // [1807] call spi_read
    jsr spi_read
    // [1808] spi_read::return#0 = spi_read::return#12
    // spi_get_jedec::@4
    // [1809] spi_manufacturer#0 = spi_read::return#0 -- vbum1=vbuz2 
    lda.z spi_read.return
    sta spi_manufacturer
    // [1810] call spi_read
    jsr spi_read
    // [1811] spi_read::return#1 = spi_read::return#12
    // spi_get_jedec::@5
    // [1812] spi_memory_type#0 = spi_read::return#1 -- vbum1=vbuz2 
    lda.z spi_read.return
    sta spi_memory_type
    // [1813] call spi_read
    jsr spi_read
    // [1814] spi_read::return#10 = spi_read::return#12
    // spi_get_jedec::@6
    // [1815] spi_memory_capacity#0 = spi_read::return#10 -- vbum1=vbuz2 
    lda.z spi_read.return
    sta spi_memory_capacity
    // spi_get_jedec::@return
    // }
    // [1816] return 
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
// __zp($4b) struct $2 * fopen(__zp($5e) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $60
    .label fopen__9 = $3f
    .label fopen__11 = $55
    .label fopen__15 = $d9
    .label fopen__16 = $c0
    .label fopen__26 = $44
    .label fopen__28 = $32
    .label fopen__30 = $4b
    .label cbm_k_setnam1_fopen__0 = $d4
    .label stream = $4b
    .label pathtoken = $c7
    .label path = $5e
    .label return = $4b
    // unsigned char sp = __stdio_filecount
    // [1817] fopen::sp#0 = __stdio_filecount -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [1818] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1819] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1820] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [1821] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [1822] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [1823] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [1824] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [1825] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1825] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [1825] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1825] phi fopen::path#13 = w25q16_read::path [phi:fopen->fopen::@8#2] -- pbuz1=pbuc1 
    lda #<w25q16_read.path
    sta.z path
    lda #>w25q16_read.path
    sta.z path+1
    // [1825] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    lda #0
    sta pathstep
    // [1825] phi fopen::pathtoken#10 = w25q16_read::path [phi:fopen->fopen::@8#4] -- pbuz1=pbuc1 
    lda #<w25q16_read.path
    sta.z pathtoken
    lda #>w25q16_read.path
    sta.z pathtoken+1
  // Iterate while path is not \0.
    // [1825] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1825] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1825] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1825] phi fopen::path#13 = fopen::path#10 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1825] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1825] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1826] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [1827] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [1828] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1829] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1830] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [1831] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1831] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1831] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1831] phi fopen::path#10 = fopen::path#12 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1831] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1832] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken
    bne !+
    inc.z pathtoken+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1833] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [1834] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [1835] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [1836] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1837] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [1838] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1839] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1840] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1841] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1842] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1843] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [1844] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [1845] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbuz2 
    lda.z fopen__11
    sta cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1846] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1847] call strlen
    // [1998] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1998] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1848] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1849] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [1850] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1852] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [1853] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [1854] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [1855] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [1857] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1859] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [1860] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [1861] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [1862] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [1863] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [1864] call ferror
    jsr ferror
    // [1865] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [1866] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [1867] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [1868] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [1870] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [1870] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [1871] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [1872] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [1873] fopen::return#6 = (struct $2 *)fopen::stream#0
    // [1870] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [1870] phi fopen::return#2 = fopen::return#6 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [1874] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [1875] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [1876] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    // [1877] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [1877] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [1877] phi fopen::path#12 = fopen::path#15 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [1878] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [1879] fopen::pathcmp#0 = *fopen::path#13 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [1880] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [1881] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [1882] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [1883] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [1883] phi fopen::path#15 = fopen::path#13 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [1883] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [1884] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [1885] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [1886] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [1887] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [1888] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [1889] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [1890] atoi::str#0 = fopen::path#13 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [1891] call atoi
    // [2406] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2406] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [1892] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [1893] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [1894] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [1895] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
// int fclose(__zp($71) struct $2 *stream)
fclose: {
    .label fclose__1 = $3f
    .label fclose__4 = $d9
    .label fclose__6 = $69
    .label stream = $71
    // unsigned char sp = (unsigned char)stream
    // [1896] fclose::sp#0 = (char)fclose::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [1897] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [1898] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [1900] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1902] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [1903] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [1904] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [1905] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1906] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [1907] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [1908] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [1910] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1912] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [1913] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [1914] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [1915] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1916] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [1917] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [1918] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [1919] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [1920] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [1921] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [1922] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
// void display_action_text_reading(__zp($3b) char *action, char *file, __zp($cd) unsigned long bytes, unsigned long size, __zp($73) char bram_bank, __zp($e3) char *bram_ptr)
display_action_text_reading: {
    .label action = $3b
    .label bytes = $cd
    .label bram_bank = $73
    .label bram_ptr = $e3
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1924] call snprintf_init
    jsr snprintf_init
    // display_action_text_reading::@1
    // [1925] printf_string::str#14 = display_action_text_reading::action#0
    // [1926] call printf_string
    // [1261] phi from display_action_text_reading::@1 to printf_string [phi:display_action_text_reading::@1->printf_string]
    // [1261] phi printf_string::putc#17 = &snputc [phi:display_action_text_reading::@1->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = printf_string::str#14 [phi:display_action_text_reading::@1->printf_string#1] -- register_copy 
    // [1261] phi printf_string::format_justify_left#17 = 0 [phi:display_action_text_reading::@1->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 0 [phi:display_action_text_reading::@1->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1927] phi from display_action_text_reading::@1 to display_action_text_reading::@2 [phi:display_action_text_reading::@1->display_action_text_reading::@2]
    // display_action_text_reading::@2
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1928] call printf_str
    // [626] phi from display_action_text_reading::@2 to printf_str [phi:display_action_text_reading::@2->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_reading::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_reading::s [phi:display_action_text_reading::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [1929] phi from display_action_text_reading::@2 to display_action_text_reading::@3 [phi:display_action_text_reading::@2->display_action_text_reading::@3]
    // display_action_text_reading::@3
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1930] call printf_string
    // [1261] phi from display_action_text_reading::@3 to printf_string [phi:display_action_text_reading::@3->printf_string]
    // [1261] phi printf_string::putc#17 = &snputc [phi:display_action_text_reading::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = w25q16_read::file [phi:display_action_text_reading::@3->printf_string#1] -- pbuz1=pbuc1 
    lda #<w25q16_read.file
    sta.z printf_string.str
    lda #>w25q16_read.file
    sta.z printf_string.str+1
    // [1261] phi printf_string::format_justify_left#17 = 0 [phi:display_action_text_reading::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 0 [phi:display_action_text_reading::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1931] phi from display_action_text_reading::@3 to display_action_text_reading::@4 [phi:display_action_text_reading::@3->display_action_text_reading::@4]
    // display_action_text_reading::@4
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1932] call printf_str
    // [626] phi from display_action_text_reading::@4 to printf_str [phi:display_action_text_reading::@4->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_reading::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_reading::s1 [phi:display_action_text_reading::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@5
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1933] printf_ulong::uvalue#3 = display_action_text_reading::bytes#0 -- vdum1=vduz2 
    lda.z bytes
    sta printf_ulong.uvalue
    lda.z bytes+1
    sta printf_ulong.uvalue+1
    lda.z bytes+2
    sta printf_ulong.uvalue+2
    lda.z bytes+3
    sta printf_ulong.uvalue+3
    // [1934] call printf_ulong
    // [1428] phi from display_action_text_reading::@5 to printf_ulong [phi:display_action_text_reading::@5->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_reading::@5->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_reading::@5->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@5->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#3 [phi:display_action_text_reading::@5->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1935] phi from display_action_text_reading::@5 to display_action_text_reading::@6 [phi:display_action_text_reading::@5->display_action_text_reading::@6]
    // display_action_text_reading::@6
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1936] call printf_str
    // [626] phi from display_action_text_reading::@6 to printf_str [phi:display_action_text_reading::@6->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_reading::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_reading::s2 [phi:display_action_text_reading::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [1937] phi from display_action_text_reading::@6 to display_action_text_reading::@7 [phi:display_action_text_reading::@6->display_action_text_reading::@7]
    // display_action_text_reading::@7
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1938] call printf_ulong
    // [1428] phi from display_action_text_reading::@7 to printf_ulong [phi:display_action_text_reading::@7->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_reading::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_reading::@7->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@7->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = vera_size [phi:display_action_text_reading::@7->printf_ulong#3] -- vdum1=vduc1 
    lda #<vera_size
    sta printf_ulong.uvalue
    lda #>vera_size
    sta printf_ulong.uvalue+1
    lda #<vera_size>>$10
    sta printf_ulong.uvalue+2
    lda #>vera_size>>$10
    sta printf_ulong.uvalue+3
    jsr printf_ulong
    // [1939] phi from display_action_text_reading::@7 to display_action_text_reading::@8 [phi:display_action_text_reading::@7->display_action_text_reading::@8]
    // display_action_text_reading::@8
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1940] call printf_str
    // [626] phi from display_action_text_reading::@8 to printf_str [phi:display_action_text_reading::@8->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_reading::@8->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_reading::s3 [phi:display_action_text_reading::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@9
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1941] printf_uchar::uvalue#2 = display_action_text_reading::bram_bank#0 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [1942] call printf_uchar
    // [690] phi from display_action_text_reading::@9 to printf_uchar [phi:display_action_text_reading::@9->printf_uchar]
    // [690] phi printf_uchar::format_zero_padding#10 = 1 [phi:display_action_text_reading::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [690] phi printf_uchar::format_min_length#10 = 2 [phi:display_action_text_reading::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [690] phi printf_uchar::putc#10 = &snputc [phi:display_action_text_reading::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [690] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [690] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#2 [phi:display_action_text_reading::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1943] phi from display_action_text_reading::@9 to display_action_text_reading::@10 [phi:display_action_text_reading::@9->display_action_text_reading::@10]
    // display_action_text_reading::@10
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1944] call printf_str
    // [626] phi from display_action_text_reading::@10 to printf_str [phi:display_action_text_reading::@10->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_reading::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_reading::s4 [phi:display_action_text_reading::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@11
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1945] printf_uint::uvalue#2 = (unsigned int)display_action_text_reading::bram_ptr#0 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [1946] call printf_uint
    // [1537] phi from display_action_text_reading::@11 to printf_uint [phi:display_action_text_reading::@11->printf_uint]
    // [1537] phi printf_uint::format_zero_padding#4 = 1 [phi:display_action_text_reading::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1537] phi printf_uint::format_min_length#4 = 4 [phi:display_action_text_reading::@11->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1537] phi printf_uint::putc#4 = &snputc [phi:display_action_text_reading::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1537] phi printf_uint::format_radix#4 = HEXADECIMAL [phi:display_action_text_reading::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1537] phi printf_uint::uvalue#4 = printf_uint::uvalue#2 [phi:display_action_text_reading::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1947] phi from display_action_text_reading::@11 to display_action_text_reading::@12 [phi:display_action_text_reading::@11->display_action_text_reading::@12]
    // display_action_text_reading::@12
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1948] call printf_str
    // [626] phi from display_action_text_reading::@12 to printf_str [phi:display_action_text_reading::@12->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_reading::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_reading::s5 [phi:display_action_text_reading::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@13
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [1949] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1950] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1952] call display_action_text
    // [701] phi from display_action_text_reading::@13 to display_action_text [phi:display_action_text_reading::@13->display_action_text]
    // [701] phi display_action_text::info_text#17 = info_text [phi:display_action_text_reading::@13->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_reading::@return
    // }
    // [1953] return 
    rts
  .segment Data
    s: .text " "
    .byte 0
    s1: .text ":"
    .byte 0
    s2: .text "/"
    .byte 0
    s3: .text " -> RAM:"
    .byte 0
    s4: .text ":"
    .byte 0
    s5: .text " ..."
    .byte 0
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
// __mem() unsigned int fgets(__zp($4d) char *ptr, unsigned int size, __zp($71) struct $2 *stream)
fgets: {
    .label fgets__1 = $69
    .label fgets__8 = $3d
    .label fgets__9 = $50
    .label fgets__13 = $3e
    .label ptr = $4d
    .label stream = $71
    // unsigned char sp = (unsigned char)stream
    // [1954] fgets::sp#0 = (char)fgets::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [1955] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1956] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1958] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1960] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [1961] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@9
    // cbm_k_readst()
    // [1962] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [1963] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1964] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b8
    // [1965] phi from fgets::@10 fgets::@3 fgets::@9 to fgets::@return [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return]
  __b1:
    // [1965] phi fgets::return#1 = 0 [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [1966] return 
    rts
    // [1967] phi from fgets::@13 to fgets::@1 [phi:fgets::@13->fgets::@1]
    // [1967] phi fgets::read#10 = fgets::read#1 [phi:fgets::@13->fgets::@1#0] -- register_copy 
    // [1967] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@13->fgets::@1#1] -- register_copy 
    // [1967] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@13->fgets::@1#2] -- register_copy 
    // [1967] phi from fgets::@9 to fgets::@1 [phi:fgets::@9->fgets::@1]
  __b8:
    // [1967] phi fgets::read#10 = 0 [phi:fgets::@9->fgets::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [1967] phi fgets::remaining#11 = VERA_PROGRESS_CELL [phi:fgets::@9->fgets::@1#1] -- vwum1=vbuc1 
    lda #<VERA_PROGRESS_CELL
    sta remaining
    lda #>VERA_PROGRESS_CELL
    sta remaining+1
    // [1967] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@9->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@6
  __b6:
    // if (remaining >= 512)
    // [1968] if(fgets::remaining#11>=$200) goto fgets::@2 -- vwum1_ge_vwuc1_then_la1 
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
    // [1969] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [1970] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1971] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1972] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@12
  __b12:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1973] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1974] phi from fgets::@11 fgets::@12 to fgets::cbm_k_readst2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2]
    // [1974] phi fgets::bytes#10 = fgets::bytes#2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1975] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1977] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [1978] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@10
    // cbm_k_readst()
    // [1979] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [1980] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [1981] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [1982] if(0==fgets::$9) goto fgets::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    jmp __b1
    // fgets::@3
  __b3:
    // if (bytes == 0xFFFF)
    // [1983] if(fgets::bytes#10!=$ffff) goto fgets::@4 -- vwum1_neq_vwuc1_then_la1 
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
    // [1984] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [1985] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1986] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [1987] if(fgets::$13!=$c0) goto fgets::@5 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b5
    // fgets::@8
    // ptr -= 0x2000
    // [1988] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1989] phi from fgets::@4 fgets::@8 to fgets::@5 [phi:fgets::@4/fgets::@8->fgets::@5]
    // [1989] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@4/fgets::@8->fgets::@5#0] -- register_copy 
    // fgets::@5
  __b5:
    // remaining -= bytes
    // [1990] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1991] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@13 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b13
    // [1965] phi from fgets::@13 fgets::@5 to fgets::@return [phi:fgets::@13/fgets::@5->fgets::@return]
    // [1965] phi fgets::return#1 = fgets::read#1 [phi:fgets::@13/fgets::@5->fgets::@return#0] -- register_copy 
    rts
    // fgets::@13
  __b13:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1992] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b6+
    jmp __b6
  !__b6:
    rts
    // fgets::@2
  __b2:
    // cx16_k_macptr(512, ptr)
    // [1993] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [1994] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1995] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1996] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@11
    // bytes = cx16_k_macptr(512, ptr)
    // [1997] fgets::bytes#2 = cx16_k_macptr::return#3
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
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($32) char *str)
strlen: {
    .label str = $32
    // [1999] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1999] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [1999] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2000] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2001] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2002] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [2003] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1999] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1999] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1999] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($4b) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $4b
    // [2005] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2005] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2006] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [2007] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2008] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [2009] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall19
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2011] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2005] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2005] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
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
  // uctoa_append
// Used to convert a single digit of an unsigned number value to a string representation
// Counts a single digit up from '0' as long as the value is larger than sub.
// Each time the digit is increased sub is subtracted from value.
// - buffer : pointer to the char that receives the digit
// - value : The value where the digit will be derived from
// - sub : the value of a '1' in the digit. Subtracted continually while the digit is increased.
//        (For decimal the subs used are 10000, 1000, 100, 10, 1)
// returns : the value reduced by sub * digit so that it is less than sub.
// __mem() char uctoa_append(__zp($46) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $46
    // [2013] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2013] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2013] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2014] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2015] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2016] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2017] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2018] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [2013] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2013] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2013] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uchar.uvalue
    .label sub = uctoa.digit_value
    .label return = printf_uchar.uvalue
    digit: .byte 0
}
.segment CodeVera
  // spi_wait_non_busy
spi_wait_non_busy: {
    .label w = $4a
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
    .label y = $63
    .label return = $ba
    // [2020] phi from spi_wait_non_busy to spi_wait_non_busy::@1 [phi:spi_wait_non_busy->spi_wait_non_busy::@1]
    // [2020] phi spi_wait_non_busy::y#2 = 0 [phi:spi_wait_non_busy->spi_wait_non_busy::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // spi_wait_non_busy::@1
    // [2021] phi from spi_wait_non_busy::@1 to spi_wait_non_busy::@2 [phi:spi_wait_non_busy::@1->spi_wait_non_busy::@2]
    // spi_wait_non_busy::@2
  __b2:
    // spi_select()
    // [2022] call spi_select
    // [2080] phi from spi_wait_non_busy::@2 to spi_select [phi:spi_wait_non_busy::@2->spi_select]
    jsr spi_select
    // spi_wait_non_busy::@5
    // spi_write(0x05)
    // [2023] spi_write::data = 5 -- vbuz1=vbuc1 
    lda #5
    sta.z spi_write.data
    // [2024] call spi_write
    jsr spi_write
    // [2025] phi from spi_wait_non_busy::@5 to spi_wait_non_busy::@6 [phi:spi_wait_non_busy::@5->spi_wait_non_busy::@6]
    // spi_wait_non_busy::@6
    // unsigned char w = spi_read()
    // [2026] call spi_read
    jsr spi_read
    // [2027] spi_read::return#11 = spi_read::return#12
    // spi_wait_non_busy::@7
    // [2028] spi_wait_non_busy::w#0 = spi_read::return#11
    // w &= 1
    // [2029] spi_wait_non_busy::w#1 = spi_wait_non_busy::w#0 & 1 -- vbuz1=vbuz1_band_vbuc1 
    lda #1
    and.z w
    sta.z w
    // if(w == 0)
    // [2030] if(spi_wait_non_busy::w#1==0) goto spi_wait_non_busy::@return -- vbuz1_eq_0_then_la1 
    beq __b1
    // spi_wait_non_busy::@4
    // y++;
    // [2031] spi_wait_non_busy::y#1 = ++ spi_wait_non_busy::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // if(y == 0)
    // [2032] if(spi_wait_non_busy::y#1!=0) goto spi_wait_non_busy::@3 -- vbuz1_neq_0_then_la1 
    lda.z y
    bne __b3
    // [2033] phi from spi_wait_non_busy::@4 to spi_wait_non_busy::@return [phi:spi_wait_non_busy::@4->spi_wait_non_busy::@return]
    // [2033] phi spi_wait_non_busy::return#3 = 1 [phi:spi_wait_non_busy::@4->spi_wait_non_busy::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    rts
    // [2033] phi from spi_wait_non_busy::@7 to spi_wait_non_busy::@return [phi:spi_wait_non_busy::@7->spi_wait_non_busy::@return]
  __b1:
    // [2033] phi spi_wait_non_busy::return#3 = 0 [phi:spi_wait_non_busy::@7->spi_wait_non_busy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    // spi_wait_non_busy::@return
    // }
    // [2034] return 
    rts
    // spi_wait_non_busy::@3
  __b3:
    // asm
    // asm { .byte$CB  }
    // WAI
    .byte $cb
    // [2020] phi from spi_wait_non_busy::@3 to spi_wait_non_busy::@1 [phi:spi_wait_non_busy::@3->spi_wait_non_busy::@1]
    // [2020] phi spi_wait_non_busy::y#2 = spi_wait_non_busy::y#1 [phi:spi_wait_non_busy::@3->spi_wait_non_busy::@1#0] -- register_copy 
    jmp __b2
}
  // spi_read_flash
// void spi_read_flash(unsigned long spi_data)
spi_read_flash: {
    // spi_select()
    // [2037] call spi_select
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
    // [2080] phi from spi_read_flash to spi_select [phi:spi_read_flash->spi_select]
    jsr spi_select
    // spi_read_flash::@1
    // spi_write(0x03)
    // [2038] spi_write::data = 3 -- vbuz1=vbuc1 
    lda #3
    sta.z spi_write.data
    // [2039] call spi_write
    jsr spi_write
    // spi_read_flash::@2
    // spi_write(BYTE2(spi_data))
    // [2040] spi_write::data = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z spi_write.data
    // [2041] call spi_write
    jsr spi_write
    // spi_read_flash::@3
    // spi_write(BYTE1(spi_data))
    // [2042] spi_write::data = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z spi_write.data
    // [2043] call spi_write
    jsr spi_write
    // spi_read_flash::@4
    // spi_write(BYTE0(spi_data))
    // [2044] spi_write::data = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z spi_write.data
    // [2045] call spi_write
    jsr spi_write
    // spi_read_flash::@return
    // }
    // [2046] return 
    rts
}
  // spi_read
spi_read: {
    .label return = $4a
    // asm
    // asm { stzvera_reg_SPIData !: bitvera_reg_SPICtrl bmi!-  }
    /*
    .proc spi_read
	stz Vera::Reg::SPIData
@1:	bit Vera::Reg::SPICtrl
	bmi @1
    lda Vera::Reg::SPIData
	rts
.endproc
*/
    stz vera_reg_SPIData
  !:
    bit vera_reg_SPICtrl
    bmi !-
    // return *vera_reg_SPIData;
    // [2048] spi_read::return#12 = *vera_reg_SPIData -- vbuz1=_deref_pbuc1 
    lda vera_reg_SPIData
    sta.z return
    // spi_read::@return
    // }
    // [2049] return 
    rts
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
    .label ultoa__4 = $3d
    .label ultoa__10 = $3e
    .label ultoa__11 = $50
    .label buffer = $37
    .label digit_values = $32
    // if(radix==DECIMAL)
    // [2050] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2051] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2052] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2053] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2054] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2055] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2056] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2057] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2058] return 
    rts
    // [2059] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2059] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2059] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2059] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2059] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2059] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2059] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2059] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2059] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2059] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2059] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2059] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2060] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2060] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2060] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2060] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2060] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2061] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2062] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2063] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2064] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2065] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2066] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2067] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2068] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2069] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2070] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2071] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2071] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2071] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2071] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2072] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2060] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2060] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2060] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2060] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2060] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2073] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2074] ultoa_append::value#0 = ultoa::value#2
    // [2075] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2076] call ultoa_append
    // [2427] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2077] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2078] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2079] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2071] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2071] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2071] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2071] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .dword 0
    digit: .byte 0
    .label value = printf_ulong.uvalue
    .label radix = printf_ulong.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment CodeVera
  // spi_select
spi_select: {
    // spi_deselect()
    // [2081] call spi_deselect
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
    // [2082] *vera_reg_SPICtrl = *vera_reg_SPICtrl | 1 -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #1
    ora vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // spi_select::@return
    // }
    // [2083] return 
    rts
}
  // spi_block_erase
// void spi_block_erase(__zp($cd) unsigned long data)
spi_block_erase: {
    .label spi_block_erase__4 = $ae
    .label spi_block_erase__6 = $41
    .label spi_block_erase__8 = $4a
    .label data = $cd
    // spi_select()
    // [2085] call spi_select
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
    // [2080] phi from spi_block_erase to spi_select [phi:spi_block_erase->spi_select]
    jsr spi_select
    // spi_block_erase::@1
    // spi_write(0x06)
    // [2086] spi_write::data = 6 -- vbuz1=vbuc1 
    lda #6
    sta.z spi_write.data
    // [2087] call spi_write
    jsr spi_write
    // [2088] phi from spi_block_erase::@1 to spi_block_erase::@2 [phi:spi_block_erase::@1->spi_block_erase::@2]
    // spi_block_erase::@2
    // spi_select()
    // [2089] call spi_select
    // [2080] phi from spi_block_erase::@2 to spi_select [phi:spi_block_erase::@2->spi_select]
    jsr spi_select
    // spi_block_erase::@3
    // spi_write(0xD8)
    // [2090] spi_write::data = $d8 -- vbuz1=vbuc1 
    lda #$d8
    sta.z spi_write.data
    // [2091] call spi_write
    jsr spi_write
    // spi_block_erase::@4
    // BYTE2(data)
    // [2092] spi_block_erase::$4 = byte2  spi_block_erase::data#0 -- vbuz1=_byte2_vduz2 
    lda.z data+2
    sta.z spi_block_erase__4
    // spi_write(BYTE2(data))
    // [2093] spi_write::data = spi_block_erase::$4 -- vbuz1=vbuz2 
    sta.z spi_write.data
    // [2094] call spi_write
    jsr spi_write
    // spi_block_erase::@5
    // BYTE1(data)
    // [2095] spi_block_erase::$6 = byte1  spi_block_erase::data#0 -- vbuz1=_byte1_vduz2 
    lda.z data+1
    sta.z spi_block_erase__6
    // spi_write(BYTE1(data))
    // [2096] spi_write::data = spi_block_erase::$6 -- vbuz1=vbuz2 
    sta.z spi_write.data
    // [2097] call spi_write
    jsr spi_write
    // spi_block_erase::@6
    // BYTE0(data)
    // [2098] spi_block_erase::$8 = byte0  spi_block_erase::data#0 -- vbuz1=_byte0_vduz2 
    lda.z data
    sta.z spi_block_erase__8
    // spi_write(BYTE0(data))
    // [2099] spi_write::data = spi_block_erase::$8 -- vbuz1=vbuz2 
    sta.z spi_write.data
    // [2100] call spi_write
    jsr spi_write
    // [2101] phi from spi_block_erase::@6 to spi_block_erase::@7 [phi:spi_block_erase::@6->spi_block_erase::@7]
    // spi_block_erase::@7
    // spi_deselect()
    // [2102] call spi_deselect
    jsr spi_deselect
    // spi_block_erase::@return
    // }
    // [2103] return 
    rts
}
.segment Code
  // display_action_text_flashed
// void display_action_text_flashed(__zp($ef) unsigned long bytes, char *chip)
display_action_text_flashed: {
    .label bytes = $ef
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2105] call snprintf_init
    jsr snprintf_init
    // [2106] phi from display_action_text_flashed to display_action_text_flashed::@1 [phi:display_action_text_flashed->display_action_text_flashed::@1]
    // display_action_text_flashed::@1
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2107] call printf_str
    // [626] phi from display_action_text_flashed::@1 to printf_str [phi:display_action_text_flashed::@1->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashed::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashed::s [phi:display_action_text_flashed::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@2
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2108] printf_ulong::uvalue#2 = display_action_text_flashed::bytes#0 -- vdum1=vduz2 
    lda.z bytes
    sta printf_ulong.uvalue
    lda.z bytes+1
    sta printf_ulong.uvalue+1
    lda.z bytes+2
    sta printf_ulong.uvalue+2
    lda.z bytes+3
    sta printf_ulong.uvalue+3
    // [2109] call printf_ulong
    // [1428] phi from display_action_text_flashed::@2 to printf_ulong [phi:display_action_text_flashed::@2->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 0 [phi:display_action_text_flashed::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 0 [phi:display_action_text_flashed::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = DECIMAL [phi:display_action_text_flashed::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#2 [phi:display_action_text_flashed::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2110] phi from display_action_text_flashed::@2 to display_action_text_flashed::@3 [phi:display_action_text_flashed::@2->display_action_text_flashed::@3]
    // display_action_text_flashed::@3
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2111] call printf_str
    // [626] phi from display_action_text_flashed::@3 to printf_str [phi:display_action_text_flashed::@3->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashed::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashed::s1 [phi:display_action_text_flashed::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [2112] phi from display_action_text_flashed::@3 to display_action_text_flashed::@4 [phi:display_action_text_flashed::@3->display_action_text_flashed::@4]
    // display_action_text_flashed::@4
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2113] call printf_string
    // [1261] phi from display_action_text_flashed::@4 to printf_string [phi:display_action_text_flashed::@4->printf_string]
    // [1261] phi printf_string::putc#17 = &snputc [phi:display_action_text_flashed::@4->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = w25q16_flash::chip [phi:display_action_text_flashed::@4->printf_string#1] -- pbuz1=pbuc1 
    lda #<w25q16_flash.chip
    sta.z printf_string.str
    lda #>w25q16_flash.chip
    sta.z printf_string.str+1
    // [1261] phi printf_string::format_justify_left#17 = 0 [phi:display_action_text_flashed::@4->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 0 [phi:display_action_text_flashed::@4->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2114] phi from display_action_text_flashed::@4 to display_action_text_flashed::@5 [phi:display_action_text_flashed::@4->display_action_text_flashed::@5]
    // display_action_text_flashed::@5
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2115] call printf_str
    // [626] phi from display_action_text_flashed::@5 to printf_str [phi:display_action_text_flashed::@5->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashed::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashed::s2 [phi:display_action_text_flashed::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@6
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2116] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2117] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2119] call display_action_text
    // [701] phi from display_action_text_flashed::@6 to display_action_text [phi:display_action_text_flashed::@6->display_action_text]
    // [701] phi display_action_text::info_text#17 = info_text [phi:display_action_text_flashed::@6->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashed::@return
    // }
    // [2120] return 
    rts
  .segment Data
    s: .text "Flashed "
    .byte 0
    s1: .text " bytes from RAM -> "
    .byte 0
    s2: .text " ... "
    .byte 0
}
.segment CodeVera
  // spi_write_page_begin
// void spi_write_page_begin(__zp($ef) unsigned long data)
spi_write_page_begin: {
    .label spi_write_page_begin__4 = $ae
    .label spi_write_page_begin__6 = $41
    .label spi_write_page_begin__8 = $4a
    .label data = $ef
    // spi_select()
    // [2122] call spi_select
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
    // [2080] phi from spi_write_page_begin to spi_select [phi:spi_write_page_begin->spi_select]
    jsr spi_select
    // spi_write_page_begin::@1
    // spi_write(0x06)
    // [2123] spi_write::data = 6 -- vbuz1=vbuc1 
    lda #6
    sta.z spi_write.data
    // [2124] call spi_write
    jsr spi_write
    // [2125] phi from spi_write_page_begin::@1 to spi_write_page_begin::@2 [phi:spi_write_page_begin::@1->spi_write_page_begin::@2]
    // spi_write_page_begin::@2
    // spi_select()
    // [2126] call spi_select
    // [2080] phi from spi_write_page_begin::@2 to spi_select [phi:spi_write_page_begin::@2->spi_select]
    jsr spi_select
    // spi_write_page_begin::@3
    // spi_write(0x02)
    // [2127] spi_write::data = 2 -- vbuz1=vbuc1 
    lda #2
    sta.z spi_write.data
    // [2128] call spi_write
    jsr spi_write
    // spi_write_page_begin::@4
    // BYTE2(data)
    // [2129] spi_write_page_begin::$4 = byte2  spi_write_page_begin::data#0 -- vbuz1=_byte2_vduz2 
    lda.z data+2
    sta.z spi_write_page_begin__4
    // spi_write(BYTE2(data))
    // [2130] spi_write::data = spi_write_page_begin::$4 -- vbuz1=vbuz2 
    sta.z spi_write.data
    // [2131] call spi_write
    jsr spi_write
    // spi_write_page_begin::@5
    // BYTE1(data)
    // [2132] spi_write_page_begin::$6 = byte1  spi_write_page_begin::data#0 -- vbuz1=_byte1_vduz2 
    lda.z data+1
    sta.z spi_write_page_begin__6
    // spi_write(BYTE1(data))
    // [2133] spi_write::data = spi_write_page_begin::$6 -- vbuz1=vbuz2 
    sta.z spi_write.data
    // [2134] call spi_write
    jsr spi_write
    // spi_write_page_begin::@6
    // BYTE0(data)
    // [2135] spi_write_page_begin::$8 = byte0  spi_write_page_begin::data#0 -- vbuz1=_byte0_vduz2 
    lda.z data
    sta.z spi_write_page_begin__8
    // spi_write(BYTE0(data))
    // [2136] spi_write::data = spi_write_page_begin::$8 -- vbuz1=vbuz2 
    sta.z spi_write.data
    // [2137] call spi_write
    jsr spi_write
    // spi_write_page_begin::@return
    // }
    // [2138] return 
    rts
}
.segment Code
  // get_info_text_flashing
// char * get_info_text_flashing(__zp($e5) unsigned long flash_bytes)
get_info_text_flashing: {
    .label flash_bytes = $e5
    // sprintf(info_text, "%u bytes flashed", flash_bytes)
    // [2140] call snprintf_init
    jsr snprintf_init
    // get_info_text_flashing::@1
    // [2141] printf_ulong::uvalue#5 = get_info_text_flashing::flash_bytes#0 -- vdum1=vduz2 
    lda.z flash_bytes
    sta printf_ulong.uvalue
    lda.z flash_bytes+1
    sta printf_ulong.uvalue+1
    lda.z flash_bytes+2
    sta printf_ulong.uvalue+2
    lda.z flash_bytes+3
    sta printf_ulong.uvalue+3
    // [2142] call printf_ulong
    // [1428] phi from get_info_text_flashing::@1 to printf_ulong [phi:get_info_text_flashing::@1->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 0 [phi:get_info_text_flashing::@1->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 0 [phi:get_info_text_flashing::@1->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = DECIMAL [phi:get_info_text_flashing::@1->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#5 [phi:get_info_text_flashing::@1->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2143] phi from get_info_text_flashing::@1 to get_info_text_flashing::@2 [phi:get_info_text_flashing::@1->get_info_text_flashing::@2]
    // get_info_text_flashing::@2
    // sprintf(info_text, "%u bytes flashed", flash_bytes)
    // [2144] call printf_str
    // [626] phi from get_info_text_flashing::@2 to printf_str [phi:get_info_text_flashing::@2->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:get_info_text_flashing::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = get_info_text_flashing::s [phi:get_info_text_flashing::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // get_info_text_flashing::@3
    // sprintf(info_text, "%u bytes flashed", flash_bytes)
    // [2145] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2146] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // get_info_text_flashing::@return
    // }
    // [2148] return 
    rts
  .segment Data
    s: .text " bytes flashed"
    .byte 0
}
.segment Code
  // display_action_text_flashing
// void display_action_text_flashing(unsigned long bytes, char *chip, __zp($d1) char bram_bank, __zp($d6) char *bram_ptr, __zp($db) unsigned long address)
display_action_text_flashing: {
    .label bram_bank = $d1
    .label bram_ptr = $d6
    .label address = $db
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2150] call snprintf_init
    jsr snprintf_init
    // [2151] phi from display_action_text_flashing to display_action_text_flashing::@1 [phi:display_action_text_flashing->display_action_text_flashing::@1]
    // display_action_text_flashing::@1
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2152] call printf_str
    // [626] phi from display_action_text_flashing::@1 to printf_str [phi:display_action_text_flashing::@1->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashing::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashing::s [phi:display_action_text_flashing::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [2153] phi from display_action_text_flashing::@1 to display_action_text_flashing::@2 [phi:display_action_text_flashing::@1->display_action_text_flashing::@2]
    // display_action_text_flashing::@2
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2154] call printf_ulong
    // [1428] phi from display_action_text_flashing::@2 to printf_ulong [phi:display_action_text_flashing::@2->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 0 [phi:display_action_text_flashing::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 0 [phi:display_action_text_flashing::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = DECIMAL [phi:display_action_text_flashing::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = VERA_PROGRESS_PAGE [phi:display_action_text_flashing::@2->printf_ulong#3] -- vdum1=vduc1 
    lda #<VERA_PROGRESS_PAGE
    sta printf_ulong.uvalue
    lda #>VERA_PROGRESS_PAGE
    sta printf_ulong.uvalue+1
    lda #<VERA_PROGRESS_PAGE>>$10
    sta printf_ulong.uvalue+2
    lda #>VERA_PROGRESS_PAGE>>$10
    sta printf_ulong.uvalue+3
    jsr printf_ulong
    // [2155] phi from display_action_text_flashing::@2 to display_action_text_flashing::@3 [phi:display_action_text_flashing::@2->display_action_text_flashing::@3]
    // display_action_text_flashing::@3
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2156] call printf_str
    // [626] phi from display_action_text_flashing::@3 to printf_str [phi:display_action_text_flashing::@3->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashing::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashing::s1 [phi:display_action_text_flashing::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@4
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2157] printf_uchar::uvalue#1 = display_action_text_flashing::bram_bank#0 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [2158] call printf_uchar
    // [690] phi from display_action_text_flashing::@4 to printf_uchar [phi:display_action_text_flashing::@4->printf_uchar]
    // [690] phi printf_uchar::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@4->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [690] phi printf_uchar::format_min_length#10 = 2 [phi:display_action_text_flashing::@4->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [690] phi printf_uchar::putc#10 = &snputc [phi:display_action_text_flashing::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [690] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@4->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [690] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#1 [phi:display_action_text_flashing::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2159] phi from display_action_text_flashing::@4 to display_action_text_flashing::@5 [phi:display_action_text_flashing::@4->display_action_text_flashing::@5]
    // display_action_text_flashing::@5
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2160] call printf_str
    // [626] phi from display_action_text_flashing::@5 to printf_str [phi:display_action_text_flashing::@5->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashing::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashing::s2 [phi:display_action_text_flashing::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@6
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2161] printf_uint::uvalue#1 = (unsigned int)display_action_text_flashing::bram_ptr#0 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2162] call printf_uint
    // [1537] phi from display_action_text_flashing::@6 to printf_uint [phi:display_action_text_flashing::@6->printf_uint]
    // [1537] phi printf_uint::format_zero_padding#4 = 1 [phi:display_action_text_flashing::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1537] phi printf_uint::format_min_length#4 = 4 [phi:display_action_text_flashing::@6->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1537] phi printf_uint::putc#4 = &snputc [phi:display_action_text_flashing::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1537] phi printf_uint::format_radix#4 = HEXADECIMAL [phi:display_action_text_flashing::@6->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1537] phi printf_uint::uvalue#4 = printf_uint::uvalue#1 [phi:display_action_text_flashing::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2163] phi from display_action_text_flashing::@6 to display_action_text_flashing::@7 [phi:display_action_text_flashing::@6->display_action_text_flashing::@7]
    // display_action_text_flashing::@7
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2164] call printf_str
    // [626] phi from display_action_text_flashing::@7 to printf_str [phi:display_action_text_flashing::@7->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashing::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashing::s3 [phi:display_action_text_flashing::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // [2165] phi from display_action_text_flashing::@7 to display_action_text_flashing::@8 [phi:display_action_text_flashing::@7->display_action_text_flashing::@8]
    // display_action_text_flashing::@8
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2166] call printf_string
    // [1261] phi from display_action_text_flashing::@8 to printf_string [phi:display_action_text_flashing::@8->printf_string]
    // [1261] phi printf_string::putc#17 = &snputc [phi:display_action_text_flashing::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1261] phi printf_string::str#17 = w25q16_flash::chip1 [phi:display_action_text_flashing::@8->printf_string#1] -- pbuz1=pbuc1 
    lda #<w25q16_flash.chip1
    sta.z printf_string.str
    lda #>w25q16_flash.chip1
    sta.z printf_string.str+1
    // [1261] phi printf_string::format_justify_left#17 = 0 [phi:display_action_text_flashing::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1261] phi printf_string::format_min_length#17 = 0 [phi:display_action_text_flashing::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2167] phi from display_action_text_flashing::@8 to display_action_text_flashing::@9 [phi:display_action_text_flashing::@8->display_action_text_flashing::@9]
    // display_action_text_flashing::@9
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2168] call printf_str
    // [626] phi from display_action_text_flashing::@9 to printf_str [phi:display_action_text_flashing::@9->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashing::@9->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashing::s4 [phi:display_action_text_flashing::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@10
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2169] printf_ulong::uvalue#1 = display_action_text_flashing::address#0 -- vdum1=vduz2 
    lda.z address
    sta printf_ulong.uvalue
    lda.z address+1
    sta printf_ulong.uvalue+1
    lda.z address+2
    sta printf_ulong.uvalue+2
    lda.z address+3
    sta printf_ulong.uvalue+3
    // [2170] call printf_ulong
    // [1428] phi from display_action_text_flashing::@10 to printf_ulong [phi:display_action_text_flashing::@10->printf_ulong]
    // [1428] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@10->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1428] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_flashing::@10->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1428] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@10->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1428] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#1 [phi:display_action_text_flashing::@10->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2171] phi from display_action_text_flashing::@10 to display_action_text_flashing::@11 [phi:display_action_text_flashing::@10->display_action_text_flashing::@11]
    // display_action_text_flashing::@11
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2172] call printf_str
    // [626] phi from display_action_text_flashing::@11 to printf_str [phi:display_action_text_flashing::@11->printf_str]
    // [626] phi printf_str::putc#49 = &snputc [phi:display_action_text_flashing::@11->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [626] phi printf_str::s#49 = display_action_text_flashing::s5 [phi:display_action_text_flashing::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@12
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2173] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2174] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2176] call display_action_text
    // [701] phi from display_action_text_flashing::@12 to display_action_text [phi:display_action_text_flashing::@12->display_action_text]
    // [701] phi display_action_text::info_text#17 = info_text [phi:display_action_text_flashing::@12->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashing::@return
    // }
    // [2177] return 
    rts
  .segment Data
    s: .text "Flashing "
    .byte 0
    s1: .text " bytes from RAM:"
    .byte 0
    s2: .text ":"
    .byte 0
    s3: .text " -> "
    .byte 0
    s4: .text ":"
    .byte 0
    s5: .text " ... "
    .byte 0
}
.segment CodeVera
  // spi_write
/**
 * @brief 
 * 
 * 
 */
// void spi_write(__zp($67) volatile char data)
spi_write: {
    .label data = $67
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
    // [2179] return 
    rts
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
// void display_chip_led(__zp($54) char x, char y, __zp($53) char w, __zp($66) char tc, char bc)
display_chip_led: {
    .label x = $54
    .label w = $53
    .label tc = $66
    // textcolor(tc)
    // [2181] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [2182] call textcolor
    // [439] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [439] phi textcolor::color#21 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2183] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2184] call bgcolor
    // [444] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [2185] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2185] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2185] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2186] cputcxy::x#9 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2187] call cputcxy
    // [1200] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1200] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [1200] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [1200] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2188] cputcxy::x#10 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2189] call cputcxy
    // [1200] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1200] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [1200] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [1200] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2190] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2191] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2192] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2193] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2194] call textcolor
    // [439] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2195] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2196] call bgcolor
    // [444] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2197] return 
    rts
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($39) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $40
    .label utoa__10 = $3f
    .label utoa__11 = $60
    .label buffer = $39
    .label digit_values = $37
    // if(radix==DECIMAL)
    // [2198] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [2199] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [2200] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [2201] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [2202] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2203] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2204] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2205] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [2206] return 
    rts
    // [2207] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [2207] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [2207] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [2207] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [2207] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [2207] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [2207] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [2207] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [2207] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [2207] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [2207] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [2207] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [2208] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [2208] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2208] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2208] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [2208] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [2209] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2210] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2211] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [2212] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2213] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2214] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [2215] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [2216] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [2217] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [2218] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [2219] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [2219] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [2219] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [2219] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2220] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2208] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [2208] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [2208] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [2208] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [2208] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [2221] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [2222] utoa_append::value#0 = utoa::value#2
    // [2223] utoa_append::sub#0 = utoa::digit_value#0
    // [2224] call utoa_append
    // [2434] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [2225] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [2226] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [2227] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2219] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [2219] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [2219] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2219] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
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
    // [2228] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2229] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2230] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2231] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2232] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2233] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2234] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2235] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2236] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2237] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2238] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2239] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2240] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2241] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2242] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2242] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2243] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [2244] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2245] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2246] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2247] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
  // display_frame_maskxy
/**
 * @brief 
 * 
 * @param x 
 * @param y 
 * @return unsigned char 
 */
// __zp($6a) char display_frame_maskxy(__zp($aa) char x, __zp($b4) char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $40
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $60
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $3f
    .label c = $6b
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
    .label return = $6a
    .label x = $aa
    .label y = $b4
    .label x_1 = $b0
    .label y_1 = $7a
    .label x_2 = $bb
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2249] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [2250] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [2251] call gotoxy
    // [457] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2252] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2253] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2254] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2255] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2256] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2257] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2258] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2259] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2260] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2261] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2262] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2263] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2264] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2265] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2266] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2267] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2268] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2269] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2270] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2272] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2272] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [2271] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2272] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2272] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2272] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2272] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2272] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2272] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2272] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2272] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2272] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2272] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2272] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [2272] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2272] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // display_frame_maskxy::@return
    // }
    // [2273] return 
    rts
  .segment Data
    cpeekcxy1_x: .byte 0
    cpeekcxy1_y: .byte 0
}
.segment Code
  // display_frame_char
/**
 * @brief 
 * 
 * @param mask 
 * @return unsigned char 
 */
// __zp($78) char display_frame_char(__zp($6a) char mask)
display_frame_char: {
    .label return = $78
    .label mask = $6a
    // case 0b0110:
    //             return 0x70;
    // [2275] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2276] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2277] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2278] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2279] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2280] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2281] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2282] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2283] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2284] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2285] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [2287] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2287] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2286] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2287] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2287] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2287] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2287] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2287] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2287] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2287] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2287] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2287] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2287] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2287] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2287] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2287] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2287] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2287] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2287] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2287] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2287] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2287] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2287] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2287] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2287] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // display_frame_char::@return
    // }
    // [2288] return 
    rts
}
  // display_chip_line
/**
 * @brief Print one line of a chip figure.
 * 
 * @param x Start X
 * @param y Start Y
 * @param w Width
 * @param c Fore color
 */
// void display_chip_line(__zp($7e) char x, __zp($d8) char y, __zp($68) char w, __zp($76) char c)
display_chip_line: {
    .label i = $5c
    .label x = $7e
    .label w = $68
    .label c = $76
    .label y = $d8
    // gotoxy(x, y)
    // [2290] gotoxy::x#7 = display_chip_line::x#16 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [2291] gotoxy::y#7 = display_chip_line::y#16 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [2292] call gotoxy
    // [457] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [457] phi gotoxy::y#26 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [457] phi gotoxy::x#26 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2293] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [2294] call textcolor
    // [439] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [439] phi textcolor::color#21 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2295] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [2296] call bgcolor
    // [444] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2297] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2298] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2300] call textcolor
    // [439] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2301] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [2302] call bgcolor
    // [444] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [444] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2303] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [2303] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2304] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2305] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [2306] call textcolor
    // [439] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [439] phi textcolor::color#21 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2307] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [2308] call bgcolor
    // [444] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2309] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2310] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2312] call textcolor
    // [439] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [439] phi textcolor::color#21 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2313] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [2314] call bgcolor
    // [444] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [444] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2315] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbum1=vbuz2_plus_2 
    lda.z x
    clc
    adc #2
    sta cputcxy.x
    // [2316] cputcxy::y#8 = display_chip_line::y#16 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [2317] cputcxy::c#8 = display_chip_line::c#15 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2318] call cputcxy
    // [1200] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1200] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1200] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1200] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2319] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2320] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2321] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2323] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2303] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [2303] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // display_chip_end
/**
 * @brief Print last line of a chip figure.
 * 
 * @param x Start X
 * @param y Start Y
 * @param w Width
 */
// void display_chip_end(__zp($7f) char x, char y, __zp($60) char w)
display_chip_end: {
    .label i = $5d
    .label x = $7f
    .label w = $60
    // gotoxy(x, y)
    // [2324] gotoxy::x#8 = display_chip_end::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [2325] call gotoxy
    // [457] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [457] phi gotoxy::y#26 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [457] phi gotoxy::x#26 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2326] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2327] call textcolor
    // [439] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [439] phi textcolor::color#21 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2328] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2329] call bgcolor
    // [444] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2330] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2331] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2333] call textcolor
    // [439] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [439] phi textcolor::color#21 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [2334] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2335] call bgcolor
    // [444] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [444] phi bgcolor::color#15 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2336] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2336] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2337] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2338] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2339] call textcolor
    // [439] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [439] phi textcolor::color#21 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2340] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2341] call bgcolor
    // [444] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [444] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2342] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2343] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2345] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2346] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2347] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2349] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2336] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2336] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
    jmp __b1
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
    // [2351] return 
    rts
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
    // [2353] return 
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
// __mem() int ferror(__zp($4b) struct $2 *stream)
ferror: {
    .label ferror__6 = $6b
    .label ferror__15 = $73
    .label cbm_k_setnam1_filename = $ea
    .label cbm_k_setnam1_ferror__0 = $35
    .label stream = $4b
    .label errno_len = $7b
    // unsigned char sp = (unsigned char)stream
    // [2354] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [2355] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2356] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2357] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2358] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2359] ferror::cbm_k_setnam1_filename = ferror::$18 -- pbuz1=pbuc1 
    lda #<ferror__18
    sta.z cbm_k_setnam1_filename
    lda #>ferror__18
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2360] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2361] call strlen
    // [1998] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1998] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2362] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2363] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [2364] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2367] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2368] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2370] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2372] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2373] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2374] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2375] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2375] phi __errno#18 = __errno#118 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2375] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2375] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2375] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2376] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2378] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2379] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2380] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [2381] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [2382] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [2383] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2384] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2386] ferror::return#1 = __errno#18 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2387] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2388] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2389] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2390] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2391] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [2392] call strncpy
    // [2441] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [2393] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2394] call atoi
    // [2406] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2406] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2395] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2396] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [2397] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2397] phi __errno#116 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2397] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2398] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2399] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2400] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2402] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2403] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2404] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [2405] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [2375] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2375] phi __errno#18 = __errno#116 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2375] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2375] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2375] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    ferror__18: .text ""
    .byte 0
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
// __mem() int atoi(__zp($5e) const char *str)
atoi: {
    .label atoi__6 = $3b
    .label atoi__7 = $3b
    .label str = $5e
    .label atoi__10 = $3b
    .label atoi__11 = $3b
    // if (str[i] == '-')
    // [2407] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2408] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2409] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2409] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [2409] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [2409] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [2409] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2409] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [2409] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [2409] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2410] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2411] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2412] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [2414] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2414] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2413] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [2415] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2416] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2417] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [2418] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2419] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2420] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2421] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [2409] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2409] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2409] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2409] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
    // [2422] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [2424] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [2425] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2426] return 
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
// __mem() unsigned long ultoa_append(__zp($44) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $44
    // [2428] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2428] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2428] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2429] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [2430] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2431] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2432] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2433] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [2428] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2428] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2428] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_ulong.uvalue
    .label sub = ultoa.digit_value
    .label return = printf_ulong.uvalue
    digit: .byte 0
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
// __mem() unsigned int utoa_append(__zp($35) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $35
    // [2435] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2435] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2435] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2436] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [2437] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2438] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2439] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2440] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [2435] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2435] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2435] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uint.uvalue
    .label sub = utoa.digit_value
    .label return = printf_uint.uvalue
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
// char * strncpy(__zp($55) char *dst, __zp($39) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $55
    .label src = $39
    // [2442] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2442] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [2442] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [2442] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2443] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [2444] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2445] strncpy::c#0 = *strncpy::src#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [2446] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [2447] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2448] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2448] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2449] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2450] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2451] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [2442] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2442] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2442] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2442] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
  info_text: .fill $50, 0
  status_text: .word __3, __4, __5, __6, __7, __8, __9, __10, __11, __12, __13, __14
  status_color: .byte BLACK, GREY, WHITE, CYAN, PURPLE, CYAN, PURPLE, PURPLE, GREEN, YELLOW, RED, PINK
  status_rom: .byte 0
  .fill 7, 0
.segment DataIntro
  display_into_briefing_text: .word __15, __16, __17, __18, __19, __20, __21, __22, __23, __24, __25, __26, __27, __28, __29
  display_into_colors_text: .word __30, __31, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, __42, __43, __44, __45
.segment DataVera
  display_jp1_spi_vera_text: .word __46, __47, __48, __49, __50, __51, __52, __53, __54, __55, __56, __57, __58, __59, __60, __61
  display_smc_rom_issue_text: .word __62, __63, __64, __65, __66, __67, __68, __69
  display_smc_unsupported_rom_text: .word __70, __71, __72, __73, __74, __75, __76
.segment Data
  display_debriefing_smc_text: .word __77, __78, __79, __80, __81, __82, __83, __84, __85, __86, __87, __88, __89, __90
  display_debriefing_text_rom: .word __91, __92, __93, __94, __95, __96
  smc_file_header: .fill $20, 0
  smc_version_text: .fill $10, 0
  rom_device_names: .word 0
  .fill 2*7, 0
  rom_size_strings: .word 0
  .fill 2*7, 0
  rom_release_text: .fill 8*$d, 0
  rom_release: .fill 8, 0
  rom_github: .fill 8*8, 0
  rom_file_github: .fill 8*8, 0
  rom_file_release: .fill 8, 0
  TEXT_PROGRESS_FLASHING: .text "Flashing ... (-) equal, (+) flashed, (!) error."
  .byte 0
  __3: .text "None"
  .byte 0
  __4: .text "Skip"
  .byte 0
  __5: .text "Detected"
  .byte 0
  __6: .text "Checking"
  .byte 0
  __7: .text "Reading"
  .byte 0
  __8: .text "Comparing"
  .byte 0
  __9: .text "Update"
  .byte 0
  __10: .text "Updating"
  .byte 0
  __11: .text "Updated"
  .byte 0
  __12: .text "Issue"
  .byte 0
  __13: .text "Error"
  .byte 0
  __14: .text "Waiting"
  .byte 0
  __15: .text "Welcome to the CX16 update tool! This program updates the"
  .byte 0
  __16: .text "chipsets on your CX16 and ROM expansion boards."
  .byte 0
  __17: .text ""
  .byte 0
  __18: .text "Depending on the files found on the SDCard, various"
  .byte 0
  __19: .text "components will be updated:"
  .byte 0
  __20: .text "- Mandatory: SMC.BIN for the SMC firmware."
  .byte 0
  __21: .text "- Mandatory: ROM.BIN for the main ROM."
  .byte 0
  __22: .text "- Optional: VERA.BIN for the VERA firmware."
  .byte 0
  __23: .text "- Optional: ROMn.BIN for a ROM expansion board or cartridge."
  .byte 0
  __24: .text ""
  .byte 0
  __25: .text "  Important: Ensure J1 write-enable jumper is closed"
  .byte 0
  __26: .text "  on both the main board and any ROM expansion board."
  .byte 0
  __27: .text ""
  .byte 0
  __28: .text "Please carefully read the step-by-step instructions at "
  .byte 0
  __29: .text "https://flightcontrol-user.github.io/x16-flash"
  .byte 0
  __30: .text "The panels above indicate the update progress,"
  .byte 0
  __31: .text "using status indicators and colors as specified below:"
  .byte 0
  __32: .text ""
  .byte 0
  __33: .text " -   None       Not detected, no action."
  .byte 0
  __34: .text " -   Skipped    Detected, but no action, eg. no file."
  .byte 0
  __35: .text " -   Detected   Detected, verification pending."
  .byte 0
  __36: .text " -   Checking   Verifying size of the update file."
  .byte 0
  __37: .text " -   Reading    Reading the update file into RAM."
  .byte 0
  __38: .text " -   Comparing  Comparing the RAM with the ROM."
  .byte 0
  __39: .text " -   Update     Ready to update the firmware."
  .byte 0
  __40: .text " -   Updating   Updating the firmware."
  .byte 0
  __41: .text " -   Updated    Updated the firmware succesfully."
  .byte 0
  __42: .text " -   Issue      Problem identified during update."
  .byte 0
  __43: .text " -   Error      Error found during update."
  .byte 0
  __44: .text ""
  .byte 0
  __45: .text "Errors can indicate J1 jumpers are not closed!"
  .byte 0
  __46: .text "The following steps are IMPORTANT to update the VERA:"
  .byte 0
  __47: .text ""
  .byte 0
  __48: .text "1. In the next step you will be asked to close the JP1 jumper"
  .byte 0
  __49: .text "   pins on the VERA board."
  .byte 0
  __50: .text "   The closure of the JP1 jumper pins is required"
  .byte 0
  __51: .text "   to allow the program to access VERA flash memory"
  .byte 0
  __52: .text "   instead of the SDCard!"
  .byte 0
  __53: .text ""
  .byte 0
  __54: .text "2. Once the VERA has been updated, you will be asked to open"
  .byte 0
  __55: .text "   the JP1 jumper pins!"
  .byte 0
  __56: .text ""
  .byte 0
  __57: .text "Reminder:"
  .byte 0
  __58: .text " - DON'T CLOSE THE JP1 JUMPER PINS BEFORE BEING ASKED!"
  .byte 0
  __59: .text " - DON'T OPEN THE JP1 JUMPER PINS WHILE VERA IS BEING UPDATED!"
  .byte 0
  __60: .text ""
  .byte 0
  __61: .text "The program continues once the JP1 pins are opened/closed."
  .byte 0
  __62: .text "There is an issue with the CX16 SMC or ROM flash readiness."
  .byte 0
  __63: .text ""
  .byte 0
  __64: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __65: .text "to avoid possible conflicts of firmware, bricking your CX16."
  .byte 0
  __66: .text ""
  .byte 0
  __67: .text "Therefore, ensure you have the correct SMC.BIN and ROM.BIN"
  .byte 0
  __68: .text "files placed on your SDcard. Also ensure that the"
  .byte 0
  __69: .text "J1 jumper pins on the CX16 board are closed."
  .byte 0
  __70: .text "There is an issue with the CX16 SMC or ROM flash versions."
  .byte 0
  __71: .text ""
  .byte 0
  __72: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __73: .text "to avoid possible conflicts, risking bricking your CX16."
  .byte 0
  __74: .text ""
  .byte 0
  __75: .text "The SMC.BIN and ROM.BIN found on your SDCard may not be"
  .byte 0
  __76: .text "mutually compatible. Update the CX16 at your own risk!"
  .byte 0
  __77: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __78: .text ""
  .byte 0
  __79: .text "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!"
  .byte 0
  __80: .text ""
  .byte 0
  __81: .text "Because your SMC chipset has been updated,"
  .byte 0
  __82: .text "the restart process differs, depending on the"
  .byte 0
  __83: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __84: .text ""
  .byte 0
  __85: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __86: .text ""
  .byte 0
  __87: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __88: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __89: .text "  The power-off button won't work!"
  .byte 0
  __90: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __91: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __92: .text ""
  .byte 0
  __93: .text ""
  .byte 0
  __94: .text ""
  .byte 0
  __95: .text "Since your CX16 system SMC chip has not been updated"
  .byte 0
  __96: .text "your CX16 will just reset automatically after count down."
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
  spi_manufacturer: .byte 0
  spi_memory_type: .byte 0
  spi_memory_capacity: .byte 0
  vera_file_size: .dword 0
  status_vera: .byte 0
  // Globals
  status_smc: .byte 0
