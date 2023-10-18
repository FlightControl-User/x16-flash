  // File Comments
/**
 * @file cx16-checksum.c
 * 
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program.
 * 
 * @brief COMMANDER X16 UPDATE TOOL CHECKSUM VALIDATOR
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */
  // Upstart
.cpu _65c02
  // Commander X16 PRG executable file
.file [name="cx16-checksum.prg", type="prg", segments="Program"]
.segmentdef Program [segments="Basic, Code, Data"]
.segmentdef Basic [start=$0801]
.segmentdef Code [start=$80d]
.segmentdef Data [startAfter="Code"]
.segment Basic
:BasicUpstart(__start)

  // Global Constants & labels
  .const WHITE = 1
  .const BLUE = 6
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
  .const VERA_INC_1 = $10
  .const VERA_DCSEL = 2
  .const VERA_ADDRSEL = 1
  .const VERA_SPRITES_ENABLE = $40
  .const VERA_LAYER1_ENABLE = $20
  .const VERA_LAYER0_ENABLE = $10
  .const VERA_LAYER_WIDTH_MASK = $30
  .const VERA_LAYER_HEIGHT_MASK = $c0
  .const OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS = 1
  .const STACK_BASE = $103
  .const SIZEOF_STRUCT___1 = $8f
  .const SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER = $c
  .const SIZEOF_STRUCT___2 = $90
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
    jsr main
    // __start::@return
    // [7] return 
    rts
}
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    .label conio_x16_init__4 = $69
    .label conio_x16_init__5 = $65
    .label conio_x16_init__6 = $69
    .label conio_x16_init__7 = $b5
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
    lda.z conio_x16_init__4+1
    sta.z conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [21] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
    sta __conio
    // cbm_k_plot_get()
    // [22] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [23] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [24] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [25] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuz1=_byte0_vwuz2 
    lda.z conio_x16_init__6
    sta.z conio_x16_init__7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [26] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbuz1 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [27] gotoxy::x#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z gotoxy.x
    // [28] gotoxy::y#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z gotoxy.y
    // [29] call gotoxy
    // [133] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [133] phi gotoxy::y#3 = gotoxy::y#0 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [133] phi gotoxy::x#3 = gotoxy::x#0 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
// void cputc(__zp($33) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $66
    .label cputc__3 = $67
    .label c = $33
    // [33] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
    // if(c=='\n')
    // [34] if(cputc::c#0==' ') goto cputc::@1 -- vbuz1_eq_vbuc1_then_la1 
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
    sta.z cputc__1
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [37] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [38] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cputc__2
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [39] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [40] cputc::$3 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z cputc__3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [41] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [42] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuz1 
    lda.z c
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
    rts
    // cputc::@5
  __b5:
    // if(__conio.cursor_x >= __conio.width)
    // [52] if(*((char *)&__conio)>=*((char *)&__conio+6)) goto cputc::@7 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+6
    bcs __b7
    // cputc::@8
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
    // [56] phi from cputc::@5 to cputc::@7 [phi:cputc::@5->cputc::@7]
    // cputc::@7
  __b7:
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
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label cx16_k_screen_set_charset1_charset = $b9
    .label cx16_k_screen_set_charset1_offset = $b6
    // cx16_k_screen_set_mode(0)
    // [60] cx16_k_screen_set_mode::mode = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_screen_set_mode.mode
    // [61] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [62] phi from main to main::@2 [phi:main->main::@2]
    // main::@2
    // screenlayer1()
    // [63] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // main::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [64] main::cx16_k_screen_set_charset1_charset = 3 -- vbuz1=vbuc1 
    lda #3
    sta.z cx16_k_screen_set_charset1_charset
    // [65] main::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cx16_k_screen_set_charset1_offset
    sta.z cx16_k_screen_set_charset1_offset+1
    // main::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // main::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [67] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [68] *VERA_DC_HSTART = main::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // main::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [69] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [70] *VERA_DC_HSTOP = main::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // main::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [71] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [72] *VERA_DC_VSTART = main::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // main::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [73] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [74] *VERA_DC_VSTOP = main::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // main::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [75] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [76] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // main::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [77] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [78] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // main::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [79] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [80] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [81] phi from main::vera_layer1_show1 to main::@1 [phi:main::vera_layer1_show1->main::@1]
    // main::@1
    // textcolor(WHITE)
    // [82] call textcolor
    // Layer 1 is the current text canvas.
    jsr textcolor
    // [83] phi from main::@1 to main::@4 [phi:main::@1->main::@4]
    // main::@4
    // bgcolor(BLUE)
    // [84] call bgcolor
    // Default text color is white.
    jsr bgcolor
    // [85] phi from main::@4 to main::@5 [phi:main::@4->main::@5]
    // main::@5
    // clrscr()
    // [86] call clrscr
    // With a blue background.
    jsr clrscr
    // [87] phi from main::@5 to main::@6 [phi:main::@5->main::@6]
    // main::@6
    // printf("\n\n\n\nCommander X16 checksum calculator and validator of .BIN files.\n\n")
    // [88] call printf_str
    // [180] phi from main::@6 to printf_str [phi:main::@6->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:main::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = main::s [phi:main::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [89] phi from main::@6 to main::@7 [phi:main::@6->main::@7]
    // main::@7
    // rom_calc_file_checksum(1)
    // [90] call rom_calc_file_checksum
    // [189] phi from main::@7 to rom_calc_file_checksum [phi:main::@7->rom_calc_file_checksum]
    jsr rom_calc_file_checksum
    // [91] phi from main::@7 to main::@8 [phi:main::@7->main::@8]
    // main::@8
    // printf("ROM-R45.BIN size    : %x\n", rom_file_size)
    // [92] call printf_str
    // [180] phi from main::@8 to printf_str [phi:main::@8->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:main::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = main::s1 [phi:main::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@9
    // printf("ROM-R45.BIN size    : %x\n", rom_file_size)
    // [93] printf_ulong::uvalue#0 = rom_file_size#10 -- vduz1=vdum2 
    lda rom_file_size
    sta.z printf_ulong.uvalue
    lda rom_file_size+1
    sta.z printf_ulong.uvalue+1
    lda rom_file_size+2
    sta.z printf_ulong.uvalue+2
    lda rom_file_size+3
    sta.z printf_ulong.uvalue+3
    // [94] call printf_ulong
    // [220] phi from main::@9 to printf_ulong [phi:main::@9->printf_ulong]
    // [220] phi printf_ulong::uvalue#3 = printf_ulong::uvalue#0 [phi:main::@9->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [95] phi from main::@9 to main::@10 [phi:main::@9->main::@10]
    // main::@10
    // printf("ROM-R45.BIN size    : %x\n", rom_file_size)
    // [96] call printf_str
    // [180] phi from main::@10 to printf_str [phi:main::@10->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:main::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = main::s2 [phi:main::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [97] phi from main::@10 to main::@11 [phi:main::@10->main::@11]
    // main::@11
    // printf("\nROM-R45.BIN checksum: %x\n", rom_file_checksum)
    // [98] call printf_str
    // [180] phi from main::@11 to printf_str [phi:main::@11->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:main::@11->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = main::s3 [phi:main::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@12
    // printf("\nROM-R45.BIN checksum: %x\n", rom_file_checksum)
    // [99] printf_ulong::uvalue#1 = rom_file_checksum#16 -- vduz1=vdum2 
    lda rom_file_checksum
    sta.z printf_ulong.uvalue
    lda rom_file_checksum+1
    sta.z printf_ulong.uvalue+1
    lda rom_file_checksum+2
    sta.z printf_ulong.uvalue+2
    lda rom_file_checksum+3
    sta.z printf_ulong.uvalue+3
    // [100] call printf_ulong
    // [220] phi from main::@12 to printf_ulong [phi:main::@12->printf_ulong]
    // [220] phi printf_ulong::uvalue#3 = printf_ulong::uvalue#1 [phi:main::@12->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [101] phi from main::@12 to main::@13 [phi:main::@12->main::@13]
    // main::@13
    // printf("\nROM-R45.BIN checksum: %x\n", rom_file_checksum)
    // [102] call printf_str
    // [180] phi from main::@13 to printf_str [phi:main::@13->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:main::@13->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = main::s2 [phi:main::@13->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [103] phi from main::@13 to main::@14 [phi:main::@13->main::@14]
    // main::@14
    // rom_calc_rom_checksum()
    // [104] call rom_calc_rom_checksum
    // [227] phi from main::@14 to rom_calc_rom_checksum [phi:main::@14->rom_calc_rom_checksum]
    jsr rom_calc_rom_checksum
    // [105] phi from main::@14 to main::@15 [phi:main::@14->main::@15]
    // main::@15
    // printf("ROM         checksum: %x\n", rom_checksum)
    // [106] call printf_str
    // [180] phi from main::@15 to printf_str [phi:main::@15->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:main::@15->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = main::s5 [phi:main::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@16
    // printf("ROM         checksum: %x\n", rom_checksum)
    // [107] printf_ulong::uvalue#2 = rom_checksum#1 -- vduz1=vdum2 
    lda rom_checksum
    sta.z printf_ulong.uvalue
    lda rom_checksum+1
    sta.z printf_ulong.uvalue+1
    lda rom_checksum+2
    sta.z printf_ulong.uvalue+2
    lda rom_checksum+3
    sta.z printf_ulong.uvalue+3
    // [108] call printf_ulong
    // [220] phi from main::@16 to printf_ulong [phi:main::@16->printf_ulong]
    // [220] phi printf_ulong::uvalue#3 = printf_ulong::uvalue#2 [phi:main::@16->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [109] phi from main::@16 to main::@17 [phi:main::@16->main::@17]
    // main::@17
    // printf("ROM         checksum: %x\n", rom_checksum)
    // [110] call printf_str
    // [180] phi from main::@17 to printf_str [phi:main::@17->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:main::@17->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = main::s2 [phi:main::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::bank_set_bram1
    // BRAM = bank
    // [111] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::bank_set_brom1
    // BROM = bank
    // [112] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // main::@return
    // }
    // [113] return 
    rts
  .segment Data
    s: .text @"\n\n\n\nCommander X16 checksum calculator and validator of .BIN files.\n\n"
    .byte 0
    s1: .text "ROM-R45.BIN size    : "
    .byte 0
    s2: .text @"\n"
    .byte 0
    s3: .text @"\nROM-R45.BIN checksum: "
    .byte 0
    s5: .text "ROM         checksum: "
    .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [114] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [115] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [116] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [117] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(char color)
