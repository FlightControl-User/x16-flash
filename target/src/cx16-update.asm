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
  // Commander X16 PRG executable file
.file [name="cx16-update.prg", type="prg", segments="Program"]
.segmentdef Program [segments="Basic, Code, Data"]
.segmentdef Basic [start=$0801]
.segmentdef Code [start=$80d]
.segmentdef Data [startAfter="Code"]
.segment Basic
:BasicUpstart(__start)

  // Global Constants & labels
  // Some addressing constants.
  // These pre-processor directives allow to disable specific ROM flashing functions (for emulator development purposes).
  // Normally they should be all activated.
  // #define __FLASH
  // #define __SMC_CHIP_PROCESS
  // #define __ROM_CHIP_PROCESS
  // #define __SMC_CHIP_DETECT
  // #define __ROM_CHIP_DETECT
  // #define __SMC_CHIP_CHECK
  // #define __ROM_CHIP_CHECK
  // #define __SMC_CHIP_FLASH
  // #define __ROM_CHIP_FLASH
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
  ///< Read a character from the current channel for input.
  .const CBM_GETIN = $ffe4
  ///< Close a logical file.
  .const CBM_CLRCHN = $ffcc
  ///< Load a logical file.
  .const CBM_PLOT = $fff0
  .const CX16_SCREEN_MODE = $ff5f
  ///< CX16 Set/Get screen mode.
  .const CX16_SCREEN_SET_CHARSET = $ff62
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
  .const STATUS_FLASH = 6
  .const STATUS_FLASHED = 8
  .const STATUS_ISSUE = 9
  .const STATUS_ERROR = $a
  /**
 * @file cx16-display-text.h
 * @author your name (you@domain.com)
 * @brief 
 * @version 0.1
 * @date 2023-10-05
 * 
 * @copyright Copyright (c) 2023
 * 
 */
  .const display_intro_briefing_count = $f
  .const display_intro_colors_count = $10
  .const display_smc_rom_issue_count = 8
  .const display_smc_unsupported_rom_count = 7
  .const display_debriefing_count_smc = $e
  .const display_debriefing_count_rom = 4
  .const OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS = 1
  // Globals (to save zeropage and code overhead with parameter passing.)
  .const smc_bootloader = 0
  .const STACK_BASE = $103
  .const SIZEOF_STRUCT___1 = $8f
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
  .label __snprintf_buffer = $b9
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
    .label conio_x16_init__4 = $bf
    .label conio_x16_init__5 = $55
    .label conio_x16_init__6 = $c1
    .label conio_x16_init__7 = $c3
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [417] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [422] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [435] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label cputc__2 = $33
    .label cputc__3 = $34
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
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 4
    .const bank_set_brom3_bank = 0
    .const bank_set_brom4_bank = 4
    .const bank_set_bram2_bank = 0
    .label main__40 = $56
    .label main__57 = $7a
    .label main__66 = $b1
    .label main__77 = $b8
    .label main__80 = $b0
    .label main__120 = $6b
    .label main__125 = $37
    .label main__137 = $b1
    .label main__142 = $b1
    .label check_status_smc1_main__0 = $5f
    .label check_status_cx16_rom1_check_status_rom1_main__0 = $6d
    .label check_status_smc2_main__0 = $65
    .label check_status_cx16_rom2_check_status_rom1_main__0 = $6a
    .label check_status_smc3_main__0 = $69
    .label check_status_cx16_rom3_check_status_rom1_main__0 = $ae
    .label check_status_smc4_main__0 = $af
    .label check_status_cx16_rom4_check_status_rom1_main__0 = $79
    .label check_status_smc5_main__0 = $42
    .label check_status_smc6_main__0 = $41
    .label check_status_vera1_main__0 = $68
    .label check_status_smc7_main__0 = $50
    .label check_status_vera2_main__0 = $5a
    .label check_status_smc8_main__0 = $3f
    .label check_status_smc9_main__0 = $3e
    .label check_status_vera3_main__0 = $5c
    .label check_status_vera4_main__0 = $7f
    .label check_status_smc10_main__0 = $60
    .label check_status_cx16_rom5_check_status_rom1_main__0 = $5b
    .label check_status_smc11_main__0 = $ab
    .label check_status_vera5_main__0 = $7e
    .label check_status_smc12_main__0 = $6f
    .label check_status_vera6_main__0 = $70
    .label check_status_smc13_main__0 = $51
    .label rom_chip = $b4
    .label intro_status = $b2
    .label check_status_smc1_return = $5f
    .label check_status_cx16_rom1_check_status_rom1_return = $6d
    .label check_status_smc2_return = $65
    .label check_status_cx16_rom2_check_status_rom1_return = $6a
    .label check_status_smc3_return = $69
    .label check_status_cx16_rom3_check_status_rom1_return = $ae
    .label check_status_smc4_return = $af
    .label check_status_cx16_rom4_check_status_rom1_return = $79
    .label check_status_smc5_return = $42
    .label ch = $be
    .label check_status_smc6_return = $41
    .label check_status_vera1_return = $68
    .label check_status_smc7_return = $50
    .label check_status_vera2_return = $5a
    .label check_status_smc8_return = $3f
    .label check_status_smc9_return = $3e
    .label check_status_vera3_return = $5c
    .label check_status_vera4_return = $7f
    .label check_status_smc10_return = $60
    .label check_status_cx16_rom5_check_status_rom1_return = $5b
    .label ch1 = $aa
    .label rom_chip1 = $b3
    .label check_status_smc11_return = $ab
    .label check_status_vera5_return = $7e
    .label check_status_smc12_return = $6f
    .label check_status_vera6_return = $70
    .label check_status_smc13_return = $51
    .label w = $b7
    .label w1 = $b6
    .label main__212 = $b0
    .label main__213 = $b0
    .label main__214 = $b0
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::bank_set_bram1
    // BRAM = bank
    // [72] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::bank_set_brom1
    // BROM = bank
    // [73] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [74] phi from main::bank_set_brom1 to main::@28 [phi:main::bank_set_brom1->main::@28]
    // main::@28
    // display_frame_init_64()
    // [75] call display_frame_init_64
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
    // [76] phi from main::@28 to main::@48 [phi:main::@28->main::@48]
    // main::@48
    // display_frame_draw()
    // [77] call display_frame_draw
  // ST1 | Reset canvas to 64 columns
    // [484] phi from main::@48 to display_frame_draw [phi:main::@48->display_frame_draw]
    jsr display_frame_draw
    // [78] phi from main::@48 to main::@49 [phi:main::@48->main::@49]
    // main::@49
    // display_frame_title("Commander X16 Update Utility (v2.2.0).")
    // [79] call display_frame_title
    // [525] phi from main::@49 to display_frame_title [phi:main::@49->display_frame_title]
    jsr display_frame_title
    // [80] phi from main::@49 to main::display_info_title1 [phi:main::@49->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [81] call cputsxy
    // [530] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [530] phi cputsxy::s#3 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [530] phi cputsxy::y#3 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [530] phi cputsxy::x#3 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [82] phi from main::display_info_title1 to main::@50 [phi:main::display_info_title1->main::@50]
    // main::@50
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [83] call cputsxy
    // [530] phi from main::@50 to cputsxy [phi:main::@50->cputsxy]
    // [530] phi cputsxy::s#3 = main::s1 [phi:main::@50->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [530] phi cputsxy::y#3 = $11-1 [phi:main::@50->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [530] phi cputsxy::x#3 = 4-2 [phi:main::@50->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [84] phi from main::@50 to main::@29 [phi:main::@50->main::@29]
    // main::@29
    // display_action_progress("Introduction, please read carefully the below!")
    // [85] call display_action_progress
    // [537] phi from main::@29 to display_action_progress [phi:main::@29->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text [phi:main::@29->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [86] phi from main::@29 to main::@51 [phi:main::@29->main::@51]
    // main::@51
    // display_progress_clear()
    // [87] call display_progress_clear
    // [551] phi from main::@51 to display_progress_clear [phi:main::@51->display_progress_clear]
    jsr display_progress_clear
    // [88] phi from main::@51 to main::@52 [phi:main::@51->main::@52]
    // main::@52
    // display_chip_smc()
    // [89] call display_chip_smc
    // [566] phi from main::@52 to display_chip_smc [phi:main::@52->display_chip_smc]
    jsr display_chip_smc
    // [90] phi from main::@52 to main::@53 [phi:main::@52->main::@53]
    // main::@53
    // display_chip_vera()
    // [91] call display_chip_vera
    // [571] phi from main::@53 to display_chip_vera [phi:main::@53->display_chip_vera]
    jsr display_chip_vera
    // [92] phi from main::@53 to main::@54 [phi:main::@53->main::@54]
    // main::@54
    // display_chip_rom()
    // [93] call display_chip_rom
    // [576] phi from main::@54 to display_chip_rom [phi:main::@54->display_chip_rom]
    jsr display_chip_rom
    // [94] phi from main::@54 to main::@55 [phi:main::@54->main::@55]
    // main::@55
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [95] call display_info_smc
    // [595] phi from main::@55 to display_info_smc [phi:main::@55->display_info_smc]
    // [595] phi display_info_smc::info_text#10 = 0 [phi:main::@55->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [595] phi display_info_smc::info_status#10 = BLACK [phi:main::@55->display_info_smc#1] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [96] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
    // display_info_vera(STATUS_NONE, NULL)
    // [97] call display_info_vera
    // [629] phi from main::@56 to display_info_vera [phi:main::@56->display_info_vera]
    // [629] phi display_info_vera::info_text#10 = 0 [phi:main::@56->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [629] phi spi_memory_capacity#12 = 0 [phi:main::@56->display_info_vera#1] -- vbum1=vbuc1 
    sta spi_memory_capacity
    // [629] phi spi_memory_type#12 = 0 [phi:main::@56->display_info_vera#2] -- vbum1=vbuc1 
    sta spi_memory_type
    // [629] phi spi_manufacturer#12 = 0 [phi:main::@56->display_info_vera#3] -- vbum1=vbuc1 
    sta spi_manufacturer
    // [629] phi display_info_vera::info_status#4 = STATUS_NONE [phi:main::@56->display_info_vera#4] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [98] phi from main::@56 to main::@10 [phi:main::@56->main::@10]
    // [98] phi main::rom_chip#2 = 0 [phi:main::@56->main::@10#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // main::@10
  __b10:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [99] if(main::rom_chip#2<8) goto main::@11 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcs !__b11+
    jmp __b11
  !__b11:
    // main::bank_set_brom2
    // BROM = bank
    // [100] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [102] phi from main::CLI1 to main::@30 [phi:main::CLI1->main::@30]
    // main::@30
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [103] call display_progress_text
    // [663] phi from main::@30 to display_progress_text [phi:main::@30->display_progress_text]
    // [663] phi display_progress_text::text#10 = display_into_briefing_text [phi:main::@30->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [663] phi display_progress_text::lines#11 = display_intro_briefing_count [phi:main::@30->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [104] phi from main::@30 to main::@59 [phi:main::@30->main::@59]
    // main::@59
    // util_wait_space()
    // [105] call util_wait_space
    // [673] phi from main::@59 to util_wait_space [phi:main::@59->util_wait_space]
    jsr util_wait_space
    // [106] phi from main::@59 to main::@60 [phi:main::@59->main::@60]
    // main::@60
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [107] call display_progress_text
    // [663] phi from main::@60 to display_progress_text [phi:main::@60->display_progress_text]
    // [663] phi display_progress_text::text#10 = display_into_colors_text [phi:main::@60->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [663] phi display_progress_text::lines#11 = display_intro_colors_count [phi:main::@60->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [108] phi from main::@60 to main::@12 [phi:main::@60->main::@12]
    // [108] phi main::intro_status#2 = 0 [phi:main::@60->main::@12#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_status
    // main::@12
  __b12:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [109] if(main::intro_status#2<$b) goto main::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_status
    cmp #$b
    bcs !__b13+
    jmp __b13
  !__b13:
    // [110] phi from main::@12 to main::@14 [phi:main::@12->main::@14]
    // main::@14
    // util_wait_space()
    // [111] call util_wait_space
    // [673] phi from main::@14 to util_wait_space [phi:main::@14->util_wait_space]
    jsr util_wait_space
    // [112] phi from main::@14 to main::@62 [phi:main::@14->main::@62]
    // main::@62
    // display_progress_clear()
    // [113] call display_progress_clear
    // [551] phi from main::@62 to display_progress_clear [phi:main::@62->display_progress_clear]
    jsr display_progress_clear
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom3
    // BROM = bank
    // [115] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // [116] phi from main::bank_set_brom3 to main::@31 [phi:main::bank_set_brom3->main::@31]
    // main::@31
    // vera_detect()
    // [117] call vera_detect
  // Detecting VERA FPGA.
    // [676] phi from main::@31 to vera_detect [phi:main::@31->vera_detect]
    jsr vera_detect
    // [118] phi from main::@31 to main::@63 [phi:main::@31->main::@63]
    // main::@63
    // display_chip_vera()
    // [119] call display_chip_vera
    // [571] phi from main::@63 to display_chip_vera [phi:main::@63->display_chip_vera]
    jsr display_chip_vera
    // main::@64
    // [120] spi_manufacturer#281 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [121] spi_memory_type#281 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [122] spi_memory_capacity#281 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [123] call display_info_vera
    // [629] phi from main::@64 to display_info_vera [phi:main::@64->display_info_vera]
    // [629] phi display_info_vera::info_text#10 = main::info_text1 [phi:main::@64->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [629] phi spi_memory_capacity#12 = spi_memory_capacity#281 [phi:main::@64->display_info_vera#1] -- register_copy 
    // [629] phi spi_memory_type#12 = spi_memory_type#281 [phi:main::@64->display_info_vera#2] -- register_copy 
    // [629] phi spi_manufacturer#12 = spi_manufacturer#281 [phi:main::@64->display_info_vera#3] -- register_copy 
    // [629] phi display_info_vera::info_status#4 = STATUS_DETECTED [phi:main::@64->display_info_vera#4] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // main::@65
    // [124] spi_manufacturer#282 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [125] spi_memory_type#282 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [126] spi_memory_capacity#282 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "VERA not yet supported")
    // [127] call display_info_vera
  // Set the info for the VERA to Detected.
    // [629] phi from main::@65 to display_info_vera [phi:main::@65->display_info_vera]
    // [629] phi display_info_vera::info_text#10 = main::info_text2 [phi:main::@65->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_vera.info_text
    lda #>info_text2
    sta.z display_info_vera.info_text+1
    // [629] phi spi_memory_capacity#12 = spi_memory_capacity#282 [phi:main::@65->display_info_vera#1] -- register_copy 
    // [629] phi spi_memory_type#12 = spi_memory_type#282 [phi:main::@65->display_info_vera#2] -- register_copy 
    // [629] phi spi_manufacturer#12 = spi_manufacturer#282 [phi:main::@65->display_info_vera#3] -- register_copy 
    // [629] phi display_info_vera::info_status#4 = STATUS_SKIP [phi:main::@65->display_info_vera#4] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // main::bank_set_brom4
    // BROM = bank
    // [128] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc1
    // status_smc == status
    // [130] main::check_status_smc1_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [131] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // [132] phi from main::check_status_smc1 to main::check_status_cx16_rom1 [phi:main::check_status_smc1->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [133] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [134] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0
    // main::@32
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [135] if(0!=main::check_status_smc1_return#0) goto main::check_status_smc2 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc1_return
    bne check_status_smc2
    // main::@117
    // [136] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@15 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom1_check_status_rom1_return
    beq !__b15+
    jmp __b15
  !__b15:
    // main::check_status_smc2
  check_status_smc2:
    // status_smc == status
    // [137] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [138] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0
    // [139] phi from main::check_status_smc2 to main::check_status_cx16_rom2 [phi:main::check_status_smc2->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [140] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_NONE -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [141] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0
    // main::@33
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [142] if(0==main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_eq_vbuz1_then_la1 
    // VA3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
    lda.z check_status_smc2_return
    beq check_status_smc3
    // main::@118
    // [143] if(0!=main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@1 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom2_check_status_rom1_return
    beq !__b1+
    jmp __b1
  !__b1:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [144] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [145] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0
    // [146] phi from main::check_status_smc3 to main::check_status_cx16_rom3 [phi:main::check_status_smc3->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [147] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [148] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0
    // main::@34
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [149] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc3_return
    beq check_status_smc4
    // main::@119
    // [150] if(0==main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@3 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom3_check_status_rom1_return
    bne !__b3+
    jmp __b3
  !__b3:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [151] main::check_status_smc4_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [152] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0
    // [153] phi from main::check_status_smc4 to main::check_status_cx16_rom4 [phi:main::check_status_smc4->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [154] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [155] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0
    // main::@35
    // smc_supported_rom(rom_release[0])
    // [156] smc_supported_rom::rom_release#0 = *rom_release -- vbuz1=_deref_pbuc1 
    lda rom_release
    sta.z smc_supported_rom.rom_release
    // [157] call smc_supported_rom
    // [679] phi from main::@35 to smc_supported_rom [phi:main::@35->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_release[0])
    // [158] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@78
    // [159] main::$40 = smc_supported_rom::return#3
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_release[0]))
    // [160] if(0==main::check_status_smc4_return#0) goto main::check_status_smc5 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc4_return
    beq check_status_smc5
    // main::@121
    // [161] if(0==main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::check_status_smc5 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom4_check_status_rom1_return
    beq check_status_smc5
    // main::@120
    // [162] if(0==main::$40) goto main::@4 -- 0_eq_vbuz1_then_la1 
    lda.z main__40
    bne !__b4+
    jmp __b4
  !__b4:
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [163] main::check_status_smc5_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [164] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0
    // main::@36
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [165] if(0!=main::check_status_smc5_return#0) goto main::@6 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc5_return
    beq !__b6+
    jmp __b6
  !__b6:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [166] main::check_status_smc6_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [167] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0
    // main::check_status_vera1
    // status_vera == status
    // [168] main::check_status_vera1_$0 = status_vera#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [169] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0
    // [170] phi from main::check_status_vera1 to main::@37 [phi:main::check_status_vera1->main::@37]
    // main::@37
    // check_status_roms(STATUS_ISSUE)
    // [171] call check_status_roms
    // [686] phi from main::@37 to check_status_roms [phi:main::@37->check_status_roms]
    // [686] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@37->check_status_roms#0] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [172] check_status_roms::return#3 = check_status_roms::return#2
    // main::@83
    // [173] main::$57 = check_status_roms::return#3 -- vbuz1=vbuz2 
    lda.z check_status_roms.return
    sta.z main__57
    // main::check_status_smc7
    // status_smc == status
    // [174] main::check_status_smc7_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [175] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0
    // main::check_status_vera2
    // status_vera == status
    // [176] main::check_status_vera2_$0 = status_vera#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [177] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0
    // [178] phi from main::check_status_vera2 to main::@38 [phi:main::check_status_vera2->main::@38]
    // main::@38
    // check_status_roms(STATUS_ERROR)
    // [179] call check_status_roms
    // [686] phi from main::@38 to check_status_roms [phi:main::@38->check_status_roms]
    // [686] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@38->check_status_roms#0] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [180] check_status_roms::return#4 = check_status_roms::return#2
    // main::@84
    // [181] main::$66 = check_status_roms::return#4
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [182] if(0!=main::check_status_smc6_return#0) goto main::check_status_smc8 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc6_return
    bne check_status_smc8
    // main::@126
    // [183] if(0==main::check_status_vera1_return#0) goto main::@125 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera1_return
    bne !__b125+
    jmp __b125
  !__b125:
    // main::check_status_smc8
  check_status_smc8:
    // status_smc == status
    // [184] main::check_status_smc8_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [185] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0
    // main::check_status_smc9
    // status_smc == status
    // [186] main::check_status_smc9_$0 = status_smc#0 == STATUS_NONE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [187] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0
    // main::check_status_vera3
    // status_vera == status
    // [188] main::check_status_vera3_$0 = status_vera#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [189] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0
    // main::check_status_vera4
    // status_vera == status
    // [190] main::check_status_vera4_$0 = status_vera#0 == STATUS_NONE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera4_main__0
    // return (unsigned char)(status_vera == status);
    // [191] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0
    // [192] phi from main::check_status_vera4 to main::@39 [phi:main::check_status_vera4->main::@39]
    // main::@39
    // check_status_roms_less(STATUS_SKIP)
    // [193] call check_status_roms_less
    // [695] phi from main::@39 to check_status_roms_less [phi:main::@39->check_status_roms_less]
    jsr check_status_roms_less
    // check_status_roms_less(STATUS_SKIP)
    // [194] check_status_roms_less::return#3 = check_status_roms_less::return#2
    // main::@87
    // [195] main::$77 = check_status_roms_less::return#3
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        check_status_roms_less(STATUS_SKIP))
    // [196] if(0!=main::check_status_smc8_return#0) goto main::@128 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc8_return
    beq !__b128+
    jmp __b128
  !__b128:
    // main::@129
    // [197] if(0!=main::check_status_smc9_return#0) goto main::@128 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc9_return
    beq !__b128+
    jmp __b128
  !__b128:
    // main::check_status_smc11
  check_status_smc11:
    // status_smc == status
    // [198] main::check_status_smc11_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc11_main__0
    // return (unsigned char)(status_smc == status);
    // [199] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0
    // main::check_status_vera5
    // status_vera == status
    // [200] main::check_status_vera5_$0 = status_vera#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera5_main__0
    // return (unsigned char)(status_vera == status);
    // [201] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0
    // [202] phi from main::check_status_vera5 to main::@42 [phi:main::check_status_vera5->main::@42]
    // main::@42
    // check_status_roms(STATUS_ERROR)
    // [203] call check_status_roms
    // [686] phi from main::@42 to check_status_roms [phi:main::@42->check_status_roms]
    // [686] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@42->check_status_roms#0] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [204] check_status_roms::return#10 = check_status_roms::return#2
    // main::@94
    // [205] main::$137 = check_status_roms::return#10
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [206] if(0!=main::check_status_smc11_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc11_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@133
    // [207] if(0!=main::check_status_vera5_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera5_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@132
    // [208] if(0!=main::$137) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z main__137
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_status_smc12
    // status_smc == status
    // [209] main::check_status_smc12_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc12_main__0
    // return (unsigned char)(status_smc == status);
    // [210] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0
    // main::check_status_vera6
    // status_vera == status
    // [211] main::check_status_vera6_$0 = status_vera#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera6_main__0
    // return (unsigned char)(status_vera == status);
    // [212] main::check_status_vera6_return#0 = (char)main::check_status_vera6_$0
    // [213] phi from main::check_status_vera6 to main::@44 [phi:main::check_status_vera6->main::@44]
    // main::@44
    // check_status_roms(STATUS_ISSUE)
    // [214] call check_status_roms
    // [686] phi from main::@44 to check_status_roms [phi:main::@44->check_status_roms]
    // [686] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@44->check_status_roms#0] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [215] check_status_roms::return#11 = check_status_roms::return#2
    // main::@96
    // [216] main::$142 = check_status_roms::return#11
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [217] if(0!=main::check_status_smc12_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc12_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@135
    // [218] if(0!=main::check_status_vera6_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera6_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@134
    // [219] if(0!=main::$142) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z main__142
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [220] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [221] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [222] phi from main::vera_display_set_border_color4 to main::@46 [phi:main::vera_display_set_border_color4->main::@46]
    // main::@46
    // display_action_progress("Your CX16 update is a success!")
    // [223] call display_action_progress
    // [537] phi from main::@46 to display_action_progress [phi:main::@46->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text24 [phi:main::@46->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_action_progress.info_text
    lda #>info_text24
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc13
    // status_smc == status
    // [224] main::check_status_smc13_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc13_main__0
    // return (unsigned char)(status_smc == status);
    // [225] main::check_status_smc13_return#0 = (char)main::check_status_smc13_$0
    // main::@47
    // if(check_status_smc(STATUS_FLASHED))
    // [226] if(0!=main::check_status_smc13_return#0) goto main::@19 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc13_return
    beq !__b19+
    jmp __b19
  !__b19:
    // [227] phi from main::@47 to main::@9 [phi:main::@47->main::@9]
    // main::@9
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [228] call display_progress_text
    // [663] phi from main::@9 to display_progress_text [phi:main::@9->display_progress_text]
    // [663] phi display_progress_text::text#10 = display_debriefing_text_rom [phi:main::@9->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [663] phi display_progress_text::lines#11 = display_debriefing_count_rom [phi:main::@9->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [229] phi from main::@41 main::@45 main::@9 to main::@2 [phi:main::@41/main::@45/main::@9->main::@2]
    // main::@2
  __b2:
    // textcolor(PINK)
    // [230] call textcolor
  // DE6 | Wait until reset
    // [417] phi from main::@2 to textcolor [phi:main::@2->textcolor]
    // [417] phi textcolor::color#20 = PINK [phi:main::@2->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [231] phi from main::@2 to main::@109 [phi:main::@2->main::@109]
    // main::@109
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [232] call display_progress_line
    // [704] phi from main::@109 to display_progress_line [phi:main::@109->display_progress_line]
    // [704] phi display_progress_line::text#3 = main::text [phi:main::@109->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [704] phi display_progress_line::line#3 = 2 [phi:main::@109->display_progress_line#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_progress_line.line
    jsr display_progress_line
    // [233] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // textcolor(WHITE)
    // [234] call textcolor
    // [417] phi from main::@110 to textcolor [phi:main::@110->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:main::@110->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [235] phi from main::@110 to main::@25 [phi:main::@110->main::@25]
    // [235] phi main::w1#2 = $78 [phi:main::@110->main::@25#0] -- vbuz1=vbuc1 
    lda #$78
    sta.z w1
    // main::@25
  __b25:
    // for (unsigned char w=120; w>0; w--)
    // [236] if(main::w1#2>0) goto main::@26 -- vbuz1_gt_0_then_la1 
    lda.z w1
    bne __b26
    // [237] phi from main::@25 to main::@27 [phi:main::@25->main::@27]
    // main::@27
    // system_reset()
    // [238] call system_reset
    // [709] phi from main::@27 to system_reset [phi:main::@27->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [239] return 
    rts
    // [240] phi from main::@25 to main::@26 [phi:main::@25->main::@26]
    // main::@26
  __b26:
    // wait_moment()
    // [241] call wait_moment
    // [714] phi from main::@26 to wait_moment [phi:main::@26->wait_moment]
    jsr wait_moment
    // [242] phi from main::@26 to main::@111 [phi:main::@26->main::@111]
    // main::@111
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [243] call snprintf_init
    jsr snprintf_init
    // [244] phi from main::@111 to main::@112 [phi:main::@111->main::@112]
    // main::@112
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [245] call printf_str
    // [723] phi from main::@112 to printf_str [phi:main::@112->printf_str]
    // [723] phi printf_str::putc#21 = &snputc [phi:main::@112->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = main::s5 [phi:main::@112->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@113
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [246] printf_uchar::uvalue#5 = main::w1#2 -- vbum1=vbuz2 
    lda.z w1
    sta printf_uchar.uvalue
    // [247] call printf_uchar
    // [732] phi from main::@113 to printf_uchar [phi:main::@113->printf_uchar]
    // [732] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@113->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [732] phi printf_uchar::format_min_length#10 = 0 [phi:main::@113->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [732] phi printf_uchar::putc#10 = &snputc [phi:main::@113->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [732] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@113->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [732] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#5 [phi:main::@113->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [248] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [249] call printf_str
    // [723] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [723] phi printf_str::putc#21 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = main::s6 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [250] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [251] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [253] call display_action_text
    // [743] phi from main::@115 to display_action_text [phi:main::@115->display_action_text]
    // [743] phi display_action_text::info_text#6 = info_text [phi:main::@115->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@116
    // for (unsigned char w=120; w>0; w--)
    // [254] main::w1#1 = -- main::w1#2 -- vbuz1=_dec_vbuz1 
    dec.z w1
    // [235] phi from main::@116 to main::@25 [phi:main::@116->main::@25]
    // [235] phi main::w1#2 = main::w1#1 [phi:main::@116->main::@25#0] -- register_copy 
    jmp __b25
    // [255] phi from main::@47 to main::@19 [phi:main::@47->main::@19]
    // main::@19
  __b19:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [256] call display_progress_text
    // [663] phi from main::@19 to display_progress_text [phi:main::@19->display_progress_text]
    // [663] phi display_progress_text::text#10 = display_debriefing_text_smc [phi:main::@19->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [663] phi display_progress_text::lines#11 = display_debriefing_count_smc [phi:main::@19->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_smc
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [257] phi from main::@19 to main::@97 [phi:main::@19->main::@97]
    // main::@97
    // textcolor(PINK)
    // [258] call textcolor
    // [417] phi from main::@97 to textcolor [phi:main::@97->textcolor]
    // [417] phi textcolor::color#20 = PINK [phi:main::@97->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [259] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [260] call display_progress_line
    // [704] phi from main::@98 to display_progress_line [phi:main::@98->display_progress_line]
    // [704] phi display_progress_line::text#3 = main::text [phi:main::@98->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [704] phi display_progress_line::line#3 = 2 [phi:main::@98->display_progress_line#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_progress_line.line
    jsr display_progress_line
    // [261] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // textcolor(WHITE)
    // [262] call textcolor
    // [417] phi from main::@99 to textcolor [phi:main::@99->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:main::@99->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [263] phi from main::@99 to main::@20 [phi:main::@99->main::@20]
    // [263] phi main::w#2 = $78 [phi:main::@99->main::@20#0] -- vbuz1=vbuc1 
    lda #$78
    sta.z w
    // main::@20
  __b20:
    // for (unsigned char w=120; w>0; w--)
    // [264] if(main::w#2>0) goto main::@21 -- vbuz1_gt_0_then_la1 
    lda.z w
    bne __b21
    // [265] phi from main::@20 to main::@22 [phi:main::@20->main::@22]
    // main::@22
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [266] call snprintf_init
    jsr snprintf_init
    // [267] phi from main::@22 to main::@106 [phi:main::@22->main::@106]
    // main::@106
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [268] call printf_str
    // [723] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [723] phi printf_str::putc#21 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = main::s4 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [269] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [270] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [272] call display_action_text
    // [743] phi from main::@107 to display_action_text [phi:main::@107->display_action_text]
    // [743] phi display_action_text::info_text#6 = info_text [phi:main::@107->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [273] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // smc_reset()
    // [274] call smc_reset
  // DE5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [757] phi from main::@108 to smc_reset [phi:main::@108->smc_reset]
    jsr smc_reset
    // [275] phi from main::@108 main::@23 to main::@23 [phi:main::@108/main::@23->main::@23]
  __b5:
  // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
    // main::@23
    jmp __b5
    // [276] phi from main::@20 to main::@21 [phi:main::@20->main::@21]
    // main::@21
  __b21:
    // wait_moment()
    // [277] call wait_moment
    // [714] phi from main::@21 to wait_moment [phi:main::@21->wait_moment]
    jsr wait_moment
    // [278] phi from main::@21 to main::@100 [phi:main::@21->main::@100]
    // main::@100
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [279] call snprintf_init
    jsr snprintf_init
    // [280] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [281] call printf_str
    // [723] phi from main::@101 to printf_str [phi:main::@101->printf_str]
    // [723] phi printf_str::putc#21 = &snputc [phi:main::@101->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = main::s2 [phi:main::@101->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@102
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [282] printf_uchar::uvalue#4 = main::w#2 -- vbum1=vbuz2 
    lda.z w
    sta printf_uchar.uvalue
    // [283] call printf_uchar
    // [732] phi from main::@102 to printf_uchar [phi:main::@102->printf_uchar]
    // [732] phi printf_uchar::format_zero_padding#10 = 1 [phi:main::@102->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [732] phi printf_uchar::format_min_length#10 = 3 [phi:main::@102->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [732] phi printf_uchar::putc#10 = &snputc [phi:main::@102->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [732] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@102->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [732] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#4 [phi:main::@102->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [284] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [285] call printf_str
    // [723] phi from main::@103 to printf_str [phi:main::@103->printf_str]
    // [723] phi printf_str::putc#21 = &snputc [phi:main::@103->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = main::s3 [phi:main::@103->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@104
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [286] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [287] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [289] call display_action_text
    // [743] phi from main::@104 to display_action_text [phi:main::@104->display_action_text]
    // [743] phi display_action_text::info_text#6 = info_text [phi:main::@104->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@105
    // for (unsigned char w=120; w>0; w--)
    // [290] main::w#1 = -- main::w#2 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [263] phi from main::@105 to main::@20 [phi:main::@105->main::@20]
    // [263] phi main::w#2 = main::w#1 [phi:main::@105->main::@20#0] -- register_copy 
    jmp __b20
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [291] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [292] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [293] phi from main::vera_display_set_border_color3 to main::@45 [phi:main::vera_display_set_border_color3->main::@45]
    // main::@45
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [294] call display_action_progress
    // [537] phi from main::@45 to display_action_progress [phi:main::@45->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text23 [phi:main::@45->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_action_progress.info_text
    lda #>info_text23
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b2
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [295] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [296] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [297] phi from main::vera_display_set_border_color2 to main::@43 [phi:main::vera_display_set_border_color2->main::@43]
    // main::@43
    // display_action_progress("Update Failure! Your CX16 may no longer boot!")
    // [298] call display_action_progress
    // [537] phi from main::@43 to display_action_progress [phi:main::@43->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text21 [phi:main::@43->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_action_progress.info_text
    lda #>info_text21
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [299] phi from main::@43 to main::@95 [phi:main::@43->main::@95]
    // main::@95
    // display_action_text("Take a photo of this screen, shut down power and retry!")
    // [300] call display_action_text
    // [743] phi from main::@95 to display_action_text [phi:main::@95->display_action_text]
    // [743] phi display_action_text::info_text#6 = main::info_text22 [phi:main::@95->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_text.info_text
    lda #>info_text22
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [301] phi from main::@24 main::@95 to main::@24 [phi:main::@24/main::@95->main::@24]
    // main::@24
  __b24:
    jmp __b24
    // main::@128
  __b128:
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        check_status_roms_less(STATUS_SKIP))
    // [302] if(0!=main::check_status_vera3_return#0) goto main::@127 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera3_return
    bne __b127
    // main::@136
    // [303] if(0==main::check_status_vera4_return#0) goto main::check_status_smc11 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera4_return
    bne !check_status_smc11+
    jmp check_status_smc11
  !check_status_smc11:
    // main::@127
  __b127:
    // [304] if(0!=main::$77) goto main::vera_display_set_border_color1 -- 0_neq_vbuz1_then_la1 
    lda.z main__77
    bne vera_display_set_border_color1
    jmp check_status_smc11
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [305] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [306] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [307] phi from main::vera_display_set_border_color1 to main::@41 [phi:main::vera_display_set_border_color1->main::@41]
    // main::@41
    // display_action_progress("No CX16 component has been updated with new firmware!")
    // [308] call display_action_progress
    // [537] phi from main::@41 to display_action_progress [phi:main::@41->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text20 [phi:main::@41->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_action_progress.info_text
    lda #>info_text20
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b2
    // main::@125
  __b125:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [309] if(0!=main::$57) goto main::check_status_smc8 -- 0_neq_vbuz1_then_la1 
    lda.z main__57
    beq !check_status_smc8+
    jmp check_status_smc8
  !check_status_smc8:
    // main::@124
    // [310] if(0==main::check_status_smc7_return#0) goto main::@123 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc7_return
    beq __b123
    jmp check_status_smc8
    // main::@123
  __b123:
    // [311] if(0!=main::check_status_vera2_return#0) goto main::check_status_smc8 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera2_return
    beq !check_status_smc8+
    jmp check_status_smc8
  !check_status_smc8:
    // main::@122
    // [312] if(0==main::$66) goto main::check_status_smc10 -- 0_eq_vbuz1_then_la1 
    lda.z main__66
    beq check_status_smc10
    jmp check_status_smc8
    // main::check_status_smc10
  check_status_smc10:
    // status_smc == status
    // [313] main::check_status_smc10_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [314] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0
    // [315] phi from main::check_status_smc10 to main::check_status_cx16_rom5 [phi:main::check_status_smc10->main::check_status_cx16_rom5]
    // main::check_status_cx16_rom5
    // main::check_status_cx16_rom5_check_status_rom1
    // status_rom[rom_chip] == status
    // [316] main::check_status_cx16_rom5_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom5_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [317] main::check_status_cx16_rom5_check_status_rom1_return#0 = (char)main::check_status_cx16_rom5_check_status_rom1_$0
    // [318] phi from main::check_status_cx16_rom5_check_status_rom1 to main::@40 [phi:main::check_status_cx16_rom5_check_status_rom1->main::@40]
    // main::@40
    // check_status_card_roms(STATUS_FLASH)
    // [319] call check_status_card_roms
    // [766] phi from main::@40 to check_status_card_roms [phi:main::@40->check_status_card_roms]
    jsr check_status_card_roms
    // check_status_card_roms(STATUS_FLASH)
    // [320] check_status_card_roms::return#3 = check_status_card_roms::return#2
    // main::@88
    // [321] main::$120 = check_status_card_roms::return#3
    // if(check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [322] if(0!=main::check_status_smc10_return#0) goto main::@7 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc10_return
    bne __b7
    // main::@131
    // [323] if(0!=main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::@7 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom5_check_status_rom1_return
    bne __b7
    // main::@130
    // [324] if(0!=main::$120) goto main::@7 -- 0_neq_vbuz1_then_la1 
    lda.z main__120
    bne __b7
    // main::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [325] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    jmp check_status_smc8
    // [327] phi from main::@130 main::@131 main::@88 to main::@7 [phi:main::@130/main::@131/main::@88->main::@7]
    // main::@7
  __b7:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [328] call display_action_progress
    // [537] phi from main::@7 to display_action_progress [phi:main::@7->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text14 [phi:main::@7->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_action_progress.info_text
    lda #>info_text14
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [329] phi from main::@7 to main::@89 [phi:main::@7->main::@89]
    // main::@89
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [330] call util_wait_key
    // [775] phi from main::@89 to util_wait_key [phi:main::@89->util_wait_key]
    // [775] phi util_wait_key::filter#13 = main::filter1 [phi:main::@89->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z util_wait_key.filter
    lda #>filter1
    sta.z util_wait_key.filter+1
    // [775] phi util_wait_key::info_text#3 = main::info_text15 [phi:main::@89->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z util_wait_key.info_text
    lda #>info_text15
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [331] util_wait_key::return#4 = util_wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z util_wait_key.ch
    sta.z util_wait_key.return_1
    // main::@90
    // [332] main::ch1#0 = util_wait_key::return#4
    // strchr("nN", ch)
    // [333] strchr::c#1 = main::ch1#0 -- vbum1=vbuz2 
    lda.z ch1
    sta strchr.c
    // [334] call strchr
    // [799] phi from main::@90 to strchr [phi:main::@90->strchr]
    // [799] phi strchr::c#4 = strchr::c#1 [phi:main::@90->strchr#0] -- register_copy 
    // [799] phi strchr::str#2 = (const void *)main::$190 [phi:main::@90->strchr#1] -- pvoz1=pvoc1 
    lda #<main__190
    sta.z strchr.str
    lda #>main__190
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [335] strchr::return#4 = strchr::return#2
    // main::@91
    // [336] main::$125 = strchr::return#4
    // if(strchr("nN", ch))
    // [337] if((void *)0==main::$125) goto main::bank_set_bram2 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__125
    cmp #<0
    bne !+
    lda.z main__125+1
    cmp #>0
    beq bank_set_bram2
  !:
    // [338] phi from main::@91 to main::@8 [phi:main::@91->main::@8]
    // main::@8
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [339] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [595] phi from main::@8 to display_info_smc [phi:main::@8->display_info_smc]
    // [595] phi display_info_smc::info_text#10 = main::info_text16 [phi:main::@8->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_info_smc.info_text
    lda #>info_text16
    sta.z display_info_smc.info_text+1
    // [595] phi display_info_smc::info_status#10 = STATUS_SKIP [phi:main::@8->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::@92
    // [340] spi_manufacturer#283 = spi_read::return#0 -- vbum1=vbum2 
    lda spi_read.return
    sta spi_manufacturer
    // [341] spi_memory_type#283 = spi_read::return#1 -- vbum1=vbum2 
    lda spi_read.return_1
    sta spi_memory_type
    // [342] spi_memory_capacity#283 = spi_read::return#2 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_memory_capacity
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [343] call display_info_vera
    // [629] phi from main::@92 to display_info_vera [phi:main::@92->display_info_vera]
    // [629] phi display_info_vera::info_text#10 = main::info_text16 [phi:main::@92->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_info_vera.info_text
    lda #>info_text16
    sta.z display_info_vera.info_text+1
    // [629] phi spi_memory_capacity#12 = spi_memory_capacity#283 [phi:main::@92->display_info_vera#1] -- register_copy 
    // [629] phi spi_memory_type#12 = spi_memory_type#283 [phi:main::@92->display_info_vera#2] -- register_copy 
    // [629] phi spi_manufacturer#12 = spi_manufacturer#283 [phi:main::@92->display_info_vera#3] -- register_copy 
    // [629] phi display_info_vera::info_status#4 = STATUS_SKIP [phi:main::@92->display_info_vera#4] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [344] phi from main::@92 to main::@16 [phi:main::@92->main::@16]
    // [344] phi main::rom_chip1#2 = 0 [phi:main::@92->main::@16#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip1
    // main::@16
  __b16:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [345] if(main::rom_chip1#2<8) goto main::@17 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip1
    cmp #8
    bcc __b17
    // [346] phi from main::@16 to main::@18 [phi:main::@16->main::@18]
    // main::@18
    // display_action_text("You have selected not to cancel the update ... ")
    // [347] call display_action_text
    // [743] phi from main::@18 to display_action_text [phi:main::@18->display_action_text]
    // [743] phi display_action_text::info_text#6 = main::info_text19 [phi:main::@18->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_action_text.info_text
    lda #>info_text19
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_bram2
    // main::@17
  __b17:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [348] display_info_rom::rom_chip#2 = main::rom_chip1#2 -- vbuz1=vbuz2 
    lda.z rom_chip1
    sta.z display_info_rom.rom_chip
    // [349] call display_info_rom
    // [808] phi from main::@17 to display_info_rom [phi:main::@17->display_info_rom]
    // [808] phi display_info_rom::info_text#10 = main::info_text16 [phi:main::@17->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_info_rom.info_text
    lda #>info_text16
    sta.z display_info_rom.info_text+1
    // [808] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#2 [phi:main::@17->display_info_rom#1] -- register_copy 
    // [808] phi display_info_rom::info_status#10 = STATUS_SKIP [phi:main::@17->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@93
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [350] main::rom_chip1#1 = ++ main::rom_chip1#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip1
    // [344] phi from main::@93 to main::@16 [phi:main::@93->main::@16]
    // [344] phi main::rom_chip1#2 = main::rom_chip1#1 [phi:main::@93->main::@16#0] -- register_copy 
    jmp __b16
    // [351] phi from main::@36 to main::@6 [phi:main::@36->main::@6]
    // main::@6
  __b6:
    // display_action_progress("The SMC chip and SMC.BIN versions are equal, no flash required!")
    // [352] call display_action_progress
    // [537] phi from main::@6 to display_action_progress [phi:main::@6->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text12 [phi:main::@6->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_action_progress.info_text
    lda #>info_text12
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [353] phi from main::@6 to main::@85 [phi:main::@6->main::@85]
    // main::@85
    // util_wait_space()
    // [354] call util_wait_space
    // [673] phi from main::@85 to util_wait_space [phi:main::@85->util_wait_space]
    jsr util_wait_space
    // [355] phi from main::@85 to main::@86 [phi:main::@85->main::@86]
    // main::@86
    // display_info_smc(STATUS_SKIP, "SMC.BIN and SMC equal.")
    // [356] call display_info_smc
    // [595] phi from main::@86 to display_info_smc [phi:main::@86->display_info_smc]
    // [595] phi display_info_smc::info_text#10 = main::info_text13 [phi:main::@86->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_info_smc.info_text
    lda #>info_text13
    sta.z display_info_smc.info_text+1
    // [595] phi display_info_smc::info_status#10 = STATUS_SKIP [phi:main::@86->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_smc6
    // [357] phi from main::@120 to main::@4 [phi:main::@120->main::@4]
    // main::@4
  __b4:
    // display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!")
    // [358] call display_action_progress
    // [537] phi from main::@4 to display_action_progress [phi:main::@4->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text10 [phi:main::@4->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [359] phi from main::@4 to main::@79 [phi:main::@4->main::@79]
    // main::@79
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [360] call display_progress_text
    // [663] phi from main::@79 to display_progress_text [phi:main::@79->display_progress_text]
    // [663] phi display_progress_text::text#10 = display_smc_unsupported_rom_text [phi:main::@79->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [663] phi display_progress_text::lines#11 = display_smc_unsupported_rom_count [phi:main::@79->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [361] phi from main::@79 to main::@80 [phi:main::@79->main::@80]
    // main::@80
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [362] call util_wait_key
    // [775] phi from main::@80 to util_wait_key [phi:main::@80->util_wait_key]
    // [775] phi util_wait_key::filter#13 = main::filter [phi:main::@80->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [775] phi util_wait_key::info_text#3 = main::info_text11 [phi:main::@80->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z util_wait_key.info_text
    lda #>info_text11
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN")
    // [363] util_wait_key::return#3 = util_wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z util_wait_key.ch
    sta.z util_wait_key.return
    // main::@81
    // [364] main::ch#0 = util_wait_key::return#3
    // if(ch == 'N')
    // [365] if(main::ch#0!='N') goto main::check_status_smc5 -- vbuz1_neq_vbuc1_then_la1 
    lda #'N'
    cmp.z ch
    beq !check_status_smc5+
    jmp check_status_smc5
  !check_status_smc5:
    // [366] phi from main::@81 to main::@5 [phi:main::@81->main::@5]
    // main::@5
    // display_info_smc(STATUS_ISSUE, NULL)
    // [367] call display_info_smc
  // Cancel flash
    // [595] phi from main::@5 to display_info_smc [phi:main::@5->display_info_smc]
    // [595] phi display_info_smc::info_text#10 = 0 [phi:main::@5->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [595] phi display_info_smc::info_status#10 = STATUS_ISSUE [phi:main::@5->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [368] phi from main::@5 to main::@82 [phi:main::@5->main::@82]
    // main::@82
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [369] call display_info_cx16_rom
    // [851] phi from main::@82 to display_info_cx16_rom [phi:main::@82->display_info_cx16_rom]
    // [851] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@82->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [851] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@82->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc5
    // [370] phi from main::@119 to main::@3 [phi:main::@119->main::@3]
    // main::@3
  __b3:
    // display_action_progress("CX16 ROM update issue!")
    // [371] call display_action_progress
    // [537] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text8 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [372] phi from main::@3 to main::@74 [phi:main::@3->main::@74]
    // main::@74
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [373] call display_progress_text
    // [663] phi from main::@74 to display_progress_text [phi:main::@74->display_progress_text]
    // [663] phi display_progress_text::text#10 = display_smc_rom_issue_text [phi:main::@74->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [663] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@74->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [374] phi from main::@74 to main::@75 [phi:main::@74->main::@75]
    // main::@75
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [375] call display_info_smc
    // [595] phi from main::@75 to display_info_smc [phi:main::@75->display_info_smc]
    // [595] phi display_info_smc::info_text#10 = main::info_text6 [phi:main::@75->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_smc.info_text
    lda #>info_text6
    sta.z display_info_smc.info_text+1
    // [595] phi display_info_smc::info_status#10 = STATUS_SKIP [phi:main::@75->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [376] phi from main::@75 to main::@76 [phi:main::@75->main::@76]
    // main::@76
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [377] call display_info_cx16_rom
    // [851] phi from main::@76 to display_info_cx16_rom [phi:main::@76->display_info_cx16_rom]
    // [851] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@76->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [851] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@76->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [378] phi from main::@76 to main::@77 [phi:main::@76->main::@77]
    // main::@77
    // util_wait_space()
    // [379] call util_wait_space
    // [673] phi from main::@77 to util_wait_space [phi:main::@77->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [380] phi from main::@118 to main::@1 [phi:main::@118->main::@1]
    // main::@1
  __b1:
    // display_action_progress("CX16 ROM update issue, ROM not detected!")
    // [381] call display_action_progress
    // [537] phi from main::@1 to display_action_progress [phi:main::@1->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text5 [phi:main::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_action_progress.info_text
    lda #>info_text5
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [382] phi from main::@1 to main::@70 [phi:main::@1->main::@70]
    // main::@70
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [383] call display_progress_text
    // [663] phi from main::@70 to display_progress_text [phi:main::@70->display_progress_text]
    // [663] phi display_progress_text::text#10 = display_smc_rom_issue_text [phi:main::@70->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [663] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@70->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [384] phi from main::@70 to main::@71 [phi:main::@70->main::@71]
    // main::@71
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [385] call display_info_smc
    // [595] phi from main::@71 to display_info_smc [phi:main::@71->display_info_smc]
    // [595] phi display_info_smc::info_text#10 = main::info_text6 [phi:main::@71->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_smc.info_text
    lda #>info_text6
    sta.z display_info_smc.info_text+1
    // [595] phi display_info_smc::info_status#10 = STATUS_SKIP [phi:main::@71->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [386] phi from main::@71 to main::@72 [phi:main::@71->main::@72]
    // main::@72
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [387] call display_info_cx16_rom
    // [851] phi from main::@72 to display_info_cx16_rom [phi:main::@72->display_info_cx16_rom]
    // [851] phi display_info_cx16_rom::info_text#4 = main::info_text7 [phi:main::@72->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_info_cx16_rom.info_text
    lda #>info_text7
    sta.z display_info_cx16_rom.info_text+1
    // [851] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@72->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [388] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // util_wait_space()
    // [389] call util_wait_space
    // [673] phi from main::@73 to util_wait_space [phi:main::@73->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [390] phi from main::@117 to main::@15 [phi:main::@117->main::@15]
    // main::@15
  __b15:
    // display_action_progress("SMC update issue!")
    // [391] call display_action_progress
    // [537] phi from main::@15 to display_action_progress [phi:main::@15->display_action_progress]
    // [537] phi display_action_progress::info_text#11 = main::info_text3 [phi:main::@15->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [392] phi from main::@15 to main::@66 [phi:main::@15->main::@66]
    // main::@66
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [393] call display_progress_text
    // [663] phi from main::@66 to display_progress_text [phi:main::@66->display_progress_text]
    // [663] phi display_progress_text::text#10 = display_smc_rom_issue_text [phi:main::@66->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [663] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@66->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [394] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [395] call display_info_cx16_rom
    // [851] phi from main::@67 to display_info_cx16_rom [phi:main::@67->display_info_cx16_rom]
    // [851] phi display_info_cx16_rom::info_text#4 = main::info_text4 [phi:main::@67->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_cx16_rom.info_text
    lda #>info_text4
    sta.z display_info_cx16_rom.info_text+1
    // [851] phi display_info_cx16_rom::info_status#4 = STATUS_SKIP [phi:main::@67->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [396] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // display_info_smc(STATUS_ISSUE, NULL)
    // [397] call display_info_smc
    // [595] phi from main::@68 to display_info_smc [phi:main::@68->display_info_smc]
    // [595] phi display_info_smc::info_text#10 = 0 [phi:main::@68->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [595] phi display_info_smc::info_status#10 = STATUS_ISSUE [phi:main::@68->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [398] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // util_wait_space()
    // [399] call util_wait_space
    // [673] phi from main::@69 to util_wait_space [phi:main::@69->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc2
    // main::@13
  __b13:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [400] display_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y+3
    clc
    adc.z intro_status
    sta.z display_info_led.y
    // [401] display_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z intro_status
    lda status_color,y
    sta.z display_info_led.tc
    // [402] call display_info_led
    // [856] phi from main::@13 to display_info_led [phi:main::@13->display_info_led]
    // [856] phi display_info_led::y#4 = display_info_led::y#3 [phi:main::@13->display_info_led#0] -- register_copy 
    // [856] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main::@13->display_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z display_info_led.x
    // [856] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main::@13->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main::@61
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [403] main::intro_status#1 = ++ main::intro_status#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_status
    // [108] phi from main::@61 to main::@12 [phi:main::@61->main::@12]
    // [108] phi main::intro_status#2 = main::intro_status#1 [phi:main::@61->main::@12#0] -- register_copy 
    jmp __b12
    // main::@11
  __b11:
    // rom_chip*13
    // [404] main::$212 = main::rom_chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z main__212
    // [405] main::$213 = main::$212 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__213
    clc
    adc.z rom_chip
    sta.z main__213
    // [406] main::$214 = main::$213 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__214
    asl
    asl
    sta.z main__214
    // [407] main::$80 = main::$214 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z main__80
    clc
    adc.z rom_chip
    sta.z main__80
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [408] strcpy::destination#1 = rom_release_text + main::$80 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [409] call strcpy
    // [867] phi from main::@11 to strcpy [phi:main::@11->strcpy]
    // [867] phi strcpy::dst#0 = strcpy::destination#1 [phi:main::@11->strcpy#0] -- register_copy 
    // [867] phi strcpy::src#0 = main::source [phi:main::@11->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@57
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [410] display_info_rom::rom_chip#1 = main::rom_chip#2 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z display_info_rom.rom_chip
    // [411] call display_info_rom
    // [808] phi from main::@57 to display_info_rom [phi:main::@57->display_info_rom]
    // [808] phi display_info_rom::info_text#10 = 0 [phi:main::@57->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [808] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#1 [phi:main::@57->display_info_rom#1] -- register_copy 
    // [808] phi display_info_rom::info_status#10 = STATUS_NONE [phi:main::@57->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@58
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [412] main::rom_chip#1 = ++ main::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [98] phi from main::@58 to main::@10 [phi:main::@58->main::@10]
    // [98] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@58->main::@10#0] -- register_copy 
    jmp __b10
  .segment Data
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
    info_text1: .text "VERA installed, OK"
    .byte 0
    info_text2: .text "VERA not yet supported"
    .byte 0
    info_text3: .text "SMC update issue!"
    .byte 0
    info_text4: .text "Issue with SMC!"
    .byte 0
    info_text5: .text "CX16 ROM update issue, ROM not detected!"
    .byte 0
    info_text6: .text "Issue with main CX16 ROM!"
    .byte 0
    info_text7: .text "Are J1 jumper pins closed?"
    .byte 0
    info_text8: .text "CX16 ROM update issue!"
    .byte 0
    info_text10: .text "Compatibility between ROM.BIN and SMC.BIN can't be assured!"
    .byte 0
    info_text11: .text "Continue with flashing anyway? [Y/N]"
    .byte 0
    filter: .text "YN"
    .byte 0
    info_text12: .text "The SMC chip and SMC.BIN versions are equal, no flash required!"
    .byte 0
    info_text13: .text "SMC.BIN and SMC equal."
    .byte 0
    info_text14: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text15: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter1: .text "nyNY"
    .byte 0
    main__190: .text "nN"
    .byte 0
    info_text16: .text "Cancelled"
    .byte 0
    info_text19: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text20: .text "No CX16 component has been updated with new firmware!"
    .byte 0
    info_text21: .text "Update Failure! Your CX16 may no longer boot!"
    .byte 0
    info_text22: .text "Take a photo of this screen, shut down power and retry!"
    .byte 0
    info_text23: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text24: .text "Your CX16 update is a success!"
    .byte 0
    text: .text "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!"
    .byte 0
    s2: .text "["
    .byte 0
    s3: .text "] Please read carefully the below ..."
    .byte 0
    s4: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s5: .text "("
    .byte 0
    s6: .text ") Your CX16 will reset after countdown ..."
    .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [413] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [414] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [415] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [416] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $45
    .label textcolor__1 = $45
    // __conio.color & 0xF0
    // [418] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [419] textcolor::$1 = textcolor::$0 | textcolor::color#20 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [420] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [421] return 
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
    .label bgcolor__0 = $45
    .label bgcolor__1 = $4a
    .label bgcolor__2 = $45
    // __conio.color & 0x0F
    // [423] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [424] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [425] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [426] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [427] return 
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
    // [428] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [429] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [430] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [431] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [433] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [434] return 
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
    // [436] if(gotoxy::x#19>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [438] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [438] phi gotoxy::$3 = gotoxy::x#19 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [437] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [438] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [438] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [439] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [440] if(gotoxy::y#19>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [441] gotoxy::$14 = gotoxy::y#19 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [442] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [442] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [443] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [444] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [445] gotoxy::$10 = gotoxy::y#19 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [446] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [447] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [448] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [449] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    .label cputln__2 = $32
    // __conio.cursor_x = 0
    // [450] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [451] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [452] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [453] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [454] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [455] return 
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
    .label cx16_k_screen_set_charset1_offset = $bc
    // cx16_k_screen_set_mode(0)
    // [456] cx16_k_screen_set_mode::mode = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_screen_set_mode.mode
    // [457] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [458] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // screenlayer1()
    // [459] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // display_frame_init_64::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [460] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [461] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // [463] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [464] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [465] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [466] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [467] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [468] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [469] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [470] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [471] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [472] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [473] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [474] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [475] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [476] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [477] phi from display_frame_init_64::vera_layer1_show1 to display_frame_init_64::@1 [phi:display_frame_init_64::vera_layer1_show1->display_frame_init_64::@1]
    // display_frame_init_64::@1
    // textcolor(WHITE)
    // [478] call textcolor
  // Layer 1 is the current text canvas.
    // [417] phi from display_frame_init_64::@1 to textcolor [phi:display_frame_init_64::@1->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:display_frame_init_64::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [479] phi from display_frame_init_64::@1 to display_frame_init_64::@4 [phi:display_frame_init_64::@1->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // bgcolor(BLUE)
    // [480] call bgcolor
  // Default text color is white.
    // [422] phi from display_frame_init_64::@4 to bgcolor [phi:display_frame_init_64::@4->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_frame_init_64::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [481] phi from display_frame_init_64::@4 to display_frame_init_64::@5 [phi:display_frame_init_64::@4->display_frame_init_64::@5]
    // display_frame_init_64::@5
    // clrscr()
    // [482] call clrscr
    // With a blue background.
    // cx16-conio.c won't compile scrolling code for this program with the underlying define, resulting in less code overhead!
    jsr clrscr
    // display_frame_init_64::@return
    // }
    // [483] return 
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
    // [485] call textcolor
    // [417] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [417] phi textcolor::color#20 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [486] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [487] call bgcolor
    // [422] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [488] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [489] call clrscr
    jsr clrscr
    // [490] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [491] call display_frame
    // [947] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [947] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [492] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [493] call display_frame
    // [947] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [947] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [494] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [495] call display_frame
    // [947] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [496] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [497] call display_frame
  // Chipset areas
    // [947] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x1
    jsr display_frame
    // [498] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [499] call display_frame
    // [947] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x1
    jsr display_frame
    // [500] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [501] call display_frame
    // [947] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x1
    jsr display_frame
    // [502] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [503] call display_frame
    // [947] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x1
    jsr display_frame
    // [504] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [505] call display_frame
    // [947] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x1
    jsr display_frame
    // [506] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [507] call display_frame
    // [947] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x1
    jsr display_frame
    // [508] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [509] call display_frame
    // [947] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x1
    jsr display_frame
    // [510] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [511] call display_frame
    // [947] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x1
    jsr display_frame
    // [512] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [513] call display_frame
    // [947] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x1
    jsr display_frame
    // [514] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [515] call display_frame
    // [947] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [947] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [516] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [517] call display_frame
  // Progress area
    // [947] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [947] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [518] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [519] call display_frame
    // [947] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [947] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [520] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [521] call display_frame
    // [947] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [947] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y
    // [947] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.y1
    // [947] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [947] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [522] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [523] call textcolor
    // [417] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [524] return 
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
    // [526] call gotoxy
    // [435] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [435] phi gotoxy::y#19 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [435] phi gotoxy::x#19 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [527] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [528] call printf_string
    // [1081] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1081] phi printf_string::str#12 = main::title_text [phi:display_frame_title::@1->printf_string#0] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1081] phi printf_string::format_min_length#12 = $41 [phi:display_frame_title::@1->printf_string#1] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [529] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($35) const char *s)
cputsxy: {
    .label s = $35
    // gotoxy(x, y)
    // [531] gotoxy::x#1 = cputsxy::x#3 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [532] gotoxy::y#1 = cputsxy::y#3 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [533] call gotoxy
    // [435] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [534] cputs::s#1 = cputsxy::s#3 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [535] call cputs
    // [1098] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [536] return 
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
// void display_action_progress(__zp($37) char *info_text)
display_action_progress: {
    .label x = $57
    .label y = $54
    .label info_text = $37
    // unsigned char x = wherex()
    // [538] call wherex
    jsr wherex
    // [539] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [540] display_action_progress::x#0 = wherex::return#2 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [541] call wherey
    jsr wherey
    // [542] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [543] display_action_progress::y#0 = wherey::return#2 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // gotoxy(2, PROGRESS_Y-4)
    // [544] call gotoxy
    // [435] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [435] phi gotoxy::y#19 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [435] phi gotoxy::x#19 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [545] printf_string::str#1 = display_action_progress::info_text#11
    // [546] call printf_string
    // [1081] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = $41 [phi:display_action_progress::@3->printf_string#1] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [547] gotoxy::x#10 = display_action_progress::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [548] gotoxy::y#10 = display_action_progress::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [549] call gotoxy
    // [435] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [550] return 
    rts
}
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $5c
    .label i = $56
    .label y = $6b
    // textcolor(WHITE)
    // [552] call textcolor
    // [417] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [553] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [554] call bgcolor
    // [422] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [555] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [555] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [556] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [557] return 
    rts
    // [558] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [558] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [558] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [559] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [560] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [555] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [555] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [561] cputcxy::x#12 = display_progress_clear::x#2 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [562] cputcxy::y#12 = display_progress_clear::y#2 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [563] call cputcxy
    // [1111] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1111] phi cputcxy::c#13 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [1111] phi cputcxy::y#13 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [564] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [565] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [558] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [558] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [558] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [567] call display_smc_led
    // [1119] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1119] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [568] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [569] call display_print_chip
    // [1125] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1125] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1125] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z display_print_chip.w
    // [1125] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [570] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [572] call display_vera_led
    // [1169] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [1169] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_vera_led.c
    jsr display_vera_led
    // [573] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [574] call display_print_chip
    // [1125] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1125] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1125] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z display_print_chip.w
    // [1125] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [575] return 
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
    .label display_chip_rom__4 = $57
    .label display_chip_rom__6 = $69
    .label r = $7f
    .label display_chip_rom__11 = $3b
    .label display_chip_rom__12 = $3b
    // [577] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [577] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [578] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [579] return 
    rts
    // [580] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [581] call strcpy
    // [867] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [867] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [867] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [582] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z r
    asl
    sta.z display_chip_rom__11
    // [583] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [584] call strcat
    // [1175] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [585] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbuz1_then_la1 
    lda.z r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [586] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [587] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [588] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z display_rom_led.chip
    // [589] call display_rom_led
    // [1187] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [1187] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [1187] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [590] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_chip_rom__12
    clc
    adc.z r
    sta.z display_chip_rom__12
    // [591] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz2_rol_1 
    asl
    sta.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [592] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z display_print_chip.x
    sta.z display_print_chip.x
    // [593] call display_print_chip
    // [1125] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1125] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1125] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z display_print_chip.w
    // [1125] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [594] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [577] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [577] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
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
// void display_info_smc(__zp($b1) char info_status, __zp($46) char *info_text)
display_info_smc: {
    .label display_info_smc__8 = $b1
    .label x = $ad
    .label y = $ac
    .label info_status = $b1
    .label info_text = $46
    // unsigned char x = wherex()
    // [596] call wherex
    jsr wherex
    // [597] wherex::return#10 = wherex::return#0
    // display_info_smc::@3
    // [598] display_info_smc::x#0 = wherex::return#10 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [599] call wherey
    jsr wherey
    // [600] wherey::return#10 = wherey::return#0
    // display_info_smc::@4
    // [601] display_info_smc::y#0 = wherey::return#10 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_smc = info_status
    // [602] status_smc#0 = display_info_smc::info_status#10 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [603] display_smc_led::c#1 = status_color[display_info_smc::info_status#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [604] call display_smc_led
    // [1119] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1119] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [605] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [606] call gotoxy
    // [435] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [435] phi gotoxy::y#19 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [435] phi gotoxy::x#19 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [607] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [608] call printf_str
    // [723] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [609] display_info_smc::$8 = display_info_smc::info_status#10 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_smc__8
    // [610] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [611] call printf_string
    // [1081] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = 9 [phi:display_info_smc::@7->printf_string#1] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [612] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [613] call printf_str
    // [723] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [614] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [615] call printf_string
    // [1081] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1081] phi printf_string::str#12 = smc_version_text [phi:display_info_smc::@9->printf_string#0] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1081] phi printf_string::format_min_length#12 = 8 [phi:display_info_smc::@9->printf_string#1] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [616] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [617] call printf_str
    // [723] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [618] phi from display_info_smc::@10 to display_info_smc::@11 [phi:display_info_smc::@10->display_info_smc::@11]
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [619] call printf_uint
    // [1198] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    jsr printf_uint
    // [620] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [621] call printf_str
    // [723] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = s3 [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [622] if((char *)0==display_info_smc::info_text#10) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-25s", info_text)
    // [623] printf_string::str#5 = display_info_smc::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [624] call printf_string
    // [1081] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#5 [phi:display_info_smc::@2->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = $19 [phi:display_info_smc::@2->printf_string#1] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [625] gotoxy::x#14 = display_info_smc::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [626] gotoxy::y#14 = display_info_smc::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [627] call gotoxy
    // [435] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [628] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " BL:"
    .byte 0
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__zp($ab) char info_status, __zp($4b) char *info_text)
display_info_vera: {
    .label display_info_vera__8 = $ab
    .label x = $bb
    .label y = $7d
    .label info_status = $ab
    .label info_text = $4b
    // unsigned char x = wherex()
    // [630] call wherex
    jsr wherex
    // [631] wherex::return#11 = wherex::return#0
    // display_info_vera::@3
    // [632] display_info_vera::x#0 = wherex::return#11 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [633] call wherey
    jsr wherey
    // [634] wherey::return#11 = wherey::return#0
    // display_info_vera::@4
    // [635] display_info_vera::y#0 = wherey::return#11 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_vera = info_status
    // [636] status_vera#0 = display_info_vera::info_status#4 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [637] display_vera_led::c#1 = status_color[display_info_vera::info_status#4] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_vera_led.c
    // [638] call display_vera_led
    // [1169] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [1169] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [639] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [640] call gotoxy
    // [435] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [435] phi gotoxy::y#19 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [435] phi gotoxy::x#19 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [641] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s SPI %x%x%x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [642] call printf_str
    // [723] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s SPI %x%x%x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [643] display_info_vera::$8 = display_info_vera::info_status#4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_vera__8
    // [644] printf_string::str#6 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [645] call printf_string
    // [1081] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = 9 [phi:display_info_vera::@7->printf_string#1] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [646] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s SPI %x%x%x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [647] call printf_str
    // [723] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // printf("VERA %-9s SPI %x%x%x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [648] printf_uchar::uvalue#0 = spi_manufacturer#12 -- vbum1=vbum2 
    lda spi_manufacturer
    sta printf_uchar.uvalue
    // [649] call printf_uchar
    // [732] phi from display_info_vera::@9 to printf_uchar [phi:display_info_vera::@9->printf_uchar]
    // [732] phi printf_uchar::format_zero_padding#10 = 0 [phi:display_info_vera::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [732] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_vera::@9->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [732] phi printf_uchar::putc#10 = &cputc [phi:display_info_vera::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [732] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_info_vera::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [732] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#0 [phi:display_info_vera::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // display_info_vera::@10
    // printf("VERA %-9s SPI %x%x%x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [650] printf_uchar::uvalue#1 = spi_memory_type#12 -- vbum1=vbum2 
    lda spi_memory_type
    sta printf_uchar.uvalue
    // [651] call printf_uchar
    // [732] phi from display_info_vera::@10 to printf_uchar [phi:display_info_vera::@10->printf_uchar]
    // [732] phi printf_uchar::format_zero_padding#10 = 0 [phi:display_info_vera::@10->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [732] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_vera::@10->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [732] phi printf_uchar::putc#10 = &cputc [phi:display_info_vera::@10->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [732] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_info_vera::@10->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [732] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#1 [phi:display_info_vera::@10->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // display_info_vera::@11
    // printf("VERA %-9s SPI %x%x%x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [652] printf_uchar::uvalue#2 = spi_memory_capacity#12 -- vbum1=vbum2 
    lda spi_memory_capacity
    sta printf_uchar.uvalue
    // [653] call printf_uchar
    // [732] phi from display_info_vera::@11 to printf_uchar [phi:display_info_vera::@11->printf_uchar]
    // [732] phi printf_uchar::format_zero_padding#10 = 0 [phi:display_info_vera::@11->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [732] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_vera::@11->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [732] phi printf_uchar::putc#10 = &cputc [phi:display_info_vera::@11->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [732] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:display_info_vera::@11->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [732] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#2 [phi:display_info_vera::@11->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [654] phi from display_info_vera::@11 to display_info_vera::@12 [phi:display_info_vera::@11->display_info_vera::@12]
    // display_info_vera::@12
    // printf("VERA %-9s SPI %x%x%x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [655] call printf_str
    // [723] phi from display_info_vera::@12 to printf_str [phi:display_info_vera::@12->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_vera::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = display_info_vera::s2 [phi:display_info_vera::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@13
    // if(info_text)
    // [656] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-25s", info_text)
    // [657] printf_string::str#7 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [658] call printf_string
    // [1081] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#7 [phi:display_info_vera::@2->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = $19 [phi:display_info_vera::@2->printf_string#1] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [659] gotoxy::x#16 = display_info_vera::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [660] gotoxy::y#16 = display_info_vera::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [661] call gotoxy
    // [435] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [662] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " SPI "
    .byte 0
    s2: .text "              "
    .byte 0
}
.segment Code
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($39) char **text, __zp($b8) char lines)
display_progress_text: {
    .label display_progress_text__3 = $54
    .label l = $7e
    .label lines = $b8
    .label text = $39
    // display_progress_clear()
    // [664] call display_progress_clear
    // [551] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [665] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [665] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [666] if(display_progress_text::l#2<display_progress_text::lines#11) goto display_progress_text::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [667] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [668] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z l
    asl
    sta.z display_progress_text__3
    // [669] display_progress_line::line#0 = display_progress_text::l#2 -- vbuz1=vbuz2 
    lda.z l
    sta.z display_progress_line.line
    // [670] display_progress_line::text#0 = display_progress_text::text#10[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [671] call display_progress_line
    // [704] phi from display_progress_text::@2 to display_progress_line [phi:display_progress_text::@2->display_progress_line]
    // [704] phi display_progress_line::text#3 = display_progress_line::text#0 [phi:display_progress_text::@2->display_progress_line#0] -- register_copy 
    // [704] phi display_progress_line::line#3 = display_progress_line::line#0 [phi:display_progress_text::@2->display_progress_line#1] -- register_copy 
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [672] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [665] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [665] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
}
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [674] call util_wait_key
    // [775] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [775] phi util_wait_key::filter#13 = s3 [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s3
    sta.z util_wait_key.filter
    lda #>s3
    sta.z util_wait_key.filter+1
    // [775] phi util_wait_key::info_text#3 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [675] return 
    rts
  .segment Data
    info_text: .text "Press [SPACE] to continue ..."
    .byte 0
}
.segment Code
  // vera_detect
/**
 * @file cx16-vera.c

 * @author MooingLemur (https://github.com/mooinglemur)
 * @author Sven Van de Velde (https://github.com/FlightControl-User)
 * 
 * @brief COMMANDER X16 VERA FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-10-11
 *
 * @copyright Copyright (c) 2023
 *
 */
vera_detect: {
    // spi_get_jedec()
    // [677] call spi_get_jedec
  // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    // [1204] phi from vera_detect to spi_get_jedec [phi:vera_detect->spi_get_jedec]
    jsr spi_get_jedec
    // vera_detect::@return
    // }
    // [678] return 
    rts
}
  // smc_supported_rom
/**
 * @brief Search in the smc file header for supported ROM.BIN releases.
 * The first 3 bytes of the smc file header contain the SMC.BIN version, major and minor numbers.
 * 
 * @param rom_release The ROM release to search for.
 * @return unsigned char true if found.
 */
// __zp($56) char smc_supported_rom(__zp($aa) char rom_release)
smc_supported_rom: {
    .label i = $6b
    .label return = $56
    .label rom_release = $aa
    // [680] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [680] phi smc_supported_rom::i#2 = $1f [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z i
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=31; i>3; i--)
    // [681] if(smc_supported_rom::i#2>=3+1) goto smc_supported_rom::@2 -- vbuz1_ge_vbuc1_then_la1 
    lda.z i
    cmp #3+1
    bcs __b2
    // [683] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [683] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_file_header[i] == rom_release)
    // [682] if(smc_file_header[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbuz1_neq_vbuz2_then_la1 
    lda.z rom_release
    ldy.z i
    cmp smc_file_header,y
    bne __b3
    // [683] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [683] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // smc_supported_rom::@return
    // }
    // [684] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=31; i>3; i--)
    // [685] smc_supported_rom::i#1 = -- smc_supported_rom::i#2 -- vbuz1=_dec_vbuz1 
    dec.z i
    // [680] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [680] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
    jmp __b1
}
  // check_status_roms
/**
 * @brief Check the status of all the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
// __zp($b1) char check_status_roms(__zp($5c) char status)
check_status_roms: {
    .label check_status_rom1_check_status_roms__0 = $3b
    .label check_status_rom1_return = $3b
    .label rom_chip = $7f
    .label return = $b1
    .label status = $5c
    // [687] phi from check_status_roms to check_status_roms::@1 [phi:check_status_roms->check_status_roms::@1]
    // [687] phi check_status_roms::rom_chip#2 = 0 [phi:check_status_roms->check_status_roms::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // check_status_roms::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [688] if(check_status_roms::rom_chip#2<8) goto check_status_roms::check_status_rom1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc check_status_rom1
    // [689] phi from check_status_roms::@1 to check_status_roms::@return [phi:check_status_roms::@1->check_status_roms::@return]
    // [689] phi check_status_roms::return#2 = 0 [phi:check_status_roms::@1->check_status_roms::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    // check_status_roms::@return
    // }
    // [690] return 
    rts
    // check_status_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [691] check_status_roms::check_status_rom1_$0 = status_rom[check_status_roms::rom_chip#2] == check_status_roms::status#6 -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuz3 
    lda.z status
    ldy.z rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [692] check_status_roms::check_status_rom1_return#0 = (char)check_status_roms::check_status_rom1_$0
    // check_status_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [693] if(0==check_status_roms::check_status_rom1_return#0) goto check_status_roms::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_rom1_return
    beq __b2
    // [689] phi from check_status_roms::@3 to check_status_roms::@return [phi:check_status_roms::@3->check_status_roms::@return]
    // [689] phi check_status_roms::return#2 = 1 [phi:check_status_roms::@3->check_status_roms::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    rts
    // check_status_roms::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [694] check_status_roms::rom_chip#1 = ++ check_status_roms::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [687] phi from check_status_roms::@2 to check_status_roms::@1 [phi:check_status_roms::@2->check_status_roms::@1]
    // [687] phi check_status_roms::rom_chip#2 = check_status_roms::rom_chip#1 [phi:check_status_roms::@2->check_status_roms::@1#0] -- register_copy 
    jmp __b1
}
  // check_status_roms_less
/**
 * @brief Check the status of all the ROMs mutually.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if all chips are equal to the status.
 */
// __zp($b8) char check_status_roms_less(char status)
check_status_roms_less: {
    .label check_status_rom1_check_status_roms_less__0 = $ad
    .label check_status_rom1_return = $ad
    .label rom_chip = $ab
    .label return = $b8
    // [696] phi from check_status_roms_less to check_status_roms_less::@1 [phi:check_status_roms_less->check_status_roms_less::@1]
    // [696] phi check_status_roms_less::rom_chip#2 = 0 [phi:check_status_roms_less->check_status_roms_less::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // check_status_roms_less::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [697] if(check_status_roms_less::rom_chip#2<8) goto check_status_roms_less::check_status_rom1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc check_status_rom1
    // [698] phi from check_status_roms_less::@1 to check_status_roms_less::@return [phi:check_status_roms_less::@1->check_status_roms_less::@return]
    // [698] phi check_status_roms_less::return#2 = 1 [phi:check_status_roms_less::@1->check_status_roms_less::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // check_status_roms_less::@return
    // }
    // [699] return 
    rts
    // check_status_roms_less::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [700] check_status_roms_less::check_status_rom1_$0 = status_rom[check_status_roms_less::rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy.z rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms_less__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [701] check_status_roms_less::check_status_rom1_return#0 = (char)check_status_roms_less::check_status_rom1_$0
    // check_status_roms_less::@3
    // if(check_status_rom(rom_chip, status) > status)
    // [702] if(check_status_roms_less::check_status_rom1_return#0<STATUS_SKIP+1) goto check_status_roms_less::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z check_status_rom1_return
    cmp #STATUS_SKIP+1
    bcc __b2
    // [698] phi from check_status_roms_less::@3 to check_status_roms_less::@return [phi:check_status_roms_less::@3->check_status_roms_less::@return]
    // [698] phi check_status_roms_less::return#2 = 0 [phi:check_status_roms_less::@3->check_status_roms_less::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // check_status_roms_less::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [703] check_status_roms_less::rom_chip#1 = ++ check_status_roms_less::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [696] phi from check_status_roms_less::@2 to check_status_roms_less::@1 [phi:check_status_roms_less::@2->check_status_roms_less::@1]
    // [696] phi check_status_roms_less::rom_chip#2 = check_status_roms_less::rom_chip#1 [phi:check_status_roms_less::@2->check_status_roms_less::@1#0] -- register_copy 
    jmp __b1
}
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__zp($6b) char line, __zp($35) char *text)
display_progress_line: {
    .label line = $6b
    .label text = $35
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [705] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#3 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y
    clc
    adc.z line
    sta cputsxy.y
    // [706] cputsxy::s#0 = display_progress_line::text#3
    // [707] call cputsxy
    // [530] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [530] phi cputsxy::s#3 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [530] phi cputsxy::y#3 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [530] phi cputsxy::x#3 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [708] return 
    rts
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
    // [710] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [711] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [713] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
    // system_reset::@1
  __b1:
    jmp __b1
}
  // wait_moment
/**
 * @brief 
 * 
 */
wait_moment: {
    .label i = $35
    // [715] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [715] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [716] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b2
    lda.z i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [717] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [718] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [715] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [715] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [719] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [720] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [721] __snprintf_buffer = info_text -- pbuz1=pbuc1 
    lda #<info_text
    sta.z __snprintf_buffer
    lda #>info_text
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [722] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($39) void (*putc)(char), __zp($37) const char *s)
printf_str: {
    .label s = $37
    .label putc = $39
    // [724] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [724] phi printf_str::s#20 = printf_str::s#21 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [725] printf_str::c#1 = *printf_str::s#20 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [726] printf_str::s#0 = ++ printf_str::s#20 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [727] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [728] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [729] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [730] callexecute *printf_str::putc#21  -- call__deref_pprz1 
    jsr icall4
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall4:
    jmp (putc)
  .segment Data
    c: .byte 0
}
.segment Code
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($72) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $72
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [733] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [734] uctoa::value#1 = printf_uchar::uvalue#6
    // [735] uctoa::radix#0 = printf_uchar::format_radix#10
    // [736] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [737] printf_number_buffer::putc#1 = printf_uchar::putc#10
    // [738] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [739] printf_number_buffer::format_min_length#1 = printf_uchar::format_min_length#10
    // [740] printf_number_buffer::format_zero_padding#1 = printf_uchar::format_zero_padding#10
    // [741] call printf_number_buffer
  // Print using format
    // [1248] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1248] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #0
    sta printf_number_buffer.format_upper_case
    // [1248] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1248] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1248] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    // [1248] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbum1=vbuc1 
    sta printf_number_buffer.format_justify_left
    // [1248] phi printf_number_buffer::format_min_length#2 = printf_number_buffer::format_min_length#1 [phi:printf_uchar::@2->printf_number_buffer#5] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [742] return 
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
// void display_action_text(__zp($72) char *info_text)
display_action_text: {
    .label info_text = $72
    .label x = $a9
    .label y = $71
    // unsigned char x = wherex()
    // [744] call wherex
    jsr wherex
    // [745] wherex::return#3 = wherex::return#0
    // display_action_text::@1
    // [746] display_action_text::x#0 = wherex::return#3 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [747] call wherey
    jsr wherey
    // [748] wherey::return#3 = wherey::return#0
    // display_action_text::@2
    // [749] display_action_text::y#0 = wherey::return#3 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // gotoxy(2, PROGRESS_Y-3)
    // [750] call gotoxy
    // [435] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [435] phi gotoxy::y#19 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [435] phi gotoxy::x#19 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [751] printf_string::str#2 = display_action_text::info_text#6 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [752] call printf_string
    // [1081] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#2 [phi:display_action_text::@3->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = $41 [phi:display_action_text::@3->printf_string#1] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [753] gotoxy::x#12 = display_action_text::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [754] gotoxy::y#12 = display_action_text::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [755] call gotoxy
    // [435] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [756] return 
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
    // [758] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [759] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@1
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [760] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [761] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [762] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [763] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [765] return 
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
// __zp($6b) char check_status_card_roms(char status)
check_status_card_roms: {
    .label check_status_rom1_check_status_card_roms__0 = $ac
    .label check_status_rom1_return = $ac
    .label rom_chip = $7e
    .label return = $6b
    // [767] phi from check_status_card_roms to check_status_card_roms::@1 [phi:check_status_card_roms->check_status_card_roms::@1]
    // [767] phi check_status_card_roms::rom_chip#2 = 1 [phi:check_status_card_roms->check_status_card_roms::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z rom_chip
    // check_status_card_roms::@1
  __b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [768] if(check_status_card_roms::rom_chip#2<8) goto check_status_card_roms::check_status_rom1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc check_status_rom1
    // [769] phi from check_status_card_roms::@1 to check_status_card_roms::@return [phi:check_status_card_roms::@1->check_status_card_roms::@return]
    // [769] phi check_status_card_roms::return#2 = 0 [phi:check_status_card_roms::@1->check_status_card_roms::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    // check_status_card_roms::@return
    // }
    // [770] return 
    rts
    // check_status_card_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [771] check_status_card_roms::check_status_rom1_$0 = status_rom[check_status_card_roms::rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy.z rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_card_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [772] check_status_card_roms::check_status_rom1_return#0 = (char)check_status_card_roms::check_status_rom1_$0
    // check_status_card_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [773] if(0==check_status_card_roms::check_status_rom1_return#0) goto check_status_card_roms::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_rom1_return
    beq __b2
    // [769] phi from check_status_card_roms::@3 to check_status_card_roms::@return [phi:check_status_card_roms::@3->check_status_card_roms::@return]
    // [769] phi check_status_card_roms::return#2 = 1 [phi:check_status_card_roms::@3->check_status_card_roms::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    rts
    // check_status_card_roms::@2
  __b2:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [774] check_status_card_roms::rom_chip#1 = ++ check_status_card_roms::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [767] phi from check_status_card_roms::@2 to check_status_card_roms::@1 [phi:check_status_card_roms::@2->check_status_card_roms::@1]
    // [767] phi check_status_card_roms::rom_chip#2 = check_status_card_roms::rom_chip#1 [phi:check_status_card_roms::@2->check_status_card_roms::@1#0] -- register_copy 
    jmp __b1
}
  // util_wait_key
/**
 * @brief 
 * 
 * @param info_text 
 * @param filter 
 * @return unsigned char 
 */
// __zp($aa) char util_wait_key(__zp($72) char *info_text, __zp($48) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__9 = $37
    .label bram = $bb
    .label return = $be
    .label return_1 = $aa
    .label info_text = $72
    .label ch = $77
    .label filter = $48
    // display_action_text(info_text)
    // [776] display_action_text::info_text#0 = util_wait_key::info_text#3
    // [777] call display_action_text
    // [743] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [743] phi display_action_text::info_text#6 = display_action_text::info_text#0 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [778] util_wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [779] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [780] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [781] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [782] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [784] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [785] call cbm_k_getin
    jsr cbm_k_getin
    // [786] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [787] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwuz1=vbum2 
    lda cbm_k_getin.return
    sta.z ch
    lda #0
    sta.z ch+1
    // util_wait_key::@3
    // if (filter)
    // [788] if((char *)0!=util_wait_key::filter#13) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [789] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwuz1_then_la1 
    lda.z ch
    ora.z ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [790] BRAM = util_wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [791] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [792] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [793] strchr::str#0 = (const void *)util_wait_key::filter#13 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [794] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwuz2 
    lda.z ch
    sta strchr.c
    // [795] call strchr
    // [799] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [799] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [799] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [796] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [797] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [798] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__9
    ora.z util_wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    bank_get_brom1_return: .byte 0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($37) void * strchr(__zp($37) const void *str, __mem() char c)
strchr: {
    .label ptr = $37
    .label return = $37
    .label str = $37
    // [800] strchr::ptr#6 = (char *)strchr::str#2
    // [801] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [801] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [802] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [803] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [803] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [804] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [805] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [806] strchr::return#8 = (void *)strchr::ptr#2
    // [803] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [803] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [807] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
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
// void display_info_rom(__zp($60) char rom_chip, __zp($51) char info_status, __zp($52) char *info_text)
display_info_rom: {
    .label display_info_rom__6 = $7d
    .label display_info_rom__12 = $51
    .label display_info_rom__13 = $b5
    .label x = $74
    .label y = $58
    .label info_status = $51
    .label info_text = $52
    .label rom_chip = $60
    .label display_info_rom__16 = $7d
    .label display_info_rom__17 = $7d
    // unsigned char x = wherex()
    // [809] call wherex
    jsr wherex
    // [810] wherex::return#12 = wherex::return#0
    // display_info_rom::@3
    // [811] display_info_rom::x#0 = wherex::return#12 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [812] call wherey
    jsr wherey
    // [813] wherey::return#12 = wherey::return#0
    // display_info_rom::@4
    // [814] display_info_rom::y#0 = wherey::return#12 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_rom[rom_chip] = info_status
    // [815] status_rom[display_info_rom::rom_chip#10] = display_info_rom::info_status#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [816] display_rom_led::chip#1 = display_info_rom::rom_chip#10 -- vbuz1=vbuz2 
    tya
    sta.z display_rom_led.chip
    // [817] display_rom_led::c#1 = status_color[display_info_rom::info_status#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [818] call display_rom_led
    // [1187] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [1187] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [1187] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [819] gotoxy::y#17 = display_info_rom::rom_chip#10 + $11+2 -- vbum1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta gotoxy.y
    // [820] call gotoxy
    // [435] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#17 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [821] display_info_rom::$13 = display_info_rom::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z display_info_rom__13
    // rom_chip*13
    // [822] display_info_rom::$16 = display_info_rom::$13 + display_info_rom::rom_chip#10 -- vbuz1=vbuz2_plus_vbuz3 
    clc
    adc.z rom_chip
    sta.z display_info_rom__16
    // [823] display_info_rom::$17 = display_info_rom::$16 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z display_info_rom__17
    asl
    asl
    sta.z display_info_rom__17
    // [824] display_info_rom::$6 = display_info_rom::$17 + display_info_rom::rom_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_info_rom__6
    clc
    adc.z rom_chip
    sta.z display_info_rom__6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [825] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta.z printf_string.str_1+1
    // [826] call printf_str
    // [723] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [827] printf_uchar::uvalue#3 = display_info_rom::rom_chip#10 -- vbum1=vbuz2 
    lda.z rom_chip
    sta printf_uchar.uvalue
    // [828] call printf_uchar
    // [732] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [732] phi printf_uchar::format_zero_padding#10 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [732] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [732] phi printf_uchar::putc#10 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [732] phi printf_uchar::format_radix#10 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [732] phi printf_uchar::uvalue#6 = printf_uchar::uvalue#3 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [829] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [830] call printf_str
    // [723] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = s3 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [831] display_info_rom::$12 = display_info_rom::info_status#10 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_rom__12
    // [832] printf_string::str#8 = status_text[display_info_rom::$12] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__12
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [833] call printf_string
    // [1081] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = 9 [phi:display_info_rom::@9->printf_string#1] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [834] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [835] call printf_str
    // [723] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = s3 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [836] printf_string::str#9 = rom_device_names[display_info_rom::$13] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__13
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [837] call printf_string
    // [1081] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = 6 [phi:display_info_rom::@11->printf_string#1] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [838] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [839] call printf_str
    // [723] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = s3 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [840] printf_string::str#23 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z printf_string.str_1
    sta.z printf_string.str
    lda.z printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [841] call printf_string
    // [1081] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#23 [phi:display_info_rom::@13->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = $d [phi:display_info_rom::@13->printf_string#1] -- vbum1=vbuc1 
    lda #$d
    sta printf_string.format_min_length
    jsr printf_string
    // [842] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [843] call printf_str
    // [723] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = s3 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [844] if((char *)0==display_info_rom::info_text#10) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // printf("%-25s", info_text)
    // [845] printf_string::str#11 = display_info_rom::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [846] call printf_string
    // [1081] phi from display_info_rom::@2 to printf_string [phi:display_info_rom::@2->printf_string]
    // [1081] phi printf_string::str#12 = printf_string::str#11 [phi:display_info_rom::@2->printf_string#0] -- register_copy 
    // [1081] phi printf_string::format_min_length#12 = $19 [phi:display_info_rom::@2->printf_string#1] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [847] gotoxy::x#18 = display_info_rom::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [848] gotoxy::y#18 = display_info_rom::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [849] call gotoxy
    // [435] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#18 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#18 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [850] return 
    rts
  .segment Data
    s: .text "ROM"
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
// void display_info_cx16_rom(__zp($51) char info_status, __zp($52) char *info_text)
display_info_cx16_rom: {
    .label info_status = $51
    .label info_text = $52
    // display_info_rom(0, info_status, info_text)
    // [852] display_info_rom::info_status#0 = display_info_cx16_rom::info_status#4
    // [853] display_info_rom::info_text#0 = display_info_cx16_rom::info_text#4
    // [854] call display_info_rom
    // [808] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [808] phi display_info_rom::info_text#10 = display_info_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [808] phi display_info_rom::rom_chip#10 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z display_info_rom.rom_chip
    // [808] phi display_info_rom::info_status#10 = display_info_rom::info_status#0 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [855] return 
    rts
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
// void display_info_led(__zp($6f) char x, __zp($70) char y, __zp($5f) char tc, char bc)
display_info_led: {
    .label tc = $5f
    .label y = $70
    .label x = $6f
    // textcolor(tc)
    // [857] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [858] call textcolor
    // [417] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [417] phi textcolor::color#20 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [859] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [860] call bgcolor
    // [422] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [861] cputcxy::x#11 = display_info_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [862] cputcxy::y#11 = display_info_led::y#4 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [863] call cputcxy
    // [1111] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1111] phi cputcxy::c#13 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [1111] phi cputcxy::y#13 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [864] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [865] call textcolor
    // [417] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [866] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($4b) char *destination, char *source)
strcpy: {
    .label src = $46
    .label dst = $4b
    .label destination = $4b
    // [868] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [868] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [868] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [869] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [870] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [871] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [872] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [873] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [874] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
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
    .label screenlayer__0 = $4a
    .label screenlayer__1 = $45
    .label screenlayer__2 = $75
    .label screenlayer__5 = $6e
    .label screenlayer__6 = $6e
    .label screenlayer__7 = $6c
    .label screenlayer__8 = $6c
    .label screenlayer__9 = $66
    .label screenlayer__10 = $66
    .label screenlayer__11 = $66
    .label screenlayer__12 = $67
    .label screenlayer__13 = $67
    .label screenlayer__14 = $67
    .label screenlayer__16 = $6c
    .label screenlayer__17 = $59
    .label screenlayer__18 = $66
    .label screenlayer__19 = $67
    .label y = $55
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [875] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [876] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [877] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [878] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [879] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [880] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [881] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [882] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [883] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [884] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [885] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [886] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [887] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [888] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [889] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [890] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [891] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [892] screenlayer::$18 = (char)screenlayer::$9
    // [893] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [894] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [895] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [896] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [897] screenlayer::$19 = (char)screenlayer::$12
    // [898] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [899] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [900] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [901] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [902] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [902] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [902] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [903] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [904] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [905] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [906] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [907] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [908] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [902] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [902] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [902] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [909] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [910] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [911] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [912] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [913] call gotoxy
    // [435] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [435] phi gotoxy::y#19 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [435] phi gotoxy::x#19 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [914] return 
    rts
    // [915] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [916] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [917] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [918] call gotoxy
    // [435] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [919] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [920] call clearline
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
    // [921] cx16_k_screen_set_mode::error = 0 -- vbum1=vbuc1 
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
    // [923] return 
    rts
  .segment Data
    mode: .byte 0
    error: .byte 0
}
.segment Code
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $a9
    .label clrscr__1 = $71
    .label clrscr__2 = $74
    // unsigned int line_text = __conio.mapbase_offset
    // [924] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [925] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [926] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [927] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [928] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [929] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [929] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [929] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [930] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [931] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [932] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [933] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [934] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [935] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [935] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [936] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [937] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [938] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [939] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [940] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [941] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [942] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [943] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [944] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [945] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [946] return 
    rts
  .segment Data
    .label line_text = ch
    l: .byte 0
    ch: .word 0
    c: .byte 0
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
// void display_frame(char x0, char y0, __zp($6f) char x1, __zp($70) char y1)
display_frame: {
    .label w = $b5
    .label h = $40
    .label x = $6a
    .label y = $5b
    .label mask = $51
    .label c = $60
    .label x_1 = $6d
    .label y_1 = $65
    .label x1 = $6f
    .label y1 = $70
    // unsigned char w = x1 - x0
    // [948] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [949] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta.z h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [950] display_frame_maskxy::x#0 = display_frame::x#0
    // [951] display_frame_maskxy::y#0 = display_frame::y#0
    // [952] call display_frame_maskxy
    // [1327] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [1327] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [1327] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [953] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [954] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [955] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = display_frame_char(mask)
    // [956] display_frame_char::mask#0 = display_frame::mask#1
    // [957] call display_frame_char
  // Add a corner.
    // [1353] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [1353] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [958] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [959] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [960] cputcxy::x#0 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [961] cputcxy::y#0 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [962] cputcxy::c#0 = display_frame::c#0 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [963] call cputcxy
    // [1111] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [964] if(display_frame::w#0<2) goto display_frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [965] display_frame::x#1 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [966] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [966] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [967] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [968] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [968] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [969] display_frame_maskxy::x#1 = display_frame::x#24
    // [970] display_frame_maskxy::y#1 = display_frame::y#0
    // [971] call display_frame_maskxy
    // [1327] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [1327] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [1327] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [972] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [973] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [974] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [975] display_frame_char::mask#1 = display_frame::mask#3
    // [976] call display_frame_char
    // [1353] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [1353] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [977] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [978] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [979] cputcxy::x#1 = display_frame::x#24 -- vbum1=vbuz2 
    lda.z x_1
    sta cputcxy.x
    // [980] cputcxy::y#1 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [981] cputcxy::c#1 = display_frame::c#1 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [982] call cputcxy
    // [1111] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [983] if(display_frame::h#0<2) goto display_frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [984] display_frame::y#1 = ++ display_frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [985] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [985] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [986] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [987] display_frame_maskxy::x#5 = display_frame::x#0
    // [988] display_frame_maskxy::y#5 = display_frame::y#10
    // [989] call display_frame_maskxy
    // [1327] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [1327] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [1327] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [990] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [991] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [992] display_frame::mask#11 = display_frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [993] display_frame_char::mask#5 = display_frame::mask#11
    // [994] call display_frame_char
    // [1353] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [1353] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [995] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [996] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [997] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [998] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [999] cputcxy::c#5 = display_frame::c#5 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1000] call cputcxy
    // [1111] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1001] if(display_frame::w#0<2) goto display_frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1002] display_frame::x#4 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1003] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1003] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1004] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1005] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1005] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1006] display_frame_maskxy::x#6 = display_frame::x#15
    // [1007] display_frame_maskxy::y#6 = display_frame::y#10
    // [1008] call display_frame_maskxy
    // [1327] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [1327] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [1327] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1009] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1010] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1011] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1012] display_frame_char::mask#6 = display_frame::mask#13
    // [1013] call display_frame_char
    // [1353] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [1353] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1014] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1015] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1016] cputcxy::x#6 = display_frame::x#15 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1017] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1018] cputcxy::c#6 = display_frame::c#6 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1019] call cputcxy
    // [1111] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1020] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1021] display_frame_maskxy::x#7 = display_frame::x#18
    // [1022] display_frame_maskxy::y#7 = display_frame::y#10
    // [1023] call display_frame_maskxy
    // [1327] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [1327] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [1327] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1024] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1025] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1026] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1027] display_frame_char::mask#7 = display_frame::mask#15
    // [1028] call display_frame_char
    // [1353] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [1353] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1029] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1030] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1031] cputcxy::x#7 = display_frame::x#18 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1032] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1033] cputcxy::c#7 = display_frame::c#7 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1034] call cputcxy
    // [1111] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1035] display_frame::x#5 = ++ display_frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1036] display_frame_maskxy::x#3 = display_frame::x#0
    // [1037] display_frame_maskxy::y#3 = display_frame::y#10
    // [1038] call display_frame_maskxy
    // [1327] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [1327] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [1327] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1039] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1040] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1041] display_frame::mask#7 = display_frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1042] display_frame_char::mask#3 = display_frame::mask#7
    // [1043] call display_frame_char
    // [1353] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [1353] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1044] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1045] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1046] cputcxy::x#3 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1047] cputcxy::y#3 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1048] cputcxy::c#3 = display_frame::c#3 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1049] call cputcxy
    // [1111] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1050] display_frame_maskxy::x#4 = display_frame::x1#16
    // [1051] display_frame_maskxy::y#4 = display_frame::y#10
    // [1052] call display_frame_maskxy
    // [1327] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [1327] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [1327] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_2
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1053] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1054] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1055] display_frame::mask#9 = display_frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1056] display_frame_char::mask#4 = display_frame::mask#9
    // [1057] call display_frame_char
    // [1353] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [1353] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1058] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1059] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1060] cputcxy::x#4 = display_frame::x1#16 -- vbum1=vbuz2 
    lda.z x1
    sta cputcxy.x
    // [1061] cputcxy::y#4 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [1062] cputcxy::c#4 = display_frame::c#4 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1063] call cputcxy
    // [1111] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1064] display_frame::y#2 = ++ display_frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1065] display_frame_maskxy::x#2 = display_frame::x#10
    // [1066] display_frame_maskxy::y#2 = display_frame::y#0
    // [1067] call display_frame_maskxy
    // [1327] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [1327] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [1327] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1068] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1069] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1070] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1071] display_frame_char::mask#2 = display_frame::mask#5
    // [1072] call display_frame_char
    // [1353] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [1353] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1073] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1074] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1075] cputcxy::x#2 = display_frame::x#10 -- vbum1=vbuz2 
    lda.z x_1
    sta cputcxy.x
    // [1076] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1077] cputcxy::c#2 = display_frame::c#2 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1078] call cputcxy
    // [1111] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1079] display_frame::x#2 = ++ display_frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1080] display_frame::x#30 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($37) char *str, __mem() char format_min_length, char format_justify_left)
printf_string: {
    .label printf_string__9 = $61
    .label str = $37
    .label str_1 = $7b
    // if(format.min_length)
    // [1082] if(0==printf_string::format_min_length#12) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b1
    // printf_string::@3
    // strlen(str)
    // [1083] strlen::str#3 = printf_string::str#12 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1084] call strlen
    // [1368] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1368] phi strlen::str#6 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1085] strlen::return#4 = strlen::len#2
    // printf_string::@5
    // [1086] printf_string::$9 = strlen::return#4 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1087] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1088] printf_string::padding#1 = (signed char)printf_string::format_min_length#12 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1089] if(printf_string::padding#1>=0) goto printf_string::@7 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b2
    // [1091] phi from printf_string printf_string::@5 to printf_string::@1 [phi:printf_string/printf_string::@5->printf_string::@1]
  __b1:
    // [1091] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@5->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1090] phi from printf_string::@5 to printf_string::@7 [phi:printf_string::@5->printf_string::@7]
    // printf_string::@7
    // [1091] phi from printf_string::@7 to printf_string::@1 [phi:printf_string::@7->printf_string::@1]
    // [1091] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@7->printf_string::@1#0] -- register_copy 
    // printf_string::@1
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1092] printf_str::s#2 = printf_string::str#12
    // [1093] call printf_str
    // [723] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [723] phi printf_str::putc#21 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [723] phi printf_str::s#21 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@6
    // if(format.justify_left && padding)
    // [1094] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    rts
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1095] printf_padding::length#4 = (char)printf_string::padding#3
    // [1096] call printf_padding
    // [1374] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1374] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1374] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1374] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
    // }
    // [1097] return 
    rts
  .segment Data
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($3c) const char *s)
cputs: {
    .label s = $3c
    // [1099] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1099] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1100] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1101] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1102] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [1103] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1104] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1105] callexecute cputc  -- call_vprc1 
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
    // [1107] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [1108] return 
    rts
  .segment Data
    return: .byte 0
}
.segment Code
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [1109] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [1110] return 
    rts
  .segment Data
    return: .byte 0
}
.segment Code
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__mem() char x, __mem() char y, __mem() char c)
cputcxy: {
    // gotoxy(x, y)
    // [1112] gotoxy::x#0 = cputcxy::x#13 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1113] gotoxy::y#0 = cputcxy::y#13 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1114] call gotoxy
    // [435] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1115] stackpush(char) = cputcxy::c#13 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1116] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1118] return 
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
// void display_smc_led(__zp($5f) char c)
display_smc_led: {
    .label c = $5f
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1120] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1121] call display_chip_led
    // [1382] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [1382] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [1382] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [1382] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1122] display_info_led::tc#0 = display_smc_led::c#2
    // [1123] call display_info_led
    // [856] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [856] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [856] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [856] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1124] return 
    rts
}
  // display_print_chip
/**
 * @brief Print a full chip.
 * 
 * @param x Start X
 * @param y Start Y
 * @param w Width
 * @param text Vertical text to be displayed in the chip, starting from the top.
 */
// void display_print_chip(__zp($69) char x, char y, __zp($ae) char w, __zp($77) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $77
    .label text_1 = $7b
    .label x = $69
    .label text_2 = $4e
    .label text_3 = $61
    .label text_4 = $43
    .label text_5 = $63
    .label text_6 = $5d
    .label w = $ae
    // display_chip_line(x, y++, w, *text++)
    // [1126] display_chip_line::x#0 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1127] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1128] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_chip_line.c
    // [1129] call display_chip_line
    // [1400] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [1400] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [1400] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [1400] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2
    sta.z display_chip_line.y
    // [1400] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [1130] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [1131] display_chip_line::x#1 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1132] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1133] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_chip_line.c
    // [1134] call display_chip_line
    // [1400] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [1400] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [1400] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [1400] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z display_chip_line.y
    // [1400] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [1135] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [1136] display_chip_line::x#2 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1137] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1138] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_chip_line.c
    // [1139] call display_chip_line
    // [1400] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [1400] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [1400] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [1400] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z display_chip_line.y
    // [1400] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [1140] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [1141] display_chip_line::x#3 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1142] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1143] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z display_chip_line.c
    // [1144] call display_chip_line
    // [1400] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [1400] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [1400] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [1400] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z display_chip_line.y
    // [1400] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [1145] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [1146] display_chip_line::x#4 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1147] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1148] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z display_chip_line.c
    // [1149] call display_chip_line
    // [1400] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [1400] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [1400] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [1400] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z display_chip_line.y
    // [1400] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [1150] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [1151] display_chip_line::x#5 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1152] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1153] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z display_chip_line.c
    // [1154] call display_chip_line
    // [1400] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [1400] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [1400] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [1400] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z display_chip_line.y
    // [1400] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [1155] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [1156] display_chip_line::x#6 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1157] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1158] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [1159] call display_chip_line
    // [1400] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [1400] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [1400] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [1400] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [1400] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [1160] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [1161] display_chip_line::x#7 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1162] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1163] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [1164] call display_chip_line
    // [1400] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [1400] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [1400] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [1400] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [1400] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [1165] display_chip_end::x#0 = display_print_chip::x#10
    // [1166] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_end.w
    // [1167] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [1168] return 
    rts
}
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__zp($af) char c)
display_vera_led: {
    .label c = $af
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1170] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1171] call display_chip_led
    // [1382] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [1382] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [1382] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [1382] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1172] display_info_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1173] call display_info_led
    // [856] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [856] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [856] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [856] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [1174] return 
    rts
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($3c) char *source)
strcat: {
    .label strcat__0 = $48
    .label dst = $48
    .label src = $3c
    .label source = $3c
    // strlen(destination)
    // [1176] call strlen
    // [1368] phi from strcat to strlen [phi:strcat->strlen]
    // [1368] phi strlen::str#6 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1177] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1178] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [1179] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1180] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1180] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1180] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1181] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1182] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1183] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1184] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1185] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1186] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($79) char chip, __zp($aa) char c)
display_rom_led: {
    .label display_rom_led__0 = $42
    .label chip = $79
    .label c = $aa
    .label display_rom_led__7 = $42
    .label display_rom_led__8 = $42
    // chip*6
    // [1188] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z display_rom_led__7
    // [1189] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_rom_led__8
    clc
    adc.z chip
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1190] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1191] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_chip_led.x
    sta.z display_chip_led.x
    // [1192] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1193] call display_chip_led
    // [1382] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [1382] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [1382] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [1382] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1194] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [1195] display_info_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1196] call display_info_led
    // [856] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [856] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [856] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [856] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [1197] return 
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), unsigned int uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uint: {
    .const format_min_length = 0
    .const format_justify_left = 0
    .const format_zero_padding = 0
    .const format_upper_case = 0
    .label putc = cputc
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1199] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1200] call utoa
  // Format number into buffer
    // [1461] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1201] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1202] call printf_number_buffer
  // Print using format
    // [1248] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1248] phi printf_number_buffer::format_upper_case#10 = printf_uint::format_upper_case#0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbum1=vbuc1 
    lda #format_upper_case
    sta printf_number_buffer.format_upper_case
    // [1248] phi printf_number_buffer::putc#10 = printf_uint::putc#0 [phi:printf_uint::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [1248] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1248] phi printf_number_buffer::format_zero_padding#10 = printf_uint::format_zero_padding#0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbum1=vbuc1 
    lda #format_zero_padding
    sta printf_number_buffer.format_zero_padding
    // [1248] phi printf_number_buffer::format_justify_left#10 = printf_uint::format_justify_left#0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbum1=vbuc1 
    lda #format_justify_left
    sta printf_number_buffer.format_justify_left
    // [1248] phi printf_number_buffer::format_min_length#2 = printf_uint::format_min_length#0 [phi:printf_uint::@2->printf_number_buffer#5] -- vbum1=vbuc1 
    lda #format_min_length
    sta printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1203] return 
    rts
}
  // spi_get_jedec
spi_get_jedec: {
    // spi_fast()
    // [1205] call spi_fast
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
    // [1206] phi from spi_get_jedec to spi_get_jedec::@1 [phi:spi_get_jedec->spi_get_jedec::@1]
    // spi_get_jedec::@1
    // spi_select()
    // [1207] call spi_select
    // [1484] phi from spi_get_jedec::@1 to spi_select [phi:spi_get_jedec::@1->spi_select]
    jsr spi_select
    // spi_get_jedec::@2
    // spi_write(0x9F)
    // [1208] spi_write::data = $9f -- vbum1=vbuc1 
    lda #$9f
    sta spi_write.data
    // [1209] call spi_write
    jsr spi_write
    // [1210] phi from spi_get_jedec::@2 to spi_get_jedec::@3 [phi:spi_get_jedec::@2->spi_get_jedec::@3]
    // spi_get_jedec::@3
    // spi_read()
    // [1211] call spi_read
    jsr spi_read
    // [1212] spi_read::return#0 = spi_read::return#4 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_read.return
    // [1213] phi from spi_get_jedec::@3 to spi_get_jedec::@4 [phi:spi_get_jedec::@3->spi_get_jedec::@4]
    // spi_get_jedec::@4
    // spi_read()
    // [1214] call spi_read
    jsr spi_read
    // [1215] spi_read::return#1 = spi_read::return#4 -- vbum1=vbum2 
    lda spi_read.return_2
    sta spi_read.return_1
    // [1216] phi from spi_get_jedec::@4 to spi_get_jedec::@5 [phi:spi_get_jedec::@4->spi_get_jedec::@5]
    // spi_get_jedec::@5
    // spi_read()
    // [1217] call spi_read
    jsr spi_read
    // [1218] spi_read::return#2 = spi_read::return#4
    // spi_get_jedec::@return
    // }
    // [1219] return 
    rts
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__mem() char value, __zp($35) char *buffer, __mem() char radix)
uctoa: {
    .label uctoa__4 = $40
    .label buffer = $35
    .label digit_values = $4e
    // if(radix==DECIMAL)
    // [1220] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1221] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1222] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1223] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1224] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1225] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1226] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1227] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1228] return 
    rts
    // [1229] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1229] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1229] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1229] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1229] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1229] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [1229] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1229] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1229] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [1229] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1229] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1229] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [1230] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1230] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1230] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1230] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1230] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1231] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1232] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1233] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1234] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1235] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1236] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [1237] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [1238] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [1239] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1239] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1239] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1239] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1240] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1230] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1230] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1230] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1230] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1230] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1241] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1242] uctoa_append::value#0 = uctoa::value#2
    // [1243] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1244] call uctoa_append
    // [1495] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1245] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1246] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1247] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1239] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1239] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1239] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1239] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
// void printf_number_buffer(__zp($72) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, __mem() char format_justify_left, char format_sign_always, __mem() char format_zero_padding, __mem() char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $63
    .label putc = $72
    // if(format.min_length)
    // [1249] if(0==printf_number_buffer::format_min_length#2) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b6
    // [1250] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [1251] call strlen
    // [1368] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [1368] phi strlen::str#6 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1252] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@14
    // [1253] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [1254] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [1255] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [1256] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1257] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [1257] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [1258] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#2 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1259] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1261] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [1261] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1260] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [1261] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [1261] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1262] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [1263] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [1264] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [1265] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1266] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1267] call printf_padding
    // [1374] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1374] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1374] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@8->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1374] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1268] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [1269] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1270] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall7
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1272] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [1273] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [1274] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1275] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1276] call printf_padding
    // [1374] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1374] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1374] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@10->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [1374] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [1277] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbum1_then_la1 
    lda format_upper_case
    beq __b5
    // [1278] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [1279] call strupr
    // [1502] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [1280] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1281] call printf_str
    // [723] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [723] phi printf_str::putc#21 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [723] phi printf_str::s#21 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [1282] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [1283] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [1284] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [1285] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1286] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1287] call printf_padding
    // [1374] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1374] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1374] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@12->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1374] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [1288] return 
    rts
    // Outside Flow
  icall7:
    jmp (putc)
  .segment Data
    buffer_sign: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
    len: .byte 0
    .label padding = len
    format_justify_left: .byte 0
    format_upper_case: .byte 0
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
    // [1289] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1291] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [1292] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1293] return 
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
    .label insertup__0 = $30
    .label insertup__4 = $29
    .label insertup__6 = $2a
    .label insertup__7 = $29
    // __conio.width+1
    // [1294] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [1295] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [1296] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1296] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1297] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [1298] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1299] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1300] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1301] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1302] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [1303] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [1304] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [1305] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [1306] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [1307] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [1308] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [1309] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1310] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [1296] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1296] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [1311] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [1312] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1313] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1314] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1315] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1316] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1317] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1318] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1319] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1320] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1321] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1321] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1322] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1323] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1324] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1325] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1326] return 
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
// __zp($51) char display_frame_maskxy(__zp($6a) char x, __zp($5b) char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $58
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $4d
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $57
    .label c = $54
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
    .label return = $51
    .label x = $6a
    .label y = $5b
    .label x_1 = $6d
    .label y_1 = $65
    .label x_2 = $6f
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [1328] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [1329] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [1330] call gotoxy
    // [435] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1331] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [1332] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [1333] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [1334] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1335] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1336] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1337] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1338] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1339] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1340] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1341] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1342] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1343] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1344] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1345] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1346] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1347] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1348] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1349] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [1351] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [1351] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [1350] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [1351] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [1351] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [1351] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [1351] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [1351] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [1351] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [1351] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [1351] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [1351] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [1351] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [1351] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [1351] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [1351] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // display_frame_maskxy::@return
    // }
    // [1352] return 
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
// __zp($60) char display_frame_char(__zp($51) char mask)
display_frame_char: {
    .label return = $60
    .label mask = $51
    // case 0b0110:
    //             return 0x70;
    // [1354] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1355] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1356] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1357] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1358] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1359] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1360] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1361] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1362] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1363] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1364] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [1366] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [1366] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [1365] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [1366] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [1366] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [1366] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [1366] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [1366] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [1366] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [1366] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [1366] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [1366] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [1366] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [1366] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [1366] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [1366] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [1366] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [1366] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [1366] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [1366] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [1366] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [1366] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [1366] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [1366] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [1366] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // display_frame_char::@return
    // }
    // [1367] return 
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($35) char *str)
strlen: {
    .label str = $35
    // [1369] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1369] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [1369] phi strlen::str#4 = strlen::str#6 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1370] if(0!=*strlen::str#4) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1371] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1372] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [1373] strlen::str#1 = ++ strlen::str#4 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1369] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1369] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1369] phi strlen::str#4 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($39) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $39
    // [1375] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1375] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1376] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [1377] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1378] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [1379] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall8
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1381] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1375] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1375] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall8:
    jmp (putc)
  .segment Data
    i: .byte 0
    .label length = printf_string.format_min_length
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
// void display_chip_led(__zp($42) char x, char y, __zp($41) char w, __zp($5b) char tc, char bc)
display_chip_led: {
    .label x = $42
    .label w = $41
    .label tc = $5b
    // textcolor(tc)
    // [1383] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [1384] call textcolor
    // [417] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [417] phi textcolor::color#20 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1385] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [1386] call bgcolor
    // [422] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [1387] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [1387] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [1387] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [1388] cputcxy::x#9 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1389] call cputcxy
    // [1111] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1111] phi cputcxy::c#13 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [1111] phi cputcxy::y#13 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [1111] phi cputcxy::x#13 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [1390] cputcxy::x#10 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1391] call cputcxy
    // [1111] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1111] phi cputcxy::c#13 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [1111] phi cputcxy::y#13 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [1111] phi cputcxy::x#13 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [1392] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [1393] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [1394] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [1395] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [1396] call textcolor
    // [417] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1397] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [1398] call bgcolor
    // [422] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [1399] return 
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
// void display_chip_line(__zp($68) char x, __zp($7a) char y, __zp($50) char w, __zp($5a) char c)
display_chip_line: {
    .label i = $3f
    .label x = $68
    .label w = $50
    .label c = $5a
    .label y = $7a
    // gotoxy(x, y)
    // [1401] gotoxy::x#7 = display_chip_line::x#16 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1402] gotoxy::y#7 = display_chip_line::y#16 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1403] call gotoxy
    // [435] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [435] phi gotoxy::y#19 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [435] phi gotoxy::x#19 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1404] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [1405] call textcolor
    // [417] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [417] phi textcolor::color#20 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1406] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [1407] call bgcolor
    // [422] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1408] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1409] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1411] call textcolor
    // [417] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1412] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [1413] call bgcolor
    // [422] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [422] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [1414] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [1414] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1415] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1416] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [1417] call textcolor
    // [417] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [417] phi textcolor::color#20 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1418] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [1419] call bgcolor
    // [422] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [1420] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1421] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1423] call textcolor
    // [417] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [417] phi textcolor::color#20 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1424] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [1425] call bgcolor
    // [422] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [422] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [1426] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbum1=vbuz2_plus_2 
    lda.z x
    clc
    adc #2
    sta cputcxy.x
    // [1427] cputcxy::y#8 = display_chip_line::y#16 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1428] cputcxy::c#8 = display_chip_line::c#15 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1429] call cputcxy
    // [1111] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1111] phi cputcxy::c#13 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1111] phi cputcxy::y#13 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1111] phi cputcxy::x#13 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [1430] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [1431] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1432] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1434] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1414] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [1414] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
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
// void display_chip_end(__zp($69) char x, char y, __zp($4d) char w)
display_chip_end: {
    .label i = $3e
    .label x = $69
    .label w = $4d
    // gotoxy(x, y)
    // [1435] gotoxy::x#8 = display_chip_end::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1436] call gotoxy
    // [435] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [435] phi gotoxy::y#19 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [435] phi gotoxy::x#19 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1437] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [1438] call textcolor
    // [417] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [417] phi textcolor::color#20 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1439] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [1440] call bgcolor
    // [422] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [1441] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1442] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1444] call textcolor
    // [417] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [417] phi textcolor::color#20 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [1445] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [1446] call bgcolor
    // [422] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [422] phi bgcolor::color#14 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [1447] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [1447] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1448] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1449] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [1450] call textcolor
    // [417] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [417] phi textcolor::color#20 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1451] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [1452] call bgcolor
    // [422] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [422] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [1453] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1454] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [1456] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [1457] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1458] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1460] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1447] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [1447] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
    jmp __b1
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($52) char *buffer, char radix)
utoa: {
    .const max_digits = 5
    .label utoa__10 = $54
    .label utoa__11 = $57
    .label buffer = $52
    // [1462] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
    // [1462] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa->utoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1462] phi utoa::started#2 = 0 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1462] phi utoa::value#2 = smc_bootloader [phi:utoa->utoa::@1#2] -- vwum1=vwuc1 
    lda #<smc_bootloader
    sta value
    lda #>smc_bootloader
    sta value+1
    // [1462] phi utoa::digit#2 = 0 [phi:utoa->utoa::@1#3] -- vbum1=vbuc1 
    lda #0
    sta digit
    // utoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1463] if(utoa::digit#2<utoa::max_digits#1-1) goto utoa::@2 -- vbum1_lt_vbuc1_then_la1 
    lda digit
    cmp #max_digits-1
    bcc __b2
    // utoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1464] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [1465] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1466] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1467] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // utoa::@return
    // }
    // [1468] return 
    rts
    // utoa::@2
  __b2:
    // unsigned int digit_value = digit_values[digit]
    // [1469] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [1470] utoa::digit_value#0 = RADIX_DECIMAL_VALUES[utoa::$10] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda RADIX_DECIMAL_VALUES,y
    sta digit_value
    lda RADIX_DECIMAL_VALUES+1,y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1471] if(0!=utoa::started#2) goto utoa::@5 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b5
    // utoa::@7
    // [1472] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@5 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b5
  !:
    bcc __b5
    // [1473] phi from utoa::@7 to utoa::@4 [phi:utoa::@7->utoa::@4]
    // [1473] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@7->utoa::@4#0] -- register_copy 
    // [1473] phi utoa::started#4 = utoa::started#2 [phi:utoa::@7->utoa::@4#1] -- register_copy 
    // [1473] phi utoa::value#6 = utoa::value#2 [phi:utoa::@7->utoa::@4#2] -- register_copy 
    // utoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1474] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1462] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
    // [1462] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@4->utoa::@1#0] -- register_copy 
    // [1462] phi utoa::started#2 = utoa::started#4 [phi:utoa::@4->utoa::@1#1] -- register_copy 
    // [1462] phi utoa::value#2 = utoa::value#6 [phi:utoa::@4->utoa::@1#2] -- register_copy 
    // [1462] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@4->utoa::@1#3] -- register_copy 
    jmp __b1
    // utoa::@5
  __b5:
    // utoa_append(buffer++, value, digit_value)
    // [1475] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1476] utoa_append::value#0 = utoa::value#2
    // [1477] utoa_append::sub#0 = utoa::digit_value#0
    // [1478] call utoa_append
    // [1532] phi from utoa::@5 to utoa_append [phi:utoa::@5->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1479] utoa_append::return#0 = utoa_append::value#2
    // utoa::@6
    // value = utoa_append(buffer++, value, digit_value)
    // [1480] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1481] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1473] phi from utoa::@6 to utoa::@4 [phi:utoa::@6->utoa::@4]
    // [1473] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@6->utoa::@4#0] -- register_copy 
    // [1473] phi utoa::started#4 = 1 [phi:utoa::@6->utoa::@4#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1473] phi utoa::value#6 = utoa::value#0 [phi:utoa::@6->utoa::@4#2] -- register_copy 
    jmp __b4
  .segment Data
    digit_value: .word 0
    digit: .byte 0
    value: .word 0
    started: .byte 0
}
.segment Code
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
    // [1483] return 
    rts
}
  // spi_select
spi_select: {
    // spi_deselect()
    // [1485] call spi_deselect
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
    // [1486] *vera_reg_SPICtrl = *vera_reg_SPICtrl | 1 -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #1
    ora vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // spi_select::@return
    // }
    // [1487] return 
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
    // [1489] return 
    rts
  .segment Data
    data: .byte 0
}
.segment Code
  // spi_read
spi_read: {
    // unsigned char SPIData
    // [1490] spi_read::SPIData = 0 -- vbum1=vbuc1 
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
    // [1492] spi_read::return#3 = spi_read::SPIData -- vbum1=vbum2 
    sta return_2
    // spi_read::@return
    // }
    // [1493] spi_read::return#4 = spi_read::return#3
    // [1494] return 
    rts
  .segment Data
    SPIData: .byte 0
    return: .byte 0
    return_1: .byte 0
    return_2: .byte 0
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
    // [1496] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1496] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1496] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1497] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1498] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1499] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1500] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1501] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [1496] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1496] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1496] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uchar.uvalue
    .label sub = uctoa.digit_value
    .label return = printf_uchar.uvalue
    digit: .byte 0
}
.segment Code
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label strupr__0 = $3b
    .label src = $39
    // [1503] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1503] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1504] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1505] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1506] toupper::ch#0 = *strupr::src#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta toupper.ch
    // [1507] call toupper
    jsr toupper
    // [1508] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1509] strupr::$0 = toupper::return#3 -- vbuz1=vbum2 
    lda toupper.return
    sta.z strupr__0
    // *src = toupper(*src)
    // [1510] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbuz2 
    ldy #0
    sta (src),y
    // src++;
    // [1511] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1503] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1503] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
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
// void memcpy8_vram_vram(__mem() char dbank_vram, __mem() unsigned int doffset_vram, __mem() char sbank_vram, __mem() unsigned int soffset_vram, __mem() char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $23
    .label memcpy8_vram_vram__1 = $24
    .label memcpy8_vram_vram__2 = $25
    .label memcpy8_vram_vram__3 = $26
    .label memcpy8_vram_vram__4 = $27
    .label memcpy8_vram_vram__5 = $28
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1512] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1513] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1514] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1515] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1516] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1517] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1518] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1519] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1520] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1521] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1522] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1523] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1524] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1525] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1526] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1526] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1527] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [1528] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1529] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1530] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1531] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
// __mem() unsigned int utoa_append(__zp($5d) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $5d
    // [1533] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1533] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1533] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1534] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [1535] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1536] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1537] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1538] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [1533] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1533] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1533] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = utoa.value
    .label sub = utoa.digit_value
    .label return = utoa.value
    digit: .byte 0
}
.segment Code
  // spi_deselect