textcolor: {
    .label textcolor__0 = $7c
    .label textcolor__1 = $7c
    // __conio.color & 0xF0
    // [118] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [119] textcolor::$1 = textcolor::$0 | WHITE -- vbuz1=vbuz1_bor_vbuc1 
    lda #WHITE
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [120] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [121] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(char color)
bgcolor: {
    .label bgcolor__0 = $78
    .label bgcolor__2 = $78
    // __conio.color & 0x0F
    // [122] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // __conio.color & 0x0F | color << 4
    // [123] bgcolor::$2 = bgcolor::$0 | BLUE<<4 -- vbuz1=vbuz1_bor_vbuc1 
    lda #BLUE<<4
    ora.z bgcolor__2
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [124] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [125] return 
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
    // [126] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [127] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $69
    // __mem unsigned char x
    // [128] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [129] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [131] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [132] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($3c) char x, __zp($46) char y)
gotoxy: {
    .label gotoxy__2 = $3c
    .label gotoxy__3 = $3c
    .label gotoxy__6 = $3a
    .label gotoxy__7 = $3a
    .label gotoxy__8 = $4a
    .label gotoxy__9 = $48
    .label gotoxy__10 = $46
    .label x = $3c
    .label y = $46
    .label gotoxy__14 = $3a
    // (x>=__conio.width)?__conio.width:x
    // [134] if(gotoxy::x#3>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [136] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [136] phi gotoxy::$3 = gotoxy::x#3 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [135] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [137] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [138] if(gotoxy::y#3>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [139] gotoxy::$14 = gotoxy::y#3 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [140] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [140] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [141] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [142] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [143] gotoxy::$10 = gotoxy::y#3 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [144] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [145] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [146] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [147] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $5b
    // __conio.cursor_x = 0
    // [148] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [149] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [150] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [151] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [152] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [153] return 
    rts
}
  // cx16_k_screen_set_mode
/**
 * @brief Sets the screen mode.
 *
 * @return cx16_k_screen_mode_error_t Contains 1 if there is an error.
 */
// char cx16_k_screen_set_mode(__zp($b8) volatile char mode)
cx16_k_screen_set_mode: {
    .label mode = $b8
    .label error = $b4
    // cx16_k_screen_mode_error_t error = 0
    // [154] cx16_k_screen_set_mode::error = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z error
    // asm
    // asm { clc ldamode jsrCX16_SCREEN_MODE rolerror  }
    clc
    lda mode
    jsr CX16_SCREEN_MODE
    rol error
    // cx16_k_screen_set_mode::@return
    // }
    // [156] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $4f
    .label clrscr__1 = $54
    .label clrscr__2 = $32
    .label line_text = $63
    .label l = $60
    .label ch = $63
    .label c = $5d
    // unsigned int line_text = __conio.mapbase_offset
    // [157] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [158] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [159] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [160] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [161] clrscr::l#0 = *((char *)&__conio+9) -- vbuz1=_deref_pbuc1 
    lda __conio+9
    sta.z l
    // [162] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [162] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [162] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [163] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [164] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [165] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [166] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [167] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta.z c
    // [168] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [168] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [169] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [170] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [171] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [172] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [173] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [174] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [175] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [176] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [177] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [178] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [179] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($63) void (*putc)(char), __zp($59) const char *s)
printf_str: {
    .label c = $39
    .label s = $59
    .label putc = $63
    // [181] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [181] phi printf_str::s#12 = printf_str::s#13 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [182] printf_str::c#1 = *printf_str::s#12 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [183] printf_str::s#0 = ++ printf_str::s#12 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [184] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [185] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [186] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [187] callexecute *printf_str::putc#13  -- call__deref_pprz1 
    jsr icall1
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall1:
    jmp (putc)
}
  // rom_calc_file_checksum
// void rom_calc_file_checksum(char rom_chip)
rom_calc_file_checksum: {
    // We start for ROM from 0x0:0x7800 !!!!
    .const rom_bram_bank = 0
    .label rom_bram_ptr = $400
    .label fp = $61
    .label rom_package_read = $34
    .label b = $59
    .label rom_calc_file_checksum__13 = $2a
    // rom_calc_file_checksum::bank_set_bram1
    // BRAM = bank
    // [190] BRAM = rom_calc_file_checksum::rom_bram_bank -- vbuz1=vbuc1 
    lda #rom_bram_bank
    sta.z BRAM
    // [191] phi from rom_calc_file_checksum::bank_set_bram1 to rom_calc_file_checksum::@7 [phi:rom_calc_file_checksum::bank_set_bram1->rom_calc_file_checksum::@7]
    // rom_calc_file_checksum::@7
    // printf("Opening %s from SD card ...\n", file)
    // [192] call printf_str
    // [180] phi from rom_calc_file_checksum::@7 to printf_str [phi:rom_calc_file_checksum::@7->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:rom_calc_file_checksum::@7->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = rom_calc_file_checksum::s [phi:rom_calc_file_checksum::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [193] phi from rom_calc_file_checksum::@7 to rom_calc_file_checksum::@8 [phi:rom_calc_file_checksum::@7->rom_calc_file_checksum::@8]
    // rom_calc_file_checksum::@8
    // printf("Opening %s from SD card ...\n", file)
    // [194] call printf_string
    // [286] phi from rom_calc_file_checksum::@8 to printf_string [phi:rom_calc_file_checksum::@8->printf_string]
    jsr printf_string
    // [195] phi from rom_calc_file_checksum::@8 to rom_calc_file_checksum::@9 [phi:rom_calc_file_checksum::@8->rom_calc_file_checksum::@9]
    // rom_calc_file_checksum::@9
    // printf("Opening %s from SD card ...\n", file)
    // [196] call printf_str
    // [180] phi from rom_calc_file_checksum::@9 to printf_str [phi:rom_calc_file_checksum::@9->printf_str]
    // [180] phi printf_str::putc#13 = &cputc [phi:rom_calc_file_checksum::@9->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = rom_calc_file_checksum::s1 [phi:rom_calc_file_checksum::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [197] phi from rom_calc_file_checksum::@9 to rom_calc_file_checksum::@10 [phi:rom_calc_file_checksum::@9->rom_calc_file_checksum::@10]
    // rom_calc_file_checksum::@10
    // FILE *fp = fopen(file, "r")
    // [198] call fopen
    jsr fopen
    // [199] fopen::return#3 = fopen::return#2
    // rom_calc_file_checksum::@11
    // [200] rom_calc_file_checksum::fp#0 = fopen::return#3
    // if (fp)
    // [201] if((struct $2 *)0==rom_calc_file_checksum::fp#0) goto rom_calc_file_checksum::cbm_k_clrchn1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b6
  !:
    // [202] phi from rom_calc_file_checksum::@11 to rom_calc_file_checksum::@1 [phi:rom_calc_file_checksum::@11->rom_calc_file_checksum::@1]
    // [202] phi rom_file_checksum#22 = 0 [phi:rom_calc_file_checksum::@11->rom_calc_file_checksum::@1#0] -- vdum1=vbuc1 
    lda #0
    sta rom_file_checksum
    sta rom_file_checksum+1
    sta rom_file_checksum+2
    sta rom_file_checksum+3
    // [202] phi rom_file_size#27 = 0 [phi:rom_calc_file_checksum::@11->rom_calc_file_checksum::@1#1] -- vdum1=vbuc1 
    sta rom_file_size
    sta rom_file_size+1
    sta rom_file_size+2
    sta rom_file_size+3
    // rom_calc_file_checksum::@1
  __b1:
    // while (rom_file_size < 0x800000)
    // [203] if(rom_file_size#27<$800000) goto rom_calc_file_checksum::@2 -- vdum1_lt_vduc1_then_la1 
    lda rom_file_size+3
    cmp #>$800000>>$10
    bcc __b2
    bne !+
    lda rom_file_size+2
    cmp #<$800000>>$10
    bcc __b2
    bne !+
    lda rom_file_size+1
    cmp #>$800000
    bcc __b2
    bne !+
    lda rom_file_size
    cmp #<$800000
    bcc __b2
  !:
    // rom_calc_file_checksum::@3
  __b3:
    // fclose(fp)
    // [204] fclose::stream#0 = rom_calc_file_checksum::fp#0
    // [205] call fclose
    jsr fclose
    // [206] phi from rom_calc_file_checksum::@3 to rom_calc_file_checksum::cbm_k_clrchn1 [phi:rom_calc_file_checksum::@3->rom_calc_file_checksum::cbm_k_clrchn1]
    // [206] phi rom_file_checksum#16 = rom_file_checksum#22 [phi:rom_calc_file_checksum::@3->rom_calc_file_checksum::cbm_k_clrchn1#0] -- register_copy 
    // [206] phi rom_file_size#10 = rom_file_size#27 [phi:rom_calc_file_checksum::@3->rom_calc_file_checksum::cbm_k_clrchn1#1] -- register_copy 
    jmp cbm_k_clrchn1
    // [206] phi from rom_calc_file_checksum::@11 to rom_calc_file_checksum::cbm_k_clrchn1 [phi:rom_calc_file_checksum::@11->rom_calc_file_checksum::cbm_k_clrchn1]
  __b6:
    // [206] phi rom_file_checksum#16 = 0 [phi:rom_calc_file_checksum::@11->rom_calc_file_checksum::cbm_k_clrchn1#0] -- vdum1=vbuc1 
    lda #0
    sta rom_file_checksum
    sta rom_file_checksum+1
    sta rom_file_checksum+2
    sta rom_file_checksum+3
    // [206] phi rom_file_size#10 = 0 [phi:rom_calc_file_checksum::@11->rom_calc_file_checksum::cbm_k_clrchn1#1] -- vdum1=vbuc1 
    sta rom_file_size
    sta rom_file_size+1
    sta rom_file_size+2
    sta rom_file_size+3
    // rom_calc_file_checksum::cbm_k_clrchn1
  cbm_k_clrchn1:
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // rom_calc_file_checksum::@return
    // }
    // [208] return 
    rts
    // rom_calc_file_checksum::@2
  __b2:
    // unsigned int rom_package_read = fgets(rom_bram_ptr, 128, fp)
    // [209] fgets::stream#0 = rom_calc_file_checksum::fp#0
    // [210] call fgets
    jsr fgets
    // [211] fgets::return#5 = fgets::return#1
    // rom_calc_file_checksum::@12
    // [212] rom_calc_file_checksum::rom_package_read#0 = fgets::return#5
    // if (!rom_package_read)
    // [213] if(0!=rom_calc_file_checksum::rom_package_read#0) goto rom_calc_file_checksum::@4 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b7
    jmp __b3
    // [214] phi from rom_calc_file_checksum::@12 to rom_calc_file_checksum::@4 [phi:rom_calc_file_checksum::@12->rom_calc_file_checksum::@4]
  __b7:
    // [214] phi rom_file_checksum#15 = rom_file_checksum#22 [phi:rom_calc_file_checksum::@12->rom_calc_file_checksum::@4#0] -- register_copy 
    // [214] phi rom_calc_file_checksum::b#2 = 0 [phi:rom_calc_file_checksum::@12->rom_calc_file_checksum::@4#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z b
    sta.z b+1
    // rom_calc_file_checksum::@4
  __b4:
    // for(unsigned int b=0; b<rom_package_read; b++)
    // [215] if(rom_calc_file_checksum::b#2<rom_calc_file_checksum::rom_package_read#0) goto rom_calc_file_checksum::@5 -- vwuz1_lt_vwuz2_then_la1 
    lda.z b+1
    cmp.z rom_package_read+1
    bcc __b5
    bne !+
    lda.z b
    cmp.z rom_package_read
    bcc __b5
  !:
    // rom_calc_file_checksum::@6
    // rom_file_size += rom_package_read
    // [216] rom_file_size#1 = rom_file_size#27 + rom_calc_file_checksum::rom_package_read#0 -- vdum1=vdum1_plus_vwuz2 
    lda rom_file_size
    clc
    adc.z rom_package_read
    sta rom_file_size
    lda rom_file_size+1
    adc.z rom_package_read+1
    sta rom_file_size+1
    lda rom_file_size+2
    adc #0
    sta rom_file_size+2
    lda rom_file_size+3
    adc #0
    sta rom_file_size+3
    // [202] phi from rom_calc_file_checksum::@6 to rom_calc_file_checksum::@1 [phi:rom_calc_file_checksum::@6->rom_calc_file_checksum::@1]
    // [202] phi rom_file_checksum#22 = rom_file_checksum#15 [phi:rom_calc_file_checksum::@6->rom_calc_file_checksum::@1#0] -- register_copy 
    // [202] phi rom_file_size#27 = rom_file_size#1 [phi:rom_calc_file_checksum::@6->rom_calc_file_checksum::@1#1] -- register_copy 
    jmp __b1
    // rom_calc_file_checksum::@5
  __b5:
    // rom_file_checksum += rom_bram_ptr[b]
    // [217] rom_calc_file_checksum::$13 = rom_calc_file_checksum::rom_bram_ptr#1 + rom_calc_file_checksum::b#2 -- pbuz1=pbuc1_plus_vwuz2 
    lda.z b
    clc
    adc #<rom_bram_ptr
    sta.z rom_calc_file_checksum__13
    lda.z b+1
    adc #>rom_bram_ptr
    sta.z rom_calc_file_checksum__13+1
    // [218] rom_file_checksum#1 = rom_file_checksum#15 + *rom_calc_file_checksum::$13 -- vdum1=vdum1_plus__deref_pbuz2 
    ldy #0
    lda (rom_calc_file_checksum__13),y
    clc
    adc rom_file_checksum
    sta rom_file_checksum
    lda rom_file_checksum+1
    adc #0
    sta rom_file_checksum+1
    lda rom_file_checksum+2
    adc #0
    sta rom_file_checksum+2
    lda rom_file_checksum+3
    adc #0
    sta rom_file_checksum+3
    // for(unsigned int b=0; b<rom_package_read; b++)
    // [219] rom_calc_file_checksum::b#1 = ++ rom_calc_file_checksum::b#2 -- vwuz1=_inc_vwuz1 
    inc.z b
    bne !+
    inc.z b+1
  !:
    // [214] phi from rom_calc_file_checksum::@5 to rom_calc_file_checksum::@4 [phi:rom_calc_file_checksum::@5->rom_calc_file_checksum::@4]
    // [214] phi rom_file_checksum#15 = rom_file_checksum#1 [phi:rom_calc_file_checksum::@5->rom_calc_file_checksum::@4#0] -- register_copy 
    // [214] phi rom_calc_file_checksum::b#2 = rom_calc_file_checksum::b#1 [phi:rom_calc_file_checksum::@5->rom_calc_file_checksum::@4#1] -- register_copy 
    jmp __b4
  .segment Data
    file: .text "ROM-R45.BIN"
    .byte 0
    s: .text "Opening "
    .byte 0
    s1: .text @" from SD card ...\n"
    .byte 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($42) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $42
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [221] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [222] ultoa::value#1 = printf_ulong::uvalue#3
    // [223] call ultoa
  // Format number into buffer
    // [428] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [224] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [225] call printf_number_buffer
  // Print using format
    // [449] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [226] return 
    rts
}
  // rom_calc_rom_checksum
rom_calc_rom_checksum: {
    .const bank_set_brom2_bank = 4
    .label rom_addr = $42
    .label byte_brom = $63
    .label bank_brom = $60
    // rom_calc_rom_checksum::SEI1
    // asm
    // asm { sei  }
    sei
    // [229] phi from rom_calc_rom_checksum::SEI1 to rom_calc_rom_checksum::@1 [phi:rom_calc_rom_checksum::SEI1->rom_calc_rom_checksum::@1]
    // [229] phi rom_calc_rom_checksum::byte_brom#3 = (char *) 49152 [phi:rom_calc_rom_checksum::SEI1->rom_calc_rom_checksum::@1#0] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z byte_brom
    lda #>$c000
    sta.z byte_brom+1
    // [229] phi rom_checksum#1 = 0 [phi:rom_calc_rom_checksum::SEI1->rom_calc_rom_checksum::@1#1] -- vdum1=vduc1 
    lda #<0
    sta rom_checksum
    sta rom_checksum+1
    lda #<0>>$10
    sta rom_checksum+2
    lda #>0>>$10
    sta rom_checksum+3
    // [229] phi rom_calc_rom_checksum::bank_brom#2 = 0 [phi:rom_calc_rom_checksum::SEI1->rom_calc_rom_checksum::@1#2] -- vbuz1=vbuc1 
    lda #0
    sta.z bank_brom
    // [229] phi rom_calc_rom_checksum::rom_addr#2 = 0 [phi:rom_calc_rom_checksum::SEI1->rom_calc_rom_checksum::@1#3] -- vduz1=vduc1 
    sta.z rom_addr
    sta.z rom_addr+1
    lda #<0>>$10
    sta.z rom_addr+2
    lda #>0>>$10
    sta.z rom_addr+3
    // [229] phi from rom_calc_rom_checksum::@3 to rom_calc_rom_checksum::@1 [phi:rom_calc_rom_checksum::@3->rom_calc_rom_checksum::@1]
    // [229] phi rom_calc_rom_checksum::byte_brom#3 = rom_calc_rom_checksum::byte_brom#1 [phi:rom_calc_rom_checksum::@3->rom_calc_rom_checksum::@1#0] -- register_copy 
    // [229] phi rom_checksum#1 = rom_checksum#0 [phi:rom_calc_rom_checksum::@3->rom_calc_rom_checksum::@1#1] -- register_copy 
    // [229] phi rom_calc_rom_checksum::bank_brom#2 = rom_calc_rom_checksum::bank_brom#2 [phi:rom_calc_rom_checksum::@3->rom_calc_rom_checksum::@1#2] -- register_copy 
    // [229] phi rom_calc_rom_checksum::rom_addr#2 = rom_calc_rom_checksum::rom_addr#1 [phi:rom_calc_rom_checksum::@3->rom_calc_rom_checksum::@1#3] -- register_copy 
    // rom_calc_rom_checksum::@1
  __b1:
    // while(rom_addr < rom_file_size)
    // [230] if(rom_calc_rom_checksum::rom_addr#2<rom_file_size#10) goto rom_calc_rom_checksum::bank_set_brom1 -- vduz1_lt_vdum2_then_la1 
    lda.z rom_addr+3
    cmp rom_file_size+3
    bcc bank_set_brom1
    bne !+
    lda.z rom_addr+2
    cmp rom_file_size+2
    bcc bank_set_brom1
    bne !+
    lda.z rom_addr+1
    cmp rom_file_size+1
    bcc bank_set_brom1
    bne !+
    lda.z rom_addr
    cmp rom_file_size
    bcc bank_set_brom1
  !:
    // rom_calc_rom_checksum::bank_set_brom2
    // BROM = bank
    // [231] BROM = rom_calc_rom_checksum::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // rom_calc_rom_checksum::CLI1
    // asm
    // asm { cli  }
    cli
    // rom_calc_rom_checksum::@return
    // }
    // [233] return 
    rts
    // rom_calc_rom_checksum::bank_set_brom1
  bank_set_brom1:
    // BROM = bank
    // [234] BROM = rom_calc_rom_checksum::bank_brom#2 -- vbuz1=vbuz2 
    lda.z bank_brom
    sta.z BROM
    // rom_calc_rom_checksum::@3
    // rom_checksum += *byte_brom
    // [235] rom_checksum#0 = rom_checksum#1 + *rom_calc_rom_checksum::byte_brom#3 -- vdum1=vdum1_plus__deref_pbuz2 
    ldy #0
    lda (byte_brom),y
    clc
    adc rom_checksum
    sta rom_checksum
    lda rom_checksum+1
    adc #0
    sta rom_checksum+1
    lda rom_checksum+2
    adc #0
    sta rom_checksum+2
    lda rom_checksum+3
    adc #0
    sta rom_checksum+3
    // rom_addr++;
    // [236] rom_calc_rom_checksum::rom_addr#1 = ++ rom_calc_rom_checksum::rom_addr#2 -- vduz1=_inc_vduz1 
    inc.z rom_addr
    bne !+
    inc.z rom_addr+1
    bne !+
    inc.z rom_addr+2
    bne !+
    inc.z rom_addr+3
  !:
    // byte_brom++;
    // [237] rom_calc_rom_checksum::byte_brom#1 = ++ rom_calc_rom_checksum::byte_brom#3 -- pbuz1=_inc_pbuz1 
    inc.z byte_brom
    bne !+
    inc.z byte_brom+1
  !:
    // if(byte_brom == 0x0)
    // [238] if(rom_calc_rom_checksum::byte_brom#1!=0) goto rom_calc_rom_checksum::@1 -- pbuz1_neq_0_then_la1 
    lda.z byte_brom
    ora.z byte_brom+1
    bne __b1
    // rom_calc_rom_checksum::@2
    // bank_brom++;
    // [239] rom_calc_rom_checksum::bank_brom#1 = ++ rom_calc_rom_checksum::bank_brom#2 -- vbuz1=_inc_vbuz1 
    inc.z bank_brom
    // [229] phi from rom_calc_rom_checksum::@2 to rom_calc_rom_checksum::@1 [phi:rom_calc_rom_checksum::@2->rom_calc_rom_checksum::@1]
    // [229] phi rom_calc_rom_checksum::byte_brom#3 = (char *) 49152 [phi:rom_calc_rom_checksum::@2->rom_calc_rom_checksum::@1#0] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z byte_brom
    lda #>$c000
    sta.z byte_brom+1
    // [229] phi rom_checksum#1 = rom_checksum#0 [phi:rom_calc_rom_checksum::@2->rom_calc_rom_checksum::@1#1] -- register_copy 
    // [229] phi rom_calc_rom_checksum::bank_brom#2 = rom_calc_rom_checksum::bank_brom#1 [phi:rom_calc_rom_checksum::@2->rom_calc_rom_checksum::@1#2] -- register_copy 
    // [229] phi rom_calc_rom_checksum::rom_addr#2 = rom_calc_rom_checksum::rom_addr#1 [phi:rom_calc_rom_checksum::@2->rom_calc_rom_checksum::@1#3] -- register_copy 
    jmp __b1
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($7c) char mapbase, __zp($78) char config)
screenlayer: {
    .label screenlayer__0 = $7d
    .label screenlayer__1 = $7c
    .label screenlayer__2 = $7e
    .label screenlayer__5 = $78
    .label screenlayer__6 = $78
    .label screenlayer__7 = $77
    .label screenlayer__8 = $77
    .label screenlayer__9 = $72
    .label screenlayer__10 = $72
    .label screenlayer__11 = $72
    .label screenlayer__12 = $73
    .label screenlayer__13 = $73
    .label screenlayer__14 = $73
    .label screenlayer__16 = $77
    .label screenlayer__17 = $68
    .label screenlayer__18 = $72
    .label screenlayer__19 = $73
    .label mapbase = $7c
    .label config = $78
    .label mapbase_offset = $69
    .label y = $65
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [240] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [241] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [242] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [243] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [244] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [245] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [246] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [247] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [248] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [249] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [250] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [251] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [252] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [253] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [254] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [255] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [256] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [257] screenlayer::$18 = (char)screenlayer::$9
    // [258] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [259] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [260] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [261] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [262] screenlayer::$19 = (char)screenlayer::$12
    // [263] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [264] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [265] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [266] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z mapbase_offset
    lda __conio+3+1
    sta.z mapbase_offset+1
    // [267] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [267] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [267] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [268] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [269] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [270] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [271] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [272] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+$a
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+$a+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [273] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [267] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [267] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [267] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [274] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [275] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [276] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [277] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [278] call gotoxy
    // [133] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [133] phi gotoxy::y#3 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [133] phi gotoxy::x#3 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [279] return 
    rts
    // [280] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [281] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [282] gotoxy::y#1 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [283] call gotoxy
    // [133] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [133] phi gotoxy::y#3 = gotoxy::y#1 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [133] phi gotoxy::x#3 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [284] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [285] call clearline
    jsr clearline
    rts
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), char *str, char format_min_length, char format_justify_left)
printf_string: {
    .label putc = cputc
    // [287] phi from printf_string to printf_string::@1 [phi:printf_string->printf_string::@1]
    // printf_string::@1
    // printf_str(putc, str)
    // [288] call printf_str
    // [180] phi from printf_string::@1 to printf_str [phi:printf_string::@1->printf_str]
    // [180] phi printf_str::putc#13 = printf_string::putc#0 [phi:printf_string::@1->printf_str#0] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_str.putc
    lda #>putc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = rom_calc_file_checksum::file [phi:printf_string::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<rom_calc_file_checksum.file
    sta.z printf_str.s
    lda #>rom_calc_file_checksum.file
    sta.z printf_str.s+1
    jsr printf_str
    // printf_string::@return
    // }
    // [289] return 
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
// __zp($61) struct $2 * fopen(__zp($3f) const char *path, const char *mode)
fopen: {
    .label stream = $8000
    .label fopen__15 = $47
    .label fopen__16 = $2e
    .label fopen__26 = $2a
    .label fopen__28 = $34
    .label cbm_k_setnam1_filename = $b2
    .label cbm_k_setnam1_filename_len = $aa
    .label cbm_k_setnam1_fopen__0 = $3d
    .label cbm_k_readst1_status = $ab
    .label cbm_k_close1_channel = $ac
    .label pathpos = $60
    .label pathtoken = $63
    .label pathcmp = $71
    .label path = $3f
    // Parse path
    .label pathstep = $5d
    .label num = $5c
    .label cbm_k_readst1_return = $47
    .label return = $61
    // __logical = 0
    // [290] *((char *)&__stdio_file+$80) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __stdio_file+$80
    // __device = 0
    // [291] *((char *)&__stdio_file+$84) = 0 -- _deref_pbuc1=vbuc2 
    sta __stdio_file+$84
    // __channel = 0
    // [292] *((char *)&__stdio_file+$88) = 0 -- _deref_pbuc1=vbuc2 
    sta __stdio_file+$88
    // [293] phi from fopen to fopen::@7 [phi:fopen->fopen::@7]
    // [293] phi fopen::num#10 = 0 [phi:fopen->fopen::@7#0] -- vbuz1=vbuc1 
    sta.z num
    // [293] phi fopen::pathpos#10 = 0 [phi:fopen->fopen::@7#1] -- vbuz1=vbuc1 
    sta.z pathpos
    // [293] phi fopen::path#13 = rom_calc_file_checksum::file [phi:fopen->fopen::@7#2] -- pbuz1=pbuc1 
    lda #<rom_calc_file_checksum.file
    sta.z path
    lda #>rom_calc_file_checksum.file
    sta.z path+1
    // [293] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@7#3] -- vbuz1=vbuc1 
    lda #0
    sta.z pathstep
    // [293] phi fopen::pathtoken#10 = rom_calc_file_checksum::file [phi:fopen->fopen::@7#4] -- pbuz1=pbuc1 
    lda #<rom_calc_file_checksum.file
    sta.z pathtoken
    lda #>rom_calc_file_checksum.file
    sta.z pathtoken+1
  // Iterate while path is not \0.
    // [293] phi from fopen::@21 to fopen::@7 [phi:fopen::@21->fopen::@7]
    // [293] phi fopen::num#10 = fopen::num#13 [phi:fopen::@21->fopen::@7#0] -- register_copy 
    // [293] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@21->fopen::@7#1] -- register_copy 
    // [293] phi fopen::path#13 = fopen::path#10 [phi:fopen::@21->fopen::@7#2] -- register_copy 
    // [293] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@21->fopen::@7#3] -- register_copy 
    // [293] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@21->fopen::@7#4] -- register_copy 
    // fopen::@7
  __b7:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [294] if(*fopen::pathtoken#10==',') goto fopen::@8 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken),y
    bne !__b8+
    jmp __b8
  !__b8:
    // fopen::@32
    // [295] if(*fopen::pathtoken#10=='@') goto fopen::@8 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken),y
    bne !__b8+
    jmp __b8
  !__b8:
    // fopen::@22
    // if (pathstep == 0)
    // [296] if(fopen::pathstep#10!=0) goto fopen::@9 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b9
    // fopen::@23
    // __stdio_file.filename[pathpos] = *pathtoken
    // [297] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbuz2 
    lda (pathtoken),y
    ldy.z pathpos
    sta __stdio_file,y
    // pathpos++;
    // [298] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos
    // [299] phi from fopen::@11 fopen::@22 fopen::@23 to fopen::@9 [phi:fopen::@11/fopen::@22/fopen::@23->fopen::@9]
    // [299] phi fopen::num#13 = fopen::num#15 [phi:fopen::@11/fopen::@22/fopen::@23->fopen::@9#0] -- register_copy 
    // [299] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@11/fopen::@22/fopen::@23->fopen::@9#1] -- register_copy 
    // [299] phi fopen::path#10 = fopen::path#12 [phi:fopen::@11/fopen::@22/fopen::@23->fopen::@9#2] -- register_copy 
    // [299] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@11/fopen::@22/fopen::@23->fopen::@9#3] -- register_copy 
    // fopen::@9
  __b9:
    // pathtoken++;
    // [300] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken
    bne !+
    inc.z pathtoken+1
  !:
    // fopen::@21
    // pathtoken - 1
    // [301] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [302] if(0!=*fopen::$28) goto fopen::@7 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b7
    // fopen::@25
    // __status = 0
    // [303] *((char *)&__stdio_file+$8c) = 0 -- _deref_pbuc1=vbuc2 
    tya
    sta __stdio_file+$8c
    // if(!__logical)
    // [304] if(0!=*((char *)&__stdio_file+$80)) goto fopen::@1 -- 0_neq__deref_pbuc1_then_la1 
    lda __stdio_file+$80
    bne __b1
    // fopen::@26
    // __logical = __stdio_filecount+1
    // [305] *((char *)&__stdio_file+$80) = 1 -- _deref_pbuc1=vbuc2 
    lda #1
    sta __stdio_file+$80
    // fopen::@1
  __b1:
    // if(!__device)
    // [306] if(0!=*((char *)&__stdio_file+$84)) goto fopen::@2 -- 0_neq__deref_pbuc1_then_la1 
    lda __stdio_file+$84
    bne __b2
    // fopen::@4
    // __device = 8
    // [307] *((char *)&__stdio_file+$84) = 8 -- _deref_pbuc1=vbuc2 
    lda #8
    sta __stdio_file+$84
    // fopen::@2
  __b2:
    // if(!__channel)
    // [308] if(0!=*((char *)&__stdio_file+$88)) goto fopen::@3 -- 0_neq__deref_pbuc1_then_la1 
    lda __stdio_file+$88
    bne __b3
    // fopen::@5
    // __channel = __stdio_filecount+2
    // [309] *((char *)&__stdio_file+$88) = 2 -- _deref_pbuc1=vbuc2 
    lda #2
    sta __stdio_file+$88
    // fopen::@3
  __b3:
    // cbm_k_setnam(__filename)
    // [310] fopen::cbm_k_setnam1_filename = (char *)&__stdio_file -- pbuz1=pbuc1 
    lda #<__stdio_file
    sta.z cbm_k_setnam1_filename
    lda #>__stdio_file
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [311] strlen::str#3 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [312] call strlen
    // [490] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [490] phi strlen::str#7 = strlen::str#3 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [313] strlen::return#4 = strlen::len#2
    // fopen::@30
    // [314] fopen::cbm_k_setnam1_$0 = strlen::return#4
    // char filename_len = (char)strlen(filename)
    // [315] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta.z cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@27
    // cbm_k_setlfs(__logical, __device, __channel)
    // [317] cbm_k_setlfs::channel = *((char *)&__stdio_file+$80) -- vbuz1=_deref_pbuc1 
    lda __stdio_file+$80
    sta.z cbm_k_setlfs.channel
    // [318] cbm_k_setlfs::device = *((char *)&__stdio_file+$84) -- vbuz1=_deref_pbuc1 
    lda __stdio_file+$84
    sta.z cbm_k_setlfs.device
    // [319] cbm_k_setlfs::command = *((char *)&__stdio_file+$88) -- vbuz1=_deref_pbuc1 
    lda __stdio_file+$88
    sta.z cbm_k_setlfs.command
    // [320] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [322] fopen::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [324] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [325] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@28
    // cbm_k_readst()
    // [326] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [327] *((char *)&__stdio_file+$8c) = fopen::$15 -- _deref_pbuc1=vbuz1 
    lda.z fopen__15
    sta __stdio_file+$8c
    // ferror(stream)
    // [328] call ferror
    jsr ferror
    // [329] ferror::return#0 = ferror::return#1
    // fopen::@31
    // [330] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [331] if(0==fopen::$16) goto fopen::@return -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@6
    // cbm_k_close(__logical)
    // [332] fopen::cbm_k_close1_channel = *((char *)&__stdio_file+$80) -- vbuz1=_deref_pbuc1 
    lda __stdio_file+$80
    sta.z cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [334] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [334] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    rts
    // [334] phi from fopen::@31 to fopen::@return [phi:fopen::@31->fopen::@return]
  __b4:
    // [334] phi fopen::return#2 = fopen::stream#0 [phi:fopen::@31->fopen::@return#0] -- pssz1=pssc1 
    lda #<stream
    sta.z return
    lda #>stream
    sta.z return+1
    // fopen::@return
    // }
    // [335] return 
    rts
    // fopen::@8
  __b8:
    // if (pathstep > 0)
    // [336] if(fopen::pathstep#10>0) goto fopen::@10 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = '\0'
    // [337] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos
    sta __stdio_file,y
    // path = pathtoken + 1
    // [338] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    // [339] phi from fopen::@15 fopen::@16 fopen::@17 fopen::@18 fopen::@24 to fopen::@11 [phi:fopen::@15/fopen::@16/fopen::@17/fopen::@18/fopen::@24->fopen::@11]
    // [339] phi fopen::num#15 = fopen::num#2 [phi:fopen::@15/fopen::@16/fopen::@17/fopen::@18/fopen::@24->fopen::@11#0] -- register_copy 
    // [339] phi fopen::path#12 = fopen::path#15 [phi:fopen::@15/fopen::@16/fopen::@17/fopen::@18/fopen::@24->fopen::@11#1] -- register_copy 
    // fopen::@11
  __b11:
    // pathstep++;
    // [340] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b9
    // fopen::@10
  __b10:
    // char pathcmp = *path
    // [341] fopen::pathcmp#0 = *fopen::path#13 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [342] if(fopen::pathcmp#0=='D') goto fopen::@12 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b12
    // fopen::@19
    // case 'L':
    // [343] if(fopen::pathcmp#0=='L') goto fopen::@12 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b12
    // fopen::@20
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [344] if(fopen::pathcmp#0=='C') goto fopen::@12 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b12
    // [345] phi from fopen::@20 fopen::@29 to fopen::@13 [phi:fopen::@20/fopen::@29->fopen::@13]
    // [345] phi fopen::path#15 = fopen::path#13 [phi:fopen::@20/fopen::@29->fopen::@13#0] -- register_copy 
    // [345] phi fopen::num#2 = fopen::num#10 [phi:fopen::@20/fopen::@29->fopen::@13#1] -- register_copy 
    // fopen::@13
  __b13:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [346] if(fopen::pathcmp#0=='L') goto fopen::@16 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b16
    // fopen::@14
    // case 'D':
    //                     __device = num;
    //                     break;
    // [347] if(fopen::pathcmp#0=='D') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [348] if(fopen::pathcmp#0!='C') goto fopen::@11 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b11
    // fopen::@18
    // __channel = num
    // [349] *((char *)&__stdio_file+$88) = fopen::num#2 -- _deref_pbuc1=vbuz1 
    lda.z num
    sta __stdio_file+$88
    jmp __b11
    // fopen::@17
  __b17:
    // __device = num
    // [350] *((char *)&__stdio_file+$84) = fopen::num#2 -- _deref_pbuc1=vbuz1 
    lda.z num
    sta __stdio_file+$84
    jmp __b11
    // fopen::@16
  __b16:
    // __logical = num
    // [351] *((char *)&__stdio_file+$80) = fopen::num#2 -- _deref_pbuc1=vbuz1 
    lda.z num
    sta __stdio_file+$80
    jmp __b11
    // fopen::@12
  __b12:
    // atoi(path + 1)
    // [352] atoi::str#0 = fopen::path#13 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [353] call atoi
    // [549] phi from fopen::@12 to atoi [phi:fopen::@12->atoi]
    // [549] phi atoi::str#2 = atoi::str#0 [phi:fopen::@12->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [354] atoi::return#3 = atoi::return#2
    // fopen::@29
    // [355] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [356] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [357] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    jmp __b13
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
// int fclose(__zp($61) struct $2 *stream)
fclose: {
    .label fclose__1 = $5d
    .label fclose__4 = $5c
    .label fclose__6 = $71
    .label cbm_k_chkin1_channel = $b1
    .label cbm_k_chkin1_status = $ad
    .label cbm_k_readst1_status = $ae
    .label cbm_k_close1_channel = $af
    .label cbm_k_readst2_status = $b0
    .label sp = $71
    .label cbm_k_readst1_return = $5d
    .label cbm_k_readst2_return = $5c
    .label stream = $61
    // unsigned char sp = (unsigned char)stream
    // [358] fclose::sp#0 = (char)fclose::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [359] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$80)[fclose::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$80,y
    sta.z cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [360] fclose::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [362] fclose::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [364] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [365] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [366] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [367] ((char *)&__stdio_file+$8c)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [368] if(0==((char *)&__stdio_file+$8c)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [369] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [370] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$80)[fclose::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$80,y
    sta.z cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [372] fclose::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [374] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [375] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [376] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [377] ((char *)&__stdio_file+$8c)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [378] if(0==((char *)&__stdio_file+$8c)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [379] ((char *)&__stdio_file+$80)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$80,y
    // __device = 0
    // [380] ((char *)&__stdio_file+$84)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$84,y
    // __channel = 0
    // [381] ((char *)&__stdio_file+$88)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$88,y
    // __filename
    // [382] fclose::$6 = fclose::sp#0 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z fclose__6
    asl
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [383] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
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
// __zp($34) unsigned int fgets(__zp($3f) char *ptr, unsigned int size, __zp($61) struct $2 *stream)
fgets: {
    .const size = $80
    .label fgets__1 = $5c
    .label fgets__8 = $4f
    .label fgets__9 = $54
    .label fgets__13 = $32
    .label cbm_k_chkin1_channel = $75
    .label cbm_k_chkin1_status = $6b
    .label cbm_k_readst1_status = $6c
    .label cbm_k_readst2_status = $55
    .label sp = $5d
    .label cbm_k_readst1_return = $5c
    .label return = $34
    .label bytes = $3d
    .label cbm_k_readst2_return = $4f
    .label read = $34
    .label ptr = $3f
    .label remaining = $2a
    .label stream = $61
    // unsigned char sp = (unsigned char)stream
    // [384] fgets::sp#0 = (char)fgets::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [385] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$80)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$80,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [386] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [388] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [390] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [391] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@9
    // cbm_k_readst()
    // [392] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [393] ((char *)&__stdio_file+$8c)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [394] if(0==((char *)&__stdio_file+$8c)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b8
    // [395] phi from fgets::@10 fgets::@3 fgets::@9 to fgets::@return [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return]
  __b1:
    // [395] phi fgets::return#1 = 0 [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [396] return 
    rts
    // [397] phi from fgets::@13 to fgets::@1 [phi:fgets::@13->fgets::@1]
    // [397] phi fgets::read#10 = fgets::read#1 [phi:fgets::@13->fgets::@1#0] -- register_copy 
    // [397] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@13->fgets::@1#1] -- register_copy 
    // [397] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@13->fgets::@1#2] -- register_copy 
    // [397] phi from fgets::@9 to fgets::@1 [phi:fgets::@9->fgets::@1]
  __b8:
    // [397] phi fgets::read#10 = 0 [phi:fgets::@9->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [397] phi fgets::remaining#11 = fgets::size#0 [phi:fgets::@9->fgets::@1#1] -- vwuz1=vwuc1 
    lda #<size
    sta.z remaining
    lda #>size
    sta.z remaining+1
    // [397] phi fgets::ptr#10 = rom_calc_file_checksum::rom_bram_ptr#1 [phi:fgets::@9->fgets::@1#2] -- pbuz1=pbuc1 
    lda #<rom_calc_file_checksum.rom_bram_ptr
    sta.z ptr
    lda #>rom_calc_file_checksum.rom_bram_ptr
    sta.z ptr+1
    // fgets::@1
    // fgets::@6
  __b6:
    // if (remaining >= 512)
    // [398] if(fgets::remaining#11>=$200) goto fgets::@2 -- vwuz1_ge_vwuc1_then_la1 
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
    // [399] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [400] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [401] call cx16_k_macptr
    jsr cx16_k_macptr
    // [402] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@12
  __b12:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [403] fgets::bytes#3 = cx16_k_macptr::return#4
    // [404] phi from fgets::@11 fgets::@12 to fgets::cbm_k_readst2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2]
    // [404] phi fgets::bytes#10 = fgets::bytes#2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [405] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [407] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [408] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@10
    // cbm_k_readst()
    // [409] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [410] ((char *)&__stdio_file+$8c)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$8c,y
    // __status & 0xBF
    // [411] fgets::$9 = ((char *)&__stdio_file+$8c)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$8c,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [412] if(0==fgets::$9) goto fgets::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    jmp __b1
    // fgets::@3
  __b3:
    // if (bytes == 0xFFFF)
    // [413] if(fgets::bytes#10!=$ffff) goto fgets::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [414] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [415] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [416] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [417] if(fgets::$13!=$c0) goto fgets::@5 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b5
    // fgets::@8
    // ptr -= 0x2000
    // [418] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [419] phi from fgets::@4 fgets::@8 to fgets::@5 [phi:fgets::@4/fgets::@8->fgets::@5]
    // [419] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@4/fgets::@8->fgets::@5#0] -- register_copy 
    // fgets::@5
  __b5:
    // remaining -= bytes
    // [420] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [421] if(((char *)&__stdio_file+$8c)[fgets::sp#0]==0) goto fgets::@13 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$8c,y
    cmp #0
    beq __b13
    // [395] phi from fgets::@13 fgets::@5 to fgets::@return [phi:fgets::@13/fgets::@5->fgets::@return]
    // [395] phi fgets::return#1 = fgets::read#1 [phi:fgets::@13/fgets::@5->fgets::@return#0] -- register_copy 
    rts
    // fgets::@13
  __b13:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [422] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b6+
    jmp __b6
  !__b6:
    rts
    // fgets::@2
  __b2:
    // cx16_k_macptr(512, ptr)
    // [423] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [424] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [425] call cx16_k_macptr
    jsr cx16_k_macptr
    // [426] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@11
    // bytes = cx16_k_macptr(512, ptr)
    // [427] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b12
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($42) unsigned long value, __zp($61) char *buffer, char radix)
ultoa: {
    .label ultoa__10 = $54
    .label ultoa__11 = $4f
    .label digit_value = $50
    .label buffer = $61
    .label digit = $60
    .label value = $42
    .label started = $5c
    // [429] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [429] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [429] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [429] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [429] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [430] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [431] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [432] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [433] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [434] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [435] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [436] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [437] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [438] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [439] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [440] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [440] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [440] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [440] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [441] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [429] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [429] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [429] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [429] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [429] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [442] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [443] ultoa_append::value#0 = ultoa::value#2
    // [444] ultoa_append::sub#0 = ultoa::digit_value#0
    // [445] call ultoa_append
    // [570] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [446] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [447] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [448] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [440] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [440] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [440] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [440] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(void (*putc)(char), __zp($47) char buffer_sign, char *buffer_digits, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label buffer_digits = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label putc = cputc
    .label buffer_sign = $47
    // printf_number_buffer::@1
    // if(buffer.sign)
    // [450] if(0==printf_number_buffer::buffer_sign#0) goto printf_number_buffer::@2 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b2
    // printf_number_buffer::@3
    // putc(buffer.sign)
    // [451] stackpush(char) = printf_number_buffer::buffer_sign#0 -- _stackpushbyte_=vbuz1 
    pha
    // [452] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [454] phi from printf_number_buffer::@1 printf_number_buffer::@3 to printf_number_buffer::@2 [phi:printf_number_buffer::@1/printf_number_buffer::@3->printf_number_buffer::@2]
    // printf_number_buffer::@2
  __b2:
    // printf_str(putc, buffer.digits)
    // [455] call printf_str
    // [180] phi from printf_number_buffer::@2 to printf_str [phi:printf_number_buffer::@2->printf_str]
    // [180] phi printf_str::putc#13 = printf_number_buffer::putc#0 [phi:printf_number_buffer::@2->printf_str#0] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_str.putc
    lda #>putc
    sta.z printf_str.putc+1
    // [180] phi printf_str::s#13 = printf_number_buffer::buffer_digits#0 [phi:printf_number_buffer::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<buffer_digits
    sta.z printf_str.s
    lda #>buffer_digits
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [456] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $41
    .label insertup__4 = $38
    .label insertup__6 = $3b
    .label insertup__7 = $38
    .label width = $41
    .label y = $33
    // __conio.width+1
    // [457] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [458] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [459] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [459] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [460] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [461] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [462] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [463] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [464] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [465] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [466] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [467] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [468] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [469] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [470] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [471] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [472] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [473] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [459] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [459] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $24
    .label clearline__1 = $26
    .label clearline__2 = $27
    .label clearline__3 = $25
    .label addr = $36
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [474] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [475] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [476] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [477] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [478] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [479] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [480] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [481] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [482] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [483] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [484] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [484] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [485] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [486] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [487] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [488] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [489] return 
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($3d) unsigned int strlen(__zp($2a) char *str)
strlen: {
    .label len = $3d
    .label str = $2a
    .label return = $3d
    // [491] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [491] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [491] phi strlen::str#5 = strlen::str#7 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [492] if(0!=*strlen::str#5) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [493] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [494] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [495] strlen::str#0 = ++ strlen::str#5 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [491] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [491] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [491] phi strlen::str#5 = strlen::str#0 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // cbm_k_setlfs
/**
 * @brief Sets the logical file channel.
 *
 * @param channel the logical file number.
 * @param device the device number.
 * @param command the command.
 */
// void cbm_k_setlfs(__zp($a9) volatile char channel, __zp($7b) volatile char device, __zp($74) volatile char command)
cbm_k_setlfs: {
    .label channel = $a9
    .label device = $7b
    .label command = $74
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [497] return 
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
// __zp($2e) int ferror(struct $2 *stream)
ferror: {
    .label ferror__6 = $32
    .label ferror__15 = $4f
    .label cbm_k_setnam1_filename = $79
    .label cbm_k_setnam1_filename_len = $6d
    .label cbm_k_setnam1_ferror__0 = $3d
    .label cbm_k_chkin1_channel = $76
    .label cbm_k_chkin1_status = $6e
    .label cbm_k_chrin1_ch = $6f
    .label cbm_k_readst1_status = $5e
    .label cbm_k_close1_channel = $70
    .label cbm_k_chrin2_ch = $5f
    .label return = $2e
    .label cbm_k_chrin1_return = $4f
    .label ch = $4f
    .label cbm_k_readst1_return = $32
    .label st = $32
    .label errno_len = $54
    .label cbm_k_chrin2_return = $4f
    .label errno_parsed = $47
    // cbm_k_setlfs(15, 8, 15)
    // [498] cbm_k_setlfs::channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.channel
    // [499] cbm_k_setlfs::device = 8 -- vbuz1=vbuc1 
    lda #8
    sta.z cbm_k_setlfs.device
    // [500] cbm_k_setlfs::command = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.command
    // [501] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [502] ferror::cbm_k_setnam1_filename = ferror::$18 -- pbuz1=pbuc1 
    lda #<ferror__18
    sta.z cbm_k_setnam1_filename
    lda #>ferror__18
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [503] strlen::str#4 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [504] call strlen
    // [490] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [490] phi strlen::str#7 = strlen::str#4 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [505] strlen::return#10 = strlen::len#2
    // ferror::@12
    // [506] ferror::cbm_k_setnam1_$0 = strlen::return#10
    // char filename_len = (char)strlen(filename)
    // [507] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
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
    // [510] ferror::cbm_k_chkin1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [511] ferror::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [513] ferror::cbm_k_chrin1_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [515] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [516] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [517] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [518] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [518] phi __errno#13 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [518] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    sta.z errno_len
    // [518] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [518] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [519] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [521] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [522] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [523] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [524] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [525] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [526] *((char *)&__stdio_file+$8c) = ferror::st#1 -- _deref_pbuc1=vbuz1 
    sta __stdio_file+$8c
    // cbm_k_close(15)
    // [527] ferror::cbm_k_close1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [529] ferror::return#1 = __errno#13 -- vwsz1=vwsm2 
    lda __errno
    sta.z return
    lda __errno+1
    sta.z return+1
    // ferror::@return
    // }
    // [530] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [531] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [532] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [533] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [534] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [535] call strncpy
    // [597] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [536] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [537] call atoi
    // [549] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [549] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [538] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [539] __errno#2 = atoi::return#4 -- vwsm1=vwsz2 
    lda.z atoi.return
    sta __errno
    lda.z atoi.return+1
    sta __errno+1
    // [540] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [540] phi __errno#61 = __errno#13 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [540] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [541] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [542] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [543] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [545] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [546] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [547] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [548] ferror::ch#1 = ferror::$15
    // [518] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [518] phi __errno#13 = __errno#61 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [518] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [518] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [518] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    ferror__18: .text ""
    .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($2a) int atoi(__zp($3f) const char *str)
atoi: {
    .label atoi__6 = $2a
    .label atoi__7 = $2a
    .label res = $2a
    // Initialize sign as positive
    .label i = $32
    .label return = $2a
    .label str = $3f
    // Initialize result
    .label negative = $39
    .label atoi__10 = $30
    .label atoi__11 = $2a
    // if (str[i] == '-')
    // [550] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [551] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [552] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [552] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [552] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [552] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [552] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [552] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [552] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [552] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [553] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [554] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [555] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [557] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [557] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [556] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [558] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [559] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [560] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [561] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [562] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [563] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [564] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [552] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [552] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [552] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [552] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
    jmp __b3
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
// __zp($3d) unsigned int cx16_k_macptr(__zp($58) volatile char bytes, __zp($56) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $58
    .label buffer = $56
    .label bytes_read = $4b
    .label return = $3d
    // unsigned int bytes_read
    // [565] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [567] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [568] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [569] return 
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
// __zp($42) unsigned long ultoa_append(__zp($34) char *buffer, __zp($42) unsigned long value, __zp($50) unsigned long sub)
ultoa_append: {
    .label buffer = $34
    .label value = $42
    .label sub = $50
    .label return = $42
    .label digit = $47
    // [571] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [571] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [571] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [572] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [573] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [574] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [575] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [576] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [571] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [571] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [571] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
// void memcpy8_vram_vram(__zp($25) char dbank_vram, __zp($36) unsigned int doffset_vram, __zp($24) char sbank_vram, __zp($2c) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $26
    .label memcpy8_vram_vram__1 = $27
    .label memcpy8_vram_vram__2 = $24
    .label memcpy8_vram_vram__3 = $28
    .label memcpy8_vram_vram__4 = $29
    .label memcpy8_vram_vram__5 = $25
    .label num8 = $23
    .label dbank_vram = $25
    .label doffset_vram = $36
    .label sbank_vram = $24
    .label soffset_vram = $2c
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [577] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [578] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [579] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [580] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [581] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [582] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [583] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [584] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [585] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [586] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [587] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [588] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [589] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [590] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [591] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [591] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [592] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [593] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [594] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [595] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [596] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
    lda.z num8
    sta.z num8_1
    jmp __b1
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($30) char *dst, __zp($2e) const char *src, __zp($4d) unsigned int n)
strncpy: {
    .label c = $39
    .label dst = $30
    .label i = $34
    .label src = $2e
    .label n = $4d
    // [598] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [598] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [598] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [598] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [599] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [600] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [601] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [602] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [603] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [604] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [604] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [605] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [606] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [607] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [598] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [598] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [598] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [598] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_LONG: .dword $10000000, $1000000, $100000, $10000, $1000, $100, $10
  isr_vsync: .word $314
  __conio: .fill SIZEOF_STRUCT___1, 0
  // Buffer used for stringified number being printed
  printf_buffer: .fill SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER, 0
  __stdio_file: .fill SIZEOF_STRUCT___2, 0
  __errno: .word 0
  rom_file_checksum: .dword 0
  rom_file_size: .dword 0
  rom_checksum: .dword 0