spi_deselect: {
    // *vera_reg_SPICtrl &= 0xfe
    // [1539] *vera_reg_SPICtrl = *vera_reg_SPICtrl & $fe -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
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
    // [1540] call spi_read
    jsr spi_read
    // spi_deselect::@return
    // }
    // [1541] return 
    rts
}
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __mem() char toupper(__mem() char ch)
toupper: {
    // if(ch>='a' && ch<='z')
    // [1542] if(toupper::ch#0<'a') goto toupper::@return -- vbum1_lt_vbuc1_then_la1 
    lda ch
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1543] if(toupper::ch#0<='z') goto toupper::@1 -- vbum1_le_vbuc1_then_la1 
    lda #'z'
    cmp ch
    bcs __b1
    // [1545] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1545] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1544] toupper::return#0 = toupper::ch#0 + 'A'-'a' -- vbum1=vbum1_plus_vbuc1 
    lda #'A'-'a'
    clc
    adc return
    sta return
    // toupper::@return
  __breturn:
    // }
    // [1546] return 
    rts
  .segment Data
    return: .byte 0
    .label ch = return
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
  // Values of decimal digits
  RADIX_DECIMAL_VALUES: .word $2710, $3e8, $64, $a
  info_text: .fill $50, 0
  status_text: .word __3, __4, __5, __6, __7, __8, __9, __10, __11, __12, __13
  status_color: .byte BLACK, GREY, WHITE, CYAN, PURPLE, CYAN, PURPLE, PURPLE, GREEN, YELLOW, RED
  status_rom: .byte 0
  .fill 7, 0
  display_into_briefing_text: .word __14, __15, __75, __17, __18, __19, __20, __21, __22, __75, __24, __25, __75, __27, __28
  display_into_colors_text: .word __29, __30, __75, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, __42, __75, __44
  display_smc_rom_issue_text: .word __45, __75, __55, __48, __75, __50, __51, __52
  display_smc_unsupported_rom_text: .word __53, __75, __55, __56, __75, __58, __59
  display_debriefing_text_smc: .word __74, __75, main.text, __75, __64, __65, __66, __75, __68, __75, __70, __71, __72, __73
  display_debriefing_text_rom: .word __74, __75, __76, __77
  smc_file_header: .fill $20, 0
  smc_version_text: .fill $10, 0
  rom_device_names: .word 0
  .fill 2*7, 0
  rom_size_strings: .word 0
  .fill 2*7, 0
  rom_release_text: .fill 8*$d, 0
  rom_release: .fill 8, 0
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
  __14: .text "Welcome to the CX16 update tool! This program updates the"
  .byte 0
  __15: .text "chipsets on your CX16 and ROM expansion boards."
  .byte 0
  __17: .text "Depending on the files found on the SDCard, various"
  .byte 0
  __18: .text "components will be updated:"
  .byte 0
  __19: .text "- Mandatory: SMC.BIN for the SMC firmware."
  .byte 0
  __20: .text "- Mandatory: ROM.BIN for the main ROM."
  .byte 0
  __21: .text "- Optional: VERA.BIN for the VERA firmware."
  .byte 0
  __22: .text "- Optional: ROMn.BIN for a ROM expansion board or cartridge."
  .byte 0
  __24: .text "  Important: Ensure J1 write-enable jumper is closed"
  .byte 0
  __25: .text "  on both the main board and any ROM expansion board."
  .byte 0
  __27: .text "Please carefully read the step-by-step instructions at "
  .byte 0
  __28: .text "https://flightcontrol-user.github.io/x16-flash"
  .byte 0
  __29: .text "The panels above indicate the update progress,"
  .byte 0
  __30: .text "using status indicators and colors as specified below:"
  .byte 0
  __32: .text " -   None       Not detected, no action."
  .byte 0
  __33: .text " -   Skipped    Detected, but no action, eg. no file."
  .byte 0
  __34: .text " -   Detected   Detected, verification pending."
  .byte 0
  __35: .text " -   Checking   Verifying size of the update file."
  .byte 0
  __36: .text " -   Reading    Reading the update file into RAM."
  .byte 0
  __37: .text " -   Comparing  Comparing the RAM with the ROM."
  .byte 0
  __38: .text " -   Update     Ready to update the firmware."
  .byte 0
  __39: .text " -   Updating   Updating the firmware."
  .byte 0
  __40: .text " -   Updated    Updated the firmware succesfully."
  .byte 0
  __41: .text " -   Issue      Problem identified during update."
  .byte 0
  __42: .text " -   Error      Error found during update."
  .byte 0
  __44: .text "Errors can indicate J1 jumpers are not closed!"
  .byte 0
  __45: .text "There is an issue with the CX16 SMC or ROM flash readiness."
  .byte 0
  __48: .text "to avoid possible conflicts of firmware, bricking your CX16."
  .byte 0
  __50: .text "Therefore, ensure you have the correct SMC.BIN and ROM.BIN"
  .byte 0
  __51: .text "files placed on your SDcard. Also ensure that the"
  .byte 0
  __52: .text "J1 jumper pins on the CX16 board are closed."
  .byte 0
  __53: .text "There is an issue with the CX16 SMC or ROM flash versions."
  .byte 0
  __55: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __56: .text "to avoid possible conflicts, risking bricking your CX16."
  .byte 0
  __58: .text "The SMC.BIN and ROM.BIN found on your SDCard may not be"
  .byte 0
  __59: .text "mutually compatible. Update the CX16 at your own risk!"
  .byte 0
  __64: .text "Because your SMC chipset has been updated,"
  .byte 0
  __65: .text "the restart process differs, depending on the"
  .byte 0
  __66: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __68: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __70: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __71: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __72: .text "  The power-off button won't work!"
  .byte 0
  __73: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __74: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __75: .text ""
  .byte 0
  __76: .text "Since your CX16 system SMC chip has not been updated"
  .byte 0
  __77: .text "your CX16 will just reset automatically after count down."
  .byte 0
  s3: .text " "
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
  // Globals
  status_smc: .byte 0
  status_vera: .byte 0
  spi_manufacturer: .byte 0
  spi_memory_type: .byte 0
  spi_memory_capacity: .byte 0
